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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(context, 0, Icons.dashboard_rounded, 'Dashboard', false),
        _navItem(context, 1, Icons.sell_rounded, 'Sales', false),
        _navItem(context, 2, Icons.inventory_2_rounded, 'Inventory', showInventoryDot),
        _navItem(context, 3, Icons.people_rounded, 'Khata', showKhataDot),
      ],
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label, bool showDot) {
    final active = index == currentIndex;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final activeIconBg = isDark ? const Color(0x2600897B) : const Color(0xFFE0F2F1);
    final activeColor = AppTheme.teal;
    final inactiveColor = cs.onSurfaceVariant;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active ? activeIconBg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: active ? activeColor : inactiveColor),
                  if (showDot)
                    Positioned(
                      top: -2,
                      right: -3,
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
