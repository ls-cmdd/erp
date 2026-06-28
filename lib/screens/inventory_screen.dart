import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/app_provider.dart';
import '../core/utils.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadLowStock();
      context.read<AppProvider>().loadProducts();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final app = context.watch<AppProvider>();

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [
          Row(children: [
            Text('إدارة المخزون', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            FutureBuilder<double>(
              future: inv.getTotalStockValue(),
              builder: (_, snap) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'قيمة المخزون: ${AppUtils.money(snap.data ?? 0)}',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabs,
            tabs: const [Tab(text: 'جميع المنتجات'), Tab(text: 'تنبيهات المخزون'), Tab(text: 'حركة المخزون')],
          ),
        ]),
      ),
      Expanded(
        child: TabBarView(controller: _tabs, children: [
          _AllStockTab(products: app.products),
          _LowStockTab(products: inv.lowStockProducts),
          _MovementsTab(),
        ]),
      ),
    ]);
  }
}

class _AllStockTab extends StatelessWidget {
  final List products;
  const _AllStockTab({required this.products});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (products.isEmpty) return const EmptyState(icon: Icons.warehouse_outlined, title: 'لا توجد منتجات');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = products[i];
        final isLow = p.isLowStock;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(width: 44, height: 44,
            decoration: BoxDecoration(
              color: isLow ? Colors.red.withOpacity(.1) : cs.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_outlined, color: isLow ? Colors.red : cs.primary, size: 20)),
          title: Text(p.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('سعر التكلفة: ${AppUtils.money(p.costPrice)}  |  سعر البيع: ${AppUtils.money(p.salePrice)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${AppUtils.num(p.stockQty)} ${p.unitName ?? ''}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16,
                      color: isLow ? Colors.red : Colors.green)),
              Text('قيمة: ${AppUtils.money(p.stockValue)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 20),
              tooltip: 'تعديل المخزون',
              onPressed: () => _adjustDialog(context, p),
            ),
          ]),
        );
      },
    );
  }

  void _adjustDialog(BuildContext context, dynamic p) {
    final qtyCtrl   = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'in';
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text('تعديل مخزون: ${p.nameAr}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('المخزون الحالي: ${AppUtils.num(p.stockQty)} ${p.unitName ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: RadioListTile<String>(
              title: const Text('إضافة وارد'), value: 'in', groupValue: type,
              onChanged: (v) => setS(() => type = v!), dense: true)),
            Expanded(child: RadioListTile<String>(
              title: const Text('خصم صادر'), value: 'out', groupValue: type,
              onChanged: (v) => setS(() => type = v!), dense: true)),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: const InputDecoration(labelText: 'الكمية *')),
          const SizedBox(height: 12),
          TextFormField(controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            final qty = double.tryParse(qtyCtrl.text) ?? 0;
            if (qty <= 0) return;
            await context.read<InventoryProvider>().adjustStock(p.id!, qty, type, notesCtrl.text.trim());
            await context.read<AppProvider>().loadProducts();
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('تأكيد')),
        ],
      ),
    ));
  }
}

class _LowStockTab extends StatelessWidget {
  final List products;
  const _LowStockTab({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const EmptyState(icon: Icons.check_circle_outline,
        title: 'جميع المنتجات بمخزون كافٍ', subtitle: 'لا توجد تنبيهات حالياً');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = products[i];
        final deficit = p.minStock - p.stockQty;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.red.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22)),
          title: Text(p.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المخزون: ${AppUtils.num(p.stockQty)}  |  الحد الأدنى: ${AppUtils.num(p.minStock)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (p.stockQty / p.minStock).clamp(0, 1.0).toDouble(),
              backgroundColor: Colors.red.withOpacity(.1),
              valueColor: const AlwaysStoppedAnimation(Colors.red),
              minHeight: 4, borderRadius: BorderRadius.circular(4),
            ),
          ]),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('يحتاج', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text('${AppUtils.num(deficit)} وحدة',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red, fontSize: 14)),
          ]),
        );
      },
    );
  }
}

class _MovementsTab extends StatefulWidget {
  @override
  State<_MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends State<_MovementsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<InventoryProvider>().loadStockMovements());
  }

  @override
  Widget build(BuildContext context) {
    final movements = context.watch<InventoryProvider>().stockMovements;
    if (movements.isEmpty) return const EmptyState(icon: Icons.swap_horiz_rounded, title: 'لا توجد حركات مخزون');
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: movements.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m    = movements[i];
        final type = m['type']?.toString() ?? '';
        final isIn = type.contains('in') || type == 'purchase';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: isIn ? Colors.green.withOpacity(.1) : Colors.red.withOpacity(.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isIn ? Colors.green : Colors.red, size: 18)),
          title: Text(m['product_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(_typeLabel(type), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isIn ? '+' : '-'}${AppUtils.num((m['quantity'] as num?)?.toDouble() ?? 0)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: isIn ? Colors.green : Colors.red)),
            Text(AppUtils.date(m['created_at']?.toString()),
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        );
      },
    );
  }

  String _typeLabel(String t) => switch (t) {
    'purchase'       => 'مشتريات',
    'sale'           => 'مبيعات',
    'adjustment_in'  => 'تعديل وارد',
    'adjustment_out' => 'تعديل صادر',
    _                => t,
  };
}
