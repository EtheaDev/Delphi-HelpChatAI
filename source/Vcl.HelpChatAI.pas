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
///  The VCL component. Drop a <see cref="TVclHelpChatAI" /> on the main form, set
///  <c>Active</c>, and the application gets a help bubble in the bottom-right
///  corner of the form, the chat as the help system of the application (F1 and
///  <c>Application.HelpKeyword/HelpContext</c> reach it through the standard
///  <c>ICustomHelpViewer</c> / <c>IExtendedHelpViewer</c> registration, like
///  any Delphi help viewer), and the chat panel (<see cref="TVclHelpChatAIPanel" />,
///  a WebView2) shown in the component's own tool window — or, when the
///  application prefers, embedded in any container it provides through
///  <c>Container</c> or <c>OnBeforeShowHelp</c> (a side panel of the main form,
///  like recent Office apps do). The engine and the local HTTP server run
///  in-process; the component builds the screen context, follows the VCL style
///  and confines the browser to the panel origin.
/// </summary>
unit Vcl.HelpChatAI;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.HelpIntfs,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ImgList,
  Vcl.HelpChatAI.Bubble,
  Vcl.HelpChatAI.Voice,
  System.UITypes,   // after Vcl.ImgList, whose own TImageIndex is deprecated
  Vcl.AppEvnts,
  Vcl.HelpChatAI.Panel,
  HelpChatAI.HelpViewer,
  HelpChatAI.Actions,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Theme,
  HelpChatAI.Engine,
  HelpChatAI.Transport;

const
  HELPCHAT_VCL_DEF_PANEL_WIDTH = 400;
  HELPCHAT_VCL_DEF_PANEL_HEIGHT = 600;
  HELPCHAT_VCL_DEF_BUBBLE_SIZE = 44;
  HELPCHAT_VCL_MARGIN = 16;
  /// <summary>The same question within this interval (key auto-repeat, F1 routed
  /// twice) is shown but not sent again.</summary>
  HELPCHAT_VCL_ASK_DEBOUNCE_MS = 1500;
  /// <summary>Per-application UI state (panel position and size).</summary>
  HELPCHAT_VCL_UI_STATE_FILENAME = 'helpchatai-ui.json';

