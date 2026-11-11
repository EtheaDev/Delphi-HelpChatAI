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
    [Test] procedure EveryId_HasEveryLanguage;
    [Test] procedure EveryTranslation_KeepsTheFormatSpecifiers;
    [Test] procedure Languages_CodesAndNames;
    [Test] procedure LanguageList_FollowsTheEnumeration;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions;

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
    HelpChatMsgFmt(hcmApiError, ['Claude', 401, 'Unauthorized'], hclEnglish));
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

procedure TMessagesTests.EveryId_HasEveryLanguage;
var
  LId: THelpChatMsgId;
  L: THelpChatLanguage;
begin
  for L in HELPCHAT_ALL_LANGUAGES do
    for LId := Low(THelpChatMsgId) to High(THelpChatMsgId) do
      Assert.IsNotEmpty(HelpChatMsg(LId, L), Format('Missing %s string for id %d',
        [HelpChatLanguageName(L), Ord(LId)]));
  // Each table is its own, not a copy of the English one.
  for L in HELPCHAT_ALL_LANGUAGES - [hclEnglish] do
    Assert.AreNotEqual(HelpChatMsg(hcmGreeting, hclEnglish), HelpChatMsg(hcmGreeting, L),
      HelpChatLanguageName(L));
end;

procedure TMessagesTests.EveryTranslation_KeepsTheFormatSpecifiers;

  function Specifiers(const AText: string): string;
  var
    LList: TStringList;
    LMatch: TMatch;
  begin
    LList := TStringList.Create;
    try
      for LMatch in TRegEx.Matches(AText, '%(\d+:)?[sdx]') do
        LList.Add(LMatch.Value);
      LList.Sort;
      Result := LList.CommaText;
    finally
      LList.Free;
    end;
  end;

var
  LId: THelpChatMsgId;
  L: THelpChatLanguage;
begin
  // A translation that loses or adds a %s raises EConvertError at the
  // moment the string is shown, which is the worst moment to find out.
  for L in HELPCHAT_ALL_LANGUAGES - [hclEnglish] do
    for LId := Low(THelpChatMsgId) to High(THelpChatMsgId) do
      Assert.AreEqual(Specifiers(HelpChatMsg(LId, hclEnglish)), Specifiers(HelpChatMsg(LId, L)),
        Format('%s, id %d', [HelpChatLanguageName(L), Ord(LId)]));
end;

procedure TMessagesTests.Languages_CodesAndNames;
var
  L: THelpChatLanguage;
begin
  Assert.AreEqual('es', HelpChatLanguageCode(hclSpanish));
  Assert.AreEqual('fr', HelpChatLanguageCode(hclFrench));
  Assert.AreEqual('de', HelpChatLanguageCode(hclGerman));
  Assert.AreEqual('pt', HelpChatLanguageCode(hclPortuguese));
  Assert.AreEqual('German', HelpChatLanguageName(hclGerman));
  Assert.AreEqual('Español', HelpChatLanguageNativeName(hclSpanish));
  Assert.AreEqual('Italiano', HelpChatLanguageNativeName(hclItalian));
  // A code, an English name, a native name: all three are understood.
  Assert.IsTrue(HelpChatLanguageFromCode('ES', L));
  Assert.AreEqual(hclSpanish, L);
  Assert.IsTrue(HelpChatLanguageFromCode('French', L));
  Assert.AreEqual(hclFrench, L);
  Assert.IsTrue(HelpChatLanguageFromCode(' Português ', L));
  Assert.AreEqual(hclPortuguese, L);
  Assert.IsTrue(HelpChatLanguageFromCode('auto', L));
  Assert.AreEqual(hclAuto, L);
  Assert.IsFalse(HelpChatLanguageFromCode('klingon', L));
  Assert.IsFalse(HelpChatLanguageFromCode('', L));
  for L in HELPCHAT_ALL_LANGUAGES do
    Assert.AreEqual(2, HelpChatLanguageCode(L).Length, HelpChatLanguageName(L));
end;

procedure TMessagesTests.LanguageList_FollowsTheEnumeration;
var
  LList: TArray<THelpChatLanguage>;
begin
  LList := HelpChatLanguageList([hclGerman, hclEnglish, hclAuto]);
  Assert.AreEqual(2, Length(LList), 'auto is never a language to offer');
  Assert.AreEqual(hclEnglish, LList[0]);
  Assert.AreEqual(hclGerman, LList[1]);
  Assert.AreEqual(0, Length(HelpChatLanguageList([])));
end;

end.
