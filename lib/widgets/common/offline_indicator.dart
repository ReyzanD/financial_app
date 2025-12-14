import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/network_service.dart';

/// Widget untuk menampilkan offline indicator
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final NetworkService _networkService = NetworkService();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = _networkService.isOnline;
    _networkService.addListener(_onNetworkStatusChanged);
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkStatusChanged);
    super.dispose();
  }

  void _onNetworkStatusChanged(bool isOnline) {
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[700],
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tidak ada koneksi internet',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

