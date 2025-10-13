import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PaymentMethodSection extends StatelessWidget {
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodSelected;

  const PaymentMethodSection({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
  });

  static const List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Tunai', 'icon': Iconsax.money},
    {'id': 'debit_card', 'name': 'Kartu Debit', 'icon': Iconsax.card},
    {'id': 'credit_card', 'name': 'Kartu Kredit', 'icon': Iconsax.card_pos},
    {'id': 'e_wallet', 'name': 'E-Wallet', 'icon': Iconsax.wallet},
    {'id': 'bank_transfer', 'name': 'Transfer Bank', 'icon': Iconsax.bank},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _paymentMethods.map((method) {
                final isSelected = selectedPaymentMethod == method['id'];

                return GestureDetector(
                  onTap: () => onPaymentMethodSelected(method['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF8B5FBF).withValues(alpha: 0.3)
                              : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF8B5FBF)
                                : Colors.grey[700]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          method['icon'] as IconData,
                          size: 16,
                          color:
                              isSelected
                                  ? const Color(0xFF8B5FBF)
                                  : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          method['name'] as String,
                          style: GoogleFonts.poppins(
                            color:
                                isSelected
                                    ? const Color(0xFF8B5FBF)
                                    : Colors.grey[500],
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
