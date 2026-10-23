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
///  Settings of the HelpChat engine, as <c>TPersistent</c> classes so the
///  VCL/FMX component can publish them and the IDE can stream them. Every
///  default lives here once, in shared constants, and is used both by the
///  property defaults and by the runtime readers. The engine snapshots the
///  settings (via <c>Assign</c>) for each request, so a provider always works
///  on a private copy and property changes take effect on the next message.
/// </summary>
unit HelpChatAI.Settings;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  HelpChatAI.Messages;

const
  HELPCHAT_DEF_PROVIDER = 'stub';
  HELPCHAT_DEF_POOLSIZE = 2;
  HELPCHAT_DEF_MSGMAXLEN = 4000;
  HELPCHAT_DEF_HISTMAXMSG = 50;
  HELPCHAT_DEF_STOREDMAXMSG = 200;
  HELPCHAT_DEF_CONVERSATION_MAXAGE_DAYS = 30;
  HELPCHAT_DEF_PERSIST = True;
  HELPCHAT_DEF_CONVERSATION_FILENAME = 'helpchatai-conversation.json';
  HELPCHAT_DEF_DOCINDEX_FILENAME = 'help-index.json';
  /// <summary>Name of the JSON configuration file, looked up next to the
  /// executable (application defaults) and in the per-user data folder (user
  /// overrides, typically the API key). See THelpChatSettings.LoadFromDefaultFiles.</summary>
  HELPCHAT_DEF_CONFIG_FILENAME = 'helpchatai.json';
  /// <summary>Timeout of the calls the remote transport makes on the UI thread
  /// (session, context, theme): short on purpose, a slow server must not freeze
  /// the application.</summary>
  HELPCHAT_REMOTE_DEF_TIMEOUTMS = 4000;

  // Defaults shared by every model provider: what differs between claude,
  // openai and gemini is the endpoint, the key and the name of the model, not
  // how many tokens to ask for or how much documentation to inject.
  HELPCHAT_MODEL_DEF_MAXTOKENS = 1024;
  HELPCHAT_MODEL_DEF_GROUNDING = 3;
  HELPCHAT_MODEL_DEF_GROUNDING_CHARS = 2000;
  HELPCHAT_MODEL_DEF_CONNECTTIMEOUTMS = 15000;
  HELPCHAT_MODEL_DEF_RESPONSETIMEOUTMS = 120000;
  /// <summary>Model call, actions, model call again: how many times at most.
  /// One means the model may ask, but the answer ends there.</summary>
  HELPCHAT_MODEL_DEF_MAXTOOLROUNDS = 4;
  /// <summary>Built-in system prompt, used when SystemPrompt is empty. It
  /// is an instruction to the model, not a UI string, so it is English only: the
  /// model is told to answer in the language of the user. It deliberately forbids
  /// generic answers: the assistant must stick to the documentation excerpts.</summary>
  HELPCHAT_MODEL_DEF_SYSTEMPROMPT =
    'You are the in-app help assistant of a desktop application. Your only job is to explain ' +
    'how to use this application. ' +
    'Base your answers ONLY on the documentation excerpts provided below and on the screen the ' +
    'user is on. If the excerpts do not cover the question, say so plainly and point the user to ' +
    'the documentation link instead of guessing: never describe generic software features and ' +
    'never invent menu items, buttons, options or behaviours that are not in the excerpts. ' +
    'When you use an excerpt, cite its page link. ' +
    'Be concise and practical: a few sentences or a short numbered list of steps. ' +
    'Use only light Markdown: bold, lists, links, inline code.';
  /// <summary>Appended to the system prompt with the configured language name:
  /// the chat speaks the language of the application, and follows the user only
  /// when the user clearly switches.</summary>
  HELPCHAT_MODEL_DEF_LANGUAGE_RULE =
    'The user interface of the application is in %0:s. Reply in %0:s, unless the user ' +
    'clearly writes in another language: in that case reply in the language of the user.';
  /// <summary>Added to the system prompt when the application registered
  /// actions: the model has to know that the tools change the application the
  /// user is looking at, not some sandbox.</summary>
  HELPCHAT_MODEL_ACTIONS_RULE =
    'You can also operate the application through the tools listed for you. They act on ' +
    'the running application of this very user: use one only when the user asks for ' +
    'something to be done, never to look up an answer, never to explore. Use the exact ' +
    'parameters declared, and ask the user for the ones you are missing instead of ' +
    'guessing. Do not announce what you are about to do: call the tools first, then say ' +
    'briefly what was actually done.';

  // The former names, kept because applications and documentation use them.
  HELPCHAT_CLAUDE_DEF_MAXTOKENS = HELPCHAT_MODEL_DEF_MAXTOKENS;
  HELPCHAT_CLAUDE_DEF_GROUNDING = HELPCHAT_MODEL_DEF_GROUNDING;
  HELPCHAT_CLAUDE_DEF_GROUNDING_CHARS = HELPCHAT_MODEL_DEF_GROUNDING_CHARS;
  HELPCHAT_CLAUDE_DEF_CONNECTTIMEOUTMS = HELPCHAT_MODEL_DEF_CONNECTTIMEOUTMS;
  HELPCHAT_CLAUDE_DEF_RESPONSETIMEOUTMS = HELPCHAT_MODEL_DEF_RESPONSETIMEOUTMS;
  HELPCHAT_CLAUDE_DEF_MAXTOOLROUNDS = HELPCHAT_MODEL_DEF_MAXTOOLROUNDS;
  HELPCHAT_CLAUDE_DEF_SYSTEMPROMPT = HELPCHAT_MODEL_DEF_SYSTEMPROMPT;
  HELPCHAT_CLAUDE_DEF_LANGUAGE_RULE = HELPCHAT_MODEL_DEF_LANGUAGE_RULE;
  HELPCHAT_CLAUDE_ACTIONS_RULE = HELPCHAT_MODEL_ACTIONS_RULE;

  // claude - Anthropic Messages API.
  HELPCHAT_CLAUDE_DEF_MODEL = 'claude-haiku-4-5';
  HELPCHAT_CLAUDE_DEF_VERSION = '2023-06-01';
  HELPCHAT_CLAUDE_DEF_BASEURL = 'https://api.anthropic.com';
  HELPCHAT_CLAUDE_APIKEY_ENVVAR = 'ANTHROPIC_API_KEY';

  // openai - Chat Completions. The same API is spoken by Azure OpenAI, Groq,
  // OpenRouter, Mistral, DeepSeek, Ollama and LM Studio: BaseUrl and Model are
  // all that separates them.
  HELPCHAT_OPENAI_DEF_MODEL = 'gpt-6-luna';
  HELPCHAT_OPENAI_DEF_BASEURL = 'https://api.openai.com';
  HELPCHAT_OPENAI_APIKEY_ENVVAR = 'OPENAI_API_KEY';
  /// <summary>api-version of Azure OpenAI, used only when AzureDeployment is set.</summary>
  HELPCHAT_OPENAI_DEF_AZURE_APIVERSION = '2024-10-21';

  // gemini - Google generateContent.
  HELPCHAT_GEMINI_DEF_MODEL = 'gemini-3.8-flash';
  HELPCHAT_GEMINI_DEF_BASEURL = 'https://generativelanguage.googleapis.com';
  HELPCHAT_GEMINI_APIKEY_ENVVAR = 'GEMINI_API_KEY';
  /// <summary>Read when GEMINI_API_KEY is empty: the name Google Cloud uses.</summary>
  HELPCHAT_GEMINI_APIKEY_ENVVAR_ALT = 'GOOGLE_API_KEY';

