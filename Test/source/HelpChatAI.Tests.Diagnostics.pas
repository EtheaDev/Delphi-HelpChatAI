unit HelpChatAI.Tests.Diagnostics;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Diagnostics;

type
  [TestFixture]
  TDiagnosticsTests = class
  strict private
    FSettings: THelpChatSettings;
    /// <summary>The finding about ATopic, or an empty one.</summary>
    function Find(const AIssues: THelpChatIssues; const ATopic: string): THelpChatIssue;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure EmptyProvider_IsAWarning_NotAnError;
    [Test] procedure UnknownProvider_IsAnError_ListingTheRegisteredOnes;
    [Test] procedure DocSearch_WithoutIndex_IsAnError;
    [Test] procedure MissingIndex_IsReportedOnce_NotTwice;
    [Test] procedure DocSearch_WithIndex_HasNoErrors;
    [Test] procedure Claude_WithoutKey_IsAnError;
    [Test] procedure Claude_WithKey_HasNoErrors;
    [Test] procedure MissingDocFolder_IsAnError;
    [Test] procedure Remote_SkipsTheLocalChecks;
    [Test] procedure Remote_NonHttpBaseUrl_IsAnError;
    [Test] procedure ExpandPaths_MakesThemAbsoluteAgainstTheFolder;
    [Test] procedure ExpandPaths_EmptyIndexFile_BecomesTheDefaultOfTheFolder;
    [Test] procedure SettingsForFolder_IsACopy_WithThePathsExpanded;
    [Test] procedure SettingsForFolder_NamedFile_IsTheOnlyOneRead;
    [Test] procedure IssuesToText_PutsErrorsFirst;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  HelpChatAI.Provider,
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Tests.Helpers;

{ TDiagnosticsTests }

procedure TDiagnosticsTests.Setup;
begin
  FSettings := THelpChatSettings.Create;
  // Absolute paths everywhere: the resolution against the folder of the
  // executable is what the Expand tests are for.
  FSettings.DocIndexFile := TestDataFile('help-index.json');
end;

procedure TDiagnosticsTests.TearDown;
begin
  FreeAndNil(FSettings);
end;

function TDiagnosticsTests.Find(const AIssues: THelpChatIssues;
  const ATopic: string): THelpChatIssue;
var
  LIssue: THelpChatIssue;
begin
  Result := Default(THelpChatIssue);
  for LIssue in AIssues do
    if LIssue.Topic.StartsWith(ATopic, True) then
      Exit(LIssue);
end;

procedure TDiagnosticsTests.EmptyProvider_IsAWarning_NotAnError;
var
  LIssues: THelpChatIssues;
begin
  FSettings.Provider := '';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsFalse(HelpChatHasErrors(LIssues), 'the stub answers, it just answers nothing useful');
  Assert.AreEqual(Ord(hikWarning), Ord(Find(LIssues, 'Provider').Kind));
  Assert.Contains(Find(LIssues, 'Provider').Text, 'stub');
end;

procedure TDiagnosticsTests.UnknownProvider_IsAnError_ListingTheRegisteredOnes;
var
  LIssues: THelpChatIssues;
  LText: string;
begin
  FSettings.Provider := 'typo';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsTrue(HelpChatHasErrors(LIssues));
  LText := Find(LIssues, 'Provider').Text;
  Assert.Contains(LText, '"typo"');
  Assert.Contains(LText, HELPCHAT_PROVIDER_STUB, 'names what is available');
  Assert.Contains(LText, HELPCHAT_PROVIDER_CLAUDE);
end;

procedure TDiagnosticsTests.DocSearch_WithoutIndex_IsAnError;
var
  LIssues: THelpChatIssues;
begin
  FSettings.Provider := HELPCHAT_PROVIDER_DOCSEARCH;
  FSettings.DocIndexFile := TPath.Combine(TPath.GetTempPath, 'helpchat-no-such-index.json');
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsTrue(HelpChatHasErrors(LIssues), 'docsearch has nothing but the index');
  Assert.Contains(Find(LIssues, 'Provider "docsearch"').Text, 'helpchat-no-such-index.json');
end;

procedure TDiagnosticsTests.DocSearch_WithIndex_HasNoErrors;
var
  LIssues: THelpChatIssues;
