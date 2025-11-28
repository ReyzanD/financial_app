import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/app_refresh.dart';
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
        print('Error parsing date: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      print('🔄 Loading categories from API...');
      final categories = await _apiService
          .getCategories(forceRefresh: true)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ Category loading timed out');
              return [];
            },
          );
      print('✅ Categories loaded: ${categories.length}');
      if (mounted) {
        setState(() {
          _categories = categories.cast<Map<String, dynamic>>();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        // Show error to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat kategori: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi dihapus'),
        backgroundColor: Color(0xFF8B5FBF),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    print('📍 [AddTransaction] Attempting to get current location...');
    setState(() => _isGettingLocation = true);

    try {
      // Simulate location service
      final position = await LocationService.getCurrentLatLng();
      if (position == null) {
        print('❌ [AddTransaction] Location service returned null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal mendapatkan lokasi. Pastikan izin lokasi aktif.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print(
          '✅ [AddTransaction] Location received: ${position.latitude}, ${position.longitude}',
        );
        final placeName = LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        print('📍 [AddTransaction] Place name: $placeName');

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

        print('✅ [AddTransaction] Location set: $_currentLocation');

        // Auto-categorize based on location
        _autoCategorizeFromLocation();
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGettingLocation = false);
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
      lastDate: DateTime(2030),
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

      // If balance would be negative, block the transaction
      if (newBalance < 0) {
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
                            'Pengeluaran',
                            expenseAmount,
                            Colors.red[300]!,
                          ),
                          const Divider(color: Colors.grey, height: 20),
                          _buildBalanceRow(
                            'Kekurangan',
                            newBalance.abs(),
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
                              'Tambahkan pemasukan terlebih dahulu atau kurangi jumlah pengeluaran.',
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
                      'Mengerti',
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
      print('Error checking balance: $e');
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

        print('═══════════════════════════════════');
        print('📤 SENDING Transaction data:');
        print('   Location Name: ${transactionData['location_name']}');
        print('   Latitude: ${transactionData['latitude']}');
        print('   Longitude: ${transactionData['longitude']}');
        print('   Full data: $transactionData');
        print('═══════════════════════════════════');

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
        final response = await _apiService.addTransaction(transactionData);
        print('API Response: $response');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Trigger immediate app-wide refresh
        await AppRefresh.refreshAll(context);

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        print('Error adding transaction: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: Colors.red,
          ),
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
            icon: const Icon(Iconsax.scan_barcode, color: Colors.white),
            onPressed: () {
              // OCR receipt scanning feature
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Amount Input
              AmountField(controller: _amountController),
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

              // Description
              DescriptionField(controller: _descriptionController),
              const SizedBox(height: 20),

              // Location Section (only for expenses, not for income)
              if (_selectedType == 'expense') ...[
                LocationSection(
                  currentLocation: _currentLocation,
                  isGettingLocation: _isGettingLocation,
                  onGetLocation: _getCurrentLocation,
                  onPickFromMap: _pickLocationFromMap,
                  onClearLocation: _clearLocation,
                ),
                const SizedBox(height: 20),
              ],

              // Date & Time
              DateTimeSection(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                onSelectDate: _selectDate,
                onSelectTime: _selectTime,
              ),
              const SizedBox(height: 20),

              // Payment Method
              PaymentMethodSection(
                selectedPaymentMethod: _selectedPaymentMethod,
                onPaymentMethodSelected: (method) {
                  setState(() => _selectedPaymentMethod = method);
                },
              ),
              const SizedBox(height: 20),

              // Additional Options
              AdditionalOptions(
                isRecurring: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),
              const SizedBox(height: 20),

              // Notes
              NotesField(controller: _notesController),
              const SizedBox(height: 30),

              // Save Button
              SubmitButton(onPressed: _submitForm, isLoading: _isSubmitting),
            ],
          ),
        ),
      ),
    );
  }
}
