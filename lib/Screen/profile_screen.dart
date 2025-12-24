import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String _email = '';
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _incomeRange;
  final TextEditingController _familySizeController = TextEditingController();
  final TextEditingController _baseLocationController = TextEditingController();

  final List<String> _incomeRanges = [
    ' < 3 juta',
    '3 - 5 juta',
    '5 - 10 juta',
    '> 10 juta',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _familySizeController.dispose();
    _baseLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getUserProfile();
      final user = response['user'] ?? {};

      setState(() {
        _email = (user['email'] ?? '') as String;
        _fullNameController.text = (user['full_name'] ?? '') as String;
        _phoneController.text = (user['phone_number'] ?? '') as String;
        _incomeRange = user['income_range'] as String?;
        _familySizeController.text = user['family_size']?.toString() ?? '';
        _baseLocationController.text = (user['base_location'] ?? '') as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout')) {
      return 'Koneksi timeout. Cek koneksi internet Anda.';
    } else if (errorStr.contains('connection') ||
        errorStr.contains('network')) {
      return 'Gagal terhubung ke server. Pastikan backend berjalan.';
    } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Sesi berakhir. Silakan login kembali.';
    } else {
      return 'Gagal memuat profil pengguna.';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> data = {
        'full_name': _fullNameController.text.trim(),
        'phone_number':
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        'income_range': _incomeRange,
        'base_location':
            _baseLocationController.text.trim().isEmpty
                ? null
                : _baseLocationController.text.trim(),
      };

      final familySizeText = _familySizeController.text.trim();
      if (familySizeText.isNotEmpty) {
        final parsed = int.tryParse(familySizeText);
        if (parsed != null) {
          data['family_size'] = parsed;
        }
      }

      await _apiService.updateProfile(data);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (context.mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          'Profil berhasil diperbarui.',
        );
      }
    } catch (e) {
      LoggerService.error('Error saving profile', error: e);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      if (context.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _saveProfile,
        );
      }
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.user_profile,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              )
              : _errorMessage != null
              ? _buildErrorState()
              : _buildForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.failed_to_load_profile,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '-',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5FBF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.try_again,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.account_information,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(AppLocalizations.of(context)!.email, _email),
            const SizedBox(height: 16),
            _buildTextField(
              label: AppLocalizations.of(context)!.full_name,
              controller: _fullNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.full_name_required;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: AppLocalizations.of(context)!.phone_number,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.financial_information,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdownField(),
            const SizedBox(height: 16),
            _buildTextField(
              label: AppLocalizations.of(context)!.family_members_count,
              controller: _familySizeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: AppLocalizations.of(context)!.residence_location,
              controller: _baseLocationController,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          AppLocalizations.of(context)!.save_changes,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _incomeRange,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.income_range,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items:
          _incomeRanges
              .map(
                (range) =>
                    DropdownMenuItem<String>(value: range, child: Text(range)),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _incomeRange = value;
        });
      },
    );
  }
}
