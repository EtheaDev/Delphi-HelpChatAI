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
///  The <c>gemini</c> provider: Google's <c>streamGenerateContent</c>, with
///  the actions of the application offered as function declarations.
///
///  It is the one of the three that agrees with the others on nothing. The
///  conversation is <c>contents</c>, a turn is a <c>role</c> plus a list of
///  <c>parts</c>, the assistant is called <c>model</c>, the instruction is
///  <c>systemInstruction</c> and the limits live under <c>generationConfig</c>.
///  The key travels in <c>x-goog-api-key</c>, never in the query string, where
///  it would end up in somebody's log.
///
///  <c>?alt=sse</c> is not optional: without it the endpoint answers with one
///  big JSON array when it is done, which is the opposite of streaming.
///
///  A function call arrives whole, as a <c>functionCall</c> part, not in
///  fragments like the other two: there is nothing to reassemble, and the
///  round ends as soon as a part carries one.
/// </summary>
unit HelpChatAI.Provider.Gemini;

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
  HELPCHAT_PROVIDER_GEMINI = 'gemini';
  /// <summary>Path of the streaming endpoint; %s is the model.</summary>
  HELPCHAT_GEMINI_STREAM_PATH = '/v1beta/models/%s:streamGenerateContent?alt=sse';
  /// <summary>Header carrying the key.</summary>
  HELPCHAT_GEMINI_KEY_HEADER = 'x-goog-api-key';

type
  /// <summary>Parses the stream of <c>GenerateContentResponse</c> chunks: the
  /// text parts and the function calls, which arrive whole.</summary>
  THelpChatGeminiStream = class(THelpChatSseStreamBase)
  strict private
    FFinishReason: string;
    FTextSignature: string;
    FToolCalls: TList<THelpChatToolCall>;
    procedure ReadPart(const APart: TJSONObject);
    function GetToolCalls: TArray<THelpChatToolCall>;
  strict protected
    procedure ProcessLine(const ALine: string); override;
  public
    constructor Create(const AOnToken: THelpChatTokenProc);
    destructor Destroy; override;
    /// <summary>finishReason of the candidate: STOP, MAX_TOKENS, SAFETY...</summary>
    property FinishReason: string read FFinishReason;
    /// <summary>The actions the model asked for in this reply, in order.</summary>
    property ToolCalls: TArray<THelpChatToolCall> read GetToolCalls;
    /// <summary>The signature that came with the text, when the reply carried
    /// one outside a function call. Returning it is not validated, only
    /// recommended: the model reasons better with its own notes back.</summary>
    property TextSignature: string read FTextSignature;
  end;

  THelpChatGeminiProvider = class(THelpChatProviderBase)
  strict private
    /// <summary>Runs what the model asked for and builds the user turn whose
    /// parts are the <c>functionResponse</c> of each call.</summary>
    function ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
      const ACancel: IHelpChatCancelToken): string;
    /// <summary>One request/response round; returns the stream it parsed.</summary>
    function PostRound(const ABody: string; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): THelpChatGeminiStream;
  public
    /// <summary>Full URL of the streaming endpoint for the configured model.
    /// Public for tests.</summary>
    class function StreamUrl(const ASettings: THelpChatGeminiSettings): string; static;
    function GetName: string; override;
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; override;
    function SupportsStreaming: Boolean; override;
    function SupportsActions: Boolean; override;
    function SupportsDocuments: Boolean; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;

    /// <summary>The actions of the application as the <c>tools</c> array of
    /// this API: one Tool holding every <c>functionDeclaration</c>, each with
    /// the JSON Schema the broker produced under <c>input_schema</c> renamed
    /// to <c>parameters</c>. Public for tests.</summary>
    class function BuildToolsJson(const ABrokerToolsJson: string): string; static;
    /// <summary>Builds the JSON body of the request. <c>AExtraContentsJson</c>
    /// is a JSON array of the turns this reply already exchanged with the
    /// tools. Public for tests; no network involved.</summary>
    class function BuildRequestBody(const AHistory: TArray<THelpChatMessage>;
      const ASystemPrompt: string; const ASettings: THelpChatGeminiSettings;
      const AToolsJson, AExtraContentsJson: string;
      const AAttachments: TArray<THelpChatAttachment> = nil;
      const ALanguage: THelpChatLanguage = hclAuto): string; static;
    /// <summary>The model turn that asked for the actions, as the API wants it
    /// back: its text and one functionCall part per call, each carrying again
    /// the <c>thoughtSignature</c> it arrived with. Dropping those is a 400
    /// from any thinking model.</summary>
    class function BuildModelToolMessage(const AText: string;
      const ACalls: TArray<THelpChatToolCall>;
      const ATextSignature: string = ''): string; static;
    /// <summary>Extracts a readable message from a non-2xx response body.</summary>
    class function ExtractApiError(const ARaw: string; const AStatus: Integer;
      const AStatusText: string; const ASettings: THelpChatSettings): string; static;
  end;

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

