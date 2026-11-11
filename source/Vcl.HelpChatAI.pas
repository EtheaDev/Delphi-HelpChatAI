{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
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
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  The VCL component. Drop a <see cref="TVclHelpChatAI" /> on a form, set
///  <c>Active</c>, and the application gets a help bubble in the bottom-right
///  corner of that form, the chat as the help system of the application (F1 and
///  <c>Application.HelpKeyword/HelpContext</c> reach it through the standard
///  <c>ICustomHelpViewer</c> / <c>IExtendedHelpViewer</c> registration, like
///  any Delphi help viewer), and the chat panel (<see cref="TVclHelpChatAIPanel" />,
///  a WebView2) shown in the component's own tool window — or, when the
///  application prefers, embedded in any container it provides through
///  <c>Container</c> or <c>OnBeforeShowHelp</c> (a side panel of the main form,
///  like recent Office apps do). The engine and the local HTTP server run
///  in-process; the component builds the screen context, follows the VCL style
///  and confines the browser to the panel origin.
///
///  Several components may be active at once, each an assistant on its own
///  form (<c>Profile</c> says which one: its section of the configuration,
///  its files, its engine). What belongs to the application and not to a
///  form - F1, the help viewer, the style change, the idle turn - lives in
///  one coordinator per process, in the implementation of this unit, which
///  hands each of them to the assistant it belongs to.
///
///  How the component is layered, which is what makes its user interface
///  reusable. The browser control (<c>Vcl.HelpChatAI.Panel</c>) knows a URL
///  and an origin and nothing else. Everything that is of this panel goes
///  through <see cref="IHelpChatTransport" />: the screen context, the theme,
///  the name and the icon, the enabled commands, the actions, the commands
///  of the page and the documents to print - and <c>CreateTransport</c> is
///  virtual. The engine is reached directly only for what the application
///  does from code: <c>THelpChatEngines.Acquire</c>/<c>Release</c> and
///  <c>Start</c> at activation, <c>RunSettings</c> (the settings of the
///  engine), <c>ContextQuestion</c>, <c>ExplainCommand</c>,
///  <c>ClearConversation</c>, <c>Models</c>/<c>SelectModel</c>,
///  <c>SelectLanguage</c> and <c>AttachFile</c>. The component never sees a
///  provider, the runner or the store.
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
  HelpChatAI.Commands,
  HelpChatAI.Engine,
  HelpChatAI.Html,
  HelpChatAI.Pdf,
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
    /// <summary>The user closed the window (it is only hidden): the component
    /// saves where it was and fires its hide events.</summary>
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

  /// <summary>One assistant of the application: the bubble on its host form,
  /// the chat panel in its own window or in a container, the screen context,
  /// the actions of its form. It lives on the form that owns it
  /// (<c>HostForm</c> to say otherwise), and while <c>Active</c> it holds the
  /// engine of its <c>Profile</c> - shared with the other assistants of that
  /// profile - and its own transport. Main thread only; what arrives from
  /// other threads (a command of the page, an action the model calls, a
  /// document to print) is queued to it.</summary>
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
    FActive: Boolean;
    FStreamedActive: Boolean;
    FHandleF1: Boolean;
    FRegisterHelpViewer: Boolean;
    FShowBubble: Boolean;
    FConfigFileName: TFileName;
    FPdfStyleSheet: TFileName;
    FPanelStyleSheet: TFileName;
    FPanelCss: string;
    FPdfHeaderFile: TFileName;
    FPdfFooterFile: TFileName;
    FOnPdfInfo: THelpChatPdfInfoEvent;
    FOnDecryptSecret: THelpChatSecretEvent;
    FCaption: string;
    FAssistantName: string;
    FProfile: string;
    FEnabledCommands: THelpChatCommands;
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
    FUseSharedActions: Boolean;
    FOnActionConfirm: THelpChatActionConfirmEvent;
    FOnActionExecuted: THelpChatActionExecutedEvent;
    FOnBeforeShowHelp: TVclHelpChatShowEvent;
    FOnAfterShowHelp: TNotifyEvent;
    FOnBeforeHideHelp: TNotifyEvent;
    FOnAfterHideHelp: TNotifyEvent;
    FOnOpenLink: THelpChatOpenLinkEvent;
    procedure SetActionsEnabled(const Value: Boolean);
    /// <summary>The broker has a call to run - told on the worker thread that
    /// waits for it: queued to the main thread, with a reference that keeps
    /// the broker alive should the component go first.</summary>
    procedure ActionsPending(Sender: TObject);
    /// <summary>An action that asks first: <c>OnActionConfirm</c> when the
    /// application handles it, else the dialog of
    /// <c>Vcl.HelpChatAI.ConfirmDialog</c>, owned by the host form.</summary>
    procedure ActionConfirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    procedure ActionExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
    /// <summary>Assigns the values; the secret handler and the profile stay
    /// the component's.</summary>
    procedure SetSettings(const Value: THelpChatSettings);
    procedure SetOnDecryptSecret(const Value: THelpChatSecretEvent);
    procedure SetContainer(const Value: TWinControl);
    /// <summary>Activation: reads the configuration (the profile on top of
    /// the root), acquires the engine of the profile and starts it unless it
    /// is remote, creates the transport and gives it what is of this panel
    /// (actions, handlers), joins the coordinator, shows the bubble. A
    /// failure on the way leaves nothing behind. Deactivation undoes it in
    /// the opposite order and releases the engine, which stops only when the
    /// last assistant of the profile lets it go. At design time and while
    /// loading only the flag is kept.</summary>
    procedure SetActive(const Value: Boolean);
    procedure SetShowBubble(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageName(const Value: TImageName);
    procedure SetCaption(const Value: string);
    procedure SetAssistantName(const Value: string);
    procedure SetProfile(const Value: string);
    /// <summary>The name as the application wrote it - the configuration's
    /// first, then the property - unresolved: the page resolves an empty one
    /// in the language it is rendered in.</summary>
    function ConfiguredAssistantName: string;
    /// <summary>The settings in force: the engine's while active - an engine is
    /// shared by the assistants of a profile, and what the user changes in
    /// the panel (the language, the model) changes there - else Settings.</summary>
    function RunSettings: THelpChatSettings;
    procedure SetEnabledCommands(const Value: THelpChatCommands);
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
    /// <summary><c>HostForm</c>, else the form that owns the component -
    /// through a frame if need be - else the main form (a component on a data
    /// module).</summary>
    function ResolveHostForm: TCustomForm;
    /// <summary>Creates the bubble on the host form, once the form has a
    /// window; called again at idle until it does.</summary>
    procedure EnsureBubble;
    procedure DestroyBubble;
    procedure BubbleClick(Sender: TObject);
    /// <summary>Creates the browser control, hidden and with no parent yet:
    /// <c>OpenWithContext</c> decides where it goes.</summary>
    procedure EnsureView;
    /// <summary>Creates the tool window the chat opens in when the
    /// application gives it no container.</summary>
    procedure EnsureOwnForm;
    /// <summary>Where the user left the own window, if that is still on a
    /// monitor, else the bottom-right corner of the host form, sized for the
    /// DPI of its monitor.</summary>
    procedure PositionOwnForm;
    /// <summary>Gives the own window the right owner before showing it: the
    /// active modal form when there is one, the host form otherwise.</summary>
    procedure UpdateOwnFormOwner;
    procedure OwnFormClosedByUser(Sender: TObject);
    procedure ViewCloseRequested(Sender: TObject);
    /// <summary>What the page asked of its host through the server, delivered
    /// here on the main thread: <c>close</c>, the microphone
    /// (<c>mic-start</c>, <c>mic-stop</c>) and the change of language.</summary>
    procedure UiCommand(const ACommand: string);
    /// <summary>The language of the chat changed (from the flag of the page
    /// or from SelectLanguage): the captions this side writes follow it.</summary>
    procedure LanguageChanged;
    /// <summary>A document the engine built (an answer, the conversation, a
    /// page of the manual, or what the <c>export_pdf</c> action wrote) is to
    /// be saved: the stylesheet, the sheet and the bands are put on it here,
    /// the user is asked where it goes, and it is printed with the browser
    /// environment of the panel.</summary>
    procedure PdfRequest(const ADoc: THelpChatPrintableDoc);
    /// <summary>Registers <c>export_pdf</c> among the actions of this
    /// assistant when <c>Settings.Pdf.Action</c> asks for it; removed again at
    /// deactivation.</summary>
    procedure RegisterPdfAction;
    procedure ViewStyleChanged(Sender: TObject);
    /// <summary>The page (re)loaded: the theme, the microphone button and the
    /// caret are given to it again.</summary>
    procedure ViewPageReady(Sender: TObject);
    procedure ViewOpenLink(Sender: TObject; const AUrl: string; var AHandled: Boolean);
    procedure DeferredApplyTheme;
    /// <summary>Hides the chat wherever it is, between
    /// <c>OnBeforeHideHelp</c> and <c>OnAfterHideHelp</c>.</summary>
    procedure HideView;
    /// <summary>The file the own window remembers its place in:
    /// <c>helpchatai-ui.json</c> in the per-user folder, with the profile in
    /// its name so that two assistants do not share one.</summary>
    function UiStateFile: string;
    procedure SavePanelBounds;
    function LoadPanelBounds(out ABounds: TRect; out APPI: Integer): Boolean;
    /// <summary>The one way the panel opens: activates if needed, hands the
    /// context to the transport, decides the container (<c>Container</c>,
    /// then <c>OnBeforeShowHelp</c>, else the own window), parents the
    /// browser there and loads the page - or just gives it the caret when it
    /// is already loaded.</summary>
    procedure OpenWithContext(const AContext: THelpChatContext);
    /// <summary>Puts AQuestion in the question box of the page and sends it
    /// when ASend; the same question within
    /// <c>HELPCHAT_VCL_ASK_DEBOUNCE_MS</c> is not sent twice.</summary>
    procedure Ask(const AQuestion: string; const ASend: Boolean);
  private
    // What the coordinator of the process calls: it owns the one
    // TApplicationEvents and the one help viewer every component shares.
    procedure CoordinatorStyleChanged;
    procedure CoordinatorIdle;
    procedure CoordinatorModalEnd;
    function IsOurWindow(const AHandle: HWND): Boolean;
    /// <summary>True when AForm is where this assistant lives: its host form,
    /// its own window, or the form of the container it is embedded in.</summary>
    function LivesOn(const AForm: TCustomForm): Boolean;
    function TakesF1: Boolean;
    function TakesHelp: Boolean;
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
    /// <summary>The assistant F1 goes to now: the one whose form is active,
    /// else the one whose form was active last; nil when no assistant of
    /// the process takes F1. Several assistants may be active at once, each
    /// on its own form; this is how the application asks which one is in
    /// front of the user.</summary>
    class function CurrentAssistant: TVclHelpChatAI; static;
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
    /// <summary>Runs a slash command in the panel exactly as if the user had
    /// typed it (opening the panel when it is closed), answer included. From
    /// code any command runs, enabled or not: <c>EnabledCommands</c> is what
    /// the user may type. With a remote engine the server decides.</summary>
    procedure ExecuteCommand(const ACommand: THelpChatCommand; const AArgs: string = '');
    /// <summary>The answer of a command as plain text, without the panel:
    /// "Available actions (/actions):" and the list. The commands of the page
    /// (clear, pdf, copy...) answer with what they do; <c>run</c> with its
    /// usage - call <c>Actions</c> to run one. Empty with a remote engine:
    /// the answer lives on the server.</summary>
    function ExplainCommand(const ACommand: THelpChatCommand; const AArgs: string = ''): string;
    /// <summary>Clears the conversation: the ↺ of the panel.</summary>
    procedure ClearConversation;
    /// <summary>The models the panel offers, with the one in use marked.</summary>
    function Models: TArray<THelpChatModelInfo>;
    /// <summary>Makes AName the model in use, like the list of the badge;
    /// False when there is no such model or the engine is remote. The engine
    /// is the profile's: the switch is for every assistant that shares it.</summary>
    function SelectModel(const AName: string): Boolean;
    /// <summary>The languages the flag of the panel offers (<c>Settings.Languages</c>).</summary>
    function Languages: TArray<THelpChatLanguage>;
    /// <summary>The language the chat speaks now, never <c>hclAuto</c>: the
    /// one the user picked in the panel when there is one - it is kept by
    /// the engine, not by <c>Settings</c>.</summary>
    function ActiveLanguage: THelpChatLanguage;
    /// <summary>Makes ALanguage the language of the chat, like the menu of
    /// the flag, and reloads the panel with it; False when the language is
    /// not offered or the engine is remote.</summary>
    function SelectLanguage(const ALanguage: THelpChatLanguage): Boolean;
    /// <summary>Asks the last question again, to AModel when named: /retry.</summary>
    procedure RetryLastQuestion(const AModel: string = '');
    /// <summary>Saves the conversation as PDF, asking where: the PDF button.</summary>
    procedure SaveConversationPdf;
    /// <summary>Copies the last answer to the clipboard: its copy button.</summary>
    procedure CopyLastAnswer;
    /// <summary>Attaches a file to the conversation, like the clip; False with
    /// the reason in AError when it is refused (type, size, attachments off).</summary>
    function AttachFile(const AFileName: string; out AError: string): Boolean;
    /// <summary>Hides the panel (the chat stays loaded, the conversation
    /// stays).</summary>
    procedure Close;
    /// <summary>Opens the panel when it is hidden, hides it when it is shown:
    /// what the bubble does.</summary>
    procedure Toggle;
    /// <summary>True when the chat is shown, in the own window or in a
    /// container.</summary>
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
    /// <summary>The form this assistant lives on: <c>HostForm</c>, else the
    /// form that owns the component, else the main form.</summary>
    function ResolvedHostForm: TCustomForm;

    /// <summary>The engine of the profile of this assistant while
    /// <c>Active</c>, nil otherwise. It is shared with the other assistants of
    /// the same profile and not owned: never free it, and expect
    /// <c>Engine.Settings</c> - not <c>Settings</c> - to carry what the user
    /// changed in the panel. With <c>Settings.Remote</c> it exists but is not
    /// started.</summary>
    property Engine: THelpChatEngine read FEngine;
    /// <summary>What serves the panel of this assistant while <c>Active</c>:
    /// the local server over the engine, or the client of a remote
    /// one.</summary>
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
    /// <summary>Form hosting the bubble and anchoring the panel, and the form
    /// whose activation makes this the assistant F1 goes to. nil = the form
    /// that owns the component (on a frame, the form that owns the frame),
    /// else - for a component on a data module - Application.MainForm. Set it
    /// in code: at design time the form of another unit is not a component
    /// of this one, so there would be nothing to choose from.</summary>
    property HostForm: TCustomForm read FHostForm write SetHostForm;
  published
    /// <summary>The settings of this assistant as the form file has them. At
    /// activation the configuration files are merged on top - their root, then
    /// the section of <c>Profile</c> - and a copy becomes the settings of the
    /// engine: changing a value here while active affects the next
    /// activation.</summary>
    property Settings: THelpChatSettings read FSettings write SetSettings;
    /// <summary>Starts engine, server and hooks. Set at design time, it activates
    /// when the owner form is loaded at runtime.</summary>
    property Active: Boolean read FActive write SetActive default False;
    /// <summary>Answer the help system of the application: F1 on a control
    /// with HelpKeyword/HelpContext, Application.HelpKeyword/HelpContext and
    /// HelpShowTableOfContents open the chat. One viewer is registered for
    /// the whole process, and it hands each request to the assistant of the
    /// form the request comes from (else to the current one); False keeps
    /// this assistant out of it.</summary>
    property RegisterHelpViewer: Boolean read FRegisterHelpViewer write FRegisterHelpViewer default True;
    /// <summary>F1 opens the chat also where no control declares any help (the
    /// VCL would do nothing): a question about the current screen is asked.
    /// With several assistants it goes to the one of the active form, else to
    /// the one whose form was active last; False keeps this one out of it.</summary>
    property HandleF1: Boolean read FHandleF1 write FHandleF1 default True;
    /// <summary>Title of the window the chat opens in when it is not embedded
    /// in a container of yours. Empty (the default) = the localized "Help".</summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>Which assistant this is: the name of its section under
    /// <c>"Profiles"</c> in the configuration, where what this assistant
    /// changes is written (its instructions, its part of the manual, its
    /// models), and part of the name of its conversation, state and window
    /// files. Never shown to the user - that is <c>AssistantName</c> - and
    /// never translated: renaming the assistant must not break the tie with
    /// the file. Empty = the default assistant.</summary>
    property Profile: string read FProfile write SetProfile;
    /// <summary>What the assistant is called, written in the header of the
    /// chat panel next to its icon - and the title of the page itself. Empty
    /// (the default) = the localized "Assistant". It is a name, not a window
    /// title: that is <c>Caption</c>.</summary>
    property AssistantName: string read FAssistantName write SetAssistantName;
    /// <summary>The slash commands the user may type in the question box
    /// (<c>/who</c>, <c>/use</c>, <c>/search</c>...). Everything but
    /// <c>prompt</c> and <c>run</c> by default: those two show the context
    /// of a request and run an action by hand. See <c>HelpChatAI.Commands</c>.</summary>
    property EnabledCommands: THelpChatCommands read FEnabledCommands write SetEnabledCommands
      default HELPCHAT_DEF_COMMANDS;
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
    /// (%APPDATA%\HelpChatAI), the one next to the executable, then the per-user
    /// one of this application - which is where an API key belongs.</summary>
    property ConfigFileName: TFileName read FConfigFileName write FConfigFileName;
    /// <summary>A CSS file of the application, added to the page of the
    /// chat after its own stylesheet - a radius, a spacing, a button hidden;
    /// the colours belong to the theme (<c>OnGetTheme</c>). Empty = none; a
    /// relative path resolves against the executable, and a named file that
    /// is not there stops the activation. Read once, when the component
    /// activates; it reaches <c>OnGetTheme</c> as <c>ATheme.StyleSheet</c>,
    /// which is also where code writes CSS of its own. The classes of the
    /// page (<c>hc-chat-*</c>) are what such a file may rely on.</summary>
    property PanelStyleSheet: TFileName read FPanelStyleSheet write FPanelStyleSheet;
    /// <summary>The stylesheet a saved PDF is laid out with. Empty = the one
    /// built into the library; a relative path resolves against the
    /// executable. It is a property of the component and not a setting
    /// because the look of a document belongs to the application, exactly
    /// like its colours - and because the PDF is written here, on the client,
    /// whatever the engine is.</summary>
    property PdfStyleSheet: TFileName read FPdfStyleSheet write FPdfStyleSheet;
    /// <summary>The band printed at the top of every sheet of a saved PDF,
    /// as an HTML template. Empty = the one built into the library; a
    /// relative path resolves against the executable. Only printed when
    /// <c>Settings.Pdf.HeaderFooter</c> is on. The placeholders are
    /// <c>{app} {version} {user} {title} {date} {time} {extra}</c> and, for
    /// the numbering, <c>{page}</c> and <c>{pages}</c>.</summary>
    property PdfHeaderFile: TFileName read FPdfHeaderFile write FPdfHeaderFile;
    /// <summary>The band printed at the foot of every sheet. See
    /// <see cref="PdfHeaderFile" />.</summary>
    property PdfFooterFile: TFileName read FPdfFooterFile write FPdfFooterFile;
    /// <summary>Fired before a document is printed, with what the library
    /// found out by itself: the name and version in the version information
    /// of the executable, the user Windows is logged on as, the clock. Change
    /// what the application knows better - the user who logged into it is
    /// rarely the user of the machine - and fill <c>Extra</c> for the
    /// <c>{extra}</c> placeholder.</summary>
    property OnPdfInfo: THelpChatPdfInfoEvent read FOnPdfInfo write FOnPdfInfo;
    /// <summary>Turns a secret kept encrypted in the configuration into the
    /// value to use: the API key of the provider
    /// (<c>Claude.ApiKey</c>...) and the credentials of a remote engine
    /// (<c>Remote.AppKey</c>, <c>Remote.UserToken</c>), told apart by
    /// <c>AName</c>. Without a handler nothing changes: the value is used as
    /// the configuration holds it.
    ///
    /// <b>It runs on the worker thread</b> that is about to call the service:
    /// decrypt and return, never show anything. It does not run inside the
    /// IDE either, so the design-time preview of a component whose key is
    /// encrypted will be refused by the service - the configuration check
    /// still passes, because it only asks whether a key is there.
    ///
    /// See <see cref="THelpChatSecretEvent" />, and <c>uAppSecret</c> of the
    /// CRM demo for a worked example.</summary>
    property OnDecryptSecret: THelpChatSecretEvent read FOnDecryptSecret
      write SetOnDecryptSecret;
    /// <summary>Offer the registered actions to the model. False keeps them
    /// registered but invisible: the assistant can only answer.</summary>
    property ActionsEnabled: Boolean read FActionsEnabled write SetActionsEnabled default True;
    /// <summary>Offer also the actions every assistant of the application may
    /// use (<c>HelpChatSharedActions</c>). Read when the component activates.
    /// <c>Settings.AllowedActions</c> narrows both the own and the shared.</summary>
    property UseSharedActions: Boolean read FUseSharedActions write FUseSharedActions default True;
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
    /// <summary>See <c>PanelWidth</c>.</summary>
    property PanelHeight: Integer read FPanelHeight write FPanelHeight default HELPCHAT_VCL_DEF_PANEL_HEIGHT;
    /// <summary>Refines the screen context the component built: the place to
    /// name the screen after the active page, or to add the help keyword of a
    /// form that declares none.</summary>
    property OnGetContext: TVclHelpChatContextEvent read FOnGetContext write FOnGetContext;
    /// <summary>Adjusts the theme before it reaches the page: the colours
    /// derived from the VCL style and the CSS of
    /// <c>PanelStyleSheet</c>.</summary>
    property OnGetTheme: TVclHelpChatThemeEvent read FOnGetTheme write FOnGetTheme;
    /// <summary>Decide where the chat goes and show its container (a side
    /// panel, a page); leave AContainer nil for the own window.</summary>
    property OnBeforeShowHelp: TVclHelpChatShowEvent read FOnBeforeShowHelp write FOnBeforeShowHelp;
    /// <summary>The chat is visible in its container.</summary>
    property OnAfterShowHelp: TNotifyEvent read FOnAfterShowHelp write FOnAfterShowHelp;
    /// <summary>The chat is about to be hidden (✕, Esc, Close): hide your container here.</summary>
    property OnBeforeHideHelp: TNotifyEvent read FOnBeforeHideHelp write FOnBeforeHideHelp;
    /// <summary>The chat has been hidden.</summary>
    property OnAfterHideHelp: TNotifyEvent read FOnAfterHideHelp write FOnAfterHideHelp;
    /// <summary>A link of the panel is leaving it (web site, mail, a page that
    /// is not in DocFolder): set AHandled to open it yourself, else it opens
    /// in the system browser.</summary>
    property OnOpenLink: THelpChatOpenLinkEvent read FOnOpenLink write FOnOpenLink;
  end;

implementation

uses
  HelpChatAI.Attachments,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Dialogs,
  Vcl.ComCtrls,
  Vcl.HelpChatAI.Theme,
  Vcl.HelpChatAI.ConfirmDialog,
  HelpChatAI.Panel,            // the page contract: it decides the default name
  HelpChatAI.Server,
  HelpChatAI.Transport.Remote;

function ControlHasHelp(const AControl: TControl): Boolean;
begin
  Result := Assigned(AControl) and
    (((AControl.HelpType = htKeyword) and (AControl.HelpKeyword <> '')) or
     ((AControl.HelpType = htContext) and (AControl.HelpContext <> 0)));
end;

type
  TVclHelpChatNeed = (hnAny, hnF1, hnHelp);

  /// <summary>
  ///  The application-wide half of every TVclHelpChatAI, one per process.
  ///  F1 and the help system belong to the application, not to a component:
  ///  with one TApplicationEvents and one help viewer per component, two
  ///  assistants answered the same key and the help manager had two viewers
  ///  to choose between. The coordinator keeps the active assistants with the
  ///  most recently active first - the one whose form the user activated last
  ///  - and hands F1, a request of the help system, a style change, an idle
  ///  turn and the end of a modal form to whom they belong.
  /// </summary>
  TVclHelpChatCoordinator = class(TComponent, IHelpChatHelpTarget)
  strict private
    FItems: TList<TVclHelpChatAI>;
    FAppEvents: TApplicationEvents;
    FHelpViewer: THelpChatHelpViewer;
    FHelpViewerIntf: ICustomHelpViewer;
    FLastForm: TCustomForm;
    FDispatching: Integer;
    procedure AppMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    procedure AppModalEnd(Sender: TObject);
    procedure SetLastForm(const AForm: TCustomForm);
    function Accepts(const AItem: TVclHelpChatAI; const ANeed: TVclHelpChatNeed): Boolean;
    function ItemOn(const AForm: TCustomForm; const ANeed: TVclHelpChatNeed): TVclHelpChatAI;
    function FirstItem(const ANeed: TVclHelpChatNeed): TVclHelpChatAI;
    /// <summary>The assistant of the form the user was in last, among the
    /// forms that host one: what answers when the active form hosts none.</summary>
    function MostRecentItem(const ANeed: TVclHelpChatNeed): TVclHelpChatAI;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const AItem: TVclHelpChatAI);
    procedure Remove(const AItem: TVclHelpChatAI);
    function Count: Integer;
    function Dispatching: Boolean;
    /// <summary>Registers the help viewer while some assistant answers the
    /// help system, and only then: the design-time preview runs a component
    /// inside the IDE, and must not leave a viewer in the help manager of the
    /// IDE.</summary>
    procedure UpdateHelpViewer;
    /// <summary>Notices a form that became active: if an assistant lives on
    /// it, that assistant moves to the front.</summary>
    procedure TrackActiveForm;
    /// <summary>The assistant of the active form, else the most recently
    /// active one, among those that take F1.</summary>
    function F1Target: TVclHelpChatAI;
    /// <summary>The assistant of the form of the focused control - where a
    /// help keyword comes from - else the most recently active one, among
    /// those that answer the help system.</summary>
    function HelpTarget: TVclHelpChatAI;
    // IHelpChatHelpTarget: the one viewer of the process asks here.
    function IsHelpViewerActive: Boolean;
    procedure Open;
    procedure OpenForHelp(const AKeyword: string; const AContext: Integer);
    procedure Close;
  end;

var
  GCoordinator: TVclHelpChatCoordinator;
  GCoordinatorOrphaned: Boolean;

procedure CoordinatorAdd(const AItem: TVclHelpChatAI);
begin
  if GCoordinator = nil then
    GCoordinator := TVclHelpChatCoordinator.Create(nil);
  GCoordinatorOrphaned := False;
  GCoordinator.Add(AItem);
end;

procedure CoordinatorRemove(const AItem: TVclHelpChatAI);
begin
  if GCoordinator = nil then
    Exit;
  GCoordinator.Remove(AItem);
  if GCoordinator.Count = 0 then
  begin
    // Never free the TApplicationEvents from inside its own handler: the
    // coordinator goes when the dispatch is over.
    if GCoordinator.Dispatching then
      GCoordinatorOrphaned := True
    else
      FreeAndNil(GCoordinator);
  end;
end;

{ TVclHelpChatCoordinator }

constructor TVclHelpChatCoordinator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList<TVclHelpChatAI>.Create;
  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnMessage := AppMessage;
  FAppEvents.OnIdle := AppIdle;
  FAppEvents.OnModalEnd := AppModalEnd;
end;

destructor TVclHelpChatCoordinator.Destroy;
begin
  if Assigned(FHelpViewer) then
  begin
    FHelpViewer.Unregister;
    FHelpViewer := nil;
    FHelpViewerIntf := nil;
  end;
  SetLastForm(nil);
  FreeAndNil(FAppEvents);
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TVclHelpChatCoordinator.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FLastForm) then
    FLastForm := nil;
