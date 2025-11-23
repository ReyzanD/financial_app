import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/Screen/budgets_screen.dart';

class BudgetProgress extends StatefulWidget {
  const BudgetProgress({super.key});

  @override
  State<BudgetProgress> createState() => _BudgetProgressState();
}

class _BudgetProgressState extends State<BudgetProgress>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _budgets = [];
  Map<String, String> _categories = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _retryCount = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('📊 Loading budget data (attempt ${_retryCount + 1})...');

      // Load categories and budgets in parallel for better performance
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getBudgets(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final categories = results[0];
      final budgets = results[1];

      print('✅ Categories loaded: ${categories.length}');
      print('✅ Budgets loaded: ${budgets.length}');

      // Build category map
      final categoryMap = <String, String>{};
      for (var cat in categories) {
        final id = cat['id'];
        final name = cat['name'];
        if (id != null && name != null) {
          categoryMap[id.toString()] = name.toString();
        }
      }

      if (mounted) {
        setState(() {
          _categories = categoryMap;
          _budgets = budgets.map((b) => b as Map<String, dynamic>).toList();
          _isLoading = false;
          _errorMessage = null;
          _retryCount = 0;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('❌ Error loading budgets: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });

        // Auto-retry up to 2 times with exponential backoff
        if (_retryCount < 2) {
          _retryCount++;
          final delaySeconds = _retryCount * 2; // 2s, 4s
          print('🔄 Retrying in $delaySeconds seconds...');

          await Future.delayed(Duration(seconds: delaySeconds));
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            _loadData();
          }
        }
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout')) {
      return 'Koneksi timeout. Cek koneksi internet Anda.';
    } else if (errorStr.contains('connection') ||
        errorStr.contains('network')) {
      return 'Gagal terhubung ke server. Pastikan backend berjalan.';
    } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Sesi berakhir. Silakan login kembali.';
    } else {
      return 'Gagal memuat data. Tap untuk coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Progress',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudgetsScreen(),
                  ),
                );
              },
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  color: Color(0xFF8B5FBF),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            ),
          )
        else if (_errorMessage != null)
          GestureDetector(
            onTap: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
                _retryCount = 0;
              });
              _loadData();
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi Kesalahan',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5FBF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8B5FBF)),
                    ),
                    child: Text(
                      'Tap untuk mencoba lagi',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B5FBF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_budgets.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Icon(Icons.wallet_outlined, color: Colors.grey[600], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Belum ada budget',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Buat budget untuk kelola keuangan lebih baik',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children:
                  _budgets.map((budget) => _buildBudgetItem(budget)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget) {
    final categoryId = budget['category_id'] as String?;
    final category =
        categoryId != null && _categories.containsKey(categoryId)
            ? _categories[categoryId]!
            : 'All Categories';

    final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
    final amount = (budget['amount'] as num?)?.toDouble() ?? 1.0;
    final remaining = amount - spent;
    final color = _getCategoryColor(category);

    final percentage = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > amount;
    final displayColor = isOverBudget ? Colors.red : color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget ? Colors.red.withOpacity(0.3) : Colors.grey[800]!,
          width: isOverBudget ? 1.5 : 1,
        ),
        boxShadow:
            isOverBudget
                ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: displayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOverBudget) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 16,
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(spent.toInt()),
                    style: GoogleFonts.poppins(
                      color: displayColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'dari ${CurrencyFormatter.formatRupiah(amount.toInt())}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: percentage),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[850],
                  valueColor: AlwaysStoppedAnimation(displayColor),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget
                    ? 'Melebihi ${CurrencyFormatter.formatRupiah((spent - amount).toInt())}'
                    : 'Sisa ${CurrencyFormatter.formatRupiah(remaining.toInt())}',
                style: GoogleFonts.poppins(
                  color: isOverBudget ? Colors.red[300] : Colors.green[300],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: displayColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return const Color(0xFFE74C3C);
      case 'transportasi':
        return const Color(0xFFF39C12);
      case 'hiburan':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF8B5FBF);
    }
  }
}
