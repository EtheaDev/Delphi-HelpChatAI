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
    [Test] procedure Sse_ToolCallsWithoutIndex_AreToldApartByTheirId;
    [Test] procedure Sse_BytesThatAreNotUtf8_AreSkipped;
    [Test] procedure Tools_AreWrappedAsFunctions;
    [Test] procedure RequestBody_Shape;
    [Test] procedure RequestBody_CarriesToolsAndTheToolTurns;
    [Test] procedure AssistantToolMessage_HasToolCalls;
    [Test] procedure ExtractApiError_FromJson_AndFallback;
    [Test] procedure ConfigurationIssue_OnlyWhenCallingOpenAIItself;
    [Test] procedure ReasoningEffort_OnlyWhenTheServiceAsksForIt;
    [Test] procedure ConfigurationIssue_AServiceOnTheInternet_WantsAKey;
    [Test] procedure LocalEndpoint_ThisMachine_AndThePrivateNetwork;
    [Test] procedure CompletionsUrl_Default_Local_AndAzure;
    [Test] procedure Responses_OnOpenAIItself_ChatElsewhere;
    [Test] procedure Responses_Url_Tools_AndBody;
    [Test] procedure Responses_Stream_TextCallsAndItems;
    [Test] procedure Responses_Stream_Failure_IsKept;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  HelpChatAI.Messages,
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

procedure TOpenAITests.Sse_ToolCallsWithoutIndex_AreToldApartByTheirId;
var
  LCalls: TArray<THelpChatToolCall>;
