import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../db/database.dart';

class PdfService {
  static PdfService get instance => _i;
  static final _i = PdfService._();
  PdfService._();

  pw.Font? _regular, _bold;

  Future<void> _loadFonts() async {
    if (_regular != null) return;
    try {
      final reg = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final bld = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _regular = pw.Font.ttf(reg);
      _bold    = pw.Font.ttf(bld);
    } catch (_) {
      _regular = pw.Font.helvetica();
      _bold    = pw.Font.helveticaBold();
    }
  }

  pw.TextStyle _ts({double size = 11, bool bold = false, PdfColor? color}) =>
      pw.TextStyle(
        font    : bold ? _bold : _regular,
        fontSize: size,
        color   : color ?? PdfColors.grey900,
      );

  // ── Invoice PDF ──────────────────────────────────────────────────────────
  Future<Uint8List> buildInvoicePdf(SalesInvoice invoice, Map<String, String> settings) async {
    await _loadFonts();
    final doc = pw.Document();
    final currency = settings['currency'] ?? 'ريال';

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _invoiceHeader(settings),
          pw.SizedBox(height: 20),
          _invoiceInfo(invoice),
          pw.SizedBox(height: 16),
          _invoiceTable(invoice, currency),
          pw.SizedBox(height: 16),
          _invoiceTotals(invoice, currency),
          pw.Spacer(),
          _invoiceFooter(settings),
        ],
      ),
    ));

    return doc.save();
  }

  pw.Widget _invoiceHeader(Map<String, String> s) => pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color   : PdfColors.blueGrey900,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(s['company_name'] ?? '', style: _ts(size: 18, bold: true, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text(s['company_address'] ?? '', style: _ts(size: 10, color: const PdfColor(1, 1, 1, 0.7))),
          pw.Text('هاتف: ${s['company_phone'] ?? ''}', style: _ts(size: 10, color: const PdfColor(1, 1, 1, 0.7))),
          if ((s['tax_number'] ?? '').isNotEmpty)
            pw.Text('الرقم الضريبي: ${s['tax_number']}', style: _ts(size: 10, color: const PdfColor(1, 1, 1, 0.7))),
        ]),
        pw.Text('فاتورة ضريبية', style: _ts(size: 22, bold: true, color: PdfColors.amber200)),
      ],
    ),
  );

  pw.Widget _invoiceInfo(SalesInvoice inv) => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color : PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _infoRow('رقم الفاتورة', inv.invoiceNumber),
        _infoRow('التاريخ', inv.date),
        if (inv.dueDate != null) _infoRow('تاريخ الاستحقاق', inv.dueDate!),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _infoRow('اسم العميل', inv.customerName ?? ''),
        _infoRow('طريقة الدفع', inv.paymentMethod),
        _infoRow('الحالة', _statusAr(inv.status)),
      ]),
    ]),
  );

  pw.Widget _infoRow(String label, String val) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(children: [
      pw.Text('$label: ', style: _ts(bold: true, size: 10, color: PdfColors.blueGrey700)),
      pw.Text(val, style: _ts(size: 10)),
    ]),
  );

  pw.Widget _invoiceTable(SalesInvoice inv, String cur) {
    const cols = ['#', 'المنتج / الخدمة', 'الكمية', 'السعر', 'الخصم', 'الضريبة', 'الإجمالي'];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
          children: cols.map((c) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: pw.Text(c, style: _ts(bold: true, size: 11, color: PdfColors.white),
                textAlign: pw.TextAlign.center),
          )).toList(),
        ),
        ...inv.items.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(
              color: e.key.isEven ? PdfColors.white : PdfColors.grey50),
          children: [
            _cell((e.key + 1).toString()),
            _cell(e.value.productName ?? ''),
            _cell(e.value.qty.toStringAsFixed(2)),
            _cell(e.value.unitPrice.toStringAsFixed(2)),
            _cell('${e.value.discountRate.toStringAsFixed(1)}%'),
            _cell('${e.value.taxRate.toStringAsFixed(1)}%'),
            _cell('${e.value.total.toStringAsFixed(2)} $cur', bold: true),
          ],
        )),
      ],
    );
  }

  pw.Widget _cell(String t, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: pw.Text(t, style: _ts(bold: bold, size: 10), textAlign: pw.TextAlign.center),
  );

  pw.Widget _invoiceTotals(SalesInvoice inv, String cur) => pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Container(
      width: 260,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(children: [
        _totRow('المجموع الفرعي', '${inv.subtotal.toStringAsFixed(2)} $cur'),
        if (inv.discountAmount > 0)
          _totRow('الخصم', '- ${inv.discountAmount.toStringAsFixed(2)} $cur', color: PdfColors.red700),
        _totRow('الضريبة (${inv.taxRate.toStringAsFixed(0)}%)', '${inv.taxAmount.toStringAsFixed(2)} $cur'),
        pw.Divider(thickness: 1, color: PdfColors.blueGrey900),
        _totRow('الإجمالي', '${inv.total.toStringAsFixed(2)} $cur', big: true),
        if (inv.paidAmount > 0)
          _totRow('المدفوع', '${inv.paidAmount.toStringAsFixed(2)} $cur', color: PdfColors.green700),
        if (inv.remaining > 0)
          _totRow('المتبقي', '${inv.remaining.toStringAsFixed(2)} $cur', color: PdfColors.red700),
      ]),
    ),
  );

  pw.Widget _totRow(String l, String v, {bool big = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(l, style: _ts(size: big ? 13 : 11, bold: big, color: color ?? PdfColors.blueGrey700)),
          pw.Text(v, style: _ts(size: big ? 13 : 11, bold: big, color: color ?? PdfColors.grey900)),
        ]),
      );

  pw.Widget _invoiceFooter(Map<String, String> s) => pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Center(
      child: pw.Text(s['invoice_footer'] ?? 'شكراً لتعاملكم معنا',
          style: _ts(size: 12, bold: true, color: PdfColors.blueGrey600)),
    ),
  );

  // ── Generic Report PDF ───────────────────────────────────────────────────
  Future<Uint8List> buildReportPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    Map<String, String>? settings,
    Map<String, double>? summary,
  }) async {
    await _loadFonts();
    final doc = pw.Document();
    const fmt = PdfPageFormat.a4;

    doc.addPage(pw.MultiPage(
      pageFormat : fmt.landscape,
      textDirection: pw.TextDirection.rtl,
      margin     : const pw.EdgeInsets.all(28),
      header     : (ctx) => _reportHeader(title, settings),
      footer     : (ctx) => _reportFooter(ctx),
      build      : (ctx) => [
        pw.SizedBox(height: 14),
        _reportTable(headers, rows),
        if (summary != null) ...[
          pw.SizedBox(height: 20),
          _reportSummary(summary, settings?['currency'] ?? 'ريال'),
        ],
      ],
    ));

    return doc.save();
  }

  pw.Widget _reportHeader(String title, Map<String, String>? s) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey300, width: 1)),
    ),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(title, style: _ts(size: 18, bold: true, color: PdfColors.blueGrey900)),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(s?['company_name'] ?? '', style: _ts(size: 11, bold: true)),
        pw.Text('تاريخ الطباعة: ${DateTime.now().toString().substring(0, 10)}',
            style: _ts(size: 9, color: PdfColors.grey600)),
      ]),
    ]),
  );

  pw.Widget _reportFooter(pw.Context ctx) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
    ),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('نظام ERP المتكامل', style: _ts(size: 9, color: PdfColors.grey500)),
      pw.Text('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
          style: _ts(size: 9, color: PdfColors.grey500)),
    ]),
  );

  pw.Widget _reportTable(List<String> headers, List<List<String>> rows) =>
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            children: headers.map((h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: pw.Text(h, style: _ts(bold: true, size: 10, color: PdfColors.white),
                  textAlign: pw.TextAlign.center),
            )).toList(),
          ),
          ...rows.asMap().entries.map((e) => pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : PdfColors.grey50),
            children: e.value.map((cell) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: pw.Text(cell, style: _ts(size: 10), textAlign: pw.TextAlign.center),
            )).toList(),
          )),
        ],
      );

  pw.Widget _reportSummary(Map<String, double> summary, String cur) => pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
      ),
      child: pw.Column(
        children: summary.entries.map((e) => _totRow(
          e.key,
          '${e.value.toStringAsFixed(2)} $cur',
          big: e.key.contains('الصافي') || e.key.contains('الإجمالي'),
        )).toList(),
      ),
    ),
  );

  // ── Save & Open ──────────────────────────────────────────────────────────
  Future<String> savePdf(Uint8List bytes, String fileName) async {
    final dir  = await getApplicationDocumentsDirectory();
    final pDir = Directory(p.join(dir.path, 'ERP_PDF'));
    if (!pDir.existsSync()) pDir.createSync(recursive: true);
    final file = File(p.join(pDir.path,
        '${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> previewPdf(Uint8List bytes, String name) async {
    await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
  }

  String _statusAr(String s) => switch (s) {
    'paid'      => 'مدفوع',
    'pending'   => 'معلق',
    'partial'   => 'جزئي',
    'cancelled' => 'ملغي',
    'overdue'   => 'متأخر',
    _           => s,
  };
}
