import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/modern_widgets.dart';
import 'bahce_yonetimi_screen.dart';
import 'gorev_yonetimi_screen.dart';
import 'daily_work_report_screen.dart';
import 'gubreleme_screen.dart';

class OperasyonHomeScreen extends StatefulWidget {
  const OperasyonHomeScreen({super.key});

  @override
  State<OperasyonHomeScreen> createState() => _OperasyonHomeScreenState();
}

class _OperasyonHomeScreenState extends State<OperasyonHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      const BahceYonetimiScreen(),
      const GorevYonetimiScreen(),
      const DailyWorkReportScreen(),
      const GubrelemeScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.agriculture,
              color: ThemeProvider.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Operasyon',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (authProvider.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authProvider.currentUser!.adSoyad.split(' ').first,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeProvider.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? ThemeProvider.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              HapticHelper.lightTap();
              setState(() => _selectedIndex = index);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 70,
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFD97706).withOpacity(0.15),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.park_outlined, size: 24),
                selectedIcon: Icon(Icons.park, size: 24, color: const Color(0xFFD97706)),
                label: 'Bahçeler',
              ),
              NavigationDestination(
                icon: const Icon(Icons.task_alt_outlined, size: 24),
                selectedIcon: Icon(Icons.task_alt, size: 24, color: const Color(0xFFD97706)),
                label: 'Görevler',
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined, size: 24),
                selectedIcon: Icon(Icons.assignment, size: 24, color: const Color(0xFFD97706)),
                label: 'Günlük Rapor',
              ),
              NavigationDestination(
                icon: const Icon(Icons.science_outlined, size: 24),
                selectedIcon: Icon(Icons.science, size: 24, color: const Color(0xFFD97706)),
                label: 'Gübreleme',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
