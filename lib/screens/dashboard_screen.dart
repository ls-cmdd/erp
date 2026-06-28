import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../core/utils.dart';
import '../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app      = context.watch<AppProvider>();
    final settings = context.watch<SettingsProvider>();
    final stats    = app.stats;
    final cur      = settings.get('currency', defaultValue: 'ريال');
    final cs       = Theme.of(context).colorScheme;
    final isLight  = Theme.of(context).brightness == Brightness.light;
    final bgCard   = isLight ? Colors.white : const Color(0xFF1A2332);

    return RefreshIndicator(
      onRefresh: () => app.loadDashboardStats(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Greeting ────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('لوحة التحكم',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(AppUtils.dateTime(DateTime.now().toIso8601String()),
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ]),
            IconButton.outlined(
              onPressed: () => app.loadDashboardStats(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
            ),
          ]),
          const SizedBox(height: 24),

          // ── KPI Cards ───────────────────────────────────────────────────
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280, mainAxisExtent: 120,
              crossAxisSpacing: 16, mainAxisSpacing: 16,
            ),
            children: [
              _KpiCard(title: 'إجمالي المبيعات', value: AppUtils.money(stats.totalSales, cur: cur),
                  icon: Icons.trending_up_rounded, color: const Color(0xFF0E9F6E),
                  sub: '${stats.pendingInvoices} فاتورة معلقة'),
              _KpiCard(title: 'إجمالي المشتريات', value: AppUtils.money(stats.totalPurchases, cur: cur),
                  icon: Icons.shopping_basket_rounded, color: const Color(0xFF3B82F6)),
              _KpiCard(title: 'صافي الربح', value: AppUtils.money(stats.netProfit, cur: cur),
                  icon: Icons.account_balance_wallet_rounded,
                  color: stats.netProfit >= 0 ? const Color(0xFF0E9F6E) : const Color(0xFFEF4444)),
              _KpiCard(title: 'إجمالي المصروفات', value: AppUtils.money(stats.totalExpenses, cur: cur),
                  icon: Icons.payments_rounded, color: const Color(0xFFF59E0B)),
              _KpiCard(title: 'العملاء', value: stats.totalCustomers.toString(),
                  icon: Icons.people_rounded, color: const Color(0xFF8B5CF6)),
              _KpiCard(title: 'المنتجات', value: stats.totalProducts.toString(),
                  icon: Icons.inventory_2_rounded, color: const Color(0xFFEC4899)),
              _KpiCard(title: 'الموظفون', value: stats.totalEmployees.toString(),
                  icon: Icons.badge_rounded, color: const Color(0xFF06B6D4)),
              if (stats.lowStockProducts > 0)
                _KpiCard(title: 'تنبيهات المخزون', value: '${stats.lowStockProducts} منتج',
                    icon: Icons.warning_amber_rounded, color: const Color(0xFFEF4444),
                    isAlert: true),
            ],
          ),
          const SizedBox(height: 28),

          // ── Charts row ──────────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _SalesChart(monthlySales: stats.monthlySales,
                monthlyPurchases: stats.monthlyPurchases)),
            const SizedBox(width: 20),
            SizedBox(width: 280, child: _CategoryPie(categories: stats.salesByCategory)),
          ]),
          const SizedBox(height: 24),

          // ── Recent + Top Products ────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _RecentSalesTable(data: stats.recentSales, cur: cur)),
            const SizedBox(width: 20),
            SizedBox(width: 300, child: _TopProducts(data: stats.topProducts, cur: cur)),
          ]),
        ],
      ),
    );
  }
}

// ── KPI Card ────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final String? sub;
  final bool isAlert;

  const _KpiCard({
    required this.title, required this.value, required this.icon, required this.color,
    this.sub, this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? color.withOpacity(.4)
              : isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748),
        ),
        boxShadow: isLight ? [BoxShadow(
          color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ]),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: isAlert ? color : null)),
        if (sub != null) Text(sub!,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
    );
  }
}

