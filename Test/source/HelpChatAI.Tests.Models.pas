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
unit HelpChatAI.Tests.Models;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

type
  [TestFixture]
  TModelsTests = class
  public
    [Test] procedure Settings_NoList_IsTheImplicitOneOfTheProvider;
    [Test] procedure Settings_RoundTrip_ListAndActive;
    [Test] procedure Settings_LoadJson_ListReplacesWhole;
    [Test] procedure Settings_Apply_OverridesTheSection_AndIsReversible;
    [Test] procedure Settings_Apply_UnknownName_ChangesNothing;
    [Test] procedure Settings_Apply_NoProviderOfItsOwn_IsTheConfiguredOne;
    [Test] procedure Settings_KeyOfTheSection_NeverGoesToAnotherHost;
    [Test] procedure Settings_Assign_CarriesTheOverrides;
    [Test] procedure Icons_ModelFirst_ThenEndpoint_ThenProvider;
    [Test] procedure Icons_EveryShippedIdHasAnSvg_WithoutTitle;
    [Test] procedure Flags_EveryLanguageHasOne;
    [Test] procedure Engine_Select_ChangesTheNextRequest;
    [Test] procedure Engine_Start_AppliesTheConfiguredOne;
    [Test] procedure Engine_Models_OnlyTheOnesThatCanAnswer;
    [Test] procedure Engine_Start_SkipsAModelThatCannotAnswer;
    [Test] procedure Engine_Models_AKeyInAFile_OffersItsModel;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  HelpChatAI.Messages,
  HelpChatAI.Icons,
  HelpChatAI.Provider,
  HelpChatAI.Tests.Helpers;

procedure TModelsTests.Settings_NoList_IsTheImplicitOneOfTheProvider;
var
  LSettings: THelpChatSettings;
  LList: TArray<THelpChatModelInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    LList := LSettings.ResolveModels;
    Assert.AreEqual(1, Length(LList));
    Assert.AreEqual('Claude', LList[0].Name);
    Assert.AreEqual('claude', LList[0].Provider);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_MODEL, LList[0].Model);
    Assert.IsTrue(LList[0].Active);
    Assert.AreEqual('Claude', LSettings.ActiveModelName);
    Assert.IsTrue(LSettings.ApplyModel('claude'), 'its own name, case apart, is accepted');
    Assert.IsFalse(LSettings.ApplyModel('Gemini'), 'nothing else is there to switch to');
    Assert.AreEqual('claude', LSettings.Provider);

    LSettings.Provider := 'docsearch';
    LList := LSettings.ResolveModels;
    Assert.AreEqual('docsearch', LList[0].Name);
    Assert.AreEqual('', LList[0].Model, 'no model behind it');
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Settings_RoundTrip_ListAndActive;
var
  LSource, LCopy: THelpChatSettings;
