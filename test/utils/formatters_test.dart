import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/utils/formatters.dart';

void main() {
  group('CurrencyFormatter', () {
    test('should format zero amount correctly', () {
      final result = CurrencyFormatter.formatRupiah(0);
      expect(result, 'Rp 0');
    });

    test('should format small amounts correctly', () {
      final result = CurrencyFormatter.formatRupiah(1000);
      expect(result, 'Rp 1.000');
    });

    test('should format medium amounts with thousand separators', () {
      final result = CurrencyFormatter.formatRupiah(1000000);
      expect(result, 'Rp 1.000.000');
    });

    test('should format large amounts correctly', () {
      final result = CurrencyFormatter.formatRupiah(1000000000);
      expect(result, 'Rp 1.000.000.000');
    });

    test('should format amounts with decimals by truncating', () {
      final result = CurrencyFormatter.formatRupiah(50000.50);
      expect(result, 'Rp 50.001');
    });

    test('should format negative amounts correctly', () {
      final result = CurrencyFormatter.formatRupiah(-50000);
      expect(result.contains('-'), true);
      expect(result.contains('50.000'), true);
    });

    test('should include Rp prefix', () {
      final result = CurrencyFormatter.formatRupiah(100000);
      expect(result.startsWith('Rp'), true);
    });

    test('should handle typical transaction amounts', () {
      expect(CurrencyFormatter.formatRupiah(15000), 'Rp 15.000');
      expect(CurrencyFormatter.formatRupiah(250000), 'Rp 250.000');
      expect(CurrencyFormatter.formatRupiah(5000000), 'Rp 5.000.000');
    });
  });
}
