import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/error_handler_service.dart';

void main() {
  group('ErrorHandlerService.getUserFriendlyMessage', () {
    test('should return Indonesian message for network errors', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        'SocketException: Failed host lookup',
      );

      expect(
        message.toLowerCase().contains('koneksi') ||
            message.toLowerCase().contains('internet'),
        true,
      );
    });

    test('should return Indonesian message for timeout errors', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        'Connection timeout: server not responding',
      );

      expect(message.contains('timeout') || message.contains('mencoba'), true);
    });

    test('should return message for unauthorized access', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        '401 Unauthorized',
      );

      expect(message.contains('login') || message.contains('sesi'), true);
    });

    test('should return message for not authenticated', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        'Exception: Not authenticated',
      );

      expect(message.contains('login'), true);
    });

    test('should return message for forbidden access', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        '403 Forbidden',
      );

      expect(message.contains('izin'), true);
    });

    test('should return message for not found', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        '404 Not Found',
      );

      expect(message.contains('tidak ditemukan'), true);
    });

    test('should return message for validation errors', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        '422 Validation Error',
      );

      expect(message.contains('tidak valid'), true);
    });

    test('should return message for server errors', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        '500 Internal Server Error',
      );

      expect(
        message.toLowerCase().contains('server') || message.contains('coba'),
        true,
      );
    });

    test('should return message for service unavailable', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        '503 Service Unavailable',
      );

      expect(
        message.contains('tidak tersedia') || message.contains('mencoba'),
        true,
      );
    });

    test('should return default message for unknown errors', () {
      final message = ErrorHandlerService.getUserFriendlyMessage(
        'SomeRandomError: something went wrong',
      );

      expect(message.contains('kesalahan') || message.contains('coba'), true);
    });
  });
}
