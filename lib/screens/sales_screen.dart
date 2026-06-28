import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sales_provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_service.dart';
import '../core/utils.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();

  static const _statuses = [
    ('all','الكل'), ('pending','معلق'), ('paid','مدفوع'),
    ('partial','جزئي'), ('overdue','متأخر'), ('cancelled','ملغي'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadInvoices();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _newInvoice() => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => const _SalesInvoiceDialog(),
  );

  void _viewInvoice(SalesInvoice inv) => showDialog(
    context: context,
    builder: (_) => _InvoiceDetailDialog(invoice: inv),
  );

  @override
  Widget build(BuildContext context) {
    final sp      = context.watch<SalesProvider>();
    final cs      = Theme.of(context).colorScheme;
    final settings= context.watch<SettingsProvider>();
    final cur     = settings.get('currency', defaultValue: 'ريال');

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('المبيعات', style: Theme.of(context).textTheme.headlineSmall),
              Text('${sp.invoices.length} فاتورة', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ]),
            const Spacer(),
            ElevatedButton.icon(onPressed: _newInvoice,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('فاتورة جديدة')),
          ]),
          const SizedBox(height: 16),
          // Search
          AppSearchBar(hint: 'بحث برقم الفاتورة أو العميل...', controller: _search,
              onChanged: (v) => sp.setSearch(v)),
          const SizedBox(height: 12),
          // Status tabs
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (i) => sp.setFilter(_statuses[i].$1),
            tabs: _statuses.map((s) => Tab(text: s.$2)).toList(),
          ),
        ]),
      ),
      // List
      Expanded(
        child: sp.isLoading
            ? const Center(child: CircularProgressIndicator())
            : sp.invoices.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'لا توجد فواتير')
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: sp.invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final inv = sp.invoices[i];
                      return _InvoiceCard(
                        invoice: inv, cur: cur,
                        onTap: () async {
                          final full = await sp.getInvoiceById(inv.id!);
                          if (full != null && mounted) _viewInvoice(full);
                        },
                        onDelete: () async {
                          final ok = await showConfirmDialog(context,
                              title: 'حذف الفاتورة', content: 'حذف الفاتورة ${inv.invoiceNumber}؟', isDanger: true);
                          if (ok && mounted) await sp.deleteInvoice(inv.id!);
                        },
                      );
                    },
                  ),
      ),
    ]);
  }
}

// ── Invoice Card ──────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final SalesInvoice invoice;
  final String cur;
  final VoidCallback onTap, onDelete;

  const _InvoiceCard({required this.invoice, required this.cur,
      required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final isLight  = Theme.of(context).brightness == Brightness.light;
    final status   = invoice.status;
    final color    = AppTheme.statusColor(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
        ),
        child: Row(children: [
          // Status bar
          Container(width: 4, height: 52,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 16),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(invoice.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                child: Text(AppTheme.statusLabel(status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(invoice.customerName ?? 'عميل غير محدد',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ])),
          // Amount + date
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppUtils.money(invoice.total, cur: cur),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: cs.primary)),
            const SizedBox(height: 4),
            Text(AppUtils.date(invoice.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            if (invoice.remaining > 0)
              Text('متبقي: ${AppUtils.money(invoice.remaining, cur: cur)}',
                  style: const TextStyle(fontSize: 11, color: Colors.red)),
          ]),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: onDelete),
        ]),
      ),
    );
  }
}

