import 'package:flutter/material.dart';
import 'package:water_quality/analysis_page.dart';
import 'package:water_quality/dashboard_page.dart';
import 'package:water_quality/sensor_settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const DashboardPage(),
    const AnalysisPage(),
    const SensorSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1128), // Dark background
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E2247), // Lighter dark tone for bottom bar
        currentIndex: _currentIndex,
        selectedItemColor: const Color.fromARGB(255, 171, 184, 247), // Light blue text/icon for selected
        unselectedItemColor: Colors.white54, // Muted white for unselected
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
