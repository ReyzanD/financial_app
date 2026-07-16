import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/tags/presentation/controllers/tag_controller.dart';

class TagsScreen extends StatefulWidget {
  final bool showAppBar;

  const TagsScreen({super.key, this.showAppBar = true});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: DesignTokens.backgroundDark,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Tags',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Consumer<TagController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading)
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.primaryColor,
                    ),
                  );
                if (ctrl.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.warning_2,
                          size: 64,
                          color: DesignTokens.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat tags',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ctrl.errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: ctrl.refresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryColor,
                          ),
                          child: Text(
                            'Coba Lagi',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (ctrl.tags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.tag, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada tags',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spacing4),
                  itemCount: ctrl.tags.length,
                  itemBuilder: (_, i) {
                    final tag = ctrl.tags[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceDark,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        border: Border.all(color: DesignTokens.borderDark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (_getTagColor(
                                tag.color,
                              )).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Iconsax.tag,
                              color: _getTagColor(tag.color),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tag.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (tag.usageCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.borderDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${tag.usageCount}',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String? color) {
    if (color == null || color.isEmpty) return DesignTokens.primaryColor;
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'yellow':
        return Colors.yellow;
      case 'cyan':
        return Colors.cyan;
      default:
        return DesignTokens.primaryColor;
    }
  }
}
