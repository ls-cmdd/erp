// ─── Models ───────────────────────────────────────────────────────────────────

class Category {
  int? id; String nameAr; String nameEn; String? description; bool isActive;
  Category({this.id, required this.nameAr, required this.nameEn,
      this.description, this.isActive = true});
  factory Category.fromMap(Map<String, dynamic> m) => Category(
      id: m['id'], nameAr: m['name_ar'] ?? '', nameEn: m['name_en'] ?? '',
      description: m['description'], isActive: (m['is_active'] ?? 1) == 1);
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name_ar': nameAr, 'name_en': nameEn,
    'description': description, 'is_active': isActive ? 1 : 0,
  };
}

class Unit {
  int? id; String nameAr; String nameEn; String? abbreviation; bool isActive;
  Unit({this.id, required this.nameAr, required this.nameEn,
      this.abbreviation, this.isActive = true});
  factory Unit.fromMap(Map<String, dynamic> m) => Unit(
      id: m['id'], nameAr: m['name_ar'] ?? '', nameEn: m['name_en'] ?? '',
      abbreviation: m['abbreviation'], isActive: (m['is_active'] ?? 1) == 1);
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name_ar': nameAr, 'name_en': nameEn,
    'abbreviation': abbreviation, 'is_active': isActive ? 1 : 0,
  };
}

class Customer {
  int? id; String? code; String name; String? company; String? phone;
  String? phone2; String? email; String? address; String? city;
  String? country; String? taxNumber; double creditLimit; double balance;
  double discountRate; String? notes; bool isActive; String? createdAt;

  Customer({this.id, this.code, required this.name, this.company,
      this.phone, this.phone2, this.email, this.address, this.city,
      this.country = 'Saudi Arabia', this.taxNumber, this.creditLimit = 0,
      this.balance = 0, this.discountRate = 0, this.notes,
      this.isActive = true, this.createdAt});

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
      id: m['id'], code: m['code'], name: m['name'] ?? '',
      company: m['company'], phone: m['phone'], phone2: m['phone2'],
      email: m['email'], address: m['address'], city: m['city'],
      country: m['country'], taxNumber: m['tax_number'],
      creditLimit: (m['credit_limit'] as num?)?.toDouble() ?? 0,
      balance: (m['balance'] as num?)?.toDouble() ?? 0,
      discountRate: (m['discount_rate'] as num?)?.toDouble() ?? 0,
      notes: m['notes'], isActive: (m['is_active'] ?? 1) == 1,
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'code': code, 'name': name, 'company': company,
    'phone': phone, 'phone2': phone2, 'email': email, 'address': address,
    'city': city, 'country': country, 'tax_number': taxNumber,
    'credit_limit': creditLimit, 'balance': balance,
    'discount_rate': discountRate, 'notes': notes, 'is_active': isActive ? 1 : 0,
  };
}

class Supplier {
  int? id; String? code; String name; String? company; String? phone;
  String? phone2; String? email; String? address; String? city;
  String? country; String? taxNumber; double balance;
  String? notes; bool isActive; String? createdAt;

  Supplier({this.id, this.code, required this.name, this.company,
      this.phone, this.phone2, this.email, this.address, this.city,
      this.country = 'Saudi Arabia', this.taxNumber, this.balance = 0,
      this.notes, this.isActive = true, this.createdAt});

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
      id: m['id'], code: m['code'], name: m['name'] ?? '',
      company: m['company'], phone: m['phone'], phone2: m['phone2'],
      email: m['email'], address: m['address'], city: m['city'],
      country: m['country'], taxNumber: m['tax_number'],
      balance: (m['balance'] as num?)?.toDouble() ?? 0,
      notes: m['notes'], isActive: (m['is_active'] ?? 1) == 1,
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'code': code, 'name': name, 'company': company,
    'phone': phone, 'phone2': phone2, 'email': email, 'address': address,
    'city': city, 'country': country, 'tax_number': taxNumber,
    'balance': balance, 'notes': notes, 'is_active': isActive ? 1 : 0,
  };
}

class Product {
  int? id; String? sku; String? barcode; String nameAr; String? nameEn;
  int? categoryId; String? categoryName; int? unitId; String? unitName;
  double costPrice; double salePrice; double salePrice2;
  double taxRate; double stockQty; double minStock; double maxStock;
  String? description; String? imagePath; bool isActive; String? createdAt;

