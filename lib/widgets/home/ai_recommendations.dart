import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/api_service.dart';

class AIRecommendations extends StatefulWidget {
  const AIRecommendations({super.key});

  @override
  State<AIRecommendations> createState() => _AIRecommendationsState();
}

class _AIRecommendationsState extends State<AIRecommendations> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAIRecommendations();
  }

  Future<void> _loadAIRecommendations() async {
    try {
      final recommendations = await _apiService.getAIRecommendations();
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error - show default message
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
          border: Border.all(color: Color(0xFF8B5FBF).withOpacity(0.3)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
        ),
      );
    }

    final recommendation =
        _recommendations?['recommendation'] ??
        'Belum ada rekomendasi AI tersedia';
    final savings = _recommendations?['potential_savings'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.flash, color: Color(0xFF8B5FBF), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          if (savings > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Potensi penghematan: ${CurrencyFormatter.formatRupiah(savings)}/bulan',
              style: GoogleFonts.poppins(
                color: Color(0xFF8B5FBF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
