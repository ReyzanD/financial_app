import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';

class ContributeModal extends StatefulWidget {
  final Map<String, dynamic> goal;

  const ContributeModal({super.key, required this.goal});

  @override
  State<ContributeModal> createState() => _ContributeModalState();
}

class _ContributeModalState extends State<ContributeModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GoalDataService _goalService = GoalDataService();
  final AccountService _accountService = AccountService();
  bool _isLoading = false;

  List<AccountModel> _accounts = [];
  AccountModel? _selectedAccount;
  double _totalBalance = 0.0;
  double _totalGoals = 0.0;
  double _availableBalance = 0.0;
  bool _isLoadingAccounts = true;

  final List<double> _quickAmounts = [50000, 100000, 250000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountService.getAccounts(activeOnly: true);
      final totalBalance = await _accountService.getTotalBalance();
      final totalGoals = await _accountService.getAvailableBalance();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _totalBalance = totalBalance;
        _totalGoals = totalBalance - totalGoals;
        _availableBalance = totalGoals;
        _isLoadingAccounts = false;

        if (_accounts.isNotEmpty) {
          final defaultAcc = _accounts.where((a) => a.isDefault).firstOrNull;
          _selectedAccount = defaultAcc ?? _accounts.first;
        }
      });
    } catch (e) {
      LoggerService.error('Error loading accounts', error: e);
      if (!mounted) return;
      setState(() => _isLoadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _contributeToGoal() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Masukkan jumlah kontribusi',
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Jumlah harus lebih dari 0',
      );
      return;
    }

    if (_selectedAccount != null && amount > _selectedAccount!.balance) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Saldo ${_selectedAccount!.name} tidak mencukupi (${CurrencyFormatter.formatRupiah(_selectedAccount!.balance.toInt())})',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _goalService.addGoalContribution(
        (widget.goal['goal_id_232143'] ?? widget.goal['id']).toString(),
        amount,
        accountId: _selectedAccount?.id,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (!mounted) return;

      ErrorHandlerService.showSuccessSnackbar(
        context,
        'Berhasil menambah ${CurrencyFormatter.formatRupiah(amount)}${_selectedAccount != null ? ' dari ${_selectedAccount!.name}' : ''}',
      );
      Navigator.pop(context, true);
    } catch (e) {
      LoggerService.error('Error contributing to goal', error: e);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (context.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _contributeToGoal,
        );
      }
    }
  }

  void _setQuickAmount(double amount) {
    _amountController.text = CurrencyFormatter.formatRupiah(amount);
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount =
        ((widget.goal['current_amount_232143'] ??
                    widget.goal['current_amount'] ??
                    0)
                as num)
            .toDouble();
    final targetAmount =
        ((widget.goal['target_amount_232143'] ??
                    widget.goal['target_amount'] ??
                    0)
                as num)
            .toDouble();
    final remaining = targetAmount - currentAmount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Kontribusi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Goal Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.goal['name_232143'] ?? widget.goal['name'] ?? 'Goal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terkumpul',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(currentAmount),
                            style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tersisa',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(remaining),
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Selector
            if (!_isLoadingAccounts) ...[
              Text(
                'Sumber Dana',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DesignTokens.borderDark),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AccountModel>(
                    value: _selectedAccount,
                    isExpanded: true,
                    dropdownColor: DesignTokens.surfaceDark,
                    hint: Text(
                      'Pilih akun',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    items:
                        _accounts.map((account) {
                          return DropdownMenuItem<AccountModel>(
                            value: account,
                            child: Row(
                              children: [
                                Icon(
                                  _getAccountIcon(account.icon),
                                  size: 18,
                                  color: DesignTokens.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    account.name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    account.balance.toInt(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (account) {
                      if (account != null) {
                        setState(() => _selectedAccount = account);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Available Balance Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      size: 16,
                      color: DesignTokens.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                          children: [
                            const TextSpan(text: 'Saldo tersedia: '),
                            TextSpan(
                              text: CurrencyFormatter.formatRupiah(
                                _availableBalance.toInt(),
                              ),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' (dari total ${CurrencyFormatter.formatRupiah(_totalBalance.toInt())} - ${CurrencyFormatter.formatRupiah(_totalGoals.toInt())} dialokasikan ke goal)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedAccount != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.wallet, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedAccount!.name}: ${CurrencyFormatter.formatRupiah(_selectedAccount!.balance.toInt())}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Quick Amount Buttons
            Text(
              'Nominal Cepat',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _quickAmounts.map((amount) {
                    return GestureDetector(
                      onTap: () => _setQuickAmount(amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5FBF,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatRupiah(amount),
                          style: GoogleFonts.poppins(
                            color: DesignTokens.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // Amount Input
            Text(
              'Jumlah Kontribusi',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Rp 0',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: DesignTokens.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryColor,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Iconsax.money_4,
                  color: DesignTokens.primaryColor,
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Note Input (Optional)
            Text(
              'Catatan (Opsional)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: DesignTokens.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignTokens.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _contributeToGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Tambah Kontribusi',
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

  IconData _getAccountIcon(String? icon) {
    switch (icon) {
      case 'wallet':
        return Iconsax.wallet;
      case 'account_balance':
        return Iconsax.bank;
      case 'phone_android':
        return Iconsax.mobile;
      default:
        return Iconsax.wallet;
    }
  }
}
