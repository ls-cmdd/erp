@echo off
chcp 65001 > nul
title ERP System - NSIS Installer Build
echo.
echo ==========================================
echo   بناء مثبت NSIS
echo ==========================================
echo.

where makensis >nul 2>&1
if %errorlevel% neq 0 (
    echo [خطأ] NSIS غير مثبت. قم بتثبيته من https://nsis.sourceforge.io
    echo أو عبر: choco install nsis
    pause
    exit /b 1
)

echo بناء التطبيق أولاً...
call scripts\build_windows.bat

echo.
echo بناء المثبت...
for /f "tokens=2 delims=: " %%v in ('findstr "version:" pubspec.yaml') do (
    for /f "tokens=1 delims=+" %%a in ("%%v") do set VERSION=%%a
)

set NSI_TEMP=installers\installer_temp.nsi
copy installers\installer.nsi "%NSI_TEMP%" > nul
powershell -Command "(gc '%NSI_TEMP%') -replace 'APP_VERSION_PLACEHOLDER', '%VERSION%' | Set-Content '%NSI_TEMP%'"
makensis "%NSI_TEMP%"
del "%NSI_TEMP%" > nul

if exist "installers\ERP_Setup.exe" (
    if not exist dist mkdir dist
    move "installers\ERP_Setup.exe" "dist\ERP_Setup_v%VERSION%_Windows.exe"
    echo.
    echo [نجح] المثبت: dist\ERP_Setup_v%VERSION%_Windows.exe
) else (
    echo [خطأ] فشل إنشاء المثبت
)
pause
