import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  final PinAuthService _pinAuthService = PinAuthService();

  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  int _pinLength = 6;
  int _newPinLength = 6;
  int _currentStep = 0; // 0: old PIN, 1: new PIN, 2: confirm PIN
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPinLength();
  }

  Future<void> _loadPinLength() async {
    final length = await _pinAuthService.getPinLength();
    setState(() {
      _pinLength = length;
      _newPinLength = length;
    });
  }

  void _onPinChanged(String pin) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _oldPin = pin;
          break;
        case 1:
          _newPin = pin;
          break;
        case 2:
          _confirmPin = pin;
          break;
      }
    });
  }

  Future<void> _onPinComplete() async {
    if (_currentStep == 0) {
      // Verify old PIN
      await _verifyOldPin();
    } else if (_currentStep == 1) {
      // Move to confirm step
      setState(() {
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      // Confirm and save new PIN
      await _saveNewPin();
    }
  }

  Future<void> _verifyOldPin() async {
    setState(() => _isLoading = true);

    try {
      final isValid = await _pinAuthService.verifyPin(_oldPin);

      if (isValid) {
        setState(() {
          _currentStep = 1;
        });
      } else {
        _showError('PIN lama salah');
        setState(() {
          _oldPin = '';
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _oldPin = '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNewPin() async {
    if (_newPin != _confirmPin) {
      _showError('PIN baru tidak cocok');
      setState(() {
        _newPin = '';
        _confirmPin = '';
        _currentStep = 1;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _pinAuthService.createPin(_newPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ PIN berhasil diubah!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Gagal mengubah PIN: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _oldPin = '';
          _newPin = '';
          _confirmPin = '';
        } else if (_currentStep == 1) {
          _newPin = '';
          _confirmPin = '';
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  String _getTitle() {
    switch (_currentStep) {
      case 0:
        return 'PIN Lama';
      case 1:
        return 'PIN Baru';
      case 2:
        return 'Konfirmasi PIN Baru';
      default:
        return '';
    }
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Masukkan PIN lama Anda';
      case 1:
        return 'Buat PIN baru';
      case 2:
        return 'Masukkan PIN baru sekali lagi';
      default:
        return '';
    }
  }

  String _getCurrentPin() {
    switch (_currentStep) {
      case 0:
        return _oldPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  int _getCurrentPinLength() {
    return _currentStep == 0 ? _pinLength : _newPinLength;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: _onBack,
        ),
        title: Text(
          'Ubah PIN',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                        child: Icon(
                          _currentStep == 0 ? Iconsax.lock : Iconsax.lock_1,
                          size: 60,
                          color: const Color(0xFF8B5FBF),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Progress Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final isCompleted = index < _currentStep;
                          final isCurrent = index == _currentStep;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isCurrent ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  isCompleted || isCurrent
                                      ? const Color(0xFF8B5FBF)
                                      : Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        _getTitle(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        _getSubtitle(),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // PIN Length Selection (only on new PIN step)
                      if (_currentStep == 1) ...[
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
                        pin: _getCurrentPin(),
                        pinLength: _getCurrentPinLength(),
                        onPinChanged: _onPinChanged,
                        onComplete: _onPinComplete,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildPinLengthButton(int length) {
    final isSelected = _newPinLength == length;
    return InkWell(
      onTap: () {
        setState(() {
          _newPinLength = length;
          _newPin = '';
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
