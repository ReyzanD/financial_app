import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class AddObligationModal extends StatefulWidget {
  final Map<String, dynamic>? initialObligation;

  const AddObligationModal({super.key, this.initialObligation});

  @override
  State<AddObligationModal> createState() => _AddObligationModalState();
}

class _AddObligationModalState extends State<AddObligationModal> {
  final _formKey = GlobalKey<FormState>();
  final ObligationService _obligationService = ObligationService();

  late TextEditingController _nameController;
  late TextEditingController _monthlyAmountController;
  late TextEditingController _originalAmountController;
  late TextEditingController _currentBalanceController;
  late TextEditingController _interestRateController;
  late TextEditingController _minimumPaymentController;

  String _selectedType = 'bill';
  String _selectedCategory = 'utility';
  int _dueDayOfMonth = 1;
  String? _subscriptionCycle;
  String? _payoffStrategy;
  bool _isLoading = false;

  bool get _isEdit => widget.initialObligation != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _monthlyAmountController = TextEditingController();
    _originalAmountController = TextEditingController();
    _currentBalanceController = TextEditingController();
    _interestRateController = TextEditingController();
    _minimumPaymentController = TextEditingController();

    final initial = widget.initialObligation;
    if (initial != null) {
      _nameController.text = initial['name_232143']?.toString() ?? '';
      _monthlyAmountController.text =
          (initial['monthly_amount_232143'] as num?)?.toStringAsFixed(0) ?? '';
      _selectedType = initial['type_232143']?.toString() ?? 'bill';
      _selectedCategory = initial['category_232143']?.toString() ?? 'utility';
      _dueDayOfMonth =
          int.tryParse(initial['due_date_232143']?.toString() ?? '1') ?? 1;

      if (initial['original_amount_232143'] != null) {
        _originalAmountController.text =
            (initial['original_amount_232143'] as num?)?.toStringAsFixed(0) ??
            '';
      }
      if (initial['current_balance_232143'] != null) {
        _currentBalanceController.text =
            (initial['current_balance_232143'] as num?)?.toStringAsFixed(0) ??
            '';
      }
      if (initial['interest_rate_232143'] != null) {
        _interestRateController.text =
            (initial['interest_rate_232143'] as num?)?.toStringAsFixed(2) ?? '';
      }
      if (initial['minimum_payment_232143'] != null) {
        _minimumPaymentController.text =
            (initial['minimum_payment_232143'] as num?)?.toStringAsFixed(0) ??
            '';
      }

      _subscriptionCycle = initial['subscription_cycle_232143']?.toString();
      _payoffStrategy = initial['payoff_strategy_232143']?.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyAmountController.dispose();
    _originalAmountController.dispose();
    _currentBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    LoggerService.debug('Submit button tapped');

    if (!_formKey.currentState!.validate()) {
      LoggerService.warning('Form validation failed');
      return;
    }

    LoggerService.debug('Form validation passed');
    setState(() {
      _isLoading = true;
    });

    try {
      LoggerService.debug('Preparing obligation data...');
      final data = <String, dynamic>{
        'name': _nameController.text,
        'type': _selectedType,
        'category': _selectedCategory,
        'monthly_amount': double.parse(_monthlyAmountController.text),
        'due_date': _dueDayOfMonth,
      };

      if (_originalAmountController.text.isNotEmpty) {
        data['original_amount'] = double.parse(_originalAmountController.text);
      }
      if (_currentBalanceController.text.isNotEmpty) {
        data['current_balance'] = double.parse(_currentBalanceController.text);
      }
      if (_interestRateController.text.isNotEmpty) {
        data['interest_rate'] = double.parse(_interestRateController.text);
      }
      if (_minimumPaymentController.text.isNotEmpty) {
        data['minimum_payment'] = double.parse(_minimumPaymentController.text);
      }
      if (_subscriptionCycle != null && _subscriptionCycle!.isNotEmpty) {
        data['subscription_cycle'] = _subscriptionCycle;
        data['is_subscription'] = true;
      }
      if (_payoffStrategy != null && _payoffStrategy!.isNotEmpty) {
        data['payoff_strategy'] = _payoffStrategy;
      }

      if (_isEdit) {
        LoggerService.info('Updating existing obligation...');
        final id =
            widget.initialObligation?['obligation_id_232143']?.toString();
        if (id == null) {
          throw Exception(AppLocalizations.of(context)!.invalid_obligation_id);
        }
        await _obligationService.updateObligation(id, data);
        LoggerService.success('Update successful');
      } else {
        LoggerService.info('Creating new obligation...');
        LoggerService.debug('Obligation data', error: data);
        await _obligationService.createObligation(data);
        LoggerService.success('Create successful');
      }

      if (!mounted) return;

      Navigator.pop(context, true);
      if (context.mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          _isEdit
              ? 'Kewajiban berhasil diperbarui.'
              : 'Kewajiban berhasil ditambahkan.',
        );
      }
    } catch (e) {
      LoggerService.error('Error during obligation submission', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _submit,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEdit
                    ? AppLocalizations.of(context)!.edit_obligation
                    : AppLocalizations.of(context)!.add_obligation,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.obligation_name,
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator:
                    (value) => FormValidators.validateName(
                      value,
                      fieldName: AppLocalizations.of(context)!.name,
                    ),
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.type,
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'bill',
                    child: Text(AppLocalizations.of(context)!.bill),
                  ),
                  DropdownMenuItem(
                    value: 'debt',
                    child: Text(AppLocalizations.of(context)!.debt),
                  ),
                  DropdownMenuItem(
                    value: 'subscription',
                    child: Text(AppLocalizations.of(context)!.subscription),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.category,
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'utility',
                    child: Text(AppLocalizations.of(context)!.utilities),
                  ),
                  DropdownMenuItem(
                    value: 'internet',
                    child: Text(AppLocalizations.of(context)!.internet),
                  ),
                  DropdownMenuItem(
                    value: 'phone',
                    child: Text(AppLocalizations.of(context)!.phone),
                  ),
                  DropdownMenuItem(
                    value: 'insurance',
                    child: Text(AppLocalizations.of(context)!.insurance),
                  ),
                  DropdownMenuItem(
                    value: 'credit_card',
                    child: Text(AppLocalizations.of(context)!.credit_card),
                  ),
                  DropdownMenuItem(
                    value: 'personal_loan',
                    child: Text(AppLocalizations.of(context)!.personal_loan),
                  ),
                  DropdownMenuItem(
                    value: 'mortgage',
                    child: Text(AppLocalizations.of(context)!.mortgage),
                  ),
                  DropdownMenuItem(
                    value: 'car_loan',
                    child: Text(AppLocalizations.of(context)!.car_loan),
                  ),
                  DropdownMenuItem(
                    value: 'student_loan',
                    child: Text(AppLocalizations.of(context)!.student_loan),
                  ),
                  DropdownMenuItem(
                    value: 'subscription',
                    child: Text(AppLocalizations.of(context)!.subscription),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(AppLocalizations.of(context)!.other),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Monthly Amount
              TextFormField(
                controller: _monthlyAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.monthly_amount_rp,
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => FormValidators.validateAmount(value),
              ),
              const SizedBox(height: 16),

              // Due Day of Month
              DropdownButtonFormField<int>(
                value: _dueDayOfMonth,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.due_date_day,
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: List.generate(
                  31,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _dueDayOfMonth = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Show additional fields for debt type
              if (_selectedType == 'debt') ...[
                TextFormField(
                  controller: _originalAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(
                          context,
                        )!.original_debt_amount_optional,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentBalanceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.current_balance_optional,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _interestRateController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(
                          context,
                        )!.interest_rate_percent_optional,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minimumPaymentController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.minimum_payment_optional,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Show subscription cycle for subscription type
              if (_selectedType == 'subscription') ...[
                DropdownButtonFormField<String>(
                  value: _subscriptionCycle,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.subscription_cycle_label,
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(AppLocalizations.of(context)!.monthly),
                    ),
                    DropdownMenuItem(
                      value: 'yearly',
                      child: Text(AppLocalizations.of(context)!.yearly),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(AppLocalizations.of(context)!.weekly),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _subscriptionCycle = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _isEdit
                              ? AppLocalizations.of(context)!.save_changes
                              : AppLocalizations.of(context)!.add_obligation,
                        ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