end;

procedure TVclHelpChatCoordinator.SetLastForm(const AForm: TCustomForm);
begin
  if AForm = FLastForm then
    Exit;
  if Assigned(FLastForm) then
    FLastForm.RemoveFreeNotification(Self);
  FLastForm := AForm;
  if Assigned(FLastForm) then
    FLastForm.FreeNotification(Self);
end;

procedure TVclHelpChatCoordinator.Add(const AItem: TVclHelpChatAI);
begin
  if FItems.IndexOf(AItem) < 0 then
    FItems.Add(AItem);
  // Activated on the form the user is in (a form that creates its assistant
  // when it opens): it is the current one from the start.
  if AItem.LivesOn(Screen.ActiveCustomForm) then
    FItems.Move(FItems.IndexOf(AItem), 0);
  UpdateHelpViewer;
end;

procedure TVclHelpChatCoordinator.Remove(const AItem: TVclHelpChatAI);
begin
  FItems.Remove(AItem);
  UpdateHelpViewer;
end;

function TVclHelpChatCoordinator.Count: Integer;
begin
  Result := FItems.Count;
end;

function TVclHelpChatCoordinator.Dispatching: Boolean;
begin
  Result := FDispatching > 0;
end;

procedure TVclHelpChatCoordinator.UpdateHelpViewer;
begin
  if Assigned(FirstItem(hnHelp)) then
  begin
    if not Assigned(FHelpViewer) then
    begin
      FHelpViewer := THelpChatHelpViewer.Create(Self);
      FHelpViewerIntf := FHelpViewer; // the manager and this reference share the object
      FHelpViewer.Register;
    end;
  end
  else if Assigned(FHelpViewer) then
  begin
    FHelpViewer.Unregister;
    FHelpViewer := nil;
    FHelpViewerIntf := nil;
  end;
