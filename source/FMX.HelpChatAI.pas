{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  <c>TFmxHelpChatAI</c>: the help chat for FireMonkey applications. A
///  non-visual component that owns the engine and the transport, puts a "?"
///  bubble on the host form, answers F1 with the context of the current screen
///  (the deepest HelpKeyword/HelpContext from the focused control upwards, the
///  active tab as label), registers as Delphi help viewer (System.HelpIntfs),
///  and shows the chat (<see cref="TFmxHelpChatAIPanel" />) in its own tool
///  window or in any container the application provides through
///  <c>Container</c> or <c>OnBeforeShowHelp</c>. The engine and the local
///  HTTP server run in-process on every platform.
/// </summary>
unit FMX.HelpChatAI;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Messaging,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.HelpChatAI.Panel,
  HelpChatAI.HelpViewer,
  HelpChatAI.Actions,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Theme,
  HelpChatAI.Engine,
  HelpChatAI.Transport;

const
  HELPCHAT_FMX_DEF_PANEL_WIDTH = 400;
  HELPCHAT_FMX_DEF_PANEL_HEIGHT = 600;
  HELPCHAT_FMX_DEF_BUBBLE_SIZE = 44;
  HELPCHAT_FMX_MARGIN = 16;
  /// <summary>The same question within this interval (key auto-repeat, a
  /// request routed twice) is shown but not sent again.</summary>
  HELPCHAT_FMX_ASK_DEBOUNCE_MS = 1500;
  /// <summary>Per-application UI state (panel position and size).</summary>
  HELPCHAT_FMX_UI_STATE_FILENAME = 'helpchatai-ui.json';

type
  TFmxHelpChatAI = class;

  /// <summary>Event to refine the screen context built automatically from the
  /// active form and control (rename the screen, add the help keyword...).</summary>
  TFmxHelpChatContextEvent = procedure(Sender: TObject; var AContext: THelpChatContext) of object;

  /// <summary>Event to adjust the theme before it is applied to the panel
  /// (brand accent...). Empty the theme to keep the page defaults.</summary>
  TFmxHelpChatThemeEvent = procedure(Sender: TObject; var ATheme: THelpChatTheme) of object;

  /// <summary>Fired before the chat is shown. <c>AContainer</c> arrives as the
  /// <c>Container</c> property; set it to any control or form (and make it
  /// visible) to embed the chat there, leave it nil for the own window.</summary>
  TFmxHelpChatShowEvent = procedure(Sender: TObject; var AContainer: TFmxObject) of object;

  /// <summary>Colours of the panel: the page's own light/dark defaults (following
  /// the system), or one of the two built-in themes.</summary>
  TFmxHelpChatThemeMode = (tmAuto, tmLight, tmDark);

  /// <summary>
  ///  The default host of the chat panel: a tool window anchored to the
  ///  bottom-right corner of the host form, remembering where the user left it.
  /// </summary>
  TFmxHelpChatAIForm = class(TForm)
  strict private
    FOnClosedByUser: TNotifyEvent;
  protected
    procedure DoClose(var CloseAction: TCloseAction); override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: NativeInt = 0); override;
    property OnClosedByUser: TNotifyEvent read FOnClosedByUser write FOnClosedByUser;
  end;

  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TFmxHelpChatAI = class(TComponent, IHelpChatHelpTarget)
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FTransport: IHelpChatTransport;
    FView: TFmxHelpChatAIPanel;
    FOwnForm: TFmxHelpChatAIForm;
    FContainer: TFmxObject;
    FActiveContainer: TFmxObject;
    FBubble: TButton;
    FHelpViewer: THelpChatHelpViewer;
    FHelpViewerIntf: IInterface;
    FHookedForm: TCommonCustomForm;
    FSavedKeyDown: TKeyEvent;
    FFormsCreatedId: Integer;
    FActive: Boolean;
    FStreamedActive: Boolean;
    FHandleF1: Boolean;
    FRegisterHelpViewer: Boolean;
    FShowBubble: Boolean;
    FConfigFileName: TFileName;
    FRememberPanelPosition: Boolean;
    FThemeMode: TFmxHelpChatThemeMode;
    FHostForm: TCommonCustomForm;
    FPanelWidth: Integer;
    FPanelHeight: Integer;
    FLastAskText: string;
    FLastAskTick: Cardinal;
    FOnGetContext: TFmxHelpChatContextEvent;
    FOnGetTheme: TFmxHelpChatThemeEvent;
    FActions: THelpChatActionBroker;
    FActionsRef: IHelpChatActionInvoker; // owns the broker (it is reference counted)
    FActionsEnabled: Boolean;
    FOnActionConfirm: THelpChatActionConfirmEvent;
    FOnActionExecuted: THelpChatActionExecutedEvent;
    FOnBeforeShowHelp: TFmxHelpChatShowEvent;
    FOnAfterShowHelp: TNotifyEvent;
    FOnBeforeHideHelp: TNotifyEvent;
    FOnAfterHideHelp: TNotifyEvent;
    FOnOpenLink: THelpChatOpenLinkEvent;
    procedure SetActionsEnabled(const Value: Boolean);
    procedure ActionsPending(Sender: TObject);
    procedure ActionConfirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    procedure ActionExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
    procedure SetSettings(const Value: THelpChatSettings);
    procedure SetContainer(const Value: TFmxObject);
    procedure SetActive(const Value: Boolean);
    procedure SetShowBubble(const Value: Boolean);
    procedure SetHostForm(const Value: TCommonCustomForm);
    procedure SetThemeMode(const Value: TFmxHelpChatThemeMode);
    function ResolveHostForm: TCommonCustomForm;
    procedure EnsureBubble;
    procedure DestroyBubble;
    procedure BubbleClick(Sender: TObject);
    procedure EnsureView(const AContainer: TFmxObject);
    procedure DestroyView;
    procedure EnsureOwnForm;
    procedure PositionOwnForm;
    procedure OwnFormClosedByUser(Sender: TObject);
    procedure UiCommand(const ACommand: string);
    procedure ViewPageReady(Sender: TObject);
    procedure ViewOpenLink(Sender: TObject; const AUrl: string; var AHandled: Boolean);
    procedure HideView;
    procedure HookHostForm;
    procedure UnhookHostForm;
    procedure HostKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure FormsCreated(const Sender: TObject; const M: TMessage);
    function UiStateFile: string;
    procedure SavePanelBounds;
    function LoadPanelBounds(out ABounds: TRect): Boolean;
    procedure OpenWithContext(const AContext: THelpChatContext);
    procedure Ask(const AQuestion: string; const ASend: Boolean);
  protected
    procedure Loaded; override;
    /// <summary>Reads the configuration into Settings when the component
    /// activates: <c>ConfigFileName</c> alone when it names one, the three
    /// default files otherwise. Virtual because the design-time preview has
    /// already read it, from the folder of the project rather than the folder
    /// of the IDE, and must not read it again from the wrong place.</summary>
    procedure LoadConfiguration; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Creates the transport; override to plug a remote one.</summary>
    function CreateTransport(const AEngine: THelpChatEngine): IHelpChatTransport; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>Builds the context of the current screen: active form (name,
    /// caption, class), the deepest control with HelpKeyword/HelpContext from
    /// the focused control upwards, the active tab item as label, the focused
    /// control; then fires OnGetContext.</summary>
    function BuildContext: THelpChatContext;
    /// <summary>IHelpChatHelpTarget: the help system may route requests here.</summary>
    function IsHelpViewerActive: Boolean;
    /// <summary>Opens the panel (starts the engine and the server if needed).</summary>
    procedure Open;
    /// <summary>Opens the panel and sends AQuestion, or pre-fills it when ASend is False.</summary>
    procedure OpenWithQuestion(const AQuestion: string; const ASend: Boolean = True);
    /// <summary>Opens the panel with the localized question about the current screen.</summary>
    procedure OpenForCurrentScreen;
    /// <summary>The current screen context with the keyword or context id it
    /// was asked for (what the help system calls).</summary>
    procedure OpenForHelp(const AKeyword: string; const AContext: Integer);
    /// <summary>Opens the panel on a page of <c>Settings.DocFolder</c> ("110",
    /// "guide/setup.md"); the page shows "not available" when there is none.</summary>
    procedure OpenDocPage(const APage: string);
    procedure Close;
    procedure Toggle;
    function IsPanelVisible: Boolean;
    /// <summary>The theme the panel gets from ThemeMode, then OnGetTheme.</summary>
    function BuildTheme: THelpChatTheme;
    /// <summary>Recomputes the theme, hands it to the transport (next page load)
    /// and pushes it into the open page.</summary>
    procedure ApplyTheme;
    /// <summary>For forms other than the host: call from their OnKeyDown to
    /// give them F1 too. Returns True when the key was consumed.</summary>
    function HandleKeyDown(var AKey: Word; const AShift: TShiftState): Boolean;

    property Engine: THelpChatEngine read FEngine;
    property Transport: IHelpChatTransport read FTransport;
    /// <summary>What the assistant may do in this application, beyond
    /// answering: the application registers its actions here (see
    /// <see cref="HelpChatAI.Actions" />). Available from the constructor, so
    /// actions can be registered before or after Active.</summary>
    property Actions: THelpChatActionBroker read FActions;
    /// <summary>The chat control (web view), wherever it is parented.</summary>
    property View: TFmxHelpChatAIPanel read FView;
    /// <summary>The component's own window, when the chat is not embedded.</summary>
    property OwnForm: TFmxHelpChatAIForm read FOwnForm;
    /// <summary>The container currently hosting the chat: the application's one,
    /// or the own window.</summary>
    property ActiveContainer: TFmxObject read FActiveContainer;
    /// <summary>Form hosting the bubble, F1 and anchoring the own window;
    /// nil = Application.MainForm. Set it in code: at design time the form of
    /// another unit is not a component of this one, so there would be nothing
    /// to choose from.</summary>
    property HostForm: TCommonCustomForm read FHostForm write SetHostForm;
  published
    property Settings: THelpChatSettings read FSettings write SetSettings;
    /// <summary>Starts engine, server and hooks. Set at design time, it activates
    /// when the owner form is loaded at runtime.</summary>
    property Active: Boolean read FActive write SetActive default False;
    /// <summary>Register the chat as the Delphi help viewer (System.HelpIntfs):
    /// code calling the help system with a keyword or context opens the chat.</summary>
    property RegisterHelpViewer: Boolean read FRegisterHelpViewer write FRegisterHelpViewer default True;
    /// <summary>F1 on the host form opens the chat with the current screen as
    /// context (its OnKeyDown is chained, the previous handler still runs).</summary>
    property HandleF1: Boolean read FHandleF1 write FHandleF1 default True;
    /// <summary>Round "?" button in the bottom-right corner of the host form.</summary>
    property ShowBubble: Boolean read FShowBubble write SetShowBubble default True;
    /// <summary>The configuration file to read when the component activates.
    /// Named here, that file is the configuration and nothing else is looked
    /// at; a relative path is resolved against the executable. Left empty, the
    /// usual three are merged in order: the shared per-user one
    /// (%APPDATA%\HelpChat), the one next to the executable, then the per-user
    /// one of this application - which is where an API key belongs.</summary>
    property ConfigFileName: TFileName read FConfigFileName write FConfigFileName;
    /// <summary>Offer the registered actions to the model. False keeps them
    /// registered but invisible: the assistant can only answer.</summary>
    property ActionsEnabled: Boolean read FActionsEnabled write SetActionsEnabled default True;
    /// <summary>Asked before running an action marked as needing confirmation.
    /// Set AAllow to False to refuse: the model is told the user said no.</summary>
    property OnActionConfirm: THelpChatActionConfirmEvent read FOnActionConfirm write FOnActionConfirm;
    /// <summary>Fired after every action, for a log or a status bar.</summary>
    property OnActionExecuted: THelpChatActionExecutedEvent read FOnActionExecuted write FOnActionExecuted;

    /// <summary>Reopen the own window where the user left it (per application, per user).</summary>
    property RememberPanelPosition: Boolean read FRememberPanelPosition write FRememberPanelPosition default True;
    /// <summary>Page defaults (follow the system), or the built-in light/dark theme.</summary>
    property ThemeMode: TFmxHelpChatThemeMode read FThemeMode write SetThemeMode default tmAuto;
    /// <summary>Where the chat is embedded (a side panel, a tab, a form of yours).
    /// nil = the component's own tool window. OnBeforeShowHelp can still change it.</summary>
    property Container: TFmxObject read FContainer write SetContainer;
    /// <summary>Default size of the own window.</summary>
    property PanelWidth: Integer read FPanelWidth write FPanelWidth default HELPCHAT_FMX_DEF_PANEL_WIDTH;
    property PanelHeight: Integer read FPanelHeight write FPanelHeight default HELPCHAT_FMX_DEF_PANEL_HEIGHT;
    property OnGetContext: TFmxHelpChatContextEvent read FOnGetContext write FOnGetContext;
    property OnGetTheme: TFmxHelpChatThemeEvent read FOnGetTheme write FOnGetTheme;
    /// <summary>Decide where the chat goes and show its container; leave
    /// AContainer nil for the own window.</summary>
    property OnBeforeShowHelp: TFmxHelpChatShowEvent read FOnBeforeShowHelp write FOnBeforeShowHelp;
    /// <summary>The chat is visible in its container.</summary>
    property OnAfterShowHelp: TNotifyEvent read FOnAfterShowHelp write FOnAfterShowHelp;
    /// <summary>The chat is about to be hidden (✕, Esc, Close): hide your container here.</summary>
    property OnBeforeHideHelp: TNotifyEvent read FOnBeforeHideHelp write FOnBeforeHideHelp;
    property OnAfterHideHelp: TNotifyEvent read FOnAfterHideHelp write FOnAfterHideHelp;
    /// <summary>A link of the panel is leaving it (web site, mail, a page that
    /// is not in DocFolder): set AHandled to open it yourself, else it opens
    /// in the system browser.</summary>
    property OnOpenLink: THelpChatOpenLinkEvent read FOnOpenLink write FOnOpenLink;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.Math,
  FMX.TabControl,
  HelpChatAI.Server,
  HelpChatAI.Transport.Remote;

// Help properties live on TStyledControl (TControl has none).
function ControlHasHelp(const AControl: TStyledControl): Boolean;
begin
  Result := Assigned(AControl) and
    (((AControl.HelpType = htKeyword) and (AControl.HelpKeyword <> '')) or
     ((AControl.HelpType = htContext) and (AControl.HelpContext <> 0)));
end;

function ActiveTabOf(const ARoot: TFmxObject): TTabItem;
var
  I: Integer;
begin
  Result := nil;
  if ARoot = nil then
    Exit;
  if ARoot is TTabControl then
    Exit(TTabControl(ARoot).ActiveTab);
  for I := 0 to ARoot.ChildrenCount - 1 do
  begin
    Result := ActiveTabOf(ARoot.Children[I]);
    if Assigned(Result) then
      Exit;
  end;
end;

{ TFmxHelpChatAIForm }

constructor TFmxHelpChatAIForm.CreateNew(AOwner: TComponent; Dummy: NativeInt);
begin
  inherited CreateNew(AOwner, Dummy);
  BorderStyle := TFmxFormBorderStyle.SizeToolWin;
  BorderIcons := [TBorderIcon.biSystemMenu];
  Position := TFormPosition.Designed;
  Width := HELPCHAT_FMX_DEF_PANEL_WIDTH;
  Height := HELPCHAT_FMX_DEF_PANEL_HEIGHT;
end;

procedure TFmxHelpChatAIForm.DoClose(var CloseAction: TCloseAction);
begin
  inherited DoClose(CloseAction);
  CloseAction := TCloseAction.caHide; // reused: the chat inside stays warm
  if Assigned(FOnClosedByUser) then
    FOnClosedByUser(Self);
end;

{ TFmxHelpChatAI }

constructor TFmxHelpChatAI.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSettings := THelpChatSettings.Create;
  FActions := THelpChatActionBroker.Create;
  FActionsRef := FActions; // reference counted from here on
  FActions.OnPending := ActionsPending;
  FActions.OnConfirm := ActionConfirm;
  FActions.OnExecuted := ActionExecuted;
  FActionsEnabled := True;
  FHandleF1 := True;
  FRegisterHelpViewer := True;
  FShowBubble := True;
  FRememberPanelPosition := True;
  FPanelWidth := HELPCHAT_FMX_DEF_PANEL_WIDTH;
  FPanelHeight := HELPCHAT_FMX_DEF_PANEL_HEIGHT;
  FFormsCreatedId := -1;
end;

destructor TFmxHelpChatAI.Destroy;
begin
  Active := False;
  FActions.OnPending := nil;
  FActions.OnConfirm := nil;
  FActions.OnExecuted := nil;
  FActions := nil;
  FActionsRef := nil; // freed here, unless a queued call still holds it
  FSettings.Free;
  inherited;
end;

procedure TFmxHelpChatAI.LoadConfiguration;
begin
  FSettings.LoadConfiguration(FConfigFileName);
end;

procedure TFmxHelpChatAI.Loaded;
begin
  inherited Loaded;
  if FStreamedActive and not (csDesigning in ComponentState) then
    SetActive(True);
end;

procedure TFmxHelpChatAI.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FHostForm then
      FHostForm := nil;
    if AComponent = FHookedForm then
      FHookedForm := nil;
    if AComponent = FBubble then
      FBubble := nil;
    if AComponent = FOwnForm then
      FOwnForm := nil;
    if AComponent = FView then
      FView := nil;
    if AComponent = FContainer then
      FContainer := nil;
    if AComponent = FActiveContainer then
      FActiveContainer := nil;
  end;
end;

procedure TFmxHelpChatAI.SetSettings(const Value: THelpChatSettings);
begin
  FSettings.Assign(Value);
end;

procedure TFmxHelpChatAI.SetHostForm(const Value: TCommonCustomForm);
begin
  if Value = FHostForm then
    Exit;
  if Assigned(FHostForm) then
    FHostForm.RemoveFreeNotification(Self);
  DestroyBubble;
  UnhookHostForm;
  FHostForm := Value;
  if Assigned(FHostForm) then
    FHostForm.FreeNotification(Self);
  if FActive then
  begin
    HookHostForm;
    EnsureBubble;
  end;
end;

procedure TFmxHelpChatAI.SetContainer(const Value: TFmxObject);
begin
  if Value = FContainer then
    Exit;
  if Assigned(FContainer) then
    FContainer.RemoveFreeNotification(Self);
  FContainer := Value;
  if Assigned(FContainer) then
    FContainer.FreeNotification(Self);
end;

procedure TFmxHelpChatAI.SetThemeMode(const Value: TFmxHelpChatThemeMode);
begin
  if Value = FThemeMode then
    Exit;
  FThemeMode := Value;
  if FActive then
    ApplyTheme;
end;

function TFmxHelpChatAI.CreateTransport(const AEngine: THelpChatEngine): IHelpChatTransport;
begin
  // Settings decide where the engine lives: on mobile this is how the model key
  // stays out of the application (see Settings.Remote).
  if FSettings.Remote.IsConfigured then
    Result := THelpChatRemoteTransport.Create(FSettings.Remote)
  else
    Result := THelpChatLocalServer.Create(AEngine, False);
end;

procedure TFmxHelpChatAI.SetActive(const Value: Boolean);
begin
  if csDesigning in ComponentState then
  begin
    FActive := Value;
    Exit;
  end;
  if csLoading in ComponentState then
  begin
    FStreamedActive := Value;
    Exit;
  end;
  if Value = FActive then
    Exit;

  if Value then
  begin
    LoadConfiguration;
    HelpChatDefaultLanguage := FSettings.Language;
    FEngine := THelpChatEngine.Create(FSettings);
    FEngine.Actions := FActionsRef;
    // With a remote server the local engine stays idle: no documentation index
    // loaded, no worker pool, no model key in this process.
    if not FSettings.Remote.IsConfigured then
      FEngine.Start;
    FTransport := CreateTransport(FEngine);
    FTransport.SetOnUiCommand(UiCommand);
    try
      FTransport.Start;
    except
      // A server that will not answer must not leave half a component behind.
      FTransport := nil;
      FreeAndNil(FEngine);
      raise;
    end;
    FActive := True;
    if FRegisterHelpViewer and not Assigned(FHelpViewer) then
    begin
      FHelpViewer := THelpChatHelpViewer.Create(Self);
      FHelpViewerIntf := FHelpViewer; // the manager and this reference share the object
      FHelpViewer.Register;
    end;
    // The main form may not exist yet (Active set in the DFM of the main form
    // itself): hook and place the bubble as soon as the forms are created.
    HookHostForm;
    if FShowBubble then
      EnsureBubble;
    if (FHookedForm = nil) or (FBubble = nil) then
      FFormsCreatedId := TMessageManager.DefaultManager.SubscribeToMessage(TFormsCreatedMessage, FormsCreated);
  end
  else
  begin
    FActive := False;
    if FFormsCreatedId >= 0 then
    begin
      TMessageManager.DefaultManager.Unsubscribe(TFormsCreatedMessage, FFormsCreatedId);
      FFormsCreatedId := -1;
    end;
    if Assigned(FHelpViewer) then
    begin
      FHelpViewer.Unregister;
      FHelpViewer := nil;
      FHelpViewerIntf := nil;
    end;
    UnhookHostForm;
    DestroyBubble;
    if Assigned(FOwnForm) then
      SavePanelBounds;
    DestroyView;
    if Assigned(FOwnForm) then
    begin
      FOwnForm.OnClosedByUser := nil;
      FreeAndNil(FOwnForm);
    end;
    FActiveContainer := nil;
    if Assigned(FTransport) then
    begin
      FTransport.SetOnUiCommand(nil);
      FTransport.Stop;
      FTransport := nil;
    end;
    FreeAndNil(FEngine); // stops the workers (bounded wait) and persists
  end;
end;

procedure TFmxHelpChatAI.FormsCreated(const Sender: TObject; const M: TMessage);
begin
  if not FActive then
    Exit;
  HookHostForm;
  if FShowBubble then
    EnsureBubble;
end;

function TFmxHelpChatAI.IsHelpViewerActive: Boolean;
begin
  Result := FActive and FRegisterHelpViewer;
end;

function TFmxHelpChatAI.ResolveHostForm: TCommonCustomForm;
begin
  Result := FHostForm;
  if Result = nil then
    Result := Application.MainForm;
  if (Result = nil) and (Owner is TCommonCustomForm) then
    Result := TCommonCustomForm(Owner);
end;

procedure TFmxHelpChatAI.HookHostForm;
var
  LHost: TCommonCustomForm;
begin
  if Assigned(FHookedForm) then
    Exit;
  LHost := ResolveHostForm;
  if LHost = nil then
    Exit;
  // FMX has no application-wide key hook: the host form's OnKeyDown is chained
  // (the handler the application set still runs first).
  FHookedForm := LHost;
  FHookedForm.FreeNotification(Self);
  FSavedKeyDown := LHost.OnKeyDown;
  LHost.OnKeyDown := HostKeyDown;
end;

procedure TFmxHelpChatAI.UnhookHostForm;
var
  LOurs, LCurrent: TKeyEvent;
begin
  if Assigned(FHookedForm) then
  begin
    LOurs := HostKeyDown;
    LCurrent := FHookedForm.OnKeyDown;
    if (TMethod(LCurrent).Code = TMethod(LOurs).Code) and (TMethod(LCurrent).Data = TMethod(LOurs).Data) then
      FHookedForm.OnKeyDown := FSavedKeyDown;
    FHookedForm.RemoveFreeNotification(Self);
    FHookedForm := nil;
  end;
  FSavedKeyDown := nil;
end;

procedure TFmxHelpChatAI.HostKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
begin
  if Assigned(FSavedKeyDown) then
    FSavedKeyDown(Sender, Key, KeyChar, Shift);
  if Key <> 0 then
    HandleKeyDown(Key, Shift);
end;

function TFmxHelpChatAI.HandleKeyDown(var AKey: Word; const AShift: TShiftState): Boolean;
begin
  Result := FActive and FHandleF1 and (AKey = vkF1) and
    (AShift * [ssCtrl, ssAlt, ssCommand] = []);
  if Result then
  begin
    AKey := 0;
    OpenForCurrentScreen;
  end;
end;

procedure TFmxHelpChatAI.EnsureBubble;
var
  LHost: TCommonCustomForm;
begin
  if Assigned(FBubble) or not FShowBubble or not FActive then
    Exit;
  LHost := ResolveHostForm;
  if LHost = nil then
    Exit;
  FBubble := TButton.Create(Self);
  FBubble.FreeNotification(Self);
  FBubble.Stored := False;
  FBubble.Text := '?';
  FBubble.StyledSettings := FBubble.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];
  FBubble.TextSettings.Font.Size := 18;
  FBubble.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBubble.Hint := HelpChatMsg(hcmUiHelp, FSettings.Language) + ' (F1)';
  FBubble.ShowHint := True;
  FBubble.SetBounds(LHost.ClientWidth - HELPCHAT_FMX_DEF_BUBBLE_SIZE - HELPCHAT_FMX_MARGIN,
    LHost.ClientHeight - HELPCHAT_FMX_DEF_BUBBLE_SIZE - HELPCHAT_FMX_MARGIN,
    HELPCHAT_FMX_DEF_BUBBLE_SIZE, HELPCHAT_FMX_DEF_BUBBLE_SIZE);
  FBubble.Anchors := [TAnchorKind.akRight, TAnchorKind.akBottom];
  FBubble.OnClick := BubbleClick;
  FBubble.Parent := LHost;
  FBubble.BringToFront;
