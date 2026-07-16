import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
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
    final ctrl = context.read<AuthController>();
    try {
      final pinLength = await ctrl.getPinLength();
      final remaining = await ctrl.getRemainingAttempts();
      final lockTime = await ctrl.getLockRemainingTime();
      final bioAvail = await ctrl.biometricAvailable;
      final bioEnabled = await ctrl.biometricEnabled;
      setState(() {
        _pinLength = pinLength;
        _remainingAttempts = remaining;
        _lockDuration = lockTime;
        _biometricAvailable = bioAvail;
        _biometricEnabled = bioEnabled;
        _isLoading = false;
      });
      if (_lockDuration != null) {
        _startLockTimer();
      } else if (_biometricAvailable && _biometricEnabled) {
        _tryBiometricAuth();
      }
    } catch (e) {
      LoggerService.error('Error initializing PIN unlock', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tryBiometricAuth() async {
    if (_lockDuration != null || _isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      final authenticated = await context.read<AuthController>().authenticate(
        reason: 'Autentikasi diperlukan untuk membuka aplikasi',
      );
      if (authenticated && context.mounted)
        Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
    } finally {
      if (context.mounted) setState(() => _isVerifying = false);
    }
  }

  void _startLockTimer() {
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final lockTime =
          await context.read<AuthController>().getLockRemainingTime();
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
    if (mounted)
      setState(() {
        _pin = pin;
      });
  }

  Future<void> _onPinComplete() async {
    setState(() => _isVerifying = true);
    try {
      final isValid = await context.read<AuthController>().verifyPin(_pin);
      if (isValid) {
        if (context.mounted)
          Navigator.of(context).pushReplacementNamed('/home');
      } else {
        final remaining =
            await context.read<AuthController>().getRemainingAttempts();
        final lockTime =
            await context.read<AuthController>().getLockRemainingTime();
        if (context.mounted) {
          setState(() {
            _pin = '';
            _remainingAttempts = remaining;
            _lockDuration = lockTime;
          });
          if (lockTime != null) {
            _startLockTimer();
            ErrorHandlerService.showWarningSnackbar(
              context,
              '${AppLocalizations.of(context)?.too_many_attempts ?? 'Terlalu banyak percobaan gagal'}. Tunggu ${_formatDuration(lockTime)}',
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
      if (context.mounted) {
        setState(() => _pin = '');
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isVerifying = false);
    }
  }

  String _formatDuration(Duration d) =>
      d.inMinutes > 0 ? '${d.inMinutes} menit' : '${d.inSeconds} detik';

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
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
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
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
      await context.read<AuthController>().clearPin();
      await context.read<AuthController>().logout();
      if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: DesignTokens.backgroundDark,
        body: Column(
          children: [
            const OfflineIndicator(),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.lock_1,
                        size: 60,
                        color: DesignTokens.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.enter_pin,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lockDuration != null
                          ? '${l10n.wait} ${_formatDuration(_lockDuration!)}'
                          : l10n.enter_pin_to_unlock,
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
                    if (_biometricAvailable &&
                        _biometricEnabled &&
                        _lockDuration == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: FutureBuilder<dynamic>(
                          future:
                              context
                                  .read<AuthController>()
                                  .getAvailableBiometrics(),
                          builder: (ctx, snap) {
                            if (!snap.hasData) return const SizedBox.shrink();
                            final bio =
                                (snap.data as List<BiometricType>?) ??
                                <BiometricType>[];
                            IconData icon;
                            String label;
                            if (bio.contains(BiometricType.face)) {
                              icon = Iconsax.scan_barcode;
                              label = l10n.use_face_id;
                            } else if (bio.contains(
                              BiometricType.fingerprint,
                            )) {
                              icon = Iconsax.finger_scan;
                              label = l10n.use_fingerprint;
                            } else if (bio.contains(BiometricType.iris)) {
                              icon = Iconsax.scan;
                              label = l10n.use_iris;
                            } else {
                              icon = Iconsax.scan_barcode;
                              label = l10n.use_biometric;
                            }
                            return ElevatedButton.icon(
                              onPressed:
                                  _isVerifying ? null : _tryBiometricAuth,
                              icon: Icon(icon, size: 20),
                              label: Text(label),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusMedium,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                    if (_remainingAttempts < 5 && _lockDuration == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusMedium,
                          ),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
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
                    TextButton(
                      onPressed: _logout,
                      child: Text(
                        l10n.forgot_pin_logout,
                        style: GoogleFonts.poppins(
                          color: DesignTokens.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
