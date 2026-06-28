import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../core/utils.dart';
import '../widgets/app_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AppProvider>().loadCustomers());
  }

  void _openForm([Customer? c]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CustomerFormDialog(customer: c),
    );
  }

  void _delete(Customer c) async {
    final ok = await showConfirmDialog(context,
        title: 'حذف العميل', content: 'هل تريد حذف "${c.name}"؟', isDanger: true);
    if (ok && mounted) await context.read<AppProvider>().deleteCustomer(c.id!);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final customers = app.customers;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('العملاء', style: Theme.of(context).textTheme.headlineSmall),
            Text('${customers.length} عميل',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة عميل'),
          ),
        ]),
      ),
      // Search
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: AppSearchBar(
          hint: 'بحث بالاسم أو الهاتف أو الشركة...',
          controller: _search,
          onChanged: (v) => app.loadCustomers(search: v),
        ),
      ),
      // Table
      Expanded(
        child: customers.isEmpty
            ? const EmptyState(icon: Icons.people_outline,
                title: 'لا يوجد عملاء', subtitle: 'أضف عميلك الأول الآن')
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: customers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = customers[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primary.withOpacity(.12),
                      child: Text(c.name[0],
                          style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([c.phone, c.city].where((e) => e != null && e!.isNotEmpty).join(' · ') ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (c.balance != 0)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.balance > 0 ? Colors.red.withOpacity(.1) : Colors.green.withOpacity(.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(AppUtils.money(c.balance),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: c.balance > 0 ? Colors.red : Colors.green)),
                        ),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _openForm(c)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _delete(c)),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  const _CustomerFormDialog({this.customer});
  @override State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name   = TextEditingController(text: widget.customer?.name ?? '');
  late final _company= TextEditingController(text: widget.customer?.company ?? '');
  late final _phone  = TextEditingController(text: widget.customer?.phone ?? '');
  late final _email  = TextEditingController(text: widget.customer?.email ?? '');
  late final _address= TextEditingController(text: widget.customer?.address ?? '');
  late final _city   = TextEditingController(text: widget.customer?.city ?? '');
  late final _taxNo  = TextEditingController(text: widget.customer?.taxNumber ?? '');
  late final _notes  = TextEditingController(text: widget.customer?.notes ?? '');
  late final _credit = TextEditingController(text: (widget.customer?.creditLimit ?? 0).toString());
  late final _disc   = TextEditingController(text: (widget.customer?.discountRate ?? 0).toString());
  bool _saving = false;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final c = Customer(
      id          : widget.customer?.id,
      name        : _name.text.trim(),
      company     : _company.text.trim(),
      phone       : _phone.text.trim(),
      email       : _email.text.trim(),
      address     : _address.text.trim(),
      city        : _city.text.trim(),
      taxNumber   : _taxNo.text.trim(),
      notes       : _notes.text.trim(),
      creditLimit : double.tryParse(_credit.text) ?? 0,
      discountRate: double.tryParse(_disc.text) ?? 0,
      balance     : widget.customer?.balance ?? 0,
    );
    await context.read<AppProvider>().saveCustomer(c);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'إضافة عميل' : 'تعديل العميل'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Wrap(runSpacing: 16, spacing: 16,
              children: [
                _field(_name, 'الاسم', required: true, width: 260),
                _field(_company, 'الشركة', width: 260),
                _field(_phone, 'الهاتف', width: 200),
                _field(_email, 'البريد الإلكتروني', width: 320),
                _field(_city, 'المدينة', width: 200),
                _field(_address, 'العنوان', width: 520),
                _field(_taxNo, 'الرقم الضريبي', width: 250),
                _field(_credit, 'حد الائتمان', width: 200, isNum: true),
                _field(_disc, 'نسبة الخصم %', width: 200, isNum: true),
                _field(_notes, 'ملاحظات', maxLines: 2, width: 520),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.customer == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1, double width = 240, bool isNum = false}) =>
      SizedBox(
        width: width,
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : null,
          validator: required ? (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null : null,
          decoration: InputDecoration(labelText: label + (required ? ' *' : '')),
        ),
      );
}