type
  /// <summary>
  ///  What every model provider needs, and in practice the only thing that
  ///  differs between them: a key, a model, an endpoint, how much to ask for
  ///  and how long to wait. A provider that needs more adds it in its own
  ///  class; one that needs nothing more (gemini) adds nothing at all.
  ///
  ///  Each lives under its own name in <c>helpchatai.json</c> and under its own
  ///  property of <see cref="THelpChatSettings" />: the one that matters at
  ///  run time is the one named by <c>Provider</c>, reachable as
  ///  <see cref="THelpChatSettings.ActiveModel" />.
  /// </summary>
  THelpChatModelSettings = class(TPersistent)
  private
    FApiKey: string;
    FModel: string;
    FMaxTokens: Integer;
    FGroundingMaxPages: Integer;
    FGroundingMaxChars: Integer;
    FSystemPrompt: string;
    FBaseUrl: string;
    FConnectTimeoutMs: Integer;
    FResponseTimeoutMs: Integer;
    FMaxToolRounds: Integer;
  public
    /// <summary>Model used when <c>Model</c> is empty.</summary>
    class function DefaultModel: string; virtual; abstract;
    /// <summary>Endpoint used when <c>BaseUrl</c> is empty.</summary>
    class function DefaultBaseUrl: string; virtual; abstract;
    /// <summary>Environment variable read when <c>ApiKey</c> is empty. Named
    /// in the message that tells the developer where to put the key.</summary>
    class function ApiKeyEnvVar: string; virtual; abstract;
    constructor Create; virtual;
    procedure Assign(Source: TPersistent); override;
    /// <summary>Name of this section in <c>helpchatai.json</c>, which is also the
    /// name of the property on <c>THelpChatSettings</c>.</summary>
    class function SectionName: string; virtual; abstract;
    /// <summary>The API key to use: <c>ApiKey</c> when set, else the
    /// environment variable of this provider, else empty.</summary>
    function ResolveApiKey: string; virtual;
    /// <summary>Base URL without trailing slash; the default when empty.</summary>
    function NormalizedBaseUrl: string;
    /// <summary>Model when set, else the default of this provider.</summary>
    function ResolveModel: string;
    /// <summary>SystemPrompt when set, else <see cref="HELPCHAT_MODEL_DEF_SYSTEMPROMPT" />.</summary>
    function ResolveSystemPrompt: string;
    /// <summary>MaxToolRounds, never below one.</summary>
    function ResolveMaxToolRounds: Integer;
    /// <summary>Reads the keys present in AObject; missing keys keep their value.</summary>
    procedure LoadFromJSONObject(const AObject: TJSONObject); virtual;
    /// <summary>Adds every setting to AObject.</summary>
    procedure SaveToJSONObject(const AObject: TJSONObject); virtual;
  published
    /// <summary>API key of the service. Empty = fall back to the environment
    /// variable. On a desktop the key is recoverable by whoever owns the
    /// machine: route the calls through your own server when that matters.</summary>
    property ApiKey: string read FApiKey write FApiKey;
    /// <summary>Empty = the default model of this provider.</summary>
    property Model: string read FModel write FModel;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens default HELPCHAT_MODEL_DEF_MAXTOKENS;
    /// <summary>Documentation pages injected into the system prompt (0 = off).</summary>
    property GroundingMaxPages: Integer read FGroundingMaxPages write FGroundingMaxPages default HELPCHAT_MODEL_DEF_GROUNDING;
    /// <summary>Characters of page text injected per page: the passages around
    /// the matching terms (0 = summary only).</summary>
    property GroundingMaxChars: Integer read FGroundingMaxChars write FGroundingMaxChars default HELPCHAT_MODEL_DEF_GROUNDING_CHARS;
    /// <summary>Replaces the built-in system prompt (HELPCHAT_MODEL_DEF_SYSTEMPROMPT) when not empty.</summary>
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    /// <summary>Empty = the default endpoint of this provider. This is the one
    /// setting that points a provider at another service altogether.</summary>
    property BaseUrl: string read FBaseUrl write FBaseUrl;
    property ConnectTimeoutMs: Integer read FConnectTimeoutMs write FConnectTimeoutMs default HELPCHAT_MODEL_DEF_CONNECTTIMEOUTMS;
    property ResponseTimeoutMs: Integer read FResponseTimeoutMs write FResponseTimeoutMs default HELPCHAT_MODEL_DEF_RESPONSETIMEOUTMS;
    /// <summary>How many times the model may ask for actions and be called
    /// again with their results, within one reply.</summary>
    property MaxToolRounds: Integer read FMaxToolRounds write FMaxToolRounds default HELPCHAT_MODEL_DEF_MAXTOOLROUNDS;
  end;

  THelpChatModelSettingsClass = class of THelpChatModelSettings;

  /// <summary>Settings of the <c>claude</c> provider (Anthropic Messages API).</summary>
  THelpChatClaudeSettings = class(THelpChatModelSettings)
  private
    FApiVersion: string;
  public
    class function DefaultModel: string; override;
    class function DefaultBaseUrl: string; override;
    class function ApiKeyEnvVar: string; override;
    constructor Create; override;
    procedure Assign(Source: TPersistent); override;
    class function SectionName: string; override;
    procedure LoadFromJSONObject(const AObject: TJSONObject); override;
    procedure SaveToJSONObject(const AObject: TJSONObject); override;
  published
    /// <summary>Value of the anthropic-version header.</summary>
    property ApiVersion: string read FApiVersion write FApiVersion;
  end;

  /// <summary>
  ///  Settings of the <c>openai</c> provider (Chat Completions). A dozen
  ///  services speak the same API: point <c>BaseUrl</c> at Groq, OpenRouter,
  ///  Mistral, DeepSeek, a local Ollama (<c>http://localhost:11434/v1</c>) or
  ///  LM Studio, set <c>Model</c>, and nothing else changes. Azure OpenAI is
  ///  the exception that needs one more thing: set <c>AzureDeployment</c> and
  ///  both the path and the authentication header change with it.
  /// </summary>
  THelpChatOpenAISettings = class(THelpChatModelSettings)
  private
    FOrganization: string;
    FAzureDeployment: string;
    FAzureApiVersion: string;
  public
    class function DefaultModel: string; override;
    class function DefaultBaseUrl: string; override;
    class function ApiKeyEnvVar: string; override;
    constructor Create; override;
    procedure Assign(Source: TPersistent); override;
    class function SectionName: string; override;
    /// <summary>True when the request must be shaped for Azure OpenAI.</summary>
    function IsAzure: Boolean;
    procedure LoadFromJSONObject(const AObject: TJSONObject); override;
    procedure SaveToJSONObject(const AObject: TJSONObject); override;
  published
    /// <summary>OpenAI-Organization header; empty = not sent.</summary>
    property Organization: string read FOrganization write FOrganization;
    /// <summary>Name of the Azure OpenAI deployment. Not empty = Azure: the
    /// path becomes /openai/deployments/&lt;name&gt;/chat/completions and the key
    /// travels in the api-key header instead of Authorization.</summary>
    property AzureDeployment: string read FAzureDeployment write FAzureDeployment;
    /// <summary>api-version query parameter of Azure OpenAI.</summary>
    property AzureApiVersion: string read FAzureApiVersion write FAzureApiVersion;
  end;

  /// <summary>Settings of the <c>gemini</c> provider (Google generateContent).</summary>
  THelpChatGeminiSettings = class(THelpChatModelSettings)
  public
    class function DefaultModel: string; override;
    class function DefaultBaseUrl: string; override;
    class function ApiKeyEnvVar: string; override;
    class function SectionName: string; override;
    /// <summary>GEMINI_API_KEY, else GOOGLE_API_KEY.</summary>
    function ResolveApiKey: string; override;
  end;

  /// <summary>
  ///  Where the conversation engine lives. Empty <c>BaseUrl</c> (the default) =
  ///  in this process, served by the local HTTP server. With a BaseUrl the
  ///  component talks to a HelpChat server instead: the API key of the model
  ///  stays there, the documentation index too, and this application only shows
  ///  the panel. Because these are plain settings, an installed application is
  ///  switched from local to remote by editing <c>helpchatai.json</c>.
  /// </summary>
  THelpChatRemoteSettings = class(TPersistent)
  private
    FBaseUrl: string;
    FAppKey: string;
    FUserId: string;
    FUserToken: string;
    FUseHostChannel: Boolean;
    FTimeoutMs: Integer;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    /// <summary>True when a remote server is configured (BaseUrl not empty).</summary>
    function IsConfigured: Boolean;
    /// <summary>BaseUrl without trailing slash.</summary>
    function NormalizedBaseUrl: string;
    /// <summary>The user id to send: <c>UserId</c> when set, else empty (the
    /// server then keeps the conversation per session, not per user).</summary>
    function ResolveUserId: string;
    procedure LoadFromJSONObject(const AObject: TJSONObject);
    procedure SaveToJSONObject(const AObject: TJSONObject);
  published
    /// <summary>Root URL of the HelpChat server, e.g. https://help.acme.com.
    /// Empty = the engine runs in this process.</summary>
    property BaseUrl: string read FBaseUrl write FBaseUrl;
    /// <summary>Key identifying this application to the server (not the model's
    /// API key: that one never leaves the server).</summary>
    property AppKey: string read FAppKey write FAppKey;
    /// <summary>Who is asking, when the application knows it: the server keeps
    /// one conversation per user and can apply quotas. Empty = anonymous.</summary>
    property UserId: string read FUserId write FUserId;
    /// <summary>Optional credential for UserId, validated by the server's
    /// OnAuthenticate hook against the application's own user store.</summary>
    property UserToken: string read FUserToken write FUserToken;
    /// <summary>Open a loopback channel so the page can talk to its host
    /// (close, and later file exchange). Off = the panel page has no ✕.</summary>
    property UseHostChannel: Boolean read FUseHostChannel write FUseHostChannel default True;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default HELPCHAT_REMOTE_DEF_TIMEOUTMS;
  end;

  /// <summary>Settings of the whole engine.</summary>
  THelpChatSettings = class(TPersistent)
  private
    FProvider: string;
    FPoolSize: Integer;
    FMessageMaxLength: Integer;
    FHistoryMaxMessages: Integer;
    FMaxStoredMessages: Integer;
    FGreeting: string;
    FLanguage: THelpChatLanguage;
    FDocIndexFile: string;
    FDocBaseUrl: string;
    FDocFolder: string;
    FPersistConversation: Boolean;
    FConversationFile: string;
    FConversationMaxAgeDays: Integer;
    FClaude: THelpChatClaudeSettings;
    FOpenAI: THelpChatOpenAISettings;
    FGemini: THelpChatGeminiSettings;
    FRemote: THelpChatRemoteSettings;
    procedure SetClaude(const Value: THelpChatClaudeSettings);
    procedure SetOpenAI(const Value: THelpChatOpenAISettings);
    procedure SetGemini(const Value: THelpChatGeminiSettings);
    procedure SetRemote(const Value: THelpChatRemoteSettings);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    /// <summary>The greeting to show: <c>Greeting</c> when set, else the localized default.</summary>
    function ResolveGreeting: string;
    /// <summary>The conversation file: <c>ConversationFile</c> when set, else
    /// <c>helpchatai-conversation.json</c> in the per-user application data folder.</summary>
    function ResolveConversationFile: string;
    /// <summary>The documentation index file: <c>DocIndexFile</c> when set, else
    /// <c>help-index.json</c> next to the executable (may not exist).</summary>
    function ResolveDocIndexFile: string;
    /// <summary>The folder of the Markdown pages shown in the panel:
    /// <c>DocFolder</c>, relative to the executable when not absolute; empty
    /// when not set (page links then keep their URL).</summary>
    function ResolveDocFolder: string;

    /// <summary>The section of the named provider, or nil for one that has no
    /// model behind it (stub, docsearch) or that nobody knows.</summary>
    function ModelFor(const AProvider: string): THelpChatModelSettings;
    /// <summary>The section <c>Provider</c> points at; the Claude one when the
    /// provider has no model of its own, so that whoever reads grounding or
    /// timeouts always has an answer.</summary>
    function ActiveModel: THelpChatModelSettings;

    /// <summary>Merges a JSON document into these settings: only the keys present
    /// are applied, so a partial file (e.g. just the API key) is fine. Keys are
    /// the property names, case-insensitive; <c>Language</c> is "auto", "en" or
    /// "it"; the Claude settings live in a nested <c>"Claude"</c> object.
    /// Raises EHelpChatConfigError on malformed JSON.</summary>
    procedure LoadFromJSON(const AJson: string);
    /// <summary>Every setting as a JSON document (the API key included: keep the
    /// file out of version control).</summary>
    function SaveToJSON: string;
    /// <summary>Merges AFileName (UTF-8 JSON) into these settings. False when the
    /// file does not exist; raises EHelpChatConfigError when it is malformed.</summary>
    function LoadFromFile(const AFileName: string): Boolean;
    /// <summary>Writes SaveToJSON to AFileName, creating the folder if needed.</summary>
    procedure SaveToFile(const AFileName: string);
    /// <summary>Loads, in order, <see cref="SharedUserConfigFile" />,
    /// <see cref="AppConfigFile" /> then <see cref="UserConfigFile" />, each if
    /// present; later files override earlier ones key by key. Returns the files
    /// actually loaded.</summary>
    function LoadFromDefaultFiles: TArray<string>;
    /// <summary>The configuration an application asks for: <c>AFileName</c>
    /// alone when it names one - that file and nothing else, relative to the
    /// executable when the path is not absolute - and otherwise the three
    /// default files, each if present. Returns what was actually read.
    /// Naming a file that is not there raises <c>EHelpChatConfigError</c>:
    /// asking for a configuration and silently running without it is how an
    /// application ships with the wrong settings and nobody notices.</summary>
    function LoadConfiguration(const AFileName: string): TArray<string>;
    /// <summary>helpchatai.json in the per-user HelpChatAI folder (%APPDATA%\HelpChat):
    /// settings shared by every HelpChat application of this user, typically the
    /// API key alone. Lowest priority.</summary>
    class function SharedUserConfigFile: string; static;
    /// <summary>helpchatai.json next to the executable: application defaults shipped
    /// with the program (provider, index, documentation URL).</summary>
    class function AppConfigFile: string; static;
    /// <summary>helpchatai.json in the per-application user data folder
    /// (%APPDATA%\&lt;ExeName&gt;): personal overrides for this application. Highest priority.</summary>
    class function UserConfigFile: string; static;
  published
    /// <summary>Registered provider name: stub, docsearch, claude (or a custom one).</summary>
    property Provider: string read FProvider write FProvider;
    /// <summary>Worker threads producing replies (1..n).</summary>
    property PoolSize: Integer read FPoolSize write FPoolSize default HELPCHAT_DEF_POOLSIZE;
    /// <summary>User messages are truncated to this length (0 = no limit).</summary>
    property MessageMaxLength: Integer read FMessageMaxLength write FMessageMaxLength default HELPCHAT_DEF_MSGMAXLEN;
    /// <summary>Most recent completed messages passed to the provider (0 = all).</summary>
    property HistoryMaxMessages: Integer read FHistoryMaxMessages write FHistoryMaxMessages default HELPCHAT_DEF_HISTMAXMSG;
    /// <summary>Messages kept in the conversation; older completed ones are pruned (0 = unlimited).</summary>
    property MaxStoredMessages: Integer read FMaxStoredMessages write FMaxStoredMessages default HELPCHAT_DEF_STOREDMAXMSG;
    /// <summary>First assistant bubble. Empty = localized default.</summary>
    property Greeting: string read FGreeting write FGreeting;
    property Language: THelpChatLanguage read FLanguage write FLanguage default hclAuto;
    /// <summary>JSON documentation index for docsearch and Claude grounding.</summary>
    property DocIndexFile: string read FDocIndexFile write FDocIndexFile;
    /// <summary>Prefix of the documentation links produced from the index.</summary>
    property DocBaseUrl: string read FDocBaseUrl write FDocBaseUrl;
    /// <summary>Folder of the Markdown documentation: when set, a link to one of
    /// its pages (a relative URL, or one starting with <c>DocBaseUrl</c>) opens
    /// inside the panel, rendered as HTML, instead of in the browser.</summary>
    property DocFolder: string read FDocFolder write FDocFolder;
    /// <summary>Save the conversation to disk and reload it at startup.</summary>
    property PersistConversation: Boolean read FPersistConversation write FPersistConversation default HELPCHAT_DEF_PERSIST;
    property ConversationFile: string read FConversationFile write FConversationFile;
    /// <summary>A persisted conversation older than this is discarded at load (0 = never).</summary>
    property ConversationMaxAgeDays: Integer read FConversationMaxAgeDays write FConversationMaxAgeDays default HELPCHAT_DEF_CONVERSATION_MAXAGE_DAYS;
    property Claude: THelpChatClaudeSettings read FClaude write SetClaude;
    /// <summary>Settings of the <c>openai</c> provider, and of every service
    /// that speaks the same API (BaseUrl + Model).</summary>
    property OpenAI: THelpChatOpenAISettings read FOpenAI write SetOpenAI;
    /// <summary>Settings of the <c>gemini</c> provider.</summary>
    property Gemini: THelpChatGeminiSettings read FGemini write SetGemini;
    /// <summary>Where the engine lives: in process (default) or on a server.</summary>
    property Remote: THelpChatRemoteSettings read FRemote write SetRemote;
  end;

