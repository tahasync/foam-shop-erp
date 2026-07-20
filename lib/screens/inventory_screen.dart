import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/firebase_providers.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _typeFilter = 'All';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: SizedBox(
        width: 46, height: 46,
        child: FloatingActionButton(
          key: const ValueKey('add_product_fab'),
          backgroundColor: AppTheme.amber,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onPressed: _addProduct,
          child: const Icon(Icons.add_rounded, size: 22),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.onSurface))),
        data: (products) {
          var filtered = products.where((p) {
            if (_typeFilter == 'Low Stock' && !p.isLowStock) return false;
            if (_searchCtrl.text.isNotEmpty && !p.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())) return false;
            return true;
          }).toList();

          final totalValue = products.fold(0.0, (s, p) => s + (p.currentStock * p.costPrice));

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search products\u2026',
                    hintStyle: TextStyle(color: ac.inkFaint, fontSize: 12.5),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: ac.inkFaint),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
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
                Text('Rs ${totalValue.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature('tnum')], color: ac.profitFg)),
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
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddProductDialog(
        onSave: (Product product) async {
          final svc = ref.read(firestoreServiceProvider);
          await svc.addProduct(product.copyWith(id: svc.generateId()));
        },
      ),
    );
  }

  void _edit(Product product) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditProductDialog(
        product: product,
        onSave: (Product updated) async {
          await ref.read(firestoreServiceProvider).updateProduct(updated);
        },
      ),
    );
  }

  void _restock(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RestockDialog(key: const ValueKey('restock_dialog_modal'), product: product),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  final Future<void> Function(Product product) onSave;
  const _AddProductDialog({required this.onSave});

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
  bool _saving = false;

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

  Future<void> _submit() async {
    if (_saving) return;
    if (_nc.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await widget.onSave(Product(
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
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
    }
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
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_saving ? 'Saving...' : 'Add Product'),
        ),
      ],
    );
  }
}

class _EditProductDialog extends StatefulWidget {
  final Product product;
  final Future<void> Function(Product product) onSave;
  const _EditProductDialog({required this.product, required this.onSave});

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
  bool _saving = false;

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

  Future<void> _submit() async {
    if (_saving) return;
    if (_nc.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await widget.onSave(widget.product.copyWith(
        name: _nc.text.trim(),
        sizeLength: double.tryParse(_lc.text) ?? widget.product.sizeLength,
        sizeWidth: double.tryParse(_wc.text) ?? widget.product.sizeWidth,
        thickness: double.tryParse(_tc.text) ?? widget.product.thickness,
        costPrice: double.tryParse(_cc.text) ?? widget.product.costPrice,
        currentStock: double.tryParse(_sc.text) ?? widget.product.currentStock,
        lowStockThreshold: double.tryParse(_thc.text) ?? widget.product.lowStockThreshold,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
    }
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
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_saving ? 'Saving...' : 'Save Product'),
        ),
      ],
    );
  }
}

class RestockDialog extends StatefulWidget {
  final Product product;
  const RestockDialog({super.key, required this.product});

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCostCtrl;
  late TextEditingController _paidCtrl;
  bool _userEditedPaid = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _unitCostCtrl = TextEditingController(text: widget.product.costPrice.toStringAsFixed(0));
    _paidCtrl = TextEditingController();
    _recalc();
    _qtyCtrl.addListener(_onFieldChanged);
    _unitCostCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_userEditedPaid) _recalc();
  }

  void _recalc() {
    final q = double.tryParse(_qtyCtrl.text) ?? 0;
    final uc = double.tryParse(_unitCostCtrl.text) ?? 0;
    _paidCtrl.text = (q * uc) > 0 ? (q * uc).toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_onFieldChanged);
    _unitCostCtrl.removeListener(_onFieldChanged);
    _qtyCtrl.dispose();
    _unitCostCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  double get _total => (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_unitCostCtrl.text) ?? 0);

  Future<void> _submit() async {
    final q = double.tryParse(_qtyCtrl.text) ?? 0;
    if (q <= 0) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final uc = double.tryParse(_unitCostCtrl.text) ?? widget.product.costPrice;
      final paid = double.tryParse(_paidCtrl.text) ?? 0;
      final svc = FirestoreService();
      await svc.restockTransaction(widget.product.id, q, uc, paid);
      if (!mounted) return;
      Navigator.pop(context);
    } on Exception {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const ValueKey('restock_dialog_modal'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Restock: ${widget.product.name}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Current stock: ${widget.product.stockLabel}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyCtrl,
            decoration: const InputDecoration(labelText: 'Quantity (pcs)', filled: true),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitCostCtrl,
            decoration: const InputDecoration(labelText: 'Unit Cost / Buying Price (PKR)', filled: true),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paidCtrl,
            decoration: const InputDecoration(labelText: 'Total Amount Paid (PKR)', filled: true),
            keyboardType: TextInputType.number,
            onChanged: (_) {
              _userEditedPaid = true;
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Calculated Total:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Rs ${_total.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16,
                      fontFeatures: [FontFeature('tnum')])),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_shopping_cart_rounded),
          label: Text(_submitting ? 'Restocking...' : 'Restock'),
        ),
      ],
    );
  }
}

class _ProdCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProdCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final totalValue = product.currentStock * product.costPrice;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [BoxShadow(color: cs.shadow, blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4)],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: ac.inventoryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_rounded, size: 20, color: ac.inventoryFg),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text('${product.sizeLength.toStringAsFixed(0)}in \u00d7 ${product.sizeWidth.toStringAsFixed(0)}in \u00b7 ${product.thickness.toStringAsFixed(0)}in',
                style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: product.isLowStock ? ac.expenseTint : ac.profitTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(product.isLowStock ? 'Low \u00b7 ${product.stockLabel} left' : '${product.stockLabel} in stock',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                        color: product.isLowStock ? ac.expenseFg : ac.profitFg)),
              ),
              Text('Rs ${product.costPrice.toStringAsFixed(0)}/pc',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, fontFeatures: [FontFeature('tnum')], color: cs.onSurface)),
            ]),
            const SizedBox(height: 4),
            Text('Total Value: Rs ${totalValue.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.primary,
                    fontFeatures: [FontFeature('tnum')])),
          ])),
        ]),
      ),
    );
  }
}
