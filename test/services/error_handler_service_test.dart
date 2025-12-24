import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/error_handler_service.dart';

void main() {
  group('ErrorHandlerService', () {
    group('getUserFriendlyMessage', () {
      test('should return user-friendly message for network errors', () {
        final error = Exception('SocketException: Failed host lookup');
        final message = ErrorHandlerService.getUserFriendlyMessage(error);

        expect(message, contains('internet'));
        expect(message, isNot(contains('SocketException')));
      });

      test('should return user-friendly message for timeout errors', () {
        final error = Exception('TimeoutException: Connection timeout');
        final message = ErrorHandlerService.getUserFriendlyMessage(error);

        expect(message.toLowerCase(), contains('timeout'));
      });

      test('should return user-friendly message for server errors', () {
        final error = Exception('500 Internal Server Error');
        final message = ErrorHandlerService.getUserFriendlyMessage(error);

        // The error handler checks for '500' or 'internal server error' in lowercase
        expect(message.toLowerCase(), contains('server'));
      });

      test('should return user-friendly message for unauthorized errors', () {
        final error = Exception('Unauthorized - Please login again');
        final message = ErrorHandlerService.getUserFriendlyMessage(error);

        expect(message.toLowerCase(), contains('login'));
      });

      test('should return generic message for unknown errors', () {
        final error = Exception('Unknown error');
        final message = ErrorHandlerService.getUserFriendlyMessage(error);

        expect(message, isNotEmpty);
        expect(message, isNot(contains('Unknown error')));
      });
    });
  });
}

