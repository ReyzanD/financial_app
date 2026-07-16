import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:financial_app/widgets/onboarding/onboarding_flow_manager.dart';
import 'package:financial_app/widgets/onboarding/permission_request_card.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/accessibility_helper.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _fadeAnimation;

  static const int _onboardingPageCount = 2;

  List<_OnboardingItem> _getOnboardingItems(AppLocalizations? l10n) {
    return [
      _OnboardingItem(
        title: l10n?.welcome ?? 'Selamat Datang!',
        subtitle: l10n?.start_managing_finances ?? 'Mari mulai mengelola keuangan Anda dengan lebih baik',
        description:
            l10n?.app_description ??
            'Aplikasi ini akan membantu Anda melacak pengeluaran, mengatur anggaran, dan mencapai tujuan keuangan.',
        icon: Iconsax.wallet,
        color: DesignTokens.primaryColor,
        features: [
          l10n?.track_all_transactions ?? 'Lacak semua transaksi',
          'Input cepat dengan voice & scan struk',
          'Kategori otomatis pintar',
        ],
      ),
      _OnboardingItem(
        title: l10n?.manage_budget ?? 'Atur Anggaran & Capai Tujuan',
        subtitle: l10n?.control_expenses ?? 'Kendalikan pengeluaran Anda',
        description:
            'Tetapkan batas anggaran dan tujuan keuangan. Dapatkan notifikasi serta rekomendasi untuk mencapai target Anda.',
        icon: Iconsax.chart_square,
        color: DesignTokens.errorColor,
        features: [
          'Budget & spending insights real-time',
          'Lacak progress tujuan keuangan',
          'Rekomendasi penghematan cerdas',
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _trackProgress();
  }

  void _setupAnimations() {
    _iconAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconAnimationController, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn));
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
    try {
      await OnboardingFlowManager.saveProgress(_currentPage, _onboardingPageCount + 1);
    } catch (e) {
      LoggerService.debug('Error tracking onboarding progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _getOnboardingItems(l10n);
    final totalPages = _onboardingPageCount + 1;
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicator(),
            _buildProgressBar(totalPages, l10n),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: ResponsiveHelper.padding(context, multiplier: 1.0),
                child: AccessibilityHelper.createAccessibleButton(
                  context: context,
                  label: l10n?.skip ?? 'Lewati',
                  onPressed: _skipOnboarding,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.grey[400]!,
                ),
              ),
            ),
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
                itemBuilder:
                    (_, index) =>
                        index < _onboardingPageCount ? _buildOnboardingPage(items[index]) : _buildPermissionsPage(l10n),
              ),
            ),
            _buildBottomSection(totalPages, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int totalPages, [AppLocalizations? l10n]) {
    l10n ??= AppLocalizations.of(context);
    final progress = (_currentPage + 1) / totalPages;
    return Container(
      margin: ResponsiveHelper.padding(context, multiplier: 1.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n?.step ?? 'Langkah'} ${_currentPage + 1} dari $totalPages',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeLabelSmall),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeLabelSmall),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, DesignTokens.radiusRound)),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(_OnboardingItem item) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: ResponsiveHelper.padding(context, multiplier: 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _iconScaleAnimation,
              child: Container(
                width: ResponsiveHelper.screenWidth(context) * 0.3,
                height: ResponsiveHelper.screenWidth(context) * 0.3,
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(item.icon, size: ResponsiveHelper.iconSize(context, 60), color: item.color),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 32)),
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: item.title,
              isHeader: true,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeHeadlineMedium),
                fontWeight: DesignTokens.weightBold,
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
            Text(
              item.subtitle,
              style: GoogleFonts.poppins(
                color: item.color,
                fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeTitleLarge),
                fontWeight: DesignTokens.weightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: item.description,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeBodyLarge),
                height: 1.6,
              ),
            ),
            if (item.features.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),
              ...item.features.map(
                (f) => Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveHelper.verticalSpacing(context, 8)),
                  child: Row(
                    children: [
                      Icon(Iconsax.tick_circle, size: ResponsiveHelper.iconSize(context, 20), color: item.color),
                      SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
                      Expanded(
                        child: Text(
                          f,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeBodyMedium),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsPage([AppLocalizations? l10n]) {
    l10n ??= AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: ResponsiveHelper.padding(context, multiplier: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: ResponsiveHelper.padding(context, multiplier: 2.0),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryColor.withValues(alpha: 0.1),
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
                  text: l10n?.allow_access ?? 'Izinkan Akses',
                  isHeader: true,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeHeadlineMedium),
                    fontWeight: DesignTokens.weightBold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  l10n?.enable_features_for_best_experience ?? 'Aktifkan fitur untuk pengalaman terbaik',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: ResponsiveHelper.fontSize(context, DesignTokens.fontSizeBodyMedium),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 32)),
          PermissionRequestCard(
            permission: Permission.notification,
            title: l10n?.notifications ?? 'Notifikasi',
            description: 'Terima notifikasi untuk budget alerts, pengingat tagihan, dan rekomendasi keuangan',
            benefit: 'Jangan lewatkan pengingat penting tentang keuangan Anda',
            icon: Iconsax.notification,
            iconColor: DesignTokens.errorColor,
            onPermissionGranted: () => LoggerService.success('Notification permission granted'),
          ),
          PermissionRequestCard(
            permission: Permission.camera,
            title: l10n?.camera ?? 'Kamera',
            description: 'Gunakan kamera untuk scan struk dan extract informasi transaksi secara otomatis',
            benefit: 'Scan struk dengan mudah untuk input transaksi cepat',
            icon: Iconsax.camera,
            iconColor: DesignTokens.warningColor,
            onPermissionGranted: () => LoggerService.success('Camera permission granted'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(int totalPages, AppLocalizations? l10n) {
    return Padding(
      padding: ResponsiveHelper.padding(context, multiplier: 1.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (i) => _buildPageIndicator(i)),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: AccessibilityHelper.createAccessibleButton(
                    context: context,
                    label: l10n?.back ?? 'Kembali',
                    onPressed: _previousPage,
                    backgroundColor: Colors.transparent,
                    foregroundColor: DesignTokens.primaryColor,
                  ),
                ),
              if (_currentPage > 0) SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
              Expanded(
                child: AccessibilityHelper.createAccessibleButton(
                  context: context,
                  label:
                      _currentPage == totalPages - 1
                          ? (l10n?.start_now ?? 'Mulai Sekarang')
                          : (l10n?.next ?? 'Selanjutnya'),
                  onPressed: _currentPage == totalPages - 1 ? _completeOnboarding : _nextPage,
                  backgroundColor: DesignTokens.primaryColor,
                  icon: _currentPage == totalPages - 1 ? Iconsax.arrow_right_3 : Iconsax.arrow_right_1,
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
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalSpacing(context, 4)),
      width:
          isActive ? ResponsiveHelper.horizontalSpacing(context, 24) : ResponsiveHelper.horizontalSpacing(context, 8),
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? DesignTokens.primaryColor : Colors.grey[600]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, DesignTokens.radiusRound)),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingPageCount)
      _pageController.nextPage(duration: DesignTokens.durationMedium, curve: DesignTokens.curveStandard);
  }

  void _previousPage() {
    if (_currentPage > 0)
      _pageController.previousPage(duration: DesignTokens.durationMedium, curve: DesignTokens.curveStandard);
  }

  Future<void> _skipOnboarding() async {
    try {
      await OnboardingFlowManager.skipOnboarding();
    } catch (e) {
      LoggerService.error('Error skipping onboarding', error: e);
    }
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _completeOnboarding() async {
    // 1. Complete onboarding flow (core operation — fail blocks navigation)
    try {
      await OnboardingFlowManager.completeOnboarding();
    } catch (e) {
      LoggerService.error('Error completing onboarding flow', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // 2. Mark permissions as requested (non-critical — log and continue)
    try {
      await OnboardingFlowManager.markPermissionsRequested();
    } catch (e) {
      LoggerService.error('Error marking permissions requested', error: e);
    }

    // 3. Save user preferences (non-critical — log and continue)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('default_tab_index', 0);
      await prefs.setBool('ai_recommendations_enabled', true);
    } catch (e) {
      LoggerService.error('Error saving onboarding preferences', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          'Gagal menyimpan beberapa preferensi. Pengaturan default akan digunakan.',
        );
      }
    }

    // 4. Navigate to home
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }
}

class _OnboardingItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.features = const [],
  });
}
