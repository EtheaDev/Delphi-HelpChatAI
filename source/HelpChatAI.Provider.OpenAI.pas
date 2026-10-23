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
  HelpChatAI.Settings,
  HelpChatAI.Actions,
  HelpChatAI.Provider,
  HelpChatAI.Provider.Sse;

const
  HELPCHAT_PROVIDER_OPENAI = 'openai';
  /// <summary>Path appended to BaseUrl when this is not Azure.</summary>
  HELPCHAT_OPENAI_COMPLETIONS_PATH = '/v1/chat/completions';

type
  /// <summary>Parses the <c>chat.completion.chunk</c> events: the text
  /// deltas, the tool calls assembled per index, and the finish reason.</summary>
  THelpChatOpenAIStream = class(THelpChatSseStreamBase)
  strict private
    FFinishReason: string;
    FToolCalls: TList<THelpChatToolCall>;
    FToolIndexes: TDictionary<Integer, Integer>; // delta index -> tool call
    procedure ApplyToolDelta(const ADelta: TJSONObject);
    function GetToolCalls: TArray<THelpChatToolCall>;
  strict protected
    procedure ProcessLine(const ALine: string); override;
  public
    constructor Create(const AOnToken: THelpChatTokenProc);
    destructor Destroy; override;
    /// <summary>finish_reason of the choice: stop, length, tool_calls...</summary>
    property FinishReason: string read FFinishReason;
    /// <summary>The actions the model asked for in this reply, in order.</summary>
    property ToolCalls: TArray<THelpChatToolCall> read GetToolCalls;
  end;

  THelpChatOpenAIProvider = class(THelpChatProviderBase)
  strict private
    /// <summary>Runs what the model asked for and builds the <c>tool</c>
    /// messages that carry the results back.</summary>
    function ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
      const ACancel: IHelpChatCancelToken): string;
    /// <summary>One request/response round; returns the stream it parsed.</summary>
    function PostRound(const ABody: string; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): THelpChatOpenAIStream;
  public
    /// <summary>Full URL of the endpoint: Azure puts the deployment in the
    /// path, a BaseUrl that already ends in /v1 does not get a second one.
    /// Public for tests.</summary>
    class function CompletionsUrl(const ASettings: THelpChatOpenAISettings): string; static;
    function GetName: string; override;
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; override;
    function SupportsStreaming: Boolean; override;
    function SupportsActions: Boolean; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;

    /// <summary>The actions of the application, as the <c>tools</c> array of
    /// this API: the broker describes them with a JSON Schema under
    /// <c>input_schema</c>, here each becomes
    /// <c>{"type":"function","function":{name,description,parameters}}</c>.
    /// Public for tests.</summary>
    class function BuildToolsJson(const ABrokerToolsJson: string): string; static;
    /// <summary>Builds the JSON body of the request. <c>AExtraMessagesJson</c>
    /// is a JSON array of the turns this reply already exchanged with the
    /// tools. Public for tests; no network involved.</summary>
    class function BuildRequestBody(const AHistory: TArray<THelpChatMessage>;
      const ASystemPrompt: string; const ASettings: THelpChatOpenAISettings;
      const AToolsJson, AExtraMessagesJson: string): string; static;
    /// <summary>The assistant turn that asked for the actions, as the API
    /// wants it back.</summary>
    class function BuildAssistantToolMessage(const AText: string;
      const ACalls: TArray<THelpChatToolCall>): string; static;
    /// <summary>Extracts a readable message from a non-2xx response body.</summary>
    class function ExtractApiError(const ARaw: string; const AStatus: Integer;
      const AStatusText: string; const ASettings: THelpChatSettings): string; static;
  end;

implementation

