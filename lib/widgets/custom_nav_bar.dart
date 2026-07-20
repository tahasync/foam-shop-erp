import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 26, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
            _navItem(context, 1, Icons.sell_rounded, 'Sales'),
            _navItem(context, 2, Icons.inventory_2_rounded, 'Inventory'),
            _navItem(context, 3, Icons.people_rounded, 'Khata'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
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
                if (active)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      width: 5,
                      height: 5,
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
