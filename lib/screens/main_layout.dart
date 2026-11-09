import 'package:flutter/material.dart';
import 'package:reset_flow/screens/home_screen.dart';
import 'package:reset_flow/screens/report_screen.dart';
import 'package:reset_flow/screens/rules_screen.dart';
import 'package:reset_flow/screens/dues_screen.dart';
import 'package:reset_flow/screens/monetary_dealings_screen.dart';
import 'package:reset_flow/screens/quote_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}
class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ReportScreen(),
    const RulesScreen(), 
    const DuesScreen(),  
    const MonetaryDealingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rtl_outlined),
              selectedIcon: Icon(Icons.checklist_rtl),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Decisions',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_available_outlined),
              selectedIcon: Icon(Icons.event_available),
              label: 'Dues',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Finance',
            ),
          ],
        ),
      ),
    );
  }
}
