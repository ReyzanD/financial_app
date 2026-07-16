import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:financial_app/features/receipt_history/presentation/screens/receipt_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';

class HomeFloatingActionButton extends StatefulWidget {
  const HomeFloatingActionButton({super.key});

  @override
  State<HomeFloatingActionButton> createState() => _HomeFloatingActionButtonState();
}

class _HomeFloatingActionButtonState extends State<HomeFloatingActionButton> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  Future<void> _addTransaction({String? defaultType}) async {
    _close();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTransactionScreen(defaultType: defaultType)),
    );
    if (!context.mounted) return;
    if (result == true) {
      await context.read<DashboardController>().refresh();
      if (!context.mounted) return;
      ErrorHandlerService.showSuccessSnackbar(context, 'Dashboard diperbarui');
    }
  }

  void _scanReceipt() {
    _close();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiptHistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: _isOpen ? 200 : 56,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Mini FAB: Scan Receipt
          _buildMiniFab(
            animation: _expandAnimation,
            index: 2,
            icon: Iconsax.scan_barcode,
            label: 'Scan',
            backgroundColor: Colors.teal,
            onPressed: _scanReceipt,
          ),
          // Mini FAB: Add Income
          _buildMiniFab(
            animation: _expandAnimation,
            index: 1,
            icon: Iconsax.arrow_down_1,
            label: 'Pemasukan',
            backgroundColor: DesignTokens.successColor,
            onPressed: () => _addTransaction(defaultType: 'income'),
          ),
          // Mini FAB: Add Expense (default)
          _buildMiniFab(
            animation: _expandAnimation,
            index: 0,
            icon: Iconsax.arrow_up_3,
            label: 'Pengeluaran',
            backgroundColor: DesignTokens.errorColor,
            onPressed: () => _addTransaction(defaultType: 'expense'),
          ),
          // Main FAB
          Semantics(
            label: _isOpen ? 'Tutup menu' : 'Tambah Transaksi',
            hint: _isOpen ? 'Ketuk untuk menutup' : 'Ketuk untuk membuka menu tambah',
            child: FloatingActionButton(
              heroTag: 'home_fab',
              onPressed: _toggle,
              backgroundColor: DesignTokens.primaryColor,
              child: AnimatedBuilder(
                animation: _rotateAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value * 3.14159,
                    child: const Icon(Iconsax.add, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFab({
    required Animation<double> animation,
    required int index,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    final offset = 56.0 + (index * 48.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          bottom: 8 + offset * animation.value,
          child: GestureDetector(
            onTap: onPressed,
            child: Semantics(
              label: label,
              button: true,
              child: Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    if (animation.value > 0.5)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
