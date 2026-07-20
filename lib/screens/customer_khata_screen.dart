import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../providers/customer_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class CustomerKhataScreen extends ConsumerWidget {
  const CustomerKhataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final customersAsync = ref.watch(customersStreamProvider);
    final salesAsync = ref.watch(salesStreamProvider);
    final paymentsAsync = ref.watch(paymentsStreamProvider);

    final combined = customersAsync.when(
      data: (csList) => salesAsync.when(
        data: (sales) => paymentsAsync.when(
          data: (payments) => csList.map((c) {
            final cSales = sales.where((s) => s.customerId == c.id);
            final cPayments = payments.where((p) => p.customerId == c.id);
            final total = cSales.fold(0.0, (s, x) => s + x.amount);
            final recv = cPayments.fold(0.0, (s, x) => s + x.amountCollected);
            return _CustBal(customer: c, balance: total - recv);
          }).toList(),
          loading: () => null, error: (_, __) => null,
        ),
        loading: () => null, error: (_, __) => null,
      ),
      loading: () => null, error: (e, _) => <_CustBal>[],
    );

    if (combined == null) {
      return Scaffold(appBar: AppBar(title: const Text('Customer Khata')),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Khata')),
      body: combined.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline_rounded, size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('No customers yet', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: combined.length,
              itemBuilder: (_, i) {
                final item = combined[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => _CustDetail(customer: item.customer))),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: item.balance > 0 ? ac.expenseTint : ac.profitTint,
                            child: Text(item.customer.name[0].toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.w700,
                                    color: item.balance > 0 ? ac.expenseFg : ac.profitFg)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.customer.name,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                              if (item.customer.phone.isNotEmpty)
                                Text(item.customer.phone,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          )),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('Rs. ${item.balance.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700, fontFeatures: [FontFeature('tnum')],
                                    color: item.balance > 0 ? ac.expenseFg : ac.profitFg)),
                            Text(item.balance <= 0 ? 'Clear' : 'Baqaya',
                                style: TextStyle(fontSize: 11, color: item.balance > 0 ? ac.expenseFg : ac.profitFg)),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CustBal {
  final Customer customer; final double balance;
  const _CustBal({required this.customer, required this.balance});
}

class _CustDetail extends ConsumerWidget {
  final Customer customer;
  const _CustDetail({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final salesAsync = ref.watch(salesStreamProvider);
    final paymentsAsync = ref.watch(paymentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
      ),
      body: salesAsync.when(
        data: (sales) => paymentsAsync.when(
          data: (payments) {
            final cSales = sales.where((s) => s.customerId == customer.id);
            final cPayments = payments.where((p) => p.customerId == customer.id);
            final total = cSales.fold(0.0, (s, x) => s + x.amount);
            final recv = cPayments.fold(0.0, (s, x) => s + x.amountCollected);
            final balance = total - recv;

            final txns = <_Txn>[
              ...cSales.map((s) => _Txn(date: s.date, desc: 'Sale — Diamond Foam', isSale: true, amount: s.amount)),
              ...cPayments.map((p) => _Txn(date: p.date, desc: 'Payment Collected', isSale: false, amount: p.amountCollected)),
            ];
            txns.sort((a, b) => b.date.compareTo(a.date));

            return Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: ac.expenseTint,
                child: Column(children: [
                  Text('Outstanding Baqaya',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.05, color: ac.expenseFg)),
                  const SizedBox(height: 4),
                  Text('Rs. ${balance.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, fontFeatures: [FontFeature('tnum')], color: ac.expenseFg)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        shadowColor: AppTheme.teal.withValues(alpha: 0.3),
                      ),
                      onPressed: () => _collectPayment(context, ref, customer),
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: const Text('Collect Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Transaction History',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.06, color: cs.onSurfaceVariant)),
                ),
              ),
              Expanded(child: txns.isEmpty
                  ? Center(child: Text('No transactions', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: txns.length,
                      itemBuilder: (_, i) {
                        final t = txns[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cs.outlineVariant),
                            boxShadow: [BoxShadow(color: cs.shadow, blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4)],
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t.desc,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurface)),
                                const SizedBox(height: 1),
                                Text('${t.date.day}/${t.date.month}/${t.date.year}',
                                    style: TextStyle(fontSize: 10.5, color: ac.inkFaint)),
                              ]),
                            ),
                            Text(
                              '${t.isSale ? '+' : '-'} Rs. ${t.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFeatures: [FontFeature('tnum')],
                                color: t.isSale ? ac.expenseFg : ac.profitFg,
                              ),
                            ),
                          ]),
                        );
                      },
                    )),
            ]);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.onSurface))),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.onSurface))),
      ),
    );
  }
}

void _collectPayment(BuildContext context, WidgetRef ref, Customer customer) {
  final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Collect Payment'),
    content: SingleChildScrollView(child: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Amount (PKR)', filled: true), keyboardType: TextInputType.number)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      FilledButton(onPressed: () async {
        final amt = double.tryParse(ctrl.text) ?? 0;
        if (amt <= 0) return;
        final s = ref.read(firestoreServiceProvider);
        await s.savePaymentTransaction(Payment(
            id: s.generateId(), date: DateTime.now(), customerId: customer.id, amountCollected: amt));
        ref.invalidate(accountingSummaryProvider);
        if (ctx.mounted) Navigator.pop(ctx);
      }, child: const Text('Save')),
    ],
  )).then((_) => ctrl.dispose());
}

class _Txn {
  final DateTime date; final String desc; final bool isSale; final double amount;
  const _Txn({required this.date, required this.desc, required this.isSale, required this.amount});
}