{ THelpChatGeminiStream }

constructor THelpChatGeminiStream.Create(const AOnToken: THelpChatTokenProc);
begin
  inherited Create(AOnToken);
  FToolCalls := TList<THelpChatToolCall>.Create;
end;

destructor THelpChatGeminiStream.Destroy;
begin
  FToolCalls.Free;
  inherited;
end;

function THelpChatGeminiStream.GetToolCalls: TArray<THelpChatToolCall>;
begin
  Result := FToolCalls.ToArray;
end;

procedure THelpChatGeminiStream.ReadPart(const APart: TJSONObject);
var
  LCall: THelpChatToolCall;
  LFunctionCall: TJSONObject;
  LArgs: TJSONValue;
  LSignature: string;
begin
  // The signature belongs to the part, not to the call inside it, and it is
  // read before anything else is decided about the part: a thinking model
  // puts one on the first function call of every round and refuses the next
  // request when it does not come back.
  LSignature := APart.GetValue<string>('thoughtSignature', '');

  LFunctionCall := APart.GetValue('functionCall') as TJSONObject;
  if LFunctionCall <> nil then
  begin
    LCall.Id := LFunctionCall.GetValue<string>('id', '');
    LCall.Name := LFunctionCall.GetValue<string>('name', '');
    LArgs := LFunctionCall.GetValue('args');
    if LArgs <> nil then
      LCall.InputJson := LArgs.ToJSON
    else
      LCall.InputJson := '{}';
    LCall.Signature := LSignature;
    FToolCalls.Add(LCall);
    Exit;
  end;

  if (LSignature <> '') and (FTextSignature = '') then
    FTextSignature := LSignature;
  // A "thought" part is the model reasoning out loud: never shown as an
  // answer, but its signature has already been taken.
  if APart.GetValue<Boolean>('thought', False) then
    Exit;

  EmitToken(APart.GetValue<string>('text', ''));
end;

procedure THelpChatGeminiStream.ProcessLine(const ALine: string);
var
  LRoot, LCandidate, LContent, LErr: TJSONObject;
  LCandidates, LParts: TJSONArray;
  LItem: TJSONValue;
  LFinish: string;
begin
  LRoot := ParseObject(DataPayload(ALine));
  if LRoot = nil then
    Exit;
  try
    LErr := LRoot.GetValue('error') as TJSONObject;
    if LErr <> nil then
    begin
      FError := LErr.GetValue<string>('message', '');
      if FError = '' then
        FError := HelpChatMsg(hcmProviderError);
      Exit;
    end;

    LCandidates := LRoot.GetValue('candidates') as TJSONArray;
    if (LCandidates = nil) or (LCandidates.Count = 0) then
      Exit;
    LCandidate := LCandidates.Items[0] as TJSONObject;
    if LCandidate = nil then
      Exit;

    LFinish := LCandidate.GetValue<string>('finishReason', '');
    if LFinish <> '' then
      FFinishReason := LFinish;

    LContent := LCandidate.GetValue('content') as TJSONObject;
    if LContent = nil then
      Exit;
    LParts := LContent.GetValue('parts') as TJSONArray;
    if LParts = nil then
      Exit;
    for LItem in LParts do
      if LItem is TJSONObject then
        ReadPart(TJSONObject(LItem));
  finally
    LRoot.Free;
  end;
