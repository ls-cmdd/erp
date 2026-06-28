import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../core/utils.dart';
import '../widgets/app_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  int? _filterCat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AppProvider>().loadProducts());
  }

  void _openForm([Product? p]) => showDialog(context: context,
      barrierDismissible: false,
      builder: (_) => _ProductFormDialog(product: p));

  void _delete(Product p) async {
    final ok = await showConfirmDialog(context,
        title: 'حذف المنتج', content: 'حذف "${p.nameAr}"؟', isDanger: true);
    if (ok && mounted) await context.read<AppProvider>().deleteProduct(p.id!);
  }

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final products  = app.products;
    final categories= app.categories;
    final cs        = Theme.of(context).colorScheme;

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المنتجات', style: Theme.of(context).textTheme.headlineSmall),
            Text('${products.length} منتج', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ]),
          const Spacer(),
          ElevatedButton.icon(onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18), label: const Text('إضافة منتج')),
        ]),
      ),
      // Search + filter
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Row(children: [
          Expanded(child: AppSearchBar(hint: 'بحث بالاسم أو الكود...', controller: _search,
              onChanged: (v) => app.loadProducts(search: v, categoryId: _filterCat))),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<int?>(
              value: _filterCat,
              decoration: const InputDecoration(labelText: 'الفئة'),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل الفئات')),
                ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr))),
              ],
              onChanged: (v) { _filterCat = v; app.loadProducts(categoryId: v); },
            ),
          ),
        ]),
      ),
      // Table
      Expanded(
        child: products.isEmpty
            ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'لا توجد منتجات')
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: p.isLowStock ? Colors.red.withOpacity(.1) : cs.primary.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          color: p.isLowStock ? Colors.red : cs.primary, size: 20),
                    ),
                    title: Row(children: [
                      Text(p.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (p.isLowStock) ...[
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('مخزون منخفض',
                                style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700))),
                      ],
                    ]),
                    subtitle: Text([
                      if (p.sku != null) 'الكود: ${p.sku}',
                      if (p.categoryName != null) p.categoryName!,
                    ].join(' · '), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(AppUtils.money(p.salePrice), style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
                        Text('مخزون: ${AppUtils.num(p.stockQty)} ${p.unitName ?? ''}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ]),
                      const SizedBox(width: 12),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openForm(p)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(p)),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Product? product;
  const _ProductFormDialog({this.product});
  @override State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _form    = GlobalKey<FormState>();
  late final _nameAr  = TextEditingController(text: widget.product?.nameAr ?? '');
  late final _sku     = TextEditingController(text: widget.product?.sku ?? '');
  late final _barcode = TextEditingController(text: widget.product?.barcode ?? '');
  late final _cost    = TextEditingController(text: (widget.product?.costPrice ?? 0).toString());
  late final _sale    = TextEditingController(text: (widget.product?.salePrice ?? 0).toString());
  late final _tax     = TextEditingController(text: (widget.product?.taxRate ?? 0).toString());
  late final _stock   = TextEditingController(text: (widget.product?.stockQty ?? 0).toString());
  late final _minStock= TextEditingController(text: (widget.product?.minStock ?? 0).toString());
  late final _desc    = TextEditingController(text: widget.product?.description ?? '');
  int? _categoryId, _unitId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
    _unitId     = widget.product?.unitId;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final p = Product(
      id: widget.product?.id,
      nameAr: _nameAr.text.trim(), sku: _sku.text.trim(), barcode: _barcode.text.trim(),
      categoryId: _categoryId, unitId: _unitId,
      costPrice: double.tryParse(_cost.text) ?? 0,
      salePrice: double.tryParse(_sale.text) ?? 0,
      taxRate: double.tryParse(_tax.text) ?? 0,
      stockQty: double.tryParse(_stock.text) ?? 0,
      minStock: double.tryParse(_minStock.text) ?? 0,
      description: _desc.text.trim(),
    );
    await context.read<AppProvider>().saveProduct(p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return AlertDialog(
      title: Text(widget.product == null ? 'إضافة منتج' : 'تعديل المنتج'),
      content: SizedBox(
        width: 620,
        child: Form(key: _form,
          child: SingleChildScrollView(
            child: Wrap(runSpacing: 16, spacing: 16, children: [
              _tf(_nameAr, 'الاسم بالعربي', req: true, w: 380),
              _tf(_sku, 'كود المنتج (SKU)', w: 200),
              _tf(_barcode, 'الباركود', w: 200),
              SizedBox(width: 250, child: DropdownButtonFormField<int?>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'الفئة'),
                items: [const DropdownMenuItem(value: null, child: Text('بدون فئة')),
                  ...app.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)))],
                onChanged: (v) => setState(() => _categoryId = v),
              )),
              SizedBox(width: 180, child: DropdownButtonFormField<int?>(
                value: _unitId,
                decoration: const InputDecoration(labelText: 'الوحدة'),
                items: [const DropdownMenuItem(value: null, child: Text('بدون وحدة')),
                  ...app.units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nameAr)))],
                onChanged: (v) => setState(() => _unitId = v),
              )),
              _nf(_cost, 'سعر التكلفة', w: 180),
              _nf(_sale, 'سعر البيع', w: 180, req: true),
              _nf(_tax, 'نسبة الضريبة %', w: 160),
              _nf(_stock, 'الكمية الحالية', w: 180),
              _nf(_minStock, 'الحد الأدنى للمخزون', w: 200),
              _tf(_desc, 'الوصف', ml: 2, w: 600),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(onPressed: _saving ? null : _save,
            child: Text(widget.product == null ? 'إضافة' : 'حفظ')),
      ],
    );
  }

  Widget _tf(TextEditingController c, String l, {bool req = false, int ml = 1, double w = 240}) =>
      SizedBox(width: w, child: TextFormField(controller: c, maxLines: ml,
          validator: req ? (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null : null,
          decoration: InputDecoration(labelText: l + (req ? ' *' : ''))));

  Widget _nf(TextEditingController c, String l, {bool req = false, double w = 200}) =>
      SizedBox(width: w, child: TextFormField(controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          validator: req ? (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null : null,
          decoration: InputDecoration(labelText: l)));
}
