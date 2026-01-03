import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:intl/intl.dart';

class AddBudgetModal extends StatefulWidget {
  final Map<String, String> categories;
  final Map<String, dynamic>? initialBudget;

  const AddBudgetModal({
    super.key,
    required this.categories,
    this.initialBudget,
  });

  @override
  State<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends State<AddBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

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
    LoggerService.debug(
      'AddBudgetModal - Received ${widget.categories.length} categories',
    );
    _amountController = TextEditingController();
    final initial = widget.initialBudget;
    if (initial != null) {
      final amount = (initial['amount'] as num?)?.toDouble();
      if (amount != null) {
        _amountController.text = amount.toStringAsFixed(0);
      }
      final categoryId = initial['category_id'];
      if (categoryId != null) {
        final categoryIdStr = categoryId.toString();
        // Only set selected category if it exists in the categories map
        // This prevents dropdown errors when category was deleted or filtered out
        if (widget.categories.containsKey(categoryIdStr)) {
          _selectedCategoryId = categoryIdStr;
        } else {
          // Category doesn't exist in filtered list, reset to null
          _selectedCategoryId = null;
          LoggerService.debug(
            'Category $categoryIdStr not found in categories map, resetting selection',
          );
        }
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5FBF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final data = <String, dynamic>{
        'amount': amount,
        'period': _selectedPeriod,
        'period_start': DateFormat('yyyy-MM-dd').format(_startDate),
        'rollover_enabled': _rolloverEnabled,
        'alert_threshold': _alertThreshold.toInt(),
        'is_active': _isActive,
      };
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        data['category_id'] = _selectedCategoryId;
      }

      if (_isEdit) {
        final id = widget.initialBudget?['id']?.toString();
        if (id == null) {
          throw Exception('ID budget tidak valid');
        }
        await _apiService.updateBudget(id, data);
      } else {
        await _apiService.createBudget(data);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
      if (context.mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          _isEdit
              ? 'Budget berhasil diperbarui.'
              : 'Budget berhasil ditambahkan.',
        );
      }
    } catch (e) {
      LoggerService.error('Error saving budget', error: e);
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

  Future<void> _confirmDelete() async {
    final id = widget.initialBudget?['id']?.toString();
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Hapus Budget',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Yakin ingin menghapus budget ini?',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.deleteBudget(id);
        if (!mounted) return;

        // Clear cache and trigger app-wide refresh
        ApiService.clearCache();
        if (context.mounted) {
          await AppRefresh.refreshAll(context);
        }

        Navigator.pop(context, true);
        if (context.mounted) {
          ErrorHandlerService.showSuccessSnackbar(
            context,
            'Budget berhasil dihapus.',
          );
        }
      } catch (e) {
        LoggerService.error('Error deleting budget', error: e);
        if (!mounted) return;
        
        final errorMessage = e.toString().toLowerCase();
        final isNotFound = errorMessage.contains('404') || errorMessage.contains('not found');
        
        // If budget not found (404), it might already be deleted, so refresh the list anyway
        if (isNotFound) {
          // Clear cache and trigger refresh even if we got 404
          ApiService.clearCache();
          if (context.mounted) {
            await AppRefresh.refreshAll(context);
          }
          Navigator.pop(context, true);
          if (context.mounted) {
            // Show a less alarming message since the budget is likely already gone
            ErrorHandlerService.showSuccessSnackbar(
              context,
              'Budget tidak ditemukan. Daftar sudah diperbarui.',
            );
          }
          return;
        }
        
        setState(() {
          _isLoading = false;
        });
        if (context.mounted) {
          String userMessage;
          
          if (errorMessage.contains('401') || errorMessage.contains('unauthorized')) {
            userMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
          } else {
            userMessage = ErrorHandlerService.getUserFriendlyMessage(e);
          }
          
          ErrorHandlerService.showErrorSnackbar(
            context,
            userMessage,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodOptions = <String, String>{
      'daily': 'Harian',
      'weekly': 'Mingguan',
      'monthly': 'Bulanan',
      'yearly': 'Tahunan',
    };

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
                _isEdit ? 'Edit Budget' : 'Tambah Budget',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String?>(
                value: _selectedCategoryId != null &&
                        widget.categories.containsKey(_selectedCategoryId)
                    ? _selectedCategoryId
                    : null, // Ensure value exists in items
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Semua Kategori'),
                  ),
                  ...widget.categories.entries.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Jumlah Budget (Rp)',
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
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Periode',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    periodOptions.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPeriod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mulai', style: TextStyle(color: Colors.grey[400])),
                      Text(
                        DateFormat('dd MMM yyyy').format(_startDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _rolloverEnabled,
                onChanged: (value) {
                  setState(() {
                    _rolloverEnabled = value;
                  });
                },
                activeColor: const Color(0xFF8B5FBF),
                title: Text(
                  'Rollover sisa ke periode berikutnya',
                  style: TextStyle(color: Colors.white),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
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
                    activeColor: const Color(0xFF8B5FBF),
                    inactiveColor: Colors.grey[800],
                    onChanged: (value) {
                      setState(() {
                        _alertThreshold = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: const Color(0xFF8B5FBF),
                title: Text('Aktif', style: TextStyle(color: Colors.white)),
                contentPadding: EdgeInsets.zero,
              ),
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
                        : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Budget'),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Hapus Budget'),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
