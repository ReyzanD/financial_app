import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/logger_service.dart';

void main() {
  group('LoggerService', () {
    test('debug should not throw', () {
      expect(() => LoggerService.debug('Test debug message'), returnsNormally);
    });

    test('debug should not throw with error and stackTrace', () {
      expect(
        () => LoggerService.debug(
          'Test debug message',
          error: Exception('test error'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('info should not throw', () {
      expect(() => LoggerService.info('Test info message'), returnsNormally);
    });

    test('success should not throw', () {
      expect(
        () => LoggerService.success('Test success message'),
        returnsNormally,
      );
    });

    test('warning should not throw', () {
      expect(
        () => LoggerService.warning('Test warning message'),
        returnsNormally,
      );
    });

    test('warning should not throw with error', () {
      expect(
        () => LoggerService.warning(
          'Test warning message',
          error: Exception('test error'),
        ),
        returnsNormally,
      );
    });

    test('error should not throw', () {
      expect(() => LoggerService.error('Test error message'), returnsNormally);
    });

    test('error should not throw with error and stackTrace', () {
      expect(
        () => LoggerService.error(
          'Test error message',
          error: Exception('test error'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('apiRequest should not throw', () {
      expect(
        () => LoggerService.apiRequest('GET', '/api/test'),
        returnsNormally,
      );
    });

    test('apiResponse should not throw for success status', () {
      expect(
        () => LoggerService.apiResponse(200, '/api/test'),
        returnsNormally,
      );
    });

    test('apiResponse should not throw for error status', () {
      expect(
        () => LoggerService.apiResponse(500, '/api/test'),
        returnsNormally,
      );
    });

    test('apiResponse should not throw for 404 status', () {
      expect(
        () => LoggerService.apiResponse(404, '/api/test'),
        returnsNormally,
      );
    });

    test('cache should not throw', () {
      expect(() => LoggerService.cache('HIT', 'test_key'), returnsNormally);
    });
  });
}