end;

procedure TFmxHelpChatAI.DestroyBubble;
begin
  if Assigned(FBubble) then
  begin
    FBubble.RemoveFreeNotification(Self);
    FreeAndNil(FBubble);
  end;
end;

procedure TFmxHelpChatAI.SetShowBubble(const Value: Boolean);
begin
  if Value = FShowBubble then
    Exit;
  FShowBubble := Value;
  if csDesigning in ComponentState then
    Exit;
  if FShowBubble then
    EnsureBubble
  else
    DestroyBubble;
end;

procedure TFmxHelpChatAI.BubbleClick(Sender: TObject);
begin
  Toggle;
end;

procedure TFmxHelpChatAI.EnsureView(const AContainer: TFmxObject);
begin
  // A native web view is not moved between windows: a new one is created for
  // a new container (the page reloads, the conversation comes from the server).
  if Assigned(FView) and (FView.Parent <> AContainer) then
    DestroyView;
  if Assigned(FView) then
    Exit;
  FView := TFmxHelpChatAIPanel.Create(Self);
  FView.FreeNotification(Self);
  FView.Stored := False;
  FView.Visible := False;
  FView.OnPageReady := ViewPageReady;
  FView.OnOpenLink := ViewOpenLink;
  FView.Align := TAlignLayout.Client;
  FView.Parent := AContainer;
  if FActiveContainer <> AContainer then
  begin
    if Assigned(FActiveContainer) and (FActiveContainer <> FOwnForm) then
      FActiveContainer.RemoveFreeNotification(Self);
    FActiveContainer := AContainer;
    if FActiveContainer <> FOwnForm then
      FActiveContainer.FreeNotification(Self);
  end;
