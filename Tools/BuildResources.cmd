@rem ---- Explorer pause: when started by double click the window stays open at the end ----
@if defined EXPLORER_PAUSE_CHILD goto :explorer_pause_skip
@if not "%~1"=="" goto :explorer_pause_skip
@echo %cmdcmdline% | "%SystemRoot%\System32\find.exe" /i "%~nx0" > NUL
@if errorlevel 1 goto :explorer_pause_skip
@echo %cmdcmdline% | "%SystemRoot%\System32\find.exe" /i "call " > NUL
@if not errorlevel 1 goto :explorer_pause_skip
@set EXPLORER_PAUSE_CHILD=1
@"%ComSpec%" /c ""%~f0""
@set EXPLORER_PAUSE_RC=%errorlevel%
@echo.
@pause
@exit /b %EXPLORER_PAUSE_RC%
:explorer_pause_skip
@echo off
rem ---------------------------------------------------------------------------
rem  HelpChatAI - compiles the panel resources (HTML, CSS, JS, htmx) into
rem  source\HelpChatAI.Panel.res, the assistant icons (Images\*.png) into
rem  source\HelpChatAI.Assistant.res and the IDE splash/About icons into
rem  source\HelpChatAI.Splash.res, and the provider icons (Images\providers\*.svg)
rem  into source\HelpChatAI.Providers.res. Run after editing anything under
rem  resources\, or after regenerating the icons with Tools\BuildIcons.cmd.
rem ---------------------------------------------------------------------------
setlocal
set ROOT=%~dp0..
set BRCC=C:\BDS\Studio\37.0\bin\brcc32.exe
if not exist "%BRCC%" (
  echo brcc32.exe not found in %BRCC%
  exit /b 1
)
pushd "%ROOT%\resources"
"%BRCC%" -fo "%ROOT%\source\HelpChatAI.Panel.res" HelpChatAI.Panel.rc
set RC=%errorlevel%
if not "%RC%"=="0" goto :done
"%BRCC%" -fo "%ROOT%\source\HelpChatAI.Assistant.res" HelpChatAI.Assistant.rc
set RC=%errorlevel%
if not "%RC%"=="0" goto :done
"%BRCC%" -fo "%ROOT%\source\HelpChatAI.Splash.res" HelpChatAI.Splash.rc
set RC=%errorlevel%
if not "%RC%"=="0" goto :done
"%BRCC%" -fo "%ROOT%\source\HelpChatAI.Providers.res" HelpChatAI.Providers.rc
set RC=%errorlevel%
:done
popd
if not "%RC%"=="0" exit /b %RC%
echo source\HelpChatAI.Panel.res, HelpChatAI.Assistant.res, HelpChatAI.Splash.res and HelpChatAI.Providers.res updated.
