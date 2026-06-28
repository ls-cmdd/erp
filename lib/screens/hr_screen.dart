import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/hr_provider.dart';
import '../core/utils.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../widgets/app_widgets.dart';

class HRScreen extends StatefulWidget {
  const HRScreen({super.key});
  @override State<HRScreen> createState() => _HRScreenState();
}

class _HRScreenState extends State<HRScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HRProvider>().init());
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
            Text('الموارد البشرية', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            Builder(builder: (ctx) => ElevatedButton.icon(
              onPressed: () => _tabAction(ctx),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة'),
            )),
          ]),
          const SizedBox(height: 16),
          TabBar(controller: _tabs, tabs: const [
            Tab(text: 'الموظفون'), Tab(text: 'الحضور والغياب'),
            Tab(text: 'الإجازات'), Tab(text: 'كشف الرواتب'),
          ]),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _EmployeesTab(),
        _AttendanceTab(),
        _LeavesTab(),
        _PayrollTab(),
      ])),
    ]);
  }

  void _tabAction(BuildContext context) {
    switch (_tabs.index) {
      case 0: showDialog(context: context, barrierDismissible: false, builder: (_) => const _EmployeeFormDialog()); break;
      case 1: showDialog(context: context, barrierDismissible: false, builder: (_) => _AttendanceFormDialog()); break;
      case 2: showDialog(context: context, barrierDismissible: false, builder: (_) => const _LeaveFormDialog()); break;
      case 3: _generatePayrollDialog(context); break;
    }
  }

  void _generatePayrollDialog(BuildContext context) async {
    final now   = DateTime.now();
    int month   = now.month;
    int year    = now.year;
    await showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('توليد كشف الرواتب'),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(value: month,
            decoration: const InputDecoration(labelText: 'الشهر'),
            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1,
                child: Text(AppUtils.monthYear(i + 1, year)))).toList(),
            onChanged: (v) => setS(() => month = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(initialValue: year.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => year = int.tryParse(v) ?? year,
            decoration: const InputDecoration(labelText: 'السنة'),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            await context.read<HRProvider>().generateMonthlyPayroll(month, year);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('توليد')),
        ],
      ),
    ));
  }
}

// ── Employees Tab ─────────────────────────────────────────────────────────────
class _EmployeesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hr = context.watch<HRProvider>();
    final cs = Theme.of(context).colorScheme;
    if (hr.employees.isEmpty) return const EmptyState(icon: Icons.badge_outlined, title: 'لا يوجد موظفون');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: hr.employees.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = hr.employees[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: CircleAvatar(radius: 22,
            backgroundColor: cs.primary.withOpacity(.12),
            child: Text(e.name[0], style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary, fontSize: 16))),
          title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text([e.position, e.department].where((v) => v != null && v!.isNotEmpty).join(' · '),
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(AppUtils.money(e.totalSalary), style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
              Text(e.phone ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => showDialog(context: context, barrierDismissible: false,
                    builder: (_) => _EmployeeFormDialog(employee: e))),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => hr.deleteEmployee(e.id!)),
          ]),
        );
      },
    );
  }
}

// ── Attendance Tab ────────────────────────────────────────────────────────────
class _AttendanceTab extends StatefulWidget {
  @override State<_AttendanceTab> createState() => _AttendanceTabState();
}
class _AttendanceTabState extends State<_AttendanceTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<HRProvider>().loadAttendance());
  }
  @override
  Widget build(BuildContext context) {
    final records = context.watch<HRProvider>().attendance;
    if (records.isEmpty) return const EmptyState(icon: Icons.access_time_outlined, title: 'لا توجد سجلات حضور');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r      = records[i];
        final status = r['status']?.toString() ?? 'present';
        final color  = status == 'present' ? Colors.green : status == 'absent' ? Colors.red : Colors.orange;
        return ListTile(
          leading: Container(width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(status == 'present' ? Icons.check_circle_outline : Icons.cancel_outlined, color: color, size: 18)),
          title: Text(r['employee_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${AppUtils.date(r['date']?.toString())}  ·  دخول: ${r['check_in'] ?? '--'}  خروج: ${r['check_out'] ?? '--'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: _statusChip(status, color),
        );
      },
    );
  }
  Widget _statusChip(String s, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
    child: Text(_statusLabel(s), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)));
  String _statusLabel(String s) => switch(s) {
    'present' => 'حاضر', 'absent' => 'غائب', 'late' => 'متأخر', _ => s };
}