end;

procedure TFmxHelpChatAI.DestroyView;
begin
  if Assigned(FView) then
  begin
    FView.OnPageReady := nil;
    FView.OnOpenLink := nil;
    FView.RemoveFreeNotification(Self);
    FreeAndNil(FView);
  end;
end;

procedure TFmxHelpChatAI.EnsureOwnForm;
begin
  if Assigned(FOwnForm) then
    Exit;
  FOwnForm := TFmxHelpChatAIForm.CreateNew(Self);
  FOwnForm.FreeNotification(Self);
  FOwnForm.Caption := HelpChatMsg(hcmUiTitle, FSettings.Language);
  FOwnForm.OnClosedByUser := OwnFormClosedByUser;
end;

function TFmxHelpChatAI.UiStateFile: string;
begin
  Result := TPath.Combine(HelpChatAppDataFolder, HELPCHAT_FMX_UI_STATE_FILENAME);
end;

procedure TFmxHelpChatAI.SavePanelBounds;
var
  LRoot, LPanel: TJSONObject;
  LBounds: TRect;
begin
  // Position memory belongs to the own window; an application container is
  // the application's business.
  if not FRememberPanelPosition or not Assigned(FOwnForm) or
     (FOwnForm.WindowState <> TWindowState.wsNormal) then
    Exit;
  LBounds := FOwnForm.Bounds;
  if (LBounds.Width <= 0) or (LBounds.Height <= 0) then
    Exit;
  LRoot := TJSONObject.Create;
  try
    LPanel := TJSONObject.Create;
    LRoot.AddPair('panel', LPanel);
    LPanel.AddPair('left', TJSONNumber.Create(LBounds.Left));
    LPanel.AddPair('top', TJSONNumber.Create(LBounds.Top));
    LPanel.AddPair('width', TJSONNumber.Create(LBounds.Width));
    LPanel.AddPair('height', TJSONNumber.Create(LBounds.Height));
    try
      TFile.WriteAllText(UiStateFile, LRoot.ToJSON, TEncoding.UTF8);
    except
      // UI state is a convenience: never fail for it.
    end;
  finally
    LRoot.Free;
  end;