/// <summary>Per-user writable data folder of the running application
/// (e.g. %LOCALAPPDATA%\&lt;ExeName&gt; on Windows), created on demand.</summary>
function HelpChatAppDataFolder: string;

implementation

uses
  System.IOUtils,
  HelpChatAI.Types;

// ---- JSON helpers: tolerant, case-insensitive readers (missing key = keep value)

function JsonFind(const AObject: TJSONObject; const AName: string): TJSONValue;
var
  LPair: TJSONPair;
begin
  Result := nil;
  if AObject = nil then
    Exit;
  for LPair in AObject do
    if SameText(LPair.JsonString.Value, AName) then
      Exit(LPair.JsonValue);
end;

function JsonStr(const AObject: TJSONObject; const AName: string; const ADefault: string): string;
var
  LValue: TJSONValue;
begin
  LValue := JsonFind(AObject, AName);
  if (LValue = nil) or (LValue is TJSONNull) then
    Result := ADefault
  else
    Result := LValue.Value;
end;

function JsonInt(const AObject: TJSONObject; const AName: string; const ADefault: Integer): Integer;
var
  LValue: TJSONValue;
begin
  LValue := JsonFind(AObject, AName);
  if LValue is TJSONNumber then
    Result := TJSONNumber(LValue).AsInt
  else if (LValue is TJSONString) and TryStrToInt(LValue.Value, Result) then
    Exit
  else
    Result := ADefault;
