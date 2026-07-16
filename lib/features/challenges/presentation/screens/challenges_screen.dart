import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/challenges/presentation/controllers/challenge_controller.dart';
import 'package:financial_app/features/challenges/presentation/widgets/add_challenge_modal.dart';
import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ChallengeController>().loadData();
    });
  }

  Color _getChallengeTypeColor(String type) {
    switch (type) {
      case 'no_spend':
        return DesignTokens.errorColor;
      case 'savings_target':
        return DesignTokens.successColor;
      case 'budget_limit':
        return DesignTokens.warningColor;
      default:
        return DesignTokens.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<ChallengeController>();

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n, controller),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: controller.refresh,
                child: _buildBody(context, l10n, controller),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'challenges_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () => _showAddChallengeModal(context),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    ChallengeController controller,
  ) {
    final activeChallenges =
        (controller.stats['active_challenges'] as num?)?.toInt() ?? 0;
    final totalStreak =
        (controller.stats['total_streak'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Semantics(
                header: true,
                child: Text(
                  'Challenges',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                controller.activeOnly
                    ? l10n?.active ?? 'Aktif'
                    : l10n?.all ?? 'Semua',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: controller.activeOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: DesignTokens.textTertiaryDark,
                inactiveTrackColor: DesignTokens.borderDark,
                onChanged: (_) => controller.toggleActiveOnly(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(color: DesignTokens.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '$activeChallenges',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textPrimaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(color: DesignTokens.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Streak',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '$totalStreak days',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.successColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations? l10n,
    ChallengeController controller,
  ) {
    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (controller.errorMessage != null) {
      return _buildErrorState(context, l10n, controller);
    }

    if (controller.challenges.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: controller.challenges.length,
      itemBuilder: (context, index) {
        final challenge = controller.challenges[index];
        return _buildChallengeCard(challenge, l10n);
      },
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, AppLocalizations? l10n) {
    final progress =
        challenge.target > 0
            ? (challenge.currentProgress / challenge.target).clamp(0.0, 1.0)
            : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getChallengeTypeColor(
                    challenge.type,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: Icon(
                  Iconsax.medal,
                  color: _getChallengeTypeColor(challenge.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getChallengeTypeLabel(challenge.type),
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.flash,
                      color: DesignTokens.successColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.streak}',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.formatRupiah(challenge.currentProgress.toInt())} / ${CurrencyFormatter.formatRupiah(challenge.target.toInt())}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  color: DesignTokens.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DesignTokens.borderDark,
              valueColor: AlwaysStoppedAnimation(
                _getChallengeTypeColor(challenge.type),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.daysRemaining} ${l10n?.days_left ?? 'hari lagi'}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textTertiaryDark,
                  fontSize: 11,
                ),
              ),
              InkWell(
                onTap: () => _deleteChallenge(context, challenge),
                child: Icon(
                  Iconsax.trash,
                  size: 16,
                  color: DesignTokens.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getChallengeTypeLabel(String type) {
    switch (type) {
      case 'no_spend':
        return 'No Spend';
      case 'savings_target':
        return 'Savings Target';
      case 'budget_limit':
        return 'Budget Limit';
      default:
        return type;
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.medal, size: 64, color: DesignTokens.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            l10n?.no_challenges ?? 'Belum Ada Challenges',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambah challenge baru',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
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
    ChallengeController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n?.error ?? 'Terjadi kesalahan',
              style: GoogleFonts.poppins(
                color: DesignTokens.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              controller.errorMessage ?? '',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.refresh,
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

  void _showAddChallengeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddChallengeModal(
          onChallengeAdded: () => context.read<ChallengeController>().refresh(),
        );
      },
    );
  }

  Future<void> _deleteChallenge(
    BuildContext context,
    ChallengeModel challenge,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            l10n?.delete ?? 'Hapus',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n?.delete_challenge_confirm ??
                'Yakin ingin menghapus challenge ini?',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n?.cancel ?? 'Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n?.delete ?? 'Hapus',
                style: const TextStyle(color: DesignTokens.errorColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await context.read<ChallengeController>().deleteChallenge(challenge.id);
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.challenge_deleted_successfully ?? 'Challenge berhasil dihapus',
        );
      } catch (e) {
        if (!mounted) return;
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    }
  }
}
