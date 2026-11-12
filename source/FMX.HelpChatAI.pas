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
///  <c>TFmxHelpChatAI</c>: the help chat for FireMonkey applications, the
///  twin of <c>TVclHelpChatAI</c>. A non-visual component that is one
///  assistant of the application: it holds the engine of its profile (shared
///  with the other components that name the same <c>Profile</c>, see
///  <see cref="THelpChatEngines" />) and owns its own transport, puts a round
///  bubble on its host form, answers F1 with the context of the current screen
///  (the deepest HelpKeyword/HelpContext from the focused control upwards, the
///  active tab as label), answers the Delphi help system (System.HelpIntfs),
///  and shows the chat (<see cref="TFmxHelpChatAIPanel" />) in its own tool
///  window or in any container the application provides through
///  <c>Container</c> or <c>OnBeforeShowHelp</c>. The engine and the local
///  HTTP server run in-process on every platform, unless
///  <c>Settings.Remote</c> names a server.
///
///  Several components may be active at once, each on its own form. What
///  belongs to the application and not to a component - the one help viewer,
///  and who answers F1 - lives in a coordinator in the implementation of this
///  unit, one per process, created by the first active component and freed
///  with the last.
///
///  Where FireMonkey differs from the VCL twin: there is no application-wide
///  key hook, so the <c>OnKeyDown</c> of the host form is chained (and
///  <see cref="TFmxHelpChatAI.HandleKeyDown" /> serves the other forms); help
///  properties live on <c>TStyledControl</c>, forms have none; a native
///  <c>TWebBrowser</c> is never moved between windows, so a new panel is
///  created for a new container; the colours come from <c>ThemeMode</c>, no
///  style is tracked; there is no dictation; and the own window is not tied
///  to a modal form. Only Windows is verified.
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
  FMX.Graphics,
  FMX.ImgList,
  FMX.MultiResBitmap,
  FMX.Objects,
  FMX.Surfaces,
  FMX.StdCtrls,
  FMX.HelpChatAI.Panel,
  HelpChatAI.Assistant,
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
  /// <summary>Default width of the component's own window, in the logical
  /// units of FireMonkey: unlike the VCL ones, they are not scaled by hand
  /// for the DPI of the monitor.</summary>
  HELPCHAT_FMX_DEF_PANEL_WIDTH = 400;
  /// <summary>Default height of the component's own window.</summary>
  HELPCHAT_FMX_DEF_PANEL_HEIGHT = 600;
  /// <summary>Diameter of the bubble.</summary>
  HELPCHAT_FMX_DEF_BUBBLE_SIZE = 44;
  /// <summary>Distance of the bubble from the corner of the host form, and of
  /// the own window from the corner it opens in.</summary>
  HELPCHAT_FMX_MARGIN = 16;
  /// <summary>Space between the icon and the edge of the disc.</summary>
  HELPCHAT_FMX_BUBBLE_PADDING = 8;
  /// <summary>The same question within this interval (key auto-repeat, a
  /// request routed twice) is shown but not sent again.</summary>
  HELPCHAT_FMX_ASK_DEBOUNCE_MS = 1500;
  /// <summary>Per-application UI state (position and size of the own
  /// window), in the per-user folder of the application. The name carries
  /// the profile of the assistant (<c>THelpChatSettings.ProfileFileName</c>),
  /// the default assistant keeping this one.</summary>
  HELPCHAT_FMX_UI_STATE_FILENAME = 'helpchatai-ui.json';

