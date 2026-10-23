@echo off
rem ---------------------------------------------------------------------------
rem  HelpChatAI - build everything with Delphi 13 and run the test suite.
rem  Usage: Build_Delphi13.cmd [Win32|Win64] [Debug|Release]
rem  (rsvars.bat clears PLATFORM, hence the HC_ prefixed variables)
rem ---------------------------------------------------------------------------
setlocal
set HC_PLATFORM=%1
if "%HC_PLATFORM%"=="" set HC_PLATFORM=Win32
set HC_CONFIG=%2
if "%HC_CONFIG%"=="" set HC_CONFIG=Debug

set ROOT=%~dp0..
set BDSDIR=C:\BDS\Studio\37.0
if not exist "%BDSDIR%\bin\rsvars.bat" (
  echo Delphi 13 not found in %BDSDIR%
  exit /b 1
)
call "%BDSDIR%\bin\rsvars.bat"

rem  The MarkdownProcessor is a package of Ethea of its own (Ext is an
rem  svn:external): the engine requires it, so it is built first.
echo === MarkdownProcessor (%HC_PLATFORM% Release) ===
msbuild "%ROOT%\Ext\MarkdownProcessor\Packages\D13\MarkdownProcessor.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1

echo === Runtime packages (%HC_PLATFORM% Release) ===
msbuild "%ROOT%\packages\Delphi13\HelpChatAI.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1
msbuild "%ROOT%\packages\Delphi13\HelpChatAIServer.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1
msbuild "%ROOT%\packages\Delphi13\HelpChatAIVcl.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1
msbuild "%ROOT%\packages\Delphi13\HelpChatAIFmx.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1
if "%HC_PLATFORM%"=="Win32" (
  echo === Design-time packages (Win32 Release) ===
  msbuild "%ROOT%\packages\Delphi13\dclHelpChatAIVcl.dproj" /t:Build /p:Config=Release /p:Platform=Win32 /v:m /nologo
  if errorlevel 1 exit /b 1
  msbuild "%ROOT%\packages\Delphi13\dclHelpChatAIFmx.dproj" /t:Build /p:Config=Release /p:Platform=Win32 /v:m /nologo
  if errorlevel 1 exit /b 1
)

echo === Tests (%HC_PLATFORM% %HC_CONFIG%) ===
msbuild "%ROOT%\Test\Delphi13\HelpChatAITests.dproj" /t:Build /p:Config=%HC_CONFIG% /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1

echo === Console demo (%HC_PLATFORM% %HC_CONFIG%) ===
msbuild "%ROOT%\Demos\Projects\HelpChatAIConsoleDemo.dproj" /t:Build /p:Config=%HC_CONFIG% /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1

echo === VCL demo (%HC_PLATFORM% %HC_CONFIG%) ===
msbuild "%ROOT%\Demos\Projects\HelpChatAIVclDemo.dproj" /t:Build /p:Config=%HC_CONFIG% /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1
echo === FMX demo (%HC_PLATFORM% %HC_CONFIG%) ===
msbuild "%ROOT%\Demos\Projects\HelpChatAIFmxDemo.dproj" /t:Build /p:Config=%HC_CONFIG% /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1
if "%HC_PLATFORM%"=="Win64" (set HC_ARCH=x64) else (set HC_ARCH=x86)
copy /Y "%ROOT%\Redist\WebView2\%HC_ARCH%\WebView2Loader.dll" "%ROOT%\Demos\Bin\%HC_PLATFORM%\" >nul

echo === HelpChatAI server (%HC_PLATFORM% Release) ===
msbuild "%ROOT%\Server\Delphi13\HelpChatAIServerApp.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1

echo === HelpIndexBuilder tool (%HC_PLATFORM% Release) ===
msbuild "%ROOT%\Tools\HelpIndexBuilder\HelpIndexBuilder.dproj" /t:Build /p:Config=Release /p:Platform=%HC_PLATFORM% /v:m /nologo
if errorlevel 1 exit /b 1

echo === Running tests ===
"%ROOT%\Test\Bin\%HC_PLATFORM%\HelpChatAITests.exe" --exitbehavior:Continue
exit /b %errorlevel%
