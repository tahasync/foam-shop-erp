import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../services/accounting_service.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final as = ref.watch(accountingSummaryProvider);
    final ac = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: as.when(
        loading: () => _shimmer(context),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
        data: (d) => RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: ac.saleTint, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.sage, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Synced just now', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ac.saleFg)),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.teal, AppTheme.tealDark]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.teal.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cash in Hand', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 4),
                  Text('Rs ${d.cashInHand.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 30)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _heroStat('Revenue', 'Rs ${d.revenue.toStringAsFixed(0)}'),
                    const SizedBox(width: 16),
                    _heroStat('Net Profit', 'Rs ${d.netProfit.toStringAsFixed(0)}'),
                    const SizedBox(width: 16),
                    _heroStat('Baqaya', 'Rs ${d.totalCustomerBaqaya.toStringAsFixed(0)}'),
                  ]),
                ]),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _statCard(context, 'Revenue', 'Rs ${d.revenue.toStringAsFixed(0)}', 'Gross: Rs ${d.grossProfit.toStringAsFixed(0)}', Icons.trending_up_rounded, ac.saleTint, ac.saleFg)),
                const SizedBox(width: 10),
                Expanded(child: _statCard(context, 'COGS', 'Rs ${d.cogs.toStringAsFixed(0)}', 'Cost of goods sold', Icons.inventory_2_rounded, ac.purchaseTint, ac.purchaseFg)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _statCard(context, 'Gross Profit', 'Rs ${d.grossProfit.toStringAsFixed(0)}', 'Revenue \u2212 COGS', Icons.account_balance_rounded, ac.profitTint, ac.profitFg)),
                const SizedBox(width: 10),
                Expanded(child: _statCard(context, 'Expenses', 'Rs ${d.totalExpenses.toStringAsFixed(0)}', 'Total kharcha', Icons.trending_down_rounded, ac.expenseTint, ac.expenseFg)),
              ]).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _statCard(context, 'Net Profit', 'Rs ${d.netProfit.toStringAsFixed(0)}', 'Margin: ${d.revenue > 0 ? ((d.netProfit / d.revenue) * 100).toStringAsFixed(0) : 0}%', Icons.trending_up_rounded, ac.profitTint, ac.profitFg)),
                const SizedBox(width: 10),
                Expanded(child: _statCard(context, 'Inventory Value', 'Rs ${d.inventoryValue.toStringAsFixed(0)}', '${d.totalProducts} products', Icons.inventory_rounded, ac.inventoryTint, ac.inventoryFg)),
              ]).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              const SizedBox(height: 12),
              if (d.lowStockCount > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: ac.inventoryTint, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.warning_amber_rounded, size: 17, color: ac.inventoryFg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${d.lowStockCount} ${d.lowStockCount == 1 ? 'item' : 'items'} low on stock',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12.5, color: ac.inventoryFg)),
                    ])),
                  ]),
                ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
      const SizedBox(height: 1),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, fontFeatures: [FontFeature('tnum')], color: Colors.white)),
    ]));
  }

  Widget _statCard(BuildContext context, String title, String value, String sub, IconData icon, Color tint, Color iconColor) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [BoxShadow(color: cs.shadow, blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFeatures: [FontFeature('tnum')], color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, color: ac.inkFaint)),
      ]),
    );
  }

  Widget _shimmer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(5, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(height: 100, decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16))),
        )),
      ),
    );
  }
}
