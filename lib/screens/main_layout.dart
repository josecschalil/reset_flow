import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:reset_flow/screens/home_screen.dart';
import 'package:reset_flow/screens/report_screen.dart';
import 'package:reset_flow/screens/rules_screen.dart';
import 'package:reset_flow/screens/dues_screen.dart';
import 'package:reset_flow/theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ReportScreen(),
    const RulesScreen(), // To be implemented next
    const DuesScreen(),  // To be implemented next
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to scroll seamlessly behind the bottom nav bar
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24), // Floating dock style
        decoration: BoxDecoration(
           color: AppTheme.cardColor.withOpacity(0.8),
           borderRadius: BorderRadius.circular(32),
           boxShadow: AppTheme.glassShadows(),
           border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.textPrimary,
              unselectedItemColor: AppTheme.textSecondary.withOpacity(0.4),
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Today',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights_rounded),
                  label: 'Report',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.gavel_rounded),
                  label: 'Decisions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_available_rounded),
                  label: 'Dues',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
