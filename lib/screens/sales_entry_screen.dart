import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/sale.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/dashboard_provider.dart';
import '../services/accounting_service.dart';
import '../theme/app_theme.dart';

const double _marginHealthy = 0.20;

class _LineItemEntry {
  Product product;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  _LineItemEntry({
    required this.product,
    TextEditingController? qtyCtrl,
    TextEditingController? priceCtrl,
    TextEditingController? discCtrl,
  })  : qtyCtrl = qtyCtrl ?? TextEditingController(text: '1'),
        priceCtrl = priceCtrl ?? TextEditingController(text: product.unitPrice.toStringAsFixed(0)),
        discCtrl = discCtrl ?? TextEditingController();

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get salePrice => double.tryParse(priceCtrl.text) ?? 0;
  double get lineDisc => double.tryParse(discCtrl.text) ?? 0;
  double get lineTotal => (qty * salePrice) - lineDisc;

  double? get marginRatio =>
      product.costPrice > 0 ? (salePrice - product.costPrice) / product.costPrice : null;

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }
}

class SalesEntryScreen extends ConsumerStatefulWidget {
  final Sale? editSale;
  const SalesEntryScreen({super.key, this.editSale});

  @override
  ConsumerState<SalesEntryScreen> createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends ConsumerState<SalesEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paidCtrl = TextEditingController();
  final _discAmtCtrl = TextEditingController();
  final _discPctCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _cuttingCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;
  List<_LineItemEntry> _items = [];
  bool _isQuote = false;

  // Price history cache
  Map<String, double?> _lastPrices = {};

  @override
  void initState() {
    super.initState();
    if (widget.editSale != null) {
      _loadEditSale(widget.editSale!);
    }
  }

  void _loadEditSale(Sale s) {
    _selectedDate = s.date;
    _paidCtrl.text = s.paid.toStringAsFixed(0);
    final da = s.discountAmount; if (da != null) _discAmtCtrl.text = da.toStringAsFixed(0);
    final dp = s.discountPercent; if (dp != null) _discPctCtrl.text = dp.toStringAsFixed(0);
    final dc = s.deliveryCharge; if (dc != null) _deliveryCtrl.text = dc.toStringAsFixed(0);
    final cc = s.cuttingCharge; if (cc != null) _cuttingCtrl.text = cc.toStringAsFixed(0);
    _isQuote = s.isQuote;
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    _discAmtCtrl.dispose();
    _discPctCtrl.dispose();
    _deliveryCtrl.dispose();
    _cuttingCtrl.dispose();
    _customerCtrl.dispose();
    for (final item in _items) item.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.lineTotal);
  double get _totalDisc => double.tryParse(_discAmtCtrl.text) ?? (_subtotal * (double.tryParse(_discPctCtrl.text) ?? 0) / 100);
  double get _delivery => double.tryParse(_deliveryCtrl.text) ?? 0;
  double get _cutting => double.tryParse(_cuttingCtrl.text) ?? 0;
  double get _totalAmount => _subtotal - _totalDisc + _delivery + _cutting;
  double get _paid => double.tryParse(_paidCtrl.text) ?? 0;
  double get _balance => _totalAmount - _paid;

