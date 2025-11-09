import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/services/api_service.dart';
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
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Form state
  String _selectedType = 'expense';
  String? _selectedCategory;
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  LocationData? _currentLocation;
  bool _isGettingLocation = false;
  bool _isRecurring = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-get location when screen opens
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Simulate location service
      await Future.delayed(const Duration(seconds: 2));

      // Mock location data - in real app, use geolocator package
      setState(() {
        _currentLocation = LocationData(
          latitude: -6.2088,
          longitude: 106.8456,
          placeName: 'Restaurant Sederhana',
          address: 'Jl. Sudirman No. 123, Jakarta',
          placeType: 'restaurant',
        );
      });

      // Auto-categorize based on location
      _autoCategorizeFromLocation();
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
    if (_currentLocation?.placeType == 'restaurant' ||
        _currentLocation?.placeName?.toLowerCase().contains('restaurant') ==
            true) {
      setState(() {
        _selectedCategory = 'food';
      });
    } else if (_currentLocation?.placeType == 'gas_station') {
      setState(() {
        _selectedCategory = 'transport';
      });
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
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'notes': _notesController.text,
          'payment_method': _selectedPaymentMethod,
          'date':
              _selectedDate.toIso8601String().split(
                'T',
              )[0], // Just the date part
          'time':
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'latitude': _currentLocation?.latitude,
          'longitude': _currentLocation?.longitude,
          'location_name': _currentLocation?.placeName,
          'location_address': _currentLocation?.address,
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
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
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
