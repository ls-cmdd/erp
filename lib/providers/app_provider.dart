import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
  List<Customer>  _customers  = [];
  List<Supplier>  _suppliers  = [];
  List<Product>   _products   = [];
  List<Category>  _categories = [];
  List<Unit>      _units      = [];
  DashboardStats  _stats      = const DashboardStats();
  int  _selectedIndex = 0;

  List<Customer>  get customers      => _customers;
  List<Supplier>  get suppliers      => _suppliers;
  List<Product>   get products       => _products;
  List<Category>  get categories     => _categories;
  List<Unit>      get units          => _units;
  DashboardStats  get stats          => _stats;
  int             get selectedIndex  => _selectedIndex;

  void setSelectedIndex(int i) { _selectedIndex = i; notifyListeners(); }

  Future<void> init() async {
    await Future.wait([loadCustomers(), loadSuppliers(), loadProducts(),
        loadCategories(), loadUnits(), loadDashboardStats()]);
  }

  Future<void> loadCustomers({String? search, bool activeOnly = true}) async {
    final conditions = <String>[];
    final args       = <dynamic>[];
    if (activeOnly)    { conditions.add('is_active = 1'); }
    if (search != null && search.isNotEmpty) {
      conditions.add('(name LIKE ? OR phone LIKE ? OR company LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final r = await AppDatabase.instance.query('customers',
        where: where, whereArgs: args.isEmpty ? null : args, orderBy: 'name ASC');
    _customers = r.map(Customer.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadSuppliers({String? search, bool activeOnly = true}) async {
    final conditions = <String>[];
    final args       = <dynamic>[];
    if (activeOnly)    { conditions.add('is_active = 1'); }
    if (search != null && search.isNotEmpty) {
      conditions.add('(name LIKE ? OR phone LIKE ? OR company LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final r = await AppDatabase.instance.query('suppliers',
        where: where, whereArgs: args.isEmpty ? null : args, orderBy: 'name ASC');
    _suppliers = r.map(Supplier.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadProducts({String? search, int? categoryId, bool activeOnly = true}) async {
    final conds = <String>[];
    final args  = <dynamic>[];
    if (activeOnly) conds.add('p.is_active = 1');
    if (search != null && search.isNotEmpty) {
      conds.add('(p.name_ar LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (categoryId != null) { conds.add('p.category_id = ?'); args.add(categoryId); }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';
    final r = await AppDatabase.instance.rawQuery('''
      SELECT p.*, c.name_ar as category_name, u.name_ar as unit_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN units u ON p.unit_id = u.id
      $where ORDER BY p.name_ar ASC
    ''', args.isEmpty ? null : args);
    _products = r.map(Product.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final r = await AppDatabase.instance.query('categories',
        where: 'is_active = 1', orderBy: 'name_ar ASC');
    _categories = r.map(Category.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadUnits() async {
    final r = await AppDatabase.instance.query('units',
        where: 'is_active = 1', orderBy: 'name_ar ASC');
    _units = r.map(Unit.fromMap).toList();
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    final db  = AppDatabase.instance;
    final now = DateTime.now();
    final yearStart = '${now.year}-01-01';

    final sales     = await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM sales_invoices WHERE status!='cancelled'");
    final purchases = await db.rawQuery("SELECT COALESCE(SUM(total),0) v FROM purchase_invoices WHERE status!='cancelled'");
    final expenses  = await db.rawQuery("SELECT COALESCE(SUM(amount),0) v FROM expenses");
    final custCnt   = await db.rawQuery("SELECT COUNT(*) v FROM customers WHERE is_active=1");
    final suppCnt   = await db.rawQuery("SELECT COUNT(*) v FROM suppliers WHERE is_active=1");
    final prodCnt   = await db.rawQuery("SELECT COUNT(*) v FROM products WHERE is_active=1");
    final empCnt    = await db.rawQuery("SELECT COUNT(*) v FROM employees WHERE is_active=1");
    final pending   = await db.rawQuery("SELECT COUNT(*) v FROM sales_invoices WHERE status='pending'");
    final lowStock  = await db.rawQuery("SELECT COUNT(*) v FROM products WHERE stock_qty<=min_stock AND min_stock>0");

    final monthlySales = await db.rawQuery('''
      SELECT strftime('%Y-%m',date) month, COALESCE(SUM(total),0) total
      FROM sales_invoices WHERE date>=? AND status!='cancelled'
      GROUP BY strftime('%Y-%m',date) ORDER BY month
    ''', [yearStart]);

    final monthlyPurch = await db.rawQuery('''
      SELECT strftime('%Y-%m',date) month, COALESCE(SUM(total),0) total
      FROM purchase_invoices WHERE date>=? AND status!='cancelled'
      GROUP BY strftime('%Y-%m',date) ORDER BY month
    ''', [yearStart]);

    final recentSales = await db.rawQuery('''
      SELECT s.invoice_number, s.date, s.total, s.status, c.name customer_name
      FROM sales_invoices s LEFT JOIN customers c ON s.customer_id=c.id
      ORDER BY s.created_at DESC LIMIT 10
    ''');

    final topProducts = await db.rawQuery('''
      SELECT p.name_ar, SUM(si.qty) total_qty, SUM(si.total) total_amount
      FROM sale_items si JOIN products p ON si.product_id=p.id
      JOIN sales_invoices inv ON si.invoice_id=inv.id WHERE inv.status!='cancelled'
      GROUP BY si.product_id ORDER BY total_amount DESC LIMIT 6
    ''');

    final byCategory = await db.rawQuery('''
      SELECT c.name_ar category, SUM(si.total) total
      FROM sale_items si JOIN products p ON si.product_id=p.id
      JOIN categories c ON p.category_id=c.id
      JOIN sales_invoices inv ON si.invoice_id=inv.id WHERE inv.status!='cancelled'
      GROUP BY p.category_id ORDER BY total DESC LIMIT 6
    ''');

    final ts = (sales.first['v'] as num?)?.toDouble() ?? 0;
    final tp = (purchases.first['v'] as num?)?.toDouble() ?? 0;
    final te = (expenses.first['v'] as num?)?.toDouble() ?? 0;

    _stats = DashboardStats(
      totalSales      : ts,
      totalPurchases  : tp,
      totalExpenses   : te,
      netProfit       : ts - tp - te,
      totalCustomers  : (custCnt.first['v'] as int?) ?? 0,
      totalSuppliers  : (suppCnt.first['v'] as int?) ?? 0,
      totalProducts   : (prodCnt.first['v'] as int?) ?? 0,
      totalEmployees  : (empCnt.first['v'] as int?) ?? 0,
      pendingInvoices : (pending.first['v'] as int?) ?? 0,
      lowStockProducts: (lowStock.first['v'] as int?) ?? 0,
      monthlySales    : monthlySales.map((r) => Map<String,dynamic>.from(r)).toList(),
      monthlyPurchases: monthlyPurch.map((r)  => Map<String,dynamic>.from(r)).toList(),
      recentSales     : recentSales.map((r)   => Map<String,dynamic>.from(r)).toList(),
      topProducts     : topProducts.map((r)   => Map<String,dynamic>.from(r)).toList(),
      salesByCategory : byCategory.map((r)    => Map<String,dynamic>.from(r)).toList(),
    );
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<int> saveCustomer(Customer c) async {
    int id;
    if (c.id != null) { await AppDatabase.instance.update('customers', c.toMap(), where: 'id=?', whereArgs: [c.id]); id = c.id!; }
    else id = await AppDatabase.instance.insert('customers', c.toMap());
    await loadCustomers(); return id;
  }
  Future<void> deleteCustomer(int id) async {
    await AppDatabase.instance.update('customers', {'is_active':0}, where:'id=?', whereArgs:[id]);
    await loadCustomers();
  }
  Future<int> saveSupplier(Supplier s) async {
    int id;
    if (s.id != null) { await AppDatabase.instance.update('suppliers', s.toMap(), where: 'id=?', whereArgs: [s.id]); id = s.id!; }
    else id = await AppDatabase.instance.insert('suppliers', s.toMap());
    await loadSuppliers(); return id;
  }
  Future<void> deleteSupplier(int id) async {
    await AppDatabase.instance.update('suppliers', {'is_active':0}, where:'id=?', whereArgs:[id]);
    await loadSuppliers();
  }
  Future<int> saveProduct(Product p) async {
    int id;
    if (p.id != null) { await AppDatabase.instance.update('products', p.toMap(), where: 'id=?', whereArgs: [p.id]); id = p.id!; }
    else id = await AppDatabase.instance.insert('products', p.toMap());
    await loadProducts(); return id;
  }
  Future<void> deleteProduct(int id) async {
    await AppDatabase.instance.update('products', {'is_active':0}, where:'id=?', whereArgs:[id]);
    await loadProducts();
  }
  Future<int> saveCategory(Category c) async {
    int id;
    if (c.id != null) { await AppDatabase.instance.update('categories', c.toMap(), where:'id=?', whereArgs:[c.id]); id = c.id!; }
    else id = await AppDatabase.instance.insert('categories', c.toMap());
    await loadCategories(); return id;
  }
  Future<int> saveUnit(Unit u) async {
    int id;
    if (u.id != null) { await AppDatabase.instance.update('units', u.toMap(), where:'id=?', whereArgs:[u.id]); id = u.id!; }
    else id = await AppDatabase.instance.insert('units', u.toMap());
    await loadUnits(); return id;
  }
}
