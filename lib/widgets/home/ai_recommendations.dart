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
  Map<String, dynamic>? _recommendations;
  bool _isLoading = true;

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

      final recommendations = await _aiService.generateRecommendations();
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
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

    final recommendation =
        _recommendations?['recommendation'] ??
        'Belum ada rekomendasi AI tersedia';
    final savings = (_recommendations?['potential_savings'] ?? 0).toDouble();
    final priority = _recommendations?['priority'];
    final category = _recommendations?['category'];

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
          const SizedBox(height: 12),
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
}
