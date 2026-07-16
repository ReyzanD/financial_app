import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  String _oldPin = '', _newPin = '', _confirmPin = '';
  int _pinLength = 6, _newPinLength = 6;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPinLength();
  }

  Future<void> _loadPinLength() async {
    final len = await context.read<AuthController>().getPinLength();
    if (mounted)
      setState(() {
        _pinLength = len;
        _newPinLength = len;
      });
  }

  void _onPinChanged(String pin) {
    if (mounted)
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
    if (_currentStep == 0)
      await _verifyOldPin();
    else if (_currentStep == 1)
      setState(() => _currentStep = 2);
    else if (_currentStep == 2)
      await _saveNewPin();
  }

  Future<void> _verifyOldPin() async {
    setState(() => _isLoading = true);
    final ctx = context;
    try {
      final valid = await ctx.read<AuthController>().verifyPin(_oldPin);
      if (valid) {
        if (mounted) setState(() => _currentStep = 1);
      } else {
        if (ctx.mounted)
          ErrorHandlerService.showWarningSnackbar(ctx, AppLocalizations.of(ctx)?.wrong_old_pin ?? 'PIN lama salah');
        if (mounted) setState(() => _oldPin = '');
      }
    } catch (e) {
      LoggerService.error('Error verifying old PIN', error: e);
      if (ctx.mounted) ErrorHandlerService.showErrorSnackbar(ctx, ErrorHandlerService.getUserFriendlyMessage(e));
      if (mounted) setState(() => _oldPin = '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNewPin() async {
    if (_newPin != _confirmPin) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        AppLocalizations.of(context)?.new_pin_mismatch ?? 'PIN baru tidak cocok',
      );
      setState(() {
        _newPin = '';
        _confirmPin = '';
        _currentStep = 1;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthController>().createPin(_newPin);
      if (mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          AppLocalizations.of(context)?.pin_changed_successfully ?? 'PIN berhasil diubah!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      LoggerService.error('Error changing PIN', error: e);
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _saveNewPin,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  String _getTitle(AppLocalizations? l10n) {
    switch (_currentStep) {
      case 0:
        return l10n?.old_pin ?? 'PIN Lama';
      case 1:
        return l10n?.new_pin ?? 'PIN Baru';
      case 2:
        return l10n?.confirm_new_pin ?? 'Konfirmasi PIN Baru';
      default:
        return '';
    }
  }

  String _getSubtitle(AppLocalizations? l10n) {
    switch (_currentStep) {
      case 0:
        return l10n?.old_pin_subtitle ?? 'Masukkan PIN lama Anda';
      case 1:
        return l10n?.new_pin_subtitle ?? 'Buat PIN baru';
      case 2:
        return l10n?.confirm_new_pin_subtitle ?? 'Masukkan PIN baru sekali lagi';
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

  int _getCurrentPinLength() => _currentStep == 0 ? _pinLength : _newPinLength;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: l10n?.back ?? 'Kembali',
          onPressed: _onBack,
        ),
        title: Text(
          l10n?.change_pin ?? 'Ubah PIN',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor))
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: DesignTokens.spacing5),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _currentStep == 0 ? Iconsax.lock : Iconsax.lock_1,
                                size: 60,
                                color: DesignTokens.primaryColor,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacing7),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final completed = i < _currentStep;
                                final current = i == _currentStep;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: current ? 32 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: completed || current ? DesignTokens.primaryColor : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: DesignTokens.spacing6),
                            Text(
                              _getTitle(l10n),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacing2),
                            Text(
                              _getSubtitle(l10n),
                              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DesignTokens.spacing8),
                            if (_currentStep == 1) ...[
                              Text(
                                l10n?.select_pin_length ?? 'Pilih Panjang PIN',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacing4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPinLengthButton(4),
                                  const SizedBox(width: 16),
                                  _buildPinLengthButton(6),
                                ],
                              ),
                              const SizedBox(height: DesignTokens.spacing8),
                            ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildPinLengthButton(int length) {
    final sel = _newPinLength == length;
    return InkWell(
      onTap:
          () => setState(() {
            _newPinLength = length;
            _newPin = '';
          }),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: sel ? DesignTokens.primaryColor : DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: sel ? DesignTokens.primaryColor : DesignTokens.borderDark, width: 2),
        ),
        child: Text(
          '$length Digit',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
