import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/subscription_tracker_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionTrackerService _subscriptionService =
      getIt<SubscriptionTrackerService>();

  bool _isLoading = true;
  String? _errorMessage;
  bool _activeOnly = true;

  List<dynamic> _subscriptions = [];
  Map<String, dynamic> _summary = {};

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
        _subscriptionService.getSubscriptions(activeOnly: _activeOnly),
        _subscriptionService.getSubscriptionSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        _subscriptions = results[0] as List<dynamic>;
        _summary = results[1] as Map<String, dynamic>;
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

  int _getDaysRemaining(DateTime? nextRenewal) {
    if (nextRenewal == null) return 0;
    return nextRenewal.difference(DateTime.now()).inDays;
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
        heroTag: 'subscriptions_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _showAddSubscriptionModal,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final monthlyTotal = (_summary['monthly_total'] as num?)?.toDouble() ?? 0.0;
    final yearlyTotal = (_summary['yearly_total'] as num?)?.toDouble() ?? 0.0;

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
                l10n?.subscription ?? 'Langganan',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _activeOnly ? l10n?.active ?? 'Aktif' : l10n?.all ?? 'Semua',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _activeOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: DesignTokens.textTertiaryDark,
                inactiveTrackColor: DesignTokens.borderDark,
                onChanged: (value) {
                  setState(() {
                    _activeOnly = value;
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
                        l10n?.monthly_total ?? 'Bulanan',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatRupiah(monthlyTotal.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textPrimaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                        l10n?.yearly ?? 'Tahunan',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatRupiah(yearlyTotal.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textPrimaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

    if (_subscriptions.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = _subscriptions[index];
        return _buildSubscriptionCard(context, subscription, l10n);
      },
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    dynamic subscription,
    AppLocalizations? l10n,
  ) {
    final name = subscription.name ?? '';
    final cost = subscription.cost ?? 0.0;
    final cycle = subscription.cycle ?? 'monthly';
    final nextRenewal = subscription.nextRenewal;
    final category = subscription.category ?? '';
    final daysRemaining = _getDaysRemaining(nextRenewal);

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
                  color: DesignTokens.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: const Icon(
                  Iconsax.repeat,
                  color: DesignTokens.primaryColor,
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
                      '$category • ${_getCycleLabel(cycle, l10n)}',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(cost.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '/${_getCycleShortLabel(cycle)}',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textTertiaryDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.calendar,
                    size: 14,
                    color: DesignTokens.textSecondaryDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n?.due_date ?? 'Jatuh tempo'}: ${nextRenewal != null ? "${nextRenewal.day}/${nextRenewal.month}" : "-"}',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      daysRemaining <= 3
                          ? DesignTokens.errorColor.withValues(alpha: 0.15)
                          : DesignTokens.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Text(
                  daysRemaining > 0
                      ? '$daysRemaining ${l10n?.days_left ?? 'hari lagi'}'
                      : l10n?.due_soon ?? 'Segera',
                  style: GoogleFonts.poppins(
                    color:
                        daysRemaining <= 3
                            ? DesignTokens.errorColor
                            : DesignTokens.successColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _cancelSubscription(subscription),
                child: Text(
                  l10n?.cancel ?? 'Batal',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCycleLabel(String cycle, AppLocalizations? l10n) {
    switch (cycle) {
      case 'weekly':
        return l10n?.subscription_cycle_weekly ?? 'Mingguan';
      case 'monthly':
        return l10n?.subscription_cycle_monthly ?? 'Bulanan';
      case 'yearly':
        return l10n?.subscription_cycle_yearly ?? 'Tahunan';
      default:
        return cycle;
    }
  }

  String _getCycleShortLabel(String cycle) {
    switch (cycle) {
      case 'weekly':
        return 'w';
      case 'monthly':
        return 'mo';
      case 'yearly':
        return 'yr';
      default:
        return cycle;
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.repeat, size: 64, color: DesignTokens.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            l10n?.no_subscriptions ?? 'Tidak ada langganan aktif',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.no_obligations_subtitle ??
                'Tap + untuk menambah langganan baru',
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

  void _showAddSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddSubscriptionModal(onSubscriptionAdded: _loadData);
      },
    );
  }

  Future<void> _cancelSubscription(dynamic subscription) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            l10n?.cancel ?? 'Batal',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n?.confirm_delete_budget ??
                'Yakin ingin membatalkan langganan ini?',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Ya',
                style: const TextStyle(color: DesignTokens.errorColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _subscriptionService.cancelSubscription(subscription.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Langganan dibatalkan'),
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

class _AddSubscriptionModal extends StatefulWidget {
  final VoidCallback onSubscriptionAdded;

  const _AddSubscriptionModal({required this.onSubscriptionAdded});

  @override
  State<_AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends State<_AddSubscriptionModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedCycle = 'monthly';
  final DateTime _nextRenewal = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
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
                l10n?.add ?? 'Tambah Langganan',
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
              TextFormField(
                controller: _costController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.amount ?? 'Biaya',
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
                    return 'Biaya tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.subscription_cycle ?? 'Siklus',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    ['weekly', 'monthly', 'yearly'].map((cycle) {
                      final isSelected = _selectedCycle == cycle;
                      return ChoiceChip(
                        label: Text(
                          _getCycleLabel(cycle, l10n),
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
                            _selectedCycle = cycle;
                          });
                        },
                        backgroundColor: DesignTokens.surfaceDark,
                        selectedColor: DesignTokens.primaryColor,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSubscription,
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

  String _getCycleLabel(String cycle, AppLocalizations? l10n) {
    switch (cycle) {
      case 'weekly':
        return l10n?.subscription_cycle_weekly ?? 'Mingguan';
      case 'monthly':
        return l10n?.subscription_cycle_monthly ?? 'Bulanan';
      case 'yearly':
        return l10n?.subscription_cycle_yearly ?? 'Tahunan';
      default:
        return cycle;
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final subscriptionService = getIt<SubscriptionTrackerService>();
      await subscriptionService.addSubscription(
        SubscriptionModel(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          cost: double.tryParse(_costController.text) ?? 0.0,
          cycle: _selectedCycle,
          startDate: DateTime.now(),
          nextRenewal: _nextRenewal,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubscriptionAdded();
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
