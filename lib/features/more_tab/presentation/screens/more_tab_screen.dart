import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/common/responsive_content.dart';

class MoreTabScreen extends StatelessWidget {
  const MoreTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: ResponsiveContent(
        child: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: SafeArea(
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
                          Icon(
                            Iconsax.more_square,
                            color: DesignTokens.textSecondaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final section in sections) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          section.title,
                          style: GoogleFonts.poppins(
                            color: DesignTokens.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.9,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildGridItem(context, section.items[index]),
                          childCount: section.items.length,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  List<_MoreSection> _buildSections() {
    return [
      _MoreSection(
        title: 'KEUANGAN',
        items: [
          _MoreItem(
            icon: Iconsax.wallet,
            label: 'Anggaran',
            color: Colors.blue,
            route: '/budgets',
          ),
          _MoreItem(
            icon: Iconsax.flag,
            label: 'Goals',
            color: DesignTokens.successColor,
            route: '/goals',
          ),
          _MoreItem(
            icon: Iconsax.wallet_1,
            label: 'Akun',
            color: Colors.indigo,
            route: '/accounts',
          ),
          _MoreItem(
            icon: Iconsax.receipt_1,
            label: 'Kewajiban',
            color: Colors.red,
            route: '/obligations',
          ),
          _MoreItem(
            icon: Iconsax.chart_1,
            label: 'Investasi',
            color: Colors.green,
            route: '/investments',
          ),
          _MoreItem(
            icon: Iconsax.people,
            label: 'Patungan',
            color: Colors.teal,
            route: '/splits',
          ),
        ],
      ),
      _MoreSection(
        title: 'ANALISIS',
        items: [
          _MoreItem(
            icon: Iconsax.chart,
            label: 'Analitik',
            color: Colors.orange,
            route: '/analytics',
          ),
          _MoreItem(
            icon: Iconsax.graph,
            label: 'Perkiraan',
            color: Colors.cyan,
            route: '/forecast',
          ),
          _MoreItem(
            icon: Iconsax.calendar,
            label: 'Kalender',
            color: Colors.cyan,
            route: '/calendar',
          ),
          _MoreItem(
            icon: Iconsax.receipt,
            label: 'Riwayat Resi',
            color: Colors.cyan,
            route: '/receipt-history',
          ),
          _MoreItem(
            icon: Iconsax.diagram,
            label: 'Penasihat',
            color: DesignTokens.primaryColor,
            route: '/financial-advisor',
          ),
          _MoreItem(
            icon: Iconsax.global,
            label: 'Studi Jerman',
            color: const Color(0xFFFFCD00),
            route: '/german-finance',
          ),
        ],
      ),
      _MoreSection(
        title: 'ALAT',
        items: [
          _MoreItem(
            icon: Iconsax.copy,
            label: 'Template',
            color: Colors.deepOrange,
            route: '/templates',
          ),
          _MoreItem(
            icon: Iconsax.flag,
            label: 'Tantangan',
            color: Colors.amber,
            route: '/challenges',
          ),
        ],
      ),
      _MoreSection(
        title: 'PENGATURAN',
        items: [
          _MoreItem(
            icon: Iconsax.category,
            label: 'Kategori & Tag',
            color: Colors.pink,
            route: '/categories',
          ),
          _MoreItem(
            icon: Iconsax.cloud_add,
            label: 'Backup',
            color: Colors.teal,
            route: '/backup',
          ),
          _MoreItem(
            icon: Iconsax.user,
            label: 'Profil',
            color: Colors.indigo,
            route: '/profile',
          ),
          _MoreItem(
            icon: Iconsax.setting,
            label: 'Pengaturan',
            color: Colors.grey,
            route: '/settings',
          ),
        ],
      ),
    ];
  }

  Widget _buildGridItem(BuildContext context, _MoreItem item) {
    return Semantics(
      label: item.label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item.route != null) Navigator.pushNamed(context, item.route!);
          },
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              border: Border.all(color: item.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 24),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreSection {
  final String title;
  final List<_MoreItem> items;
  const _MoreSection({required this.title, required this.items});
}

class _MoreItem {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.color,
    this.route,
  });
}
