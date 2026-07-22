import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/firebase_providers.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/debounce.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  final bool initialLowStockFilter;
  final String? highlightProductId;
  const InventoryScreen({super.key, this.initialLowStockFilter = false, this.highlightProductId});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  bool _didHighlight = false;
  final _searchDebounce = Debouncer();
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialLowStockFilter) _typeFilter = 'Low Stock';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didHighlight && widget.highlightProductId != null) {
      _didHighlight = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final products = ref.read(productsStreamProvider).asData?.value ?? [];
        final product = products.where((p) => p.id == widget.highlightProductId).firstOrNull;
        if (product != null) _showOptions(product);
      });
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); _searchDebounce.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 96 + MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
        key: const ValueKey('add_product_fab'),
        backgroundColor: AppTheme.amber,
        foregroundColor: const Color(0xFF2A1A00),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _addProduct,
        child: const Icon(Icons.add_rounded, size: 22),
      ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.onSurface))),
        data: (products) {
          final query = _searchCtrl.text.toLowerCase();
          var filtered = products.where((p) {
            if (_typeFilter == 'Low Stock' && !p.isLowStock) return false;
            if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) return false;
            return true;
          }).toList();

          final totalValue = products.fold(0.0, (s, p) => s + (p.currentStock * p.costPrice));

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search products\u2026',
                  hintStyle: TextStyle(color: ac.inkFaint, fontSize: 12.5),
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: ac.inkFaint),
                ),
                onChanged: (_) => _searchDebounce.call(() => setState(() {})),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ac.profitTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.account_balance_rounded, size: 16, color: ac.profitFg),
                const SizedBox(width: 8),
                Text('Total Inventory Value: ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ac.profitFg)),
                Text('Rs ${NumberFormat('#,##0').format(totalValue.toInt())}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()], color: ac.profitFg)),
              ]),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', 'Low Stock'].map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _typeFilter = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _typeFilter == t ? AppTheme.teal : cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _typeFilter == t ? AppTheme.teal : cs.outlineVariant),
                      ),
                      child: Text(t, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _typeFilter == t ? Colors.white : cs.onSurfaceVariant,
                      )),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No matching products', style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _ProdCard(
                        product: filtered[i],
                        onTap: () => _showOptions(filtered[i]),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  void _showOptions(Product product) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Edit'), onTap: () { Navigator.pop(ctx); _edit(product); }),
      ListTile(leading: const Icon(Icons.add_shopping_cart_rounded), title: const Text('Restock'), onTap: () { Navigator.pop(ctx); _restock(product); }),
      ListTile(leading: const Icon(Icons.archive_rounded), title: const Text('Archive'), onTap: () async {
        Navigator.pop(ctx);
        await ref.read(firestoreServiceProvider).archiveProduct(product.id);
        if (!mounted) return;
      }),
    ])));
  }

  void _addProduct() {
    _AddProductDialog.show(context, (Product product) {
      final svc = ref.read(firestoreServiceProvider);
      svc.addProduct(product.copyWith(id: svc.generateId())).catchError((_) {});
    });
  }

  void _edit(Product product) {
    _EditProductDialog.show(context, product, (Product updated) {
      ref.read(firestoreServiceProvider).updateProduct(updated).catchError((_) {});
    });
  }

  void _restock(Product product) {
    RestockDialog.show(context, product);
  }
}

class _AddProductDialog extends StatefulWidget {
  final void Function(Product) onSave;
  const _AddProductDialog({required this.onSave});

