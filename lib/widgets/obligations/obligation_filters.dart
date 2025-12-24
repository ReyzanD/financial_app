import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Filter options untuk obligations
class ObligationFilters {
  final String? type; // 'bill', 'debt', 'subscription', null for all
  final String? category;
  final String? status; // 'active', 'overdue', 'paid', null for all
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  ObligationFilters({
    this.type,
    this.category,
    this.status,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
  });

  bool get hasFilters {
    return type != null ||
        category != null ||
        status != null ||
        minAmount != null ||
        maxAmount != null ||
        startDate != null ||
        endDate != null;
  }

  ObligationFilters copyWith({
    String? type,
    String? category,
    String? status,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ObligationFilters(
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Widget untuk advanced filtering
class ObligationFiltersWidget extends StatefulWidget {
  final ObligationFilters initialFilters;
  final Function(ObligationFilters) onFiltersChanged;

  const ObligationFiltersWidget({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<ObligationFiltersWidget> createState() =>
      _ObligationFiltersWidgetState();
}

class _ObligationFiltersWidgetState extends State<ObligationFiltersWidget> {
  late ObligationFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.filter,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (_filters.hasFilters)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filters = ObligationFilters();
                        });
                        widget.onFiltersChanged(_filters);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.reset,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type Filter
          Text(
            AppLocalizations.of(context)!.type,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                AppLocalizations.of(context)!.all,
                _filters.type == null,
                () {
                  setState(() {
                    _filters = _filters.copyWith(type: null);
                  });
                },
              ),
              _buildFilterChip(
                AppLocalizations.of(context)!.bill,
                _filters.type == 'bill',
                () {
                  setState(() {
                    _filters = _filters.copyWith(type: 'bill');
                  });
                },
              ),
              _buildFilterChip(
                AppLocalizations.of(context)!.debt,
                _filters.type == 'debt',
                () {
                  setState(() {
                    _filters = _filters.copyWith(type: 'debt');
                  });
                },
              ),
              _buildFilterChip(
                AppLocalizations.of(context)!.subscription,
                _filters.type == 'subscription',
                () {
                  setState(() {
                    _filters = _filters.copyWith(type: 'subscription');
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter
          Text(
            AppLocalizations.of(context)!.status,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                AppLocalizations.of(context)!.all,
                _filters.status == null,
                () {
                  setState(() {
                    _filters = _filters.copyWith(status: null);
                  });
                },
              ),
              _buildFilterChip(
                AppLocalizations.of(context)!.active,
                _filters.status == 'active',
                () {
                  setState(() {
                    _filters = _filters.copyWith(status: 'active');
                  });
                },
              ),
              _buildFilterChip(
                AppLocalizations.of(context)!.overdue,
                _filters.status == 'overdue',
                () {
                  setState(() {
                    _filters = _filters.copyWith(status: 'overdue');
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged(_filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5FBF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.apply_filter,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF8B5FBF).withOpacity(0.2)
                  : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5FBF) : Colors.grey[800]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? const Color(0xFF8B5FBF) : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