end;

function TVclHelpChatCoordinator.Accepts(const AItem: TVclHelpChatAI;
  const ANeed: TVclHelpChatNeed): Boolean;
begin
  case ANeed of
    hnF1: Result := AItem.TakesF1;
    hnHelp: Result := AItem.TakesHelp;
  else
    Result := True;
  end;
end;

function TVclHelpChatCoordinator.ItemOn(const AForm: TCustomForm;
  const ANeed: TVclHelpChatNeed): TVclHelpChatAI;
var
  LItem: TVclHelpChatAI;
begin
  if Assigned(AForm) then
    for LItem in FItems do
      if Accepts(LItem, ANeed) and LItem.LivesOn(AForm) then
        Exit(LItem);
  Result := nil;
end;

function TVclHelpChatCoordinator.FirstItem(const ANeed: TVclHelpChatNeed): TVclHelpChatAI;
var
  LItem: TVclHelpChatAI;
begin
  for LItem in FItems do
    if Accepts(LItem, ANeed) then
      Exit(LItem);
  Result := nil;
end;

function TVclHelpChatCoordinator.MostRecentItem(const ANeed: TVclHelpChatNeed): TVclHelpChatAI;
var
  I: Integer;
begin
  // The VCL keeps Screen.CustomForms with the form that took the focus last
  // first (TCustomForm.SetFocusedControl), and it does so while the focus
  // moves, not at the next message. The list of this coordinator is updated
  // by TrackActiveForm, which only runs when a message is dispatched or the
  // application is idle: two forms activated by code one after the other,
  // with nothing posted in between, and the first activation was never seen
  // - the assistant of the form before it answered. So the order of the
  // screen is asked first, and the tracked order is the fallback for an
  // assistant that lives on no form of that list.
  for I := 0 to Screen.CustomFormCount - 1 do
  begin
    Result := ItemOn(Screen.CustomForms[I], ANeed);
    if Assigned(Result) then
      Exit;
  end;
  Result := FirstItem(ANeed);