uses
  System.IOUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  HelpChatAI.Messages;

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
  LName := '';
  LArgs := '';
  LFunction := ADelta.GetValue('function') as TJSONObject;
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
    LErr := LRoot.GetValue('error') as TJSONObject;
    if LErr <> nil then
    begin
      FError := LErr.GetValue<string>('message', '');
      if FError = '' then
        FError := HelpChatMsg(hcmProviderError);
      Exit;
    end;

    LChoices := LRoot.GetValue('choices') as TJSONArray;
    if (LChoices = nil) or (LChoices.Count = 0) then
      Exit;
    LChoice := LChoices.Items[0] as TJSONObject;
    if LChoice = nil then
      Exit;

    LFinish := LChoice.GetValue<string>('finish_reason', '');
    if LFinish <> '' then
      FFinishReason := LFinish;

    LDelta := LChoice.GetValue('delta') as TJSONObject;
    if LDelta = nil then
      Exit;
    EmitToken(LDelta.GetValue<string>('content', ''));

    LToolDeltas := LDelta.GetValue('tool_calls') as TJSONArray;
    if LToolDeltas <> nil then
      for LItem in LToolDeltas do
        if LItem is TJSONObject then
          ApplyToolDelta(TJSONObject(LItem));
  finally
    LRoot.Free;
  end;
end;

{ THelpChatOpenAIProvider }

function THelpChatOpenAIProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_OPENAI;
end;

class function THelpChatOpenAIProvider.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
begin
  Result := '';
  if not Assigned(ASettings) then
    Exit;
  // A local Ollama or LM Studio asks for no key at all: only a service we are
  // actually calling over the internet can be said to be missing one.
  if (ASettings.OpenAI.ResolveApiKey = '') and
     SameText(ASettings.OpenAI.NormalizedBaseUrl, HELPCHAT_OPENAI_DEF_BASEURL) then
    Result := Format('No API key: set Settings.OpenAI.ApiKey, the OpenAI/ApiKey ' +
      'entry of helpchatai.json, or the %s environment variable. A local server ' +
      '(Ollama, LM Studio) needs none: point Settings.OpenAI.BaseUrl at it.',
      [HELPCHAT_OPENAI_APIKEY_ENVVAR]);
end;

function THelpChatOpenAIProvider.SupportsStreaming: Boolean;
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

class function THelpChatOpenAIProvider.BuildRequestBody(
  const AHistory: TArray<THelpChatMessage>; const ASystemPrompt: string;
  const ASettings: THelpChatOpenAISettings;
  const AToolsJson, AExtraMessagesJson: string): string;
var
  LRoot, LMsg, LStreamOptions: TJSONObject;
  LMessages: TJSONArray;
  LValue, LItem: TJSONValue;
  I: Integer;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('model', ASettings.ResolveModel);
    LRoot.AddPair('max_completion_tokens', TJSONNumber.Create(ASettings.MaxTokens));
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
    for I := Low(AHistory) to High(AHistory) do
    begin
      if (AHistory[I].Role = hcrSystem) or (Trim(AHistory[I].Content) = '') then
        Continue;
      LMsg := TJSONObject.Create;
      if AHistory[I].Role = hcrUser then
        LMsg.AddPair('role', 'user')
      else
        LMsg.AddPair('role', 'assistant');
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
  const ACancel: IHelpChatCancelToken): string;
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
      LOutcome := Actions.Invoke(ACalls[I].Name, ACalls[I].InputJson, ACancel, LResult);
      if LOutcome = aoCancelled then
        raise EHelpChatCancelled.Create(Msg(hcmCancelled));
      LMsg := TJSONObject.Create;
      LMsg.AddPair('role', 'tool');
      LMsg.AddPair('tool_call_id', ACalls[I].Id);
      LMsg.AddPair('content', HelpChatActionOutcomeText(LOutcome, ACalls[I].Name, LResult));
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
  LErr: TJSONObject;
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
          LErr := TJSONObject(LValue).GetValue('error') as TJSONObject;
          if LErr <> nil then
            Result := LErr.GetValue<string>('message', '');
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
    Result := HelpChatMsgFmt(hcmApiError, [AStatus, AStatusText], LLang);
  end;
end;

