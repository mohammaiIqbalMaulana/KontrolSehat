import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../appointment/presentation/appointment_page.dart';
import '../../bp/presentation/bp_entry_page.dart';
import '../../home/presentation/home_page.dart';
import '../../medication/presentation/medication_page.dart';
import '../../stats/presentation/stats_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  Widget _buildBody() => switch (_currentIndex) {
    0 => const HomePage(),
    1 => const MedicationPage(),
    3 => const AppointmentPage(),
    4 => const StatsPage(),
    _ => const HomePage(),
  };

  void _onTabSelected(int index) {
    if (index == 2) {
      Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const BpEntryPage()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _buildBody(),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      destinations: <NavigationDestination>[
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        const NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication),
          label: 'Obat',
        ),
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          label: 'Catat TD',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Kontrol',
        ),
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Statistik',
        ),
      ],
    ),
  );
}
