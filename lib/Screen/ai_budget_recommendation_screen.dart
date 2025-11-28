import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
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

      // Get financial summary
      final summary = await _apiService.getFinancialSummary();
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) {
        setState(() {
          _error = 'Tidak ada data keuangan tersedia';
          _isLoading = false;
        });
        return;
      }

      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;

      // Get recurring transactions and bills (with error handling)
      double monthlyRecurringExpenses = 0.0;

      try {
        final recurringTransactions =
            await _apiService.getRecurringTransactions();
        // Sum recurring transactions
        for (var recurring in recurringTransactions) {
          if (recurring['type'] == 'expense' &&
              recurring['is_active'] == true) {
            final amount = (recurring['amount'] ?? 0.0).toDouble();
            monthlyRecurringExpenses += amount;
          }
        }
      } catch (e) {
        print('⚠️ Could not fetch recurring transactions: $e');
      }

      try {
        final bills = await _apiService.getObligations();
        // Sum bills/obligations
        for (var bill in bills) {
          if (bill['status_232143'] == 'active') {
            final monthlyAmountRaw = bill['monthly_amount_232143'];
            final amount =
                monthlyAmountRaw is num
                    ? monthlyAmountRaw.toDouble()
                    : (double.tryParse(monthlyAmountRaw?.toString() ?? '0') ??
                        0.0);
            monthlyRecurringExpenses += amount;
          }
        }
      } catch (e) {
        print('⚠️ Could not fetch obligations: $e');
      }

      // Generate AI budget recommendation with recurring expenses data
      final recommendation = _generateBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
      );

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
            (recCategory['percentage'] as int).toDouble();
        final amount = income * (percentage / 100);

        // Find matching category in user's categories
        final matchingCategory = _findMatchingCategory(
          categories,
          categoryName,
        );

        if (matchingCategory != null) {
          try {
            // Create budget for this category
            await _apiService.post('budgets', {
              'category_id': matchingCategory['id'],
              'amount': amount,
              'period': 'monthly',
              'alert_threshold': 80,
            });
            successCount++;
          } catch (e) {
            print('Error creating budget for $categoryName: $e');
            errorCount++;
          }
        }
      }

      if (mounted) {
        setState(() => _isApplying = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount budget berhasil dibuat! ${errorCount > 0 ? "$errorCount gagal." : ""}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after showing message
        if (successCount > 0) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat budget: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
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
      final categoryName = (category['name'] as String? ?? '').toLowerCase();
      for (var possibleName in possibleNames) {
        if (categoryName.contains(possibleName.toLowerCase())) {
          return category;
        }
      }
    }

    return null;
  }

  void _showEditDialog(String categoryName, int currentPercentage) {
    final controller = TextEditingController(
      text: currentPercentage.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Edit Persentase',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Persentase (%)',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF8B5FBF)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '💡 Pastikan total semua persentase = 100%',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newPercentage = double.tryParse(controller.text);
                  if (newPercentage != null &&
                      newPercentage > 0 &&
                      newPercentage <= 100) {
                    setState(() {
                      _editedPercentages[categoryName] = newPercentage;
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Masukkan persentase yang valid (1-100)',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Map<String, dynamic> _generateBudgetRecommendation(
    double income,
    double monthlyRecurringExpenses,
  ) {
    // Smart budget recommendation that adapts to user's recurring bills
    // Base: 50/30/20 Rule adapted for Indonesian context
    // Adjusted based on recurring expenses (bills, subscriptions)

    // Calculate available income after recurring expenses
    final availableIncome = income - monthlyRecurringExpenses;
    final recurringPercentage =
        income > 0 ? (monthlyRecurringExpenses / income) * 100 : 0;

    // Adjust percentages if recurring expenses are high
    double needsPercentage = 50;

    // If recurring expenses exceed typical needs allocation, adjust
    if (recurringPercentage > 30) {
      needsPercentage = recurringPercentage + 10; // Add buffer
      // Wants will be reduced to 25%, Savings calculated as remainder
    }

    return {
      'total_income': income,
      'monthly_recurring_expenses': monthlyRecurringExpenses,
      'available_income': availableIncome,
      'categories': [
        // Recurring Bills & Subscriptions (if any)
        if (monthlyRecurringExpenses > 0)
          {
            'name': 'Tagihan & Langganan Rutin',
            'percentage': recurringPercentage.toInt(),
            'amount': monthlyRecurringExpenses,
            'icon': Iconsax.receipt_2,
            'color': const Color(0xFFFF5252),
            'description': '⚡ Dari tagihan & langganan Anda yang aktif',
            'subcategories': [
              {
                'name': '✓ Total pengeluaran rutin bulanan',
                'percentage': recurringPercentage.toInt(),
                'amount': monthlyRecurringExpenses,
              },
            ],
          },
        {
          'name': 'Kebutuhan Pokok',
          'percentage': needsPercentage.toInt(),
          'amount': income * (needsPercentage / 100),
          'icon': Iconsax.home,
          'color': const Color(0xFF4CAF50),
          'description': 'Kebutuhan dasar & tagihan bulanan',
          'subcategories': [
            {
              'name': 'Makanan & Bahan Pokok',
              'percentage': 20,
              'amount': income * 0.20,
            },
            {'name': 'Transportasi', 'percentage': 10, 'amount': income * 0.10},
            {
              'name': 'Tagihan (Listrik, Air, Internet)',
              'percentage': 10,
              'amount': income * 0.10,
            },
            {
              'name': 'Cicilan/Hutang (jika ada)',
              'percentage': (needsPercentage - 40).toInt(),
              'amount': income * ((needsPercentage - 40) / 100),
            },
          ],
        },
        {
          'name': 'Dana Darurat',
          'percentage': 10,
          'amount': income * 0.10,
          'icon': Iconsax.shield_tick,
          'color': const Color(0xFFFF9800),
          'description': 'Simpan untuk keadaan darurat',
          'subcategories': [
            {
              'name': 'Target: 6 bulan pengeluaran',
              'percentage': 10,
              'amount': income * 0.10,
            },
          ],
        },
        {
          'name': 'Tabungan & Investasi',
          'percentage': 10,
          'amount': income * 0.10,
          'icon': Iconsax.chart,
          'color': const Color(0xFF2196F3),
          'description': 'Tabungan jangka panjang & investasi',
          'subcategories': [
            {
              'name': 'Reksadana/Saham',
              'percentage': 5,
              'amount': income * 0.05,
            },
            {'name': 'Deposito/Emas', 'percentage': 5, 'amount': income * 0.05},
          ],
        },
        {
          'name': 'Hiburan & Lifestyle',
          'percentage': 20,
          'amount': income * 0.20,
          'icon': Iconsax.music,
          'color': const Color(0xFFE91E63),
          'description': 'Keinginan & hiburan',
          'subcategories': [
            {'name': 'Makan di Luar', 'percentage': 8, 'amount': income * 0.08},
            {
              'name': 'Hobi & Hiburan',
              'percentage': 7,
              'amount': income * 0.07,
            },
            {
              'name': 'Shopping & Fashion',
              'percentage': 5,
              'amount': income * 0.05,
            },
          ],
        },
        {
          'name': 'Pendidikan & Pengembangan',
          'percentage': 5,
          'amount': income * 0.05,
          'icon': Iconsax.book,
          'color': const Color(0xFF9C27B0),
          'description': 'Kursus, buku, pelatihan',
          'subcategories': [
            {
              'name': 'Belajar skill baru',
              'percentage': 5,
              'amount': income * 0.05,
            },
          ],
        },
        {
          'name': 'Amal & Sedekah',
          'percentage': 5,
          'amount': income * 0.05,
          'icon': Iconsax.heart,
          'color': const Color(0xFF00BCD4),
          'description': 'Berbagi dengan sesama',
          'subcategories': [
            {
              'name': 'Donasi & Zakat',
              'percentage': 5,
              'amount': income * 0.05,
            },
          ],
        },
      ],
    };
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
              ? const Center(child: CircularProgressIndicator())
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
                                '💡 Berdasarkan aturan 50/30/20 yang disesuaikan',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
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
                          .map((category) => _buildCategoryCard(category))
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
                      _buildTipsSection(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
              size: 24,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  final categoryName = category['name'] as String;
                  final currentPercentage =
                      _editedPercentages[categoryName]?.toInt() ??
                      category['percentage'] as int;
                  _showEditDialog(categoryName, currentPercentage);
                },
                icon: const Icon(Iconsax.edit, size: 20),
                color: const Color(0xFF8B5FBF),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
            ],
          ),
          title: Text(
            category['name'],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                category['description'],
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_editedPercentages[category['name']]?.toInt() ?? category['percentage']}%',
                      style: GoogleFonts.poppins(
                        color: category['color'] as Color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.formatRupiah(
                      (_editedPercentages[category['name']] != null
                          ? (_budgetRecommendation!['total_income'] as double) *
                              (_editedPercentages[category['name']]! / 100)
                          : category['amount']),
                    ),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),
                  ...(category['subcategories'] as List).map(
                    (sub) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: category['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    sub['name'],
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.formatRupiah(sub['amount']),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${sub['percentage']}%',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.lamp, color: Color(0xFFFFB74D), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips Mengelola Budget',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            '1. Prioritaskan dana darurat minimal 6 bulan pengeluaran',
          ),
          _buildTipItem(
            '2. Sisihkan tabungan dan investasi di awal bulan (pay yourself first)',
          ),
          _buildTipItem(
            '3. Tinjau dan sesuaikan budget setiap bulan sesuai kebutuhan',
          ),
          _buildTipItem(
            '4. Gunakan metode amplop untuk kategori yang sering over budget',
          ),
          _buildTipItem(
            '5. Batasi pengeluaran impulsif dengan aturan tunggu 24 jam',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.tick_circle, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
