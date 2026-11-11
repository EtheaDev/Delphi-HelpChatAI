unit HelpChatAI.Tests.Theme;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Theme;

type
  [TestFixture]
  TThemeTests = class
  public
    [Test] procedure NormalizeColor;
    [Test] procedure Blend_And_Luminance;
    [Test] procedure Complete_DerivesEverythingFromBaseColours;
    [Test] procedure ToCss_AssignsEveryVariable_AndColorScheme;
    [Test] procedure ToJson_KeysAreCssVariables;
    [Test] procedure Empty_RendersNothing;
    [Test] procedure BuiltIn_LightAndDark;
    [Test] procedure ColorDistance;
    [Test] procedure Bubbles_OfTheSameColour_AreSeparated;
    [Test] procedure Bubbles_SetByTheProducer_AreLeftAlone;
    [Test] procedure Shadow_FollowsTheMode;
    [Test] procedure Link_IsTheAccent_WhenItReads;
    [Test] procedure Link_MovesTowardsTheText_WhenTheAccentDoesNotRead;
    [Test] procedure StyleSheet_ComesBeforeTheColours;
    [Test] procedure StyleSheet_Alone_IsTheWholeCss;
    [Test] procedure StyleSheet_TravelsInTheJson;
    [Test] procedure CssForStyleTag_CannotCloseTheElement;
    [Test] procedure PanelCss_EmptyName_MissingFile_AndAFile;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  HelpChatAI.Panel,
  HelpChatAI.Types;

procedure TThemeTests.NormalizeColor;
begin
  Assert.AreEqual('#a0b1c2', HelpChatNormalizeColor(' #A0B1C2 '));
  Assert.AreEqual('#a0b1c2', HelpChatNormalizeColor('A0B1C2'));
  Assert.AreEqual('#aabbcc', HelpChatNormalizeColor('#abc'));
  Assert.AreEqual('', HelpChatNormalizeColor('#12345'));
  Assert.AreEqual('', HelpChatNormalizeColor('red'));
  Assert.AreEqual('#0a0b0c', HelpChatRgbToHex(10, 11, 12));
  Assert.AreEqual('#ff0000', HelpChatRgbToHex(300, -5, 0), 'components are clamped');
end;

procedure TThemeTests.Blend_And_Luminance;
begin
  Assert.AreEqual('#000000', HelpChatBlend('#000000', '#ffffff', 0));
  Assert.AreEqual('#ffffff', HelpChatBlend('#000000', '#ffffff', 1));
  Assert.AreEqual('#808080', HelpChatBlend('#000000', '#ffffff', 0.5));
  Assert.AreEqual('#ffffff', HelpChatBlend('nope', '#ffffff', 0.5), 'an invalid colour yields the other one');
  Assert.AreEqual('#bbaadd', HelpChatNormalizeColor('bad'), '"bad" happens to be a valid #rgb shorthand');
  Assert.IsTrue(HelpChatIsDarkColor('#17191d'));
  Assert.IsFalse(HelpChatIsDarkColor('#f6f7f9'));
  Assert.AreEqual('#ffffff', HelpChatContrastText('#2563eb'));
  Assert.AreEqual('#000000', HelpChatContrastText('#e0eef9'));
  Assert.IsTrue(HelpChatSaturation('#0078d4') > HelpChatSaturation('#e0eef9'), 'the brand blue beats the pale hover');
  Assert.AreEqual(Double(0), HelpChatSaturation('#808080'), 0.001);
end;

procedure TThemeTests.Complete_DerivesEverythingFromBaseColours;
var
  LTheme: THelpChatTheme;