end;

{ THelpChatGeminiProvider }

function THelpChatGeminiProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_GEMINI;
end;

class function THelpChatGeminiProvider.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
begin
  Result := '';
  if not Assigned(ASettings) then
    Exit;
  if ASettings.Gemini.ResolveApiKey = '' then
    Result := Format('No API key: set Settings.Gemini.ApiKey, the Gemini/ApiKey ' +
      'entry of helpchatai.json, or the %s (or %s) environment variable.',
      [HELPCHAT_GEMINI_APIKEY_ENVVAR, HELPCHAT_GEMINI_APIKEY_ENVVAR_ALT]);
end;

function THelpChatGeminiProvider.SupportsStreaming: Boolean;
begin
  Result := True;
end;

function THelpChatGeminiProvider.SupportsDocuments: Boolean;
begin
  Result := True;
end;

function THelpChatGeminiProvider.SupportsActions: Boolean;
begin
  Result := True;
end;

class function THelpChatGeminiProvider.StreamUrl(
  const ASettings: THelpChatGeminiSettings): string;
begin
  Result := ASettings.NormalizedBaseUrl +
    Format(HELPCHAT_GEMINI_STREAM_PATH, [ASettings.ResolveModel]);
end;

class function THelpChatGeminiProvider.BuildToolsJson(const ABrokerToolsJson: string): string;
var
  LSource, LTarget, LDeclarations: TJSONArray;
  LItem: TJSONValue;
  LAction, LDeclaration, LTool: TJSONObject;
  LSchema: TJSONValue;
begin
  Result := '';
  if Trim(ABrokerToolsJson) = '' then
    Exit;
  LSource := TJSONObject.ParseJSONValue(ABrokerToolsJson) as TJSONArray;
  if LSource = nil then
    Exit;
  try
    LDeclarations := TJSONArray.Create;
    for LItem in LSource do
    begin
      if not (LItem is TJSONObject) then
        Continue;
      LAction := TJSONObject(LItem);
      LDeclaration := TJSONObject.Create;
      LDeclaration.AddPair('name', LAction.GetValue<string>('name', ''));
      LDeclaration.AddPair('description', LAction.GetValue<string>('description', ''));
      LSchema := LAction.GetValue('input_schema');
      if LSchema <> nil then
        LDeclaration.AddPair('parameters', LSchema.Clone as TJSONValue);
      LDeclarations.AddElement(LDeclaration);
    end;
    if LDeclarations.Count = 0 then
    begin
      LDeclarations.Free;
      Exit;
    end;
    // Every declaration goes into one Tool, which is how this API groups them.
    LTool := TJSONObject.Create;
    LTarget := TJSONArray.Create;
    try
      LTool.AddPair('functionDeclarations', LDeclarations);
      LTarget.AddElement(LTool);
      Result := LTarget.ToJSON;
    finally
      LTarget.Free; // owns LTool, which owns LDeclarations
    end;
  finally
    LSource.Free;
  end;
end;

class function THelpChatGeminiProvider.BuildRequestBody(
  const AHistory: TArray<THelpChatMessage>; const ASystemPrompt: string;
  const ASettings: THelpChatGeminiSettings;
  const AToolsJson, AExtraContentsJson: string;
  const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage): string;
