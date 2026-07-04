import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';

class MoreTabScreen extends StatelessWidget {
  const MoreTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        icon: Iconsax.wallet,
        label: 'Akun',
        subtitle: 'Kelola semua akun',
        color: Colors.blue,
        route: '/accounts',
      ),
      _MoreItem(
        icon: Iconsax.wallet_1,
        label: 'Hutang',
        subtitle: 'Lacak hutang',
        color: Colors.red,
        route: '/debts',
      ),
      _MoreItem(
        icon: Iconsax.receipt_1,
        label: 'Langganan',
        subtitle: 'Kelola langganan',
        color: Colors.orange,
        route: '/subscriptions',
      ),
      _MoreItem(
        icon: Iconsax.chart_1,
        label: 'Investasi',
        subtitle: 'Portofolio investasi',
        color: Colors.green,
        route: '/investments',
      ),
      _MoreItem(
        icon: Iconsax.tag,
        label: 'Tag',
        subtitle: 'Kategorisasi transaksi',
        color: Colors.purple,
        route: '/tags',
      ),
      _MoreItem(
        icon: Iconsax.people,
        label: 'Patungan',
        subtitle: 'Split tagihan',
        color: Colors.teal,
        route: '/splits',
      ),
      _MoreItem(
        icon: Iconsax.flag,
        label: 'Tantangan',
        subtitle: 'Tantangan hemat',
        color: Colors.amber,
        route: '/challenges',
      ),
      _MoreItem(
        icon: Iconsax.calendar,
        label: 'Kalender',
        subtitle: 'Keuangan bulanan',
        color: Colors.cyan,
        route: '/calendar',
      ),
      _MoreItem(
        icon: Iconsax.trend_up,
        label: 'Kekayaan Bersih',
        subtitle: 'Aset vs hutang',
        color: Colors.indigo,
        route: '/net-worth',
      ),
      _MoreItem(
        icon: Iconsax.arrow_swap_horizontal,
        label: 'Arus Kas',
        subtitle: 'Proyeksi arus kas',
        color: Colors.lime,
        route: '/cash-flow',
      ),
      _MoreItem(
        icon: Iconsax.category,
        label: 'Kategori',
        subtitle: 'Kustomisasi kategori',
        color: Colors.pink,
        route: '/categories',
      ),
      _MoreItem(
        icon: Iconsax.copy,
        label: 'Template',
        subtitle: 'Template transaksi',
        color: Colors.deepOrange,
        route: '/templates',
      ),
      _MoreItem(
        icon: Iconsax.wallet,
        label: 'Budget',
        subtitle: 'Kelola anggaran',
        color: Colors.blue,
        route: '/budgets',
      ),
      _MoreItem(
        icon: Iconsax.flag,
        label: 'Goals',
        subtitle: 'Target keuangan',
        color: DesignTokens.successColor,
        route: '/goals',
      ),
      _MoreItem(
        icon: Iconsax.chart,
        label: 'Analytics',
        subtitle: 'Analisis pengeluaran',
        color: Colors.orange,
        route: '/analytics',
      ),
      _MoreItem(
        icon: Iconsax.lamp_charge,
        label: 'Wawasan',
        subtitle: 'Insight keuangan AI',
        color: DesignTokens.primaryColor,
        route: '/financial-insights',
      ),
      _MoreItem(
        icon: Iconsax.receipt,
        label: 'Riwayat Resi',
        subtitle: 'Scan & kelola resi',
        color: Colors.cyan,
        route: '/receipt-history',
      ),
      _MoreItem(
        icon: Iconsax.calendar,
        label: 'Tagihan',
        subtitle: 'Kewajiban keuangan',
        color: Colors.pink,
        route: '/financial-obligations',
      ),
      _MoreItem(
        icon: Iconsax.repeat,
        label: 'Transaksi Berulang',
        subtitle: 'Transaksi otomatis',
        color: Colors.amber,
        route: '/recurring-transactions',
      ),
      _MoreItem(
        icon: Iconsax.document_text,
        label: 'Laporan',
        subtitle: 'Laporan keuangan',
        color: Colors.deepPurple,
        route: '/reports',
      ),
      _MoreItem(
        icon: Iconsax.cloud_add,
        label: 'Backup',
        subtitle: 'Cadangkan data',
        color: Colors.teal,
        route: '/backup',
      ),
      _MoreItem(
        icon: Iconsax.user,
        label: 'Profil',
        subtitle: 'Pengaturan akun',
        color: Colors.indigo,
        route: '/profile',
      ),
      _MoreItem(
        icon: Iconsax.setting,
        label: 'Pengaturan',
        subtitle: 'Preferensi aplikasi',
        color: Colors.grey,
        route: '/settings',
      ),
    ];

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lainnya',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    Icon(Iconsax.more_square, color: DesignTokens.textSecondaryDark),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildGridItem(context, items[index]),
                  childCount: items.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, _MoreItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item.route != null) {
            Navigator.pushNamed(context, item.route!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 28),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? route;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.route,
  });
}
