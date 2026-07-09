import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_item.dart';

class OverdueObligationsView extends StatefulWidget {
  final String searchQuery;

  const OverdueObligationsView({super.key, this.searchQuery = ''});

  @override
  State<OverdueObligationsView> createState() => _OverdueObligationsViewState();
}

class _OverdueObligationsViewState extends State<OverdueObligationsView> {
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      key: ValueKey('overdue_$_refreshKey'),
      future: ObligationService().getObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final obligations = snapshot.data!;
        final overdue = obligations.where((o) => o.daysUntilDue < 0).toList();

        if (overdue.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.tick_circle, size: 64, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(
                  'Tidak Ada Tagihan Terlambat',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Semua tagihan Anda sudah dibayar atau belum jatuh tempo',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        overdue.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: overdue.length + 1, // +1 for warning banner
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.red[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${overdue.length} tagihan terlambat - segera bayar untuk menghindari denda',
                        style: GoogleFonts.poppins(
                          color: Colors.red[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ObligationItem(
              obligation: overdue[index - 1],
              onTap: () {},
              onPaymentRecorded: _refreshData,
            );
          },
        );
      },
    );
  }
}
