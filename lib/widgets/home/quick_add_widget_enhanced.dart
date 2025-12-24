import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/voice_input_service.dart';
import 'package:financial_app/services/receipt_scanning_service.dart';
import 'package:financial_app/services/transaction_templates_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/responsive_helper.dart';

/// Enhanced Quick Add Widget dengan voice input, receipt scanning, smart suggestions, dan templates
class QuickAddWidgetEnhanced extends StatefulWidget {
  final VoidCallback? onTransactionAdded;

  const QuickAddWidgetEnhanced({super.key, this.onTransactionAdded});

  @override
  State<QuickAddWidgetEnhanced> createState() => _QuickAddWidgetEnhancedState();
}

class _QuickAddWidgetEnhancedState extends State<QuickAddWidgetEnhanced> {
  final ApiService _apiService = ApiService();
  final VoiceInputService _voiceService = VoiceInputService();
  final ReceiptScanningService _receiptService = ReceiptScanningService();
  final TransactionTemplatesService _templatesService = TransactionTemplatesService();
  
  List<dynamic> _recentCategories = [];
  List<Map<String, dynamic>> _templates = [];
  bool _isLoadingCategories = true;
  bool _isListening = false;
  bool _isScanning = false;

  final List<double> _quickAmounts = [
    10000, 25000, 50000, 100000, 250000, 500000,
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadRecentCategories();
    _loadTemplates();
  }

  @override
  void dispose() {
    _receiptService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _voiceService.initialize();
  }