type
  TFmxHelpChatAI = class;

  /// <summary>Event to refine the screen context built automatically from the
  /// active form and control (rename the screen, add the help keyword...).
  /// Fired on the main thread, every time the panel opens. In FireMonkey it
  /// is also the only place where a form can declare a help keyword, because
  /// forms have no help properties: read <c>Screen.ActiveForm</c> here.</summary>
  TFmxHelpChatContextEvent = procedure(Sender: TObject; var AContext: THelpChatContext) of object;

  /// <summary>Event to adjust the theme before it is applied to the panel
  /// (brand accent...). Empty the theme to keep the page defaults.
  /// <c>ATheme.StyleSheet</c> arrives with the CSS of <c>PanelStyleSheet</c>
  /// and may be changed too. Fired often (every open, every page load, every
  /// change of <c>ThemeMode</c>): compute, do not show anything.</summary>
  TFmxHelpChatThemeEvent = procedure(Sender: TObject; var ATheme: THelpChatTheme) of object;

  /// <summary>Fired before the chat is shown. <c>AContainer</c> arrives as the
  /// <c>Container</c> property; set it to any control or form (and make it
  /// visible) to embed the chat there, leave it nil for the own window.
  /// A container different from the one the chat is in now costs a new web
  /// view and a page load: FireMonkey does not move a native browser between
  /// windows.</summary>
  TFmxHelpChatShowEvent = procedure(Sender: TObject; var AContainer: TFmxObject) of object;

  /// <summary>Colours of the panel: the page's own light/dark defaults (following
  /// the system), or one of the two built-in themes. This is what FireMonkey
  /// has in place of <c>FollowVclStyle</c>: the style of the application is
  /// not read, so a custom style needs <c>OnGetTheme</c>.</summary>
  TFmxHelpChatThemeMode = (tmAuto, tmLight, tmDark);

  /// <summary>
  ///  The default host of the chat panel: a tool window anchored to the
  ///  bottom-right corner of the host form, remembering where the user left it.
  ///  Created with <c>CreateNew</c> (it has no FMX file) and owned by the
  ///  component. It is a top-level form of its own: unlike the VCL one it is
  ///  not owned by the host form, nor handed to a modal form while one is up.
  /// </summary>
  TFmxHelpChatAIForm = class(TForm)
  strict private
    FOnClosedByUser: TNotifyEvent;
  protected
    /// <summary>Closing hides: the window is reused, so the page inside keeps
    /// its state. Then fires <c>OnClosedByUser</c>.</summary>
    procedure DoClose(var CloseAction: TCloseAction); override;
  public
    /// <summary>A sizeable tool window with the system menu only, at the
    /// default size; the component places it before showing it.</summary>
    constructor CreateNew(AOwner: TComponent; Dummy: NativeInt = 0); override;
    /// <summary>The user closed the window with its own button (not the
    /// component through <c>Close</c>): the component saves the position and
    /// fires the hide events.</summary>
    property OnClosedByUser: TNotifyEvent read FOnClosedByUser write FOnClosedByUser;
  end;

  /// <summary>
  ///  One assistant of a FireMonkey application. Drop it on the form it
  ///  helps with, set <c>Profile</c> when the application has more than one,
  ///  and set <c>Active</c>.
  ///
  ///  Everything here runs on the main thread; the events that do not are
  ///  marked (<c>OnDecryptSecret</c>). While active the component holds the
  ///  engine of its profile, which other components may hold too: what the
  ///  user changes in the panel (the model, the language) is written in the
  ///  settings of that engine, not in <c>Settings</c>, which stay what the
  ///  application configured.
  ///
  ///  Whatever the user can do in the panel, code can do here:
  ///  <c>ExecuteCommand</c>, <c>ClearConversation</c>, <c>SelectModel</c>,
  ///  <c>SelectLanguage</c>, <c>AttachFile</c> and the others.
  /// </summary>
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
    FBubble: TCircle;
    FBubbleGlyph: TLabel;
    FBubbleImage: TImage;
    FImages: TCustomImageList;
    FImageIndex: TImageIndex;
    FImageName: string;
    FHookedForm: TCommonCustomForm;
    FFormsCreatedId: Integer;
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
    FUseSharedActions: Boolean;
    FOnActionConfirm: THelpChatActionConfirmEvent;
    FOnActionExecuted: THelpChatActionExecutedEvent;
    FOnBeforeShowHelp: TFmxHelpChatShowEvent;
    FOnAfterShowHelp: TNotifyEvent;
    FOnBeforeHideHelp: TNotifyEvent;
    FOnAfterHideHelp: TNotifyEvent;
    FOnOpenLink: THelpChatOpenLinkEvent;
    FOnModelChanged: TNotifyEvent;
    procedure SetActionsEnabled(const Value: Boolean);
    /// <summary>The broker has a request queued. Called on the worker thread
    /// that waits for the action: queues <c>ExecutePending</c> to the main
    /// thread, the closure holding the interface of the broker so that the
    /// call cannot land on a broker freed with the component.</summary>
    procedure ActionsPending(Sender: TObject);
    /// <summary>The broker asks whether an action may run (main thread):
    /// <c>OnActionConfirm</c> when assigned, else the dialog of
    /// <c>FMX.HelpChatAI.ConfirmDialog</c>, which refuses without asking on a
    /// mobile platform.</summary>
    procedure ActionConfirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
    procedure ActionExecuted(Sender: TObject; const AName: string;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
    /// <summary>Copies Value into Settings, then puts back what is the
    /// component's and not the settings': the secret handler and the
    /// profile.</summary>
    procedure SetSettings(const Value: THelpChatSettings);
    procedure SetOnDecryptSecret(const Value: THelpChatSecretEvent);
    procedure SetContainer(const Value: TFmxObject);
    /// <summary>Activation: reads the configuration, acquires the engine of
    /// the profile and starts it (not with a remote server), creates and
    /// starts the transport, joins the coordinator, chains the key handler of
    /// the host form and places the bubble. A failure up to the start of the
    /// transport releases the engine and is raised again
    /// (<c>EHelpChatConfigError</c> for a named file that is missing).
    /// Deactivation undoes it in reverse and releases the engine, which the
    /// last assistant of the profile frees. While loading the value is only
    /// remembered (<c>Loaded</c> applies it); at design time nothing
    /// starts.</summary>
    procedure SetActive(const Value: Boolean);
    procedure SetShowBubble(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageName(const Value: string);
    /// <summary>Loads the icon into the bubble (the "?" shows when there is
    /// none) and, through <c>ApplyAssistant</c>, into the header of the
    /// panel - also when there is no bubble at all.</summary>
    procedure ApplyBubbleIcon;
    procedure SetCaption(const Value: string);
    procedure SetAssistantName(const Value: string);
    procedure SetProfile(const Value: string);
    /// <summary>The name as the application wrote it - the configuration's
    /// first, then the property - unresolved: the page resolves an empty one
    /// in the language it is rendered in.</summary>
    function ConfiguredAssistantName: string;
    procedure SetEnabledCommands(const Value: THelpChatCommands);
    /// <summary>Moves bubble and key handler to the new host; with nil they
    /// go back to the form that owns the component.</summary>
    procedure SetHostForm(const Value: TCommonCustomForm);
    procedure SetThemeMode(const Value: TFmxHelpChatThemeMode);
    /// <summary>The rule behind <c>ResolvedHostForm</c>: <c>HostForm</c>, else
    /// the first form up the chain of owners (so a component on a frame lives
    /// on the form of the frame), else <c>Application.MainForm</c>, which may
    /// still be nil while the application starts.</summary>
    function ResolveHostForm: TCommonCustomForm;
    /// <summary>Creates the bubble on the host form, once: a <c>TCircle</c>
    /// owned by the component and parented to the form, with the "?" glyph
    /// and the icon as children. Does nothing while there is no host form
    /// yet; <c>FormsCreated</c> tries again.</summary>
    procedure EnsureBubble;
    /// <summary>The disc wears the accent of the theme of the panel, the
    /// light one when the theme is empty (<c>tmAuto</c>).</summary>
    procedure ApplyBubbleColors;
    procedure DestroyBubble;
    procedure BubbleClick(Sender: TObject);
    /// <summary>The web view parented to AContainer. A view that sits in
    /// another container is freed and a new one created - a native browser
    /// is not reparented - so the page loads again and the conversation
    /// comes back from the server. Also records AContainer as the active
    /// container, with a free notification when it is the application's.</summary>
    procedure EnsureView(const AContainer: TFmxObject);
    procedure DestroyView;
    procedure EnsureOwnForm;
    /// <summary>Where the user left the own window, when that spot is still
    /// on the screen; else the bottom-right corner of the host form. Always
    /// brought back inside the work area.</summary>
    procedure PositionOwnForm;
    procedure OwnFormClosedByUser(Sender: TObject);
    /// <summary>What the transport delivers from the page, on the main
    /// thread: <c>close</c> (Escape) and the change of language. The
    /// microphone commands of the VCL twin do not exist here.</summary>
    procedure UiCommand(const ACommand: string);
    /// <summary>The language of the chat changed (from the flag of the page
    /// or from SelectLanguage): the captions this side writes follow it.</summary>
    procedure LanguageChanged;
    /// <summary>The model in use changed - in the panel or through
    /// <c>SelectModel</c>: fires <c>OnModelChanged</c>.</summary>
    procedure ModelChanged;
    /// <summary>A document to save as PDF, from the page (through the
    /// transport) or from the <c>export_pdf</c> action, on the main thread:
    /// puts the stylesheet on it, asks where it goes, builds the bands and
    /// prints it with <c>THelpChatPdfExporter</c>. The paper and the bands
    /// are read from the settings of the engine.</summary>
    procedure PdfRequest(const ADoc: THelpChatPrintableDoc);
    /// <summary>Adds the <c>export_pdf</c> action to the broker when
    /// <c>Pdf.Enabled</c> and <c>Pdf.Action</c> are on; the deactivation
    /// removes it. Its handler answers the model at once and opens the save
    /// dialog at the next turn of the message loop.</summary>
    procedure RegisterPdfAction;
    procedure ViewPageReady(Sender: TObject);
    procedure ViewOpenLink(Sender: TObject; const AUrl: string; var AHandled: Boolean);
    /// <summary>Hides the view and the own window (saving its position),
    /// between <c>OnBeforeHideHelp</c> and <c>OnAfterHideHelp</c>. The view
    /// is kept: the page stays loaded for the next opening.</summary>
    procedure HideView;
    /// <summary>Chains the <c>OnKeyDown</c> of the host form: the handler
    /// found there is remembered and still called first. This is what
    /// FireMonkey has in place of the application-wide key hook of the VCL
    /// coordinator. The chaining is done once per form, by an object the
    /// assistants of that form share (<c>TFmxFormKeyHook</c>), so they can
    /// come and go in any order. Does nothing while there is no host form
    /// yet.</summary>
    procedure HookHostForm;
    /// <summary>Leaves the hook of the form; the last assistant to leave
    /// puts back the handler that was there, but only while the form still
    /// calls the hook: a handler assigned after it is left alone.</summary>
    procedure UnhookHostForm;
    /// <summary>The forms of the application now exist: the hook and the
    /// bubble that could not be placed at activation (a component on a data
    /// module, activated before the main form was created) are placed now.</summary>
    procedure FormsCreated(const Sender: TObject; const M: TMessage);
    /// <summary>The file the position of the own window is kept in: one per
    /// profile, so two assistants do not open over each other; two components
    /// of the same profile share it.</summary>
    function UiStateFile: string;
    procedure SavePanelBounds;
    /// <summary>False when nothing was saved, the file cannot be read or the
    /// size in it is not a usable one.</summary>
    function LoadPanelBounds(out ABounds: TRect): Boolean;
    /// <summary>What every way of opening ends in: activates if need be,
    /// hands context and theme to the transport, decides the container
    /// (<c>Container</c>, then <c>OnBeforeShowHelp</c>, else the own window),
    /// shows the view there and loads the page when it is not loaded yet.</summary>
    procedure OpenWithContext(const AContext: THelpChatContext);
    /// <summary>Hands a question to the page (the view queues it until the
    /// page is ready). A question equal to the previous one within
    /// <c>HELPCHAT_FMX_ASK_DEBOUNCE_MS</c> is not sent again: FireMonkey
    /// gives no auto-repeat flag for a held F1, so this is the only
    /// guard.</summary>
    procedure Ask(const AQuestion: string; const ASend: Boolean);
  private
    // What the coordinator of the process asks.
    /// <summary>True when AForm is where this assistant lives: its host form,
    /// its own window, or the form of the container it is embedded in.</summary>
    function LivesOn(const AForm: TCommonCustomForm): Boolean;
    /// <summary>Active and with <c>HandleF1</c>: a candidate for F1.</summary>
    function TakesF1: Boolean;
    /// <summary>Active and with <c>RegisterHelpViewer</c>: a candidate for a
    /// request of the help system.</summary>
    function TakesHelp: Boolean;
  protected
    /// <summary>Applies an <c>Active</c> read from the form file, which
    /// <c>SetActive</c> only remembered while loading. Never at design
    /// time.</summary>
    procedure Loaded; override;
    /// <summary>Reads the configuration into Settings when the component
    /// activates: <c>ConfigFileName</c> alone when it names one, the three
    /// default files otherwise. Virtual because the design-time preview has
    /// already read it, from the folder of the project rather than the folder
    /// of the IDE, and must not read it again from the wrong place.</summary>
    procedure LoadConfiguration; virtual;
    /// <summary>Forgets what is going away: the host form, the hooked form,
    /// the image list, the bubble, the own window, the view and the
    /// containers. The bubble and the view are owned by the component but
    /// parented to a form of the application, which frees its children
    /// with itself: that is why they ask for a notification too.</summary>
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    /// <summary>Creates what serves the panel of this component:
    /// <c>THelpChatRemoteTransport</c> when <c>Settings.Remote</c> names a
    /// server, else a <c>THelpChatLocalServer</c> over AEngine - one server
    /// per component, even when the engine is shared. Override to plug in
    /// another backend: the component talks to it through
    /// <c>IHelpChatTransport</c> and loads the URL it gives.</summary>
    function CreateTransport(const AEngine: THelpChatEngine): IHelpChatTransport; virtual;
  public
    /// <summary>Creates the settings and the action broker, so both can be
    /// used before <c>Active</c>; nothing starts here.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>The settings in force: the engine's while active - an engine is
    /// shared by the assistants of a profile, and what the user changes in
    /// the panel (the language, the model) changes there - else
    /// <c>Settings</c>. Read it, not <c>Settings</c>, to know what the
    /// assistant is using now: <c>RunSettings.ActiveModelName</c>, the
    /// provider and the key of that model (see <c>OnModelChanged</c>).</summary>
    function RunSettings: THelpChatSettings;
    /// <summary>Deactivates, then lets go of the broker: it is reference
    /// counted and lives on while a queued call still holds it.</summary>
    destructor Destroy; override;

    /// <summary>Builds the context of the current screen: active form (name,
    /// caption, class), the deepest control with HelpKeyword/HelpContext from
    /// the focused control upwards, the active tab item as label, the focused
    /// control; then fires OnGetContext. The form is <c>Screen.ActiveForm</c>
    /// - the host form when that is the chat's own window - so a form
    /// without an assistant is described too. A form declares no help of its
    /// own in FireMonkey, and with nothing focused the active tab of the
    /// first <c>TTabControl</c> is the screen.</summary>
    function BuildContext: THelpChatContext;
    /// <summary>IHelpChatHelpTarget: the help system may route requests here.
    /// The viewer of the process asks the coordinator, not a component; this
    /// answers for this assistant alone (active, with
    /// <c>RegisterHelpViewer</c>).</summary>
    function IsHelpViewerActive: Boolean;
    /// <summary>The assistant F1 goes to now: the one whose form is active,
    /// else the one whose form was active last; nil when no assistant of
    /// the process takes F1. Several assistants may be active at once, each
    /// on its own form; this is how the application asks which one is in
    /// front of the user.</summary>
    class function CurrentAssistant: TFmxHelpChatAI; static;
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
    /// <summary>The models the panel lets the user switch between
    /// (<c>Settings.Models</c>, or the one implicit model of
    /// <c>Settings.Provider</c>), with the one in use marked. The assistant
    /// is the component and its profile; these are the models it may answer
    /// with.</summary>
    function Models: TArray<THelpChatModelInfo>;
    /// <summary>Makes AName the model in use for the questions that follow,
    /// like the list of the badge in the panel, and remembers it for the
    /// next start (in the state file, when the conversation is persisted).
    /// The choice is the engine's, so it holds for every
    /// component of the same profile. False when no model has that name,
    /// the component is not active or the engine is remote.</summary>
    function SelectModel(const AName: string): Boolean;
    /// <summary>The languages the flag of the panel offers
    /// (<c>Settings.Languages</c>); fewer than two = no flag.</summary>
    function Languages: TArray<THelpChatLanguage>;
    /// <summary>The language the chat speaks now, never <c>hclAuto</c>.</summary>
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
    /// <summary>Hides the chat, in its own window or in the container, with
    /// <c>OnBeforeHideHelp</c> and <c>OnAfterHideHelp</c> around; nothing
    /// when it is not visible. The page stays loaded and the conversation
    /// goes on.</summary>
    procedure Close;
    /// <summary>Close when visible, Open otherwise: the click on the bubble.</summary>
    procedure Toggle;
    /// <summary>True while the view is shown in its container - and, for the
    /// own window, while that window is visible. A container of the
    /// application hidden by the application itself is not noticed.</summary>
    function IsPanelVisible: Boolean;
    /// <summary>The theme the panel gets from ThemeMode (empty for
    /// <c>tmAuto</c>: the page keeps its defaults), with the CSS of
    /// <c>PanelStyleSheet</c> in <c>StyleSheet</c>; then OnGetTheme.</summary>
    function BuildTheme: THelpChatTheme;
    /// <summary>Recomputes the theme, hands it to the transport (next page load)
    /// and pushes it into the open page; the bubble takes the same accent.
    /// Called on Open, on every page load and when ThemeMode changes - call
    /// it yourself after changing what <c>OnGetTheme</c> answers.</summary>
    procedure ApplyTheme;
    /// <summary>Title of the component's own window: <c>Caption</c>, or the
    /// localized "Help" when it is empty.</summary>
    function ResolvedCaption: string;
    /// <summary>Name the panel writes in its header: <c>AssistantName</c>, or
    /// the localized "Assistant" when it is empty.</summary>
    function ResolvedAssistantName: string;
    /// <summary>Name of the icon actually used: <c>ImageName</c>, or - with no
    /// image list of the application - the built-in one <c>ImageIndex</c>
    /// points at, or the default assistant.</summary>
    function ResolvedImageName: string;
    /// <summary>The icon of the bubble as a PNG; empty when there is none.</summary>
    function AssistantIconPng: TBytes;
    /// <summary>That same icon as the <c>data:image/png</c> URI the chat page
    /// can load.</summary>
    function AssistantIconDataUri: string;
    /// <summary>Retitles the own window, hands name and icon to the transport
    /// (so the next page load already carries them) and updates an open page.
    /// Called when any of Caption, AssistantName, Images, ImageIndex or
    /// ImageName changes, and when the component activates.</summary>
    procedure ApplyAssistant;
    /// <summary>The form this assistant lives on: <c>HostForm</c>, else the
    /// form that owns the component (through a frame if need be), else the
    /// main form; nil only while the application has no main form yet.</summary>
    function ResolvedHostForm: TCommonCustomForm;
    /// <summary>F1 for a form that has no assistant of its own: call it from
    /// its OnKeyDown, on any assistant of the application - which one does
    /// not matter, not even whether it is active. The key is forwarded to
    /// the current assistant of the process
    /// (<see cref="CurrentAssistant" />): the one of the active form, else
    /// the one whose form was active last, which opens with the active form
    /// as the screen. Only a plain F1 (no Ctrl, Alt or Command) is taken.
    /// Returns True, with AKey set to 0, when the key was consumed; False
    /// when it is another key or no assistant takes F1. The host form of a
    /// component needs no call: its OnKeyDown is chained at activation.</summary>
    function HandleKeyDown(var AKey: Word; const AShift: TShiftState): Boolean;

    /// <summary>The engine of the profile while the component is active,
    /// nil otherwise. It is not this component's alone: every component with
    /// the same <c>Profile</c> holds the same one, with one conversation and
    /// one set of settings (<c>Engine.Settings</c>, which is where a model or
    /// a language picked in the panel is written). With a remote server it
    /// exists but is never started. Never free it.</summary>
    property Engine: THelpChatEngine read FEngine;
    /// <summary>What serves the panel of this component - its own, never
    /// shared: the local server over the engine, or the remote transport.
    /// nil while not active.</summary>
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
    /// <summary>Form hosting the bubble, F1 and anchoring the own window, and
    /// whose activation makes this the assistant F1 goes to. nil = the form
    /// that owns the component (through a frame if need be), else - on a
    /// data module - Application.MainForm. Set it in code: at design time the form of
    /// another unit is not a component of this one, so there would be nothing
    /// to choose from.</summary>
    property HostForm: TCommonCustomForm read FHostForm write SetHostForm;
  published
    /// <summary>What the application configured for this assistant: the
    /// values of the form file, and on top of them, at activation, the
    /// configuration files (<c>ConfigFileName</c>). Assigning copies. While
    /// active these are not what runs: the engine of the profile works on a
    /// copy taken by the first component that acquired it, and a model or a
    /// language picked in the panel is written there
    /// (<c>Engine.Settings</c>), never here. A change made here while active
    /// reaches the engine at the next activation of the profile.</summary>
    property Settings: THelpChatSettings read FSettings write SetSettings;
    /// <summary>Starts engine, server and hooks. Set at design time, it activates
    /// when the owner form is loaded at runtime. Raises when the configuration
    /// cannot be read (a named file that is missing, a key of an older
    /// version) or the server cannot start, and stays False then.</summary>
    property Active: Boolean read FActive write SetActive default False;
    /// <summary>Answer the Delphi help system (System.HelpIntfs): code calling
    /// it with a keyword or context opens the chat. One viewer serves the
    /// whole process and hands a request to the assistant of the active form,
    /// else to the current one; False keeps this assistant out of it.</summary>
    property RegisterHelpViewer: Boolean read FRegisterHelpViewer write FRegisterHelpViewer default True;
    /// <summary>F1 opens the chat with a question about the current screen.
    /// FireMonkey has no application-wide key hook: the OnKeyDown of the host
    /// form is chained at activation (the handler found there still runs
    /// first, and a key it consumes is left alone), and any other form calls
    /// <see cref="HandleKeyDown" /> from its own. With several assistants the
    /// key goes to the one of the active form, else to the one whose form was
    /// active last; False keeps this one out of it. A handler assigned to the
    /// host form after the activation replaces the chain: call
    /// <c>HandleKeyDown</c> from it.</summary>
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
    /// chat panel - and the title of the page itself. Empty (the default) =
    /// the localized "Assistant". It is a name, not a window title: that is
    /// <c>Caption</c>.</summary>
    property AssistantName: string read FAssistantName write SetAssistantName;
    /// <summary>The slash commands the user may type in the question box
    /// (<c>/who</c>, <c>/use</c>, <c>/search</c>...). Everything but
    /// <c>prompt</c> and <c>run</c> by default: those two show the context
    /// of a request and run an action by hand. See <c>HelpChatAI.Commands</c>.</summary>
    property EnabledCommands: THelpChatCommands read FEnabledCommands write SetEnabledCommands
      default HELPCHAT_DEF_COMMANDS;
    /// <summary>Round button with the assistant icon, in the bottom-right
    /// corner of the host form.</summary>
    property ShowBubble: Boolean read FShowBubble write SetShowBubble default True;
    /// <summary>Image list holding the bubble icon; nil uses the icons
    /// compiled into the component (HELPCHAT_ICON_* names). The same icon is
    /// drawn in the header of the chat panel, left of AssistantName.</summary>
    property Images: TCustomImageList read FImages write SetImages;
    /// <summary>Bubble icon by position. With no image list of the
    /// application it picks among the built-in ones, in the order of
    /// <c>HelpChatAssistantIconNames</c>.</summary>
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    /// <summary>Bubble icon by name: with the built-in icons, one of
    /// AIAssistant_Male, AIAssistant_Female, Assistant_Male, Assistant_Female.</summary>
    property ImageName: string read FImageName write SetImageName;
    /// <summary>The configuration file to read when the component activates.
    /// Named here, that file is the configuration and nothing else is looked
    /// at; a relative path is resolved against the executable. Left empty, the
    /// usual three are merged in order: the shared per-user one
    /// (%APPDATA%\HelpChatAI), the one next to the executable, then the per-user
    /// one of this application - which is where an API key belongs. A named
    /// file that is not there raises <c>EHelpChatConfigError</c> at
    /// activation: an application that asked for a configuration must not
    /// run without it.</summary>
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
    /// executable.</summary>
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
    /// IDE either, so a design-time check cannot try the key - it only asks
    /// whether one is there.
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

    /// <summary>Reopen the own window where the user left it (per application,
    /// per user, per profile). A container of the application is the
    /// application's to remember.</summary>
    property RememberPanelPosition: Boolean read FRememberPanelPosition write FRememberPanelPosition default True;
    /// <summary>Page defaults (follow the system), or the built-in light/dark theme.</summary>
    property ThemeMode: TFmxHelpChatThemeMode read FThemeMode write SetThemeMode default tmAuto;
    /// <summary>Where the chat is embedded (a side panel, a tab, a form of yours).
    /// nil = the component's own tool window. OnBeforeShowHelp can still change it.</summary>
    property Container: TFmxObject read FContainer write SetContainer;
    /// <summary>Width of the own window the first time it opens, or when the
    /// remembered position is no longer on the screen.</summary>
    property PanelWidth: Integer read FPanelWidth write FPanelWidth default HELPCHAT_FMX_DEF_PANEL_WIDTH;
    /// <summary>Height of the own window; see <see cref="PanelWidth" />.</summary>
    property PanelHeight: Integer read FPanelHeight write FPanelHeight default HELPCHAT_FMX_DEF_PANEL_HEIGHT;
    /// <summary>Refine the screen context before it reaches the engine; see
    /// <see cref="TFmxHelpChatContextEvent" />.</summary>
    property OnGetContext: TFmxHelpChatContextEvent read FOnGetContext write FOnGetContext;
    /// <summary>Adjust the colours and the CSS of the panel; see
    /// <see cref="TFmxHelpChatThemeEvent" />. The bubble takes the accent
    /// this answers.</summary>
    property OnGetTheme: TFmxHelpChatThemeEvent read FOnGetTheme write FOnGetTheme;
    /// <summary>Decide where the chat goes and show its container; leave
    /// AContainer nil for the own window.</summary>
    property OnBeforeShowHelp: TFmxHelpChatShowEvent read FOnBeforeShowHelp write FOnBeforeShowHelp;
    /// <summary>The chat is visible in its container.</summary>
    property OnAfterShowHelp: TNotifyEvent read FOnAfterShowHelp write FOnAfterShowHelp;
    /// <summary>The chat is about to be hidden (✕, Esc, Close): hide your container here.</summary>
    property OnBeforeHideHelp: TNotifyEvent read FOnBeforeHideHelp write FOnBeforeHideHelp;
    /// <summary>The chat is hidden; also fired when the user closes the own
    /// window with its button.</summary>
    property OnAfterHideHelp: TNotifyEvent read FOnAfterHideHelp write FOnAfterHideHelp;
    /// <summary>The user switched model in the panel (the badge of the
    /// header, or /use), or code did with <c>SelectModel</c>; on the main
    /// thread. <c>RunSettings.ActiveModelName</c> is the new one: the place to
    /// check that it has what it needs - a key - and to ask for it.</summary>
    property OnModelChanged: TNotifyEvent read FOnModelChanged write FOnModelChanged;
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
  System.Math,
  FMX.Dialogs,
  FMX.DialogService,
  FMX.TabControl,
  FMX.HelpChatAI.ConfirmDialog,
  HelpChatAI.Panel,            // the page contract: it decides the default name
  HelpChatAI.Server,
  HelpChatAI.Transport.Remote,
  System.Generics.Collections;

// Help properties live on TStyledControl (TControl has none).
function ControlHasHelp(const AControl: TStyledControl): Boolean;
begin
  Result := Assigned(AControl) and
    (((AControl.HelpType = htKeyword) and (AControl.HelpKeyword <> '')) or
     ((AControl.HelpType = htContext) and (AControl.HelpContext <> 0)));
end;

// The active tab of the first tab control found under ARoot, depth first:
// the screen of a form on which nothing is focused. A tab control nested in
// a tab is not looked for - the outer one answers.
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

type
  /// <summary>What an assistant is wanted for: anything (who lives on this
  /// form), F1 (<c>HandleF1</c>) or the help system
  /// (<c>RegisterHelpViewer</c>).</summary>
  TFmxHelpChatNeed = (hnAny, hnF1, hnHelp);

  /// <summary>
  ///  The application-wide half of every TFmxHelpChatAI, one per process: the
  ///  one help viewer, and the active assistants with the most recently
  ///  active first - the one whose form the user activated last. FireMonkey
  ///  has no application-wide key hook, so each component still chains the
  ///  OnKeyDown of its own form; what the coordinator decides is who answers
  ///  F1 pressed on a form that has no assistant of its own (through
  ///  HandleKeyDown), and a request of the help system.
  ///
  ///  Unlike the VCL one it has no TApplicationEvents: the activation of a
  ///  form arrives as a <c>TFormActivateMessage</c>, synchronously, so the
  ///  order of the list is always current and there is nothing to track at
  ///  every message. It is freed as soon as the last assistant leaves, with
  ///  no deferral to an idle turn: it owns no event source of its own. It is a
  ///  TComponent only to implement the interface without reference
  ///  counting; nobody owns it.
  /// </summary>
  TFmxHelpChatCoordinator = class(TComponent, IHelpChatHelpTarget)
  strict private
    FItems: TList<TFmxHelpChatAI>;
    FHelpViewer: THelpChatHelpViewer;
    FHelpViewerIntf: IInterface;
    FActivateId: Integer;
    procedure FormActivated(const Sender: TObject; const M: TMessage);
    /// <summary>True when AItem is a candidate for ANeed.</summary>
    function Accepts(const AItem: TFmxHelpChatAI; const ANeed: TFmxHelpChatNeed): Boolean;
    /// <summary>The first assistant, in order of recency, that lives on
    /// AForm and accepts ANeed; nil when there is none or AForm is nil.</summary>
    function ItemOn(const AForm: TCommonCustomForm; const ANeed: TFmxHelpChatNeed): TFmxHelpChatAI;
    /// <summary>The most recently active assistant that accepts ANeed.</summary>
    function FirstItem(const ANeed: TFmxHelpChatNeed): TFmxHelpChatAI;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>An assistant became active: last in the list, unless it
    /// lives on the active form, which makes it the current one at once.</summary>
    procedure Add(const AItem: TFmxHelpChatAI);
    procedure Remove(const AItem: TFmxHelpChatAI);
    function Count: Integer;
    /// <summary>Registers the help viewer while some assistant answers the
    /// help system, and only then (the design-time preview runs inside the
    /// IDE).</summary>
    procedure UpdateHelpViewer;
    /// <summary>A form became active: if an assistant lives on it, that
    /// assistant moves to the front.</summary>
    procedure Activated(const AForm: TCommonCustomForm);
    /// <summary>The assistant of the active form, else the most recently
    /// active one, among those that take F1.</summary>
    function F1Target: TFmxHelpChatAI;
    /// <summary>The same choice among those that answer the help system.
    /// The VCL asks for the form of the focused control; in FireMonkey the
    /// active form is the one that has the focus.</summary>
    function HelpTarget: TFmxHelpChatAI;
    // IHelpChatHelpTarget: the one viewer of the process asks here.
    function IsHelpViewerActive: Boolean;
    procedure Open;
    procedure OpenForHelp(const AKeyword: string; const AContext: Integer);
    procedure Close;
  end;

var
  // The coordinator of the process: created by the first assistant that
  // activates, freed when the last one deactivates (or at finalization).
  GCoordinator: TFmxHelpChatCoordinator;

type
  // The OnKeyDown of a form, chained once for all the assistants hosted on
  // it. Each assistant used to chain it by itself, keeping the handler it
  // found: with two on one form, the one that left first could not unhook
  // (the form no longer called it) and stayed in the chain of the other as
  // a pointer to a freed component. Here the form calls one object, which
  // lives until nobody needs it - or, when the application assigned a
  // handler of its own after it and may be calling it as "the previous
  // one", until the form goes away.
  TFmxFormKeyHook = class(TComponent)
  strict private
    FForm: TCommonCustomForm;
    FSaved: TKeyEvent;
    FHolders: TList<TFmxHelpChatAI>;
    procedure KeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
    function IsCurrent: Boolean;
    class function Find(const AForm: TCommonCustomForm): TFmxFormKeyHook; static;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor CreateFor(const AForm: TCommonCustomForm);
    destructor Destroy; override;
    class procedure Attach(const AForm: TCommonCustomForm; const AHolder: TFmxHelpChatAI); static;
    class procedure Detach(const AForm: TCommonCustomForm; const AHolder: TFmxHelpChatAI); static;
  end;

var
  GKeyHooks: TList<TFmxFormKeyHook>;

constructor TFmxFormKeyHook.CreateFor(const AForm: TCommonCustomForm);
begin
  inherited Create(nil);
  FHolders := TList<TFmxHelpChatAI>.Create;
  FForm := AForm;
  FForm.FreeNotification(Self);
  FSaved := FForm.OnKeyDown;
  FForm.OnKeyDown := KeyDown;
  if GKeyHooks = nil then
    GKeyHooks := TList<TFmxFormKeyHook>.Create;
  GKeyHooks.Add(Self);
end;

destructor TFmxFormKeyHook.Destroy;
begin
  if Assigned(GKeyHooks) then
    GKeyHooks.Remove(Self);
  FHolders.Free;
  inherited;
end;

function TFmxFormKeyHook.IsCurrent: Boolean;
var
  LOurs, LCurrent: TKeyEvent;
begin
  LOurs := KeyDown;
  LCurrent := FForm.OnKeyDown;
  Result := (TMethod(LCurrent).Code = TMethod(LOurs).Code) and
    (TMethod(LCurrent).Data = TMethod(LOurs).Data);
end;

class function TFmxFormKeyHook.Find(const AForm: TCommonCustomForm): TFmxFormKeyHook;
var
  LHook: TFmxFormKeyHook;
begin
  Result := nil;
  if Assigned(GKeyHooks) then
    for LHook in GKeyHooks do
      if LHook.FForm = AForm then
        Exit(LHook);
end;

class procedure TFmxFormKeyHook.Attach(const AForm: TCommonCustomForm;
  const AHolder: TFmxHelpChatAI);
var
  LHook: TFmxFormKeyHook;
begin
  LHook := Find(AForm);
  if LHook = nil then
    LHook := TFmxFormKeyHook.CreateFor(AForm);
  if not LHook.FHolders.Contains(AHolder) then
    LHook.FHolders.Add(AHolder);
end;

class procedure TFmxFormKeyHook.Detach(const AForm: TCommonCustomForm;
  const AHolder: TFmxHelpChatAI);
var
  LHook: TFmxFormKeyHook;
begin
  LHook := Find(AForm);
  if LHook = nil then
    Exit;
  LHook.FHolders.Remove(AHolder);
  // Put back only while the form still calls us: whoever assigned a handler
  // after the hook owns the event now and may be holding ours as its
  // previous one - then the hook stays, passing the key on, until the form
  // goes away or an assistant comes back.
  if (LHook.FHolders.Count = 0) and LHook.IsCurrent then
  begin
    AForm.OnKeyDown := LHook.FSaved;
    LHook.Free;
  end;
end;

procedure TFmxFormKeyHook.KeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
  Shift: TShiftState);
begin
  if Assigned(FSaved) then
    FSaved(Sender, Key, KeyChar, Shift);
  // A key the application consumed (Key = 0) is the application's. Which
  // assistant answers is the coordinator's decision, so any holder will do.
  if (Key <> 0) and (FHolders.Count > 0) then
    FHolders[0].HandleKeyDown(Key, Shift);
end;

procedure TFmxFormKeyHook.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // The form is going: nothing will call the hook again. Last statement of
  // the method on purpose.
  if (Operation = opRemove) and (AComponent = FForm) then
    Free;
end;

procedure CoordinatorAdd(const AItem: TFmxHelpChatAI);
begin
  if GCoordinator = nil then
    GCoordinator := TFmxHelpChatCoordinator.Create(nil);
  GCoordinator.Add(AItem);
end;

procedure CoordinatorRemove(const AItem: TFmxHelpChatAI);
begin
  if GCoordinator = nil then
    Exit;
  GCoordinator.Remove(AItem);
  if GCoordinator.Count = 0 then
    FreeAndNil(GCoordinator);
end;

// The form AObject sits on, AObject itself when it is one; nil for an object
// that is parented to nothing yet.
function FormOfObject(AObject: TFmxObject): TCommonCustomForm;
begin
  while Assigned(AObject) do
  begin
    if AObject is TCommonCustomForm then
      Exit(TCommonCustomForm(AObject));
    AObject := AObject.Parent;
  end;
  Result := nil;
end;

{ TFmxHelpChatCoordinator }

constructor TFmxHelpChatCoordinator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList<TFmxHelpChatAI>.Create;
  FActivateId := TMessageManager.DefaultManager.SubscribeToMessage(TFormActivateMessage,
    FormActivated);
end;

destructor TFmxHelpChatCoordinator.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TFormActivateMessage, FActivateId);
  if Assigned(FHelpViewer) then
  begin
    FHelpViewer.Unregister;
    FHelpViewer := nil;
    FHelpViewerIntf := nil;
  end;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TFmxHelpChatCoordinator.FormActivated(const Sender: TObject; const M: TMessage);
