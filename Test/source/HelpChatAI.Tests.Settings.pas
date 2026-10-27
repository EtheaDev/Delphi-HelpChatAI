unit HelpChatAI.Tests.Settings;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Settings;

type
  [TestFixture]
  TSettingsTests = class
  public
    [Test] procedure Defaults;
    [Test] procedure Assign_DeepCopiesClaude;
    [Test] procedure ResolveGreeting_UsesLanguage;
    [Test] procedure Claude_NormalizedBaseUrl_StripsSlashes;
    [Test] procedure Claude_ResolveApiKey_TrimsExplicitKey;
    [Test] procedure ResolveConversationFile_DefaultsToAppData;
    [Test] procedure Json_RoundTrip;
    [Test] procedure ActiveModel_FollowsProvider;
    [Test] procedure Model_ResolvesTheDefaultsOfItsProvider;
    [Test] procedure LoadConfiguration_NamedFile_OrTheDefaults;
    [Test] procedure Json_PartialFile_MergesOnlyPresentKeys;
    [Test] procedure Json_LanguageCodes;
    [Test] procedure Json_Malformed_RaisesConfigError;
    [Test] procedure File_Missing_ReturnsFalse_SaveAndLoad;
    [Test] procedure DefaultConfigFiles_Locations;
    [Test] procedure DocPaths_RelativeToTheExecutable;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Tests.Helpers;

procedure TSettingsTests.DocPaths_RelativeToTheExecutable;
var
  LSettings: THelpChatSettings;
  LExeDir: string;
begin
  LExeDir := TPath.GetDirectoryName(ParamStr(0));
  LSettings := THelpChatSettings.Create;
  try
    // Nothing set: the default name, next to the executable.
    Assert.AreEqual(TPath.Combine(LExeDir, HELPCHAT_DEF_DOCINDEX_FILENAME),
      LSettings.ResolveDocIndexFile);

    // A relative path is relative to the executable, never to the current
    // directory: a shortcut, the IDE and Explorer set three different ones,
    // and the index would be found by accident. Same rule as DocFolder, and
    // what the documentation has always promised.
    LSettings.DocIndexFile := '..\Help\help-index.json';
    LSettings.DocFolder := '..\Help';
    Assert.AreEqual(
      ExpandFileName(TPath.Combine(LExeDir, '..\Help\help-index.json')),
      LSettings.ResolveDocIndexFile);
    Assert.AreEqual(ExpandFileName(TPath.Combine(LExeDir, '..\Help')),
      LSettings.ResolveDocFolder);

    // An absolute one is left alone.
    LSettings.DocIndexFile := 'C:\somewhere\index.json';
    Assert.AreEqual('C:\somewhere\index.json', LSettings.ResolveDocIndexFile);
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Defaults;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    Assert.AreEqual(HELPCHAT_DEF_PROVIDER, LSettings.Provider);
    Assert.AreEqual(HELPCHAT_DEF_POOLSIZE, LSettings.PoolSize);
    Assert.AreEqual(HELPCHAT_DEF_MSGMAXLEN, LSettings.MessageMaxLength);
    Assert.AreEqual(HELPCHAT_DEF_HISTMAXMSG, LSettings.HistoryMaxMessages);
    Assert.AreEqual(HELPCHAT_DEF_STOREDMAXMSG, LSettings.MaxStoredMessages);
    Assert.AreEqual(hclAuto, LSettings.Language);
    Assert.IsTrue(LSettings.PersistConversation);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_MODEL, LSettings.Claude.Model);
    Assert.IsFalse(LSettings.Remote.IsConfigured, 'the engine runs in process by default');
    Assert.IsTrue(LSettings.Remote.UseHostChannel);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_MAXTOKENS, LSettings.Claude.MaxTokens);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_GROUNDING, LSettings.Claude.GroundingMaxPages);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_BASEURL, LSettings.Claude.BaseUrl);
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_VERSION, LSettings.Claude.ApiVersion);
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Assign_DeepCopiesClaude;
var
  LSource, LCopy: THelpChatSettings;
