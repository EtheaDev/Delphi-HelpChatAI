unit HelpChatAI.Tests.Gemini;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider.Gemini;

type
  /// <summary>Everything here runs without network: the SSE parser is fed by
  /// hand and the request builders are pure functions.</summary>
  [TestFixture]
  TGeminiTests = class
  strict private
    FTokens: TList<string>;
    FStream: THelpChatGeminiStream;
    FSettings: THelpChatSettings;
    procedure Feed(const AText: string);
    class function Msg(const ARole: THelpChatRole; const AContent: string): THelpChatMessage; static;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Sse_ParsesTextParts_AndFinishReason;
    [Test] procedure Sse_HandlesChunkBoundaryInsideALine;
    [Test] procedure Sse_ErrorPayload_IsKept;
    [Test] procedure Sse_ThoughtParts_AreNotAnAnswer;
    [Test] procedure Sse_ReadsWholeFunctionCalls;
    [Test] procedure Sse_KeepsTheThoughtSignature;
    [Test] procedure ModelToolMessage_GivesTheSignatureBack;
    [Test] procedure Tools_BecomeOneToolWithEveryDeclaration;
    [Test] procedure RequestBody_Shape;
    [Test] procedure RequestBody_CarriesToolsAndTheToolTurns;
    [Test] procedure ModelToolMessage_HasTextAndFunctionCalls;
    [Test] procedure ExtractApiError_FromObject_FromArray_AndFallback;
    [Test] procedure ConfigurationIssue_WhenThereIsNoKey;
    [Test] procedure StreamUrl_NamesTheModel_AndAsksForSse;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  HelpChatAI.Provider;

const
  CHUNK_HEL = 'data: {"candidates":[{"content":{"role":"model","parts":[{"text":"Cia"}]}}]}'#10#10;
  CHUNK_LO = 'data: {"candidates":[{"content":{"role":"model","parts":[{"text":"o, città"}]}}]}'#10#10;
  CHUNK_STOP = 'data: {"candidates":[{"content":{"role":"model","parts":[]},"finishReason":"STOP"}],' +
    '"usageMetadata":{"totalTokenCount":42}}'#10#10;

procedure TGeminiTests.Setup;
begin
  FTokens := TList<string>.Create;
  FStream := THelpChatGeminiStream.Create(
    procedure(const AToken: string)
    begin
      FTokens.Add(AToken);
    end);
  FSettings := THelpChatSettings.Create;
  FSettings.Provider := HELPCHAT_PROVIDER_GEMINI;
end;

procedure TGeminiTests.TearDown;
begin
  FSettings.Free;
  FStream.Free;
  FTokens.Free;
end;

class function TGeminiTests.Msg(const ARole: THelpChatRole;
  const AContent: string): THelpChatMessage;
begin
  Result := Default(THelpChatMessage);
  Result.Role := ARole;
  Result.Content := AContent;
end;

procedure TGeminiTests.Feed(const AText: string);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AText);
  if Length(LBytes) > 0 then
    FStream.Write(LBytes[0], Length(LBytes));
end;

procedure TGeminiTests.Sse_ParsesTextParts_AndFinishReason;
begin
  Feed(CHUNK_HEL);
  Feed(CHUNK_LO);
  Feed(CHUNK_STOP);
  FStream.Finish;
  Assert.AreEqual('Ciao, città', FStream.Text);
  Assert.AreEqual(2, FTokens.Count);
  Assert.AreEqual('STOP', FStream.FinishReason);
  Assert.AreEqual('', FStream.Error);
end;

procedure TGeminiTests.Sse_HandlesChunkBoundaryInsideALine;
var
  LBytes: TBytes;
  LCut: Integer;
begin
  LBytes := TEncoding.UTF8.GetBytes(CHUNK_LO);
  LCut := Length(LBytes) - 14;
  FStream.Write(LBytes[0], LCut);
  Assert.AreEqual('', FStream.Text, 'half a line is not an event yet');
  FStream.Write(LBytes[LCut], Length(LBytes) - LCut);
  FStream.Finish;
  Assert.AreEqual('o, città', FStream.Text);
