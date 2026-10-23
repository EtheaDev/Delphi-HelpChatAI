{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       FMX demo application.                                                  }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
program HelpChatAIFmxDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  HelpChatAI.Demo.Fmx.MainForm in '..\source\HelpChatAI.Demo.Fmx.MainForm.pas' {MainForm},
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini;

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'HelpChat FMX Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