var
  LRoot, LContent, LPart, LConfig, LSystem, LToolConfig, LCallingConfig: TJSONObject;
  LContents, LParts, LTools: TJSONArray;
  LValue, LItem: TJSONValue;
  I, LLastUser: Integer;

  function NewTextContent(const ARole, AText: string): TJSONObject;
  var
    LTextPart: TJSONObject;
    LTextParts: TJSONArray;
  begin
    Result := TJSONObject.Create;
    Result.AddPair('role', ARole);
    LTextParts := TJSONArray.Create;
    Result.AddPair('parts', LTextParts);
    LTextPart := TJSONObject.Create;
    LTextPart.AddPair('text', AText);
    LTextParts.AddElement(LTextPart);
  end;

  // The same turn with the documents in front of the text: here a part is an
  // inlineData, and a PDF and an image are told apart by the MIME type alone.
  function NewUserContentWithFiles: TJSONObject;
  var
    LFilePart, LInline: TJSONObject;
    LFileParts: TJSONArray;
    J: Integer;
  begin
    Result := TJSONObject.Create;
    Result.AddPair('role', 'user');
    LFileParts := TJSONArray.Create;
    Result.AddPair('parts', LFileParts);
    for J := Low(AAttachments) to High(AAttachments) do
    begin
      if (AAttachments[J].Kind = hcakText) or (Length(AAttachments[J].Data) = 0) then
        Continue;
      LInline := TJSONObject.Create;
      LInline.AddPair('mimeType', AAttachments[J].MediaType);
      LInline.AddPair('data', AAttachments[J].Base64);
      LFilePart := TJSONObject.Create;
      LFilePart.AddPair('inlineData', LInline);
      LFileParts.AddElement(LFilePart);
    end;
    LFilePart := TJSONObject.Create;
    LFilePart.AddPair('text', HelpChatQuestionWithText(
      AHistory[LLastUser].Content, AAttachments, ALanguage));
    LFileParts.AddElement(LFilePart);
  end;

begin
  LRoot := TJSONObject.Create;
  try
    // The instruction is a Content of its own, outside the conversation.
    if ASystemPrompt <> '' then
    begin
      LSystem := TJSONObject.Create;
      LRoot.AddPair('systemInstruction', LSystem);
      LParts := TJSONArray.Create;
      LSystem.AddPair('parts', LParts);
      LPart := TJSONObject.Create;
      LPart.AddPair('text', ASystemPrompt);
      LParts.AddElement(LPart);
    end;

    // The attachments belong to the question being asked: the last user turn.
    LLastUser := -1;
    if Length(AAttachments) > 0 then
      for I := High(AHistory) downto Low(AHistory) do
        if (AHistory[I].Role = hcrUser) and (Trim(AHistory[I].Content) <> '') then
        begin
          LLastUser := I;
          Break;
        end;

    LContents := TJSONArray.Create;
    LRoot.AddPair('contents', LContents);
    for I := Low(AHistory) to High(AHistory) do
    begin
      if (AHistory[I].Role = hcrSystem) or (Trim(AHistory[I].Content) = '') then
        Continue;
      // The assistant is called "model" here.
      if I = LLastUser then
        LContent := NewUserContentWithFiles
      else if AHistory[I].Role = hcrUser then
        LContent := NewTextContent('user', AHistory[I].Content)
      else
        LContent := NewTextContent('model', AHistory[I].Content);
      LContents.AddElement(LContent);
    end;
    if (LContents.Count = 0) and (Trim(AExtraContentsJson) = '[]') then
      LContents.AddElement(NewTextContent('user', LastUserMessage(AHistory)));

    if Trim(AExtraContentsJson) <> '' then
    begin
      LValue := TJSONObject.ParseJSONValue(AExtraContentsJson);
      try
        if LValue is TJSONArray then
          for LItem in TJSONArray(LValue) do
            LContents.AddElement(LItem.Clone as TJSONValue);
      finally
        LValue.Free;
      end;
    end;

    LConfig := TJSONObject.Create;
    LRoot.AddPair('generationConfig', LConfig);
    LConfig.AddPair('maxOutputTokens', TJSONNumber.Create(ASettings.MaxTokens));

    if Trim(AToolsJson) <> '' then
    begin
      LValue := TJSONObject.ParseJSONValue(AToolsJson);
      if (LValue is TJSONArray) and (TJSONArray(LValue).Count > 0) then
      begin
        LTools := TJSONArray(LValue);
        LRoot.AddPair('tools', LTools);
        LToolConfig := TJSONObject.Create;
        LRoot.AddPair('toolConfig', LToolConfig);
        LCallingConfig := TJSONObject.Create;
        LToolConfig.AddPair('functionCallingConfig', LCallingConfig);
        LCallingConfig.AddPair('mode', 'AUTO');
      end
      else
        LValue.Free;
    end;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatGeminiProvider.BuildModelToolMessage(const AText: string;
  const ACalls: TArray<THelpChatToolCall>; const ATextSignature: string): string;