end;

function JsonBool(const AObject: TJSONObject; const AName: string; const ADefault: Boolean): Boolean;
var
  LValue: TJSONValue;
begin
  LValue := JsonFind(AObject, AName);
  if LValue is TJSONBool then
    Result := TJSONBool(LValue).AsBoolean
  else if (LValue is TJSONString) and TryStrToBool(LValue.Value, Result) then
    Exit
  else
    Result := ADefault;
end;

function LanguageToConfig(const ALanguage: THelpChatLanguage): string;
begin
  case ALanguage of
    hclEnglish: Result := 'en';
    hclItalian: Result := 'it';
  else
    Result := 'auto';
  end;
end;

function ConfigToLanguage(const AValue: string; const ADefault: THelpChatLanguage): THelpChatLanguage;
begin
  if SameText(AValue, 'en') or SameText(AValue, 'english') then
    Result := hclEnglish
  else if SameText(AValue, 'it') or SameText(AValue, 'italian') or SameText(AValue, 'italiano') then
    Result := hclItalian
  else if SameText(AValue, 'auto') then
    Result := hclAuto
  else
    Result := ADefault;
end;

function HelpChatAppDataFolder: string;
var
  LAppName: string;
begin
  LAppName := TPath.GetFileNameWithoutExtension(ParamStr(0));
  if LAppName = '' then
    LAppName := 'HelpChatAI';
  Result := TPath.Combine(TPath.GetHomePath, LAppName);
  if not TDirectory.Exists(Result) then
    try
      TDirectory.CreateDirectory(Result);
    except
      // A read-only profile must not break the chat: fall back to temp.
      Result := TPath.Combine(TPath.GetTempPath, LAppName);
      if not TDirectory.Exists(Result) then
        TDirectory.CreateDirectory(Result);
    end;
