import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/templates/presentation/controllers/template_controller.dart';
import 'package:financial_app/services/data/transaction_template_data_service.dart';
import 'package:financial_app/models/feature_models.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateController>().loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<TemplateController>().loadData();
  }

  Color _getTemplateTypeColor(String type) {
    switch (type) {
      case 'income':
        return DesignTokens.successColor;
      case 'expense':
        return DesignTokens.errorColor;
      default:
        return DesignTokens.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: _loadData,
                child: Consumer<TemplateController>(
                  builder: (context, ctrl, _) {
                    if (ctrl.isLoading)
                      return Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.primaryColor,
                        ),
                      );
                    if (ctrl.error != null)
                      return _buildErrorState(context, l10n, ctrl);
                    if (ctrl.templates.isEmpty)
                      return _buildEmptyState(context, l10n);
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(DesignTokens.spacing4),
                      itemCount: ctrl.templates.length,
                      itemBuilder:
                          (_, i) => _buildTemplateCard(
                            context,
                            ctrl.templates[i],
                            l10n,
                            ctrl,
                          ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'templates_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () => _showAddTemplateModal(),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Iconsax.arrow_left,
              color: DesignTokens.textPrimaryDark,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Templates',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Consumer<TemplateController>(
            builder:
                (_, ctrl, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(color: DesignTokens.borderDark),
                  ),
                  child: Text(
                    '${ctrl.templates.length} ${l10n?.total_categories ?? 'templates'}',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    TransactionTemplateModel template,
    AppLocalizations? l10n,
    TemplateController ctrl,
  ) {
    final name = template.name;
    final amount = template.amount;
    final type = template.type;
    final categoryName = template.categoryName ?? '';
    final usageCount = template.usageCount;
    final isIncome = type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getTemplateTypeColor(type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Icon(
              isIncome ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
              color: _getTemplateTypeColor(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (categoryName.isNotEmpty)
                  Text(
                    categoryName,
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  '$usageCount digunakan',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textTertiaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatRupiah(amount.toInt()),
                style: GoogleFonts.poppins(
                  color:
                      isIncome
                          ? DesignTokens.successColor
                          : DesignTokens.errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _quickAdd(template, ctrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n?.quick_add ?? 'Quick Add',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _deleteTemplate(template.id, ctrl),
            child: Icon(
              Iconsax.trash,
              size: 16,
              color: DesignTokens.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.note, size: 64, color: DesignTokens.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            l10n?.no_transactions_title ?? 'No Templates',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new template',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddTemplateModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
            ),
            child: Text(
              l10n?.add_template ?? 'Tambah Template',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations? l10n,
    TemplateController ctrl,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n?.error ?? 'An error occurred',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ctrl.error ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: ctrl.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
            ),
            child: Text(
              l10n?.retry ?? 'Retry',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTemplateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => _AddTemplateModal(onTemplateAdded: _loadData),
    );
  }

  Future<void> _quickAdd(TransactionTemplateModel template, TemplateController ctrl) async {
    try {
      await getIt<TransactionTemplateDataService>().createTransactionFromTemplate(
        template.id,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final name = template.name;
      ErrorHandlerService.showSuccessSnackbar(
        context,
        '$name ${l10n?.added ?? 'added'}',
      );
      await ctrl.loadData();
    } catch (e) {
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
    }
  }

  Future<void> _deleteTemplate(
    String templateId,
    TemplateController ctrl,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(
              l10n?.delete ?? 'Delete',
              style: GoogleFonts.poppins(
                color: DesignTokens.textPrimaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              l10n?.confirm_delete_budget ??
                  'Are you sure you want to delete this template?',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(
                  l10n?.delete ?? 'Delete',
                  style: const TextStyle(color: DesignTokens.errorColor),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await getIt<TransactionTemplateDataService>().deleteTransactionTemplate(
          templateId,
        );
        if (mounted)
          ErrorHandlerService.showSuccessSnackbar(
            context,
            l10n?.transaction_deleted_successfully ?? 'Template deleted',
          );
        await ctrl.loadData();
      } catch (e) {
        if (mounted)
          ErrorHandlerService.showErrorSnackbar(
            context,
            ErrorHandlerService.getUserFriendlyMessage(e),
          );
      }
    }
  }
}

class _AddTemplateModal extends StatefulWidget {
  final VoidCallback onTemplateAdded;
  const _AddTemplateModal({required this.onTemplateAdded});
  @override
  State<_AddTemplateModal> createState() => _AddTemplateModalState();
}

class _AddTemplateModalState extends State<_AddTemplateModal> {
  final TransactionTemplateDataService _templateData =
      getIt<TransactionTemplateDataService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'expense';
  final List<Map<String, dynamic>> _types = [
    {'value': 'expense', 'label': 'Expense'},
    {'value': 'income', 'label': 'Income'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textTertiaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n?.add ?? 'Add Template',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.name ?? 'Name',
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Name cannot be empty'
                            : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _types.map((t) {
                      final sel = _selectedType == t['value'];
                      return ChoiceChip(
                        label: Text(
                          t['label'],
                          style: GoogleFonts.poppins(
                            color:
                                sel
                                    ? Colors.white
                                    : DesignTokens.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                        selected: sel,
                        onSelected:
                            (_) => setState(() => _selectedType = t['value']),
                        backgroundColor: DesignTokens.surfaceDark,
                        selectedColor: DesignTokens.primaryColor,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.amount ?? 'Amount',
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Amount cannot be empty'
                            : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTemplate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n?.add ?? 'Add',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _templateData.addTransactionTemplate({
        'name': _nameController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'type': _selectedType,
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onTemplateAdded();
    } catch (e) {
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
    }
  }
}
