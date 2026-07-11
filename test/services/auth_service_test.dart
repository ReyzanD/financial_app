import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    group('isValidTokenFormat', () {
      test('should return true for valid UUID format', () {
        const validToken = '550e8400-e29b-41d4-a716-446655440000';
        expect(authService.isValidTokenFormat(validToken), isTrue);
      });

      test('should return false for null token', () {
        expect(authService.isValidTokenFormat(null), isFalse);
      });

      test('should return false for empty token', () {
        expect(authService.isValidTokenFormat(''), isFalse);
      });

      test('should return false for token that is too short', () {
        expect(authService.isValidTokenFormat('short'), isFalse);
      });

      test('should return false for token that is too long', () {
        expect(
          authService.isValidTokenFormat(
            '550e8400-e29b-41d4-a716-446655440000-extra',
          ),
          isFalse,
        );
      });

      test('should return false for token without hyphens', () {
        expect(
          authService.isValidTokenFormat('550e8400e29b41d4a716446655440000'),
          isFalse,
        );
      });
    });
  });
}
