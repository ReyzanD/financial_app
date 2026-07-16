import 'package:uuid/uuid.dart';
import 'package:financial_app/models/place_visit.dart';
import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/price_observation_data_service.dart';
import 'package:financial_app/services/data/alternative_suggestion_data_service.dart';
import 'package:financial_app/services/overpass_api_service.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Core recommendation engine for the Phase D alternative-recommendation feature.
///
/// Pipeline:
///   1. Receive a PlaceVisit (origin) with lat/lng + category.
///   2. Check cache for fresh suggestions.
///   3. If stale/missing, query Overpass for nearby POIs matching the category.
///   4. Cross-reference known prices (price_observations) for savings estimation.
///   5. Rank by distance, then by price savings (when available).
///   6. Compute confidence level (0–100) based on data quality.
///   7. Persist to alternative_suggestions table and return.
class AlternativeRecommendationEngine {
  final PlaceVisitDataService _placeVisitDataService;
  final PriceObservationDataService _priceObservationDataService;
  final AlternativeSuggestionDataService _alternativeSuggestionDataService;
  final OverpassApiService _overpassApiService;
  final _uuid = const Uuid();

  AlternativeRecommendationEngine({
    PlaceVisitDataService? placeVisitDataService,
    PriceObservationDataService? priceObservationDataService,
    AlternativeSuggestionDataService? alternativeSuggestionDataService,
    OverpassApiService? overpassApiService,
  }) : _placeVisitDataService =
           placeVisitDataService ?? getIt<PlaceVisitDataService>(),
       _priceObservationDataService =
           priceObservationDataService ?? getIt<PriceObservationDataService>(),
       _alternativeSuggestionDataService =
           alternativeSuggestionDataService ??
           getIt<AlternativeSuggestionDataService>(),
       _overpassApiService = overpassApiService ?? getIt<OverpassApiService>();

  /// Get alternative suggestions for a given place visit.
  ///
  /// Returns cached suggestions if fresh (≤24h), otherwise runs the full
  /// Overpass query + ranking pipeline.
  Future<List<AlternativeSuggestion>> getAlternativesForPlace(
    PlaceVisit placeVisit, {
    bool forceRefresh = false,
    int radiusMeters = 1000,
  }) async {
    try {
      // 1. Check cache
      if (!forceRefresh) {
        final fresh = await _alternativeSuggestionDataService
            .hasFreshSuggestions(placeVisit.id);
        if (fresh) {
          LoggerService.cache('HIT', 'suggestions_${placeVisit.id}');
          return _alternativeSuggestionDataService.getForOriginPlace(
            placeVisit.id,
          );
        }
      }

      // 2. Query Overpass for nearby POIs
      final pois = await _overpassApiService.findNearbyPois(
        latitude: placeVisit.latitude,
        longitude: placeVisit.longitude,
        categoryName: placeVisit.category,
        radiusMeters: radiusMeters,
        maxResults: 20,
        forceRefresh: forceRefresh,
      );

      if (pois.isEmpty) {
        LoggerService.info(
          'ℹ️ No Overpass POIs found near ${placeVisit.placeName}',
        );
        return [];
      }

      // 3. Get median price for this category for savings estimation
      final medianPrice = await _priceObservationDataService
          .getMedianPriceForCategory(placeVisit.category, minObservations: 2);

      // 4. Get known prices for this category's place visits
      final knownPlacePrices = await _priceObservationDataService
          .getPriceObservations(category: placeVisit.category);

      // Build a map: place_name -> lowest price observed
      final lowestPrices = <String, double>{};
      for (final obs in knownPlacePrices) {
        final pv = await _placeVisitDataService.getPlaceVisit(obs.placeVisitId);
        if (pv != null) {
          final current = lowestPrices[pv.placeName.toLowerCase()];
          if (current == null || obs.price < current) {
            lowestPrices[pv.placeName.toLowerCase()] = obs.price;
          }
        }
      }

      // 5. Build and rank suggestions
      final suggestions = <_RankedSuggestion>[];
      final originPrice = placeVisit.totalSpent / placeVisit.visitCount;

      for (final poi in pois) {
        // Calculate distance from origin
        final distance = LocationService.calculateDistance(
          placeVisit.latitude,
          placeVisit.longitude,
          poi.latitude,
          poi.longitude,
        );

        // Check if we have price data for this POI (match by name)
        double? estimatedSavings;
        String basis = 'distance_only';
        if (medianPrice != null) {
          estimatedSavings = 0.0;
        }

        final poiNameLower = poi.name.toLowerCase();
        final knownPrice = lowestPrices[poiNameLower];
        if (knownPrice != null && originPrice > 0) {
          estimatedSavings = originPrice - knownPrice;
          if (estimatedSavings > 0) {
            basis = 'price';
          } else {
            estimatedSavings = null;
          }
        } else if (medianPrice != null && originPrice > medianPrice) {
          // Estimate savings as the difference from median
          estimatedSavings = originPrice - medianPrice;
          if (estimatedSavings > 0) {
            basis = 'price';
          }
        }

        // Confidence: higher if we have price data, closer, and named
        int confidence = _computeConfidence(
          hasPriceData: knownPrice != null || (medianPrice != null),
          distanceMeters: distance,
          hasName: poi.name.isNotEmpty && poi.name != poi.osmId,
        );

        suggestions.add(
          _RankedSuggestion(
            poi: poi,
            distanceMeters: distance,
            estimatedSavings: estimatedSavings,
            basis: basis,
            confidence: confidence,
          ),
        );
      }

      // 6. Sort per Phase D spec:
      //    - Rank by Haversine distance (ascending) as the primary signal.
      //    - When price observations exist for a candidate, rank by
      //      (price savings, distance) instead — cheaper + closer first.
      //    Confidence remains a displayed reliability signal, not the sort key.
      suggestions.sort(_compareForRanking);

      // Take top 10
      final top = suggestions.take(10).toList();
      final now = DateTime.now();

      // 7. Persist
      final models =
          top
              .map(
                (s) => AlternativeSuggestion(
                  id: _uuid.v4(),
                  originPlaceVisitId: placeVisit.id,
                  suggestedPlaceName: s.poi.name,
                  suggestedOsmNodeId: s.poi.osmNodeId,
                  suggestedLatitude: s.poi.latitude,
                  suggestedLongitude: s.poi.longitude,
                  distanceMeters: s.distanceMeters,
                  estimatedSavings: s.estimatedSavings,
                  basis: s.basis,
                  category: placeVisit.category,
                  confidenceLevel: s.confidence,
                  generatedAt: now,
                ),
              )
              .toList();

      await _alternativeSuggestionDataService.saveSuggestions(models);
      LoggerService.info(
        '✅ Generated ${models.length} alternatives for ${placeVisit.placeName}',
      );

      return models;
    } catch (e) {
      LoggerService.error(
        'Error generating alternatives for ${placeVisit.placeName}',
        error: e,
      );
      rethrow;
    }
  }