function THelpChatOpenAIProvider.PostRound(const ABody: string;
  const AOnToken: THelpChatTokenProc; const ACancel: IHelpChatCancelToken): THelpChatOpenAIStream;
var
  LClient: THTTPClient;
  LSource: TStringStream;
  LWatcher: TAbortWatcher;
  LHeaders: TNetHeaders;
  LResponse: IHTTPResponse;
  LKey: string;
begin
  Result := THelpChatOpenAIStream.Create(AOnToken);
  LClient := THTTPClient.Create;
  LSource := TStringStream.Create(ABody, TEncoding.UTF8);
  LWatcher := TAbortWatcher.Create(ACancel);
  try
    try
      LClient.ConnectionTimeout := Settings.OpenAI.ConnectTimeoutMs;
      LClient.ResponseTimeout := Settings.OpenAI.ResponseTimeoutMs;
      LClient.OnReceiveData := LWatcher.OnReceiveData;

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

      try
        LResponse := LClient.Post(CompletionsUrl(Settings.OpenAI), LSource, Result, LHeaders);
      except
        on E: Exception do
          if Assigned(ACancel) and ACancel.IsCancelled then
            raise EHelpChatCancelled.Create(Msg(hcmCancelled))
          else
            raise;
      end;
      Result.Finish;
      CheckCancelled(ACancel);

      if LResponse.StatusCode >= 400 then
        raise EHelpChatError.Create(ExtractApiError(Result.Raw, LResponse.StatusCode,
          LResponse.StatusText, Settings));
      if Result.Error <> '' then
        raise EHelpChatError.Create(Result.Error);
    except
      Result.Free;
      raise;
    end;
  finally
    LWatcher.Free;
    LSource.Free;
    LClient.Free;
  end;
end;

function THelpChatOpenAIProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  LSystem, LTools: string;
  LStream: THelpChatOpenAIStream;
  LExtra: TStringBuilder;
  LText: TStringBuilder;
  LRound, LMaxRounds: Integer;
  LCalls: TArray<THelpChatToolCall>;
begin
  if (Settings.OpenAI.ResolveApiKey = '') and
     SameText(Settings.OpenAI.NormalizedBaseUrl, HELPCHAT_OPENAI_DEF_BASEURL) then
    raise EHelpChatConfigError.Create(MsgFmt(hcmProviderKeyMissing,
      [HELPCHAT_PROVIDER_OPENAI, THelpChatOpenAISettings.SectionName,
       THelpChatOpenAISettings.ApiKeyEnvVar,
       TPath.GetDirectoryName(THelpChatSettings.SharedUserConfigFile),
       TPath.GetDirectoryName(THelpChatSettings.UserConfigFile)]));

  CheckCancelled(ACancel);
  LSystem := BuildSystemPrompt(AHistory, AContext, Settings, Retriever);
  LTools := '';
  if Assigned(Actions) and Actions.HasActions then
  begin
    LTools := BuildToolsJson(Actions.ToolsJson);
    if LTools <> '' then
      LSystem := LSystem + sLineBreak + sLineBreak + HELPCHAT_MODEL_ACTIONS_RULE;
  end;
  CheckCancelled(ACancel);

  LMaxRounds := Settings.OpenAI.ResolveMaxToolRounds;
  LText := TStringBuilder.Create;
  LExtra := TStringBuilder.Create; // the tool turns, as a JSON array body
  try
    for LRound := 1 to LMaxRounds do
    begin
      LStream := PostRound(BuildRequestBody(AHistory, LSystem, Settings.OpenAI,
        LTools, '[' + LExtra.ToString + ']'), AOnToken, ACancel);
      try
        LText.Append(LStream.Text);
        LCalls := LStream.ToolCalls;
        // Nothing to do, or nobody to do it: this is the reply.
        if (LStream.FinishReason <> 'tool_calls') or (Length(LCalls) = 0) or
           (LTools = '') or (LRound = LMaxRounds) then
          Break;
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
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_OPENAI, THelpChatOpenAIProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_OPENAI);

end.