end;

{ THelpChatClaudeSettings }

{ THelpChatModelSettings }

constructor THelpChatModelSettings.Create;
begin
  inherited Create;
  FMaxTokens := HELPCHAT_MODEL_DEF_MAXTOKENS;
  FGroundingMaxPages := HELPCHAT_MODEL_DEF_GROUNDING;
  FGroundingMaxChars := HELPCHAT_MODEL_DEF_GROUNDING_CHARS;
  FConnectTimeoutMs := HELPCHAT_MODEL_DEF_CONNECTTIMEOUTMS;
  FResponseTimeoutMs := HELPCHAT_MODEL_DEF_RESPONSETIMEOUTMS;
  FMaxToolRounds := HELPCHAT_MODEL_DEF_MAXTOOLROUNDS;
  // Model and BaseUrl stay empty: Resolve* answers with the default of the
  // provider, so a file that never mentions them keeps following the library.
end;

procedure THelpChatModelSettings.Assign(Source: TPersistent);
var
  LSource: THelpChatModelSettings;
begin
  if Source is THelpChatModelSettings then
  begin
    LSource := THelpChatModelSettings(Source);
    FApiKey := LSource.FApiKey;
    FModel := LSource.FModel;
    FMaxTokens := LSource.FMaxTokens;
    FGroundingMaxPages := LSource.FGroundingMaxPages;
    FGroundingMaxChars := LSource.FGroundingMaxChars;
    FSystemPrompt := LSource.FSystemPrompt;
    FBaseUrl := LSource.FBaseUrl;
    FConnectTimeoutMs := LSource.FConnectTimeoutMs;
    FResponseTimeoutMs := LSource.FResponseTimeoutMs;
    FMaxToolRounds := LSource.FMaxToolRounds;
  end
  else
    inherited Assign(Source);
end;

function THelpChatModelSettings.ResolveApiKey: string;
begin
  Result := Trim(FApiKey);
  if Result = '' then
    Result := Trim(GetEnvironmentVariable(ApiKeyEnvVar));
end;

function THelpChatModelSettings.NormalizedBaseUrl: string;
begin
  Result := Trim(FBaseUrl);
  if Result = '' then
    Result := DefaultBaseUrl;
  while Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

function THelpChatModelSettings.ResolveModel: string;
begin
  Result := Trim(FModel);
  if Result = '' then
    Result := DefaultModel;
end;

function THelpChatModelSettings.ResolveSystemPrompt: string;
begin
  Result := Trim(FSystemPrompt);
  if Result = '' then
    Result := HELPCHAT_MODEL_DEF_SYSTEMPROMPT;
end;

function THelpChatModelSettings.ResolveMaxToolRounds: Integer;
begin
  Result := FMaxToolRounds;
  if Result < 1 then
    Result := 1;
end;

procedure THelpChatModelSettings.LoadFromJSONObject(const AObject: TJSONObject);
begin
  if AObject = nil then
    Exit;
  FApiKey := JsonStr(AObject, 'ApiKey', FApiKey);
  FModel := JsonStr(AObject, 'Model', FModel);
  FMaxTokens := JsonInt(AObject, 'MaxTokens', FMaxTokens);
  FGroundingMaxPages := JsonInt(AObject, 'GroundingMaxPages', FGroundingMaxPages);
  FGroundingMaxChars := JsonInt(AObject, 'GroundingMaxChars', FGroundingMaxChars);
  FSystemPrompt := JsonStr(AObject, 'SystemPrompt', FSystemPrompt);
  FBaseUrl := JsonStr(AObject, 'BaseUrl', FBaseUrl);
  FConnectTimeoutMs := JsonInt(AObject, 'ConnectTimeoutMs', FConnectTimeoutMs);
  FResponseTimeoutMs := JsonInt(AObject, 'ResponseTimeoutMs', FResponseTimeoutMs);
  FMaxToolRounds := JsonInt(AObject, 'MaxToolRounds', FMaxToolRounds);
end;