begin
  LSource := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    with LSource.Models.Add do
    begin
      Name := 'Claude';
      Provider := 'claude';
      Model := 'claude-haiku-4-5';
    end;
    with LSource.Models.Add do
    begin
      Name := 'Gemma (locale)';
      Provider := 'openai';
      Model := 'gemma4:12b';
      BaseUrl := 'http://localhost:11434/v1';
      ApiKey := 'none';
      Icon := 'gemma';
    end;
    LSource.SelectedModel := 'Gemma (locale)';

    LCopy.LoadFromJSON(LSource.SaveToJSON);

    Assert.AreEqual(2, LCopy.Models.Count);
    Assert.AreEqual('Claude', LCopy.Models[0].Name);
    Assert.AreEqual('claude', LCopy.Models[0].Provider);
    Assert.AreEqual('claude-haiku-4-5', LCopy.Models[0].Model);
    Assert.AreEqual('Gemma (locale)', LCopy.Models[1].Name);
    Assert.AreEqual('openai', LCopy.Models[1].Provider);
    Assert.AreEqual('gemma4:12b', LCopy.Models[1].Model);
    Assert.AreEqual('http://localhost:11434/v1', LCopy.Models[1].BaseUrl);
    Assert.AreEqual('none', LCopy.Models[1].ApiKey);
    Assert.AreEqual('gemma', LCopy.Models[1].Icon);
    Assert.AreEqual('Gemma (locale)', LCopy.SelectedModel);
    Assert.AreEqual('Gemma (locale)', LCopy.ActiveModelName);
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TModelsTests.Settings_LoadJson_ListReplacesWhole;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"Models":[{"Name":"A","Provider":"claude"},' +
      '{"Name":"B","Provider":"gemini"}]}');
    Assert.AreEqual(2, LSettings.Models.Count);
    // A later file with its own list is the list; one without leaves it.
    LSettings.LoadFromJSON('{"Models":[{"Provider":"openai","Model":"gpt-x"}]}');
    Assert.AreEqual(1, LSettings.Models.Count);
    Assert.AreEqual('OpenAI gpt-x', LSettings.Models[0].Name, 'a nameless one is called by what it runs');
    LSettings.LoadFromJSON('{"Provider":"claude"}');
    Assert.AreEqual(1, LSettings.Models.Count);
    Assert.AreEqual('OpenAI gpt-x', LSettings.ActiveModelName,
      'Assistant empty: the first of the list');
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Settings_Apply_OverridesTheSection_AndIsReversible;
var
  LSettings: THelpChatSettings;
  LList: TArray<THelpChatModelInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    LSettings.Claude.Model := 'claude-configured';
    LSettings.OpenAI.ApiKey := 'sk-configured';
    with LSettings.Models.Add do
    begin
      Name := 'Anthropic';
      Provider := 'claude';
      Model := 'claude-other';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Local';
      Provider := 'openai';
      Model := 'gemma4:12b';
      BaseUrl := 'http://localhost:11434/v1/';
      ApiKey := 'ollama';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Cloud';
      Provider := 'openai';   // no model, no endpoint: the section's own
    end;

    Assert.IsTrue(LSettings.ApplyModel('local'));
    Assert.AreEqual('openai', LSettings.Provider);
    Assert.AreEqual('Local', LSettings.SelectedModel);
    Assert.AreEqual('gemma4:12b', LSettings.OpenAI.ResolveModel);
    Assert.AreEqual('http://localhost:11434/v1', LSettings.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual('ollama', LSettings.OpenAI.ResolveApiKey);
    Assert.AreEqual('', LSettings.OpenAI.Model, 'the configuration is not rewritten');
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LSettings.OpenAI.ConfiguredModel);

    Assert.IsTrue(LSettings.ApplyModel('Cloud'));
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LSettings.OpenAI.ResolveModel, 'the override is gone');
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_BASEURL, LSettings.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual('sk-configured', LSettings.OpenAI.ResolveApiKey);

    Assert.IsTrue(LSettings.ApplyModel('Anthropic'));
    Assert.AreEqual('claude', LSettings.Provider);
    Assert.AreEqual('claude-other', LSettings.Claude.ResolveModel);
    Assert.AreEqual('claude-configured', LSettings.Claude.ConfiguredModel);

    // The list describes each one on its own, whatever is applied.
    LList := LSettings.ResolveModels;
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

procedure TModelsTests.Settings_Apply_NoProviderOfItsOwn_IsTheConfiguredOne;
var
  LSettings: THelpChatSettings;
  LList: TArray<THelpChatModelInfo>;