begin
  FSettings.Provider := HELPCHAT_PROVIDER_DOCSEARCH;
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsFalse(HelpChatHasErrors(LIssues), HelpChatIssuesToText(LIssues));
  Assert.AreEqual(Ord(hikInfo), Ord(Find(LIssues, 'Documentation index').Kind));
end;

procedure TDiagnosticsTests.Claude_WithoutKey_IsAnError;
var
  LIssues: THelpChatIssues;
begin
  // The key may legitimately be in the environment of whoever runs the suite:
  // then there is no "without key" to test.
  if GetEnvironmentVariable(HELPCHAT_CLAUDE_APIKEY_ENVVAR) <> '' then
    Assert.Pass(HELPCHAT_CLAUDE_APIKEY_ENVVAR + ' is set: no missing key to check');
  FSettings.Provider := HELPCHAT_PROVIDER_CLAUDE;
  FSettings.Claude.ApiKey := '';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsTrue(HelpChatHasErrors(LIssues));
  Assert.Contains(Find(LIssues, 'Provider "claude"').Text, HELPCHAT_CLAUDE_APIKEY_ENVVAR);
end;

procedure TDiagnosticsTests.Claude_WithKey_HasNoErrors;
var
  LIssues: THelpChatIssues;
begin
  FSettings.Provider := HELPCHAT_PROVIDER_CLAUDE;
  FSettings.Claude.ApiKey := 'sk-ant-not-a-real-key';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsFalse(HelpChatHasErrors(LIssues), HelpChatIssuesToText(LIssues));
end;

procedure TDiagnosticsTests.MissingDocFolder_IsAnError;
var
  LIssues: THelpChatIssues;
begin
  FSettings.Provider := HELPCHAT_PROVIDER_DOCSEARCH;
  FSettings.DocFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-no-such-folder');
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsTrue(HelpChatHasErrors(LIssues));
  Assert.AreEqual(Ord(hikError), Ord(Find(LIssues, 'Documentation pages').Kind));
end;

procedure TDiagnosticsTests.Remote_SkipsTheLocalChecks;
var
  LIssues: THelpChatIssues;
begin
  // Nothing local matters any more: no provider here, no index here.
  FSettings.Provider := 'typo';
  FSettings.DocIndexFile := '';
  FSettings.Remote.BaseUrl := 'https://help.example.com';
  FSettings.Remote.AppKey := 'app-key';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsFalse(HelpChatHasErrors(LIssues), HelpChatIssuesToText(LIssues));
  Assert.Contains(Find(LIssues, 'Remote server').Text, 'help.example.com');
end;

procedure TDiagnosticsTests.Remote_NonHttpBaseUrl_IsAnError;
var
  LIssues: THelpChatIssues;
begin
  FSettings.Remote.BaseUrl := 'help.example.com';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.IsTrue(HelpChatHasErrors(LIssues));
end;

procedure TDiagnosticsTests.ExpandPaths_MakesThemAbsoluteAgainstTheFolder;
var
  LFolder: string;
begin
  LFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-base');
  FSettings.DocIndexFile := 'help\help-index.json';
  FSettings.DocFolder := 'help';
  FSettings.ConversationFile := 'chat.json';
  HelpChatExpandSettingsPaths(FSettings, LFolder);
  Assert.IsFalse(TPath.IsRelativePath(FSettings.DocIndexFile));
  Assert.IsFalse(TPath.IsRelativePath(FSettings.DocFolder));
  Assert.IsFalse(TPath.IsRelativePath(FSettings.ConversationFile));
  Assert.StartsWith(LFolder, FSettings.DocFolder);
end;

procedure TDiagnosticsTests.ExpandPaths_EmptyIndexFile_BecomesTheDefaultOfTheFolder;
var
  LFolder: string;
begin
  LFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-base');
  FSettings.DocIndexFile := '';
  HelpChatExpandSettingsPaths(FSettings, LFolder);
  Assert.AreEqual(TPath.Combine(LFolder, HELPCHAT_DEF_DOCINDEX_FILENAME),
    FSettings.DocIndexFile, 'the empty value means "next to the executable"');
end;

procedure TDiagnosticsTests.SettingsForFolder_IsACopy_WithThePathsExpanded;
var
  LCopy: THelpChatSettings;
  LFiles: TArray<string>;
  LFolder: string;