procedure THelpChatModelSettings.SaveToJSONObject(const AObject: TJSONObject);
begin
  AObject.AddPair('ApiKey', FApiKey);
  AObject.AddPair('Model', FModel);
  AObject.AddPair('MaxTokens', TJSONNumber.Create(FMaxTokens));
  AObject.AddPair('GroundingMaxPages', TJSONNumber.Create(FGroundingMaxPages));
  AObject.AddPair('GroundingMaxChars', TJSONNumber.Create(FGroundingMaxChars));
  AObject.AddPair('SystemPrompt', FSystemPrompt);
  AObject.AddPair('BaseUrl', FBaseUrl);
  AObject.AddPair('ConnectTimeoutMs', TJSONNumber.Create(FConnectTimeoutMs));
  AObject.AddPair('ResponseTimeoutMs', TJSONNumber.Create(FResponseTimeoutMs));
  AObject.AddPair('MaxToolRounds', TJSONNumber.Create(FMaxToolRounds));
end;

{ THelpChatClaudeSettings }

class function THelpChatClaudeSettings.DefaultModel: string;
begin
  Result := HELPCHAT_CLAUDE_DEF_MODEL;
end;

class function THelpChatClaudeSettings.DefaultBaseUrl: string;
begin
  Result := HELPCHAT_CLAUDE_DEF_BASEURL;
end;

class function THelpChatClaudeSettings.ApiKeyEnvVar: string;
begin
  Result := HELPCHAT_CLAUDE_APIKEY_ENVVAR;
end;

class function THelpChatClaudeSettings.SectionName: string;
begin
  Result := 'Claude';
end;

constructor THelpChatClaudeSettings.Create;
begin
  inherited Create;
  // Written out, unlike Model and BaseUrl: an application that was reading
  // Claude.Model or Claude.BaseUrl before these were resolvable keeps reading
  // the same strings.
  FModel := HELPCHAT_CLAUDE_DEF_MODEL;
  FBaseUrl := HELPCHAT_CLAUDE_DEF_BASEURL;
  FApiVersion := HELPCHAT_CLAUDE_DEF_VERSION;
end;

procedure THelpChatClaudeSettings.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is THelpChatClaudeSettings then
    FApiVersion := THelpChatClaudeSettings(Source).FApiVersion;
end;

procedure THelpChatClaudeSettings.LoadFromJSONObject(const AObject: TJSONObject);
begin
  inherited LoadFromJSONObject(AObject);
  if AObject = nil then
    Exit;
  FApiVersion := JsonStr(AObject, 'ApiVersion', FApiVersion);
end;

procedure THelpChatClaudeSettings.SaveToJSONObject(const AObject: TJSONObject);
begin
  inherited SaveToJSONObject(AObject);
  AObject.AddPair('ApiVersion', FApiVersion);
end;

{ THelpChatOpenAISettings }

class function THelpChatOpenAISettings.DefaultModel: string;
begin
  Result := HELPCHAT_OPENAI_DEF_MODEL;
end;

class function THelpChatOpenAISettings.DefaultBaseUrl: string;
begin
  Result := HELPCHAT_OPENAI_DEF_BASEURL;
end;

class function THelpChatOpenAISettings.ApiKeyEnvVar: string;
begin
  Result := HELPCHAT_OPENAI_APIKEY_ENVVAR;
end;

class function THelpChatOpenAISettings.SectionName: string;
begin
  Result := 'OpenAI';
end;

constructor THelpChatOpenAISettings.Create;
begin
  inherited Create;
  FAzureApiVersion := HELPCHAT_OPENAI_DEF_AZURE_APIVERSION;
end;

procedure THelpChatOpenAISettings.Assign(Source: TPersistent);
var
  LSource: THelpChatOpenAISettings;
begin
  inherited Assign(Source);
  if Source is THelpChatOpenAISettings then
  begin
    LSource := THelpChatOpenAISettings(Source);
    FOrganization := LSource.FOrganization;
    FAzureDeployment := LSource.FAzureDeployment;
    FAzureApiVersion := LSource.FAzureApiVersion;
  end;
end;

function THelpChatOpenAISettings.IsAzure: Boolean;
begin
  Result := Trim(FAzureDeployment) <> '';
end;

procedure THelpChatOpenAISettings.LoadFromJSONObject(const AObject: TJSONObject);
begin
  inherited LoadFromJSONObject(AObject);
  if AObject = nil then
    Exit;
  FOrganization := JsonStr(AObject, 'Organization', FOrganization);
  FAzureDeployment := JsonStr(AObject, 'AzureDeployment', FAzureDeployment);
  FAzureApiVersion := JsonStr(AObject, 'AzureApiVersion', FAzureApiVersion);
end;

procedure THelpChatOpenAISettings.SaveToJSONObject(const AObject: TJSONObject);
begin
  inherited SaveToJSONObject(AObject);
  AObject.AddPair('Organization', FOrganization);
  AObject.AddPair('AzureDeployment', FAzureDeployment);
  AObject.AddPair('AzureApiVersion', FAzureApiVersion);
end;

{ THelpChatGeminiSettings }

class function THelpChatGeminiSettings.DefaultModel: string;
begin
  Result := HELPCHAT_GEMINI_DEF_MODEL;
end;

class function THelpChatGeminiSettings.DefaultBaseUrl: string;
begin
  Result := HELPCHAT_GEMINI_DEF_BASEURL;
end;

class function THelpChatGeminiSettings.ApiKeyEnvVar: string;
begin
  Result := HELPCHAT_GEMINI_APIKEY_ENVVAR;
end;

class function THelpChatGeminiSettings.SectionName: string;
begin
  Result := 'Gemini';
end;

function THelpChatGeminiSettings.ResolveApiKey: string;
begin
  Result := inherited ResolveApiKey;
  if Result = '' then
    Result := Trim(GetEnvironmentVariable(HELPCHAT_GEMINI_APIKEY_ENVVAR_ALT));
end;

{ THelpChatRemoteSettings }

constructor THelpChatRemoteSettings.Create;
begin
  inherited Create;
  FUseHostChannel := True;
  FTimeoutMs := HELPCHAT_REMOTE_DEF_TIMEOUTMS;
end;

procedure THelpChatRemoteSettings.Assign(Source: TPersistent);
var
  LSource: THelpChatRemoteSettings;
begin
  if Source is THelpChatRemoteSettings then
  begin
    LSource := THelpChatRemoteSettings(Source);
    FBaseUrl := LSource.FBaseUrl;
    FAppKey := LSource.FAppKey;
    FUserId := LSource.FUserId;
    FUserToken := LSource.FUserToken;
    FUseHostChannel := LSource.FUseHostChannel;
    FTimeoutMs := LSource.FTimeoutMs;
  end
  else
    inherited Assign(Source);
