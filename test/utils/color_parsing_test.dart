import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:financial_app/utils/formatters.dart';

void main() {
  group('ColorParsing', () {
    test('parses #RRGGBB', () {
      final c = ColorParsing.parse('#3498db');
      expect(c.value, 0xFF3498DB);
    });

    test('parses RRGGBB without hash', () {
      final c = ColorParsing.parse('3498db');
      expect(c.value, 0xFF3498DB);
    });

    test('parses 0xFF prefixed', () {
      final c = ColorParsing.parse('0xFF3498DB');
      expect(c.value, 0xFF3498DB);
    });

    test('parses AARRGGBB', () {
      final c = ColorParsing.parse('FF3498DB');
      expect(c.value, 0xFF3498DB);
    });

    test('returns fallback on null', () {
      final c = ColorParsing.parse(null, fallback: Colors.red);
      expect(c, Colors.red);
    });

    test('returns fallback on empty', () {
      final c = ColorParsing.parse('', fallback: Colors.red);
      expect(c, Colors.red);
    });

    test('returns fallback on malformed (non-hex)', () {
      final c = ColorParsing.parse('not-a-color', fallback: Colors.red);
      expect(c, Colors.red);
    });

    test('returns fallback on wrong length', () {
      final c = ColorParsing.parse('#12', fallback: Colors.red);
      expect(c, Colors.red);
    });

    test('returns fallback on "null" string', () {
      final c = ColorParsing.parse('null', fallback: Colors.red);
      expect(c, Colors.red);
    });
  });
}
