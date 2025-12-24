import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_reminder_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Widget untuk mengatur reminder settings untuk obligation
class ReminderSettings extends StatefulWidget {
  final FinancialObligation obligation;

  const ReminderSettings({super.key, required this.obligation});

  @override
  State<ReminderSettings> createState() => _ReminderSettingsState();
}

class _ReminderSettingsState extends State<ReminderSettings> {
  final ObligationReminderService _reminderService =
      ObligationReminderService();
  bool _remindersEnabled = true;
  int _reminderDays = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    setState(() => _isLoading = true);
    try {
      final enabled = await _reminderService.getReminderEnabled(
        widget.obligation.id,
      );
      final days = await _reminderService.getReminderDays(widget.obligation.id);

      setState(() {
        _remindersEnabled = enabled;
        _reminderDays = days;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading reminder settings', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() => _remindersEnabled = value);
    await _reminderService.setReminderEnabled(widget.obligation.id, value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? AppLocalizations.of(context)!.reminder_enabled
                : AppLocalizations.of(context)!.reminder_disabled,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF8B5FBF),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setReminderDays(int days) async {
    setState(() => _reminderDays = days);
    await _reminderService.setReminderDays(widget.obligation.id, days);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.reminder_set} $days hari',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF8B5FBF),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _snoozeReminder() async {
    await _reminderService.snoozeReminder(widget.obligation.id, hours: 24);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.reminder_snoozed,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.notification,
                color: const Color(0xFF8B5FBF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.reminder_settings,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle reminders
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.enable_reminders,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.reminder_description,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
            value: _remindersEnabled,
            onChanged: _toggleReminders,
            activeColor: const Color(0xFF8B5FBF),
          ),

          if (_remindersEnabled) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),

            // Reminder days selector
            Text(
              '${AppLocalizations.of(context)!.reminder_days} $_reminderDays hari',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildReminderDayChip(1, AppLocalizations.of(context)!.one_day),
                const SizedBox(width: 8),
                _buildReminderDayChip(
                  3,
                  AppLocalizations.of(context)!.three_days,
                ),
                const SizedBox(width: 8),
                _buildReminderDayChip(
                  7,
                  AppLocalizations.of(context)!.seven_days,
                ),
                const SizedBox(width: 8),
                _buildReminderDayChip(
                  14,
                  AppLocalizations.of(context)!.fourteen_days,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Snooze button
            if (widget.obligation.daysUntilDue <= 3 &&
                widget.obligation.daysUntilDue >= 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _snoozeReminder,
                  icon: const Icon(Iconsax.timer, size: 18),
                  label: Text(
                    AppLocalizations.of(context)!.snooze_reminder,
                    style: GoogleFonts.poppins(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderDayChip(int days, String label) {
    final isSelected = _reminderDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setReminderDays(days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF8B5FBF).withOpacity(0.2)
                    : Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B5FBF) : Colors.grey[800]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? const Color(0xFF8B5FBF) : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
