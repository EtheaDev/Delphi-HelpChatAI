{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       FMX demo: a small "application" with two screens whose HelpKeyword     }
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
unit HelpChatAI.Demo.Fmx.MainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.TabControl, FMX.Memo, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Controls.Presentation,
  HelpChatAI.Types, HelpChatAI.Settings, FMX.HelpChatAI;

type
  TMainForm = class(TForm)
    TopLayout: TLayout;
    TitleLabel: TLabel;
    ProviderLabel: TLabel;
    ProviderCombo: TComboBox;
    ThemeLabel: TLabel;
    ThemeCombo: TComboBox;
    EmbeddedCheck: TCheckBox;
    OpenChatButton: TButton;
    AskScreenButton: TButton;
    StatusLabel: TLabel;
    ChatPanel: TPanel;
    ChatHeaderLabel: TLabel;
    ChatSplitter: TSplitter;
    TabControl: TTabControl;
    SchedulerTab: TTabItem;
    SchedulerMemo: TMemo;
    MailTab: TTabItem;
    MailMemo: TMemo;
    HelpChat: TFmxHelpChatAI;
    procedure FormCreate(Sender: TObject);
    procedure OpenChatButtonClick(Sender: TObject);
    procedure AskScreenButtonClick(Sender: TObject);
    procedure ProviderComboChange(Sender: TObject);
    procedure ThemeComboChange(Sender: TObject);
    procedure EmbeddedCheckChange(Sender: TObject);
    procedure HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
    procedure HelpChatBeforeShowHelp(Sender: TObject; var AContainer: TFmxObject);
    procedure HelpChatAfterShowHelp(Sender: TObject);
    procedure HelpChatBeforeHideHelp(Sender: TObject);
  private
    FLastContext: string;
    function RepositoryRoot: string;
    procedure UpdateStatus;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.IOUtils,
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
  HelpChat.Settings.DocIndexFile := TPath.Combine(RepositoryRoot, 'Test\Help\help-index.json');
  HelpChat.Settings.DocBaseUrl := 'https://help.ethea.it/lendingreport/';
  // helpchatai.json next to the exe and %APPDATA%\HelpChatAIFmxDemo\helpchatai.json are
  // merged on activation: that is where the Claude API key goes. Naming one
  // in ConfigFileName would make that file the only one read.
  HelpChat.Active := True;

  for LName in THelpChatProviderRegistry.ProviderNames do
    ProviderCombo.Items.Add(LName);
  ProviderCombo.ItemIndex := ProviderCombo.Items.IndexOf(HelpChat.Settings.Provider);
  ThemeCombo.ItemIndex := Ord(HelpChat.ThemeMode);
  UpdateStatus;
end;

procedure TMainForm.UpdateStatus;
var
  LIndex, LServer: string;
begin
  // With Settings.Remote configured the engine of this process is idle: index,
  // model and key are all on the server.
  if HelpChat.Settings.Remote.IsConfigured then
    LIndex := 'Engine: ' + HelpChat.Settings.Remote.NormalizedBaseUrl
  else if Assigned(HelpChat.Engine) and Assigned(HelpChat.Engine.DocIndex) and
     HelpChat.Engine.DocIndex.IsAvailable then
    LIndex := Format('Index: %d pages', [HelpChat.Engine.DocIndex.Count])
  else
    LIndex := 'Index: not found - ' + HelpChat.Settings.ResolveDocIndexFile;
  if Assigned(HelpChat.Transport) and HelpChat.Transport.IsActive then
    LServer := HelpChat.Transport.GetPanelOrigin
  else
    LServer := 'server not running';
  StatusLabel.Text := Format('%s   |   Provider: %s   |   %s   |   %s',
    [LIndex, HelpChat.Settings.Provider, LServer, FLastContext]);
end;

procedure TMainForm.OpenChatButtonClick(Sender: TObject);
begin
  HelpChat.Open;
end;

procedure TMainForm.AskScreenButtonClick(Sender: TObject);
begin
  // What F1 does on the active tab: FMX has no Application.HelpKeyword, the
  // component is asked directly with the keyword of the screen.
  if Assigned(TabControl.ActiveTab) and (TabControl.ActiveTab.HelpKeyword <> '') then
    HelpChat.OpenForHelp(TabControl.ActiveTab.HelpKeyword, 0)
  else
    HelpChat.OpenForCurrentScreen;
end;

procedure TMainForm.ProviderComboChange(Sender: TObject);
begin
  // Settings changes apply to the next message: no restart needed.
  if ProviderCombo.ItemIndex >= 0 then
    HelpChat.Settings.Provider := ProviderCombo.Items[ProviderCombo.ItemIndex];
  UpdateStatus;
end;

procedure TMainForm.ThemeComboChange(Sender: TObject);
begin
  // Auto = the page follows the system (light/dark); the built-in themes are
  // the same THelpChatTheme record the VCL derives from its styles.
  if ThemeCombo.ItemIndex >= 0 then
    HelpChat.ThemeMode := TFmxHelpChatThemeMode(ThemeCombo.ItemIndex);
end;

procedure TMainForm.HelpChatGetContext(Sender: TObject; var AContext: THelpChatContext);
begin
  // The component built the context from the active form, tab and control;
  // an application can refine it here. This demo just shows it.
  FLastContext := Format('Context: %s [%s]', [AContext.DisplayName, AContext.HelpKeyword]);
  UpdateStatus;
end;

procedure TMainForm.HelpChatBeforeShowHelp(Sender: TObject; var AContainer: TFmxObject);
begin
  // Where the chat goes: by default (AContainer = nil) in the component's own
  // tool window; with "Help embedded" in the side panel of this form, which
  // the application shows here.
  if EmbeddedCheck.IsChecked then
  begin
    ChatPanel.Visible := True;
    ChatSplitter.Visible := True;
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

procedure TMainForm.EmbeddedCheckChange(Sender: TObject);
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
