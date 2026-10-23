unit HelpChatAI.Tests.Messages;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Messages;

type
  [TestFixture]
  TMessagesTests = class
  public
    [Test] procedure English_And_Italian_Differ;
    [Test] procedure EveryId_HasBothTranslations;
    [Test] procedure Fmt_FormatsArguments;
    [Test] procedure DefaultLanguage_DrivesAuto;
    [Test] procedure LanguageCode;
  end;

implementation

uses
  System.SysUtils;

procedure TMessagesTests.English_And_Italian_Differ;
begin
  Assert.StartsWith('Hi!', HelpChatMsg(hcmGreeting, hclEnglish));
  Assert.StartsWith('Ciao!', HelpChatMsg(hcmGreeting, hclItalian));
  Assert.AreEqual('Read more', HelpChatMsg(hcmReadMore, hclEnglish));
  Assert.AreEqual('Leggi tutto', HelpChatMsg(hcmReadMore, hclItalian));
end;

procedure TMessagesTests.EveryId_HasBothTranslations;
var
  LId: THelpChatMsgId;
begin
  for LId := Low(THelpChatMsgId) to High(THelpChatMsgId) do
  begin
    Assert.IsNotEmpty(HelpChatMsg(LId, hclEnglish), 'Missing English string for id ' + IntToStr(Ord(LId)));
    Assert.IsNotEmpty(HelpChatMsg(LId, hclItalian), 'Missing Italian string for id ' + IntToStr(Ord(LId)));
  end;
end;

procedure TMessagesTests.Fmt_FormatsArguments;
begin
  Assert.AreEqual('Claude API error (HTTP 401 Unauthorized).',
    HelpChatMsgFmt(hcmApiError, [401, 'Unauthorized'], hclEnglish));
  Assert.AreEqual('How do I use the "Orders" screen?',
    HelpChatMsgFmt(hcmContextQuestion, ['Orders'], hclEnglish));
  Assert.AreEqual('Come si usa la schermata "Ordini"?',
    HelpChatMsgFmt(hcmContextQuestion, ['Ordini'], hclItalian));
end;

procedure TMessagesTests.DefaultLanguage_DrivesAuto;
var
  LSaved: THelpChatLanguage;
begin
  LSaved := HelpChatDefaultLanguage;
  try
    HelpChatDefaultLanguage := hclItalian;
    Assert.AreEqual(hclItalian, HelpChatResolveLanguage(hclAuto));
    Assert.AreEqual('Leggi tutto', HelpChatMsg(hcmReadMore));
    HelpChatDefaultLanguage := hclEnglish;
    Assert.AreEqual(hclEnglish, HelpChatResolveLanguage(hclAuto));
    Assert.AreEqual('Read more', HelpChatMsg(hcmReadMore));
    // An explicit language always wins over the default.
    Assert.AreEqual('Leggi tutto', HelpChatMsg(hcmReadMore, hclItalian));
  finally
    HelpChatDefaultLanguage := LSaved;
  end;
end;

procedure TMessagesTests.LanguageCode;
begin
  Assert.AreEqual('en', HelpChatLanguageCode(hclEnglish));
  Assert.AreEqual('it', HelpChatLanguageCode(hclItalian));
  Assert.AreEqual('English', HelpChatLanguageName(hclEnglish));
  Assert.AreEqual('Italian', HelpChatLanguageName(hclItalian));
end;

end.
