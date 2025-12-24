import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/accessibility_helper.dart';

/// Card untuk request permission dengan explanation
class PermissionRequestCard extends StatefulWidget {
  final Permission permission;
  final String title;
  final String description;
  final String benefit;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionRequestCard({
    super.key,
    required this.permission,
    required this.title,
    required this.description,
    required this.benefit,
    required this.icon,
    this.iconColor = const Color(0xFF8B5FBF),
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<PermissionRequestCard> createState() => _PermissionRequestCardState();
}

class _PermissionRequestCardState extends State<PermissionRequestCard> {
  bool _isRequesting = false;
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await widget.permission.status;
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final status = await widget.permission.request();
      
      if (mounted) {
        setState(() {
          _status = status;
          _isRequesting = false;
        });

        if (status.isGranted) {
          widget.onPermissionGranted?.call();
        } else if (status.isPermanentlyDenied) {
          widget.onPermissionDenied?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isGranted = _status?.isGranted ?? false;
    final isPermanentlyDenied = _status?.isPermanentlyDenied ?? false;

    return Semantics(
      label: AccessibilityHelper.createSemanticLabel(
        label: widget.title,
        hint: widget.description,
      ),
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveHelper.verticalSpacing(context, 16),
        ),
        padding: ResponsiveHelper.padding(context),
        decoration: BoxDecoration(
          color: DesignTokens.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, DesignTokens.radiusLarge),
          ),
          border: Border.all(
            color: isGranted
                ? DesignTokens.successColor
                : DesignTokens.getBorderColor(context),
            width: isGranted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: ResponsiveHelper.padding(context, multiplier: 0.75),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.borderRadius(context, DesignTokens.radiusMedium),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: ResponsiveHelper.iconSize(context, 24),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibilityHelper.createAccessibleText(
                        context: context,
                        text: widget.title,
                        isHeader: true,
                        style: GoogleFonts.poppins(
                          color: DesignTokens.getTextColor(context),
                          fontSize: ResponsiveHelper.fontSize(
                            context,
                            DesignTokens.fontSizeTitleMedium,
                          ),
                          fontWeight: DesignTokens.weightSemiBold,
                        ),
                      ),
                      if (isGranted) ...[
                        SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
                        Row(
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              size: ResponsiveHelper.iconSize(context, 16),
                              color: DesignTokens.successColor,
                            ),
                            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 4)),
                            Text(
                              'Diizinkan',
                              style: GoogleFonts.poppins(
                                color: DesignTokens.successColor,
                                fontSize: ResponsiveHelper.fontSize(
                                  context,
                                  DesignTokens.fontSizeLabelSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),

            // Description
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: widget.description,
              style: GoogleFonts.poppins(
                color: DesignTokens.getTextColor(context, isPrimary: false),
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeBodySmall,
                ),
                height: 1.5,
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),

            // Benefit
            Container(
              padding: ResponsiveHelper.padding(context, multiplier: 0.75),
              decoration: BoxDecoration(
                color: DesignTokens.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, DesignTokens.radiusSmall),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: ResponsiveHelper.iconSize(context, 16),
                    color: DesignTokens.infoColor,
                  ),
                  SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
                  Expanded(
                    child: Text(
                      widget.benefit,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.infoColor,
                        fontSize: ResponsiveHelper.fontSize(
                          context,
                          DesignTokens.fontSizeLabelSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            if (!isGranted) ...[
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
              SizedBox(
                width: double.infinity,
                child: isPermanentlyDenied
                    ? AccessibilityHelper.createAccessibleButton(
                        context: context,
                        label: 'Buka Pengaturan',
                        onPressed: () {
                          _openSettings();
                        },
                        backgroundColor: DesignTokens.warningColor,
                        icon: Iconsax.setting_2,
                      )
                    : _isRequesting
                        ? Container(
                            padding: ResponsiveHelper.padding(context),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: widget.iconColor,
                              ),
                            ),
                          )
                        : AccessibilityHelper.createAccessibleButton(
                            context: context,
                            label: 'Izinkan',
                            onPressed: () {
                              _requestPermission();
                            },
                            backgroundColor: widget.iconColor,
                            icon: Iconsax.tick_circle,
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

