import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
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
    final dir = await getApplicationDocumentsDirectory();
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
    final tealColor = PdfColor.fromInt(0xFF0F6B64);
    final tealDark = PdfColor.fromInt(0xFF0B4E49);
    const subStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey600);
    final thStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    const tdStyle = pw.TextStyle(fontSize: 9);
    final totalStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

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
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: pw.BoxDecoration(color: tealColor),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(shopName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.Text('${_rangeLabel(startDate, endDate)}', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xD9FFFFFF))),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Generated', style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                  pw.Text('${_dateFmt.format(DateTime.now())}', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xD9FFFFFF))),
                ]),
              ]),
            ),
            pw.SizedBox(height: 14),
            pw.Text('Report period: ${_rangeLabel(startDate, endDate)}', style: subStyle),
            pw.SizedBox(height: 12),
            pw.Row(children: [
              pw.Expanded(child: _summaryCard('Revenue', _fmt(summary.revenue), PdfColor.fromInt(0xFFEAF3F1), PdfColor.fromInt(0xFF0F6B64))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _summaryCard('COGS', _fmt(summary.cogs), PdfColor.fromInt(0xFFFDF1E4), PdfColor.fromInt(0xFFB4712A))),
            ]),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Expanded(child: _summaryCard('Expenses', _fmt(summary.totalExpenses), PdfColor.fromInt(0xFFFBEBE8), PdfColor.fromInt(0xFFB54A38))),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _summaryCard('Net Profit', _fmt(summary.netProfit), PdfColor.fromInt(0xFFEAF3EC), PdfColor.fromInt(0xFF2E6B4E))),
            ]),
            pw.SizedBox(height: 14),
            pw.Text('Sales Detail', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
          ],
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Text('Page ${chunkIdx + 1} of $totalChunks', style: subStyle),
          ]),
        ]),
        footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('$shopName — Digital Register', style: subStyle),
          pw.Text('Page $pageNum', style: subStyle),
        ]),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headerStyle: thStyle,
            headerDecoration: pw.BoxDecoration(color: tealDark),
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
            headers: ['Date', 'Customer', 'Items', 'Amount', 'COGS', 'Profit'],
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
                s.customerName ?? s.customerId.substring(0, 6),
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
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEAF3F1)),
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

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'foam_shop_report_${_dateFmtFile.format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.Widget _summaryCard(String label, String value, PdfColor bg, PdfColor fg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: bg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xCC2E6B4E))),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: fg)),
      ]),
    );
  }

  Future<File> generateXlsxReport({
    required List<Sale> sales,
    required List<Product> products,
    required AccountingSummary summary,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final xl = Excel.createExcel();

    // Sheet 1: Summary
    final summarySheet = xl['Summary'];
    summarySheet.updateCell(CellIndex.indexByString('A1'), TextCellValue('Asif Foam Center — Business Report'),
        cellStyle: CellStyle(bold: true, fontSize: 14));
    summarySheet.updateCell(CellIndex.indexByString('A2'), TextCellValue('Period: ${_rangeLabel(startDate, endDate)}'));
    summarySheet.updateCell(CellIndex.indexByString('A3'), TextCellValue('Generated: ${_dateFmt.format(DateTime.now())}'));

    final metrics = [
      ('Revenue', _fmtRaw(summary.revenue)),
      ('COGS', _fmtRaw(summary.cogs)),
      ('Gross Profit', _fmtRaw(summary.grossProfit)),
      ('Expenses', _fmtRaw(summary.totalExpenses)),
      ('Net Profit', _fmtRaw(summary.netProfit)),
    ];
    for (var i = 0; i < metrics.length; i++) {
      final row = i + 5;
      summarySheet.updateCell(CellIndex.indexByString('A$row'), TextCellValue(metrics[i].$1),
          cellStyle: CellStyle(bold: true));
      summarySheet.updateCell(CellIndex.indexByString('B$row'), TextCellValue(metrics[i].$2));
    }

    // Sheet 2: Sales Detail
    final detailSheet = xl['Sales Detail'];
    final headers = ['Date', 'Customer', 'Items', 'Amount', 'COGS', 'Profit'];
    for (var c = 0; c < headers.length; c++) {
      final col = String.fromCharCode(65 + c);
      detailSheet.updateCell(CellIndex.indexByString('$col${1}'), TextCellValue(headers[c]), cellStyle: CellStyle(
        bold: true,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('FF0F6B64'),
      ));
    }

    final productMap = {for (final p in products) p.id: p};
    int row = 2;
    for (final s in sales) {
      if (s.isVoided || s.isQuote) continue;
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
      detailSheet.updateCell(CellIndex.indexByString('A$row'), TextCellValue(_dateFmt.format(s.date)));
      detailSheet.updateCell(CellIndex.indexByString('B$row'), TextCellValue(s.customerName ?? s.customerId.substring(0, 6)));
      detailSheet.updateCell(CellIndex.indexByString('C$row'), TextCellValue(items.length > 25 ? '${items.substring(0, 25)}...' : items));
      detailSheet.updateCell(CellIndex.indexByString('D$row'), TextCellValue(_fmtRaw(s.amount)));
      detailSheet.updateCell(CellIndex.indexByString('E$row'), TextCellValue(_fmtRaw(cogs)));
      detailSheet.updateCell(CellIndex.indexByString('F$row'), TextCellValue(_fmtRaw(s.amount - cogs)));
      row++;
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'foam_shop_report_${_dateFmtFile.format(DateTime.now())}.xlsx';
    final fileBytes = xl.save();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(fileBytes!);
    return file;
  }
}
