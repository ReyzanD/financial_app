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
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/receipt_scanning_service.dart';
import 'package:financial_app/services/smart_categorization_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/price_observation_data_service.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/utils/date_picker_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/balance_check_helper.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/widgets/maps/location_picker_map.dart';
import 'package:financial_app/widgets/add_transaction/amount_field.dart';
import 'package:financial_app/widgets/add_transaction/type_selector.dart';
import 'package:financial_app/widgets/add_transaction/category_section.dart';
import 'package:financial_app/widgets/add_transaction/description_field.dart';
import 'package:financial_app/widgets/add_transaction/date_time_section.dart';
import 'package:financial_app/widgets/add_transaction/submit_button.dart';
import 'package:financial_app/widgets/add_transaction/more_options_section.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/receipt_history/presentation/screens/receipt_history_screen.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Optional for edit mode
  final VoidCallback? onUpdated;

  /// Optional: pre-select transaction type ('income' or 'expense').
  /// If null, defaults to 'expense' (or the transaction's type in edit mode).
  final String? defaultType;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.onUpdated,
    this.defaultType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();

  bool get isEditMode => transaction != null;
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final TransactionDataService _transactionData =
      getIt<TransactionDataService>();
  final CategoryDataService _categoryData = getIt<CategoryDataService>();
  final ReceiptScanningService _receiptService =
      getIt<ReceiptScanningService>();
  final SmartCategorizationService _categorizationService =
      getIt<SmartCategorizationService>();

  // Form state
  late String _selectedType;
  String? _selectedCategory;
  String? _selectedAccountId;
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LocationData? _currentLocation;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;
  bool _isScanningReceipt = false;
  String? _receiptImagePath;
  List<Map<String, dynamic>> _categorySuggestions = [];

  // Recurring transaction state
  bool _isRecurring = false;
  String? _recurringFrequency;

  // Category data from API
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    // Initialize type: defaultType param > edit mode > 'expense'
    _selectedType =
        widget.defaultType ??
        (widget.transaction?['type']?.toString()) ??
        'expense';

    // If editing, populate form with existing data
    if (widget.isEditMode) {
      _populateFormData();
    }

    // Load categories from API
    _loadCategories();

    _descriptionController.addListener(_onDescriptionChanged);
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
      final categories = await _categoryData.getCategories().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          LoggerService.warning('Category loading timed out');
          return <CategoryModel>[];
        },
      );
      LoggerService.success('Categories loaded: ${categories.length}');
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;

          // Pre-select a default category if none is selected and not in edit mode
          if (!widget.isEditMode && _selectedCategory == null) {
            final filtered =
                _categories.where((cat) => cat.type == _selectedType).toList();
            if (filtered.isNotEmpty) {
              // Prefer "Lainnya" or "Other" category as sensible default
              final defaultCat = filtered.firstWhere((cat) {
                final name = cat.name.toLowerCase();
                return name == 'lainnya' || name == 'other';
              }, orElse: () => filtered.first);
              _selectedCategory = defaultCat.id;
            }
          }
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
    final normalizedName = categoryName.toLowerCase();
    for (final cat in _categories) {
      final name = cat.name.toLowerCase();
      if (name.contains(normalizedName) || normalizedName.contains(name)) {
        return cat.id;
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
      AppLocalizations.of(context)?.location_removed ?? 'Location removed',
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
            AppLocalizations.of(context)?.failed_to_get_location ??
                'Failed to get location',
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

        if (mounted) {
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
        }

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
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _showReceiptScanOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DesignTokens.surfaceDark,
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
                  AppLocalizations.of(context)?.select_image_source ??
                      'Select Image Source',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing5),
                ListTile(
                  leading: const Icon(
                    Iconsax.camera,
                    color: DesignTokens.primaryColor,
                  ),
                  title: Text(
                    AppLocalizations.of(context)?.take_photo ?? 'Take Photo',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(
                    Iconsax.gallery,
                    color: DesignTokens.primaryColor,
                  ),
                  title: Text(
                    AppLocalizations.of(context)?.choose_from_gallery ??
                        'Choose from Gallery',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)?.cancel ?? 'Cancel',
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
        ErrorHandlerService.showInfoSnackbar(
          context,
          AppLocalizations.of(context)?.loading ?? 'Loading...',
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

        ErrorHandlerService.showSuccessSnackbar(
          context,
          AppLocalizations.of(context)?.receipt_scanned_successfully ??
              'Receipt scanned successfully',
        );

        LoggerService.success('Receipt scanned successfully');
      } else {
        if (mounted) {
          ErrorHandlerService.showWarningSnackbar(
            context,
            AppLocalizations.of(context)?.cannot_scan_receipt ??
                'Cannot scan receipt',
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error scanning receipt', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          AppLocalizations.of(context)?.error_scanning_receipt ??
              'Error scanning receipt',
        );
      }
    } finally {
      if (mounted) setState(() => _isScanningReceipt = false);
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
      final matches = _categories.where(
        (cat) => cat.name.toLowerCase().contains(categoryName!),
      );

      if (matches.isNotEmpty) {
        setState(() {
          _selectedCategory = matches.first.id;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await DatePickerHelper.showDarkDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate:
          _selectedType == 'expense'
              ? DateTime.now()
              : DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
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
              primary: DesignTokens.primaryColor,
              onPrimary: Colors.white,
              surface: DesignTokens.surfaceDark,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: DesignTokens.backgroundDark,
            ),
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final ctx = context;

      // Check for duplicate transactions
      try {
        final recentTransactionsData = await _transactionData.getTransactions(
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
                  backgroundColor: DesignTokens.surfaceDark,
                  title: Text(
                    AppLocalizations.of(ctx)?.duplicate_transaction ??
                        'Duplicate Transaction?',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    AppLocalizations.of(ctx)?.similar_transaction_added ??
                        'A similar transaction was just added',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(AppLocalizations.of(ctx)?.cancel ?? 'Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryColor,
                      ),
                      child: Text(
                        AppLocalizations.of(ctx)?.continueText ?? 'Continue',
                      ),
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

      if (!ctx.mounted) return;
      setState(() => _isSubmitting = true);

      try {
        // Prepare transaction data for API
        final parsedAmount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        if (parsedAmount == null || parsedAmount <= 0) {
          ErrorHandlerService.showWarningSnackbar(
            ctx,
            AppLocalizations.of(ctx)?.invalid_amount ?? 'Jumlah tidak valid',
          );
          setState(() => _isSubmitting = false);
          return;
        }
        final transactionData = {
          'amount': parsedAmount,
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
          if (_isRecurring) 'is_recurring': true,
          if (_isRecurring && _recurringFrequency != null)
            'recurring_pattern': _recurringFrequency,
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
          final parsedAmount = double.tryParse(_amountController.text);
          if (parsedAmount == null || parsedAmount <= 0) {
            ErrorHandlerService.showWarningSnackbar(
              context,
              AppLocalizations.of(context)?.invalid_amount ??
                  'Jumlah tidak valid',
            );
            setState(() => _isSubmitting = false);
            return;
          }
          final shouldContinue = await _checkBalanceBeforeExpense(parsedAmount);
          if (!shouldContinue) {
            setState(() => _isSubmitting = false);
            return;
          }
        }

        // Call API to add transaction
        final savedTx = await _transactionData.addTransaction(transactionData);
        LoggerService.success('Transaction saved successfully');

        // Auto-create PlaceVisit + PriceObservation for location-based features
        if (savedTx.locationData != null) {
          try {
            final pvService = getIt<PlaceVisitDataService>();
            final poService = getIt<PriceObservationDataService>();
            final placeVisit = await pvService.upsertFromTransaction(savedTx);
            await poService.createFromTransaction(
              placeVisitId: placeVisit.id,
              transaction: savedTx,
            );
            LoggerService.info(
              '✅ PlaceVisit + PriceObservation created for ${placeVisit.placeName}',
            );
          } catch (e) {
            LoggerService.warning(
              'Non-critical: could not create place visit',
              error: e,
            );
          }
        }

        // If it's an expense, update the budget spent amount
        if (_selectedType == 'expense') {
          try {
            final budgetAmount = double.tryParse(
              _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
            );
            if (budgetAmount != null && budgetAmount > 0) {
              await getIt<BudgetDataService>().updateBudgetForExpense(
                categoryId: _selectedCategory ?? '',
                amount: budgetAmount,
                transactionDate: _selectedDate,
              );
            }
          } catch (e) {
            LoggerService.warning('Budget update not critical', error: e);
          }
        }

        // Show success message
        if (!ctx.mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          ctx,
          AppLocalizations.of(ctx)?.transaction_saved_successfully ??
              'Transaction saved successfully!',
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
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        title: Text(
          l10n?.add_transaction ?? 'Tambah Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: l10n?.back ?? 'Kembali',
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
            tooltip: l10n?.scan_receipt ?? 'Pindai',
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
            tooltip: l10n?.receipt_history ?? 'Riwayat Struk',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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

                          if (type == 'income') {
                            _currentLocation = null;
                          }
                        });
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Category Selection
                    FormField<String>(
                      initialValue: _selectedCategory,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n?.select_category ?? 'Pilih kategori';
                        }
                        return null;
                      },
                      builder: (FormFieldState<String> field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CategorySection(
                              selectedType: _selectedType,
                              selectedCategory: _selectedCategory,
                              categories: _categories,
                              isLoading: _isLoadingCategories,
                              onCategorySelected: (categoryId) {
                                field.didChange(categoryId);
                                setState(() => _selectedCategory = categoryId);
                              },
                            ),
                            if (field.hasError)
                              Semantics(
                                liveRegion: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 12,
                                  ),
                                  child: Text(
                                    field.errorText!,
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // Description
                    DescriptionField(controller: _descriptionController),
                    if (_categorySuggestions.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.spacing3),
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

                    // Date & Time
                    FormField<DateTime>(
                      initialValue: _selectedDate,
                      validator: (value) {
                        return FormValidators.validateDate(
                          value,
                          allowFuture: _selectedType == 'income',
                        );
                      },
                      builder: (FormFieldState<DateTime> field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateTimeSection(
                              selectedDate: _selectedDate,
                              selectedTime: _selectedTime,
                              onSelectDate: () {
                                _selectDate().then((_) {
                                  field.didChange(_selectedDate);
                                });
                              },
                              onSelectTime: _selectTime,
                            ),
                            if (field.hasError)
                              Semantics(
                                liveRegion: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    field.errorText!,
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 20),
                    ),

                    // More Options (collapsible — Account, Payment, Location, Notes, Recurring)
                    MoreOptionsSection(
                      selectedAccountId: _selectedAccountId,
                      onAccountSelected: (accountId) {
                        setState(() => _selectedAccountId = accountId);
                      },
                      selectedPaymentMethod: _selectedPaymentMethod,
                      onPaymentMethodSelected: (method) {
                        setState(() => _selectedPaymentMethod = method);
                      },
                      currentLocation:
                          _selectedType == 'expense' ? _currentLocation : null,
                      isGettingLocation: _isGettingLocation,
                      onGetLocation: _getCurrentLocation,
                      onPickFromMap: _pickLocationFromMap,
                      onClearLocation: _clearLocation,
                      notesController: _notesController,
                      showRecurring: !widget.isEditMode,
                      isRecurring: _isRecurring,
                      onRecurringChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                          if (!value) _recurringFrequency = null;
                        });
                      },
                      recurringFrequency: _recurringFrequency,
                      onRecurringFrequencyChanged: (value) {
                        setState(() => _recurringFrequency = value);
                      },
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 24),
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
