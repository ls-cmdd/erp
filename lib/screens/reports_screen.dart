import "dart:typed_data";
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reports_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/app_provider.dart';
import '../services/pdf_service.dart';
import '../services/csv_service.dart';
import '../core/utils.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _startDate, _endDate;
  bool _loading = false;

  static const _reports = [
    (Icons.point_of_sale_rounded, 'تقرير المبيعات', Color(0xFF0E9F6E), 'sales'),
    (Icons.shopping_basket_rounded, 'تقرير المشتريات', Color(0xFF3B82F6), 'purchases'),
    (Icons.warehouse_rounded, 'تقرير المخزون', Color(0xFFF59E0B), 'inventory'),
    (Icons.account_balance_wallet_rounded, 'الأرباح والخسائر', Color(0xFF8B5CF6), 'pnl'),
    (Icons.people_rounded, 'أكثر المنتجات مبيعاً', Color(0xFFEC4899), 'top_products'),
    (Icons.pie_chart_rounded, 'المبيعات حسب الفئة', Color(0xFF06B6D4), 'by_category'),
    (Icons.warning_amber_rounded, 'الذمم المتأخرة', Color(0xFFEF4444), 'aged'),
    (Icons.receipt_long_rounded, 'تقرير الضريبة', Color(0xFF64748B), 'tax'),
  ];

  Future<void> _run(String type) async {
    setState(() => _loading = true);
    try {
      final rp      = context.read<ReportsProvider>();
      final settings= context.read<SettingsProvider>().settings;
      final cur     = settings['currency'] ?? 'ريال';

      switch (type) {
        case 'sales': await _salesReport(rp, settings, cur); break;
        case 'purchases': await _purchasesReport(rp, settings, cur); break;
        case 'inventory': await _inventoryReport(rp, settings, cur); break;
        case 'pnl': await _pnlReport(rp, settings, cur); break;
        case 'top_products': await _topProductsReport(rp, settings, cur); break;
        case 'by_category': await _byCategoryReport(rp, settings, cur); break;
        case 'aged': await _agedReport(rp, settings, cur); break;
        case 'tax': await _taxReport(rp, settings, cur); break;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _salesReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getSalesReport(startDate: _startDate, endDate: _endDate);
    final total = data.fold(0.0, (sum, r) => sum + ((r['total'] as num?)?.toDouble() ?? 0));
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'تقرير المبيعات',
      headers: ['رقم الفاتورة', 'العميل', 'التاريخ', 'الإجمالي', 'المدفوع', 'المتبقي', 'الحالة'],
      rows: data.map((r) => [
        r['invoice_number']?.toString() ?? '',
        r['customer_name']?.toString() ?? 'غير محدد',
        AppUtils.date(r['date']?.toString()),
        AppUtils.money((r['total'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['paid_amount'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['remaining'] as num?)?.toDouble() ?? 0, cur: cur),
        AppTheme.statusLabel(r['status']?.toString() ?? ''),
      ]).toList(),
      settings: s,
      summary: {'إجمالي المبيعات': total},
    );
    _showResult(bytes, 'sales_report', data, {
      'invoice_number':'رقم الفاتورة','customer_name':'العميل','date':'التاريخ','total':'الإجمالي','status':'الحالة'
    });
  }

  Future<void> _purchasesReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getPurchasesReport(startDate: _startDate, endDate: _endDate);
    final total = data.fold(0.0, (sum, r) => sum + ((r['total'] as num?)?.toDouble() ?? 0));
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'تقرير المشتريات',
      headers: ['رقم الفاتورة', 'المورد', 'التاريخ', 'الإجمالي', 'المدفوع', 'المتبقي'],
      rows: data.map((r) => [
        r['invoice_number']?.toString() ?? '',
        r['supplier_name']?.toString() ?? 'غير محدد',
        AppUtils.date(r['date']?.toString()),
        AppUtils.money((r['total'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['paid_amount'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['remaining'] as num?)?.toDouble() ?? 0, cur: cur),
      ]).toList(),
      settings: s,
      summary: {'إجمالي المشتريات': total},
    );
    _showResult(bytes, 'purchases_report', data, {
      'invoice_number':'رقم الفاتورة','supplier_name':'المورد','date':'التاريخ','total':'الإجمالي'
    });
  }

  Future<void> _inventoryReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getInventoryReport();
    final totalVal = data.fold(0.0, (sum, r) => sum + ((r['stock_value'] as num?)?.toDouble() ?? 0));
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'تقرير المخزون',
      headers: ['المنتج', 'الكود', 'الفئة', 'الكمية', 'سعر التكلفة', 'سعر البيع', 'القيمة', 'تنبيه'],
      rows: data.map((r) => [
        r['name_ar']?.toString() ?? '',
        r['sku']?.toString() ?? '',
        r['category_name']?.toString() ?? '',
        AppUtils.num((r['stock_qty'] as num?)?.toDouble() ?? 0),
        AppUtils.money((r['cost_price'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['sale_price'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['stock_value'] as num?)?.toDouble() ?? 0, cur: cur),
        (r['is_low'] as int?) == 1 ? '⚠ منخفض' : '✓',
      ]).toList(),
      settings: s,
      summary: {'إجمالي قيمة المخزون': totalVal},
    );
    _showResult(bytes, 'inventory_report', data, {
      'name_ar':'المنتج','sku':'الكود','stock_qty':'الكمية','cost_price':'سعر التكلفة','stock_value':'القيمة'
    });
  }

  Future<void> _pnlReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getProfitLossReport(startDate: _startDate, endDate: _endDate);
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'تقرير الأرباح والخسائر',
      headers: ['البند', 'المبلغ'],
      rows: [
        ['إجمالي المبيعات', AppUtils.money(data['total_sales'] ?? 0, cur: cur)],
        ['إجمالي المشتريات', AppUtils.money(data['total_purchases'] ?? 0, cur: cur)],
        ['الربح الإجمالي', AppUtils.money(data['gross_profit'] ?? 0, cur: cur)],
        ['إجمالي المصروفات', AppUtils.money(data['total_expenses'] ?? 0, cur: cur)],
        ['صافي الربح', AppUtils.money(data['net_profit'] ?? 0, cur: cur)],
        ['ضريبة محصلة', AppUtils.money(data['tax_collected'] ?? 0, cur: cur)],
        ['ضريبة مدفوعة', AppUtils.money(data['tax_paid'] ?? 0, cur: cur)],
      ],
      settings: s,
      summary: {'صافي الربح': data['net_profit'] ?? 0},
    );
    await PdfService.instance.printPdf(bytes);
  }

  Future<void> _topProductsReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getTopProductsReport(limit: 20);
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'أكثر المنتجات مبيعاً',
      headers: ['المنتج', 'الكمية المباعة', 'إجمالي المبيعات', 'عدد الفواتير'],
      rows: data.map((r) => [
        r['name_ar']?.toString() ?? '',
        AppUtils.num((r['total_qty'] as num?)?.toDouble() ?? 0),
        AppUtils.money((r['total_sales'] as num?)?.toDouble() ?? 0, cur: cur),
        (r['invoice_count'] ?? 0).toString(),
      ]).toList(),
      settings: s,
    );
    _showResult(bytes, 'top_products', data, {
      'name_ar':'المنتج','total_qty':'الكمية','total_sales':'الإجمالي'
    });
  }

  Future<void> _byCategoryReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getSalesByProductCategory();
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'المبيعات حسب الفئة',
      headers: ['الفئة', 'عدد الفواتير', 'الكمية الإجمالية', 'إجمالي المبيعات'],
      rows: data.map((r) => [
        r['category']?.toString() ?? '',
        (r['invoice_count'] ?? 0).toString(),
        AppUtils.num((r['total_qty'] as num?)?.toDouble() ?? 0),
        AppUtils.money((r['total_amount'] as num?)?.toDouble() ?? 0, cur: cur),
      ]).toList(),
      settings: s,
    );
    _showResult(bytes, 'sales_by_category', data, {
      'category':'الفئة','total_amount':'الإجمالي'
    });
  }

  Future<void> _agedReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getAgedReceivables();
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'تقرير الذمم المتأخرة',
      headers: ['العميل', 'رقم الفاتورة', 'تاريخ الاستحقاق', 'المتبقي', 'أيام التأخير'],
      rows: data.map((r) => [
        r['customer_name']?.toString() ?? '',
        r['invoice_number']?.toString() ?? '',
        AppUtils.date(r['due_date']?.toString()),
        AppUtils.money((r['remaining'] as num?)?.toDouble() ?? 0, cur: cur),
        '${r['days_overdue'] ?? 0} يوم',
      ]).toList(),
      settings: s,
    );
    _showResult(bytes, 'aged_receivables', data, {
      'customer_name':'العميل','invoice_number':'الفاتورة','remaining':'المتبقي','days_overdue':'أيام التأخير'
    });
  }

  Future<void> _taxReport(ReportsProvider rp, Map<String, String> s, String cur) async {
    final data = await rp.getTaxReport(startDate: _startDate, endDate: _endDate);
    final bytes = await PdfService.instance.buildReportPdf(
      title: 'تقرير الضريبة',
      headers: ['الفترة', 'الضريبة المحصلة', 'الضريبة المدفوعة', 'الصافي'],
      rows: data.map((r) => [
        AppUtils.arabicMonth(r['period']?.toString() ?? ''),
        AppUtils.money((r['tax_collected'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money((r['tax_paid'] as num?)?.toDouble() ?? 0, cur: cur),
        AppUtils.money(((r['tax_collected'] as num?)?.toDouble() ?? 0) - ((r['tax_paid'] as num?)?.toDouble() ?? 0), cur: cur),
      ]).toList(),
      settings: s,
    );
    await PdfService.instance.printPdf(bytes);
  }

  void _showResult(Uint8List bytes, String name, List<Map<String, dynamic>> data, Map<String, String> labels) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('تصدير التقرير'),
      content: const Text('اختر صيغة التصدير'),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('طباعة PDF'),
          onPressed: () async {
            Navigator.pop(context);
            await PdfService.instance.printPdf(bytes);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.save_alt_outlined),
          label: const Text('حفظ PDF'),
          onPressed: () async {
            Navigator.pop(context);
            final path = await PdfService.instance.savePdf(bytes, name);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم الحفظ: $path')));
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('تصدير CSV'),
          onPressed: () async {
            Navigator.pop(context);
            final mapped = CsvService.instance.mapHeaders(data, labels);
            final path   = await CsvService.instance.export(mapped, name);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم التصدير: $path')));
          },
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return LoadingOverlay(
      isLoading: _loading,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(children: [
            Row(children: [
              Text('التقارير', style: Theme.of(context).textTheme.headlineSmall),
            ]),
            const SizedBox(height: 16),
            // Date filter
            Row(children: [
              _DateBtn('من', _startDate, (v) => setState(() => _startDate = v)),
              const SizedBox(width: 12),
              _DateBtn('إلى', _endDate, (v) => setState(() => _endDate = v)),
              const SizedBox(width: 12),
              if (_startDate != null || _endDate != null)
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('مسح الفلتر'),
                  onPressed: () => setState(() { _startDate = null; _endDate = null; }),
                ),
            ]),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280, mainAxisExtent: 160,
                crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: _reports.length,
            itemBuilder: (_, i) {
              final r = _reports[i];
              return _ReportCard(
                icon: r.$1, title: r.$2, color: r.$3,
                onTap: () => _run(r.$4),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon; final String title; final Color color; final VoidCallback onTap;
  const _ReportCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.picture_as_pdf_outlined, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('PDF', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(width: 8),
            Icon(Icons.table_chart_outlined, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('CSV', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ]),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label; final String? value; final void Function(String) onPicked;
  const _DateBtn(this.label, this.value, this.onPicked);
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final d = await showDatePicker(context: context, initialDate: DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2100));
      if (d != null) onPicked(d.toIso8601String().substring(0, 10));
    },
    icon: const Icon(Icons.calendar_today_outlined, size: 14),
    label: Text(value != null ? '$label: ${AppUtils.date(value)}' : label),
  );
}

// Required import for Uint8List
