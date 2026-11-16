{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  What the developer may change of what the library says: the texts of the
///  system prompt (properties whose defaults are the constants), the last
///  word on the prompt (<c>OnBuildSystemPrompt</c>) and the messages of the
///  panel (<c>HelpChatSetMsg</c>).
/// </summary>
unit HelpChatAI.Tests.Customization;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings;

type
  [TestFixture]
  TCustomizationTests = class
  strict private
    FSeen: string;
    procedure AppendToPrompt(Sender: TObject; const AContext: THelpChatContext;
      const ALanguage: THelpChatLanguage; var APrompt: string);
    function Prompt(const ASettings: THelpChatSettings): string;
  public
    [TearDown] procedure TearDown;
    [Test] procedure PromptTexts_DefaultToTheConstants;
    [Test] procedure PromptTexts_ReachThePrompt;
    [Test] procedure PromptTexts_EmptyMeansTheDefault;
    [Test] procedure PromptTexts_ThatDoNotFit_FallBackAndAreReported;
    [Test] procedure PromptTexts_Json_OnlyWhenTheyDiffer;
    [Test] procedure PromptTexts_FormFile_OnlyWhenTheyDiffer;
    [Test] procedure BuildSystemPrompt_Event_HasTheLastWord_BeforeTheActionsRule;
    [Test] procedure Messages_CanBeReplaced_PerLanguage_OrForAll;
    [Test] procedure AssistantIcons_EveryMemberNamed_InEverySize;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  HelpChatAI.Provider,
  HelpChatAI.Diagnostics,
  HelpChatAI.Assistant;

type
  TPromptHolder = class(TComponent)
  strict private
    FSettings: THelpChatSettings;
    procedure SetSettings(const Value: THelpChatSettings);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // A writable property: the writer skips a read-only one.
    property Settings: THelpChatSettings read FSettings write SetSettings;
  end;

constructor TPromptHolder.Create(AOwner: TComponent);
begin
  inherited;
  FSettings := THelpChatSettings.Create;
end;

procedure TPromptHolder.SetSettings(const Value: THelpChatSettings);
begin
  FSettings.Assign(Value);
end;

destructor TPromptHolder.Destroy;
begin
  FSettings.Free;
  inherited;
end;

function FormText(const AComponent: TComponent): string;
var
  LBinary, LText: TMemoryStream;
  LBytes: TBytes;
begin
  LBinary := TMemoryStream.Create;
  LText := TMemoryStream.Create;
  try
    LBinary.WriteComponent(AComponent);
    LBinary.Position := 0;
    ObjectBinaryToText(LBinary, LText);
    SetLength(LBytes, LText.Size);
    LText.Position := 0;
    if LText.Size > 0 then
      LText.ReadBuffer(LBytes[0], LText.Size);
    Result := TEncoding.ANSI.GetString(LBytes);
  finally
    LText.Free;
    LBinary.Free;
  end;
end;

{ TCustomizationTests }

procedure TCustomizationTests.TearDown;
begin
  HelpChatClearMsgs;
end;

procedure TCustomizationTests.AppendToPrompt(Sender: TObject;
  const AContext: THelpChatContext; const ALanguage: THelpChatLanguage; var APrompt: string);
begin
  FSeen := APrompt;
  APrompt := APrompt + ' CUSTOM-' + HelpChatLanguageCode(ALanguage);
end;

function TCustomizationTests.Prompt(const ASettings: THelpChatSettings): string;
var
  LHistory: TArray<THelpChatMessage>;
begin
  SetLength(LHistory, 1);
  LHistory[0].Role := hcrUser;
  LHistory[0].Content := 'help';
  Result := THelpChatProviderBase.BuildSystemPrompt(LHistory, Default(THelpChatContext),
    ASettings, nil);
end;

procedure TCustomizationTests.PromptTexts_DefaultToTheConstants;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    Assert.AreEqual(HELPCHAT_MODEL_DEF_SYSTEMPROMPT, LSettings.SystemPrompt);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_IDENTITY_RULE, LSettings.IdentityRule);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_LANGUAGE_RULE, LSettings.LanguageRule);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_DOC_LANGUAGE_RULE, LSettings.DocLanguageRule);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_EXPERTISE, LSettings.ExpertiseIntro);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_EXPERTISE_RULE, LSettings.ExpertiseRule);
  finally
    LSettings.Free;
  end;
