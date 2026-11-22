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
///  Provider abstraction of the help chat. A provider turns the conversation
///  history plus the screen context into an assistant reply; a streaming
///  provider also emits the reply token by token. Providers register by name
///  in <see cref="THelpChatProviderRegistry" /> from their unit initialization,
///  so the active one is selected by <c>Settings.Provider</c> with no code
///  change on the call site. Ships the always-available <c>stub</c> provider.
///
///  This is the place where another AI system joins the library with the
///  least work: a class descending from <see cref="THelpChatProviderBase" />,
///  registered under a name, receives for each reply a private snapshot of
///  the settings, the retriever, the actions of the assistant that asked
///  (<see cref="IHelpChatActionInvoker" />: a neutral list of tools and a
///  blocking <c>Invoke</c>) and the attachments; it is handed the history
///  and the screen context, streams through a callback, honours a
///  cancellation token and returns the text. Store, workers, panel, HTTP
///  contract, confirmations and persistence are untouched. What a provider
///  outside the three built-in ones does not get for free is a section of
///  <c>THelpChatSettings</c> (<c>ModelFor</c> knows claude, openai and
///  gemini): it reads its configuration by itself, or from the section it
///  chooses to borrow.
/// </summary>
unit HelpChatAI.Provider;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Log,
  HelpChatAI.Settings,
  HelpChatAI.Actions,
  HelpChatAI.Attachments;

const
  /// <summary>The longest request body an llDebug entry carries, in
  /// characters: an attached PDF travels as base64 inside it.</summary>
  HELPCHAT_LOG_BODY_CHARS = 50000;
  /// <summary>Name of the always-available placeholder provider.</summary>
  HELPCHAT_PROVIDER_STUB = 'stub';

