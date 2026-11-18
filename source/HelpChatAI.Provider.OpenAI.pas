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
///  The <c>openai</c> provider: Chat Completions, streamed, with the actions
///  of the application offered as tools.
///
///  It is deliberately the widest of the three. Chat Completions is the API a
///  dozen other services chose to speak, so <c>Settings.OpenAI.BaseUrl</c> and
///  <c>Model</c> are enough to point this same provider at Groq, OpenRouter,
///  Mistral, DeepSeek, a local Ollama (<c>http://localhost:11434/v1</c>) or LM
///  Studio. The one that needs more than a URL is Azure OpenAI, which puts the
///  deployment in the path and the key in another header:
///  <c>AzureDeployment</c> switches both.
///
///  Two things differ from Anthropic and cost more code than one would think.
///  The tool call arrives in pieces identified by an <c>index</c>, not by an
///  id (the id comes in the first piece only), so the fragments are collected
///  per index. And the reason the model stopped arrives as
///  <c>finish_reason</c> on the choice, not as a separate event: an answer
///  that asks for actions ends with <c>tool_calls</c>.
/// </summary>
unit HelpChatAI.Provider.OpenAI;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Actions,
  HelpChatAI.Provider,
  HelpChatAI.Attachments,
  HelpChatAI.Provider.Sse;

const
  /// <summary>Name the provider registers under. Every service that speaks
  /// Chat Completions is this provider with another <c>BaseUrl</c>, so three
  /// local models on one Ollama are three models of the catalogue with this
  /// same name.</summary>
  HELPCHAT_PROVIDER_OPENAI = 'openai';
  /// <summary>Path appended to BaseUrl when this is not Azure.</summary>
  HELPCHAT_OPENAI_COMPLETIONS_PATH = '/v1/chat/completions';
  /// <summary>Path of the Responses API, appended the same way.</summary>
  HELPCHAT_OPENAI_RESPONSES_PATH = '/v1/responses';

