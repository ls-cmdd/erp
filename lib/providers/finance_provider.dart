import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/models.dart';

class FinanceProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Payment> _payments = [];
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  List<Payment> get payments => _payments;
  List<Map<String, dynamic>> get accounts => _accounts;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await Future.wait([loadExpenses(), loadPayments(), loadAccounts()]);
  }

  Future<void> loadExpenses({String? search, String? startDate, String? endDate}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conditions = <String>[];
      final args = <dynamic>[];
      if (search != null && search.isNotEmpty) {
        conditions.add('(description LIKE ? OR category LIKE ?)');
        args.addAll(['%$search%', '%$search%']);
      }
      if (startDate != null) {
        conditions.add('date >= ?');
        args.add(startDate);
      }
      if (endDate != null) {
        conditions.add('date <= ?');
        args.add(endDate);
      }
      final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
      final result = await AppDatabase.instance.rawQuery(
          'SELECT * FROM expenses $where ORDER BY date DESC LIMIT 500',
          args.isEmpty ? null : args);
      _expenses = result.map((r) => Expense.fromMap(r)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPayments({String? type}) async {
    final where = type != null ? 'WHERE p.type = ?' : '';
    final args = type != null ? [type] : null;
    final result = await AppDatabase.instance.rawQuery('''
      SELECT p.*,
        CASE p.party_type 
          WHEN 'customer' THEN c.name
          WHEN 'supplier' THEN s.name
        END as party_name
      FROM payments p
      LEFT JOIN customers c ON p.party_type = 'customer' AND p.party_id = c.id
      LEFT JOIN suppliers s ON p.party_type = 'supplier' AND p.party_id = s.id
      $where
      ORDER BY p.date DESC LIMIT 500
    ''', args);
    _payments = result.map((r) => Payment.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    final result = await AppDatabase.instance.rawQuery(
        'SELECT * FROM accounts WHERE is_active = 1 ORDER BY code');
    _accounts = result.map((r) => Map<String, dynamic>.from(r)).toList();
    notifyListeners();
  }

  Future<int> saveExpense(Expense expense) async {
    final db = AppDatabase.instance;
    if (expense.expenseNumber == null || expense.expenseNumber!.isEmpty) {
      expense.expenseNumber = await db.generateNumber('EXP', 'expenses', 'expense_number');
    }
    int id;
    if (expense.id != null) {
      await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
      id = expense.id!;
    } else {
      id = await db.insert('expenses', expense.toMap());
    }
    await loadExpenses();
    return id;
  }

  Future<void> deleteExpense(int id) async {
    await AppDatabase.instance.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await loadExpenses();
  }

  Future<Map<String, double>> getProfitLoss({String? startDate, String? endDate}) async {
    final db = AppDatabase.instance;
    final hasRange = startDate != null && endDate != null;
    final dateFilter = hasRange ? 'WHERE date BETWEEN ? AND ?' : '';
    final dateFilterSales = hasRange ? 'AND date BETWEEN ? AND ?' : '';
    final rangeArgs = hasRange ? [startDate, endDate] : <dynamic>[];

    final sales = await db.rawQuery(
        "SELECT COALESCE(SUM(total),0) as v FROM sales_invoices WHERE status!='cancelled' $dateFilterSales",
        rangeArgs);
    final purchases = await db.rawQuery(
        "SELECT COALESCE(SUM(total),0) as v FROM purchase_invoices WHERE status!='cancelled' $dateFilterSales",
        rangeArgs);
    final expensesTotal = await db.rawQuery(
        "SELECT COALESCE(SUM(amount),0) as v FROM expenses $dateFilter", rangeArgs);
    final taxCollected = await db.rawQuery(
        "SELECT COALESCE(SUM(tax_amount),0) as v FROM sales_invoices WHERE status!='cancelled' $dateFilterSales",
        rangeArgs);
    final taxPaid = await db.rawQuery(
        "SELECT COALESCE(SUM(tax_amount),0) as v FROM purchase_invoices WHERE status!='cancelled' $dateFilterSales",
        rangeArgs);

    final totalSales = (sales.first['v'] as num?)?.toDouble() ?? 0;
    final totalPurchases = (purchases.first['v'] as num?)?.toDouble() ?? 0;
    final totalExpenses = (expensesTotal.first['v'] as num?)?.toDouble() ?? 0;
    final grossProfit = totalSales - totalPurchases;
    final netProfit = grossProfit - totalExpenses;

    return {
      'total_sales': totalSales,
      'total_purchases': totalPurchases,
      'gross_profit': grossProfit,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'tax_collected': (taxCollected.first['v'] as num?)?.toDouble() ?? 0,
      'tax_paid': (taxPaid.first['v'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getCashflow({String? year}) async {
    final y = year ?? DateTime.now().year.toString();
    final result = await AppDatabase.instance.rawQuery('''
      SELECT strftime('%m', date) as month,
             SUM(CASE WHEN type='receipt' THEN amount ELSE 0 END) as inflow,
             SUM(CASE WHEN type='payment' THEN amount ELSE 0 END) as outflow
      FROM payments
      WHERE strftime('%Y', date) = ?
      GROUP BY strftime('%m', date)
      ORDER BY month
    ''', [y]);
    return result.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory({String? startDate, String? endDate}) async {
    final hasRange = startDate != null && endDate != null;
    final dateFilter = hasRange ? 'WHERE date BETWEEN ? AND ?' : '';
    final rangeArgs = hasRange ? [startDate, endDate] : <dynamic>[];
    final result = await AppDatabase.instance.rawQuery('''
      SELECT COALESCE(category, 'أخرى') as category,
             SUM(amount) as total,
             COUNT(*) as count
      FROM expenses
      $dateFilter
      GROUP BY category
      ORDER BY total DESC
    ''', rangeArgs);
    return result.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}
