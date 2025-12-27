import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/budget_recommendation_service.dart';
import 'package:financial_app/widgets/budget_recommendation/budget_category_card.dart';
import 'package:financial_app/widgets/budget_recommendation/budget_edit_dialog.dart';
import 'package:financial_app/widgets/budget_recommendation/budget_tips_section.dart';
import 'package:financial_app/utils/formatters.dart';

class AIBudgetRecommendationScreen extends StatefulWidget {
  const AIBudgetRecommendationScreen({super.key});

  @override
  State<AIBudgetRecommendationScreen> createState() =>
      _AIBudgetRecommendationScreenState();
}

class _AIBudgetRecommendationScreenState
    extends State<AIBudgetRecommendationScreen> {
  final ApiService _apiService = ApiService();
  final BudgetRecommendationService _budgetService =
      BudgetRecommendationService();
  bool _isLoading = true;
  bool _isApplying = false;
  Map<String, dynamic>? _budgetRecommendation;
  Map<String, double> _editedPercentages = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBudgetRecommendation();
  }

  Future<void> _loadBudgetRecommendation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Generate AI budget recommendation using service
      final recommendation = await _budgetService.generateRecommendation();

      setState(() {
        _budgetRecommendation = recommendation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat rekomendasi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyRecommendationAsBudgets() async {
    if (_budgetRecommendation == null) return;

    setState(() => _isApplying = true);

    try {
      final categories = await _apiService.getCategories();
      final income = _budgetRecommendation!['total_income'] as double;
      final recommendedCategories =
          _budgetRecommendation!['categories'] as List;

      int successCount = 0;
      int errorCount = 0;

      // Create budgets for main categories
      for (var recCategory in recommendedCategories) {
        final categoryName = recCategory['name'] as String;
        final percentage =
            _editedPercentages[categoryName] ??
            ((recCategory['percentage'] as num?)?.toDouble() ?? 0.0);
        final amount = income * (percentage / 100);

        // Find matching category in user's categories
        final matchingCategory = _findMatchingCategory(
          categories,
          categoryName,
        );

        if (matchingCategory != null) {
          try {
            // Create budget for this category
            final now = DateTime.now();
            final periodStart = DateTime(now.year, now.month, 1);
            final periodEnd = DateTime(now.year, now.month + 1, 0);

            // Use correct field name for category_id
            final categoryId =
                matchingCategory['category_id_232143'] ??
                matchingCategory['id'];
            if (categoryId == null) {
              LoggerService.warning('Category ID not found for $categoryName');
              errorCount++;
              continue;
            }

            await _apiService.createBudget({
              'category_id': categoryId,
              'amount': amount,
              'period': 'monthly',
              'period_start': periodStart.toIso8601String().split('T')[0],
              'period_end': periodEnd.toIso8601String().split('T')[0],
              'alert_threshold': 80,
            });
            successCount++;
          } catch (e) {
            LoggerService.error(
              'Error creating budget for $categoryName',
              error: e,
            );
            errorCount++;
          }
        }
      }

      if (mounted) {
        setState(() => _isApplying = false);

        // Show success message
        if (successCount > 0) {
          ErrorHandlerService.showSuccessSnackbar(
            context,
            '$successCount budget berhasil dibuat!${errorCount > 0 ? " $errorCount gagal." : ""}',
          );
          // Navigate back after showing message
          if (mounted) Navigator.pop(context, true);
        } else {
          ErrorHandlerService.showWarningSnackbar(
            context,
            'Gagal membuat budget. Silakan coba lagi.',
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error applying budget recommendations', error: e);
      if (mounted) {
        setState(() => _isApplying = false);
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    }
  }

  Map<String, dynamic>? _findMatchingCategory(
    List<dynamic> categories,
    String recommendationName,
  ) {
    // Map recommendation names to category names
    final mappings = {
      'Kebutuhan Pokok': ['Makanan', 'Food', 'Groceries'],
      'Dana Darurat': ['Tabungan', 'Savings', 'Emergency'],
      'Tabungan & Investasi': ['Investasi', 'Investment', 'Savings'],
      'Hiburan & Lifestyle': ['Hiburan', 'Entertainment', 'Lifestyle'],
      'Pendidikan & Pengembangan': ['Pendidikan', 'Education', 'Learning'],
      'Amal & Sedekah': ['Amal', 'Charity', 'Donation'],
    };

    final possibleNames = mappings[recommendationName] ?? [recommendationName];

    for (var category in categories) {
      // Support both old and new field names
      final categoryName =
          (category['name_232143'] ?? category['name'] ?? '')
              .toString()
              .toLowerCase();
      for (var possibleName in possibleNames) {
        if (categoryName.contains(possibleName.toLowerCase())) {
          return category;
        }
      }
    }

    return null;
  }

  Future<void> _showEditDialog(
    String categoryName,
    int currentPercentage,
  ) async {
    final newPercentage = await BudgetEditDialog.show(
      context,
      categoryName: categoryName,
      currentPercentage: currentPercentage,
    );

    if (newPercentage != null) {
      setState(() {
        _editedPercentages[categoryName] = newPercentage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rekomendasi Budget AI',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              )
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBudgetRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                      ),
                      child: Text(
                        'Coba Lagi',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5FBF), Color(0xFF6A4C9C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.flash,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Budget Planner',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Pendapatan Bulanan',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatRupiah(
                                _budgetRecommendation!['total_income'],
                              ),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _budgetRecommendation!['is_new_user'] == true
                                    ? '💡 Template standar untuk user baru - akan disesuaikan setelah ada transaksi'
                                    : '💡 Berdasarkan aturan 50/30/20 yang disesuaikan dengan pola pengeluaran Anda',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (_budgetRecommendation!['is_new_user'] ==
                                true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Iconsax.info_circle,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _budgetRecommendation!['message']
                                                as String? ??
                                            'Mulai catat transaksi untuk mendapatkan rekomendasi yang lebih personal',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Budget Categories
                      Text(
                        'Alokasi Budget yang Disarankan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Cards
                      ...(_budgetRecommendation!['categories'] as List)
                          .map(
                            (category) => BudgetCategoryCard(
                              category: category,
                              editedPercentages: _editedPercentages,
                              totalIncome:
                                  _budgetRecommendation!['total_income']
                                      as double,
                              onEdit: () {
                                final categoryName = category['name'] as String;
                                final currentPercentage =
                                    _editedPercentages[categoryName]?.toInt() ??
                                    ((category['percentage'] as num?)
                                            ?.toInt() ??
                                        0);
                                _showEditDialog(
                                  categoryName,
                                  currentPercentage,
                                );
                              },
                            ),
                          )
                          .toList(),

                      const SizedBox(height: 24),

                      // Apply Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5FBF), Color(0xFF6A4C9C)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed:
                              _isApplying
                                  ? null
                                  : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            backgroundColor: const Color(
                                              0xFF1A1A1A,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Text(
                                              'Terapkan Budget?',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                              ),
                                            ),
                                            content: Text(
                                              'Budget ini akan otomatis dibuat berdasarkan rekomendasi AI. Anda bisa mengeditnya nanti.',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  'Batal',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF8B5FBF,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Terapkan',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirmed == true) {
                                      await _applyRecommendationAsBudgets();
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isApplying
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Iconsax.tick_circle,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Terapkan sebagai Budget',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tips Section
                      const BudgetTipsSection(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }
}
