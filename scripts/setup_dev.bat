@echo off
chcp 65001 > nul
title ERP System - Dev Setup
echo.
echo ==========================================
echo   إعداد بيئة التطوير
echo ==========================================
echo.

echo [1] تفعيل Windows Desktop...
flutter config --enable-windows-desktop

echo [2] تحديث الحزم...
flutter pub get

echo [3] تشغيل الفحص...
flutter analyze --no-fatal-infos

echo [4] تشغيل التطبيق في وضع debug...
flutter run -d windows