end;

procedure TCustomizationTests.PromptTexts_ReachThePrompt;
var
  LSettings, LCopy: THelpChatSettings;
  LText: string;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSettings.Language := hclItalian;
    LSettings.DocLanguage := hclEnglish;
    LSettings.Expertise := 'accounting';
    LSettings.AssistantName := 'Giulio';
    LSettings.SystemPrompt := 'RULES.';
    LSettings.IdentityRule := 'I am %0:s.';
    LSettings.LanguageRule := 'Speak %0:s.';
    LSettings.DocLanguageRule := 'Manual in %0:s, chat in %1:s.';
    LSettings.ExpertiseIntro := 'Expert of %s.';
    LSettings.ExpertiseRule := 'EXPERTISE-RULE, 100% sure.';
    // What a request reads is a snapshot: Assign carries them.
    LCopy.Assign(LSettings);
    LText := Prompt(LCopy);
    // The prompt of a provider that sends it whole: now right after the
    // identity, as before 1.12.
    Assert.StartsWith('I am Giulio. Now it is ', LText);
    Assert.Contains(LText, '). Expert of accounting. RULES. EXPERTISE-RULE, 100% sure. ' +
      'Speak Italian. Manual in English, chat in Italian.');
    Assert.DoesNotContain(LText, 'Your name is');
    // Split (claude): the system prompt never says now, the question does.
    Assert.AreEqual('I am Giulio. Expert of accounting. RULES. EXPERTISE-RULE, 100% sure. ' +
      'Speak Italian. Manual in English, chat in Italian.',
      THelpChatProviderBase.BuildStablePrompt(Default(THelpChatContext), LCopy));
    Assert.StartsWith('Now it is ', THelpChatProviderBase.BuildQuestionContext(nil,
      Default(THelpChatContext), LCopy, nil));
    // An identity rule written before 1.12 still says now, and only once.
    LCopy.IdentityRule := 'I am %0:s, at %1:s.';
    Assert.IsTrue(LCopy.IdentityRuleSaysNow);
    Assert.StartsWith('I am Giulio, at ', THelpChatProviderBase.BuildStablePrompt(
      Default(THelpChatContext), LCopy));
    Assert.AreEqual('', THelpChatProviderBase.BuildQuestionContext(nil,
      Default(THelpChatContext), LCopy, nil), 'NowRule is not added twice');
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TCustomizationTests.PromptTexts_EmptyMeansTheDefault;
var
  LSettings: THelpChatSettings;
  LText: string;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclEnglish;
    LSettings.SystemPrompt := '';
    LSettings.IdentityRule := ' ';
    LSettings.LanguageRule := '';
    LText := Prompt(LSettings);
    Assert.StartsWith('Your name is ', LText);
    Assert.Contains(LText, HELPCHAT_MODEL_DEF_SYSTEMPROMPT);
    Assert.Contains(LText, Format(HELPCHAT_MODEL_DEF_LANGUAGE_RULE, ['English']));
  finally
    LSettings.Free;
  end;
end;

