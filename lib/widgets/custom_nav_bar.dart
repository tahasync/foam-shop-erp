import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showInventoryDot;
  final bool showKhataDot;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showInventoryDot = false,
    this.showKhataDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final activeIconBg = isDark ? const Color(0x2600897B) : const Color(0xFFE0F2F1);
    final activeColor = AppTheme.teal;
    final inactiveColor = cs.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(index: 0, icon: Icons.dashboard_rounded, label: 'Dashboard', showDot: false,
            isActive: 0 == currentIndex, activeColor: activeColor, inactiveColor: inactiveColor,
            activeIconBg: activeIconBg, onTap: () => onTap(0)),
        _NavItem(index: 1, icon: Icons.sell_rounded, label: 'Sales', showDot: false,
            isActive: 1 == currentIndex, activeColor: activeColor, inactiveColor: inactiveColor,
            activeIconBg: activeIconBg, onTap: () => onTap(1)),
        _NavItem(index: 2, icon: Icons.inventory_2_rounded, label: 'Inventory', showDot: showInventoryDot,
            isActive: 2 == currentIndex, activeColor: activeColor, inactiveColor: inactiveColor,
            activeIconBg: activeIconBg, onTap: () => onTap(2)),
        _NavItem(index: 3, icon: Icons.people_rounded, label: 'Khata', showDot: showKhataDot,
            isActive: 3 == currentIndex, activeColor: activeColor, inactiveColor: inactiveColor,
            activeIconBg: activeIconBg, onTap: () => onTap(3)),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool showDot;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeIconBg;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.showDot,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeIconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? activeIconBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: isActive ? activeColor : inactiveColor),
                  if (showDot)
                    Positioned(
                      top: -2, right: -3,
                      child: Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}