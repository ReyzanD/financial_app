/// Utility class untuk form validation
class FormValidators {
  // Max amount: 999,999,999,999 (999 triliun)
  static const double maxAmount = 999999999999.0;
  static const double minAmount = 1.0;
  
  // Max description length
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;
  
  // Max name/title length
  static const int maxNameLength = 100;

  /// Validate amount input
  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Masukkan jumlah';
    }

    // Remove non-numeric characters for validation
    final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanValue.isEmpty) {
      return 'Masukkan jumlah yang valid';
    }

    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Masukkan angka yang valid';
    }

    final minValue = min ?? minAmount;
    if (amount < minValue) {
      return 'Jumlah minimal adalah ${_formatCurrency(minValue)}';
    }

    final maxValue = max ?? maxAmount;
    if (amount > maxValue) {
      return 'Jumlah maksimal adalah ${_formatCurrency(maxValue)}';
    }

    return null;
  }

  /// Validate description input
  static String? validateDescription(String? value, {int? maxLength}) {
    if (value == null || value.isEmpty) {
      return null; // Description is optional
    }

    final maxLen = maxLength ?? maxDescriptionLength;
    if (value.length > maxLen) {
      return 'Deskripsi maksimal $maxLen karakter';
    }

    // Check for potentially harmful characters
    if (value.contains('<script>') || value.contains('javascript:')) {
      return 'Deskripsi mengandung karakter yang tidak diizinkan';
    }

    return null;
  }

  /// Validate required text field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Field'} harus diisi';
    }
    return null;
  }

  /// Validate name/title field
  static String? validateName(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Nama'} harus diisi';
    }

    if (value.length > maxNameLength) {
      return '${fieldName ?? 'Nama'} maksimal $maxNameLength karakter';
    }

    return null;
  }

  /// Validate date - prevent future dates for expenses
  static String? validateDate(DateTime? date, {bool allowFuture = false}) {
    if (date == null) {
      return 'Pilih tanggal';
    }

    if (!allowFuture && date.isAfter(DateTime.now())) {
      return 'Tanggal tidak boleh di masa depan';
    }

    // Prevent dates too far in the past (more than 10 years)
    final tenYearsAgo = DateTime.now().subtract(const Duration(days: 3650));
    if (date.isBefore(tenYearsAgo)) {
      return 'Tanggal terlalu lama di masa lalu';
    }

    return null;
  }

  /// Validate notes field
  static String? validateNotes(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Notes are optional
    }

    if (value.length > maxNotesLength) {
      return 'Catatan maksimal $maxNotesLength karakter';
    }

    return null;
  }

  /// Check for duplicate transaction
  /// Returns true if transaction appears to be duplicate
  static bool isDuplicateTransaction({
    required double amount,
    required String description,
    required DateTime date,
    required List<Map<String, dynamic>> recentTransactions,
    Duration? timeWindow,
  }) {
    final window = timeWindow ?? const Duration(minutes: 5);
    final threshold = DateTime.now().subtract(window);

    for (var transaction in recentTransactions) {
      final txAmount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final txDescription = transaction['description']?.toString() ?? '';
      final txDate = transaction['date'] != null
          ? DateTime.tryParse(transaction['date'].toString())
          : null;

      if (txDate == null) continue;

      // Check if same amount, similar description, and within time window
      if ((txAmount - amount).abs() < 0.01 && // Same amount (within 1 cent)
          txDescription.toLowerCase().trim() ==
              description.toLowerCase().trim() &&
          txDate.isAfter(threshold)) {
        return true;
      }
    }

    return false;
  }

  /// Format currency for display
  static String _formatCurrency(double amount) {
    if (amount >= 1000000000000) {
      return '${(amount / 1000000000000).toStringAsFixed(1)}T';
    } else if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}Rb';
    }
    return amount.toStringAsFixed(0);
  }
}

