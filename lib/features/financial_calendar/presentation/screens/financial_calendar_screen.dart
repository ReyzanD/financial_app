import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/financial_calendar/presentation/controllers/calendar_controller.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CalendarController>().loadMonthEvents(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Consumer<CalendarController>(
              builder: (_, ctrl, __) => _buildHeader(context, l10n, ctrl),
            ),
            const OfflineIndicator(),
            Expanded(
              child: Consumer<CalendarController>(
                builder: (_, ctrl, __) {
                  if (ctrl.isLoading)
                    return Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryColor,
                      ),
                    );
                  if (ctrl.error != null)
                    return _buildErrorState(context, l10n, ctrl);
                  return ListView(
                    padding: const EdgeInsets.all(DesignTokens.spacing4),
                    children: [
                      _buildCalendarGrid(context, ctrl),
                      const SizedBox(height: DesignTokens.spacing4),
                      _buildSelectedDayEvents(context, l10n, ctrl),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    CalendarController ctrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Row(
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
              final m = ctrl.selectedMonth == 1 ? 12 : ctrl.selectedMonth - 1;
              final y =
                  ctrl.selectedMonth == 1
                      ? ctrl.selectedYear - 1
                      : ctrl.selectedYear;
              ctrl.setDate(y, m, DateTime(y, m, 1));
            },
          ),
          Text(
            '${monthNames[ctrl.selectedMonth - 1]} ${ctrl.selectedYear}',
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
              final m = ctrl.selectedMonth == 12 ? 1 : ctrl.selectedMonth + 1;
              final y =
                  ctrl.selectedMonth == 12
                      ? ctrl.selectedYear + 1
                      : ctrl.selectedYear;
              ctrl.setDate(y, m, DateTime(y, m, 1));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, CalendarController ctrl) {
    final daysInMonth =
        DateTime(ctrl.selectedYear, ctrl.selectedMonth + 1, 0).day;
    final firstDayOfWeek =
        DateTime(ctrl.selectedYear, ctrl.selectedMonth, 1).weekday;
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
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
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
          const SizedBox(height: DesignTokens.spacing2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: daysInMonth + firstDayOfWeek - 1,
            itemBuilder: (_, index) {
              if (index < firstDayOfWeek - 1) return const SizedBox.shrink();
              final day = index - firstDayOfWeek + 2;
              final isSelected =
                  ctrl.selectedDay.year == ctrl.selectedYear &&
                  ctrl.selectedDay.month == ctrl.selectedMonth &&
                  ctrl.selectedDay.day == day;
              final isToday =
                  DateTime.now().year == ctrl.selectedYear &&
                  DateTime.now().month == ctrl.selectedMonth &&
                  DateTime.now().day == day;
              return GestureDetector(
                onTap:
                    () => ctrl.setDate(
                      ctrl.selectedYear,
                      ctrl.selectedMonth,
                      DateTime(ctrl.selectedYear, ctrl.selectedMonth, day),
                    ),
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
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        color:
                            isSelected
                                ? Colors.white
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

  Widget _buildSelectedDayEvents(
    BuildContext context,
    AppLocalizations? l10n,
    CalendarController ctrl,
  ) {
    final dayEvents =
        ctrl.events.where((e) {
          final d =
              e['date'] as DateTime? ??
              (e['date_str'] is String
                  ? DateTime.tryParse(e['date_str'] as String)
                  : null);
          if (d == null) return false;
          return d.year == ctrl.selectedDay.year &&
              d.month == ctrl.selectedDay.month &&
              d.day == ctrl.selectedDay.day;
        }).toList();
    double totalIncome = 0, totalExpense = 0;
    for (final ev in dayEvents) {
      if (ev['transaction_type'] == 'income')
        totalIncome += (ev['amount'] ?? 0).toDouble();
      else
        totalExpense += (ev['amount'] ?? 0).toDouble();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ctrl.selectedDay.day}/${ctrl.selectedDay.month} - ${dayEvents.length} ${l10n?.transactions ?? 'transaksi'}',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing2),
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
        const SizedBox(height: DesignTokens.spacing3),
        if (dayEvents.isEmpty)
          Center(
            child: Text(
              l10n?.no_events ?? 'Tidak ada event',
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
            itemCount: dayEvents.length,
            itemBuilder: (_, i) => _buildEventItem(dayEvents[i]),
          ),
      ],
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final isIncome = event['transaction_type'] == 'income';
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

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations? l10n,
    CalendarController ctrl,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            ctrl.error ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
          ElevatedButton(
            onPressed: ctrl.loadMonthEvents,
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