type
  /// <summary>Parses the <c>chat.completion.chunk</c> events: the text
  /// deltas, the tool calls assembled per index, and the finish reason. Only
  /// the first choice is read. An <c>error</c> object arriving as a payload
  /// of its own is kept in <c>Error</c> for the provider to raise. Lives for
  /// one round of one reply, on the worker thread that runs it.</summary>
  THelpChatOpenAIStream = class(THelpChatSseStreamBase)
  strict private
    FUsage: THelpChatTokenUsage;
    FFinishReason: string;
    FToolCalls: TList<THelpChatToolCall>;
    FToolIndexes: TDictionary<Integer, Integer>; // delta index -> tool call
    /// <summary>One element of <c>delta.tool_calls</c>: opens the call of
    /// its <c>index</c> the first time that index is seen, then appends the
    /// fragments of the arguments to it. A delta without an index counts as
    /// index 0.</summary>
    procedure ApplyToolDelta(const ADelta: TJSONObject);
    function GetToolCalls: TArray<THelpChatToolCall>;
  strict protected
    procedure ProcessLine(const ALine: string); override;
  public
    /// <summary><c>AOnToken</c> receives every text delta, on the thread the
    /// HTTP client writes from; nil when nobody is listening.</summary>
    constructor Create(const AOnToken: THelpChatTokenProc);
    destructor Destroy; override;
    /// <summary>finish_reason of the choice: stop, length, tool_calls... The
    /// provider runs the actions only when it is <c>tool_calls</c>.</summary>
    property FinishReason: string read FFinishReason;
    /// <summary>The actions the model asked for in this reply, in order of
    /// first appearance. A copy: the arguments of a call are complete only
    /// once the stream is.</summary>
    property ToolCalls: TArray<THelpChatToolCall> read GetToolCalls;
    /// <summary>The tokens of the round, from the usage record that ends the
    /// stream (<c>stream_options.include_usage</c>): the prompt split into
    /// what was read from the automatic prompt cache of the service
    /// (<c>prompt_tokens_details.cached_tokens</c>) and the rest. Zero
    /// where the server sends no record.</summary>
    property Usage: THelpChatTokenUsage read FUsage;
  end;

  /// <summary>Parses the events of the Responses API: the text deltas
  /// (<c>response.output_text.delta</c>) and every finished output item
  /// (<c>response.output_item.done</c>) - a <c>function_call</c> becomes a
  /// tool call, and every item, the encrypted reasoning included, is kept
  /// as it came, because the next round has to send it back: the requests
  /// are stateless (<c>store: false</c>), and a reasoning model that acted
  /// wants its reasoning back with the results. A failure
  /// (<c>response.failed</c>, <c>error</c>) is kept in <c>Error</c>. Lives
  /// for one round of one reply.</summary>
  THelpChatOpenAIResponsesStream = class(THelpChatSseStreamBase)
  strict private
    FUsage: THelpChatTokenUsage;
    FItems: TJSONArray;
    FToolCalls: TList<THelpChatToolCall>;
    FCutAtLimit: Boolean;
    function GetToolCalls: TArray<THelpChatToolCall>;
    function GetItemsJson: string;
  strict protected
    procedure ProcessLine(const ALine: string); override;
  public
    constructor Create(const AOnToken: THelpChatTokenProc);
    destructor Destroy; override;
    /// <summary>The actions the model asked for, in order.</summary>
    property ToolCalls: TArray<THelpChatToolCall> read GetToolCalls;
    /// <summary>Every output item of the round, as JSON array elements
    /// without the brackets: what the next round puts back in its input.</summary>
    property ItemsJson: string read GetItemsJson;
    /// <summary>The tokens of the round, from <c>response.completed</c>: the
    /// input split into what the automatic prompt cache of the service read
    /// (<c>input_tokens_details.cached_tokens</c>) and the rest.</summary>
    property Usage: THelpChatTokenUsage read FUsage;
    /// <summary>The round ended as <c>response.incomplete</c> because it
    /// reached <c>max_output_tokens</c>: the text is not whole.</summary>
    property CutAtLimit: Boolean read FCutAtLimit;
  end;

  /// <summary>
  ///  The <c>openai</c> provider. One instance per reply, created by the
  ///  registry on a runner worker and never shared. It reads its
  ///  <c>Settings.OpenAI</c> section through <c>ResolveModel</c>,
  ///  <c>NormalizedBaseUrl</c> and <c>ResolveApiKey</c>, which is how the
  ///  model picked in the panel - another model, another endpoint, another
  ///  key - reaches it without the section being rewritten. The class
  ///  functions that build the request are static and touch no network.
  /// </summary>
  THelpChatOpenAIProvider = class(THelpChatProviderBase)
  strict private
    /// <summary>Runs what the model asked for and builds the <c>tool</c>
    /// messages that carry the results back: one per call, as the elements
    /// of a JSON array without its brackets, because the caller splices them
    /// into one. Blocks while the application runs each action on its main
    /// thread. Raises <see cref="EHelpChatCancelled" /> when the request is
    /// cancelled before or during a call.</summary>
    function ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
      const ACancel: IHelpChatCancelToken; const AResponses: Boolean = False): string;
    /// <summary>Posts ABody to AUrl and lets AStream parse the answer; the
    /// headers, the timeouts, the cancellation and the errors of every round
    /// of both APIs.</summary>
    procedure Post(const ABody, AUrl: string; const AStream: THelpChatSseStreamBase;
      const ACancel: IHelpChatCancelToken);
    /// <summary>The reply through the Responses API: the same loop of rounds
    /// as Chat Completions, the output items of a round and the results of
    /// its actions sent back with the next.</summary>
    /// <summary>True, once per model, when AError says the model has no
    /// encrypted reasoning: the model is remembered and the caller repeats
    /// its request, whose body no longer asks for it.</summary>
    function LearnsNoEncryptedReasoning(const AError: string): Boolean;
    function GenerateResponses(const AHistory: TArray<THelpChatMessage>;
      const ASystem, ATools, AQuestionContext: string; const AMaxRounds: Integer;
      const AOnToken: THelpChatTokenProc; const ACancel: IHelpChatCancelToken): string;
    /// <summary>One request/response round; returns the stream it parsed,
    /// which the caller owns. The key goes in <c>Authorization: Bearer</c>,
    /// in <c>api-key</c> for Azure, and in no header at all when there is
    /// none (a local server). Raises <see cref="EHelpChatCancelled" /> when
    /// the token flipped during the transfer, <see cref="EHelpChatError" />
    /// for a status of 400 and above or an error payload in the stream, and
    /// whatever the HTTP client raises otherwise.</summary>
    function PostRound(const ABody: string; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): THelpChatOpenAIStream;
  public
    /// <summary>Full URL of the endpoint: Azure puts the deployment in the
    /// path, a BaseUrl that already ends in /v1 does not get a second one.
    /// Public for tests.</summary>
    class function CompletionsUrl(const ASettings: THelpChatOpenAISettings): string; static;
    /// <summary>Full URL of the Responses API: <c>/v1/responses</c>, or
    /// <c>/responses</c> after a BaseUrl that ends in /v1; on Azure
    /// <c>/openai/v1/responses</c>. Public for tests.</summary>
    class function ResponsesUrl(const ASettings: THelpChatOpenAISettings): string; static;
    /// <summary>The actions as the Responses API wants them: flat
    /// <c>{"type":"function",name,description,parameters,"strict":false}</c>
    /// - not strict, because an action may have optional parameters. Public
    /// for tests.</summary>
    class function BuildResponsesToolsJson(const ABrokerToolsJson: string): string; static;
    /// <summary>The body of a Responses request: the system prompt as
    /// <c>instructions</c>, the history as <c>input</c> (the attachments on
    /// the last user turn, as <c>input_file</c> and <c>input_image</c>
    /// parts), then <c>AExtraItemsJson</c> - a JSON array of what this reply
    /// already exchanged with the tools. Stateless (<c>store: false</c>),
    /// asking for the encrypted reasoning so that it can be sent back.
    /// Public for tests.</summary>
    class function BuildResponsesBody(const AHistory: TArray<THelpChatMessage>;
      const ASystemPrompt: string; const ASettings: THelpChatOpenAISettings;
      const AToolsJson, AExtraItemsJson: string;
      const AAttachments: TArray<THelpChatAttachment> = nil;
      const ALanguage: THelpChatLanguage = hclAuto;
      const AQuestionContext: string = ''): string; static;
    function GetName: string; override;
    /// <summary>True: the system prompt (<c>instructions</c>, or the first
    /// message) is the part that does not change, and the context goes with
    /// the question, so that the automatic prompt cache of the service reads
    /// the system prompt and the conversation again.</summary>
    class function SplitsPrompt: Boolean; override;
    /// <summary>One request with the system prompt and the question alone,
    /// no tools. Both APIs ask for no reasoning
    /// (<c>reasoning_effort: none</c>, which a local gemma4 needs or it spends
    /// the whole cap thinking) and <c>HELPCHAT_SEARCH_TERMS_MAX_TOKENS</c>; a
    /// server that refuses the effort gets the request again without it and
    /// with room to think. The Responses API gets
    /// <c>HELPCHAT_SEARCH_TERMS_THINKING_TOKENS</c> in any case. Empty when
    /// OpenAI itself has no key.</summary>
    function CompleteText(const ASystem, AUser: string;
      const ACancel: IHelpChatCancelToken): string; override;
    /// <summary>The body of <see cref="CompleteText" /> for Chat Completions
    /// or, with <c>UsesResponses</c>, for the Responses API;
    /// <c>AReasoningEffort</c> 'none' or empty (<c>reasoning_effort</c>,
    /// <c>reasoning.effort</c>). Public for tests; no network
    /// involved.</summary>
    class function BuildCompletionBody(const ASystem, AUser: string;
      const ASettings: THelpChatOpenAISettings; const AReasoningEffort: string): string; static;
    /// <summary>A missing key is an issue unless the endpoint is on this
    /// machine or on a private network (<c>HelpChatIsLocalEndpoint</c>): a
    /// local Ollama or LM Studio asks for none, while OpenAI itself, Groq,
    /// OpenRouter and Azure all want one. Asked through
    /// <c>ResolveApiKey</c>, so at run time the application's
    /// <c>OnDecryptSecret</c> handler runs for an encrypted key.</summary>
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; override;
    function SupportsStreaming: Boolean; override;
    function SupportsActions: Boolean; override;
    /// <summary>True for the provider as a whole: whether the model behind
    /// the configured endpoint really reads a PDF or an image is something
    /// only that service knows, and it says so with an error of its own.</summary>
    function SupportsDocuments: Boolean; override;
    /// <summary>The reply, streamed through <c>AOnToken</c> as it arrives and
    /// returned whole. With actions registered it is a loop of at most
    /// <c>Settings.OpenAI.ResolveMaxToolRounds</c> requests: the text of
    /// every round is concatenated, a paragraph break between two, and that
    /// same break goes through <c>AOnToken</c>. Actions asked for in the last
    /// round are not run. Runs on a worker thread and blocks it. Raises
    /// <see cref="EHelpChatConfigError" /> when OpenAI itself is called
    /// without a key, <see cref="EHelpChatCancelled" /> on cancellation and
    /// <see cref="EHelpChatError" /> for what the service refuses; an empty
    /// answer becomes the localized "no content" sentence.</summary>
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;

    /// <summary>The actions of the application, as the <c>tools</c> array of
    /// this API: the broker describes them with a JSON Schema under
    /// <c>input_schema</c>, here each becomes
    /// <c>{"type":"function","function":{name,description,parameters}}</c>.
    /// Public for tests.</summary>
    class function BuildToolsJson(const ABrokerToolsJson: string): string; static;
    /// <summary>Builds the JSON body of the request: the model of
    /// <c>ASettings.ResolveModel</c>, the system prompt as the first message,
    /// the history without its system and empty messages, the attachments on
    /// the last non-empty user turn. <c>AToolsJson</c> is the array
    /// <see cref="BuildToolsJson" /> produced, not the broker's;
    /// <c>AExtraMessagesJson</c> is a JSON array of the turns this reply
    /// already exchanged with the tools. Public for tests; no network
    /// involved. <c>AReasoningEffort</c> not empty is sent as
    /// <c>reasoning_effort</c>: see <see cref="AsksForNoReasoning" />.</summary>
    class function BuildRequestBody(const AHistory: TArray<THelpChatMessage>;
      const ASystemPrompt: string; const ASettings: THelpChatOpenAISettings;
      const AToolsJson, AExtraMessagesJson: string;
      const AAttachments: TArray<THelpChatAttachment> = nil;
      const ALanguage: THelpChatLanguage = hclAuto;
      const AReasoningEffort: string = '';
      const AQuestionContext: string = ''): string; static;
    /// <summary>True when AError is the refusal of a reasoning model that
    /// takes function tools in Chat Completions only without reasoning -
    /// "Function tools with reasoning_effort are not supported for
    /// gpt-6-luna in /v1/chat/completions ... set reasoning_effort to
    /// 'none'", measured on the default model. <c>Generate</c> then repeats
    /// the round with <c>reasoning_effort: none</c>. Asked of the service's
    /// own words, never of the model name: an older model, Ollama or a
    /// gateway may refuse the parameter, so it is sent only to whoever asked
    /// for it. Public for tests.</summary>
    class function AsksForNoReasoning(const AError: string): Boolean; static;
    /// <summary>True when AError is about the reasoning effort itself - a
    /// model or a server that does not know the parameter, or refuses the
    /// value: the only refusal the request of the search terms is repeated
    /// for, without the effort. A wrong key or a rate limit used to cost a
    /// second failing request before every reply. Public for tests.</summary>
    class function RefusesReasoningEffort(const AError: string): Boolean; static;
    /// <summary>True when AError is the Responses API saying that the model
    /// has no encrypted reasoning to give ("Encrypted content is not
    /// supported with this model"): a model that does not reason. The round
    /// is then repeated without <c>include</c>, and the model remembered
    /// (<see cref="RefusesEncryptedReasoning" />). Public for tests.</summary>
    class function AsksForNoEncryptedReasoning(const AError: string): Boolean; static;
    /// <summary>True when the service told this provider, earlier in the
    /// process, that <c>AModel</c> has no encrypted reasoning: the body of a
    /// Responses request then carries no <c>include</c>.</summary>
    class function RefusesEncryptedReasoning(const AModel: string): Boolean; static;
    /// <summary>The content of a user message that carries attachments: a
    /// <c>file</c> part per PDF (the only binary Chat Completions reads), an
    /// <c>image_url</c> part with a data URI per picture, and the text last,
    /// with the text attachments in front of the question. The caller owns
    /// the array.</summary>
    class function BuildUserContent(const AText: string;
      const AAttachments: TArray<THelpChatAttachment>;
      const ALanguage: THelpChatLanguage): TJSONArray; static;
    /// <summary>The assistant turn that asked for the actions, as the API
    /// wants it back: <c>content</c> always present, even empty, and one
    /// <c>tool_calls</c> entry per call whose arguments are a string of JSON
    /// (<c>{}</c> when the model sent none), not an object.</summary>
    class function BuildAssistantToolMessage(const AText: string;
      const ACalls: TArray<THelpChatToolCall>): string; static;
    /// <summary>Extracts a readable message from a non-2xx response body:
    /// the <c>error.message</c> of the JSON the service answers with, else
    /// the localized "HTTP status" sentence in the language of
    /// <c>ASettings</c> (which may be nil). Never raises.</summary>
    class function ExtractApiError(const ARaw: string; const AStatus: Integer;
      const AStatusText: string; const ASettings: THelpChatSettings): string; static;
  end;

