{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       VCL demo: a small "application" with two screens whose HelpKeyword     }
{       points to pages of the LendingReport manual (Test\Help).               }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Demo.Vcl.MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  HelpChatAI.Types, HelpChatAI.Settings, HelpChatAI.Actions, Vcl.HelpChatAI;

type
  TMainForm = class(TForm)
    TopPanel: TPanel;
    TitleLabel: TLabel;
    OpenChatButton: TButton;
    AskScreenButton: TButton;
    ProviderCombo: TComboBox;
    ProviderLabel: TLabel;
    StyleLabel: TLabel;
    StyleCombo: TComboBox;
    PageControl: TPageControl;
    SchedulerSheet: TTabSheet;
    SchedulerMemo: TMemo;
    MailSheet: TTabSheet;
    MailMemo: TMemo;
    StatusBar: TStatusBar;
    HelpChat: TVclHelpChatAI;
    EmbeddedCheck: TCheckBox;
    NewReportSheet: TTabSheet;
    ReportNameLabel: TLabel;
    ReportDescLabel: TLabel;
    ReportMailLabel: TLabel;
    ReportFormatLabel: TLabel;
    ActionsHintLabel: TLabel;
    ReportNameEdit: TEdit;
    ReportDescEdit: TEdit;
    ReportMailEdit: TEdit;
    ReportFormatCombo: TComboBox;
    CreateReportButton: TButton;
    ChatPanel: TPanel;
    ChatSplitter: TSplitter;
    ChatHeaderPanel: TPanel;
    ChatHeaderLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure OpenChatButtonClick(Sender: TObject);
    procedure AskScreenButtonClick(Sender: TObject);
    procedure ProviderComboChange(Sender: TObject);
    procedure StyleComboChange(Sender: TObject);
    procedure HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
    procedure HelpChatBeforeShowHelp(Sender: TObject; var AContainer: TWinControl);
    procedure HelpChatAfterShowHelp(Sender: TObject);
    procedure HelpChatBeforeHideHelp(Sender: TObject);
    procedure EmbeddedCheckClick(Sender: TObject);
    procedure CreateReportButtonClick(Sender: TObject);
    procedure HelpChatActionExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
  private
    function RepositoryRoot: string;
    procedure UpdateStatus;
    /// <summary>What this application lets the assistant do. Only what is
    /// registered here exists for the model, with the parameters declared.</summary>
    procedure RegisterActions;
    function FindSheet(const AName: string): TTabSheet;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  Vcl.Themes,
  HelpChatAI.Provider;

function TMainForm.RepositoryRoot: string;
begin
  // Demos\Bin\<Platform>\ -> repository root
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..'));
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LName: string;
begin
  // The demo indexes the real Italian manual under Test\Help. Your own
  // application would ship help-index.json next to the executable, or set
  // Settings.DocIndexFile from its configuration.
  // The form already carries that path, relative to the executable, so the
  // design-time check of the component editor finds it too; this only steps
  // in when the demo is run from somewhere else, where that path leads
  // nowhere and the repository has to be looked up.
  if not TFile.Exists(HelpChat.Settings.ResolveDocIndexFile) then
    HelpChat.Settings.DocIndexFile := TPath.Combine(RepositoryRoot, 'Test\Help\help-index.json');
  // helpchatai.json next to the exe and %APPDATA%\HelpChatAIVclDemo\helpchatai.json are
  // merged on activation: that is where the Claude API key goes. Naming one
  // in ConfigFileName would make that file the only one read.
  HelpChat.Active := True;

  for LName in THelpChatProviderRegistry.ProviderNames do
    ProviderCombo.Items.Add(LName);
  ProviderCombo.ItemIndex := ProviderCombo.Items.IndexOf(HelpChat.Settings.Provider);

  // Every VCL style linked into the project (Project Options > Appearance); the
  // chat panel follows the choice at once (FollowVclStyle).
  for LName in TStyleManager.StyleNames do
    StyleCombo.Items.Add(LName);
  StyleCombo.ItemIndex := StyleCombo.Items.IndexOf(TStyleManager.ActiveStyle.Name);
  ReportFormatCombo.ItemIndex := 0;
  RegisterActions;
  UpdateStatus;
end;

function TMainForm.FindSheet(const AName: string): TTabSheet;
var
  I: Integer;
begin
  // The assistant names a screen the way a user would: match the caption, the
  // help keyword or the component name, then try a partial match.
  for I := 0 to PageControl.PageCount - 1 do
    if SameText(PageControl.Pages[I].Caption, AName) or
       SameText(PageControl.Pages[I].HelpKeyword, AName) or
       SameText(PageControl.Pages[I].Name, AName) then
      Exit(PageControl.Pages[I]);
  for I := 0 to PageControl.PageCount - 1 do
    // TCaption is a distinct type: it needs the cast to get the string helper.
    if string(PageControl.Pages[I].Caption).ToLower.Contains(AName.ToLower) then
      Exit(PageControl.Pages[I]);
  Result := nil;
end;