// ── Invoice Detail Dialog ─────────────────────────────────────────────────────
class _InvoiceDetailDialog extends StatelessWidget {
  final SalesInvoice invoice;
  const _InvoiceDetailDialog({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final cur      = settings.get('currency', defaultValue: 'ريال');
    final sp       = context.read<SalesProvider>();
    final cs       = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(children: [
        Text('فاتورة ${invoice.invoiceNumber}'),
        const Spacer(),
        // Print
        IconButton(
          icon: const Icon(Icons.print_outlined),
          tooltip: 'طباعة',
          onPressed: () async {
            final settingsMap = await context.read<SettingsProvider>().settings;
            final bytes = await PdfService.instance.buildInvoicePdf(invoice, settingsMap);
            await PdfService.instance.printPdf(bytes);
          },
        ),
        // Pay button
        if (invoice.remaining > 0)
          ElevatedButton.icon(
            icon: const Icon(Icons.payment_outlined, size: 16),
            label: const Text('تسجيل دفعة'),
            onPressed: () => _payDialog(context, sp, cur),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success, foregroundColor: Colors.white),
          ),
      ]),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Meta
            Wrap(spacing: 16, runSpacing: 8, children: [
              _badge(Icons.person_outline, invoice.customerName ?? 'غير محدد'),
              _badge(Icons.calendar_today_outlined, AppUtils.date(invoice.date)),
              _badge(Icons.payments_outlined, invoice.paymentMethod),
              if (invoice.dueDate != null)
                _badge(Icons.alarm_outlined, 'استحقاق: ${AppUtils.date(invoice.dueDate)}'),
            ]),
            const SizedBox(height: 16),
            // Items table
            Table(
              border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5)},
              children: [
                _headerRow(['المنتج', 'الكمية', 'السعر', 'الإجمالي']),
                ...invoice.items.map((item) => TableRow(children: [
                  _td(item.productName ?? ''),
                  _td(AppUtils.num(item.qty)),
                  _td(AppUtils.money(item.unitPrice, cur: cur)),
                  _td(AppUtils.money(item.total, cur: cur), bold: true),
                ])),
              ],
            ),
            const SizedBox(height: 16),
            // Totals
            Align(alignment: Alignment.centerLeft,
              child: SizedBox(width: 300, child: Column(children: [
                _totRow('المجموع الفرعي', AppUtils.money(invoice.subtotal, cur: cur)),
                if (invoice.discountAmount > 0)
                  _totRow('الخصم', '- ${AppUtils.money(invoice.discountAmount, cur: cur)}',
                      color: Colors.red),
                _totRow('الضريبة (${invoice.taxRate.toStringAsFixed(0)}%)',
                    AppUtils.money(invoice.taxAmount, cur: cur)),
                const Divider(),
                _totRow('الإجمالي', AppUtils.money(invoice.total, cur: cur),
                    bold: true, color: cs.primary),
                if (invoice.paidAmount > 0)
                  _totRow('المدفوع', AppUtils.money(invoice.paidAmount, cur: cur),
                      color: AppTheme.success),
                if (invoice.remaining > 0)
                  _totRow('المتبقي', AppUtils.money(invoice.remaining, cur: cur),
                      color: Colors.red),
              ])),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }

  void _payDialog(BuildContext context, SalesProvider sp, String cur) async {
    final amtCtrl = TextEditingController(
        text: invoice.remaining.toStringAsFixed(2));
    String method = 'نقدي';
    await showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'المبلغ ($cur)')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: method,
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
            await sp.addPayment(invoice.id!, amt, method);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('تأكيد')),
        ],
      ),
    ));
  }

  Widget _badge(IconData ic, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(ic, size: 14, color: Colors.grey[400]),
    const SizedBox(width: 4),
    Text(t, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  ]);

  TableRow _headerRow(List<String> cols) => TableRow(
    decoration: const BoxDecoration(color: Color(0xFFF0F5FF)),
    children: cols.map((c) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    )).toList(),
  );

  Widget _td(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
  );

  Widget _totRow(String l, String v, {bool bold = false, Color? color}) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(v, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ]));
}

// ── Sales Invoice Dialog (Create) ─────────────────────────────────────────────
class _SalesInvoiceDialog extends StatefulWidget {
  const _SalesInvoiceDialog();
  @override State<_SalesInvoiceDialog> createState() => _SalesInvoiceDialogState();
}

