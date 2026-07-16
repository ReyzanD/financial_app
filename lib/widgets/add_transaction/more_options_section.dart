import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/widgets/add_transaction/account_section.dart';
import 'package:financial_app/widgets/add_transaction/location_section.dart';
import 'package:financial_app/widgets/add_transaction/payment_method_section.dart';
import 'package:financial_app/widgets/add_transaction/notes_field.dart';
import 'package:financial_app/models/location_data.dart';

/// Collapsible "More Options" section that houses secondary form fields.
/// Keeps the Add Transaction form clean with only 5 core fields visible.
class MoreOptionsSection extends StatefulWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountSelected;
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodSelected;
  final LocationData? currentLocation;
  final bool isGettingLocation;
  final VoidCallback onGetLocation;
  final VoidCallback onPickFromMap;
  final VoidCallback onClearLocation;
  final TextEditingController notesController;
  final bool? showRecurring;
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final String? recurringFrequency;
  final ValueChanged<String?> onRecurringFrequencyChanged;

  const MoreOptionsSection({
    super.key,
    this.selectedAccountId,
    required this.onAccountSelected,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    this.currentLocation,
    required this.isGettingLocation,
    required this.onGetLocation,
    required this.onPickFromMap,
    required this.onClearLocation,
    required this.notesController,
    this.showRecurring,
    this.isRecurring = false,
    required this.onRecurringChanged,
    this.recurringFrequency,
    required this.onRecurringFrequencyChanged,
  });

  @override
  State<MoreOptionsSection> createState() => _MoreOptionsSectionState();
}

class _MoreOptionsSectionState extends State<MoreOptionsSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.setting,
                      color: DesignTokens.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Opsi Lainnya',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Iconsax.arrow_down_1,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible content
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: DesignTokens.borderDark),
                  const SizedBox(height: 8),

                  // Recurring toggle
                  if (widget.showRecurring == true) ...[
                    _buildRecurringToggle(),
                    if (widget.isRecurring) ...[
                      const SizedBox(height: 12),
                      _buildRecurringFrequencyOptions(),
                    ],
                    const SizedBox(height: 20),
                  ],

                  // Account
                  AccountSection(
                    selectedAccountId: widget.selectedAccountId,
                    onAccountSelected: widget.onAccountSelected,
                  ),
                  const SizedBox(height: 20),

                  // Payment Method
                  PaymentMethodSection(
                    selectedPaymentMethod: widget.selectedPaymentMethod,
                    onPaymentMethodSelected: widget.onPaymentMethodSelected,
                  ),
                  const SizedBox(height: 20),

                  // Location
                  LocationSection(
                    currentLocation: widget.currentLocation,
                    isGettingLocation: widget.isGettingLocation,
                    onGetLocation: widget.onGetLocation,
                    onPickFromMap: widget.onPickFromMap,
                    onClearLocation: widget.onClearLocation,
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  NotesField(controller: widget.notesController),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignTokens.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Iconsax.refresh,
            color: DesignTokens.primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi Berulang',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.isRecurring ? 'Aktif' : 'Nonaktif',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: widget.isRecurring,
          onChanged: widget.onRecurringChanged,
          activeThumbColor: DesignTokens.primaryColor,
        ),
      ],
    );
  }

  Widget _buildRecurringFrequencyOptions() {
    const frequencies = [
      {'value': 'daily', 'label': 'Harian', 'icon': Iconsax.calendar_1},
      {'value': 'weekly', 'label': 'Mingguan', 'icon': Iconsax.calendar_2},
      {'value': 'monthly', 'label': 'Bulanan', 'icon': Iconsax.calendar},
      {'value': 'yearly', 'label': 'Tahunan', 'icon': Iconsax.calendar_tick},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.backgroundDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frekuensi',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...frequencies.map((freq) {
            final value = freq['value'] as String;
            final label = freq['label'] as String;
            final icon = freq['icon'] as IconData;
            final isSelected = widget.recurringFrequency == value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () => widget.onRecurringFrequencyChanged(value),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? DesignTokens.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color:
                            isSelected
                                ? DesignTokens.primaryColor
                                : Colors.grey[500],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontSize: 13,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected
                                    ? DesignTokens.primaryColor
                                    : Colors.grey[600]!,
                            width: 2,
                          ),
                          color:
                              isSelected
                                  ? DesignTokens.primaryColor
                                  : Colors.transparent,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
