import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk encrypt/decrypt sensitive data
/// Menggunakan AES-256 encryption dengan secure key storage
class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const String _ivStorageKey = 'encryption_iv';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  Key? _encryptionKey;
  IV? _encryptionIV;
  Encrypter? _encrypter;

  // Singleton pattern
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Initialize encryption service
  /// Generate atau load encryption key dan IV
  Future<void> initialize() async {
    try {
      final existingKey = await _secureStorage.read(key: _keyStorageKey);
      final existingIV = await _secureStorage.read(key: _ivStorageKey);
      
      if (existingKey == null || existingIV == null) {
        // Generate new key and IV
        final key = _generateAESKey();
        final iv = _generateIV();
        
        await _secureStorage.write(key: _keyStorageKey, value: key.base64);
        await _secureStorage.write(key: _ivStorageKey, value: iv.base64);
        
        _encryptionKey = key;
        _encryptionIV = iv;
        _encrypter = Encrypter(AES(key));
        
        LoggerService.success('[EncryptionService] New AES-256 encryption key generated');
      } else {
        // Load existing key and IV
        _encryptionKey = Key.fromBase64(existingKey);
        _encryptionIV = IV.fromBase64(existingIV);
        _encrypter = Encrypter(AES(_encryptionKey!));
        
        LoggerService.debug('[EncryptionService] AES-256 encryption key loaded');
      }
    } catch (e) {
      LoggerService.error(
        '[EncryptionService] Error initializing encryption',
        error: e,
      );
      rethrow;
    }
  }

  /// Generate AES-256 key (32 bytes = 256 bits)
  Key _generateAESKey() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    return Key(keyBytes);
  }

  /// Generate IV (Initialization Vector) - 16 bytes for AES
  IV _generateIV() {
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return IV(ivBytes);
  }

  /// Get encryption key (ensure initialized)
  Future<void> _ensureInitialized() async {
    if (_encrypter == null || _encryptionKey == null || _encryptionIV == null) {
      await initialize();
    }
  }

  /// Encrypt string data menggunakan AES-256
  Future<String> encrypt(String data) async {
    try {
      await _ensureInitialized();
      
      if (_encrypter == null || _encryptionIV == null) {
        throw Exception('Encryption not initialized');
      }

      final encrypted = _encrypter!.encrypt(data, iv: _encryptionIV!);
      final encryptedBase64 = encrypted.base64;
      
      LoggerService.debug('[EncryptionService] Data encrypted using AES-256 (length: ${encryptedBase64.length})');
      return encryptedBase64;
    } catch (e) {
      LoggerService.error('[EncryptionService] Encryption failed', error: e);
      rethrow;
    }
  }

  /// Decrypt string data menggunakan AES-256
  Future<String> decrypt(String encryptedData) async {
    try {
      await _ensureInitialized();
      
      if (_encrypter == null || _encryptionIV == null) {
        throw Exception('Encryption not initialized');
      }

      final encrypted = Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter!.decrypt(encrypted, iv: _encryptionIV!);
      
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
      await _secureStorage.delete(key: _ivStorageKey);
      
      _encryptionKey = null;
      _encryptionIV = null;
      _encrypter = null;
      
      LoggerService.info('[EncryptionService] AES-256 encryption keys cleared');
    } catch (e) {
      LoggerService.error('[EncryptionService] Error clearing keys', error: e);
    }
  }

  /// Check if encryption is available
  Future<bool> isEncryptionAvailable() async {
    try {
      await _ensureInitialized();
      return _encrypter != null && _encryptionKey != null && _encryptionIV != null;
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
      return {
        'data': encrypted,
        'algorithm': 'AES-256',
        'timestamp': DateTime.now().toIso8601String(),
      };
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

