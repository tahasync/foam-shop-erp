import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/payment.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class CartWidget extends ConsumerWidget {
  final CartItem item;
  const CartWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final priceCtrl = TextEditingController(text: item.salePrice.toStringAsFixed(0));
    final total = item.lineTotal;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(item.product.name,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface)),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ref.read(salesProvider.notifier).removeFromCart(item.product.id),
            child: Container(width: 24, height: 24, alignment: Alignment.center,
                child: Text('\u2715', style: TextStyle(fontSize: 12, color: ac.inkFaint))),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(
            width: 90,
            child: TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature('tnum')], color: cs.onSurface),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outlineVariant)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.outlineVariant)),
              ),
              onChanged: (val) {
                final newPrice = double.tryParse(val) ?? 0;
                ref.read(salesProvider.notifier).updateItemPrice(item.product.id, newPrice);
              },
            ),
          ),
          const SizedBox(width: 6),
          Text('Rs/unit', style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => ref.read(salesProvider.notifier).changeQty(item.product.id, -1),
                child: Container(width: 28, height: 28, alignment: Alignment.center,
                    child: Text('\u2212', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant))),
              ),
              SizedBox(
                width: 24,
                child: Text('${item.quantity}', textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface)),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: item.quantity < item.product.currentStock
                    ? () => ref.read(salesProvider.notifier).changeQty(item.product.id, 1)
                    : null,
                child: Container(width: 28, height: 28, alignment: Alignment.center,
                    child: Text('+', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant))),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text('Rs ${total.toStringAsFixed(0)}', textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14,
                    fontFeatures: [FontFeature('tnum')], color: cs.onSurface)),
          ),
        ]),
      ]),
    );
  }
}