  /// Get alternatives for a place visit by its ID (convenience wrapper).
  Future<List<AlternativeSuggestion>> getAlternativesForPlaceId(
    String placeVisitId, {
    bool forceRefresh = false,
  }) async {
    final pv = await _placeVisitDataService.getPlaceVisit(placeVisitId);
    if (pv == null) return [];
    return getAlternativesForPlace(pv, forceRefresh: forceRefresh);
  }

  /// Ranking comparator per the Phase D spec:
  ///   - Price-based suggestions (basis == 'price' with positive savings)
  ///     rank above distance-only ones.
  ///   - Among price-based suggestions, higher savings wins, then closer.
  ///   - Distance-only suggestions rank by Haversine distance (ascending).
  /// Confidence is a displayed signal, not a sort key.
  static int _compareForRanking(_RankedSuggestion a, _RankedSuggestion b) {
    final aHasPrice =
        a.basis == 'price' &&
        a.estimatedSavings != null &&
        a.estimatedSavings! > 0;
    final bHasPrice =
        b.basis == 'price' &&
        b.estimatedSavings != null &&
        b.estimatedSavings! > 0;

    if (aHasPrice && !bHasPrice) return -1;
    if (!aHasPrice && bHasPrice) return 1;

    if (aHasPrice && bHasPrice) {
      final savingsCmp = b.estimatedSavings!.compareTo(a.estimatedSavings!);
      if (savingsCmp != 0) return savingsCmp;
      return a.distanceMeters.compareTo(b.distanceMeters);
    }

    return a.distanceMeters.compareTo(b.distanceMeters);
  }

  /// Score a suggestion's reliability from 0–100.
  int _computeConfidence({
    required bool hasPriceData,
    required double distanceMeters,
    required bool hasName,
  }) {
    int score = 30; // baseline: exists and is an OSM feature

    if (hasName) score += 20;
    if (distanceMeters < 200) {
      score += 25;
    } else if (distanceMeters < 500) {
      score += 20;
    } else if (distanceMeters < 1000) {
      score += 10;
    }

    if (hasPriceData) score += 25;

    return score.clamp(0, 100);
  }
}

/// Internal ranked suggestion helper.
class _RankedSuggestion {
  final OverpassPoiResult poi;
  final double distanceMeters;
  final double? estimatedSavings;
  final String basis;
  final int confidence;

  _RankedSuggestion({
    required this.poi,
    required this.distanceMeters,
    this.estimatedSavings,
    required this.basis,
    required this.confidence,
  });
}
