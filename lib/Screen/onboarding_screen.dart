import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/location_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Selamat Datang!',
      subtitle: 'Mari mulai mengelola keuangan Anda dengan lebih baik',
      description:
          'Aplikasi ini akan membantu Anda melacak pengeluaran, mengatur anggaran, dan mencapai tujuan keuangan Anda.',
      icon: Iconsax.wallet,
      color: const Color(0xFF8B5FBF),
    ),
    OnboardingItem(
      title: 'Catat Transaksi',
      subtitle: 'Pantau setiap pengeluaran dan pemasukan',
      description:
          'Catat semua transaksi Anda dengan mudah. Kami akan mengkategorikannya secara otomatis dan memberikan wawasan berharga.',
      icon: Iconsax.receipt,
      color: const Color(0xFF4ECDC4),
    ),
    OnboardingItem(
      title: 'Atur Anggaran',
      subtitle: 'Kendalikan pengeluaran Anda',
      description:
          'Tetapkan batas anggaran untuk setiap kategori dan dapatkan notifikasi ketika Anda mendekati batas.',
      icon: Iconsax.chart_square,
      color: const Color(0xFFFF6B6B),
    ),
    OnboardingItem(
      title: 'Kelola Utang',
      subtitle: 'Bayar utang Anda secara strategis',
      description:
          'Lacak semua utang dan langganan Anda. Kami akan membantu Anda membuat strategi pembayaran yang efektif.',
      icon: Iconsax.money_send,
      color: const Color(0xFFFFEAA7),
    ),
    OnboardingItem(
      title: 'Capai Tujuan',
      subtitle: 'Rencanakan masa depan keuangan Anda',
      description:
          'Tetapkan tujuan keuangan dan lacak progress Anda. Mulai dari dana darurat hingga liburan impian.',
      icon: Iconsax.flag,
      color: const Color(0xFF45B7D1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => _completeOnboarding(),
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingItems.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingItems[index]);
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingItems.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B5FBF)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Kembali',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8B5FBF),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),

                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _currentPage == _onboardingItems.length - 1
                                  ? _completeOnboarding
                                  : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5FBF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == _onboardingItems.length - 1
                                ? 'Mulai Sekarang'
                                : 'Selanjutnya',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 60, color: item.color),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            item.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            item.subtitle,
            style: GoogleFonts.poppins(
              color: item.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            item.description,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color:
            _currentPage == index ? const Color(0xFF8B5FBF) : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Set user defaults for new users
      await prefs.setBool('onboarding_completed', true);
      await prefs.setInt('default_tab_index', 2); // Goals tab (index 2)
      await prefs.setBool('ai_recommendations_enabled', true);

      // Fetch and store user location
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        await prefs.setDouble('user_latitude', position.latitude);
        await prefs.setDouble('user_longitude', position.longitude);
      }

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // If there's an error, still complete onboarding but without location
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setInt('default_tab_index', 2);
      await prefs.setBool('ai_recommendations_enabled', true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
