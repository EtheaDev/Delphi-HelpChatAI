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
///  Claude provider (<c>claude</c>): Anthropic Messages API with
///  <c>stream: true</c>. There is no official Anthropic SDK for Delphi, so the
///  call is a single <c>System.Net.HttpClient</c> POST whose response body is
///  streamed into <see cref="THelpChatSseStream" />, which parses the
///  Server-Sent Events as bytes arrive and forwards each text delta to the
///  runner's token callback. Streaming therefore crosses provider, runner and
///  store without any persistent channel towards the UI.
///
///  Replies are grounded on the documentation: the pages best matching the
///  question are injected into the system prompt, together with the screen the
///  user is on, so the model cites the right page instead of inventing.
///
///  Cancellation aborts the HTTP transfer through <c>OnReceiveData</c>: on a
///  desktop the application must close at once even with a reply in flight.
///
///  When the application registered actions (<see cref="HelpChatAI.Actions" />)
///  they are declared as tools and the reply becomes a short conversation: the
///  model asks for an action, this provider has it executed where the
///  application lives, hands the result back and lets the model continue, up to
///  <c>Claude.MaxToolRounds</c> times.
/// </summary>
unit HelpChatAI.Provider.Claude;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Actions,
  HelpChatAI.Provider,
  HelpChatAI.Provider.Sse;

const
  HELPCHAT_PROVIDER_CLAUDE = 'claude';
  HELPCHAT_CLAUDE_MESSAGES_PATH = '/v1/messages';

type
  /// <summary>
  ///  Write-only TStream receiving the Anthropic SSE body as THTTPClient streams
  ///  it. Accumulates bytes, splits on newlines and, for each complete
  ///  <c>data:</c> line, decodes the JSON event: a <c>content_block_delta</c> /
  ///  <c>text_delta</c> appends its text and invokes the token callback; an
  ///  <c>error</c> event is kept and raised at the end. The full decoded body is
  ///  also kept, since a non-2xx response is a plain JSON error, not a stream.
  /// </summary>
  THelpChatSseStream = class(THelpChatSseStreamBase)
  strict private
    FStopReason: string;
    FToolCalls: TList<THelpChatToolCall>;
    FToolBlocks: TDictionary<Integer, Integer>; // content block index -> tool call
    procedure StartBlock(const AIndex: Integer; const ABlock: TObject);
    procedure AppendToolInput(const AIndex: Integer; const APartial: string);
    function GetToolCalls: TArray<THelpChatToolCall>;
  strict protected
    procedure ProcessLine(const ALine: string); override;
  public
    constructor Create(const AOnToken: THelpChatTokenProc);
    destructor Destroy; override;
    /// <summary>stop_reason of the message_delta event (end_turn, max_tokens,
    /// tool_use...).</summary>
    property StopReason: string read FStopReason;
    /// <summary>The actions the model asked for in this reply, in order.</summary>
    property ToolCalls: TArray<THelpChatToolCall> read GetToolCalls;
  end;

  THelpChatClaudeProvider = class(THelpChatProviderBase)
  strict private
    /// <summary>Runs what the model asked for and builds the user turn that
    /// carries the results back to it.</summary>
    function ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
      const ACancel: IHelpChatCancelToken): string;
    /// <summary>One request/response round; returns the stream it parsed.</summary>
    function PostRound(const ABody: string; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): THelpChatSseStream;
  public
    function GetName: string; override;
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; override;
    function SupportsStreaming: Boolean; override;
    function SupportsActions: Boolean; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;

    /// <summary>Builds the JSON body of the Messages API request. Public for tests.</summary>
    class function BuildRequestBody(const AHistory: TArray<THelpChatMessage>;
      const ASystemPrompt: string; const ASettings: THelpChatClaudeSettings): string; overload; static;
    /// <summary>The same, declaring the actions as tools and continuing a
    /// conversation that already contains tool calls and their results
    /// (<c>AExtraMessagesJson</c>: a JSON array of message objects).</summary>
    class function BuildRequestBody(const AHistory: TArray<THelpChatMessage>;
      const ASystemPrompt: string; const ASettings: THelpChatClaudeSettings;
      const AToolsJson, AExtraMessagesJson: string): string; overload; static;
    /// <summary>The assistant turn that asked for the actions, as the API wants
    /// it back: the text it produced plus one tool_use block per call.</summary>
    class function BuildAssistantToolMessage(const AText: string;
      const ACalls: TArray<THelpChatToolCall>): string; static;
    /// <summary>Extracts a readable message from a non-2xx response body.</summary>
    class function ExtractApiError(const ARaw: string; const AStatus: Integer;
      const AStatusText: string; const ASettings: THelpChatSettings): string; static;
  end;