// ── Leaves Tab ────────────────────────────────────────────────────────────────
class _LeavesTab extends StatefulWidget {
  @override State<_LeavesTab> createState() => _LeavesTabState();
}
class _LeavesTabState extends State<_LeavesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<HRProvider>().loadLeaves());
  }
  @override
  Widget build(BuildContext context) {
    final leaves = context.watch<HRProvider>().leaves;
    final hr     = context.read<HRProvider>();
    if (leaves.isEmpty) return const EmptyState(icon: Icons.event_available_outlined, title: 'لا توجد طلبات إجازة');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: leaves.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final l      = leaves[i];
        final status = l['status']?.toString() ?? 'pending';
        final color  = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
        return ListTile(
          title: Text(l['employee_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${l['leave_type'] ?? ''}  ·  ${AppUtils.date(l['start_date']?.toString())} → ${AppUtils.date(l['end_date']?.toString())}  ·  ${l['days'] ?? 0} يوم',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
              child: Text(status == 'approved' ? 'موافق' : status == 'rejected' ? 'مرفوض' : 'معلق',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
            if (status == 'pending') ...[
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  onPressed: () => hr.approveLeave(l['id'] as int)),
              IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                  onPressed: () => hr.rejectLeave(l['id'] as int)),
            ],
          ]),
        );
      },
    );
  }
}

// ── Payroll Tab ───────────────────────────────────────────────────────────────
class _PayrollTab extends StatefulWidget {
  @override State<_PayrollTab> createState() => _PayrollTabState();
}
class _PayrollTabState extends State<_PayrollTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<HRProvider>().loadPayroll());
  }
  @override
  Widget build(BuildContext context) {
    final payroll = context.watch<HRProvider>().payroll;
    final hr      = context.read<HRProvider>();
    if (payroll.isEmpty) return const EmptyState(icon: Icons.receipt_long_outlined,
        title: 'لا يوجد كشف رواتب', subtitle: 'اضغط إضافة لتوليد كشف رواتب شهري');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: payroll.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p     = payroll[i];
        final color = p.status == 'approved' ? Colors.green : Colors.orange;
        return ListTile(
          leading: CircleAvatar(radius: 20,
            backgroundColor: color.withOpacity(.12),
            child: Text(p.employeeName?[0] ?? 'م',
                style: TextStyle(fontWeight: FontWeight.w700, color: color))),
          title: Text(p.employeeName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${AppUtils.monthYear(p.month, p.year)}  ·  ${p.payrollNumber}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(AppUtils.money(p.netSalary),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            const SizedBox(width: 8),
            if (p.status == 'draft')
              ElevatedButton(
                onPressed: () => hr.approvePayroll(p.id!),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('اعتماد', style: TextStyle(fontSize: 12)),
              )
            else
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('معتمد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green))),
          ]),
        );
      },
    );
  }
}

// ── Employee Form Dialog ──────────────────────────────────────────────────────
class _EmployeeFormDialog extends StatefulWidget {
  final Employee? employee;
  const _EmployeeFormDialog({this.employee});
  @override State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}
class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _form     = GlobalKey<FormState>();
  late final _name    = TextEditingController(text: widget.employee?.name ?? '');
  late final _pos     = TextEditingController(text: widget.employee?.position ?? '');
  late final _phone   = TextEditingController(text: widget.employee?.phone ?? '');
  late final _email   = TextEditingController(text: widget.employee?.email ?? '');
  late final _basic   = TextEditingController(text: (widget.employee?.basicSalary ?? 0).toString());
  late final _housing = TextEditingController(text: (widget.employee?.housingAllowance ?? 0).toString());
  late final _trans   = TextEditingController(text: (widget.employee?.transportAllowance ?? 0).toString());
  late final _hire    = TextEditingController(text: widget.employee?.hireDate ?? AppUtils.today());
  late final _iban    = TextEditingController(text: widget.employee?.iban ?? '');
  late final _idNo    = TextEditingController(text: widget.employee?.idNumber ?? '');
  String? _dept;
  bool _saving = false;

  @override
  void initState() { super.initState(); _dept = widget.employee?.department; }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final e = Employee(
      id: widget.employee?.id,
      name: _name.text.trim(), position: _pos.text.trim(),
      department: _dept, phone: _phone.text.trim(), email: _email.text.trim(),
      basicSalary: double.tryParse(_basic.text) ?? 0,
      housingAllowance: double.tryParse(_housing.text) ?? 0,
      transportAllowance: double.tryParse(_trans.text) ?? 0,
      hireDate: _hire.text, iban: _iban.text.trim(), idNumber: _idNo.text.trim(),
    );
    await context.read<HRProvider>().saveEmployee(e);
    if (mounted) Navigator.pop(context);
  }

  Widget _tf(TextEditingController c, String l, {bool req = false, double w = 240, bool isNum = false}) =>
      SizedBox(width: w, child: TextFormField(controller: c,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : null,
          inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
          validator: req ? (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null : null,
          decoration: InputDecoration(labelText: l + (req ? ' *' : ''))));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.employee == null ? 'إضافة موظف' : 'تعديل الموظف'),
      content: SizedBox(width: 620, child: Form(key: _form,
        child: SingleChildScrollView(child: Wrap(runSpacing: 16, spacing: 16, children: [
          _tf(_name, 'الاسم الكامل', req: true, w: 280),
          _tf(_pos, 'المنصب', w: 240),
          SizedBox(width: 220, child: DropdownButtonFormField<String?>(
            value: _dept, decoration: const InputDecoration(labelText: 'القسم'),
            items: [const DropdownMenuItem(value: null, child: Text('غير محدد')),
              ...AppConstants.departments.map((d) => DropdownMenuItem(value: d, child: Text(d)))],
            onChanged: (v) => setState(() => _dept = v),
          )),
          _tf(_phone, 'الهاتف', w: 200),
          _tf(_email, 'البريد الإلكتروني', w: 280),
          _tf(_idNo, 'رقم الهوية', w: 200),
          _tf(_hire, 'تاريخ التوظيف', w: 200),
          _tf(_basic, 'الراتب الأساسي', isNum: true, w: 180),
          _tf(_housing, 'بدل السكن', isNum: true, w: 180),
          _tf(_trans, 'بدل النقل', isNum: true, w: 180),
          _tf(_iban, 'رقم الآيبان', w: 320),
        ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _saving ? null : _save,
            child: Text(widget.employee == null ? 'إضافة' : 'حفظ')),
      ],
    );
  }
}

