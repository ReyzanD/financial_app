import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/ai_service.dart';

class AIRecommendations extends StatefulWidget {
  const AIRecommendations({super.key});

  @override
  State<AIRecommendations> createState() => _AIRecommendationsState();
}

class _AIRecommendationsState extends State<AIRecommendations> {
  final AIService _aiService = AIService();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAIRecommendations();
  }

  Future<void> _loadAIRecommendations() async {
    try {
      // Check if AI recommendations are enabled
      final prefs = await SharedPreferences.getInstance();
      final aiEnabled = prefs.getBool('ai_recommendations_enabled') ?? true;

      if (!aiEnabled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final recommendations = await _aiService.generateMultipleRecommendations(limit: 5);
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
          _currentIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Handle error - show default message
    }
  }

  IconData _getPriorityIcon(String? priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      case 'low':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return const Color(0xFF8B5FBF);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'Belum ada rekomendasi AI tersedia',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final currentRec = _recommendations[_currentIndex];
    final recommendation = currentRec['recommendation'] ?? 'Belum ada rekomendasi AI tersedia';
    final savings = (currentRec['potential_savings'] ?? 0).toDouble();
    final priority = currentRec['priority'];
    final category = currentRec['category'];
    final action = currentRec['action'] as String?;

    final priorityColor = _getPriorityColor(priority);
    final priorityIcon = _getPriorityIcon(priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [priorityColor.withOpacity(0.05), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(priorityIcon, color: priorityColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Smart Insights',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (category != null)
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (priority != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority == 'high'
                        ? 'URGENT'
                        : priority == 'medium'
                        ? 'PENTING'
                        : 'INFO',
                    style: GoogleFonts.poppins(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (savings > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Potensi Penghematan',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.formatRupiah(savings)}/bulan',
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_recommendations.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _currentIndex = (_currentIndex - 1) % _recommendations.length;
                      });
                    },
                    iconSize: 20,
                  ),
                Text(
                  '${_currentIndex + 1} / ${_recommendations.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                if (_currentIndex < _recommendations.length - 1)
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _currentIndex = (_currentIndex + 1) % _recommendations.length;
                      });
                    },
                    iconSize: 20,
                  ),
              ],
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleAction(action, currentRec),
                style: ElevatedButton.styleFrom(
                  backgroundColor: priorityColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _getActionLabel(action),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _loadAIRecommendations,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text(
                  'Refresh Rekomendasi',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'review_budget':
        return 'Tinjau Budget';
      case 'create_budget':
        return 'Buat Budget';
      case 'set_goal':
        return 'Buat Goal';
      case 'review_spending':
        return 'Tinjau Pengeluaran';
      case 'plan_spending':
        return 'Rencanakan Pengeluaran';
      case 'review_subscriptions':
        return 'Tinjau Langganan';
      case 'view_obligations':
        return 'Lihat Tagihan';
      case 'view_goal':
        return 'Lihat Goal';
      case 'view_investment':
        return 'Lihat Investasi';
      default:
        return 'Tindakan';
    }
  }

  void _handleAction(String action, Map<String, dynamic> recommendation) {
    // Track feedback
    _aiService.trackRecommendationFeedback(
      recommendationId: recommendation['category'] ?? 'unknown',
      recommendationType: recommendation['category'] ?? 'general',
      action: 'acted_on',
    );

    // Navigate based on action
    // Note: This would need proper navigation context
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aksi: ${_getActionLabel(action)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