/// <summary>True when AUrl names this machine (<c>localhost</c>, 127.x,
/// <c>::1</c>) or a private network (10.x, 172.16-31.x, 192.168.x, a
/// <c>.local</c> or a single-label name such as <c>gpu-box</c>): where a
/// server speaking the OpenAI API usually asks for no key. Anything else is
/// a service on the internet, which does.</summary>
function HelpChatIsLocalEndpoint(const AUrl: string): Boolean;

implementation

uses
  System.IOUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts;

type
  /// <summary>Aborts the transfer as soon as the request is cancelled.</summary>
  TAbortWatcher = class
  strict private
    FCancel: IHelpChatCancelToken;
  public
    constructor Create(const ACancel: IHelpChatCancelToken);
    procedure OnReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64;
      var AAbort: Boolean);
  end;

{ TAbortWatcher }

constructor TAbortWatcher.Create(const ACancel: IHelpChatCancelToken);
begin
  inherited Create;
  FCancel := ACancel;
end;

procedure TAbortWatcher.OnReceiveData(const Sender: TObject; AContentLength,
  AReadCount: Int64; var AAbort: Boolean);
begin
  if Assigned(FCancel) and FCancel.IsCancelled then
    AAbort := True;
end;

{ THelpChatOpenAIStream }

constructor THelpChatOpenAIStream.Create(const AOnToken: THelpChatTokenProc);
begin
  inherited Create(AOnToken);
  FToolCalls := TList<THelpChatToolCall>.Create;
  FToolIndexes := TDictionary<Integer, Integer>.Create;
end;

destructor THelpChatOpenAIStream.Destroy;
begin
  FToolIndexes.Free;
  FToolCalls.Free;
  inherited;
end;

function THelpChatOpenAIStream.GetToolCalls: TArray<THelpChatToolCall>;
begin
  Result := FToolCalls.ToArray;
end;

procedure THelpChatOpenAIStream.ApplyToolDelta(const ADelta: TJSONObject);
var
  LIndex, LPos: Integer;
  LCall: THelpChatToolCall;
  LFunction: TJSONObject;
  LId, LName, LArgs: string;
begin
  // Each delta carries an index: the first one names the call, the following
  // ones only add fragments of the arguments to it.
  LIndex := ADelta.GetValue<Integer>('index', 0);
  LId := ADelta.GetValue<string>('id', '');
  // Some servers that speak this API leave the index out. Then the id is
  // what starts a call - two parallel calls would otherwise be glued into
  // one, name of the first and arguments of both - and a fragment without
  // an id belongs to the call before it.
  if ADelta.GetValue('index') = nil then
  begin
    if (LId <> '') and
       ((FToolCalls.Count = 0) or (FToolCalls[FToolCalls.Count - 1].Id <> LId)) then
      LIndex := -(FToolCalls.Count + 1)   // a key no real index can have
    else if FToolCalls.Count > 0 then
      LIndex := -FToolCalls.Count;
    if (LIndex < 0) and (LIndex = -FToolCalls.Count) and
       not FToolIndexes.ContainsKey(LIndex) then
      FToolIndexes.AddOrSetValue(LIndex, FToolCalls.Count - 1);
  end;
  LName := '';
  LArgs := '';
  LFunction := HelpChatJsonObject(ADelta, 'function');
  if LFunction <> nil then
  begin
    LName := LFunction.GetValue<string>('name', '');
    LArgs := LFunction.GetValue<string>('arguments', '');
  end;

  if not FToolIndexes.TryGetValue(LIndex, LPos) then
  begin
    LCall.Id := LId;
    LCall.Name := LName;
    LCall.InputJson := LArgs;
    FToolCalls.Add(LCall);
    FToolIndexes.AddOrSetValue(LIndex, FToolCalls.Count - 1);
    Exit;
  end;

  LCall := FToolCalls[LPos];
  if LId <> '' then
    LCall.Id := LId;
  if LName <> '' then
    LCall.Name := LName;
  LCall.InputJson := LCall.InputJson + LArgs;
  FToolCalls[LPos] := LCall;
end;

procedure THelpChatOpenAIStream.ProcessLine(const ALine: string);
var
  LRoot, LChoice, LDelta, LErr: TJSONObject;
  LChoices, LToolDeltas: TJSONArray;
  LItem: TJSONValue;
  LFinish: string;
begin
  LRoot := ParseObject(DataPayload(ALine));
  if LRoot = nil then
    Exit;
  try
    // An error can arrive as a payload of its own, before any choice.
    LErr := HelpChatJsonObject(LRoot, 'error');
    if (LErr <> nil) or (LRoot.GetValue('error') is TJSONString) then
    begin
      // An object with a message, or - several local servers - the message
      // itself as a string.
      FError := HelpChatJsonErrorText(LRoot);
      if FError = '' then
        FError := HelpChatMsg(hcmProviderError);
      Exit;
    end;

    // The usage record comes last, with no choice; the model names itself
    // on every chunk.
    if FUsage.Model = '' then
      FUsage.Model := LRoot.GetValue<string>('model', '');
    if LRoot.GetValue('usage') is TJSONObject then
    begin
      FUsage.CacheReadTokens := LRoot.GetValue<Integer>('usage.prompt_tokens_details.cached_tokens', 0);
      FUsage.CacheWriteTokens := LRoot.GetValue<Integer>('usage.prompt_tokens_details.cache_write_tokens', 0);
      FUsage.InputTokens := LRoot.GetValue<Integer>('usage.prompt_tokens', 0) - FUsage.CacheReadTokens -
        FUsage.CacheWriteTokens;
      FUsage.OutputTokens := LRoot.GetValue<Integer>('usage.completion_tokens', 0);
    end;

    LChoices := HelpChatJsonArray(LRoot, 'choices');
    if (LChoices = nil) or (LChoices.Count = 0) then
      Exit;
    if not (LChoices.Items[0] is TJSONObject) then
      Exit;
    LChoice := TJSONObject(LChoices.Items[0]);

    // Null on every chunk but the last of the choice; the usage record that
    // may follow has no choice at all and never gets here.
    LFinish := LChoice.GetValue<string>('finish_reason', '');
    if LFinish <> '' then
      FFinishReason := LFinish;

    LDelta := HelpChatJsonObject(LChoice, 'delta');
    if LDelta = nil then
      Exit;
    EmitToken(LDelta.GetValue<string>('content', ''));

    LToolDeltas := HelpChatJsonArray(LDelta, 'tool_calls');
    if LToolDeltas <> nil then
      for LItem in LToolDeltas do
        if LItem is TJSONObject then
          ApplyToolDelta(TJSONObject(LItem));
  finally
    LRoot.Free;
  end;
end;

{ THelpChatOpenAIResponsesStream }

constructor THelpChatOpenAIResponsesStream.Create(const AOnToken: THelpChatTokenProc);
begin
  inherited Create(AOnToken);
  FItems := TJSONArray.Create;
  FToolCalls := TList<THelpChatToolCall>.Create;
end;

destructor THelpChatOpenAIResponsesStream.Destroy;
begin
  FToolCalls.Free;
  FItems.Free;
  inherited;
end;

function THelpChatOpenAIResponsesStream.GetToolCalls: TArray<THelpChatToolCall>;
begin
  Result := FToolCalls.ToArray;
end;

function THelpChatOpenAIResponsesStream.GetItemsJson: string;
begin
  Result := FItems.ToJSON;
  // The caller splices the elements into an array of its own.
  Result := Copy(Result, 2, Length(Result) - 2);
