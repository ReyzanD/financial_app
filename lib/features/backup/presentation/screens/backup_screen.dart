import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/backup/presentation/controllers/backup_controller.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupController>().loadBackups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Backup & Restore',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Consumer<BackupController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading)
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.primaryColor,
                    ),
                  );
                return ListView(
                  padding: const EdgeInsets.all(DesignTokens.spacing4),
                  children: [
                    _buildActionCard(context, l10n),
                    const SizedBox(height: 24),
                    _buildBackupList(context, l10n, ctrl),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, AppLocalizations l10n) {
    return Consumer<BackupController>(
      builder:
          (context, ctrl, _) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DesignTokens.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              border: Border.all(
                color: DesignTokens.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Iconsax.cloud,
                  size: 48,
                  color: DesignTokens.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Backup Data',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.backup_description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Iconsax.document_upload,
                        label: 'Backup',
                        isLoading: ctrl.isCreating,
                        onTap: () async {
                          try {
                            await ctrl.createBackup();
                            if (context.mounted)
                              ErrorHandlerService.showSuccessSnackbar(
                                context,
                                l10n.backup_created_successfully,
                              );
                          } catch (e) {
                            if (context.mounted)
                              ErrorHandlerService.showErrorSnackbar(
                                context,
                                ErrorHandlerService.getUserFriendlyMessage(e),
                              );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Iconsax.export,
                        label: 'Share',
                        isLoading: ctrl.isCreating,
                        onTap: () async {
                          try {
                            await ctrl.createBackup(share: true);
                            if (context.mounted)
                              ErrorHandlerService.showSuccessSnackbar(
                                context,
                                '✅ ${l10n.backup_created_and_ready}',
                              );
                          } catch (e) {
                            if (context.mounted)
                              ErrorHandlerService.showErrorSnackbar(
                                context,
                                ErrorHandlerService.getUserFriendlyMessage(e),
                              );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: DesignTokens.primaryColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child:
            isLoading
                ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
                : Column(
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildBackupList(
    BuildContext context,
    AppLocalizations l10n,
    BackupController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.backup_history,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (ctrl.backups.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            ),
            child: Center(
              child: Text(
                l10n.no_backups,
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...ctrl.backups.reversed.take(10).map((file) {
            final stat = file.statSync();
            final size = stat.size;
            final modified = stat.modified;
            final name = file.path.split('/').last;
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
                  const Icon(
                    Iconsax.document,
                    color: DesignTokens.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatSize(size)} - ${DateFormat('dd/MM/yy HH:mm').format(modified)}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.trash,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              backgroundColor: DesignTokens.surfaceDark,
                              title: Text(
                                l10n.delete_backup_title,
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              content: Text(
                                l10n.delete_backup_warning,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    l10n.cancel,
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text(
                                    l10n.delete,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        try {
                          await ctrl.deleteBackup(file.path);
                          if (context.mounted)
                            ErrorHandlerService.showSuccessSnackbar(
                              context,
                              l10n.backup_deleted_message,
                            );
                        } catch (e) {
                          if (context.mounted)
                            ErrorHandlerService.showErrorSnackbar(
                              context,
                              ErrorHandlerService.getUserFriendlyMessage(e),
                            );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
