import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';
import 'package:local_auth/local_auth.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final PinAuthService _pinAuthService = PinAuthService();
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  String _pin = '';
  int _pinLength = 6;
  bool _isLoading = true;
  bool _isVerifying = false;
  int _remainingAttempts = 5;
  Duration? _lockDuration;
  Timer? _lockTimer;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final pinLength = await _pinAuthService.getPinLength();
      final remaining = await _pinAuthService.getRemainingAttempts();
      final lockTime = await _pinAuthService.getLockRemainingTime();

      // Check biometric availability
      final biometricAvailable = await _biometricService.isAvailable();
      final biometricEnabled = await _biometricService.isBiometricEnabled();

      setState(() {
        _pinLength = pinLength;
        _remainingAttempts = remaining;
        _lockDuration = lockTime;
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _isLoading = false;
      });

      if (_lockDuration != null) {
        _startLockTimer();
      } else if (_biometricAvailable && _biometricEnabled) {
        // Try biometric authentication automatically
        _tryBiometricAuth();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tryBiometricAuth() async {
    if (_lockDuration != null || _isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Autentikasi diperlukan untuk membuka aplikasi',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (authenticated && mounted) {
        // Biometric authentication successful, navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Biometric failed, user can use PIN instead
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _startLockTimer() {
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final lockTime = await _pinAuthService.getLockRemainingTime();

      if (lockTime == null) {
        timer.cancel();
        setState(() {
          _lockDuration = null;
          _remainingAttempts = 5;
        });
      } else {
        setState(() {
          _lockDuration = lockTime;
        });
      }
    });
  }

  void _onPinChanged(String pin) {
    setState(() {
      _pin = pin;
    });
  }

  Future<void> _onPinComplete() async {
    setState(() => _isVerifying = true);

    try {
      final isValid = await _pinAuthService.verifyPin(_pin);

      if (isValid) {
        // PIN is correct, navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // PIN is incorrect
        final remaining = await _pinAuthService.getRemainingAttempts();
        final lockTime = await _pinAuthService.getLockRemainingTime();

        if (mounted) {
          setState(() {
            _pin = '';
            _remainingAttempts = remaining;
            _lockDuration = lockTime;
          });

          if (lockTime != null) {
            _startLockTimer();
            ErrorHandlerService.showWarningSnackbar(
              context,
              'Terlalu banyak percobaan gagal. Tunggu ${_formatDuration(lockTime)}',
            );
          } else {
            ErrorHandlerService.showWarningSnackbar(
              context,
              'PIN salah. $remaining percobaan tersisa.',
            );
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error verifying PIN', error: e);
      if (mounted) {
        setState(() => _pin = '');
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit';
    } else {
      return '${duration.inSeconds} detik';
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Logout?',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              AppLocalizations.of(context)!.you_need_to_login_again,
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _pinAuthService.clearPin();
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // App Logo/Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5FBF).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.lock_1,
                  size: 60,
                  color: Color(0xFF8B5FBF),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                AppLocalizations.of(context)!.enter_pin,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                _lockDuration != null
                    ? '${AppLocalizations.of(context)!.wait} ${_formatDuration(_lockDuration!)}'
                    : AppLocalizations.of(context)!.enter_pin_to_unlock,
                style: GoogleFonts.poppins(
                  color:
                      _lockDuration != null
                          ? Colors.red[400]
                          : Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Biometric Authentication Button
              if (_biometricAvailable &&
                  _biometricEnabled &&
                  _lockDuration == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: FutureBuilder<List<BiometricType>>(
                    future: _biometricService.getAvailableBiometrics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      final biometrics = snapshot.data!;
                      final hasFingerprint = biometrics.contains(
                        BiometricType.fingerprint,
                      );
                      final hasFace = biometrics.contains(BiometricType.face);
                      final hasIris = biometrics.contains(BiometricType.iris);

                      IconData icon;
                      String label;

                      if (hasFace) {
                        icon = Iconsax.scan_barcode;
                        label = AppLocalizations.of(context)!.use_face_id;
                      } else if (hasFingerprint) {
                        icon = Iconsax.finger_scan;
                        label = AppLocalizations.of(context)!.use_fingerprint;
                      } else if (hasIris) {
                        icon = Iconsax.scan;
                        label = AppLocalizations.of(context)!.use_iris;
                      } else {
                        icon = Iconsax.scan_barcode;
                        label = AppLocalizations.of(context)!.use_biometric;
                      }

                      return ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _tryBiometricAuth,
                        icon: Icon(icon, size: 20),
                        label: Text(label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5FBF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // PIN Pad (disabled if locked)
              IgnorePointer(
                ignoring: _lockDuration != null || _isVerifying,
                child: Opacity(
                  opacity: _lockDuration != null ? 0.4 : 1.0,
                  child: PinPad(
                    pin: _pin,
                    pinLength: _pinLength,
                    onPinChanged: _onPinChanged,
                    onComplete: _onPinComplete,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Remaining Attempts
              if (_remainingAttempts < 5 && _lockDuration == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.warning_2,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_remainingAttempts percobaan tersisa',
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Forgot PIN / Logout
              TextButton(
                onPressed: _logout,
                child: Text(
                  AppLocalizations.of(context)!.forgot_pin_logout,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B5FBF),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
