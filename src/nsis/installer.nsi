; Install the application without requiring any admin-privileges
; http://www.klopfenstein.net/lorenz.aspx/simple-nsis-installer-with-user-execution-level

; INCLUDES
!include MUI2.nsh
!include LogicLib.nsh
!include includes/StrRep.nsh
!include includes/ReplaceInFile.nsh

; INIT
!define APP_NAME "Lightroom integration"
Name "${APP_NAME}"
OutFile "${BASEDIR}/target/${OUT_FILE}"
RequestExecutionLevel user

!define SCRIPT "${BASEDIR}/src/main/resources"

!define SCRIPT_DIR "$APPDATA\Adobe\Lightroom\Modules"

!define IMPORT_PLUGIN_NAME "NetlifeImport"
!define EXPORT_PLUGIN_NAME "NetlifeExport"
!define IMPORT_SCRIPT_DIR "${SCRIPT_DIR}\${IMPORT_PLUGIN_NAME}.lrplugin"
!define EXPORT_SCRIPT_DIR "${SCRIPT_DIR}\${EXPORT_PLUGIN_NAME}.lrplugin"

; PAGES
var /GLOBAL RLInstDir 
!define MUI_ICON "icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "logo.bmp"
!define MUI_PAGE_HEADER_SUBTEXT "Choose the folder in where Retouch Link puts the jobs."
!define MUI_DIRECTORYPAGE_TEXT_TOP "The installer will set the 'input' parameter in the config files  to the following folder. To select a different folder, click Browse and select another folder. Click Next to continue."
!define MUI_DIRECTORYPAGE_VARIABLE $RLInstDir
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

; REFS
!define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
!define UNINSTALLER_NAME "${APP_NAME}-Uninstall.exe"

; Functions & macros
Function RegisterApplication

    ; Register uninstaller into Add/Remove panel (for local user only)
    WriteRegStr HKCU "${REG_UNINSTALL}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKCU "${REG_UNINSTALL}" "Publisher" "Netlife as"
    WriteRegStr HKCU "${REG_UNINSTALL}" "InstallLocation" "$\"${SCRIPT_DIR}$\""
    WriteRegStr HKCU "${REG_UNINSTALL}" "InstallSource" "$\"$EXEDIR$\""
    WriteRegDWord HKCU "${REG_UNINSTALL}" "NoModify" 1
    WriteRegDWord HKCU "${REG_UNINSTALL}" "NoRepair" 1
    WriteRegStr HKCU "${REG_UNINSTALL}" "UninstallString" "$\"${SCRIPT_DIR}\${UNINSTALLER_NAME}$\""
    WriteRegStr HKCU "${REG_UNINSTALL}" "Comments" "Uninstalls ${APP_NAME}."

FunctionEnd

Function un.DeregisterApplication
    ; Deregister uninstaller from Add/Remove panel
    DeleteRegKey HKCU "${REG_UNINSTALL}"
FunctionEnd

Function UninstallPreviousVersion

    ; Currently installed?
    ReadRegStr $R0 HKCU "${REG_UNINSTALL}" "InstallLocation"
    ${If} $R0 == ""        
        Goto Done
    ${EndIf}

    ; Uninstall silently
    DetailPrint "Removing current installation."
    ExecWait '"${SCRIPT_DIR}\${UNINSTALLER_NAME}" /S _?=${SCRIPT_DIR}'
    DetailPrint "Done..."

    Done:
FunctionEnd

; Macro for copying over lightroom-script files & tweaking some config
!macro InstallLightroomScript Src Dest RLFolder
    SetOutPath "${Dest}"
    File /r ${SCRIPT}/${Src}/*
    File ${SCRIPT}/Config.lua
    !insertmacro ReplaceInFile "${Dest}\info.lua" "123456789" "${VERSION}"
    ExpandEnvStrings $0 "%USERNAME%"
    !insertmacro ReplaceInFile "${Dest}\Config.lua" "USERID" "$0"
	!insertmacro ReplaceInFile "${Dest}\Config.lua" "JOB_SOURCE_FOLDER" "${RLFolder}"
!macroend


; INSTALLER
Section
    Call UninstallPreviousVersion
    
    ; Don't overwrite files at all, 'transient' stuff should be removed by the uninstaller
    SetOverwrite off

    ;*********************
    ; Lightroom-scripts
    ;*********************
	DetailPrint "Retouch Link job folder $RLInstDir"
    !insertmacro InstallLightroomScript "import" "${IMPORT_SCRIPT_DIR}" $RLInstDir
    !insertmacro InstallLightroomScript "export" "${EXPORT_SCRIPT_DIR}" $RLInstDir

    ;*********************
    ; Register the app
    ;*********************
    WriteUninstaller "${SCRIPT_DIR}\${UNINSTALLER_NAME}"
    Call RegisterApplication 
SectionEnd


; UNINSTALLER
section "Uninstall"

    ; Remove the lightroom-scripts
    RMDir /r "${IMPORT_SCRIPT_DIR}"
    RMDir /r "${EXPORT_SCRIPT_DIR}"

    ; Delete the actual uninstaller
    Delete "${SCRIPT_DIR}\${UNINSTALLER_NAME}"

    ; Remove shortcuts etc
    Call un.DeregisterApplication
SectionEnd

