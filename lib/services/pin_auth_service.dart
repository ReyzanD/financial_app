import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinAuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _pinKey = 'user_pin';
  static const String _pinLengthKey = 'pin_length';
  static const String _hasPinKey = 'has_pin';
  static const String _pinCreatedAtKey = 'pin_created_at';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockUntilKey = 'lock_until';
  static const String _lastUnlockKey = 'last_unlock';

  // Salt for PIN hashing (in production, use a more secure salt)
  static const String _salt = 'FinancialApp_SecureSalt_2024';

  /// Check if user has set up a PIN
  Future<bool> hasPin() async {
    final hasPin = await _secureStorage.read(key: _hasPinKey);
    return hasPin == 'true';
  }

  /// Get PIN length (4 or 6)
  Future<int> getPinLength() async {
    final length = await _secureStorage.read(key: _pinLengthKey);
    return int.tryParse(length ?? '6') ?? 6;
  }

  /// Create new PIN (first-time setup)
  Future<void> createPin(String pin) async {
    if (pin.length != 4 && pin.length != 6) {
      throw Exception('PIN must be 4 or 6 digits');
    }

    if (!_isNumeric(pin)) {
      throw Exception('PIN must contain only numbers');
    }

    final hashedPin = _hashPin(pin);
    final now = DateTime.now().toIso8601String();

    await _secureStorage.write(key: _pinKey, value: hashedPin);
    await _secureStorage.write(
      key: _pinLengthKey,
      value: pin.length.toString(),
    );
    await _secureStorage.write(key: _hasPinKey, value: 'true');
    await _secureStorage.write(key: _pinCreatedAtKey, value: now);
    await _secureStorage.write(key: _failedAttemptsKey, value: '0');
  }

  /// Verify PIN for unlock
  Future<bool> verifyPin(String pin) async {
    // Check if app is locked
    if (await _isLocked()) {
      throw Exception('Too many failed attempts. Please wait.');
    }

    final storedPin = await _secureStorage.read(key: _pinKey);
    if (storedPin == null) {
      throw Exception('No PIN set');
    }

    final hashedPin = _hashPin(pin);
    final isValid = hashedPin == storedPin;

    if (isValid) {
      // Reset failed attempts and update last unlock
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      await _secureStorage.write(
        key: _lastUnlockKey,
        value: DateTime.now().toIso8601String(),
      );
      return true;
    } else {
      // Increment failed attempts
      await _incrementFailedAttempts();
      return false;
    }
  }

  /// Update PIN (change existing PIN)
  Future<void> updatePin(String oldPin, String newPin) async {
    // Verify old PIN first
    final isOldPinValid = await verifyPin(oldPin);
    if (!isOldPinValid) {
      throw Exception('Current PIN is incorrect');
    }

    // Create new PIN
    await createPin(newPin);
  }

  /// Clear PIN (on logout)
  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _pinLengthKey);
    await _secureStorage.delete(key: _hasPinKey);
    await _secureStorage.delete(key: _pinCreatedAtKey);
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockUntilKey);
    await _secureStorage.delete(key: _lastUnlockKey);
  }

  /// Get failed attempts count
  Future<int> getFailedAttempts() async {
    final attempts = await _secureStorage.read(key: _failedAttemptsKey);
    return int.tryParse(attempts ?? '0') ?? 0;
  }

  /// Get remaining attempts before lock
  Future<int> getRemainingAttempts() async {
    final failed = await getFailedAttempts();
    return 5 - failed; // Max 5 attempts
  }

  /// Check if app is locked due to failed attempts
  Future<bool> _isLocked() async {
    final lockUntilStr = await _secureStorage.read(key: _lockUntilKey);
    if (lockUntilStr == null) return false;

    final lockUntil = DateTime.parse(lockUntilStr);
    final now = DateTime.now();

    if (now.isBefore(lockUntil)) {
      return true;
    } else {
      // Lock expired, clear it
      await _secureStorage.delete(key: _lockUntilKey);
      await _secureStorage.write(key: _failedAttemptsKey, value: '0');
      return false;
    }
  }

  /// Get lock remaining time
  Future<Duration?> getLockRemainingTime() async {
    final lockUntilStr = await _secureStorage.read(key: _lockUntilKey);
    if (lockUntilStr == null) return null;

    final lockUntil = DateTime.parse(lockUntilStr);
    final now = DateTime.now();

    if (now.isBefore(lockUntil)) {
      return lockUntil.difference(now);
    }
    return null;
  }

  /// Increment failed attempts and lock if needed
  Future<void> _incrementFailedAttempts() async {
    final attempts = await getFailedAttempts();
    final newAttempts = attempts + 1;

    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: newAttempts.toString(),
    );

    // Lock for 30 seconds after 3 attempts
    if (newAttempts >= 3 && newAttempts < 5) {
      final lockUntil = DateTime.now().add(const Duration(seconds: 30));
      await _secureStorage.write(
        key: _lockUntilKey,
        value: lockUntil.toIso8601String(),
      );
    }
    // Lock for 5 minutes after 5 attempts
    else if (newAttempts >= 5) {
      final lockUntil = DateTime.now().add(const Duration(minutes: 5));
      await _secureStorage.write(
        key: _lockUntilKey,
        value: lockUntil.toIso8601String(),
      );
    }
  }

  /// Hash PIN with salt
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if string is numeric
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  /// Check if PIN needs refresh (older than 90 days)
  Future<bool> needsPinRefresh() async {
    final createdAtStr = await _secureStorage.read(key: _pinCreatedAtKey);
    if (createdAtStr == null) return false;

    final createdAt = DateTime.parse(createdAtStr);
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;

    return daysSinceCreation > 90;
  }

  /// Get last unlock time
  Future<DateTime?> getLastUnlockTime() async {
    final lastUnlockStr = await _secureStorage.read(key: _lastUnlockKey);
    if (lastUnlockStr == null) return null;
    return DateTime.parse(lastUnlockStr);
  }

  /// Check if should auto-lock (based on inactivity)
  Future<bool> shouldAutoLock({
    Duration inactivityTimeout = const Duration(minutes: 5),
  }) async {
    final lastUnlock = await getLastUnlockTime();
    if (lastUnlock == null) return true;

    final inactiveDuration = DateTime.now().difference(lastUnlock);
    return inactiveDuration > inactivityTimeout;
  }
}