implementation

uses
  System.JSON,
  System.IOUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  HelpChatAI.Messages;

type
  /// <summary>Method holder for THTTPClient.OnReceiveData: flips AAbort when the
  /// cancellation token is set, which makes the client stop the transfer.</summary>
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

{ THelpChatSseStream }

constructor THelpChatSseStream.Create(const AOnToken: THelpChatTokenProc);
begin
  inherited Create(AOnToken);
  FToolCalls := TList<THelpChatToolCall>.Create;
  FToolBlocks := TDictionary<Integer, Integer>.Create;
end;

destructor THelpChatSseStream.Destroy;
begin
  FToolBlocks.Free;
  FToolCalls.Free;
  inherited;
end;

function THelpChatSseStream.GetToolCalls: TArray<THelpChatToolCall>;
begin
  Result := FToolCalls.ToArray;
end;

procedure THelpChatSseStream.StartBlock(const AIndex: Integer; const ABlock: TObject);
var
  LBlock: TJSONObject;
  LCall: THelpChatToolCall;
begin
  if not (ABlock is TJSONObject) then
    Exit;
  LBlock := TJSONObject(ABlock);
  if LBlock.GetValue<string>('type', '') <> 'tool_use' then
    Exit;
  LCall.Id := LBlock.GetValue<string>('id', '');
  LCall.Name := LBlock.GetValue<string>('name', '');
  LCall.InputJson := '';
  FToolCalls.Add(LCall);
  FToolBlocks.AddOrSetValue(AIndex, FToolCalls.Count - 1);
end;

procedure THelpChatSseStream.AppendToolInput(const AIndex: Integer; const APartial: string);
var
  LPos: Integer;
  LCall: THelpChatToolCall;
begin
  // The arguments arrive as fragments of JSON text, to be concatenated.
  if not FToolBlocks.TryGetValue(AIndex, LPos) then
    Exit;
  LCall := FToolCalls[LPos];
  LCall.InputJson := LCall.InputJson + APartial;
  FToolCalls[LPos] := LCall;
end;

procedure THelpChatSseStream.ProcessLine(const ALine: string);
var
  LRoot, LDelta, LErr: TJSONObject;
  LType, LToken: string;
  LIndex: Integer;
begin
  LRoot := ParseObject(DataPayload(ALine));
  if LRoot = nil then
    Exit;
  try
    LType := LRoot.GetValue<string>('type', '');
    if LType = 'content_block_start' then
      // A block of the reply begins: text, or an action the model wants to call.
      StartBlock(LRoot.GetValue<Integer>('index', -1), LRoot.GetValue('content_block'))
    else if LType = 'content_block_delta' then
    begin
      LDelta := LRoot.GetValue('delta') as TJSONObject;
      if LDelta <> nil then
      begin
        LIndex := LRoot.GetValue<Integer>('index', -1);
        if LDelta.GetValue<string>('type', '') = 'text_delta' then
        begin
          LToken := LDelta.GetValue<string>('text', '');
          EmitToken(LToken);
        end
        else if LDelta.GetValue<string>('type', '') = 'input_json_delta' then
          AppendToolInput(LIndex, LDelta.GetValue<string>('partial_json', ''));
      end;
    end
    else if LType = 'message_delta' then
    begin
      LDelta := LRoot.GetValue('delta') as TJSONObject;
      if LDelta <> nil then
        FStopReason := LDelta.GetValue<string>('stop_reason', '');
    end
    else if LType = 'error' then
    begin
      LErr := LRoot.GetValue('error') as TJSONObject;
      if LErr <> nil then
        FError := LErr.GetValue<string>('message', '');
      if FError = '' then
        FError := HelpChatMsg(hcmProviderError);
    end;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatClaudeProvider.BuildAssistantToolMessage(const AText: string;
  const ACalls: TArray<THelpChatToolCall>): string;
var
  LMsg, LBlock: TJSONObject;
  LContent: TJSONArray;
  LInput: TJSONValue;
  I: Integer;