begin
  LTheme := Default(THelpChatTheme);
  LTheme.IsDark := True;
  LTheme.Background := '#202020';
  LTheme.Surface := '#2A2A2A';
  LTheme.Text := '#EEEEEE';
  LTheme.Accent := '#6EE4D3';
  LTheme.Complete;
  Assert.AreEqual('#2a2a2a', LTheme.Surface, 'normalized');
  Assert.AreEqual('#6ee4d3', LTheme.UserBubble, 'user bubble = accent');
  Assert.AreEqual('#000000', LTheme.UserText, 'dark text on a light accent');
  Assert.AreEqual('#2a2a2a', LTheme.AssistantBubble);
  Assert.AreEqual('#eeeeee', LTheme.AssistantText);
  Assert.IsNotEmpty(LTheme.Border);
  Assert.IsNotEmpty(LTheme.Muted);
  Assert.IsNotEmpty(LTheme.CodeBackground);
  Assert.AreEqual('#3b1d1d', LTheme.ErrorBubble, 'dark error pair');
  Assert.IsNotEmpty(LTheme.FontFamily);

  // Only a surface: background and text are derived too.
  LTheme := Default(THelpChatTheme);
  LTheme.Surface := '#fdfdfd';
  LTheme.Complete;
  Assert.AreEqual('#fdfdfd', LTheme.Background);
  Assert.AreEqual('#000000', LTheme.Text);
  Assert.AreEqual('#fef2f2', LTheme.ErrorBubble, 'light error pair');
end;

procedure TThemeTests.ToCss_AssignsEveryVariable_AndColorScheme;
var
  LTheme: THelpChatTheme;
  LCss: string;
begin
  LTheme := THelpChatTheme.Dark;
  LCss := LTheme.ToCss;
  Assert.StartsWith(':root{', LCss);
  Assert.EndsWith('}', LCss);
  Assert.Contains(LCss, '--hc-bg:#17191d;');
  Assert.Contains(LCss, '--hc-user-bg:#3b82f6;');
  Assert.Contains(LCss, '--hc-font:');
  Assert.Contains(LCss, 'color-scheme:dark;');
  Assert.Contains(THelpChatTheme.Light.ToCss, 'color-scheme:light;');
end;

procedure TThemeTests.ToJson_KeysAreCssVariables;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.ParseJSONValue(THelpChatTheme.Light.ToJson) as TJSONObject;
  try
    Assert.AreEqual('#f6f7f9', LJson.GetValue<string>('--hc-bg'));
    Assert.AreEqual('#2563eb', LJson.GetValue<string>('--hc-accent'));
    Assert.AreEqual('light', LJson.GetValue<string>('color-scheme'));
    Assert.AreEqual(20, LJson.Count, '19 variables + color-scheme');
  finally
    LJson.Free;
  end;
end;

procedure TThemeTests.Empty_RendersNothing;
var
  LTheme: THelpChatTheme;
begin
  LTheme := Default(THelpChatTheme);
  Assert.IsTrue(LTheme.IsEmpty);
  Assert.AreEqual('', LTheme.ToCss);
  Assert.AreEqual('{}', LTheme.ToJson);
end;

procedure TThemeTests.BuiltIn_LightAndDark;
begin
  Assert.IsFalse(THelpChatTheme.Light.IsDark);
  Assert.IsTrue(THelpChatTheme.Dark.IsDark);
  Assert.IsFalse(THelpChatTheme.Light.IsEmpty);
  Assert.AreEqual('#ffffff', THelpChatTheme.Light.AssistantBubble);
  Assert.AreEqual('#22252b', THelpChatTheme.Dark.AssistantBubble);
end;

procedure TThemeTests.ColorDistance;
begin
  Assert.AreEqual(Double(0), HelpChatColorDistance('#cccccc', '#CCCCCC'), 0.001);
  Assert.AreEqual(Double(1), HelpChatColorDistance('#000000', '#ffffff'), 0.001);
  // The largest difference of the components, not their average: two colours
  // that share two of them are still far apart.
  Assert.AreEqual(Double(1), HelpChatColorDistance('#ff0000', '#000000'), 0.001);
  Assert.AreEqual(Double(1), HelpChatColorDistance('nope', '#000000'), 0.001, 'unparsable = as far as it gets');
end;

procedure TThemeTests.Bubbles_OfTheSameColour_AreSeparated;
var
  LTheme: THelpChatTheme;