begin
  if M is TFormActivateMessage then
    Activated(TFormActivateMessage(M).Value);
end;

procedure TFmxHelpChatCoordinator.Activated(const AForm: TCommonCustomForm);
var
  LItem: TFmxHelpChatAI;
begin
  // A form that hosts no assistant changes nothing: F1 there goes to the
  // assistant of the form the user came from.
  LItem := ItemOn(AForm, hnAny);
  if Assigned(LItem) and (FItems.IndexOf(LItem) > 0) then
    FItems.Move(FItems.IndexOf(LItem), 0);
end;

procedure TFmxHelpChatCoordinator.Add(const AItem: TFmxHelpChatAI);
begin
  if FItems.IndexOf(AItem) < 0 then
    FItems.Add(AItem);
  if AItem.LivesOn(Screen.ActiveForm) then
    FItems.Move(FItems.IndexOf(AItem), 0);
  UpdateHelpViewer;
end;

procedure TFmxHelpChatCoordinator.Remove(const AItem: TFmxHelpChatAI);
begin
  FItems.Remove(AItem);
  UpdateHelpViewer;
end;

function TFmxHelpChatCoordinator.Count: Integer;
begin
  Result := FItems.Count;
end;

procedure TFmxHelpChatCoordinator.UpdateHelpViewer;
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