end;

function TFmxHelpChatAI.LoadPanelBounds(out ABounds: TRect): Boolean;
var
  LValue: TJSONValue;
  LPanel: TJSONObject;
begin
  Result := False;
  ABounds := TRect.Empty;
  if not FRememberPanelPosition or not TFile.Exists(UiStateFile) then
    Exit;
  try
    LValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(UiStateFile, TEncoding.UTF8));
  except
    LValue := nil;
  end;
  if LValue = nil then
    Exit;
  try
    if (LValue is TJSONObject) and (TJSONObject(LValue).GetValue('panel') is TJSONObject) then
    begin
      LPanel := TJSONObject(TJSONObject(LValue).GetValue('panel'));
      ABounds := TRect.Create(LPanel.GetValue<Integer>('left', 0), LPanel.GetValue<Integer>('top', 0), 0, 0);
      ABounds.Width := LPanel.GetValue<Integer>('width', 0);
      ABounds.Height := LPanel.GetValue<Integer>('height', 0);
      Result := (ABounds.Width > 100) and (ABounds.Height > 100);
    end;
  finally
    LValue.Free;
  end;
end;

procedure TFmxHelpChatAI.PositionOwnForm;
var
  LHost: TCommonCustomForm;
  LArea: TRectF;
  LSaved, LHostBounds: TRect;
  LLeft, LTop, LWidth, LHeight: Integer;
