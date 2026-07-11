import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/services/subscription_tracker_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AddSubscriptionModal extends StatefulWidget {
  final VoidCallback onSubscriptionAdded;
  const AddSubscriptionModal({super.key, required this.onSubscriptionAdded});

  @override
  State<AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<AddSubscriptionModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedCycle = 'monthly';
  DateTime _nextRenewal = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() { _nameController.dispose(); _costController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DesignTokens.textTertiaryDark, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(l10n?.add ?? 'Tambah Langganan', style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          TextFormField(controller: _nameController, style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
            decoration: InputDecoration(labelText: l10n?.name ?? 'Nama', labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark), filled: true, fillColor: DesignTokens.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium), borderSide: BorderSide(color: DesignTokens.borderDark))),
            validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _costController, keyboardType: TextInputType.number, style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
            decoration: InputDecoration(labelText: 'Biaya', labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark), filled: true, fillColor: DesignTokens.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium), borderSide: BorderSide(color: DesignTokens.borderDark))),
            validator: (v) => (v == null || v.isEmpty) ? 'Biaya tidak boleh kosong' : null),
          const SizedBox(height: 16),
          Text('Siklus', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final c in ['monthly', 'yearly', 'weekly'])
              ChoiceChip(label: Text(c == 'monthly' ? 'Bulanan' : c == 'yearly' ? 'Tahunan' : 'Mingguan',
                style: GoogleFonts.poppins(color: _selectedCycle == c ? Colors.white : DesignTokens.textSecondaryDark, fontSize: 12)),
                selected: _selectedCycle == c, onSelected: (_) => setState(() => _selectedCycle = c),
                backgroundColor: DesignTokens.surfaceDark, selectedColor: DesignTokens.primaryColor),
          ]),
          const SizedBox(height: 16),
          InkWell(onTap: _pickDate, child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: DesignTokens.surfaceDark, borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tagihan Berikutnya', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark)),
              Text(DateFormat('dd MMM yyyy').format(_nextRenewal), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
            ]))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium))),
            child: Text(l10n?.add ?? 'Tambah', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _nextRenewal, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: DesignTokens.primaryColor, onPrimary: Colors.white, surface: DesignTokens.surfaceDark, onSurface: Colors.white)), child: child!));
    if (picked != null) setState(() => _nextRenewal = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await getIt<SubscriptionTrackerService>().addSubscription(SubscriptionModel(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}', name: _nameController.text,
        cost: double.tryParse(_costController.text) ?? 0.0, cycle: _selectedCycle, startDate: DateTime.now(), nextRenewal: _nextRenewal, createdAt: DateTime.now(), isActive: true,
      ));
      if (!mounted) return; Navigator.pop(context); widget.onSubscriptionAdded();
    } catch (e) { if (!mounted) return; ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e)); }
  }
}