var
  LContent, LPart, LCall: TJSONObject;
  LParts: TJSONArray;
  LArgs: TJSONValue;
  I: Integer;
begin
  LContent := TJSONObject.Create;
  try
    LContent.AddPair('role', 'model');
    LParts := TJSONArray.Create;
    LContent.AddPair('parts', LParts);
    if Trim(AText) <> '' then
    begin
      LPart := TJSONObject.Create;
      LPart.AddPair('text', AText);
      if ATextSignature <> '' then
        LPart.AddPair('thoughtSignature', ATextSignature);
      LParts.AddElement(LPart);
    end;
    for I := Low(ACalls) to High(ACalls) do
    begin
      LCall := TJSONObject.Create;
      if ACalls[I].Id <> '' then
        LCall.AddPair('id', ACalls[I].Id);
      LCall.AddPair('name', ACalls[I].Name);
      LArgs := nil;
      if Trim(ACalls[I].InputJson) <> '' then
        LArgs := TJSONObject.ParseJSONValue(ACalls[I].InputJson);
      if not (LArgs is TJSONObject) then
      begin
        LArgs.Free;
        LArgs := TJSONObject.Create;
      end;
      LCall.AddPair('args', LArgs);
      LPart := TJSONObject.Create;
      LPart.AddPair('functionCall', LCall);
      // Back exactly where it came from, on the part and not in the call.
      // With parallel calls only the first one carries it.
      if ACalls[I].Signature <> '' then
        LPart.AddPair('thoughtSignature', ACalls[I].Signature);
      LParts.AddElement(LPart);
    end;
    Result := LContent.ToJSON;
  finally
    LContent.Free;
  end;
end;

function THelpChatGeminiProvider.ExecuteToolCalls(const ACalls: TArray<THelpChatToolCall>;
  const ACancel: IHelpChatCancelToken): string;
var
  LContent, LPart, LResponse, LPayload: TJSONObject;
  LParts: TJSONArray;
  LOutcome: THelpChatActionOutcome;
  LResult: string;
  I: Integer;
begin
  // Every result travels in one user turn, one functionResponse part each.
  LContent := TJSONObject.Create;
  try
    LContent.AddPair('role', 'user');
    LParts := TJSONArray.Create;
    LContent.AddPair('parts', LParts);
    for I := Low(ACalls) to High(ACalls) do
    begin
      CheckCancelled(ACancel);
      // Invoke never raises: whatever happened is told to the model as text.
      LOutcome := Actions.Invoke(ACalls[I].Name, ACalls[I].InputJson, ACancel, LResult);
      if LOutcome = aoCancelled then
        raise EHelpChatCancelled.Create(Msg(hcmCancelled));
      LPayload := TJSONObject.Create;
      // The response has to be an object, so the sentence goes in a field.
      LPayload.AddPair('result', HelpChatActionOutcomeText(LOutcome, ACalls[I].Name, LResult));
      LResponse := TJSONObject.Create;
      if ACalls[I].Id <> '' then
        LResponse.AddPair('id', ACalls[I].Id);
      LResponse.AddPair('name', ACalls[I].Name);
      LResponse.AddPair('response', LPayload);
      LPart := TJSONObject.Create;
      LPart.AddPair('functionResponse', LResponse);
      LParts.AddElement(LPart);
    end;
    Result := LContent.ToJSON;
  finally
    LContent.Free;
  end;
end;

class function THelpChatGeminiProvider.ExtractApiError(const ARaw: string;
  const AStatus: Integer; const AStatusText: string; const ASettings: THelpChatSettings): string;