class SalesEntryScreen extends ConsumerStatefulWidget {
  const SalesEntryScreen({super.key});
  @override
  ConsumerState<SalesEntryScreen> createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends ConsumerState<SalesEntryScreen> {
  final _paidCtrl = TextEditingController(text: '0');

  @override
  void dispose() { _paidCtrl.dispose(); super.dispose(); }

  void _changeCustomer() {
    final ctrl = TextEditingController(text: ref.read(salesProvider).customerName);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      key: const ValueKey('change_customer_dialog'),
      title: const Text('Customer'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name', filled: true)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (ctrl.text.trim().isNotEmpty) {
            ref.read(salesProvider.notifier).setCustomer(ctrl.text.trim());
          }
          Navigator.pop(ctx);
        }, child: const Text('Set')),
      ],
    )).then((_) => ctrl.dispose());
  }

  Future<void> _save({required bool isQuote}) async {
    final state = ref.read(salesProvider);
    if (state.cart.isEmpty) return;

    final svc = ref.read(firestoreServiceProvider);
    final products = await ref.read(productsStreamProvider.future);
    if (!mounted) return;
    final productMap = {for (final p in products) p.id: p};

    final subtotal = state.subtotal;
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final balance = (subtotal - paid).clamp(0, double.infinity);

    final lineItems = state.cart.map((c) {
      final prod = productMap[c.product.id];
      return SaleLineItem(
        productId: c.product.id,
        name: c.product.name,
        qtyOrArea: c.quantity.toDouble(),
        salePrice: c.salePrice,
        costPriceAtSale: prod?.costPrice ?? 0,
      );
    }).toList();

    final saleId = svc.generateId();
    final sale = Sale(
      id: saleId,
      date: DateTime.now(),
      customerId: state.customerName,
      customerName: state.customerName,
      lineItems: lineItems,
      paid: paid,
      isQuote: isQuote,
    );

    if (!isQuote) {
      final deductions = <String, double>{};
      for (final c in state.cart) {
        deductions[c.product.id] = c.quantity.toDouble();
      }
      await svc.saveSaleTransaction(sale, deductions);

      if (paid > 0) {
        await svc.addPayment(Payment(
          id: svc.generateId(),
          date: DateTime.now(),
          customerId: state.customerName,
          amountCollected: paid,
        ));
      }
    } else {
      await svc.addSale(sale);
    }
    if (!mounted) return;

    ref.invalidate(accountingSummaryProvider);
    ref.read(salesProvider.notifier).clearCart();
    _paidCtrl.text = '0';

    final itemsSummary = state.cart.map((c) =>
        '  ${c.product.name} \u00d7${c.quantity} = Rs ${c.lineTotal.toStringAsFixed(0)}').join('\n');
    final msg = '${isQuote ? 'Quote' : 'Sale'} saved!\n'
        'Customer: ${state.customerName}\n'
        'Items: ${state.totalItems}\n'
        'Total: Rs ${subtotal.toStringAsFixed(0)}\n'
        'Paid: Rs ${paid.toStringAsFixed(0)}\n'
        'Balance: Rs ${balance.toStringAsFixed(0)}\n'
        '---\n$itemsSummary';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final salesState = ref.watch(salesProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final balance = (salesState.subtotal - paid).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Customer Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: ac.saleTint, borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.person_rounded, size: 20, color: ac.saleFg),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(salesState.customerName,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface)),
                Text('Change customer', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ])),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _changeCustomer,
                child: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Products
          Text('Select Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant, letterSpacing: 0.06)),
          const SizedBox(height: 8),
          productsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.onSurface))),
            data: (products) => Column(children: products.map((p) => GestureDetector(
              onTap: () {
                if (p.currentStock <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Out of stock!')),
                  );
                  return;
                }
                ref.read(salesProvider.notifier).addToCart(p);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: ac.inventoryTint, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.inventory_2_rounded, size: 18, color: ac.inventoryFg),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface)),
                    Text('${p.sizeLength.toStringAsFixed(0)}in \u00d7 ${p.sizeWidth.toStringAsFixed(0)}in \u00b7 ${p.thickness.toStringAsFixed(0)}in',
                        style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                    Text('${p.stockLabel} left',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ac.inkFaint)),
                  ])),
                  Text('Rs ${p.effectivePrice.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                          fontFeatures: [FontFeature('tnum')], color: cs.onSurface)),
                ]),
              ),
            )).toList()),
          ),
          const SizedBox(height: 10),

          // Cart
          Row(children: [
            Text('Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant, letterSpacing: 0.06)),
            if (salesState.totalItems > 0)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: ac.expenseTint, borderRadius: BorderRadius.circular(999)),
                child: Text('${salesState.totalItems}',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: ac.expenseFg)),
              ),
          ]),
          const SizedBox(height: 8),
          if (salesState.cart.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.shopping_cart_outlined, size: 36, color: ac.inkFaint),
                const SizedBox(height: 8),
                Text('No items added yet.', style: TextStyle(color: ac.inkFaint, fontSize: 13)),
                Text('Tap a product above to add', style: TextStyle(fontSize: 12, color: ac.inkFaint)),
              ]),
            )
          else
            ...salesState.cart.map((c) => CartWidget(key: ValueKey(c.product.id), item: c)),

          const SizedBox(height: 12),

          // Totals
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Subtotal', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                Text('Rs ${salesState.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature('tnum')], color: cs.onSurface)),
              ]),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total Amount', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
                Text('Rs ${salesState.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature('tnum')], color: ac.saleFg)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Paid & Balance
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Paid (PKR)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: TextField(
                    controller: _paidCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature('tnum')], color: cs.onSurface),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Balance', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: ac.saleTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Text('Rs ${balance.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14,
                            fontFeatures: [FontFeature('tnum')], color: ac.saleFg)),
                  ]),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),

          // Save Sale button
          FilledButton.icon(
            onPressed: salesState.cart.isEmpty ? null : () => _save(isQuote: false),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: salesState.cart.isEmpty ? null : () => _save(isQuote: true),
            child: Text('Save as Quote',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