end;

procedure THelpChatOpenAIResponsesStream.ProcessLine(const ALine: string);
var
  LRoot, LItem: TJSONObject;
  LValue: TJSONValue;
  LType: string;
begin
  LRoot := ParseObject(DataPayload(ALine));
  if LRoot = nil then
    Exit;
  try
    // Every event names itself in "type": the "event:" lines say the same.
    LType := LRoot.GetValue<string>('type', '');
    if LType = 'response.output_text.delta' then
      EmitToken(LRoot.GetValue<string>('delta', ''))
    else if LType = 'response.output_item.done' then
    begin
      LValue := LRoot.GetValue('item');
      if not (LValue is TJSONObject) then
        Exit;
      LItem := TJSONObject(LValue);
      FItems.AddElement(LItem.Clone as TJSONValue);
      // Whole, unlike Chat Completions: nothing to reassemble.
      if LItem.GetValue<string>('type', '') = 'function_call' then
        FToolCalls.Add(THelpChatToolCall.Create(LItem.GetValue<string>('call_id', ''),
          LItem.GetValue<string>('name', ''), LItem.GetValue<string>('arguments', '')));
    end
    else if LType = 'response.completed' then
    begin
      // The tokens of the round, the automatic prompt cache included.
      FUsage.Model := LRoot.GetValue<string>('response.model', '');
      // The input counts all of it: what the cache read, what this request
      // wrote to it (cache_write_tokens), the rest.
      FUsage.CacheReadTokens := LRoot.GetValue<Integer>('response.usage.input_tokens_details.cached_tokens', 0);
      FUsage.CacheWriteTokens := LRoot.GetValue<Integer>('response.usage.input_tokens_details.cache_write_tokens', 0);
      FUsage.InputTokens := LRoot.GetValue<Integer>('response.usage.input_tokens', 0) -
        FUsage.CacheReadTokens - FUsage.CacheWriteTokens;
      FUsage.OutputTokens := LRoot.GetValue<Integer>('response.usage.output_tokens', 0);
    end
    else if LType = 'response.incomplete' then
      FCutAtLimit := LRoot.GetValue<string>('response.incomplete_details.reason', '') =
        'max_output_tokens'
    else if LType = 'response.failed' then
    begin
      LValue := LRoot.FindValue('response.error.message');
      if LValue <> nil then
        FError := LValue.Value;
      if FError = '' then
        FError := HelpChatMsg(hcmProviderError);
    end
    else if LType = 'error' then
    begin
      FError := LRoot.GetValue<string>('message', '');
      if FError = '' then
        FError := HelpChatMsg(hcmProviderError);
    end;
  finally
    LRoot.Free;
  end;
end;

{ THelpChatOpenAIProvider }

function HelpChatIsLocalEndpoint(const AUrl: string): Boolean;
var
  LHost: string;
  LAt: Integer;
  LParts: TArray<string>;
  LSecond: Integer;
begin
  LHost := Trim(AUrl).ToLower;
  LAt := LHost.IndexOf('://');
  if LAt >= 0 then
    LHost := LHost.Substring(LAt + 3);
  LAt := LHost.IndexOfAny(['/', '?', '#']);
  if LAt >= 0 then
    LHost := LHost.Substring(0, LAt);
  LAt := LHost.LastIndexOf('@');
  if LAt >= 0 then
    LHost := LHost.Substring(LAt + 1);
  if LHost.StartsWith('[') then
  begin
    // [::1]:8080
    LAt := LHost.IndexOf(']');
    if LAt > 0 then
      LHost := LHost.Substring(1, LAt - 1);
  end
  else
  begin
    LAt := LHost.LastIndexOf(':');
    if LAt >= 0 then
      LHost := LHost.Substring(0, LAt);
  end;
  if LHost = '' then
    Exit(False);
  if (LHost = 'localhost') or LHost.EndsWith('.localhost') or (LHost = '::1') or
     LHost.EndsWith('.local') or LHost.StartsWith('127.') or LHost.StartsWith('10.') or
     LHost.StartsWith('192.168.') then
    Exit(True);
  if LHost.StartsWith('172.') then
  begin
    LParts := LHost.Split(['.']);
    if (Length(LParts) = 4) and TryStrToInt(LParts[1], LSecond) then
      Exit((LSecond >= 16) and (LSecond <= 31));
  end;
  // A name with no dot is a machine of the network, not a service.
  Result := not LHost.Contains('.') and not LHost.Contains(':');
end;

function THelpChatOpenAIProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_OPENAI;
end;

class function THelpChatOpenAIProvider.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
var
  LUrl: string;
begin
  Result := '';
  if not Assigned(ASettings) then
    Exit;
  // A local Ollama or LM Studio asks for no key at all: only a service we are
  // actually calling over the internet can be said to be missing one.
  if ASettings.OpenAI.ResolveApiKey <> '' then
    Exit;
  LUrl := ASettings.OpenAI.NormalizedBaseUrl;
  if SameText(LUrl, HELPCHAT_OPENAI_DEF_BASEURL) then
    Result := Format('No API key: set Settings.OpenAI.ApiKey, the OpenAI/ApiKey ' +
      'entry of helpchatai.json, or the %s environment variable. A local server ' +
      '(Ollama, LM Studio) needs none: point Settings.OpenAI.BaseUrl at it.',
      [HELPCHAT_OPENAI_APIKEY_ENVVAR])
  else if not HelpChatIsLocalEndpoint(LUrl) then
    // Groq, OpenRouter, Azure: on the internet, a key of
    // their own - never the one of OpenAI, nor its environment variable.
    Result := Format('No API key for %s: a service on the internet wants one. ' +
      'Set the ApiKey of that model in Models, or of the OpenAI section. A local ' +
      'server (Ollama, LM Studio) needs none.', [LUrl]);
end;

function THelpChatOpenAIProvider.SupportsStreaming: Boolean;
begin
  Result := True;
end;

function THelpChatOpenAIProvider.SupportsDocuments: Boolean;
begin
  Result := True;
end;

function THelpChatOpenAIProvider.SupportsActions: Boolean;
begin
  Result := True;
end;

class function THelpChatOpenAIProvider.CompletionsUrl(
  const ASettings: THelpChatOpenAISettings): string;
begin
  if ASettings.IsAzure then
    // Azure puts the deployment in the path and the version in the query.
    Result := Format('%s/openai/deployments/%s/chat/completions?api-version=%s',
      [ASettings.NormalizedBaseUrl, ASettings.AzureDeployment,
       ASettings.AzureApiVersion])
  else if ASettings.NormalizedBaseUrl.EndsWith('/v1', True) then
    // A BaseUrl that already names the version (what Ollama and LM Studio
    // publish) must not get a second one.
    Result := ASettings.NormalizedBaseUrl + '/chat/completions'
  else
    Result := ASettings.NormalizedBaseUrl + HELPCHAT_OPENAI_COMPLETIONS_PATH;
end;

class function THelpChatOpenAIProvider.ResponsesUrl(
  const ASettings: THelpChatOpenAISettings): string;
begin
  if ASettings.IsAzure then
    // The v1 API of Azure OpenAI: no deployment in the path, no version.
    Result := ASettings.NormalizedBaseUrl + '/openai/v1/responses'
  else if ASettings.NormalizedBaseUrl.EndsWith('/v1', True) then
    Result := ASettings.NormalizedBaseUrl + '/responses'
  else
    Result := ASettings.NormalizedBaseUrl + HELPCHAT_OPENAI_RESPONSES_PATH;
end;

class function THelpChatOpenAIProvider.BuildResponsesToolsJson(
  const ABrokerToolsJson: string): string;
var
  LSource, LTarget: TJSONArray;
  LItem: TJSONValue;
  LAction, LTool: TJSONObject;
  LSchema: TJSONValue;
begin
  Result := '';
  if Trim(ABrokerToolsJson) = '' then
    Exit;
  LSource := TJSONObject.ParseJSONValue(ABrokerToolsJson) as TJSONArray;
  if LSource = nil then
    Exit;
  try
    LTarget := TJSONArray.Create;
    try
      for LItem in LSource do
      begin
        if not (LItem is TJSONObject) then
          Continue;
        LAction := TJSONObject(LItem);
        LTool := TJSONObject.Create;
        LTool.AddPair('type', 'function');
        LTool.AddPair('name', LAction.GetValue<string>('name', ''));
        LTool.AddPair('description', LAction.GetValue<string>('description', ''));
        LSchema := LAction.GetValue('input_schema');
        if LSchema <> nil then
          LTool.AddPair('parameters', LSchema.Clone as TJSONValue);
        // Strict would want every parameter required.
        LTool.AddPair('strict', TJSONBool.Create(False));
        LTarget.AddElement(LTool);
      end;
      if LTarget.Count > 0 then
        Result := LTarget.ToJSON;
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

