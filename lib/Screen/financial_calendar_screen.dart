import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/financial_calendar_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class FinancialCalendarScreen extends StatefulWidget {
  const FinancialCalendarScreen({super.key});

  @override
  State<FinancialCalendarScreen> createState() =>
      _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState extends State<FinancialCalendarScreen> {
  final FinancialCalendarService _calendarService =
      getIt<FinancialCalendarService>();

  bool _isLoading = true;
  String? _errorMessage;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _monthEvents = [];
  Map<String, dynamic> _selectedDaySummary = {};
  Map<int, int> _heatMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final results = await Future.wait([
        _calendarService.getMonthEvents(_selectedYear, _selectedMonth),
        _calendarService.getDaySummary(_selectedDay),
        _calendarService.getMonthlyHeatMap(_selectedYear, _selectedMonth),
      ]);

      if (!mounted) return;

      setState(() {
        _monthEvents = results[0] as List<Map<String, dynamic>>;
        _selectedDaySummary = results[1] as Map<String, dynamic>;
        _heatMap = results[2] as Map<int, int>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _getEventsForSelectedDay() {
    return _monthEvents.where((e) {
      final eventDate = e['date'] as DateTime;
      return eventDate.year == _selectedDay.year &&
          eventDate.month == _selectedDay.month &&
          eventDate.day == _selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const OfflineIndicator(),
            Expanded(child: _buildBody(context, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Iconsax.arrow_left,
                  color: DesignTokens.textPrimaryDark,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.dashboard ?? 'Kalender',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Iconsax.arrow_left,
                  color: DesignTokens.textPrimaryDark,
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedMonth == 1) {
                      _selectedMonth = 12;
                      _selectedYear--;
                    } else {
                      _selectedMonth--;
                    }
                    _selectedDay = DateTime(_selectedYear, _selectedMonth, 1);
                  });
                  _loadData();
                },
              ),
              Text(
                '${monthNames[_selectedMonth - 1]} $_selectedYear',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Iconsax.arrow_right,
                  color: DesignTokens.textPrimaryDark,
                ),
                onPressed: () {
                  setState(() {
                    if (_selectedMonth == 12) {
                      _selectedMonth = 1;
                      _selectedYear++;
                    } else {
                      _selectedMonth++;
                    }
                    _selectedDay = DateTime(_selectedYear, _selectedMonth, 1);
                  });
                  _loadData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations? l10n) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context, l10n);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCalendarGrid(context),
        const SizedBox(height: 16),
        _buildSelectedDayEvents(context, l10n),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final firstDayOfWeek = DateTime(_selectedYear, _selectedMonth, 1).weekday;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: daysInMonth + firstDayOfWeek - 1,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek - 1) {
                return const SizedBox.shrink();
              }

              final day = index - firstDayOfWeek + 2;
              final isSelected =
                  _selectedDay.year == _selectedYear &&
                  _selectedDay.month == _selectedMonth &&
                  _selectedDay.day == day;
              final hasEvents = _heatMap[day] != null && _heatMap[day]! > 0;
              final isToday =
                  DateTime.now().year == _selectedYear &&
                  DateTime.now().month == _selectedMonth &&
                  DateTime.now().day == day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = DateTime(_selectedYear, _selectedMonth, day);
                  });
                  _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? DesignTokens.primaryColor
                            : isToday
                            ? DesignTokens.primaryColor.withValues(alpha: 0.3)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        hasEvents && !isSelected
                            ? Border.all(
                              color: DesignTokens.errorColor.withValues(
                                alpha: 0.5,
                              ),
                            )
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        color:
                            isSelected
                                ? Colors.white
                                : hasEvents
                                ? DesignTokens.errorColor
                                : DesignTokens.textPrimaryDark,
                        fontSize: 12,
                        fontWeight:
                            isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEvents(BuildContext context, AppLocalizations? l10n) {
    final events = _getEventsForSelectedDay();
    final daySummary = _selectedDaySummary;
    final totalIncome = (daySummary['total_income'] as num?)?.toDouble() ?? 0.0;
    final totalExpense =
        (daySummary['total_expense'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedDay.day}/${_selectedDay.month} - ${events.length} ${l10n?.transactions ?? 'transaksi'}',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (totalIncome > 0 || totalExpense > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.income ?? 'Pemasukan',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(totalIncome.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.successColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.expense ?? 'Pengeluaran',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(totalExpense.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Center(
            child: Text(
              'Tidak ada event',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 14,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) => _buildEventItem(events[index]),
          ),
      ],
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final type = event['transaction_type'] ?? 'expense';
    final isIncome = type == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isIncome
                      ? DesignTokens.successColor.withValues(alpha: 0.15)
                      : DesignTokens.errorColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
              color:
                  isIncome
                      ? DesignTokens.successColor
                      : DesignTokens.errorColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? '',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: DesignTokens.textPrimaryDark,
                  ),
                ),
                Text(
                  event['description'] ?? '',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.formatRupiah((event['amount'] ?? 0).toInt())}',
            style: GoogleFonts.poppins(
              color:
                  isIncome
                      ? DesignTokens.successColor
                      : DesignTokens.errorColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
            ),
            child: Text(
              l10n?.retry ?? 'Coba Lagi',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
