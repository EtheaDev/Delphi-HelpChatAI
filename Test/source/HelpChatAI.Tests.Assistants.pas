{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Tests of the assistants: the list in the settings, the overrides it    }
{       applies, the icon each one gets, and the switch in the engine.         }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}
unit HelpChatAI.Tests.Assistants;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

type
  [TestFixture]
  TAssistantsTests = class
  public
    [Test] procedure Settings_NoList_IsTheImplicitOneOfTheProvider;
    [Test] procedure Settings_RoundTrip_ListAndActive;
    [Test] procedure Settings_LoadJson_ListReplacesWhole;
    [Test] procedure Settings_Apply_OverridesTheSection_AndIsReversible;
    [Test] procedure Settings_Apply_UnknownName_ChangesNothing;
    [Test] procedure Settings_Assign_CarriesTheOverrides;
    [Test] procedure Icons_ModelFirst_ThenEndpoint_ThenProvider;
    [Test] procedure Icons_EveryShippedIdHasAnSvg_WithoutTitle;
    [Test] procedure Engine_Select_ChangesTheNextRequest;
    [Test] procedure Engine_Start_AppliesTheConfiguredOne;
  end;

implementation

uses
  System.SysUtils,
  HelpChatAI.Icons,
  HelpChatAI.Tests.Helpers;

procedure TAssistantsTests.Settings_NoList_IsTheImplicitOneOfTheProvider;
var
  LSettings: THelpChatSettings;
  LList: TArray<THelpChatAssistantInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    LList := LSettings.ResolveAssistants;
    Assert.AreEqual(1, Length(LList));
    Assert.AreEqual('Claude', LList[0].Name);
    Assert.AreEqual('claude', LList[0].Provider);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_MODEL, LList[0].Model);
    Assert.IsTrue(LList[0].Active);
    Assert.AreEqual('Claude', LSettings.ActiveAssistantName);
    Assert.IsTrue(LSettings.ApplyAssistant('claude'), 'its own name, case apart, is accepted');
    Assert.IsFalse(LSettings.ApplyAssistant('Gemini'), 'nothing else is there to switch to');
    Assert.AreEqual('claude', LSettings.Provider);

    LSettings.Provider := 'docsearch';
    LList := LSettings.ResolveAssistants;
    Assert.AreEqual('docsearch', LList[0].Name);
    Assert.AreEqual('', LList[0].Model, 'no model behind it');
  finally
    LSettings.Free;
  end;
end;

procedure TAssistantsTests.Settings_RoundTrip_ListAndActive;
var
  LSource, LCopy: THelpChatSettings;
begin
  LSource := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    with LSource.Assistants.Add do
    begin
      Name := 'Claude';
      Provider := 'claude';
      Model := 'claude-haiku-4-5';
    end;
    with LSource.Assistants.Add do
    begin
      Name := 'Gemma (locale)';
      Provider := 'openai';
      Model := 'gemma4:12b';
      BaseUrl := 'http://localhost:11434/v1';
      ApiKey := 'none';
      Icon := 'gemma';
    end;
    LSource.Assistant := 'Gemma (locale)';

    LCopy.LoadFromJSON(LSource.SaveToJSON);

    Assert.AreEqual(2, LCopy.Assistants.Count);
    Assert.AreEqual('Claude', LCopy.Assistants[0].Name);
    Assert.AreEqual('claude', LCopy.Assistants[0].Provider);
    Assert.AreEqual('claude-haiku-4-5', LCopy.Assistants[0].Model);
    Assert.AreEqual('Gemma (locale)', LCopy.Assistants[1].Name);
    Assert.AreEqual('openai', LCopy.Assistants[1].Provider);
    Assert.AreEqual('gemma4:12b', LCopy.Assistants[1].Model);
    Assert.AreEqual('http://localhost:11434/v1', LCopy.Assistants[1].BaseUrl);
    Assert.AreEqual('none', LCopy.Assistants[1].ApiKey);
    Assert.AreEqual('gemma', LCopy.Assistants[1].Icon);
    Assert.AreEqual('Gemma (locale)', LCopy.Assistant);
    Assert.AreEqual('Gemma (locale)', LCopy.ActiveAssistantName);
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TAssistantsTests.Settings_LoadJson_ListReplacesWhole;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"Assistants":[{"Name":"A","Provider":"claude"},' +
      '{"Name":"B","Provider":"gemini"}]}');
    Assert.AreEqual(2, LSettings.Assistants.Count);
    // A later file with its own list is the list; one without leaves it.
    LSettings.LoadFromJSON('{"Assistants":[{"Provider":"openai","Model":"gpt-x"}]}');
    Assert.AreEqual(1, LSettings.Assistants.Count);
    Assert.AreEqual('OpenAI gpt-x', LSettings.Assistants[0].Name, 'a nameless one is called by what it runs');
    LSettings.LoadFromJSON('{"Provider":"claude"}');
    Assert.AreEqual(1, LSettings.Assistants.Count);
    Assert.AreEqual('OpenAI gpt-x', LSettings.ActiveAssistantName,
      'Assistant empty: the first of the list');
  finally
    LSettings.Free;
  end;
