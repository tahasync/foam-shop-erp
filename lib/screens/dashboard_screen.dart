import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/torn_receipt_card.dart';
import '../widgets/stitched_divider.dart';
import 'account_settings_screen.dart';
import 'billing_screen.dart';
import 'expense_sheet_screen.dart';
import 'customer_recovery_screen.dart';
import 'supplier_khata_screen.dart';
import 'reports_screen.dart';
import 'export_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final as = ref.watch(accountingSummaryProvider);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: as.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) => SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 96 + bottom),
            children: [
              _GreetHeader(),
              const SizedBox(height: 16),
              TornReceiptCard(
                label: 'Cash in Hand',
                amount: 'Rs ${NumberFormat('#,##0').format(d.cashInHand.toInt())}',
                gradientStart: AppTheme.teal,
                gradientEnd: AppTheme.tealDark,
                stats: [
                  SlipStat(label: 'Revenue', value: 'Rs ${NumberFormat('#,##0').format(d.revenue.toInt())}'),
                  SlipStat(label: 'Net Profit', value: 'Rs ${NumberFormat('#,##0').format(d.netProfit.toInt())}'),
                  SlipStat(label: 'Baqaya', value: 'Rs ${NumberFormat('#,##0').format(d.totalCustomerBaqaya.toInt())}'),
                ],
                stubLeft: 'Register slip · today',
                stubRight: '#0001',
              ),
              const StitchedDivider(margin: EdgeInsets.symmetric(vertical: 14)),
              _StatGrid(d: d),
              const StitchedDivider(margin: EdgeInsets.symmetric(vertical: 14)),
              if (d.lowStockCount > 0)
                _LowStockAlert(d: d),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final now = DateTime.now();
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    final authState = ref.watch(authStateProvider);
    final authService = ref.watch(authServiceProvider);
    final user = authState.asData?.value;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Asif Foam Center', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.01, color: cs.onSurface)),
          const SizedBox(height: 2),
          Row(children: [
            Text(dateStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: ac.saleTint, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: BoxDecoration(color: AppTheme.sage, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.sage.withValues(alpha: 0.3), blurRadius: 3, spreadRadius: 1.5)])),
                const SizedBox(width: 4),
                Text('Synced', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ac.saleFg)),
              ]),
            ),
          ]),
        ]),
      ),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
        icon: CircleAvatar(
          radius: 16,
          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
          child: user?.photoURL == null ? const Icon(Icons.person_rounded, size: 18) : null,
        ),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'settings', child: Text('Account / Settings')),
          const PopupMenuItem(value: 'billing', child: Text('Billing')),
          const PopupMenuItem(value: 'expenses', child: Text('Expenses')),
          const PopupMenuItem(value: 'recovery', child: Text('Recovery')),
          const PopupMenuItem(value: 'supplier', child: Text('Supplier Khata')),
          const PopupMenuItem(value: 'reports', child: Text('Reports')),
          const PopupMenuItem(value: 'export', child: Text('Export Reports')),
          const PopupMenuDivider(),
          PopupMenuItem(value: 'signout', child: Text('Sign Out', style: TextStyle(color: cs.error))),
        ],
        onSelected: (v) async {
          if (v == 'signout') await authService.signOut();
          else if (v == 'settings') _push(context, const AccountSettingsScreen());
          else if (v == 'billing') _push(context, const BillingScreen());
          else if (v == 'expenses') _push(context, const ExpenseSheetScreen());
          else if (v == 'recovery') _push(context, const CustomerRecoveryScreen());
          else if (v == 'supplier') Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierKhataScreen()));
          else if (v == 'reports') Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
          else if (v == 'export') Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen()));
        },
      ),
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
        Expanded(child: _StatCard(
          title: 'Revenue', value: 'Rs ${NumberFormat('#,##0').format(d.revenue.toInt())}',
          sub: 'Gross: Rs ${NumberFormat('#,##0').format(d.grossProfit.toInt())}',
          icon: Icons.trending_up_rounded, tint: ac.saleTint, iconColor: ac.saleFg)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          title: 'COGS', value: 'Rs ${NumberFormat('#,##0').format(d.cogs.toInt())}',
          sub: 'Cost of goods sold',
          icon: Icons.receipt_rounded, tint: ac.purchaseTint, iconColor: ac.purchaseFg)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(
          title: 'Gross Profit', value: 'Rs ${NumberFormat('#,##0').format(d.grossProfit.toInt())}',
          sub: 'Revenue \u2212 COGS',
          icon: Icons.account_balance_rounded, tint: ac.profitTint, iconColor: ac.profitFg)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          title: 'Expenses', value: 'Rs ${NumberFormat('#,##0').format(d.totalExpenses.toInt())}',
          sub: 'Total kharcha',
          icon: Icons.trending_down_rounded, tint: ac.expenseTint, iconColor: ac.expenseFg)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(
          title: 'Net Profit', value: 'Rs ${NumberFormat('#,##0').format(d.netProfit.toInt())}',
          sub: 'Margin: ${d.revenue > 0 ? ((d.netProfit / d.revenue) * 100).toStringAsFixed(0) : 0}%',
          icon: Icons.trending_up_rounded, tint: ac.profitTint, iconColor: ac.profitFg)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          title: 'Inventory Value', value: 'Rs ${NumberFormat('#,##0').format(d.inventoryValue.toInt())}',
          sub: '${d.totalProducts} products',
          icon: Icons.inventory_2_rounded, tint: ac.inventoryTint, iconColor: ac.inventoryFg)),
      ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color tint, iconColor;
  const _StatCard({required this.title, required this.value, required this.sub,
    required this.icon, required this.tint, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: iconColor)),
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

void _push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