function TFmxHelpChatCoordinator.Accepts(const AItem: TFmxHelpChatAI;
  const ANeed: TFmxHelpChatNeed): Boolean;
begin
  case ANeed of
    hnF1: Result := AItem.TakesF1;
    hnHelp: Result := AItem.TakesHelp;
  else
    Result := True;
  end;
end;

function TFmxHelpChatCoordinator.ItemOn(const AForm: TCommonCustomForm;
  const ANeed: TFmxHelpChatNeed): TFmxHelpChatAI;
var
  LItem: TFmxHelpChatAI;
begin
  if Assigned(AForm) then
    for LItem in FItems do
      if Accepts(LItem, ANeed) and LItem.LivesOn(AForm) then
        Exit(LItem);
  Result := nil;
end;

function TFmxHelpChatCoordinator.FirstItem(const ANeed: TFmxHelpChatNeed): TFmxHelpChatAI;
var
  LItem: TFmxHelpChatAI;
begin
  for LItem in FItems do
    if Accepts(LItem, ANeed) then
      Exit(LItem);
  Result := nil;
end;

function TFmxHelpChatCoordinator.F1Target: TFmxHelpChatAI;
begin
  Result := ItemOn(Screen.ActiveForm, hnF1);
  if Result = nil then
    Result := FirstItem(hnF1);
