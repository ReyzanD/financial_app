import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/widgets/onboarding/onboarding_flow_manager.dart';
import 'package:financial_app/widgets/onboarding/permission_request_card.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/accessibility_helper.dart';
import 'package:financial_app/services/logger_service.dart';

/// Enhanced Onboarding Screen dengan interactive tutorial, feature highlights,
/// permission requests dengan explanations, skip option, dan progress tracking
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Selamat Datang!',
      subtitle: 'Mari mulai mengelola keuangan Anda dengan lebih baik',
      description:
          'Aplikasi ini akan membantu Anda melacak pengeluaran, mengatur anggaran, dan mencapai tujuan keuangan Anda.',
      icon: Iconsax.wallet,
      color: const Color(0xFF8B5FBF),
      features: [
        'Lacak semua transaksi',
        'Atur anggaran per kategori',
        'Capai tujuan keuangan',
      ],
    ),
    OnboardingItem(
      title: 'Catat Transaksi',
      subtitle: 'Pantau setiap pengeluaran dan pemasukan',
      description:
          'Catat semua transaksi Anda dengan mudah. Kami akan mengkategorikannya secara otomatis dan memberikan wawasan berharga.',
      icon: Iconsax.receipt,
      color: const Color(0xFF4ECDC4),
      features: [
        'Voice input untuk cepat',
        'Scan struk otomatis',
        'Smart category suggestions',
      ],
    ),
    OnboardingItem(
      title: 'Atur Anggaran',
      subtitle: 'Kendalikan pengeluaran Anda',
      description:
          'Tetapkan batas anggaran untuk setiap kategori dan dapatkan notifikasi ketika Anda mendekati batas.',
      icon: Iconsax.chart_square,
      color: const Color(0xFFFF6B6B),
      features: [
        'Budget forecasting',
        'Real-time alerts',
        'Spending insights',
      ],
    ),
    OnboardingItem(
      title: 'Capai Tujuan',
      subtitle: 'Rencanakan masa depan keuangan Anda',
      description:
          'Tetapkan tujuan keuangan dan lacak progress Anda. Mulai dari dana darurat hingga liburan impian.',
      icon: Iconsax.flag,
      color: const Color(0xFF45B7D1),
      features: [
        'Visual progress tracking',
        'Savings recommendations',
        'Goal milestones',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _trackProgress();
  }

  void _setupAnimations() {
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _iconAnimationController.forward();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _fadeAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _trackProgress() async {
    await OnboardingFlowManager.saveProgress(
      _currentPage,
      _onboardingItems.length + 1, // +1 for permissions page
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _onboardingItems.length + 1; // +1 for permissions page

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            _buildProgressBar(totalPages),

            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: ResponsiveHelper.padding(context, multiplier: 1.0),
                child: AccessibilityHelper.createAccessibleButton(
                  context: context,
                  label: 'Lewati',
                  onPressed: () => _skipOnboarding(),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.grey[400]!,
                  minWidth: 0,
                  minHeight: 0,
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
                    _iconAnimationController.reset();
                    _iconAnimationController.forward();
                  });
                  _trackProgress();
                },
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  if (index < _onboardingItems.length) {
                    return _buildOnboardingPage(_onboardingItems[index]);
                  } else {
                    return _buildPermissionsPage();
                  }
                },
              ),
            ),

            // Bottom Section
            _buildBottomSection(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int totalPages) {
    final progress = (_currentPage + 1) / totalPages;

    return Container(
      margin: ResponsiveHelper.padding(context, multiplier: 1.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Langkah ${_currentPage + 1} dari $totalPages',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(
                    context,
                    DesignTokens.fontSizeLabelSmall,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(
                    context,
                    DesignTokens.fontSizeLabelSmall,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, DesignTokens.radiusRound),
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.primaryColor,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: ResponsiveHelper.padding(context, multiplier: 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _iconScaleAnimation,
              child: Container(
                width: ResponsiveHelper.screenWidth(context) * 0.3,
                height: ResponsiveHelper.screenWidth(context) * 0.3,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: ResponsiveHelper.iconSize(context, 60),
                  color: item.color,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 32)),

            // Title
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: item.title,
              isHeader: true,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeHeadlineMedium,
                ),
                fontWeight: DesignTokens.weightBold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),

            // Subtitle
            Text(
              item.subtitle,
              style: GoogleFonts.poppins(
                color: item.color,
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeTitleLarge,
                ),
                fontWeight: DesignTokens.weightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),

            // Description
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: item.description,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeBodyLarge,
                ),
                height: 1.6,
              ),
            ),

            // Feature Highlights
            if (item.features.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),
              ...item.features.map((feature) => Padding(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveHelper.verticalSpacing(context, 8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          size: ResponsiveHelper.iconSize(context, 20),
                          color: item.color,
                        ),
                        SizedBox(
                          width: ResponsiveHelper.horizontalSpacing(context, 12),
                        ),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[300],
                              fontSize: ResponsiveHelper.fontSize(
                                context,
                                DesignTokens.fontSizeBodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.padding(context, multiplier: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: ResponsiveHelper.padding(context, multiplier: 2.0),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.shield_tick,
                    size: ResponsiveHelper.iconSize(context, 60),
                    color: DesignTokens.primaryColor,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),
                AccessibilityHelper.createAccessibleText(
                  context: context,
                  text: 'Izinkan Akses',
                  isHeader: true,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(
                      context,
                      DesignTokens.fontSizeHeadlineMedium,
                    ),
                    fontWeight: DesignTokens.weightBold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  'Aktifkan fitur untuk pengalaman terbaik',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: ResponsiveHelper.fontSize(
                      context,
                      DesignTokens.fontSizeBodyMedium,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 32)),

          // Permission Cards
          PermissionRequestCard(
            permission: Permission.location,
            title: 'Lokasi',
            description:
                'Gunakan lokasi untuk memberikan rekomendasi tempat hemat dan tracking pengeluaran berdasarkan lokasi',
            benefit: 'Dapatkan rekomendasi tempat hemat di sekitar Anda',
            icon: Iconsax.location,
            iconColor: const Color(0xFF4ECDC4),
            onPermissionGranted: () {
              LoggerService.success('Location permission granted');
            },
          ),
          PermissionRequestCard(
            permission: Permission.notification,
            title: 'Notifikasi',
            description:
                'Terima notifikasi untuk budget alerts, pengingat tagihan, dan rekomendasi keuangan',
            benefit: 'Jangan lewatkan pengingat penting tentang keuangan Anda',
            icon: Iconsax.notification,
            iconColor: const Color(0xFFFF6B6B),
            onPermissionGranted: () {
              LoggerService.success('Notification permission granted');
            },
          ),
          PermissionRequestCard(
            permission: Permission.camera,
            title: 'Kamera',
            description:
                'Gunakan kamera untuk scan struk dan extract informasi transaksi secara otomatis',
            benefit: 'Scan struk dengan mudah untuk input transaksi cepat',
            icon: Iconsax.camera,
            iconColor: const Color(0xFFFFEAA7),
            onPermissionGranted: () {
              LoggerService.success('Camera permission granted');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(int totalPages) {
    return Padding(
      padding: ResponsiveHelper.padding(context, multiplier: 1.5),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => _buildPageIndicator(index),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),

          // Navigation Buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: AccessibilityHelper.createAccessibleButton(
                    context: context,
                    label: 'Kembali',
                    onPressed: _previousPage,
                    backgroundColor: Colors.transparent,
                    foregroundColor: DesignTokens.primaryColor,
                    minWidth: 0,
                  ),
                ),
              if (_currentPage > 0)
                SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
              Expanded(
                child: AccessibilityHelper.createAccessibleButton(
                  context: context,
                  label: _currentPage == totalPages - 1
                      ? 'Mulai Sekarang'
                      : 'Selanjutnya',
                  onPressed: _currentPage == totalPages - 1
                      ? _completeOnboarding
                      : _nextPage,
                  backgroundColor: DesignTokens.primaryColor,
                  icon: _currentPage == totalPages - 1
                      ? Iconsax.arrow_right_3
                      : Iconsax.arrow_right_1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: DesignTokens.durationMedium,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.horizontalSpacing(context, 4),
      ),
      width: isActive
          ? ResponsiveHelper.horizontalSpacing(context, 24)
          : ResponsiveHelper.horizontalSpacing(context, 8),
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? DesignTokens.primaryColor
            : Colors.grey[600]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, DesignTokens.radiusRound),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingItems.length) {
      _pageController.nextPage(
        duration: DesignTokens.durationMedium,
        curve: DesignTokens.curveStandard,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: DesignTokens.durationMedium,
        curve: DesignTokens.curveStandard,
      );
    }
  }

  Future<void> _skipOnboarding() async {
    await OnboardingFlowManager.skipOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await OnboardingFlowManager.completeOnboarding();
      await OnboardingFlowManager.markPermissionsRequested();

      final prefs = await SharedPreferences.getInstance();

      // Set user defaults for new users
      await prefs.setInt('default_tab_index', 0); // Home tab
      await prefs.setBool('ai_recommendations_enabled', true);

      // Fetch and store user location if permission granted
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          await prefs.setDouble('user_latitude', position.latitude);
          await prefs.setDouble('user_longitude', position.longitude);
        }
      } catch (e) {
        LoggerService.debug('Location not available: $e');
      }

      // Request notification permission if not already granted
      try {
        await NotificationService().requestPermissions();
      } catch (e) {
        LoggerService.debug('Notification permission not available: $e');
      }

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      LoggerService.error('Error completing onboarding', error: e);
      // Still navigate to home even if there's an error
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
  final List<String> features;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.features = const [],
  });
}
