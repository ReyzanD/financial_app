/// Add/Edit Transaction Screen
///
/// A comprehensive screen for adding new transactions or editing existing ones.
/// Supports both income and expense transactions with full validation.
///
/// Features:
/// - Form validation using FormValidators
/// - Location picker integration
/// - Auto-categorization based on location
/// - Date/time selection with future date prevention for expenses
/// - Payment method selection
/// - Notes and additional options
///
/// Usage:
/// ```dart
/// // Add new transaction
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => AddTransactionScreen()),
/// );
///
/// // Edit existing transaction
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AddTransactionScreen(transaction: transactionData),
///   ),
/// );
/// ```
///
/// Author: Financial App Team
/// Last Updated: 2025
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/receipt_scanning_service.dart';
import 'package:financial_app/services/smart_categorization_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/widgets/maps/location_picker_map.dart';
import 'package:financial_app/widgets/add_transaction/account_section.dart';
import 'package:financial_app/widgets/add_transaction/amount_field.dart';
import 'package:financial_app/widgets/add_transaction/type_selector.dart';
import 'package:financial_app/widgets/add_transaction/category_section.dart';
import 'package:financial_app/widgets/add_transaction/description_field.dart';
import 'package:financial_app/widgets/add_transaction/location_section.dart';
import 'package:financial_app/widgets/add_transaction/date_time_section.dart';
import 'package:financial_app/widgets/add_transaction/payment_method_section.dart';
import 'package:financial_app/widgets/add_transaction/submit_button.dart';
import 'package:financial_app/widgets/add_transaction/additional_options.dart';
import 'package:financial_app/widgets/add_transaction/notes_field.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/Screen/receipt_history_screen.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Optional for edit mode
  final VoidCallback? onUpdated;

  const AddTransactionScreen({super.key, this.transaction, this.onUpdated});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();

  bool get isEditMode => transaction != null;
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ReceiptScanningService _receiptService = ReceiptScanningService();
  final SmartCategorizationService _categorizationService =
      SmartCategorizationService();

  // Form state
  String _selectedType = 'expense';
  String? _selectedCategory;
  String? _selectedAccountId;
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LocationData? _currentLocation;
  bool _isGettingLocation = false;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  bool _isScanningReceipt = false;
  String? _receiptImagePath;
  List<Map<String, dynamic>> _categorySuggestions = [];

  // Category data from API
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    // If editing, populate form with existing data
    if (widget.isEditMode) {
      _populateFormData();
    }

    // Load categories from API
    _loadCategories();

    _descriptionController.addListener(_onDescriptionChanged);

    // Auto-get location when screen opens (only for new expense transactions)
    // Income transactions don't need location
    if (!widget.isEditMode && _selectedType == 'expense') {
      _getCurrentLocation();
    }
  }

  void _populateFormData() {
    final transaction = widget.transaction!;
    _amountController.text = transaction['amount']?.toString() ?? '';
    _descriptionController.text = transaction['description']?.toString() ?? '';
    _selectedType = transaction['type']?.toString() ?? 'expense';
    _selectedCategory = transaction['category_id']?.toString();
    _selectedAccountId = transaction['account_id']?.toString();
    _selectedPaymentMethod =
        transaction['payment_method']?.toString() ?? 'cash';

    // Parse date
    if (transaction['date'] != null) {
      try {
        final date = DateTime.parse(transaction['date'].toString());
        _selectedDate = date;
        _selectedTime = TimeOfDay(hour: date.hour, minute: date.minute);
      } catch (e) {
        LoggerService.warning('Error parsing date', error: e);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _receiptService.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      LoggerService.info('Loading categories from API...');
      final categories = await _apiService
          .getCategories(forceRefresh: true)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              LoggerService.warning('Category loading timed out');
              return [];
            },
          );
      LoggerService.success('Categories loaded: ${categories.length}');
      if (mounted) {
        setState(() {
          _categories = categories.cast<Map<String, dynamic>>();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading categories', error: e);
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        if (context.mounted) {
          ErrorHandlerService.showErrorSnackbar(
            context,
            ErrorHandlerService.getUserFriendlyMessage(e),
            onRetry: _loadCategories,
          );
        }
      }
    }
  }

  void _onDescriptionChanged() {
    final desc = _descriptionController.text.trim();
    if (desc.length < 3) {
      if (_categorySuggestions.isNotEmpty) {
        setState(() => _categorySuggestions = []);
      }
      return;
    }

    _categorizationService.suggestCategory(description: desc).then((
      suggestions,
    ) {
      if (mounted && suggestions.isNotEmpty) {
        final categoryIds =
            suggestions
                .where((s) => s['confidence'] > 0.3)
                .map((s) => _findCategoryId(s['category'] as String))
                .where((id) => id != null)
                .toList();

        if (categoryIds.isNotEmpty) {
          setState(() => _categorySuggestions = suggestions);
        }
      }
    });
  }

  String? _findCategoryId(String categoryName) {
    for (final cat in _categories) {
      final name =
          (cat['name']?.toString() ?? cat['name_232143']?.toString() ?? '')
              .toLowerCase();
      if (name.contains(categoryName.toLowerCase()) ||
          categoryName.toLowerCase().contains(name)) {
        return cat['category_id']?.toString() ??
            cat['category_id_232143']?.toString();
      }
    }
    return null;
  }

  void _selectSuggestedCategory(Map<String, dynamic> suggestion) {
    final categoryId = _findCategoryId(suggestion['category'] as String);
    if (categoryId != null) {
      setState(() {
        _selectedCategory = categoryId;
        _categorySuggestions = [];
      });
    }
  }

  Future<void> _pickLocationFromMap() async {
    // Import the location picker map
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationPickerMap(initialLocation: _currentLocation),
      ),
    );

    if (result != null && result is LocationData) {
      setState(() {
        _currentLocation = result;
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _currentLocation = null;
    });
    ErrorHandlerService.showInfoSnackbar(
      context,
      AppLocalizations.of(context)!.location_removed,
    );
  }

  Future<void> _getCurrentLocation() async {
    LoggerService.debug('Attempting to get current location...');
    setState(() => _isGettingLocation = true);

    try {
      // Simulate location service
      final position = await LocationService.getCurrentLatLng();
      if (position == null) {
        LoggerService.warning('Location service returned null');
        if (mounted) {
          ErrorHandlerService.showWarningSnackbar(
            context,
            AppLocalizations.of(context)!.failed_to_get_location,
          );
        }
      } else {
        LoggerService.debug(
          'Location received: ${position.latitude}, ${position.longitude}',
        );
        final placeName = LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        LoggerService.debug('Place name: $placeName');

        // Mock location data - in real app, use geolocator package
        setState(() {
          _currentLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            placeName: placeName,
            address: null,
            placeType: null,
          );
        });

        LoggerService.success('Location set successfully');

        // Auto-categorize based on location
        _autoCategorizeFromLocation();
      }
    } catch (e) {
      LoggerService.error('Error getting location', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _showReceiptScanOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.select_image_source,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Iconsax.camera, color: Color(0xFF8B5FBF)),
                  title: Text(
                    AppLocalizations.of(context)!.take_photo,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(
                    Iconsax.gallery,
                    color: Color(0xFF8B5FBF),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.choose_from_gallery,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
    );

    if (option != null) {
      await _scanReceipt(fromCamera: option == 'camera');
    }
  }

  Future<void> _scanReceipt({required bool fromCamera}) async {
    setState(() => _isScanningReceipt = true);

    try {
      final imageFile = await _receiptService.pickImage(fromCamera: fromCamera);
      if (imageFile == null) {
        setState(() => _isScanningReceipt = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.loading,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF8B5FBF),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final scanResult = await _receiptService.scanReceipt(
        imageFile,
        saveImage: true,
      );

      if (scanResult != null && mounted) {
        final parsedData = scanResult['parsed_data'] as Map<String, dynamic>;
        final amount = (parsedData['total'] as num?)?.toDouble() ?? 0.0;
        final merchant = parsedData['merchant'] as String? ?? '';
        final dateStr = parsedData['date'] as String?;
        final imagePath = parsedData['image_path'] as String?;

        if (amount > 0) {
          _amountController.text = amount.toStringAsFixed(0);
        }
        if (merchant.isNotEmpty) {
          _descriptionController.text = merchant;
        }

        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            final dateParts = dateStr.split(RegExp(r'[/-]'));
            if (dateParts.length == 3) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final year = int.parse(
                dateParts[2].length == 2 ? '20${dateParts[2]}' : dateParts[2],
              );
              final parsedDate = DateTime(year, month, day);

              if (_selectedType == 'expense' &&
                  parsedDate.isAfter(DateTime.now())) {
              } else {
                setState(() {
                  _selectedDate = parsedDate;
                  _selectedTime = TimeOfDay.now();
                });
              }
            }
          } catch (e) {
            LoggerService.warning('Error parsing receipt date', error: e);
          }
        }

        setState(() {
          _selectedType = 'expense';
          if (imagePath != null) {
            _receiptImagePath = imagePath;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.receipt_scanned_successfully,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        LoggerService.success('Receipt scanned successfully');
      } else {
        if (mounted) {
          ErrorHandlerService.showWarningSnackbar(
            context,
            AppLocalizations.of(context)!.cannot_scan_receipt,
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error scanning receipt', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          AppLocalizations.of(context)!.error_scanning_receipt,
        );
      }
    } finally {
      setState(() => _isScanningReceipt = false);
    }
  }

  void _autoCategorizeFromLocation() {
    // Find category by name from loaded categories
    String? categoryName;

    if (_currentLocation?.placeType == 'restaurant' ||
        _currentLocation?.placeName?.toLowerCase().contains('restaurant') ==
            true) {
      categoryName = 'food';
    } else if (_currentLocation?.placeType == 'gas_station') {
      categoryName = 'transport';
    }

    if (categoryName != null) {
      // Find the category ID from the loaded categories
      final category = _categories.firstWhere(
        (cat) =>
            cat['name']?.toString().toLowerCase().contains(categoryName!) ??
            false,
        orElse: () => {},
      );

      if (category.isNotEmpty && category['id'] != null) {
        setState(() {
          _selectedCategory = category['id'].toString();
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate:
          _selectedType == 'expense'
              ? DateTime.now()
              : DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5FBF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      // Validate: expense cannot have future dates
      if (_selectedType == 'expense' && picked.isAfter(DateTime.now())) {
        if (mounted) {
          ErrorHandlerService.showWarningSnackbar(
            context,
            'Tanggal pengeluaran tidak boleh di masa depan',
          );
        }
        return;
      }
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5FBF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<bool> _checkBalanceBeforeExpense(double expenseAmount) async {
    final ctx = context;
    try {
      // Get current financial summary
      final summary = await _apiService.getFinancialSummary();
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) return true; // Allow if we can't check

      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final expense =
          (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final currentBalance = income - expense;
      final newBalance = currentBalance - expenseAmount;

      // Minimum balance requirement: 25000
      const double minimumBalance = 25000.0;

      // If balance would go below the minimum, block the transaction
      if (newBalance < minimumBalance) {
        if (!ctx.mounted) return false;
        await showDialog(
          context: ctx,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saldo Tidak Cukup',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi ditolak! Saldo Anda tidak mencukupi untuk pengeluaran ini.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildBalanceRow(
                            'Saldo Tersedia',
                            currentBalance,
                            Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            'Saldo Minimum',
                            minimumBalance,
                            Colors.orange[300]!,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            'Pengeluaran',
                            expenseAmount,
                            Colors.red[300]!,
                          ),
                          const Divider(color: Colors.grey, height: 20),
                          _buildBalanceRow(
                            'Kekurangan',
                            (minimumBalance - newBalance).abs(),
                            Colors.red[400]!,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue[300],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.add_income_first,
                              style: GoogleFonts.poppins(
                                color: Colors.blue[300],
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.understood,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        );
        return false; // Block the transaction
      }

      return true; // Balance is fine, proceed
    } catch (e) {
      LoggerService.error('Error checking balance', error: e);
      return true; // Allow transaction if check fails
    }
  }

  Widget _buildBalanceRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.formatRupiah(amount.abs()),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation: expense cannot have future dates
      final dateError = FormValidators.validateDate(
        _selectedDate,
        allowFuture: _selectedType == 'income',
      );
      if (dateError != null) {
        ErrorHandlerService.showWarningSnackbar(context, dateError);
        return;
      }

      final ctx = context;

      // Check for duplicate transactions
      try {
        final recentTransactionsData = await _apiService.getTransactions(
          limit: 20,
        );
        final recentTransactions = List<Map<String, dynamic>>.from(
          recentTransactionsData['transactions'] ?? [],
        );
        final amount =
            double.tryParse(
              _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        final isDuplicate = FormValidators.isDuplicateTransaction(
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          recentTransactions: recentTransactions,
        );

        if (isDuplicate) {
          if (!ctx.mounted) return;
          final shouldContinue = await showDialog<bool>(
            context: ctx,
            builder:
                (dialogContext) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: Text(
                    AppLocalizations.of(ctx)!.duplicate_transaction,
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    AppLocalizations.of(ctx)!.similar_transaction_added,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(AppLocalizations.of(ctx)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                      ),
                      child: Text(AppLocalizations.of(ctx)!.continueText),
                    ),
                  ],
                ),
          );

          if (shouldContinue != true) {
            return;
          }
        }
      } catch (e) {
        LoggerService.warning('Error checking duplicates', error: e);
        // Continue if duplicate check fails
      }

      setState(() => _isSubmitting = true);

      try {
        // Prepare transaction data for API
        final transactionData = {
          'amount': double.parse(_amountController.text),
          'type': _selectedType,
          'category_id': _selectedCategory,
          'account_id': _selectedAccountId,
          'description': _descriptionController.text,
          'notes': _notesController.text,
          'payment_method': _selectedPaymentMethod,
          'transaction_date': _selectedDate.toIso8601String().split('T')[0],
          'time':
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          if (_receiptImagePath != null) 'receipt_image_url': _receiptImagePath,
          if (_currentLocation != null)
            'location_name':
                _currentLocation!.placeName ?? _currentLocation!.address ?? '',
          if (_currentLocation != null) 'latitude': _currentLocation!.latitude,
          if (_currentLocation != null)
            'longitude': _currentLocation!.longitude,
          if (_currentLocation != null) 'address': _currentLocation!.address,
          if (_currentLocation != null)
            'location_data': {
              'latitude': _currentLocation?.latitude,
              'longitude': _currentLocation?.longitude,
              'place_name': _currentLocation?.placeName,
              'address': _currentLocation?.address,
            },
          'is_recurring': _isRecurring,
        };

        LoggerService.debug(
          'Sending transaction data',
          error: {
            'location_name': transactionData['location_name'],
            'latitude': transactionData['latitude'],
            'longitude': transactionData['longitude'],
          },
        );
        LoggerService.apiRequest('POST', 'transactions');

        // Check balance before adding expense
        if (_selectedType == 'expense') {
          final shouldContinue = await _checkBalanceBeforeExpense(
            double.parse(_amountController.text),
          );
          if (!shouldContinue) {
            setState(() => _isSubmitting = false);
            return;
          }
        }

        // Call API to add transaction
        await _apiService.addTransaction(transactionData);
        LoggerService.success('Transaction saved successfully');

        // Show success message
        if (!ctx.mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          ctx,
          AppLocalizations.of(ctx)!.transaction_saved_successfully,
        );

        if (!ctx.mounted) return;
        await AppRefresh.refreshAll(ctx);

        if (!ctx.mounted) return;
        Navigator.pop(ctx, true); // Return true to indicate success
      } catch (e) {
        LoggerService.error('Error adding transaction', error: e);
        if (!ctx.mounted) return;
        ErrorHandlerService.showErrorSnackbar(
          ctx,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: () => _submitForm(),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Tambah Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                _isScanningReceipt
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Iconsax.scan_barcode, color: Colors.white),
            onPressed: _isScanningReceipt ? null : _showReceiptScanOptions,
          ),
          IconButton(
            icon: const Icon(Iconsax.book_saved, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiptHistoryScreen(),
                ),
              );
            },
            tooltip: 'Riwayat Struk',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: ResponsiveHelper.padding(context),
                child: Column(
                  children: [
                    // Amount Input
                    AmountField(controller: _amountController),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Transaction Type Selector
                    TypeSelector(
                      selectedType: _selectedType,
                      onTypeChanged: (type) {
                        setState(() {
                          _selectedType = type;
                          _selectedCategory = null;

                          // Clear location when switching to income
                          if (type == 'income') {
                            _currentLocation = null;
                          } else if (type == 'expense' &&
                              _currentLocation == null) {
                            // Auto-get location when switching to expense
                            _getCurrentLocation();
                          }
                        });
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Category Selection
                    CategorySection(
                      selectedType: _selectedType,
                      selectedCategory: _selectedCategory,
                      categories: _categories,
                      isLoading: _isLoadingCategories,
                      onCategorySelected: (categoryId) {
                        setState(() => _selectedCategory = categoryId);
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Account Selection
                    AccountSection(
                      selectedAccountId: _selectedAccountId,
                      onAccountSelected: (accountId) {
                        setState(() => _selectedAccountId = accountId);
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Description
                    DescriptionField(controller: _descriptionController),
                    if (_categorySuggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _categorySuggestions.map((suggestion) {
                              final confidence =
                                  suggestion['confidence'] as double;
                              final category = suggestion['category'] as String;
                              return Material(
                                color: DesignTokens.primaryColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap:
                                      () =>
                                          _selectSuggestedCategory(suggestion),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Iconsax.tag,
                                          size: 14,
                                          color: DesignTokens.primaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          category,
                                          style: GoogleFonts.poppins(
                                            color: DesignTokens.primaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(confidence * 100).toInt()}%',
                                          style: GoogleFonts.poppins(
                                            color:
                                                DesignTokens.textTertiaryDark,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Location Section (only for expenses, not for income)
                    if (_selectedType == 'expense') ...[
                      LocationSection(
                        currentLocation: _currentLocation,
                        isGettingLocation: _isGettingLocation,
                        onGetLocation: _getCurrentLocation,
                        onPickFromMap: _pickLocationFromMap,
                        onClearLocation: _clearLocation,
                      ),
                      SizedBox(
                        height: ResponsiveHelper.verticalSpacing(context, 20),
                      ),
                    ],

                    // Date & Time
                    DateTimeSection(
                      selectedDate: _selectedDate,
                      selectedTime: _selectedTime,
                      onSelectDate: _selectDate,
                      onSelectTime: _selectTime,
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Payment Method
                    PaymentMethodSection(
                      selectedPaymentMethod: _selectedPaymentMethod,
                      onPaymentMethodSelected: (method) {
                        setState(() => _selectedPaymentMethod = method);
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Additional Options
                    AdditionalOptions(
                      isRecurring: _isRecurring,
                      onChanged:
                          (value) => setState(() => _isRecurring = value),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Notes
                    NotesField(controller: _notesController),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 30),
                    ),

                    // Save Button
                    SubmitButton(
                      onPressed: _submitForm,
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