begin
  // Windows10: the style answers #cccccc for its surface and for its accent.
  LTheme := Default(THelpChatTheme);
  LTheme.Background := '#ffffff';
  LTheme.Surface := '#cccccc';
  LTheme.Accent := '#cccccc';
  LTheme.Text := '#000000';
  LTheme.Complete;
  Assert.IsTrue(HelpChatColorDistance(LTheme.UserBubble, LTheme.AssistantBubble) >= 0.12,
    'the two bubbles are told apart');
  Assert.IsTrue(HelpChatLuminance(LTheme.UserBubble) < HelpChatLuminance('#cccccc'),
    'under a light theme the user bubble is the darker one');
  Assert.IsTrue(HelpChatLuminance(LTheme.AssistantBubble) > HelpChatLuminance('#cccccc'));

  // Windows10 Dark: #262626 for both, and the other way round.
  LTheme := Default(THelpChatTheme);
  LTheme.IsDark := True;
  LTheme.Background := '#000000';
  LTheme.Surface := '#262626';
  LTheme.Accent := '#262626';
  LTheme.Text := '#ffffff';
  LTheme.Complete;
  Assert.IsTrue(HelpChatColorDistance(LTheme.UserBubble, LTheme.AssistantBubble) >= 0.12);
  Assert.IsTrue(HelpChatLuminance(LTheme.UserBubble) > HelpChatLuminance('#262626'),
    'under a dark theme the user bubble is the lighter one');
  Assert.IsTrue(HelpChatLuminance(LTheme.AssistantBubble) < HelpChatLuminance('#262626'));

  // Two colours that can be told apart are not touched.
  LTheme := Default(THelpChatTheme);
  LTheme.Surface := '#ffffff';
  LTheme.Accent := '#2563eb';
  LTheme.Complete;
  Assert.AreEqual('#2563eb', LTheme.UserBubble);
  Assert.AreEqual('#ffffff', LTheme.AssistantBubble);
end;

procedure TThemeTests.Bubbles_SetByTheProducer_AreLeftAlone;
var
  LTheme: THelpChatTheme;
begin
  LTheme := Default(THelpChatTheme);
  LTheme.Surface := '#cccccc';
  LTheme.Accent := '#cccccc';
  LTheme.UserBubble := '#cccccc';
  LTheme.AssistantBubble := '#cccccc';
  LTheme.Complete;
  Assert.AreEqual('#cccccc', LTheme.UserBubble, 'what the producer wrote is kept');
  Assert.AreEqual('#cccccc', LTheme.AssistantBubble);
end;

procedure TThemeTests.Shadow_FollowsTheMode;
begin
  Assert.AreEqual('rgba(0,0,0,0.16)', THelpChatTheme.Light.Shadow);
  Assert.AreEqual('rgba(0,0,0,0.55)', THelpChatTheme.Dark.Shadow);
  Assert.Contains(THelpChatTheme.Light.ToCss, '--hc-shadow:rgba(0,0,0,0.16);');
end;

procedure TThemeTests.Link_IsTheAccent_WhenItReads;
var
  LTheme: THelpChatTheme;
begin
  LTheme := THelpChatTheme.Light;
  LTheme.Complete;
  Assert.AreEqual(LTheme.Accent, LTheme.Link, 'light defaults');
  LTheme := THelpChatTheme.Dark;
  LTheme.Complete;
  Assert.AreEqual(LTheme.Accent, LTheme.Link, 'dark defaults');
  Assert.Contains(THelpChatTheme.Light.ToCss, '--hc-link:');
end;

procedure TThemeTests.Link_MovesTowardsTheText_WhenTheAccentDoesNotRead;
var
  LTheme: THelpChatTheme;
