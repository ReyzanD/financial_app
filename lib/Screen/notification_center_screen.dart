import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/notification_history_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  final NotificationHistoryService _historyService =
      NotificationHistoryService();

  List<Map<String, dynamic>> _history = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  // Settings
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
    setState(() => _isLoading = true);

    final history = await _historyService.getHistory();
    final unread = await _historyService.getUnreadCount();
    await _loadSettings();

    setState(() {
      _history = history;
      _unreadCount = unread;
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () async {
                await _historyService.markAllAsRead();
                _loadData();
              },
              child: Text(
                'Tandai Semua',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF8B5FBF),
                  fontSize: 13,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5FBF),
          labelColor: const Color(0xFF8B5FBF),
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Riwayat'),
            Tab(text: 'Terjadwal'),
            Tab(text: 'Pengaturan'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildPendingTab(),
                  _buildSettingsTab(),
                ],
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
            const SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifikasi akan muncul di sini',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Iconsax.trash, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            await _historyService.deleteNotification(notification['id']);
            _loadData();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Notifikasi dihapus')));
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isUnread
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isUnread
                          ? const Color(0xFF8B5FBF).withOpacity(0.3)
                          : Colors.grey[900]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(
                        _historyService.getColorForType(notification['type']),
                      ).withOpacity(0.2),
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
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['body'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5FBF),
                        shape: BoxShape.circle,
                      ),
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
          );
        }

        final pending = snapshot.data!;

        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.calendar, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada notifikasi terjadwal',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final notification = pending[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[900]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5FBF).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.clock,
                        color: Color(0xFF8B5FBF),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title ?? 'Notifikasi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (notification.body != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            notification.body!,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${notification.id}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: () async {
                      await _notificationService.cancelNotification(
                        notification.id,
                      );
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifikasi dibatalkan')),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Jenis Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Iconsax.warning_2,
          title: 'Peringatan Budget',
          subtitle: 'Notifikasi saat budget hampir/sudah habis',
          value: _budgetAlertsEnabled,
          onChanged: (value) {
            setState(() => _budgetAlertsEnabled = value);
            _saveSetting('budget_alerts', value);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.receipt,
          title: 'Pengingat Tagihan',
          subtitle: 'Notifikasi tagihan yang akan jatuh tempo',
          value: _billRemindersEnabled,
          onChanged: (value) {
            setState(() => _billRemindersEnabled = value);
            _saveSetting('bill_reminders', value);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.flag,
          title: 'Pencapaian Tujuan',
          subtitle: 'Notifikasi progress dan pencapaian tujuan',
          value: _goalNotificationsEnabled,
          onChanged: (value) {
            setState(() => _goalNotificationsEnabled = value);
            _saveSetting('goal_notifications', value);
          },
        ),
        _buildSettingTile(
          icon: Iconsax.flash,
          title: 'Insight AI',
          subtitle: 'Saran dan rekomendasi finansial',
          value: _aiInsightsEnabled,
          onChanged: (value) {
            setState(() => _aiInsightsEnabled = value);
            _saveSetting('ai_insights', value);
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Ringkasan Berkala',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Iconsax.calendar_1,
          title: 'Ringkasan Harian',
          subtitle:
              _dailySummaryEnabled
                  ? 'Setiap hari pukul ${_dailySummaryHour}:00'
                  : 'Ringkasan transaksi harian',
          value: _dailySummaryEnabled,
          onChanged: (value) async {
            setState(() => _dailySummaryEnabled = value);
            _saveSetting('daily_summary', value);

            if (value) {
              await _notificationService.scheduleDailyNotification(
                id: 999,
                title: '📊 Ringkasan Harian',
                body: 'Lihat aktivitas keuangan Anda hari ini',
                time: NotificationServiceTimeOfDay(
                  hour: _dailySummaryHour,
                  minute: 0,
                ),
              );
            } else {
              await _notificationService.cancelNotification(999);
            }
          },
        ),
        _buildSettingTile(
          icon: Iconsax.calendar,
          title: 'Ringkasan Mingguan',
          subtitle: 'Ringkasan transaksi mingguan',
          value: _weeklySummaryEnabled,
          onChanged: (value) {
            setState(() => _weeklySummaryEnabled = value);
            _saveSetting('weekly_summary', value);
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[900]!),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.info_circle, color: Color(0xFF8B5FBF)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notifikasi membantu Anda tetap update dengan keuangan',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: Text(
                      'Hapus Riwayat?',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    content: Text(
                      'Semua riwayat notifikasi akan dihapus',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
            );

            if (confirm == true) {
              await _historyService.clearHistory();
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Riwayat notifikasi dihapus')),
                );
              }
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Hapus Semua Riwayat',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5FBF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF8B5FBF),
          ),
        ],
      ),
    );
  }
}