end;

function TFmxHelpChatCoordinator.HelpTarget: TFmxHelpChatAI;
begin
  Result := ItemOn(Screen.ActiveForm, hnHelp);
  if Result = nil then
    Result := FirstItem(hnHelp);
end;

function TFmxHelpChatCoordinator.IsHelpViewerActive: Boolean;
begin
  Result := HelpTarget <> nil;
end;

procedure TFmxHelpChatCoordinator.Open;
var
  LTarget: TFmxHelpChatAI;
begin
  LTarget := HelpTarget;
  if Assigned(LTarget) then
    LTarget.Open;
end;

procedure TFmxHelpChatCoordinator.OpenForHelp(const AKeyword: string; const AContext: Integer);
var
  LTarget: TFmxHelpChatAI;
begin
  LTarget := HelpTarget;
  if Assigned(LTarget) then
    LTarget.OpenForHelp(AKeyword, AContext);
end;

procedure TFmxHelpChatCoordinator.Close;
var
  LItem: TFmxHelpChatAI;
begin
  for LItem in FItems.ToArray do
    LItem.Close;
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
  FUseSharedActions := True;
  FHandleF1 := True;
  FEnabledCommands := HELPCHAT_DEF_COMMANDS;
  FRegisterHelpViewer := True;
  FShowBubble := True;
  FImageIndex := -1;
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
    begin
      // The hook of the form goes with the form: only leave its list.
      TFmxFormKeyHook.Detach(FHookedForm, Self);
      FHookedForm := nil;
    end;
    if AComponent = FImages then
    begin
      FImages := nil;
      ApplyBubbleIcon;
    end;
    if AComponent = FBubble then
    begin
      FBubble := nil;
      FBubbleGlyph := nil;          // they were children of the circle
      FBubbleImage := nil;
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

