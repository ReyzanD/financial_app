import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/notification_history_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = getIt<NotificationService>();
  final NotificationHistoryService _historyService = getIt<NotificationHistoryService>();

  List<Map<String, dynamic>> _history = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  bool _budgetAlertsEnabled = true;
  bool _billRemindersEnabled = true;
  bool _goalNotificationsEnabled = true;
  bool _dailySummaryEnabled = false;
  bool _weeklySummaryEnabled = false;
  bool _aiInsightsEnabled = true;
  int _dailySummaryHour = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history = await _historyService.getHistory();
      final unread = await _historyService.getUnreadCount();
      await _loadSettings();
      if (mounted)
        setState(() {
          _history = history;
          _unreadCount = unread;
          _isLoading = false;
        });
    } catch (e) {
      LoggerService.error('Error loading notifications', error: e);
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() {
        _budgetAlertsEnabled = prefs.getBool('budget_alerts') ?? true;
        _billRemindersEnabled = prefs.getBool('bill_reminders') ?? true;
        _goalNotificationsEnabled = prefs.getBool('goal_notifications') ?? true;
        _dailySummaryEnabled = prefs.getBool('daily_summary') ?? false;
        _weeklySummaryEnabled = prefs.getBool('weekly_summary') ?? false;
        _aiInsightsEnabled = prefs.getBool('ai_insights') ?? true;
        _dailySummaryHour = prefs.getInt('daily_summary_hour') ?? 20;
      });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)
      await prefs.setBool(key, value);
    else if (value is int)
      await prefs.setInt(key, value);
  }

  String _formatTimestamp(String timestamp, AppLocalizations? l10n) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n?.just_now ?? 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} ${l10n?.minutes_ago ?? 'menit yang lalu'}';
    if (diff.inHours < 24) return '${diff.inHours} ${l10n?.hours_ago ?? 'jam yang lalu'}';
    if (diff.inDays < 7) return '${diff.inDays} ${l10n?.days_ago ?? 'hari yang lalu'}';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)?.notifications ?? 'Notifications',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () async {
                await _historyService.markAllAsRead();
                _loadData();
              },
              child: Text(
                AppLocalizations.of(context)!.mark_all,
                style: GoogleFonts.poppins(color: DesignTokens.primaryColor, fontSize: 13),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.primaryColor,
          labelColor: DesignTokens.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.history),
            Tab(text: AppLocalizations.of(context)!.scheduled),
            Tab(text: AppLocalizations.of(context)!.settings),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor))
                    : _errorMessage != null
                    ? _buildErrorState()
                    : TabBarView(
                      controller: _tabController,
                      children: [_buildHistoryTab(), _buildPendingTab(), _buildSettingsTab()],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            const SizedBox(height: DesignTokens.spacing4),
            Text(
              l10n?.error ?? 'Terjadi kesalahan',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(_errorMessage ?? '', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: DesignTokens.spacing6),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
              child: Text(l10n?.retry ?? 'Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.notification, size: 80, color: Colors.grey),
            const SizedBox(height: DesignTokens.spacing4),
            Text(
              AppLocalizations.of(context)!.no_notifications_yet,
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.notifications_will_appear_here,
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final notification = _history[index];
        final isUnread = notification['read'] == false;

        return Dismissible(
          key: Key(notification['id']),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Iconsax.trash, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) async {
            setState(() {
              _history.removeAt(index);
              if (notification['read'] == false && _unreadCount > 0) _unreadCount--;
            });
            try {
              await _historyService.deleteNotification(notification['id']);
              if (mounted)
                ErrorHandlerService.showSuccessSnackbar(context, AppLocalizations.of(context)!.notification_deleted);
            } catch (e) {
              _loadData();
              if (mounted)
                ErrorHandlerService.showErrorSnackbar(
                  context,
                  '${AppLocalizations.of(context)?.failed_to_delete_notification ?? 'Failed to delete'}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
                );
            }
          },
          child: InkWell(
            onTap: () async {
              if (isUnread) {
                await _historyService.markAsRead(notification['id']);
                _loadData();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              decoration: BoxDecoration(
                color: isUnread ? DesignTokens.surfaceDark : DesignTokens.surfaceModalAlt,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(
                  color: isUnread ? DesignTokens.primaryColor.withValues(alpha: 0.3) : Colors.grey[900]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(_historyService.getColorForType(notification['type'])).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _historyService.getIconForType(notification['type']),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacing1),
                        Text(
                          notification['body'],
                          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DesignTokens.spacing1),
                        Text(
                          _formatTimestamp(notification['timestamp'], AppLocalizations.of(context)),
                          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: DesignTokens.primaryColor, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingTab() {
    return FutureBuilder<List<PendingNotificationRequest>>(
      future: _notificationService.getPendingNotifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
        final pending = snapshot.data!;
        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.calendar, size: 80, color: Colors.grey),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  AppLocalizations.of(context)!.no_scheduled_notifications,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(DesignTokens.spacing4),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final n = pending[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(color: Colors.grey[900]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Icon(Iconsax.clock, color: DesignTokens.primaryColor, size: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title ?? AppLocalizations.of(context)?.notifications ?? 'Notifications',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (n.body != null) ...[
                          const SizedBox(height: DesignTokens.spacing1),
                          Text(
                            n.body!,
                            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: DesignTokens.spacing1),
                        Text('ID: ${n.id}', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    tooltip: AppLocalizations.of(context)?.delete ?? 'Hapus',
                    onPressed: () async {
                      await _notificationService.cancelNotification(n.id);
                      if (mounted) setState(() {});
                      ErrorHandlerService.showSuccessSnackbar(
                        context,
                        AppLocalizations.of(context)!.notification_cancelled,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      children: [
        Text(
          l10n?.notification_type ?? 'Jenis Notifikasi',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: DesignTokens.spacing3),
        _buildSettingTile(
          icon: Iconsax.warning_2,
          title: l10n?.budget_warning ?? 'Peringatan Budget',
          subtitle: l10n?.notifications_budget_almost_empty ?? '',
          value: _budgetAlertsEnabled,
          onChanged: (v) {
            setState(() => _budgetAlertsEnabled = v);
            _saveSetting('budget_alerts', v);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.receipt,
          title: l10n?.bill_reminders ?? 'Pengingat Tagihan',
          subtitle: l10n?.notifications_bills_due ?? '',
          value: _billRemindersEnabled,
          onChanged: (v) {
            setState(() => _billRemindersEnabled = v);
            _saveSetting('bill_reminders', v);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.flag,
          title: l10n?.goal_notifications ?? 'Pencapaian Tujuan',
          subtitle: l10n?.notifications_progress_achievements ?? '',
          value: _goalNotificationsEnabled,
          onChanged: (v) {
            setState(() => _goalNotificationsEnabled = v);
            _saveSetting('goal_notifications', v);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.flash,
          title: l10n?.ai_insights ?? 'Insight AI',
          subtitle: l10n?.ai_insights_subtitle ?? 'Saran dan rekomendasi finansial',
          value: _aiInsightsEnabled,
          onChanged: (v) {
            setState(() => _aiInsightsEnabled = v);
            _saveSetting('ai_insights', v);
          },
        ),
        const SizedBox(height: DesignTokens.spacing6),
        Text(
          l10n?.periodic_summary ?? 'Ringkasan Berkala',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: DesignTokens.spacing3),
        _buildSettingTile(
          icon: Iconsax.calendar_1,
          title: l10n?.daily_summary ?? 'Ringkasan Harian',
          subtitle:
              _dailySummaryEnabled
                  ? '${l10n?.every_day_at ?? 'Setiap hari pukul'} $_dailySummaryHour:00'
                  : (l10n?.view_today_financial_activity ?? 'Lihat aktivitas keuangan Anda hari ini'),
          value: _dailySummaryEnabled,
          onChanged: (v) async {
            setState(() => _dailySummaryEnabled = v);
            _saveSetting('daily_summary', v);
            if (v)
              await _notificationService.scheduleDailyNotification(
                id: 999,
                title: l10n?.daily_summary ?? 'Ringkasan Harian',
                body: l10n?.view_today_financial_activity ?? 'Lihat aktivitas keuangan Anda hari ini',
                time: NotificationServiceTimeOfDay(hour: _dailySummaryHour, minute: 0),
              );
            else
              await _notificationService.cancelNotification(999);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.calendar,
          title: l10n?.weekly_summary ?? 'Ringkasan Mingguan',
          subtitle: l10n?.weekly_summary_subtitle ?? 'Ringkasan transaksi mingguan',
          value: _weeklySummaryEnabled,
          onChanged: (v) {
            setState(() => _weeklySummaryEnabled = v);
            _saveSetting('weekly_summary', v);
          },
        ),
        const SizedBox(height: DesignTokens.spacing6),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacing4),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(color: Colors.grey[900]!),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.info_circle, color: DesignTokens.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.notifications_help_stay_updated,
                  style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacing4),
        OutlinedButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (c) => AlertDialog(
                    backgroundColor: DesignTokens.surfaceDark,
                    title: Text(
                      AppLocalizations.of(context)!.delete_history_question,
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.delete_notification_history_message,
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(c, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(
                          AppLocalizations.of(context)!.delete,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirm == true) {
              await _historyService.clearHistory();
              _loadData();
              if (mounted)
                ErrorHandlerService.showSuccessSnackbar(
                  context,
                  AppLocalizations.of(context)!.notification_history_deleted,
                );
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            AppLocalizations.of(context)!.delete_all_history,
            style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: DesignTokens.primaryColor),
        ],
      ),
    );
  }
}