class function THelpChatOpenAIProvider.BuildResponsesBody(
  const AHistory: TArray<THelpChatMessage>; const ASystemPrompt: string;
  const ASettings: THelpChatOpenAISettings; const AToolsJson, AExtraItemsJson: string;
  const AAttachments: TArray<THelpChatAttachment>; const ALanguage: THelpChatLanguage;
  const AQuestionContext: string): string;
var
  LRoot, LMsg, LPart: TJSONObject;
  LInput, LInclude, LContent: TJSONArray;
  LValue, LItem: TJSONValue;
  I, J, LLastUser: Integer;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('model', ASettings.ResolveModel);
    if ASystemPrompt <> '' then
      LRoot.AddPair('instructions', ASystemPrompt);
    LRoot.AddPair('max_output_tokens', TJSONNumber.Create(ASettings.MaxTokens));
    LRoot.AddPair('stream', TJSONBool.Create(True));
    // Nothing is kept on the service: every round sends the whole of it,
    // the way the other providers work, and the encrypted reasoning is what
    // lets a reasoning model pick up where it left after an action.
    LRoot.AddPair('store', TJSONBool.Create(False));
    // A model that does not reason refuses the request for it: told once,
    // it is not asked again.
    if not RefusesEncryptedReasoning(ASettings.ResolveModel) then
    begin
      LInclude := TJSONArray.Create;
      LInclude.Add('reasoning.encrypted_content');
      LRoot.AddPair('include', LInclude);
    end;

    LInput := TJSONArray.Create;
    LRoot.AddPair('input', LInput);
    LLastUser := -1;
    if (Length(AAttachments) > 0) or (AQuestionContext <> '') then
      for I := High(AHistory) downto Low(AHistory) do
        if (AHistory[I].Role = hcrUser) and (Trim(AHistory[I].Content) <> '') then
        begin
          LLastUser := I;
          Break;
        end;
    for I := Low(AHistory) to High(AHistory) do
    begin
      if (AHistory[I].Role = hcrSystem) or (Trim(AHistory[I].Content) = '') then
        Continue;
      LMsg := TJSONObject.Create;
      if AHistory[I].Role = hcrUser then
        LMsg.AddPair('role', 'user')
      else
        LMsg.AddPair('role', 'assistant');
      // Parts only with attachments: a question that is text alone goes as
      // text, as it will go in the history of the next request.
      if (I = LLastUser) and (Length(AAttachments) > 0) then
      begin
        LContent := TJSONArray.Create;
        LMsg.AddPair('content', LContent);
        for J := Low(AAttachments) to High(AAttachments) do
        begin
          if (AAttachments[J].Kind = hcakText) or (Length(AAttachments[J].Data) = 0) then
            Continue;
          LPart := TJSONObject.Create;
          if AAttachments[J].Kind = hcakImage then
          begin
            LPart.AddPair('type', 'input_image');
            LPart.AddPair('image_url', 'data:' + AAttachments[J].MediaType + ';base64,' +
              AAttachments[J].Base64);
          end
          else
          begin
            LPart.AddPair('type', 'input_file');
            LPart.AddPair('filename', AAttachments[J].FileName);
            LPart.AddPair('file_data', 'data:' + AAttachments[J].MediaType + ';base64,' +
              AAttachments[J].Base64);
          end;
          LContent.AddElement(LPart);
        end;
        LPart := TJSONObject.Create;
        LPart.AddPair('type', 'input_text');
        LPart.AddPair('text', HelpChatQuestionWithText(AHistory[I].Content, AAttachments, ALanguage));
        LContent.AddElement(LPart);
      end
      else
        LMsg.AddPair('content', AHistory[I].Content);
      LInput.AddElement(LMsg);
      // The context of the question, right after it, in the channel of the
      // application: a developer message never goes back into the history.
      if (I = LLastUser) and (AQuestionContext <> '') then
      begin
        LMsg := TJSONObject.Create;
        LMsg.AddPair('role', 'developer');
        LMsg.AddPair('content', AQuestionContext);
        LInput.AddElement(LMsg);
      end;
    end;

    // The items of the earlier rounds of this reply, as they came, and the
    // results of their actions.
    if Trim(AExtraItemsJson) <> '' then
    begin
      LValue := TJSONObject.ParseJSONValue(AExtraItemsJson);
      try
        if LValue is TJSONArray then
          for LItem in TJSONArray(LValue) do
            LInput.AddElement(LItem.Clone as TJSONValue);
      finally
        LValue.Free;
      end;
    end;

    if Trim(AToolsJson) <> '' then
    begin
      LValue := TJSONObject.ParseJSONValue(AToolsJson);
      if (LValue is TJSONArray) and (TJSONArray(LValue).Count > 0) then
        LRoot.AddPair('tools', LValue)
      else
        LValue.Free;
    end;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatOpenAIProvider.BuildToolsJson(const ABrokerToolsJson: string): string;
var
  LSource, LTarget: TJSONArray;
  LItem: TJSONValue;
  LAction, LTool, LFunction: TJSONObject;
  LSchema: TJSONValue;
begin
  Result := '';
  if Trim(ABrokerToolsJson) = '' then
    Exit;
  LSource := TJSONObject.ParseJSONValue(ABrokerToolsJson) as TJSONArray;
  if LSource = nil then
    Exit;
  try
    LTarget := TJSONArray.Create;
    try
      for LItem in LSource do
      begin
        if not (LItem is TJSONObject) then
          Continue;
        LAction := TJSONObject(LItem);
        LFunction := TJSONObject.Create;
        LFunction.AddPair('name', LAction.GetValue<string>('name', ''));
        LFunction.AddPair('description', LAction.GetValue<string>('description', ''));
        LSchema := LAction.GetValue('input_schema');
        if LSchema <> nil then
          LFunction.AddPair('parameters', LSchema.Clone as TJSONValue);
        LTool := TJSONObject.Create;
        LTool.AddPair('type', 'function');
        LTool.AddPair('function', LFunction);
        LTarget.AddElement(LTool);
      end;
      if LTarget.Count > 0 then
        Result := LTarget.ToJSON;
    finally
      LTarget.Free;
    end;
  finally
    LSource.Free;
  end;
end;

class function THelpChatOpenAIProvider.BuildUserContent(const AText: string;
  const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage): TJSONArray;
var
  LPart, LInner: TJSONObject;
  I: Integer;
begin
  Result := TJSONArray.Create;
  try
    for I := Low(AAttachments) to High(AAttachments) do
    begin
      if (AAttachments[I].Kind = hcakText) or (Length(AAttachments[I].Data) = 0) then
        Continue;
      LPart := TJSONObject.Create;
      LInner := TJSONObject.Create;
      if AAttachments[I].Kind = hcakImage then
      begin
        // An image is a data: URL, the same shape a hosted one would have.
        LPart.AddPair('type', 'image_url');
        LInner.AddPair('url', 'data:' + AAttachments[I].MediaType + ';base64,' +
          AAttachments[I].Base64);
        LPart.AddPair('image_url', LInner);
      end
      else
      begin
        // A PDF is the one file Chat Completions takes, and it wants the name
        // next to the bytes.
        LPart.AddPair('type', 'file');
        LInner.AddPair('filename', AAttachments[I].FileName);
        LInner.AddPair('file_data', 'data:' + AAttachments[I].MediaType + ';base64,' +
          AAttachments[I].Base64);
        LPart.AddPair('file', LInner);
      end;
      Result.AddElement(LPart);
    end;
    LPart := TJSONObject.Create;
    LPart.AddPair('type', 'text');
    LPart.AddPair('text', HelpChatQuestionWithText(AText, AAttachments, ALanguage));
    Result.AddElement(LPart);
  except
    Result.Free;
    raise;
  end;
end;

class function THelpChatOpenAIProvider.BuildRequestBody(
  const AHistory: TArray<THelpChatMessage>; const ASystemPrompt: string;
  const ASettings: THelpChatOpenAISettings;
  const AToolsJson, AExtraMessagesJson: string;
  const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage; const AReasoningEffort, AQuestionContext: string): string;