begin
  // A model that names no provider runs on the configured one - also after
  // the user went through a model of another provider and came back.
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    with LSettings.Models.Add do
    begin
      Name := 'Default';
      Model := 'claude-other';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Local';
      Provider := 'openai';
      Model := 'gemma4';
    end;
    Assert.IsTrue(LSettings.ApplyModel('Local'));
    Assert.AreEqual('openai', LSettings.Provider);
    LList := LSettings.ResolveModels;
    Assert.AreEqual('claude', LList[0].Provider,
      'the list describes each model on its own, whichever is in use');
    Assert.IsTrue(LSettings.ApplyModel('Default'));
    Assert.AreEqual('claude', LSettings.Provider, 'back to the configured provider');
    Assert.AreEqual('claude-other', LSettings.Claude.ResolveModel);
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Settings_Apply_UnknownName_ChangesNothing;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'claude';
    with LSettings.Models.Add do
    begin
      Name := 'A';
      Provider := 'gemini';
    end;
    Assert.IsFalse(LSettings.ApplyModel('B'));
    Assert.AreEqual('claude', LSettings.Provider);
    Assert.AreEqual('', LSettings.SelectedModel);
    Assert.AreEqual('A', LSettings.ActiveModelName, 'the first of the list, until one is applied');
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Settings_Assign_CarriesTheOverrides;
var
  LSettings, LCopy: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    with LSettings.Models.Add do
    begin
      Name := 'Local';
      Provider := 'openai';
      Model := 'qwen3-coder:30b';
      BaseUrl := 'http://localhost:11434/v1';
    end;
    LSettings.ApplyModel('Local');
    // What a request works on is a snapshot: it must see the same model.
    LCopy.Assign(LSettings);
    Assert.AreEqual('openai', LCopy.Provider);
    Assert.AreEqual('qwen3-coder:30b', LCopy.OpenAI.ResolveModel);
    Assert.AreEqual('http://localhost:11434/v1', LCopy.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual(1, LCopy.Models.Count);
    Assert.AreEqual('Local', LCopy.SelectedModel);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TModelsTests.Icons_ModelFirst_ThenEndpoint_ThenProvider;
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

procedure TModelsTests.Icons_EveryShippedIdHasAnSvg_WithoutTitle;
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

procedure TModelsTests.Flags_EveryLanguageHasOne;
var
  L: THelpChatLanguage;
  LSvg: string;
begin
  for L in HELPCHAT_ALL_LANGUAGES do
  begin
    LSvg := HelpChatFlagSvg(HelpChatLanguageCode(L));
    Assert.IsTrue(LSvg.StartsWith('<svg'), HelpChatLanguageName(L));
    Assert.IsTrue(LSvg.TrimRight.EndsWith('</svg>'), HelpChatLanguageName(L));
  end;
  Assert.AreEqual('', HelpChatFlagSvg('xx'));
  Assert.AreEqual('', HelpChatFlagSvg('auto'), 'not two letters');
  Assert.AreEqual('', HelpChatFlagSvg('../'), 'the code becomes a resource name');
end;

procedure TModelsTests.Engine_Select_ChangesTheNextRequest;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LResult: THelpChatSendResult;
  LMessage: THelpChatMessage;
  LList: TArray<THelpChatModelInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    with LSettings.Models.Add do
    begin
      Name := 'Echo';
      Provider := TEST_PROVIDER_ECHO;
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Broken';
      Provider := TEST_PROVIDER_FAIL;
    end;
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual(TEST_PROVIDER_ECHO, LSettings.Provider, 'Start applies the first of the list');
      Assert.IsTrue(LEngine.CanSelectModel);
      LList := LEngine.Models;
      Assert.AreEqual(2, Length(LList));
      Assert.AreEqual('', LList[0].Icon, 'a test provider has no icon');

      LResult := LEngine.Send('hello');
      Assert.IsTrue(WaitFor(function: Boolean
        begin
          Result := LEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage) and not LMessage.Pending;
        end));
      Assert.IsTrue(LMessage.Content.StartsWith('echo:'), LMessage.Content);

      Assert.IsTrue(LEngine.SelectModel('Broken'));
      Assert.AreEqual('Broken', LEngine.ActiveModelInfo.Name);
      LResult := LEngine.Send('hello again');
      Assert.IsTrue(WaitFor(function: Boolean
        begin
          Result := LEngine.TryGetMessage(LResult.AssistantMessage.Id, LMessage) and not LMessage.Pending;
        end));
      Assert.IsTrue(LMessage.IsError, 'the failing provider answered this one');

      Assert.IsFalse(LEngine.SelectModel('Nobody'));
      Assert.AreEqual('Broken', LEngine.ActiveModelInfo.Name);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Engine_Models_OnlyTheOnesThatCanAnswer;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LList: TArray<THelpChatModelInfo>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    with LSettings.Models.Add do
    begin
      Name := 'Echo';
      Provider := TEST_PROVIDER_ECHO;
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Locked';
      Provider := TEST_PROVIDER_UNCONFIGURED;
    end;
    Assert.IsTrue(HelpChatModelIsConfigured(LSettings, 'Echo'));
    Assert.IsFalse(HelpChatModelIsConfigured(LSettings, 'Locked'));
    Assert.IsFalse(HelpChatModelIsConfigured(LSettings, 'Nobody'));
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      LList := LEngine.Models;
      Assert.AreEqual(1, Length(LList), 'a model that cannot answer is no choice');
      Assert.AreEqual('Echo', LList[0].Name);
      // Code may still pick it (the application then asks for its key), and
      // the one in use is always listed: the panel shows what answers.
      Assert.IsTrue(LEngine.SelectModel('Locked'));
      LList := LEngine.Models;
      Assert.AreEqual(2, Length(LList));
      Assert.AreEqual('Locked', LEngine.ActiveModelInfo.Name);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Engine_Models_AKeyInAFile_OffersItsModel;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LList: TArray<THelpChatModelInfo>;
  LNames: string;
  LInfo: THelpChatModelInfo;
