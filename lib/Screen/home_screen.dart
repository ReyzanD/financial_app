import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/models/location_recommendation.dart';
import 'package:financial_app/services/location_intelligence_service.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/widgets/home/home_header.dart';
import 'package:financial_app/widgets/home/financial_summary_card.dart';
import 'package:financial_app/widgets/home/quick_actions_enhanced.dart';
import 'package:financial_app/widgets/home/budget_progress.dart';
import 'package:financial_app/widgets/home/recent_transactions_enhanced.dart';
import 'package:financial_app/widgets/home/ai_recommendations.dart';
import 'package:financial_app/widgets/home/quick_add_widget_enhanced.dart';
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

  // Cache location recommendations to avoid rebuilding
  Future<List<LocationRecommendation>>? _locationRecommendationsFuture;

  @override
  void initState() {
    super.initState();
    _loadDefaultTab();
    _loadLocationRecommendations();

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

  void _loadLocationRecommendations() {
    setState(() {
      LoggerService.info('[HomeScreen] Loading location recommendations...');
      _locationRecommendationsFuture =
          LocationIntelligenceService().generateLocationInsights();
    });
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

            // Quick Add Widget (Enhanced)
            QuickAddWidgetEnhanced(
              key: ValueKey('quick_add_$_refreshCounter'),
              onTransactionAdded: _refreshDashboard,
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // Location-Based Recommendations (rebuild with counter)
            KeyedSubtree(
              key: ValueKey('location_recs_$_refreshCounter'),
              child: _buildLocationRecommendations(),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // Budget Progress (forced refresh with key)
            BudgetProgress(key: ValueKey('budget_$_refreshCounter')),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // Recent Transactions (Enhanced - forced refresh with key)
            RecentTransactionsEnhanced(key: ValueKey('transactions_$_refreshCounter')),
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
      // Reload location recommendations on manual refresh
      LoggerService.info('[HomeScreen] Reloading location recommendations...');
      _locationRecommendationsFuture =
          LocationIntelligenceService().generateLocationInsights();
    });
    // Note: Removed delay - refresh immediately for better performance
    LoggerService.success('[HomeScreen] Dashboard refreshed (counter: $_refreshCounter)');
  }

  // Location Recommendations Section
  Widget _buildLocationRecommendations() {
    LoggerService.debug('[HomeScreen] Building location recommendations widget');
    return FutureBuilder<List<LocationRecommendation>>(
      future: _locationRecommendationsFuture,
      builder: (context, snapshot) {
        LoggerService.debug(
          '[FutureBuilder] State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, DataLength: ${snapshot.data?.length ?? 0}',
        );

        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          LoggerService.debug('[LocationRecommendations] Loading...');
          return Container(
            padding: ResponsiveHelper.padding(context),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5FBF),
                strokeWidth: 2,
              ),
            ),
          );
        }

        // Show error state (with debug info)
        if (snapshot.hasError) {
          LoggerService.error(
            '[LocationRecommendations] Error',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return Container(); // Hide on error
        }

        // Handle empty data - SHOW the section with helpful message
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          LoggerService.info(
            '[LocationRecommendations] No recommendations available (hasData: ${snapshot.hasData}, isEmpty: ${snapshot.data?.isEmpty})',
          );
          // Still show the section header and a helpful message
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    color: const Color(0xFF8B5FBF),
                    size: ResponsiveHelper.iconSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
                  Text(
                    'Rekomendasi Lokal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
              Container(
                padding: ResponsiveHelper.padding(context),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, 16),
                  ),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.location_tick,
                      color: Colors.grey[600],
                      size: ResponsiveHelper.iconSize(context, 40),
                    ),
                    SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                    Text(
                      'Belum Ada Rekomendasi',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: ResponsiveHelper.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.verticalSpacing(context, 6)),
                    Text(
                      'Tambahkan lokasi saat mencatat pengeluaran untuk mendapat rekomendasi hemat',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: ResponsiveHelper.fontSize(context, 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final recommendations = snapshot.data!;
        LoggerService.success(
          '[LocationRecommendations] Showing ${recommendations.length} recommendations',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.location,
                  color: const Color(0xFF8B5FBF),
                  size: ResponsiveHelper.iconSize(context, 20),
                ),
                SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
                Text(
                  'Rekomendasi Lokal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),

            // Show maximum 2 recommendations
            ...recommendations
                .take(2)
                .map(
                  (recommendation) =>
                      _buildLocationRecommendationCard(recommendation),
                ),
          ],
        );
      },
    );
  }

  Widget _buildLocationRecommendationCard(
    LocationRecommendation recommendation,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.verticalSpacing(context, 12),
      ),
      padding: ResponsiveHelper.padding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 16),
        ),
        border: Border.all(
          color: Color.lerp(Colors.black, Colors.transparent, 0.3)!,
          width: 0.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon based on recommendation type
              _getRecommendationIcon(recommendation.type),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          Text(
            recommendation.description,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: ResponsiveHelper.fontSize(context, 12),
            ),
          ),
          if (recommendation.estimatedSavings > 0) ...[
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
            Text(
              'Perkiraan penghematan: Rp ${recommendation.estimatedSavings.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B5FBF),
                fontSize: ResponsiveHelper.fontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Icon _getRecommendationIcon(RecommendationType type) {
    final iconSize = ResponsiveHelper.iconSize(context, 20);
    switch (type) {
      case RecommendationType.price_alert:
        return Icon(Iconsax.warning_2, color: Colors.orange, size: iconSize);
      case RecommendationType.alternative_location:
        return Icon(Iconsax.location, color: Colors.blue, size: iconSize);
      case RecommendationType.spending_pattern:
        return Icon(Iconsax.chart, color: Colors.green, size: iconSize);
      default:
        return Icon(
          Iconsax.info_circle,
          color: const Color(0xFF8B5FBF),
          size: iconSize,
        );
    }
  }
}
