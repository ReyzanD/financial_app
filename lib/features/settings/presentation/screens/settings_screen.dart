import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:financial_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:financial_app/services/localization_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/export_service.dart';
import 'package:financial_app/utils/biometric_helper.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/core/di/service_locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsController>().load();
      _loadCurrentLocale();
    });
  }

  void _loadCurrentLocale() async {
    final loc = Provider.of<LocalizationService>(context, listen: false).currentLocale;
    if (mounted) setState(() => _currentLocale = loc);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        title: Text(
          l10n.settings,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        child: Consumer<SettingsController>(
          builder:
              (_, ctrl, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OfflineIndicator(),
                  _section(l10n.account),
                  _tile(
                    icon: Iconsax.user,
                    title: l10n.user_profile,
                    subtitle: l10n.manage_account_info,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  ),
                  _tile(
                    icon: Iconsax.security_card,
                    title: l10n.security,
                    subtitle: l10n.change_password_security,
                    onTap: () => _showSecurityOptions(),
                  ),
                  const SizedBox(height: DesignTokens.spacing6),
                  _section(l10n.preferences),
                  _switchTile(
                    icon: Iconsax.flash,
                    title: l10n.ai_recommendations,
                    subtitle: l10n.get_smart_financial_advice,
                    value: ctrl.aiRecommendationsEnabled,
                    onChanged: ctrl.toggleAi,
                  ),
                  _switchTile(
                    icon: Iconsax.location,
                    title: l10n.location_services,
                    subtitle: l10n.enable_for_local_recommendations,
                    value: ctrl.locationServicesEnabled,
                    onChanged: ctrl.toggleLocation,
                  ),
                  _switchTile(
                    icon: Iconsax.notification,
                    title: l10n.notifications,
                    subtitle: l10n.reminders_and_updates,
                    value: ctrl.notificationsEnabled,
                    onChanged: ctrl.toggleNotifications,
                  ),
                  _switchTile(
                    icon: Iconsax.moon,
                    title: l10n.dark_mode,
                    subtitle: l10n.theme,
                    value: ctrl.darkModeEnabled,
                    onChanged: ctrl.toggleDarkMode,
                  ),
                  const SizedBox(height: DesignTokens.spacing6),
                  _section(l10n.app),
                  _tile(
                    icon: Iconsax.language_square,
                    title: l10n.language,
                    subtitle: _currentLocale != null ? _getLanguageName(_currentLocale!) : l10n.bahasa_indonesia,
                    onTap: () => _showLanguageDialog(),
                  ),
                  _tile(
                    icon: Iconsax.home,
                    title: l10n.default_tab,
                    subtitle: _tabLabel(context, ctrl.defaultTabIndex),
                    onTap: () => _showDefaultTabDialog(ctrl),
                  ),
                  _tile(
                    icon: Iconsax.data,
                    title: l10n.data_privacy,
                    subtitle: l10n.manage_data_and_permissions,
                    onTap: () => _showDataPrivacy(),
                  ),
                  _tile(
                    icon: Iconsax.info_circle,
                    title: l10n.about_app,
                    subtitle: l10n.app_version,
                    onTap: () => _showAboutDialog(),
                  ),
                  const SizedBox(height: DesignTokens.spacing6),
                  _section(l10n.actions),
                  _tile(
                    icon: Iconsax.export,
                    title: l10n.export_data,
                    subtitle: l10n.download_financial_data,
                    onTap: () => _exportData(ctrl),
                  ),
                  _tile(
                    icon: Iconsax.import,
                    title: l10n.import_data,
                    subtitle: l10n.import_from_other_apps,
                    onTap: () => _pickAndImportCSV(),
                  ),
                  _tile(
                    icon: Iconsax.trash,
                    title: l10n.delete_account,
                    subtitle: l10n.delete_account_and_all_data,
                    onTap: () => _showDeleteAccountDialog(ctrl),
                  ),
                  const SizedBox(height: DesignTokens.spacing7),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ctrl.logout();
                        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
                      ),
                      child: Text(
                        l10n.logout,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                ],
              ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(t, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  );
  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceDark,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(color: DesignTokens.borderDark),
    ),
    child: ListTile(
      leading: Icon(icon, color: DesignTokens.primaryColor, size: 24),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
      trailing: const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
    ),
  );
  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceDark,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(color: DesignTokens.borderDark),
    ),
    child: ListTile(
      leading: Icon(icon, color: DesignTokens.primaryColor, size: 24),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: DesignTokens.primaryColor,
        activeTrackColor: DesignTokens.primaryColor.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
    ),
  );

  void _showSecurityOptions() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.security, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.lock, color: DesignTokens.primaryColor),
                  title: Text(l10n.change_pin, style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text(
                    l10n.change_app_security_pin,
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    Navigator.pushNamed(context, '/pin-change');
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.key, color: DesignTokens.primaryColor),
                  title: Text(l10n.change_password, style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text(
                    l10n.change_login_password,
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    _showChangePasswordDialog();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.close, style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
              ),
            ],
          ),
    );
  }

  String _getLanguageName(Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'id':
        return l10n.bahasa_indonesia;
      case 'en':
        return l10n.english;
      default:
        return locale.languageCode;
    }
  }

  String _tabLabel(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.dashboard;
      case 1:
        return l10n.transactions;
      case 2:
        return l10n.goals;
      case 3:
        return l10n.analytics;
      default:
        return l10n.dashboard;
    }
  }

  void _showLanguageDialog() {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final currentLocale = localizationService.currentLocale;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(l10n.select_language, style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  localizationService.supportedLocales.map((locale) {
                    final sel = locale.languageCode == currentLocale.languageCode;
                    return ListTile(
                      title: Text(
                        localizationService.getLanguageName(locale),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Radio<Locale>(value: locale, activeColor: DesignTokens.primaryColor),
                      onTap: () async {
                        await localizationService.setLocale(locale);
                        if (c.mounted) {
                          setState(() => _currentLocale = locale);
                          Navigator.pop(c);
                          ErrorHandlerService.showSuccessSnackbar(
                            c,
                            '${l10n.language_changed_to} ${localizationService.getLanguageName(locale)}',
                          );
                        }
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
              ),
            ],
          ),
    );
  }

  void _showDefaultTabDialog(SettingsController ctrl) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(l10n.select_default_tab, style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l10n.dashboard, style: GoogleFonts.poppins(color: Colors.white)),
                  leading: Radio<int>(value: 0, activeColor: DesignTokens.primaryColor),
                  onTap: () {
                    ctrl.setDefaultTab(0);
                    Navigator.pop(c);
                  },
                ),
                ListTile(
                  title: Text(l10n.transactions, style: GoogleFonts.poppins(color: Colors.white)),
                  leading: Radio<int>(value: 1, activeColor: DesignTokens.primaryColor),
                  onTap: () {
                    ctrl.setDefaultTab(1);
                    Navigator.pop(c);
                  },
                ),
                ListTile(
                  title: Text(l10n.goals, style: GoogleFonts.poppins(color: Colors.white)),
                  leading: Radio<int>(value: 2, activeColor: DesignTokens.primaryColor),
                  onTap: () {
                    ctrl.setDefaultTab(2);
                    Navigator.pop(c);
                  },
                ),
                ListTile(
                  title: Text(l10n.analytics, style: GoogleFonts.poppins(color: Colors.white)),
                  leading: Radio<int>(value: 3, activeColor: DesignTokens.primaryColor),
                  onTap: () {
                    ctrl.setDefaultTab(3);
                    Navigator.pop(c);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
              ),
            ],
          ),
    );
  }

  void _showDataPrivacy() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(
              l10n.data_privacy,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.privacy_policy,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: DesignTokens.spacing2),
                  Text(l10n.app_stores_data_locally, style: GoogleFonts.poppins(color: Colors.grey[400])),
                  const SizedBox(height: DesignTokens.spacing4),
                  Text(
                    l10n.app_permissions,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: DesignTokens.spacing2),
                  Text(l10n.location_permission_desc, style: GoogleFonts.poppins(color: Colors.grey[400])),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.close, style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(l10n.about_financial_app, style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.app_version, style: GoogleFonts.poppins(color: Colors.grey[400])),
                const SizedBox(height: DesignTokens.spacing4),
                Text(
                  l10n.app_description,
                  style: GoogleFonts.poppins(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.close, style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
              ),
            ],
          ),
    );
  }

  Future<void> _exportData(SettingsController ctrl) async {
    final ctx = context;
    final authenticated = await BiometricHelper.requestBiometricAuth(
      context: ctx,
      reason: AppLocalizations.of(ctx)!.authentication_required_for_export,
    );
    if (!authenticated) {
      if (ctx.mounted) ErrorHandlerService.showWarningSnackbar(ctx, AppLocalizations.of(ctx)!.authentication_cancelled);
      return;
    }
    final l10n = AppLocalizations.of(ctx)!;
    try {
      ErrorHandlerService.showInfoSnackbar(ctx, l10n.exporting_data);
      final data = await ctrl.exportData();
      if (!ctx.mounted) return;
      final stats = data['stats'] as Map<String, dynamic>;
      showDialog(
        context: ctx,
        builder:
            (c) => AlertDialog(
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(l10n.data_exported_successfully, style: GoogleFonts.poppins(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.export_completed_on, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                  Text(
                    (data['exported_at'] as String).split('T')[0],
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Text(l10n.exported_data, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                  Text(
                    '• ${stats['total_transactions'] ?? 0} ${l10n.total_transactions}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• ${stats['budgets'] ?? 0} ${l10n.total_budgets}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• ${stats['goals'] ?? 0} ${l10n.total_goals}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Text(
                    l10n.data_saved_to_clipboard,
                    style: GoogleFonts.poppins(color: DesignTokens.primaryColor, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(l10n.close, style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
                ),
              ],
            ),
      );
      LoggerService.debug('Export data: ${json.encode(data)}');
    } catch (e) {
      LoggerService.error('Error exporting', error: e);
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: () => _exportData(ctrl),
        );
    }
  }

  Future<void> _pickAndImportCSV() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor)),
      );
      final importResult = await getIt<ExportService>().importTransactionsFromCSV(filePath);
      if (!mounted) return;
      Navigator.pop(context);
      final imported = importResult['imported'] as int;
      final failed = importResult['failed'] as int;
      final errors = (importResult['errors'] as List?) ?? [];
      showDialog(
        context: context,
        builder:
            (c) => AlertDialog(
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(
                importResult['success'] == true
                    ? (l10n?.import_successful ?? 'Import Berhasil')
                    : (l10n?.import_completed ?? 'Import Selesai'),
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n?.import_success_count ?? 'Berhasil'}: $imported ${l10n?.transactions ?? 'transaksi'}',
                    style: GoogleFonts.poppins(color: Colors.green[400], fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (failed > 0) ...[
                    const SizedBox(height: DesignTokens.spacing2),
                    Text(
                      '${l10n?.import_failed_count ?? 'Gagal'}: $failed ${l10n?.transactions ?? 'transaksi'}',
                      style: GoogleFonts.poppins(color: Colors.red[400], fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (errors.isNotEmpty && errors.length <= 5) ...[
                    const SizedBox(height: DesignTokens.spacing3),
                    ...errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(e, style: GoogleFonts.poppins(color: Colors.red[300], fontSize: 12)),
                      ),
                    ),
                  ],
                  if (errors.length > 5) ...[
                    const SizedBox(height: DesignTokens.spacing2),
                    Text(
                      '...dan ${errors.length - 5} error lainnya',
                      style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(l10n?.close ?? 'Tutup', style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
                ),
              ],
            ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ErrorHandlerService.showErrorSnackbar(
        context,
        '${l10n?.failed_to_import_file ?? 'Gagal mengimpor file'}: ${e.toString()}',
      );
    }
  }

  void _showDeleteAccountDialog(SettingsController ctrl) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(l10n.delete_account_title, style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(l10n.delete_account_confirmation, style: GoogleFonts.poppins(color: Colors.grey[400])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(c);
                  final authOk = await BiometricHelper.requestBiometricAuth(
                    context: context,
                    reason: AppLocalizations.of(context)!.authentication_required_for_delete,
                  );
                  if (!authOk) {
                    if (mounted)
                      ErrorHandlerService.showWarningSnackbar(
                        context,
                        AppLocalizations.of(context)!.authentication_cancelled,
                      );
                    return;
                  }
                  try {
                    await ctrl.deleteAccount();
                    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  } catch (e) {
                    LoggerService.error('Error deleting account', error: e);
                    if (mounted)
                      ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
                  }
                },
                child: Text(l10n.delete, style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChanging = false;
    showDialog(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (_, setD) => AlertDialog(
                  backgroundColor: DesignTokens.surfaceDark,
                  title: Text(
                    l10n.change_password_title,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: oldCtrl,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.old_password,
                              labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              filled: true,
                              fillColor: DesignTokens.surfaceDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: DesignTokens.primaryColor),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? l10n.enter_old_password : null,
                          ),
                          const SizedBox(height: DesignTokens.spacing4),
                          TextFormField(
                            controller: newCtrl,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.new_password,
                              labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              filled: true,
                              fillColor: DesignTokens.surfaceDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: DesignTokens.primaryColor),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.enter_new_password;
                              if (v.length < 6) return l10n.password_min_6_chars;
                              return null;
                            },
                          ),
                          const SizedBox(height: DesignTokens.spacing4),
                          TextFormField(
                            controller: confirmCtrl,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.confirm_password,
                              labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              filled: true,
                              fillColor: DesignTokens.surfaceDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: DesignTokens.primaryColor),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.confirm_new_password;
                              if (v != newCtrl.text) return l10n.passwords_do_not_match;
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isChanging
                              ? null
                              : () {
                                Navigator.pop(c);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  oldCtrl.dispose();
                                  newCtrl.dispose();
                                  confirmCtrl.dispose();
                                });
                              },
                      child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed:
                          isChanging
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setD(() => isChanging = true);
                                  try {
                                    if (c.mounted) {
                                      Navigator.pop(c);
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        oldCtrl.dispose();
                                        newCtrl.dispose();
                                        confirmCtrl.dispose();
                                      });
                                      ErrorHandlerService.showSuccessSnackbar(
                                        context,
                                        l10n.password_changed_successfully,
                                      );
                                    }
                                  } catch (e) {
                                    LoggerService.error('Error changing password', error: e);
                                    setD(() => isChanging = false);
                                    if (c.mounted)
                                      ErrorHandlerService.showErrorSnackbar(
                                        c,
                                        ErrorHandlerService.getUserFriendlyMessage(e),
                                      );
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
                      child:
                          isChanging
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                              : Text(l10n.change, style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
          ),
    );
  }
}