var
  LRoot, LMsg, LStreamOptions, LPart: TJSONObject;
  LMessages, LContent: TJSONArray;
  LValue, LItem: TJSONValue;
  I, LLastUser: Integer;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('model', ASettings.ResolveModel);
    LRoot.AddPair('max_completion_tokens', TJSONNumber.Create(ASettings.MaxTokens));
    if Trim(AReasoningEffort) <> '' then
      LRoot.AddPair('reasoning_effort', Trim(AReasoningEffort));
    LRoot.AddPair('stream', TJSONBool.Create(True));
    // Ask for the usage record at the end of the stream: harmless where it is
    // not supported, and the only way to know the cost of a reply.
    LStreamOptions := TJSONObject.Create;
    LStreamOptions.AddPair('include_usage', TJSONBool.Create(True));
    LRoot.AddPair('stream_options', LStreamOptions);

    LMessages := TJSONArray.Create;
    LRoot.AddPair('messages', LMessages);
    // Unlike Anthropic, the instruction is just the first message.
    if ASystemPrompt <> '' then
    begin
      LMsg := TJSONObject.Create;
      LMsg.AddPair('role', 'system');
      LMsg.AddPair('content', ASystemPrompt);
      LMessages.AddElement(LMsg);
    end;
    // The attachments and the context belong to the question being asked:
    // the last user turn.
    LLastUser := -1;
    if (Length(AAttachments) > 0) or (AQuestionContext <> '') then
      for I := High(AHistory) downto Low(AHistory) do
        if (AHistory[I].Role = hcrUser) and (Trim(AHistory[I].Content) <> '') then
        begin
          LLastUser := I;
          Break;
        end;
    for I := Low(AHistory) to High(AHistory) do
    begin
      if (AHistory[I].Role = hcrSystem) or (Trim(AHistory[I].Content) = '') then
        Continue;
      LMsg := TJSONObject.Create;
      if AHistory[I].Role = hcrUser then
        LMsg.AddPair('role', 'user')
      else
        LMsg.AddPair('role', 'assistant');
      if (I = LLastUser) and (Length(AAttachments) > 0) then
      begin
        LContent := BuildUserContent(AHistory[I].Content, AAttachments, ALanguage);
        LMsg.AddPair('content', LContent);
        if AQuestionContext <> '' then
        begin
          LPart := TJSONObject.Create;
          LPart.AddPair('type', 'text');
          LPart.AddPair('text', AQuestionContext);
          LContent.AddElement(LPart);
        end;
      end
      // The context in the message of the question, in front of it: a
      // system message after the first is not something every server of this
      // API accepts (the chat template of several local models refuses it),
      // and with the excerpts after it a small local model lost the request
      // (qwen3-coder, measured). The question comes back next time without
      // it, so everything before it is still the prefix the cache knows.
      else if (I = LLastUser) and (AQuestionContext <> '') then
        LMsg.AddPair('content', AQuestionContext + #10#10 + AHistory[I].Content)
      else
        LMsg.AddPair('content', AHistory[I].Content);
      LMessages.AddElement(LMsg);
    end;

    // What this reply already exchanged with the tools: the assistant turn
    // that asked and one tool turn per result.
    if Trim(AExtraMessagesJson) <> '' then
    begin
      LValue := TJSONObject.ParseJSONValue(AExtraMessagesJson);
      try
        if LValue is TJSONArray then
          for LItem in TJSONArray(LValue) do
            LMessages.AddElement(LItem.Clone as TJSONValue);
      finally
        LValue.Free;
      end;
    end;

    if Trim(AToolsJson) <> '' then
    begin
      LValue := TJSONObject.ParseJSONValue(AToolsJson);
      if (LValue is TJSONArray) and (TJSONArray(LValue).Count > 0) then
        LRoot.AddPair('tools', LValue)
      else
        LValue.Free;
    end;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatOpenAIProvider.AsksForNoReasoning(const AError: string): Boolean;
var
  LError: string;
begin
  LError := AError.ToLower;
  Result := LError.Contains('reasoning_effort') and LError.Contains('''none''');
end;

class function THelpChatOpenAIProvider.RefusesReasoningEffort(const AError: string): Boolean;
var
  LError: string;
begin
  // "reasoning_effort", "reasoning.effort", "does not support thinking".
  LError := AError.ToLower;
  Result := LError.Contains('reasoning') or LError.Contains('effort') or
    LError.Contains('think');
end;

class function THelpChatOpenAIProvider.AsksForNoEncryptedReasoning(
  const AError: string): Boolean;
var
  LError: string;
begin
  LError := AError.ToLower;
  Result := LError.Contains('encrypted content') or LError.Contains('encrypted_content');
end;

var
  // The models that have no encrypted reasoning to give, remembered for the
  // whole process: asking each of them once is enough.
  GPlainModels: TStringList;

class function THelpChatOpenAIProvider.RefusesEncryptedReasoning(const AModel: string): Boolean;
begin
  TMonitor.Enter(GPlainModels);
  try
    Result := GPlainModels.IndexOf(AModel) >= 0;
  finally
    TMonitor.Exit(GPlainModels);
  end;
end;

function THelpChatOpenAIProvider.LearnsNoEncryptedReasoning(const AError: string): Boolean;
var
  LModel: string;
begin
  LModel := Settings.OpenAI.ResolveModel;
  Result := AsksForNoEncryptedReasoning(AError) and not RefusesEncryptedReasoning(LModel);
  if not Result then
    Exit;
  TMonitor.Enter(GPlainModels);
  try
    GPlainModels.Add(LModel);
  finally
    TMonitor.Exit(GPlainModels);
  end;
  LogRetry('repeated without the encrypted reasoning, the model has none', AError);
end;

class function THelpChatOpenAIProvider.BuildAssistantToolMessage(const AText: string;
  const ACalls: TArray<THelpChatToolCall>): string;
var
  LMsg, LCall, LFunction: TJSONObject;
  LCalls: TJSONArray;
  I: Integer;
begin
  LMsg := TJSONObject.Create;
  try
    LMsg.AddPair('role', 'assistant');
    // The field has to be there even when the model only asked for actions.
    LMsg.AddPair('content', AText);
    LCalls := TJSONArray.Create;
    LMsg.AddPair('tool_calls', LCalls);
    for I := Low(ACalls) to High(ACalls) do
    begin
      LFunction := TJSONObject.Create;
      LFunction.AddPair('name', ACalls[I].Name);
      // An action without parameters streams no arguments at all.
      if Trim(ACalls[I].InputJson) = '' then
        LFunction.AddPair('arguments', '{}')
      else
        LFunction.AddPair('arguments', ACalls[I].InputJson);
      LCall := TJSONObject.Create;
      LCall.AddPair('id', ACalls[I].Id);
      LCall.AddPair('type', 'function');
      LCall.AddPair('function', LFunction);
      LCalls.AddElement(LCall);
    end;
    Result := LMsg.ToJSON;
  finally
    LMsg.Free;
  end;
end;

function THelpChatOpenAIProvider.ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
  const ACancel: IHelpChatCancelToken; const AResponses: Boolean): string;
var
  LMessages: TJSONArray;
  LMsg: TJSONObject;
  LOutcome: THelpChatActionOutcome;
  LResult: string;
  I: Integer;
begin
  // One message per result, unlike Anthropic where they share a single turn.
  LMessages := TJSONArray.Create;
  try
    for I := Low(ACalls) to High(ACalls) do
    begin
      CheckCancelled(ACancel);
      // Invoke never raises: whatever happened is told to the model as text.
      // InvokeAction, not Actions.Invoke: after a refusal the base class
      // answers every later call of this reply without asking again.
      LOutcome := InvokeAction(ACalls[I].Name, ACalls[I].InputJson, ACancel, LResult);
      if LOutcome = aoCancelled then
        raise EHelpChatCancelled.Create(Msg(hcmCancelled));
      // This API has no error flag on a tool message: a failure is told by
      // the sentence alone.
      LMsg := TJSONObject.Create;
      if AResponses then
      begin
        // The Responses API: an item that names the call it answers.
        LMsg.AddPair('type', 'function_call_output');
        LMsg.AddPair('call_id', ACalls[I].Id);
        LMsg.AddPair('output', HelpChatActionOutcomeText(LOutcome, ACalls[I].Name, LResult));
      end
      else
      begin
        LMsg.AddPair('role', 'tool');
        LMsg.AddPair('tool_call_id', ACalls[I].Id);
        LMsg.AddPair('content', HelpChatActionOutcomeText(LOutcome, ACalls[I].Name, LResult));
      end;
      LMessages.AddElement(LMsg);
    end;
    Result := LMessages.ToJSON;
    // The caller splices this into an array, so hand back the elements only.
    Result := Copy(Result, 2, Length(Result) - 2);
  finally
    LMessages.Free;
  end;
