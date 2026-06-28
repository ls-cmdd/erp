import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/models.dart';

class SalesProvider extends ChangeNotifier {
  List<SalesInvoice> _invoices = [];
  bool _isLoading = false;
  String _filterStatus = 'all';
  String _searchQuery = '';
  String? _startDate;
  String? _endDate;

  List<SalesInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;

  Future<void> init() async {
    await loadInvoices();
  }

  void setFilter(String status) {
    _filterStatus = status;
    loadInvoices();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadInvoices();
  }

  void setDateRange(String? start, String? end) {
    _startDate = start;
    _endDate = end;
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final conditions = <String>[];
      final args = <dynamic>[];

      if (_filterStatus != 'all') {
        conditions.add('s.status = ?');
        args.add(_filterStatus);
      }
      if (_searchQuery.isNotEmpty) {
        conditions.add(
            '(s.invoice_number LIKE ? OR c.name LIKE ?)');
        args.addAll(['%$_searchQuery%', '%$_searchQuery%']);
      }
      if (_startDate != null) {
        conditions.add('s.date >= ?');
        args.add(_startDate);
      }
      if (_endDate != null) {
        conditions.add('s.date <= ?');
        args.add(_endDate);
      }

      final where =
          conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      final result = await AppDatabase.instance.rawQuery('''
        SELECT s.*, c.name as customer_name
        FROM sales_invoices s
        LEFT JOIN customers c ON s.customer_id = c.id
        $where
        ORDER BY s.created_at DESC
        LIMIT 500
      ''', args.isEmpty ? null : args);

      _invoices = result.map((r) => SalesInvoice.fromMap(r)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SalesInvoice?> getInvoiceById(int id) async {
    final result = await AppDatabase.instance.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sales_invoices s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
    ''', [id]);
    if (result.isEmpty) return null;
    final invoice = SalesInvoice.fromMap(result.first);
    invoice.items = await getInvoiceItems(id);
    return invoice;
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final result = await AppDatabase.instance.rawQuery('''
      SELECT si.*, p.name_ar as product_name, p.sku
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.invoice_id = ?
    ''', [invoiceId]);
    return result.map((r) => InvoiceItem.fromMap(r)).toList();
  }

  Future<int> saveInvoice(SalesInvoice invoice) async {
    final db = AppDatabase.instance;
    late int invoiceId;

    await db.transaction((txn) async {
      if (invoice.id != null) {
        // Update existing invoice - restore stock first
        final oldItems = await txn.rawQuery(
            'SELECT * FROM sale_items WHERE invoice_id = ?', [invoice.id]);
        for (final item in oldItems) {
          await txn.rawUpdate(
              'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
              [item['qty'], item['product_id']]);
        }
        await txn.delete('sale_items',
            where: 'invoice_id = ?', whereArgs: [invoice.id]);
        await txn.update('sales_invoices', invoice.toMap(),
            where: 'id = ?', whereArgs: [invoice.id]);
        invoiceId = invoice.id!;
      } else {
        invoiceId = await txn.insert('sales_invoices', invoice.toMap());
      }

      // Insert items & update stock
      for (final item in invoice.items) {
        await txn.insert('sale_items', item.toSaleMap(invoiceId));
        await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
            [item.qty, item.productId]);
      }

      // Update customer balance
      if (invoice.customerId != null && invoice.remaining > 0) {
        await txn.rawUpdate(
            'UPDATE customers SET balance = balance + ? WHERE id = ?',
            [invoice.remaining, invoice.customerId]);
      }
    });

    await loadInvoices();
    return invoiceId;
  }

  Future<void> addPayment(int invoiceId, double amount, String method) async {
    final db = AppDatabase.instance;
    await db.transaction((txn) async {
      final invoice = await txn.query('sales_invoices',
          where: 'id = ?', whereArgs: [invoiceId]);
      if (invoice.isEmpty) return;

      final current = invoice.first;
      final newPaid =
          ((current['paid_amount'] as num?)?.toDouble() ?? 0) + amount;
      final total = (current['total'] as num?)?.toDouble() ?? 0;
      final newRemaining = total - newPaid;
      final newStatus = newRemaining <= 0
          ? 'paid'
          : newPaid > 0
              ? 'partial'
              : 'pending';

      await txn.update(
          'sales_invoices',
          {
            'paid_amount': newPaid,
            'remaining': newRemaining,
            'status': newStatus,
          },
          where: 'id = ?',
          whereArgs: [invoiceId]);

      // Record payment
      final payNum = await AppDatabase.instance.generateNumber(
          'PAY', 'payments', 'payment_number');
      await txn.insert('payments', {
        'payment_number': payNum,
        'type': 'receipt',
        'reference_type': 'sale',
        'reference_id': invoiceId,
        'party_type': 'customer',
        'party_id': current['customer_id'],
        'amount': amount,
        'payment_method': method,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });

      // Update customer balance
      if (current['customer_id'] != null) {
        await txn.rawUpdate(
            'UPDATE customers SET balance = balance - ? WHERE id = ?',
            [amount, current['customer_id']]);
      }
    });
    await loadInvoices();
  }

  Future<void> cancelInvoice(int id) async {
    final db = AppDatabase.instance;
    await db.transaction((txn) async {
      // Restore stock
      final items = await txn.rawQuery(
          'SELECT * FROM sale_items WHERE invoice_id = ?', [id]);
      for (final item in items) {
        await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
            [item['qty'], item['product_id']]);
      }
      await txn.update('sales_invoices', {'status': 'cancelled'},
          where: 'id = ?', whereArgs: [id]);
    });
    await loadInvoices();
  }

  Future<void> deleteInvoice(int id) async {
    await cancelInvoice(id);
    await AppDatabase.instance.delete('sales_invoices',
        where: 'id = ?', whereArgs: [id]);
    await loadInvoices();
  }

  Future<String> generateInvoiceNumber() async {
    final settings = await AppDatabase.instance.getAllSettings();
    final prefix = settings['sales_prefix'] ?? 'INV';
    return AppDatabase.instance.generateNumber(prefix, 'sales_invoices', 'invoice_number');
  }
}
