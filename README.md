# نظام ERP المتكامل v2.0

نظام إدارة موارد المؤسسات متكامل مبني بـ Flutter يدعم Windows / Linux / macOS.

## المميزات

| الوحدة | المحتوى |
|--------|---------|
| **المبيعات** | فواتير، عملاء، دفعات، إرجاع |
| **المشتريات** | فواتير الموردين، دفعات |
| **المخزون** | حركات، تنبيهات مخزون منخفض، تعديلات |
| **المالية** | مصروفات، P&L، تدفق نقدي، حسابات |
| **الموارد البشرية** | موظفون، حضور، إجازات، رواتب |
| **التقارير** | 8 تقارير بتصدير PDF + CSV |
| **الإعدادات** | شركة، مظهر، مستخدمون، نسخ احتياطي |

## تشغيل المشروع

```bash
# 1. تفعيل Windows Desktop
flutter config --enable-windows-desktop

# 2. تحديث الحزم  
flutter pub get

# 3. تشغيل
flutter run -d windows

# 4. بناء release
flutter build windows --release
```

## بناء المثبت

```bash
# بناء portable ZIP
scripts\build_windows.bat

# بناء NSIS installer (يتطلب NSIS)
scripts\build_installer.bat
```

## بيانات الدخول الافتراضية

- **المستخدم:** admin
- **كلمة المرور:** admin123

## المتطلبات

- Flutter 3.22+
- Dart 3.3+
- Windows 10/11 (64-bit)
