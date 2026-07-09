import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/models/feature_models.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final LocalDataService _localData = LocalDataService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _showActiveOnly = true;

  List<ChallengeModel> _challenges = [];
  Map<String, dynamic> _stats = {};

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

      final results = await _localData.getChallenges(
        activeOnly: _showActiveOnly,
      );

      if (!mounted) return;

      setState(() {
        _challenges = results.map((e) => ChallengeModel.fromMap(e)).toList();
        _stats = {
          'active_challenges': _challenges.where((c) => c.isActive).length,
          'total_streak': _challenges.fold<int>(0, (sum, c) => sum + c.streak),
          'completed': _challenges.where((c) => c.isCompleted).length,
        };
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

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: _loadData,
                child: _buildBody(context, l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'challenges_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _showAddChallengeModal,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final activeChallenges =
        (_stats['active_challenges'] as num?)?.toInt() ?? 0;
    final totalStreak = (_stats['total_streak'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'Challenges',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _showActiveOnly
                    ? l10n?.active ?? 'Aktif'
                    : l10n?.all ?? 'Semua',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _showActiveOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: DesignTokens.textTertiaryDark,
                inactiveTrackColor: DesignTokens.borderDark,
                onChanged: (value) {
                  setState(() {
                    _showActiveOnly = value;
                  });
                  _loadData();
                },
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

  Widget _buildBody(BuildContext context, AppLocalizations? l10n) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context, l10n);
    }

    if (_challenges.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _challenges.length,
      itemBuilder: (context, index) {
        final challenge = _challenges[index];
        return _buildChallengeCard(context, challenge, l10n);
      },
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    dynamic challenge,
    AppLocalizations? l10n,
  ) {
    final name = challenge.name ?? '';
    final type = challenge.type ?? 'no_spend';
    final target = challenge.target ?? 0.0;
    final currentProgress = challenge.currentProgress ?? 0.0;
    final streak = challenge.streak ?? 0;
    final daysRemaining = challenge.daysRemaining ?? 0;

    final progress =
        target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                  color: _getChallengeTypeColor(type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: Icon(
                  Iconsax.medal,
                  color: _getChallengeTypeColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getChallengeTypeLabel(type),
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
                      '$streak',
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
                '${CurrencyFormatter.formatRupiah(currentProgress.toInt())} / ${CurrencyFormatter.formatRupiah(target.toInt())}',
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
              valueColor: AlwaysStoppedAnimation(_getChallengeTypeColor(type)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$daysRemaining ${l10n?.days_left ?? 'hari lagi'}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textTertiaryDark,
                  fontSize: 11,
                ),
              ),
              InkWell(
                onTap: () => _deleteChallenge(challenge),
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
            'Belum Ada Challenges',
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

  void _showAddChallengeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddChallengeModal(onChallengeAdded: _loadData);
      },
    );
  }

  Future<void> _deleteChallenge(dynamic challenge) async {
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
            l10n?.confirm_delete_budget ??
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
        await LocalDataService().deleteChallenge(challenge.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.transaction_deleted_successfully ??
                  'Challenge berhasil dihapus',
            ),
            backgroundColor: DesignTokens.primaryColor,
          ),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
      }
    }
  }
}

class _AddChallengeModal extends StatefulWidget {
  final VoidCallback onChallengeAdded;

  const _AddChallengeModal({required this.onChallengeAdded});

  @override
  State<_AddChallengeModal> createState() => _AddChallengeModalState();
}

class _AddChallengeModalState extends State<_AddChallengeModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedType = 'no_spend';

  final List<Map<String, dynamic>> _types = [
    {'value': 'no_spend', 'label': 'No Spend'},
    {'value': 'savings_target', 'label': 'Savings Target'},
    {'value': 'budget_limit', 'label': 'Budget Limit'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textTertiaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tambah Challenge',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.name ?? 'Nama',
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Tipe Challenge',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _types.map((type) {
                      final isSelected = _selectedType == type['value'];
                      return ChoiceChip(
                        label: Text(
                          type['label'],
                          style: GoogleFonts.poppins(
                            color:
                                isSelected
                                    ? Colors.white
                                    : DesignTokens.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = type['value'];
                          });
                        },
                        backgroundColor: DesignTokens.surfaceDark,
                        selectedColor: DesignTokens.primaryColor,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Target tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n?.add ?? 'Tambah',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await LocalDataService().addChallenge({
        'name': _nameController.text,
        'type': _selectedType,
        'target_amount': double.tryParse(_targetController.text) ?? 0.0,
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'end_date':
            DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String()
                .split('T')[0],
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onChallengeAdded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
    }
  }
}