end;

class function THelpChatOpenAIProvider.ExtractApiError(const ARaw: string;
  const AStatus: Integer; const AStatusText: string; const ASettings: THelpChatSettings): string;
var
  LValue: TJSONValue;
  LLang: THelpChatLanguage;
begin
  Result := '';
  if Trim(ARaw) <> '' then
  begin
    try
      LValue := TJSONObject.ParseJSONValue(Trim(ARaw));
    except
      LValue := nil;
    end;
    if LValue <> nil then
      try
        if LValue is TJSONObject then
        begin
          Result := HelpChatJsonErrorText(TJSONObject(LValue));
        end;
      finally
        LValue.Free;
      end;
  end;
  if Result = '' then
  begin
    if Assigned(ASettings) then
      LLang := ASettings.Language
    else
      LLang := hclAuto;
    Result := HelpChatMsgFmt(hcmApiError, [HelpChatServiceName(ASettings, 'openai'), AStatus, AStatusText], LLang);
  end;
end;

procedure THelpChatOpenAIProvider.Post(const ABody, AUrl: string;
  const AStream: THelpChatSseStreamBase; const ACancel: IHelpChatCancelToken);
var
  LClient: THTTPClient;
  LSource: TStringStream;
  LWatcher: TAbortWatcher;
  LHeaders: TNetHeaders;
  LResponse: IHTTPResponse;
  LKey: string;
  LStart: Cardinal;
begin
  LClient := THTTPClient.Create;
  LSource := TStringStream.Create(ABody, TEncoding.UTF8);
  LWatcher := TAbortWatcher.Create(ACancel);
  try
    LClient.ConnectionTimeout := Settings.OpenAI.ConnectTimeoutMs;
    LClient.ResponseTimeout := Settings.OpenAI.ResponseTimeoutMs;
    LClient.OnReceiveData := LWatcher.OnReceiveData;
    // No redirect is followed: the client would repeat the headers - the
    // key among them - at whatever address the answer names.
    LClient.HandleRedirects := False;

    LKey := Settings.OpenAI.ResolveApiKey;
    LHeaders := [
      TNetHeader.Create('content-type', 'application/json'),
      TNetHeader.Create('accept', 'text/event-stream')
    ];
    // Azure authenticates with its own header; a local server with none.
    if LKey <> '' then
      if Settings.OpenAI.IsAzure then
        LHeaders := LHeaders + [TNetHeader.Create('api-key', LKey)]
      else
        LHeaders := LHeaders + [TNetHeader.Create('Authorization', 'Bearer ' + LKey)];
    if Settings.OpenAI.Organization <> '' then
      LHeaders := LHeaders + [TNetHeader.Create('OpenAI-Organization', Settings.OpenAI.Organization)];

    LogPost(AUrl, ABody);
    LStart := TThread.GetTickCount;
    try
      LResponse := LClient.Post(AUrl, LSource, AStream, LHeaders);
    except
      on E: Exception do
        if Assigned(ACancel) and ACancel.IsCancelled then
          raise EHelpChatCancelled.Create(Msg(hcmCancelled))
        else
          raise;
    end;
    AStream.Finish;
    LogPosted(AUrl, LResponse.StatusCode, LResponse.StatusText,
      TThread.GetTickCount - LStart, AStream.Raw);
    CheckCancelled(ACancel);

    // A redirect is an error too: it was not followed.
    if LResponse.StatusCode >= 300 then
      raise EHelpChatError.Create(ExtractApiError(AStream.Raw, LResponse.StatusCode,
        LResponse.StatusText, Settings));
    if AStream.Error <> '' then
      raise EHelpChatError.Create(AStream.Error);
  finally
    LWatcher.Free;
    LSource.Free;
    LClient.Free;
  end;
end;

function THelpChatOpenAIProvider.PostRound(const ABody: string;
  const AOnToken: THelpChatTokenProc; const ACancel: IHelpChatCancelToken): THelpChatOpenAIStream;
begin
  Result := THelpChatOpenAIStream.Create(AOnToken);
  try
    Post(ABody, CompletionsUrl(Settings.OpenAI), Result, ACancel);
  except
    Result.Free;
    raise;
  end;
end;

class function THelpChatOpenAIProvider.SplitsPrompt: Boolean;
begin
  Result := True;
end;

class function THelpChatOpenAIProvider.BuildCompletionBody(const ASystem, AUser: string;
  const ASettings: THelpChatOpenAISettings; const AReasoningEffort: string): string;
begin
  if ASettings.UsesResponses then
  begin
    Result := HelpChatJsonSetNumber(BuildResponsesBody(SingleQuestion(AUser), ASystem,
      ASettings, '', '[]'), 'max_output_tokens', HELPCHAT_SEARCH_TERMS_THINKING_TOKENS);
    if AReasoningEffort <> '' then
      Result := HelpChatJsonSetString(Result, 'reasoning.effort', AReasoningEffort);
  end
  else if AReasoningEffort <> '' then
    Result := HelpChatJsonSetNumber(BuildRequestBody(SingleQuestion(AUser), ASystem,
      ASettings, '', '[]', nil, hclAuto, AReasoningEffort), 'max_completion_tokens',
      HELPCHAT_SEARCH_TERMS_MAX_TOKENS)
  else
    Result := HelpChatJsonSetNumber(BuildRequestBody(SingleQuestion(AUser), ASystem,
      ASettings, '', '[]'), 'max_completion_tokens', HELPCHAT_SEARCH_TERMS_THINKING_TOKENS);
end;

function THelpChatOpenAIProvider.CompleteText(const ASystem, AUser: string;
  const ACancel: IHelpChatCancelToken): string;
var
  LResponses: THelpChatOpenAIResponsesStream;
  LStream: THelpChatOpenAIStream;
  LEffort: string;
begin
  Result := '';
  if (Settings.OpenAI.ResolveApiKey = '') and
     SameText(Settings.OpenAI.NormalizedBaseUrl, HELPCHAT_OPENAI_DEF_BASEURL) then
    Exit;
  if Settings.OpenAI.UsesResponses then
  begin
    // No reasoning for a line of terms (gpt-6-luna took two seconds with
    // it); a model that refuses the effort gets the request without it.
    // Asked again only for what the service said about the request itself:
    // any other error (a key, a rate limit) is the answer.
    LEffort := 'none';
    LResponses := nil;
    try
      while LResponses = nil do
      begin
        LResponses := THelpChatOpenAIResponsesStream.Create(nil);
        try
          Post(BuildCompletionBody(ASystem, AUser, Settings.OpenAI, LEffort),
            ResponsesUrl(Settings.OpenAI), LResponses, ACancel);
        except
          on E: EHelpChatError do
          begin
            FreeAndNil(LResponses);
            if E is EHelpChatCancelled then
              raise;
            if LearnsNoEncryptedReasoning(E.Message) then
              Continue;
            if (LEffort = '') or not RefusesReasoningEffort(E.Message) then
              raise;
            LogRetry('search terms asked again without the reasoning effort', E.Message);
            LEffort := '';
          end;
        end;
      end;
      ReportTokenUsage(LResponses.Usage);
      Result := LResponses.Text;
    finally
      LResponses.Free;
    end;
    Exit;
  end;
  try
    LStream := PostRound(BuildCompletionBody(ASystem, AUser, Settings.OpenAI, 'none'), nil, ACancel);
  except
    on E: EHelpChatError do
    begin
      if (E is EHelpChatCancelled) or not RefusesReasoningEffort(E.Message) then
        raise;
      // A server or a model that does not know the effort: as a reply asks.
      LogRetry('search terms asked again without the reasoning effort', E.Message);
      LStream := PostRound(BuildCompletionBody(ASystem, AUser, Settings.OpenAI, ''), nil, ACancel);
    end;
  end;
  try
    ReportTokenUsage(LStream.Usage);
    Result := LStream.Text;
  finally
    LStream.Free;
  end;
end;