begin
  LMsg := TJSONObject.Create;
  try
    LMsg.AddPair('role', 'assistant');
    LContent := TJSONArray.Create;
    LMsg.AddPair('content', LContent);
    if Trim(AText) <> '' then
    begin
      LBlock := TJSONObject.Create;
      LBlock.AddPair('type', 'text');
      LBlock.AddPair('text', AText);
      LContent.AddElement(LBlock);
    end;
    for I := Low(ACalls) to High(ACalls) do
    begin
      LBlock := TJSONObject.Create;
      LBlock.AddPair('type', 'tool_use');
      LBlock.AddPair('id', ACalls[I].Id);
      LBlock.AddPair('name', ACalls[I].Name);
      // An action without parameters streams no input at all.
      LInput := nil;
      if Trim(ACalls[I].InputJson) <> '' then
        LInput := TJSONObject.ParseJSONValue(ACalls[I].InputJson);
      if not (LInput is TJSONObject) then
      begin
        LInput.Free;
        LInput := TJSONObject.Create;
      end;
      LBlock.AddPair('input', LInput);
      LContent.AddElement(LBlock);
    end;
    Result := LMsg.ToJSON;
  finally
    LMsg.Free;
  end;
end;

{ THelpChatClaudeProvider }

function THelpChatClaudeProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_CLAUDE;
end;

class function THelpChatClaudeProvider.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
begin
  Result := '';
  if not Assigned(ASettings) then
    Exit;
  if ASettings.Claude.ResolveApiKey = '' then
    Result := Format('No API key: set Settings.Claude.ApiKey, the Claude/ApiKey ' +
      'entry of helpchatai.json, or the %s environment variable.',
      [HELPCHAT_CLAUDE_APIKEY_ENVVAR]);
end;

function THelpChatClaudeProvider.SupportsStreaming: Boolean;
begin
  Result := True;
end;

function THelpChatClaudeProvider.SupportsActions: Boolean;
begin
  Result := True;
end;

function THelpChatClaudeProvider.ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
  const ACancel: IHelpChatCancelToken): string;
var
  LMsg, LBlock: TJSONObject;
  LContent: TJSONArray;
  LOutcome: THelpChatActionOutcome;
  LResult: string;
  I: Integer;
begin
  LMsg := TJSONObject.Create;
  try
    LMsg.AddPair('role', 'user');
    LContent := TJSONArray.Create;
    LMsg.AddPair('content', LContent);
    for I := Low(ACalls) to High(ACalls) do
    begin
      CheckCancelled(ACancel);
      // Invoke never raises: whatever happened is told to the model as text.
      LOutcome := Actions.Invoke(ACalls[I].Name, ACalls[I].InputJson, ACancel, LResult);
      if LOutcome = aoCancelled then
        raise EHelpChatCancelled.Create(Msg(hcmCancelled));
      LBlock := TJSONObject.Create;
      LBlock.AddPair('type', 'tool_result');
      LBlock.AddPair('tool_use_id', ACalls[I].Id);
      LBlock.AddPair('content', HelpChatActionOutcomeText(LOutcome, ACalls[I].Name, LResult));
      if LOutcome in [aoFailed, aoUnknown, aoTimeout] then
        LBlock.AddPair('is_error', TJSONBool.Create(True));
      LContent.AddElement(LBlock);
    end;
    Result := LMsg.ToJSON;
  finally
    LMsg.Free;
  end;
end;

class function THelpChatClaudeProvider.BuildRequestBody(
  const AHistory: TArray<THelpChatMessage>; const ASystemPrompt: string;
  const ASettings: THelpChatClaudeSettings): string;
begin
  Result := BuildRequestBody(AHistory, ASystemPrompt, ASettings, '', '');
end;

class function THelpChatClaudeProvider.BuildRequestBody(
  const AHistory: TArray<THelpChatMessage>; const ASystemPrompt: string;
  const ASettings: THelpChatClaudeSettings;
  const AToolsJson, AExtraMessagesJson: string): string;