var
  LRoot, LHolder: TJSONValue;
  LErr: TJSONObject;
  LLang: THelpChatLanguage;
begin
  Result := '';
  if Trim(ARaw) <> '' then
  begin
    try
      LRoot := TJSONObject.ParseJSONValue(Trim(ARaw));
    except
      LRoot := nil;
    end;
    if LRoot <> nil then
      try
        // A failing request answers with an object; a failing stream with an
        // array holding one. The item belongs to the array, so only the root
        // is ever freed.
        LHolder := LRoot;
        if (LHolder is TJSONArray) and (TJSONArray(LHolder).Count > 0) then
          LHolder := TJSONArray(LHolder).Items[0];
        if LHolder is TJSONObject then
        begin
          LErr := TJSONObject(LHolder).GetValue('error') as TJSONObject;
          if LErr <> nil then
            Result := LErr.GetValue<string>('message', '');
        end;
      finally
        LRoot.Free;
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

function THelpChatGeminiProvider.PostRound(const ABody: string;
  const AOnToken: THelpChatTokenProc; const ACancel: IHelpChatCancelToken): THelpChatGeminiStream;
var
  LClient: THTTPClient;
  LSource: TStringStream;
  LWatcher: TAbortWatcher;
  LHeaders: TNetHeaders;
  LResponse: IHTTPResponse;
begin
  Result := THelpChatGeminiStream.Create(AOnToken);
  LClient := THTTPClient.Create;
  LSource := TStringStream.Create(ABody, TEncoding.UTF8);
  LWatcher := TAbortWatcher.Create(ACancel);
  try
    try
      LClient.ConnectionTimeout := Settings.Gemini.ConnectTimeoutMs;
      LClient.ResponseTimeout := Settings.Gemini.ResponseTimeoutMs;
      LClient.OnReceiveData := LWatcher.OnReceiveData;

      LHeaders := [
        TNetHeader.Create(HELPCHAT_GEMINI_KEY_HEADER, Settings.Gemini.ResolveApiKey),
        TNetHeader.Create('content-type', 'application/json'),
        TNetHeader.Create('accept', 'text/event-stream')
      ];

      try
        LResponse := LClient.Post(StreamUrl(Settings.Gemini), LSource, Result, LHeaders);
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

function THelpChatGeminiProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  LSystem, LTools: string;
  LStream: THelpChatGeminiStream;
  LExtra: TStringBuilder;
  LText: TStringBuilder;
  LRound, LMaxRounds: Integer;
  LCalls: TArray<THelpChatToolCall>;
begin
  if Settings.Gemini.ResolveApiKey = '' then
    raise EHelpChatConfigError.Create(MsgFmt(hcmProviderKeyMissing,
      [HELPCHAT_PROVIDER_GEMINI, THelpChatGeminiSettings.SectionName,
       THelpChatGeminiSettings.ApiKeyEnvVar,
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

  LMaxRounds := Settings.Gemini.ResolveMaxToolRounds;
  LText := TStringBuilder.Create;
  LExtra := TStringBuilder.Create; // the tool turns, as a JSON array body
  try
    for LRound := 1 to LMaxRounds do
    begin
      LStream := PostRound(BuildRequestBody(AHistory, LSystem, Settings.Gemini,
        LTools, '[' + LExtra.ToString + ']', Attachments, Settings.Language),
        AOnToken, ACancel);
      try
        LText.Append(LStream.Text);
        LCalls := LStream.ToolCalls;
        // A function call part is the whole signal here: this API does not
        // flag the turn the way the other two do.
        if (Length(LCalls) = 0) or (LTools = '') or (LRound = LMaxRounds) then
          Break;
        if LExtra.Length > 0 then
          LExtra.Append(',');
        LExtra.Append(BuildModelToolMessage(LStream.Text, LCalls,
          LStream.TextSignature));
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
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_GEMINI, THelpChatGeminiProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_GEMINI);

end.