end;

function THelpChatRemoteSettings.IsConfigured: Boolean;
begin
  Result := Trim(FBaseUrl) <> '';
end;

function THelpChatRemoteSettings.NormalizedBaseUrl: string;
begin
  Result := Trim(FBaseUrl);
  while Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

function THelpChatRemoteSettings.ResolveUserId: string;
begin
  Result := Trim(FUserId);
end;

procedure THelpChatRemoteSettings.LoadFromJSONObject(const AObject: TJSONObject);
begin
  if AObject = nil then
    Exit;
  FBaseUrl := JsonStr(AObject, 'BaseUrl', FBaseUrl);
  FAppKey := JsonStr(AObject, 'AppKey', FAppKey);
  FUserId := JsonStr(AObject, 'UserId', FUserId);
  FUserToken := JsonStr(AObject, 'UserToken', FUserToken);
  FUseHostChannel := JsonBool(AObject, 'UseHostChannel', FUseHostChannel);
  FTimeoutMs := JsonInt(AObject, 'TimeoutMs', FTimeoutMs);
end;

procedure THelpChatRemoteSettings.SaveToJSONObject(const AObject: TJSONObject);
begin
  AObject.AddPair('BaseUrl', FBaseUrl);
  AObject.AddPair('AppKey', FAppKey);
  AObject.AddPair('UserId', FUserId);
  AObject.AddPair('UserToken', FUserToken);
  AObject.AddPair('UseHostChannel', TJSONBool.Create(FUseHostChannel));
  AObject.AddPair('TimeoutMs', TJSONNumber.Create(FTimeoutMs));
end;

{ THelpChatSettings }

constructor THelpChatSettings.Create;
begin
  inherited Create;
  FClaude := THelpChatClaudeSettings.Create;
  FOpenAI := THelpChatOpenAISettings.Create;
  FGemini := THelpChatGeminiSettings.Create;
  FRemote := THelpChatRemoteSettings.Create;
  FProvider := HELPCHAT_DEF_PROVIDER;
  FPoolSize := HELPCHAT_DEF_POOLSIZE;
  FMessageMaxLength := HELPCHAT_DEF_MSGMAXLEN;
  FHistoryMaxMessages := HELPCHAT_DEF_HISTMAXMSG;
  FMaxStoredMessages := HELPCHAT_DEF_STOREDMAXMSG;
  FLanguage := hclAuto;
  FPersistConversation := HELPCHAT_DEF_PERSIST;
  FConversationMaxAgeDays := HELPCHAT_DEF_CONVERSATION_MAXAGE_DAYS;
end;

destructor THelpChatSettings.Destroy;
begin
  FRemote.Free;
  FGemini.Free;
  FOpenAI.Free;
  FClaude.Free;
  inherited;
end;

procedure THelpChatSettings.SetClaude(const Value: THelpChatClaudeSettings);
begin
  FClaude.Assign(Value);
end;

procedure THelpChatSettings.SetOpenAI(const Value: THelpChatOpenAISettings);
begin
  FOpenAI.Assign(Value);
end;

procedure THelpChatSettings.SetGemini(const Value: THelpChatGeminiSettings);
begin
  FGemini.Assign(Value);
end;

function THelpChatSettings.ModelFor(const AProvider: string): THelpChatModelSettings;
var
  LName: string;
begin
  LName := Trim(AProvider).ToLower;
  if LName = 'claude' then
    Result := FClaude
  else if LName = 'openai' then
    Result := FOpenAI
  else if LName = 'gemini' then
    Result := FGemini
  else
    Result := nil;
end;

function THelpChatSettings.ActiveModel: THelpChatModelSettings;
begin
  Result := ModelFor(FProvider);
  // stub, docsearch, a provider of the application: no model of its own, but
  // whoever asks for grounding or timeouts still needs an answer, and the
  // Claude section is where those lived before there were three.
  if Result = nil then
    Result := FClaude;
end;

procedure THelpChatSettings.SetRemote(const Value: THelpChatRemoteSettings);
begin
  FRemote.Assign(Value);
end;

procedure THelpChatSettings.Assign(Source: TPersistent);
var
  LSource: THelpChatSettings;
begin
  if Source is THelpChatSettings then
  begin
    LSource := THelpChatSettings(Source);
    FProvider := LSource.FProvider;
    FPoolSize := LSource.FPoolSize;
    FMessageMaxLength := LSource.FMessageMaxLength;
    FHistoryMaxMessages := LSource.FHistoryMaxMessages;
    FMaxStoredMessages := LSource.FMaxStoredMessages;
    FGreeting := LSource.FGreeting;
    FLanguage := LSource.FLanguage;
    FDocIndexFile := LSource.FDocIndexFile;
    FDocBaseUrl := LSource.FDocBaseUrl;
    FDocFolder := LSource.FDocFolder;
    FPersistConversation := LSource.FPersistConversation;
    FConversationFile := LSource.FConversationFile;
    FConversationMaxAgeDays := LSource.FConversationMaxAgeDays;
    FClaude.Assign(LSource.FClaude);
    FOpenAI.Assign(LSource.FOpenAI);
    FGemini.Assign(LSource.FGemini);
    FRemote.Assign(LSource.FRemote);
  end
  else
    inherited Assign(Source);
end;

function THelpChatSettings.ResolveGreeting: string;
begin
  Result := Trim(FGreeting);
  if Result = '' then
    Result := HelpChatMsg(hcmGreeting, FLanguage);
end;

function THelpChatSettings.ResolveConversationFile: string;
begin
  Result := Trim(FConversationFile);
  if Result = '' then
    Result := TPath.Combine(HelpChatAppDataFolder, HELPCHAT_DEF_CONVERSATION_FILENAME);
end;

function THelpChatSettings.ResolveDocIndexFile: string;
begin
  Result := Trim(FDocIndexFile);
  if Result = '' then
    Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), HELPCHAT_DEF_DOCINDEX_FILENAME);
end;

function THelpChatSettings.ResolveDocFolder: string;
begin
  Result := Trim(FDocFolder);
  if (Result <> '') and TPath.IsRelativePath(Result) then
    Result := ExpandFileName(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), Result));
end;

procedure THelpChatSettings.LoadFromJSON(const AJson: string);
var
  LValue: TJSONValue;
  LRoot: TJSONObject;
