import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/models/place_visit.dart';
import 'package:financial_app/models/price_observation.dart';
import 'package:financial_app/services/alternative_recommendation_engine.dart';
import 'package:financial_app/services/data/alternative_suggestion_data_service.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/price_observation_data_service.dart';
import 'package:financial_app/services/overpass_api_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/services/api_security_service.dart';

/// Fake NetworkService (always online for engine tests).
class _FakeNetwork extends NetworkService {
  _FakeNetwork() : super.forTest(online: true);
}

/// Fake ApiSecurityService (always allows for engine tests).
class _FakeSecurity extends ApiSecurityService {
  _FakeSecurity() : super();
  @override
  Future<bool> checkRateLimit(String endpoint) async => true;
}

/// Manual mock of OverpassApiService that returns a fixed set of POIs.
class _FakeOverpass extends OverpassApiService {
  final List<OverpassPoiResult> pois;
  _FakeOverpass(this.pois)
    : super(
        networkService: _FakeNetwork(),
        apiSecurityService: _FakeSecurity(),
      );

  @override
  Future<List<OverpassPoiResult>> findNearbyPois({
    required double latitude,
    required double longitude,
    required String categoryName,
    int radiusMeters = 1000,
    int maxResults = 10,
    bool forceRefresh = false,
  }) async => pois;
}

/// Manual mock that records persisted suggestions and reports freshness.
class _FakeSuggestionStore extends AlternativeSuggestionDataService {
  List<AlternativeSuggestion> lastSaved = [];
  bool fresh = false;

  @override
  Future<bool> hasFreshSuggestions(
    String originPlaceVisitId, {
    int maxAgeHours = 24,
  }) async => fresh;

  @override
  Future<List<AlternativeSuggestion>> getForOriginPlace(
    String originPlaceVisitId,
  ) async => lastSaved;

  @override
  Future<void> saveSuggestions(List<AlternativeSuggestion> suggestions) async =>
      lastSaved = suggestions;
}

/// Manual mock of PriceObservationDataService with injectable median + known prices.
class _FakePriceStore extends PriceObservationDataService {
  final double? median;
  final List<PriceObservation> known;
  _FakePriceStore({this.median, this.known = const []});

  @override
  Future<double?> getMedianPriceForCategory(
    String category, {
    int minObservations = 3,
  }) async => median;

  @override
  Future<List<PriceObservation>> getPriceObservations({
    String? placeVisitId,
    String? category,
  }) async => known;
}

/// Manual mock of PlaceVisitDataService that resolves a place visit by id,
/// mapping the known-price observation ids to pvs whose name matches the POI.
class _FakePlaceVisitStore extends PlaceVisitDataService {
  final Map<String, PlaceVisit> byId;
  _FakePlaceVisitStore(this.byId);

  @override
  Future<PlaceVisit?> getPlaceVisit(String id) async => byId[id];
}

OverpassPoiResult _poi(String name, double lat, double lng) =>
    OverpassPoiResult(
      osmId: name,
      osmType: 'node',
      name: name,
      latitude: lat,
      longitude: lng,
    );

PlaceVisit _pv(String id, String name) => PlaceVisit(
  id: id,
  placeName: name,
  latitude: 0,
  longitude: 0,
  category: 'Makanan & Minuman',
  firstVisit: DateTime.now(),
  lastVisit: DateTime.now(),
);

void main() {
  group('AlternativeRecommendationEngine ranking', () {
    setUp(() => OverpassApiService.clearCache());

    final origin = PlaceVisit(
      id: 'origin',
      placeName: 'Origin Cafe',
      latitude: -5.0,
      longitude: 119.0,
      category: 'Makanan & Minuman',
      visitCount: 1,
      totalSpent: 10000,
      firstVisit: DateTime.now(),
      lastVisit: DateTime.now(),
    );

    test(
      'ranks by distance when no price data exists (distance-only basis)',
      () async {
        final near = _poi('Near', -5.0001, 119.0);
        final mid = _poi('Mid', -5.001, 119.0);
        final far = _poi('Far', -5.01, 119.0);
        final engine = AlternativeRecommendationEngine(
          overpassApiService: _FakeOverpass([far, mid, near]),
          priceObservationDataService: _FakePriceStore(median: null),
          placeVisitDataService: _FakePlaceVisitStore({}),
          alternativeSuggestionDataService: _FakeSuggestionStore(),
        );

        final results = await engine.getAlternativesForPlace(origin);

        expect(results.length, 3);
        expect(results[0].suggestedPlaceName, 'Near');
        expect(results[1].suggestedPlaceName, 'Mid');
        expect(results[2].suggestedPlaceName, 'Far');
        expect(results.every((r) => r.basis == 'distance_only'), isTrue);
      },
    );

    test(
      'price-based suggestions rank above distance-only, then by savings',
      () async {
        final cheap = _poi('CheapAlt', -5.001, 119.0);
        final pricey = _poi('PriceyAlt', -5.0001, 119.0);
        final near = _poi('NearNoPrice', -5.00005, 119.0);
        final far = _poi('FarNoPrice', -5.02, 119.0);

        final known = [
          PriceObservation(
            id: 'p1',
            placeVisitId: 'pv_cheap',
            category: 'Makanan & Minuman',
            price: 5000,
            observedAt: DateTime.now(),
            source: 'self_reported',
            createdAt: DateTime.now(),
          ),
          PriceObservation(
            id: 'p2',
            placeVisitId: 'pv_pricey',
            category: 'Makanan & Minuman',
            price: 9000,
            observedAt: DateTime.now(),
            source: 'self_reported',
            createdAt: DateTime.now(),
          ),
        ];

        final engine = AlternativeRecommendationEngine(
          overpassApiService: _FakeOverpass([near, far, cheap, pricey]),
          priceObservationDataService: _FakePriceStore(
            median: null,
            known: known,
          ),
          placeVisitDataService: _FakePlaceVisitStore({
            'pv_cheap': _pv('pv_cheap', 'CheapAlt'),
            'pv_pricey': _pv('pv_pricey', 'PriceyAlt'),
          }),
          alternativeSuggestionDataService: _FakeSuggestionStore(),
        );

        final results = await engine.getAlternativesForPlace(origin);

        expect(results[0].suggestedPlaceName, 'CheapAlt');
        expect(results[0].basis, 'price');
        expect(results[1].suggestedPlaceName, 'PriceyAlt');
        expect(results[1].basis, 'price');
        expect(results[2].suggestedPlaceName, 'NearNoPrice');
        expect(results[3].suggestedPlaceName, 'FarNoPrice');

        // Observation count (2 known price reports) is propagated to every
        // suggestion so the "based on N reports" honesty signal is persisted.
        expect(results[0].observationCount, 2);
        expect(results[2].observationCount, 2);
      },
    );
  });
}
