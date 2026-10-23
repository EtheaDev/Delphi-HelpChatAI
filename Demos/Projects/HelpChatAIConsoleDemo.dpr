{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Console demo: try the engine and its providers without any UI.         }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
program HelpChatAIConsoleDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  HelpChatAI.Demo.Console in '..\source\HelpChatAI.Demo.Console.pas';

begin
  try
    ExitCode := RunConsoleDemo;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
