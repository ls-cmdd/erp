@echo off
chcp 65001 > nul
title ERP System - Full Build
echo.
echo ==========================================
echo   بناء كامل لنظام ERP
echo ==========================================
echo.
echo [1] بناء Windows Portable
call scripts\build_windows.bat

echo [2] بناء Windows Installer
call scripts\build_installer.bat

echo.
echo ==========================================
echo   اكتمل البناء
echo ==========================================
dir dist\
pause
