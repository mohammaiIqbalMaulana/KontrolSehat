import 'package:flutter/material.dart';

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
    bottomNavigationBar: _BottomNavigation(
      selectedIndex: _currentIndex,
      onSelected: _onTabSelected,
    ),
  );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home, 'Beranda'),
    _NavItem(Icons.medication_outlined, Icons.medication, 'Obat'),
    _NavItem(Icons.add, Icons.add, 'Catat TD'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Kontrol'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Statistik'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: scheme.surface,
      elevation: dark ? 10 : 8,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: List<Widget>.generate(_items.length, (index) {
              final item = _items[index];
              if (index == 2) {
                return _CenterNavAction(
                  item: item,
                  onTap: () => onSelected(index),
                );
              }
              return Expanded(
                child: _NavDestination(
                  item: item,
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDestination extends StatefulWidget {
  const _NavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavDestination> createState() => _NavDestinationState();
}

class _NavDestinationState extends State<_NavDestination> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.selected;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : (_hovered ? 1.03 : 1),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: active
                  ? scheme.primary.withValues(alpha: 0.14)
                  : (_hovered
                        ? scheme.primary.withValues(alpha: 0.06)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  active ? widget.item.selectedIcon : widget.item.icon,
                  color: color,
                  size: 23,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterNavAction extends StatefulWidget {
  const _CenterNavAction({required this.item, required this.onTap});

  final _NavItem item;
  final VoidCallback onTap;

  @override
  State<_CenterNavAction> createState() => _CenterNavActionState();
}

class _CenterNavActionState extends State<_CenterNavAction> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.88 : (_hovered ? 1.08 : 1),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: _hovered ? 58 : 54,
                  height: _hovered ? 58 : 54,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: _hovered ? 0.40 : 0.25,
                        ),
                        blurRadius: _hovered ? 16 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: scheme.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