  Product({this.id, this.sku, this.barcode, required this.nameAr,
      this.nameEn, this.categoryId, this.categoryName, this.unitId,
      this.unitName, this.costPrice = 0, this.salePrice = 0,
      this.salePrice2 = 0, this.taxRate = 0, this.stockQty = 0,
      this.minStock = 0, this.maxStock = 0, this.description,
      this.imagePath, this.isActive = true, this.createdAt});

  bool get isLowStock => minStock > 0 && stockQty <= minStock;
  double get stockValue => stockQty * costPrice;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
      id: m['id'], sku: m['sku'], barcode: m['barcode'],
      nameAr: m['name_ar'] ?? '', nameEn: m['name_en'],
      categoryId: m['category_id'], categoryName: m['category_name'],
      unitId: m['unit_id'], unitName: m['unit_name'],
      costPrice: (m['cost_price'] as num?)?.toDouble() ?? 0,
      salePrice: (m['sale_price'] as num?)?.toDouble() ?? 0,
      salePrice2: (m['sale_price2'] as num?)?.toDouble() ?? 0,
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
      stockQty: (m['stock_qty'] as num?)?.toDouble() ?? 0,
      minStock: (m['min_stock'] as num?)?.toDouble() ?? 0,
      maxStock: (m['max_stock'] as num?)?.toDouble() ?? 0,
      description: m['description'], imagePath: m['image_path'],
      isActive: (m['is_active'] ?? 1) == 1, createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'sku': sku, 'barcode': barcode,
    'name_ar': nameAr, 'name_en': nameEn, 'category_id': categoryId,
    'unit_id': unitId, 'cost_price': costPrice, 'sale_price': salePrice,
    'sale_price2': salePrice2, 'tax_rate': taxRate, 'stock_qty': stockQty,
    'min_stock': minStock, 'max_stock': maxStock, 'description': description,
    'image_path': imagePath, 'is_active': isActive ? 1 : 0,
  };
}

class InvoiceItem {
  int? id; int? invoiceId; int? productId; String? productName;
  String? productSku; double qty; double unitPrice; double discountRate;
  double discountAmount; double taxRate; double taxAmount; double total; String? notes;

  InvoiceItem({this.id, this.invoiceId, this.productId, this.productName,
      this.productSku, this.qty = 1, this.unitPrice = 0, this.discountRate = 0,
      this.discountAmount = 0, this.taxRate = 0, this.taxAmount = 0,
      this.total = 0, this.notes});

  void calculate() {
    final line  = qty * unitPrice;
    discountAmount = line * discountRate / 100;
    final after = line - discountAmount;
    taxAmount   = after * taxRate / 100;
    total       = after + taxAmount;
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
      id: m['id'], invoiceId: m['invoice_id'], productId: m['product_id'],
      productName: m['product_name'] ?? m['name_ar'],
      productSku: m['sku'],
      qty: (m['qty'] as num?)?.toDouble() ?? 0,
      unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
      discountRate: (m['discount_rate'] as num?)?.toDouble() ?? 0,
      discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      notes: m['notes']);

  Map<String, dynamic> toSaleMap(int invId) => {
    if (id != null) 'id': id, 'invoice_id': invId, 'product_id': productId,
    'qty': qty, 'unit_price': unitPrice, 'discount_rate': discountRate,
    'discount_amount': discountAmount, 'tax_rate': taxRate,
    'tax_amount': taxAmount, 'total': total, 'notes': notes,
  };

  Map<String, dynamic> toPurchaseMap(int invId) => {
    if (id != null) 'id': id, 'invoice_id': invId, 'product_id': productId,
    'qty': qty, 'unit_price': unitPrice, 'discount_rate': discountRate,
    'discount_amount': discountAmount, 'tax_rate': taxRate,
    'tax_amount': taxAmount, 'total': total, 'notes': notes,
  };
}

class SalesInvoice {
  int? id; String invoiceNumber; int? customerId; String? customerName;
  String date; String? dueDate; double subtotal; double discountRate;
  double discountAmount; double taxRate; double taxAmount; double total;
  double paidAmount; double remaining; String paymentMethod; String status;
  String? notes; List<InvoiceItem> items; String? createdAt;

