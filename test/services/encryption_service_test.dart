import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests the core AES-256 encryption logic that EncryptionService relies on,
/// without depending on FlutterSecureStorage (which requires a platform impl).
///
/// The real EncryptionService wraps this same logic with key persistence via
/// FlutterSecureStorage. The critical security fix tested here is:
/// **each encrypt() call uses a fresh random IV**, not a single global IV.
void main() {
  // Generate a one-time AES-256 key (same approach as EncryptionService)
  late Key key;
  late Encrypter encrypter;

  setUp(() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    key = Key(keyBytes);
    encrypter = Encrypter(AES(key));
  });

  Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// Simulates the fixed EncryptionService.encrypt():
  /// fresh IV per call, prepended to ciphertext, base64-encoded.
  String _encrypt(String data) {
    final iv = IV(_generateIV());
    final encrypted = encrypter.encrypt(data, iv: iv);
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64Encode(combined);
  }

  /// Simulates the fixed EncryptionService.decrypt():
  /// extracts IV from first 16 bytes, decodes rest as ciphertext.
  String _decrypt(String encoded) {
    final combined = base64Decode(encoded);
    final iv = IV(combined.sublist(0, 16));
    final cipher = Encrypted(combined.sublist(16));
    return encrypter.decrypt(cipher, iv: iv);
  }

  group('AES-256 with per-call IV (IV reuse fix)', () {
    test('should encrypt and decrypt correctly', () {
      const plaintext = 'Hello, World!';
      final encrypted = _encrypt(plaintext);
      final decrypted = _decrypt(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('should produce different ciphertext each time (IV reuse fix)', () {
      const plaintext = 'same data every time';

      final results = <String>{};
      for (int i = 0; i < 10; i++) {
        results.add(_encrypt(plaintext));
      }

      // All 10 encryptions of the same plaintext must be unique
      expect(results.length, equals(10));
    });

    test('should handle long strings', () {
      final plaintext = 'A' * 10000;
      final encrypted = _encrypt(plaintext);
      final decrypted = _decrypt(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('should handle unicode and special characters', () {
      const plaintext = '🔥 Flutter 💙 AES-256 ✅';
      final encrypted = _encrypt(plaintext);
      final decrypted = _decrypt(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('should throw on corrupted ciphertext', () {
      const plaintext = 'test data';
      final encrypted = _encrypt(plaintext);
      final corrupted =
          encrypted.substring(0, encrypted.length ~/ 2) +
          'INVALID' +
          encrypted.substring(encrypted.length ~/ 2);

      expect(() => _decrypt(corrupted), throwsException);
    });

    test('should throw on data too short to contain IV', () {
      expect(() => _decrypt('AA=='), throwsA(isA<RangeError>()));
    });

    test('should produce valid ciphertext that includes IV bytes', () {
      const plaintext = 'hello';
      final encrypted = _encrypt(plaintext);
      final decoded = base64Decode(encrypted);

      // Must have at least 16 bytes (IV) + some ciphertext
      expect(decoded.length, greaterThan(16));
    });

    test('should not decrypt with wrong key', () {
      const plaintext = 'secret';

      // Encrypt with one key
      final encrypted = _encrypt(plaintext);

      // Try to decrypt with a different key
      final random = Random.secure();
      final wrongKeyBytes = Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      final wrongEncrypter = Encrypter(AES(Key(wrongKeyBytes)));

      final combined = base64Decode(encrypted);
      final iv = IV(combined.sublist(0, 16));
      final cipher = Encrypted(combined.sublist(16));

      expect(
        () => wrongEncrypter.decrypt(cipher, iv: iv),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should support SHA-256 hashing (same as EncryptionService)', () {
      const data = 'sensitive-pin-1234';
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes).toString();

      expect(hash.length, equals(64));
      expect(sha256.convert(utf8.encode(data)).toString(), equals(hash));
      expect(
        sha256.convert(utf8.encode('wrong-data')).toString(),
        isNot(equals(hash)),
      );
    });
  });
}
