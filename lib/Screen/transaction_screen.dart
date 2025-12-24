import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/widgets/transactions/transaction_header.dart';
import 'package:financial_app/widgets/transactions/transaction_filters.dart';
import 'package:financial_app/widgets/transactions/transaction_list.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/l10n/app_localizations.dart';

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
    _selectedFilter =
        'Semua'; // Default value, will be updated in didChangeDependencies
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshData();
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const TransactionHeader(),

            // Search Bar
            Padding(
              padding: ResponsiveHelper.horizontalPadding(context),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: Colors.grey[600],
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF8B5FBF),
                      width: 2,
                    ),
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
            TransactionList(
              selectedFilter: _selectedFilter,
              searchQuery: _searchQuery,
            ),
          ],
        ),
      ),
    );
  }
}
