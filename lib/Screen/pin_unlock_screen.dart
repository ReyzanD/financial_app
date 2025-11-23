import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final PinAuthService _pinAuthService = PinAuthService();
  final AuthService _authService = AuthService();

  String _pin = '';
  int _pinLength = 6;
  bool _isLoading = true;
  bool _isVerifying = false;
  int _remainingAttempts = 5;
  Duration? _lockDuration;
  Timer? _lockTimer;

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

      setState(() {
        _pinLength = pinLength;
        _remainingAttempts = remaining;
        _lockDuration = lockTime;
        _isLoading = false;
      });

      if (_lockDuration != null) {
        _startLockTimer();
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
            _showError(
              'Terlalu banyak percobaan gagal. Tunggu ${_formatDuration(lockTime)}',
            );
          } else {
            _showError('PIN salah. $remaining percobaan tersisa.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pin = '');
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
              'Anda perlu login kembali dengan email dan password.',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  'Logout',
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
                'Masukkan PIN',
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
                    ? 'Tunggu ${_formatDuration(_lockDuration!)}'
                    : 'Masukkan PIN untuk membuka aplikasi',
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
                  'Lupa PIN? Logout',
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
