import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/widgets/home/global_search_sheet.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final LocalAuthService _authService = LocalAuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error - maybe show default name
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.black.withValues(alpha: 0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang,', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: DesignTokens.spacing1),
                Text(
                  _isLoading ? 'Loading...' : (_userProfile?['full_name'] ?? 'User'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Search, Notifications & Settings
          Row(
            children: [
              _buildIconButton(
                icon: Iconsax.search_normal_1,
                label: 'Pencarian Global',
                onPressed: () => _showGlobalSearch(context),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Iconsax.notification,
                label: 'Notifikasi',
                onPressed: () {
                  try {
                    Navigator.pushNamed(context, '/notifications');
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Halaman notifikasi belum tersedia')));
                  }
                },
                hasNotification: true,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Iconsax.setting,
                label: 'Pengaturan',
                onPressed: () {
                  try {
                    Navigator.pushNamed(context, '/settings');
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Halaman pengaturan belum tersedia')));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGlobalSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlobalSearchSheet(),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: IconButton(icon: Icon(icon, size: 20, color: Colors.white), onPressed: onPressed),
          ),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: DesignTokens.primaryColor, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