end;

procedure TAssistantsTests.Settings_Apply_OverridesTheSection_AndIsReversible;
var
  LSettings: THelpChatSettings;
  LList: TArray<THelpChatAssistantInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    LSettings.Claude.Model := 'claude-configured';
    LSettings.OpenAI.ApiKey := 'sk-configured';
    with LSettings.Assistants.Add do
    begin
      Name := 'Anthropic';
      Provider := 'claude';
      Model := 'claude-other';
    end;
    with LSettings.Assistants.Add do
    begin
      Name := 'Local';
      Provider := 'openai';
      Model := 'gemma4:12b';
      BaseUrl := 'http://localhost:11434/v1/';
      ApiKey := 'ollama';
    end;
    with LSettings.Assistants.Add do
    begin
      Name := 'Cloud';
      Provider := 'openai';   // no model, no endpoint: the section's own
    end;

    Assert.IsTrue(LSettings.ApplyAssistant('local'));
    Assert.AreEqual('openai', LSettings.Provider);
    Assert.AreEqual('Local', LSettings.Assistant);
    Assert.AreEqual('gemma4:12b', LSettings.OpenAI.ResolveModel);
    Assert.AreEqual('http://localhost:11434/v1', LSettings.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual('ollama', LSettings.OpenAI.ResolveApiKey);
    Assert.AreEqual('', LSettings.OpenAI.Model, 'the configuration is not rewritten');
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LSettings.OpenAI.ConfiguredModel);

    Assert.IsTrue(LSettings.ApplyAssistant('Cloud'));
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LSettings.OpenAI.ResolveModel, 'the override is gone');
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_BASEURL, LSettings.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual('sk-configured', LSettings.OpenAI.ResolveApiKey);

    Assert.IsTrue(LSettings.ApplyAssistant('Anthropic'));
    Assert.AreEqual('claude', LSettings.Provider);
    Assert.AreEqual('claude-other', LSettings.Claude.ResolveModel);
    Assert.AreEqual('claude-configured', LSettings.Claude.ConfiguredModel);

    // The list describes each one on its own, whatever is applied.
    LList := LSettings.ResolveAssistants;
    Assert.AreEqual(3, Length(LList));
    Assert.AreEqual('claude-other', LList[0].Model);
    Assert.IsTrue(LList[0].Active);
    Assert.AreEqual('gemma4:12b', LList[1].Model);
    Assert.AreEqual('http://localhost:11434/v1/', LList[1].BaseUrl);
    Assert.IsFalse(LList[1].Active);
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LList[2].Model, 'the configured model of the section');
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_BASEURL, LList[2].BaseUrl);
  finally
    LSettings.Free;
  end;
end;

procedure TAssistantsTests.Settings_Apply_UnknownName_ChangesNothing;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    with LSettings.Assistants.Add do
    begin
      Name := 'A';
      Provider := 'gemini';
    end;
    Assert.IsFalse(LSettings.ApplyAssistant('B'));
    Assert.AreEqual('claude', LSettings.Provider);
    Assert.AreEqual('', LSettings.Assistant);
    Assert.AreEqual('A', LSettings.ActiveAssistantName, 'the first of the list, until one is applied');
  finally
    LSettings.Free;
  end;
end;

