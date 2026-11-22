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
///  Actions: what the assistant may <i>do</i> in the application, beyond
///  answering. The application registers them by name with a description and
///  their parameters; a provider that supports tools (claude, openai, gemini)
///  offers them to the model, and when the model calls one this unit runs it
///  and hands the result back so the model can continue.
///
///  Since 1.7 the actions belong to an assistant, not to an engine: each
///  component has its own broker and gives it to its transport, so a question
///  carries the actions of the panel it was asked from - two order windows
///  that share the engine of their profile each fill their own form. What an
///  assistant may call is its own actions, plus the ones the application
///  shares (<see cref="HelpChatSharedActions" />), minus what its profile
///  does not allow (<c>Allowed</c>).
///
///  Three rules shape the design:
///
///  <list type="bullet">
///  <item>Only what is registered exists. There is no generic "run this" entry
///  point: the model can call the actions of that application and nothing
///  else, with the parameters they declare.</item>
///  <item>An action runs where the application lives, on its main thread — it
///  opens forms and fills fields — while the model call runs on a worker. So a
///  request is queued, the host is woken up, and the worker waits for the
///  answer with a timeout and with cancellation honoured
///  (<see cref="THelpChatActionBroker" />). The same queue is what will carry
///  actions to a client of a remote server, where the model is on one machine
///  and the window to fill on another.</item>
///  <item>Anything asks first unless told otherwise: an action is registered
///  with <c>Confirm</c> on, and is executed only after the host says yes.
///  Switching it off is for an action that changes nothing (bringing a
///  screen to the front) or that asks in its own way (a save dialog).</item>
///  </list>
/// </summary>
unit HelpChatAI.Actions;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  System.JSON,
  HelpChatAI.Types,
  HelpChatAI.Messages;

const
  /// <summary>How long a model call waits for an action to run, confirmation
  /// included. Beyond it the model is told the action timed out - and the
  /// action is not run any more, even if the user confirms it afterwards.</summary>
  HELPCHAT_DEF_ACTION_TIMEOUT_MS = 60000;
  /// <summary>Characters of an action result handed back to the model.</summary>
  HELPCHAT_DEF_ACTION_RESULT_MAXCHARS = 2000;
  /// <summary>Characters of one parameter value shown to the user when an
  /// action asks for confirmation. The model writes the values, and a model
  /// under the influence of a hostile text would gladly write a paragraph
  /// that reads like an approval: the user sees a line per value, and the
  /// line is short.</summary>
  HELPCHAT_ACTION_DISPLAY_MAXCHARS = 120;
  /// <summary>The longest name of a parameter a confirmation shows.</summary>
  HELPCHAT_ACTION_DISPLAY_KEY_MAXCHARS = 40;
  /// <summary>What the model reads when the user said no: the plan stops
  /// there, and the model is told not to look for another way.</summary>
  HELPCHAT_ACTION_DENIED_TEXT =
    'The user did not allow the action "%s". Do not try it again or in another way, ' +
    'and do not go on with the steps that depended on it: tell the user what was not ' +
    'done and stop.';
  /// <summary>What the model reads for an action asked after the user said
  /// no to another one of the same reply: it was not run, and nobody was asked.</summary>
  HELPCHAT_ACTION_DENIED_BEFORE_TEXT =
    'The action "%s" was not run: the user refused an action of this request, which ' +
    'ends it. Tell the user what was not done and stop.';
  /// <summary>What the model reads for a call whose arguments are not one
  /// whole JSON object - cut at the token limit, usually: the action was not
  /// run.</summary>
  HELPCHAT_ACTION_BROKEN_ARGS_TEXT =
    'its arguments arrived incomplete or were not a JSON object, so nothing was done. ' +
    'Call it again with the complete arguments.';

