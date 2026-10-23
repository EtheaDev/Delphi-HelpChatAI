unit HelpChatAI.Tests.OpenAI;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider.OpenAI;

type
  /// <summary>Everything here runs without network: the SSE parser is fed by
  /// hand and the request builders are pure functions.</summary>
  [TestFixture]
  TOpenAITests = class
  strict private
    FTokens: TList<string>;
    FStream: THelpChatOpenAIStream;
    FSettings: THelpChatSettings;
    procedure Feed(const AText: string);
    class function Msg(const ARole: THelpChatRole; const AContent: string): THelpChatMessage; static;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Sse_ParsesContentDeltas_AndFinishReason;
    [Test] procedure Sse_HandlesChunkBoundaryInsideALine;
    [Test] procedure Sse_ErrorPayload_IsKept;
    [Test] procedure Sse_AssemblesToolCallsByIndex;
    [Test] procedure Tools_AreWrappedAsFunctions;
    [Test] procedure RequestBody_Shape;
    [Test] procedure RequestBody_CarriesToolsAndTheToolTurns;
    [Test] procedure AssistantToolMessage_HasToolCalls;
    [Test] procedure ExtractApiError_FromJson_AndFallback;
    [Test] procedure ConfigurationIssue_OnlyWhenCallingOpenAIItself;
    [Test] procedure CompletionsUrl_Default_Local_AndAzure;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  HelpChatAI.Provider;

const
  CHUNK_HEL = 'data: {"choices":[{"index":0,"delta":{"content":"Hel"}}]}'#10#10;
  CHUNK_LO = 'data: {"choices":[{"index":0,"delta":{"content":"lo, città"}}]}'#10#10;
  CHUNK_STOP = 'data: {"choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}'#10'data: [DONE]'#10#10;

procedure TOpenAITests.Setup;
begin
  FTokens := TList<string>.Create;
  FStream := THelpChatOpenAIStream.Create(
    procedure(const AToken: string)
    begin
      FTokens.Add(AToken);
    end);
  FSettings := THelpChatSettings.Create;
  FSettings.Provider := HELPCHAT_PROVIDER_OPENAI;
end;

procedure TOpenAITests.TearDown;
begin
  FSettings.Free;
  FStream.Free;
  FTokens.Free;
end;

class function TOpenAITests.Msg(const ARole: THelpChatRole;
  const AContent: string): THelpChatMessage;
begin
  Result := Default(THelpChatMessage);
  Result.Role := ARole;
  Result.Content := AContent;
end;

procedure TOpenAITests.Feed(const AText: string);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AText);
  if Length(LBytes) > 0 then
    FStream.Write(LBytes[0], Length(LBytes));
end;

procedure TOpenAITests.Sse_ParsesContentDeltas_AndFinishReason;
begin
  Feed(CHUNK_HEL);
  Feed(CHUNK_LO);
  Feed(CHUNK_STOP);
  FStream.Finish;
  Assert.AreEqual('Hello, città', FStream.Text);
  Assert.AreEqual(2, FTokens.Count, 'one token per delta, [DONE] is not one');
  Assert.AreEqual('stop', FStream.FinishReason);
  Assert.AreEqual('', FStream.Error);
end;

procedure TOpenAITests.Sse_HandlesChunkBoundaryInsideALine;
var
  LWhole: string;
  LBytes: TBytes;
  LCut: Integer;
begin
  // The socket splits where it likes, multi-byte characters included.
  LWhole := CHUNK_LO;
  LBytes := TEncoding.UTF8.GetBytes(LWhole);
  LCut := Length(LBytes) - 12;
  FStream.Write(LBytes[0], LCut);
  Assert.AreEqual('', FStream.Text, 'half a line is not an event yet');
  FStream.Write(LBytes[LCut], Length(LBytes) - LCut);
  FStream.Finish;
  Assert.AreEqual('lo, città', FStream.Text);
end;