class _SalesInvoiceDialogState extends State<_SalesInvoiceDialog> {
  final _form       = GlobalKey<FormState>();
  final _dateCtrl   = TextEditingController(text: AppUtils.today());
  final _dueDateCtrl= TextEditingController();
  final _notesCtrl  = TextEditingController();
  final _discCtrl   = TextEditingController(text: '0');
  final _taxCtrl    = TextEditingController(text: '0');

  int? _customerId;
  String _payMethod = 'نقدي';
  String _status    = 'pending';
  List<InvoiceItem> _items = [];
  bool _saving = false;
  String _invoiceNum = '';

  @override
  void initState() {
    super.initState();
    _loadInvoiceNumber();
  }

  Future<void> _loadInvoiceNumber() async {
    final num = await context.read<SalesProvider>().generateInvoiceNumber();
    setState(() => _invoiceNum = num);
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.qty * i.unitPrice);
  double get _discAmt  => _subtotal * (double.tryParse(_discCtrl.text) ?? 0) / 100;
  double get _taxAmt   => (_subtotal - _discAmt) * (double.tryParse(_taxCtrl.text) ?? 0) / 100;
  double get _total    => _subtotal - _discAmt + _taxAmt;

  void _addItem() {
    final products = context.read<AppProvider>().products;
    if (products.isEmpty) return;
    showDialog(context: context, builder: (_) => _AddItemDialog(
      products: products,
      onAdd: (item) => setState(() { _items = [..._items, item]; }),
    ));
  }

  void _removeItem(int i) => setState(() {
    final l = [..._items]; l.removeAt(i); _items = l;
  });

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أضف منتجاً واحداً على الأقل')));
      return;
    }
    setState(() => _saving = true);
    final disc = double.tryParse(_discCtrl.text) ?? 0;
    final tax  = double.tryParse(_taxCtrl.text) ?? 0;
    final inv  = SalesInvoice(
      invoiceNumber: _invoiceNum,
      customerId   : _customerId,
      date         : _dateCtrl.text,
      dueDate      : _dueDateCtrl.text.isEmpty ? null : _dueDateCtrl.text,
      discountRate : disc,
      discountAmount: _discAmt,
      taxRate      : tax,
      taxAmount    : _taxAmt,
      subtotal     : _subtotal,
      total        : _total,
      paidAmount   : _status == 'paid' ? _total : 0,
      remaining    : _status == 'paid' ? 0 : _total,
      paymentMethod: _payMethod,
      status       : _status == 'paid' ? 'paid' : 'pending',
      notes        : _notesCtrl.text.trim(),
      items        : _items,
    );
    await context.read<SalesProvider>().saveInvoice(inv);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app      = context.read<AppProvider>();
    final settings = context.read<SettingsProvider>();
    final cur      = settings.get('currency', defaultValue: 'ريال');
    final cs       = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(children: [
        const Text('فاتورة مبيعات جديدة'),
        const Spacer(),
        Text(_invoiceNum, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ]),
      content: SizedBox(
        width: 800,
        child: Form(key: _form,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Row 1
              Row(children: [
                Expanded(child: DropdownButtonFormField<int?>(
                  value: _customerId,
                  decoration: const InputDecoration(labelText: 'العميل'),
                  items: [const DropdownMenuItem(value: null, child: Text('عميل غير محدد')),
                    ...app.customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
                  onChanged: (v) => setState(() => _customerId = v),
                )),
                const SizedBox(width: 12),
                SizedBox(width: 160, child: TextFormField(
                  controller: _dateCtrl, readOnly: true,
                  decoration: const InputDecoration(labelText: 'التاريخ',
                      suffixIcon: Icon(Icons.calendar_today, size: 16)),
                  validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
                  onTap: () async {
                    final d = await showDatePicker(context: context,
                        initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) _dateCtrl.text = d.toIso8601String().substring(0, 10);
                  },
                )),
                const SizedBox(width: 12),
                SizedBox(width: 160, child: TextFormField(
                  controller: _dueDateCtrl, readOnly: true,
                  decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق',
                      suffixIcon: Icon(Icons.alarm_outlined, size: 16)),
                  onTap: () async {
                    final d = await showDatePicker(context: context,
                        initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (d != null) _dueDateCtrl.text = d.toIso8601String().substring(0, 10);
                  },
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(width: 200, child: DropdownButtonFormField<String>(
                  value: _payMethod,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                  items: ['نقدي','بطاقة ائتمان','تحويل بنكي','شيك','آجل']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _payMethod = v!),
                )),
                const SizedBox(width: 12),
                SizedBox(width: 200, child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
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
              // Items
              Row(children: [
                Text('البنود', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                ElevatedButton.icon(onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 16), label: const Text('إضافة منتج'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
              ]),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(child: Text('أضف منتجات للفاتورة', style: TextStyle(color: Colors.grey))),
                )
              else
                Table(
                  border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1.5), 4: FixedColumnWidth(44)},
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF0F5FF)),
                      children: ['المنتج','الكمية','السعر','الإجمالي',''].map((h) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      )).toList(),
                    ),
                    ..._items.asMap().entries.map((e) => TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8),
                          child: Text(e.value.productName ?? '', style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.all(8),
                          child: Text(AppUtils.num(e.value.qty), style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.all(8),
                          child: Text(AppUtils.money(e.value.unitPrice, cur: cur), style: const TextStyle(fontSize: 13))),
                      Padding(padding: const EdgeInsets.all(8),
                          child: Text(AppUtils.money(e.value.total, cur: cur),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary))),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                          onPressed: () => _removeItem(e.key)),
                    ])),
                  ],
                ),
              const SizedBox(height: 16),
              // Totals
              Align(alignment: Alignment.centerLeft,
                child: SizedBox(width: 300, child: Column(children: [
                  _tot('المجموع الفرعي', AppUtils.money(_subtotal, cur: cur)),
                  if (_discAmt > 0) _tot('الخصم', '- ${AppUtils.money(_discAmt, cur: cur)}', color: Colors.red),
                  _tot('الضريبة', AppUtils.money(_taxAmt, cur: cur)),
                  const Divider(),
                  _tot('الإجمالي', AppUtils.money(_total, cur: cur), bold: true, color: cs.primary),
                ])),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _notesCtrl, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'ملاحظات')),
            ]),
          ),
        ),
      ),
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