procedure TCustomizationTests.PromptTexts_ThatDoNotFit_FallBackAndAreReported;
var
  LSettings: THelpChatSettings;
  LIssues: THelpChatIssues;
  LText: string;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Language := hclEnglish;
    // A name expected as a number, a value more than the rule receives.
    LSettings.IdentityRule := 'I am %0:d.';
    LSettings.LanguageRule := 'Speak %0:s and %1:s.';
    LText := Prompt(LSettings);
    Assert.StartsWith('Your name is ', LText);
    Assert.Contains(LText, Format(HELPCHAT_MODEL_DEF_LANGUAGE_RULE, ['English']));
    LIssues := HelpChatCheckSettings(LSettings);
    LText := HelpChatIssuesToText(LIssues);
    Assert.Contains(LText, 'IdentityRule');
    Assert.Contains(LText, 'LanguageRule');
    Assert.DoesNotContain(LText, 'DocLanguageRule');
    Assert.AreEqual('', HelpChatRuleIssue('Fewer values than given: %0:s', 2));
  finally
    LSettings.Free;
  end;
end;

procedure TCustomizationTests.PromptTexts_Json_OnlyWhenTheyDiffer;
var
  LSettings, LCopy: THelpChatSettings;
  LJson: string;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LJson := LSettings.SaveToJSON;
    Assert.DoesNotContain(LJson, 'SystemPrompt');
    Assert.DoesNotContain(LJson, 'IdentityRule');
    Assert.DoesNotContain(LJson, 'ExpertiseRule');
    LSettings.SystemPrompt := 'RULES.';
    LSettings.DocLanguageRule := 'Doc %0:s chat %1:s.';
    LSettings.ExpertiseIntro := 'Expert of %s.';
    LJson := LSettings.SaveToJSON;
    Assert.DoesNotContain(LJson, 'IdentityRule');
    LCopy.LoadFromJSON(LJson);
    Assert.AreEqual('RULES.', LCopy.SystemPrompt);
    Assert.AreEqual('Doc %0:s chat %1:s.', LCopy.DocLanguageRule);
    Assert.AreEqual('Expert of %s.', LCopy.ExpertiseIntro);
    Assert.AreEqual(HELPCHAT_MODEL_DEF_IDENTITY_RULE, LCopy.IdentityRule);
    // In a profile, like every other key.
    LCopy.Profile := 'Sales';
    LCopy.LoadFromJSON('{"Profiles":{"Sales":{"LanguageRule":"Sales speak %0:s."}}}');
    Assert.AreEqual('Sales speak %0:s.', LCopy.LanguageRule);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TCustomizationTests.PromptTexts_FormFile_OnlyWhenTheyDiffer;
var
  LHolder: TPromptHolder;
  LText: string;
begin
  LHolder := TPromptHolder.Create(nil);
  try
    LText := FormText(LHolder);
    Assert.IsFalse(ContainsText(LText, 'SystemPrompt'), LText);
    Assert.IsFalse(ContainsText(LText, 'Rule'), LText);
    Assert.IsFalse(ContainsText(LText, 'ExpertiseIntro'), LText);
    LHolder.Settings.LanguageRule := 'Speak %0:s.';
    LText := FormText(LHolder);
    Assert.IsTrue(ContainsText(LText, 'Settings.LanguageRule = ''Speak %0:s.'''), LText);
    Assert.IsFalse(ContainsText(LText, 'IdentityRule'), LText);
  finally
    LHolder.Free;
  end;
end;

procedure TCustomizationTests.BuildSystemPrompt_Event_HasTheLastWord_BeforeTheActionsRule;
var
  LSettings, LCopy: THelpChatSettings;
  LText: string;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSettings.Language := hclItalian;
    LSettings.SetPromptHandler(AppendToPrompt, Self);
    Assert.AreSame(TObject(Self), LSettings.PromptSender);
    LCopy.Assign(LSettings);
    FSeen := '';
    LText := Prompt(LCopy);
    Assert.EndsWith(' CUSTOM-it', LText);
    Assert.StartsWith('Your name is ', FSeen, 'the handler gets the prompt already built');
    // The rule about the actions is not part of what the handler sees: the
    // providers add it afterwards.
    Assert.DoesNotContain(FSeen, HELPCHAT_MODEL_ACTIONS_RULE);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TCustomizationTests.Messages_CanBeReplaced_PerLanguage_OrForAll;
