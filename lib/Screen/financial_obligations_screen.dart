import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_view_tabs.dart';
import 'package:financial_app/widgets/obligations/all_obligations_view.dart';
import 'package:financial_app/widgets/obligations/upcoming_obligations_view.dart';
import 'package:financial_app/widgets/obligations/debts_view.dart';
import 'package:financial_app/widgets/obligations/subscriptions_view.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';

class FinancialObligationsScreen extends StatefulWidget {
  const FinancialObligationsScreen({super.key});

  @override
  State<FinancialObligationsScreen> createState() =>
      _FinancialObligationsScreenState();
}

class _FinancialObligationsScreenState
    extends State<FinancialObligationsScreen> {
  String _selectedView = 'all'; // 'all', 'upcoming', 'debts', 'subscriptions'
  int _refreshKey = 0;

  void _refreshScreen() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Kewajiban Finansial',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(),

          // View Selector
          ObligationViewTabs(
            selectedView: _selectedView,
            onViewChanged: (value) => setState(() => _selectedView = value),
          ),

          // Content based on selected view
          Expanded(child: _buildSelectedView()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'obligations_fab',
        onPressed: () async {
          final result = await ObligationHelpers.showAddObligationModal(
            context,
          );
          if (result == true) {
            _refreshScreen();
          }
        },
        child: Icon(Iconsax.add),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('summary_$_refreshKey'),
      future: ObligationService().getObligationsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final summary = snapshot.data!;

        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Monthly Obligations
              Expanded(
                child: _buildSummaryCard(
                  'Bulan Ini',
                  'Rp ${summary['monthlyTotal']?.toStringAsFixed(0) ?? '0'}',
                  Colors.blue,
                  Iconsax.calendar,
                ),
              ),
              SizedBox(width: 12),

              // Total Debt
              Expanded(
                child: _buildSummaryCard(
                  'Total Hutang',
                  'Rp ${summary['totalDebt']?.toStringAsFixed(0) ?? '0'}',
                  Colors.red,
                  Iconsax.card,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case 'all':
        return AllObligationsView(key: ValueKey('all_$_refreshKey'));
      case 'upcoming':
        return UpcomingObligationsView(key: ValueKey('upcoming_$_refreshKey'));
      case 'debts':
        return DebtsView(key: ValueKey('debts_$_refreshKey'));
      case 'subscriptions':
        return SubscriptionsView(key: ValueKey('subscriptions_$_refreshKey'));
      default:
        return AllObligationsView(key: ValueKey('all_$_refreshKey'));
    }
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
