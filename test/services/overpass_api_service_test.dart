import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/overpass_api_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/services/api_security_service.dart';
import 'package:financial_app/services/osm_category_mapping_service.dart';

/// Fake NetworkService with controllable online state.
class _FakeNetwork extends NetworkService {
  final bool online;
  _FakeNetwork(this.online) : super.forTest(online: online);
}

/// Fake ApiSecurityService with controllable rate-limit decision.
class _FakeSecurity extends ApiSecurityService {
  bool allow;
  int calls = 0;
  _FakeSecurity(this.allow);

  @override
  Future<bool> checkRateLimit(String endpoint) async {
    calls++;
    return allow;
  }
}

void main() {
  group('OverpassApiService network gating', () {
    setUp(() => OverpassApiService.clearCache());

    test('returns empty list when offline (no network call)', () async {
      final service = OverpassApiService(
        mappingService: OsmCategoryMappingService(),
        networkService: _FakeNetwork(false),
        apiSecurityService: _FakeSecurity(true),
      );

      final result = await service.findNearbyPois(
        latitude: -5.0,
        longitude: 119.0,
        categoryName: 'Makanan & Minuman',
      );

      expect(result, isEmpty);
    });

    test('returns empty list when rate limit exceeded', () async {
      final service = OverpassApiService(
        mappingService: OsmCategoryMappingService(),
        networkService: _FakeNetwork(true),
        apiSecurityService: _FakeSecurity(false),
      );

      final result = await service.findNearbyPois(
        latitude: -5.0,
        longitude: 119.0,
        categoryName: 'Makanan & Minuman',
      );

      expect(result, isEmpty);
    });
  });
}
