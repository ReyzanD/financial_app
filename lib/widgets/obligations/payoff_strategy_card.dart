import 'package:flutter/material.dart';
import 'package:financial_app/utils/design_tokens.dart';

class PayoffStrategyCard extends StatelessWidget {
  const PayoffStrategyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DesignTokens.surfaceDark,
      margin: const EdgeInsets.all(DesignTokens.spacing4),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strategi Pelunasan',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: DesignTokens.spacing3),
            Text('Fokus pada hutang dengan bunga tertinggi terlebih dahulu', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
