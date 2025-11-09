import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/api_service.dart';

class FinancialSummaryCard extends StatefulWidget {
  const FinancialSummaryCard({super.key});

  @override
  State<FinancialSummaryCard> createState() => _FinancialSummaryCardState();

  static void refresh(BuildContext context) {
    final state = context.findAncestorStateOfType<_FinancialSummaryCardState>();
    state?.refreshSummary();
  }
}

class _FinancialSummaryCardState extends State<FinancialSummaryCard> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
  }

  Future<void> _loadFinancialSummary() async {
    try {
      final summary = await _apiService.getFinancialSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error - show default values
    }
  }

  void refreshSummary() {
    _loadFinancialSummary();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5FBF), Color(0xFF6A3093)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5FBF).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final Map<String, dynamic> summaries = _summary?['summary'] ?? {};
    final income =
        (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ?? 0.0;
    final expense =
        (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ?? 0.0;
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5FBF), Color(0xFF6A3093)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5FBF).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Balance
          Text(
            'Saldo Bulan Ini',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatRupiah(balance),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Income vs Expense
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFinanceItem(
                title: 'Pemasukan',
                amount: CurrencyFormatter.formatRupiah(income),
                color: Colors.green[400]!,
                icon: Iconsax.arrow_up,
              ),
              _buildFinanceItem(
                title: 'Pengeluaran',
                amount: CurrencyFormatter.formatRupiah(expense),
                color: Colors.red[400]!,
                icon: Iconsax.arrow_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceItem({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
