import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/models.dart';

class HRProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _leaves = [];
  List<Payroll> _payroll = [];
  bool _isLoading = false;

  List<Employee> get employees => _employees;
  List<Map<String, dynamic>> get attendance => _attendance;
  List<Map<String, dynamic>> get leaves => _leaves;
  List<Payroll> get payroll => _payroll;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await loadEmployees();
  }

  Future<void> loadEmployees({String? search, bool activeOnly = true}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conditions = <String>[];
      final args = <dynamic>[];
      if (activeOnly) conditions.add('is_active = 1');
      if (search != null && search.isNotEmpty) {
        conditions.add('(name LIKE ? OR position LIKE ? OR department LIKE ? OR phone LIKE ?)');
        args.addAll(['%$search%', '%$search%', '%$search%', '%$search%']);
      }
      final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
      final result = await AppDatabase.instance.rawQuery(
          'SELECT * FROM employees $where ORDER BY name ASC',
          args.isEmpty ? null : args);
      _employees = result.map((r) => Employee.fromMap(r)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> saveEmployee(Employee emp) async {
    int id;
    if (emp.id != null) {
      await AppDatabase.instance.update('employees', emp.toMap(),
          where: 'id = ?', whereArgs: [emp.id]);
      id = emp.id!;
    } else {
      // Generate employee code
      final count = await AppDatabase.instance.rawQuery(
          'SELECT COUNT(*) as cnt FROM employees');
      final cnt = (count.first['cnt'] as int?) ?? 0;
      emp.code = 'EMP${(cnt + 1).toString().padLeft(4, '0')}';
      id = await AppDatabase.instance.insert('employees', emp.toMap());
    }
    await loadEmployees();
    return id;
  }

  Future<void> deleteEmployee(int id) async {
    await AppDatabase.instance.update('employees', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
    await loadEmployees();
  }

  Future<void> loadAttendance({int? employeeId, String? month}) async {
    final conditions = <String>[];
    final args = <dynamic>[];
    if (employeeId != null) {
      conditions.add('a.employee_id = ?');
      args.add(employeeId);
    }
    if (month != null) {
      conditions.add("strftime('%Y-%m', a.date) = ?");
      args.add(month);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final result = await AppDatabase.instance.rawQuery('''
      SELECT a.*, e.name as employee_name, e.position
      FROM attendance a
      JOIN employees e ON a.employee_id = e.id
      $where
      ORDER BY a.date DESC LIMIT 300
    ''', args.isEmpty ? null : args);
    _attendance = result.map((r) => Map<String, dynamic>.from(r)).toList();
    notifyListeners();
  }

  Future<void> saveAttendance(Map<String, dynamic> record) async {
    final existing = await AppDatabase.instance.query('attendance',
        where: 'employee_id = ? AND date = ?',
        whereArgs: [record['employee_id'], record['date']]);
    if (existing.isNotEmpty) {
      await AppDatabase.instance.update('attendance', record,
          where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await AppDatabase.instance.insert('attendance', record);
    }
    await loadAttendance();
  }

  Future<void> loadLeaves({int? employeeId, String? status}) async {
    final conditions = <String>[];
    final args = <dynamic>[];
    if (employeeId != null) {
      conditions.add('l.employee_id = ?');
      args.add(employeeId);
    }
    if (status != null) {
      conditions.add('l.status = ?');
      args.add(status);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final result = await AppDatabase.instance.rawQuery('''
      SELECT l.*, e.name as employee_name
      FROM leaves l
      JOIN employees e ON l.employee_id = e.id
      $where
      ORDER BY l.created_at DESC
    ''', args.isEmpty ? null : args);
    _leaves = result.map((r) => Map<String, dynamic>.from(r)).toList();
    notifyListeners();
  }

  Future<void> saveLeave(Map<String, dynamic> leave) async {
    if (leave['id'] != null) {
      await AppDatabase.instance.update('leaves', leave,
          where: 'id = ?', whereArgs: [leave['id']]);
    } else {
      await AppDatabase.instance.insert('leaves', leave);
    }
    await loadLeaves();
  }

  Future<void> approveLeave(int id) async {
    await AppDatabase.instance.update('leaves', {'status': 'approved'},
        where: 'id = ?', whereArgs: [id]);
    await loadLeaves();
  }

  Future<void> rejectLeave(int id) async {
    await AppDatabase.instance.update('leaves', {'status': 'rejected'},
        where: 'id = ?', whereArgs: [id]);
    await loadLeaves();
  }

  Future<void> loadPayroll({int? year, int? month}) async {
    final conditions = <String>[];
    final args = <dynamic>[];
    if (year != null) {
      conditions.add('p.year = ?');
      args.add(year);
    }
    if (month != null) {
      conditions.add('p.month = ?');
      args.add(month);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final result = await AppDatabase.instance.rawQuery('''
      SELECT p.*, e.name as employee_name, e.position, e.department
      FROM payroll p
      JOIN employees e ON p.employee_id = e.id
      $where
      ORDER BY p.year DESC, p.month DESC
    ''', args.isEmpty ? null : args);
    _payroll = result.map((r) => Payroll.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> generateMonthlyPayroll(int month, int year) async {
    final employees = await AppDatabase.instance.query('employees',
        where: 'is_active = 1');
    for (final emp in employees) {
      final existing = await AppDatabase.instance.query('payroll',
          where: 'employee_id = ? AND month = ? AND year = ?',
          whereArgs: [emp['id'], month, year]);
      if (existing.isNotEmpty) continue;

      final basicSalary = (emp['basic_salary'] as num?)?.toDouble() ?? 0;
      final housing = (emp['housing_allowance'] as num?)?.toDouble() ?? 0;
      final transport = (emp['transport_allowance'] as num?)?.toDouble() ?? 0;
      final food = (emp['food_allowance'] as num?)?.toDouble() ?? 0;
      final other = (emp['other_allowances'] as num?)?.toDouble() ?? 0;
      final totalAllowances = housing + transport + food + other;
      final grossSalary = basicSalary + totalAllowances;
      // GOSI: employee 10%, employer 12%
      final gosiEmp = basicSalary * 0.10;
      final gosiEmpR = basicSalary * 0.12;
      final netSalary = grossSalary - gosiEmp;

      final payNum = await AppDatabase.instance.generateNumber(
          'PAY', 'payroll', 'payroll_number');

      final payroll = Payroll(
        payrollNumber: payNum,
        employeeId: emp['id'] as int,
        month: month,
        year: year,
        basicSalary: basicSalary,
        totalAllowances: totalAllowances,
        gosiEmployee: gosiEmp,
        gosiEmployer: gosiEmpR,
        netSalary: netSalary,
        status: 'draft',
      );
      await AppDatabase.instance.insert('payroll', payroll.toMap());
    }
    await loadPayroll(month: month, year: year);
  }

  Future<void> approvePayroll(int id) async {
    await AppDatabase.instance.update('payroll',
        {'status': 'approved', 'paid_date': DateTime.now().toIso8601String().substring(0, 10)},
        where: 'id = ?', whereArgs: [id]);
    await loadPayroll();
  }

  Future<Map<String, dynamic>> getAttendanceSummary(int employeeId, int month, int year) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final result = await AppDatabase.instance.rawQuery('''
      SELECT 
        COUNT(*) as total_days,
        SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) as present,
        SUM(CASE WHEN status='absent' THEN 1 ELSE 0 END) as absent,
        SUM(CASE WHEN status='late' THEN 1 ELSE 0 END) as late,
        SUM(overtime_hours) as overtime
      FROM attendance
      WHERE employee_id = ? AND strftime('%Y-%m', date) = ?
    ''', [employeeId, monthStr]);
    return result.isEmpty ? {} : Map<String, dynamic>.from(result.first);
  }
}