// ── Sales Chart ──────────────────────────────────────────────────────────────
class _SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlySales, monthlyPurchases;
  const _SalesChart({required this.monthlySales, required this.monthlyPurchases});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final months  = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));

    double maxY = 1000;
    final salesMap = {for (final m in monthlySales) m['month'].toString().split('-').last: (m['total'] as num).toDouble()};
    final purchMap = {for (final m in monthlyPurchases) m['month'].toString().split('-').last: (m['total'] as num).toDouble()};

    final allVals = [...salesMap.values, ...purchMap.values];
    if (allVals.isNotEmpty) maxY = (allVals.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();
    if (maxY < 1000) maxY = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('المبيعات vs المشتريات', style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          _legend('المبيعات', cs.primary),
          const SizedBox(width: 16),
          _legend('المشتريات', const Color(0xFFF59E0B)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: BarChart(BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  months[v.toInt()], style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 52,
                getTitlesWidget: (v, _) => Text(AppUtils.num(v),
                    style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              )),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles   : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(.12), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(12, (i) {
              final mo = months[i];
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: salesMap[mo] ?? 0, color: cs.primary,
                    width: 10, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: purchMap[mo] ?? 0, color: const Color(0xFFF59E0B),
                    width: 10, borderRadius: BorderRadius.circular(4)),
              ], barsSpace: 2);
            }),
          )),
        ),
      ]),
    );
  }

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 12)),
  ]);
}

// ── Category Pie ──────────────────────────────────────────────────────────────
class _CategoryPie extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _CategoryPie({required this.categories});

  static const _colors = [
    Color(0xFF3B82F6), Color(0xFF0E9F6E), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المبيعات حسب الفئة', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const SizedBox(height: 200, child: Center(child: Text('لا توجد بيانات')))
        else ...[
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(
              sections: categories.asMap().entries.map((e) {
                final color = _colors[e.key % _colors.length];
                final val   = (e.value['total'] as num).toDouble();
                return PieChartSectionData(
                  value: val, color: color, radius: 68,
                  title: '', showTitle: false,
                );
              }).toList(),
              sectionsSpace: 2, centerSpaceRadius: 36,
            )),
          ),
          const SizedBox(height: 12),
          ...categories.asMap().entries.take(6).map((e) {
            final color = _colors[e.key % _colors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value['category']?.toString() ?? '',
                    style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                Text(AppUtils.num((e.value['total'] as num).toDouble()),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

// ── Recent Sales Table ────────────────────────────────────────────────────────
class _RecentSalesTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String cur;
  const _RecentSalesTable({required this.data, required this.cur});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('آخر الفواتير', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 14),
        if (data.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text('لا توجد فواتير', style: TextStyle(color: Colors.grey))))
        else
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.8), 1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.4), 3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F1623),
                  borderRadius: BorderRadius.circular(8),
                ),
                children: ['العميل', 'الفاتورة', 'المبلغ', 'الحالة']
                    .map((h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(h, style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                )).toList(),
              ),
              ...data.take(8).map((row) => TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                children: [
                  _cell(row['customer_name']?.toString() ?? 'عميل غير محدد'),
                  _cell(row['invoice_number']?.toString() ?? ''),
                  _cell(AppUtils.money((row['total'] as num?)?.toDouble() ?? 0, cur: cur),
                      bold: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: _StatusChip(row['status']?.toString() ?? 'pending'),
                  ),
                ],
              )),
            ],
          ),
      ]),
    );
  }

  Widget _cell(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(t,
        style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
        overflow: TextOverflow.ellipsis),
  );
}

// ── Top Products ──────────────────────────────────────────────────────────────
class _TopProducts extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String cur;
  const _TopProducts({required this.data, required this.cur});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cs      = Theme.of(context).colorScheme;
    double maxVal = 1;
    if (data.isNotEmpty) maxVal = (data.map((d) => (d['total_amount'] as num).toDouble()).reduce((a, b) => a > b ? a : b));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('أكثر المنتجات مبيعاً', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 14),
        if (data.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey))))
        else
          ...data.take(6).map((d) {
            final pct = ((d['total_amount'] as num).toDouble() / maxVal).clamp(0, 1.0).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(d['name_ar']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
                  Text(AppUtils.money((d['total_amount'] as num).toDouble(), cur: cur),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
                ]),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: pct, minHeight: 6,
                  backgroundColor: cs.primary.withOpacity(.1),
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    final label = AppTheme.statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
