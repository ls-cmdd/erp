; ─── NSIS Installer Script for ERP System ────────────────────────────────────
Unicode true
!define APP_NAME        "نظام ERP المتكامل"
!define APP_NAME_EN     "ERP System"
!define APP_VERSION     "APP_VERSION_PLACEHOLDER"
!define APP_EXE         "erp_system.exe"
!define PUBLISHER       "ERP Solutions"
!define INSTALL_DIR     "$PROGRAMFILES64\ERP System"
!define REG_KEY         "Software\Microsoft\Windows\CurrentVersion\Uninstall\ERPSystem"
!define MUI_ICON        "..\windows\runner\resources\app_icon.ico"

!include "MUI2.nsh"
!include "x64.nsh"

Name "${APP_NAME}"
OutFile "ERP_Setup.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKLM "${REG_KEY}" "InstallLocation"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

; ─── Pages ───────────────────────────────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "Arabic"
!insertmacro MUI_LANGUAGE "English"

; ─── Install ─────────────────────────────────────────────────────────────────
Section "Install"
  SetOutPath "$INSTDIR"
  
  ; Copy all build files
  File /r "..\build\windows\x64\runner\Release\*"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Registry entries (Add/Remove Programs)
  WriteRegStr   HKLM "${REG_KEY}" "DisplayName"     "${APP_NAME}"
  WriteRegStr   HKLM "${REG_KEY}" "DisplayVersion"   "${APP_VERSION}"
  WriteRegStr   HKLM "${REG_KEY}" "Publisher"        "${PUBLISHER}"
  WriteRegStr   HKLM "${REG_KEY}" "InstallLocation"  "$INSTDIR"
  WriteRegStr   HKLM "${REG_KEY}" "UninstallString"  '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKLM "${REG_KEY}" "NoModify"        1
  WriteRegDWORD HKLM "${REG_KEY}" "NoRepair"        1
  WriteRegStr   HKLM "${REG_KEY}" "DisplayIcon"     "$INSTDIR\${APP_EXE}"
  
  ; Desktop shortcut
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
  
  ; Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\${APP_NAME_EN}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME_EN}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME_EN}\Uninstall.lnk"    "$INSTDIR\Uninstall.exe"
SectionEnd

; ─── Uninstall ────────────────────────────────────────────────────────────────
Section "Uninstall"
  RMDir /r "$INSTDIR"
  Delete "$DESKTOP\${APP_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APP_NAME_EN}"
  DeleteRegKey HKLM "${REG_KEY}"
SectionEnd