end;

procedure TVclHelpChatCoordinator.TrackActiveForm;
var
  LForm: TCustomForm;
  LItem: TVclHelpChatAI;
begin
  LForm := Screen.ActiveCustomForm;
  if LForm = FLastForm then
    Exit;
  SetLastForm(LForm);
  // A form that hosts no assistant changes nothing: F1 there goes to the
  // assistant of the form the user came from.
  LItem := ItemOn(LForm, hnAny);
  if Assigned(LItem) and (FItems.IndexOf(LItem) > 0) then
    FItems.Move(FItems.IndexOf(LItem), 0);
end;

function TVclHelpChatCoordinator.F1Target: TVclHelpChatAI;
begin
  TrackActiveForm;
  Result := ItemOn(Screen.ActiveCustomForm, hnF1);
  if Result = nil then
    Result := MostRecentItem(hnF1);
end;

function TVclHelpChatCoordinator.HelpTarget: TVclHelpChatAI;
var
  LForm: TCustomForm;
begin
  TrackActiveForm;
  if Assigned(Screen.ActiveControl) then
    LForm := GetParentForm(Screen.ActiveControl)
  else
    LForm := Screen.ActiveCustomForm;
  Result := ItemOn(LForm, hnHelp);
  if Result = nil then
    Result := MostRecentItem(hnHelp);
