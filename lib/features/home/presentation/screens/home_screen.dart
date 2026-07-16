import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:financial_app/widgets/home/home_header.dart';
import 'package:financial_app/widgets/home/financial_summary_card.dart';
import 'package:financial_app/widgets/home/quick_actions_enhanced.dart';
import 'package:financial_app/widgets/home/ai_recommendations.dart';
import 'package:financial_app/widgets/home/budget_progress.dart';
import 'package:financial_app/widgets/home/tab_placeholders.dart';
import 'package:financial_app/widgets/home/bottom_nav_bar.dart';
import 'package:financial_app/widgets/home/floating_action_button.dart';
import 'package:financial_app/widgets/common/expandable_section.dart';
import 'package:financial_app/widgets/home/health_score_card.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/widgets/common/responsive_content.dart';
import 'package:financial_app/features/more_tab/presentation/screens/more_tab_screen.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  int _refreshCounter = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDefaultTab();
    RefreshNotifier().addListener(_onGlobalRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    LoggerService.info('[HomeScreen] Triggering initial data load...');
    try {
      await context.read<DashboardController>().loadInitialData();
      if (mounted) setState(() => _errorMessage = null);
      LoggerService.success('[HomeScreen] Initial data load completed');
    } catch (e) {
      LoggerService.error('[HomeScreen] Error loading initial data', error: e);
      if (mounted) {
        setState(
          () => _errorMessage = ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    }
  }

  void _onGlobalRefresh() {
    LoggerService.info('[HomeScreen] Received global refresh notification');
    _refreshDashboard();
  }

  @override
  void dispose() {
    _pageController.dispose();
    RefreshNotifier().removeListener(_onGlobalRefresh);
    super.dispose();
  }

  Future<void> _loadDefaultTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final idx = prefs.getInt('default_tab_index') ?? 0;
      setState(() => _currentIndex = idx);
      _pageController.jumpToPage(idx);
    } catch (e) {
      LoggerService.error('[HomeScreen] Error loading default tab', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  const HomeHeader(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentIndex = i),
                      children: [
                        _buildDashboardTab(),
                        TabPlaceholders.buildTransactionsTab(),
                        const MoreTabScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          _pageController.jumpToPage(i);
        },
        pageController: _pageController,
      ),
      floatingActionButton: const HomeFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDashboardTab() {
    final l10n = AppLocalizations.of(context);
    if (_errorMessage != null) return _buildErrorState();
    return ResponsiveContent(
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshDashboard,
        color: DesignTokens.primaryColor,
        backgroundColor: DesignTokens.surfaceDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsiveHelper.padding(context),
          child: Column(
            children: [
              FinancialSummaryCard(key: ValueKey('summary_$_refreshCounter')),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),
              const QuickActionsEnhanced(),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),
              ExpandableSection(
                title: l10n?.budget ?? 'Anggaran',
                icon: Iconsax.wallet,
                initiallyExpanded: true,
                child: BudgetProgress(key: ValueKey('budget_$_refreshCounter')),
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
              ExpandableSection(
                title: l10n?.ai_recommendations ?? 'AI Rekomendasi',
                icon: Iconsax.lamp_1,
                initiallyExpanded: false,
                accentColor: DesignTokens.warningColor,
                child: const AIRecommendations(),
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
              ExpandableSection(
                title: l10n?.health_score ?? 'Skor Kesehatan',
                icon: Iconsax.health,
                initiallyExpanded: false,
                accentColor: DesignTokens.successColor,
                child: HealthScoreCard(
                  key: ValueKey('health_$_refreshCounter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.verticalSpacing(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n?.error ?? 'Terjadi kesalahan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
            Semantics(
              liveRegion: true,
              child: Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 24)),
            Semantics(
              label: l10n?.try_again ?? 'Coba lagi',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _errorMessage = null);
                  _loadInitialData();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.try_again ?? 'Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    try {
      final controller = context.read<DashboardController>();
      await controller.refresh();
      if (controller.error != null && mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(controller.error!),
        );
      } else {
        LoggerService.success('[HomeScreen] Dashboard refreshed successfully');
      }
    } catch (e) {
      LoggerService.error('[HomeScreen] Refresh failed', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    }
    if (mounted) {
      setState(() => _refreshCounter++);
    }
  }
}
