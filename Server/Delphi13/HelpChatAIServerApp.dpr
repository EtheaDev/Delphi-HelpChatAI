{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       The HelpChat server: one engine, many clients.                         }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
program HelpChatAIServerApp;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  HelpChatAI.ServerApp in '..\source\HelpChatAI.ServerApp.pas';

var
  LApp: THelpChatServerApp;

begin
  try
    LApp := THelpChatServerApp.Create;
    try
      ExitCode := LApp.Run;
    finally
      LApp.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
