import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/Screen/budgets_screen.dart';
import 'package:financial_app/utils/responsive_helper.dart';

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

    // Delay initial load to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didUpdateWidget(BudgetProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget is rebuilt with new key
    if (widget.key != oldWidget.key) {
      LoggerService.debug('BudgetProgress widget key changed, reloading data');
      _loadData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      LoggerService.debug('Loading budget data (attempt ${_retryCount + 1})');

      // Load categories and budgets in parallel for better performance
      // Only get active budgets for home screen
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getBudgets(activeOnly: true),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final categories = results[0];
      final budgets = results[1];

      LoggerService.debug('Categories loaded: ${categories.length}');
      LoggerService.debug('Budgets loaded: ${budgets.length}');

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
          // Limit to top 5 budgets for home screen (sorted by percentage used)
          final budgetsList =
              budgets.map((b) => b as Map<String, dynamic>).toList();
          budgetsList.sort((a, b) {
            final spentA = (a['spent'] as num?)?.toDouble() ?? 0.0;
            final amountA = (a['amount'] as num?)?.toDouble() ?? 1.0;
            final spentB = (b['spent'] as num?)?.toDouble() ?? 0.0;
            final amountB = (b['amount'] as num?)?.toDouble() ?? 1.0;
            final percentageA = amountA > 0 ? spentA / amountA : 0.0;
            final percentageB = amountB > 0 ? spentB / amountB : 0.0;
            return percentageB.compareTo(percentageA); // Sort descending
          });
          _budgets = budgetsList.take(5).toList(); // Show only top 5
          _isLoading = false;
          _errorMessage = null;
          _retryCount = 0;
        });
        _animationController.forward();
      }
    } catch (e) {
      LoggerService.error('Error loading budgets', error: e);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });

        // Auto-retry up to 2 times with exponential backoff
        if (_retryCount < 2) {
          _retryCount++;
          final delaySeconds = _retryCount * 2; // 2s, 4s
          LoggerService.debug('Retrying in $delaySeconds seconds...');

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
                fontSize: ResponsiveHelper.fontSize(context, 18),
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
                  fontSize: ResponsiveHelper.fontSize(context, 12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
        if (_isLoading)
          Center(
            child: Padding(
              padding: ResponsiveHelper.padding(context, multiplier: 1.25),
              child: const CircularProgressIndicator(color: Color(0xFF8B5FBF)),
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
              padding: ResponsiveHelper.padding(context, multiplier: 2.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, 16),
                ),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red[400],
                    size: ResponsiveHelper.iconSize(context, 48),
                  ),
                  SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                  Text(
                    'Terjadi Kesalahan',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: ResponsiveHelper.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: ResponsiveHelper.fontSize(context, 12),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                  Container(
                    padding: ResponsiveHelper.symmetricPadding(
                      context,
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5FBF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.borderRadius(context, 20),
                      ),
                      border: Border.all(color: const Color(0xFF8B5FBF)),
                    ),
                    child: Text(
                      'Tap untuk mencoba lagi',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B5FBF),
                        fontSize: ResponsiveHelper.fontSize(context, 12),
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
            padding: ResponsiveHelper.padding(context, multiplier: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, 16),
              ),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.grey[600],
                  size: ResponsiveHelper.iconSize(context, 48),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  'Belum ada budget',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: ResponsiveHelper.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
                Text(
                  'Buat budget untuk kelola keuangan lebih baik',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: ResponsiveHelper.fontSize(context, 12),
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
    final amount = (budget['amount'] as num?)?.toDouble() ?? 0.0;

    // Handle edge cases
    if (amount <= 0) {
      // If amount is 0 or invalid, don't show this budget
      return const SizedBox.shrink();
    }

    final remaining = amount - spent;
    final color = _getCategoryColor(category);

    // Calculate percentage
    final actualPercentage =
        spent / amount; // Actual percentage (can be > 100%)
    final percentage = actualPercentage.clamp(
      0.0,
      1.0,
    ); // For progress bar (max 100%)
    final isOverBudget = spent > amount;
    final displayColor = isOverBudget ? Colors.red : color;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.verticalSpacing(context, 12),
      ),
      padding: ResponsiveHelper.padding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 16),
        ),
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveHelper.iconSize(context, 40),
                  height: ResponsiveHelper.iconSize(context, 40),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.borderRadius(context, 10),
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: displayColor,
                    size: ResponsiveHelper.iconSize(context, 20),
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.horizontalSpacing(context, 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isOverBudget) ...[
                        SizedBox(
                          height: ResponsiveHelper.verticalSpacing(context, 4),
                        ),
                        Container(
                          padding: ResponsiveHelper.symmetricPadding(
                            context,
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.borderRadius(context, 6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                                size: ResponsiveHelper.iconSize(context, 12),
                              ),
                              SizedBox(
                                width: ResponsiveHelper.horizontalSpacing(context, 4),
                              ),
                              Text(
                                'Over',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: ResponsiveHelper.fontSize(context, 10),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatRupiah(spent.toInt()),
                      style: GoogleFonts.poppins(
                        color: displayColor,
                        fontSize: ResponsiveHelper.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'dari ${CurrencyFormatter.formatRupiah(amount.toInt())}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: ResponsiveHelper.fontSize(context, 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, 10),
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: percentage),
              builder: (context, value, child) {
                // Cap progress bar at 100% even if over budget
                final displayValue = value > 1.0 ? 1.0 : value;
                return LinearProgressIndicator(
                  value: displayValue,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(displayColor),
                  minHeight: ResponsiveHelper.verticalSpacing(context, 8),
                );
              },
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverBudget
                    ? 'Melebihi ${CurrencyFormatter.formatRupiah((spent - amount).toInt())}'
                    : 'Sisa ${CurrencyFormatter.formatRupiah(remaining.toInt())}',
                style: GoogleFonts.poppins(
                  color: isOverBudget ? Colors.red[300] : Colors.green[300],
                  fontSize: ResponsiveHelper.fontSize(context, 11),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isOverBudget
                    ? '${(actualPercentage * 100).toStringAsFixed(0)}%'
                    : '${(percentage * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: displayColor,
                  fontSize: ResponsiveHelper.fontSize(context, 12),
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

