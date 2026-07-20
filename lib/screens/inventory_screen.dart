import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/firebase_providers.dart';
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
            if (_typeFilter != 'All' && _typeFilter != 'Low Stock' && p.type != _typeFilter) return false;
            if (_searchCtrl.text.isNotEmpty && !p.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())) return false;
            return true;
          }).toList();

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
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', 'Foam', 'Mattress', 'Sponge', 'Low Stock'].map((t) => Padding(
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
      }),
    ])));
  }

  void _addProduct() {
    final fk = GlobalKey<FormState>();
    String name = '', type = 'Foam', unitType = 'per_piece';
    double sl = 0, sw = 0, th = 0, de = 0, up = 0, cp = 0, cs = 0, lt = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Product'),
      content: SingleChildScrollView(child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(decoration: const InputDecoration(labelText: 'Name', filled: true), onSaved: (v) => name = v ?? '',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Type', filled: true),
            items: 'Foam,Mattress,Sponge,Pillow,Custom Cut'.split(',').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => type = v ?? 'Foam'),
        DropdownButtonFormField<String>(initialValue: unitType, decoration: const InputDecoration(labelText: 'Unit Type', filled: true),
            items: const [DropdownMenuItem(value: 'per_piece', child: Text('Per Piece')), DropdownMenuItem(value: 'per_sqft', child: Text('Per Sq.ft'))],
            onChanged: (v) => unitType = v ?? 'per_piece'),
        TextFormField(decoration: const InputDecoration(labelText: 'Size Length (in)', filled: true), keyboardType: TextInputType.number, onSaved: (v) => sl = double.tryParse(v ?? '') ?? 0),
        TextFormField(decoration: const InputDecoration(labelText: 'Size Width (in)', filled: true), keyboardType: TextInputType.number, onSaved: (v) => sw = double.tryParse(v ?? '') ?? 0),
        TextFormField(decoration: const InputDecoration(labelText: 'Thickness', filled: true), keyboardType: TextInputType.number, onSaved: (v) => th = double.tryParse(v ?? '') ?? 0),
        TextFormField(decoration: const InputDecoration(labelText: 'Density', filled: true), keyboardType: TextInputType.number, onSaved: (v) => de = double.tryParse(v ?? '') ?? 0),
        TextFormField(decoration: const InputDecoration(labelText: 'Buy Price / Cost (PKR)', filled: true), keyboardType: TextInputType.number, onSaved: (v) => cp = double.tryParse(v ?? '') ?? 0),
        TextFormField(decoration: const InputDecoration(labelText: 'Sell Price (PKR)', filled: true), keyboardType: TextInputType.number, onSaved: (v) => up = double.tryParse(v ?? '') ?? 0,
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid price' : null),
        TextFormField(decoration: const InputDecoration(labelText: 'Current Stock', filled: true), keyboardType: TextInputType.number, onSaved: (v) => cs = double.tryParse(v ?? '') ?? 0),
        TextFormField(decoration: const InputDecoration(labelText: 'Low Stock Threshold', filled: true), keyboardType: TextInputType.number, onSaved: (v) => lt = double.tryParse(v ?? '') ?? 0),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!fk.currentState!.validate()) return;
          fk.currentState!.save();
          final svc = ref.read(firestoreServiceProvider);
          await svc.addProduct(Product(id: svc.generateId(), name: name, type: type,
              sizeLength: sl, sizeWidth: sw, thickness: th, density: de,
              unitType: unitType, unitPrice: up, costPrice: cp,
              currentStock: cs, lowStockThreshold: lt));
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  void _edit(Product product) {
    final fk = GlobalKey<FormState>();
    String name = product.name, type = product.type, unitType = product.unitType;
    double sl = product.sizeLength, sw = product.sizeWidth, th = product.thickness;
    double de = product.density, up = product.unitPrice, cp = product.costPrice, lt = product.lowStockThreshold;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit Product'),
      content: SingleChildScrollView(child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(initialValue: name, decoration: const InputDecoration(labelText: 'Name', filled: true), onSaved: (v) => name = v ?? name),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Type', filled: true),
            items: 'Foam,Mattress,Sponge,Pillow,Custom Cut'.split(',').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => type = v ?? type),
        DropdownButtonFormField<String>(initialValue: unitType, decoration: const InputDecoration(labelText: 'Unit Type', filled: true),
            items: const [DropdownMenuItem(value: 'per_piece', child: Text('Per Piece')), DropdownMenuItem(value: 'per_sqft', child: Text('Per Sq.ft'))],
            onChanged: (v) => unitType = v ?? unitType),
        TextFormField(initialValue: sl.toString(), decoration: const InputDecoration(labelText: 'Size Length', filled: true), keyboardType: TextInputType.number, onSaved: (v) => sl = double.tryParse(v ?? '') ?? sl),
        TextFormField(initialValue: sw.toString(), decoration: const InputDecoration(labelText: 'Size Width', filled: true), keyboardType: TextInputType.number, onSaved: (v) => sw = double.tryParse(v ?? '') ?? sw),
        TextFormField(initialValue: th.toString(), decoration: const InputDecoration(labelText: 'Thickness', filled: true), keyboardType: TextInputType.number, onSaved: (v) => th = double.tryParse(v ?? '') ?? th),
        TextFormField(initialValue: de.toString(), decoration: const InputDecoration(labelText: 'Density', filled: true), keyboardType: TextInputType.number, onSaved: (v) => de = double.tryParse(v ?? '') ?? de),
        TextFormField(initialValue: cp.toString(), decoration: const InputDecoration(labelText: 'Buy Price / Cost (PKR)', filled: true), keyboardType: TextInputType.number, onSaved: (v) => cp = double.tryParse(v ?? '') ?? cp),
        TextFormField(initialValue: up.toString(), decoration: const InputDecoration(labelText: 'Sell Price (PKR)', filled: true), keyboardType: TextInputType.number, onSaved: (v) => up = double.tryParse(v ?? '') ?? up),
        TextFormField(initialValue: lt.toString(), decoration: const InputDecoration(labelText: 'Low Stock Threshold', filled: true), keyboardType: TextInputType.number, onSaved: (v) => lt = double.tryParse(v ?? '') ?? lt),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          fk.currentState!.save();
          await ref.read(firestoreServiceProvider).updateProduct(product.copyWith(
              name: name, type: type, sizeLength: sl, sizeWidth: sw, thickness: th,
              density: de, unitType: unitType, unitPrice: up, costPrice: cp,
              lowStockThreshold: lt));
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Update')),
      ],
    ));
  }

  void _restock(Product product) {
    final qc = TextEditingController(); final cc = TextEditingController(); final pc = TextEditingController();
    final svc = ref.read(firestoreServiceProvider);
      showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Restock'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${product.name} | Current: ${product.stockLabel}'),
        const SizedBox(height: 12),
        TextField(controller: qc, decoration: InputDecoration(labelText: 'Quantity', suffixText: product.unitType == 'per_sqft' ? 'sq.ft' : 'pcs', filled: true), keyboardType: TextInputType.number),
        TextField(controller: cc, decoration: const InputDecoration(labelText: 'Cost Amount (PKR)', filled: true), keyboardType: TextInputType.number),
        TextField(controller: pc, decoration: const InputDecoration(labelText: 'Amount Paid (PKR)', filled: true), keyboardType: TextInputType.number),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final q = double.tryParse(qc.text) ?? 0; final c = double.tryParse(cc.text) ?? 0; final p = double.tryParse(pc.text) ?? 0;
          if (q <= 0 || c <= 0) return;
          final unitCost = c / q;
          await svc.restockTransaction(product.id, q, unitCost, p);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Restock')),
      ],
    )).then((_) { qc.dispose(); cc.dispose(); pc.dispose(); });
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
            Text('${product.sizeLength.toStringAsFixed(0)}ft \u00d7 ${product.sizeWidth.toStringAsFixed(0)}ft \u00b7 ${product.thickness.toStringAsFixed(0)}in${product.density > 0 ? ' \u00b7 Density ${product.density.toStringAsFixed(0)}' : ''}',
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
              Text('Rs ${product.unitPrice.toStringAsFixed(0)}/${product.unitType == 'per_sqft' ? 'sq.ft' : 'pc'}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, fontFeatures: [FontFeature('tnum')], color: cs.onSurface)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
