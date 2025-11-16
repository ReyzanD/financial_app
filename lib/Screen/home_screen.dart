import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/models/location_recommendation.dart';
import 'package:financial_app/widgets/home/home_header.dart';
import 'package:financial_app/widgets/home/financial_summary_card.dart';
import 'package:financial_app/widgets/home/quick_actions.dart';
import 'package:financial_app/widgets/home/budget_progress.dart';
import 'package:financial_app/widgets/home/recent_transactions.dart';
import 'package:financial_app/widgets/home/ai_recommendations.dart';
import 'package:financial_app/widgets/home/bottom_nav_bar.dart';
import 'package:financial_app/widgets/home/floating_action_button.dart';
import 'package:financial_app/widgets/home/tab_placeholders.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDefaultTab();
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
            // Financial Summary Card
            const FinancialSummaryCard(),
            const SizedBox(height: 20),

            // Quick Actions
            const QuickActions(),
            const SizedBox(height: 20),

            // Location-Based Recommendations
            _buildLocationRecommendations(),
            const SizedBox(height: 20),

            // Budget Progress
            const BudgetProgress(),
            const SizedBox(height: 20),

            // Recent Transactions
            const RecentTransactions(),
            const SizedBox(height: 20),

            // AI Recommendations
            const AIRecommendations(),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    // Trigger refresh for all dashboard widgets
    setState(() {});
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Location Recommendations Section
  Widget _buildLocationRecommendations() {
    return FutureBuilder<List<LocationRecommendation>>(
      future: LocationRecommendationService().getDailyLocationInsights(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(); // Don't show if no data
        }

        final recommendations = snapshot.data!;

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
