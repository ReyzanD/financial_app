import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/features/transactions/presentation/widgets/transaction_header.dart';
import 'package:financial_app/features/transactions/presentation/widgets/transaction_filters.dart';
import 'package:financial_app/features/transactions/presentation/widgets/transaction_list.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'Semua'; // Default value, will be updated in didChangeDependencies
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<TransactionController>().loadTransactions();
      } catch (e) {
        LoggerService.error('[TransactionsScreen] Error refreshing data', error: e);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update filter with localized value now that context is available
    final localizations = AppLocalizations.of(context);
    if (localizations != null && _selectedFilter == 'Semua') {
      _selectedFilter = localizations.all;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicator(),
            // Header
            const TransactionHeader(),

            // Search Bar
            Padding(
              padding: ResponsiveHelper.horizontalPadding(context),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.search ?? 'Search',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[600]),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            tooltip: AppLocalizations.of(context)?.delete_search ?? 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: const BorderSide(color: DesignTokens.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),

            // Filter Chips
            TransactionFilters(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),

            // Transactions List
            TransactionList(selectedFilter: _selectedFilter, searchQuery: _searchQuery),
          ],
        ),
      ),
    );
  }
}
