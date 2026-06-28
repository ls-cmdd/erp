import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../core/utils.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FinanceProvider>().init());
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [
          Row(children: [
            Text('المالية', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _addExpenseDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة مصروف'),
            ),
          ]),
          const SizedBox(height: 16),
          TabBar(controller: _tabs, tabs: const [
            Tab(text: 'الأرباح والخسائر'), Tab(text: 'المصروفات'),
            Tab(text: 'المدفوعات'), Tab(text: 'التدفق النقدي'),
          ]),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _ProfitLossTab(),
        _ExpensesTab(),
        _PaymentsTab(),
        _CashflowTab(),
      ])),
    ]);
  }

  void _addExpenseDialog(BuildContext context) => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => const _ExpenseFormDialog(),
  );
}

// ── Profit & Loss Tab ─────────────────────────────────────────────────────────
class _ProfitLossTab extends StatefulWidget {
  @override State<_ProfitLossTab> createState() => _ProfitLossTabState();
}

class _ProfitLossTabState extends State<_ProfitLossTab> {
  String? _start, _end;
  Map<String, double> _data = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await context.read<FinanceProvider>().getProfitLoss(startDate: _start, endDate: _end);
    setState(() => _data = d);
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    final cs  = Theme.of(context).colorScheme;
    final profit = _data['net_profit'] ?? 0;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ListView(padding: const EdgeInsets.all(24), children: [
      // Date filter
      Row(children: [
        _DateBtn('من', _start, (v) => setState(() { _start = v; _load(); })),
        const SizedBox(width: 12),
        _DateBtn('إلى', _end, (v) => setState(() { _end = v; _load(); })),
        const SizedBox(width: 12),
        if (_start != null || _end != null)
          TextButton(onPressed: () => setState(() { _start = null; _end = null; _load(); }),
              child: const Text('مسح الفلتر')),
      ]),
      const SizedBox(height: 20),
      // Profit summary
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: profit >= 0 ? [const Color(0xFF0E9F6E), const Color(0xFF057A55)]
                : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('صافي الربح', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(AppUtils.money(profit, cur: cur),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(profit >= 0 ? 'ربح' : 'خسارة',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 20),
      // Cards
      GridView(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260, mainAxisExtent: 110, crossAxisSpacing: 16, mainAxisSpacing: 16),
        children: [
          _PnlCard('إجمالي المبيعات', _data['total_sales'] ?? 0, Colors.green, Icons.trending_up_rounded, cur),
          _PnlCard('إجمالي المشتريات', _data['total_purchases'] ?? 0, Colors.blue, Icons.shopping_basket_rounded, cur),
          _PnlCard('إجمالي المصروفات', _data['total_expenses'] ?? 0, Colors.orange, Icons.payments_rounded, cur),
          _PnlCard('الربح الإجمالي', _data['gross_profit'] ?? 0, Colors.teal, Icons.account_balance_wallet_rounded, cur),
          _PnlCard('ضريبة محصلة', _data['tax_collected'] ?? 0, Colors.purple, Icons.receipt_outlined, cur),
          _PnlCard('ضريبة مدفوعة', _data['tax_paid'] ?? 0, Colors.red, Icons.receipt_long_outlined, cur),
        ],
      ),
    ]);
  }
}

class _PnlCard extends StatelessWidget {
  final String label; final double value; final Color color; final IconData icon; final String cur;
  const _PnlCard(this.label, this.value, this.color, this.icon, this.cur);
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
          const Spacer(),
        ]),
        const SizedBox(height: 10),
        Text(AppUtils.money(value, cur: cur),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
    );
  }
}

// ── Expenses Tab ──────────────────────────────────────────────────────────────
class _ExpensesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fp  = context.watch<FinanceProvider>();
    final cur = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    final total = fp.expenses.fold(0.0, (s, e) => s + e.amount);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${fp.expenses.length} مصروف', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            Text('الإجمالي: ${AppUtils.money(total, cur: cur)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
      Expanded(
        child: fp.expenses.isEmpty
            ? const EmptyState(icon: Icons.payments_outlined, title: 'لا توجد مصروفات')
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: fp.expenses.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = fp.expenses[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.payments_outlined, color: Colors.orange, size: 18)),
                    title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${e.category ?? 'غير مصنف'}  ·  ${AppUtils.date(e.date)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(AppUtils.money(e.amount, cur: cur),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => fp.deleteExpense(e.id!)),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────
class _PaymentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fp  = context.watch<FinanceProvider>();
    final cur = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    return fp.payments.isEmpty
        ? const EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'لا توجد مدفوعات')
        : ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: fp.payments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p   = fp.payments[i];
              final isIn = p.type == 'receipt';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isIn ? Colors.green.withOpacity(.1) : Colors.red.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isIn ? Colors.green : Colors.red, size: 18)),
                title: Text(p.partyName ?? (isIn ? 'مقبوضات' : 'مدفوعات'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${p.paymentMethod}  ·  ${AppUtils.date(p.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: Text(
                  '${isIn ? '+' : '-'} ${AppUtils.money(p.amount, cur: cur)}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                      color: isIn ? Colors.green : Colors.red),
                ),
              );
            },
          );
  }
}