begin
  LArea := Screen.WorkAreaRect;
  // Where the user left it, if that spot is still on the screen.
  if LoadPanelBounds(LSaved) and LArea.IntersectsWith(TRectF.Create(LSaved)) then
  begin
    LLeft := LSaved.Left;
    LTop := LSaved.Top;
    LWidth := LSaved.Width;
    LHeight := LSaved.Height;
  end
  else
  begin
    // Default: bottom-right corner of the host form.
    LWidth := FPanelWidth;
    LHeight := FPanelHeight;
    LHost := ResolveHostForm;
    if Assigned(LHost) then
    begin
      LHostBounds := LHost.Bounds;
      LLeft := LHostBounds.Right - LWidth - HELPCHAT_FMX_MARGIN;
      LTop := LHostBounds.Bottom - LHeight - HELPCHAT_FMX_MARGIN;
    end
    else
    begin
      LLeft := Round(LArea.Right) - LWidth - HELPCHAT_FMX_MARGIN;
      LTop := Round(LArea.Bottom) - LHeight - HELPCHAT_FMX_MARGIN;
    end;
  end;
  if LLeft + LWidth > LArea.Right then
    LLeft := Round(LArea.Right) - LWidth;
  if LTop + LHeight > LArea.Bottom then
    LTop := Round(LArea.Bottom) - LHeight;
  LLeft := Max(LLeft, Round(LArea.Left));
  LTop := Max(LTop, Round(LArea.Top));
  FOwnForm.SetBounds(LLeft, LTop, LWidth, LHeight);