  SalesInvoice({this.id, required this.invoiceNumber, this.customerId,
      this.customerName, required this.date, this.dueDate, this.subtotal = 0,
      this.discountRate = 0, this.discountAmount = 0, this.taxRate = 0,
      this.taxAmount = 0, this.total = 0, this.paidAmount = 0,
      this.remaining = 0, this.paymentMethod = 'نقدي',
      this.status = 'pending', this.notes, this.items = const [], this.createdAt});

  factory SalesInvoice.fromMap(Map<String, dynamic> m) => SalesInvoice(
      id: m['id'], invoiceNumber: m['invoice_number'] ?? '',
      customerId: m['customer_id'], customerName: m['customer_name'],
      date: m['date'] ?? '', dueDate: m['due_date'],
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
      discountRate: (m['discount_rate'] as num?)?.toDouble() ?? 0,
      discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
      remaining: (m['remaining'] as num?)?.toDouble() ?? 0,
      paymentMethod: m['payment_method'] ?? 'نقدي',
      status: m['status'] ?? 'pending', notes: m['notes'],
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'invoice_number': invoiceNumber,
    'customer_id': customerId, 'date': date, 'due_date': dueDate,
    'subtotal': subtotal, 'discount_rate': discountRate,
    'discount_amount': discountAmount, 'tax_rate': taxRate,
    'tax_amount': taxAmount, 'total': total, 'paid_amount': paidAmount,
    'remaining': remaining, 'payment_method': paymentMethod,
    'status': status, 'notes': notes,
  };
}

class PurchaseInvoice {
  int? id; String invoiceNumber; int? supplierId; String? supplierName;
  String date; String? dueDate; double subtotal; double discountRate;
  double discountAmount; double taxRate; double taxAmount; double total;
  double paidAmount; double remaining; String paymentMethod; String status;
  String? notes; List<InvoiceItem> items; String? createdAt;

  PurchaseInvoice({this.id, required this.invoiceNumber, this.supplierId,
      this.supplierName, required this.date, this.dueDate, this.subtotal = 0,
      this.discountRate = 0, this.discountAmount = 0, this.taxRate = 0,
      this.taxAmount = 0, this.total = 0, this.paidAmount = 0,
      this.remaining = 0, this.paymentMethod = 'نقدي',
      this.status = 'pending', this.notes, this.items = const [], this.createdAt});

  factory PurchaseInvoice.fromMap(Map<String, dynamic> m) => PurchaseInvoice(
      id: m['id'], invoiceNumber: m['invoice_number'] ?? '',
      supplierId: m['supplier_id'], supplierName: m['supplier_name'],
      date: m['date'] ?? '', dueDate: m['due_date'],
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
      discountRate: (m['discount_rate'] as num?)?.toDouble() ?? 0,
      discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
      taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
      taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      paidAmount: (m['paid_amount'] as num?)?.toDouble() ?? 0,
      remaining: (m['remaining'] as num?)?.toDouble() ?? 0,
      paymentMethod: m['payment_method'] ?? 'نقدي',
      status: m['status'] ?? 'pending', notes: m['notes'],
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'invoice_number': invoiceNumber,
    'supplier_id': supplierId, 'date': date, 'due_date': dueDate,
    'subtotal': subtotal, 'discount_rate': discountRate,
    'discount_amount': discountAmount, 'tax_rate': taxRate,
    'tax_amount': taxAmount, 'total': total, 'paid_amount': paidAmount,
    'remaining': remaining, 'payment_method': paymentMethod,
    'status': status, 'notes': notes,
  };
}

class Employee {
  int? id; String? code; String name; String? nameEn; String? idNumber;
  String? idType; String? nationality; String? birthDate; String? gender;
  String? maritalStatus; String? position; String? department; String? branch;
  String? hireDate; String? contractType; String? contractEnd;
  double basicSalary; double housingAllowance; double transportAllowance;
  double foodAllowance; double otherAllowances;
  String? phone; String? phone2; String? email; String? address;
  String? bankName; String? bankAccount; String? iban;
  String? notes; bool isActive; String? createdAt;