  static void show(BuildContext context, void Function(Product) onSave) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddProductDialog(
        onSave: (Product p) {
          Navigator.of(context).pop();
          onSave(p);
        },
      ),
    );
  }

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _nc = TextEditingController();
  final _lc = TextEditingController();
  final _wc = TextEditingController();
  final _tc = TextEditingController();
  final _cc = TextEditingController();
  final _sc = TextEditingController();
  final _thc = TextEditingController();

  @override
  void dispose() {
    _nc.dispose();
    _lc.dispose();
    _wc.dispose();
    _tc.dispose();
    _cc.dispose();
    _sc.dispose();
    _thc.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nc.text.trim().isEmpty) return;
    widget.onSave(Product(
      id: '',
      name: _nc.text.trim(),
      type: '',
      sizeLength: double.tryParse(_lc.text) ?? 0,
      sizeWidth: double.tryParse(_wc.text) ?? 0,
      thickness: double.tryParse(_tc.text) ?? 0,
      density: 0,
      unitType: 'per_sqft',
      unitPrice: 0,
      costPrice: double.tryParse(_cc.text) ?? 0,
      currentStock: double.tryParse(_sc.text) ?? 0,
      lowStockThreshold: double.tryParse(_thc.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs2 = Theme.of(context).colorScheme;
    final costPrice = double.tryParse(_cc.text) ?? 0;
    final stock = double.tryParse(_sc.text) ?? 0;
    final totalCost = costPrice * stock;
    return AlertDialog(
      key: const ValueKey('add_product_dialog_modal'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nc, decoration: const InputDecoration(labelText: 'Name', filled: true)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: _lc, decoration: const InputDecoration(labelText: 'Size Length (in)', filled: true), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _wc, decoration: const InputDecoration(labelText: 'Size Width (in)', filled: true), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: _tc, decoration: const InputDecoration(labelText: 'Thickness (in)', filled: true), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _cc, decoration: const InputDecoration(labelText: 'Buy Price / Cost (PKR)', filled: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: _sc, decoration: const InputDecoration(labelText: 'Current Stock', filled: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _thc, decoration: const InputDecoration(labelText: 'Low Stock Threshold', filled: true), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs2.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: Text('Total Cost for this lot: Rs ${totalCost.toStringAsFixed(0)}',
                style: TextStyle(color: cs2.primary, fontWeight: FontWeight.bold, fontFeatures: [FontFeature('tnum')])),
          ),
        ]),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Add Product'),
        ),
      ],
    );
  }
}

class _EditProductDialog extends StatefulWidget {
  final Product product;
  final void Function(Product) onSave;
  const _EditProductDialog({required this.product, required this.onSave});

  static void show(BuildContext context, Product product, void Function(Product) onSave) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditProductDialog(
        product: product,
        onSave: (Product p) {
          Navigator.of(context).pop();
          onSave(p);
        },
      ),
    );
  }

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late final TextEditingController _nc;
  late final TextEditingController _lc;
  late final TextEditingController _wc;
  late final TextEditingController _tc;
  late final TextEditingController _cc;
  late final TextEditingController _sc;
  late final TextEditingController _thc;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nc = TextEditingController(text: p.name);
    _lc = TextEditingController(text: p.sizeLength.toString());
    _wc = TextEditingController(text: p.sizeWidth.toString());
    _tc = TextEditingController(text: p.thickness.toString());
    _cc = TextEditingController(text: p.costPrice.toString());
    _sc = TextEditingController(text: p.currentStock.toString());
    _thc = TextEditingController(text: p.lowStockThreshold.toString());
  }

  @override
  void dispose() {
    _nc.dispose();
    _lc.dispose();
    _wc.dispose();
    _tc.dispose();
    _cc.dispose();
    _sc.dispose();
    _thc.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nc.text.trim().isEmpty) return;
    widget.onSave(widget.product.copyWith(
      name: _nc.text.trim(),
      sizeLength: double.tryParse(_lc.text) ?? widget.product.sizeLength,
      sizeWidth: double.tryParse(_wc.text) ?? widget.product.sizeWidth,
      thickness: double.tryParse(_tc.text) ?? widget.product.thickness,
      costPrice: double.tryParse(_cc.text) ?? widget.product.costPrice,
      currentStock: double.tryParse(_sc.text) ?? widget.product.currentStock,
      lowStockThreshold: double.tryParse(_thc.text) ?? widget.product.lowStockThreshold,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs2 = Theme.of(context).colorScheme;
    final costPrice = double.tryParse(_cc.text) ?? 0;
    final stock = double.tryParse(_sc.text) ?? 0;
    final totalCost = costPrice * stock;
    return AlertDialog(
      key: const ValueKey('edit_product_dialog_modal'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nc, decoration: const InputDecoration(labelText: 'Name', filled: true)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: _lc, decoration: const InputDecoration(labelText: 'Size Length (in)', filled: true), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _wc, decoration: const InputDecoration(labelText: 'Size Width (in)', filled: true), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: _tc, decoration: const InputDecoration(labelText: 'Thickness (in)', filled: true), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _cc, decoration: const InputDecoration(labelText: 'Buy Price / Cost (PKR)', filled: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextField(controller: _sc, decoration: const InputDecoration(labelText: 'Current Stock', filled: true), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _thc, decoration: const InputDecoration(labelText: 'Low Stock Threshold', filled: true), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cs2.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
            child: Text('Total Cost for this lot: Rs ${totalCost.toStringAsFixed(0)}',
                style: TextStyle(color: cs2.primary, fontWeight: FontWeight.bold, fontFeatures: [FontFeature('tnum')])),
          ),
        ]),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('Save Product'),
        ),
      ],
    );
  }
}

