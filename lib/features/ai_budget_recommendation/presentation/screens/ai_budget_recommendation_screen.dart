import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/ai_budget_recommendation/presentation/controllers/ai_budget_controller.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';

class AIBudgetRecommendationScreen extends StatefulWidget {
  const AIBudgetRecommendationScreen({super.key});

  @override
  State<AIBudgetRecommendationScreen> createState() => _AIBudgetRecommendationScreenState();
}

class _AIBudgetRecommendationScreenState extends State<AIBudgetRecommendationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rekomendasi Budget AI',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Consumer<AIBudgetController>(
              builder: (_, ctrl, __) {
                if (ctrl.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
                }
                if (ctrl.error != null && ctrl.recommendation == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.info_circle, color: Colors.red, size: 48),
                        const SizedBox(height: DesignTokens.spacing4),
                        Text(
                          ctrl.error!,
                          style: GoogleFonts.poppins(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.spacing4),
                        ElevatedButton(
                          onPressed: ctrl.loadRecommendation,
                          style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
                          child: Text('Coba Lagi', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
                final rec = ctrl.recommendation!;
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacing4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(rec, ctrl),
                        const SizedBox(height: DesignTokens.spacing6),
                        _buildAllocationSection(rec, ctrl),
                        const SizedBox(height: DesignTokens.spacing6),
                        _buildApplyButton(ctrl),
                        const SizedBox(height: DesignTokens.spacing6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> rec, AIBudgetController ctrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.primaryColor, DesignTokens.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.magic_star, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommendation',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Bulanan', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              GestureDetector(
                onTap: _showIncomeEditDialog,
                child: Row(
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format((rec['total_income'] as num?)?.toDouble() ?? 0),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Iconsax.edit, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing2),
          if (rec['period'] != null)
            Text(rec['period'].toString(), style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: DesignTokens.spacing4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Kategori', '${rec['categories']?.length ?? 0}', Iconsax.category),
              _buildStatItem('Sisa', _formatCurrency((rec['total_income'] as num?)?.toDouble() ?? 0), Iconsax.money),
              _buildStatItem('Alokasi', '${rec['categories']?.length ?? 0} item', Iconsax.tick_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: DesignTokens.spacing1),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildAllocationSection(Map<String, dynamic> rec, AIBudgetController ctrl) {
    final categories = rec['categories'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alokasi per Kategori',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: DesignTokens.spacing3),
        ...categories.map((cat) {
          final catMap = cat as Map<String, dynamic>;
          final name = catMap['name']?.toString() ?? 'Kategori';
          final percentage = (catMap['percentage'] as num?)?.toDouble() ?? 0;
          final amount = (catMap['amount'] as num?)?.toDouble() ?? 0;
          final notes = catMap['notes']?.toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(DesignTokens.spacing4),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount),
                      style: GoogleFonts.poppins(
                        color: DesignTokens.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacing2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.primaryColor),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}% dari total',
                      style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11),
                    ),
                    if (notes != null)
                      Text(
                        notes,
                        style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildApplyButton(AIBudgetController ctrl) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [DesignTokens.primaryColor, DesignTokens.secondaryColor]),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: ElevatedButton(
        onPressed: ctrl.isApplying ? null : () => _handleApply(ctrl),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLarge)),
        ),
        child:
            ctrl.isApplying
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.tick_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'Terapkan sebagai Budget',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _handleApply(AIBudgetController ctrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLarge)),
            title: Text('Terapkan Budget?', style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(
              'Budget ini akan otomatis dibuat berdasarkan rekomendasi AI. Anda bisa mengeditnya nanti.',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
                child: Text('Terapkan', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await ctrl.applyRecommendation();
      if (mounted && ctrl.error == null) Navigator.pop(context, true);
    }
  }

  Future<void> _showIncomeEditDialog() async {
    final ctrl = context.read<AIBudgetController>();
    final current = ctrl.editedIncome ?? (ctrl.recommendation?['total_income'] as num?)?.toDouble() ?? 0;
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    final newIncome = await showDialog<double>(
      context: context,
      builder: (c) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLarge)),
          title: Text('Edit Total Budget', style: GoogleFonts.poppins(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan total pendapatan bulanan Anda',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Total Pendapatan',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey),
                  prefixText: 'Rp ',
                  prefixStyle: GoogleFonts.poppins(color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: DesignTokens.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing3),
              Text(
                'Jumlah ini akan digunakan untuk menghitung ulang alokasi budget per kategori',
                style: GoogleFonts.poppins(color: Colors.orange, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(controller.text.replaceAll(',', ''));
                if (v != null && v > 0) {
                  Navigator.pop(c, v);
                } else {
                  ErrorHandlerService.showWarningSnackbar(c, 'Masukkan jumlah yang valid');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
              child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (newIncome != null && newIncome > 0) ctrl.setEditedIncome(newIncome);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }
}
