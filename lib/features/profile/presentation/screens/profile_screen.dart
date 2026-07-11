import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/profile/presentation/controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String? _incomeRange;
  final _incomeRanges = ['< 3 juta', '3 - 5 juta', '5 - 10 juta', '> 10 juta'];

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProfileController>().loadProfile()); }
  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _familyCtrl.dispose(); _locationCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(backgroundColor: DesignTokens.backgroundDark, elevation: 0, leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.user_profile, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        const OfflineIndicator(),
        Expanded(child: Consumer<ProfileController>(builder: (context, ctrl, _) {
          if (ctrl.isLoading) return const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
          return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildAvatarSection(ctrl),
              const SizedBox(height: 24),
              Text('Informasi Pribadi', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildField('Nama Lengkap', _nameCtrl, icon: Iconsax.user),
              const SizedBox(height: 12),
              _buildField('No. Telepon', _phoneCtrl, icon: Iconsax.call, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField('Jumlah Anggota Keluarga', _familyCtrl, icon: Iconsax.people, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildField('Lokasi', _locationCtrl, icon: Iconsax.location),
              const SizedBox(height: 16),
              Text('Rentang Pendapatan', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _incomeRange,
                dropdownColor: DesignTokens.surfaceDark,
                decoration: InputDecoration(
                  filled: true, fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.borderDark)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.borderDark)),
                  prefixIcon: const Icon(Iconsax.money, color: Colors.grey),
                ),
                items: _incomeRanges.map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.poppins(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => _incomeRange = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ctrl.isSaving ? null : () => _save(ctrl),
                  style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: ctrl.isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Simpan', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ));
        })),
      ]),
    );
  }

  Widget _buildAvatarSection(ProfileController ctrl) {
    return Center(child: Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: DesignTokens.primaryColor.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Center(child: Text(
          (ctrl.profile['name']?.toString().isNotEmpty == true ? ctrl.profile['name'].toString()[0].toUpperCase() : 'U'),
          style: GoogleFonts.poppins(color: DesignTokens.primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
        )),
      ),
      const SizedBox(height: 12),
      Text(ctrl.profile['email']?.toString() ?? '', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
    ]));
  }

  Widget _buildField(String label, TextEditingController ctrl, {IconData? icon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
        filled: true, fillColor: DesignTokens.surfaceDark,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500], size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.borderDark)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DesignTokens.borderDark)),
      ),
    );
  }

  Future<void> _save(ProfileController ctrl) async {
    try {
      await ctrl.saveProfile({
        'name': _nameCtrl.text, 'phone': _phoneCtrl.text, 'family_size': _familyCtrl.text, 'base_location': _locationCtrl.text, 'income_range': _incomeRange,
      });
      if (mounted) ErrorHandlerService.showSuccessSnackbar(context, 'Profil berhasil disimpan');
    } catch (e) {
      if (mounted) ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
    }
  }
}
