import 'package:flutter/material.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Service untuk generate AI budget recommendations
class BudgetRecommendationService {
  final ApiService _apiService = ApiService();

  /// Generate budget recommendation berdasarkan income dan recurring expenses
  Future<Map<String, dynamic>> generateRecommendation() async {
    try {
      // Get financial summary
      final summary = await _apiService.getFinancialSummary();
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) {
        throw Exception('Tidak ada data keuangan tersedia');
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
        LoggerService.warning('Could not fetch recurring transactions', error: e);
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
        LoggerService.warning('Could not fetch obligations', error: e);
      }

      // Generate AI budget recommendation with recurring expenses data
      return _generateBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
      );
    } catch (e) {
      LoggerService.error('Error generating budget recommendation', error: e);
      rethrow;
    }
  }

  /// Generate budget recommendation structure
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
}