end;

procedure TFmxHelpChatAI.OwnFormClosedByUser(Sender: TObject);
begin
  // The user closed the own window (✕ of the tool window).
  SavePanelBounds;
  if Assigned(FOnBeforeHideHelp) then
    FOnBeforeHideHelp(Self);
  if Assigned(FView) then
    FView.Visible := False;
  if Assigned(FOnAfterHideHelp) then
    FOnAfterHideHelp(Self);
end;


procedure TFmxHelpChatAI.SetActionsEnabled(const Value: Boolean);
begin
  FActionsEnabled := Value;
  FActions.Enabled := Value;
end;

procedure TFmxHelpChatAI.ActionsPending(Sender: TObject);
var
  LKeepAlive: IHelpChatActionInvoker;
  LBroker: THelpChatActionBroker;
begin
  // Called on the worker thread that is waiting for the action: the handlers
  // touch the user interface, so they run on the main thread. The interface
  // reference travels into the closure and keeps the broker alive even if the
  // component is destroyed before the queued call runs.
  LKeepAlive := FActionsRef;
  LBroker := FActions;
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(LKeepAlive) then
        LBroker.ExecutePending;
    end);
end;

procedure TFmxHelpChatAI.ActionExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
begin
  if Assigned(FOnActionExecuted) then
    FOnActionExecuted(Self, AName, AOutcome, AResult);
