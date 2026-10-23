@echo off
rem ---------------------------------------------------------------------------
rem  HelpChatAI - compiles the panel resources (HTML, CSS, JS, htmx) into
rem  source\HelpChatAI.Panel.res, the assistant icons (Images\*.png) into
rem  source\HelpChatAI.Assistant.res and the IDE splash/About icons into
rem  source\HelpChatAI.Splash.res. Run after editing anything under
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
:done
popd
if not "%RC%"=="0" exit /b %RC%
echo source\HelpChatAI.Panel.res, HelpChatAI.Assistant.res and HelpChatAI.Splash.res updated.