  Future<void> _addItem() async {
    final products = await ref.read(productsStreamProvider.future);
    if (products.isEmpty) return;

    Product? selected;
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Product'),
      content: DropdownButtonFormField<Product>(
        decoration: const InputDecoration(labelText: 'Select Product'),
        items: products.where((p) => p.currentStock > 0 || _isQuote).map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.stockLabel})'))).toList(),
        onChanged: (v) => selected = v,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (selected != null) Navigator.pop(ctx);
        }, child: const Text('Add')),
      ],
    ));

    if (selected != null) {
      setState(() {
        _items.add(_LineItemEntry(product: selected!));
        _loadPriceHistory(selected!);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _loadPriceHistory(Product product) {
    if (_selectedCustomer == null) return;
    final svc = ref.read(firestoreServiceProvider);
    svc.getCustomerSales(_selectedCustomer!.id).then((sales) {
      for (final s in sales) {
        for (final li in s.lineItems) {
          if (li.productId == product.id && !_lastPrices.containsKey(product.id)) {
            _lastPrices[product.id] = li.salePrice;
            if (mounted) setState(() {});
            return;
          }
        }
      }
    }).catchError((_) {}); // ignore index not found
  }

  void _resetForm() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCustomer = null;
      _customerCtrl.clear();
      _paidCtrl.clear();
      _discAmtCtrl.clear();
      _discPctCtrl.clear();
      _deliveryCtrl.clear();
      _cuttingCtrl.clear();
      _lastPrices = {};
      for (final item in _items) item.dispose();
      _items.clear();
    });
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) return;
    if (_items.isEmpty) return;

    final products = await ref.read(productsStreamProvider.future);
    final accounting = ref.read(accountingServiceProvider);
    final svc = ref.read(firestoreServiceProvider);

    final uuid = widget.editSale?.transactionUuid ?? DateTime.now().microsecondsSinceEpoch.toString();

    // Idempotency check for new sales
    if (widget.editSale == null) {
      final exists = await svc.saleExistsByUuid(uuid);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale already recorded')),
          );
        }
        return;
      }
    }

    try {
      final productMap = {for (final p in products) p.id: p};
      final sale = Sale(
        id: widget.editSale?.id ?? svc.generateId(),
        date: _selectedDate,
        customerId: _selectedCustomer!.id,
        lineItems: _items.map((i) {
          final prod = productMap[i.product.id];
          return SaleLineItem(
            productId: i.product.id,
            customLength: null,
            customWidth: null,
            qtyOrArea: i.qty,
            salePrice: i.salePrice,
            lineDiscountAmount: i.lineDisc,
            costPriceAtSale: prod?.costPrice ?? 0,
          );
        }).toList(),
        paid: _paid,
        discountAmount: double.tryParse(_discAmtCtrl.text),
        discountPercent: double.tryParse(_discPctCtrl.text),
        deliveryCharge: _delivery > 0 ? _delivery : null,
        cuttingCharge: _cutting > 0 ? _cutting : null,
        isQuote: _isQuote,
        transactionUuid: uuid,
      );

      if (!_isQuote) {
        final error = accounting.validateSale(sale, products);
        if (error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
          return;
        }

        // Compute net stock deductions (new qty - old qty per product)
        final deductions = <String, double>{};
        for (final item in _items) {
          deductions.update(item.product.id, (v) => v + item.qty, ifAbsent: () => item.qty);
        }
        if (widget.editSale != null) {
          for (final li in widget.editSale!.lineItems) {
            deductions.update(li.productId, (v) => v - li.qtyOrArea, ifAbsent: () => -li.qtyOrArea);
          }
        }
        deductions.removeWhere((_, v) => v == 0);

        await svc.saveSaleTransaction(sale, deductions);
      } else {
        if (widget.editSale != null) {
          await svc.updateSale(sale);
        } else {
          await svc.addSale(sale);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isQuote ? 'Quote saved' : 'Sale recorded')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final style = Theme.of(context).textTheme;
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editSale != null ? 'Edit Sale' : (_isQuote ? 'New Quote' : 'New Sale')),
        actions: [
          if (widget.editSale == null)
            TextButton(
              onPressed: () => setState(() => _isQuote = !_isQuote),
              child: Text(_isQuote ? 'Switch to Sale' : 'Switch to Quote', style: TextStyle(fontSize: 12, color: cs.primary)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Date
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final p = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (p != null) setState(() => _selectedDate = p);
              },
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.teal),
                  const SizedBox(width: 10),
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: style.bodyLarge),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            // Customer
            Row(children: [
              Expanded(child: customersAsync.when(
                data: (cl) => Autocomplete<Customer>(
                  optionsBuilder: (t) => t.text.isEmpty ? cl : cl.where((c) => c.name.toLowerCase().contains(t.text.toLowerCase())),
                  displayStringForOption: (c) => c.name,
                  onSelected: (c) => setState(() { _selectedCustomer = c; _lastPrices = {}; }),
                  fieldViewBuilder: (ctx, ctrl, fn, onSubmit) => TextFormField(
                    controller: ctrl, focusNode: fn,
                    decoration: const InputDecoration(labelText: 'Customer', filled: true),
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: (_) => _selectedCustomer == null ? 'Required' : null,
                  ),
                ),
                loading: () => const TextField(enabled: false, decoration: InputDecoration(labelText: 'Customer', filled: true)),
                error: (e, _) => Text('Error: $e', style: TextStyle(color: cs.onSurface)),
              )),
              const SizedBox(width: 8),
              IconButton(onPressed: _addCustomer, icon: const Icon(Icons.person_add_rounded), style: IconButton.styleFrom(backgroundColor: cs.primaryContainer)),
            ]),
            const SizedBox(height: 14),
            // Line items
            ..._items.asMap().entries.map((entry) => _buildLineItem(entry.key, entry.value)),
            // Add item button
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: cs.outlineVariant, width: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            // Discounts
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Discounts & Charges', style: style.titleSmall?.copyWith(fontSize: 13)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: _discAmtCtrl, decoration: const InputDecoration(labelText: 'Discount (PKR)', filled: true, isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 8),
                  Text('or', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  SizedBox(width: 80, child: TextField(controller: _discPctCtrl, decoration: const InputDecoration(labelText: '%', filled: true, isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: _deliveryCtrl, decoration: const InputDecoration(labelText: 'Delivery Charge', filled: true, isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _cuttingCtrl, decoration: const InputDecoration(labelText: 'Cutting Charge', filled: true, isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            // Totals
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant)),
              child: Column(children: [
                _totalRow('Subtotal', _subtotal, false),
                if (_totalDisc > 0) _totalRow('Discount', -_totalDisc, false),
                if (_delivery > 0) _totalRow('Delivery', _delivery, false),
                if (_cutting > 0) _totalRow('Cutting', _cutting, false),
                const Divider(height: 16),
                _totalRow('Total', _totalAmount, true),
                const SizedBox(height: 8),
                TextField(controller: _paidCtrl, decoration: const InputDecoration(labelText: 'Paid (PKR)', filled: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
                if (_balance != 0)
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('Balance: Rs. ${_balance.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _balance > 0 ? ac.expenseFg : ac.profitFg))),
              ]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isQuote ? Icons.description_rounded : Icons.save_rounded),
              label: Text(_isQuote ? 'Save Quote' : (widget.editSale != null ? 'Update Sale' : 'Save Sale')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(int index, _LineItemEntry item) {
    final ac = AppColors.of(context);
    final cs = Theme.of(context).colorScheme;
    final ratio = item.marginRatio;
    Color? marginColor;
    String? marginLabel;
    if (ratio != null) {
      if (ratio >= _marginHealthy) {
        marginColor = ac.profitFg;
        marginLabel = 'Good margin';
      } else if (ratio > 0) {
        marginColor = ac.purchaseFg;
        marginLabel = 'Thin margin';
      } else {
        marginColor = ac.expenseFg;
        marginLabel = 'At cost';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.product.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface))),
          IconButton(onPressed: () => _removeItem(index), icon: const Icon(Icons.close_rounded, size: 18), visualDensity: VisualDensity.compact),
        ]),
        if (_lastPrices[item.product.id] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Last paid: Rs. ${_lastPrices[item.product.id]!.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: ac.inkFaint)),
          ),
        TextField(
          controller: item.qtyCtrl,
          decoration: InputDecoration(
            labelText: item.product.unitType == 'per_sqft' ? 'Area (sq.ft)' : 'Quantity',
            filled: true, isDense: true,
          ),
          keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: item.priceCtrl,
            decoration: InputDecoration(labelText: 'Sale Price (PKR)', filled: true, isDense: true,
              suffixIcon: marginLabel != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: marginColor, shape: BoxShape.circle)),
                        const SizedBox(width: 3),
                        Text(marginLabel, style: TextStyle(fontSize: 9, color: marginColor, fontWeight: FontWeight.w600)),
                      ]),
                    )
                  : null,
            ),
            keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
          )),
        ]),
        TextField(
          controller: item.discCtrl,
          decoration: const InputDecoration(labelText: 'Line Discount (PKR)', filled: true, isDense: true),
          keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Line total: Rs. ${item.lineTotal.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        ),
      ]),
    );
  }

  Widget _totalRow(String label, double amount, bool bold) {
    final cs2 = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: cs2.onSurfaceVariant)),
        Text('Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 15 : 13, fontFeatures: [FontFeature('tnum')], color: cs2.onSurface)),
      ]),
    );
  }

  void _addCustomer() {
    final nc = TextEditingController(); final pc = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Customer'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nc, decoration: const InputDecoration(labelText: 'Name', filled: true)),
        const SizedBox(height: 8),
        TextField(controller: pc, decoration: const InputDecoration(labelText: 'Phone', filled: true), keyboardType: TextInputType.phone),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (nc.text.trim().isEmpty) return;
          final s = ref.read(firestoreServiceProvider);
          final c = Customer(id: s.generateId(), name: nc.text.trim(), phone: pc.text.trim());
          await s.addCustomer(c);
          setState(() => _selectedCustomer = c);
          _customerCtrl.text = c.name;
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    )).then((_) { nc.dispose(); pc.dispose(); });
  }
}