begin
  try
    LValue := TJSONObject.ParseJSONValue(AJson);
  except
    on E: Exception do
      raise EHelpChatConfigError.Create('Invalid HelpChat configuration: ' + E.Message);
  end;
  if not (LValue is TJSONObject) then
  begin
    LValue.Free;
    raise EHelpChatConfigError.Create('Invalid HelpChat configuration: expected a JSON object');
  end;
  LRoot := TJSONObject(LValue);
  try
    FProvider := JsonStr(LRoot, 'Provider', FProvider);
    FPoolSize := JsonInt(LRoot, 'PoolSize', FPoolSize);
    FMessageMaxLength := JsonInt(LRoot, 'MessageMaxLength', FMessageMaxLength);
    FHistoryMaxMessages := JsonInt(LRoot, 'HistoryMaxMessages', FHistoryMaxMessages);
    FMaxStoredMessages := JsonInt(LRoot, 'MaxStoredMessages', FMaxStoredMessages);
    FGreeting := JsonStr(LRoot, 'Greeting', FGreeting);
    FLanguage := ConfigToLanguage(JsonStr(LRoot, 'Language', ''), FLanguage);
    FDocIndexFile := JsonStr(LRoot, 'DocIndexFile', FDocIndexFile);
    FDocBaseUrl := JsonStr(LRoot, 'DocBaseUrl', FDocBaseUrl);
    FDocFolder := JsonStr(LRoot, 'DocFolder', FDocFolder);
    FPersistConversation := JsonBool(LRoot, 'PersistConversation', FPersistConversation);
    FConversationFile := JsonStr(LRoot, 'ConversationFile', FConversationFile);
    FConversationMaxAgeDays := JsonInt(LRoot, 'ConversationMaxAgeDays', FConversationMaxAgeDays);
    if JsonFind(LRoot, 'Claude') is TJSONObject then
      FClaude.LoadFromJSONObject(TJSONObject(JsonFind(LRoot, 'Claude')));
    if JsonFind(LRoot, 'OpenAI') is TJSONObject then
      FOpenAI.LoadFromJSONObject(TJSONObject(JsonFind(LRoot, 'OpenAI')));
    if JsonFind(LRoot, 'Gemini') is TJSONObject then
      FGemini.LoadFromJSONObject(TJSONObject(JsonFind(LRoot, 'Gemini')));
    if JsonFind(LRoot, 'Remote') is TJSONObject then
      FRemote.LoadFromJSONObject(TJSONObject(JsonFind(LRoot, 'Remote')));
  finally
    LRoot.Free;
  end;
end;

function THelpChatSettings.SaveToJSON: string;
var
  LRoot, LClaude, LSection, LRemote: TJSONObject;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('Provider', FProvider);
    LRoot.AddPair('Language', LanguageToConfig(FLanguage));
    LRoot.AddPair('Greeting', FGreeting);
    LRoot.AddPair('DocIndexFile', FDocIndexFile);
    LRoot.AddPair('DocBaseUrl', FDocBaseUrl);
    LRoot.AddPair('DocFolder', FDocFolder);
    LRoot.AddPair('PoolSize', TJSONNumber.Create(FPoolSize));
    LRoot.AddPair('MessageMaxLength', TJSONNumber.Create(FMessageMaxLength));
    LRoot.AddPair('HistoryMaxMessages', TJSONNumber.Create(FHistoryMaxMessages));
    LRoot.AddPair('MaxStoredMessages', TJSONNumber.Create(FMaxStoredMessages));
    LRoot.AddPair('PersistConversation', TJSONBool.Create(FPersistConversation));
    LRoot.AddPair('ConversationFile', FConversationFile);
    LRoot.AddPair('ConversationMaxAgeDays', TJSONNumber.Create(FConversationMaxAgeDays));
    LClaude := TJSONObject.Create;
    LRoot.AddPair('Claude', LClaude);
    FClaude.SaveToJSONObject(LClaude);
    LSection := TJSONObject.Create;
    LRoot.AddPair('OpenAI', LSection);
    FOpenAI.SaveToJSONObject(LSection);
    LSection := TJSONObject.Create;
    LRoot.AddPair('Gemini', LSection);
    FGemini.SaveToJSONObject(LSection);
    LRemote := TJSONObject.Create;
    LRoot.AddPair('Remote', LRemote);
    FRemote.SaveToJSONObject(LRemote);
    Result := LRoot.Format(2);
  finally
    LRoot.Free;
  end;
end;

function THelpChatSettings.LoadFromFile(const AFileName: string): Boolean;
begin
  Result := (AFileName <> '') and TFile.Exists(AFileName);
  if not Result then
    Exit;
  try
    LoadFromJSON(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  except
    on E: EHelpChatConfigError do
      raise EHelpChatConfigError.CreateFmt('%s (%s)', [E.Message, AFileName]);
  end;
end;

procedure THelpChatSettings.SaveToFile(const AFileName: string);
var
  LDir: string;
begin
  LDir := TPath.GetDirectoryName(AFileName);
  if (LDir <> '') and not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
  TFile.WriteAllText(AFileName, SaveToJSON, TEncoding.UTF8);
end;

class function THelpChatSettings.SharedUserConfigFile: string;
begin
  Result := TPath.Combine(TPath.Combine(TPath.GetHomePath, 'HelpChatAI'), HELPCHAT_DEF_CONFIG_FILENAME);
end;

class function THelpChatSettings.AppConfigFile: string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), HELPCHAT_DEF_CONFIG_FILENAME);
end;

class function THelpChatSettings.UserConfigFile: string;
begin
  Result := TPath.Combine(HelpChatAppDataFolder, HELPCHAT_DEF_CONFIG_FILENAME);
end;

function THelpChatSettings.LoadConfiguration(const AFileName: string): TArray<string>;
var
  LFile: string;
begin
  LFile := Trim(AFileName);
  if LFile = '' then
    Exit(LoadFromDefaultFiles);
  // Named explicitly: that one, wherever the defaults would have looked.
  if TPath.IsRelativePath(LFile) then
    LFile := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LFile));
  if not TFile.Exists(LFile) then
    raise EHelpChatConfigError.CreateFmt(
      'HelpChat configuration file not found: %s', [LFile]);
  LoadFromFile(LFile);
  Result := [LFile];
end;

function THelpChatSettings.LoadFromDefaultFiles: TArray<string>;
var
  LFile: string;
begin
  Result := nil;
  // Shared user defaults (the key), then the application defaults, then the
  // per-application user file on top.
  for LFile in [SharedUserConfigFile, AppConfigFile, UserConfigFile] do
    if LoadFromFile(LFile) then
      Result := Result + [LFile];
end;

end.