begin
  LSource := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSource.Provider := 'claude';
    LSource.Language := hclItalian;
    LSource.Claude.ApiKey := 'k';
    LSource.Claude.Model := 'm';
    LCopy.Assign(LSource);
    Assert.AreEqual('claude', LCopy.Provider);
    Assert.AreEqual(hclItalian, LCopy.Language);
    Assert.AreEqual('k', LCopy.Claude.ApiKey);
    Assert.AreEqual('m', LCopy.Claude.Model);
    Assert.AreNotSame(LSource.Claude, LCopy.Claude);
    // Changing the source afterwards must not touch the copy.
    LSource.Claude.Model := 'other';
    Assert.AreEqual('m', LCopy.Claude.Model);
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TSettingsTests.ResolveGreeting_UsesLanguage;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclItalian;
    Assert.StartsWith('Ciao!', LSettings.ResolveGreeting);
    LSettings.Language := hclEnglish;
    Assert.StartsWith('Hi!', LSettings.ResolveGreeting);
    LSettings.Greeting := '  Welcome  ';
    Assert.AreEqual('Welcome', LSettings.ResolveGreeting);
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Claude_NormalizedBaseUrl_StripsSlashes;
var
  LClaude: THelpChatClaudeSettings;
begin
  LClaude := THelpChatClaudeSettings.Create;
  try
    LClaude.BaseUrl := 'https://proxy.local/anthropic//';
    Assert.AreEqual('https://proxy.local/anthropic', LClaude.NormalizedBaseUrl);
    LClaude.BaseUrl := '';
    Assert.AreEqual(HELPCHAT_CLAUDE_DEF_BASEURL, LClaude.NormalizedBaseUrl);
  finally
    LClaude.Free;
  end;
end;

procedure TSettingsTests.Claude_ResolveApiKey_TrimsExplicitKey;
var
  LClaude: THelpChatClaudeSettings;
begin
  LClaude := THelpChatClaudeSettings.Create;
  try
    LClaude.ApiKey := '  sk-test  ';
    Assert.AreEqual('sk-test', LClaude.ResolveApiKey);
  finally
    LClaude.Free;
  end;
end;

procedure TSettingsTests.ResolveConversationFile_DefaultsToAppData;
var
  LSettings: THelpChatSettings;
  LFile: string;
begin
  LSettings := THelpChatSettings.Create;
  try
    LFile := LSettings.ResolveConversationFile;
    Assert.EndsWith(HELPCHAT_DEF_CONVERSATION_FILENAME, LFile);
    Assert.IsTrue(TDirectory.Exists(TPath.GetDirectoryName(LFile)), 'app data folder must exist');
    LSettings.ConversationFile := 'C:\x\y.json';
    Assert.AreEqual('C:\x\y.json', LSettings.ResolveConversationFile);
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Json_RoundTrip;
var
  LSource, LCopy: THelpChatSettings;
