import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';

class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final PageController pageController;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: DesignTokens.borderDark)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          onTap(index);
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: DesignTokens.primaryColor,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.receipt),
            activeIcon: Icon(Iconsax.receipt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.graph),
            activeIcon: Icon(Iconsax.graph),
            label: 'Forecast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.menu),
            activeIcon: Icon(Iconsax.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
