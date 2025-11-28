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
import 'package:financial_app/widgets/home/quick_actions.dart';
import 'package:financial_app/widgets/home/budget_progress.dart';
import 'package:financial_app/widgets/home/recent_transactions.dart';
import 'package:financial_app/widgets/home/ai_recommendations.dart';
import 'package:financial_app/widgets/home/quick_add_widget.dart';
import 'package:financial_app/widgets/home/bottom_nav_bar.dart';
import 'package:financial_app/widgets/home/floating_action_button.dart';
import 'package:financial_app/widgets/home/tab_placeholders.dart';
import 'package:financial_app/utils/app_refresh.dart';

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
    print('🎬 [HomeScreen] Triggering initial data load...');
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadInitialData();
      print('✅ [HomeScreen] Initial data load completed');
    } catch (e) {
      print('❌ [HomeScreen] Error loading initial data: $e');
    }
  }

  void _onGlobalRefresh() {
    print('🔔 [HomeScreen] Received global refresh notification');
    _refreshDashboard();
  }

  @override
  void dispose() {
    RefreshNotifier().removeListener(_onGlobalRefresh);
    super.dispose();
  }

  void _loadLocationRecommendations() {
    setState(() {
      print('🔄 [HomeScreen] Loading location recommendations...');
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
      body: SafeArea(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Financial Summary Card (forced refresh with key)
            FinancialSummaryCard(key: ValueKey('summary_$_refreshCounter')),
            const SizedBox(height: 20),

            // Quick Actions
            const QuickActions(),
            const SizedBox(height: 20),

            // Quick Add Widget
            QuickAddWidget(
              key: ValueKey('quick_add_$_refreshCounter'),
              onTransactionAdded: _refreshDashboard,
            ),
            const SizedBox(height: 20),

            // Location-Based Recommendations (rebuild with counter)
            KeyedSubtree(
              key: ValueKey('location_recs_$_refreshCounter'),
              child: _buildLocationRecommendations(),
            ),
            const SizedBox(height: 20),

            // Budget Progress (forced refresh with key)
            BudgetProgress(key: ValueKey('budget_$_refreshCounter')),
            const SizedBox(height: 20),

            // Recent Transactions (forced refresh with key)
            RecentTransactions(key: ValueKey('transactions_$_refreshCounter')),
            const SizedBox(height: 20),

            // AI Recommendations
            const AIRecommendations(),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    print('🔄 [HomeScreen] Refreshing dashboard...');
    // Trigger refresh for all dashboard widgets
    setState(() {
      _refreshCounter++; // Increment to force widget rebuilds
      // Reload location recommendations on manual refresh
      print('🔄 [HomeScreen] Reloading location recommendations...');
      _locationRecommendationsFuture =
          LocationIntelligenceService().generateLocationInsights();
    });
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    print('✅ [HomeScreen] Dashboard refreshed (counter: $_refreshCounter)');
  }

  // Location Recommendations Section
  Widget _buildLocationRecommendations() {
    print('🏗️ [HomeScreen] Building location recommendations widget');
    return FutureBuilder<List<LocationRecommendation>>(
      future: _locationRecommendationsFuture,
      builder: (context, snapshot) {
        print(
          '🔍 [FutureBuilder] State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}, DataLength: ${snapshot.data?.length ?? 0}',
        );

        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ [LocationRecommendations] Loading...');
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5FBF),
                strokeWidth: 2,
              ),
            ),
          );
        }

        // Show error state (with debug info)
        if (snapshot.hasError) {
          print('❌ [LocationRecommendations] Error: ${snapshot.error}');
          print('❌ Stack trace: ${snapshot.stackTrace}');
          return Container(); // Hide on error
        }

        // Handle empty data - SHOW the section with helpful message
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print(
            'ℹ️ [LocationRecommendations] No recommendations available (hasData: ${snapshot.hasData}, isEmpty: ${snapshot.data?.isEmpty})',
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
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rekomendasi Lokal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.location_tick,
                      color: Colors.grey[600],
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum Ada Rekomendasi',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tambahkan lokasi saat mencatat pengeluaran untuk mendapat rekomendasi hemat',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final recommendations = snapshot.data!;
        print(
          '✅ [LocationRecommendations] Showing ${recommendations.length} recommendations',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.location,
                  color: const Color(0xFF8B5FBF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Lokal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
          ),
          if (recommendation.estimatedSavings > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Perkiraan penghematan: Rp ${recommendation.estimatedSavings.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B5FBF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Icon _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.price_alert:
        return Icon(Iconsax.warning_2, color: Colors.orange, size: 20);
      case RecommendationType.alternative_location:
        return Icon(Iconsax.location, color: Colors.blue, size: 20);
      case RecommendationType.spending_pattern:
        return Icon(Iconsax.chart, color: Colors.green, size: 20);
      default:
        return Icon(
          Iconsax.info_circle,
          color: const Color(0xFF8B5FBF),
          size: 20,
        );
    }
  }
}