begin
  LSource := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSource.Provider := 'claude';
    LSource.Language := hclItalian;
    LSource.Greeting := 'Ciao "tu"';
    LSource.DocIndexFile := 'C:\docs\index.json';
    LSource.DocBaseUrl := 'https://docs.example.com/';
    LSource.DocFolder := 'C:\docs\pages';
    LSource.PoolSize := 3;
    LSource.MessageMaxLength := 123;
    LSource.HistoryMaxMessages := 7;
    LSource.MaxStoredMessages := 99;
    LSource.PersistConversation := False;
    LSource.ConversationFile := 'conv.json';
    LSource.ConversationMaxAgeDays := 5;
    LSource.Claude.ApiKey := 'sk-ant-test';
    LSource.Claude.Model := 'claude-x';
    LSource.Claude.MaxTokens := 555;
    LSource.Claude.GroundingMaxPages := 1;
    LSource.Claude.GroundingMaxChars := 1234;
    LSource.Claude.SystemPrompt := 'Sei Bob.';
    LSource.Claude.BaseUrl := 'https://proxy/';
    LSource.Claude.ApiVersion := '2099-01-01';
    LSource.Claude.ConnectTimeoutMs := 11;
    LSource.Claude.ResponseTimeoutMs := 22;
    LSource.OpenAI.ApiKey := 'sk-openai-test';
    LSource.OpenAI.Model := 'gpt-x';
    LSource.OpenAI.BaseUrl := 'https://groq.example.com/openai/v1';
    LSource.OpenAI.Organization := 'org-1';
    LSource.OpenAI.AzureDeployment := 'my-deployment';
    LSource.OpenAI.AzureApiVersion := '2099-02-02';
    LSource.OpenAI.MaxToolRounds := 9;
    LSource.Gemini.ApiKey := 'g-test';
    LSource.Gemini.Model := 'gemini-x';
    LSource.Gemini.BaseUrl := 'https://gemini.example.com';
    LSource.Gemini.GroundingMaxPages := 2;
    LSource.Remote.BaseUrl := 'https://help.example.com';
    LSource.Remote.AppKey := 'app-key-1';
    LSource.Remote.UserId := 'bob';
    LSource.Remote.UserToken := 'u-token';
    LSource.Remote.UseHostChannel := False;
    LSource.Remote.TimeoutMs := 1500;

    LCopy.LoadFromJSON(LSource.SaveToJSON);

    Assert.AreEqual('claude', LCopy.Provider);
    Assert.AreEqual(hclItalian, LCopy.Language);
    Assert.AreEqual('Ciao "tu"', LCopy.Greeting);
    Assert.AreEqual('C:\docs\index.json', LCopy.DocIndexFile);
    Assert.AreEqual('https://docs.example.com/', LCopy.DocBaseUrl);
    Assert.AreEqual('C:\docs\pages', LCopy.DocFolder);
    Assert.AreEqual(3, LCopy.PoolSize);
    Assert.AreEqual(123, LCopy.MessageMaxLength);
    Assert.AreEqual(7, LCopy.HistoryMaxMessages);
    Assert.AreEqual(99, LCopy.MaxStoredMessages);
    Assert.IsFalse(LCopy.PersistConversation);
    Assert.AreEqual('conv.json', LCopy.ConversationFile);
    Assert.AreEqual(5, LCopy.ConversationMaxAgeDays);
    Assert.AreEqual('sk-ant-test', LCopy.Claude.ApiKey);
    Assert.AreEqual('claude-x', LCopy.Claude.Model);
    Assert.AreEqual(555, LCopy.Claude.MaxTokens);
    Assert.AreEqual(1, LCopy.Claude.GroundingMaxPages);
    Assert.AreEqual(1234, LCopy.Claude.GroundingMaxChars);
    Assert.AreEqual('Sei Bob.', LCopy.Claude.SystemPrompt);
    Assert.AreEqual('https://proxy/', LCopy.Claude.BaseUrl);
    Assert.AreEqual('2099-01-01', LCopy.Claude.ApiVersion);
    Assert.AreEqual(11, LCopy.Claude.ConnectTimeoutMs);
    Assert.AreEqual(22, LCopy.Claude.ResponseTimeoutMs);
    Assert.AreEqual('sk-openai-test', LCopy.OpenAI.ApiKey);
    Assert.AreEqual('gpt-x', LCopy.OpenAI.Model);
    Assert.AreEqual('https://groq.example.com/openai/v1', LCopy.OpenAI.BaseUrl);
    Assert.AreEqual('org-1', LCopy.OpenAI.Organization);
    Assert.AreEqual('my-deployment', LCopy.OpenAI.AzureDeployment);
    Assert.AreEqual('2099-02-02', LCopy.OpenAI.AzureApiVersion);
    Assert.AreEqual(9, LCopy.OpenAI.MaxToolRounds);
    Assert.IsTrue(LCopy.OpenAI.IsAzure, 'a deployment is what makes it Azure');
    Assert.AreEqual('g-test', LCopy.Gemini.ApiKey);
    Assert.AreEqual('gemini-x', LCopy.Gemini.Model);
    Assert.AreEqual('https://gemini.example.com', LCopy.Gemini.BaseUrl);
    Assert.AreEqual(2, LCopy.Gemini.GroundingMaxPages);
    Assert.AreEqual('https://help.example.com', LCopy.Remote.BaseUrl);
    Assert.AreEqual('app-key-1', LCopy.Remote.AppKey);
    Assert.AreEqual('bob', LCopy.Remote.UserId);
    Assert.AreEqual('u-token', LCopy.Remote.UserToken);
    Assert.IsFalse(LCopy.Remote.UseHostChannel);
    Assert.AreEqual(1500, LCopy.Remote.TimeoutMs);
    Assert.IsTrue(LCopy.Remote.IsConfigured);
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TSettingsTests.Json_PartialFile_MergesOnlyPresentKeys;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'docsearch';
    LSettings.Claude.Model := 'keep-me';
    // The typical user file: just the key (keys are case-insensitive).
    LSettings.LoadFromJSON('{ "claude": { "apikey": "sk-user" }, "PoolSize": "4" }');
    Assert.AreEqual('sk-user', LSettings.Claude.ApiKey);
    Assert.AreEqual('keep-me', LSettings.Claude.Model, 'untouched');
    Assert.AreEqual('docsearch', LSettings.Provider, 'untouched');
    Assert.AreEqual(4, LSettings.PoolSize, 'numbers as strings are accepted');
    LSettings.LoadFromJSON('{}');
    Assert.AreEqual('sk-user', LSettings.Claude.ApiKey, 'an empty object changes nothing');
    LSettings.LoadFromJSON('{ "Claude": { "ApiKey": null } }');
    Assert.AreEqual('sk-user', LSettings.Claude.ApiKey, 'null keeps the value');
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Json_LanguageCodes;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"Language":"it"}');
    Assert.AreEqual(hclItalian, LSettings.Language);
    LSettings.LoadFromJSON('{"Language":"EN"}');
    Assert.AreEqual(hclEnglish, LSettings.Language);
    LSettings.LoadFromJSON('{"Language":"auto"}');
    Assert.AreEqual(hclAuto, LSettings.Language);
    LSettings.Language := hclItalian;
    LSettings.LoadFromJSON('{"Language":"klingon"}');
    Assert.AreEqual(hclItalian, LSettings.Language, 'unknown code keeps the value');
    Assert.Contains(LSettings.SaveToJSON, '"Language": "it"');
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Json_Malformed_RaisesConfigError;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadFromJSON('{ not json');
      end, EHelpChatConfigError);
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadFromJSON('[1,2]');
      end, EHelpChatConfigError);
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.File_Missing_ReturnsFalse_SaveAndLoad;
var
  LSettings, LCopy: THelpChatSettings;
  LFile: string;