function THelpChatOpenAIProvider.GenerateResponses(const AHistory: TArray<THelpChatMessage>;
  const ASystem, ATools, AQuestionContext: string; const AMaxRounds: Integer;
  const AOnToken: THelpChatTokenProc; const ACancel: IHelpChatCancelToken): string;
var
  LStream: THelpChatOpenAIResponsesStream;
  LExtra, LText: TStringBuilder;
  LRound: Integer;
  LCalls: TArray<THelpChatToolCall>;
begin
  LText := TStringBuilder.Create;
  LExtra := TStringBuilder.Create; // the items of the earlier rounds, as a JSON array body
  try
    for LRound := 1 to AMaxRounds do
    begin
      LStream := THelpChatOpenAIResponsesStream.Create(AOnToken);
      try
        try
          Post(BuildResponsesBody(AHistory, ASystem, Settings.OpenAI, ATools,
            '[' + LExtra.ToString + ']', Attachments, Settings.Language, AQuestionContext),
            ResponsesUrl(Settings.OpenAI), LStream, ACancel);
        except
          // A model that does not reason: the same round once more, without
          // asking for the reasoning. A refused request streamed nothing.
          on E: EHelpChatError do
          begin
            if (E is EHelpChatCancelled) or not LearnsNoEncryptedReasoning(E.Message) then
              raise;
            FreeAndNil(LStream);
            LStream := THelpChatOpenAIResponsesStream.Create(AOnToken);
            Post(BuildResponsesBody(AHistory, ASystem, Settings.OpenAI, ATools,
              '[' + LExtra.ToString + ']', Attachments, Settings.Language, AQuestionContext),
              ResponsesUrl(Settings.OpenAI), LStream, ACancel);
          end;
        end;
        ReportTokenUsage(LStream.Usage);
        LText.Append(LStream.Text);
        LCalls := LStream.ToolCalls;
        if (Length(LCalls) = 0) or (ATools = '') then
        begin
          if LStream.CutAtLimit then
            NoteReplyCut(LText, AOnToken);
          Break;
        end;
        if LRound = AMaxRounds then
        begin
          NoteActionsNotRun(LText, AOnToken);
          Break;
        end;
        // Everything the round produced goes back, the encrypted reasoning
        // included, then one result per call.
        if LExtra.Length > 0 then
          LExtra.Append(',');
        LExtra.Append(LStream.ItemsJson);
        LExtra.Append(',');
        LExtra.Append(ExecuteToolCalls(LCalls, ACancel, True));
        if LText.Length > 0 then
        begin
          if Assigned(AOnToken) then
            AOnToken(sLineBreak + sLineBreak);
          LText.Append(sLineBreak + sLineBreak);
        end;
      finally
        LStream.Free;
      end;
      CheckCancelled(ACancel);
    end;
    Result := TrimRight(LText.ToString);
    if Trim(Result) = '' then
      Result := Msg(hcmEmptyReply);
  finally
    LExtra.Free;
    LText.Free;
  end;
end;

function THelpChatOpenAIProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  LSystem, LTools, LEffort, LQuestionContext: string;
  LStream: THelpChatOpenAIStream;
  LExtra: TStringBuilder;
  LText: TStringBuilder;
  LRound, LMaxRounds: Integer;
  LCalls: TArray<THelpChatToolCall>;
begin
  LEffort := '';
  // Only OpenAI itself is refused here: another endpoint is left to answer
  // for itself, and a service that wants a key says so with its own 401 -
  // ConfigurationIssue is what keeps such a model out of the panel.
  if (Settings.OpenAI.ResolveApiKey = '') and
     SameText(Settings.OpenAI.NormalizedBaseUrl, HELPCHAT_OPENAI_DEF_BASEURL) then
    raise EHelpChatConfigError.Create(MsgFmt(hcmProviderKeyMissing,
      [HELPCHAT_PROVIDER_OPENAI, THelpChatOpenAISettings.SectionName,
       THelpChatOpenAISettings.ApiKeyEnvVar,
       TPath.GetDirectoryName(THelpChatSettings.SharedUserConfigFile),
       TPath.GetDirectoryName(THelpChatSettings.UserConfigFile)]));

  CheckCancelled(ACancel);
  // The prompt every provider shares, in two parts: what stays the same for
  // every question is the system prompt, now, the screen and the excerpts go
  // with the question - the automatic prompt cache of the service then reads
  // the system prompt and the conversation again at the next question.
  LSystem := BuildStablePrompt(AContext, Settings);
  LQuestionContext := BuildQuestionContext(AHistory, AContext, Settings, Retriever);
  LMaxRounds := Settings.OpenAI.ResolveMaxToolRounds;
  LTools := '';
  if OffersActions(LMaxRounds) then
  begin
    // The broker speaks the Anthropic shape; this API wants its own, and
    // the Responses API another one still.
    if Settings.OpenAI.UsesResponses then
      LTools := BuildResponsesToolsJson(Actions.ToolsJson)
    else
      LTools := BuildToolsJson(Actions.ToolsJson);
    if LTools <> '' then
      LSystem := LSystem + sLineBreak + sLineBreak + HELPCHAT_MODEL_ACTIONS_RULE;
  end;
  CheckCancelled(ACancel);
  // OpenAI itself: the API where a reasoning model keeps its reasoning while
  // it acts. Chat Completions refuses the two together for the GPT-6 family.
  if Settings.OpenAI.UsesResponses then
    Exit(GenerateResponses(AHistory, LSystem, LTools, LQuestionContext, LMaxRounds, AOnToken, ACancel));

  LText := TStringBuilder.Create;
  LExtra := TStringBuilder.Create; // the tool turns, as a JSON array body
  try
    for LRound := 1 to LMaxRounds do
    begin
      // At most twice: a reasoning model that refuses actions with its
      // reasoning on (the GPT-6 family in Chat Completions) says what it
      // wants, and gets the same round again without reasoning - and so the
      // rest of this reply. A refused request streamed nothing, so nothing
      // is said twice.
      LStream := nil;
      while LStream = nil do
        try
          LStream := PostRound(BuildRequestBody(AHistory, LSystem, Settings.OpenAI,
            LTools, '[' + LExtra.ToString + ']', Attachments, Settings.Language, LEffort,
            LQuestionContext), AOnToken, ACancel);
        except
          on E: EHelpChatError do
            if (LEffort = '') and (LTools <> '') and AsksForNoReasoning(E.Message) then
            begin
              LogRetry('repeated with reasoning_effort none, the model refuses ' +
                'actions while reasoning', E.Message);
              LEffort := 'none';
            end
            else
              raise;
        end;
      try
        ReportTokenUsage(LStream.Usage);
        LText.Append(LStream.Text);
        LCalls := LStream.ToolCalls;
        // Nothing to do, or nobody to do it: this is the reply. The calls
        // are the signal, not the finish reason: several servers that speak
        // this API (Ollama, LM Studio, some gateways) end a turn that asks
        // for a tool with "stop".
        if (Length(LCalls) = 0) or (LTools = '') then
        begin
          if LStream.FinishReason = 'length' then
            NoteReplyCut(LText, AOnToken);
          Break;
        end;
        // The last round ends here as well, with the actions it asked for
        // not run, and the reply says so.
        if LRound = LMaxRounds then
        begin
          NoteActionsNotRun(LText, AOnToken);
          Break;
        end;
        if LExtra.Length > 0 then
          LExtra.Append(',');
        LExtra.Append(BuildAssistantToolMessage(LStream.Text, LCalls));
        LExtra.Append(',');
        LExtra.Append(ExecuteToolCalls(LCalls, ACancel));
        // What the model says after acting is a new paragraph, not a sentence
        // glued to the previous one. The break goes through the token callback
        // too, so the streamed text and the final one stay identical.
        if LText.Length > 0 then
        begin
          if Assigned(AOnToken) then
            AOnToken(sLineBreak + sLineBreak);
          LText.Append(sLineBreak + sLineBreak);
        end;
      finally
        LStream.Free;
      end;
      CheckCancelled(ACancel);
    end;

    Result := TrimRight(LText.ToString);
    if Trim(Result) = '' then
      Result := Msg(hcmEmptyReply);
  finally
    LExtra.Free;
    LText.Free;
  end;
end;

initialization
  GPlainModels := TStringList.Create;
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_OPENAI, THelpChatOpenAIProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_OPENAI);
  GPlainModels.Free;

end.
