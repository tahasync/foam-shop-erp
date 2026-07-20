import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/torn_receipt_card.dart';
import '../widgets/stitched_divider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final as = ref.watch(accountingSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Asif Foam Center')),
      body: as.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(),
            const SizedBox(height: 8),
            TornReceiptCard(
              label: 'Cash in Hand',
              amount: 'Rs ${d.cashInHand.toStringAsFixed(0)}',
              gradientStart: AppTheme.teal,
              gradientEnd: AppTheme.tealDark,
              stats: [
                SlipStat(label: 'Revenue', value: 'Rs ${d.revenue.toStringAsFixed(0)}'),
                SlipStat(label: 'Net Profit', value: 'Rs ${d.netProfit.toStringAsFixed(0)}'),
                SlipStat(label: 'Baqaya', value: 'Rs ${d.totalCustomerBaqaya.toStringAsFixed(0)}'),
              ],
              stubLeft: 'Register slip · today',
              stubRight: '#0001',
            ),
            const StitchedDivider(),
            _StatGrid(d: d),
            const StitchedDivider(),
            if (d.lowStockCount > 0)
              _LowStockAlert(d: d),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final now = DateTime.now();
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Asif Foam Center', style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.01)),
        Text(dateStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: ac.saleTint, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
                decoration: BoxDecoration(color: AppTheme.sage, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppTheme.sage.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 2)])),
            const SizedBox(width: 5),
            Text('Synced just now', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ac.saleFg)),
          ]),
        ),
      ])),
      const SizedBox(width: 8),
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(11),
            border: Border.all(color: cs.outlineVariant)),
        child: Icon(Icons.person_rounded, size: 18, color: cs.onSurfaceVariant)),
    ]);
  }
}

class _StatGrid extends StatelessWidget {
  final dynamic d;
  const _StatGrid({required this.d});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard(context, 'Revenue', 'Rs ${d.revenue.toStringAsFixed(0)}', 'Gross: Rs ${d.grossProfit.toStringAsFixed(0)}', Icons.trending_up_rounded, ac.saleTint, ac.saleFg)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, 'COGS', 'Rs ${d.cogs.toStringAsFixed(0)}', 'Cost of goods sold', Icons.receipt_rounded, ac.purchaseTint, ac.purchaseFg)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard(context, 'Gross Profit', 'Rs ${d.grossProfit.toStringAsFixed(0)}', 'Revenue \u2212 COGS', Icons.account_balance_rounded, ac.profitTint, ac.profitFg)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, 'Expenses', 'Rs ${d.totalExpenses.toStringAsFixed(0)}', 'Total kharcha', Icons.trending_down_rounded, ac.expenseTint, ac.expenseFg)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard(context, 'Net Profit', 'Rs ${d.netProfit.toStringAsFixed(0)}', 'Margin: ${d.revenue > 0 ? ((d.netProfit / d.revenue) * 100).toStringAsFixed(0) : 0}%', Icons.trending_up_rounded, ac.profitTint, ac.profitFg)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, 'Inventory Value', 'Rs ${d.inventoryValue.toStringAsFixed(0)}', '${d.totalProducts} products', Icons.inventory_2_rounded, ac.inventoryTint, ac.inventoryFg)),
      ]),
    ]);
  }

  Widget _statCard(BuildContext context, String title, String value, String sub, IconData icon, Color tint, Color iconColor) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(color: cs.shadow, blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4),
          BoxShadow(color: Colors.transparent, offset: Offset.zero, blurRadius: 0, spreadRadius: 0),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: iconColor)),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], color: cs.onSurface)),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(fontSize: 9.5, color: ac.inkFaint)),
      ]),
    );
  }
}

class _LowStockAlert extends StatelessWidget {
  final dynamic d;
  const _LowStockAlert({required this.d});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.purchaseTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.warning_amber_rounded, size: 17, color: ac.purchaseFg)),
        const SizedBox(width: 11),
        Expanded(child: Text('${d.lowStockCount} ${d.lowStockCount == 1 ? 'item' : 'items'} low on stock',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ac.purchaseFg))),
        Icon(Icons.chevron_right_rounded, size: 18, color: ac.inkFaint),
      ]),
    );
  }
}
