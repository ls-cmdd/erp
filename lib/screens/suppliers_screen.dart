import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../core/utils.dart';
import '../widgets/app_widgets.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AppProvider>().loadSuppliers());
  }

  void _openForm([Supplier? s]) => showDialog(context: context,
      barrierDismissible: false,
      builder: (_) => _SupplierFormDialog(supplier: s));

  void _delete(Supplier s) async {
    final ok = await showConfirmDialog(context,
        title: 'حذف المورد', content: 'حذف "${s.name}"؟', isDanger: true);
    if (ok && mounted) await context.read<AppProvider>().deleteSupplier(s.id!);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<AppProvider>().suppliers;
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('الموردون', style: Theme.of(context).textTheme.headlineSmall),
            Text('${suppliers.length} مورد', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
          const Spacer(),
          ElevatedButton.icon(onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18), label: const Text('إضافة مورد')),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: AppSearchBar(hint: 'بحث...', controller: _search,
            onChanged: (v) => context.read<AppProvider>().loadSuppliers(search: v)),
      ),
      Expanded(
        child: suppliers.isEmpty
            ? const EmptyState(icon: Icons.local_shipping_outlined, title: 'لا يوجد موردون')
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: suppliers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = suppliers[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.orange.withOpacity(.12),
                      child: Text(s.name[0],
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange)),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([s.phone, s.city].where((e) => e != null && e!.isNotEmpty).join(' · ')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (s.balance != 0)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(AppUtils.money(s.balance),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange)),
                        ),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _openForm(s)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _delete(s)),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormDialog({this.supplier});
  @override State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _form    = GlobalKey<FormState>();
  late final _name   = TextEditingController(text: widget.supplier?.name ?? '');
  late final _company= TextEditingController(text: widget.supplier?.company ?? '');
  late final _phone  = TextEditingController(text: widget.supplier?.phone ?? '');
  late final _email  = TextEditingController(text: widget.supplier?.email ?? '');
  late final _address= TextEditingController(text: widget.supplier?.address ?? '');
  late final _city   = TextEditingController(text: widget.supplier?.city ?? '');
  late final _taxNo  = TextEditingController(text: widget.supplier?.taxNumber ?? '');
  late final _notes  = TextEditingController(text: widget.supplier?.notes ?? '');
  bool _saving = false;

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final s = Supplier(
      id: widget.supplier?.id,
      name: _name.text.trim(), company: _company.text.trim(),
      phone: _phone.text.trim(), email: _email.text.trim(),
      address: _address.text.trim(), city: _city.text.trim(),
      taxNumber: _taxNo.text.trim(), notes: _notes.text.trim(),
      balance: widget.supplier?.balance ?? 0,
    );
    await context.read<AppProvider>().saveSupplier(s);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supplier == null ? 'إضافة مورد' : 'تعديل المورد'),
      content: SizedBox(
        width: 560,
        child: Form(key: _form,
          child: SingleChildScrollView(
            child: Wrap(runSpacing: 16, spacing: 16, children: [
              _f(_name, 'الاسم', req: true, w: 260),
              _f(_company, 'الشركة', w: 260),
              _f(_phone, 'الهاتف', w: 200),
              _f(_email, 'البريد', w: 320),
              _f(_city, 'المدينة', w: 200),
              _f(_address, 'العنوان', w: 520),
              _f(_taxNo, 'الرقم الضريبي', w: 250),
              _f(_notes, 'ملاحظات', ml: 2, w: 520),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _saving ? null : _save,
            child: Text(widget.supplier == null ? 'إضافة' : 'حفظ')),
      ],
    );
  }

  Widget _f(TextEditingController c, String l, {bool req = false, int ml = 1, double w = 240}) =>
      SizedBox(width: w, child: TextFormField(controller: c, maxLines: ml,
          validator: req ? (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null : null,
          decoration: InputDecoration(labelText: l + (req ? ' *' : ''))));
}