begin
  LFile := TempFileName;
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    Assert.IsFalse(LSettings.LoadFromFile(LFile));
    Assert.IsFalse(LSettings.LoadFromFile(''));
    LSettings.Claude.ApiKey := 'sk-file';
    LSettings.Provider := 'claude';
    LSettings.SaveToFile(LFile);
    Assert.IsTrue(TFile.Exists(LFile));
    Assert.IsTrue(LCopy.LoadFromFile(LFile));
    Assert.AreEqual('sk-file', LCopy.Claude.ApiKey);
    Assert.AreEqual('claude', LCopy.Provider);
    TFile.WriteAllText(LFile, 'garbage');
    Assert.WillRaise(
      procedure
      begin
        LCopy.LoadFromFile(LFile);
      end, EHelpChatConfigError);
  finally
    LCopy.Free;
    LSettings.Free;
    if TFile.Exists(LFile) then
      TFile.Delete(LFile);
  end;
end;

procedure TSettingsTests.DefaultConfigFiles_Locations;
begin
  Assert.EndsWith(HELPCHAT_DEF_CONFIG_FILENAME, THelpChatSettings.AppConfigFile);
  Assert.AreEqual(TPath.GetDirectoryName(ParamStr(0)),
    TPath.GetDirectoryName(THelpChatSettings.AppConfigFile));
  Assert.EndsWith(HELPCHAT_DEF_CONFIG_FILENAME, THelpChatSettings.UserConfigFile);
  Assert.AreEqual(HelpChatAppDataFolder, TPath.GetDirectoryName(THelpChatSettings.UserConfigFile));
  Assert.EndsWith('\HelpChatAI\' + HELPCHAT_DEF_CONFIG_FILENAME, THelpChatSettings.SharedUserConfigFile);
  Assert.AreNotEqual(THelpChatSettings.SharedUserConfigFile, THelpChatSettings.UserConfigFile,
    'the shared file is not the per-application one (the test exe is not named HelpChat)');
end;

procedure TSettingsTests.ActiveModel_FollowsProvider;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Provider := 'openai';
    Assert.AreSame(LSettings.OpenAI, LSettings.ActiveModel);
    LSettings.Provider := 'GEMINI';
    Assert.AreSame(LSettings.Gemini, LSettings.ActiveModel, 'the name is case insensitive');
    LSettings.Provider := 'claude';
    Assert.AreSame(LSettings.Claude, LSettings.ActiveModel);
    // A provider with no model of its own still has to answer: whoever asks
    // for grounding or timeouts must not get nil.
    LSettings.Provider := 'docsearch';
    Assert.IsNull(LSettings.ModelFor('docsearch'));
    Assert.AreSame(LSettings.Claude, LSettings.ActiveModel);
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.Model_ResolvesTheDefaultsOfItsProvider;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    // Left empty, each section answers with the endpoint and the model of its
    // own service, so a configuration file that mentions neither keeps
    // following the library.
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_MODEL, LSettings.OpenAI.ResolveModel);
    Assert.AreEqual(HELPCHAT_OPENAI_DEF_BASEURL, LSettings.OpenAI.NormalizedBaseUrl);
    Assert.AreEqual(HELPCHAT_GEMINI_DEF_MODEL, LSettings.Gemini.ResolveModel);
    Assert.AreEqual(HELPCHAT_GEMINI_DEF_BASEURL, LSettings.Gemini.NormalizedBaseUrl);
    Assert.AreEqual('OpenAI', THelpChatOpenAISettings.SectionName);
    Assert.AreEqual(HELPCHAT_OPENAI_APIKEY_ENVVAR, THelpChatOpenAISettings.ApiKeyEnvVar);
    // The shared default of the prompt is the same text for everybody.
    Assert.AreEqual(LSettings.Claude.ResolveSystemPrompt, LSettings.Gemini.ResolveSystemPrompt);
    LSettings.Gemini.MaxToolRounds := 0;
    Assert.AreEqual(1, LSettings.Gemini.ResolveMaxToolRounds, 'never below one round');
  finally
    LSettings.Free;
  end;
end;

procedure TSettingsTests.LoadConfiguration_NamedFile_OrTheDefaults;
var
  LSettings: THelpChatSettings;
  LFile: string;
  LRead: TArray<string>;
begin
  LFile := TempFileName('.json');
  TFile.WriteAllText(LFile, '{ "Provider": "gemini", "Greeting": "Ehi" }', TEncoding.UTF8);
  LSettings := THelpChatSettings.Create;
  try
    // Named: that file, and the defaults are not consulted at all.
    LRead := LSettings.LoadConfiguration(LFile);
    Assert.AreEqual(1, Length(LRead));
    Assert.AreEqual(LFile, LRead[0]);
    Assert.AreEqual('gemini', LSettings.Provider);
    Assert.AreEqual('Ehi', LSettings.Greeting);
    // Named but absent: an error, not a silent fallback to the defaults.
    Assert.WillRaise(
      procedure
      begin
        LSettings.LoadConfiguration(LFile + '.missing');
      end, EHelpChatConfigError);
    // Empty: the three defaults, each if present, and no complaint when none is.
    LRead := LSettings.LoadConfiguration('');
    Assert.IsTrue(Length(LRead) >= 0);
  finally
    LSettings.Free;
    TFile.Delete(LFile);
  end;
end;

end.
