import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Reusable collapsible section widget untuk mengurangi dashboard overload.
/// Membungkus konten dalam card yang bisa di-expand/collapse dengan animasi.
///
/// Usage:
/// ```dart
/// ExpandableSection(
///   title: 'AI Rekomendasi',
///   icon: Iconsax.bulb,
///   initiallyExpanded: false,
///   child: YourContent(),
/// )
/// ```
class ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final Color? accentColor;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
    this.accentColor,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _expandAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? DesignTokens.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header — always visible
          Semantics(
            label: widget.title,
            hint: _isExpanded ? 'Tutup' : 'Buka',
            button: true,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacing4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: Icon(Iconsax.arrow_down_1, color: Colors.grey[500], size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content — expandable with animation
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: widget.child),
          ),
        ],
      ),
    );
  }
}
