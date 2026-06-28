import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/purchases_provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../core/utils.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  static const _statuses = [
    ('all','الكل'),('pending','معلق'),('paid','مدفوع'),('partial','جزئي'),('cancelled','ملغي'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PurchasesProvider>().loadInvoices());
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pp  = context.watch<PurchasesProvider>();
    final cur = context.watch<SettingsProvider>().get('currency', defaultValue: 'ريال');

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('المشتريات', style: Theme.of(context).textTheme.headlineSmall),
              Text('${pp.invoices.length} فاتورة', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ]),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => showDialog(context: context, barrierDismissible: false,
                  builder: (_) => const _PurchaseInvoiceDialog()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('فاتورة مشتريات'),
            ),
          ]),
          const SizedBox(height: 16),
          AppSearchBar(hint: 'بحث برقم الفاتورة أو المورد...', controller: _search,
              onChanged: (v) => pp.loadInvoices(search: v)),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs, isScrollable: true, tabAlignment: TabAlignment.start,
            onTap: (i) => pp.loadInvoices(status: _statuses[i].$1 == 'all' ? null : _statuses[i].$1),
            tabs: _statuses.map((s) => Tab(text: s.$2)).toList(),
          ),
        ]),
      ),
      Expanded(
        child: pp.isLoading
            ? const Center(child: CircularProgressIndicator())
            : pp.invoices.isEmpty
                ? const EmptyState(icon: Icons.shopping_basket_outlined, title: 'لا توجد فواتير مشتريات')
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: pp.invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final inv = pp.invoices[i];
                      final color = AppTheme.statusColor(inv.status);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final full = await pp.getById(inv.id!);
                          if (full != null && mounted) _showDetail(full);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.white : const Color(0xFF1A2332),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
                          ),
                          child: Row(children: [
                            Container(width: 4, height: 52,
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                                    child: Text(AppTheme.statusLabel(inv.status),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
                              ]),
                              const SizedBox(height: 4),
                              Text(inv.supplierName ?? 'مورد غير محدد',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(AppUtils.money(inv.total, cur: cur),
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary)),
                              const SizedBox(height: 4),
                              Text(AppUtils.date(inv.date), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                              if (inv.remaining > 0)
                                Text('متبقي: ${AppUtils.money(inv.remaining, cur: cur)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  void _showDetail(PurchaseInvoice inv) {
    final cur = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(children: [
        Text('فاتورة مشتريات ${inv.invoiceNumber}'),
        const Spacer(),
        if (inv.remaining > 0)
          ElevatedButton.icon(
            icon: const Icon(Icons.payment_outlined, size: 16),
            label: const Text('تسجيل دفعة'),
            onPressed: () => _payDialog(inv),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
          ),
      ]),
      content: SizedBox(width: 700,
        child: SingleChildScrollView(child: Column(children: [
          Wrap(spacing: 16, runSpacing: 8, children: [
            _badge(Icons.local_shipping_outlined, inv.supplierName ?? 'غير محدد'),
            _badge(Icons.calendar_today_outlined, AppUtils.date(inv.date)),
            _badge(Icons.payments_outlined, inv.paymentMethod),
          ]),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5)},
            children: [
              _headerRow(['المنتج','الكمية','السعر','الإجمالي']),
              ...inv.items.map((item) => TableRow(children: [
                _td(item.productName ?? ''), _td(AppUtils.num(item.qty)),
                _td(AppUtils.money(item.unitPrice, cur: cur)),
                _td(AppUtils.money(item.total, cur: cur), bold: true),
              ])),
            ],
          ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft,
            child: SizedBox(width: 280, child: Column(children: [
              _totRow('المجموع', AppUtils.money(inv.subtotal, cur: cur)),
              if (inv.discountAmount > 0)
                _totRow('الخصم', '- ${AppUtils.money(inv.discountAmount, cur: cur)}', color: Colors.red),
              _totRow('الضريبة', AppUtils.money(inv.taxAmount, cur: cur)),
              const Divider(),
              _totRow('الإجمالي', AppUtils.money(inv.total, cur: cur), bold: true,
                  color: Theme.of(context).colorScheme.primary),
              if (inv.remaining > 0)
                _totRow('المتبقي', AppUtils.money(inv.remaining, cur: cur), color: Colors.orange),
            ])),
          ),
        ])),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
    ));
  }

  void _payDialog(PurchaseInvoice inv) async {
    final pp      = context.read<PurchasesProvider>();
    final cur     = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    final amtCtrl = TextEditingController(text: inv.remaining.toStringAsFixed(2));
    String method = 'نقدي';
    await showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'المبلغ ($cur)')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: method,
            decoration: const InputDecoration(labelText: 'طريقة الدفع'),
            items: ['نقدي','بطاقة ائتمان','تحويل بنكي','شيك']
                .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setS(() => method = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            final amt = double.tryParse(amtCtrl.text) ?? 0;
            if (amt <= 0) return;
            await pp.addPayment(inv.id!, amt, method);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('تأكيد')),
        ],
      ),
    ));
  }

  Widget _badge(IconData ic, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(ic, size: 14, color: Colors.grey[400]), const SizedBox(width: 4),
    Text(t, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  ]);
  TableRow _headerRow(List<String> cols) => TableRow(
    decoration: const BoxDecoration(color: Color(0xFFF0F5FF)),
    children: cols.map((c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))).toList(),
  );
  Widget _td(String t, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(t, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)));
  Widget _totRow(String l, String v, {bool bold = false, Color? color}) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(v, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ]));
}

