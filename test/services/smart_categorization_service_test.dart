import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/smart_categorization_service.dart';

void main() {
  group('SmartCategorizationService', () {
    late SmartCategorizationService service;

    setUp(() {
      service = SmartCategorizationService();
    });

    test('should suggest makanan for food-related descriptions', () async {
      final suggestions = await service.suggestCategory(
        description: 'makan bakso di warung',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'makanan');
      expect(suggestions.first['confidence'], greaterThan(0.3));
    });

    test('should suggest transportasi for ride-hailing descriptions', () async {
      final suggestions = await service.suggestCategory(
        description: 'gojek ke kantor',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'transportasi');
    });

    test('should suggest hiburan for streaming services', () async {
      final suggestions = await service.suggestCategory(
        description: 'bayar netflix bulanan',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'hiburan');
    });

    test('should suggest belanja for online shopping', () async {
      final suggestions = await service.suggestCategory(
        description: 'beli baju di shopee',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'belanja');
    });

    test('should suggest tagihan for utility bills', () async {
      final suggestions = await service.suggestCategory(
        description: 'bayar listrik pln',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'tagihan');
    });

    test('should suggest kesehatan for pharmacy purchases', () async {
      final suggestions = await service.suggestCategory(
        description: 'beli obat di apotek',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'kesehatan');
    });

    test('should suggest pendidikan for school fees', () async {
      final suggestions = await service.suggestCategory(
        description: 'bayar uang sekolah spp',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'pendidikan');
    });

    test('should return empty for unrecognized descriptions', () async {
      final suggestions = await service.suggestCategory(
        description: 'xyzqwerty',
      );

      expect(suggestions.isEmpty, true);
    });

    test(
      'should return multiple suggestions for ambiguous descriptions',
      () async {
        final suggestions = await service.suggestCategory(
          description: 'makan di mall belanja baju',
        );

        expect(suggestions.length, greaterThanOrEqualTo(2));
      },
    );

    test('should use merchant name for categorization', () async {
      final suggestions = await service.suggestCategory(
        description: '',
        merchant: 'kfc jakarta',
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first['category'], 'makanan');
    });

    test('predictBestCategory should return null for low confidence', () async {
      final result = await service.predictBestCategory(
        description: 'random text xyz',
      );

      expect(result, isNull);
    });

    test(
      'predictBestCategory should return category for high confidence',
      () async {
        final result = await service.predictBestCategory(
          description: 'beli nasi goreng di warung',
        );

        expect(result, 'makanan');
      },
    );
  });
}
