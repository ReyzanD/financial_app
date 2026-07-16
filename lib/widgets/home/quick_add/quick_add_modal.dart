import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/balance_check_helper.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/dropdown_helper.dart';
import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';

/// Modal untuk quick add transaction dengan form lengkap
class QuickAddModal extends StatefulWidget {
  final String type;
  final double? presetAmount;
  final String? presetDescription;
  final String? presetCategoryId;
  final VoidCallback? onTransactionAdded;

  const QuickAddModal({
    super.key,
    required this.type,
    this.presetAmount,
    this.presetDescription,
    this.presetCategoryId,
    this.onTransactionAdded,
  });

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final TransactionDataService _transactionData =
      getIt<TransactionDataService>();
  final CategoryDataService _categoryData = getIt<CategoryDataService>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    if (widget.presetAmount != null) {
      _amountController.text = widget.presetAmount!.toInt().toString();
    }
    if (widget.presetDescription != null) {
      _descriptionController.text = widget.presetDescription!;
    }
    _selectedCategoryId = widget.presetCategoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categoryModels = await _categoryData.getCategories();
      final categories = categoryModels.map((c) => c.toMap()).toList();
      if (mounted) {
        setState(() {
          _categories =
              categories
                  .where((cat) => cat['id'] != null && cat['name'] != null)
                  .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading categories', error: e);
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
      // Show error to user
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          '${AppLocalizations.of(context)!.failed_to_load_categories}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
        );
      }
    }
  }

  Future<bool> _checkBalanceBeforeExpense(double expenseAmount) async {
    try {
      final summary = await _transactionData.getFinancialSummary();
      return await BalanceCheckHelper.checkBalanceBeforeExpense(
        context: context,
        expenseAmount: expenseAmount,
        summary: summary,
      );
    } catch (e) {
      LoggerService.error('Error checking balance', error: e);
      return true;
    }
  }

  Future<void> _submitTransaction() async {
    // Validate amount
    final amountError = FormValidators.validateAmount(_amountController.text);
    if (amountError != null) {
      ErrorHandlerService.showWarningSnackbar(context, amountError);
      return;
    }

    // Validate description (optional but check length if provided)
    final description = _descriptionController.text.trim();
    final descriptionError = FormValidators.validateDescription(description);
    if (descriptionError != null) {
      ErrorHandlerService.showWarningSnackbar(context, descriptionError);
      return;
    }

    if (_selectedCategoryId == null) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        AppLocalizations.of(context)!.select_category,
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (amount == null || amount <= 0) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        AppLocalizations.of(context)?.invalid_amount ?? 'Jumlah tidak valid',
      );
      return;
    }

    final ctx = context;

    // Check balance before adding expense
    if (widget.type == 'expense') {
      final shouldContinue = await _checkBalanceBeforeExpense(amount);
      if (!shouldContinue) {
        return;
      }
    }

    if (!ctx.mounted) return;
    setState(() => _isLoading = true);

    try {
      final transactionData = <String, dynamic>{
        'id': '',
        'description':
            description.isEmpty
                ? widget.type == 'income'
                    ? AppLocalizations.of(ctx)!.quick_income
                    : AppLocalizations.of(ctx)!.quick_expense
                : description,
        'amount': amount,
        'type': widget.type,
        'category_id': _selectedCategoryId,
        'transaction_date': DateTime.now().toIso8601String(),
      };
      final entity = TransactionEntity.fromJson(transactionData);
      final ctrl = getIt<TransactionController>();
      final success = await ctrl.createTransaction(entity);
      if (!success) throw Exception('Failed to create transaction');

      // Update budget spending for expense transactions
      if (widget.type == 'expense' && _selectedCategoryId != null) {
        try {
          await getIt<BudgetDataService>().updateBudgetForExpense(
            categoryId: _selectedCategoryId!,
            amount: amount,
            transactionDate: DateTime.now(),
          );
        } catch (e) {
          LoggerService.warning('Budget update not critical', error: e);
        }
      }

      if (!ctx.mounted) return;
      // Trigger immediate refresh
      await AppRefresh.refreshAll(ctx);

      if (!ctx.mounted) return;
      Navigator.pop(ctx);
      if (!ctx.mounted) return;
      ErrorHandlerService.showSuccessSnackbar(
        ctx,
        AppLocalizations.of(ctx)!.transaction_added_successfully,
      );
      widget.onTransactionAdded?.call();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!ctx.mounted) return;
      ErrorHandlerService.showErrorSnackbar(
        ctx,
        '${AppLocalizations.of(ctx)!.failed}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.type == 'income' ? Colors.green : Colors.red;
    final typeIcon =
        widget.type == 'income' ? Iconsax.arrow_down_1 : Iconsax.arrow_up_3;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.type == 'income'
                        ? AppLocalizations.of(context)!.add_income
                        : AppLocalizations.of(context)!.add_expense,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacing5),

            // Amount
            Text(
              AppLocalizations.of(context)!.amount,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Rp 0',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: DesignTokens.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryColor,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Iconsax.money_4, color: typeColor),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing4),

            // Category
            Text(
              AppLocalizations.of(context)!.category,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            _isLoadingCategories
                ? const Center(
                  child: CircularProgressIndicator(
                    color: DesignTokens.primaryColor,
                  ),
                )
                : _categories.isEmpty
                ? Container(
                  padding: const EdgeInsets.all(DesignTokens.spacing4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.no_categories_create_first,
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  dropdownColor: DesignTokens.surfaceDark,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: DropdownHelper.darkDropdownDecoration(
                    hintText: AppLocalizations.of(context)!.select_category,
                  ),
                  items:
                      _categories.map((category) {
                        final id =
                            category['id']?.toString() ??
                            category['category_id']?.toString() ??
                            category['category_id_232143']?.toString() ??
                            '';
                        final name =
                            category['name']?.toString() ??
                            category['name_232143']?.toString() ??
                            'Unknown';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
            const SizedBox(height: DesignTokens.spacing4),

            // Description (optional)
            Text(
              'Deskripsi (Opsional)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            TextField(
              controller: _descriptionController,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.add_description,
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: DesignTokens.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing6),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          AppLocalizations.of(context)!.add_transaction,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing4),
          ],
        ),
      ),
    );
  }
}
