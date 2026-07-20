import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final salesAsync = ref.watch(salesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing / Receipts')),
      body: salesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('No sales yet', style: Theme.of(context).textTheme.bodyLarge),
            ]));
          }
          final recent = sales.take(50).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recent.length,
            itemBuilder: (_, i) {
              final s = recent[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_rounded, color: cs.onPrimaryContainer),
                    ),
                    title: Text('Rs. ${s.amount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s.date.day}/${s.date.month}/${s.date.year} | Paid: ${s.paid.toStringAsFixed(0)} | Bal: ${s.balance.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      tooltip: 'PDF',
                      onPressed: () => _generate(context, ref, s),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: cs.onSurface))),
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref, Sale sale) async {
    final products = await ref.read(productsStreamProvider.future);
    final customers = await ref.read(customersStreamProvider.future);
    final customer = customers.where((c) => c.id == sale.customerId).firstOrNull;

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('Asif Foam Center', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text('Digital Register')),
        pw.SizedBox(height: 8), pw.Divider(),
        pw.Text('Date: ${sale.date.day}/${sale.date.month}/${sale.date.year}'),
        pw.Text('Customer: ${customer?.name ?? sale.customerName ?? sale.customerId}'),
        pw.Divider(),
        // Line items
        ...sale.lineItems.map((li) {
          final prod = products.where((p) => p.id == li.productId).firstOrNull;
          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(prod?.name ?? li.productId, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (li.customLength != null && li.customWidth != null)
              pw.Text('Cut: ${(li.customLength!).toStringAsFixed(0)}\" x ${(li.customWidth!).toStringAsFixed(0)}\"'),
            pw.Text('Qty: ${li.qtyOrArea.toStringAsFixed(1)} ${prod?.unitType == 'per_sqft' ? 'sq.ft' : 'pcs'}'),
            pw.Text('Price: Rs. ${li.salePrice.toStringAsFixed(0)}'),
            if (li.lineDiscountAmount > 0)
              pw.Text('Discount: -Rs. ${li.lineDiscountAmount.toStringAsFixed(0)}'),
            pw.Text('Line Total: Rs. ${li.lineTotal.toStringAsFixed(0)}'),
          ]);
        }),
        if (sale.totalDiscount > 0)
          pw.Text('Total Discount: -Rs. ${sale.totalDiscount.toStringAsFixed(0)}'),
        if ((sale.deliveryCharge ?? 0) > 0)
          pw.Text('Delivery: Rs. ${sale.deliveryCharge!.toStringAsFixed(0)}'),
        if ((sale.cuttingCharge ?? 0) > 0)
          pw.Text('Cutting Charge: Rs. ${sale.cuttingCharge!.toStringAsFixed(0)}'),
        pw.Divider(),
        pw.Text('Amount: Rs. ${sale.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Paid: Rs. ${sale.paid.toStringAsFixed(0)}'),
        pw.Text('Balance: Rs. ${sale.balance.toStringAsFixed(0)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
        pw.Divider(),
        pw.Center(child: pw.Text('Thank you!')),
      ]),
    ));

    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.print_rounded), title: const Text('Print'),
          onTap: () async { Navigator.pop(ctx); await Printing.layoutPdf(onLayout: (_) => pdf.save()); }),
      ListTile(leading: const Icon(Icons.share_rounded), title: const Text('Share PDF'),
          onTap: () async {
            Navigator.pop(ctx);
            final dir = await getTemporaryDirectory();
            final f = File('${dir.path}/receipt_${sale.id.substring(0, 8)}.pdf');
            await f.writeAsBytes(await pdf.save());
            await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'Foam Shop Receipt'));
          }),
    ])));
  }
}
