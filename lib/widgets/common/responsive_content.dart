import 'package:flutter/material.dart';
import 'package:financial_app/utils/responsive_helper.dart';

/// Wraps child content with a max-width constraint for desktop/tablet views.
///
/// On phones the child renders full-width. On wider screens the content is
/// centered with a capped width so the UI doesn't stretch unnaturally — this
/// is especially important for the web demo target.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final mw = maxWidth ?? ResponsiveHelper.maxContentWidth(context);

    // Phone — use full width, no constraint.
    if (ResponsiveHelper.isPhone(context)) return child;

    return Center(
      child: SizedBox(
        width: mw,
        child: child,
      ),
    );
  }
}