end;

procedure TVclHelpChatCoordinator.AppMessage(var Msg: tagMSG; var Handled: Boolean);
var
  LItem, LTarget: TVclHelpChatAI;
begin
  Inc(FDispatching);
  try
    if Msg.message = CM_CUSTOMSTYLECHANGED then
    begin
      for LItem in FItems.ToArray do
        LItem.CoordinatorStyleChanged;
      Exit;
    end;
    // A pointer comparison per message: the activation of a form (shown by
    // code, clicked, Alt+Tab) is noticed before any key reaches it.
    TrackActiveForm;
    if (Msg.message <> WM_KEYDOWN) or (Msg.wParam <> VK_F1) then
      Exit;
    for LItem in FItems do
      if LItem.IsOurWindow(Msg.hwnd) then
        Exit; // F1 inside a chat panel is the panel's
    LTarget := F1Target;
    if LTarget = nil then
      Exit;
    // Auto-repeat of a held key (bit 30 of lParam): never a second request.
    if (Msg.lParam and $40000000) <> 0 then
    begin
      Handled := True;
      Exit;
    end;
    if (GetKeyState(VK_CONTROL) < 0) or (GetKeyState(VK_MENU) < 0) then
      Exit;
    // A control with help: the VCL routes F1 (WM_HELP) to the help system,
    // and the help system to the viewer. Only when nobody declares help,
    // which would make F1 do nothing, the chat steps in with the screen.
    if (HelpTarget <> nil) and TVclHelpChatAI.ActiveControlHasHelp then
      Exit;
    Handled := True;
    LTarget.OpenForCurrentScreen;
  finally
    Dec(FDispatching);
  end;
end;

procedure TVclHelpChatCoordinator.AppIdle(Sender: TObject; var Done: Boolean);
var
  LItem: TVclHelpChatAI;
begin
  // The last assistant went away while a message was being dispatched: the
  // coordinator could not free itself then, it can now.
  if GCoordinatorOrphaned and (FItems.Count = 0) then
  begin
    GCoordinatorOrphaned := False;
    GCoordinator := nil;
    TThread.ForceQueue(nil,
      procedure
      begin
        Free;
      end);
    Exit;
  end;
  TrackActiveForm;
  for LItem in FItems.ToArray do
    LItem.CoordinatorIdle;
end;

procedure TVclHelpChatCoordinator.AppModalEnd(Sender: TObject);
var
  LItem: TVclHelpChatAI;
begin
  for LItem in FItems.ToArray do
    LItem.CoordinatorModalEnd;
end;

function TVclHelpChatCoordinator.IsHelpViewerActive: Boolean;
begin
  Result := HelpTarget <> nil;
end;

procedure TVclHelpChatCoordinator.Open;
var
  LTarget: TVclHelpChatAI;
begin
  LTarget := HelpTarget;
  if Assigned(LTarget) then
    LTarget.Open;
end;

procedure TVclHelpChatCoordinator.OpenForHelp(const AKeyword: string; const AContext: Integer);
var
  LTarget: TVclHelpChatAI;
begin
  LTarget := HelpTarget;
  if Assigned(LTarget) then
    LTarget.OpenForHelp(AKeyword, AContext);
end;

procedure TVclHelpChatCoordinator.Close;
var
  LItem: TVclHelpChatAI;
begin
  for LItem in FItems.ToArray do
    LItem.Close;
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
  FUseSharedActions := True;
  FHandleF1 := True;
  FEnabledCommands := HELPCHAT_DEF_COMMANDS;
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
  // Assign brought the handler and the profile of the settings that were
  // assigned, which are not ours: the component keeps the last word on who
  // decrypts its secrets and on which assistant it is.
  FSettings.SetSecretHandler(FOnDecryptSecret, Self);
  FSettings.Profile := FProfile;
end;

procedure TVclHelpChatAI.SetProfile(const Value: string);
begin
  FProfile := Trim(Value);
  FSettings.Profile := FProfile;
end;

function TVclHelpChatAI.RunSettings: THelpChatSettings;
begin
  if Assigned(FEngine) then
    Result := FEngine.Settings
  else
    Result := FSettings;
end;

function TVclHelpChatAI.ConfiguredAssistantName: string;
begin
  Result := Trim(FSettings.AssistantName);
  if Result = '' then
    Result := Trim(FAssistantName);
end;

procedure TVclHelpChatAI.SetOnDecryptSecret(const Value: THelpChatSecretEvent);
begin
  FOnDecryptSecret := Value;
  FSettings.SetSecretHandler(Value, Self);
end;

procedure TVclHelpChatAI.SetHostForm(const Value: TCustomForm);
begin
  if Value = FHostForm then
    Exit;
  // The notification asked of the old form is left there: it is not
  // counted, and Container may be the same object. One too many costs
  // nothing.
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
  FContainer := Value;
  if Assigned(FContainer) then
    FContainer.FreeNotification(Self);
end;

