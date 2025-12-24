import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/widgets/home/home_header.dart';
import 'package:financial_app/widgets/home/financial_summary_card.dart';
import 'package:financial_app/widgets/home/budget_progress.dart';
import 'package:financial_app/widgets/home/ai_recommendations.dart';
import 'package:financial_app/widgets/home/quick_actions_enhanced.dart';
import 'package:financial_app/widgets/home/bottom_nav_bar.dart';
import 'package:financial_app/widgets/home/floating_action_button.dart';
import 'package:financial_app/widgets/home/tab_placeholders.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/responsive_helper.dart';

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
  int _refreshCounter = 0; // Add refresh counter for forcing widget rebuilds

  @override
  void initState() {
    super.initState();
    _loadDefaultTab();

    // Listen to global refresh notifications
    RefreshNotifier().addListener(_onGlobalRefresh);

    // Load initial data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    LoggerService.info('[HomeScreen] Triggering initial data load...');
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadInitialData();
      LoggerService.success('[HomeScreen] Initial data load completed');
    } catch (e) {
      LoggerService.error('[HomeScreen] Error loading initial data', error: e);
    }
  }

  void _onGlobalRefresh() {
    LoggerService.info('[HomeScreen] Received global refresh notification');
    _refreshDashboard();
  }

  @override
  void dispose() {
    RefreshNotifier().removeListener(_onGlobalRefresh);
    super.dispose();
  }

  Future<void> _loadDefaultTab() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultTabIndex =
        prefs.getInt('default_tab_index') ?? 0; // Default to dashboard (0)
    setState(() {
      _currentIndex = defaultTabIndex;
    });
    _pageController.jumpToPage(defaultTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  const HomeHeader(),

                  // Main Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      children: [
                        _buildDashboardTab(),
                        TabPlaceholders.buildTransactionsTab(),
                        TabPlaceholders.buildGoalsTab(),
                        TabPlaceholders.buildAnalyticsTab(),
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        pageController: _pageController,
      ),
      floatingActionButton: const HomeFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // MARK: - Dashboard Tab
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshDashboard,
      color: const Color(0xFF8B5FBF),
      backgroundColor: const Color(0xFF1A1A1A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.padding(context),
        child: Column(
          children: [
            // Financial Summary Card (forced refresh with key)
            FinancialSummaryCard(key: ValueKey('summary_$_refreshCounter')),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // Quick Actions (Enhanced)
            const QuickActionsEnhanced(),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // Budget Progress (forced refresh with key)
            BudgetProgress(key: ValueKey('budget_$_refreshCounter')),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // AI Recommendations
            const AIRecommendations(),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    LoggerService.info('[HomeScreen] Refreshing dashboard...');
    // Trigger refresh for all dashboard widgets
    setState(() {
      _refreshCounter++; // Increment to force widget rebuilds
    });
    // Note: Removed delay - refresh immediately for better performance
    LoggerService.success(
      '[HomeScreen] Dashboard refreshed (counter: $_refreshCounter)',
    );
  }
}