begin
  // The CRM demo: a catalogue of the three services in the form file, the
  // per-user file carrying two encrypted keys and nothing else.
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.Provider := 'claude';
    with LSettings.Models.Add do
    begin
      Name := 'Claude';
      Provider := 'claude';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Gemini';
      Provider := 'gemini';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'OpenAI';
      Provider := 'openai';
    end;
    LSettings.LoadFromJSON('{"Claude": {"ApiKeyEncrypted": "enc:one"}, ' +
      '"Gemini": {"ApiKeyEncrypted": "enc:two"}}');
    Assert.AreEqual(3, LSettings.Models.Count, 'a file without Models keeps the list');
    Assert.IsTrue(HelpChatModelIsConfigured(LSettings, 'Gemini'), 'settings');
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      LList := LEngine.Models;
      LNames := '';
      for LInfo in LList do
        LNames := LNames + LInfo.Name + ' ';
      Assert.IsTrue(Pos('Claude ', LNames) > 0, LNames);
      Assert.IsTrue(Pos('Gemini ', LNames) > 0, LNames);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Engine_Start_SkipsAModelThatCannotAnswer;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    with LSettings.Models.Add do
    begin
      Name := 'Locked';
      Provider := TEST_PROVIDER_UNCONFIGURED;
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Echo';
      Provider := TEST_PROVIDER_ECHO;
    end;
    LSettings.SelectedModel := 'Locked';
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual('Echo', LEngine.ActiveModelInfo.Name,
        'the first that can answer, not the one named');
    finally
      LEngine.Free;
    end;
    // With none that can answer, the one named stays: its first answer says
    // what is missing.
    LSettings.Models.Delete(1);
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual('Locked', LEngine.ActiveModelInfo.Name);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Engine_Start_AppliesTheConfiguredOne;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.PersistConversation := False;
    LSettings.DocIndexFile := 'Z:\no\index.json';
    LSettings.Provider := 'claude';   // what the list says wins over this
    with LSettings.Models.Add do
    begin
      Name := 'Echo';
      Provider := TEST_PROVIDER_ECHO;
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Slow';
      Provider := TEST_PROVIDER_SLOW;
    end;
    LSettings.SelectedModel := 'Slow';
    LEngine := THelpChatEngine.Create(LSettings);
    try
      LEngine.Start;
      Assert.AreEqual(TEST_PROVIDER_SLOW, LSettings.Provider);
      Assert.AreEqual('Slow', LEngine.ActiveModelInfo.Name);
      Assert.IsTrue(LEngine.ActiveModelInfo.Active);
    finally
      LEngine.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TModelsTests.Settings_KeyOfTheSection_NeverGoesToAnotherHost;
var
  LSettings: THelpChatSettings;
  LSaved: string;
begin
  // A model served by another host and with no key of its own must not be
  // sent the key of api.openai.com; a path on the same host still is.
  LSettings := THelpChatSettings.Create;
  try
    LSettings.OpenAI.ApiKey := 'sk-openai';
    with LSettings.Models.Add do
    begin
      Name := 'Lan';
      Provider := 'openai';
      BaseUrl := 'http://192.168.1.20:11434/v1';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'SameHost';
      Provider := 'openai';
      BaseUrl := HELPCHAT_OPENAI_DEF_BASEURL + '/v1/';
    end;
    with LSettings.Models.Add do
    begin
      Name := 'Groq';
      Provider := 'openai';
      BaseUrl := 'https://api.groq.com/openai/v1';
      ApiKey := 'gsk-own';
    end;
    Assert.IsTrue(LSettings.ApplyModel('Lan'));
    Assert.AreEqual('', LSettings.OpenAI.ResolveApiKey, 'another host, no key of its own');
    Assert.IsTrue(LSettings.ApplyModel('SameHost'));
    Assert.AreEqual('sk-openai', LSettings.OpenAI.ResolveApiKey, 'the same service');
    Assert.IsTrue(LSettings.ApplyModel('Groq'));
    Assert.AreEqual('gsk-own', LSettings.OpenAI.ResolveApiKey);

    // The same for the environment variable, which is named after the
    // service: a section pointed at another server does not get it.
    LSaved := GetEnvironmentVariable(HELPCHAT_OPENAI_APIKEY_ENVVAR);
    SetEnvironmentVariable(PChar(HELPCHAT_OPENAI_APIKEY_ENVVAR), 'sk-env');
    try
      LSettings.SelectedModel := '';
      LSettings.Models.Clear;
      LSettings.OpenAI.ClearOverrides;   // what the model in use had brought
      LSettings.Provider := 'openai';
      LSettings.OpenAI.ApiKey := '';
      Assert.AreEqual('sk-env', LSettings.OpenAI.ResolveApiKey, 'the service itself');
      LSettings.OpenAI.BaseUrl := 'http://localhost:11434/v1';
      Assert.AreEqual('', LSettings.OpenAI.ResolveApiKey, 'not to a server that is not OpenAI');
      LSettings.OpenAI.ApiKey := 'own';
      Assert.AreEqual('own', LSettings.OpenAI.ResolveApiKey, 'the key written for it still is');
    finally
      if LSaved = '' then
        SetEnvironmentVariable(PChar(HELPCHAT_OPENAI_APIKEY_ENVVAR), nil)
      else
        SetEnvironmentVariable(PChar(HELPCHAT_OPENAI_APIKEY_ENVVAR), PChar(LSaved));
    end;
  finally
    LSettings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TModelsTests);

end.
