@echo off
chcp 65001 > nul
title ERP System - Windows Build
echo.
echo ==========================================
echo   نظام ERP المتكامل - بناء Windows
echo ==========================================
echo.

where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [خطأ] Flutter غير مثبت. قم بتثبيته من https://flutter.dev
    pause
    exit /b 1
)

echo [1/4] تفعيل Windows Desktop...
flutter config --enable-windows-desktop

echo [2/4] تحديث الحزم...
flutter pub get
if %errorlevel% neq 0 ( echo [خطأ] فشل flutter pub get & pause & exit /b 1 )

echo [3/4] بناء نسخة Release...
flutter build windows --release
if %errorlevel% neq 0 ( echo [خطأ] فشل البناء & pause & exit /b 1 )

echo [4/4] إنشاء مجلد التوزيع...
set DIST=dist\ERP_Windows
if exist "%DIST%" rmdir /s /q "%DIST%"
mkdir "%DIST%"
xcopy /E /I /Q "build\windows\x64\runner\Release\*" "%DIST%\"

echo.
echo ==========================================
echo   تم البناء بنجاح!
echo   المجلد: %DIST%
echo ==========================================
echo.

if exist "%DIST%\erp_system.exe" (
    echo هل تريد تشغيل البرنامج الآن؟ [Y/N]
    set /p RUN=
    if /i "%RUN%"=="Y" start "" "%DIST%\erp_system.exe"
)
pause
