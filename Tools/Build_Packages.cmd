@echo off
rem ---------------------------------------------------------------------------
rem  HelpChatAI - build the packages of one Delphi version from the command line.
rem  Usage: Build_Packages.cmd [Delphi13|Delphi12|Delphi11|Delphi10.4]
rem         Build_Packages.cmd all
rem
rem  Runtime packages are built for Win32 and Win64, the design-time ones for
rem  Win32 only (the IDE loads 32-bit design packages). FMX exists from 12 on.
rem ---------------------------------------------------------------------------
setlocal
set HC_ROOT=%~dp0..

if /I "%~1"=="all" (
  call "%~f0" Delphi10.4 || exit /b 1
  call "%~f0" Delphi11   || exit /b 1
  call "%~f0" Delphi12   || exit /b 1
  call "%~f0" Delphi13   || exit /b 1
  exit /b 0
)

set HC_VER=%~1
if "%HC_VER%"=="" set HC_VER=Delphi13
if /I "%HC_VER%"=="Delphi10.4" set HC_BDS=21.0
if /I "%HC_VER%"=="Delphi11"   set HC_BDS=22.0
if /I "%HC_VER%"=="Delphi12"   set HC_BDS=23.0
if /I "%HC_VER%"=="Delphi13"   set HC_BDS=37.0
rem  The folders of the MarkdownProcessor (Ext, an svn:external) are named
rem  the way that project names them, not the way this one does.
if /I "%HC_VER%"=="Delphi10.4" set HC_MDP=D10.4
if /I "%HC_VER%"=="Delphi11"   set HC_MDP=D11
if /I "%HC_VER%"=="Delphi12"   set HC_MDP=D12
if /I "%HC_VER%"=="Delphi13"   set HC_MDP=D13
if "%HC_BDS%"=="" (
  echo Unknown version "%HC_VER%". Use Delphi10.4, Delphi11, Delphi12, Delphi13 or all.
  exit /b 1
)
if not exist "C:\BDS\Studio\%HC_BDS%\bin\rsvars.bat" (
  echo %HC_VER% ^(BDS %HC_BDS%^) is not installed here: skipped.
  exit /b 0
)
call "C:\BDS\Studio\%HC_BDS%\bin\rsvars.bat"

rem The panel page is a resource the library needs to compile.
if not exist "%HC_ROOT%\source\HelpChatAI.Panel.res" call "%~dp0BuildResources.cmd"

rem  Win64 needs the DCP folder of its own platform spelled out: the library
rem  path of an IDE can list ...\Dcp before ...\Dcp\Win64, and the compiler
rem  then picks the 32-bit HelpChatAI.dcp and stops on "Bad packaged unit format".
rem  The engine requires the MarkdownProcessor package: it comes first.
echo === %HC_VER% MarkdownProcessor (Win32 and Win64) ===
msbuild "%HC_ROOT%\Ext\MarkdownProcessor\Packages\%HC_MDP%\MarkdownProcessor.dproj" /t:Build /p:Config=Release /p:Platform=Win32 /v:m /nologo
if errorlevel 1 exit /b 1
msbuild "%HC_ROOT%\Ext\MarkdownProcessor\Packages\%HC_MDP%\MarkdownProcessor.dproj" /t:Build /p:Config=Release /p:Platform=Win64 /v:m /nologo
if errorlevel 1 exit /b 1

echo === %HC_VER% runtime packages (Win32 and Win64) ===
for %%P in (HelpChatAI HelpChatAIServer HelpChatAIVcl HelpChatAIFmx) do (
  if exist "%HC_ROOT%\packages\%HC_VER%\%%P.dproj" (
    msbuild "%HC_ROOT%\packages\%HC_VER%\%%P.dproj" /t:Build /p:Config=Release /p:Platform=Win32 /v:m /nologo
    if errorlevel 1 exit /b 1
    msbuild "%HC_ROOT%\packages\%HC_VER%\%%P.dproj" /t:Build /p:Config=Release /p:Platform=Win64 /v:m /nologo /p:DCC_UnitSearchPath="%BDSCOMMONDIR%\Dcp\Win64"
    if errorlevel 1 exit /b 1
  )
)

echo === %HC_VER% design-time packages (Win32) ===
for %%P in (dclHelpChatAIVcl dclHelpChatAIFmx) do (
  if exist "%HC_ROOT%\packages\%HC_VER%\%%P.dproj" (
    msbuild "%HC_ROOT%\packages\%HC_VER%\%%P.dproj" /t:Build /p:Config=Release /p:Platform=Win32 /v:m /nologo
    if errorlevel 1 exit /b 1
  )
)

echo === %HC_VER%: done ===
exit /b 0
