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
    final ac = AppColors.of(context);
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? ac.saleTint : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 18, color: active ? AppTheme.teal : cs.onSurfaceVariant),
                if (showDot)
                  Positioned(
                    top: -2,
                    right: -4,
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
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: active ? AppTheme.teal : cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
