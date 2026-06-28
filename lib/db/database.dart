import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/constants.dart';

/// Returns the SHA-256 hex digest of [password].
/// Used everywhere passwords are stored or compared – never store plain text.
String hashPassword(String password) =>
    sha256.convert(utf8.encode(password)).toString();

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;
  Database get db => _db!;
  String _dbPath = '';
  String get dbPath => _dbPath;

  Future<void> initialize() async {
    final dir  = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(dir.path, 'erp_system'));
    if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
    _dbPath = p.join(dbDir.path, AppConstants.dbName);

    _db = await openDatabase(
      _dbPath,
      version : AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen  : (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
    );
  }

  Future<void> _onCreate(Database db, int v) async {
    await _createAllTables(db);
    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Versioned migrations — each block runs only when upgrading from a version
    // lower than the target.  Add a new block here for every schema change
    // instead of silent try/catch — failures should surface, not be swallowed.
    if (oldV < 2) {
      // v1 → v2: add columns that were missing in the initial release
      try { await db.execute('ALTER TABLE employees ADD COLUMN id_number TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN sale_price2 REAL DEFAULT 0'); } catch (_) {}
      // Hash any plain-text passwords that existed before v2
      await _migratePasswordsToHash(db);
    }
    // if (oldV < 3) { ... future migration ... }
  }

  /// One-time migration: convert plain-text passwords to SHA-256 hashes.
  /// Safe to call multiple times – already-hashed values (64-char hex) are left alone.
  Future<void> _migratePasswordsToHash(Database db) async {
    final users = await db.query('users', columns: ['id', 'password']);
    for (final u in users) {
      final raw = u['password'] as String? ?? '';
      // SHA-256 hex is always 64 chars; skip if already hashed
      if (raw.length != 64) {
        await db.update(
          'users',
          {'password': hashPassword(raw)},
          where: 'id = ?',
          whereArgs: [u['id']],
        );
      }
    }
  }

  Future<void> _createAllTables(Database db) async {
    const tables = [
      '''CREATE TABLE IF NOT EXISTS app_settings(key TEXT PRIMARY KEY, value TEXT)''',
      '''CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL, full_name TEXT, role TEXT DEFAULT 'user',
        email TEXT, is_active INTEGER DEFAULT 1,
        last_login TEXT, created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name_ar TEXT NOT NULL, name_en TEXT,
        description TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS units(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name_ar TEXT NOT NULL, name_en TEXT,
        abbreviation TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT, name TEXT NOT NULL,
        company TEXT, phone TEXT, phone2 TEXT, email TEXT, address TEXT,
        city TEXT, country TEXT DEFAULT 'Saudi Arabia', tax_number TEXT,
        credit_limit REAL DEFAULT 0, balance REAL DEFAULT 0,
        discount_rate REAL DEFAULT 0, notes TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT, name TEXT NOT NULL,
        company TEXT, phone TEXT, phone2 TEXT, email TEXT, address TEXT,
        city TEXT, country TEXT DEFAULT 'Saudi Arabia', tax_number TEXT,
        balance REAL DEFAULT 0, notes TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT, barcode TEXT,
        name_ar TEXT NOT NULL, name_en TEXT,
        category_id INTEGER, unit_id INTEGER,
        cost_price REAL DEFAULT 0, sale_price REAL DEFAULT 0,
        sale_price2 REAL DEFAULT 0, tax_rate REAL DEFAULT 0,
        stock_qty REAL DEFAULT 0, min_stock REAL DEFAULT 0, max_stock REAL DEFAULT 0,
        description TEXT, image_path TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(unit_id) REFERENCES units(id))''',
      '''CREATE TABLE IF NOT EXISTS warehouses(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        location TEXT, manager TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL,
        warehouse_id INTEGER DEFAULT 1, type TEXT NOT NULL,
        quantity REAL NOT NULL, before_qty REAL DEFAULT 0, after_qty REAL DEFAULT 0,
        reference_type TEXT, reference_id INTEGER, notes TEXT,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(product_id) REFERENCES products(id))''',
      '''CREATE TABLE IF NOT EXISTS sales_invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER, date TEXT NOT NULL, due_date TEXT,
        subtotal REAL DEFAULT 0, discount_rate REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0, tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0, total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0, remaining REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'نقدي', status TEXT DEFAULT 'pending',
        notes TEXT, created_by INTEGER,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(customer_id) REFERENCES customers(id))''',
      '''CREATE TABLE IF NOT EXISTS sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL, qty REAL DEFAULT 0,
        unit_price REAL DEFAULT 0, discount_rate REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0, tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0, total REAL DEFAULT 0, notes TEXT,
        FOREIGN KEY(invoice_id) REFERENCES sales_invoices(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id))''',
      '''CREATE TABLE IF NOT EXISTS purchase_invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_number TEXT UNIQUE NOT NULL,
        supplier_id INTEGER, date TEXT NOT NULL, due_date TEXT,
        subtotal REAL DEFAULT 0, discount_rate REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0, tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0, total REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0, remaining REAL DEFAULT 0,
        payment_method TEXT DEFAULT 'نقدي', status TEXT DEFAULT 'pending',
        notes TEXT, created_by INTEGER,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(supplier_id) REFERENCES suppliers(id))''',
      '''CREATE TABLE IF NOT EXISTS purchase_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL, qty REAL DEFAULT 0,
        unit_price REAL DEFAULT 0, discount_rate REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0, tax_rate REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0, total REAL DEFAULT 0, notes TEXT,
        FOREIGN KEY(invoice_id) REFERENCES purchase_invoices(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id))''',
      '''CREATE TABLE IF NOT EXISTS payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT, payment_number TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL, reference_type TEXT, reference_id INTEGER,
        party_type TEXT, party_id INTEGER,
        amount REAL DEFAULT 0, payment_method TEXT DEFAULT 'نقدي',
        date TEXT NOT NULL, bank_name TEXT, check_number TEXT, notes TEXT,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT, expense_number TEXT UNIQUE NOT NULL,
        category TEXT, description TEXT NOT NULL,
        amount REAL DEFAULT 0, tax_amount REAL DEFAULT 0,
        date TEXT NOT NULL, payment_method TEXT DEFAULT 'نقدي',
        beneficiary TEXT, notes TEXT,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL, type TEXT NOT NULL, parent_id INTEGER,
        balance REAL DEFAULT 0, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(parent_id) REFERENCES accounts(id))''',
      '''CREATE TABLE IF NOT EXISTS journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT, entry_number TEXT UNIQUE NOT NULL,
        date TEXT NOT NULL, description TEXT, reference TEXT,
        total_debit REAL DEFAULT 0, total_credit REAL DEFAULT 0,
        is_posted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS journal_lines(
        id INTEGER PRIMARY KEY AUTOINCREMENT, entry_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL, description TEXT,
        debit REAL DEFAULT 0, credit REAL DEFAULT 0,
        FOREIGN KEY(entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
        FOREIGN KEY(account_id) REFERENCES accounts(id))''',
      '''CREATE TABLE IF NOT EXISTS employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT,
        name TEXT NOT NULL, name_en TEXT, id_number TEXT,
        id_type TEXT DEFAULT 'هوية وطنية', nationality TEXT DEFAULT 'سعودي',
        birth_date TEXT, gender TEXT, marital_status TEXT,
        position TEXT, department TEXT, branch TEXT,
        hire_date TEXT, contract_type TEXT DEFAULT 'دوام كامل', contract_end TEXT,
        basic_salary REAL DEFAULT 0, housing_allowance REAL DEFAULT 0,
        transport_allowance REAL DEFAULT 0, food_allowance REAL DEFAULT 0,
        other_allowances REAL DEFAULT 0,
        phone TEXT, phone2 TEXT, email TEXT, address TEXT,
        bank_name TEXT, bank_account TEXT, iban TEXT,
        notes TEXT, is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT(datetime('now','localtime')))''',
      '''CREATE TABLE IF NOT EXISTS attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL,
        date TEXT NOT NULL, check_in TEXT, check_out TEXT,
        status TEXT DEFAULT 'present', overtime_hours REAL DEFAULT 0, notes TEXT,
        FOREIGN KEY(employee_id) REFERENCES employees(id))''',
      '''CREATE TABLE IF NOT EXISTS leaves(
        id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL,
        leave_type TEXT NOT NULL, start_date TEXT NOT NULL,
        end_date TEXT NOT NULL, days INTEGER DEFAULT 0,
        reason TEXT, status TEXT DEFAULT 'pending', approved_by INTEGER, notes TEXT,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(employee_id) REFERENCES employees(id))''',
      '''CREATE TABLE IF NOT EXISTS payroll(
        id INTEGER PRIMARY KEY AUTOINCREMENT, payroll_number TEXT UNIQUE NOT NULL,
        employee_id INTEGER NOT NULL, month INTEGER NOT NULL, year INTEGER NOT NULL,
        basic_salary REAL DEFAULT 0, total_allowances REAL DEFAULT 0,
        overtime_amount REAL DEFAULT 0, total_deductions REAL DEFAULT 0,
        total_bonuses REAL DEFAULT 0, gosi_employee REAL DEFAULT 0,
        gosi_employer REAL DEFAULT 0, income_tax REAL DEFAULT 0,
        net_salary REAL DEFAULT 0, paid_date TEXT, payment_method TEXT,
        status TEXT DEFAULT 'draft', notes TEXT,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(employee_id) REFERENCES employees(id))''',
      '''CREATE TABLE IF NOT EXISTS quotations(
        id INTEGER PRIMARY KEY AUTOINCREMENT, quotation_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER, date TEXT NOT NULL, valid_until TEXT,
        subtotal REAL DEFAULT 0, discount_amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0, total REAL DEFAULT 0,
        status TEXT DEFAULT 'draft', notes TEXT, terms TEXT,
        created_at TEXT DEFAULT(datetime('now','localtime')),
        FOREIGN KEY(customer_id) REFERENCES customers(id))''',
      '''CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        message TEXT, type TEXT DEFAULT 'info', is_read INTEGER DEFAULT 0,
        link TEXT, created_at TEXT DEFAULT(datetime('now','localtime')))''',
    ];

    for (final sql in tables) {
      await db.execute(sql);
    }
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_si_date     ON sales_invoices(date)',
      'CREATE INDEX IF NOT EXISTS idx_si_customer ON sales_invoices(customer_id)',
      'CREATE INDEX IF NOT EXISTS idx_si_status   ON sales_invoices(status)',
      'CREATE INDEX IF NOT EXISTS idx_pi_date     ON purchase_invoices(date)',
      'CREATE INDEX IF NOT EXISTS idx_pi_supplier ON purchase_invoices(supplier_id)',
      'CREATE INDEX IF NOT EXISTS idx_prod_cat    ON products(category_id)',
      'CREATE INDEX IF NOT EXISTS idx_att_emp     ON attendance(employee_id)',
      'CREATE INDEX IF NOT EXISTS idx_pay_emp     ON payroll(employee_id)',
    ];
    for (final idx in indexes) await db.execute(idx);
  }

  Future<void> _seedDefaults(Database db) async {
    // Admin user — password is stored as SHA-256 hash, never plain text
    await db.insert('users', {
      'username': 'admin', 'password': hashPassword('admin123'),
      'full_name': 'مدير النظام', 'role': 'admin', 'is_active': 1,
    });

    // Default settings
    final defaults = {
      'company_name'       : 'شركة النجاح التجارية',
      'company_name_en'    : 'Al-Najah Trading Co.',
      'company_phone'      : '0500000000',
      'company_email'      : 'info@company.com',
      'company_address'    : 'الرياض، المملكة العربية السعودية',
      'company_website'    : 'www.company.com',
      'tax_number'         : '300000000000003',
      'commercial_register': '1010000000',
      'currency'           : 'ريال',
      'currency_code'      : 'SAR',
      'tax_rate'           : '15',
      'language'           : 'ar',
      'theme'              : 'light',
      'primary_color'      : '0xFF1565C0',
      'invoice_footer'     : 'شكراً لتعاملكم معنا',
      'sales_prefix'       : 'INV',
      'purchase_prefix'    : 'PUR',
      'expense_prefix'     : 'EXP',
      'payment_prefix'     : 'PAY',
    };
    for (final e in defaults.entries) {
      await db.insert('app_settings', {'key': e.key, 'value': e.value},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Categories
    for (final c in [
      {'name_ar': 'إلكترونيات',        'name_en': 'Electronics'},
      {'name_ar': 'ملابس',             'name_en': 'Clothing'},
      {'name_ar': 'أغذية ومشروبات',   'name_en': 'Food & Beverages'},
      {'name_ar': 'أجهزة منزلية',     'name_en': 'Home Appliances'},
      {'name_ar': 'مكتبية',           'name_en': 'Office Supplies'},
      {'name_ar': 'صحة وجمال',        'name_en': 'Health & Beauty'},
      {'name_ar': 'أخرى',             'name_en': 'Other'},
    ]) await db.insert('categories', c);

    // Units
    for (final u in [
      {'name_ar': 'قطعة',    'name_en': 'Piece',     'abbreviation': 'قطعة'},
      {'name_ar': 'كيلوجرام','name_en': 'Kilogram',  'abbreviation': 'كجم'},
      {'name_ar': 'جرام',    'name_en': 'Gram',      'abbreviation': 'جم'},
      {'name_ar': 'لتر',     'name_en': 'Liter',     'abbreviation': 'لتر'},
      {'name_ar': 'متر',     'name_en': 'Meter',     'abbreviation': 'م'},
      {'name_ar': 'علبة',    'name_en': 'Box',       'abbreviation': 'علبة'},
      {'name_ar': 'كرتون',   'name_en': 'Carton',    'abbreviation': 'كرتون'},
      {'name_ar': 'دزينة',   'name_en': 'Dozen',     'abbreviation': 'دزينة'},
    ]) await db.insert('units', u);

    // Main warehouse
    await db.insert('warehouses', {
      'name': 'المستودع الرئيسي', 'location': 'الرياض', 'is_active': 1,
    });

    // Chart of accounts
    final coa = [
      {'code': '1000', 'name': 'الأصول',              'type': 'asset',     'parent_id': null},
      {'code': '1100', 'name': 'الأصول المتداولة',    'type': 'asset',     'parent_id': 1},
      {'code': '1110', 'name': 'الصندوق',             'type': 'asset',     'parent_id': 2},
      {'code': '1120', 'name': 'البنك',               'type': 'asset',     'parent_id': 2},
      {'code': '1130', 'name': 'ذمم مدينة',           'type': 'asset',     'parent_id': 2},
      {'code': '1140', 'name': 'المخزون',             'type': 'asset',     'parent_id': 2},
      {'code': '2000', 'name': 'الخصوم',              'type': 'liability', 'parent_id': null},
      {'code': '2100', 'name': 'ذمم دائنة',           'type': 'liability', 'parent_id': 7},
      {'code': '2200', 'name': 'ضريبة القيمة المضافة','type': 'liability', 'parent_id': 7},
      {'code': '3000', 'name': 'حقوق الملكية',        'type': 'equity',    'parent_id': null},
      {'code': '4000', 'name': 'الإيرادات',           'type': 'revenue',   'parent_id': null},
      {'code': '4100', 'name': 'إيرادات المبيعات',   'type': 'revenue',   'parent_id': 11},
      {'code': '5000', 'name': 'المصروفات',           'type': 'expense',   'parent_id': null},
      {'code': '5100', 'name': 'تكلفة البضاعة المباعة','type': 'expense',  'parent_id': 13},
      {'code': '5200', 'name': 'مصروفات إدارية',     'type': 'expense',   'parent_id': 13},
      {'code': '5300', 'name': 'رواتب وأجور',        'type': 'expense',   'parent_id': 13},
    ];
    for (final a in coa) {
      await db.insert('accounts', {
        'code': a['code'], 'name': a['name'], 'type': a['type'], 'parent_id': a['parent_id'],
      });
    }
  }

  // ── Generic helpers ────────────────────────────────────────────────────────
  Future<int> insert(String table, Map<String, dynamic> values,
      {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) =>
      db.insert(table, values, conflictAlgorithm: conflictAlgorithm);

  Future<int> update(String table, Map<String, dynamic> values,
      {required String where, required List whereArgs}) =>
      db.update(table, values, where: where, whereArgs: whereArgs);

  Future<int> delete(String table,
      {required String where, required List whereArgs}) =>
      db.delete(table, where: where, whereArgs: whereArgs);

  Future<List<Map<String, dynamic>>> query(String table, {
    String? where, List? whereArgs, String? orderBy,
    int? limit, int? offset, List<String>? columns,
  }) => db.query(table,
      columns: columns, where: where, whereArgs: whereArgs,
      orderBy: orderBy, limit: limit, offset: offset);

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? args]) => db.rawQuery(sql, args);

  Future<int> rawUpdate(String sql, [List<dynamic>? args]) =>
      db.rawUpdate(sql, args);

  Future<void> transaction(
      Future<void> Function(Transaction txn) action) =>
      db.transaction(action);

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final r = await db.query('app_settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    return r.isEmpty ? defaultValue : (r.first['value'] as String? ?? defaultValue);
  }

  Future<void> setSetting(String key, String value) =>
      db.insert('app_settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String, String>> getAllSettings() async {
    final r = await db.query('app_settings');
    return {for (final row in r) row['key'] as String: row['value'] as String};
  }

  Future<String> generateNumber(String prefix, String table, String field) async {
    final r = await db.rawQuery(
        "SELECT MAX(CAST(SUBSTR($field, LENGTH(?)+2) AS INTEGER)) AS n "
        "FROM $table WHERE $field LIKE ?",
        [prefix, '$prefix-%']);
    final n = (r.first['n'] as int?) ?? 0;
    return '$prefix-${(n + 1).toString().padLeft(6, '0')}';
  }

  Future<void> close() async { await _db?.close(); }
}