procedure TFmxHelpChatAI.SetSettings(const Value: THelpChatSettings);
begin
  FSettings.Assign(Value);
  // Assign brought the handler and the profile of the settings that were
  // assigned, which are not ours: the component keeps the last word on who
  // decrypts its secrets and on which assistant it is.
  FSettings.SetSecretHandler(FOnDecryptSecret, Self);
  FSettings.Profile := FProfile;
end;

procedure TFmxHelpChatAI.SetProfile(const Value: string);
begin
  FProfile := Trim(Value);
  FSettings.Profile := FProfile;
end;

function TFmxHelpChatAI.RunSettings: THelpChatSettings;
begin
  if Assigned(FEngine) then
    Result := FEngine.Settings
  else
    Result := FSettings;
end;

function TFmxHelpChatAI.ConfiguredAssistantName: string;
begin
  Result := Trim(FSettings.AssistantName);
  if Result = '' then
    Result := Trim(FAssistantName);
end;

procedure TFmxHelpChatAI.SetOnDecryptSecret(const Value: THelpChatSecretEvent);
begin
  FOnDecryptSecret := Value;
  FSettings.SetSecretHandler(Value, Self);
end;

procedure TFmxHelpChatAI.SetHostForm(const Value: TCommonCustomForm);
begin
  if Value = FHostForm then
    Exit;
  // The notification asked of the old form is left there: it is not
  // counted, and Container or the hooked form may be the same object.
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
    Result := THelpChatRemoteTransport.Create(FSettings.Remote, FSettings.Profile)
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
    // Before the panel is ever shown, so the first page load already carries
    // the name and the header never flashes the default one.
    ApplyAssistant;
    CoordinatorAdd(Self);
    // The host form may not exist yet - a component on a data module created
    // before the main form, whose host is Application.MainForm: hook and
    // place the bubble as soon as the forms are created.
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
    CoordinatorRemove(Self);
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

procedure TFmxHelpChatAI.FormsCreated(const Sender: TObject; const M: TMessage);
begin
  // Both calls do nothing when the hook and the bubble are already there.
  // The subscription is dropped at deactivation, not here: the message is
  // sent once per run.
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
    if LOwner is TCommonCustomForm then
      Exit(TCommonCustomForm(LOwner));
    LOwner := LOwner.Owner;
  end;
  Result := Application.MainForm;
end;

function TFmxHelpChatAI.ResolvedHostForm: TCommonCustomForm;
begin
  Result := ResolveHostForm;
end;

function TFmxHelpChatAI.LivesOn(const AForm: TCommonCustomForm): Boolean;
begin
  // The own window counts: activating the chat keeps its assistant current.
  // So does the form of an application container, which may be another
  // form than the host.
  Result := Assigned(AForm) and ((AForm = ResolveHostForm) or (AForm = FOwnForm) or
    (Assigned(FActiveContainer) and (FActiveContainer <> FOwnForm) and
     (FormOfObject(FActiveContainer) = AForm)));
end;

function TFmxHelpChatAI.TakesF1: Boolean;
begin
  Result := FActive and FHandleF1;
end;

function TFmxHelpChatAI.TakesHelp: Boolean;
begin
  Result := FActive and FRegisterHelpViewer;
end;

class function TFmxHelpChatAI.CurrentAssistant: TFmxHelpChatAI;
begin
  if Assigned(GCoordinator) then
    Result := GCoordinator.F1Target
  else
    Result := nil;
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
  // (the handler the application set still runs first), once per form.
  FHookedForm := LHost;
  FHookedForm.FreeNotification(Self);
  TFmxFormKeyHook.Attach(LHost, Self);
end;

procedure TFmxHelpChatAI.UnhookHostForm;
begin
  if Assigned(FHookedForm) then
  begin
    TFmxFormKeyHook.Detach(FHookedForm, Self);
    // No RemoveFreeNotification: it is not counted, and the same form is
    // usually HostForm as well - removing it here cancelled the one
    // SetHostForm had asked for, and FHostForm outlived its form. A
    // notification too many costs nothing.
    FHookedForm := nil;
  end;
end;

function TFmxHelpChatAI.HandleKeyDown(var AKey: Word; const AShift: TShiftState): Boolean;
var
  LTarget: TFmxHelpChatAI;