type
  /// <summary>
  ///  Contract every chat back-end implements. <c>Generate</c> returns the full
  ///  assistant reply; a streaming provider (<c>SupportsStreaming = True</c>)
  ///  additionally calls <c>AOnToken</c> for each token as it is produced. A
  ///  provider checks <c>ACancel</c> between steps and raises
  ///  <see cref="EHelpChatCancelled" /> when it flips.
  /// </summary>
  IHelpChatProvider = interface
    ['{4C6F8A21-2B3D-4E5F-9A10-7C1B2D3E4F50}']
    /// <summary>The registered provider name.</summary>
    function GetName: string;
    /// <summary>True if the provider emits tokens incrementally via AOnToken.</summary>
    function SupportsStreaming: Boolean;
    /// <summary>True if the provider can call the actions of the application
    /// (tool use). One that cannot simply ignores them.</summary>
    function SupportsActions: Boolean;
    /// <summary>True if the provider can be given documents and images. One
    /// that cannot says so in the conversation instead of answering as though
    /// it had read them.</summary>
    function SupportsDocuments: Boolean;
    /// <summary>What the user attached to this conversation. The runner hands
    /// it over before <c>Generate</c>, from its own copy: a provider never
    /// reads the live set.</summary>
    procedure SetAttachments(const AValue: TArray<THelpChatAttachment>);
    /// <summary>Produces the assistant reply for the given history and context.</summary>
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string;
  end;

  /// <summary>
  ///  One action the model asked for, as it arrives in the stream. The three
  ///  APIs deliver it differently - Anthropic in typed blocks, OpenAI in
  ///  fragments tied by an index, Gemini whole - and all three end up here.
  /// </summary>
  THelpChatToolCall = record
    /// <summary>Id of the call, quoted back with its result. Gemini may send none.</summary>
    Id: string;
    /// <summary>Name of the action.</summary>
    Name: string;
    /// <summary>Arguments, as a JSON object.</summary>
    InputJson: string;
    /// <summary>Opaque metadata the service attached to the call and wants
    /// back, unchanged, when the conversation continues: the
    /// <c>thoughtSignature</c> of a thinking Gemini model, which refuses the
    /// next request without it. Empty for everybody else.</summary>
    Signature: string;
    class function Create(const AId, AName, AInputJson: string;
      const ASignature: string = ''): THelpChatToolCall; static;
  end;

  /// <summary>The tokens of one request to a model, as the service counted
  /// them: what it read at full price, what it wrote to its prompt cache and
  /// what it read from there, and what it wrote back. The three inputs add
  /// up to the whole prompt.</summary>
  THelpChatTokenUsage = record
    /// <summary>The provider that made the request (<c>claude</c>...).</summary>
    Provider: string;
    /// <summary>The model the service answered with.</summary>
    Model: string;
    /// <summary>Input billed at the full price: what follows the last cache
    /// breakpoint, or everything when nothing was cached.</summary>
    InputTokens: Integer;
    /// <summary>Input written to the prompt cache by this request.</summary>
    CacheWriteTokens: Integer;
    /// <summary>Input read from the prompt cache.</summary>
    CacheReadTokens: Integer;
    /// <summary>Output, the thinking of the model included.</summary>
    OutputTokens: Integer;
  end;

  /// <summary>Receives the tokens of every request a provider makes, on the
  /// worker thread that made it.</summary>
  THelpChatTokenUsageProc = reference to procedure(const AUsage: THelpChatTokenUsage);

  /// <summary>
  ///  Convenience base class for providers: reference-counted, non-streaming by
  ///  default, holding the settings snapshot and the retriever handed by the
  ///  registry. Providers are short-lived: one instance per request.
  /// </summary>
  THelpChatProviderBase = class abstract(TInterfacedObject, IHelpChatProvider)
  strict private
    FSettings: THelpChatSettings;
    FRetriever: IHelpChatRetriever;
    FActions: IHelpChatActionInvoker;
    FAttachments: TArray<THelpChatAttachment>;
    FActionDenied: Boolean;
    FActionsInvoked: Integer;
  protected
    /// <summary>Settings snapshot of the request (not owned).</summary>
    property Settings: THelpChatSettings read FSettings;
    /// <summary>Documentation retriever, may be nil.</summary>
    property Retriever: IHelpChatRetriever read FRetriever;
    /// <summary>What the application lets the assistant do, may be nil.</summary>
    property Actions: IHelpChatActionInvoker read FActions;
    /// <summary>How a provider runs an action: through the broker, with one
    /// rule of its own - once the user has said no to an action of this
    /// reply, every later one is answered "not run" without asking. A
    /// refusal ends the plan, whatever the model makes of it: it is not
    /// told "create the company" and then asked "create the lead" anyway.
    /// A provider lives for one reply, so the rule does too.</summary>
    /// <summary>Whether the actions are declared to the model at all: when
    /// the host has some and the reply may take more than one request. With
    /// one request an action could be asked for and never run - there is no
    /// second request to tell the model how it went - so none is offered.</summary>
    function OffersActions(const AMaxRounds: Integer): Boolean;
    /// <summary>The last request a reply may make still asked for actions:
    /// they are not run, and the reply says so (through the token callback
    /// too, so the stream and the stored text agree) instead of ending as
    /// if they had been.</summary>
    procedure NoteActionsNotRun(const AText: TStringBuilder;
      const AOnToken: THelpChatTokenProc);
    /// <summary>The service stopped the reply at the limit of tokens
    /// (<c>MaxTokens</c>): the reply says so, the way
    /// <c>NoteActionsNotRun</c> does, instead of ending in the middle of a
    /// sentence - or, when the thinking of the model used the whole limit,
    /// as an empty answer.</summary>
    procedure NoteReplyCut(const AText: TStringBuilder;
      const AOnToken: THelpChatTokenProc);
    function InvokeAction(const AName, AArgsJson: string;
      const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
  public
    /// <summary>How many actions this reply asked to run (refused ones
    /// included): an answer that reports an action is not one to add a
    /// documentation source to.</summary>
    property ActionsInvoked: Integer read FActionsInvoked;
  protected
    /// <summary>The attachments of the conversation; empty when there are none.</summary>
    property Attachments: TArray<THelpChatAttachment> read FAttachments;
    /// <summary>The question with the text attachments in front of it, which
    /// is what every provider sends: only the bytes of a PDF or of an image
    /// travel differently from one API to the next.</summary>
    function QuestionWithAttachments(const AQuestion: string): string;
    /// <summary>The sentence to append to a reply when documents were attached
    /// and this provider cannot read them; empty when there is nothing to say.</summary>
    function UnreadDocumentsNotice: string;
    /// <summary>Localized string in the language of the settings.</summary>
    function Msg(const AId: THelpChatMsgId): string;
    /// <summary>The same, formatted with AArgs.</summary>
    function MsgFmt(const AId: THelpChatMsgId; const AArgs: array of const): string;
    /// <summary>Raises <see cref="EHelpChatCancelled" /> when the token is set.</summary>
    procedure CheckCancelled(const ACancel: IHelpChatCancelToken);
    /// <summary>One entry of the log through the settings of the request
    /// (which carry the conversation and the reply); nothing on a bare
    /// instance.</summary>
    procedure Log(const ALevel: THelpChatLogLevel; const ASeverity: THelpChatLogSeverity;
      const ACategory: THelpChatLogCategory; const AText: string; const AData: string = '');
    /// <summary>True when an entry of ALevel would be written.</summary>
    function Logs(const ALevel: THelpChatLogLevel): Boolean;
    /// <summary>llDebug: a request is about to go to AUrl, its body in the
    /// <c>Data</c> of the entry (cut at <c>HELPCHAT_LOG_BODY_CHARS</c>). The
    /// headers are never logged: the key is in them.</summary>
    procedure LogPost(const AUrl, ABody: string);
    /// <summary>llDebug: how the request to AUrl ended - status, time, and
    /// the body of a refusal.</summary>
    procedure LogPosted(const AUrl: string; const AStatus: Integer;
      const AStatusText: string; const AElapsedMs: Int64; const ARaw: string);
    /// <summary>llDetail, a warning: the request is repeated in another way
    /// (ARetry says which, AReason why).</summary>
    procedure LogRetry(const ARetry, AReason: string);
  public
    /// <summary>Content of the most recent user message (the current question).</summary>
    class function LastUserMessage(const AHistory: TArray<THelpChatMessage>): string; static;
    /// <summary>Virtual so the registry can instantiate providers polymorphically.
    /// <c>ASettings</c> must outlive the provider (the runner guarantees it).</summary>
    constructor Create(const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever;
      const AActions: IHelpChatActionInvoker = nil); virtual;
    /// <summary>Why this provider could not answer with these settings, as one
    /// sentence; empty when everything it needs is there. Asked on the class,
    /// before any request, by <c>HelpChatAI.Diagnostics</c> and by the design-time
    /// check: a provider that needs a key or a file says so here, so adding a
    /// provider still means a new unit and nothing else.</summary>
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; virtual;
    /// <summary>True for a provider that sends <see cref="BuildStablePrompt" />
    /// as its system prompt and <see cref="BuildQuestionContext" /> with the
    /// question, instead of <see cref="BuildSystemPrompt" /> whole: what
    /// <c>/prompt</c> shows follows it. False here.</summary>
    class function SplitsPrompt: Boolean; virtual;
    /// <summary>One short answer of the model to <c>AUser</c> under the
    /// system prompt <c>ASystem</c>: no history, no tools, no attachments,
    /// few tokens, its usage reported like a reply's. Empty here: a provider
    /// with no model behind it (<c>stub</c>, <c>docsearch</c>) has nothing to
    /// say, and an application's provider that does not override it simply
    /// gets no search terms. What <see cref="SearchTerms" /> calls.</summary>
    function CompleteText(const ASystem, AUser: string;
      const ACancel: IHelpChatCancelToken): string; virtual;
    /// <summary>The search terms of the model for the last question of
    /// <c>AHistory</c>, in the language of the manual, on one line; empty when
    /// the settings do not ask for them (<c>TranslatesSearch</c>), when the
    /// provider has no model, or when the request fails - the search then
    /// runs on the question alone. A cancellation is raised.</summary>
    function SearchTerms(const AHistory: TArray<THelpChatMessage>;
      const ACancel: IHelpChatCancelToken): string;
    /// <summary>What the translator receives: the last question of
    /// <c>AHistory</c>, preceded by the one before it when there is one
    /// ("e come la cancello?" needs it), each cut at
    /// <see cref="HELPCHAT_SEARCH_TERMS_MAX_CHARS" />.</summary>
    class function SearchTermsQuestion(const AHistory: TArray<THelpChatMessage>): string; static;
    /// <summary>A history of one user message, for <see cref="CompleteText" />.</summary>
    class function SingleQuestion(const AText: string): TArray<THelpChatMessage>; static;
    /// <summary>Hands the tokens of one request to
    /// <see cref="HelpChatOnTokenUsage" />, when somebody listens, with the
    /// name of this provider. On the worker thread of the request.</summary>
    procedure ReportTokenUsage(const AUsage: THelpChatTokenUsage);
    /// <summary>The system prompt every model gets: the instruction of the
    /// assistant (<c>THelpChatSettings.ResolveSystemPrompt</c>: the built-in
    /// rules or <c>SystemPrompt</c>, then <c>Instructions</c>), the language
    /// rule, the rule about a manual in another language, today's date, the
    /// screen the user is on and the documentation excerpts the retriever
    /// found - already limited to the areas of the manual this assistant
    /// knows. Nothing in it is provider specific, which is why it lives here:
    /// two providers that ground their answers differently would answer
    /// differently to the same question. The actions rule is not part of it:
    /// a provider that supports actions appends it.</summary>
    class function BuildSystemPrompt(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever): string; static;
    /// <summary>The part of the system prompt that does not change from one
    /// question to the next: who the assistant is, the instruction
    /// (<c>ResolveSystemPrompt</c>), the language and the language of the
    /// manual - what <see cref="BuildSystemPrompt" /> writes before now, the
    /// screen and the excerpts - then <c>OnBuildSystemPrompt</c>, on this
    /// part only. A provider that keeps it apart from
    /// <see cref="BuildQuestionContext" /> can have it kept in the prompt
    /// cache of its service (claude).</summary>
    class function BuildStablePrompt(const AContext: THelpChatContext;
      const ASettings: THelpChatSettings): string; static;
    /// <summary>What changes with every question, for the provider that sends
    /// it with the question: now (<c>NowRule</c>, unless an old
    /// <c>IdentityRule</c> says it), the screen the user is on and the
    /// documentation excerpts found for the last question.</summary>
    class function BuildQuestionContext(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever): string; static;
    /// <summary>The name the provider is registered under.</summary>
    function GetName: string; virtual; abstract;
    /// <summary>False here: a provider that calls <c>AOnToken</c> while it
    /// generates overrides it.</summary>
    function SupportsStreaming: Boolean; virtual;
    /// <summary>False here: a provider that declares <c>Actions.ToolsJson</c>
    /// to its model and runs what the model asks through <see
    /// cref="InvokeAction" /> overrides it.</summary>
    function SupportsActions: Boolean; virtual;
    /// <summary>False here: a provider that sends the bytes of a PDF or of an
    /// image overrides it. Asked on a bare instance (no settings) by the
    /// registry, so it must not read them.</summary>
    function SupportsDocuments: Boolean; virtual;
    /// <summary>The runner's copy of what the user attached, handed over
    /// before <c>Generate</c>.</summary>
    procedure SetAttachments(const AValue: TArray<THelpChatAttachment>);
    /// <summary>The reply to the last user message of AHistory. Runs on a
    /// worker thread, on a provider created for this reply alone. Whatever it
    /// raises becomes the error bubble of the reply, except <see
    /// cref="EHelpChatCancelled" />, which keeps what was streamed.</summary>
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; virtual; abstract;
  end;

  THelpChatProviderClass = class of THelpChatProviderBase;

  /// <summary>
  ///  The retriever a reply works with when its question was given search
  ///  terms (<c>THelpChatProviderBase.SearchTerms</c>): asked for that very
  ///  question, it searches the question plus the terms and drops the hint
  ///  of the screen - measured, the hint dragged the page of the screen over
  ///  the page the terms found (results/translation-v1.md of Test\LLMBench).
  ///  Any other query goes to the inner retriever as it is. The prompt and
  ///  the source line of the runner use it without knowing: no provider
  ///  changes how it searches. One per reply, on one worker thread.
  /// </summary>
  THelpChatTranslatedRetriever = class(TInterfacedObject, IHelpChatRetriever)
  strict private
    FInner: IHelpChatRetriever;
    FQuestion: string;
    FTerms: string;
  public
    constructor Create(const AInner: IHelpChatRetriever);
    /// <summary>The question the terms belong to, and the terms; empty terms
    /// leave every search as it was.</summary>
    procedure SetTerms(const AQuestion, ATerms: string);
    /// <summary>The terms in force, empty when none.</summary>
    property Terms: string read FTerms;
    function IsAvailable: Boolean;
    function GetBaseUrl: string;
    function Search(const AQuery, AHint: string; const AMaxPages: Integer): TArray<THelpChatDocPage>;
  end;

/// <summary>A value of the application as it may enter the system prompt:
/// one line, no control characters, no double quotes (the prompt quotes it),
/// at most <c>AMaxChars</c> characters. The screen label is the caption of a
/// form or of a tab, and a caption often carries the name of the record on
/// it - a name somebody else typed, which must not be able to read like a
/// line of the instruction.</summary>
function HelpChatPromptField(const AValue: string; const AMaxChars: Integer = 80): string;

/// <summary>"Saturday, 14 November 2026, 15:40 (UTC+01:00)": now, in English
/// (the model writes it back in the language it answers in), with the offset
/// of this machine - which is the user's for a local engine. What the
/// identity rule of the system prompt is given.</summary>
function HelpChatNowText: string;

/// <summary>
///  True when the model AName of ASettings could answer as it is configured:
///  its provider is registered and its <c>ConfigurationIssue</c> has nothing
///  to say once that model is applied - a key for <c>claude</c> and
///  <c>gemini</c>, a key for <c>openai</c> unless its endpoint is on this
///  machine or a private network, an index for <c>docsearch</c>. False for a name that is not in the list.
///  Works on a copy: ASettings is not touched. A key is resolved the way a
///  request resolves it, so <c>OnDecryptSecret</c> may be called.
/// </summary>
function HelpChatModelIsConfigured(const ASettings: THelpChatSettings;
  const AName: string): Boolean;

/// <summary>
///  The source line the engine adds to an answer that used the documentation
///  without linking it: "Source: [Leads](Leads.md), [FAQ](FAQ.md)", in the
///  language of the panel. Empty - nothing to add - when the answer already
///  carries the link of one of APages (the model cited, in its own way), or
///  when no page of APages is named in it by its title or by its file name
///  (the answer did not use them: the weather, an action done). The prompt
///  asks every model to cite; measured, Claude and gpt-oss still answered
///  "according to the documentation" or "Source: FAQ" now and then, and the
///  same prompt gave 8/8 one run and 6/8 the next. This makes it certain.
/// </summary>
function HelpChatSourcesLine(const AReply: string; const APages: TArray<THelpChatDocPage>;
  const ALanguage: THelpChatLanguage): string; overload;

/// <summary>
///  The same, with only the pages of <c>APages</c> that <c>AQueryPages</c>
///  also has eligible: the pages the words of the question reach by
///  themselves, without the screen. A page the screen alone brought says
///  where the user is, not what the answer is about - asked about the
///  weather on the Dashboard, a model declines and offers what it can do
///  "such as what the Dashboard tiles count", and the Dashboard was then
///  added as the source of a refusal (measured, Claude 5.5). A link to any
///  page of <c>APages</c> still means the model cited, and nothing is added.
///  What the runner calls.
/// </summary>
function HelpChatSourcesLine(const AReply: string; const APages: TArray<THelpChatDocPage>;
  const ALanguage: THelpChatLanguage;
  const AQueryPages: TArray<THelpChatDocPage>): string; overload;

const
  /// <summary>How many pages the search of the question alone may return
  /// when the runner asks which pages its words reach.</summary>
  HELPCHAT_SOURCES_QUERY_PAGES = 10;
  /// <summary>The output of a request for search terms, where the model does
  /// not think: a line of terms is short, and the cap is what stops a model
  /// that loops on synonyms (a local qwen3-coder did, for five
  /// minutes).</summary>
  HELPCHAT_SEARCH_TERMS_MAX_TOKENS = 150;
  /// <summary>The same where the model may think before answering (Claude
  /// 5.5 does unasked, the reasoning models of OpenAI and Gemini): the
  /// reasoning counts against the cap, and only what is produced is
  /// billed.</summary>
  HELPCHAT_SEARCH_TERMS_THINKING_TOKENS = 1024;
  /// <summary>The longest question, previous question and line of terms a
  /// search-terms request deals with, in characters.</summary>
  HELPCHAT_SEARCH_TERMS_MAX_CHARS = 500;

/// <summary>AJson with the number at APath (dotted: "generationConfig.
/// maxOutputTokens") set to AValue, the objects on the way created when
/// missing. How a provider turns the body of a reply into the body of a short
/// request without a second builder.</summary>
function HelpChatJsonSetNumber(const AJson, APath: string; const AValue: Integer): string;
/// <summary>The same for a string.</summary>
function HelpChatJsonSetString(const AJson, APath, AValue: string): string;

type
  /// <summary>
  ///  Process-global registry of providers, keyed by (case-insensitive) name.
  ///  An empty name is <c>stub</c>. A name nobody registered (a typo, or a
  ///  provider unit the application did not link) is not silently replaced by
  ///  the stub, whose polite placeholder would pass for a real answer: it gets
  ///  <see cref="THelpChatUnavailableProvider" />, which turns every request
  ///  into an error bubble naming the provider and the unit to add.
  /// </summary>
  THelpChatProviderRegistry = class
  strict private
    class var FProviders: TDictionary<string, THelpChatProviderClass>;
    class var FLock: TObject;
  public
    class constructor Create;
    class destructor Destroy;
    /// <summary>Makes AClass the provider called AName (case apart), replacing
    /// one already registered under that name. Called from the
    /// <c>initialization</c> of the unit of the provider - which therefore has
    /// to be linked by the application, and named by its uses clause when the
    /// library is used as packages.</summary>
    class procedure RegisterProvider(const AName: string; const AClass: THelpChatProviderClass);
    /// <summary>Removes the name; the <c>finalization</c> twin of
    /// <c>RegisterProvider</c>.</summary>
    class procedure UnregisterProvider(const AName: string);
    /// <summary>True when a provider is registered under AName. False for an
    /// empty name, which nevertheless runs as <c>stub</c>.</summary>
    class function IsRegistered(const AName: string): Boolean;
    /// <summary>The class registered under <c>AName</c>, or nil.</summary>
    class function FindProviderClass(const AName: string): THelpChatProviderClass;
    /// <summary>Instantiates the named provider: stub when AName is empty,
    /// THelpChatUnavailableProvider when nobody registered it.</summary>
    class function CreateProvider(const AName: string; const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever;
      const AActions: IHelpChatActionInvoker = nil): IHelpChatProvider;
    /// <summary>Sorted names of all registered providers.</summary>
    class function ProviderNames: TArray<string>;
    /// <summary>True when the named provider can be given documents. Asked
    /// before the panel shows its paper clip: offering to attach a PDF to a
    /// provider that cannot read one is a promise the answer would break.
    /// False for a name nobody registered.</summary>
    class function SupportsDocuments(const AName: string): Boolean;
  end;

  /// <summary>
  ///  Default provider (<c>stub</c>): returns a fixed, honest placeholder reply.
  ///  Validates the whole pipeline without any external dependency or API key.
  /// </summary>
  THelpChatStubProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>
  ///  Stands in for a provider that is configured but not registered: every
  ///  request fails with a configuration error saying which provider is
  ///  missing and which ones are available. Never registered itself.
  /// </summary>
  THelpChatUnavailableProvider = class(THelpChatProviderBase)
  strict private
    FRequestedName: string;
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
    /// <summary>The name the settings asked for.</summary>
    property RequestedName: string read FRequestedName write FRequestedName;
  end;

/// <summary>How the service behind a provider is called in a message to the
/// user: the name of the model in use when the settings have a list (a
/// "Groq" served by <c>openai</c> is Groq), else the display name of the
/// provider.</summary>
function HelpChatServiceName(const ASettings: THelpChatSettings; const AProvider: string): string;

/// <summary>The sentence of a refused request whose body carries no message
/// of the service, in the language of <c>ASettings</c> (which may be nil):
/// the service, the HTTP status and, when known, the address called -
/// without its query - and the model asked for. "Claude API error (HTTP 404)
/// from https://generativelanguage.googleapis.com/..." tells a provider
/// pointed at the endpoint of another service.</summary>
function HelpChatApiErrorText(const ASettings: THelpChatSettings; const AProvider: string;
  const AStatus: Integer; const AStatusText, AUrl: string): string;

var
  /// <summary>
  ///  A diagnostic hook: when assigned, the providers that read the usage of
  ///  the service (<c>claude</c>, <c>openai</c>, <c>gemini</c>; a local
  ///  server only when it sends one) report the tokens of every request they
  ///  make - one call per round of the tool loop - on the worker thread that
  ///  made it, so the handler must be thread-safe and quick. It is what
  ///  <c>Test\LLMBench</c> measures the prompt cache with; an application may
  ///  log costs with it. Set it before the engines start and leave it.
  /// </summary>
  HelpChatOnTokenUsage: THelpChatTokenUsageProc;

implementation

uses
  System.Generics.Defaults,
  System.RegularExpressions,
  System.TimeSpan,
  System.DateUtils,
  System.JSON;

/// <summary>AJson with AValue (owned) at APath.</summary>
function JsonSetValue(const AJson, APath: string; const AValue: TJSONValue): string;
var
  LRoot: TJSONValue;
  LObject, LChild: TJSONObject;
  LParts: TArray<string>;
  I: Integer;
begin
  LRoot := TJSONObject.ParseJSONValue(AJson);
  try
    if not (LRoot is TJSONObject) then
    begin
      AValue.Free;
      Exit(AJson);
    end;
    LObject := TJSONObject(LRoot);
    LParts := APath.Split(['.']);
    for I := 0 to High(LParts) - 1 do
    begin
      if LObject.GetValue(LParts[I]) is TJSONObject then
        LChild := TJSONObject(LObject.GetValue(LParts[I]))
      else
      begin
        // Missing, or there as something that cannot hold the value (a null,
        // a string): an object takes its place.
        LObject.RemovePair(LParts[I]).Free;
        LChild := TJSONObject.Create;
        LObject.AddPair(LParts[I], LChild);
      end;
      LObject := LChild;
    end;
    LObject.RemovePair(LParts[High(LParts)]).Free;
    LObject.AddPair(LParts[High(LParts)], AValue);
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

function HelpChatJsonSetNumber(const AJson, APath: string; const AValue: Integer): string;
begin
  Result := JsonSetValue(AJson, APath, TJSONNumber.Create(AValue));
end;

function HelpChatJsonSetString(const AJson, APath, AValue: string): string;
begin
  Result := JsonSetValue(AJson, APath, TJSONString.Create(AValue));
end;

{ THelpChatTranslatedRetriever }

constructor THelpChatTranslatedRetriever.Create(const AInner: IHelpChatRetriever);
begin
  inherited Create;
  FInner := AInner;
end;

procedure THelpChatTranslatedRetriever.SetTerms(const AQuestion, ATerms: string);
begin
  FQuestion := AQuestion;
  FTerms := Trim(ATerms);
end;

function THelpChatTranslatedRetriever.IsAvailable: Boolean;
begin
  Result := Assigned(FInner) and FInner.IsAvailable;
end;

function THelpChatTranslatedRetriever.GetBaseUrl: string;
begin
  if Assigned(FInner) then
    Result := FInner.GetBaseUrl
  else
    Result := '';
end;

function THelpChatTranslatedRetriever.Search(const AQuery, AHint: string;
  const AMaxPages: Integer): TArray<THelpChatDocPage>;
begin
  if not Assigned(FInner) then
    Exit(nil);
  if (FTerms <> '') and (AQuery = FQuestion) then
    Result := FInner.Search(AQuery + ' ' + FTerms, '', AMaxPages)
  else
    Result := FInner.Search(AQuery, AHint, AMaxPages);
end;

function HelpChatNowText: string;
var
  LOffset: TTimeSpan;
  LSign: string;
begin
  LOffset := TTimeZone.Local.UtcOffset;
  if LOffset.Ticks < 0 then
    LSign := '-'
  else
    LSign := '+';
  Result := Format('%s (UTC%s%.2d:%.2d)', [FormatDateTime('dddd, d mmmm yyyy, hh:nn', Now,
    HelpChatInvariantFormat), LSign, Abs(LOffset.Hours), Abs(LOffset.Minutes)]);
end;

function HelpChatModelIsConfigured(const ASettings: THelpChatSettings;
  const AName: string): Boolean;
var
  LCopy: THelpChatSettings;
  LName: string;
  LClass: THelpChatProviderClass;
begin
  Result := False;
  if not Assigned(ASettings) then
    Exit;
  LCopy := THelpChatSettings.Create;
  try
    LCopy.Assign(ASettings);
    if not LCopy.ApplyModel(AName) then
      Exit;
    LName := Trim(LCopy.Provider);
    if LName = '' then
      LName := HELPCHAT_PROVIDER_STUB;
    LClass := THelpChatProviderRegistry.FindProviderClass(LName);
    if (LClass = nil) and SameText(LName, HELPCHAT_PROVIDER_STUB) then
      LClass := THelpChatStubProvider;
    // What a provider needs, the provider says: the same question the
    // configuration check asks, and nothing else.
    Result := (LClass <> nil) and (LClass.ConfigurationIssue(LCopy) = '');
  finally
    LCopy.Free;
  end;
end;

function HelpChatSourcesLine(const AReply: string; const APages: TArray<THelpChatDocPage>;
  const ALanguage: THelpChatLanguage): string;
begin
  // Every page eligible: they are all reached by the question.
  Result := HelpChatSourcesLine(AReply, APages, ALanguage, APages);
end;

function HelpChatSourcesLine(const AReply: string; const APages: TArray<THelpChatDocPage>;
  const ALanguage: THelpChatLanguage; const AQueryPages: TArray<THelpChatDocPage>): string;

  function Named(const AWord: string): Boolean;
  begin
    Result := (Trim(AWord) <> '') and
      TRegEx.IsMatch(AReply, '(?<![\w-])' + TRegEx.Escape(Trim(AWord)) + '(?![\w-])', [roIgnoreCase]);
  end;

  function ReachedByTheQuestion(const AUrl: string): Boolean;
  var
    LQueryPage: THelpChatDocPage;
  begin
    for LQueryPage in AQueryPages do
      if SameText(LQueryPage.Url, AUrl) then
        Exit(True);
    Result := False;
  end;

var
  LPage: THelpChatDocPage;
  LLinks, LName: string;
begin
  Result := '';
  if (Trim(AReply) = '') or (Length(APages) = 0) then
    Exit;
  for LPage in APages do
    if (LPage.Url <> '') and AReply.Contains('(' + LPage.Url + ')') then
      Exit;
  LLinks := '';
  for LPage in APages do
  begin
    if (LPage.Url = '') or not ReachedByTheQuestion(LPage.Url) then
      Continue;
    // "Leads" or "Data model" as written, or "Draft-Proposal" the way the
    // file is called: either says the answer comes from that page.
    // The name as the user reads it, not as the link encodes it.
    LName := HelpChatDecodeUrlPath(
      ChangeFileExt(ExtractFileName(LPage.Url.Replace('/', '\')), ''));
    if not (Named(LPage.Title) or Named(LName)) then
      Continue;
    if LLinks <> '' then
      LLinks := LLinks + ', ';
    LLinks := LLinks + '[' + HelpChatPromptField(LPage.Title).Replace('[', '(').Replace(']', ')') +
      '](' + LPage.Url + ')';
  end;
  if LLinks <> '' then
    Result := HelpChatMsg(hcmSource, ALanguage) + ': ' + LLinks;
end;

function HelpChatPromptField(const AValue: string; const AMaxChars: Integer): string;
var
  LSb: TStringBuilder;
  LChar: Char;
  LSpace: Boolean;
begin
  LSb := TStringBuilder.Create;
  try
    LSpace := True; // so that leading blanks are dropped
    for LChar in AValue do
    begin
      if (LChar < ' ') or (LChar = ' ') then
      begin
        if not LSpace then
          LSb.Append(' ');
        LSpace := True;
      end
      else
      begin
        if LChar = '"' then
          LSb.Append('''')
        else
          LSb.Append(LChar);
        LSpace := False;
      end;
    end;
    Result := TrimRight(LSb.ToString);
  finally
    LSb.Free;
  end;
  if (AMaxChars > 0) and (Length(Result) > AMaxChars) then
    Result := Copy(Result, 1, AMaxChars - 3) + '...';
end;

class function THelpChatProviderRegistry.SupportsDocuments(const AName: string): Boolean;
var
  LClass: THelpChatProviderClass;
  LProvider: IHelpChatProvider;
begin
  LClass := FindProviderClass(AName);
  Result := Assigned(LClass);
  if Result then
  begin
    // The answer belongs to the provider, so it is asked - on an instance
    // that is created for the question and freed with the interface. No
    // settings, no retriever: nothing of what it needs to answer this.
    LProvider := LClass.Create(nil, nil, nil);
    Result := LProvider.SupportsDocuments;
  end;
end;

function HelpChatApiErrorText(const ASettings: THelpChatSettings; const AProvider: string;
  const AStatus: Integer; const AStatusText, AUrl: string): string;
var
  LLang: THelpChatLanguage;
  LSection: THelpChatModelSettings;
  LWhere, LModel: string;
  P: Integer;
begin
  LLang := hclAuto;
  LModel := '';
  if Assigned(ASettings) then
  begin
    LLang := ASettings.Language;
    LSection := ASettings.ModelFor(AProvider);
    if LSection <> nil then
      LModel := LSection.ResolveModel;
  end;
  LWhere := Trim(AUrl);
  P := LWhere.IndexOf('?');
  if P >= 0 then
    LWhere := LWhere.Substring(0, P);
  if (LWhere <> '') and (LModel <> '') then
    Result := HelpChatMsgFmt(hcmApiErrorAt, [HelpChatServiceName(ASettings, AProvider),
      AStatus, AStatusText, LWhere, LModel], LLang)
  else
    Result := HelpChatMsgFmt(hcmApiError, [HelpChatServiceName(ASettings, AProvider),
      AStatus, AStatusText], LLang);
end;

function HelpChatServiceName(const ASettings: THelpChatSettings; const AProvider: string): string;
begin
  Result := '';
  if Assigned(ASettings) then
    Result := Trim(ASettings.SelectedModel);
  if Result = '' then
    Result := HelpChatProviderDisplayName(AProvider);
end;

{ THelpChatProviderBase }

constructor THelpChatProviderBase.Create(const ASettings: THelpChatSettings;
  const ARetriever: IHelpChatRetriever; const AActions: IHelpChatActionInvoker);
begin
  inherited Create;
  FSettings := ASettings;
  FRetriever := ARetriever;
  FActions := AActions;
end;

procedure THelpChatProviderBase.SetAttachments(const AValue: TArray<THelpChatAttachment>);
begin
  FAttachments := AValue;
end;

function THelpChatProviderBase.SupportsDocuments: Boolean;
begin
  Result := False;
end;

function THelpChatProviderBase.QuestionWithAttachments(const AQuestion: string): string;
var
  LLanguage: THelpChatLanguage;
begin
  if Assigned(FSettings) then
    LLanguage := FSettings.Language
  else
    LLanguage := hclAuto;
  Result := HelpChatQuestionWithText(AQuestion, FAttachments, LLanguage);
end;

function THelpChatProviderBase.OffersActions(const AMaxRounds: Integer): Boolean;
begin
  Result := Assigned(FActions) and FActions.HasActions and (AMaxRounds > 1);
end;

procedure THelpChatProviderBase.NoteActionsNotRun(const AText: TStringBuilder;
  const AOnToken: THelpChatTokenProc);
var
  LNote: string;
begin
  Log(llInfo, lsWarning, lcAction,
    'The last request of the reply still asked for actions: they were not run');
  LNote := Msg(hcmActionsNotRun);
  if AText.Length > 0 then
    LNote := sLineBreak + sLineBreak + LNote;
  if Assigned(AOnToken) then
    AOnToken(LNote);
  AText.Append(LNote);
end;

function THelpChatActionOutcomeName(const AOutcome: THelpChatActionOutcome): string;
begin
  case AOutcome of
    aoDone: Result := 'done';
    aoDenied: Result := 'denied by the user';
    aoUnknown: Result := 'unknown action';
    aoFailed: Result := 'failed';
    aoTimeout: Result := 'timed out';
    aoCancelled: Result := 'cancelled';
  else
    Result := 'outcome ' + IntToStr(Ord(AOutcome));
  end;
end;

procedure THelpChatProviderBase.NoteReplyCut(const AText: TStringBuilder;
  const AOnToken: THelpChatTokenProc);
var
  LNote: string;
begin
  Log(llInfo, lsWarning, lcProvider,
    'The reply was cut at the limit of tokens (MaxTokens)');
  LNote := Msg(hcmReplyCut);
  if AText.Length > 0 then
    LNote := sLineBreak + sLineBreak + LNote;
  if Assigned(AOnToken) then
    AOnToken(LNote);
  AText.Append(LNote);
end;

function THelpChatProviderBase.InvokeAction(const AName, AArgsJson: string;
  const ACancel: IHelpChatCancelToken; out AResult: string): THelpChatActionOutcome;
var
  LStart: TDateTime;
begin
  Inc(FActionsInvoked);
  Log(llDetail, lsInfo, lcAction, Format('Action %s asked with %s',
    [AName, HelpChatLogQuote(AArgsJson)]));
  if FActionDenied then
  begin
    AResult := Format(HELPCHAT_ACTION_DENIED_BEFORE_TEXT, [AName]);
    Log(llInfo, lsWarning, lcAction, Format('Action %s: not run, the user ' +
      'refused an earlier action of this reply', [AName]));
    Exit(aoDenied);
  end;
  if not Assigned(FActions) then
  begin
    AResult := '';
    Log(llInfo, lsWarning, lcAction, Format('Action %s: no actions here', [AName]));
    Exit(aoUnknown);
  end;
  // A call cut in the middle of its arguments (the reply stopped at the
  // token limit) is not a call with no arguments: it is not run.
  if not HelpChatActionArgsAreWhole(AArgsJson) then
  begin
    AResult := HELPCHAT_ACTION_BROKEN_ARGS_TEXT;
    Log(llInfo, lsWarning, lcAction, Format('Action %s: not run, its arguments ' +
      'are not a whole JSON object', [AName]));
    Exit(aoFailed);
  end;
  LStart := Now;
  Result := FActions.Invoke(AName, AArgsJson, ACancel, AResult);
  if Result = aoDenied then
    FActionDenied := True;
  if Result = aoDone then
    Log(llInfo, lsInfo, lcAction, Format('Action %s: %s in %.1f s',
      [AName, THelpChatActionOutcomeName(Result), (Now - LStart) * SecsPerDay]))
  else
    Log(llInfo, lsWarning, lcAction, Format('Action %s: %s in %.1f s',
      [AName, THelpChatActionOutcomeName(Result), (Now - LStart) * SecsPerDay]));
  Log(llDebug, lsInfo, lcAction, Format('Action %s returned to the model: %s',
    [AName, HelpChatLogQuote(AResult)]));
end;

procedure THelpChatProviderBase.Log(const ALevel: THelpChatLogLevel;
  const ASeverity: THelpChatLogSeverity; const ACategory: THelpChatLogCategory;
  const AText, AData: string);
begin
  if Assigned(FSettings) then
    FSettings.Log(ALevel, ASeverity, ACategory, AText, '', '', AData);
end;

function THelpChatProviderBase.Logs(const ALevel: THelpChatLogLevel): Boolean;
begin
  Result := Assigned(FSettings) and FSettings.Logs(ALevel);
end;

procedure THelpChatProviderBase.LogPost(const AUrl, ABody: string);
begin
  if Logs(llDebug) then
    Log(llDebug, lsInfo, lcProvider, Format('%s: POST %s, %d characters',
      [GetName, AUrl, Length(ABody)]), Copy(ABody, 1, HELPCHAT_LOG_BODY_CHARS));
end;

procedure THelpChatProviderBase.LogPosted(const AUrl: string; const AStatus: Integer;
  const AStatusText: string; const AElapsedMs: Int64; const ARaw: string);
begin
  if not Logs(llDebug) then
    Exit;
  if AStatus >= 400 then
    Log(llDebug, lsError, lcProvider, Format('%s: %d %s from %s in %d ms: %s',
      [GetName, AStatus, AStatusText, AUrl, AElapsedMs,
       HelpChatLogQuote(ARaw, HELPCHAT_LOG_ERROR_BODY_CHARS)]))
  else
    Log(llDebug, lsInfo, lcProvider, Format('%s: %d from %s in %d ms',
      [GetName, AStatus, AUrl, AElapsedMs]));
end;

procedure THelpChatProviderBase.LogRetry(const ARetry, AReason: string);
begin
  Log(llDetail, lsWarning, lcProvider, Format('%s: %s (%s)',
    [GetName, ARetry, HelpChatLogQuote(AReason, HELPCHAT_LOG_ERROR_BODY_CHARS)]));
end;

function THelpChatProviderBase.UnreadDocumentsNotice: string;
begin
  if SupportsDocuments or not HelpChatHasBinary(FAttachments) then
    Result := ''
  else
    Result := Format(Msg(hcmAttachNotSupported), [GetName]);
end;

{ THelpChatToolCall }

class function THelpChatToolCall.Create(const AId, AName, AInputJson: string;
  const ASignature: string): THelpChatToolCall;
begin
  Result.Id := AId;
  Result.Name := AName;
  Result.InputJson := AInputJson;
  Result.Signature := ASignature;
end;

/// <summary>The language the prompt is written for: the one of the chat.</summary>
function PromptLanguage(const ASettings: THelpChatSettings): THelpChatLanguage;
begin
  if Assigned(ASettings) then
    Result := ASettings.ResolveLanguage
  else
    Result := HelpChatResolveLanguage(hclAuto);
end;

/// <summary>The rules of the assistant, each followed by a space: who it is
/// (the name the panel shows, the default one in the language of the chat
/// when nobody gave one), now when <c>AWithNow</c>, the instruction, the
/// language and the language of the manual. Every text comes from the
/// settings, whose defaults are the constants (English only: the model is
/// told the language of the reply).</summary>
procedure AppendRules(const ASb: TStringBuilder; const ASettings: THelpChatSettings;
  const ALang: THelpChatLanguage; const AWithNow: Boolean);
var
  LName, LText: string;
begin
  if Assigned(ASettings) and (Trim(ASettings.AssistantName) <> '') then
    LName := HelpChatPromptField(ASettings.AssistantName)
  else
    LName := HelpChatMsg(hcmUiTitle, ALang);
  if Assigned(ASettings) then
  begin
    // An identity rule written before 1.12 may still say now: it is the
    // only way it is said then, with or without AWithNow.
    ASb.Append(ASettings.ResolveIdentityRule(LName, HelpChatNowText)).Append(' ');
    if AWithNow then
    begin
      LText := ASettings.ResolveNowRule(HelpChatNowText);
      if LText <> '' then
        ASb.Append(LText).Append(' ');
    end;
    ASb.Append(ASettings.ResolveSystemPrompt).Append(' ');
    ASb.Append(ASettings.ResolveLanguageRule(ALang)).Append(' ');
    // A manual in another language: translate the words, keep the captions.
    LText := ASettings.ResolveDocLanguageRule(ALang);
    if LText <> '' then
      ASb.Append(LText).Append(' ');
  end
  else
  begin
    ASb.Append(Format(HELPCHAT_MODEL_DEF_IDENTITY_RULE, [LName])).Append(' ');
    if AWithNow then
      ASb.Append(Format(HELPCHAT_MODEL_DEF_NOW_RULE, [HelpChatNowText])).Append(' ');
    ASb.Append(HELPCHAT_MODEL_DEF_SYSTEMPROMPT).Append(' ');
    ASb.Append(Format(HELPCHAT_MODEL_DEF_LANGUAGE_RULE, [HelpChatLanguageName(ALang)]));
    ASb.Append(' ');
  end;
end;

/// <summary>llDetail: the pages a search found for the prompt; llDebug: the
/// query, the hint and the score of each.</summary>
procedure LogPagesFound(const ASettings: THelpChatSettings; const AQuery, AHint: string;
  const AMax: Integer; const APages: TArray<THelpChatDocPage>);
var
  LTitles, LScores: string;
  I: Integer;
begin
  LTitles := '';
  LScores := '';
  for I := 0 to High(APages) do
  begin
    if I > 0 then
    begin
      LTitles := LTitles + ', ';
      LScores := LScores + ', ';
    end;
    LTitles := LTitles + APages[I].Title;
    LScores := LScores + Format('%s (%d)', [APages[I].Title, APages[I].Score]);
  end;
  if Length(APages) = 0 then
    ASettings.Log(llDetail, lsInfo, lcSearch, 'No page of the manual found for the question')
  else
    ASettings.Log(llDetail, lsInfo, lcSearch, Format('%d of at most %d pages for the prompt: %s',
      [Length(APages), AMax, LTitles]));
  ASettings.Log(llDebug, lsInfo, lcSearch, Format('Search "%s", hint "%s": %s',
    [HelpChatLogQuote(AQuery), AHint, LScores]));
end;

/// <summary>The screen the user is on and the documentation excerpts the
/// retriever found for the last question, each part preceded by an empty
/// line.</summary>
procedure AppendScreenAndDocs(const ASb: TStringBuilder;
  const AHistory: TArray<THelpChatMessage>; const AContext: THelpChatContext;
  const ASettings: THelpChatSettings; const ARetriever: IHelpChatRetriever;
  const ALang: THelpChatLanguage);
var
  LPages: TArray<THelpChatDocPage>;
  LMax, I: Integer;
begin
  if not AContext.IsEmpty then
  begin
    ASb.Append(#10#10);
    // The label is a caption, the type a class name: data of the
    // application, cut to one short line each before entering the prompt.
    ASb.Append(HelpChatMsgFmt(hcmScreenContext, [HelpChatPromptField(AContext.DisplayName),
      HelpChatPromptField(AContext.ScreenType)], ALang));
  end;

  if Assigned(ASettings) then
    LMax := ASettings.ActiveModel.GroundingMaxPages
  else
    LMax := HELPCHAT_MODEL_DEF_GROUNDING;
  if (LMax > 0) and Assigned(ARetriever) and ARetriever.IsAvailable then
  begin
    LPages := ARetriever.Search(THelpChatProviderBase.LastUserMessage(AHistory),
      AContext.SearchHint, LMax);
    if Assigned(ASettings) and ASettings.Logs(llDetail) then
      LogPagesFound(ASettings, THelpChatProviderBase.LastUserMessage(AHistory),
        AContext.SearchHint, LMax, LPages);
    if Length(LPages) > 0 then
    begin
      ASb.Append(#10#10);
      ASb.Append(HelpChatMsg(hcmRelevantDocs, ALang));
      for I := Low(LPages) to High(LPages) do
      begin
        // Title, summary, the passages around the matching terms, source link.
        ASb.Append(#10#10);
        ASb.Append(Format('## %s'#10'%s', [LPages[I].Title, LPages[I].Summary]));
        if (LPages[I].Excerpt <> '') and (LPages[I].Excerpt <> LPages[I].Summary) then
          ASb.Append(#10#10).Append(LPages[I].Excerpt);
        // The link as the model must write it back: a Markdown link it
        // copies, with no URL to assemble (and none to invent).
        ASb.Append(#10).Append(Format('%s: [%s](%s)', [HelpChatMsg(hcmSource, ALang),
          HelpChatPromptField(LPages[I].Title), LPages[I].Url]));
      end;
    end;
  end;
end;

class function THelpChatProviderBase.BuildSystemPrompt(
  const AHistory: TArray<THelpChatMessage>; const AContext: THelpChatContext;
  const ASettings: THelpChatSettings; const ARetriever: IHelpChatRetriever): string;
var
  LLang: THelpChatLanguage;
  LSb: TStringBuilder;
begin
  LLang := PromptLanguage(ASettings);
  LSb := TStringBuilder.Create;
  try
    AppendRules(LSb, ASettings, LLang, True);
    AppendScreenAndDocs(LSb, AHistory, AContext, ASettings, ARetriever, LLang);
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
  // The application has the last word - before the rule about the actions,
  // which the providers add afterwards and nobody may change.
  if Assigned(ASettings) then
    Result := ASettings.CustomizePrompt(AContext, LLang, Result);
end;

class function THelpChatProviderBase.BuildStablePrompt(const AContext: THelpChatContext;
  const ASettings: THelpChatSettings): string;
var
  LLang: THelpChatLanguage;
  LSb: TStringBuilder;
begin
  LLang := PromptLanguage(ASettings);
  LSb := TStringBuilder.Create;
  try
    AppendRules(LSb, ASettings, LLang, False);
    Result := TrimRight(LSb.ToString);
  finally
    LSb.Free;
  end;
  // The last word of the application, on this part only: whatever it adds
  // here should not change from one question to the next, or the prompt
  // cache misses.
  if Assigned(ASettings) then
    Result := ASettings.CustomizePrompt(AContext, LLang, Result);
end;

class function THelpChatProviderBase.BuildQuestionContext(
  const AHistory: TArray<THelpChatMessage>; const AContext: THelpChatContext;
  const ASettings: THelpChatSettings; const ARetriever: IHelpChatRetriever): string;
var
  LLang: THelpChatLanguage;
  LSb: TStringBuilder;
begin
  LLang := PromptLanguage(ASettings);
  LSb := TStringBuilder.Create;
  try
    if Assigned(ASettings) then
      LSb.Append(ASettings.ResolveNowRule(HelpChatNowText))
    else
      LSb.Append(Format(HELPCHAT_MODEL_DEF_NOW_RULE, [HelpChatNowText]));
    AppendScreenAndDocs(LSb, AHistory, AContext, ASettings, ARetriever, LLang);
    Result := Trim(LSb.ToString);
  finally
    LSb.Free;
  end;
end;

class function THelpChatProviderBase.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
begin
  // A provider that needs nothing but the question answers with nothing to say.
  Result := '';
end;

class function THelpChatProviderBase.SplitsPrompt: Boolean;
begin
  Result := False;
end;

procedure THelpChatProviderBase.ReportTokenUsage(const AUsage: THelpChatTokenUsage);
var
  LUsage: THelpChatTokenUsage;
begin
  LUsage := AUsage;
  LUsage.Provider := GetName;
  if Logs(llDetail) then
    Log(llDetail, lsInfo, lcProvider, Format('%s tokens (%s): input %d, cache read %d, ' +
      'cache written %d, output %d', [GetName, LUsage.Model, LUsage.InputTokens,
       LUsage.CacheReadTokens, LUsage.CacheWriteTokens, LUsage.OutputTokens]),
      Format('{"provider":"%s","model":"%s","input":%d,"cacheRead":%d,' +
      '"cacheWrite":%d,"output":%d}', [GetName, LUsage.Model.Replace('"', ''),
       LUsage.InputTokens, LUsage.CacheReadTokens, LUsage.CacheWriteTokens,
       LUsage.OutputTokens]));
  if not Assigned(HelpChatOnTokenUsage) then
    Exit;
  HelpChatOnTokenUsage(LUsage);
end;

function THelpChatProviderBase.SupportsStreaming: Boolean;
begin
  Result := False;
end;

function THelpChatProviderBase.SupportsActions: Boolean;
begin
  Result := False;
end;

function THelpChatProviderBase.Msg(const AId: THelpChatMsgId): string;
begin
  if Assigned(FSettings) then
    Result := HelpChatMsg(AId, FSettings.Language)
  else
    Result := HelpChatMsg(AId);
end;

function THelpChatProviderBase.MsgFmt(const AId: THelpChatMsgId;
  const AArgs: array of const): string;
begin
  Result := Format(Msg(AId), AArgs);
end;

procedure THelpChatProviderBase.CheckCancelled(const ACancel: IHelpChatCancelToken);
begin
  if Assigned(ACancel) and ACancel.IsCancelled then
    raise EHelpChatCancelled.Create(Msg(hcmCancelled));
end;

class function THelpChatProviderBase.LastUserMessage(
  const AHistory: TArray<THelpChatMessage>): string;
var
  I: Integer;
begin
  Result := '';
  for I := High(AHistory) downto Low(AHistory) do
    if AHistory[I].Role = hcrUser then
      Exit(AHistory[I].Content);
end;

function THelpChatProviderBase.CompleteText(const ASystem, AUser: string;
  const ACancel: IHelpChatCancelToken): string;
begin
  Result := '';
end;

class function THelpChatProviderBase.SingleQuestion(const AText: string): TArray<THelpChatMessage>;
begin
  SetLength(Result, 1);
  Result[0].Id := THelpChatMessage.NewId;
  Result[0].Role := hcrUser;
  Result[0].Content := AText;
  Result[0].Created := Now;
end;

class function THelpChatProviderBase.SearchTermsQuestion(
  const AHistory: TArray<THelpChatMessage>): string;
var
  I: Integer;
  LQuestion, LPrevious: string;
begin
  LQuestion := '';
  LPrevious := '';
  for I := High(AHistory) downto Low(AHistory) do
    if (AHistory[I].Role = hcrUser) and (Trim(AHistory[I].Content) <> '') then
    begin
      if LQuestion = '' then
        LQuestion := Copy(Trim(AHistory[I].Content), 1, HELPCHAT_SEARCH_TERMS_MAX_CHARS)
      else
      begin
        LPrevious := Copy(Trim(AHistory[I].Content), 1, HELPCHAT_SEARCH_TERMS_MAX_CHARS);
        Break;
      end;
    end;
  if (LQuestion <> '') and (LPrevious <> '') then
    Result := 'Previous question: ' + LPrevious + #10 + 'Question: ' + LQuestion
  else
    Result := LQuestion;
end;

function THelpChatProviderBase.SearchTerms(const AHistory: TArray<THelpChatMessage>;
  const ACancel: IHelpChatCancelToken): string;
var
  LUser, LText: string;
  LStart: TDateTime;
begin
  Result := '';
  if not Assigned(FSettings) or not FSettings.TranslatesSearch(FSettings.Language) then
    Exit;
  LUser := SearchTermsQuestion(AHistory);
  if LUser = '' then
    Exit;
  CheckCancelled(ACancel);
  LStart := Now;
  Log(llDebug, lsInfo, lcSearch, 'Search terms asked for: ' + HelpChatLogQuote(LUser));
  try
    LText := CompleteText(FSettings.ResolveSearchTermsPrompt, LUser, ACancel);
  except
    on E: EHelpChatCancelled do
      raise;
    on E: Exception do
    begin
      // A translation that fails costs the translation, not the reply.
      CheckCancelled(ACancel);
      Log(llInfo, lsWarning, lcSearch, 'Translation of the question for the search ' +
        'failed, searched the question alone: ' + HelpChatLogQuote(E.Message,
        HELPCHAT_LOG_ERROR_BODY_CHARS));
      LText := '';
    end;
  end;
  CheckCancelled(ACancel);
  Result := Trim(string.Join(' ', LText.Split([#13, #10, #9], TStringSplitOptions.ExcludeEmpty)));
  Result := Copy(Result, 1, HELPCHAT_SEARCH_TERMS_MAX_CHARS);
  if Result <> '' then
    Log(llDetail, lsInfo, lcSearch, Format('Search terms in %.1f s: %s',
      [(Now - LStart) * SecsPerDay, Result]));
end;

{ THelpChatProviderRegistry }

class constructor THelpChatProviderRegistry.Create;
begin
  FLock := TObject.Create;
  FProviders := TDictionary<string, THelpChatProviderClass>.Create;
end;

class destructor THelpChatProviderRegistry.Destroy;
begin
  FProviders.Free;
  FLock.Free;
end;

class procedure THelpChatProviderRegistry.RegisterProvider(const AName: string;
  const AClass: THelpChatProviderClass);
begin
  TMonitor.Enter(FLock);
  try
    FProviders.AddOrSetValue(AName.Trim.ToLower, AClass);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class procedure THelpChatProviderRegistry.UnregisterProvider(const AName: string);
begin
  TMonitor.Enter(FLock);
  try
    FProviders.Remove(AName.Trim.ToLower);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function THelpChatProviderRegistry.IsRegistered(const AName: string): Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FProviders.ContainsKey(AName.Trim.ToLower);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function THelpChatProviderRegistry.FindProviderClass(
  const AName: string): THelpChatProviderClass;
begin
  TMonitor.Enter(FLock);
  try
    if not FProviders.TryGetValue(AName.Trim.ToLower, Result) then
      Result := nil;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function THelpChatProviderRegistry.CreateProvider(const AName: string;
  const ASettings: THelpChatSettings; const ARetriever: IHelpChatRetriever;
  const AActions: IHelpChatActionInvoker): IHelpChatProvider;
var
  LClass: THelpChatProviderClass;
  LUnavailable: THelpChatUnavailableProvider;
begin
  if Trim(AName) = '' then
  begin
    LClass := FindProviderClass(HELPCHAT_PROVIDER_STUB);
    if LClass = nil then
      LClass := THelpChatStubProvider;
  end
  else
    LClass := FindProviderClass(AName);
  if LClass = nil then
  begin
    LUnavailable := THelpChatUnavailableProvider.Create(ASettings, ARetriever, AActions);
    LUnavailable.RequestedName := Trim(AName);
    Exit(LUnavailable);
  end;
  // Instantiated outside the lock: a constructor may do real work.
  Result := LClass.Create(ASettings, ARetriever, AActions);
end;

class function THelpChatProviderRegistry.ProviderNames: TArray<string>;
begin
  TMonitor.Enter(FLock);
  try
    Result := FProviders.Keys.ToArray;
  finally
    TMonitor.Exit(FLock);
  end;
  TArray.Sort<string>(Result);
end;

{ THelpChatStubProvider }

function THelpChatStubProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_STUB;
end;

function THelpChatStubProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  CheckCancelled(ACancel);
  Result := Msg(hcmStubReply);
end;

{ THelpChatUnavailableProvider }

function THelpChatUnavailableProvider.GetName: string;
begin
  Result := FRequestedName;
end;

function THelpChatUnavailableProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  CheckCancelled(ACancel);
  raise EHelpChatConfigError.Create(MsgFmt(hcmProviderNotAvailable,
    [FRequestedName, string.Join(', ', THelpChatProviderRegistry.ProviderNames)]));
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_STUB, THelpChatStubProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_STUB);

end.
