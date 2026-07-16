import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:intl/intl.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/dropdown_helper.dart';
import 'package:financial_app/utils/date_picker_helper.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/budget_model.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';

class AddBudgetModal extends StatefulWidget {
  final Map<String, String> categories;
  final Map<String, dynamic>? initialBudget;

  const AddBudgetModal({super.key, required this.categories, this.initialBudget});

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  String? _selectedCategoryId;
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _rolloverEnabled = false;
  double _alertThreshold = 80;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEdit => widget.initialBudget != null;

  @override
  void initState() {
    super.initState();
    LoggerService.debug('AddBudgetModal - Received ${widget.categories.length} categories');
    _amountController = TextEditingController();
    final initial = widget.initialBudget;
    if (initial != null) {
      final amount = (initial['amount'] as num?)?.toDouble();
      if (amount != null) {
        _amountController.text = amount.toStringAsFixed(0);
      }
      final categoryId = initial['category_id'];
      if (categoryId != null) {
        _selectedCategoryId = categoryId.toString();
      }
      final period = initial['period'] as String?;
      if (period != null && period.isNotEmpty) {
        _selectedPeriod = period;
      }
      final startStr = initial['period_start'] as String?;
      if (startStr != null && startStr.isNotEmpty) {
        try {
          _startDate = DateTime.parse(startStr);
        } catch (_) {}
      }
      final rollover = initial['rollover_enabled'];
      if (rollover is bool) {
        _rolloverEnabled = rollover;
      } else if (rollover is num) {
        _rolloverEnabled = rollover != 0;
      }
      final threshold = initial['alert_threshold'];
      if (threshold is num) {
        _alertThreshold = threshold.toDouble();
      }
      final active = initial['is_active'];
      if (active is bool) {
        _isActive = active;
      } else if (active is num) {
        _isActive = active != 0;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await DatePickerHelper.showDarkDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      DateTime periodEnd;
      switch (_selectedPeriod) {
        case 'weekly':
          periodEnd = _startDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          periodEnd = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
          break;
        case 'yearly':
          periodEnd = DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
          break;
        default:
          periodEnd = _startDate.add(const Duration(days: 30));
      }

      final data = <String, dynamic>{
        'amount': amount,
        'period': _selectedPeriod,
        'period_start': DateFormat('yyyy-MM-dd').format(_startDate),
        'period_end': DateFormat('yyyy-MM-dd').format(periodEnd),
        'rollover_enabled': _rolloverEnabled,
        'alert_threshold': _alertThreshold.toInt(),
        'is_active': _isActive,
      };
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        data['category_id'] = _selectedCategoryId;
      }

      final ctrl = getIt<BudgetController>();
      if (_isEdit) {
        final id = widget.initialBudget?['budget_id_232143']?.toString() ?? widget.initialBudget?['id']?.toString();
        if (id == null) {
          throw Exception('ID budget tidak valid');
        }
        await ctrl.updateBudgetFromMap(id, data);
      } else {
        data['id'] = '';
        final model = BudgetModel.fromMap(data);
        await ctrl.createBudget(model);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
      if (context.mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          _isEdit
              ? (l10n?.budget_updated_successfully ?? 'Budget berhasil diperbarui.')
              : (l10n?.budget_added_successfully ?? 'Budget berhasil ditambahkan.'),
        );
      }
    } catch (e) {
      LoggerService.error('Error saving budget', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e), onRetry: _submit);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periodOptions = <String, String>{
      'daily': l10n?.daily ?? 'Harian',
      'weekly': l10n?.weekly ?? 'Mingguan',
      'monthly': l10n?.monthly ?? 'Bulanan',
      'yearly': l10n?.yearly ?? 'Tahunan',
    };

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: DesignTokens.spacing5),
              Text(
                _isEdit ? (l10n?.edit_budget ?? 'Edit Budget') : (l10n?.add_budget ?? 'Tambah Budget'),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: DesignTokens.spacing6),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                dropdownColor: DesignTokens.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: DropdownHelper.darkDropdownDecoration(labelText: l10n?.category ?? 'Kategori'),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l10n?.all_categories ?? 'Semua Kategori')),
                  ...widget.categories.entries.map(
                    (entry) => DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: DesignTokens.spacing4),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Jumlah Budget (Rp)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => FormValidators.validateAmount(value),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              DropdownButtonFormField<String>(
                initialValue: _selectedPeriod,
                dropdownColor: DesignTokens.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: DropdownHelper.darkDropdownDecoration(labelText: 'Periode'),
                items:
                    periodOptions.entries
                        .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
                        .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPeriod = value;
                  });
                },
              ),
              const SizedBox(height: DesignTokens.spacing4),
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.spacing4),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mulai', style: TextStyle(color: Colors.grey[400])),
                      Text(
                        DateFormat('dd MMM yyyy').format(_startDate),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              SwitchListTile(
                value: _rolloverEnabled,
                onChanged: (value) {
                  setState(() {
                    _rolloverEnabled = value;
                  });
                },
                activeThumbColor: DesignTokens.primaryColor,
                title: Text('Rollover sisa ke periode berikutnya', style: TextStyle(color: Colors.white)),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: DesignTokens.spacing2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifikasi saat pemakaian ${_alertThreshold.toInt()}%',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Slider(
                    value: _alertThreshold,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    activeColor: DesignTokens.primaryColor,
                    inactiveColor: Colors.grey[800],
                    onChanged: (value) {
                      setState(() {
                        _alertThreshold = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacing2),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeThumbColor: DesignTokens.primaryColor,
                title: Text(l10n?.active_label ?? 'Aktif', style: TextStyle(color: Colors.white)),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: DesignTokens.spacing6),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : Text(
                          _isEdit
                              ? (l10n?.save_changes_label ?? 'Simpan Perubahan')
                              : (l10n?.add_budget ?? 'Tambah Budget'),
                        ),
              ),
              const SizedBox(height: DesignTokens.spacing5),
            ],
          ),
        ),
      ),
    );
  }
}