var
  LDefaultEn, LDefaultIt: string;
begin
  LDefaultEn := HelpChatMsg(hcmUiPlaceholder, hclEnglish);
  LDefaultIt := HelpChatMsg(hcmUiPlaceholder, hclItalian);
  HelpChatSetMsg(hcmUiPlaceholder, 'Ask me anything');
  Assert.AreEqual('Ask me anything', HelpChatMsg(hcmUiPlaceholder, hclEnglish));
  Assert.AreEqual('Ask me anything', HelpChatMsg(hcmUiPlaceholder, hclGerman));
  // One language wins over all of them.
  HelpChatSetMsg(hcmUiPlaceholder, 'Chiedi pure', hclItalian);
  Assert.AreEqual('Chiedi pure', HelpChatMsg(hcmUiPlaceholder, hclItalian));
  Assert.AreEqual('Ask me anything', HelpChatMsg(hcmUiPlaceholder, hclEnglish));
  // Empty takes it away.
  HelpChatSetMsg(hcmUiPlaceholder, '');
  Assert.AreEqual(LDefaultEn, HelpChatMsg(hcmUiPlaceholder, hclEnglish));
  Assert.AreEqual('Chiedi pure', HelpChatMsg(hcmUiPlaceholder, hclItalian));
  HelpChatClearMsgs;
  Assert.AreEqual(LDefaultIt, HelpChatMsg(hcmUiPlaceholder, hclItalian));
  // Formatted strings go through the same lookup.
  HelpChatSetMsg(hcmScreenContext, 'Screen %s / %s.', hclEnglish);
  Assert.AreEqual('Screen A / B.', HelpChatMsgFmt(hcmScreenContext, ['A', 'B'], hclEnglish));
end;

procedure TCustomizationTests.AssistantIcons_EveryMemberNamed_InEverySize;
var
  LIcon, LFound: THelpChatAssistantIcon;
  LNames: TArray<string>;
  LSize: Integer;
  LPng: TBytes;
begin
  LNames := HelpChatAssistantIconNames;
  // The order of the enumeration is the ImageIndex of the built-in list.
  Assert.AreEqual(Ord(High(THelpChatAssistantIcon)) + 1, Length(LNames));
  Assert.AreEqual(HELPCHAT_ICON_DEFAULT, LNames[0]);
  Assert.AreEqual(HELPCHAT_ICON_BUSINESSMAN, LNames[Ord(haiBusinessman)]);
  Assert.AreEqual(HELPCHAT_ICON_PORTRAIT_MODE, LNames[Ord(haiPortraitMode)]);
  for LIcon := Low(THelpChatAssistantIcon) to High(THelpChatAssistantIcon) do
  begin
    Assert.IsTrue(HelpChatAssistantIconOf(LowerCase(HELPCHAT_ICON_NAMES[LIcon]), LFound));
    Assert.AreEqual(Ord(LIcon), Ord(LFound));
    Assert.IsTrue(HelpChatIsAssistantIcon(HELPCHAT_ICON_NAMES[LIcon]));
    // Every size is in the resource, and is a PNG.
    for LSize in HELPCHAT_ICON_SIZES do
    begin
      LPng := HelpChatAssistantIconPng(HELPCHAT_ICON_NAMES[LIcon], LSize);
      Assert.IsTrue(Length(LPng) > 8, Format('%s %d', [HELPCHAT_ICON_NAMES[LIcon], LSize]));
      Assert.AreEqual(Byte($89), LPng[0]);
      Assert.AreEqual(Byte(Ord('P')), LPng[1]);
    end;
  end;
  Assert.IsFalse(HelpChatAssistantIconOf('Nobody', LFound));
end;

initialization
  TDUnitX.RegisterTestFixture(TCustomizationTests);

end.