class RestockDialog extends StatefulWidget {
  final Product product;
  const RestockDialog({super.key, required this.product});

  static void show(BuildContext context, Product product) {
    final qtyCtrl = TextEditingController(text: '1');
    final unitCostCtrl = TextEditingController(text: product.costPrice.toStringAsFixed(0));
    final paidCtrl = TextEditingController();
    String supplierId = '';
    String supplierName = '';
    bool userEditedPaid = false;

    void recalc() {
      if (userEditedPaid) return;
      final q = double.tryParse(qtyCtrl.text) ?? 0;
      final uc = double.tryParse(unitCostCtrl.text) ?? 0;
      paidCtrl.text = (q * uc) > 0 ? (q * uc).toStringAsFixed(0) : '';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setInnerState) => AlertDialog(
          key: const ValueKey('restock_dialog_modal'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Restock: ${product.name}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current stock: ${product.stockLabel}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Consumer(builder: (context, ref, _) {
                final suppliersAsync = ref.watch(suppliersStreamProvider);
                return suppliersAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (suppliers) => InkWell(
                    onTap: () async {
                      final selected = await showDialog<Supplier>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Select Supplier'),
                          children: [
                            if (supplierId.isNotEmpty)
                              SimpleDialogOption(
                                onPressed: () => Navigator.pop(ctx, Supplier(id: '', name: 'Unknown')),
                                child: const Text('Unknown / In-house'),
                              ),
                            ...suppliers.map((s) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(ctx, s),
                              child: Text(s.name),
                            )),
                          ],
                        ),
                      );
                      if (selected != null) {
                        setInnerState(() { supplierId = selected.id; supplierName = selected.name; });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Row(children: [
                        Icon(Icons.business_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(supplierId.isEmpty ? 'Select Supplier (optional)' : supplierName,
                              style: TextStyle(fontSize: 13, color: supplierId.isEmpty ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface)),
                        ),
                        Icon(Icons.arrow_drop_down_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity (pcs)', filled: true),
                keyboardType: TextInputType.number,
                onChanged: (_) { setInnerState(() { recalc(); }); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitCostCtrl,
                decoration: const InputDecoration(labelText: 'Unit Cost / Buying Price (PKR)', filled: true),
                keyboardType: TextInputType.number,
                onChanged: (_) { setInnerState(() { recalc(); }); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paidCtrl,
                decoration: const InputDecoration(labelText: 'Total Amount Paid (PKR)', filled: true),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setInnerState(() { userEditedPaid = true; });
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Calculated Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rs ${((double.tryParse(qtyCtrl.text) ?? 0) * (double.tryParse(unitCostCtrl.text) ?? 0)).toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16,
                          fontFeatures: [FontFeature('tnum')])),
                ]),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () {
                final q = double.tryParse(qtyCtrl.text) ?? 0;
                final uc = double.tryParse(unitCostCtrl.text) ?? product.costPrice;
                if (q <= 0 || uc <= 0) return;
                final paid = double.tryParse(paidCtrl.text) ?? 0;
                Navigator.of(ctx).pop();
                FirestoreService().restockTransaction(product.id, q, uc, paid, supplierId: supplierId)
                    .catchError((_) {});
              },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Restock'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      qtyCtrl.dispose();
      unitCostCtrl.dispose();
      paidCtrl.dispose();
    });
  }

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ProdCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProdCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final fmt = NumberFormat('#,##0');
    final stockInt = product.currentStock.toInt();
    final unitPrice = fmt.format(product.costPrice.toInt());
    final totalValue = product.currentStock * product.costPrice;
    final totalFmt = fmt.format(totalValue.toInt());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(color: cs.shadow, blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4),
          ],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: ac.inventoryTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.inventory_2_rounded, size: 20, color: ac.inventoryFg),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text('${product.sizeLength.toStringAsFixed(0)}in \u00d7 ${product.sizeWidth.toStringAsFixed(0)}in \u00b7 ${product.thickness.toStringAsFixed(0)}in',
                style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: product.isLowStock ? ac.expenseTint : ac.profitTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(product.isLowStock ? 'Low \u00b7 $stockInt left' : '$stockInt pcs in stock',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: product.isLowStock ? ac.expenseFg : ac.profitFg)),
              ),
              Text('Rs $unitPrice/pc',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5,
                      fontFeatures: const [FontFeature.tabularFigures()], color: cs.onSurface)),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ac.inkFaint)),
                Text('Rs $totalFmt',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.tealDark,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }
}
