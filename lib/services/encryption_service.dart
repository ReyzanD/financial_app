import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk encrypt/decrypt sensitive data
/// Menggunakan AES-256 encryption dengan secure key storage
///
/// Security notes:
/// - A fresh random IV is generated per encrypt() call and prepended to the
///   ciphertext, so each encryption of the same plaintext produces different
///   output. The stored format is: base64(16-byte-IV || ciphertext)
/// - The AES key itself is stored in FlutterSecureStorage (platform keychain).
/// - The per-record IV is embedded in the ciphertext, not stored separately.
class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const int _ivLengthBytes = 16; // AES-CBC block size
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Key? _encryptionKey;
  Encrypter? _encrypter;

  // Singleton pattern
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Initialize encryption service
  /// Generate atau load encryption key
  Future<void> initialize() async {
    try {
      final existingKey = await _secureStorage.read(key: _keyStorageKey);

      if (existingKey == null) {
        // Generate new key
        final key = _generateAESKey();

        await _secureStorage.write(key: _keyStorageKey, value: key.base64);

        _encryptionKey = key;
        _encrypter = Encrypter(AES(key));

        LoggerService.success('[EncryptionService] New AES-256 encryption key generated');
      } else {
        // Load existing key
        _encryptionKey = Key.fromBase64(existingKey);
        _encrypter = Encrypter(AES(_encryptionKey!));

        LoggerService.debug('[EncryptionService] AES-256 encryption key loaded');
      }
    } catch (e) {
      LoggerService.error('[EncryptionService] Error initializing encryption', error: e);
      rethrow;
    }
  }

  /// Generate AES-256 key (32 bytes = 256 bits)
  Key _generateAESKey() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
    return Key(keyBytes);
  }

  /// Generate a fresh random IV (Initialization Vector) — 16 bytes for AES-CBC
  Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(_ivLengthBytes, (_) => random.nextInt(256)));
  }

  /// Get encryption key (ensure initialized)
  Future<void> _ensureInitialized() async {
    if (_encrypter == null || _encryptionKey == null) {
      await initialize();
    }
  }

  /// Encrypt string data using AES-256 with a fresh random IV per call.
  ///
  /// The returned string is base64(16-byte-IV || ciphertext). Each call
  /// produces different output even for the same plaintext.
  Future<String> encrypt(String data) async {
    try {
      await _ensureInitialized();

      if (_encrypter == null) {
        throw Exception('Encryption not initialized');
      }

      // Generate a fresh IV for this encryption
      final ivBytes = _generateIV();
      final iv = IV(ivBytes);

      final encrypted = _encrypter!.encrypt(data, iv: iv);

      // Prepend IV bytes to ciphertext bytes, then base64-encode the result
      final combined = Uint8List.fromList([...ivBytes, ...encrypted.bytes]);
      final combinedBase64 = base64Encode(combined);

      LoggerService.debug('[EncryptionService] Data encrypted using AES-256 (length: ${combinedBase64.length})');
      return combinedBase64;
    } catch (e) {
      LoggerService.error('[EncryptionService] Encryption failed', error: e);
      rethrow;
    }
  }

  /// Decrypt string data that was encrypted by [encrypt].
  ///
  /// Expects input format: base64(16-byte-IV || ciphertext).
  Future<String> decrypt(String encryptedData) async {
    try {
      await _ensureInitialized();

      if (_encrypter == null) {
        throw Exception('Encryption not initialized');
      }

      final combined = base64Decode(encryptedData);

      if (combined.length < _ivLengthBytes) {
        throw FormatException('Encrypted data too short (missing IV)');
      }

      // First 16 bytes are the IV, the rest is the ciphertext
      final ivBytes = combined.sublist(0, _ivLengthBytes);
      final cipherBytes = combined.sublist(_ivLengthBytes);

      final iv = IV(ivBytes);
      final encrypted = Encrypted(cipherBytes);
      final decrypted = _encrypter!.decrypt(encrypted, iv: iv);

      LoggerService.debug('[EncryptionService] Data decrypted using AES-256');
      return decrypted;
    } catch (e) {
      LoggerService.error('[EncryptionService] Decryption failed', error: e);
      rethrow;
    }
  }

  /// Encrypt JSON data
  Future<String> encryptJson(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return await encrypt(jsonString);
  }

  /// Decrypt JSON data
  Future<Map<String, dynamic>> decryptJson(String encryptedData) async {
    final jsonString = await decrypt(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Hash sensitive data (one-way, for comparison)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify hashed data
  bool verifyHash(String data, String hash) {
    return hashData(data) == hash;
  }

  /// Clear encryption key (for logout)
  /// Note: This will make all encrypted data unreadable
  Future<void> clearKey() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);

      _encryptionKey = null;
      _encrypter = null;

      LoggerService.info('[EncryptionService] AES-256 encryption key cleared');
    } catch (e) {
      LoggerService.error('[EncryptionService] Error clearing keys', error: e);
    }
  }

  /// Check if encryption is available
  Future<bool> isEncryptionAvailable() async {
    try {
      await _ensureInitialized();
      return _encrypter != null && _encryptionKey != null;
    } catch (e) {
      LoggerService.error('[EncryptionService] Error checking availability', error: e);
      return false;
    }
  }

  /// Encrypt sensitive data for database storage
  /// Returns encrypted data with metadata
  Future<Map<String, String>> encryptForStorage(String data) async {
    try {
      final encrypted = await encrypt(data);
      return {'data': encrypted, 'algorithm': 'AES-256', 'timestamp': DateTime.now().toIso8601String()};
    } catch (e) {
      LoggerService.error('[EncryptionService] Error encrypting for storage', error: e);
      rethrow;
    }
  }

  /// Decrypt data from storage
  Future<String> decryptFromStorage(Map<String, dynamic> encryptedData) async {
    try {
      final data = encryptedData['data'] as String;
      return await decrypt(data);
    } catch (e) {
      LoggerService.error('[EncryptionService] Error decrypting from storage', error: e);
      rethrow;
    }
  }

  /// Secure data wiping (overwrite with random data)
  /// Note: This is a best-effort approach. True secure deletion requires OS-level support
  String secureWipe(String data) {
    final random = Random.secure();
    final randomData = List<int>.generate(data.length, (_) => random.nextInt(256));
    return String.fromCharCodes(randomData);
  }
}