// ── Purchase Invoice Dialog ───────────────────────────────────────────────────
class _PurchaseInvoiceDialog extends StatefulWidget {
  const _PurchaseInvoiceDialog();
  @override State<_PurchaseInvoiceDialog> createState() => _PurchaseInvoiceDialogState();
}

class _PurchaseInvoiceDialogState extends State<_PurchaseInvoiceDialog> {
  final _form       = GlobalKey<FormState>();
  final _dateCtrl   = TextEditingController(text: AppUtils.today());
  final _notesCtrl  = TextEditingController();
  final _discCtrl   = TextEditingController(text: '0');
  final _taxCtrl    = TextEditingController(text: '0');
  int? _supplierId;
  String _payMethod = 'نقدي';
  String _status    = 'pending';
  List<InvoiceItem> _items = [];
  bool _saving = false;
  String _invNum = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await context.read<PurchasesProvider>().generateInvoiceNumber();
    setState(() => _invNum = n);
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.qty * i.unitPrice);
  double get _discAmt  => _subtotal * (double.tryParse(_discCtrl.text) ?? 0) / 100;
  double get _taxAmt   => (_subtotal - _discAmt) * (double.tryParse(_taxCtrl.text) ?? 0) / 100;
  double get _total    => _subtotal - _discAmt + _taxAmt;

  void _addItem() {
    final products = context.read<AppProvider>().products;
    showDialog(context: context, builder: (_) => _AddPurchaseItemDialog(
      products: products,
      onAdd: (item) => setState(() => _items = [..._items, item]),
    ));
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف منتجاً واحداً على الأقل')));
      return;
    }
    setState(() => _saving = true);
    final inv = PurchaseInvoice(
      invoiceNumber: _invNum, supplierId: _supplierId,
      date: _dateCtrl.text, discountRate: double.tryParse(_discCtrl.text) ?? 0,
      discountAmount: _discAmt, taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      taxAmount: _taxAmt, subtotal: _subtotal, total: _total,
      paidAmount: _status == 'paid' ? _total : 0,
      remaining: _status == 'paid' ? 0 : _total,
      paymentMethod: _payMethod, status: _status == 'paid' ? 'paid' : 'pending',
      notes: _notesCtrl.text.trim(), items: _items,
    );
    await context.read<PurchasesProvider>().saveInvoice(inv);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final cur = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    final cs  = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(children: [
        const Text('فاتورة مشتريات جديدة'), const Spacer(),
        Text(_invNum, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ]),
      content: SizedBox(width: 800, child: Form(key: _form,
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<int?>(
              value: _supplierId,
              decoration: const InputDecoration(labelText: 'المورد'),
              items: [const DropdownMenuItem(value: null, child: Text('مورد غير محدد')),
                ...app.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))],
              onChanged: (v) => setState(() => _supplierId = v),
            )),
            const SizedBox(width: 12),
            SizedBox(width: 160, child: TextFormField(
              controller: _dateCtrl, readOnly: true,
              decoration: const InputDecoration(labelText: 'التاريخ', suffixIcon: Icon(Icons.calendar_today, size: 16)),
              validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(),
                    firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) _dateCtrl.text = d.toIso8601String().substring(0, 10);
              },
            )),
            const SizedBox(width: 12),
            SizedBox(width: 180, child: DropdownButtonFormField<String>(
              value: _payMethod, decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: ['نقدي','بطاقة ائتمان','تحويل بنكي','شيك','آجل']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _payMethod = v!),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            SizedBox(width: 160, child: DropdownButtonFormField<String>(
              value: _status, decoration: const InputDecoration(labelText: 'الحالة'),
              items: [('pending','معلق'),('paid','مدفوع')]
                  .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            )),
            const SizedBox(width: 12),
            SizedBox(width: 140, child: TextFormField(controller: _discCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'خصم %', suffixText: '%'))),
            const SizedBox(width: 12),
            SizedBox(width: 140, child: TextFormField(controller: _taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'ضريبة %', suffixText: '%'))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Text('البنود', style: Theme.of(context).textTheme.titleSmall), const Spacer(),
            ElevatedButton.icon(onPressed: _addItem,
                icon: const Icon(Icons.add, size: 16), label: const Text('إضافة منتج'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
          ]),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: const Center(child: Text('أضف منتجات', style: TextStyle(color: Colors.grey))))
          else
            Table(
              border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5), 4: FixedColumnWidth(44)},
              children: [
                TableRow(decoration: const BoxDecoration(color: Color(0xFFF0F5FF)),
                  children: ['المنتج','الكمية','سعر الشراء','الإجمالي',''].map((h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))).toList()),
                ..._items.asMap().entries.map((e) => TableRow(children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(e.value.productName ?? '', style: const TextStyle(fontSize: 13))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(AppUtils.num(e.value.qty), style: const TextStyle(fontSize: 13))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(AppUtils.money(e.value.unitPrice, cur: cur), style: const TextStyle(fontSize: 13))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(AppUtils.money(e.value.total, cur: cur),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary))),
                  IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                      onPressed: () { final l = [..._items]; l.removeAt(e.key); setState(() => _items = l); }),
                ])),
              ],
            ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: SizedBox(width: 300, child: Column(children: [
            _tot('المجموع الفرعي', AppUtils.money(_subtotal, cur: cur)),
            if (_discAmt > 0) _tot('الخصم', '- ${AppUtils.money(_discAmt, cur: cur)}', color: Colors.red),
            _tot('الضريبة', AppUtils.money(_taxAmt, cur: cur)), const Divider(),
            _tot('الإجمالي', AppUtils.money(_total, cur: cur), bold: true, color: cs.primary),
          ]))),
          const SizedBox(height: 12),
          TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات')),
        ])),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('حفظ الفاتورة')),
      ],
    );
  }

  Widget _tot(String l, String v, {bool bold = false, Color? color}) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(v, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ]));
}

class _AddPurchaseItemDialog extends StatefulWidget {
  final List<Product> products;
  final void Function(InvoiceItem) onAdd;
  const _AddPurchaseItemDialog({required this.products, required this.onAdd});
  @override State<_AddPurchaseItemDialog> createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<_AddPurchaseItemDialog> {
  Product? _selected;
  final _qtyCtrl   = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final total = (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0);
    return AlertDialog(
      title: const Text('إضافة منتج'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<Product>(
          decoration: const InputDecoration(labelText: 'المنتج *'),
          items: widget.products.map((p) => DropdownMenuItem(value: p, child: Text(p.nameAr))).toList(),
          onChanged: (p) => setState(() {
            _selected = p;
            _priceCtrl.text = p!.costPrice.toString();
          }),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: _qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'الكمية'))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'سعر الشراء'))),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(AppUtils.money(total), style: TextStyle(fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary)),
          ])),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _selected == null ? null : () {
            final item = InvoiceItem(
              productId: _selected!.id, productName: _selected!.nameAr,
              qty: double.tryParse(_qtyCtrl.text) ?? 1,
              unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
            )..calculate();
            widget.onAdd(item);
            Navigator.pop(context);
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