  Employee({this.id, this.code, required this.name, this.nameEn,
      this.idNumber, this.idType = 'هوية وطنية', this.nationality = 'سعودي',
      this.birthDate, this.gender, this.maritalStatus, this.position,
      this.department, this.branch, this.hireDate,
      this.contractType = 'دوام كامل', this.contractEnd,
      this.basicSalary = 0, this.housingAllowance = 0,
      this.transportAllowance = 0, this.foodAllowance = 0,
      this.otherAllowances = 0, this.phone, this.phone2, this.email,
      this.address, this.bankName, this.bankAccount, this.iban,
      this.notes, this.isActive = true, this.createdAt});

  double get totalSalary =>
      basicSalary + housingAllowance + transportAllowance + foodAllowance + otherAllowances;

  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
      id: m['id'], code: m['code'], name: m['name'] ?? '',
      nameEn: m['name_en'], idNumber: m['id_number'], idType: m['id_type'],
      nationality: m['nationality'], birthDate: m['birth_date'],
      gender: m['gender'], maritalStatus: m['marital_status'],
      position: m['position'], department: m['department'],
      branch: m['branch'], hireDate: m['hire_date'],
      contractType: m['contract_type'], contractEnd: m['contract_end'],
      basicSalary: (m['basic_salary'] as num?)?.toDouble() ?? 0,
      housingAllowance: (m['housing_allowance'] as num?)?.toDouble() ?? 0,
      transportAllowance: (m['transport_allowance'] as num?)?.toDouble() ?? 0,
      foodAllowance: (m['food_allowance'] as num?)?.toDouble() ?? 0,
      otherAllowances: (m['other_allowances'] as num?)?.toDouble() ?? 0,
      phone: m['phone'], phone2: m['phone2'], email: m['email'],
      address: m['address'], bankName: m['bank_name'],
      bankAccount: m['bank_account'], iban: m['iban'],
      notes: m['notes'], isActive: (m['is_active'] ?? 1) == 1,
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'code': code, 'name': name, 'name_en': nameEn,
    'id_number': idNumber, 'id_type': idType, 'nationality': nationality,
    'birth_date': birthDate, 'gender': gender, 'marital_status': maritalStatus,
    'position': position, 'department': department, 'branch': branch,
    'hire_date': hireDate, 'contract_type': contractType, 'contract_end': contractEnd,
    'basic_salary': basicSalary, 'housing_allowance': housingAllowance,
    'transport_allowance': transportAllowance, 'food_allowance': foodAllowance,
    'other_allowances': otherAllowances, 'phone': phone, 'phone2': phone2,
    'email': email, 'address': address, 'bank_name': bankName,
    'bank_account': bankAccount, 'iban': iban, 'notes': notes,
    'is_active': isActive ? 1 : 0,
  };
}

class Expense {
  int? id; String? expenseNumber; String? category; String description;
  double amount; double taxAmount; String date; String paymentMethod;
  String? beneficiary; String? notes; String? createdAt;

  Expense({this.id, this.expenseNumber, this.category, required this.description,
      this.amount = 0, this.taxAmount = 0, required this.date,
      this.paymentMethod = 'نقدي', this.beneficiary, this.notes, this.createdAt});

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
      id: m['id'], expenseNumber: m['expense_number'], category: m['category'],
      description: m['description'] ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
      date: m['date'] ?? '', paymentMethod: m['payment_method'] ?? 'نقدي',
      beneficiary: m['beneficiary'], notes: m['notes'],
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'expense_number': expenseNumber,
    'category': category, 'description': description,
    'amount': amount, 'tax_amount': taxAmount, 'date': date,
    'payment_method': paymentMethod, 'beneficiary': beneficiary, 'notes': notes,
  };
}

class Payment {
  int? id; String? paymentNumber; String type; String? referenceType;
  int? referenceId; String? partyType; int? partyId; String? partyName;
  double amount; String paymentMethod; String date;
  String? bankName; String? checkNumber; String? notes; String? createdAt;

