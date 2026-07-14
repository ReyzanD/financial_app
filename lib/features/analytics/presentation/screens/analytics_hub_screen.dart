import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:financial_app/features/insights/presentation/screens/financial_insights_screen.dart';
import 'package:financial_app/features/net_worth/presentation/screens/net_worth_screen.dart';
import 'package:financial_app/features/cash_flow/presentation/screens/cash_flow_screen.dart';
import 'package:financial_app/features/report/presentation/screens/report_screen.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Hub screen that consolidates 5 analytics/insights features into tabs:
///   analytics, insights, networth, cashflow, reports
///
/// Pass [initialTab] as one of the keys above to open a specific tab.
class AnalyticsHubScreen extends StatefulWidget {
  final String initialTab;

  const AnalyticsHubScreen({
    super.key,
    this.initialTab = 'analytics',
  });

  @override
  State<AnalyticsHubScreen> createState() => _AnalyticsHubScreenState();
}

class _AnalyticsHubScreenState extends State<AnalyticsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  static const _tabKeys = [
    'analytics',
    'insights',
    'networth',
    'cashflow',
    'reports',
  ];

  static const _tabLabels = [
    'Analitik',
    'Wawasan',
    'Kekayaan',
    'Arus Kas',
    'Laporan',
  ];

  static const _tabIcons = [
    Icons.analytics_outlined,
    Icons.lightbulb_outline,
    Icons.account_balance_wallet_outlined,
    Icons.swap_horiz,
    Icons.description_outlined,
  ];

  int _initialIndex(String tab) {
    final idx = _tabKeys.indexOf(tab);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialIndex(widget.initialTab);
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _tabLabels[_currentIndex],
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: DesignTokens.surfaceDark,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: DesignTokens.primaryColor,
              labelColor: DesignTokens.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: List.generate(5, (i) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tabIcons[i], size: 16),
                      const SizedBox(width: 6),
                      Text(_tabLabels[i]),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AnalyticsScreen(),
          FinancialInsightsScreen(),
          NetWorthScreen(),
          CashFlowScreen(),
          ReportScreen(),
        ],
      ),
    );
  }
}
