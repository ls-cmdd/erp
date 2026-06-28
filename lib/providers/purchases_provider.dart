// purchases_provider.dart
import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/models.dart';

class PurchasesProvider extends ChangeNotifier {
  List<PurchaseInvoice> _invoices = [];
  bool _isLoading = false;

  List<PurchaseInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  Future<void> init() async => loadInvoices();

  Future<void> loadInvoices({String? status, String? search}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conditions = <String>[];
      final args = <dynamic>[];
      if (status != null && status != 'all') {
        conditions.add('p.status = ?');
        args.add(status);
      }
      if (search != null && search.isNotEmpty) {
        conditions.add('(p.invoice_number LIKE ? OR s.name LIKE ?)');
        args.addAll(['%$search%', '%$search%']);
      }
      final where =
          conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
      final result = await AppDatabase.instance.rawQuery('''
        SELECT p.*, s.name as supplier_name
        FROM purchase_invoices p
        LEFT JOIN suppliers s ON p.supplier_id = s.id
        $where
        ORDER BY p.created_at DESC LIMIT 500
      ''', args.isEmpty ? null : args);
      _invoices = result.map((r) => PurchaseInvoice.fromMap(r)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseInvoice?> getById(int id) async {
    final result = await AppDatabase.instance.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchase_invoices p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id = ?
    ''', [id]);
    if (result.isEmpty) return null;
    final inv = PurchaseInvoice.fromMap(result.first);
    final items = await AppDatabase.instance.rawQuery('''
      SELECT pi.*, p.name_ar as product_name, p.sku
      FROM purchase_items pi
      JOIN products p ON pi.product_id = p.id
      WHERE pi.invoice_id = ?
    ''', [id]);
    inv.items = items.map((r) => InvoiceItem.fromMap(r)).toList();
    return inv;
  }

  Future<int> saveInvoice(PurchaseInvoice invoice) async {
    final db = AppDatabase.instance;
    late int invoiceId;
    await db.transaction((txn) async {
      if (invoice.id != null) {
        final oldItems = await txn.rawQuery(
            'SELECT * FROM purchase_items WHERE invoice_id = ?', [invoice.id]);
        for (final item in oldItems) {
          await txn.rawUpdate(
              'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
              [item['qty'], item['product_id']]);
        }
        await txn.delete('purchase_items',
            where: 'invoice_id = ?', whereArgs: [invoice.id]);
        await txn.update('purchase_invoices', invoice.toMap(),
            where: 'id = ?', whereArgs: [invoice.id]);
        invoiceId = invoice.id!;
      } else {
        invoiceId = await txn.insert('purchase_invoices', invoice.toMap());
      }
      for (final item in invoice.items) {
        await txn.insert('purchase_items', item.toPurchaseMap(invoiceId));
        await txn.rawUpdate(
            'UPDATE products SET stock_qty = stock_qty + ?, cost_price = ? WHERE id = ?',
            [item.qty, item.unitPrice, item.productId]);
      }
      if (invoice.supplierId != null && invoice.remaining > 0) {
        await txn.rawUpdate(
            'UPDATE suppliers SET balance = balance + ? WHERE id = ?',
            [invoice.remaining, invoice.supplierId]);
      }
    });
    await loadInvoices();
    return invoiceId;
  }

  Future<void> addPayment(int invoiceId, double amount, String method) async {
    final db = AppDatabase.instance;
    await db.transaction((txn) async {
      final invoice = await txn.query('purchase_invoices',
          where: 'id = ?', whereArgs: [invoiceId]);
      if (invoice.isEmpty) return;
      final current = invoice.first;
      final newPaid =
          ((current['paid_amount'] as num?)?.toDouble() ?? 0) + amount;
      final total = (current['total'] as num?)?.toDouble() ?? 0;
      final newRemaining = total - newPaid;
      final newStatus = newRemaining <= 0 ? 'paid' : newPaid > 0 ? 'partial' : 'pending';
      await txn.update('purchase_invoices',
          {'paid_amount': newPaid, 'remaining': newRemaining, 'status': newStatus},
          where: 'id = ?', whereArgs: [invoiceId]);
      if (current['supplier_id'] != null) {
        await txn.rawUpdate(
            'UPDATE suppliers SET balance = balance - ? WHERE id = ?',
            [amount, current['supplier_id']]);
      }
    });
    await loadInvoices();
  }

  Future<String> generateInvoiceNumber() async {
    final settings = await AppDatabase.instance.getAllSettings();
    final prefix = settings['purchase_prefix'] ?? 'PUR';
    return AppDatabase.instance.generateNumber(prefix, 'purchase_invoices', 'invoice_number');
  }
}
