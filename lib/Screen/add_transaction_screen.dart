import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/location_service.dart';
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

    // Auto-get location when screen opens (only for new transactions)
    if (!widget.isEditMode) {
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
    setState(() => _isGettingLocation = true);

    try {
      // Simulate location service
      final position = await LocationService.getCurrentLatLng();
      if (position == null) {
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
        // Mock location data - in real app, use geolocator package
        setState(() {
          _currentLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            placeName: LocationService.getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            ),
            address: null,
            placeType: null,
          );
        });

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

        print('Transaction data: $transactionData');

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

        // Refresh dashboard data - this will be handled by the home screen
        // when we pop back to it

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

              // Location Section
              LocationSection(
                currentLocation: _currentLocation,
                isGettingLocation: _isGettingLocation,
                onGetLocation: _getCurrentLocation,
                onPickFromMap: _pickLocationFromMap,
                onClearLocation: _clearLocation,
              ),
              const SizedBox(height: 20),

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