type
  /// <summary>Type of a parameter, as declared to the model. An object or an
  /// array reaches the handler as its JSON text (<c>AsString</c>,
  /// <c>AsJson</c>); <see cref="THelpChatActionParam.Schema" /> may say what
  /// is inside it.</summary>
  THelpChatActionParamKind = (apkString, apkInteger, apkNumber, apkBoolean,
    apkObject, apkArray);

  /// <summary>One parameter of an action, as the model is told about it:
  /// the description is all the model knows of it, and its first words are
  /// the label the confirmation dialog shows next to the value.</summary>
  THelpChatActionParam = record
    /// <summary>The name the model calls the parameter by.</summary>
    Name: string;
    /// <summary>What the model is told about it.</summary>
    Description: string;
    /// <summary>Its type, as declared to the model.</summary>
    Kind: THelpChatActionParamKind;
    /// <summary>False for a parameter the model may leave out.</summary>
    Required: Boolean;
    /// <summary>Optional: the JSON Schema of the parameter, as text - the
    /// properties of an object, the items of an array, an enum. When it is
    /// one JSON object it is declared to the model in place of the bare type
    /// (the description is added unless it has one); empty, or not an
    /// object, and the type of <c>Kind</c> is declared as before. Keep to
    /// what every provider takes: type, description, properties, required,
    /// items, enum.</summary>
    Schema: string;
    /// <summary>A parameter, a required string unless said otherwise.</summary>
    class function Create(const AName, ADescription: string;
      const AKind: THelpChatActionParamKind = apkString;
      const ARequired: Boolean = True): THelpChatActionParam; overload; static;
    /// <summary>A parameter with a JSON Schema of its own
    /// (<see cref="Schema" />): an object whose fields the model is told,
    /// an array of them.</summary>
    class function Create(const AName, ADescription: string;
      const AKind: THelpChatActionParamKind; const ASchema: string;
      const ARequired: Boolean = True): THelpChatActionParam; overload; static;
  end;

  THelpChatAction = class;

  /// <summary>What the model passed, by parameter name. Reading a parameter
  /// that was not sent gives the default, never an exception: a model may omit
  /// an optional one, or get a name wrong.</summary>
  THelpChatActionArgs = class
  strict private
    FValues: TDictionary<string, string>;
    FRawJson: string;
  public
    /// <summary>Reads the arguments out of the JSON object the model sent. Text
    /// that is not one object gives no parameters: nothing is raised.</summary>
    constructor Create(const AJson: string);
    destructor Destroy; override;
    /// <summary>True when the model sent that parameter (case
    /// apart).</summary>
    function Has(const AName: string): Boolean;
    /// <summary>The value as text; ADefault when the parameter was not
    /// sent.</summary>
    function AsString(const AName: string; const ADefault: string = ''): string;
    /// <summary>The value as an integer; ADefault when missing or not a
    /// number.</summary>
    function AsInteger(const AName: string; const ADefault: Integer = 0): Integer;
    /// <summary>The value as a number, with a point or a comma as decimal
    /// separator; ADefault when missing or not a number.</summary>
    function AsFloat(const AName: string; const ADefault: Double = 0): Double;
    /// <summary>true/1/yes or false/0/no, case apart; ADefault for anything
    /// else.</summary>
    function AsBoolean(const AName: string; const ADefault: Boolean = False): Boolean;
    /// <summary>The value parsed as JSON: the object or the array the model
    /// sent, or one it sent as a string holding it (models do both); nil
    /// when missing or not JSON. The caller frees it.</summary>
    function AsJson(const AName: string): TJSONValue;
    /// <summary>Names actually received.</summary>
    function Names: TArray<string>;
    /// <summary>"name=value, name=value", on one line, for a log or a status
    /// bar. Each value is made safe for display: control characters become
    /// spaces and a long one is cut at
    /// <see cref="HELPCHAT_ACTION_DISPLAY_MAXCHARS" />. The model wrote these
    /// values, so the text must not be able to pass for anything else.</summary>
    function ToDisplayString: string;
    /// <summary>The same values, one per line ("  name = value"), made safe
    /// the same way: what a plain confirmation message shows. Empty when
    /// there are no values.</summary>
    function ToDisplayLines: string; overload;
    /// <summary>One line per value ("Label: value"), the label being the
    /// short form of the description the action declared for that parameter
    /// (its name when it declared none), in the order of the declaration;
    /// values the model sent under a name the action did not declare follow,
    /// under their name. What a dialog with room for it shows.</summary>
    function ToDisplayLines(const AAction: THelpChatAction): string; overload;
    /// <summary>The same labelled values as pairs (label, safe value), in the
    /// same order: for a dialog that lays them out itself.</summary>
    function ToDisplayPairs(const AAction: THelpChatAction): TArray<TPair<string, string>>;
    /// <summary>One value as it can be shown: no control characters, no more
    /// than <see cref="HELPCHAT_ACTION_DISPLAY_MAXCHARS" /> characters.</summary>
    class function DisplayValue(const AValue: string): string; static;
    /// <summary>The name of a parameter as a dialog may show it: made safe
    /// like a value, and no longer than
    /// <see cref="HELPCHAT_ACTION_DISPLAY_KEY_MAXCHARS" />. A name nobody
    /// declared was written by the model, like its value.</summary>
    class function DisplayKey(const AKey: string): string; static;
    /// <summary>The JSON object as the model sent it.</summary>
    property RawJson: string read FRawJson;
  end;

  /// <summary>What an action does. Runs on the main thread of the application;
  /// <c>AResult</c> is what the model is told (empty means "done").</summary>
  THelpChatActionProc = reference to procedure(const AArgs: THelpChatActionArgs;
    var AResult: string);

  /// <summary>What the confirmation of an action shows, when the parameters
  /// as the model sent them would not say it well (a JSON object of field
  /// values, say): <c>ASummary</c> arrives as the description of the action
  /// and <c>AValues</c> as the labelled parameters, and either may be
  /// replaced. Runs on the thread that confirms - the main thread of the
  /// application - so it may read the screen. The values are made safe for
  /// display afterwards, like the others.</summary>
  THelpChatActionDisplayProc = reference to procedure(const AArgs: THelpChatActionArgs;
    var ASummary: string; var AValues: TArray<TPair<string, string>>);

  /// <summary>One registered action: its name, what the model is told about
  /// it, its parameters, whether it asks first, and the handler. Owned by the
  /// broker it was added to; a shared action is owned by
  /// <see cref="HelpChatSharedActions" /> and run by the broker that was
  /// asked.</summary>
  THelpChatAction = class
  strict private
    FName: string;
    FDescription: string;
    FParams: TArray<THelpChatActionParam>;
    FConfirm: Boolean;
    FHandler: THelpChatActionProc;
    FOnDisplay: THelpChatActionDisplayProc;
  public
    /// <summary>An action as the broker keeps it: what the model is told (name,
    /// description, parameters), the handler that runs it on the main thread,
    /// and whether the user is asked first.</summary>
    constructor Create(const AName, ADescription: string;
      const AParams: TArray<THelpChatActionParam>; const AHandler: THelpChatActionProc;
      const AConfirm: Boolean);
    /// <summary>The sentence a confirmation shows above the values: the
    /// description, unless <see cref="OnDisplay" /> says otherwise.</summary>
    function DisplaySummary(const AArgs: THelpChatActionArgs): string;
    /// <summary>The JSON schema of this action as an Anthropic tool
    /// (<c>name</c>, <c>description</c>, <c>input_schema</c>): the neutral
    /// form of the library, which the other providers translate into their
    /// own (OpenAI <c>function</c>, Gemini <c>functionDeclarations</c>).</summary>
    function ToToolJson: string;
    /// <summary>The label a dialog gives the value of a parameter: the
    /// description up to its first punctuation ("Company name, as in the
    /// Accounts list" reads "Company name"), cut short; the name of the
    /// parameter when there is no description, or no such parameter.</summary>
    function ParamLabel(const AName: string): string;
    /// <summary>The name the model calls it by, as registered.</summary>
    property Name: string read FName;
    /// <summary>What the model is told the action does - all it knows about it
    /// - and what the confirmation dialog shows the user.</summary>
    property Description: string read FDescription;
    /// <summary>The declared parameters, in the order they were
    /// written.</summary>
    property Params: TArray<THelpChatActionParam> read FParams;
    /// <summary>The host asks the user before running it. On unless the
    /// registration said otherwise.</summary>
    property Confirm: Boolean read FConfirm;
    /// <summary>What runs, on the main thread of the application. It must
    /// return at once: a worker is waiting for it.</summary>
    property Handler: THelpChatActionProc read FHandler;
    /// <summary>Optional: what a confirmation shows instead of the
    /// description and of the parameters as they were sent. Read by
    /// <see cref="DisplaySummary" /> and by
    /// <see cref="THelpChatActionArgs.ToDisplayPairs" />.</summary>
    property OnDisplay: THelpChatActionDisplayProc read FOnDisplay write FOnDisplay;
  end;

  /// <summary>How an action call ended. Anything but <c>aoDone</c> is reported
  /// to the model as text, so that it can explain itself or try something
  /// else instead of pretending it worked.</summary>
  THelpChatActionOutcome = (
    aoDone,
    /// <summary>The user said no.</summary>
    aoDenied,
    /// <summary>No action with that name is registered.</summary>
    aoUnknown,
    /// <summary>The handler raised.</summary>
    aoFailed,
    /// <summary>Nobody executed it in time (no host listening, or a very slow one).</summary>
    aoTimeout,
    /// <summary>The reply was cancelled while the action was waiting.</summary>
    aoCancelled);

  /// <summary>What a provider needs: the tools to declare and a way to call
  /// one. Implemented by <see cref="THelpChatActionBroker" />; a provider never
  /// sees the registry or the threading behind it.</summary>
  IHelpChatActionInvoker = interface
    ['{2F7A9C41-8D63-4B05-9E12-3A6C8B4D7E90}']
    /// <summary>True when there is at least one action to offer.</summary>
    function HasActions: Boolean;
    /// <summary>The actions the model may call - own and shared, after the
    /// narrowing of the profile - as an Anthropic <c>tools</c> array: the
    /// neutral form every provider starts from.</summary>
    function ToolsJson: string;
    /// <summary>Runs the action and waits for its result. Called on a worker
    /// thread; never raises - whatever goes wrong on the way is
    /// <c>aoFailed</c>. <c>AResult</c> is what the handler answered, or
    /// the reason of a failure; anything but <c>aoDone</c> becomes a sentence
    /// for the model through <see cref="HelpChatActionOutcomeText" />.</summary>
    function Invoke(const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
  end;

  THelpChatActionBroker = class;

  /// <summary>One call in flight, from the queue to the answer.</summary>
  THelpChatActionRequest = class
  strict private
    FId: string;
    FName: string;
    FArgsJson: string;
    FDone: TEvent;
    FResult: string;
    FOutcome: THelpChatActionOutcome;
    FAbandoned: Boolean;
  public
    /// <summary>A call of the action <c>AName</c> with the arguments the model
    /// wrote, not yet answered.</summary>
    constructor Create(const AName, AArgsJson: string);
    destructor Destroy; override;
    /// <summary>The host answers: the outcome and the text are stored and
    /// whoever waits on <c>Done</c> is woken up.</summary>
    procedure Complete(const AOutcome: THelpChatActionOutcome; const AResult: string);
    /// <summary>Nobody is waiting for the answer any more: the model call
    /// timed out or was cancelled while the host held the request. The host
    /// must not run the action, and owns the object from now on.</summary>
    procedure Abandon;
    /// <summary>An id of its own, for a host that answers from somewhere
    /// else.</summary>
    property Id: string read FId;
    /// <summary>The action that was asked for.</summary>
    property Name: string read FName;
    /// <summary>The arguments, as the JSON object the model wrote.</summary>
    property ArgsJson: string read FArgsJson;
    /// <summary>Signalled when the host answered.</summary>
    property Done: TEvent read FDone;
    /// <summary>What the handler answered, or why it did not run: read once
    /// <c>Done</c> is signalled.</summary>
    property Result: string read FResult;
    /// <summary>How it went: read once <c>Done</c> is signalled.</summary>
    property Outcome: THelpChatActionOutcome read FOutcome;
    /// <summary>True when the waiter gave up while the host held the request:
    /// the host must not run the action, and frees the request.</summary>
    property Abandoned: Boolean read FAbandoned;
  end;

  /// <summary>Asks the host whether an action may run (it is about to change
  /// something). Called on the thread that executes the action.</summary>
  THelpChatActionConfirmEvent = procedure(Sender: TObject; const AName: string;
    const AArgs: THelpChatActionArgs; var AAllow: Boolean) of object;
  /// <summary>Fired after an action ran, for a log or a status bar.</summary>
  THelpChatActionExecutedEvent = procedure(Sender: TObject; const AName: string;
    const AOutcome: THelpChatActionOutcome; const AResult: string) of object;

  /// <summary>
  ///  The registry and the queue in one object: the application registers its
  ///  actions here, a provider invokes them through
  ///  <see cref="IHelpChatActionInvoker" />, and the host (the VCL or FMX
  ///  component) executes what the queue hands it, on the main thread.
  /// </summary>
  THelpChatActionBroker = class(TInterfacedObject, IHelpChatActionInvoker)
  strict private
    FLock: TCriticalSection;
    FActions: TObjectDictionary<string, THelpChatAction>;
    FOrder: TList<string>;
    FPending: TObjectList<THelpChatActionRequest>;
    FEnabled: Boolean;
    FTimeoutMs: Integer;
    FResultMaxChars: Integer;
    FOnPending: TNotifyEvent;
    FOnConfirm: THelpChatActionConfirmEvent;
    FOnExecuted: THelpChatActionExecutedEvent;
    FShared: THelpChatActionBroker;
    FSharedRef: IHelpChatActionInvoker;
    FAllowed: TArray<string>;
    FHostActive: Boolean;
    function GetHostActive: Boolean;
    procedure SetHostActive(const Value: Boolean);
    procedure SetShared(const Value: THelpChatActionBroker);
    procedure SetAllowed(const Value: TArray<string>);
    function GetAllowed: TArray<string>;
    function IsAllowed(const AName: string): Boolean;
    function TakePending: TArray<THelpChatActionRequest>;
    /// <summary>The waiter gives up on a request: it is dropped if still
    /// queued, freed if already answered, abandoned to the host otherwise.
    /// True when the host had answered in the meantime - between the last
    /// wait and this call: the action ran, and <c>AOutcome</c> and
    /// <c>AResult</c> are what it answered. Telling the model "timeout" then
    /// would make it ask again for something already done.</summary>
    function Forget(const ARequest: THelpChatActionRequest;
      out AOutcome: THelpChatActionOutcome; out AResult: string): Boolean;
    /// <summary>The declaration of one of the own actions, built while the
    /// lock is held; empty when there is none by that name.</summary>
    function OwnToolJson(const AName: string): string;
    /// <summary>The declaration of the action the model may call by that
    /// name (see <see cref="Resolve" />), built under the lock of the broker
    /// that owns it: a skill detached meanwhile on the main thread frees
    /// its actions.</summary>
    function ToolJsonOf(const AName: string): string;
    /// <summary>The host answers a request - or frees it, if the waiter is gone.</summary>
    procedure Finish(const ARequest: THelpChatActionRequest;
      const AOutcome: THelpChatActionOutcome; const AResult: string);
  public
    /// <summary>An empty broker: enabled, its host active, the default
    /// timeout.</summary>
    constructor Create;
    destructor Destroy; override;

    /// <summary>Declares an action the assistant may call. It asks the user
    /// before running unless <c>AConfirm</c> is False: that is for an action
    /// that changes nothing, or that asks in its own way.
    /// It returns the action, owned by the broker, for what is set after the
    /// registration (<see cref="THelpChatAction.OnDisplay" />).</summary>
    function Add(const AName, ADescription: string;
      const AParams: array of THelpChatActionParam;
      const AHandler: THelpChatActionProc; const AConfirm: Boolean = True): THelpChatAction; overload;
    /// <summary>An action without parameters.</summary>
    function Add(const AName, ADescription: string;
      const AHandler: THelpChatActionProc; const AConfirm: Boolean = True): THelpChatAction; overload;
    /// <summary>Takes an action of this broker away (a shared one is removed
    /// from <see cref="HelpChatSharedActions" />, or kept out with
    /// <c>Allowed</c>).</summary>
    procedure Remove(const AName: string);
    /// <summary>Takes every action of this broker away.</summary>
    procedure Clear;
    /// <summary>The action of this broker with that name (case apart), or
    /// nil: the own ones only, whatever <c>Allowed</c> says. What the model
    /// may call is <see cref="Resolve" />.</summary>
    function Find(const AName: string): THelpChatAction;
    /// <summary>How many actions this broker registered itself.</summary>
    function Count: Integer;
    /// <summary>Registered names, in registration order.</summary>
    function Names: TArray<string>;
    /// <summary>The action the model may call by this name: one of this
    /// broker, else one of <c>Shared</c>, as long as <c>Allowed</c> lets it
    /// through; nil otherwise.</summary>
    function Resolve(const AName: string): THelpChatAction;
    /// <summary>What the model is told it may call: the names of this broker,
    /// then those of <c>Shared</c> it does not redefine, filtered by
    /// <c>Allowed</c>.</summary>
    function AvailableNames: TArray<string>;

    // IHelpChatActionInvoker
    function HasActions: Boolean;
    function ToolsJson: string;
    function Invoke(const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;

    /// <summary>Runs every queued call on the calling thread: the host calls
    /// this from its main thread when <see cref="OnPending" /> woke it up.</summary>
    procedure ExecutePending;
    /// <summary>Calls waiting to be executed.</summary>
    function PendingCount: Integer;

    /// <summary>False keeps the actions registered but hides them from the
    /// model: nothing is declared and nothing can be called.</summary>
    property Enabled: Boolean read FEnabled write FEnabled;
    /// <summary>Whether somebody is there to run what is queued. True from
    /// the start; the component of an assistant sets it False when it
    /// deactivates and True again when it activates. While False,
    /// <see cref="Invoke" /> answers <c>aoCancelled</c> at once and the calls
    /// still queued are answered the same way. It matters because the engine
    /// of a profile outlives each of the assistants that share it: a reply
    /// asked from a window that has been closed since may still call an
    /// action of that window, and without this the worker would wait the
    /// whole <see cref="TimeoutMs" /> for a host that left - or, worse, the
    /// action would run on a form that is being torn down.</summary>
    property HostActive: Boolean read GetHostActive write SetHostActive;
    /// <summary>How long <see cref="Invoke" /> waits for the host.</summary>
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
    /// <summary>Longer results are cut before reaching the model.</summary>
    property ResultMaxChars: Integer read FResultMaxChars write FResultMaxChars;
    /// <summary>"there is something to execute": fired on the worker thread,
    /// the host marshals to its own and calls <see cref="ExecutePending" />.</summary>
    property OnPending: TNotifyEvent read FOnPending write FOnPending;
    /// <summary>The actions every assistant of the application may use
    /// (<see cref="HelpChatSharedActions" />), consulted after this broker's
    /// own - an action of the same name here redefines it. A call to one of
    /// them is queued, confirmed and executed here, on the host of this
    /// broker, like the own ones: the shared broker only holds definitions.</summary>
    property Shared: THelpChatActionBroker read FShared write SetShared;
    /// <summary>The names the model may call, own and shared alike (case
    /// apart); empty = all of them. What a profile says in
    /// <c>AllowedActions</c>: a configuration can take an action away, it
    /// can never add one the code did not register.</summary>
    property Allowed: TArray<string> read GetAllowed write SetAllowed;
    /// <summary>Asked, on the thread that executes, before an action
    /// registered with confirmation runs. Without a handler such an action
    /// runs unasked: the components always install one.</summary>
    property OnConfirm: THelpChatActionConfirmEvent read FOnConfirm write FOnConfirm;
    /// <summary>Fired on the thread that executes, after every call, refused
    /// and failed ones included.</summary>
    property OnExecuted: THelpChatActionExecutedEvent read FOnExecuted write FOnExecuted;
  end;

const
  /// <summary>How many actions a client may declare to a relay.</summary>
  HELPCHAT_RELAY_MAX_ACTIONS = 64;
  /// <summary>The longest declaration (the JSON of the tools) a relay
  /// takes.</summary>
  HELPCHAT_RELAY_MAX_TOOLS_CHARS = 200000;
  /// <summary>How long a relay waits for the client to answer a call: the
  /// time the client's own broker waits for its host, plus the round trips.
  /// The client must be the one that gives up first, so that what the model
  /// is told is what the client knows.</summary>
  HELPCHAT_RELAY_DEF_TIMEOUT_MS = HELPCHAT_DEF_ACTION_TIMEOUT_MS + 15000;

type
  /// <summary>
  ///  The actions of an assistant whose engine is somewhere else: what a
  ///  HelpChatAI server gives the model of a session in place of a broker.
  ///  The client declares its actions (<see cref="SetTools" />: the
  ///  <c>ToolsJson</c> of its own broker), a provider invokes one like any
  ///  other, and the call waits here until the client took it
  ///  (<see cref="TakeCallsJson" />), ran it on its own broker - where the
  ///  handler, the confirmation and the main thread are - and answered
  ///  (<see cref="Complete" />). Nothing of the application runs on the
  ///  server. Reference counted, thread-safe.
  /// </summary>
  THelpChatActionRelay = class(TInterfacedObject, IHelpChatActionInvoker)
  strict private
    type
      TCall = class
      public
        Id: string;
        Name: string;
        ArgsJson: string;
        Result: string;
        Outcome: THelpChatActionOutcome;
        Delivered: Boolean;
        Answered: Boolean;
        Done: TEvent;
        destructor Destroy; override;
      end;
    var
      FLock: TCriticalSection;
      FNames: TArray<string>;
      FTools: TArray<string>;
      FCalls: TList<TCall>;
      FAllowed: TArray<string>;
      FClosed: Boolean;
      FTimeoutMs: Integer;
      FResultMaxChars: Integer;
    function GetAllowed: TArray<string>;
    procedure SetAllowed(const Value: TArray<string>);
    /// <summary>Called with the lock held.</summary>
    function Offers(const AName: string): Boolean;
  public
    /// <summary>A relay with nothing declared.</summary>
    constructor Create;
    destructor Destroy; override;
    /// <summary>What the client may do, as the <c>tools</c> array its broker
    /// writes (name, description, input_schema); it replaces what was
    /// declared before, and an empty text declares nothing. Only those three
    /// members are kept, a name is letters, digits, "_" and "-" (64 at
    /// most), a name declared twice counts once. False, with a short English
    /// reason and the previous declaration still in force, for a text that
    /// is not such an array, is longer than
    /// <see cref="HELPCHAT_RELAY_MAX_TOOLS_CHARS" /> or declares more than
    /// <see cref="HELPCHAT_RELAY_MAX_ACTIONS" /> actions: a client writes
    /// this text, and it goes into the request of the model.</summary>
    function SetTools(const AJson: string; out AError: string): Boolean;
    // IHelpChatActionInvoker
    function HasActions: Boolean;
    function ToolsJson: string;
    /// <summary>Queues the call and waits for the client: its answer, else
    /// <c>aoTimeout</c> after <see cref="TimeoutMs" />, <c>aoCancelled</c>
    /// when the reply was cancelled or the relay closed, <c>aoUnknown</c>
    /// for a name that was not declared or is not allowed. A client that
    /// took the call may still run it after this gave up: its answer is
    /// then refused (<see cref="Complete" /> answers False).</summary>
    function Invoke(const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
    /// <summary>True while a call is waiting that no client took yet.</summary>
    function HasUndelivered: Boolean;
    /// <summary>The calls nobody took yet, as
    /// <c>{"calls":[{"id","name","args"}]}</c> - <c>args</c> being the JSON
    /// object the model wrote, as a string - and marks them taken: a call is
    /// handed out once.</summary>
    function TakeCallsJson: string;
    /// <summary>The client answers a call. False when nobody is waiting for
    /// it any more (it timed out, was cancelled, or was answered
    /// already).</summary>
    function Complete(const AId: string; const AOutcome: THelpChatActionOutcome;
      const AResult: string): Boolean;
    /// <summary>The client is gone: every waiting call is answered
    /// <c>aoCancelled</c>, and so is every later one.</summary>
    procedure Close;
    /// <summary>The names the model may call (case apart); empty = all the
    /// declared ones. What the configuration of the server says in
    /// <c>AllowedActions</c>.</summary>
    property Allowed: TArray<string> read GetAllowed write SetAllowed;
    /// <summary>How long <see cref="Invoke" /> waits for the client.</summary>
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs;
    /// <summary>Longer results are cut before reaching the model: the client
    /// cuts them too, and is not taken at its word.</summary>
    property ResultMaxChars: Integer read FResultMaxChars write FResultMaxChars;
  end;

/// <summary>The outcome as it travels between a client and a server: done,
/// denied, unknown, failed, timeout, cancelled.</summary>
function HelpChatActionOutcomeName(const AOutcome: THelpChatActionOutcome): string;
/// <summary>The outcome of that name (case apart); False for any other
/// text.</summary>
function HelpChatActionOutcomeFromName(const AName: string;
  out AOutcome: THelpChatActionOutcome): Boolean;

/// <summary>The actions every assistant of the application may use: register
/// here what makes sense whichever form the user is on (open a screen, say,
/// or search the customers), once. Each component consults it unless its
/// <c>UseSharedActions</c> is False, and a profile can narrow it like the
/// component's own with <c>AllowedActions</c>.</summary>
function HelpChatSharedActions: THelpChatActionBroker;

/// <summary>The outcome as the sentence the model reads.</summary>
function HelpChatActionOutcomeText(const AOutcome: THelpChatActionOutcome;
  const AName, AResult: string): string;

/// <summary>What the user is asked before an action runs: the name and the
/// description of the action (which the application wrote), then the values
/// the model wants to pass, one per line and cut short, under a label saying
/// who wrote them. The question comes last. Used by the default dialog of the
/// VCL component; an application with its own <c>OnActionConfirm</c> may use
/// it too.</summary>
function HelpChatActionConfirmText(const AName, ADescription: string;
  const AArgs: THelpChatActionArgs; const ALanguage: THelpChatLanguage): string; overload;
/// <summary>The same for a registered action: the values are labelled with
/// the descriptions of its parameters (<see cref="THelpChatAction.ParamLabel" />).</summary>
function HelpChatActionConfirmText(const AAction: THelpChatAction;
  const AArgs: THelpChatActionArgs; const ALanguage: THelpChatLanguage): string; overload;
/// <summary>The short form of a parameter description, for a label: up to
/// the first punctuation, at most <c>AMaxChars</c> characters.</summary>
function HelpChatShortLabel(const ADescription: string; const AMaxChars: Integer = 40): string;
/// <summary>True when the arguments of a call are usable: nothing at all, or
/// one whole JSON object. False for a text that was cut (a reply stopped at
/// the token limit in the middle of a call) or is not an object: read as "no
/// arguments", such a call ran its action with every parameter missing.</summary>
function HelpChatActionArgsAreWhole(const AArgsJson: string): Boolean;

implementation

uses
  System.DateUtils,
  System.Diagnostics;

function HelpChatActionOutcomeText(const AOutcome: THelpChatActionOutcome;
  const AName, AResult: string): string;
begin
  case AOutcome of
    aoDone:
      if Trim(AResult) <> '' then
        Result := AResult
      else
        Result := Format('The action "%s" was executed.', [AName]);
    aoDenied:
      if Trim(AResult) <> '' then
        Result := AResult
      else
        Result := Format(HELPCHAT_ACTION_DENIED_TEXT, [AName]);
    aoUnknown:   Result := Format('There is no action named "%s" in this application.', [AName]);
    aoFailed:    Result := Format('The action "%s" failed: %s', [AName, AResult]);
    aoTimeout:   Result := Format('The action "%s" did not answer in time.', [AName]);
    aoCancelled: Result := Format('The action "%s" was cancelled.', [AName]);
  else
    Result := AResult;
  end;
end;

function ConfirmTextOf(const AName, ADescription, ALines: string;
  const ALanguage: THelpChatLanguage): string;
var
  LLines: string;
begin
  LLines := ALines;
  if LLines <> '' then
    LLines := HelpChatMsg(hcmActionValues, ALanguage) + sLineBreak + LLines + sLineBreak + sLineBreak;
  Result := Format(HelpChatMsg(hcmActionConfirm, ALanguage),
    [AName, Trim(ADescription), LLines]);
end;

function HelpChatActionConfirmText(const AName, ADescription: string;
  const AArgs: THelpChatActionArgs; const ALanguage: THelpChatLanguage): string;
var
  LLines: string;
begin
  if Assigned(AArgs) then
    LLines := AArgs.ToDisplayLines
  else
    LLines := '';
  Result := ConfirmTextOf(AName, ADescription, LLines, ALanguage);
end;

function HelpChatActionConfirmText(const AAction: THelpChatAction;
  const AArgs: THelpChatActionArgs; const ALanguage: THelpChatLanguage): string;
var
  LLines: string;
begin
  if Assigned(AArgs) then
    LLines := AArgs.ToDisplayLines(AAction)
  else
    LLines := '';
  Result := ConfirmTextOf(AAction.Name, AAction.Description, LLines, ALanguage);
end;

function HelpChatActionArgsAreWhole(const AArgsJson: string): Boolean;
var
  LValue: TJSONValue;
begin
  if Trim(AArgsJson) = '' then
    Exit(True);
  try
    LValue := TJSONObject.ParseJSONValue(AArgsJson);
  except
    LValue := nil;
  end;
  Result := LValue is TJSONObject;
  LValue.Free;
end;

function HelpChatShortLabel(const ADescription: string; const AMaxChars: Integer): string;
var
  I: Integer;
begin
  Result := Trim(ADescription);
  for I := 1 to Length(Result) do
    if CharInSet(Result[I], ['.', ':', ',', ';', '(']) then
    begin
      Result := TrimRight(Copy(Result, 1, I - 1));
      Break;
    end;
  if (AMaxChars > 0) and (Length(Result) > AMaxChars) then
    Result := TrimRight(Copy(Result, 1, AMaxChars - 3)) + '...';
end;

function ParamKindName(const AKind: THelpChatActionParamKind): string;
begin
  case AKind of
    apkInteger: Result := 'integer';
    apkNumber:  Result := 'number';
    apkBoolean: Result := 'boolean';
    apkObject:  Result := 'object';
    apkArray:   Result := 'array';
  else
    Result := 'string';
  end;
end;

{ THelpChatActionParam }

class function THelpChatActionParam.Create(const AName, ADescription: string;
  const AKind: THelpChatActionParamKind; const ARequired: Boolean): THelpChatActionParam;
begin
  Result.Name := AName;
  Result.Description := ADescription;
  Result.Kind := AKind;
  Result.Required := ARequired;
  Result.Schema := '';
end;

class function THelpChatActionParam.Create(const AName, ADescription: string;
  const AKind: THelpChatActionParamKind; const ASchema: string;
  const ARequired: Boolean): THelpChatActionParam;
begin
  Result := Create(AName, ADescription, AKind, ARequired);
  Result.Schema := ASchema;
end;

{ THelpChatActionArgs }

constructor THelpChatActionArgs.Create(const AJson: string);
var
  LValue: TJSONValue;
  LPair: TJSONPair;
begin
  inherited Create;
  FValues := TDictionary<string, string>.Create;
  FRawJson := AJson;
  if Trim(AJson) = '' then
    Exit;
  try
    LValue := TJSONObject.ParseJSONValue(AJson);
  except
    LValue := nil; // a model can send nonsense: no arguments, not an exception
  end;
  if LValue = nil then
    Exit;
  try
    if LValue is TJSONObject then
      for LPair in TJSONObject(LValue) do
        // Everything is kept as text and converted on read: a model may send
        // 3, "3" or true for the same parameter.
        // A null is a parameter left out - models write one for every
        // optional parameter they do not use - and its Value is the text
        // 'null', which an action would have read as data.
        // An object or an array is kept as its JSON text: its Value is empty,
        // and the action would have read nothing at all.
        if (LPair.JsonValue is TJSONObject) or (LPair.JsonValue is TJSONArray) then
          FValues.AddOrSetValue(LPair.JsonString.Value.ToLower, LPair.JsonValue.ToJSON)
        else if not (LPair.JsonValue is TJSONNull) then
          FValues.AddOrSetValue(LPair.JsonString.Value.ToLower, LPair.JsonValue.Value);
  finally
    LValue.Free;
  end;
end;

destructor THelpChatActionArgs.Destroy;
begin
  FValues.Free;
  inherited;
end;

function THelpChatActionArgs.Has(const AName: string): Boolean;
begin
  Result := FValues.ContainsKey(AName.ToLower);
end;

function THelpChatActionArgs.AsString(const AName, ADefault: string): string;
begin
  if not FValues.TryGetValue(AName.ToLower, Result) then
    Result := ADefault;
end;

function THelpChatActionArgs.AsInteger(const AName: string; const ADefault: Integer): Integer;
var
  LText: string;
  LFloat: Double;
begin
  LText := Trim(AsString(AName));
  if TryStrToInt(LText, Result) then
    Exit;
  // 3.0 and 1e2 are whole numbers too, and some models write them so.
  if TryStrToFloat(LText, LFloat, HelpChatInvariantFormat) and (Frac(LFloat) = 0) and
     (Abs(LFloat) <= MaxInt) then
    Result := Trunc(LFloat)
  else
    Result := ADefault;
end;

function THelpChatActionArgs.AsFloat(const AName: string; const ADefault: Double): Double;
var
  LText: string;
begin
  LText := Trim(AsString(AName)).Replace(',', '.');
  Result := StrToFloatDef(LText, ADefault, HelpChatInvariantFormat);
end;

function THelpChatActionArgs.AsBoolean(const AName: string; const ADefault: Boolean): Boolean;
var
  LText: string;
begin
  LText := Trim(AsString(AName)).ToLower;
  if (LText = 'true') or (LText = '1') or (LText = 'yes') then
    Result := True
  else if (LText = 'false') or (LText = '0') or (LText = 'no') then
    Result := False
  else
    Result := ADefault;
end;

function THelpChatActionArgs.AsJson(const AName: string): TJSONValue;
var
  LText: string;
begin
  Result := nil;
  LText := Trim(AsString(AName));
  if (LText = '') or not CharInSet(LText[1], ['{', '[']) then
    Exit;
  try
    Result := TJSONObject.ParseJSONValue(LText);
  except
    Result := nil; // a string that only looks like JSON: no value, no exception
  end;
end;

function THelpChatActionArgs.Names: TArray<string>;
begin
  Result := FValues.Keys.ToArray;
end;

class function THelpChatActionArgs.DisplayValue(const AValue: string): string;
var
  I: Integer;
begin
  Result := AValue;
  // A line break or a tab inside a value is how a value pretends to be a
  // second line of the dialog: none of them survives.
  // The same for what Unicode calls a line or paragraph separator, and for
  // the characters that reverse the reading order of what follows them.
  for I := 1 to Length(Result) do
    if (Result[I] < ' ') or (Result[I] = #$7F) or (Result[I] = #$85) or
       (Result[I] = #$2028) or (Result[I] = #$2029) or
       ((Result[I] >= #$202A) and (Result[I] <= #$202E)) or
       ((Result[I] >= #$2066) and (Result[I] <= #$2069)) then
      Result[I] := ' ';
  Result := Trim(Result);
  if Length(Result) > HELPCHAT_ACTION_DISPLAY_MAXCHARS then
    Result := Copy(Result, 1, HELPCHAT_ACTION_DISPLAY_MAXCHARS - 3) + '...';
end;

class function THelpChatActionArgs.DisplayKey(const AKey: string): string;
begin
  Result := DisplayValue(AKey);
  if Length(Result) > HELPCHAT_ACTION_DISPLAY_KEY_MAXCHARS then
    Result := Copy(Result, 1, HELPCHAT_ACTION_DISPLAY_KEY_MAXCHARS - 3) + '...';
end;

function THelpChatActionArgs.ToDisplayString: string;
var
  LPair: TPair<string, string>;
begin
  Result := '';
  for LPair in FValues do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + DisplayKey(LPair.Key) + '=' + DisplayValue(LPair.Value);
  end;
end;

function THelpChatActionArgs.ToDisplayLines: string;
var
  LPair: TPair<string, string>;
begin
  Result := '';
  for LPair in FValues do
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + '  ' + DisplayKey(LPair.Key) + ' = ' + DisplayValue(LPair.Value);
  end;
end;

function THelpChatActionArgs.ToDisplayPairs(const AAction: THelpChatAction): TArray<TPair<string, string>>;
var
  LList: TList<TPair<string, string>>;
  LSeen: TList<string>;
  LKey, LValue: string;
  I: Integer;
begin
  LList := TList<TPair<string, string>>.Create;
  LSeen := TList<string>.Create;
  try
    if Assigned(AAction) then
      // The declared parameters first, in the order the application wrote
      // them: that is the order the user expects to read them in.
      for I := Low(AAction.Params) to High(AAction.Params) do
      begin
        LKey := AAction.Params[I].Name.ToLower;
        if FValues.TryGetValue(LKey, LValue) then
        begin
          LList.Add(TPair<string, string>.Create(
            AAction.ParamLabel(AAction.Params[I].Name), DisplayValue(LValue)));
          LSeen.Add(LKey);
        end;
      end;
    // Then whatever the model sent under a name nobody declared.
    for LKey in FValues.Keys do
      if not LSeen.Contains(LKey) then
        // The model wrote the name too: a name nobody declared is shown
        // short and on one line, like a value.
        LList.Add(TPair<string, string>.Create(DisplayKey(LKey), DisplayValue(FValues[LKey])));
    Result := LList.ToArray;
    if Assigned(AAction) and Assigned(AAction.OnDisplay) then
    begin
      LKey := AAction.Description;
      AAction.OnDisplay(Self, LKey, Result);
      // Whoever wrote them, they are shown as values: made safe the same way.
      for I := 0 to High(Result) do
        Result[I] := TPair<string, string>.Create(DisplayValue(Result[I].Key),
          DisplayValue(Result[I].Value));
    end;
  finally
    LSeen.Free;
    LList.Free;
  end;
end;

function THelpChatActionArgs.ToDisplayLines(const AAction: THelpChatAction): string;
var
  LPair: TPair<string, string>;
begin
  Result := '';
  if AAction = nil then
    Exit(ToDisplayLines);
  for LPair in ToDisplayPairs(AAction) do
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + LPair.Key + ': ' + LPair.Value;
  end;
end;

{ THelpChatAction }

constructor THelpChatAction.Create(const AName, ADescription: string;
  const AParams: TArray<THelpChatActionParam>; const AHandler: THelpChatActionProc;
  const AConfirm: Boolean);
begin
  inherited Create;
  FName := AName;
  FDescription := ADescription;
  FParams := AParams;
  FHandler := AHandler;
  FConfirm := AConfirm;
end;

function THelpChatAction.DisplaySummary(const AArgs: THelpChatActionArgs): string;
var
  LValues: TArray<TPair<string, string>>;
begin
  Result := FDescription;
  if Assigned(FOnDisplay) and Assigned(AArgs) then
  begin
    LValues := nil;
    FOnDisplay(AArgs, Result, LValues);
  end;
end;

function THelpChatAction.ParamLabel(const AName: string): string;
var
  I: Integer;
begin
  for I := Low(FParams) to High(FParams) do
    if SameText(FParams[I].Name, AName) then
    begin
      Result := HelpChatShortLabel(FParams[I].Description);
      if Result <> '' then
        Exit;
      Break;
    end;
  Result := AName;
end;

function THelpChatAction.ToToolJson: string;
var
  LRoot, LSchema, LProperties, LParam: TJSONObject;
  LCustom: TJSONValue;
  LRequired: TJSONArray;
  I: Integer;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('name', FName);
    LRoot.AddPair('description', FDescription);
    LSchema := TJSONObject.Create;
    LRoot.AddPair('input_schema', LSchema);
    LSchema.AddPair('type', 'object');
    LProperties := TJSONObject.Create;
    LSchema.AddPair('properties', LProperties);
    LRequired := TJSONArray.Create;
    for I := Low(FParams) to High(FParams) do
    begin
      LParam := nil;
      if Trim(FParams[I].Schema) <> '' then
      begin
        LCustom := TJSONObject.ParseJSONValue(FParams[I].Schema);
        if LCustom is TJSONObject then
          LParam := TJSONObject(LCustom)
        else
          LCustom.Free; // not an object: the bare type, as without a schema
      end;
      if LParam = nil then
      begin
        LParam := TJSONObject.Create;
        LParam.AddPair('type', ParamKindName(FParams[I].Kind));
      end
      else if LParam.GetValue('type') = nil then
        LParam.AddPair('type', ParamKindName(FParams[I].Kind));
      if LParam.GetValue('description') = nil then
        LParam.AddPair('description', FParams[I].Description);
      LProperties.AddPair(FParams[I].Name, LParam);
      if FParams[I].Required then
        LRequired.Add(FParams[I].Name);
    end;
    // An empty "required" is allowed but noise: only add it when it says something.
    if LRequired.Count > 0 then
      LSchema.AddPair('required', LRequired)
    else
      LRequired.Free;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

{ THelpChatActionRequest }

constructor THelpChatActionRequest.Create(const AName, AArgsJson: string);
var
  LGuid: TGUID;
begin
  inherited Create;
  CreateGUID(LGuid);
  FId := GUIDToString(LGuid).Trim(['{', '}']);
  FName := AName;
  FArgsJson := AArgsJson;
  FDone := TEvent.Create(nil, True, False, '');
  FOutcome := aoTimeout; // until somebody says otherwise
end;

destructor THelpChatActionRequest.Destroy;
begin
  FDone.Free;
  inherited;
end;

procedure THelpChatActionRequest.Complete(const AOutcome: THelpChatActionOutcome;
  const AResult: string);
begin
  FOutcome := AOutcome;
  FResult := AResult;
  FDone.SetEvent;
end;

procedure THelpChatActionRequest.Abandon;
begin
  FAbandoned := True;
end;

{ THelpChatActionBroker }

constructor THelpChatActionBroker.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FActions := TObjectDictionary<string, THelpChatAction>.Create([doOwnsValues]);
  FOrder := TList<string>.Create;
  // The requests are not the list's to free: whoever touches one last does -
  // Invoke, or Finish for one the waiter gave up on.
  FPending := TObjectList<THelpChatActionRequest>.Create(False);
  FEnabled := True;
  FHostActive := True;
  FTimeoutMs := HELPCHAT_DEF_ACTION_TIMEOUT_MS;
  FResultMaxChars := HELPCHAT_DEF_ACTION_RESULT_MAXCHARS;
end;

destructor THelpChatActionBroker.Destroy;
var
  LRequest: THelpChatActionRequest;
begin
  // Whoever is waiting must not wait for a broker that no longer exists.
  FLock.Enter;
  try
    for LRequest in FPending do
      LRequest.Complete(aoCancelled, '');
    FPending.Clear;
  finally
    FLock.Leave;
  end;
  FPending.Free;
  FOrder.Free;
  FActions.Free;
  FLock.Free;
  inherited;
end;

function THelpChatActionBroker.Add(const AName, ADescription: string;
  const AParams: array of THelpChatActionParam; const AHandler: THelpChatActionProc;
  const AConfirm: Boolean): THelpChatAction;
var
  LParams: TArray<THelpChatActionParam>;
  LKey: string;
  I: Integer;
begin
  if Trim(AName) = '' then
    raise EHelpChatError.Create('HelpChat action: the name is required');
  if not Assigned(AHandler) then
    raise EHelpChatError.CreateFmt('HelpChat action "%s": no handler', [AName]);
  SetLength(LParams, Length(AParams));
  for I := Low(AParams) to High(AParams) do
    LParams[I - Low(AParams)] := AParams[I];
  LKey := AName.Trim.ToLower;
  FLock.Enter;
  try
    if not FActions.ContainsKey(LKey) then
      FOrder.Add(LKey);
    Result := THelpChatAction.Create(AName.Trim, ADescription, LParams, AHandler, AConfirm);
    FActions.AddOrSetValue(LKey, Result);
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Add(const AName, ADescription: string;
  const AHandler: THelpChatActionProc; const AConfirm: Boolean): THelpChatAction;
begin
  Result := Add(AName, ADescription, [], AHandler, AConfirm);
end;

procedure THelpChatActionBroker.Remove(const AName: string);
var
  LKey: string;
begin
  LKey := AName.Trim.ToLower;
  FLock.Enter;
  try
    FActions.Remove(LKey);
    FOrder.Remove(LKey);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.Clear;
begin
  FLock.Enter;
  try
    FActions.Clear;
    FOrder.Clear;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Find(const AName: string): THelpChatAction;
begin
  FLock.Enter;
  try
    if not FActions.TryGetValue(AName.Trim.ToLower, Result) then
      Result := nil;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Count: Integer;
begin
  FLock.Enter;
  try
    Result := FActions.Count;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Names: TArray<string>;
var
  I: Integer;
  LAction: THelpChatAction;
begin
  FLock.Enter;
  try
    SetLength(Result, FOrder.Count);
    for I := 0 to FOrder.Count - 1 do
      if FActions.TryGetValue(FOrder[I], LAction) then
        Result[I] := LAction.Name;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.SetShared(const Value: THelpChatActionBroker);
begin
  if Value = Self then
    Exit;
  FLock.Enter;
  try
    FShared := Value;
    FSharedRef := Value; // kept alive as long as it is consulted
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.GetHostActive: Boolean;
begin
  FLock.Enter;
  try
    Result := FHostActive;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.SetHostActive(const Value: Boolean);
var
  LRequest: THelpChatActionRequest;
begin
  FLock.Enter;
  try
    FHostActive := Value;
    if Value then
      Exit;
    // What nobody took yet will never be taken: whoever waits is told now.
    // A call the host is already running (or asking the user about) is the
    // host's to finish, as usual.
    for LRequest in FPending do
      LRequest.Complete(aoCancelled, '');
    FPending.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.SetAllowed(const Value: TArray<string>);
var
  LName: string;
begin
  FLock.Enter;
  try
    FAllowed := nil;
    for LName in Value do
      if Trim(LName) <> '' then
        FAllowed := FAllowed + [Trim(LName).ToLower];
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.GetAllowed: TArray<string>;
begin
  FLock.Enter;
  try
    Result := Copy(FAllowed);
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.IsAllowed(const AName: string): Boolean;
var
  LName, LAllowed: string;
begin
  FLock.Enter;
  try
    if Length(FAllowed) = 0 then
      Exit(True);
    LName := AName.Trim.ToLower;
    for LAllowed in FAllowed do
      if LAllowed = LName then
        Exit(True);
    Result := False;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.Resolve(const AName: string): THelpChatAction;
var
  LShared: THelpChatActionBroker;
begin
  if not IsAllowed(AName) then
    Exit(nil);
  Result := Find(AName);
  if Result <> nil then
    Exit;
  FLock.Enter;
  try
    LShared := FShared;
  finally
    FLock.Leave;
  end;
  if Assigned(LShared) then
    Result := LShared.Find(AName);
end;

function THelpChatActionBroker.OwnToolJson(const AName: string): string;
var
  LAction: THelpChatAction;
begin
  Result := '';
  FLock.Enter;
  try
    if FActions.TryGetValue(AName.Trim.ToLower, LAction) then
      Result := LAction.ToToolJson;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.ToolJsonOf(const AName: string): string;
var
  LShared: THelpChatActionBroker;
begin
  Result := '';
  if not IsAllowed(AName) then
    Exit;
  Result := OwnToolJson(AName);
  if Result <> '' then
    Exit;
  FLock.Enter;
  try
    LShared := FShared;
  finally
    FLock.Leave;
  end;
  if Assigned(LShared) then
    Result := LShared.OwnToolJson(AName);
end;

function THelpChatActionBroker.AvailableNames: TArray<string>;
var
  LName: string;
  LShared: THelpChatActionBroker;
begin
  Result := nil;
  for LName in Names do
    if IsAllowed(LName) then
      Result := Result + [LName];
  FLock.Enter;
  try
    LShared := FShared;
  finally
    FLock.Leave;
  end;
  if Assigned(LShared) then
    for LName in LShared.Names do
      if IsAllowed(LName) and (Find(LName) = nil) then
        Result := Result + [LName];
end;

function THelpChatActionBroker.HasActions: Boolean;
begin
  Result := FEnabled and (Length(AvailableNames) > 0);
end;

function THelpChatActionBroker.ToolsJson: string;
var
  LArray: TJSONArray;
  LValue: TJSONValue;
  LName, LTool: string;
begin
  LArray := TJSONArray.Create;
  try
    if FEnabled then
      for LName in AvailableNames do
      begin
        LTool := ToolJsonOf(LName);
        if LTool = '' then
          Continue;
        LValue := TJSONObject.ParseJSONValue(LTool);
        if LValue <> nil then
          LArray.AddElement(LValue);
      end;
    Result := LArray.ToJSON;
  finally
    LArray.Free;
  end;
end;

function THelpChatActionBroker.PendingCount: Integer;
begin
  FLock.Enter;
  try
    Result := FPending.Count;
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionBroker.TakePending: TArray<THelpChatActionRequest>;
begin
  FLock.Enter;
  try
    Result := FPending.ToArray;
    FPending.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.Finish(const ARequest: THelpChatActionRequest;
  const AOutcome: THelpChatActionOutcome; const AResult: string);
begin
  FLock.Enter;
  try
    // Under the same lock as Forget: either the waiter is still there and
    // reads the answer (and frees the request afterwards), or it has gone
    // and the request is ours to free. Never both.
    if ARequest.Abandoned then
      ARequest.Free
    else
      ARequest.Complete(AOutcome, AResult);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionBroker.ExecutePending;
var
  LRequest: THelpChatActionRequest;
  LAction: THelpChatAction;
  LArgs: THelpChatActionArgs;
  LResult: string;
  LOutcome: THelpChatActionOutcome;
  LAllow: Boolean;
begin
  for LRequest in TakePending do
  begin
    LAction := Resolve(LRequest.Name);
    if (LAction = nil) or not FEnabled then
    begin
      Finish(LRequest, aoUnknown, '');
      Continue;
    end;
    LResult := '';
    LOutcome := aoDone;
    LArgs := THelpChatActionArgs.Create(LRequest.ArgsJson);
    try
      // Whatever raises in here - the confirmation of the application, a
      // text replaced with a wrong placeholder - the request is answered:
      // left alone, the worker waited its 60 seconds, the request was never
      // freed and the others of this batch were lost with it.
      try
        LAllow := True;
        // Anything that changes something asks first - unless nobody is
        // waiting for the answer any more, in which case there is nothing to ask.
        if LAction.Confirm and Assigned(FOnConfirm) and not LRequest.Abandoned then
          FOnConfirm(Self, LAction.Name, LArgs, LAllow);
        if not LAllow then
          LOutcome := aoDenied
        else if LRequest.Abandoned then
          // The user took longer than the model call could wait (or the reply
          // was cancelled meanwhile): the model has already been told the
          // action did not answer, so running it now would act behind its
          // back - and a retry would run it twice.
          LOutcome := aoTimeout
        else
          try
            LAction.Handler(LArgs, LResult);
            if (FResultMaxChars > 0) and (LResult.Length > FResultMaxChars) then
              LResult := LResult.Substring(0, FResultMaxChars);
          except
            on E: Exception do
            begin
              // The application's bug is the model's information, not a crash.
              LOutcome := aoFailed;
              LResult := E.Message;
            end;
          end;
      except
        on E: Exception do
        begin
          LOutcome := aoFailed;
          LResult := E.Message;
        end;
      end;
      // Apart: the action has run or not by now, and what a listener raises
      // must not change what the model is told about it.
      if Assigned(FOnExecuted) then
        try
          FOnExecuted(Self, LAction.Name, LOutcome, LResult);
        except
        end;
    finally
      LArgs.Free;
    end;
    Finish(LRequest, LOutcome, LResult);
  end;
end;

function THelpChatActionBroker.Forget(const ARequest: THelpChatActionRequest;
  out AOutcome: THelpChatActionOutcome; out AResult: string): Boolean;
var
  LOwn: Boolean;
begin
  Result := False;
  AOutcome := aoCancelled;
  AResult := '';
  FLock.Enter;
  try
    // Still queued: nobody has seen it. Already answered: the host is done
    // with it. Otherwise the host holds it - running the handler, or waiting
    // for the user to confirm - and will find it abandoned when it comes
    // back to Finish.
    LOwn := FPending.Remove(ARequest) >= 0;
    if not LOwn and (ARequest.Done.WaitFor(0) = wrSignaled) then
    begin
      LOwn := True;
      Result := True;
      AOutcome := ARequest.Outcome;
      AResult := ARequest.Result;
    end;
    if not LOwn then
      ARequest.Abandon;
  finally
    FLock.Leave;
  end;
  if LOwn then
    ARequest.Free;
end;

function THelpChatActionBroker.Invoke(const AName, AArgsJson: string;
  const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
var
  LRequest: THelpChatActionRequest;
  LWatch: TStopwatch;
  LWait: TWaitResult;
  LOutcome: THelpChatActionOutcome;
  LText: string;
begin
  AResult := '';
  if not FEnabled then
    Exit(aoUnknown);
  if Resolve(AName) = nil then
    Exit(aoUnknown);

  LRequest := THelpChatActionRequest.Create(AName, AArgsJson);
  try
    FLock.Enter;
    try
      // Asked and queued under one lock: a host that leaves between the two
      // would otherwise leave this call waiting for the whole timeout.
      if FHostActive then
        FPending.Add(LRequest)
      else
        FreeAndNil(LRequest);
    finally
      FLock.Leave;
    end;
    if LRequest = nil then
      Exit(aoCancelled);
    // The host is somewhere else (the main thread of the application, or a
    // client of the server): wake it up and wait for its answer.
    if Assigned(FOnPending) then
      FOnPending(Self);

    // A stopwatch, not the clock: the time of the machine may be set, or
    // moved an hour, while a confirmation is on the screen.
    LWatch := TStopwatch.StartNew;
    repeat
      // Short waits so that a cancelled reply does not keep a worker parked.
      LWait := LRequest.Done.WaitFor(100);
      if LWait = wrSignaled then
        Break;
      if Assigned(ACancel) and ACancel.IsCancelled then
      begin
        // Answered at the very last moment: the action ran, and that is
        // what the model must hear.
        if Forget(LRequest, Result, AResult) then
          Exit;
        Exit(aoCancelled);
      end;
    until LWatch.ElapsedMilliseconds > FTimeoutMs;

    // The request is freed by whoever touches it last: by this thread when
    // the host answered, by the host (Finish) when it still holds it. A
    // confirmation dialog that outlives the timeout is the common case.
    if LWait <> wrSignaled then
    begin
      if Forget(LRequest, Result, AResult) then
        Exit;
      Exit(aoTimeout);
    end;
    AResult := LRequest.Result;
    Result := LRequest.Outcome;
    LRequest.Free;
  except
    // Nothing leaves this method as an exception: the providers call it in
    // the middle of a reply. What raised here is the host being woken up.
    on E: Exception do
    begin
      if Assigned(LRequest) then
        Forget(LRequest, LOutcome, LText);
      AResult := E.Message;
      Result := aoFailed;
    end;
  end;
end;

var
  GSharedActions: THelpChatActionBroker;
  GSharedActionsRef: IHelpChatActionInvoker;

function HelpChatSharedActions: THelpChatActionBroker;
begin
  // Created on first use, on the main thread where an application registers
  // its actions; the reference keeps it alive until the unit goes.
  if GSharedActions = nil then
  begin
    GSharedActions := THelpChatActionBroker.Create;
    GSharedActionsRef := GSharedActions;
  end;
  Result := GSharedActions;
end;

{ Outcome names }

const
  OUTCOME_NAMES: array[THelpChatActionOutcome] of string = (
    'done', 'denied', 'unknown', 'failed', 'timeout', 'cancelled');
  // How often a waiting call looks at its cancellation token and its clock.
  RELAY_WAIT_SLICE_MS = 100;

function HelpChatActionOutcomeName(const AOutcome: THelpChatActionOutcome): string;
begin
  Result := OUTCOME_NAMES[AOutcome];
end;

function HelpChatActionOutcomeFromName(const AName: string;
  out AOutcome: THelpChatActionOutcome): Boolean;
var
  L: THelpChatActionOutcome;
begin
  AOutcome := aoFailed;
  for L := Low(THelpChatActionOutcome) to High(THelpChatActionOutcome) do
    if SameText(Trim(AName), OUTCOME_NAMES[L]) then
    begin
      AOutcome := L;
      Exit(True);
    end;
  Result := False;
end;

function RelayNameIsValid(const AName: string): Boolean;
var
  I: Integer;
begin
  Result := (AName <> '') and (Length(AName) <= 64);
  if Result then
    for I := 1 to Length(AName) do
      case AName[I] of
        'A'..'Z', 'a'..'z', '0'..'9', '_', '-': ;
      else
        Exit(False);
      end;
end;

{ THelpChatActionRelay.TCall }

destructor THelpChatActionRelay.TCall.Destroy;
begin
  Done.Free;
  inherited;
end;

{ THelpChatActionRelay }

constructor THelpChatActionRelay.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FCalls := TList<TCall>.Create;
  FTimeoutMs := HELPCHAT_RELAY_DEF_TIMEOUT_MS;
  FResultMaxChars := HELPCHAT_DEF_ACTION_RESULT_MAXCHARS;
end;

destructor THelpChatActionRelay.Destroy;
begin
  // Whoever waits holds a reference: nothing can be queued here.
  FCalls.Free;
  FLock.Free;
  inherited;
end;

function THelpChatActionRelay.GetAllowed: TArray<string>;
begin
  FLock.Enter;
  try
    Result := Copy(FAllowed);
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionRelay.SetAllowed(const Value: TArray<string>);
begin
  FLock.Enter;
  try
    FAllowed := Copy(Value);
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionRelay.Offers(const AName: string): Boolean;
var
  LName: string;
  LDeclared: Boolean;
begin
  LDeclared := False;
  for LName in FNames do
    if SameText(LName, AName) then
    begin
      LDeclared := True;
      Break;
    end;
  if not LDeclared then
    Exit(False);
  if Length(FAllowed) = 0 then
    Exit(True);
  for LName in FAllowed do
    if SameText(Trim(LName), AName) then
      Exit(True);
  Result := False;
end;

function THelpChatActionRelay.SetTools(const AJson: string; out AError: string): Boolean;
var
  LValue, LItem, LMember: TJSONValue;
  LTool: TJSONObject;
  LNames, LTools: TArray<string>;
  LName, LDescription, LSeen: string;
  LTwice: Boolean;
begin
  AError := '';
  LNames := nil;
  LTools := nil;
  try
    if Trim(AJson) <> '' then
    begin
      if Length(AJson) > HELPCHAT_RELAY_MAX_TOOLS_CHARS then
      begin
        AError := 'the declaration of the actions is too long';
        Exit(False);
      end;
      LValue := TJSONObject.ParseJSONValue(AJson);
      try
        if not (LValue is TJSONArray) then
        begin
          AError := 'the actions are not a JSON array';
          Exit(False);
        end;
        if TJSONArray(LValue).Count > HELPCHAT_RELAY_MAX_ACTIONS then
        begin
          AError := 'too many actions';
          Exit(False);
        end;
        for LItem in TJSONArray(LValue) do
        begin
          if not (LItem is TJSONObject) then
          begin
            AError := 'an action is not a JSON object';
            Exit(False);
          end;
          LName := '';
          LMember := TJSONObject(LItem).GetValue('name');
          if LMember is TJSONString then
            LName := TJSONString(LMember).Value;
          if not RelayNameIsValid(LName) then
          begin
            AError := 'an action has no valid name';
            Exit(False);
          end;
          LDescription := '';
          LMember := TJSONObject(LItem).GetValue('description');
          if LMember is TJSONString then
            LDescription := TJSONString(LMember).Value;
          LMember := TJSONObject(LItem).GetValue('input_schema');
          if not (LMember is TJSONObject) then
          begin
            AError := Format('the action "%s" has no input_schema', [LName]);
            Exit(False);
          end;
          LTwice := False;
          for LSeen in LNames do
            if SameText(LSeen, LName) then
              LTwice := True;
          if LTwice then
            Continue;
          // Written again member by member: whatever else the client put
          // in the object stays here.
          LTool := TJSONObject.Create;
          try
            LTool.AddPair('name', LName);
            LTool.AddPair('description', LDescription);
            LTool.AddPair('input_schema', TJSONValue(LMember.Clone));
            LNames := LNames + [LName];
            LTools := LTools + [LTool.ToJSON];
          finally
            LTool.Free;
          end;
        end;
      finally
        LValue.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      AError := 'the actions could not be read';
      Exit(False);
    end;
  end;
  FLock.Enter;
  try
    FNames := LNames;
    FTools := LTools;
  finally
    FLock.Leave;
  end;
  Result := True;
end;

function THelpChatActionRelay.HasActions: Boolean;
var
  LName: string;
begin
  Result := False;
  FLock.Enter;
  try
    if not FClosed then
      for LName in FNames do
        if Offers(LName) then
          Exit(True);
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionRelay.ToolsJson: string;
var
  I: Integer;
begin
  Result := '';
  FLock.Enter;
  try
    if not FClosed then
      for I := 0 to High(FNames) do
        if Offers(FNames[I]) then
        begin
          if Result <> '' then
            Result := Result + ',';
          Result := Result + FTools[I];
        end;
  finally
    FLock.Leave;
  end;
  Result := '[' + Result + ']';
end;

function THelpChatActionRelay.Invoke(const AName, AArgsJson: string;
  const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
var
  LCall: TCall;
  LWatch: TStopwatch;
  LGaveUp: THelpChatActionOutcome;
begin
  AResult := '';
  try
    FLock.Enter;
    try
      if FClosed then
        Exit(aoCancelled);
      if not Offers(AName) then
        Exit(aoUnknown);
      LCall := TCall.Create;
      LCall.Id := TGUID.NewGuid.ToString.Replace('{', '').Replace('}', '').Replace('-', '').ToLower;
      LCall.Name := AName;
      LCall.ArgsJson := AArgsJson;
      LCall.Done := TEvent.Create(nil, True, False, '');
      FCalls.Add(LCall);
    finally
      FLock.Leave;
    end;
    LGaveUp := aoTimeout;
    LWatch := TStopwatch.StartNew;
    while LCall.Done.WaitFor(RELAY_WAIT_SLICE_MS) <> wrSignaled do
    begin
      if Assigned(ACancel) and ACancel.IsCancelled then
      begin
        LGaveUp := aoCancelled;
        Break;
      end;
      if LWatch.ElapsedMilliseconds >= FTimeoutMs then
        Break;
    end;
    // Under the lock Complete answers with: an answer that arrived between
    // the last wait and here is the answer, not a timeout the model would
    // retry for something already done.
    FLock.Enter;
    try
      FCalls.Remove(LCall);
      if LCall.Answered then
      begin
        Result := LCall.Outcome;
        AResult := LCall.Result;
      end
      else
        Result := LGaveUp;
    finally
      FLock.Leave;
    end;
    LCall.Free;
    if (FResultMaxChars > 0) and (Length(AResult) > FResultMaxChars) then
      AResult := Copy(AResult, 1, FResultMaxChars);
  except
    on E: Exception do
    begin
      AResult := E.Message;
      Result := aoFailed;
    end;
  end;
end;

function THelpChatActionRelay.HasUndelivered: Boolean;
var
  LCall: TCall;
begin
  Result := False;
  FLock.Enter;
  try
    for LCall in FCalls do
      if not LCall.Delivered and not LCall.Answered then
        Exit(True);
  finally
    FLock.Leave;
  end;
end;

function THelpChatActionRelay.TakeCallsJson: string;
var
  LRoot, LItem: TJSONObject;
  LItems: TJSONArray;
  LCall: TCall;
begin
  LRoot := TJSONObject.Create;
  try
    LItems := TJSONArray.Create;
    LRoot.AddPair('calls', LItems);
    FLock.Enter;
    try
      for LCall in FCalls do
        if not LCall.Delivered and not LCall.Answered then
        begin
          LCall.Delivered := True;
          LItem := TJSONObject.Create;
          LItems.AddElement(LItem);
          LItem.AddPair('id', LCall.Id);
          LItem.AddPair('name', LCall.Name);
          LItem.AddPair('args', LCall.ArgsJson);
        end;
    finally
      FLock.Leave;
    end;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

function THelpChatActionRelay.Complete(const AId: string;
  const AOutcome: THelpChatActionOutcome; const AResult: string): Boolean;
var
  LCall: TCall;
begin
  Result := False;
  FLock.Enter;
  try
    for LCall in FCalls do
      if (LCall.Id = AId) and not LCall.Answered then
      begin
        LCall.Outcome := AOutcome;
        LCall.Result := AResult;
        LCall.Answered := True;
        LCall.Done.SetEvent;
        Exit(True);
      end;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatActionRelay.Close;
var
  LCall: TCall;
begin
  FLock.Enter;
  try
    FClosed := True;
    for LCall in FCalls do
      if not LCall.Answered then
      begin
        LCall.Outcome := aoCancelled;
        LCall.Result := '';
        LCall.Answered := True;
        LCall.Done.SetEvent;
      end;
  finally
    FLock.Leave;
  end;
end;

initialization

finalization
  GSharedActions := nil;
  GSharedActionsRef := nil;

end.
