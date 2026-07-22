import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
                    title: Text('Rs. ${NumberFormat('#,##0').format(s.amount.toInt())}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s.date.day}/${s.date.month}/${s.date.year} | Paid: ${NumberFormat('#,##0').format(s.paid.toInt())} | Bal: ${NumberFormat('#,##0').format(s.balance.toInt())}',
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
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('dd MMM yyyy');

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColor.fromInt(0xFF0F6B64), PdfColor.fromInt(0xFF0B4E49)],
              begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight,
            ),
          ),
          child: pw.Column(children: [
            pw.Container(
              width: 32, height: 32,
              decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Center(child: pw.Text('\u{1F6CF}', style: pw.TextStyle(fontSize: 14))),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Asif Foam Center', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Text('Digital Register', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xD9FFFFFF))),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Date', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text(dateFmt.format(sale.date), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Receipt #', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('INV-${sale.id.substring(0, 4).toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
            pw.SizedBox(height: 10),
            pw.Text('Customer: ${customer?.name ?? sale.customerName ?? sale.customerId}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
              ),
              child: pw.Row(children: [
                pw.Expanded(child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600))),
                pw.SizedBox(width: 20, child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600))),
                pw.SizedBox(width: 40, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600))),
                pw.SizedBox(width: 45, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600))),
              ]),
            ),
            ...sale.lineItems.map((li) {
              final prod = products.where((p) => p.id == li.productId).firstOrNull;
              return pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Expanded(child: pw.Text(prod?.name ?? li.productId, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                    pw.SizedBox(width: 20, child: pw.Text('${li.qtyOrArea.toStringAsFixed(1)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    pw.SizedBox(width: 40, child: pw.Text('Rs ${fmt.format(li.salePrice.toInt())}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                    pw.SizedBox(width: 45, child: pw.Text('Rs ${fmt.format(li.lineTotal.toInt())}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  ]),
                  pw.SizedBox(height: 2),
                  pw.Text('${prod?.sizeLength.toStringAsFixed(0) ?? '?'}in \u00d7 ${prod?.sizeWidth.toStringAsFixed(0) ?? '?'}in \u00b7 ${prod?.thickness.toStringAsFixed(0) ?? '?'}in',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ]),
              );
            }),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEAF3F1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(children: [
                _row('Amount', 'Rs ${fmt.format(sale.amount.toInt())}'),
                _row('Paid', 'Rs ${fmt.format(sale.paid.toInt())}'),
                pw.Container(height: 1, color: PdfColor.fromInt(0x260F6B64), margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Balance', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F6B64))),
                  pw.Text('Rs ${fmt.format(sale.balance.toInt())}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F6B64))),
                ]),
              ]),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: sale.balance <= 0
                      ? PdfColor.fromInt(0xFFEAF3EC)
                      : PdfColor.fromInt(0xFFFBEBE8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(999)),
                ),
                child: pw.Text(
                  sale.balance <= 0 ? 'FULLY PAID' : 'BALANCE DUE',
                  style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold,
                    color: sale.balance <= 0
                        ? PdfColor.fromInt(0xFF2E6B4E)
                        : PdfColor.fromInt(0xFFB54A38),
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('Thank you for your business!',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F6B64)))),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Asif Foam Center \u00b7 Lahore, Pakistan',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500))),
          ]),
        ),
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

  pw.Widget _row(String label, String value) {
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    ]);
  }
}