begin
  Result := False;
  if (AKey <> vkF1) or (AShift * [ssCtrl, ssAlt, ssCommand] <> []) then
    Exit;
  // Whoever is asked, the coordinator decides: the assistant of the active
  // form, else the one the user came from.
  LTarget := CurrentAssistant;
  if LTarget = nil then
    Exit;
  Result := True;
  AKey := 0;
  LTarget.OpenForCurrentScreen;
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
  // Round, like the VCL one. In FireMonkey that is a TCircle and not a button
  // with a style: no stock FireMonkey style has a round button, and a square
  // one next to a round VCL one is the first thing anybody notices.
  FBubble := TCircle.Create(Self);
  FBubble.FreeNotification(Self);
  FBubble.Stored := False;
  FBubble.HitTest := True;
  FBubble.Cursor := crHandPoint;
  FBubble.Hint := HelpChatMsg(hcmUiHelp, ActiveLanguage) + ' (F1)';
  FBubble.ShowHint := True;
  FBubble.OnClick := BubbleClick;

  // The glyph is a child of the circle and lets the click through to it, so
  // the whole disc is the button.
  FBubbleGlyph := TLabel.Create(FBubble);
  FBubbleGlyph.Stored := False;
  FBubbleGlyph.Parent := FBubble;
  FBubbleGlyph.Align := TAlignLayout.Contents;
  FBubbleGlyph.HitTest := False;
  FBubbleGlyph.Text := '?';
  FBubbleGlyph.StyledSettings := FBubbleGlyph.StyledSettings -
    [TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor];
  FBubbleGlyph.TextSettings.Font.Size := 18;
  FBubbleGlyph.TextSettings.Font.Style := [TFontStyle.fsBold];
  FBubbleGlyph.TextSettings.HorzAlign := TTextAlign.Center;
  FBubbleGlyph.TextSettings.VertAlign := TTextAlign.Center;

  // The icon goes over the glyph and hides it when there is one: the "?" is
  // what is left when no icon can be resolved, exactly as in the VCL.
  FBubbleImage := TImage.Create(FBubble);
  FBubbleImage.Stored := False;
  FBubbleImage.Parent := FBubble;
  FBubbleImage.Align := TAlignLayout.Contents;
  FBubbleImage.Margins.Rect := RectF(HELPCHAT_FMX_BUBBLE_PADDING,
    HELPCHAT_FMX_BUBBLE_PADDING, HELPCHAT_FMX_BUBBLE_PADDING,
    HELPCHAT_FMX_BUBBLE_PADDING);
  FBubbleImage.HitTest := False;
  FBubbleImage.WrapMode := TImageWrapMode.Fit;
  // Parent first, then the bounds, then the anchors - in that order, and it is
  // not a matter of taste. FMX computes the anchor rules once, against the
  // parent the control has at that moment: set on an orphan control they are
  // computed against a parent of size zero, and the first time the form is
  // resized the button is pushed far outside the window. It was invisible in
  // the FMX demo until this line moved up.
  FBubble.Parent := LHost;
  FBubble.SetBounds(LHost.ClientWidth - HELPCHAT_FMX_DEF_BUBBLE_SIZE - HELPCHAT_FMX_MARGIN,
    LHost.ClientHeight - HELPCHAT_FMX_DEF_BUBBLE_SIZE - HELPCHAT_FMX_MARGIN,
    HELPCHAT_FMX_DEF_BUBBLE_SIZE, HELPCHAT_FMX_DEF_BUBBLE_SIZE);
  FBubble.Anchors := [TAnchorKind.akRight, TAnchorKind.akBottom];
  ApplyBubbleColors;
  ApplyBubbleIcon;
  FBubble.BringToFront;
end;

function TFmxHelpChatAI.ResolvedImageName: string;
begin
  Result := FImageName;
  if (Result <> '') or Assigned(FImages) then
    Exit;
  // No image list of the application: the built-in faces, by position when
  // ImageIndex names one, the default assistant otherwise.
  if (FImageIndex >= 0) and (FImageIndex < Length(HelpChatAssistantIconNames)) then
    Result := HelpChatAssistantIconNames[FImageIndex]
  else
    Result := HELPCHAT_ICON_DEFAULT;
end;

function TFmxHelpChatAI.AssistantIconPng: TBytes;
var
  LName: string;
  LBitmap: TBitmap;
  LItem: TCustomBitmapItem;
  LSize: TSize;
  LSurface: TBitmapSurface;
  LStream: TMemoryStream;
begin
  Result := nil;
  LName := ResolvedImageName;
  if not Assigned(FImages) then
    // The resource already is a PNG with its transparency: nothing to draw.
    Exit(HelpChatAssistantIconPng(LName, HELPCHAT_ICON_PANEL_SIZE));

  // A name in a FireMonkey image list belongs to the Source collection, while
  // ImageIndex addresses the Destination one: two different lookups, and the
  // name wins when it finds something.
  LBitmap := nil;
  LItem := nil;
  LSize := TSize.Create(HELPCHAT_ICON_PANEL_SIZE, HELPCHAT_ICON_PANEL_SIZE);
  if (LName <> '') and FImages.BitmapItemByName(LName, LItem, LSize) and
     Assigned(LItem) then
    LBitmap := LItem.Bitmap
  else if (FImageIndex >= 0) and (FImageIndex < FImages.Count) then
    LBitmap := FImages.Bitmap(TSizeF.Create(HELPCHAT_ICON_PANEL_SIZE,
      HELPCHAT_ICON_PANEL_SIZE), FImageIndex);
  // Whatever came back belongs to the image list and must not be freed.
  if (LBitmap = nil) or LBitmap.IsEmpty then
    Exit;
  LSurface := TBitmapSurface.Create;
  try
    LSurface.Assign(LBitmap);
    LStream := TMemoryStream.Create;
    try
      if not TBitmapCodecManager.SaveToStream(LStream, LSurface, '.png') then
        Exit;
      SetLength(Result, LStream.Size);
      if LStream.Size > 0 then
      begin
        LStream.Position := 0;
        LStream.ReadBuffer(Result[0], LStream.Size);
      end;
    finally
      LStream.Free;
    end;
  finally
    LSurface.Free;
  end;
end;

function TFmxHelpChatAI.AssistantIconDataUri: string;
begin
  Result := HelpChatPngDataUri(AssistantIconPng);
end;

procedure TFmxHelpChatAI.ApplyBubbleIcon;
var
  LPng: TBytes;
  LStream: TBytesStream;
begin
  if Assigned(FBubbleImage) then
  begin
    LPng := AssistantIconPng;
    FBubbleImage.Bitmap.SetSize(0, 0);
    if Length(LPng) > 0 then
    begin
      LStream := TBytesStream.Create(LPng);
      try
        try
          FBubbleImage.Bitmap.LoadFromStream(LStream);
        except
          // A picture that will not load leaves the "?" showing.
          FBubbleImage.Bitmap.SetSize(0, 0);
        end;
      finally
        LStream.Free;
      end;
    end;
    FBubbleImage.Visible := not FBubbleImage.Bitmap.IsEmpty;
    if Assigned(FBubbleGlyph) then
      FBubbleGlyph.Visible := not FBubbleImage.Visible;
  end;
  // The header of the chat panel shows the same icon.
  ApplyAssistant;
end;

procedure TFmxHelpChatAI.SetImages(const Value: TCustomImageList);
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

procedure TFmxHelpChatAI.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex = Value then
    Exit;
  FImageIndex := Value;
  ApplyBubbleIcon;
end;

procedure TFmxHelpChatAI.SetImageName(const Value: string);
begin
  if FImageName = Value then
    Exit;
  FImageName := Value;
  ApplyBubbleIcon;
end;

procedure TFmxHelpChatAI.ApplyBubbleColors;

  function ToAlpha(const AColor, ADefault: string): TAlphaColor;
  var
    LR, LG, LB: Integer;
  begin
    if not HelpChatHexToRgb(AColor, LR, LG, LB) then
      HelpChatHexToRgb(ADefault, LR, LG, LB);
    Result := TAlphaColor($FF000000 or (Cardinal(LR) shl 16) or (Cardinal(LG) shl 8) or
      Cardinal(LB));
  end;

var
  LTheme: THelpChatTheme;
begin
  if not Assigned(FBubble) then
    Exit;
  // The same accent the chat uses for the send button and the user bubbles, so
  // the two look like one thing. ThemeMode tmAuto leaves the theme empty (the
  // page keeps its own defaults): the light accent is the honest guess there.
  LTheme := BuildTheme;
  FBubble.Fill.Kind := TBrushKind.Solid;
  FBubble.Fill.Color := ToAlpha(LTheme.Accent, THelpChatTheme.Light.Accent);
  FBubble.Stroke.Kind := TBrushKind.Solid;
  FBubble.Stroke.Color := ToAlpha(
    HelpChatBlend(LTheme.Accent, '#000000', 0.25), '#1d4ed8');
  if Assigned(FBubbleGlyph) then
    FBubbleGlyph.TextSettings.FontColor :=
      ToAlpha(LTheme.AccentText, THelpChatTheme.Light.AccentText);
end;

procedure TFmxHelpChatAI.DestroyBubble;
begin
  if Assigned(FBubble) then
  begin
    FBubble.RemoveFreeNotification(Self);
    FBubbleGlyph := nil;            // owned by the circle, freed with it
    FBubbleImage := nil;            // and so is this one: ApplyBubbleIcon reads it
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
  FOwnForm.Caption := ResolvedCaption;
  FOwnForm.OnClosedByUser := OwnFormClosedByUser;
end;

function TFmxHelpChatAI.UiStateFile: string;
begin
  Result := FSettings.ProfileFileName(TPath.Combine(HelpChatAppDataFolder, HELPCHAT_FMX_UI_STATE_FILENAME));
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
var
  LRequest: TFmxHelpChatConfirmRequest;
