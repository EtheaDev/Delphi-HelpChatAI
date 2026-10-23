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
  end;

implementation

uses
  System.SysUtils,
  System.JSON;

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
    Assert.AreEqual(18, LJson.Count, '17 variables + color-scheme');
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

end.