type
  TVclHelpChatAI = class;

  /// <summary>Event to refine the screen context built automatically from the
  /// active form and control (rename the screen, add the help keyword...).</summary>
  TVclHelpChatContextEvent = procedure(Sender: TObject; var AContext: THelpChatContext) of object;

  /// <summary>Event to adjust the theme derived from the VCL style before it is
  /// applied to the panel (brand accent, fonts...). Empty the theme to keep the
  /// page defaults.</summary>
  TVclHelpChatThemeEvent = procedure(Sender: TObject; var ATheme: THelpChatTheme) of object;

  /// <summary>Fired before the chat is shown. <c>AContainer</c> arrives as the
  /// <c>Container</c> property; set it to any TWinControl (and make it visible)
  /// to embed the chat there, leave it nil for the component's own window.</summary>
  TVclHelpChatShowEvent = procedure(Sender: TObject; var AContainer: TWinControl) of object;

  /// <summary>
  ///  The default host of the chat panel: a tool window anchored to the
  ///  bottom-right corner of the host form, remembering where the user left it.
  /// </summary>
  TVclHelpChatAIForm = class(TForm)
  strict private
    FOnClosedByUser: TNotifyEvent;
  protected
    procedure DoClose(var Action: TCloseAction); override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    property OnClosedByUser: TNotifyEvent read FOnClosedByUser write FOnClosedByUser;
  end;

  /// <summary>Dictated text on its way to the question box: change AText to
  /// correct it, empty it to drop it. AFinal is False for a hypothesis, which
  /// the next one replaces.</summary>
  TVclHelpChatVoiceTextEvent = procedure(Sender: TObject; var AText: string;
    const AFinal: Boolean) of object;

  /// <summary>Dictation needs a consent the user never gave. Set AHandled to
  /// deal with it yourself; otherwise the component explains it and opens the
  /// Windows page where the consent lives.</summary>
  TVclHelpChatVoiceConsentEvent = procedure(Sender: TObject; var AHandled: Boolean) of object;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TVclHelpChatAI = class(TComponent, IHelpChatHelpTarget)
  strict private
    FSettings: THelpChatSettings;
    FEngine: THelpChatEngine;
    FTransport: IHelpChatTransport;
    FView: TVclHelpChatAIPanel;
    FOwnForm: TVclHelpChatAIForm;
    FContainer: TWinControl;
    FActiveContainer: TWinControl;
    FBubble: TVclHelpChatAIBubble;
    FImages: TCustomImageList;
    FVoice: THelpChatVoiceInput;
    FVoiceConsentAsked: Boolean;
    FVoiceEngine: THelpChatVoiceEngine;
    FOnVoiceConsentNeeded: TVclHelpChatVoiceConsentEvent;
    FOnVoiceText: TVclHelpChatVoiceTextEvent;
    FImageIndex: TImageIndex;
    FImageName: TImageName;
    FAppEvents: TApplicationEvents;
    FHelpViewer: THelpChatHelpViewer;
    FHelpViewerIntf: ICustomHelpViewer;
    FActive: Boolean;
    FStreamedActive: Boolean;
    FHandleF1: Boolean;
    FRegisterHelpViewer: Boolean;
    FShowBubble: Boolean;
    FConfigFileName: TFileName;
    FCaption: string;
    FAssistantName: string;
    FFollowVclStyle: Boolean;
    FRememberPanelPosition: Boolean;
    FHostForm: TCustomForm;
    FPanelWidth: Integer;
    FPanelHeight: Integer;
    FLastAskText: string;
    FLastAskTick: Cardinal;
    FOnGetContext: TVclHelpChatContextEvent;
    FOnGetTheme: TVclHelpChatThemeEvent;
    FActions: THelpChatActionBroker;
    FActionsRef: IHelpChatActionInvoker; // owns the broker (it is reference counted)
    FActionsEnabled: Boolean;
    FOnActionConfirm: THelpChatActionConfirmEvent;
    FOnActionExecuted: THelpChatActionExecutedEvent;
    FOnBeforeShowHelp: TVclHelpChatShowEvent;
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
    procedure SetContainer(const Value: TWinControl);
    procedure SetActive(const Value: Boolean);
    procedure SetShowBubble(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageName(const Value: TImageName);
    procedure SetCaption(const Value: string);
    procedure SetAssistantName(const Value: string);
    procedure ApplyBubbleIcon;
    function EnsureVoice: Boolean;
    procedure ApplyVoiceButton;
    procedure StopVoice;
    procedure HookVoice;
    procedure AskVoiceConsent;
    procedure SetVoiceEngine(const Value: THelpChatVoiceEngine);
    procedure VoiceText(Sender: TObject; const AText: string; const AFinal: Boolean);
    procedure VoiceState(Sender: TObject; const AListening: Boolean);
    procedure VoiceError(Sender: TObject; const AMessage: string);
    procedure SetHostForm(const Value: TCustomForm);
    function ResolveHostForm: TCustomForm;
    procedure EnsureBubble;
    procedure DestroyBubble;
    procedure BubbleClick(Sender: TObject);
    procedure EnsureView;
    procedure EnsureOwnForm;
    procedure PositionOwnForm;
    procedure OwnFormClosedByUser(Sender: TObject);
    procedure ViewCloseRequested(Sender: TObject);
    procedure UiCommand(const ACommand: string);
    procedure ViewStyleChanged(Sender: TObject);
    procedure ViewPageReady(Sender: TObject);
    procedure ViewOpenLink(Sender: TObject; const AUrl: string; var AHandled: Boolean);
    procedure DeferredApplyTheme;
    procedure HideView;
    procedure AppMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure HookApplication;
    procedure UnhookApplication;
    function IsOurWindow(const AHandle: HWND): Boolean;
    function UiStateFile: string;
    procedure SavePanelBounds;
    function LoadPanelBounds(out ABounds: TRect; out APPI: Integer): Boolean;
    procedure OpenWithContext(const AContext: THelpChatContext);
    procedure Ask(const AQuestion: string; const ASend: Boolean);
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Reads the configuration into Settings when the component
    /// activates: <c>ConfigFileName</c> alone when it names one, the three
    /// default files otherwise. Virtual because the design-time preview has
    /// already read it, from the folder of the project rather than the folder
    /// of the IDE, and must not read it again from the wrong place.</summary>
    procedure LoadConfiguration; virtual;
    /// <summary>Creates the transport; override to plug a remote one.</summary>
    function CreateTransport(const AEngine: THelpChatEngine): IHelpChatTransport; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    /// <summary>Builds the context of the current screen: active form (name,
    /// class), the deepest control with HelpKeyword/HelpContext from the focused
    /// control upwards (the form last), the active tab sheet as label, the
    /// focused control; then fires OnGetContext.</summary>
    function BuildContext: THelpChatContext;
    /// <summary>True when the focused control or one of its parents (the form
    /// included) declares a HelpKeyword or HelpContext: the VCL will route F1
    /// to the help system, and so to this component.</summary>
    class function ActiveControlHasHelp: Boolean; static;
    /// <summary>IHelpChatHelpTarget: the help system may route requests here.</summary>
    function IsHelpViewerActive: Boolean;
    /// <summary>Opens the panel (starts the engine and the server if needed).</summary>
    procedure Open;
    /// <summary>Opens the panel and sends AQuestion, or pre-fills it when ASend is False.</summary>
    procedure OpenWithQuestion(const AQuestion: string; const ASend: Boolean = True);
    /// <summary>Opens the panel with the localized question about the current screen.</summary>
    procedure OpenForCurrentScreen;
    /// <summary>What the help system calls: the current screen context with the
    /// keyword or context id it was asked for.</summary>
    procedure OpenForHelp(const AKeyword: string; const AContext: Integer);
    /// <summary>Opens the panel on a page of <c>Settings.DocFolder</c> ("110",
    /// "guide/setup.md"); the page shows "not available" when there is none.</summary>
    procedure OpenDocPage(const APage: string);
    procedure Close;
    procedure Toggle;
    function IsPanelVisible: Boolean;
    /// <summary>The theme the panel gets: from the active VCL style when
    /// FollowVclStyle, else empty (page defaults); then OnGetTheme.</summary>
    function BuildTheme: THelpChatTheme;
    /// <summary>Recomputes the theme, hands it to the transport (next page load)
    /// and pushes it into the open page. Called on Open and on style change.</summary>
    procedure ApplyTheme;
    /// <summary>Title of the component's own window: <c>Caption</c>, or the
    /// localized "Help" when it is empty.</summary>
    function ResolvedCaption: string;
    /// <summary>Name the panel writes in its header: <c>AssistantName</c>, or
    /// the localized "Assistant" when it is empty.</summary>
    function ResolvedAssistantName: string;
    /// <summary>The icon of the bubble as the page can load it - a
    /// <c>data:image/png</c> URI - empty when there is none.</summary>
    function AssistantIconDataUri: string;
    /// <summary>Retitles the own window, hands name and icon to the transport
    /// (so the next page load already carries them) and updates an open page.
    /// Called when any of Caption, AssistantName, Images, ImageIndex or
    /// ImageName changes, and when the component activates.</summary>
    procedure ApplyAssistant;

    property Engine: THelpChatEngine read FEngine;
    property Transport: IHelpChatTransport read FTransport;
    /// <summary>What the assistant may do in this application, beyond
    /// answering: the application registers its actions here (see
    /// <see cref="HelpChatAI.Actions" />). Available from the constructor, so
    /// actions can be registered before or after Active.</summary>
    property Actions: THelpChatActionBroker read FActions;
    /// <summary>The chat control (WebView2), wherever it is parented.</summary>
    property View: TVclHelpChatAIPanel read FView;
    /// <summary>The component's own window, when the chat is not embedded.</summary>
    property OwnForm: TVclHelpChatAIForm read FOwnForm;
    /// <summary>The container currently hosting the chat: the application's one,
    /// or the own window.</summary>
    property ActiveContainer: TWinControl read FActiveContainer;
    /// <summary>Form hosting the bubble and anchoring the panel; nil =
    /// Application.MainForm. Set it in code: at design time the form of
    /// another unit is not a component of this one, so there would be nothing
    /// to choose from.</summary>
    property HostForm: TCustomForm read FHostForm write SetHostForm;
  published
    property Settings: THelpChatSettings read FSettings write SetSettings;
    /// <summary>Starts engine, server and hooks. Set at design time, it activates
    /// when the owner form is loaded at runtime.</summary>
    property Active: Boolean read FActive write SetActive default False;
    /// <summary>Register the chat as the help viewer of the application: F1 on a
    /// control with HelpKeyword/HelpContext, Application.HelpKeyword/HelpContext
    /// and HelpShowTableOfContents open the chat.</summary>
    property RegisterHelpViewer: Boolean read FRegisterHelpViewer write FRegisterHelpViewer default True;
    /// <summary>F1 opens the chat also where no control declares any help (the
    /// VCL would do nothing): a question about the current screen is asked.</summary>
    property HandleF1: Boolean read FHandleF1 write FHandleF1 default True;
    /// <summary>Title of the window the chat opens in when it is not embedded
    /// in a container of yours. Empty (the default) = the localized "Help".</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>What the assistant is called, written in the header of the
    /// chat panel next to its icon - and the title of the page itself. Empty
    /// (the default) = the localized "Assistant". It is a name, not a window
    /// title: that is <c>Caption</c>.</summary>
    property AssistantName: string read FAssistantName write SetAssistantName;
    /// <summary>Round "?" button in the bottom-right corner of the host form.</summary>
    property ShowBubble: Boolean read FShowBubble write SetShowBubble default True;
    /// <summary>Image list holding the bubble icon; nil uses the icons
    /// compiled into the component (HELPCHAT_ICON_* names). The same icon is
    /// drawn in the header of the chat panel, left of AssistantName.</summary>
    property Images: TCustomImageList read FImages write SetImages;
    /// <summary>Bubble icon by index, used when ImageName finds nothing.</summary>
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    /// <summary>Bubble icon by name: with the built-in icons, one of
    /// AIAssistant_Male, AIAssistant_Female, Assistant_Male, Assistant_Female.</summary>
    property ImageName: TImageName read FImageName write SetImageName;
    /// <summary>Which engine dictates, and whether the microphone button
    /// appears at all (hveNone hides it). The default is the dictation of Windows,
    /// which works wherever Win+H works; the recognizer reports the text but
    /// needs the online speech consent and a Windows that still transcribes.
    /// Whatever is chosen is what runs: nothing is swapped underneath.</summary>
    property VoiceEngine: THelpChatVoiceEngine read FVoiceEngine write SetVoiceEngine
      default hveSystemDictation;
    /// <summary>Every piece of dictated text, before it reaches the box.</summary>
    property OnVoiceText: TVclHelpChatVoiceTextEvent read FOnVoiceText write FOnVoiceText;
    /// <summary>Online speech recognition is off: handle it your way, or let
    /// the component explain it and open the Windows settings page.</summary>
    property OnVoiceConsentNeeded: TVclHelpChatVoiceConsentEvent
      read FOnVoiceConsentNeeded write FOnVoiceConsentNeeded;
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

    /// <summary>Colour the panel after the active VCL style (and follow style
    /// changes at runtime). Off = the page's own light/dark defaults.</summary>
    property FollowVclStyle: Boolean read FFollowVclStyle write FFollowVclStyle default True;
    /// <summary>Reopen the panel where the user left it (per application, per user).</summary>
    property RememberPanelPosition: Boolean read FRememberPanelPosition write FRememberPanelPosition default True;
    /// <summary>Where the chat is embedded (a side panel, a page...). nil = the
    /// component's own tool window. OnBeforeShowHelp can still change it.
    /// Only a control that can hold other controls is offered at design time.</summary>
    property Container: TWinControl read FContainer write SetContainer;
    /// <summary>Default size of the panel window at 96 dpi; scaled to the DPI of the host monitor.</summary>
    property PanelWidth: Integer read FPanelWidth write FPanelWidth default HELPCHAT_VCL_DEF_PANEL_WIDTH;
    property PanelHeight: Integer read FPanelHeight write FPanelHeight default HELPCHAT_VCL_DEF_PANEL_HEIGHT;
    property OnGetContext: TVclHelpChatContextEvent read FOnGetContext write FOnGetContext;
    property OnGetTheme: TVclHelpChatThemeEvent read FOnGetTheme write FOnGetTheme;
    /// <summary>Decide where the chat goes and show its container (a side
    /// panel, a page); leave AContainer nil for the own window.</summary>
    property OnBeforeShowHelp: TVclHelpChatShowEvent read FOnBeforeShowHelp write FOnBeforeShowHelp;
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
  Vcl.Graphics,
  Vcl.Dialogs,
  Vcl.ComCtrls,
  Vcl.HelpChatAI.Theme,
  HelpChatAI.Panel,            // the page contract: it decides the default name
  HelpChatAI.Server,
  HelpChatAI.Transport.Remote;

function ControlHasHelp(const AControl: TControl): Boolean;
begin
  Result := Assigned(AControl) and
    (((AControl.HelpType = htKeyword) and (AControl.HelpKeyword <> '')) or
     ((AControl.HelpType = htContext) and (AControl.HelpContext <> 0)));
end;

{ TVclHelpChatAIForm }

constructor TVclHelpChatAIForm.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited CreateNew(AOwner, Dummy);
  BorderStyle := bsSizeToolWin;
  BorderIcons := [biSystemMenu];
  Position := poDesigned;
  Width := HELPCHAT_VCL_DEF_PANEL_WIDTH;
  Height := HELPCHAT_VCL_DEF_PANEL_HEIGHT;
  Color := clWindow;
end;

procedure TVclHelpChatAIForm.DoClose(var Action: TCloseAction);
begin
  inherited DoClose(Action);
  Action := caHide; // reused: the chat inside stays warm
  if Assigned(FOnClosedByUser) then
    FOnClosedByUser(Self);
end;

{ TVclHelpChatAI }

constructor TVclHelpChatAI.Create(AOwner: TComponent);
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
  FVoiceEngine := hveSystemDictation;
  FFollowVclStyle := True;
  FRememberPanelPosition := True;
  FPanelWidth := HELPCHAT_VCL_DEF_PANEL_WIDTH;
  FPanelHeight := HELPCHAT_VCL_DEF_PANEL_HEIGHT;
end;

destructor TVclHelpChatAI.Destroy;
begin
  Active := False;
  FreeAndNil(FVoice);
  FActions.OnPending := nil;
  FActions.OnConfirm := nil;
  FActions.OnExecuted := nil;
  FActions := nil;
  FActionsRef := nil; // freed here, unless a queued call still holds it
  FSettings.Free;
  inherited;
end;

procedure TVclHelpChatAI.LoadConfiguration;
begin
  FSettings.LoadConfiguration(FConfigFileName);
end;

procedure TVclHelpChatAI.Loaded;
begin
  inherited Loaded;
  if FStreamedActive and not (csDesigning in ComponentState) then
    SetActive(True);
end;

procedure TVclHelpChatAI.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FHostForm then
      FHostForm := nil;
    if AComponent = FBubble then
      FBubble := nil;
    if AComponent = FImages then
    begin
      FImages := nil;
      ApplyBubbleIcon;
    end;
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

procedure TVclHelpChatAI.SetSettings(const Value: THelpChatSettings);
begin
  FSettings.Assign(Value);
end;

procedure TVclHelpChatAI.SetHostForm(const Value: TCustomForm);
begin
  if Value = FHostForm then
    Exit;
  if Assigned(FHostForm) then
    FHostForm.RemoveFreeNotification(Self);
  DestroyBubble;
  FHostForm := Value;
  if Assigned(FHostForm) then
    FHostForm.FreeNotification(Self);
  if FActive then
    EnsureBubble;
end;

procedure TVclHelpChatAI.SetContainer(const Value: TWinControl);
begin
  if Value = FContainer then
    Exit;
  if Assigned(FContainer) then
    FContainer.RemoveFreeNotification(Self);
  FContainer := Value;
  if Assigned(FContainer) then
    FContainer.FreeNotification(Self);
end;

function TVclHelpChatAI.CreateTransport(const AEngine: THelpChatEngine): IHelpChatTransport;
begin
  // Settings decide where the engine lives: an installed application moves to a
  // server by editing helpchatai.json, with no change to this component.
  if FSettings.Remote.IsConfigured then
    Result := THelpChatRemoteTransport.Create(FSettings.Remote)
  else
    Result := THelpChatLocalServer.Create(AEngine, False);
end;

procedure TVclHelpChatAI.SetActive(const Value: Boolean);
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
    // Before the panel is ever shown: the first page load already carries the
    // name and the icon, so the header never flashes the default ones.
    ApplyAssistant;
    HookApplication;
    if FShowBubble then
      EnsureBubble;
  end
  else
  begin
    FActive := False;
    UnhookApplication;
    DestroyBubble;
    if Assigned(FOwnForm) then
      SavePanelBounds;
    if Assigned(FView) then
    begin
      FView.OnCloseRequested := nil;
      FView.OnStyleChanged := nil;
      FView.OnPageReady := nil;
      FView.OnOpenLink := nil;
      FreeAndNil(FView);
    end;
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

procedure TVclHelpChatAI.HookApplication;
begin
  if not Assigned(FAppEvents) then
  begin
    FAppEvents := TApplicationEvents.Create(Self);
    FAppEvents.OnMessage := AppMessage;
    FAppEvents.OnIdle := AppIdle;
  end;
  if FRegisterHelpViewer and not Assigned(FHelpViewer) then
  begin
    FHelpViewer := THelpChatHelpViewer.Create(Self);
    FHelpViewerIntf := FHelpViewer; // the manager and this reference share the object
    FHelpViewer.Register;
  end;
end;

procedure TVclHelpChatAI.UnhookApplication;
begin
  if Assigned(FHelpViewer) then
  begin
    FHelpViewer.Unregister;
    FHelpViewer := nil;
    FHelpViewerIntf := nil;
  end;
  FreeAndNil(FAppEvents);
end;

function TVclHelpChatAI.IsOurWindow(const AHandle: HWND): Boolean;
begin
  Result := Assigned(FView) and FView.HandleAllocated and
    ((AHandle = FView.Handle) or IsChild(FView.Handle, AHandle));
end;

function TVclHelpChatAI.IsHelpViewerActive: Boolean;
begin
  Result := FActive and FRegisterHelpViewer;
end;

class function TVclHelpChatAI.ActiveControlHasHelp: Boolean;
var
  LControl: TControl;
begin
  LControl := Screen.ActiveControl;
  if LControl = nil then
    LControl := Screen.ActiveCustomForm;
  while Assigned(LControl) do
  begin
    if ControlHasHelp(LControl) then
      Exit(True);
    LControl := LControl.Parent;
  end;
  Result := False;
end;

procedure TVclHelpChatAI.AppMessage(var Msg: tagMSG; var Handled: Boolean);
begin
  // TStyleManager.SetStyle posts CM_CUSTOMSTYLECHANGED to the visible forms: the
  // new theme goes to the transport now, before any form recreates its window
  // and the WebView reloads the page.
  if FActive and (Msg.message = CM_CUSTOMSTYLECHANGED) then
  begin
    ApplyTheme;
    Exit;
  end;
  if not (FActive and FHandleF1) or (Msg.message <> WM_KEYDOWN) or (Msg.wParam <> VK_F1) or
     IsOurWindow(Msg.hwnd) then
    Exit;
  // Auto-repeat of a held key (bit 30 of lParam): never a second request.
  if (Msg.lParam and $40000000) <> 0 then
  begin
    Handled := True;
    Exit;
  end;
  if (GetKeyState(VK_CONTROL) < 0) or (GetKeyState(VK_MENU) < 0) then
    Exit;
  // A control with help: the VCL routes F1 (WM_HELP) to the help system, and
  // the help system to the registered viewer. Only when nobody declares help,
  // which would make F1 do nothing, the chat steps in with the screen context.
  if FRegisterHelpViewer and ActiveControlHasHelp then
    Exit;
  Handled := True;
  OpenForCurrentScreen;
end;

procedure TVclHelpChatAI.AppIdle(Sender: TObject; var Done: Boolean);
begin
  // The main form may not exist yet when the component activates: place the
  // bubble as soon as it does, then stop listening.
  if FActive and FShowBubble and (FBubble = nil) then
    EnsureBubble;
  if Assigned(FBubble) or not FShowBubble then
    FAppEvents.OnIdle := nil;
end;

function TVclHelpChatAI.ResolveHostForm: TCustomForm;
begin
  Result := FHostForm;
  if Result = nil then
    Result := Application.MainForm;
  if (Result = nil) and (Owner is TCustomForm) then
    Result := TCustomForm(Owner);
end;

procedure TVclHelpChatAI.EnsureBubble;
var
  LHost: TCustomForm;
  LSize: Integer;
begin
  if Assigned(FBubble) or not FShowBubble or not FActive then
    Exit;
  LHost := ResolveHostForm;
  if (LHost = nil) or not LHost.HandleAllocated then
    Exit;
  LSize := LHost.ScaleValue(HELPCHAT_VCL_DEF_BUBBLE_SIZE);
  // A windowed control, not a TSpeedButton: a graphic control is painted on
  // the canvas of its parent and always stays below every windowed sibling,
  // so in a real application the bubble ended up hidden behind a grid or a
  // page control. This one has a window and keeps itself on top.
  FBubble := TVclHelpChatAIBubble.Create(Self);
  FBubble.FreeNotification(Self);
  FBubble.Name := '';
  FBubble.Parent := LHost;
  FBubble.SetBounds(LHost.ClientWidth - LSize - LHost.ScaleValue(HELPCHAT_VCL_MARGIN),
    LHost.ClientHeight - LSize - LHost.ScaleValue(HELPCHAT_VCL_MARGIN), LSize, LSize);
  FBubble.Anchors := [akRight, akBottom];
  FBubble.Font.Name := 'Segoe UI';
  FBubble.Hint := HelpChatMsg(hcmUiHelp, FSettings.Language) + ' (F1)';
  FBubble.ShowHint := True;
  FBubble.OnClick := BubbleClick;
  ApplyBubbleIcon;
  FBubble.BringToTop;
end;

procedure TVclHelpChatAI.ApplyBubbleIcon;
begin
  if Assigned(FBubble) then
  begin
    FBubble.Images := FImages;
    FBubble.ImageIndex := FImageIndex;
    FBubble.ImageName := FImageName;
  end;
  // The header of the panel shows the same icon, so it changes with it - also
  // when there is no bubble at all (ShowBubble off).
  ApplyAssistant;
end;

function TVclHelpChatAI.ResolvedCaption: string;
begin
  Result := FCaption.Trim;
  if Result = '' then
    Result := HelpChatMsg(hcmUiHelp, FSettings.Language);
end;

function TVclHelpChatAI.ResolvedAssistantName: string;
begin
  // The same rule the page applies, so the two cannot disagree.
  Result := THelpChatPanel.AssistantNameOf(FAssistantName, FSettings.Language);
end;

function TVclHelpChatAI.AssistantIconDataUri: string;
begin
  Result := HelpChatIconDataUri(FImages, FImageIndex, FImageName);
end;

procedure TVclHelpChatAI.ApplyAssistant;
var
  LName, LIcon: string;

  function JsStr(const AValue: string): string;
  var
    LJson: TJSONString;
  begin
    LJson := TJSONString.Create(AValue);
    try
      Result := LJson.ToJSON;
    finally
      LJson.Free;
    end;
  end;

begin
  if csDesigning in ComponentState then
    Exit;
  if Assigned(FOwnForm) then
    FOwnForm.Caption := ResolvedCaption;
  if not Assigned(FTransport) then
    Exit;
  LName := ResolvedAssistantName;
  LIcon := AssistantIconDataUri;
  FTransport.SetAssistant(LName, LIcon);   // the next page load is rendered with them
  if Assigned(FView) and FView.PageReady then
    FView.RunScript('window.hcSetAssistant && window.hcSetAssistant(' +
      JsStr(LName) + ', ' + JsStr(LIcon) + ');');
end;

procedure TVclHelpChatAI.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;
  FCaption := Value;
  if Assigned(FOwnForm) then
    FOwnForm.Caption := ResolvedCaption;
end;

procedure TVclHelpChatAI.SetAssistantName(const Value: string);
begin
  if FAssistantName = Value then
    Exit;
  FAssistantName := Value;
  ApplyAssistant;
end;

procedure TVclHelpChatAI.SetImages(const Value: TCustomImageList);
begin
  if FImages = Value then
    Exit;
  if Assigned(FImages) then
    FImages.RemoveFreeNotification(Self);
  FImages := Value;
  if Assigned(FImages) then
    FImages.FreeNotification(Self);
  ApplyBubbleIcon;
end;

procedure TVclHelpChatAI.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex = Value then
    Exit;
  FImageIndex := Value;
  ApplyBubbleIcon;
end;

procedure TVclHelpChatAI.SetImageName(const Value: TImageName);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ApplyBubbleIcon;
end;

procedure TVclHelpChatAI.DestroyBubble;
begin
  if Assigned(FBubble) then
  begin
    FBubble.RemoveFreeNotification(Self);
    FreeAndNil(FBubble);
  end;
end;

procedure TVclHelpChatAI.SetShowBubble(const Value: Boolean);
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

procedure TVclHelpChatAI.BubbleClick(Sender: TObject);
begin
  Toggle;
end;

procedure TVclHelpChatAI.EnsureView;
begin
  if Assigned(FView) then
    Exit;
  FView := TVclHelpChatAIPanel.Create(Self);
  FView.FreeNotification(Self);
  FView.Name := '';
  FView.Visible := False;
  FView.OnCloseRequested := ViewCloseRequested;
  FView.OnStyleChanged := ViewStyleChanged;
  FView.OnPageReady := ViewPageReady;
  FView.OnOpenLink := ViewOpenLink;
end;

procedure TVclHelpChatAI.ViewOpenLink(Sender: TObject; const AUrl: string; var AHandled: Boolean);
begin
  if Assigned(FOnOpenLink) then
    FOnOpenLink(Self, AUrl, AHandled);
end;

procedure TVclHelpChatAI.EnsureOwnForm;
begin
  if Assigned(FOwnForm) then
    Exit;
  FOwnForm := TVclHelpChatAIForm.CreateNew(Self);
  FOwnForm.FreeNotification(Self);
  FOwnForm.Caption := ResolvedCaption;
  FOwnForm.OnClosedByUser := OwnFormClosedByUser;
end;

function TVclHelpChatAI.UiStateFile: string;
begin
  Result := TPath.Combine(HelpChatAppDataFolder, HELPCHAT_VCL_UI_STATE_FILENAME);
end;

procedure TVclHelpChatAI.SavePanelBounds;
var
  LRoot, LPanel: TJSONObject;
  LBounds: TRect;
begin
  // Position memory belongs to the own window; an application container is
  // the application's business.
  if not FRememberPanelPosition or not Assigned(FOwnForm) or not FOwnForm.HandleAllocated or
     (FOwnForm.WindowState <> wsNormal) then
    Exit;
  LBounds := FOwnForm.BoundsRect;
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
    LPanel.AddPair('ppi', TJSONNumber.Create(FOwnForm.CurrentPPI));
    try
      TFile.WriteAllText(UiStateFile, LRoot.ToJSON, TEncoding.UTF8);
    except
      // UI state is a convenience: never fail for it.
    end;
  finally
    LRoot.Free;
  end;
end;

function TVclHelpChatAI.LoadPanelBounds(out ABounds: TRect; out APPI: Integer): Boolean;
var
  LValue: TJSONValue;
  LPanel: TJSONObject;
begin
  Result := False;
  ABounds := TRect.Empty;
  APPI := 96;
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
      APPI := LPanel.GetValue<Integer>('ppi', 96);
      Result := (ABounds.Width > 100) and (ABounds.Height > 100);
    end;
  finally
    LValue.Free;
  end;
end;

procedure TVclHelpChatAI.PositionOwnForm;
var
  LHost: TCustomForm;
  LArea, LSaved: TRect;
  LMonitor: TMonitor;
  LLeft, LTop, LWidth, LHeight, LMargin, LPPI, LSavedPPI: Integer;
begin
  // Where the user left it, if that spot is still on a monitor.
  if LoadPanelBounds(LSaved, LSavedPPI) then
  begin
    LMonitor := Screen.MonitorFromRect(LSaved, mdNull);
    if Assigned(LMonitor) then
    begin
      LArea := LMonitor.WorkareaRect;
      LWidth := MulDiv(LSaved.Width, LMonitor.PixelsPerInch, LSavedPPI);
      LHeight := MulDiv(LSaved.Height, LMonitor.PixelsPerInch, LSavedPPI);
      LLeft := LSaved.Left;
      LTop := LSaved.Top;
      if LLeft + LWidth > LArea.Right then
        LLeft := LArea.Right - LWidth;
      if LTop + LHeight > LArea.Bottom then
        LTop := LArea.Bottom - LHeight;
      if LLeft < LArea.Left then
        LLeft := LArea.Left;
      if LTop < LArea.Top then
        LTop := LArea.Top;
      FOwnForm.SetBounds(LLeft, LTop, LWidth, LHeight);
      Exit;
    end;
  end;

  // Default: bottom-right corner of the host form. PanelWidth/PanelHeight are
  // 96-dpi values: a form created at runtime is not scaled by the VCL, so the
  // size is computed for the DPI of the host monitor (Per-Monitor V2).
  LHost := ResolveHostForm;
  if Assigned(LHost) and LHost.HandleAllocated then
    LPPI := LHost.CurrentPPI
  else
    LPPI := Screen.PixelsPerInch;
  LWidth := MulDiv(FPanelWidth, LPPI, 96);
  LHeight := MulDiv(FPanelHeight, LPPI, 96);
  LMargin := MulDiv(HELPCHAT_VCL_MARGIN, LPPI, 96);

  if Assigned(LHost) and LHost.HandleAllocated then
  begin
    FOwnForm.PopupParent := LHost;
    LLeft := LHost.Left + LHost.Width - LWidth - LMargin;
    LTop := LHost.Top + LHost.Height - LHeight - LMargin;
    LArea := Screen.MonitorFromWindow(LHost.Handle).WorkareaRect;
  end
  else
  begin
    LArea := Screen.PrimaryMonitor.WorkareaRect;
    LLeft := LArea.Right - LWidth - LMargin;
    LTop := LArea.Bottom - LHeight - LMargin;
  end;
  if LLeft + LWidth > LArea.Right then
    LLeft := LArea.Right - LWidth;
  if LTop + LHeight > LArea.Bottom then
    LTop := LArea.Bottom - LHeight;
  if LLeft < LArea.Left then
    LLeft := LArea.Left;
  if LTop < LArea.Top then
    LTop := LArea.Top;
  FOwnForm.SetBounds(LLeft, LTop, LWidth, LHeight);
end;

procedure TVclHelpChatAI.OwnFormClosedByUser(Sender: TObject);
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

procedure TVclHelpChatAI.ViewCloseRequested(Sender: TObject);
begin
  Close;
end;


procedure TVclHelpChatAI.SetActionsEnabled(const Value: Boolean);
begin
  FActionsEnabled := Value;
  FActions.Enabled := Value;
end;

procedure TVclHelpChatAI.ActionsPending(Sender: TObject);
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

procedure TVclHelpChatAI.ActionExecuted(Sender: TObject; const AName: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
begin
  if Assigned(FOnActionExecuted) then
    FOnActionExecuted(Self, AName, AOutcome, AResult);
end;

procedure TVclHelpChatAI.ActionConfirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  if Assigned(FOnActionConfirm) then
  begin
    FOnActionConfirm(Self, AName, AArgs, AAllow);
    Exit;
  end;
  // No handler: ask plainly rather than deciding for the user. An application
  // that wants its own wording assigns OnActionConfirm.
  AAllow := MessageDlg(HelpChatMsgFmt(hcmActionConfirm, [AName, AArgs.ToDisplayString],
    FSettings.Language), mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TVclHelpChatAI.UiCommand(const ACommand: string);
begin
  // What the page asked through the server (its buttons, Esc, the microphone).
  if not FActive then
    Exit;
  if ACommand = 'close' then
    Close
  else if ACommand = 'mic-start' then
  begin
    if EnsureVoice then
    begin
      // The recognizer would compile its grammar and then refuse to start:
      // ask for the consent once, and fall back if it stays off.
      // The recognizer needs a consent no application can give: ask once,
      // then let it try and report whatever Windows answers.
      if FVoice.ReportsText and not HelpChatOnlineSpeechAccepted and
         not FVoiceConsentAsked then
      begin
        FVoiceConsentAsked := True;
        AskVoiceConsent;
        Exit;
      end;
      if Assigned(FView) then
        FView.FocusInput;   // the system dictation types where the caret is
      FVoice.Start;
    end;
  end
  else if ACommand = 'mic-stop' then
    StopVoice;
end;

{ --- dictation ----------------------------------------------------------- }

procedure TVclHelpChatAI.HookVoice;
begin
  FVoice.OnText := VoiceText;
  FVoice.OnState := VoiceState;
  FVoice.OnError := VoiceError;
end;

/// <summary>
///  Dictation needs the online speech recognition of Windows, and no
///  application can turn it on for the user: the component says so and opens
///  the page where it is turned on.
/// </summary>
procedure TVclHelpChatAI.AskVoiceConsent;
var
  LHandled: Boolean;
begin
  LHandled := False;
  if Assigned(FOnVoiceConsentNeeded) then
    FOnVoiceConsentNeeded(Self, LHandled);
  if LHandled then
    Exit;
  if MessageDlg(HelpChatMsg(hcmVoiceConsentNeeded, FSettings.Language),
       mtInformation, [mbOK, mbCancel], 0) = mrOk then
    HelpChatOpenSpeechSettings;
end;

function TVclHelpChatAI.EnsureVoice: Boolean;
begin
  if FVoice = nil then
  begin
    FVoice := CreateHelpChatVoiceInput(FVoiceEngine);
    if Assigned(FVoice) then
      HookVoice;
  end;
  Result := Assigned(FVoice) and FVoice.IsAvailable;
end;

procedure TVclHelpChatAI.StopVoice;
begin
  if Assigned(FVoice) and FVoice.Listening then
    FVoice.Stop;
end;

procedure TVclHelpChatAI.SetVoiceEngine(const Value: THelpChatVoiceEngine);
begin
  if FVoiceEngine = Value then
    Exit;
  StopVoice;
  FVoiceEngine := Value;
  FreeAndNil(FVoice);      // the next question builds the engine asked for
  ApplyVoiceButton;
end;

/// <summary>Shows or hides the microphone of the page, with its label.</summary>
procedure TVclHelpChatAI.ApplyVoiceButton;
var
  LJson: TJSONString;
  LEnabled: Boolean;
begin
  if (FView = nil) or not FView.PageReady then
    Exit;
  LEnabled := not (csDesigning in ComponentState) and EnsureVoice;
  LJson := TJSONString.Create(HelpChatMsg(hcmUiMic, FSettings.Language));
  try
    FView.RunScript(Format('window.hcVoiceEnable && window.hcVoiceEnable(%s, %s);',
      [BoolToStr(LEnabled, True).ToLower, LJson.ToJSON]));
  finally
    LJson.Free;
  end;
end;

procedure TVclHelpChatAI.VoiceText(Sender: TObject; const AText: string;
  const AFinal: Boolean);
var
  LText: string;
  LJson: TJSONString;
begin
  LText := AText;
  if Assigned(FOnVoiceText) then
    FOnVoiceText(Self, LText, AFinal);
  if (LText = '') or (FView = nil) or not FView.PageReady then
    Exit;
  LJson := TJSONString.Create(LText);
  try
    FView.RunScript(Format('window.hcVoiceText && window.hcVoiceText(%s, %s);',
      [LJson.ToJSON, BoolToStr(AFinal, True).ToLower]));
  finally
    LJson.Free;
  end;
end;

procedure TVclHelpChatAI.VoiceState(Sender: TObject; const AListening: Boolean);
begin
  if (FView = nil) or not FView.PageReady then
    Exit;
  FView.RunScript(Format('window.hcVoiceState && window.hcVoiceState(%s);',
    [BoolToStr(AListening, True).ToLower]));
  if AListening then
    FView.FocusInput;   // the dictation types where the caret is
end;

procedure TVclHelpChatAI.VoiceError(Sender: TObject; const AMessage: string);
var
  LJson: TJSONString;
  LText: string;
begin
  if (FView = nil) or not FView.PageReady then
    Exit;
  // The engine reports in its own words, or in none: say it in the user's.
  LText := HelpChatMsg(hcmVoiceUnavailable, FSettings.Language);
  LJson := TJSONString.Create(LText);
  try
    FView.RunScript(Format('window.hcSystem && window.hcSystem(%s);', [LJson.ToJSON]));
  finally
    LJson.Free;
  end;
end;

procedure TVclHelpChatAI.ViewStyleChanged(Sender: TObject);
begin
  if not FActive then
    Exit;
  ApplyTheme;
  // Once the style change has fully settled (windows recreated, WebView
  // reinitialized), apply it once more from the message loop.
  TThread.ForceQueue(nil, DeferredApplyTheme);
end;

procedure TVclHelpChatAI.ViewPageReady(Sender: TObject);
begin
  // The page (re)loaded: push the current theme, whatever the load carried.
  if not FActive then
    Exit;
  ApplyTheme;
  ApplyVoiceButton;
  // First load of a panel the user just opened: give it the caret as well.
  if Assigned(FView) and FView.Visible then
    FView.FocusInput;
end;

procedure TVclHelpChatAI.DeferredApplyTheme;
begin
  if FActive and Assigned(FView) then
    ApplyTheme;
end;

function TVclHelpChatAI.BuildTheme: THelpChatTheme;
begin
  if FFollowVclStyle then
    Result := HelpChatThemeFromVclStyle
  else
    Result := Default(THelpChatTheme);
  if Assigned(FOnGetTheme) then
    FOnGetTheme(Self, Result);
end;

procedure TVclHelpChatAI.ApplyTheme;
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

function TVclHelpChatAI.BuildContext: THelpChatContext;
var
  LForm: TCustomForm;
  LControl: TControl;
  LSheet: TTabSheet;
begin
  Result := Default(THelpChatContext);
  LForm := Screen.ActiveCustomForm;
  if (LForm = nil) or (LForm = FOwnForm) then
    LForm := ResolveHostForm;
  if Assigned(LForm) then
  begin
    Result.ScreenName := LForm.Name;
    Result.ScreenLabel := LForm.Caption;
    Result.ScreenType := LForm.ClassName;
  end;

  // Walk up from the focused control: the deepest help keyword/context wins
  // (the form's own help is the fallback), the active tab sheet is the screen.
  LControl := Screen.ActiveControl;
  if Assigned(LControl) and (GetParentForm(LControl) = LForm) then
  begin
    Result.FocusedControl := LControl.Name;
    LSheet := nil;
    while Assigned(LControl) and (LControl <> LForm) do
    begin
      if (LSheet = nil) and (LControl is TTabSheet) then
        LSheet := TTabSheet(LControl);
      if (Result.HelpKeyword = '') and (Result.HelpContext = 0) then
      begin
        if (LControl.HelpType = htKeyword) and (LControl.HelpKeyword <> '') then
          Result.HelpKeyword := LControl.HelpKeyword
        else if (LControl.HelpType = htContext) and (LControl.HelpContext <> 0) then
          Result.HelpContext := LControl.HelpContext;
      end;
      LControl := LControl.Parent;
    end;
    if Assigned(LSheet) and (LSheet.Caption <> '') then
      Result.ScreenLabel := LSheet.Caption;
  end;
  if Assigned(LForm) and (Result.HelpKeyword = '') and (Result.HelpContext = 0) then
  begin
    if (LForm.HelpType = htKeyword) and (LForm.HelpKeyword <> '') then
      Result.HelpKeyword := LForm.HelpKeyword
    else if (LForm.HelpType = htContext) and (LForm.HelpContext <> 0) then
      Result.HelpContext := LForm.HelpContext;
  end;

  if Assigned(FOnGetContext) then
    FOnGetContext(Self, Result);
end;

procedure TVclHelpChatAI.Open;
begin
  OpenWithContext(BuildContext);
end;

procedure TVclHelpChatAI.OpenWithContext(const AContext: THelpChatContext);
var
  LContainer: TWinControl;
  LWasVisible, LReparented: Boolean;
begin
  if not FActive then
    Active := True;
  FTransport.SetContext(AContext);
  EnsureView;
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

  LWasVisible := FView.Visible and (FView.Parent = LContainer) and
    (not (LContainer is TCustomForm) or TCustomForm(LContainer).Visible);
  LReparented := FView.Parent <> LContainer;
  if LReparented then
  begin
    // Reparenting recreates the WebView window: it reloads the page by itself.
    FView.Parent := LContainer;
    FView.Align := alClient;
    if FActiveContainer <> LContainer then
    begin
      if Assigned(FActiveContainer) and (FActiveContainer <> FOwnForm) then
        FActiveContainer.RemoveFreeNotification(Self);
      FActiveContainer := LContainer;
      if FActiveContainer <> FOwnForm then
        FActiveContainer.FreeNotification(Self);
    end;
  end;
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
    FView.FocusInput;   // the page is there: caret straight into the question box
  if not LWasVisible and Assigned(FOnAfterShowHelp) then
    FOnAfterShowHelp(Self);
end;

procedure TVclHelpChatAI.OpenWithQuestion(const AQuestion: string; const ASend: Boolean);
begin
  Open;
  Ask(AQuestion, ASend);
end;

procedure TVclHelpChatAI.Ask(const AQuestion: string; const ASend: Boolean);
var
  LJson: TJSONString;
  LNow: Cardinal;
begin
  // The same question right after the previous one (F1 auto-repeat, a request
  // routed twice) is not sent twice.
  LNow := GetTickCount;
  if ASend and (AQuestion = FLastAskText) and (LNow - FLastAskTick < HELPCHAT_VCL_ASK_DEBOUNCE_MS) then
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

procedure TVclHelpChatAI.OpenDocPage(const APage: string);
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

procedure TVclHelpChatAI.OpenForCurrentScreen;
begin
  OpenForHelp('', 0);
end;

procedure TVclHelpChatAI.OpenForHelp(const AKeyword: string; const AContext: Integer);
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

procedure TVclHelpChatAI.HideView;
begin
  StopVoice;
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

procedure TVclHelpChatAI.Close;
begin
  if IsPanelVisible then
    HideView;
end;

procedure TVclHelpChatAI.Toggle;
begin
  if IsPanelVisible then
    Close
  else
    Open;
end;

function TVclHelpChatAI.IsPanelVisible: Boolean;
begin
  Result := Assigned(FView) and FView.Visible and Assigned(FActiveContainer) and
    ((FActiveContainer <> FOwnForm) or FOwnForm.Visible);
end;

end.
