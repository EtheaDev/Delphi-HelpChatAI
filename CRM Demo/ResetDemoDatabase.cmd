@echo off
rem Deletes the database of the CRM demos, so that the next start creates it again
rem with the starting data (the TFDMemTable of common\uDataMod.dfm).
rem
rem The file is w10crmdemo.sdb in the Documents folder of the user, shared by the VCL
rem and the FireMonkey demo (uDataMod.pas, InitializeDatabase). It is never in the
rem repository: what changes while trying the demo stays there.

setlocal
rem The Documents folder as the demo asks for it (TPath.GetDocumentsPath): it may be
rem redirected, to OneDrive for one, so not simply %USERPROFILE%\Documents.
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('MyDocuments')"`) do set "DOCS=%%D"
if not defined DOCS set "DOCS=%USERPROFILE%\Documents"
set "DB=%DOCS%\w10crmdemo.sdb"

rem An open demo holds the file: close it first.
for %%E in (VCL_CRMDemo.exe VCL_CRMDemo_MultiAgent.exe FMX_CRMDemo.exe FMX_CRMDemo_MultiAgent.exe) do (
  tasklist /fi "imagename eq %%E" 2>nul | find /i "%%E" >nul && (
    echo %%E is running: close it, then run this again.
    set "RESULT=1"
    goto :end
  )
)

if not exist "%DB%" (
  echo Nothing to delete: %DB% is not there.
  set "RESULT=0"
  goto :end
)

del /f "%DB%"
if exist "%DB%" (
  echo Could not delete %DB%
  set "RESULT=1"
) else (
  echo Deleted %DB%: the next start of the demo creates it again.
  set "RESULT=0"
)

:end
rem Opened with a double click: keep the window until a key is pressed.
echo %CMDCMDLINE% | find /i "%~nx0" >nul && pause
exit /b %RESULT%
