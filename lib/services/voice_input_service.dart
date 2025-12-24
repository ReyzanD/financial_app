import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:financial_app/services/logger_service.dart';

/// Service untuk voice input functionality
class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          LoggerService.error('Speech recognition error', error: error);
        },
        onStatus: (status) {
          LoggerService.debug('Speech status: $status');
        },
      );
      return _isAvailable;
    } catch (e) {
      LoggerService.error('Error initializing speech recognition', error: e);
      return false;
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isAvailable;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Start listening untuk voice input
  Future<String?> startListening({
    String localeId = 'id_ID',
    Duration? listenDuration,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        return null;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    String? recognizedText;
    _isListening = true;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            recognizedText = result.recognizedWords;
            _isListening = false;
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation,
        pauseFor: listenDuration ?? const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      );

      // Wait for result
      if (listenDuration != null) {
        await Future.delayed(listenDuration);
        if (_isListening) {
          await stopListening();
        }
      }
    } catch (e) {
      LoggerService.error('Error during speech recognition', error: e);
      _isListening = false;
      return null;
    }

    return recognizedText;
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  /// Get available locales
  Future<List<dynamic>> getAvailableLocales() async {
    if (!_isAvailable) {
      await initialize();
    }
    return _speech.locales();
  }
}

