unit HelpChatAI.Tests.Provider;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider;

type
  [TestFixture]
  TProviderRegistryTests = class
  public
    [Test] procedure Stub_IsRegistered_CaseInsensitive;
    [Test] procedure BuiltInProviders_AreListedSorted;
    [Test] procedure Empty_IsStub_Unknown_IsReported;
    [Test] procedure Register_Unregister_Custom;
    [Test] procedure Stub_Reply_IsLocalized;
    [Test] procedure Stub_Cancelled_Raises;
    [Test] procedure Base_LastUserMessage;
  end;

implementation

uses
  System.SysUtils,
  HelpChatAI.Messages,
  HelpChatAI.Provider.DocSearch,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Tests.Helpers;

type
  TNamedProvider = class(THelpChatStubProvider)
  public
    function GetName: string; override;
  end;

function TNamedProvider.GetName: string;
begin
  Result := 'custom';
end;

procedure TProviderRegistryTests.Stub_IsRegistered_CaseInsensitive;
begin
  Assert.IsTrue(THelpChatProviderRegistry.IsRegistered('stub'));
  Assert.IsTrue(THelpChatProviderRegistry.IsRegistered('STUB'));
  Assert.IsTrue(THelpChatProviderRegistry.IsRegistered(' Stub '));
  Assert.IsFalse(THelpChatProviderRegistry.IsRegistered('does-not-exist'));
end;

procedure TProviderRegistryTests.BuiltInProviders_AreListedSorted;
var
  LNames: TArray<string>;
  I: Integer;
begin
  LNames := THelpChatProviderRegistry.ProviderNames;
  Assert.Contains<string>(LNames, HELPCHAT_PROVIDER_STUB);
  Assert.Contains<string>(LNames, HELPCHAT_PROVIDER_DOCSEARCH);
  Assert.Contains<string>(LNames, HELPCHAT_PROVIDER_CLAUDE);
  for I := 1 to High(LNames) do
    Assert.IsTrue(CompareStr(LNames[I - 1], LNames[I]) < 0, 'names must be sorted');
end;

procedure TProviderRegistryTests.Empty_IsStub_Unknown_IsReported;
var
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
  LMessage: string;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclEnglish;
    // A name nobody registered (typo, unit not linked) is an explicit error,
    // never the stub's placeholder that would pass for an answer.
    LProvider := THelpChatProviderRegistry.CreateProvider('typo', LSettings, nil);
    Assert.AreEqual('typo', LProvider.GetName);
    LMessage := '';
    try
      LProvider.Generate(nil, Default(THelpChatContext), nil, nil);
    except
      on E: EHelpChatConfigError do
        LMessage := E.Message;
    end;
    Assert.Contains(LMessage, '"typo"');
    Assert.Contains(LMessage, 'HelpChatAI.Provider.Claude');
    Assert.Contains(LMessage, HELPCHAT_PROVIDER_STUB, 'lists the available providers');
    LProvider := THelpChatProviderRegistry.CreateProvider('', LSettings, nil);
    Assert.AreEqual(HELPCHAT_PROVIDER_STUB, LProvider.GetName);
    LProvider := THelpChatProviderRegistry.CreateProvider('Claude', LSettings, nil);
    Assert.AreEqual(HELPCHAT_PROVIDER_CLAUDE, LProvider.GetName);
    Assert.IsTrue(LProvider.SupportsStreaming);
  finally
    LSettings.Free;
  end;
end;

procedure TProviderRegistryTests.Register_Unregister_Custom;
var
  LProvider: IHelpChatProvider;
begin
  THelpChatProviderRegistry.RegisterProvider('custom', TNamedProvider);
  try
    Assert.IsTrue(THelpChatProviderRegistry.IsRegistered('custom'));
    LProvider := THelpChatProviderRegistry.CreateProvider('custom', nil, nil);
    Assert.AreEqual('custom', LProvider.GetName);
    Assert.IsTrue(THelpChatProviderRegistry.FindProviderClass('CUSTOM') = TNamedProvider);
  finally
    THelpChatProviderRegistry.UnregisterProvider('custom');
  end;
  Assert.IsFalse(THelpChatProviderRegistry.IsRegistered('custom'));
  Assert.IsNull(THelpChatProviderRegistry.FindProviderClass('custom'));
end;

procedure TProviderRegistryTests.Stub_Reply_IsLocalized;
var
  LSettings: THelpChatSettings;
  LProvider: IHelpChatProvider;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclItalian;
    LProvider := THelpChatProviderRegistry.CreateProvider('stub', LSettings, nil);
    Assert.AreEqual(HelpChatMsg(hcmStubReply, hclItalian),
      LProvider.Generate(nil, Default(THelpChatContext), nil, nil));
    LSettings.Language := hclEnglish;
    LProvider := THelpChatProviderRegistry.CreateProvider('stub', LSettings, nil);
    Assert.AreEqual(HelpChatMsg(hcmStubReply, hclEnglish),
      LProvider.Generate(nil, Default(THelpChatContext), nil, nil));
  finally
    LSettings.Free;
  end;
end;

procedure TProviderRegistryTests.Stub_Cancelled_Raises;
var
  LProvider: IHelpChatProvider;
  LToken: IHelpChatCancelToken;
begin
  LProvider := THelpChatProviderRegistry.CreateProvider('stub', nil, nil);
  LToken := THelpChatCancelToken.Create;
  LToken.Cancel;
  Assert.WillRaise(
    procedure
    begin
      LProvider.Generate(nil, Default(THelpChatContext), nil, LToken);
    end, EHelpChatCancelled);
end;

procedure TProviderRegistryTests.Base_LastUserMessage;
var
  LHistory: TArray<THelpChatMessage>;
begin
  SetLength(LHistory, 3);
  LHistory[0].Role := hcrUser; LHistory[0].Content := 'first';
  LHistory[1].Role := hcrAssistant; LHistory[1].Content := 'reply';
  LHistory[2].Role := hcrUser; LHistory[2].Content := 'second';
  Assert.AreEqual('second', THelpChatProviderBase.LastUserMessage(LHistory));
  Assert.AreEqual('', THelpChatProviderBase.LastUserMessage(nil));
end;

end.