end;

procedure TFmxHelpChatAI.ActionConfirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  // FMX has no dialog that can be waited for on every platform (on mobile they
  // are asynchronous), and the worker is waiting for this answer: without a
  // handler an action that needs confirmation is refused, and the model says
  // so. Assign OnActionConfirm to ask the user your way.
  if Assigned(FOnActionConfirm) then
    FOnActionConfirm(Self, AName, AArgs, AAllow)
  else
    AAllow := False;
end;

procedure TFmxHelpChatAI.UiCommand(const ACommand: string);
begin
  // What the page asked through the server (its ✕ button or Esc).
  if FActive and (ACommand = 'close') then
    Close;
end;

procedure TFmxHelpChatAI.ViewPageReady(Sender: TObject);
begin
  // The page (re)loaded: push the current theme, whatever the load carried.
  if FActive then
    ApplyTheme;
end;

function TFmxHelpChatAI.BuildTheme: THelpChatTheme;
begin
  case FThemeMode of
    tmLight: Result := THelpChatTheme.Light;
    tmDark: Result := THelpChatTheme.Dark;
  else
    Result := Default(THelpChatTheme);
  end;
  if Assigned(FOnGetTheme) then
    FOnGetTheme(Self, Result);
end;

procedure TFmxHelpChatAI.ApplyTheme;
var
  LTheme: THelpChatTheme;
begin
  if not Assigned(FTransport) then
    Exit;
  LTheme := BuildTheme;
  FTransport.SetTheme(LTheme);      // the next page load gets it in the :root rule
  if Assigned(FView) and FView.PageReady then
    FView.RunScript('window.hcApplyTheme && window.hcApplyTheme(' + LTheme.ToJson + ');');
end;

function TFmxHelpChatAI.BuildContext: THelpChatContext;
var
  LForm: TCommonCustomForm;
  LFocused: IControl;
  LObject: TFmxObject;
  LControl: TStyledControl;
  LTab: TTabItem;
begin
  Result := Default(THelpChatContext);
  LForm := Screen.ActiveForm;
  if (LForm = nil) or (LForm = FOwnForm) then
    LForm := ResolveHostForm;
  if Assigned(LForm) then
  begin
    Result.ScreenName := LForm.Name;
    Result.ScreenLabel := LForm.Caption;
    Result.ScreenType := LForm.ClassName;
  end;

  // Walk up from the focused control: the deepest help keyword/context wins,
  // the active tab item is the screen. FMX forms declare no help of their own.
  LFocused := nil;
  if Assigned(LForm) then
    LFocused := LForm.Focused;
  if Assigned(LFocused) and (LFocused.GetObject is TFmxObject) then
  begin
    LObject := TFmxObject(LFocused.GetObject);
    Result.FocusedControl := LObject.Name;
    LTab := nil;
    while Assigned(LObject) and (LObject <> LForm) do
    begin
      if LObject is TStyledControl then
      begin
        LControl := TStyledControl(LObject);
        if (LTab = nil) and (LControl is TTabItem) then
          LTab := TTabItem(LControl);
        if (Result.HelpKeyword = '') and (Result.HelpContext = 0) then
        begin
          if (LControl.HelpType = htKeyword) and (LControl.HelpKeyword <> '') then
            Result.HelpKeyword := LControl.HelpKeyword
          else if (LControl.HelpType = htContext) and (LControl.HelpContext <> 0) then
            Result.HelpContext := LControl.HelpContext;
        end;
      end;
      LObject := LObject.Parent;
    end;
    if Assigned(LTab) and (LTab.Text <> '') then
      Result.ScreenLabel := LTab.Text;
  end
  else if Assigned(LForm) then
  begin
    // Nothing focused (FMX forms often have no focused control): the active
    // tab of the first tab control is the screen.
    LTab := ActiveTabOf(LForm);
    if Assigned(LTab) then
    begin
      if LTab.Text <> '' then
        Result.ScreenLabel := LTab.Text;
      if ControlHasHelp(LTab) then
        if LTab.HelpType = htKeyword then
          Result.HelpKeyword := LTab.HelpKeyword
        else
          Result.HelpContext := LTab.HelpContext;
    end;
  end;

  if Assigned(FOnGetContext) then
    FOnGetContext(Self, Result);
