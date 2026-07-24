import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart' show Sale;
import '../models/product.dart' show Product;
import '../models/expense.dart' show Expense;
import '../models/payment.dart' show Payment;
import '../models/supplier_payment.dart' show SupplierPayment;
import '../models/opening_balance.dart' show OpeningBalance;
import '../services/accounting_service.dart' show AccountingSummary;
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/sale_provider.dart';
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
  final VoidCallback? onLowStockTap;
  const DashboardScreen({super.key, this.onLowStockTap});

  static final _dateFormat = DateFormat('EEEE, d MMMM yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final as = ref.watch(accountingSummaryProvider);
    final salesAsync = ref.watch(salesStreamProvider);
    final salesCount = salesAsync.asData?.value.length ?? 0;
    final slipNumber = (salesCount + 1).toString().padLeft(4, '0');
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: as.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load dashboard')),
        data: (d) => SafeArea(
          top: true,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 96 + bottom),
            children: [
              const _GreetHeader(),
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
                stubRight: '#$slipNumber',
              ),
              const StitchedDivider(margin: EdgeInsets.symmetric(vertical: 14)),
              _StatGrid(summary: d),
              const StitchedDivider(margin: EdgeInsets.symmetric(vertical: 14)),
              if (d.lowStockCount > 0)
                _LowStockAlert(count: d.lowStockCount, onTap: onLowStockTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetHeader extends ConsumerWidget {
  const _GreetHeader();

  static final _dateStr = _GreetHeader._formatDate();

  static String _formatDate() {
    final now = DateTime.now();
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
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
            Text(_dateStr, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
          backgroundImage: user != null && user.photoURL != null ? NetworkImage(user.photoURL!) : null,
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
          else if (v == 'supplier') _push(context, const SupplierKhataScreen());
          else if (v == 'reports') _push(context, const ReportsScreen());
          else if (v == 'export') _push(context, const ExportScreen());
        },
      ),
    ]);
  }
}

class _StatGrid extends StatelessWidget {
  final AccountingSummary summary;
  const _StatGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final s = summary;
    return Column(children: [
      Row(children: [
        Expanded(child: _StatCard(
          title: 'Revenue', value: 'Rs ${NumberFormat('#,##0').format(s.revenue.toInt())}',
          sub: 'Gross: Rs ${NumberFormat('#,##0').format(s.grossProfit.toInt())}',
          icon: Icons.trending_up_rounded, tint: ac.saleTint, iconColor: ac.saleFg)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          title: 'COGS', value: 'Rs ${NumberFormat('#,##0').format(s.cogs.toInt())}',
          sub: 'Cost of goods sold',
          icon: Icons.receipt_rounded, tint: ac.purchaseTint, iconColor: ac.purchaseFg)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(
          title: 'Gross Profit', value: 'Rs ${NumberFormat('#,##0').format(s.grossProfit.toInt())}',
          sub: 'Revenue − COGS',
          icon: Icons.account_balance_rounded, tint: ac.profitTint, iconColor: ac.profitFg)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          title: 'Expenses', value: 'Rs ${NumberFormat('#,##0').format(s.totalExpenses.toInt())}',
          sub: 'Total kharcha',
          icon: Icons.trending_down_rounded, tint: ac.expenseTint, iconColor: ac.expenseFg)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(
          title: 'Net Profit', value: 'Rs ${NumberFormat('#,##0').format(s.netProfit.toInt())}',
          sub: 'Margin: ${s.revenue > 0 ? ((s.netProfit / s.revenue) * 100).toStringAsFixed(0) : 0}%',
          icon: Icons.trending_up_rounded, tint: ac.profitTint, iconColor: ac.profitFg)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          title: 'Inventory Value', value: 'Rs ${NumberFormat('#,##0').format(s.inventoryValue.toInt())}',
          sub: '${s.totalProducts} products',
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
        Text(sub, style: TextStyle(fontSize: 9.5, color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _LowStockAlert extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _LowStockAlert({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          Expanded(child: Text('$count ${count == 1 ? 'item' : 'items'} low on stock',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ac.purchaseFg))),
          Icon(Icons.chevron_right_rounded, size: 18, color: ac.inkFaint),
        ]),
      ),
    );
  }
}

void _push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));