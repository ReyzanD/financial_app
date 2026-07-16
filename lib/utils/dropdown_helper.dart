import 'package:flutter/material.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Shared styling constants for [DropdownButtonFormField] widgets across the app.
///
/// All dropdowns should reference [darkDropdownDecoration] or use
/// [darkDropdownInputDecoration] so that visual changes propagate uniformly.
class DropdownHelper {
  DropdownHelper._();

  /// Common [InputDecoration] for a dark-themed dropdown.
  ///
  /// Usage:
  /// ```dart
  /// DropdownButtonFormField<String>(
  ///   dropdownColor: DesignTokens.surfaceDark,
  ///   style: const TextStyle(color: Colors.white),
  ///   decoration: DropdownHelper.darkDropdownDecoration(labelText: '...'),
  ///   ...
  /// )
  /// ```
  static InputDecoration darkDropdownDecoration({
    String? labelText,
    TextStyle? labelStyle,
    String? hintText,
    Widget? prefixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: labelStyle ?? TextStyle(color: Colors.grey[400]),
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: DesignTokens.surfaceDark,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide(color: DesignTokens.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide(color: DesignTokens.errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        borderSide: BorderSide(color: DesignTokens.errorColor, width: 1.5),
      ),
    );
  }
}