procedure TOpenAITests.Sse_ErrorPayload_IsKept;
begin
  Feed('data: {"error":{"message":"model not found","type":"invalid_request_error"}}'#10#10);
  FStream.Finish;
  Assert.AreEqual('model not found', FStream.Error);
end;

procedure TOpenAITests.Sse_AssemblesToolCallsByIndex;
var
  LCalls: TArray<THelpChatToolCall>;
begin
  // The name comes with the first fragment, the arguments in pieces after it,
  // and only the index ties them together.
  Feed('data: {"choices":[{"index":0,"delta":{"tool_calls":[' +
    '{"index":0,"id":"call_1","type":"function","function":{"name":"open_screen","arguments":""}}]}}]}'#10#10);
  Feed('data: {"choices":[{"index":0,"delta":{"tool_calls":[' +
    '{"index":0,"function":{"arguments":"{\"name\":"}}]}}]}'#10#10);
  Feed('data: {"choices":[{"index":0,"delta":{"tool_calls":[' +
    '{"index":0,"function":{"arguments":"\"Clienti\"}"}}]}}]}'#10#10);
  Feed('data: {"choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}]}'#10#10);
  FStream.Finish;

  LCalls := FStream.ToolCalls;
  Assert.AreEqual(1, Length(LCalls));
  Assert.AreEqual('call_1', LCalls[0].Id);
  Assert.AreEqual('open_screen', LCalls[0].Name);
  Assert.AreEqual('{"name":"Clienti"}', LCalls[0].InputJson);
  Assert.AreEqual('tool_calls', FStream.FinishReason);
end;

procedure TOpenAITests.Tools_AreWrappedAsFunctions;
var
  LJson: string;
  LArray: TJSONArray;
  LTool: TJSONObject;
begin
  LJson := THelpChatOpenAIProvider.BuildToolsJson(
    '[{"name":"open_screen","description":"Opens a screen",' +
    '"input_schema":{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}}]');
  LArray := TJSONObject.ParseJSONValue(LJson) as TJSONArray;
  try
    Assert.AreEqual(1, LArray.Count);
    LTool := LArray.Items[0] as TJSONObject;
    Assert.AreEqual('function', LTool.GetValue<string>('type'));
    Assert.AreEqual('open_screen', LTool.GetValue<string>('function.name'));
    // input_schema of the broker becomes parameters here, unchanged inside.
    Assert.AreEqual('string', LTool.GetValue<string>('function.parameters.properties.name.type'));
  finally
    LArray.Free;
  end;
  Assert.AreEqual('', THelpChatOpenAIProvider.BuildToolsJson(''), 'no actions, no tools');
  Assert.AreEqual('', THelpChatOpenAIProvider.BuildToolsJson('[]'));
end;

procedure TOpenAITests.RequestBody_Shape;
var
  LHistory: TArray<THelpChatMessage>;
  LRoot: TJSONObject;
  LMessages: TJSONArray;
begin
  LHistory := [Msg(hcrUser, 'come esporto?'), Msg(hcrAssistant, 'con il bottone')];
  LRoot := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildRequestBody(
    LHistory, 'sei un assistente', FSettings.OpenAI, '', '')) as TJSONObject;
  try
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LRoot.GetValue<string>('model'),
      'an empty Model means the default of the provider');
    Assert.IsTrue(LRoot.GetValue<Boolean>('stream'));
    LMessages := LRoot.GetValue('messages') as TJSONArray;
    // The instruction is the first message, not a field of its own.
    Assert.AreEqual(3, LMessages.Count);
    Assert.AreEqual('system', (LMessages.Items[0] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('sei un assistente', (LMessages.Items[0] as TJSONObject).GetValue<string>('content'));
    Assert.AreEqual('user', (LMessages.Items[1] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('assistant', (LMessages.Items[2] as TJSONObject).GetValue<string>('role'));
    Assert.IsNull(LRoot.GetValue('tools'), 'no actions, no tools');
  finally
    LRoot.Free;
  end;
end;

procedure TOpenAITests.RequestBody_CarriesToolsAndTheToolTurns;
var
  LHistory: TArray<THelpChatMessage>;
  LRoot: TJSONObject;
  LMessages, LTools: TJSONArray;
  LTurns: string;
begin
  LHistory := [Msg(hcrUser, 'apri i clienti')];
  LTurns := '[' + THelpChatOpenAIProvider.BuildAssistantToolMessage('',
    [THelpChatToolCall.Create('call_1', 'open_screen', '{"name":"Clienti"}')]) +
    ',{"role":"tool","tool_call_id":"call_1","content":"fatto"}]';
  LRoot := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildRequestBody(
    LHistory, 'istruzione', FSettings.OpenAI,
    THelpChatOpenAIProvider.BuildToolsJson(
      '[{"name":"open_screen","description":"d","input_schema":{"type":"object","properties":{}}}]'),
    LTurns)) as TJSONObject;
  try
    LTools := LRoot.GetValue('tools') as TJSONArray;
    Assert.AreEqual(1, LTools.Count);
    LMessages := LRoot.GetValue('messages') as TJSONArray;
    // system, user, the assistant turn that asked, the tool result.
    Assert.AreEqual(4, LMessages.Count);
    Assert.AreEqual('assistant', (LMessages.Items[2] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('tool', (LMessages.Items[3] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('call_1', (LMessages.Items[3] as TJSONObject).GetValue<string>('tool_call_id'));
  finally
    LRoot.Free;
  end;
end;

procedure TOpenAITests.AssistantToolMessage_HasToolCalls;
var
  LMsg: TJSONObject;
  LCalls: TJSONArray;
  LCall: TJSONObject;
begin
  LMsg := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildAssistantToolMessage(
    'apro subito', [THelpChatToolCall.Create('call_9', 'open_screen', '')])) as TJSONObject;
  try
    Assert.AreEqual('assistant', LMsg.GetValue<string>('role'));
    Assert.AreEqual('apro subito', LMsg.GetValue<string>('content'));
    LCalls := LMsg.GetValue('tool_calls') as TJSONArray;
    LCall := LCalls.Items[0] as TJSONObject;
    Assert.AreEqual('call_9', LCall.GetValue<string>('id'));
    Assert.AreEqual('function', LCall.GetValue<string>('type'));
    // An action without parameters still needs valid JSON arguments.
    Assert.AreEqual('{}', LCall.GetValue<string>('function.arguments'));
  finally
    LMsg.Free;
  end;
end;

procedure TOpenAITests.ExtractApiError_FromJson_AndFallback;
begin
  Assert.AreEqual('invalid api key', THelpChatOpenAIProvider.ExtractApiError(
    '{"error":{"message":"invalid api key","code":"invalid_api_key"}}', 401, 'Unauthorized', FSettings));
  Assert.Contains(THelpChatOpenAIProvider.ExtractApiError('<html>502</html>', 502,
    'Bad Gateway', FSettings), '502', 'an unreadable body falls back to the status');
end;

procedure TOpenAITests.ConfigurationIssue_OnlyWhenCallingOpenAIItself;
begin
  FSettings.OpenAI.ApiKey := '';
  if GetEnvironmentVariable(HELPCHAT_OPENAI_APIKEY_ENVVAR) = '' then
    Assert.AreNotEqual('', THelpChatOpenAIProvider.ConfigurationIssue(FSettings),
      'no key and the real endpoint: that cannot work');
  // A local server asks for no key at all, so neither do we.
  FSettings.OpenAI.BaseUrl := 'http://localhost:11434/v1';
  Assert.AreEqual('', THelpChatOpenAIProvider.ConfigurationIssue(FSettings));
  FSettings.OpenAI.BaseUrl := '';
  FSettings.OpenAI.ApiKey := 'sk-not-a-real-key';
  Assert.AreEqual('', THelpChatOpenAIProvider.ConfigurationIssue(FSettings));
end;

procedure TOpenAITests.CompletionsUrl_Default_Local_AndAzure;
begin
  Assert.AreEqual(HELPCHAT_OPENAI_DEF_BASEURL + HELPCHAT_OPENAI_COMPLETIONS_PATH,
    THelpChatOpenAIProvider.CompletionsUrl(FSettings.OpenAI));
  // What Ollama and LM Studio publish already names the version: a second
  // /v1 would be a 404 that looks like a wrong key.
  FSettings.OpenAI.BaseUrl := 'http://localhost:11434/v1';
  Assert.AreEqual('http://localhost:11434/v1/chat/completions',
    THelpChatOpenAIProvider.CompletionsUrl(FSettings.OpenAI));
  // A trailing slash is not a different endpoint.
  FSettings.OpenAI.BaseUrl := 'https://api.groq.com/openai/v1/';
  Assert.AreEqual('https://api.groq.com/openai/v1/chat/completions',
    THelpChatOpenAIProvider.CompletionsUrl(FSettings.OpenAI));
  // Azure: the deployment is in the path, the version in the query.
  FSettings.OpenAI.BaseUrl := 'https://my-resource.openai.azure.com';
  FSettings.OpenAI.AzureDeployment := 'my-gpt';
  FSettings.OpenAI.AzureApiVersion := '2024-10-21';
  Assert.AreEqual('https://my-resource.openai.azure.com/openai/deployments/my-gpt' +
    '/chat/completions?api-version=2024-10-21',
    THelpChatOpenAIProvider.CompletionsUrl(FSettings.OpenAI));
end;

end.