function TVclHelpChatAI.CreateTransport(const AEngine: THelpChatEngine): IHelpChatTransport;
begin
  // Settings decide where the engine lives: an installed application moves to a
  // server by editing helpchatai.json, with no change to this component.
  if FSettings.Remote.IsConfigured then
    Result := THelpChatRemoteTransport.Create(FSettings.Remote, FSettings.Profile)
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
    FPanelCss := THelpChatPanel.PanelCss(FPanelStyleSheet);
    // The engine of the profile: shared with the other assistants that name
    // it, created by the first. What this one may do goes with its questions.
    FEngine := THelpChatEngines.Acquire(Self, FSettings);
    try
      // With a remote server the local engine stays idle: no documentation index
      // loaded, no worker pool, no model key in this process.
      if not FSettings.Remote.IsConfigured then
        FEngine.Start;
      // The language of the engine, not the one this component was configured
      // with: an engine another assistant of the profile started already may
      // carry the language the user picked in its panel.
      HelpChatDefaultLanguage := RunSettings.ResolveLanguage;
      FTransport := CreateTransport(FEngine);
      // What this assistant may do: its own actions, the application's shared
      // ones unless it opted out, and what its profile allows of them.
      if FUseSharedActions then
        FActions.Shared := HelpChatSharedActions
      else
        FActions.Shared := nil;
      FActions.Allowed := FSettings.ResolveAllowedActions;
      FActions.HostActive := True;
      FTransport.SetActions(FActionsRef);
      FTransport.SetOnUiCommand(UiCommand);
      FTransport.SetOnPdfRequest(PdfRequest);
      RegisterPdfAction;
      FTransport.Start;
    except
      // An engine that will not start or a server that will not answer must
      // not leave half a component behind - above all not a holder of the
      // shared engine that nobody will ever release.
      FActions.HostActive := False;
      FActions.Remove(HELPCHAT_PDF_ACTION);
      FTransport := nil;
      THelpChatEngines.Release(Self, FEngine);
      raise;
    end;
    FActive := True;
    // Before the panel is ever shown: the first page load already carries the
    // name and the icon, so the header never flashes the default ones.
    ApplyAssistant;
    CoordinatorAdd(Self);
    if FShowBubble then
      EnsureBubble;
  end
  else
  begin
    FActive := False;
    CoordinatorRemove(Self);
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
    // The engine may go on without this assistant (another one of the same
    // profile holds it), and with it a reply this panel asked for: an action
    // it calls from now on is answered "cancelled" instead of running on a
    // form that is going away, or waiting for it.
    FActions.HostActive := False;
    if Assigned(FTransport) then
    begin
      FTransport.SetOnUiCommand(nil);
      FTransport.SetOnPdfRequest(nil);
      // Ours, so ours to take away: what the application registered stays.
      if Assigned(FActions) then
        FActions.Remove(HELPCHAT_PDF_ACTION);
      FTransport.Stop;
      FTransport := nil;
    end;
    // The last assistant of the profile frees it: that stops the workers
    // (bounded wait) and persists the conversation.
    THelpChatEngines.Release(Self, FEngine);
  end;
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

function TVclHelpChatAI.TakesF1: Boolean;
begin
  Result := FActive and FHandleF1;
end;

function TVclHelpChatAI.TakesHelp: Boolean;
begin
  Result := FActive and FRegisterHelpViewer;
end;

function TVclHelpChatAI.ResolvedHostForm: TCustomForm;
begin
  Result := ResolveHostForm;
end;

function TVclHelpChatAI.LivesOn(const AForm: TCustomForm): Boolean;
begin
  Result := Assigned(AForm) and ((AForm = ResolveHostForm) or (AForm = FOwnForm) or
    (Assigned(FActiveContainer) and (FActiveContainer <> FOwnForm) and
     (GetParentForm(FActiveContainer) = AForm)));
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

class function TVclHelpChatAI.CurrentAssistant: TVclHelpChatAI;
begin
  if Assigned(GCoordinator) then
    Result := GCoordinator.F1Target
  else
    Result := nil;
end;

procedure TVclHelpChatAI.CoordinatorStyleChanged;
begin
  // TStyleManager.SetStyle posts CM_CUSTOMSTYLECHANGED to the visible forms: the
  // new theme goes to the transport now, before any form recreates its window
  // and the WebView reloads the page.
  if FActive then
    ApplyTheme;
end;

procedure TVclHelpChatAI.CoordinatorModalEnd;
begin
  // A modal form is going away. If the chat window is owned by it - which is
  // what UpdateOwnFormOwner did to keep it in front - it has to be handed
  // back now: Windows destroys the windows a window owns together with it,
  // and the chat would disappear with the form the user just closed.
  // ModalFinished runs inside ShowModal, so the form is still alive; what it
  // no longer has is fsModal, which ShowModal clears one line earlier - so
  // the question to ask is simply whether the owner is still the host.
  if Assigned(FOwnForm) and (FOwnForm.PopupParent <> ResolveHostForm) then
    FOwnForm.PopupParent := ResolveHostForm;
end;

procedure TVclHelpChatAI.CoordinatorIdle;
begin
  // The host form may not have a window yet when the component activates:
  // place the bubble as soon as it does.
  if FActive and FShowBubble and (FBubble = nil) then
    EnsureBubble;
end;

function TVclHelpChatAI.ResolveHostForm: TCustomForm;
var
  LOwner: TComponent;
begin
  Result := FHostForm;
  if Assigned(Result) then
    Exit;
  // The form the component was dropped on, through a frame if need be: an
  // assistant on an order form lives on the order form, not on the main one.
  LOwner := Owner;
  while Assigned(LOwner) do
  begin
    if LOwner is TCustomForm then
      Exit(TCustomForm(LOwner));
    LOwner := LOwner.Owner;
  end;
  Result := Application.MainForm;
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
  FBubble.Hint := HelpChatMsg(hcmUiHelp, ActiveLanguage) + ' (F1)';
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
    Result := HelpChatMsg(hcmUiHelp, ActiveLanguage);
end;

function TVclHelpChatAI.ResolvedAssistantName: string;
begin
  // The same rule the page applies, so the two cannot disagree.
  Result := THelpChatPanel.AssistantNameOf(ConfiguredAssistantName, ActiveLanguage);
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
  // The name as the application wrote it, empty included: the page resolves
  // an empty one in the language it is rendered in, which the user may change
  // from the panel itself.
  FTransport.SetAssistant(ConfiguredAssistantName, LIcon);   // the next page load is rendered with them
  FTransport.SetEnabledCommands(FEnabledCommands);
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

procedure TVclHelpChatAI.SetEnabledCommands(const Value: THelpChatCommands);
begin
  if FEnabledCommands = Value then
    Exit;
  FEnabledCommands := Value;
  if (csDesigning in ComponentState) or not Assigned(FTransport) then
    Exit;
  FTransport.SetEnabledCommands(FEnabledCommands);
  if Assigned(FView) and FView.PageReady then
    FView.RunScript('window.hcRefreshCommands && window.hcRefreshCommands();');
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
  Result := FSettings.ProfileFileName(TPath.Combine(HelpChatAppDataFolder, HELPCHAT_VCL_UI_STATE_FILENAME));
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

procedure TVclHelpChatAI.UpdateOwnFormOwner;
var
  LActive, LOwner: TCustomForm;
begin
  // Windows keeps a modal window above every window that shares its owner,
  // and the VCL disables the other windows of the application while one is
  // up (DisableTaskWindows). A chat window owned by the host form therefore
  // ends up behind the modal one, and disabled with it - which is not what
  // the user asked for when they pressed F1 from that very form.
  // Owned by the modal form instead, it stays above it and can be used.
  LActive := Screen.ActiveCustomForm;
  if Assigned(LActive) and (LActive <> FOwnForm) and (fsModal in LActive.FormState) then
    LOwner := LActive
  else
    LOwner := ResolveHostForm;      // no modal form: back to the host

  // Changing PopupParent recreates the window, and with it the WebView, which
  // reloads the page: only when it really changes.
  if (LOwner <> nil) and not LOwner.HandleAllocated then
    LOwner := nil;
  if FOwnForm.PopupParent <> LOwner then
    FOwnForm.PopupParent := LOwner;

  // The window may have been disabled by the modal form that opened after it.
  if FOwnForm.HandleAllocated and not IsWindowEnabled(FOwnForm.Handle) then
    EnableWindow(FOwnForm.Handle, True);
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
var
  LRequest: TVclHelpChatConfirmRequest;
