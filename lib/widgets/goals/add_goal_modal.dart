import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:intl/intl.dart';

class AddGoalModal extends StatefulWidget {
  final Map<String, dynamic>? initialGoal;

  const AddGoalModal({super.key, this.initialGoal});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();

  String _selectedType = 'emergency_fund';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  int _priority = 3;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _goalTypes = [
    {
      'value': 'emergency_fund',
      'label': 'Dana Darurat',
      'icon': Icons.security,
    },
    {'value': 'vacation', 'label': 'Liburan', 'icon': Icons.beach_access},
    {'value': 'investment', 'label': 'Investasi', 'icon': Icons.trending_up},
    {'value': 'debt_payment', 'label': 'Bayar Hutang', 'icon': Icons.payment},
    {'value': 'education', 'label': 'Pendidikan', 'icon': Icons.school},
    {'value': 'vehicle', 'label': 'Kendaraan', 'icon': Icons.directions_car},
    {'value': 'house', 'label': 'Rumah', 'icon': Icons.home},
    {'value': 'wedding', 'label': 'Pernikahan', 'icon': Icons.favorite},
    {'value': 'other', 'label': 'Lainnya', 'icon': Icons.more_horiz},
  ];

  bool get _isEdit => widget.initialGoal != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialGoal;
    if (initial != null) {
      final name = initial['name'] as String?;
      if (name != null) {
        _nameController.text = name;
      }

      final description = initial['description'] as String?;
      if (description != null) {
        _descriptionController.text = description;
      }

      final targetValue = initial['target'];
      double? targetAmount;
      if (targetValue is num) {
        targetAmount = targetValue.toDouble();
      } else if (targetValue != null) {
        targetAmount = double.tryParse(targetValue.toString());
      }
      if (targetAmount != null) {
        _targetAmountController.text = targetAmount.toStringAsFixed(0);
      }

      final type = initial['type'] as String?;
      if (type != null && type.isNotEmpty) {
        _selectedType = type;
      }

      final deadlineStr = initial['deadline'] as String?;
      if (deadlineStr != null && deadlineStr.isNotEmpty) {
        try {
          _targetDate = DateTime.parse(deadlineStr);
        } catch (_) {}
      }

      final priorityValue = initial['priority'];
      if (priorityValue is int) {
        _priority = priorityValue;
      } else if (priorityValue is String) {
        final parsed = int.tryParse(priorityValue);
        if (parsed != null) {
          _priority = parsed;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
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
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _submitGoal() async {
    LoggerService.debug('Submit button pressed');

    if (!_formKey.currentState!.validate()) {
      LoggerService.warning('Form validation failed');
      return;
    }

    LoggerService.debug('Form validated successfully');

    setState(() {
      _isLoading = true;
    });

    try {
      final goalData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'goal_type': _selectedType,
        'target_amount': double.parse(_targetAmountController.text),
        'target_date': DateFormat('yyyy-MM-dd').format(_targetDate),
        'priority': _priority,
      };

      if (_isEdit) {
        final goalId = widget.initialGoal?['id']?.toString();
        if (goalId == null || goalId.isEmpty) {
          throw Exception('ID goal tidak valid');
        }

        LoggerService.info('Updating goal $goalId');
        LoggerService.debug('Goal data', error: goalData);
        await _apiService.updateGoal(goalId, goalData);
        LoggerService.success('Goal updated successfully');

        if (mounted) {
          Navigator.pop(context, true);
          if (context.mounted) {
            ErrorHandlerService.showSuccessSnackbar(
              context,
              'Target berhasil diperbarui!',
            );
          }
        }
      } else {
        final createData = {...goalData, 'current_amount': 0};

        LoggerService.info('Creating new goal');
        LoggerService.debug('Goal data', error: createData);

        await _apiService.createGoal(createData);

        LoggerService.success('Goal created successfully');

        if (mounted) {
          Navigator.pop(context, true);
          if (context.mounted) {
            ErrorHandlerService.showSuccessSnackbar(
              context,
              'Target berhasil ditambahkan!',
            );
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error creating/updating goal', error: e);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (context.mounted) {
          ErrorHandlerService.showErrorSnackbar(
            context,
            ErrorHandlerService.getUserFriendlyMessage(e),
            onRetry: _submitGoal,
          );
        }
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
                'Tambah Target Baru',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nama Target',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama target harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Goal Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tipe Target',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    _goalTypes.map<DropdownMenuItem<String>>((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'] as String,
                        child: Row(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: const Color(0xFF8B5FBF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(type['label'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Jumlah Target (Rp)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah target harus diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Date
              InkWell(
                onTap: _selectTargetDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Tanggal',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(_targetDate),
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

              // Priority Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prioritas: ${_priority == 5
                        ? "Sangat Tinggi"
                        : _priority == 4
                        ? "Tinggi"
                        : _priority == 3
                        ? "Sedang"
                        : _priority == 2
                        ? "Rendah"
                        : "Sangat Rendah"}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Slider(
                    value: _priority.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFF8B5FBF),
                    inactiveColor: Colors.grey[800],
                    onChanged: (value) {
                      setState(() {
                        _priority = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitGoal,
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
                        : const Text('Tambah Target'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