begin
  FSettings.Provider := HELPCHAT_PROVIDER_DOCSEARCH;
  FSettings.DocFolder := 'help';
  // A folder that holds no helpchatai.json: nothing to read, nothing to merge.
  LFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-empty-' + THelpChatMessage.NewId);
  LCopy := HelpChatSettingsForFolder(FSettings, LFolder, '', LFiles);
  try
    Assert.AreEqual(HELPCHAT_PROVIDER_DOCSEARCH, LCopy.Provider);
    Assert.IsFalse(TPath.IsRelativePath(LCopy.DocFolder));
    Assert.StartsWith(LFolder, LCopy.DocFolder);
    Assert.AreEqual('help', FSettings.DocFolder, 'the source is left alone');
  finally
    LCopy.Free;
  end;
end;

procedure TDiagnosticsTests.SettingsForFolder_NamedFile_IsTheOnlyOneRead;
var
  LCopy: THelpChatSettings;
  LFiles: TArray<string>;
  LNamed, LFolder: string;
begin
  // A file named explicitly is the configuration: the defaults are not even
  // looked at, which is the whole point of naming one.
  LFolder := TPath.Combine(TPath.GetTempPath, 'helpchat-cfg-' + THelpChatMessage.NewId);
  TDirectory.CreateDirectory(LFolder);
  LNamed := TPath.Combine(LFolder, 'mine.json');
  TFile.WriteAllText(LNamed, '{ "Provider": "claude", "Greeting": "Buongiorno" }',
    TEncoding.UTF8);
  try
    LCopy := HelpChatSettingsForFolder(FSettings, LFolder, 'mine.json', LFiles);
    try
      Assert.AreEqual(1, Length(LFiles), 'exactly the one that was named');
      Assert.AreEqual(LNamed, LFiles[0], 'a relative name resolves against the folder');
      Assert.AreEqual('claude', LCopy.Provider);
      Assert.AreEqual('Buongiorno', LCopy.Greeting);
    finally
      LCopy.Free;
    end;
    // One that is not there is an error: asking for a configuration and
    // running without it is how an application ships with the wrong settings.
    Assert.WillRaise(
      procedure
      var
        LMissing: THelpChatSettings;
        LNone: TArray<string>;
      begin
        LMissing := HelpChatSettingsForFolder(FSettings, LFolder, 'nope.json', LNone);
        LMissing.Free;
      end, EHelpChatConfigError);
  finally
    TDirectory.Delete(LFolder, True);
  end;
end;

procedure TDiagnosticsTests.IssuesToText_PutsErrorsFirst;
var
  LText: string;
begin
  FSettings.Provider := 'typo';
  FSettings.DocFolder := '';
  LText := HelpChatIssuesToText(HelpChatCheckSettings(FSettings));
  Assert.StartsWith('Error - Provider', LText);
end;

procedure TDiagnosticsTests.MissingIndex_IsReportedOnce_NotTwice;
var
  LIssues: THelpChatIssues;
  LIssue: THelpChatIssue;
  LLoud: Integer;
begin
  // docsearch says the index is missing, and says it with the reason. The
  // documentation check must not repeat the same fact as a warning: two lines
  // about one file read as two problems.
  FSettings.Provider := HELPCHAT_PROVIDER_DOCSEARCH;
  FSettings.DocIndexFile := TPath.Combine(TPath.GetTempPath, 'helpchat-no-such-index.json');
  LIssues := HelpChatCheckSettings(FSettings);
  LLoud := 0;
  for LIssue in LIssues do
    if (LIssue.Kind <> hikInfo) and LIssue.Text.Contains('helpchat-no-such-index.json') then
      Inc(LLoud);
  Assert.AreEqual(1, LLoud, 'one file, one complaint');

  // With a provider that does not need the index, the warning is the only
  // thing that would tell the developer, so it stays.
  FSettings.Provider := HELPCHAT_PROVIDER_CLAUDE;
  FSettings.Claude.ApiKey := 'sk-ant-not-a-real-key';
  LIssues := HelpChatCheckSettings(FSettings);
  Assert.AreEqual(Ord(hikWarning), Ord(Find(LIssues, 'Documentation index').Kind));
end;

end.