end;

procedure TGeminiTests.Sse_ErrorPayload_IsKept;
begin
  Feed('data: {"error":{"code":400,"message":"API key not valid","status":"INVALID_ARGUMENT"}}'#10#10);
  FStream.Finish;
  Assert.AreEqual('API key not valid', FStream.Error);
end;

procedure TGeminiTests.Sse_ThoughtParts_AreNotAnAnswer;
begin
  // A thinking model streams its reasoning as parts flagged "thought": showing
  // them would put the model's notes in the chat.
  Feed('data: {"candidates":[{"content":{"role":"model","parts":[' +
    '{"text":"sto ragionando","thought":true},{"text":"Ecco"}]}}]}'#10#10);
  FStream.Finish;
  Assert.AreEqual('Ecco', FStream.Text);
end;

procedure TGeminiTests.Sse_ReadsWholeFunctionCalls;
var
  LCalls: TArray<THelpChatToolCall>;
begin
  // Unlike the other two, the call is not assembled from fragments.
  Feed('data: {"candidates":[{"content":{"role":"model","parts":[' +
    '{"functionCall":{"id":"fc_1","name":"open_screen","args":{"name":"Clienti"}}}]},' +
    '"finishReason":"STOP"}]}'#10#10);
  FStream.Finish;
  LCalls := FStream.ToolCalls;
  Assert.AreEqual(1, Length(LCalls));
  Assert.AreEqual('fc_1', LCalls[0].Id);
  Assert.AreEqual('open_screen', LCalls[0].Name);
  Assert.Contains(LCalls[0].InputJson, '"Clienti"');
end;

procedure TGeminiTests.Tools_BecomeOneToolWithEveryDeclaration;
var
  LArray: TJSONArray;
  LDeclarations: TJSONArray;
  LTool: TJSONObject;
begin
  LArray := TJSONObject.ParseJSONValue(THelpChatGeminiProvider.BuildToolsJson(
    '[{"name":"open_screen","description":"Opens a screen",' +
    '"input_schema":{"type":"object","properties":{"name":{"type":"string"}}}},' +
    '{"name":"close_all","description":"Closes","input_schema":{"type":"object","properties":{}}}]'))
    as TJSONArray;
  try
    // One Tool, every function inside it: that is how this API groups them.
    Assert.AreEqual(1, LArray.Count);
    LTool := LArray.Items[0] as TJSONObject;
    LDeclarations := LTool.GetValue('functionDeclarations') as TJSONArray;
    Assert.AreEqual(2, LDeclarations.Count);
    Assert.AreEqual('open_screen', (LDeclarations.Items[0] as TJSONObject).GetValue<string>('name'));
    Assert.AreEqual('string', (LDeclarations.Items[0] as TJSONObject)
      .GetValue<string>('parameters.properties.name.type'));
  finally
    LArray.Free;
  end;
  Assert.AreEqual('', THelpChatGeminiProvider.BuildToolsJson('[]'));
end;

procedure TGeminiTests.RequestBody_Shape;
var
  LHistory: TArray<THelpChatMessage>;
  LRoot: TJSONObject;
  LContents: TJSONArray;
begin
  LHistory := [Msg(hcrUser, 'come esporto?'), Msg(hcrAssistant, 'con il bottone')];
  LRoot := TJSONObject.ParseJSONValue(THelpChatGeminiProvider.BuildRequestBody(
    LHistory, 'sei un assistente', FSettings.Gemini, '', '')) as TJSONObject;
  try
    // The instruction is a Content of its own, not a turn of the conversation.
    Assert.AreEqual('sei un assistente',
      LRoot.GetValue<string>('systemInstruction.parts[0].text'));
    LContents := LRoot.GetValue('contents') as TJSONArray;
    Assert.AreEqual(2, LContents.Count);
    Assert.AreEqual('user', (LContents.Items[0] as TJSONObject).GetValue<string>('role'));
    // The assistant is called "model" here.
    Assert.AreEqual('model', (LContents.Items[1] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('come esporto?',
      LRoot.GetValue<string>('contents[0].parts[0].text'));
    Assert.IsNotNull(LRoot.FindValue('generationConfig.maxOutputTokens'));
    Assert.IsNull(LRoot.GetValue('tools'), 'no actions, no tools');
  finally
    LRoot.Free;
  end;
end;

procedure TGeminiTests.RequestBody_CarriesToolsAndTheToolTurns;
var
  LHistory: TArray<THelpChatMessage>;
  LRoot: TJSONObject;
  LContents: TJSONArray;
  LTurns: string;
begin
  LHistory := [Msg(hcrUser, 'apri i clienti')];
  LTurns := '[' + THelpChatGeminiProvider.BuildModelToolMessage('',
    [THelpChatToolCall.Create('fc_1', 'open_screen', '{"name":"Clienti"}')]) +
    ',{"role":"user","parts":[{"functionResponse":{"name":"open_screen","response":{"result":"fatto"}}}]}]';
  LRoot := TJSONObject.ParseJSONValue(THelpChatGeminiProvider.BuildRequestBody(
    LHistory, 'istruzione', FSettings.Gemini,
    THelpChatGeminiProvider.BuildToolsJson(
      '[{"name":"open_screen","description":"d","input_schema":{"type":"object","properties":{}}}]'),
    LTurns)) as TJSONObject;
  try
    Assert.IsNotNull(LRoot.GetValue('tools'));
    Assert.AreEqual('AUTO', LRoot.GetValue<string>('toolConfig.functionCallingConfig.mode'));
    LContents := LRoot.GetValue('contents') as TJSONArray;
    // the question, the model turn that asked, the result.
    Assert.AreEqual(3, LContents.Count);
    Assert.AreEqual('model', (LContents.Items[1] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('user', (LContents.Items[2] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('open_screen',
      LRoot.GetValue<string>('contents[2].parts[0].functionResponse.name'));
  finally
    LRoot.Free;
  end;
end;

procedure TGeminiTests.ModelToolMessage_HasTextAndFunctionCalls;
var
  LContent: TJSONObject;
  LParts: TJSONArray;
begin
  LContent := TJSONObject.ParseJSONValue(THelpChatGeminiProvider.BuildModelToolMessage(
    'apro subito', [THelpChatToolCall.Create('fc_9', 'open_screen', '')])) as TJSONObject;
  try
    Assert.AreEqual('model', LContent.GetValue<string>('role'));
    LParts := LContent.GetValue('parts') as TJSONArray;
    Assert.AreEqual(2, LParts.Count, 'the text and the call');
    Assert.AreEqual('apro subito', (LParts.Items[0] as TJSONObject).GetValue<string>('text'));
    Assert.AreEqual('open_screen',
      LContent.GetValue<string>('parts[1].functionCall.name'));
    // An action without parameters still needs an args object.
    Assert.IsNotNull(LContent.FindValue('parts[1].functionCall.args'));
  finally
    LContent.Free;
  end;
end;

procedure TGeminiTests.ExtractApiError_FromObject_FromArray_AndFallback;
begin
  Assert.AreEqual('API key not valid', THelpChatGeminiProvider.ExtractApiError(
    '{"error":{"code":400,"message":"API key not valid"}}', 400, 'Bad Request', FSettings));
  // A failing stream answers with an array holding the same object.
  Assert.AreEqual('quota exceeded', THelpChatGeminiProvider.ExtractApiError(
    '[{"error":{"code":429,"message":"quota exceeded"}}]', 429, 'Too Many Requests', FSettings));
  Assert.Contains(THelpChatGeminiProvider.ExtractApiError('<html>502</html>', 502,
    'Bad Gateway', FSettings), '502');
end;

procedure TGeminiTests.ConfigurationIssue_WhenThereIsNoKey;
begin
  FSettings.Gemini.ApiKey := '';
  if (GetEnvironmentVariable(HELPCHAT_GEMINI_APIKEY_ENVVAR) = '') and
     (GetEnvironmentVariable(HELPCHAT_GEMINI_APIKEY_ENVVAR_ALT) = '') then
    Assert.Contains(THelpChatGeminiProvider.ConfigurationIssue(FSettings),
      HELPCHAT_GEMINI_APIKEY_ENVVAR);
  FSettings.Gemini.ApiKey := 'not-a-real-key';
  Assert.AreEqual('', THelpChatGeminiProvider.ConfigurationIssue(FSettings));
end;

procedure TGeminiTests.StreamUrl_NamesTheModel_AndAsksForSse;
var
  LUrl: string;
begin
  LUrl := THelpChatGeminiProvider.StreamUrl(FSettings.Gemini);
  Assert.StartsWith(HELPCHAT_GEMINI_DEF_BASEURL, LUrl);
  Assert.Contains(LUrl, HELPCHAT_GEMINI_DEF_MODEL, 'the model is in the path');
  // Without alt=sse the endpoint answers with one array at the end: no stream.
  Assert.EndsWith('alt=sse', LUrl);
  FSettings.Gemini.Model := 'gemini-x';
  Assert.Contains(THelpChatGeminiProvider.StreamUrl(FSettings.Gemini),
    'models/gemini-x:streamGenerateContent');
end;

procedure TGeminiTests.Sse_KeepsTheThoughtSignature;
var
  LCalls: TArray<THelpChatToolCall>;
begin
  // A thinking model signs the part that carries the call, and refuses the
  // next request if the signature does not come back. It belongs to the part,
  // not to the functionCall inside it.
  Feed('data: {"candidates":[{"content":{"role":"model","parts":[' +
    '{"text":"ragiono","thought":true,"thoughtSignature":"SIG-THOUGHT"},' +
    '{"functionCall":{"name":"open_screen","args":{}},"thoughtSignature":"SIG-A"},' +
    '{"functionCall":{"name":"close_all","args":{}}}]}}]}'#10#10);
  FStream.Finish;
  LCalls := FStream.ToolCalls;
  Assert.AreEqual(2, Length(LCalls));
  Assert.AreEqual('SIG-A', LCalls[0].Signature);
  // With parallel calls only the first one is signed.
  Assert.AreEqual('', LCalls[1].Signature);
  // The thought itself is not an answer, but its signature is not thrown away.
  Assert.AreEqual('', FStream.Text);
  Assert.AreEqual('SIG-THOUGHT', FStream.TextSignature);
end;

procedure TGeminiTests.ModelToolMessage_GivesTheSignatureBack;
var
  LContent: TJSONObject;
  LParts: TJSONArray;
begin
  LContent := TJSONObject.ParseJSONValue(THelpChatGeminiProvider.BuildModelToolMessage(
    'apro', [THelpChatToolCall.Create('', 'open_screen', '{}', 'SIG-A'),
             THelpChatToolCall.Create('', 'close_all', '{}')], 'SIG-TEXT')) as TJSONObject;
  try
    LParts := LContent.GetValue('parts') as TJSONArray;
    Assert.AreEqual(3, LParts.Count, 'the text and the two calls');
    Assert.AreEqual('SIG-TEXT', LContent.GetValue<string>('parts[0].thoughtSignature'));
    // On the part, next to functionCall - not inside it.
    Assert.AreEqual('SIG-A', LContent.GetValue<string>('parts[1].thoughtSignature'));
    Assert.IsNotNull(LContent.FindValue('parts[1].functionCall'));
    // The unsigned one must not grow a signature out of nowhere.
    Assert.IsNull(LContent.FindValue('parts[2].thoughtSignature'));
  finally
    LContent.Free;
  end;
end;

end.
