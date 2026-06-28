import 'package:flutter/material.dart';
import '../db/database.dart';

class ReportsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<Map<String, dynamic>>> getSalesReport({
    String? startDate,
    String? endDate,
    int? customerId,
  }) async {
    final conditions = ["s.status != 'cancelled'"];
    final args = <dynamic>[];
    if (startDate != null) { conditions.add('s.date >= ?'); args.add(startDate); }
    if (endDate != null) { conditions.add('s.date <= ?'); args.add(endDate); }
    if (customerId != null) { conditions.add('s.customer_id = ?'); args.add(customerId); }
    final where = 'WHERE ${conditions.join(' AND ')}';
    return await AppDatabase.instance.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sales_invoices s
      LEFT JOIN customers c ON s.customer_id = c.id
      $where
      ORDER BY s.date DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getPurchasesReport({
    String? startDate,
    String? endDate,
    int? supplierId,
  }) async {
    final conditions = ["p.status != 'cancelled'"];
    final args = <dynamic>[];
    if (startDate != null) { conditions.add('p.date >= ?'); args.add(startDate); }
    if (endDate != null) { conditions.add('p.date <= ?'); args.add(endDate); }
    if (supplierId != null) { conditions.add('p.supplier_id = ?'); args.add(supplierId); }
    final where = 'WHERE ${conditions.join(' AND ')}';
    return await AppDatabase.instance.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchase_invoices p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      $where
      ORDER BY p.date DESC
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getInventoryReport() async {
    return await AppDatabase.instance.rawQuery('''
      SELECT p.*, c.name_ar as category_name, u.name_ar as unit_name,
             (p.stock_qty * p.cost_price) as stock_value,
             CASE WHEN p.stock_qty <= p.min_stock AND p.min_stock > 0 THEN 1 ELSE 0 END as is_low
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN units u ON p.unit_id = u.id
      WHERE p.is_active = 1
      ORDER BY p.name_ar
    ''');
  }

  Future<Map<String, double>> getProfitLossReport({String? startDate, String? endDate}) async {
    final hasRange = startDate != null && endDate != null;
    final dateFilter = hasRange ? 'AND date BETWEEN ? AND ?' : '';
    final expFilter = hasRange ? 'WHERE date BETWEEN ? AND ?' : '';
    final rangeArgs = hasRange ? [startDate, endDate] : <dynamic>[];

    final sales = await AppDatabase.instance.rawQuery(
        "SELECT COALESCE(SUM(total),0) as v, COALESCE(SUM(tax_amount),0) as tax FROM sales_invoices WHERE status!='cancelled' $dateFilter",
        rangeArgs);
    final purchases = await AppDatabase.instance.rawQuery(
        "SELECT COALESCE(SUM(total),0) as v, COALESCE(SUM(tax_amount),0) as tax FROM purchase_invoices WHERE status!='cancelled' $dateFilter",
        rangeArgs);
    final expenses = await AppDatabase.instance.rawQuery(
        "SELECT COALESCE(SUM(amount),0) as v FROM expenses $expFilter", rangeArgs);

    final totalSales = (sales.first['v'] as num?)?.toDouble() ?? 0;
    final totalPurchases = (purchases.first['v'] as num?)?.toDouble() ?? 0;
    final totalExpenses = (expenses.first['v'] as num?)?.toDouble() ?? 0;

    return {
      'total_sales': totalSales,
      'total_purchases': totalPurchases,
      'gross_profit': totalSales - totalPurchases,
      'total_expenses': totalExpenses,
      'net_profit': totalSales - totalPurchases - totalExpenses,
      'tax_collected': (sales.first['tax'] as num?)?.toDouble() ?? 0,
      'tax_paid': (purchases.first['tax'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getTopProductsReport({int limit = 10}) async {
    return await AppDatabase.instance.rawQuery('''
      SELECT p.name_ar, p.sku,
             SUM(si.qty) as total_qty,
             SUM(si.total) as total_sales,
             COUNT(DISTINCT si.invoice_id) as invoice_count
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales_invoices inv ON si.invoice_id = inv.id
      WHERE inv.status != 'cancelled'
      GROUP BY si.product_id
      ORDER BY total_sales DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> getCustomerStatement(int customerId) async {
    return await AppDatabase.instance.rawQuery('''
      SELECT 'فاتورة مبيعات' as type, invoice_number as ref,
             date, total as debit, paid_amount as credit,
             remaining as balance, status
      FROM sales_invoices
      WHERE customer_id = ? AND status != 'cancelled'
      ORDER BY date ASC
    ''', [customerId]);
  }

  Future<List<Map<String, dynamic>>> getSupplierStatement(int supplierId) async {
    return await AppDatabase.instance.rawQuery('''
      SELECT 'فاتورة مشتريات' as type, invoice_number as ref,
             date, total as debit, paid_amount as credit,
             remaining as balance, status
      FROM purchase_invoices
      WHERE supplier_id = ? AND status != 'cancelled'
      ORDER BY date ASC
    ''', [supplierId]);
  }

  Future<List<Map<String, dynamic>>> getTaxReport({String? startDate, String? endDate}) async {
    final hasRange = startDate != null && endDate != null;
    final salesFilter = hasRange ? 'AND date BETWEEN ? AND ?' : '';
    final purchFilter = hasRange ? 'AND date BETWEEN ? AND ?' : '';
    final rangeArgs = hasRange ? [startDate, endDate] : <dynamic>[];

    final collected = await AppDatabase.instance.rawQuery('''
      SELECT strftime('%Y-%m', date) as period,
             SUM(tax_amount) as tax_collected
      FROM sales_invoices
      WHERE status != 'cancelled' $salesFilter
      GROUP BY strftime('%Y-%m', date)
    ''', rangeArgs);

    final paid = await AppDatabase.instance.rawQuery('''
      SELECT strftime('%Y-%m', date) as period,
             SUM(tax_amount) as tax_paid
      FROM purchase_invoices
      WHERE status != 'cancelled' $purchFilter
      GROUP BY strftime('%Y-%m', date)
    ''', rangeArgs);

    final paidByPeriod = {
      for (final r in paid) r['period'] as String: (r['tax_paid'] as num?)?.toDouble() ?? 0
    };

    final result = collected.map((r) {
      final period = r['period'] as String;
      return {
        'period': period,
        'tax_collected': (r['tax_collected'] as num?)?.toDouble() ?? 0,
        'tax_paid': paidByPeriod[period] ?? 0,
      };
    }).toList()
      ..sort((a, b) => (b['period'] as String).compareTo(a['period'] as String));

    return result;
  }

  Future<List<Map<String, dynamic>>> getSalesByProductCategory() async {
    return await AppDatabase.instance.rawQuery('''
      SELECT c.name_ar as category,
             COUNT(DISTINCT si.invoice_id) as invoice_count,
             SUM(si.qty) as total_qty,
             SUM(si.total) as total_amount
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      JOIN sales_invoices inv ON si.invoice_id = inv.id
      WHERE inv.status != 'cancelled'
      GROUP BY p.category_id
      ORDER BY total_amount DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getAgedReceivables() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await AppDatabase.instance.rawQuery('''
      SELECT c.name as customer_name,
             s.invoice_number,
             s.date,
             s.due_date,
             s.remaining,
             CAST(julianday(?) - julianday(COALESCE(s.due_date, s.date)) AS INTEGER) as days_overdue
      FROM sales_invoices s
      JOIN customers c ON s.customer_id = c.id
      WHERE s.status IN ('pending','partial')
      ORDER BY days_overdue DESC
    ''', [today]);
  }
}