begin
  if Assigned(FOnActionConfirm) then
  begin
    FOnActionConfirm(Self, AName, AArgs, AAllow);
    Exit;
  end;
  // No handler: ask plainly rather than deciding for the user, with the
  // dialog registered in Vcl.HelpChatAI.ConfirmDialog (the one of the
  // library unless the application registered its own): the name of the
  // action as the instruction, what the application wrote (the description),
  // what the model wrote (the values, labelled with the description of their
  // parameter, cut short) and a footer saying who wrote them. An application
  // that wants its own wording assigns OnActionConfirm, or registers a form.
  LRequest := Default(TVclHelpChatConfirmRequest);
  LRequest.Host := ResolveHostForm;
  LRequest.Asker := Self;
  LRequest.Language := ActiveLanguage;
  LRequest.ActionName := AName;
  LRequest.Action := FActions.Find(AName);
  LRequest.Args := AArgs;
  LRequest.Caption := ResolvedAssistantName;
  LRequest.Title := HelpChatMsgFmt(hcmActionConfirmTitle, [AName], LRequest.Language);
  if Assigned(LRequest.Action) then
    LRequest.Description := LRequest.Action.Description;
  LRequest.Values := AArgs.ToDisplayPairs(LRequest.Action);
  if Length(LRequest.Values) > 0 then
    LRequest.Footer := HelpChatMsg(hcmActionValuesFooter, LRequest.Language);
  LRequest.TimeoutMs := HELPCHAT_CONFIRM_TIMEOUT_MS;
  AAllow := HelpChatVclConfirmAction(LRequest);
end;

