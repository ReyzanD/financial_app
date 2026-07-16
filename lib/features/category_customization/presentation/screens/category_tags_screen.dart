import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/features/category_customization/presentation/screens/category_customization_screen.dart';
import 'package:financial_app/features/tags/presentation/screens/tags_screen.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Hub screen that consolidates Categories + Tags into two tabs.
///
/// Pass [initialMode] as 'categories' or 'tags' to open a specific tab.
class CategoryTagsScreen extends StatefulWidget {
  final String initialMode;

  const CategoryTagsScreen({super.key, this.initialMode = 'categories'});

  @override
  State<CategoryTagsScreen> createState() => _CategoryTagsScreenState();
}

class _CategoryTagsScreenState extends State<CategoryTagsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  static const _tabKeys = ['categories', 'tags'];
  static const _tabLabels = ['Kategori', 'Tag'];

  int _initialIndex(String mode) {
    final idx = _tabKeys.indexOf(mode);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialIndex(widget.initialMode);
    _tabController = TabController(length: 2, vsync: this, initialIndex: _currentIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _tabLabels[_currentIndex],
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: DesignTokens.surfaceDark,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: DesignTokens.primaryColor,
              labelColor: DesignTokens.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [Tab(text: 'Kategori'), Tab(text: 'Tag')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [CategoryCustomizationScreen(), TagsScreen(showAppBar: false)],
      ),
    );
  }
}
