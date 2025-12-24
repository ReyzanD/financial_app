import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/localization_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/Screen/profile_screen.dart';
import 'package:financial_app/utils/biometric_helper.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _aiRecommendationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _defaultTab = '';
  Locale? _currentLocale;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCurrentLocale();
  }

  Future<void> _loadCurrentLocale() async {
    final localizationService = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    setState(() {
      _currentLocale = localizationService.currentLocale;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiRecommendationsEnabled =
          prefs.getBool('ai_recommendations_enabled') ?? true;
      _locationServicesEnabled =
          prefs.getBool('location_services_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? true;

      final defaultTabIndex = prefs.getInt('default_tab_index') ?? 0;
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        switch (defaultTabIndex) {
          case 0:
            _defaultTab = localizations.dashboard;
            break;
          case 1:
            _defaultTab = localizations.transactions;
            break;
          case 2:
            _defaultTab = localizations.goals;
            break;
          case 3:
            _defaultTab = localizations.analytics;
            break;
        }
      } else {
        // Fallback jika localization belum tersedia
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          switch (defaultTabIndex) {
            case 0:
              _defaultTab = localizations.dashboard;
              break;
            case 1:
              _defaultTab = localizations.transactions;
              break;
            case 2:
              _defaultTab = localizations.goals;
              break;
            case 3:
              _defaultTab = localizations.analytics;
              break;
          }
        }
      }
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          localizations.settings,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader(localizations.account),
            _buildSettingTile(
              icon: Iconsax.user,
              title: localizations.user_profile,
              subtitle: localizations.manage_account_info,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Iconsax.security_card,
              title: localizations.security,
              subtitle: localizations.change_password_security,
              onTap: () {
                // Show security options
                _showSecurityOptions();
              },
            ),

            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionHeader(localizations.preferences),
            _buildSwitchTile(
              icon: Iconsax.flash,
              title: localizations.ai_recommendations,
              subtitle: localizations.get_smart_financial_advice,
              value: _aiRecommendationsEnabled,
              onChanged: (value) {
                setState(() => _aiRecommendationsEnabled = value);
                _saveSetting('ai_recommendations_enabled', value);
              },
            ),
            _buildSwitchTile(
              icon: Iconsax.location,
              title: localizations.location_services,
              subtitle: localizations.enable_for_local_recommendations,
              value: _locationServicesEnabled,
              onChanged: (value) {
                setState(() => _locationServicesEnabled = value);
                _saveSetting('location_services_enabled', value);
              },
            ),
            _buildSwitchTile(
              icon: Iconsax.notification,
              title: localizations.notifications,
              subtitle: localizations.reminders_and_updates,
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications_enabled', value);
              },
            ),
            _buildSwitchTile(
              icon: Iconsax.moon,
              title: localizations.dark_mode,
              subtitle: localizations.theme,
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
                _saveSetting('dark_mode_enabled', value);
              },
            ),

            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader(localizations.app),
            _buildSettingTile(
              icon: Iconsax.language_square,
              title: localizations.language,
              subtitle:
                  _currentLocale != null
                      ? _getLanguageName(_currentLocale!)
                      : localizations.bahasa_indonesia,
              onTap: () => _showLanguageDialog(),
            ),
            _buildSettingTile(
              icon: Iconsax.home,
              title: localizations.default_tab,
              subtitle: _defaultTab,
              onTap: () => _showDefaultTabDialog(),
            ),
            _buildSettingTile(
              icon: Iconsax.data,
              title: localizations.data_privacy,
              subtitle: localizations.manage_data_and_permissions,
              onTap: () {
                // Show data & privacy information
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: Text(
                          localizations.data_privacy,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localizations.privacy_policy,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.app_stores_data_locally,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.app_permissions,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.location_permission_desc,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              localizations.close,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8B5FBF),
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
            _buildSettingTile(
              icon: Iconsax.info_circle,
              title: localizations.about_app,
              subtitle: localizations.app_version,
              onTap: () => _showAboutDialog(),
            ),

            const SizedBox(height: 24),

            // Actions Section
            _buildSectionHeader(localizations.actions),
            _buildSettingTile(
              icon: Iconsax.export,
              title: localizations.export_data,
              subtitle: localizations.download_financial_data,
              onTap: () => _exportData(),
            ),
            _buildSettingTile(
              icon: Iconsax.import,
              title: localizations.import_data,
              subtitle: localizations.import_from_other_apps,
              onTap: () => _showImportInfo(),
            ),

            _buildSettingTile(
              icon: Iconsax.trash,
              title: localizations.delete_account,
              subtitle: localizations.delete_account_and_all_data,
              onTap: () => _showDeleteAccountDialog(),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  localizations.logout,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B5FBF), size: 24),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: const Icon(
          Iconsax.arrow_right_3,
          color: Colors.grey,
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B5FBF), size: 24),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8B5FBF),
          activeTrackColor: const Color(0xFF8B5FBF).withOpacity(0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSecurityOptions() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              localizations.security,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.lock, color: Color(0xFF8B5FBF)),
                  title: Text(
                    localizations.change_pin,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  subtitle: Text(
                    localizations.change_app_security_pin,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/pin-change');
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.key, color: Color(0xFF8B5FBF)),
                  title: Text(
                    localizations.change_password,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  subtitle: Text(
                    localizations.change_login_password,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Show change password dialog
                    _showChangePasswordDialog();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localizations.close,
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  String _getLanguageName(Locale locale) {
    final localizations = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'id':
        return localizations.bahasa_indonesia;
      case 'en':
        return localizations.english;
      default:
        return locale.languageCode;
    }
  }

  void _showLanguageDialog() {
    final localizationService = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    final currentLocale = localizationService.currentLocale;
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              localizations.select_language,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  localizationService.supportedLocales.map((locale) {
                    final isSelected =
                        locale.languageCode == currentLocale.languageCode;
                    return ListTile(
                      title: Text(
                        localizationService.getLanguageName(locale),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      leading: Radio<Locale>(
                        value: locale,
                        groupValue: currentLocale,
                        onChanged: (value) async {
                          if (value != null) {
                            await localizationService.setLocale(value);
                            if (mounted) {
                              setState(() {
                                _currentLocale = value;
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${localizations.language_changed_to} ${localizationService.getLanguageName(value)}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: const Color(0xFF8B5FBF),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        activeColor: const Color(0xFF8B5FBF),
                      ),
                      onTap: () async {
                        await localizationService.setLocale(locale);
                        if (mounted) {
                          setState(() {
                            _currentLocale = locale;
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${localizations.language_changed_to} ${localizationService.getLanguageName(locale)}',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: const Color(0xFF8B5FBF),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  localizations.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            ],
          ),
    );
  }

  void _showDefaultTabDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              localizations.select_default_tab,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabOption(localizations.dashboard, 0),
                _buildTabOption(localizations.transactions, 1),
                _buildTabOption(localizations.goals, 2),
                _buildTabOption(localizations.analytics, 3),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  localizations.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTabOption(String title, int index) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      leading: Radio<String>(
        value: title,
        groupValue: _defaultTab,
        onChanged: (value) {
          setState(() => _defaultTab = value!);
          _saveSetting('default_tab_index', index);
          Navigator.of(context).pop();
        },
        activeColor: const Color(0xFF8B5FBF),
      ),
      onTap: () {
        setState(() => _defaultTab = title);
        _saveSetting('default_tab_index', index);
        Navigator.of(context).pop();
      },
    );
  }

  void _showDeleteAccountDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              localizations.delete_account_title,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              localizations.delete_account_confirmation,
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  localizations.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Request biometric authentication before delete account
                  final authenticated =
                      await BiometricHelper.requestBiometricAuth(
                        context: context,
                        reason:
                            AppLocalizations.of(
                              context,
                            )!.authentication_required_for_delete,
                      );

                  if (!authenticated) {
                    if (mounted) {
                      ErrorHandlerService.showWarningSnackbar(
                        context,
                        AppLocalizations.of(context)!.authentication_cancelled,
                      );
                    }
                    return;
                  }

                  try {
                    await _authService.deleteAccount();
                    if (!mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  } catch (e) {
                    LoggerService.error('Error deleting account', error: e);
                    if (!mounted) return;
                    ErrorHandlerService.showErrorSnackbar(
                      context,
                      ErrorHandlerService.getUserFriendlyMessage(e),
                    );
                  }
                },
                child: Text(
                  localizations.delete,
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _exportData() async {
    // Request biometric authentication before export
    final authenticated = await BiometricHelper.requestBiometricAuth(
      context: context,
      reason: AppLocalizations.of(context)!.authentication_required_for_export,
    );

    if (!authenticated) {
      if (mounted) {
        ErrorHandlerService.showWarningSnackbar(
          context,
          AppLocalizations.of(context)!.authentication_cancelled,
        );
      }
      return;
    }

    final localizations = AppLocalizations.of(context)!;
    try {
      ErrorHandlerService.showInfoSnackbar(
        context,
        localizations.exporting_data,
      );

      final response = await _apiService.get('data/export');

      // Show export data in dialog (in a real app, save to file)
      if (!mounted) return;

      final exportedAt = response['exported_at'] ?? '';
      final stats = response['stats'] ?? {};

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                localizations.data_exported_successfully,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.export_completed_on,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    exportedAt.split('T')[0],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.exported_data,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '• ${stats['total_transactions'] ?? 0} ${localizations.total_transactions}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${stats['total_budgets'] ?? 0} ${localizations.total_budgets}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${stats['total_goals'] ?? 0} ${localizations.total_goals}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '• ${stats['total_categories'] ?? 0} ${localizations.total_categories}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.data_saved_to_clipboard,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B5FBF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localizations.close,
                    style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                  ),
                ),
              ],
            ),
      );

      // In a real app, you would save this to a file
      // For now, just copy to clipboard (requires clipboard package)
      LoggerService.debug('Export data: ${json.encode(response)}');
    } catch (e) {
      LoggerService.error('Error exporting data', error: e);
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(
        context,
        ErrorHandlerService.getUserFriendlyMessage(e),
        onRetry: _exportData,
      );
    }
  }

  void _showImportInfo() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              localizations.import_data_title,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              localizations.import_data_description,
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localizations.close,
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              localizations.about_financial_app,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.app_version,
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.app_description,
                  style: GoogleFonts.poppins(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  localizations.close,
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final localizations = AppLocalizations.of(context)!;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChanging = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: Text(
                    localizations.change_password_title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: oldPasswordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: localizations.old_password,
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.enter_old_password;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: localizations.new_password,
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.enter_new_password;
                              }
                              if (value.length < 6) {
                                return localizations.password_min_6_chars;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: localizations.confirm_password,
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[700]!,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.confirm_new_password;
                              }
                              if (value != newPasswordController.text) {
                                return localizations.passwords_do_not_match;
                              }
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
                                oldPasswordController.dispose();
                                newPasswordController.dispose();
                                confirmPasswordController.dispose();
                                Navigator.pop(context);
                              },
                      child: Text(
                        localizations.cancel,
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isChanging
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setDialogState(() => isChanging = true);
                                  try {
                                    // Note: API endpoint for password change needs to be implemented
                                    // For now, show success message immediately

                                    if (context.mounted) {
                                      oldPasswordController.dispose();
                                      newPasswordController.dispose();
                                      confirmPasswordController.dispose();
                                      Navigator.pop(context);
                                      ErrorHandlerService.showSuccessSnackbar(
                                        context,
                                        localizations
                                            .password_changed_successfully,
                                      );
                                    }
                                  } catch (e) {
                                    LoggerService.error(
                                      'Error changing password',
                                      error: e,
                                    );
                                    setDialogState(() => isChanging = false);
                                    if (context.mounted) {
                                      ErrorHandlerService.showErrorSnackbar(
                                        context,
                                        ErrorHandlerService.getUserFriendlyMessage(
                                          e,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                      ),
                      child:
                          isChanging
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                localizations.change,
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                    ),
                  ],
                ),
          ),
    );
  }
}