// ── Add Item Dialog ───────────────────────────────────────────────────────────
class _AddItemDialog extends StatefulWidget {
  final List<Product> products;
  final void Function(InvoiceItem) onAdd;
  const _AddItemDialog({required this.products, required this.onAdd});
  @override State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  Product? _selected;
  final _qtyCtrl   = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _discCtrl  = TextEditingController(text: '0');

  double get _total {
    final q = double.tryParse(_qtyCtrl.text) ?? 0;
    final p = double.tryParse(_priceCtrl.text) ?? 0;
    final d = double.tryParse(_discCtrl.text) ?? 0;
    return q * p * (1 - d / 100);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة منتج'),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<Product>(
            decoration: const InputDecoration(labelText: 'المنتج *'),
            items: widget.products.map((p) => DropdownMenuItem(value: p,
                child: Text('${p.nameAr} (مخزون: ${AppUtils.num(p.stockQty)})'))).toList(),
            onChanged: (p) {
              setState(() {
                _selected = p;
                _priceCtrl.text = p!.salePrice.toString();
              });
            },
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
                decoration: const InputDecoration(labelText: 'السعر'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _discCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'خصم %'))),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(AppUtils.money(_total),
                  style: TextStyle(fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary)),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _selected == null ? null : () {
            final item = InvoiceItem(
              productId  : _selected!.id,
              productName: _selected!.nameAr,
              qty        : double.tryParse(_qtyCtrl.text) ?? 1,
              unitPrice  : double.tryParse(_priceCtrl.text) ?? _selected!.salePrice,
              discountRate: double.tryParse(_discCtrl.text) ?? 0,
              taxRate    : _selected!.taxRate,
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