end;

procedure TFmxHelpChatAI.Open;
begin
  OpenWithContext(BuildContext);
end;

procedure TFmxHelpChatAI.OpenWithContext(const AContext: THelpChatContext);
var
  LContainer: TFmxObject;
  LWasVisible: Boolean;
begin
  if not FActive then
    Active := True;
  FTransport.SetContext(AContext);
  ApplyTheme;

  // Where does the chat go? The Container property, unless the application
  // decides otherwise right now (and shows its container).
  LContainer := FContainer;
  if Assigned(FOnBeforeShowHelp) then
    FOnBeforeShowHelp(Self, LContainer);
  if LContainer = nil then
  begin
    EnsureOwnForm;
    LContainer := FOwnForm;
  end
  else if Assigned(FOwnForm) and FOwnForm.Visible then
    FOwnForm.Hide;

  LWasVisible := IsPanelVisible and (FActiveContainer = LContainer);
  EnsureView(LContainer);
  FView.Visible := True;
  FView.BringToFront;

  if LContainer = FOwnForm then
  begin
    if not FOwnForm.Visible then
      PositionOwnForm;
    FOwnForm.Show;
    FOwnForm.BringToFront;
  end;

  if not FView.PageReady then
    FView.OpenUrl(FTransport.GetPanelUrl, FTransport.GetPanelOrigin)
  else
    FView.RunScript('window.hcFocus && window.hcFocus();');
  if not LWasVisible and Assigned(FOnAfterShowHelp) then
    FOnAfterShowHelp(Self);
end;

procedure TFmxHelpChatAI.OpenWithQuestion(const AQuestion: string; const ASend: Boolean);
begin
  Open;
  Ask(AQuestion, ASend);
end;

procedure TFmxHelpChatAI.Ask(const AQuestion: string; const ASend: Boolean);
var
  LJson: TJSONString;
  LNow: Cardinal;
begin
  // The same question right after the previous one (F1 auto-repeat, a request
  // routed twice) is not sent twice.
  LNow := TThread.GetTickCount;
  if ASend and (AQuestion = FLastAskText) and (LNow - FLastAskTick < HELPCHAT_FMX_ASK_DEBOUNCE_MS) then
    Exit;
  FLastAskText := AQuestion;
  FLastAskTick := LNow;
  LJson := TJSONString.Create(AQuestion);
  try
    FView.RunScript(Format('window.hcAsk && window.hcAsk(%s, %s);',
      [LJson.ToJSON, BoolToStr(ASend, True).ToLower]));
  finally
    LJson.Free;
  end;
end;

procedure TFmxHelpChatAI.ViewOpenLink(Sender: TObject; const AUrl: string; var AHandled: Boolean);
begin
  if Assigned(FOnOpenLink) then
    FOnOpenLink(Self, AUrl, AHandled);
end;

procedure TFmxHelpChatAI.OpenDocPage(const APage: string);
var
  LJson: TJSONString;
begin
  Open;
  if not Assigned(FView) then
    Exit;
  LJson := TJSONString.Create(APage);
  try
    FView.RunScript(Format('window.hcOpenDoc && window.hcOpenDoc(%s);', [LJson.ToJSON]));
  finally
    LJson.Free;
  end;
end;

procedure TFmxHelpChatAI.OpenForCurrentScreen;
begin
  OpenForHelp('', 0);
end;

procedure TFmxHelpChatAI.OpenForHelp(const AKeyword: string; const AContext: Integer);
var
  LContext: THelpChatContext;
begin
  if not FActive then
    Active := True;
  LContext := BuildContext;
  if AKeyword <> '' then
    LContext.HelpKeyword := AKeyword;
  if AContext <> 0 then
    LContext.HelpContext := AContext;
  // This context, keyword included, is the one the provider must see.
  OpenWithContext(LContext);
  Ask(FEngine.ContextQuestion(LContext), True);
end;

procedure TFmxHelpChatAI.HideView;
begin
  if Assigned(FOnBeforeHideHelp) then
    FOnBeforeHideHelp(Self);
  if Assigned(FView) then
    FView.Visible := False;
  if Assigned(FOwnForm) and FOwnForm.Visible then
  begin
    SavePanelBounds;
    FOwnForm.Hide;
  end;
  if Assigned(FOnAfterHideHelp) then
    FOnAfterHideHelp(Self);
end;

procedure TFmxHelpChatAI.Close;
begin
  if IsPanelVisible then
    HideView;
end;

procedure TFmxHelpChatAI.Toggle;
begin
  if IsPanelVisible then
    Close
  else
    Open;
end;

function TFmxHelpChatAI.IsPanelVisible: Boolean;
begin
  Result := Assigned(FView) and FView.Visible and Assigned(FActiveContainer) and
    ((FActiveContainer <> FOwnForm) or FOwnForm.Visible);
end;

end.
