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
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/l10n/app_localizations.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ObligationFilters _filters = ObligationFilters();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          AppLocalizations.of(context)!.financial_obligations,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Iconsax.filter, color: Colors.white),
                if (_filters.hasFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5FBF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFiltersDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(),

          // Search Bar
          Padding(
            padding: ResponsiveHelper.horizontalPadding(context),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey[800]!.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search_obligations,
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Iconsax.search_normal,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]!.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),

          // View Selector
          ObligationViewTabs(
            selectedView: _selectedView,
            onViewChanged: (value) => setState(() => _selectedView = value),
          ),

          // Content based on selected view
          Expanded(child: _buildSelectedView()),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5FBF), Color(0xFF6B4C93)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5FBF).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'obligations_fab',
          onPressed: () async {
            final result = await ObligationHelpers.showAddObligationModal(
              context,
            );
            if (result == true) {
              _refreshScreen();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Iconsax.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('summary_$_refreshKey'),
      future: _getEnhancedSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            ),
          );
        }

        final summary = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // First Row: Monthly Total and Total Debt
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 'all'),
                      child: _buildSummaryCard(
                        AppLocalizations.of(context)!.monthly_total,
                        'Rp ${summary['monthlyTotal']?.toStringAsFixed(0) ?? '0'}',
                        Colors.blue,
                        Iconsax.calendar,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 'debts'),
                      child: _buildSummaryCard(
                        AppLocalizations.of(context)!.total_debt,
                        'Rp ${summary['totalDebt']?.toStringAsFixed(0) ?? '0'}',
                        Colors.red,
                        Iconsax.card,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second Row: Due This Week and Overdue
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 'upcoming'),
                      child: _buildSummaryCard(
                        AppLocalizations.of(context)!.due_this_week,
                        '${summary['dueThisWeek'] ?? 0} ${AppLocalizations.of(context)!.obligations_count}',
                        Colors.orange,
                        Iconsax.clock,
                        isCount: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Filter to show overdue
                        setState(() => _selectedView = 'all');
                        // TODO: Add filter for overdue
                      },
                      child: _buildSummaryCard(
                        AppLocalizations.of(context)!.overdue_count,
                        '${summary['overdue'] ?? 0} ${AppLocalizations.of(context)!.obligations_count}',
                        Colors.red,
                        Iconsax.warning_2,
                        isCount: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getEnhancedSummary() async {
    try {
      final summary = await ObligationService().getObligationsSummary();
      final obligations = await ObligationService().getObligations();

      final now = DateTime.now();
      final endOfWeek = now.add(Duration(days: 7 - now.weekday));

      int dueThisWeek = 0;
      int overdue = 0;

      for (var obligation in obligations) {
        if (obligation.daysUntilDue < 0) {
          overdue++;
        } else if (obligation.dueDate.isBefore(endOfWeek) ||
            obligation.dueDate.isAtSameMomentAs(endOfWeek)) {
          dueThisWeek++;
        }
      }

      return {...summary, 'dueThisWeek': dueThisWeek, 'overdue': overdue};
    } catch (e) {
      return {
        'monthlyTotal': 0.0,
        'totalDebt': 0.0,
        'dueThisWeek': 0,
        'overdue': 0,
      };
    }
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case 'all':
        return AllObligationsView(
          key: ValueKey('all_$_refreshKey'),
          searchQuery: _searchQuery,
        );
      case 'upcoming':
        return UpcomingObligationsView(
          key: ValueKey('upcoming_$_refreshKey'),
          searchQuery: _searchQuery,
        );
      case 'debts':
        return DebtsView(
          key: ValueKey('debts_$_refreshKey'),
          searchQuery: _searchQuery,
        );
      case 'subscriptions':
        return SubscriptionsView(
          key: ValueKey('subscriptions_$_refreshKey'),
          searchQuery: _searchQuery,
        );
      default:
        return AllObligationsView(
          key: ValueKey('all_$_refreshKey'),
          searchQuery: _searchQuery,
        );
    }
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1F1F1F), const Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (isCount && (amount.contains('0') == false))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    amount.split(' ')[0],
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isCount ? 15 : 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ObligationFiltersWidget(
              initialFilters: _filters,
              onFiltersChanged: (filters) {
                setState(() {
                  _filters = filters;
                });
              },
            ),
          ),
    );
  }
}