procedure TAssistantsTests.Settings_Assign_CarriesTheOverrides;
var
  LSettings, LCopy: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    with LSettings.Assistants.Add do
    begin
      Name := 'Local';
      Provider := 'openai';
      Model := 'qwen3-coder:30b';
      BaseUrl := 'http://localhost:11434/v1';
    end;
    LSettings.ApplyAssistant('Local');
    // What a request works on is a snapshot: it must see the same model.
    LCopy.Assign(LSettings);
    Assert.AreEqual('openai', LCopy.Provider);
    Assert.AreEqual('qwen3-coder:30b', LCopy.OpenAI.ResolveModel);
    Assert.AreEqual('http://localhost:11434/v1', LCopy.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual(1, LCopy.Assistants.Count);
    Assert.AreEqual('Local', LCopy.Assistant);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TAssistantsTests.Icons_ModelFirst_ThenEndpoint_ThenProvider;
begin
  Assert.AreEqual('claude', HelpChatProviderIconFor('claude-haiku-4-5', '', 'claude'));
  Assert.AreEqual('gemini', HelpChatProviderIconFor('gemini-3.8-flash', '', 'gemini'));
  Assert.AreEqual('openai', HelpChatProviderIconFor('gpt-6-luna', '', 'openai'));
  Assert.AreEqual('openai', HelpChatProviderIconFor('o3-mini', '', 'openai'));
  // A local model served through the openai provider shows itself, not OpenAI.
  Assert.AreEqual('gemma', HelpChatProviderIconFor('gemma4:12b', 'http://localhost:11434/v1', 'openai'));
  Assert.AreEqual('qwen', HelpChatProviderIconFor('qwen3-coder:30b', 'http://localhost:11434/v1', 'openai'));
  Assert.AreEqual('mistral', HelpChatProviderIconFor('mixtral-8x7b', '', 'openai'));
  Assert.AreEqual('deepseek', HelpChatProviderIconFor('deepseek-r1', '', 'openai'));
  Assert.AreEqual('llama', HelpChatProviderIconFor('llama3.3', '', 'openai'));
  Assert.AreEqual('cohere', HelpChatProviderIconFor('command-r-plus', '', 'openai'));
  Assert.AreEqual('gemma', HelpChatProviderIconFor('google/gemma-3-27b', 'https://openrouter.ai/api/v1', 'openai'),
    'the vendor prefix of OpenRouter is skipped');
  // An unknown model: the endpoint says who serves it.
  Assert.AreEqual('ollama', HelpChatProviderIconFor('gpt-oss:20b'.Replace('gpt-oss', 'phi4'), 'http://localhost:11434/v1', 'openai'));
  Assert.AreEqual('openrouter', HelpChatProviderIconFor('x', 'https://openrouter.ai/api/v1', 'openai'));
  Assert.AreEqual('groq', HelpChatProviderIconFor('x', 'https://api.groq.com/openai/v1', 'openai'));
  Assert.AreEqual('azure', HelpChatProviderIconFor('x', 'https://my.openai.azure.com', 'openai'));
  Assert.AreEqual('lmstudio', HelpChatProviderIconFor('x', 'http://localhost:1234/v1', 'openai'));
  // Then the provider; and nothing for one that has no face.
  Assert.AreEqual('openai', HelpChatProviderIconFor('x', 'https://api.openai.com/v1', 'openai'));
  Assert.AreEqual('claude', HelpChatProviderIconFor('', '', 'claude'));
  Assert.AreEqual('', HelpChatProviderIconFor('', '', 'docsearch'));
  Assert.AreEqual('', HelpChatProviderIconFor('', '', 'stub'));
  Assert.AreEqual('', HelpChatProviderIconFor('', '', TEST_PROVIDER_ECHO));
end;

procedure TAssistantsTests.Icons_EveryShippedIdHasAnSvg_WithoutTitle;
var
  LId, LSvg: string;
begin
  for LId in HELPCHAT_PROVIDER_ICONS do
  begin
    Assert.IsTrue(HelpChatProviderIconExists(LId), LId);
    LSvg := HelpChatProviderIconSvg(LId);
    Assert.IsTrue(LSvg.StartsWith('<svg'), LId + ': ' + Copy(LSvg, 1, 40));
    Assert.IsFalse(LSvg.Contains('<title>'), LId + ': the title would be a browser tooltip');
    Assert.IsTrue(LSvg.TrimRight.EndsWith('</svg>'), LId);
  end;
  Assert.IsFalse(HelpChatProviderIconExists('nobody'));
  Assert.AreEqual('', HelpChatProviderIconSvg('nobody'));
  Assert.AreEqual('', HelpChatProviderIconSvg(''));
end;

procedure TAssistantsTests.Engine_Select_ChangesTheNextRequest;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
  LList: TArray<THelpChatAssistantInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    with LSettings.Assistants.Add do
    begin
      Name := 'Echo';
      Provider := TEST_PROVIDER_ECHO;
    end;
    with LSettings.Assistants.Add do
    begin
      Name := 'Broken';
      Provider := TEST_PROVIDER_FAIL;
    end;
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual(TEST_PROVIDER_ECHO, LSettings.Provider, 'Start applies the first of the list');
      Assert.IsTrue(LEngine.CanSelectAssistant);
      LList := LEngine.Assistants;
      Assert.AreEqual(2, Length(LList));
      Assert.AreEqual('', LList[0].Icon, 'a test provider has no icon');

      LResult := LEngine.Send('hello');
      Assert.IsTrue(WaitFor(function: Boolean
        begin
          Result := LEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage) and not LMessage.Pending;
        end));
      Assert.IsTrue(LMessage.Content.StartsWith('echo:'), LMessage.Content);

      Assert.IsTrue(LEngine.SelectAssistant('Broken'));
      Assert.AreEqual('Broken', LEngine.ActiveAssistant.Name);
      LResult := LEngine.Send('hello again');
      Assert.IsTrue(WaitFor(function: Boolean
        begin
          Result := LEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage) and not LMessage.Pending;
        end));
      Assert.IsTrue(LMessage.IsError, 'the failing provider answered this one');

      Assert.IsFalse(LEngine.SelectAssistant('Nobody'));
      Assert.AreEqual('Broken', LEngine.ActiveAssistant.Name);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TAssistantsTests.Engine_Start_AppliesTheConfiguredOne;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.Provider := 'claude';   // what the list says wins over this
    with LSettings.Assistants.Add do
    begin
      Name := 'Echo';
      Provider := TEST_PROVIDER_ECHO;
    end;
    with LSettings.Assistants.Add do
    begin
      Name := 'Slow';
      Provider := TEST_PROVIDER_SLOW;
    end;
    LSettings.Assistant := 'Slow';
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual(TEST_PROVIDER_SLOW, LSettings.Provider);
      Assert.AreEqual('Slow', LEngine.ActiveAssistant.Name);
      Assert.IsTrue(LEngine.ActiveAssistant.Active);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAssistantsTests);

end.