begin
  // Some servers that speak this API send no index: two calls must not be
  // glued into one, and a fragment without an id belongs to the call before.
  Feed('data: {"choices":[{"delta":{"tool_calls":[' +
    '{"id":"call_1","function":{"name":"open_screen","arguments":"{\"name\":"}}]}}]}'#10#10);
  Feed('data: {"choices":[{"delta":{"tool_calls":[' +
    '{"function":{"arguments":"\"Clienti\"}"}}]}}]}'#10#10);
  Feed('data: {"choices":[{"delta":{"tool_calls":[' +
    '{"id":"call_2","function":{"name":"export_pdf","arguments":"{}"}}]}}]}'#10#10);
  Feed('data: {"choices":[{"delta":{},"finish_reason":"stop"}]}'#10#10);
  FStream.Finish;

  LCalls := FStream.ToolCalls;
  Assert.AreEqual(2, Length(LCalls));
  Assert.AreEqual('open_screen', LCalls[0].Name);
  Assert.AreEqual('{"name":"Clienti"}', LCalls[0].InputJson);
  Assert.AreEqual('export_pdf', LCalls[1].Name);
  Assert.AreEqual('{}', LCalls[1].InputJson);
end;

procedure TOpenAITests.Sse_BytesThatAreNotUtf8_AreSkipped;
var
  LBad: TBytes;
begin
  // A line that is not UTF-8 must not raise out of the stream the HTTP
  // client writes into: it is skipped, and what follows is still read.
  LBad := TBytes.Create(Ord('d'), Ord('a'), Ord('t'), Ord('a'), Ord(':'), $C3, $28, $FF, 10);
  FStream.Write(LBad[0], Length(LBad));
  Feed('data: {"choices":[{"index":0,"delta":{"content":"ok"}}]}'#10#10);
  FStream.Finish;
  Assert.AreEqual('ok', FStream.Text);
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
    Assert.IsNull(LRoot.GetValue('reasoning_effort'), 'never sent unless asked for');
  finally
    LRoot.Free;
  end;
end;

procedure TOpenAITests.ReasoningEffort_OnlyWhenTheServiceAsksForIt;
var
  LRoot: TJSONObject;
begin
  // What gpt-6-luna answers in Chat Completions to a request with tools.
  Assert.IsTrue(THelpChatOpenAIProvider.AsksForNoReasoning('Function tools with ' +
    'reasoning_effort are not supported for gpt-6-luna in /v1/chat/completions. To use ' +
    'function tools, use /v1/responses or set reasoning_effort to ''none''.'));
  Assert.IsFalse(THelpChatOpenAIProvider.AsksForNoReasoning('Incorrect API key provided'));
  Assert.IsFalse(THelpChatOpenAIProvider.AsksForNoReasoning(
    'Unrecognized request argument supplied: reasoning_effort'), 'not a request for none');
  LRoot := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildRequestBody(
    [Msg(hcrUser, 'ciao')], '', FSettings.OpenAI, '', '[]', nil, hclAuto, 'none')) as TJSONObject;
  try
    Assert.AreEqual('none', LRoot.GetValue<string>('reasoning_effort'));
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

procedure TOpenAITests.ConfigurationIssue_AServiceOnTheInternet_WantsAKey;
begin
  FSettings.OpenAI.ApiKey := '';
  // OpenRouter, Groq: on the internet, and the key of OpenAI never goes
  // there - the environment variable included.
  FSettings.OpenAI.BaseUrl := 'https://openrouter.ai/api/v1';
  Assert.Contains(THelpChatOpenAIProvider.ConfigurationIssue(FSettings), 'openrouter.ai');
  FSettings.OpenAI.BaseUrl := 'https://api.groq.com/openai/v1';
  Assert.AreNotEqual('', THelpChatOpenAIProvider.ConfigurationIssue(FSettings));
  FSettings.OpenAI.ApiKey := 'gsk_not-a-real-key';
  Assert.AreEqual('', THelpChatOpenAIProvider.ConfigurationIssue(FSettings));
  // A server of the LAN asks for none, like a local one.
  FSettings.OpenAI.ApiKey := '';
  FSettings.OpenAI.BaseUrl := 'http://192.168.1.20:11434/v1';
  Assert.AreEqual('', THelpChatOpenAIProvider.ConfigurationIssue(FSettings));
end;

procedure TOpenAITests.LocalEndpoint_ThisMachine_AndThePrivateNetwork;
begin
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://localhost:11434/v1'));
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://127.0.0.1:1234'));
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://[::1]:8080/v1'));
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://10.0.0.5/v1'));
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://172.20.1.1:8000'));
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://192.168.1.20:11434/v1'));
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://gpu-box:11434/v1'), 'a name of the LAN');
  Assert.IsTrue(HelpChatIsLocalEndpoint('http://studio.local:1234'));
  Assert.IsFalse(HelpChatIsLocalEndpoint('https://api.openai.com/v1'));
  Assert.IsFalse(HelpChatIsLocalEndpoint('https://openrouter.ai/api/v1'));
  Assert.IsFalse(HelpChatIsLocalEndpoint('http://172.32.0.1'), 'outside 172.16/12');
  Assert.IsFalse(HelpChatIsLocalEndpoint('https://user@api.groq.com/openai/v1'));
  Assert.IsFalse(HelpChatIsLocalEndpoint(''));
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

procedure TOpenAITests.Responses_OnOpenAIItself_ChatElsewhere;
begin
  // OpenAI itself: Responses, where a GPT-6 keeps its reasoning while it acts.
  Assert.IsTrue(FSettings.OpenAI.UsesResponses);
  // Every other service speaks Chat Completions.
  FSettings.OpenAI.BaseUrl := 'http://localhost:11434/v1';
  Assert.IsFalse(FSettings.OpenAI.UsesResponses);
  FSettings.OpenAI.BaseUrl := 'https://openrouter.ai/api/v1';
  Assert.IsFalse(FSettings.OpenAI.UsesResponses);
  FSettings.OpenAI.BaseUrl := 'https://my-resource.openai.azure.com';
  FSettings.OpenAI.AzureDeployment := 'my-gpt';
  Assert.IsFalse(FSettings.OpenAI.UsesResponses, 'Azure keeps its deployments');
  // Api says it outright, both ways.
  FSettings.OpenAI.Api := 'Responses';
  Assert.IsTrue(FSettings.OpenAI.UsesResponses);
  FSettings.OpenAI.AzureDeployment := '';
  FSettings.OpenAI.BaseUrl := '';
  FSettings.OpenAI.Api := 'chat';
  Assert.IsFalse(FSettings.OpenAI.UsesResponses);
end;

procedure TOpenAITests.Responses_Url_Tools_AndBody;
var
  LRoot, LTool, LLast: TJSONObject;
  LTools, LInput: TJSONArray;
begin
  Assert.AreEqual('https://api.openai.com/v1/responses',
    THelpChatOpenAIProvider.ResponsesUrl(FSettings.OpenAI));
  FSettings.OpenAI.BaseUrl := 'http://localhost:1234/v1/';
  Assert.AreEqual('http://localhost:1234/v1/responses',
    THelpChatOpenAIProvider.ResponsesUrl(FSettings.OpenAI));
  FSettings.OpenAI.BaseUrl := '';

  LTools := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildResponsesToolsJson(
    '[{"name":"open_screen","description":"d","input_schema":{"type":"object","properties":{}}}]'))
    as TJSONArray;
  try
    LTool := LTools.Items[0] as TJSONObject;
    // Flat, unlike Chat Completions, and not strict: a parameter may be optional.
    Assert.AreEqual('function', LTool.GetValue<string>('type'));
    Assert.AreEqual('open_screen', LTool.GetValue<string>('name'));
    Assert.IsNull(LTool.GetValue('function'));
    Assert.IsFalse(LTool.GetValue<Boolean>('strict'));
    Assert.IsNotNull(LTool.GetValue('parameters'));
  finally
    LTools.Free;
  end;

  LRoot := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildResponsesBody(
    [Msg(hcrUser, 'ciao'), Msg(hcrAssistant, 'buongiorno'), Msg(hcrUser, 'apri i clienti')],
    'istruzione', FSettings.OpenAI, '',
    '[{"type":"function_call","call_id":"call_1","name":"open_screen","arguments":"{}"},' +
    '{"type":"function_call_output","call_id":"call_1","output":"fatto"}]')) as TJSONObject;
  try
    Assert.AreEqual('istruzione', LRoot.GetValue<string>('instructions'));
    Assert.IsFalse(LRoot.GetValue<Boolean>('store'), 'nothing kept on the service');
    Assert.IsTrue(LRoot.GetValue<Boolean>('stream'));
    Assert.Contains(LRoot.GetValue('include').ToJSON, 'reasoning.encrypted_content');
    Assert.IsNull(LRoot.GetValue('messages'));
    Assert.IsNull(LRoot.GetValue('tools'), 'no tools, no key');
    LInput := LRoot.GetValue('input') as TJSONArray;
    // three turns, the call, its result
    Assert.AreEqual(5, LInput.Count);
    Assert.AreEqual('assistant', (LInput.Items[1] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('buongiorno', (LInput.Items[1] as TJSONObject).GetValue<string>('content'));
    LLast := LInput.Items[4] as TJSONObject;
    Assert.AreEqual('function_call_output', LLast.GetValue<string>('type'));
    Assert.AreEqual('call_1', LLast.GetValue<string>('call_id'));
  finally
    LRoot.Free;
  end;
end;

procedure TOpenAITests.Responses_Stream_TextCallsAndItems;
var
  LStream: THelpChatOpenAIResponsesStream;
  LBytes: TBytes;
  LCalls: TArray<THelpChatToolCall>;
  LItems: TJSONArray;
begin
  // What gpt-6.1-sol streamed, cut down: a reasoning item, a call, a text.
  LBytes := TEncoding.UTF8.GetBytes(
    'event: response.created'#10 +
    'data: {"type":"response.created","response":{"id":"resp_1","error":null}}'#10#10 +
    'event: response.output_item.done'#10 +
    'data: {"type":"response.output_item.done","item":{"id":"rs_1","type":"reasoning","encrypted_content":"gAAA"}}'#10#10 +
    'data: {"type":"response.output_item.done","item":{"id":"fc_1","type":"function_call","status":"completed","arguments":"{\"screen\":\"Leads\"}","call_id":"call_9","name":"open_screen"}}'#10#10 +
    'data: {"type":"response.output_text.delta","delta":"Fatto, "}'#10#10 +
    'data: {"type":"response.output_text.delta","delta":"città"}'#10#10 +
    'data: {"type":"response.completed","response":{"id":"resp_1"}}'#10#10);
  LStream := THelpChatOpenAIResponsesStream.Create(nil);
  try
    LStream.Write(LBytes[0], Length(LBytes));
    LStream.Finish;
    Assert.AreEqual('Fatto, città', LStream.Text);
    Assert.AreEqual('', LStream.Error);
    LCalls := LStream.ToolCalls;
    Assert.AreEqual(1, Length(LCalls));
    Assert.AreEqual('call_9', LCalls[0].Id, 'the call_id is what the result answers');
    Assert.AreEqual('open_screen', LCalls[0].Name);
    Assert.AreEqual('{"screen":"Leads"}', LCalls[0].InputJson);
    // Both items go back with the next round, the reasoning first.
    LItems := TJSONObject.ParseJSONValue('[' + LStream.ItemsJson + ']') as TJSONArray;
    try
      Assert.AreEqual(2, LItems.Count);
      Assert.AreEqual('reasoning', (LItems.Items[0] as TJSONObject).GetValue<string>('type'));
      Assert.AreEqual('gAAA', (LItems.Items[0] as TJSONObject).GetValue<string>('encrypted_content'));
    finally
      LItems.Free;
    end;
  finally
    LStream.Free;
  end;
end;

procedure TOpenAITests.Responses_Stream_Failure_IsKept;
var
  LStream: THelpChatOpenAIResponsesStream;
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(
    'data: {"type":"response.failed","response":{"error":{"code":"server_error","message":"boom"}}}'#10#10);
  LStream := THelpChatOpenAIResponsesStream.Create(nil);
  try
    LStream.Write(LBytes[0], Length(LBytes));
    LStream.Finish;
    Assert.AreEqual('boom', LStream.Error);
  finally
    LStream.Free;
  end;
end;

end.
