unit HelpChatAI.Tests.Claude;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider.Claude;

type
  /// <summary>Everything here runs without network: the SSE parser is fed by
  /// hand and the request/prompt builders are pure functions.</summary>
  [TestFixture]
  TClaudeTests = class
  strict private
    FTokens: TList<string>;
    FStream: THelpChatSseStream;
    procedure Feed(const AText: string);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Sse_ParsesTextDeltas_AndStopReason;
    [Test] procedure Sse_HandlesChunkBoundaryInsideALine;
    [Test] procedure Sse_HandlesCrLf_AndMissingTrailingNewline;
    [Test] procedure Sse_ErrorEvent_IsKept;
    [Test] procedure Sse_MalformedData_IsIgnored;
    [Test] procedure Sse_RawKeepsWholeBody;
    [Test] procedure SystemPrompt_Default_Context_Grounding;
    [Test] procedure SystemPrompt_Override_And_GroundingOff;
    [Test] procedure RequestBody_Shape;
    [Test] procedure RequestBody_EmptyHistory_HasOneUserTurn;
    [Test] procedure ExtractApiError_FromJson_AndFallback;
    [Test] procedure Provider_WithoutKey_RaisesConfigError;
    [Test] procedure Sse_ParsesToolUseBlocks;
    [Test] procedure RequestBody_DeclaresToolsAndCarriesTheToolTurns;
    [Test] procedure AssistantToolMessage_HasTextAndToolUseBlocks;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  HelpChatAI.Messages,
  HelpChatAI.DocIndex,
  HelpChatAI.Provider,
  HelpChatAI.Tests.Helpers;

procedure TClaudeTests.Setup;
begin
  FTokens := TList<string>.Create;
  FStream := THelpChatSseStream.Create(
    procedure(const AToken: string)
    begin
      FTokens.Add(AToken);
    end);
end;

procedure TClaudeTests.TearDown;
begin
  FStream.Free;
  FTokens.Free;
end;

procedure TClaudeTests.Feed(const AText: string);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AText);
  if Length(LBytes) > 0 then
    FStream.Write(LBytes[0], Length(LBytes));
end;

const
  DELTA_HEL = 'event: content_block_delta'#10'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hel"}}'#10#10;
  DELTA_LO = 'event: content_block_delta'#10'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"lo, città"}}'#10#10;
  MSG_DELTA = 'event: message_delta'#10'data: {"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":3}}'#10#10;
  MSG_STOP = 'event: message_stop'#10'data: {"type":"message_stop"}'#10#10;