begin
  // Windows10: one grey for the accent and for the surface.
  LTheme := Default(THelpChatTheme);
  LTheme.IsDark := False;
  LTheme.Background := '#ffffff';
  LTheme.Surface := '#cccccc';
  LTheme.Text := '#000000';
  LTheme.Accent := '#cccccc';
  LTheme.Complete;
  Assert.AreNotEqual(LTheme.Accent, LTheme.Link);
  Assert.IsTrue(Abs(HelpChatLuminance(LTheme.Link) - HelpChatLuminance(LTheme.AssistantBubble)) >= 0.33,
    LTheme.Link + ' on ' + LTheme.AssistantBubble);
  Assert.IsTrue(HelpChatLuminance(LTheme.Link) < HelpChatLuminance(LTheme.Accent), 'darker on a light bubble');
  // Carbon: a dark accent on a dark surface goes the other way.
  LTheme := Default(THelpChatTheme);
  LTheme.IsDark := True;
  LTheme.Background := '#3a3a3a';
  LTheme.Surface := '#3a3a3a';
  LTheme.Text := '#c0c0c0';
  LTheme.Accent := '#3e3e3e';
  LTheme.Complete;
  Assert.IsTrue(HelpChatLuminance(LTheme.Link) > HelpChatLuminance(LTheme.Accent), 'lighter on a dark bubble');
end;

procedure TThemeTests.StyleSheet_ComesBeforeTheColours;
var
  LTheme: THelpChatTheme;
  LCss: string;
begin
  LTheme := THelpChatTheme.Dark;
  LTheme.StyleSheet := '.hc-chat-bubble{border-radius:2px}';
  LCss := LTheme.ToCss;
  Assert.StartsWith('.hc-chat-bubble{border-radius:2px}', LCss);
  Assert.IsTrue(LCss.IndexOf('.hc-chat-bubble') < LCss.IndexOf(':root{'),
    'the colours come last, so a variable set by the stylesheet is the theme''s');
  Assert.Contains(LCss, '--hc-bg:#17191d;');
end;

procedure TThemeTests.StyleSheet_Alone_IsTheWholeCss;
var
  LTheme: THelpChatTheme;
begin
  LTheme := Default(THelpChatTheme);
  LTheme.StyleSheet := '#hc-copy{display:none}';
  Assert.IsTrue(LTheme.IsEmpty, 'a stylesheet is not a colour');
  Assert.AreEqual('#hc-copy{display:none}', LTheme.ToCss);
end;

procedure TThemeTests.StyleSheet_TravelsInTheJson;
var
  LTheme: THelpChatTheme;
  LJson: TJSONObject;
begin
  LTheme := Default(THelpChatTheme);
  LTheme.StyleSheet := '#hc-copy{display:none}';
  LJson := TJSONObject.ParseJSONValue(LTheme.ToJson) as TJSONObject;
  try
    Assert.AreEqual(1, LJson.Count, 'no colour, only the stylesheet');
    Assert.AreEqual('#hc-copy{display:none}', LJson.GetValue<string>('css'));
  finally
    LJson.Free;
  end;
  LJson := TJSONObject.ParseJSONValue(THelpChatTheme.Light.ToJson) as TJSONObject;
  try
    Assert.IsNull(LJson.GetValue('css'), 'no stylesheet, no key');
  finally
    LJson.Free;
  end;
end;

procedure TThemeTests.CssForStyleTag_CannotCloseTheElement;
var
  LCss: string;
begin
  LCss := THelpChatPanel.CssForStyleTag('a{}</style><script>alert(1)</script>');
  Assert.AreEqual(-1, LCss.IndexOf('</'), LCss);
  Assert.AreEqual('.x{color:red}', THelpChatPanel.CssForStyleTag('.x{color:red}'));
end;

procedure TThemeTests.PanelCss_EmptyName_MissingFile_AndAFile;
var
  LFile: string;
begin
  Assert.AreEqual('', THelpChatPanel.PanelCss('  '));
  Assert.WillRaise(
    procedure
    begin
      THelpChatPanel.PanelCss(TPath.Combine(TPath.GetTempPath, 'hc-no-such-file.css'));
    end, EHelpChatConfigError);
  LFile := TPath.Combine(TPath.GetTempPath, 'hc-panel-test.css');
  TFile.WriteAllText(LFile, '.hc-chat-bubble{border-radius:2px}', TEncoding.UTF8);
  try
    Assert.AreEqual('.hc-chat-bubble{border-radius:2px}', THelpChatPanel.PanelCss(LFile).Trim([#$FEFF]));
  finally
    TFile.Delete(LFile);
  end;
end;

end.