// ── Cashflow Tab ──────────────────────────────────────────────────────────────
class _CashflowTab extends StatefulWidget {
  @override State<_CashflowTab> createState() => _CashflowTabState();
}

class _CashflowTabState extends State<_CashflowTab> {
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await context.read<FinanceProvider>().getCashflow(year: DateTime.now().year.toString());
    setState(() => _data = d);
  }

  @override
  Widget build(BuildContext context) {
    final cur     = context.read<SettingsProvider>().get('currency', defaultValue: 'ريال');
    final cs      = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final months  = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

    final inMap  = {for (final d in _data) d['month'].toString(): (d['inflow'] as num?)?.toDouble() ?? 0};
    final outMap = {for (final d in _data) d['month'].toString(): (d['outflow'] as num?)?.toDouble() ?? 0};
    double maxY  = 1000;
    final allVals= [...inMap.values, ...outMap.values];
    if (allVals.isNotEmpty) maxY = (allVals.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    return ListView(padding: const EdgeInsets.all(24), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('التدفق النقدي ${DateTime.now().year}', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            _legend('وارد', Colors.green), const SizedBox(width: 16), _legend('صادر', Colors.red),
          ]),
          const SizedBox(height: 20),
          SizedBox(height: 260, child: BarChart(BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text(months[v.toInt()].substring(0, 3),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]))))),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 52,
                getTitlesWidget: (v, _) => Text(AppUtils.num(v),
                    style: TextStyle(fontSize: 9, color: Colors.grey[500])))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles  : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(.12), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(12, (i) {
              final mo = (i + 1).toString().padLeft(2, '0');
              return BarChartGroupData(x: i, barsSpace: 2, barRods: [
                BarChartRodData(toY: inMap[mo] ?? 0, color: Colors.green.withOpacity(.8), width: 10, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: outMap[mo] ?? 0, color: Colors.red.withOpacity(.8), width: 10, borderRadius: BorderRadius.circular(4)),
              ]);
            }),
          ))),
        ]),
      ),
    ]);
  }

  Widget _legend(String l, Color c) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6), Text(l, style: const TextStyle(fontSize: 12)),
  ]);
}

// ── Expense Form Dialog ───────────────────────────────────────────────────────
class _ExpenseFormDialog extends StatefulWidget {
  const _ExpenseFormDialog();
  @override State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  final _form    = GlobalKey<FormState>();
  final _descCtrl= TextEditingController();
  final _amtCtrl = TextEditingController();
  final _dateCtrl= TextEditingController(text: AppUtils.today());
  final _benCtrl = TextEditingController();
  final _notesCtrl= TextEditingController();
  String? _category;
  String _method = 'نقدي';
  bool _saving   = false;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final e = Expense(
      description: _descCtrl.text.trim(), amount: double.tryParse(_amtCtrl.text) ?? 0,
      date: _dateCtrl.text, paymentMethod: _method, category: _category,
      beneficiary: _benCtrl.text.trim(), notes: _notesCtrl.text.trim(),
    );
    await context.read<FinanceProvider>().saveExpense(e);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مصروف'),
      content: SizedBox(width: 520, child: Form(key: _form,
        child: SingleChildScrollView(child: Column(children: [
          TextFormField(controller: _descCtrl,
              validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
              decoration: const InputDecoration(labelText: 'الوصف *')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
                decoration: const InputDecoration(labelText: 'المبلغ *'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _dateCtrl, readOnly: true,
              decoration: const InputDecoration(labelText: 'التاريخ', suffixIcon: Icon(Icons.calendar_today, size: 16)),
              onTap: () async {
                final d = await showDatePicker(context: context,
                    initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) _dateCtrl.text = d.toIso8601String().substring(0, 10);
              },
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String?>(
              value: _category,
              decoration: const InputDecoration(labelText: 'الفئة'),
              items: [const DropdownMenuItem(value: null, child: Text('غير مصنف')),
                ...AppConstants.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
              onChanged: (v) => setState(() => _category = v),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: AppConstants.paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            )),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _benCtrl, decoration: const InputDecoration(labelText: 'الجهة المستفيدة')),
          const SizedBox(height: 12),
          TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات')),
        ])),
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('حفظ')),
      ],
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label; final String? value; final void Function(String) onPicked;
  const _DateBtn(this.label, this.value, this.onPicked);
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final d = await showDatePicker(context: context,
            initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (d != null) onPicked(d.toIso8601String().substring(0, 10));
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 14),
      label: Text(value != null ? '$label: ${AppUtils.date(value)}' : label),
    );
  }
}