  Future<void> _loadRecentCategories() async {
    try {
      final categories = await _apiService.getCategories();
      final transactions = await _apiService.getTransactions(limit: 20);

      final Map<String, int> categoryUsageCount = {};
      for (var transaction in transactions) {
        final categoryId = transaction['category_id'];
        if (categoryId != null) {
          final idString = categoryId.toString();
          categoryUsageCount[idString] = (categoryUsageCount[idString] ?? 0) + 1;
        }
      }

      final List<Map<String, dynamic>> categoryList = [];
      for (var category in categories) {
        if (category != null && category['id'] != null && category['name'] != null) {
          final idString = category['id'].toString();
          categoryList.add({
            'id': idString,
            'name': category['name'].toString(),
            'count': categoryUsageCount[idString] ?? 0,
          });
        }
      }

      categoryList.sort((a, b) {
        final countCompare = b['count'].compareTo(a['count']);
        if (countCompare != 0) return countCompare;
        return a['name'].toString().compareTo(b['name'].toString());
      });

      if (mounted) {
        setState(() {
          _recentCategories = categoryList.take(6).toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _loadTemplates() async {
    final templates = await _templatesService.getMostUsedTemplates(limit: 3);
    setState(() {
      _templates = templates;
    });
  }

  Future<void> _startVoiceInput() async {
    if (!_voiceService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    try {
      final result = await _voiceService.startListening(
        localeId: 'id_ID',
        listenDuration: const Duration(seconds: 5),
      );

      setState(() {
        _isListening = false;
      });

      if (result != null && result.isNotEmpty) {
        // Extract amount from voice input
        final amount = _extractAmountFromVoice(result);
        if (amount > 0) {
          _showQuickAddModal(type: 'expense', presetAmount: amount);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tidak dapat mengenali jumlah dari: $result'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _extractAmountFromVoice(String text) {
    // Extract numbers from voice input
    final numberPattern = RegExp(r'\d+');
    final matches = numberPattern.allMatches(text);
    
    if (matches.isNotEmpty) {
      final numberStr = matches.map((m) => m.group(0)).join('');
      return double.tryParse(numberStr) ?? 0.0;
    }
    
    return 0.0;
  }

  Future<void> _scanReceipt() async {
    setState(() => _isScanning = true);

    try {
      // Pick image
      final imageFile = await _receiptService.pickImage(fromCamera: true);
      if (imageFile == null) {
        setState(() => _isScanning = false);
        return;
      }

      // Scan receipt
      final scanResult = await _receiptService.scanReceipt(imageFile);
      if (scanResult != null) {
        final parsedData = scanResult['parsed_data'] as Map<String, dynamic>;
        final amount = (parsedData['total'] as num?)?.toDouble() ?? 0.0;
        final merchant = parsedData['merchant'] as String? ?? '';

        _showQuickAddModal(
          type: 'expense',
          presetAmount: amount,
          presetDescription: merchant,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat memindai struk. Coba lagi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _showQuickAddModal({
    required String type,
    double? presetAmount,
    String? presetDescription,
    String? presetCategoryId,
  }) {
    // Use existing QuickAddModal from quick_add_widget.dart
    // This is a placeholder - should integrate with existing modal
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Add (Enhanced)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (presetAmount != null)
              Text(
                'Amount: ${CurrencyFormatter.formatRupiah(presetAmount.toInt())}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            if (presetDescription != null)
              Text(
                'Merchant: $presetDescription',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ResponsiveHelper.horizontalPadding(context),
      padding: ResponsiveHelper.padding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 16),
        ),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.flash_1,
                color: const Color(0xFF8B5FBF),
                size: ResponsiveHelper.iconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              Text(
                'Tambah Cepat (Enhanced)',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.fontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),

          // Voice & Receipt scanning buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: _isListening ? Iconsax.microphone_slash : Iconsax.microphone_2,
                  label: _isListening ? 'Mendengarkan...' : 'Voice Input',
                  color: Colors.blue,
                  onTap: _isListening ? null : _startVoiceInput,
                ),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: _isScanning ? Iconsax.refresh : Iconsax.scan,
                  label: _isScanning ? 'Memindai...' : 'Scan Receipt',
                  color: Colors.green,
                  onTap: _isScanning ? null : _scanReceipt,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),

          // Quick type buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickTypeButton(
                  context: context,
                  label: 'Pemasukan',
                  icon: Iconsax.arrow_down_1,
                  color: Colors.green,
                  type: 'income',
                ),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
              Expanded(
                child: _buildQuickTypeButton(
                  context: context,
                  label: 'Pengeluaran',
                  icon: Iconsax.arrow_up_3,
                  color: Colors.red,
                  type: 'expense',
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),

          // Templates section
          if (_templates.isNotEmpty) ...[
            Text(
              'Templates',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: ResponsiveHelper.fontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
            Wrap(
              spacing: ResponsiveHelper.horizontalSpacing(context, 8),
              runSpacing: ResponsiveHelper.verticalSpacing(context, 8),
              children: _templates.map((template) {
                return _buildTemplateChip(context, template);
              }).toList(),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          ],

          // Quick amounts section
          Text(
            'Nominal Cepat',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: ResponsiveHelper.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          Wrap(
            spacing: ResponsiveHelper.horizontalSpacing(context, 8),
            runSpacing: ResponsiveHelper.verticalSpacing(context, 8),
            children: _quickAmounts.map((amount) {
              return _buildAmountChip(context, amount);
            }).toList(),
          ),

          // Recent categories section
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          Text(
            'Kategori Sering',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: ResponsiveHelper.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          if (_isLoadingCategories)
            Center(
              child: Padding(
                padding: ResponsiveHelper.padding(context, multiplier: 0.5),
                child: const CircularProgressIndicator(
                  color: Color(0xFF8B5FBF),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_recentCategories.isEmpty)
            Container(
              padding: ResponsiveHelper.padding(context, multiplier: 0.75),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, 12),
                ),
              ),
              child: Text(
                'Belum ada kategori yang sering digunakan',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: ResponsiveHelper.fontSize(context, 11),
                ),
              ),
            )
          else
            Wrap(
              spacing: ResponsiveHelper.horizontalSpacing(context, 8),
              runSpacing: ResponsiveHelper.verticalSpacing(context, 8),
              children: _recentCategories.map((category) {
                return _buildCategoryChip(context, category);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.verticalPadding(context, multiplier: 1.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: ResponsiveHelper.fontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTypeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(type: type),
      child: Container(
        padding: ResponsiveHelper.verticalPadding(context, multiplier: 1.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: ResponsiveHelper.fontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip(BuildContext context, Map<String, dynamic> template) {
    return GestureDetector(
      onTap: () {
        _showQuickAddModal(
          type: template['type'] as String,
          presetAmount: (template['amount'] as num?)?.toDouble(),
          presetCategoryId: template['category_id']?.toString(),
          presetDescription: template['description']?.toString(),
        );
        _templatesService.incrementUsage(template['id'].toString());
      },
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          border: Border.all(color: Colors.purple.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.document,
              size: ResponsiveHelper.iconSize(context, 14),
              color: Colors.purple,
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 6)),
            Text(
              template['name']?.toString() ?? 'Template',
              style: GoogleFonts.poppins(
                color: Colors.purple,
                fontSize: ResponsiveHelper.fontSize(context, 11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(BuildContext context, double amount) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(type: 'expense', presetAmount: amount),
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5FBF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.5)),
        ),
        child: Text(
          CurrencyFormatter.formatRupiah(amount),
          style: GoogleFonts.poppins(
            color: const Color(0xFF8B5FBF),
            fontSize: ResponsiveHelper.fontSize(context, 12),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(
        type: 'expense',
        presetCategoryId: category['id'].toString(),
      ),
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.category,
              size: ResponsiveHelper.iconSize(context, 14),
              color: Colors.blue,
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 6)),
            Text(
              category['name'].toString(),
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontSize: ResponsiveHelper.fontSize(context, 11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