class _AttendanceFormDialog extends StatefulWidget {
  @override State<_AttendanceFormDialog> createState() => _AttendanceFormDialogState();
}
class _AttendanceFormDialogState extends State<_AttendanceFormDialog> {
  int? _empId;
  String _status = 'present';
  final _dateCtrl = TextEditingController(text: AppUtils.today());
  final _inCtrl   = TextEditingController(text: '08:00');
  final _outCtrl  = TextEditingController(text: '17:00');

  @override
  Widget build(BuildContext context) {
    final employees = context.read<HRProvider>().employees;
    return AlertDialog(
      title: const Text('تسجيل حضور'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int?>(
          value: _empId, decoration: const InputDecoration(labelText: 'الموظف *'),
          items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
          onChanged: (v) => setState(() => _empId = v),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: _dateCtrl, readOnly: true,
            decoration: const InputDecoration(labelText: 'التاريخ', suffixIcon: Icon(Icons.calendar_today, size: 16)),
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) _dateCtrl.text = d.toIso8601String().substring(0, 10);
            },
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            value: _status, decoration: const InputDecoration(labelText: 'الحالة'),
            items: [('present','حاضر'),('absent','غائب'),('late','متأخر')]
                .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
            onChanged: (v) => setState(() => _status = v!),
          )),
        ]),
        if (_status != 'absent') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _inCtrl, decoration: const InputDecoration(labelText: 'وقت الدخول'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _outCtrl, decoration: const InputDecoration(labelText: 'وقت الخروج'))),
          ]),
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _empId == null ? null : () async {
          await context.read<HRProvider>().saveAttendance({
            'employee_id': _empId, 'date': _dateCtrl.text, 'status': _status,
            'check_in': _status != 'absent' ? _inCtrl.text : null,
            'check_out': _status != 'absent' ? _outCtrl.text : null,
          });
          if (mounted) Navigator.pop(context);
        }, child: const Text('حفظ')),
      ],
    );
  }
}

class _LeaveFormDialog extends StatefulWidget {
  const _LeaveFormDialog();
  @override State<_LeaveFormDialog> createState() => _LeaveFormDialogState();
}
class _LeaveFormDialogState extends State<_LeaveFormDialog> {
  int? _empId;
  String _type = 'سنوية';
  final _startCtrl = TextEditingController(text: AppUtils.today());
  final _endCtrl   = TextEditingController();
  final _reasonCtrl= TextEditingController();

  int get _days {
    try {
      final s = DateTime.parse(_startCtrl.text);
      final e = DateTime.parse(_endCtrl.text);
      return e.difference(s).inDays + 1;
    } catch (_) { return 0; }
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.read<HRProvider>().employees;
    return AlertDialog(
      title: const Text('طلب إجازة'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int?>(
          value: _empId, decoration: const InputDecoration(labelText: 'الموظف *'),
          items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
          onChanged: (v) => setState(() => _empId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _type, decoration: const InputDecoration(labelText: 'نوع الإجازة'),
          items: AppConstants.leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: _startCtrl, readOnly: true,
            decoration: const InputDecoration(labelText: 'من'),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(),
                  firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) { setState(() => _startCtrl.text = d.toIso8601String().substring(0, 10)); }
            })),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _endCtrl, readOnly: true,
            decoration: const InputDecoration(labelText: 'إلى'),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(),
                  firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) { setState(() => _endCtrl.text = d.toIso8601String().substring(0, 10)); }
            })),
        ]),
        if (_days > 0) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('عدد الأيام: $_days', style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        TextFormField(controller: _reasonCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'السبب')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: (_empId == null || _endCtrl.text.isEmpty) ? null : () async {
          await context.read<HRProvider>().saveLeave({
            'employee_id': _empId, 'leave_type': _type,
            'start_date': _startCtrl.text, 'end_date': _endCtrl.text,
            'days': _days, 'reason': _reasonCtrl.text.trim(), 'status': 'pending',
          });
          if (mounted) Navigator.pop(context);
        }, child: const Text('إرسال')),
      ],
    );
  }
}
