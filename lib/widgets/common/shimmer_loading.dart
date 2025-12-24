import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Reusable shimmer loading widgets
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.surfaceDark : Colors.grey[300]!,
      highlightColor: isDark ? DesignTokens.borderDark : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, DesignTokens.radiusMedium),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for transaction list
class TransactionShimmer extends StatelessWidget {
  const TransactionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: 10,
      padding: ResponsiveHelper.padding(context),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveHelper.verticalSpacing(context, 12),
          ),
          child: Shimmer.fromColors(
            baseColor: isDark ? DesignTokens.surfaceDark : Colors.grey[300]!,
            highlightColor: isDark ? DesignTokens.borderDark : Colors.grey[100]!,
            child: Container(
              height: ResponsiveHelper.cardHeight(context, 80),
              decoration: BoxDecoration(
                color: DesignTokens.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, DesignTokens.radiusMedium),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer for card (budget, goal)
class CardShimmer extends StatelessWidget {
  final double height;

  const CardShimmer({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: ResponsiveHelper.symmetricPadding(
        context,
        horizontal: 16,
        vertical: 8,
      ),
      child: Shimmer.fromColors(
        baseColor: isDark ? DesignTokens.surfaceDark : Colors.grey[300]!,
        highlightColor: isDark ? DesignTokens.borderDark : Colors.grey[100]!,
        child: Container(
          height: ResponsiveHelper.cardHeight(context, height),
          decoration: BoxDecoration(
            color: DesignTokens.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, DesignTokens.radiusLarge),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for list of cards
class CardListShimmer extends StatelessWidget {
  final int itemCount;
  final double cardHeight;

  const CardListShimmer({super.key, this.itemCount = 5, this.cardHeight = 120});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return CardShimmer(height: cardHeight);
      },
    );
  }
}

/// Shimmer for dashboard summary cards
class SummaryCardShimmer extends StatelessWidget {
  const SummaryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: ResponsiveHelper.padding(context),
      child: Row(
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: isDark ? DesignTokens.surfaceDark : Colors.grey[300]!,
              highlightColor: isDark ? DesignTokens.borderDark : Colors.grey[100]!,
              child: Container(
                height: ResponsiveHelper.cardHeight(context, 100),
                decoration: BoxDecoration(
                  color: DesignTokens.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, DesignTokens.radiusLarge),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: ResponsiveHelper.horizontalSpacing(context, 12),
          ),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: isDark ? DesignTokens.surfaceDark : Colors.grey[300]!,
              highlightColor: isDark ? DesignTokens.borderDark : Colors.grey[100]!,
              child: Container(
                height: ResponsiveHelper.cardHeight(context, 100),
                decoration: BoxDecoration(
                  color: DesignTokens.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, DesignTokens.radiusLarge),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic shimmer box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.surfaceDark : Colors.grey[300]!,
      highlightColor: isDark ? DesignTokens.borderDark : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DesignTokens.getSurfaceColor(context),
          borderRadius: borderRadius ??
              BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, DesignTokens.radiusSmall),
              ),
        ),
      ),
    );
  }
}