procedure TVclHelpChatAI.RegisterPdfAction;
begin
  // The assistant may write a document and hand it over. Off by default: it
  // is one more tool in every request, and an answer that becomes a file
  // without anybody asking for one.
  if not (RunSettings.Pdf.Enabled and RunSettings.Pdf.Action) then
    Exit;
  FActions.Add(HELPCHAT_PDF_ACTION,
    'Saves a document you have written as a PDF file on the computer of the ' +
    'user. Use it when the user asks for a document, a report, a summary or a ' +
    'PDF - not for an ordinary answer. Write the whole document in Markdown: ' +
    'headings, lists and tables are laid out. The user is asked where to save ' +
    'it and may say no.',
    [THelpChatActionParam.Create('title',
       'Title of the document. It is also what the save dialog offers as the file name.'),
     THelpChatActionParam.Create('markdown',
       'The document itself, in Markdown, complete.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LDoc: THelpChatPrintableDoc;
    begin
      LDoc := HelpChatMarkdownDocument(AArgs.AsString('title'),
        AArgs.AsString('markdown'), '');
      LDoc.LangCode := HelpChatLanguageCode(ActiveLanguage);
      // An action handler must return at once - a worker is waiting for it -
      // and a save dialog waits for a human. So the model is answered now and
      // the dialog opens next time round the message loop.
      TThread.ForceQueue(nil,
        procedure
        begin
          PdfRequest(LDoc);
        end);
      AResult := HelpChatMsg(hcmPdfHandedOver, ActiveLanguage);
    end, False); // the save dialog is the confirmation, and the user may cancel it
end;

/// <summary>Fills the file types of a Vista dialog from the classic
/// "name|mask" filter the messages carry: one localized string serves both
/// kinds of dialog, and nothing else in the library has to know which one
/// is in use.</summary>
procedure HelpChatFileTypes(const AItems: TFileTypeItems; const AFilter: string);
var
  LParts: TArray<string>;
  LItem: TFileTypeItem;
  I: Integer;
begin
  AItems.Clear;
  LParts := AFilter.Split(['|']);
  I := 0;
  while I < High(LParts) do
  begin
    LItem := AItems.Add;
    LItem.DisplayName := LParts[I];
    LItem.FileMask := LParts[I + 1];
    Inc(I, 2);
  end;
  if AItems.Count = 0 then
  begin
    LItem := AItems.Add;
    LItem.DisplayName := AFilter;
    LItem.FileMask := '*.*';
  end;
end;

procedure TVclHelpChatAI.PdfRequest(const ADoc: THelpChatPrintableDoc);
var
  LDoc: THelpChatPrintableDoc;
  LPage: THelpChatPdfPage;
  LInfo: THelpChatPdfInfo;
  LDialog: TFileSaveDialog;
  LExporter: THelpChatPdfExporter;
  LEnvironment: IInterface;
  LFileName, LError: string;
begin
  // On the main thread: the engine built the document, the stylesheet and the
  // sheet of paper are ours, and so is asking the user where it goes.
  if not FActive then
    Exit;
  if not THelpChatPdfExporter.IsAvailable then
  begin
    MessageDlg(HelpChatMsg(hcmPdfUnavailable, ActiveLanguage), mtError, [mbOK], 0);
    Exit;
  end;
  LDoc := ADoc;
  try
    LDoc.Css := THelpChatPanel.PrintCss(FPdfStyleSheet);
  except
    on E: Exception do
    begin
      MessageDlg(HelpChatMsgFmt(hcmPdfFailed, [E.Message], ActiveLanguage),
        mtError, [mbOK], 0);
      Exit;
    end;
  end;
  // The dialog of Windows, not the one of Windows 95: IFileSaveDialog brings
  // the places bar, the favourites and the search box the user knows. It needs
  // Vista, which costs nothing here - what writes the PDF is WebView2, and
  // that asks for Windows 10.
  LDialog := TFileSaveDialog.Create(nil);
  try
    HelpChatFileTypes(LDialog.FileTypes,
      HelpChatMsg(hcmPdfFilter, ActiveLanguage));
    LDialog.DefaultExtension := 'pdf';
    LDialog.FileName := HelpChatPdfFileName(LDoc.Title);
    LDialog.Options := [fdoOverWritePrompt, fdoPathMustExist, fdoForceFileSystem,
      fdoNoReadOnlyReturn];
    if not LDialog.Execute then
      Exit;
    LFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
  // The bands, when they were asked for. They are built here and not in the
  // engine because they say what the application is, and only the client
  // knows that.
  LPage := RunSettings.Pdf.Page(LDoc.Title);
  if RunSettings.Pdf.HeaderFooter then
  begin
    LInfo := HelpChatPdfDefaultInfo;
    LInfo.Title := LDoc.Title;
    if Assigned(FOnPdfInfo) then
      FOnPdfInfo(Self, LInfo);
    // A band file that was named and is not there is said, like the
    // stylesheet above, not raised out of a click on "save as PDF".
    try
      LPage.HeaderHtml := HelpChatPdfExpand(THelpChatPanel.PrintHeader(FPdfHeaderFile), LInfo);
      LPage.FooterHtml := HelpChatPdfExpand(THelpChatPanel.PrintFooter(FPdfFooterFile), LInfo);
    except
      on E: Exception do
      begin
        MessageDlg(HelpChatMsgFmt(hcmPdfFailed, [E.Message], ActiveLanguage),
          mtError, [mbOK], 0);
        Exit;
      end;
    end;
  end;
  // The browser of the panel already has an environment: taking it is what
  // keeps a second browser process from starting for one page of paper.
  LEnvironment := nil;
  if Assigned(FView) and Assigned(FView.Browser) then
    LEnvironment := FView.Browser.EnvironmentInterface;
  LExporter := THelpChatPdfExporter.Create(LEnvironment);
  try
    if LExporter.ExportHtml(LDoc.Render, LFileName, LPage, LError) then
    begin
      // The document is there and is right: the bands are the only thing
      // missing, so it is said once and the file is still offered.
      if LExporter.BandsDropped then
        MessageDlg(HelpChatMsgFmt(hcmPdfNoBands, [ExtractFileName(LFileName)],
          ActiveLanguage), mtWarning, [mbOK], 0);
      if MessageDlg(HelpChatMsgFmt(hcmPdfOpen, [ExtractFileName(LFileName)],
           ActiveLanguage), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        HelpChatOpenDocument(LFileName);
    end
    else
      MessageDlg(HelpChatMsgFmt(hcmPdfFailed, [LError], ActiveLanguage),
        mtError, [mbOK], 0);
  finally
    LExporter.Free;
  end;
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
    StopVoice
  else if ACommand = HELPCHAT_UI_LANGUAGE then
    LanguageChanged;
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
  if MessageDlg(HelpChatMsg(hcmVoiceConsentNeeded, ActiveLanguage),
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
  LJson := TJSONString.Create(HelpChatMsg(hcmUiMic, ActiveLanguage));
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
  LText := HelpChatMsg(hcmVoiceUnavailable, ActiveLanguage);
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
  Result.StyleSheet := FPanelCss;
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
  LPanelUrl: string;
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
      FActiveContainer := LContainer;
      if FActiveContainer <> FOwnForm then
        FActiveContainer.FreeNotification(Self);
    end;
  end;
  FView.Visible := True;
  FView.BringToFront;

  if LContainer = FOwnForm then
  begin
    UpdateOwnFormOwner;
    if not FOwnForm.Visible then
      PositionOwnForm;
    FOwnForm.Show;
    FOwnForm.BringToFront;
  end;

  // Asked every time, not only for the first page: a remote transport
  // answers another URL when the server had expired the session and a new
  // one was opened - the page loaded with the old token would be refused
  // at every request.
  LPanelUrl := FTransport.GetPanelUrl;
  if not FView.PageReady or (FView.PanelUrl <> LPanelUrl) then
    FView.OpenUrl(LPanelUrl, FTransport.GetPanelOrigin)
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

procedure TVclHelpChatAI.ExecuteCommand(const ACommand: THelpChatCommand; const AArgs: string);
var
  LLine: TJSONString;
begin
  Open;
  if not Assigned(FView) then
    Exit;
  LLine := TJSONString.Create(Trim('/' + HelpChatCommandName(ACommand) + ' ' + AArgs));
  try
    // Queued by the view until the page is ready, like a question.
    FView.RunScript(Format('window.hcCommand && window.hcCommand(%s, true);', [LLine.ToJSON]));
  finally
    LLine.Free;
  end;
end;

function TVclHelpChatAI.ExplainCommand(const ACommand: THelpChatCommand; const AArgs: string): string;
var
  LRequest: THelpChatCommandRequest;
begin
  Result := '';
  if not Assigned(FEngine) or not FEngine.Active then
    Exit;
  LRequest := Default(THelpChatCommandRequest);
  LRequest.Command := ACommand;
  LRequest.Args := AArgs;
  LRequest.ConversationKey := FEngine.ConversationKey;
  LRequest.Actions := FActionsRef;
  LRequest.Context := BuildContext;
  LRequest.Language := ActiveLanguage;
  LRequest.Enabled := FEnabledCommands;
  Result := HelpChatCommandText(FEngine, LRequest);
end;

procedure TVclHelpChatAI.ClearConversation;
begin
  if Assigned(FView) and IsPanelVisible then
    ExecuteCommand(hccClear)       // the page redraws itself with the greeting
  else if Assigned(FEngine) and FEngine.Active then
  begin
    FEngine.Clear;
    if Assigned(FView) then
      FView.RunScript('window.hcRefresh && window.hcRefresh();');
  end;
end;

function TVclHelpChatAI.Models: TArray<THelpChatModelInfo>;
begin
  if Assigned(FEngine) then
    Result := FEngine.Models
  else
    Result := RunSettings.ResolveModels;
end;

function TVclHelpChatAI.SelectModel(const AName: string): Boolean;
begin
  Result := Assigned(FEngine) and FEngine.Active and not FSettings.Remote.IsConfigured and
    FEngine.SelectModel(AName);
  if Result and Assigned(FView) then
    FView.RunScript('window.hcRefreshAssistants && window.hcRefreshAssistants();');
end;

function TVclHelpChatAI.Languages: TArray<THelpChatLanguage>;
begin
  Result := HelpChatLanguageList(RunSettings.Languages);
end;

function TVclHelpChatAI.ActiveLanguage: THelpChatLanguage;
begin
  // The engine's: the language the user picks in the panel is written there.
  // Resolved, never hclAuto: every caption and dialog of the component asks
  // here, because an Auto handed to HelpChatMsg is the default of the
  // process - the language of whichever assistant spoke last.
  Result := RunSettings.ResolveLanguage;
end;

function TVclHelpChatAI.SelectLanguage(const ALanguage: THelpChatLanguage): Boolean;
begin
  Result := Assigned(FEngine) and FEngine.Active and not FSettings.Remote.IsConfigured and
    FEngine.SelectLanguage(ALanguage);
  if not Result then
    Exit;
  LanguageChanged;
  // The labels are written into the page when it is rendered.
  if Assigned(FView) and FView.PageReady then
    FView.RunScript('window.location.reload();');
end;

procedure TVclHelpChatAI.LanguageChanged;
begin
  if not FActive then
    Exit;
  HelpChatDefaultLanguage := RunSettings.ResolveLanguage;
  if Assigned(FBubble) then
    FBubble.Hint := HelpChatMsg(hcmUiHelp, ActiveLanguage) + ' (F1)';
  // The caption of the own window, and the name the next page load carries.
  ApplyAssistant;
end;

procedure TVclHelpChatAI.RetryLastQuestion(const AModel: string);
begin
  ExecuteCommand(hccRetry, AModel);
end;

procedure TVclHelpChatAI.SaveConversationPdf;
begin
  ExecuteCommand(hccPdf);
end;

procedure TVclHelpChatAI.CopyLastAnswer;
begin
  ExecuteCommand(hccCopy);
end;

function TVclHelpChatAI.AttachFile(const AFileName: string; out AError: string): Boolean;
var
  LAttachment: THelpChatAttachment;
begin
  Result := False;
  AError := '';
  if not Assigned(FEngine) or not FEngine.Active or FSettings.Remote.IsConfigured then
    Exit;
  if not RunSettings.Attachments.Enabled then
  begin
    AError := HelpChatMsg(hcmAttachFailed, ActiveLanguage);
    Exit;
  end;
  if not TFile.Exists(AFileName) then
  begin
    AError := AFileName;
    Exit;
  end;
  Result := FEngine.AddAttachment(FEngine.ConversationKey, TPath.GetFileName(AFileName),
    TFile.ReadAllBytes(AFileName), LAttachment, AError);
  if Result and Assigned(FView) then
    FView.RunScript('window.hcRefreshAttachments && window.hcRefreshAttachments();');
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

initialization
  // The Tool Palette of a form is filtered by class group, not by the package
  // a component comes from: a plain TComponent belongs to no framework and
  // shows up in a FireMonkey form as readily as in a VCL one. This is what
  // TApplicationEvents does, for the same reason, and the FireMonkey half of
  // the library says TFmxObject in the same place.
  GroupDescendentsWith(TVclHelpChatAI, Vcl.Controls.TControl);

finalization
  FreeAndNil(GCoordinator);

end.
