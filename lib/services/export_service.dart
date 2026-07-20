import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../models/product.dart';
import 'accounting_service.dart';

class ExportService {
  final _dateFmt = DateFormat('dd-MMM-yyyy');
  final _dateFmtFile = DateFormat('yyyy-MM-dd');
  final _numberFmt = NumberFormat('#,##0');

  String _fmt(double v) => 'Rs ${_numberFmt.format(v)}';
  String _fmtRaw(double v) => v.toStringAsFixed(0);

  bool _isSingleDay(DateTime start, DateTime end) =>
      start.year == end.year && start.month == end.month && start.day == end.day;

  String _rangeLabel(DateTime start, DateTime end) {
    if (_isSingleDay(start, end)) return _dateFmt.format(start);
    return '${_dateFmt.format(start)} \u2014 ${_dateFmt.format(end)}';
  }

  Future<Directory> _getPublicDir() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) return downloadDir;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  }

  Future<File> generateCsvReport({
    required List<Sale> sales,
    required List<Product> products,
    required AccountingSummary summary,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final productMap = {for (final p in products) p.id: p};
    final rows = <List<String>>[
      ['Foam Shop - Digital Register'],
      ['Sales Report: ${_rangeLabel(startDate, endDate)}'],
      ['Generated: ${_dateFmt.format(DateTime.now())}'],
      [],
      ['Summary'],
      ['Revenue', _fmtRaw(summary.revenue)],
      ['COGS', _fmtRaw(summary.cogs)],
      ['Gross Profit', _fmtRaw(summary.grossProfit)],
      ['Net Profit', _fmtRaw(summary.netProfit)],
      [],
      ['Date', 'Invoice ID', 'Items', 'Revenue', 'COGS', 'Profit'],
    ];

    for (final sale in sales) {
      if (sale.isVoided || sale.isQuote) continue;
      final items = sale.lineItems.map((li) {
        final prod = productMap[li.productId];
        return prod?.name ?? li.productId;
      }).join(', ');
      double cogs = 0;
      for (final li in sale.lineItems) {
        double unitCost = li.costPriceAtSale;
        if (unitCost <= 0) {
          final prod = productMap[li.productId];
          unitCost = prod?.costPrice ?? 0;
        }
        if (unitCost <= 0) unitCost = li.salePrice * 0.70;
        cogs += li.qtyOrArea * unitCost;
      }
      rows.add([
        _dateFmt.format(sale.date),
        sale.id.substring(0, 8),
        items,
        _fmtRaw(sale.amount),
        _fmtRaw(cogs),
        _fmtRaw(sale.amount - cogs),
      ]);
    }

    rows.add([]);
    rows.add(['TOTAL', '', '', _fmtRaw(summary.revenue), _fmtRaw(summary.cogs), _fmtRaw(summary.netProfit)]);

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await _getPublicDir();
    final fileName = 'foam_shop_report_${_dateFmtFile.format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);
    return file;
  }

  Future<File> generatePdfReport({
    required List<Sale> sales,
    required List<Product> products,
    required AccountingSummary summary,
    required DateTime startDate,
    required DateTime endDate,
    required String shopName,
  }) async {
    final productMap = {for (final p in products) p.id: p};
    final doc = pw.Document();
    final headerStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    const subStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey600);
    const thStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    const tdStyle = pw.TextStyle(fontSize: 9);
    const totalStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

    int pageNum = 0;
    final dataRows = sales.where((s) => !s.isVoided && !s.isQuote).toList();
    final chunkSize = 25;
    final totalChunks = dataRows.isEmpty ? 1 : (dataRows.length / chunkSize).ceil();

    for (var chunkIdx = 0; chunkIdx < totalChunks; chunkIdx++) {
      final chunk = dataRows.isEmpty ? [] : dataRows.skip(chunkIdx * chunkSize).take(chunkSize).toList();
      pageNum++;

      doc.addPage(pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 56),
        header: (ctx) => pw.Column(children: [
          if (chunkIdx == 0) ...[
            pw.Center(child: pw.Text(shopName, style: headerStyle)),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('${_rangeLabel(startDate, endDate)}', style: subStyle)),
            pw.Center(child: pw.Text('Generated: ${_dateFmt.format(DateTime.now())}', style: subStyle)),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
                  _summaryCell('Revenue', _fmt(summary.revenue)),
                  _summaryCell('COGS', _fmt(summary.cogs)),
                ]),
                pw.SizedBox(height: 8),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
                  _summaryCell('Net Profit', _fmt(summary.netProfit)),
                  _summaryCell('Margin', summary.revenue > 0
                      ? '${((summary.netProfit / summary.revenue) * 100).toStringAsFixed(1)}%'
                      : '0%'),
                ]),
              ]),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
          ],
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Text('Page ${chunkIdx + 1} of $totalChunks', style: subStyle),
          ]),
        ]),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated by Foam Shop \u2014 Digital Register', style: subStyle),
            pw.Text('Page $pageNum', style: subStyle),
          ]),
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headerStyle: thStyle,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellStyle: tdStyle,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            headers: ['Date', 'Invoice', 'Items', 'Revenue', 'COGS', 'Profit'],
            data: chunk.map((s) {
              final items = s.lineItems.map((li) {
                final prod = productMap[li.productId];
                return prod?.name ?? li.productId;
              }).join(', ');
              double cogs = 0;
              for (final li in s.lineItems) {
                double unitCost = li.costPriceAtSale;
                if (unitCost <= 0) {
                  final prod = productMap[li.productId];
                  unitCost = prod?.costPrice ?? 0;
                }
                if (unitCost <= 0) unitCost = li.salePrice * 0.70;
                cogs += li.qtyOrArea * unitCost;
              }
              return [
                _dateFmt.format(s.date),
                s.id.substring(0, 8),
                items.length > 25 ? '${items.substring(0, 25)}...' : items,
                _fmt(s.amount),
                _fmt(cogs),
                _fmt(s.amount - cogs),
              ];
            }).toList(),
          ),
          if (chunkIdx == totalChunks - 1 && dataRows.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 2)),
                color: PdfColors.green50,
              ),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
                pw.Text('TOTAL', style: totalStyle),
                pw.SizedBox(width: 60),
                pw.Text(_fmt(summary.revenue), style: totalStyle),
                pw.Text(_fmt(summary.cogs), style: totalStyle),
                pw.Text(_fmt(summary.netProfit), style: totalStyle),
              ]),
            ),
          ],
        ],
      ));
    }

    final dir = await _getPublicDir();
    final fileName = 'foam_shop_report_${_dateFmtFile.format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.Widget _summaryCell(String label, String value) {
    return pw.Column(children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    ]);
  }
}
