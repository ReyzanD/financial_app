import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PinPad extends StatelessWidget {
  final String pin;
  final int pinLength;
  final Function(String) onPinChanged;
  final VoidCallback? onComplete;
  final bool obscurePin;

  const PinPad({
    super.key,
    required this.pin,
    required this.pinLength,
    required this.onPinChanged,
    this.onComplete,
    this.obscurePin = true,
  });

  void _onNumberPressed(String number) {
    if (pin.length < pinLength) {
      final newPin = pin + number;
      onPinChanged(newPin);

      if (newPin.length == pinLength && onComplete != null) {
        onComplete!();
      }
    }
  }

  void _onBackspacePressed() {
    if (pin.isNotEmpty) {
      onPinChanged(pin.substring(0, pin.length - 1));
    }
  }

  void _onClearPressed() {
    onPinChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN Display
        _buildPinDisplay(),
        const SizedBox(height: 40),

        // Number Pad
        _buildNumberPad(),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final isFilled = index < pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF8B5FBF) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFF8B5FBF) : Colors.grey[600]!,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // Row 1: 1 2 3
        _buildNumberRow(['1', '2', '3']),
        const SizedBox(height: 12),

        // Row 2: 4 5 6
        _buildNumberRow(['4', '5', '6']),
        const SizedBox(height: 12),

        // Row 3: 7 8 9
        _buildNumberRow(['7', '8', '9']),
        const SizedBox(height: 12),

        // Row 4: Clear 0 Backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(icon: Iconsax.trash, onPressed: _onClearPressed),
            _buildNumberButton('0'),
            _buildActionButton(
              icon: Iconsax.arrow_left_2,
              onPressed: _onBackspacePressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: Colors.grey[400], size: 28)),
      ),
    );
  }
}