procedure TClaudeTests.Sse_ParsesTextDeltas_AndStopReason;
begin
  Feed('event: message_start'#10'data: {"type":"message_start","message":{"id":"m1","role":"assistant"}}'#10#10);
  Feed(DELTA_HEL);
  Feed(DELTA_LO);
  Feed(MSG_DELTA);
  Feed(MSG_STOP);
  FStream.Finish;
  Assert.AreEqual('Hello, città', FStream.Text);
  Assert.AreEqual(2, Integer(FTokens.Count));
  Assert.AreEqual('Hel', FTokens[0]);
  Assert.AreEqual('lo, città', FTokens[1]);
  Assert.AreEqual('end_turn', FStream.StopReason);
  Assert.AreEqual('', FStream.Error);
end;

procedure TClaudeTests.Sse_HandlesChunkBoundaryInsideALine;
var
  LAll: string;
  I: Integer;
begin
  LAll := DELTA_HEL + DELTA_LO + MSG_DELTA;
  // One byte at a time: the worst possible chunking, including inside the
  // multi-byte UTF-8 sequence of "à".
  for I := 1 to Length(LAll) do
    Feed(LAll[I]);
  FStream.Finish;
  Assert.AreEqual('Hello, città', FStream.Text);
  Assert.AreEqual(2, Integer(FTokens.Count));
end;

procedure TClaudeTests.Sse_HandlesCrLf_AndMissingTrailingNewline;
begin
  Feed(StringReplace(DELTA_HEL, #10, #13#10, [rfReplaceAll]));
  // Last line without a terminating newline: only Finish can flush it.
  Feed('data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"lo"}}');
  Assert.AreEqual('Hel', FStream.Text, 'the incomplete line waits');
  FStream.Finish;
  Assert.AreEqual('Hello', FStream.Text);
end;

procedure TClaudeTests.Sse_ErrorEvent_IsKept;
begin
  Feed(DELTA_HEL);
  Feed('event: error'#10'data: {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}'#10#10);
  FStream.Finish;
  Assert.AreEqual('Overloaded', FStream.Error);
  Assert.AreEqual('Hel', FStream.Text, 'tokens received before the error are kept');
end;

procedure TClaudeTests.Sse_MalformedData_IsIgnored;
begin
  Feed('data: {not json'#10#10);
  Feed('data: [1,2]'#10#10);
  Feed('data: '#10#10);
  Feed('data: [DONE]'#10#10);
  Feed(': a comment line'#10);
  Feed(DELTA_HEL);
  FStream.Finish;
  Assert.AreEqual('Hel', FStream.Text);
  Assert.AreEqual('', FStream.Error);
end;

procedure TClaudeTests.Sse_RawKeepsWholeBody;
const
  PLAIN_ERROR = '{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}';
begin
  // A non-2xx reply is plain JSON, not SSE: nothing parsed, everything in Raw.
  Feed(PLAIN_ERROR);
  FStream.Finish;
  Assert.AreEqual('', FStream.Text);
  Assert.Contains(FStream.Raw, 'invalid x-api-key');
  Assert.AreEqual('invalid x-api-key',
    THelpChatClaudeProvider.ExtractApiError(FStream.Raw, 401, 'Unauthorized', nil));
end;

procedure TClaudeTests.SystemPrompt_Default_Context_Grounding;
var
  LSettings: THelpChatSettings;
  LIndex: THelpChatDocIndex;
  LRetriever: IHelpChatRetriever;
  LHistory: TArray<THelpChatMessage>;
  LContext: THelpChatContext;
  LPrompt: string;
begin
  LSettings := THelpChatSettings.Create;
  LIndex := THelpChatDocIndex.Create;
  LRetriever := LIndex;
  try
    LSettings.Language := hclEnglish;
    LIndex.BaseUrl := 'https://docs.example.com/';
    LIndex.LoadFromFile(TestDataFile('help-index.json'));
    SetLength(LHistory, 1);
    LHistory[0].Role := hcrUser;
    LHistory[0].Content := 'how do I export the grid?';
    LContext := Default(THelpChatContext);
    LContext.ScreenLabel := 'Orders';
    LContext.ScreenType := 'TOrdersForm';

    LPrompt := THelpChatClaudeProvider.BuildSystemPrompt(LHistory, LContext, LSettings, LRetriever);
    Assert.StartsWith(HELPCHAT_CLAUDE_DEF_SYSTEMPROMPT, LPrompt);
    Assert.Contains(LPrompt, 'The user is currently on the "Orders" screen (type: TOrdersForm).');
    Assert.Contains(LPrompt, HelpChatMsg(hcmRelevantDocs, hclEnglish));
    Assert.Contains(LPrompt, '## Exporting the grid');
    Assert.Contains(LPrompt, 'Export button in the toolbar', 'the page text (excerpt) is injected, not only the summary');
    Assert.Contains(LPrompt, 'Source: https://docs.example.com/grid/export.html');

    // Without context and retriever: base instruction plus the language rule.
    // The prompt stays English when the UI language is Italian; the configured
    // language becomes the default reply language.
    Assert.Contains(LPrompt, 'Reply in English,');
    LSettings.Language := hclItalian;
    LPrompt := THelpChatClaudeProvider.BuildSystemPrompt(LHistory, Default(THelpChatContext), LSettings, nil);
    Assert.StartsWith(HELPCHAT_CLAUDE_DEF_SYSTEMPROMPT, LPrompt);
    Assert.Contains(LPrompt, 'The user interface of the application is in Italian. Reply in Italian,');
    Assert.Contains(LPrompt, 'ONLY on the documentation excerpts', 'the default prompt forbids generic answers');
    Assert.DoesNotContain(LPrompt, HelpChatMsg(hcmRelevantDocs, hclItalian));
  finally
    LRetriever := nil;
    LSettings.Free;
  end;
end;

procedure TClaudeTests.SystemPrompt_Override_And_GroundingOff;
var
  LSettings: THelpChatSettings;
  LIndex: THelpChatDocIndex;
  LRetriever: IHelpChatRetriever;
  LHistory: TArray<THelpChatMessage>;
  LPrompt: string;
begin
  LSettings := THelpChatSettings.Create;
  LIndex := THelpChatDocIndex.Create;
  LRetriever := LIndex;
  try
    LIndex.LoadFromFile(TestDataFile('help-index.json'));
    SetLength(LHistory, 1);
    LHistory[0].Role := hcrUser;
    LHistory[0].Content := 'export grid';
    LSettings.Claude.SystemPrompt := 'You are Bob.';
    LSettings.Claude.GroundingMaxPages := 0;
    LPrompt := THelpChatClaudeProvider.BuildSystemPrompt(LHistory, Default(THelpChatContext), LSettings, LRetriever);
    Assert.StartsWith('You are Bob. The user interface of the application is in ', LPrompt,
      'override used, language rule kept, grounding off, no context');
    LSettings.Claude.GroundingMaxPages := 1;
    LPrompt := THelpChatClaudeProvider.BuildSystemPrompt(LHistory, Default(THelpChatContext), LSettings, LRetriever);
    Assert.StartsWith('You are Bob.', LPrompt);
    Assert.Contains(LPrompt, '## Exporting the grid');
    Assert.DoesNotContain(LPrompt, '## Filtering a list', 'only one page requested');
  finally
    LRetriever := nil;
    LSettings.Free;
  end;
end;

procedure TClaudeTests.RequestBody_Shape;
var
  LClaude: THelpChatClaudeSettings;
  LHistory: TArray<THelpChatMessage>;
  LRoot: TJSONObject;
  LMessages: TJSONArray;
begin
  LClaude := THelpChatClaudeSettings.Create;
  try
    LClaude.Model := 'claude-test';
    LClaude.MaxTokens := 77;
    SetLength(LHistory, 4);
    LHistory[0].Role := hcrSystem; LHistory[0].Content := 'ignored system';
    LHistory[1].Role := hcrUser; LHistory[1].Content := 'q1 "quoted"';
    LHistory[2].Role := hcrAssistant; LHistory[2].Content := '   '; // empty: skipped
    LHistory[3].Role := hcrUser; LHistory[3].Content := 'q2';
    LRoot := TJSONObject.ParseJSONValue(
      THelpChatClaudeProvider.BuildRequestBody(LHistory, 'SYS', LClaude)) as TJSONObject;
    try
      Assert.IsNotNull(LRoot);
      Assert.AreEqual('claude-test', LRoot.GetValue<string>('model'));
      Assert.AreEqual(77, LRoot.GetValue<Integer>('max_tokens'));
      Assert.IsTrue(LRoot.GetValue<Boolean>('stream'));
      Assert.AreEqual('SYS', LRoot.GetValue<string>('system'));
      LMessages := LRoot.GetValue('messages') as TJSONArray;
      Assert.AreEqual(2, LMessages.Count);
      Assert.AreEqual('user', (LMessages.Items[0] as TJSONObject).GetValue<string>('role'));
      Assert.AreEqual('q1 "quoted"', (LMessages.Items[0] as TJSONObject).GetValue<string>('content'));
      Assert.AreEqual('q2', (LMessages.Items[1] as TJSONObject).GetValue<string>('content'));
    finally
      LRoot.Free;
    end;
  finally
    LClaude.Free;
  end;
end;

procedure TClaudeTests.RequestBody_EmptyHistory_HasOneUserTurn;
var
  LClaude: THelpChatClaudeSettings;
  LRoot: TJSONObject;
  LMessages: TJSONArray;
begin
  LClaude := THelpChatClaudeSettings.Create;
  try
    LRoot := TJSONObject.ParseJSONValue(
      THelpChatClaudeProvider.BuildRequestBody(nil, '', LClaude)) as TJSONObject;
    try
      Assert.IsNull(LRoot.GetValue('system'), 'no system field when empty');
      LMessages := LRoot.GetValue('messages') as TJSONArray;
      Assert.AreEqual(1, LMessages.Count);
      Assert.AreEqual('user', (LMessages.Items[0] as TJSONObject).GetValue<string>('role'));
    finally
      LRoot.Free;
    end;
  finally
    LClaude.Free;
  end;
end;

procedure TClaudeTests.Sse_ParsesToolUseBlocks;
var
  LCalls: TArray<THelpChatToolCall>;
begin
  // What the API sends when the model wants to run an action: a tool_use block
  // whose arguments arrive as fragments of JSON text.
  Feed('data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}'#10#10);
  Feed('data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Apro"}}'#10#10);
  Feed('data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"apri_schermata"}}'#10#10);
  Feed('data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"nome\":"}}'#10#10);
  Feed('data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"\"Scheduler\"}"}}'#10#10);
  Feed('data: {"type":"content_block_stop","index":1}'#10#10);
  Feed('data: {"type":"message_delta","delta":{"stop_reason":"tool_use"}}'#10#10);
  FStream.Finish;

  Assert.AreEqual('Apro', FStream.Text, 'the text of the reply is separate from the call');
  Assert.AreEqual('tool_use', FStream.StopReason);
  LCalls := FStream.ToolCalls;
  Assert.AreEqual(1, Integer(Length(LCalls)));
  Assert.AreEqual('toolu_1', LCalls[0].Id);
  Assert.AreEqual('apri_schermata', LCalls[0].Name);
  Assert.AreEqual('{"nome":"Scheduler"}', LCalls[0].InputJson, 'the fragments are joined');
end;

procedure TClaudeTests.RequestBody_DeclaresToolsAndCarriesTheToolTurns;
var
  LClaude: THelpChatClaudeSettings;
  LHistory: TArray<THelpChatMessage>;
  LValue: TJSONValue;
  LRoot: TJSONObject;
  LTools, LMessages: TJSONArray;
  LBody: string;
begin
  LClaude := THelpChatClaudeSettings.Create;
  try
  SetLength(LHistory, 1);
  LHistory[0].Role := hcrUser;
  LHistory[0].Content := 'apri lo scheduler';
  LBody := THelpChatClaudeProvider.BuildRequestBody(LHistory, 'sys', LClaude,
    '[{"name":"apri_schermata","description":"Opens","input_schema":{"type":"object"}}]',
    '[{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"apri_schermata","input":{}}]},' +
    '{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"done"}]}]');
  LValue := TJSONObject.ParseJSONValue(LBody);
  try
    LRoot := LValue as TJSONObject;
    LTools := LRoot.GetValue('tools') as TJSONArray;
    Assert.AreEqual(1, LTools.Count, 'the actions are declared as tools');
    LMessages := LRoot.GetValue('messages') as TJSONArray;
    // The question, then what was already exchanged with the tools.
    Assert.AreEqual(3, LMessages.Count);
    Assert.AreEqual('user', (LMessages.Items[0] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('assistant', (LMessages.Items[1] as TJSONObject).GetValue<string>('role'));
    Assert.AreEqual('user', (LMessages.Items[2] as TJSONObject).GetValue<string>('role'));
  finally
    LValue.Free;
  end;

  // Without actions nothing changes for the model.
  LBody := THelpChatClaudeProvider.BuildRequestBody(LHistory, 'sys', LClaude);
  Assert.DoesNotContain(LBody, '"tools"');
  finally
    LClaude.Free;
  end;
end;

procedure TClaudeTests.AssistantToolMessage_HasTextAndToolUseBlocks;
var
  LCalls: TArray<THelpChatToolCall>;
  LValue: TJSONValue;
  LContent: TJSONArray;
  LBlock: TJSONObject;
begin
  SetLength(LCalls, 1);
  LCalls[0].Id := 't1';
  LCalls[0].Name := 'apri_schermata';
  LCalls[0].InputJson := '{"nome":"Scheduler"}';
  LValue := TJSONObject.ParseJSONValue(
    THelpChatClaudeProvider.BuildAssistantToolMessage('Apro', LCalls));
  try
    Assert.AreEqual('assistant', (LValue as TJSONObject).GetValue<string>('role'));
    LContent := (LValue as TJSONObject).GetValue('content') as TJSONArray;
    Assert.AreEqual(2, LContent.Count, 'the text it said, and the call it made');
    Assert.AreEqual('text', (LContent.Items[0] as TJSONObject).GetValue<string>('type'));
    LBlock := LContent.Items[1] as TJSONObject;
    Assert.AreEqual('tool_use', LBlock.GetValue<string>('type'));
    Assert.AreEqual('t1', LBlock.GetValue<string>('id'));
    Assert.AreEqual('Scheduler', (LBlock.GetValue('input') as TJSONObject).GetValue<string>('nome'));
  finally
    LValue.Free;
  end;

  // An action without arguments still needs an input object.
  LCalls[0].InputJson := '';
  LValue := TJSONObject.ParseJSONValue(THelpChatClaudeProvider.BuildAssistantToolMessage('', LCalls));
  try
    LContent := (LValue as TJSONObject).GetValue('content') as TJSONArray;
    Assert.AreEqual(1, LContent.Count, 'no text block when it said nothing');
    LBlock := LContent.Items[0] as TJSONObject;
    Assert.IsTrue(LBlock.GetValue('input') is TJSONObject);
  finally
    LValue.Free;
  end;
end;

procedure TClaudeTests.ExtractApiError_FromJson_AndFallback;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclItalian;
    Assert.AreEqual('rate limited',
      THelpChatClaudeProvider.ExtractApiError('{"error":{"message":"rate limited"}}', 429, 'Too Many', LSettings));
    Assert.AreEqual('Errore API Claude (HTTP 500 Server Error).',
      THelpChatClaudeProvider.ExtractApiError('<html>oops</html>', 500, 'Server Error', LSettings));
    Assert.AreEqual('Errore API Claude (HTTP 503 Busy).',
      THelpChatClaudeProvider.ExtractApiError('', 503, 'Busy', LSettings));
  finally
    LSettings.Free;
  end;
end;

procedure TClaudeTests.Provider_WithoutKey_RaisesConfigError;
var
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
  LHistory: TArray<THelpChatMessage>;
begin
  if GetEnvironmentVariable(HELPCHAT_CLAUDE_APIKEY_ENVVAR) <> '' then
  begin
    Assert.Pass('skipped: ' + HELPCHAT_CLAUDE_APIKEY_ENVVAR + ' is set on this machine');
    Exit;
  end;
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Claude.ApiKey := '';
    LProvider := THelpChatProviderRegistry.CreateProvider(HELPCHAT_PROVIDER_CLAUDE, LSettings, nil);
    SetLength(LHistory, 1);
    LHistory[0].Role := hcrUser;
    LHistory[0].Content := 'hi';
    Assert.WillRaise(
      procedure
      begin
        LProvider.Generate(LHistory, Default(THelpChatContext), nil, nil);
      end, EHelpChatConfigError);
    try
      LProvider.Generate(LHistory, Default(THelpChatContext), nil, nil);
    except
      on E: EHelpChatConfigError do
      begin
        Assert.Contains(E.Message, 'helpchatai.json', 'the message tells where the key goes');
        Assert.Contains(E.Message, TPath.GetDirectoryName(THelpChatSettings.SharedUserConfigFile));
      end;
    end;
  finally
    LSettings.Free;
  end;
end;

end.
