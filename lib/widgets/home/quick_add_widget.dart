import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/home/quick_add/quick_add_modal.dart';

class QuickAddWidget extends StatefulWidget {
  final VoidCallback? onTransactionAdded;

  const QuickAddWidget({super.key, this.onTransactionAdded});

  @override
  State<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends State<QuickAddWidget> {
  final ApiService _apiService = ApiService();
  List<dynamic> _recentCategories = [];
  bool _isLoadingCategories = true;

  // Quick amount presets in IDR
  final List<double> _quickAmounts = [
    10000,
    25000,
    50000,
    100000,
    250000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentCategories();
  }

  Future<void> _loadRecentCategories() async {
    try {
      // Get all categories (will use cache if available)
      final categories = await _apiService.getCategories();

      // Get recent transactions to find most used categories (reduced from 50 to 20)
      final transactions = await _apiService.getTransactions(limit: 20);

      // Count category usage
      final Map<String, int> categoryUsageCount = {};
      for (var transaction in transactions) {
        final categoryId = transaction['category_id'];
        if (categoryId != null) {
          final idString = categoryId.toString();
          categoryUsageCount[idString] =
              (categoryUsageCount[idString] ?? 0) + 1;
        }
      }

      // Convert categories to list with usage count
      final List<Map<String, dynamic>> categoryList = [];
      for (var category in categories) {
        if (category != null &&
            category['id'] != null &&
            category['name'] != null) {
          final idString = category['id'].toString();
          categoryList.add({
            'id': idString,
            'name': category['name'].toString(),
            'count': categoryUsageCount[idString] ?? 0,
          });
        }
      }

      // Sort by usage (most used first), then alphabetically
      categoryList.sort((a, b) {
        final countCompare = b['count'].compareTo(a['count']);
        if (countCompare != 0) return countCompare;
        return a['name'].toString().compareTo(b['name'].toString());
      });

      if (mounted) {
        setState(() {
          _recentCategories = categoryList.take(6).toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading recent categories', error: e);
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _showQuickAddModal({
    required String type,
    double? presetAmount,
    String? presetCategoryId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => QuickAddModal(
            type: type,
            presetAmount: presetAmount,
            presetCategoryId: presetCategoryId,
            onTransactionAdded: widget.onTransactionAdded,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ResponsiveHelper.horizontalPadding(context),
      padding: ResponsiveHelper.padding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 16),
        ),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Iconsax.flash_1,
                color: Color(0xFF8B5FBF),
                size: ResponsiveHelper.iconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              Text(
                'Tambah Cepat',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.fontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),

          // Quick type buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickTypeButton(
                  context: context,
                  label: 'Pemasukan',
                  icon: Iconsax.arrow_down_1,
                  color: Colors.green,
                  type: 'income',
                ),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
              Expanded(
                child: _buildQuickTypeButton(
                  context: context,
                  label: 'Pengeluaran',
                  icon: Iconsax.arrow_up_3,
                  color: Colors.red,
                  type: 'expense',
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),

          // Quick amounts section
          Text(
            'Nominal Cepat',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: ResponsiveHelper.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          Wrap(
            spacing: ResponsiveHelper.horizontalSpacing(context, 8),
            runSpacing: ResponsiveHelper.verticalSpacing(context, 8),
            children:
                _quickAmounts.map((amount) {
                  return _buildAmountChip(context, amount);
                }).toList(),
          ),

          // Recent categories section
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          Text(
            'Kategori Sering',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: ResponsiveHelper.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          if (_isLoadingCategories)
            Center(
              child: Padding(
                padding: ResponsiveHelper.padding(context, multiplier: 0.5),
                child: const CircularProgressIndicator(
                  color: Color(0xFF8B5FBF),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_recentCategories.isEmpty)
            Container(
              padding: ResponsiveHelper.padding(context, multiplier: 0.75),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, 12),
                ),
              ),
              child: Text(
                'Belum ada kategori yang sering digunakan',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: ResponsiveHelper.fontSize(context, 11),
                ),
              ),
            )
          else
            Wrap(
              spacing: ResponsiveHelper.horizontalSpacing(context, 8),
              runSpacing: ResponsiveHelper.verticalSpacing(context, 8),
              children:
                  _recentCategories.map((category) {
                    return _buildCategoryChip(context, category);
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickTypeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(type: type),
      child: Container(
        padding: ResponsiveHelper.verticalPadding(context, multiplier: 1.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: ResponsiveHelper.fontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(BuildContext context, double amount) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(type: 'expense', presetAmount: amount),
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5FBF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.5)),
        ),
        child: Text(
          CurrencyFormatter.formatRupiah(amount),
          style: GoogleFonts.poppins(
            color: const Color(0xFF8B5FBF),
            fontSize: ResponsiveHelper.fontSize(context, 12),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    return GestureDetector(
      onTap:
          () => _showQuickAddModal(
            type: 'expense',
            presetCategoryId: category['id'].toString(),
          ),
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.category,
              size: ResponsiveHelper.iconSize(context, 14),
              color: Colors.blue,
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 6)),
            Text(
              category['name'].toString(),
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontSize: ResponsiveHelper.fontSize(context, 11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
