import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/models.dart';

class InventoryProvider extends ChangeNotifier {
  List<Product> _lowStockProducts = [];
  List<Map<String, dynamic>> _stockMovements = [];
  bool _isLoading = false;

  List<Product> get lowStockProducts => _lowStockProducts;
  List<Map<String, dynamic>> get stockMovements => _stockMovements;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await loadLowStock();
  }

  Future<void> loadLowStock() async {
    final result = await AppDatabase.instance.rawQuery('''
      SELECT p.*, c.name_ar as category_name, u.name_ar as unit_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN units u ON p.unit_id = u.id
      WHERE p.is_active = 1 AND p.stock_qty <= p.min_stock AND p.min_stock > 0
      ORDER BY (p.stock_qty - p.min_stock) ASC
    ''');
    _lowStockProducts = result.map((r) => Product.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> loadStockMovements({int? productId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final where = productId != null ? 'WHERE sm.product_id = ?' : '';
      final args = productId != null ? [productId] : null;
      final result = await AppDatabase.instance.rawQuery('''
        SELECT sm.*, p.name_ar as product_name
        FROM stock_movements sm
        JOIN products p ON sm.product_id = p.id
        $where
        ORDER BY sm.created_at DESC
        LIMIT 200
      ''', args);
      _stockMovements = result.map((r) => Map<String, dynamic>.from(r)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adjustStock(int productId, double qty, String type, String? notes) async {
    final db = AppDatabase.instance;
    await db.transaction((txn) async {
      final product = await txn.query('products',
          columns: ['stock_qty'], where: 'id = ?', whereArgs: [productId]);
      if (product.isEmpty) return;
      final beforeQty = (product.first['stock_qty'] as num?)?.toDouble() ?? 0;
      final afterQty = type == 'in' ? beforeQty + qty : beforeQty - qty;
      await txn.update('products', {'stock_qty': afterQty},
          where: 'id = ?', whereArgs: [productId]);
      await txn.insert('stock_movements', {
        'product_id': productId,
        'type': type == 'in' ? 'adjustment_in' : 'adjustment_out',
        'quantity': qty,
        'before_qty': beforeQty,
        'after_qty': afterQty,
        'notes': notes,
      });
    });
    await loadLowStock();
    notifyListeners();
  }

  Future<double> getTotalStockValue() async {
    final result = await AppDatabase.instance.rawQuery(
        'SELECT SUM(stock_qty * cost_price) as total FROM products WHERE is_active = 1');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getProductHistory(int productId) async {
    return await AppDatabase.instance.rawQuery('''
      SELECT sm.*, 
             CASE sm.reference_type 
               WHEN 'sale' THEN 'مبيعات'
               WHEN 'purchase' THEN 'مشتريات'
               WHEN 'adjustment_in' THEN 'تعديل وارد'
               WHEN 'adjustment_out' THEN 'تعديل صادر'
               ELSE sm.reference_type END as type_label
      FROM stock_movements sm
      WHERE sm.product_id = ?
      ORDER BY sm.created_at DESC
    ''', [productId]);
  }
}
