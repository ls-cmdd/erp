class AppConstants {
  static const String appName     = 'نظام ERP المتكامل';
  static const String appVersion  = '2.0.0';
  static const String dbName      = 'erp_v2.db';
  static const int    dbVersion   = 2;

  static const String defaultCurrency     = 'ريال';
  static const String defaultCurrencyCode = 'SAR';
  static const int    defaultTaxRate      = 15;
  static const String defaultLanguage     = 'ar';

  static const String pfxSale      = 'INV';
  static const String pfxPurchase  = 'PUR';
  static const String pfxExpense   = 'EXP';
  static const String pfxPayment   = 'PAY';
  static const String pfxPayroll   = 'SAL';
  static const String pfxQuote     = 'QUO';

  static const List<String> paymentMethods = [
    'نقدي', 'بطاقة ائتمان', 'تحويل بنكي', 'شيك', 'آجل',
  ];

  static const String statusPending   = 'pending';
  static const String statusPaid      = 'paid';
  static const String statusPartial   = 'partial';
  static const String statusCancelled = 'cancelled';
  static const String statusOverdue   = 'overdue';
  static const String statusDraft     = 'draft';
  static const String statusApproved  = 'approved';

  static const List<String> leaveTypes = [
    'سنوية', 'مرضية', 'طارئة', 'بدون راتب', 'أمومة', 'أبوة',
  ];

  static const List<String> expenseCategories = [
    'إيجار', 'رواتب', 'مرافق', 'تسويق وإعلان',
    'صيانة', 'سفر وانتقالات', 'لوازم مكتبية',
    'اتصالات', 'تأمين', 'أخرى',
  ];

  static const List<String> departments = [
    'الإدارة', 'المبيعات', 'المشتريات', 'المخازن',
    'المحاسبة', 'الموارد البشرية', 'تقنية المعلومات',
    'التسويق', 'خدمة العملاء', 'الإنتاج',
  ];

  // Luxe gradient seeds
  static const List<List<int>> gradients = [
    [0xFF1565C0, 0xFF0D47A1],
    [0xFF00897B, 0xFF00695C],
    [0xFFAD1457, 0xFF880E4F],
    [0xFF6A1B9A, 0xFF4A148C],
    [0xFFE65100, 0xFFBF360C],
    [0xFF37474F, 0xFF263238],
  ];
}
