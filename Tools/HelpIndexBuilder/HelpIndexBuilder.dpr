{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       HelpIndexBuilder: builds the documentation index (JSON) from a folder   }
{       of Markdown pages. No Python, no dependencies: plain Delphi.           }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
program HelpIndexBuilder;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  HelpChatAI.Types in '..\..\source\HelpChatAI.Types.pas',
  HelpChatAI.IndexBuilder in '..\..\source\HelpChatAI.IndexBuilder.pas';

procedure PrintUsage;
begin
  Writeln('HelpIndexBuilder ', HELPCHAT_VERSION, ' - builds the HelpChat documentation index from Markdown');
  Writeln;
  Writeln('Usage: HelpIndexBuilder --source=<folder> --out=<file.json> [options]');
  Writeln('  --source=<folder>    folder with the Markdown pages (required)');
  Writeln('  --out=<file>         output JSON (default: help-index.json in the source folder)');
  Writeln('  --toc=<file>         table of contents, relative to source (default: ', HELPCHAT_INDEXBUILDER_DEF_TOCFILE, ')');
  Writeln('                       gives titles and breadcrumb keywords; use --toc= to disable');
  Writeln('  --url-ext=<ext>      extension of the published pages (default: ', HELPCHAT_INDEXBUILDER_DEF_URLEXT, '; --url-ext= keeps .md)');
  Writeln('  --url-prefix=<text>  prepended to every relative URL (e.g. manual/)');
  Writeln('  --max-text=<n>       characters of text kept per page for scoring (default: ', HELPCHAT_INDEXBUILDER_DEF_MAXTEXT, ')');
  Writeln('  --summary=<n>        maximum summary length (default: ', HELPCHAT_INDEXBUILDER_DEF_SUMMARYMAX, ')');
  Writeln('  --no-recursive       top folder only');
  Writeln('  --quiet              print warnings only');
end;

function ArgValue(const AName: string; out AValue: string): Boolean;
var
  I: Integer;
  LArg: string;
begin
  Result := False;
  AValue := '';
  for I := 1 to ParamCount do
  begin
    LArg := ParamStr(I);
    if SameText(LArg, '--' + AName) then
      Exit(True);
    if LArg.StartsWith('--' + AName + '=', True) then
    begin
      AValue := LArg.Substring(AName.Length + 3);
      Exit(True);
    end;
  end;
end;

var
  LOptions: THelpChatIndexBuilderOptions;
  LBuilder: THelpChatIndexBuilder;
  LValue, LOut, LWarning: string;
  LCount: Integer;
  LQuiet: Boolean;
begin
  try
    if (ParamCount = 0) or ArgValue('help', LValue) or ArgValue('?', LValue) then
    begin
      PrintUsage;
      Exit;
    end;
    LOptions := THelpChatIndexBuilderOptions.Default;
    if not (ArgValue('source', LOptions.SourceFolder) and (LOptions.SourceFolder <> '')) then
    begin
      Writeln('Missing --source=<folder>');
      ExitCode := 2;
      Exit;
    end;
    if not (ArgValue('out', LOut) and (LOut <> '')) then
      LOut := TPath.Combine(LOptions.SourceFolder, 'help-index.json');
    if ArgValue('toc', LValue) then
      LOptions.TocFile := LValue;
    if ArgValue('url-ext', LValue) then
      LOptions.UrlExtension := LValue;
    if ArgValue('url-prefix', LValue) then
      LOptions.UrlPrefix := LValue;
    if ArgValue('max-text', LValue) and (LValue <> '') then
      LOptions.MaxTextLength := StrToIntDef(LValue, LOptions.MaxTextLength);
    if ArgValue('summary', LValue) and (LValue <> '') then
      LOptions.SummaryMaxLength := StrToIntDef(LValue, LOptions.SummaryMaxLength);
    if ArgValue('no-recursive', LValue) then
      LOptions.Recursive := False;
    LQuiet := ArgValue('quiet', LValue);

    LBuilder := THelpChatIndexBuilder.Create;
    try
      LCount := LBuilder.BuildToFile(LOptions, LOut);
      for LWarning in LBuilder.Warnings do
        Writeln('warning: ', LWarning);
      if not LQuiet then
        Writeln(Format('%d pages indexed from %s -> %s', [LCount, TPath.GetFullPath(LOptions.SourceFolder), TPath.GetFullPath(LOut)]));
    finally
      LBuilder.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