  Payment({this.id, this.paymentNumber, required this.type, this.referenceType,
      this.referenceId, this.partyType, this.partyId, this.partyName,
      this.amount = 0, this.paymentMethod = 'نقدي', required this.date,
      this.bankName, this.checkNumber, this.notes, this.createdAt});

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
      id: m['id'], paymentNumber: m['payment_number'], type: m['type'] ?? '',
      referenceType: m['reference_type'], referenceId: m['reference_id'],
      partyType: m['party_type'], partyId: m['party_id'],
      partyName: m['party_name'],
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: m['payment_method'] ?? 'نقدي',
      date: m['date'] ?? '', bankName: m['bank_name'],
      checkNumber: m['check_number'], notes: m['notes'],
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'payment_number': paymentNumber, 'type': type,
    'reference_type': referenceType, 'reference_id': referenceId,
    'party_type': partyType, 'party_id': partyId, 'amount': amount,
    'payment_method': paymentMethod, 'date': date, 'bank_name': bankName,
    'check_number': checkNumber, 'notes': notes,
  };
}

class Payroll {
  int? id; String payrollNumber; int employeeId; String? employeeName;
  int month; int year; double basicSalary; double totalAllowances;
  double overtimeAmount; double totalDeductions; double totalBonuses;
  double gosiEmployee; double gosiEmployer; double incomeTax;
  double netSalary; String? paidDate; String? paymentMethod;
  String status; String? notes; String? createdAt;

  Payroll({this.id, required this.payrollNumber, required this.employeeId,
      this.employeeName, required this.month, required this.year,
      this.basicSalary = 0, this.totalAllowances = 0, this.overtimeAmount = 0,
      this.totalDeductions = 0, this.totalBonuses = 0, this.gosiEmployee = 0,
      this.gosiEmployer = 0, this.incomeTax = 0, this.netSalary = 0,
      this.paidDate, this.paymentMethod, this.status = 'draft',
      this.notes, this.createdAt});

  factory Payroll.fromMap(Map<String, dynamic> m) => Payroll(
      id: m['id'], payrollNumber: m['payroll_number'] ?? '',
      employeeId: m['employee_id'] ?? 0, employeeName: m['employee_name'],
      month: m['month'] ?? 1, year: m['year'] ?? 2025,
      basicSalary: (m['basic_salary'] as num?)?.toDouble() ?? 0,
      totalAllowances: (m['total_allowances'] as num?)?.toDouble() ?? 0,
      overtimeAmount: (m['overtime_amount'] as num?)?.toDouble() ?? 0,
      totalDeductions: (m['total_deductions'] as num?)?.toDouble() ?? 0,
      totalBonuses: (m['total_bonuses'] as num?)?.toDouble() ?? 0,
      gosiEmployee: (m['gosi_employee'] as num?)?.toDouble() ?? 0,
      gosiEmployer: (m['gosi_employer'] as num?)?.toDouble() ?? 0,
      incomeTax: (m['income_tax'] as num?)?.toDouble() ?? 0,
      netSalary: (m['net_salary'] as num?)?.toDouble() ?? 0,
      paidDate: m['paid_date'], paymentMethod: m['payment_method'],
      status: m['status'] ?? 'draft', notes: m['notes'],
      createdAt: m['created_at']);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'payroll_number': payrollNumber,
    'employee_id': employeeId, 'month': month, 'year': year,
    'basic_salary': basicSalary, 'total_allowances': totalAllowances,
    'overtime_amount': overtimeAmount, 'total_deductions': totalDeductions,
    'total_bonuses': totalBonuses, 'gosi_employee': gosiEmployee,
    'gosi_employer': gosiEmployer, 'income_tax': incomeTax,
    'net_salary': netSalary, 'paid_date': paidDate,
    'payment_method': paymentMethod, 'status': status, 'notes': notes,
  };
}

class DashboardStats {
  final double totalSales, totalPurchases, totalExpenses, netProfit;
  final int totalCustomers, totalSuppliers, totalProducts, totalEmployees;
  final int pendingInvoices, lowStockProducts;
  final List<Map<String, dynamic>> monthlySales, monthlyPurchases,
      recentSales, topProducts, salesByCategory;

  const DashboardStats({
    this.totalSales = 0, this.totalPurchases = 0, this.totalExpenses = 0,
    this.netProfit = 0, this.totalCustomers = 0, this.totalSuppliers = 0,
    this.totalProducts = 0, this.totalEmployees = 0, this.pendingInvoices = 0,
    this.lowStockProducts = 0, this.monthlySales = const [],
    this.monthlyPurchases = const [], this.recentSales = const [],
    this.topProducts = const [], this.salesByCategory = const [],
  });
}
