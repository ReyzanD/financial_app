import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/Screen/financial_obligations_screen.dart';
import 'package:financial_app/Screen/transaction_history_screen.dart';
import 'package:financial_app/Screen/recurring_transactions_screen.dart';
import 'package:financial_app/Screen/backup_screen.dart';
import 'package:financial_app/Screen/ai_budget_recommendation_screen.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/services/quick_actions_analytics_service.dart';

/// Enhanced Quick Actions dengan customization, analytics, swipe gestures, dan categories
class QuickActionsEnhanced extends StatefulWidget {
  const QuickActionsEnhanced({super.key});

  @override
  State<QuickActionsEnhanced> createState() => _QuickActionsEnhancedState();
}

class _QuickActionsEnhancedState extends State<QuickActionsEnhanced> {
  final QuickActionsAnalyticsService _analyticsService = QuickActionsAnalyticsService();
  List<Map<String, dynamic>> _actions = [];
  List<Map<String, dynamic>> _recentActions = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);
    
    try {
      // Get default actions first (contains icon, color, onTap)
      final defaultActions = _getDefaultActions();
      
      // Load saved preferences (only contains encodable fields)
      final preferences = await _analyticsService.getPreferences();
      
      if (preferences.isNotEmpty) {
        // Merge saved preferences with defaults to restore icon, color, onTap
        _actions = preferences.map((pref) {
          // Find matching default action by id
          final defaultAction = defaultActions.firstWhere(
            (action) => action['id'] == pref['id'],
            orElse: () => <String, dynamic>{},
          );
          
          // Merge: use saved preferences for visible/order, defaults for icon/color/onTap
          return {
            'id': pref['id'] ?? defaultAction['id'],
            'label': pref['label'] ?? defaultAction['label'],
            'category': pref['category'] ?? defaultAction['category'],
            'visible': pref['visible'] ?? defaultAction['visible'] ?? true,
            'order': pref['order'] ?? defaultAction['order'] ?? 0,
            // Restore non-encodable fields from defaults
            'icon': defaultAction['icon'],
            'color': pref['colorHex'] != null 
                ? Color(int.parse(pref['colorHex'].toString().replaceFirst('#', '0x')))
                : defaultAction['color'],
            'onTap': defaultAction['onTap'],
          };
        }).toList();
        
        // Add any new default actions that weren't in preferences
        final savedIds = preferences.map((p) => p['id']).toSet();
        for (var defaultAction in defaultActions) {
          if (!savedIds.contains(defaultAction['id'])) {
            _actions.add(defaultAction);
          }
        }
      } else {
        // No saved preferences, use defaults
        _actions = defaultActions;
        await _analyticsService.savePreferences(_actions);
      }
      
      // Load recent actions
      final mostUsed = await _analyticsService.getMostUsedActions(limit: 3);
      _recentActions = mostUsed;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getDefaultActions() {
    return [
      {
        'id': 'ai_budget',
        'icon': Iconsax.flash,
        'label': 'AI Budget',
        'color': const Color(0xFFFFB74D),
        'category': 'Analytics',
        'visible': true,
        'order': 0,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AIBudgetRecommendationScreen(),
          ),
        ),
      },
      {
        'id': 'riwayat',
        'icon': Iconsax.note_2,
        'label': 'Riwayat',
        'color': const Color(0xFF8B5FBF),
        'category': 'Transactions',
        'visible': true,
        'order': 1,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionHistoryScreen(),
          ),
        ),
      },
      {
        'id': 'tagihan',
        'icon': Iconsax.receipt_2,
        'label': 'Tagihan',
        'color': const Color(0xFFE91E63),
        'category': 'Transactions',
        'visible': true,
        'order': 2,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FinancialObligationsScreen(),
          ),
        ),
      },
      {
        'id': 'backup',
        'icon': Iconsax.shield_tick,
        'label': 'Backup',
        'color': const Color(0xFF4CAF50),
        'category': 'Settings',
        'visible': true,
        'order': 3,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BackupScreen()),
        ),
      },
      {
        'id': 'berulang',
        'icon': Iconsax.repeat,
        'label': 'Berulang',
        'color': const Color(0xFF2196F3),
        'category': 'Transactions',
        'visible': true,
        'order': 4,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RecurringTransactionsScreen(),
          ),
        ),
      },
    ];
  }

  Future<void> _handleActionTap(Map<String, dynamic> action) async {
    // Track usage
    await _analyticsService.trackAction(action['id']);
    
    // Execute action
    (action['onTap'] as VoidCallback)();
    
    // Refresh recent actions
    _loadActions();
  }

  List<Map<String, dynamic>> get _filteredActions {
    if (_selectedCategory == null) {
      return _actions.where((a) => a['visible'] == true).toList();
    }
    return _actions.where((a) => 
      a['visible'] == true && a['category'] == _selectedCategory
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'More Actions',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.setting_2, color: Color(0xFF8B5FBF)),
              onPressed: () => _showCustomizationDialog(),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
        
        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('All', null),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              ..._analyticsService.getActionCategories().map((category) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: ResponsiveHelper.horizontalSpacing(context, 8),
                  ),
                  child: _buildCategoryChip(category, category),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
        
        // Recent actions section
        if (_recentActions.isNotEmpty) ...[
          Text(
            'Sering Digunakan',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: ResponsiveHelper.fontSize(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentActions.length,
              itemBuilder: (context, index) {
                final recent = _recentActions[index];
                final action = _actions.firstWhere(
                  (a) => a['id'] == recent['id'],
                  orElse: () => {},
                );
                if (action.isEmpty) return const SizedBox.shrink();
                
                return Padding(
                  padding: EdgeInsets.only(
                    right: ResponsiveHelper.horizontalSpacing(context, 12),
                  ),
                  child: _buildRecentActionItem(context, action, recent['count']),
                );
              },
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
        ],
        
        // Main actions grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.gridCrossAxisCount(
              context,
              phone: 4,
              tablet: 5,
            ),
            crossAxisSpacing: ResponsiveHelper.horizontalSpacing(context, 10),
            mainAxisSpacing: ResponsiveHelper.verticalSpacing(context, 12),
            childAspectRatio: ResponsiveHelper.isTablet(context) ? 0.9 : 0.85,
          ),
          itemCount: _filteredActions.length,
          itemBuilder: (context, index) {
            final action = _filteredActions[index];
            return _buildQuickActionItem(
              context: context,
              action: action,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF8B5FBF).withOpacity(0.2)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF8B5FBF)
                : Colors.grey[800]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? const Color(0xFF8B5FBF) : Colors.white70,
            fontSize: ResponsiveHelper.fontSize(context, 11),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActionItem(
    BuildContext context,
    Map<String, dynamic> action,
    int count,
  ) {
    return GestureDetector(
      onTap: () => _handleActionTap(action),
      child: Container(
        width: 120,
        padding: ResponsiveHelper.padding(context, multiplier: 0.75),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (action['color'] as Color).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              action['icon'] as IconData,
              color: action['color'] as Color,
              size: ResponsiveHelper.iconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action['label'] as String,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 11),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${count}x',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: ResponsiveHelper.fontSize(context, 9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required Map<String, dynamic> action,
  }) {
    final iconSize = ResponsiveHelper.iconSize(context, 48);
    return GestureDetector(
      onTap: () => _handleActionTap(action),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: (action['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, 14),
              ),
              border: Border.all(
                color: (action['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Icon(
              action['icon'] as IconData,
              color: action['color'] as Color,
              size: ResponsiveHelper.iconSize(context, 22),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 6)),
          Flexible(
            child: Text(
              action['label'] as String,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: ResponsiveHelper.fontSize(context, 9),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Customize Quick Actions',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _actions.length,
            itemBuilder: (context, index) {
              final action = _actions[index];
              return CheckboxListTile(
                title: Text(
                  action['label'] as String,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                value: action['visible'] as bool,
                onChanged: (value) {
                  setState(() {
                    action['visible'] = value ?? true;
                  });
                  _analyticsService.savePreferences(_actions);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
            ),
          ),
        ],
      ),
    );
  }
}

