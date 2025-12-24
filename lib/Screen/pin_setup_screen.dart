import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinAuthService _pinAuthService = PinAuthService();

  int _selectedPinLength = 6; // Default to 6-digit PIN
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;

  void _onPinChanged(String pin) {
    setState(() {
      if (_isConfirmStep) {
        _confirmPin = pin;
      } else {
        _pin = pin;
      }
    });
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirmStep) {
      // First PIN entered, move to confirm step
      setState(() {
        _isConfirmStep = true;
      });
    } else {
      // Confirm PIN entered, validate and save
      if (_pin == _confirmPin) {
        await _savePin();
      } else {
        // PINs don't match
        ErrorHandlerService.showWarningSnackbar(
          context,
          'PIN tidak cocok. Silakan coba lagi.',
        );
        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirmStep = false;
        });
      }
    }
  }

  Future<void> _savePin() async {
    setState(() => _isLoading = true);

    try {
      await _pinAuthService.createPin(_pin);

      if (mounted) {
        // Show success message
        ErrorHandlerService.showSuccessSnackbar(
          context,
          'PIN berhasil dibuat!',
        );

        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      LoggerService.error('Error creating PIN', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _savePin,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBack() {
    if (_isConfirmStep) {
      setState(() {
        _confirmPin = '';
        _isConfirmStep = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading:
            _isConfirmStep
                ? IconButton(
                  icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                  onPressed: _onBack,
                )
                : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5FBF).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.lock,
                          size: 60,
                          color: Color(0xFF8B5FBF),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        _isConfirmStep ? 'Konfirmasi PIN' : 'Buat PIN',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        _isConfirmStep
                            ? 'Masukkan PIN sekali lagi untuk konfirmasi'
                            : 'Buat PIN untuk mengamankan akun Anda',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // PIN Length Selection (only on first step)
                      if (!_isConfirmStep) ...[
                        Text(
                          'Pilih Panjang PIN',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPinLengthButton(4),
                            const SizedBox(width: 16),
                            _buildPinLengthButton(6),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],

                      // PIN Pad
                      PinPad(
                        pin: _isConfirmStep ? _confirmPin : _pin,
                        pinLength: _selectedPinLength,
                        onPinChanged: _onPinChanged,
                        onComplete: _onPinComplete,
                      ),
                      const SizedBox(height: 32),

                      // Info Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Gunakan PIN ini untuk membuka aplikasi dengan cepat setiap kali Anda masuk',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildPinLengthButton(int length) {
    final isSelected = _selectedPinLength == length;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPinLength = length;
          _pin = '';
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5FBF) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5FBF) : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Text(
          '$length Digit',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