procedure TMainForm.RegisterActions;
begin
  Self.HelpChat.Actions.Add('apri_schermata',
    'Apre una schermata dell''applicazione e la porta in primo piano.',
    [THelpChatActionParam.Create('nome',
      'Nome della schermata: "Scheduler dei Report", "Server di posta" o "Nuovo report".')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LSheet: TTabSheet;
    begin
      LSheet := FindSheet(AArgs.AsString('nome'));
      if LSheet = nil then
        raise Exception.CreateFmt('Non esiste una schermata "%s".', [AArgs.AsString('nome')]);
      PageControl.ActivePage := LSheet;
      AResult := 'Aperta la schermata ' + LSheet.Caption;
    end);

  // Confirm: it writes into the form the user is looking at, so it asks first.
  Self.HelpChat.Actions.Add('compila_report',
    'Compila il modulo di un nuovo report nella schermata "Nuovo report". ' +
    'Non crea il report: lo prepara perche'' l''utente lo controlli.',
    [THelpChatActionParam.Create('nome', 'Nome del report'),
     THelpChatActionParam.Create('descrizione', 'Descrizione del report', apkString, False),
     THelpChatActionParam.Create('email', 'Indirizzo del destinatario', apkString, False),
     THelpChatActionParam.Create('formato', 'PDF, Excel oppure CSV', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LFormat: Integer;
    begin
      PageControl.ActivePage := NewReportSheet;
      ReportNameEdit.Text := AArgs.AsString('nome');
      if AArgs.Has('descrizione') then
        ReportDescEdit.Text := AArgs.AsString('descrizione');
      if AArgs.Has('email') then
        ReportMailEdit.Text := AArgs.AsString('email');
      if AArgs.Has('formato') then
      begin
        LFormat := ReportFormatCombo.Items.IndexOf(AArgs.AsString('formato'));
        if LFormat >= 0 then
          ReportFormatCombo.ItemIndex := LFormat;
      end;
      AResult := 'Modulo compilato: controlla i campi e premi "Crea report".';
    end, True);
end;

procedure TMainForm.CreateReportButtonClick(Sender: TObject);
begin
  if Trim(ReportNameEdit.Text) = '' then
  begin
    ShowMessage('Manca il nome del report.');
    Exit;
  end;
  ShowMessage(Format('Report "%s" creato in formato %s.',
    [ReportNameEdit.Text, ReportFormatCombo.Text]));
end;

procedure TMainForm.HelpChatActionExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
const
  COutcome: array[THelpChatActionOutcome] of string =
    ('eseguita', 'negata', 'sconosciuta', 'fallita', 'scaduta', 'annullata');
begin
  StatusBar.Panels[3].Text := Format('Azione %s: %s', [AName, COutcome[AOutcome]]);
end;

procedure TMainForm.StyleComboChange(Sender: TObject);
begin
  if (StyleCombo.ItemIndex >= 0) and (StyleCombo.Text <> TStyleManager.ActiveStyle.Name) then
    TStyleManager.TrySetStyle(StyleCombo.Text);
end;

procedure TMainForm.UpdateStatus;
begin
  // With Settings.Remote configured the engine of this process is idle: index,
  // model and key are all on the server.
  if HelpChat.Settings.Remote.IsConfigured then
    StatusBar.Panels[0].Text := 'Engine: ' + HelpChat.Settings.Remote.NormalizedBaseUrl
  else if Assigned(HelpChat.Engine) and Assigned(HelpChat.Engine.DocIndex) and
     HelpChat.Engine.DocIndex.IsAvailable then
    StatusBar.Panels[0].Text := Format('Index: %d pages', [HelpChat.Engine.DocIndex.Count])
  else
    StatusBar.Panels[0].Text := 'Index: not found - ' + HelpChat.Settings.ResolveDocIndexFile;
  StatusBar.Panels[1].Text := 'Provider: ' + HelpChat.Settings.Provider;
  if Assigned(HelpChat.Transport) and HelpChat.Transport.IsActive then
    StatusBar.Panels[2].Text := HelpChat.Transport.GetPanelOrigin
  else
    StatusBar.Panels[2].Text := 'server not running';
end;

procedure TMainForm.OpenChatButtonClick(Sender: TObject);
begin
  HelpChat.Open;
end;

procedure TMainForm.AskScreenButtonClick(Sender: TObject);
begin
  // The standard VCL way, exactly what F1 does on the active tab: the help
  // system routes the keyword to the registered viewer, i.e. the chat.
  if Assigned(PageControl.ActivePage) and (PageControl.ActivePage.HelpKeyword <> '') then
    Application.HelpKeyword(PageControl.ActivePage.HelpKeyword)
  else
    HelpChat.OpenForCurrentScreen;
end;

procedure TMainForm.ProviderComboChange(Sender: TObject);
begin
  // Settings changes apply to the next message: no restart needed.
  HelpChat.Settings.Provider := ProviderCombo.Text;
  UpdateStatus;
end;

procedure TMainForm.HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
begin
  // The component built the context from the active form, tab and control;
  // an application can refine it here. This demo just shows it in the status bar.
  StatusBar.Panels[2].Text := Format('Context: %s', [AContext.DisplayName]);
end;

procedure TMainForm.HelpChatBeforeShowHelp(Sender: TObject; var AContainer: TWinControl);
begin
  // Where the chat goes: by default (AContainer = nil) in the component's own
  // tool window; with "Help embedded" in the side panel of this form, which
  // the application shows here. The chat is a control (TVclHelpChatAIPanel):
  // it fills whatever container it is given.
  if EmbeddedCheck.Checked then
  begin
    ChatPanel.Visible := True;
    ChatSplitter.Visible := True;
    ChatSplitter.Left := ChatPanel.Left - 1; // keep the splitter on the left edge of the panel
    AContainer := ChatPanel;
  end;
end;

procedure TMainForm.HelpChatAfterShowHelp(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TMainForm.HelpChatBeforeHideHelp(Sender: TObject);
begin
  // The user closed the chat (its X button, Esc or the tool window): the
  // application hides its own container. The own window hides by itself.
  ChatPanel.Visible := False;
  ChatSplitter.Visible := False;
end;

procedure TMainForm.EmbeddedCheckClick(Sender: TObject);
var
  LWasVisible: Boolean;
begin
  // Move an open chat to the new place at once.
  LWasVisible := HelpChat.IsPanelVisible;
  if LWasVisible then
    HelpChat.Close;
  if LWasVisible then
    HelpChat.Open;
end;

end.
