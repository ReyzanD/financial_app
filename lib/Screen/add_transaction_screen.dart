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
/// Last Updated: 2024

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/receipt_scanning_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/widgets/maps/location_picker_map.dart';
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

  // Form state
  String _selectedType = 'expense';
  String? _selectedCategory; // This will now store category_id (UUID)
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LocationData? _currentLocation;
  bool _isGettingLocation = false;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  bool _isScanningReceipt = false;

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
      // Pick image
      final imageFile = await _receiptService.pickImage(fromCamera: fromCamera);
      if (imageFile == null) {
        setState(() => _isScanningReceipt = false);
        return;
      }

      // Show scanning message
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

      // Scan receipt
      final scanResult = await _receiptService.scanReceipt(imageFile);

      if (scanResult != null && mounted) {
        final parsedData = scanResult['parsed_data'] as Map<String, dynamic>;
        final amount = (parsedData['total'] as num?)?.toDouble() ?? 0.0;
        final merchant = parsedData['merchant'] as String? ?? '';
        final dateStr = parsedData['date'] as String?;

        // Auto-populate form fields
        if (amount > 0) {
          _amountController.text = amount.toStringAsFixed(0);
        }
        if (merchant.isNotEmpty) {
          _descriptionController.text = merchant;
        }

        // Parse and set date if available
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            // Try to parse date (format: DD/MM/YYYY or DD-MM-YYYY)
            final dateParts = dateStr.split(RegExp(r'[/-]'));
            if (dateParts.length == 3) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final year = int.parse(
                dateParts[2].length == 2 ? '20${dateParts[2]}' : dateParts[2],
              );
              final parsedDate = DateTime(year, month, day);

              // Only set if date is valid and not in future (for expenses)
              if (_selectedType == 'expense' &&
                  parsedDate.isAfter(DateTime.now())) {
                // Don't set future dates for expenses
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

        // Set transaction type to expense (receipts are usually expenses)
        setState(() {
          _selectedType = 'expense';
        });

        // Show success message
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
        await showDialog(
          context: context,
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
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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

      // Check for duplicate transactions
      try {
        final recentTransactionsData = await _apiService.getTransactions(
          limit: 20,
        );
        final recentTransactions = List<Map<String, dynamic>>.from(
          recentTransactionsData['transactions'] ?? [],
        );
        final amount = double.parse(
          _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        final isDuplicate = FormValidators.isDuplicateTransaction(
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          recentTransactions: recentTransactions,
        );

        if (isDuplicate) {
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: Text(
                    AppLocalizations.of(context)!.duplicate_transaction,
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.similar_transaction_added,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                      ),
                      child: Text(AppLocalizations.of(context)!.continueText),
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
          'category_id': _selectedCategory, // Now sending category_id (UUID)
          'description': _descriptionController.text,
          'notes': _notesController.text,
          'payment_method': _selectedPaymentMethod,
          'transaction_date':
              _selectedDate.toIso8601String().split(
                'T',
              )[0], // Just the date part
          'time':
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          // Add location fields at top level for database
          if (_currentLocation != null)
            'location_name':
                _currentLocation!.placeName ?? _currentLocation!.address ?? '',
          if (_currentLocation != null) 'latitude': _currentLocation!.latitude,
          if (_currentLocation != null)
            'longitude': _currentLocation!.longitude,
          if (_currentLocation != null) 'address': _currentLocation!.address,
          'location_data':
              _currentLocation != null
                  ? {
                    'latitude': _currentLocation?.latitude,
                    'longitude': _currentLocation?.longitude,
                    'place_name': _currentLocation?.placeName,
                    'address': _currentLocation?.address,
                  }
                  : null,
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
        if (context.mounted) {
          ErrorHandlerService.showSuccessSnackbar(
            context,
            AppLocalizations.of(context)!.transaction_saved_successfully,
          );
        }

        // Trigger immediate app-wide refresh
        await AppRefresh.refreshAll(context);

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        LoggerService.error('Error adding transaction', error: e);
        if (context.mounted) {
          ErrorHandlerService.showErrorSnackbar(
            context,
            ErrorHandlerService.getUserFriendlyMessage(e),
            onRetry: () => _submitForm(),
          );
        }
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: ResponsiveHelper.padding(context),
          child: Column(
            children: [
              // Amount Input
              AmountField(controller: _amountController),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

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
                    } else if (type == 'expense' && _currentLocation == null) {
                      // Auto-get location when switching to expense
                      _getCurrentLocation();
                    }
                  });
                },
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

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
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

              // Description
              DescriptionField(controller: _descriptionController),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

              // Location Section (only for expenses, not for income)
              if (_selectedType == 'expense') ...[
                LocationSection(
                  currentLocation: _currentLocation,
                  isGettingLocation: _isGettingLocation,
                  onGetLocation: _getCurrentLocation,
                  onPickFromMap: _pickLocationFromMap,
                  onClearLocation: _clearLocation,
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),
              ],

              // Date & Time
              DateTimeSection(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                onSelectDate: _selectDate,
                onSelectTime: _selectTime,
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

              // Payment Method
              PaymentMethodSection(
                selectedPaymentMethod: _selectedPaymentMethod,
                onPaymentMethodSelected: (method) {
                  setState(() => _selectedPaymentMethod = method);
                },
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

              // Additional Options
              AdditionalOptions(
                isRecurring: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

              // Notes
              NotesField(controller: _notesController),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 30)),

              // Save Button
              SubmitButton(onPressed: _submitForm, isLoading: _isSubmitting),
            ],
          ),
        ),
      ),
    );
  }
}