begin
  if Assigned(FOnActionConfirm) then
  begin
    FOnActionConfirm(Self, AName, AArgs, AAllow);
    Exit;
  end;
  // No handler: on the desktop the dialog registered in
  // FMX.HelpChatAI.ConfirmDialog asks (the form of the library unless the
  // application registered its own), a form that follows the style of the
  // application - which the message box of the system does not. On a mobile
  // platform a modal form answers in a callback later on while the worker is
  // waiting now, so there the action is refused and the model says so:
  // assign OnActionConfirm to ask your way.
  LRequest := Default(TFmxHelpChatConfirmRequest);
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
  AAllow := HelpChatFmxConfirmAction(LRequest);
end;

procedure TFmxHelpChatAI.RegisterPdfAction;
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

procedure TFmxHelpChatAI.PdfRequest(const ADoc: THelpChatPrintableDoc);
var
  LDoc: THelpChatPrintableDoc;
  LPage: THelpChatPdfPage;
  LInfo: THelpChatPdfInfo;
  LDialog: TSaveDialog;
  LExporter: THelpChatPdfExporter;
  LFileName, LError: string;
begin
  // The same three steps as in the VCL - the stylesheet, where to put it,
  // print - with the two differences FireMonkey always has: no browser of
  // ours to borrow an environment from (the TWebBrowser keeps its WebView2 to
  // itself) and a question that is answered in a callback.
  if not FActive then
    Exit;
  if not THelpChatPdfExporter.IsAvailable then
  begin
    ShowMessage(HelpChatMsg(hcmPdfUnavailable, ActiveLanguage));
    Exit;
  end;
  LDoc := ADoc;
  try
    LDoc.Css := THelpChatPanel.PrintCss(FPdfStyleSheet);
  except
    on E: Exception do
    begin
      ShowMessage(HelpChatMsgFmt(hcmPdfFailed, [E.Message], ActiveLanguage));
      Exit;
    end;
  end;
  LDialog := TSaveDialog.Create(nil);
  try
    LDialog.Filter := HelpChatMsg(hcmPdfFilter, ActiveLanguage);
    LDialog.DefaultExt := 'pdf';
    LDialog.FileName := HelpChatPdfFileName(LDoc.Title);
    LDialog.Options := LDialog.Options + [TOpenOption.ofOverwritePrompt,
      TOpenOption.ofPathMustExist];
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
        ShowMessage(HelpChatMsgFmt(hcmPdfFailed, [E.Message], ActiveLanguage));
        Exit;
      end;
    end;
  end;
  LExporter := THelpChatPdfExporter.Create;
  try
    if not LExporter.ExportHtml(LDoc.Render, LFileName, LPage, LError) then
    begin
      ShowMessage(HelpChatMsgFmt(hcmPdfFailed, [LError], ActiveLanguage));
      Exit;
    end;
    // The document is there and is right: only the bands are missing.
    if LExporter.BandsDropped then
      ShowMessage(HelpChatMsgFmt(hcmPdfNoBands, [ExtractFileName(LFileName)],
        ActiveLanguage));
  finally
    LExporter.Free;
  end;
  TDialogService.MessageDialog(
    HelpChatMsgFmt(hcmPdfOpen, [ExtractFileName(LFileName)], ActiveLanguage),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
        HelpChatOpenDocument(LFileName);
    end);
end;

procedure TFmxHelpChatAI.UiCommand(const ACommand: string);
begin
  // What the page asked through the server (its ✕ button or Esc), or what
  // the server says by itself (the language changed).
  if FActive and (ACommand = 'close') then
    Close
  else if ACommand = HELPCHAT_UI_LANGUAGE then
    LanguageChanged
  else if ACommand = HELPCHAT_UI_MODEL then
    ModelChanged;
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
  Result.StyleSheet := FPanelCss;
  if Assigned(FOnGetTheme) then
    FOnGetTheme(Self, Result);
end;

function TFmxHelpChatAI.ResolvedCaption: string;
begin
  Result := FCaption.Trim;
  if Result = '' then
    Result := HelpChatMsg(hcmUiHelp, ActiveLanguage);
end;

function TFmxHelpChatAI.ResolvedAssistantName: string;
begin
  // The same rule the page applies, so the two cannot disagree.
  Result := THelpChatPanel.AssistantNameOf(ConfiguredAssistantName, ActiveLanguage);
end;

procedure TFmxHelpChatAI.ApplyAssistant;
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

procedure TFmxHelpChatAI.SetCaption(const Value: string);
begin
  if FCaption = Value then
    Exit;
  FCaption := Value;
  if Assigned(FOwnForm) then
    FOwnForm.Caption := ResolvedCaption;
end;

procedure TFmxHelpChatAI.SetEnabledCommands(const Value: THelpChatCommands);
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

procedure TFmxHelpChatAI.SetAssistantName(const Value: string);
begin
  if FAssistantName = Value then
    Exit;
  FAssistantName := Value;
  ApplyAssistant;
end;

procedure TFmxHelpChatAI.ApplyTheme;
var
  LTheme: THelpChatTheme;
begin
  if not Assigned(FTransport) then
    Exit;
  LTheme := BuildTheme;
  FTransport.SetTheme(LTheme);      // the next page load gets it in the :root rule
  ApplyBubbleColors;                // the disc wears the same accent
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
  LPanelUrl: string;
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

  // Asked before the view is touched: OnAfterShowHelp is for a chat that
  // was not there, not for one that is shown again where it already was.
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

  // Asked every time, not only for the first page: a remote transport
  // answers another URL when the server had expired the session and a new
  // one was opened - the page loaded with the old token would be refused
  // at every request.
  LPanelUrl := FTransport.GetPanelUrl;
  if not FView.PageReady or (FView.PanelUrl <> LPanelUrl) then
    FView.OpenUrl(LPanelUrl, FTransport.GetPanelOrigin)
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

procedure TFmxHelpChatAI.ExecuteCommand(const ACommand: THelpChatCommand; const AArgs: string);
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

function TFmxHelpChatAI.ExplainCommand(const ACommand: THelpChatCommand; const AArgs: string): string;
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

procedure TFmxHelpChatAI.ClearConversation;
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

function TFmxHelpChatAI.Models: TArray<THelpChatModelInfo>;
begin
  if Assigned(FEngine) then
    Result := FEngine.Models
  else
    Result := RunSettings.ResolveModels;
end;

function TFmxHelpChatAI.SelectModel(const AName: string): Boolean;
begin
  // Remote is asked of the component's own settings on purpose: where the
  // engine lives is read from the configuration and never changes at run
  // time, unlike what RunSettings is for.
  Result := Assigned(FEngine) and FEngine.Active and not FSettings.Remote.IsConfigured and
    FEngine.SelectModel(AName);
  // The badge of this panel; the script keeps the name it had before 1.7,
  // when a model was called an assistant.
  if Result and Assigned(FView) then
    FView.RunScript('window.hcRefreshAssistants && window.hcRefreshAssistants();');
  if Result then
    ModelChanged;
end;

function TFmxHelpChatAI.Languages: TArray<THelpChatLanguage>;
begin
  Result := HelpChatLanguageList(RunSettings.Languages);
end;

function TFmxHelpChatAI.ActiveLanguage: THelpChatLanguage;
begin
  // The engine's: the language the user picks in the panel is written there.
  Result := RunSettings.ResolveLanguage;
end;

function TFmxHelpChatAI.SelectLanguage(const ALanguage: THelpChatLanguage): Boolean;
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

procedure TFmxHelpChatAI.ModelChanged;
begin
  if FActive and Assigned(FOnModelChanged) then
    FOnModelChanged(Self);
end;

procedure TFmxHelpChatAI.LanguageChanged;
begin
  if not FActive then
    Exit;
  HelpChatDefaultLanguage := RunSettings.ResolveLanguage;
  if Assigned(FBubble) then
    FBubble.Hint := HelpChatMsg(hcmUiHelp, ActiveLanguage) + ' (F1)';
  // The caption of the own window, and the name the next page load carries.
  ApplyAssistant;
end;

procedure TFmxHelpChatAI.RetryLastQuestion(const AModel: string);
begin
  ExecuteCommand(hccRetry, AModel);
end;

procedure TFmxHelpChatAI.SaveConversationPdf;
begin
  ExecuteCommand(hccPdf);
end;

procedure TFmxHelpChatAI.CopyLastAnswer;
begin
  ExecuteCommand(hccCopy);
end;

function TFmxHelpChatAI.AttachFile(const AFileName: string; out AError: string): Boolean;
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

initialization
  // See the note in Vcl.HelpChatAI: without this the component would also be
  // offered on a VCL form, where it cannot work.
  GroupDescendentsWith(TFmxHelpChatAI, FMX.Types.TFmxObject);

finalization
  FreeAndNil(GCoordinator);
  // The hooks still here belong to forms that outlive the unit: they are
  // left to them, only the list goes.
  FreeAndNil(GKeyHooks);

end.
