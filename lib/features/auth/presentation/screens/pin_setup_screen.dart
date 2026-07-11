import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/auth/pin_pad.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  int _selectedPinLength = 6;
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;

  void _onPinChanged(String pin) {
    if (mounted) setState(() {
      if (_isConfirmStep) _confirmPin = pin;
      else _pin = pin;
    });
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirmStep) {
      setState(() => _isConfirmStep = true);
    } else {
      if (_pin == _confirmPin) {
        await _savePin();
      } else {
        ErrorHandlerService.showWarningSnackbar(context, 'PIN tidak cocok. Silakan coba lagi.');
        setState(() { _pin = ''; _confirmPin = ''; _isConfirmStep = false; });
      }
    }
  }

  Future<void> _savePin() async {
    setState(() => _isLoading = true);
    final ctx = context;
    try {
      await ctx.read<AuthController>().createPin(_pin);
      if (!ctx.mounted) return;
      ErrorHandlerService.showSuccessSnackbar(ctx, 'PIN berhasil dibuat!');
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      if (!ctx.mounted) return;
      if (!onboardingCompleted) Navigator.of(ctx).pushReplacementNamed('/onboarding');
      else Navigator.of(ctx).pushReplacementNamed('/home');
    } catch (e) {
      LoggerService.error('Error creating PIN', error: e);
      if (!ctx.mounted) return;
      ErrorHandlerService.showErrorSnackbar(ctx, ErrorHandlerService.getUserFriendlyMessage(e), onRetry: _savePin);
    } finally { if (ctx.mounted) setState(() => _isLoading = false); }
  }

  void _onBack() {
    if (_isConfirmStep) setState(() { _confirmPin = ''; _isConfirmStep = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark, elevation: 0,
        leading: _isConfirmStep ? IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.white), onPressed: _onBack) : null,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: DesignTokens.primaryColor.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Iconsax.lock, size: 60, color: DesignTokens.primaryColor)),
                          const SizedBox(height: 32),
                          Text(_isConfirmStep ? l10n.confirm_pin : l10n.create_pin, style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(_isConfirmStep ? l10n.enter_pin_again : l10n.create_pin_to_secure, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14), textAlign: TextAlign.center),
                          const SizedBox(height: 40),
                          if (!_isConfirmStep) ...[
                            Text(l10n.select_pin_length, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              _buildPinLengthButton(4), const SizedBox(width: 16), _buildPinLengthButton(6),
                            ]),
                            const SizedBox(height: 40),
                          ],
                          PinPad(pin: _isConfirmStep ? _confirmPin : _pin, pinLength: _selectedPinLength, onPinChanged: _onPinChanged, onComplete: _onPinComplete),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: DesignTokens.surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: DesignTokens.borderDark)),
                            child: Row(children: [
                              Icon(Iconsax.info_circle, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(l10n.use_pin_to_unlock, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12))),
                            ]),
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
    final isSelected = _selectedPinLength == length;
    return InkWell(
      onTap: () => setState(() { _selectedPinLength = length; _pin = ''; }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(color: isSelected ? DesignTokens.primaryColor : DesignTokens.surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? DesignTokens.primaryColor : DesignTokens.borderDark, width: 2)),
        child: Text('$length Digit', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