var
  LRoot, LMsg: TJSONObject;
  LMessages: TJSONArray;
  LValue: TJSONValue;
  LItem: TJSONValue;
  I: Integer;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('model', ASettings.Model);
    LRoot.AddPair('max_tokens', TJSONNumber.Create(ASettings.MaxTokens));
    LRoot.AddPair('stream', TJSONBool.Create(True));
    if ASystemPrompt <> '' then
      LRoot.AddPair('system', ASystemPrompt);

    LMessages := TJSONArray.Create;
    LRoot.AddPair('messages', LMessages);
    for I := Low(AHistory) to High(AHistory) do
    begin
      // System messages live in the top-level field; empties are skipped.
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
    // The API wants a non-empty array starting with a user turn.
    if (LMessages.Count = 0) and (AExtraMessagesJson = '') then
    begin
      LMsg := TJSONObject.Create;
      LMsg.AddPair('role', 'user');
      LMsg.AddPair('content', LastUserMessage(AHistory));
      LMessages.AddElement(LMsg);
    end;

    // What this conversation already exchanged with the tools: the assistant
    // turn that asked for the actions and the user turn with their results.
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

    // The actions of the application, as tools.
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

class function THelpChatClaudeProvider.ExtractApiError(const ARaw: string;
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

function THelpChatClaudeProvider.PostRound(const ABody: string;
  const AOnToken: THelpChatTokenProc; const ACancel: IHelpChatCancelToken): THelpChatSseStream;
var
  LClient: THTTPClient;
  LSource: TStringStream;
  LWatcher: TAbortWatcher;
  LHeaders: TNetHeaders;
  LResponse: IHTTPResponse;
begin
  Result := THelpChatSseStream.Create(AOnToken);
  LClient := THTTPClient.Create;
  LSource := TStringStream.Create(ABody, TEncoding.UTF8);
  LWatcher := TAbortWatcher.Create(ACancel);
  try
    try
      LClient.ConnectionTimeout := Settings.Claude.ConnectTimeoutMs;
      LClient.ResponseTimeout := Settings.Claude.ResponseTimeoutMs;
      LClient.OnReceiveData := LWatcher.OnReceiveData;

      LHeaders := [
        TNetHeader.Create('x-api-key', Settings.Claude.ResolveApiKey),
        TNetHeader.Create('anthropic-version', Settings.Claude.ApiVersion),
        TNetHeader.Create('content-type', 'application/json'),
        TNetHeader.Create('accept', 'text/event-stream')
      ];

      try
        // The body streams into Result, which parses the SSE events and
        // forwards the tokens as they arrive.
        LResponse := LClient.Post(Settings.Claude.NormalizedBaseUrl + HELPCHAT_CLAUDE_MESSAGES_PATH,
          LSource, Result, LHeaders);
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

function THelpChatClaudeProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  LSystem, LTools: string;
  LStream: THelpChatSseStream;
  LExtra: TStringBuilder;
  LText: TStringBuilder;
  LRound, LMaxRounds: Integer;
  LCalls: TArray<THelpChatToolCall>;
begin
  if Settings.Claude.ResolveApiKey = '' then
    raise EHelpChatConfigError.Create(MsgFmt(hcmClaudeNotConfigured,
      [TPath.GetDirectoryName(THelpChatSettings.SharedUserConfigFile),
       TPath.GetDirectoryName(THelpChatSettings.UserConfigFile)]));

  CheckCancelled(ACancel);
  LSystem := BuildSystemPrompt(AHistory, AContext, Settings, Retriever);
  LTools := '';
  if Assigned(Actions) and Actions.HasActions then
  begin
    LTools := Actions.ToolsJson;
    LSystem := LSystem + sLineBreak + sLineBreak + HELPCHAT_CLAUDE_ACTIONS_RULE;
  end;
  CheckCancelled(ACancel);

  LMaxRounds := Settings.Claude.MaxToolRounds;
  if LMaxRounds < 1 then
    LMaxRounds := 1;
  LText := TStringBuilder.Create;
  LExtra := TStringBuilder.Create; // the tool turns, as a JSON array body
  try
    for LRound := 1 to LMaxRounds do
    begin
      LStream := PostRound(BuildRequestBody(AHistory, LSystem, Settings.Claude,
        LTools, '[' + LExtra.ToString + ']'), AOnToken, ACancel);
      try
        LText.Append(LStream.Text);
        LCalls := LStream.ToolCalls;
        // Nothing to do, or nobody to do it: this is the reply.
        if (LStream.StopReason <> 'tool_use') or (Length(LCalls) = 0) or
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
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_CLAUDE, THelpChatClaudeProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_CLAUDE);

end.
