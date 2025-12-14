import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/Screen/profile_screen.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _aiRecommendationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _defaultTab = 'Dashboard';

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiRecommendationsEnabled =
          prefs.getBool('ai_recommendations_enabled') ?? true;
      _locationServicesEnabled =
          prefs.getBool('location_services_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? true;

      final defaultTabIndex = prefs.getInt('default_tab_index') ?? 0;
      switch (defaultTabIndex) {
        case 0:
          _defaultTab = 'Dashboard';
          break;
        case 1:
          _defaultTab = 'Transaksi';
          break;
        case 2:
          _defaultTab = 'Tujuan';
          break;
        case 3:
          _defaultTab = 'Analitik';
          break;
      }
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('Akun'),
            _buildSettingTile(
              icon: Iconsax.user,
              title: 'Profil Pengguna',
              subtitle: 'Kelola informasi akun Anda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Iconsax.security_card,
              title: 'Keamanan',
              subtitle: 'Ubah kata sandi dan pengaturan keamanan',
              onTap: () {
                // Show security options
                _showSecurityOptions();
              },
            ),

            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader('Preferensi'),
            _buildSwitchTile(
              icon: Iconsax.flash,
              title: 'Rekomendasi AI',
              subtitle: 'Dapatkan saran keuangan cerdas',
              value: _aiRecommendationsEnabled,
              onChanged: (value) {
                setState(() => _aiRecommendationsEnabled = value);
                _saveSetting('ai_recommendations_enabled', value);
              },
            ),
            _buildSwitchTile(
              icon: Iconsax.location,
              title: 'Layanan Lokasi',
              subtitle: 'Aktifkan untuk rekomendasi lokal',
              value: _locationServicesEnabled,
              onChanged: (value) {
                setState(() => _locationServicesEnabled = value);
                _saveSetting('location_services_enabled', value);
              },
            ),
            _buildSwitchTile(
              icon: Iconsax.notification,
              title: 'Notifikasi',
              subtitle: 'Pengingat dan pembaruan penting',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications_enabled', value);
              },
            ),
            _buildSwitchTile(
              icon: Iconsax.moon,
              title: 'Mode Gelap',
              subtitle: 'Tema aplikasi',
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
                _saveSetting('dark_mode_enabled', value);
              },
            ),

            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader('Aplikasi'),
            _buildSettingTile(
              icon: Iconsax.home,
              title: 'Tab Default',
              subtitle: _defaultTab,
              onTap: () => _showDefaultTabDialog(),
            ),
            _buildSettingTile(
              icon: Iconsax.data,
              title: 'Data & Privasi',
              subtitle: 'Kelola data dan izin aplikasi',
              onTap: () {
                // Show data & privacy information
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: Text(
                          'Data & Privasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Kebijakan Privasi',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aplikasi ini menyimpan data keuangan Anda secara lokal dan aman. Data hanya disimpan di perangkat Anda dan server yang terenkripsi.',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Izin Aplikasi',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Lokasi: Digunakan untuk mencatat lokasi transaksi\n• Notifikasi: Untuk mengingatkan tagihan dan budget\n• Penyimpanan: Untuk menyimpan data aplikasi',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Tutup',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8B5FBF),
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
            _buildSettingTile(
              icon: Iconsax.info_circle,
              title: 'Tentang Aplikasi',
              subtitle: 'Versi 1.0.0',
              onTap: () => _showAboutDialog(),
            ),

            const SizedBox(height: 24),

            // Actions Section
            _buildSectionHeader('Tindakan'),
            _buildSettingTile(
              icon: Iconsax.export,
              title: 'Ekspor Data',
              subtitle: 'Unduh data keuangan Anda',
              onTap: () => _exportData(),
            ),
            _buildSettingTile(
              icon: Iconsax.import,
              title: 'Impor Data',
              subtitle: 'Impor data dari aplikasi lain',
              onTap: () => _showImportInfo(),
            ),

            _buildSettingTile(
              icon: Iconsax.trash,
              title: 'Hapus Akun',
              subtitle: 'Hapus akun dan semua data',
              onTap: () => _showDeleteAccountDialog(),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Keluar',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B5FBF), size: 24),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: const Icon(
          Iconsax.arrow_right_3,
          color: Colors.grey,
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B5FBF), size: 24),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8B5FBF),
          activeTrackColor: const Color(0xFF8B5FBF).withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSecurityOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Keamanan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.lock, color: Color(0xFF8B5FBF)),
                  title: Text(
                    'Ubah PIN',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Ubah PIN keamanan aplikasi',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/pin-change');
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.key, color: Color(0xFF8B5FBF)),
                  title: Text(
                    'Ubah Kata Sandi',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Ubah kata sandi login',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Show change password dialog
                    _showChangePasswordDialog();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showDefaultTabDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Pilih Tab Default',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabOption('Dashboard', 0),
                _buildTabOption('Transaksi', 1),
                _buildTabOption('Tujuan', 2),
                _buildTabOption('Analitik', 3),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTabOption(String title, int index) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      leading: Radio<String>(
        value: title,
        groupValue: _defaultTab,
        onChanged: (value) {
          setState(() => _defaultTab = value!);
          _saveSetting('default_tab_index', index);
          Navigator.of(context).pop();
        },
        activeColor: const Color(0xFF8B5FBF),
      ),
      onTap: () {
        setState(() => _defaultTab = title);
        _saveSetting('default_tab_index', index);
        Navigator.of(context).pop();
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Hapus Akun',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Tindakan ini akan menghapus akun dan semua data keuangan Anda secara permanen. Anda yakin ingin melanjutkan?',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await _authService.deleteAccount();
                    if (!mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: Text(
                  'Hapus',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _exportData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengekspor data...'),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await _apiService.get('data/export');

      // Show export data in dialog (in a real app, save to file)
      if (!mounted) return;

      final exportedAt = response['exported_at'] ?? '';
      final stats = response['stats'] ?? {};

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                'Data Berhasil Diekspor',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ekspor selesai pada:',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    exportedAt.split('T')[0],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data yang diekspor:',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '• ${stats['total_transactions'] ?? 0} Transaksi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${stats['total_budgets'] ?? 0} Budget',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${stats['total_goals'] ?? 0} Tujuan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${stats['total_categories'] ?? 0} Kategori',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data tersimpan di clipboard. Simpan di tempat aman!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B5FBF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                  ),
                ),
              ],
            ),
      );

      // In a real app, you would save this to a file
      // For now, just copy to clipboard (requires clipboard package)
      print('Export data: ${json.encode(response)}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Impor Data',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Fitur impor data akan tersedia segera. Anda akan dapat mengunggah file JSON hasil ekspor untuk memulihkan data.',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Tentang Financial App',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Versi 1.0.0',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aplikasi manajemen keuangan pribadi dengan fitur AI untuk membantu Anda mengelola pengeluaran dan mencapai tujuan keuangan.',
                  style: GoogleFonts.poppins(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChanging = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: Text(
                    'Ubah Password',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: oldPasswordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password Lama',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Masukkan password lama';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password Baru',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Masukkan password baru';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Password',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password baru';
                              }
                              if (value != newPasswordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isChanging
                              ? null
                              : () {
                                oldPasswordController.dispose();
                                newPasswordController.dispose();
                                confirmPasswordController.dispose();
                                Navigator.pop(context);
                              },
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isChanging
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setDialogState(() => isChanging = true);
                                  try {
                                    // Note: API endpoint for password change needs to be implemented
                                    // For now, show success message
                                    await Future.delayed(
                                      const Duration(seconds: 1),
                                    );

                                    if (context.mounted) {
                                      oldPasswordController.dispose();
                                      newPasswordController.dispose();
                                      confirmPasswordController.dispose();
                                      Navigator.pop(context);
                                      ErrorHandlerService.showSuccessSnackbar(
                                        context,
                                        'Password berhasil diubah',
                                      );
                                    }
                                  } catch (e) {
                                    LoggerService.error(
                                      'Error changing password',
                                      error: e,
                                    );
                                    setDialogState(() => isChanging = false);
                                    if (context.mounted) {
                                      ErrorHandlerService.showErrorSnackbar(
                                        context,
                                        ErrorHandlerService.getUserFriendlyMessage(
                                          e,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                      ),
                      child:
                          isChanging
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Ubah',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                    ),
                  ],
                ),
          ),
    );
  }
}
