unit HelpChatAI.Tests.Panel;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Panel;

type
  [TestFixture]
  TPanelTests = class
  public
    [Test] procedure Resources_AreLinked;
    [Test] procedure Labels_AreLocalized;
    [Test] procedure Config_HasTokenAndLabels;
    [Test] procedure Page_IsComplete_NoPlaceholdersLeft;
    [Test] procedure Page_EscapesLabels;
    [Test] procedure Page_ThemeIsInjectedAfterTheStylesheet;
    [Test] procedure Assistant_EmptyNameFollowsTheLanguage;
    [Test] procedure Page_CarriesTheAssistantNameAndIcon;
    [Test] procedure Page_TakesOnlyADataImageIcon;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  HelpChatAI.Messages,
  HelpChatAI.Theme;

procedure TPanelTests.Resources_AreLinked;
begin
  Assert.IsTrue(THelpChatPanel.HasResources, 'HelpChatAI.Panel.res must be linked (run Tools\BuildResources.cmd)');
  Assert.Contains(THelpChatPanel.LoadResourceText(HELPCHAT_RES_HTML), '<!DOCTYPE html>');
  Assert.Contains(THelpChatPanel.LoadResourceText(HELPCHAT_RES_CSS), '.hc-chat-bubble');
  Assert.Contains(THelpChatPanel.LoadResourceText(HELPCHAT_RES_JS), 'window.hcAsk');
  Assert.Contains(THelpChatPanel.LoadResourceText(HELPCHAT_RES_HTMX), 'htmx');
end;

procedure TPanelTests.Labels_AreLocalized;
var
  LJson: TJSONObject;
begin
  LJson := TJSONObject.ParseJSONValue(THelpChatPanel.LabelsJson(hclItalian)) as TJSONObject;
  try
    Assert.AreEqual('Assistente', LJson.GetValue<string>('title'));
    Assert.AreEqual('Invia', LJson.GetValue<string>('send'));
    Assert.AreEqual(HelpChatMsg(hcmUiSendError, hclItalian), LJson.GetValue<string>('sendError'));
  finally
    LJson.Free;
  end;
  LJson := TJSONObject.ParseJSONValue(THelpChatPanel.LabelsJson(hclEnglish)) as TJSONObject;
  try
    Assert.AreEqual('Assistant', LJson.GetValue<string>('title'));
  finally
    LJson.Free;
  end;
end;

procedure TPanelTests.Config_HasTokenAndLabels;
var
  LOptions: THelpChatPanelOptions;
  LJson: TJSONObject;
begin
  LOptions := THelpChatPanelOptions.Default;
  LOptions.Token := 'abc123';
  LOptions.Language := hclEnglish;
  LOptions.PollIntervalMs := 500;
  LOptions.MaxPolls := 42;
  LJson := TJSONObject.ParseJSONValue(THelpChatPanel.ConfigJson(LOptions)) as TJSONObject;
  try
    Assert.AreEqual('abc123', LJson.GetValue<string>('token'));
    Assert.AreEqual('', LJson.GetValue<string>('apiBase'));
    Assert.AreEqual(500, LJson.GetValue<Integer>('pollMs'));
    Assert.AreEqual(42, LJson.GetValue<Integer>('maxPolls'));
    Assert.AreEqual('en', LJson.GetValue<string>('lang'));
    Assert.AreEqual('Send', (LJson.GetValue('labels') as TJSONObject).GetValue<string>('send'));
  finally
    LJson.Free;
  end;
end;

procedure TPanelTests.Page_IsComplete_NoPlaceholdersLeft;
var
  LOptions: THelpChatPanelOptions;
  LPage: string;
begin
  LOptions := THelpChatPanelOptions.Default;
  LOptions.Token := 'tok';
  LOptions.Language := hclItalian;
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.DoesNotContain(LPage, '{{', 'every placeholder must be substituted');
  Assert.Contains(LPage, '<html lang="it">');
  Assert.Contains(LPage, '<title>Assistente</title>');
  Assert.Contains(LPage, '"token":"tok"');
  Assert.Contains(LPage, 'hx-get="/api/history"');
  Assert.Contains(LPage, 'hx-post="/api/send"');
  Assert.Contains(LPage, 'X-HelpChat-Token', 'the script sends the token header');
  Assert.Contains(LPage, 'var htmx=function()', 'htmx inlined');
  Assert.Contains(LPage, '.hc-chat-bubble', 'css inlined');
end;

procedure TPanelTests.Page_EscapesLabels;
var
  LOptions: THelpChatPanelOptions;
  LPage: string;
begin
  LOptions := THelpChatPanelOptions.Default;
  LOptions.Token := 'tok';
  LOptions.Language := hclEnglish;
  LOptions.ApiBase := 'https://help.example.com/chat';
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.Contains(LPage, 'hx-post="https://help.example.com/chat/api/send"');
  Assert.Contains(LPage, '"apiBase":"https://help.example.com/chat"');
  Assert.Contains(LPage, 'placeholder="Ask a question about the application..."');
end;

procedure TPanelTests.Assistant_EmptyNameFollowsTheLanguage;
begin
  Assert.AreEqual('Assistant', THelpChatPanel.AssistantNameOf('', hclEnglish));
  Assert.AreEqual('Assistente', THelpChatPanel.AssistantNameOf('', hclItalian));
  Assert.AreEqual('Assistente', THelpChatPanel.AssistantNameOf('   ', hclItalian),
    'blanks are not a name');
  Assert.AreEqual('Aida', THelpChatPanel.AssistantNameOf('  Aida  ', hclItalian),
    'what the application chose wins, trimmed');
end;

procedure TPanelTests.Page_CarriesTheAssistantNameAndIcon;
const
  // A one pixel PNG is enough: what matters is that it reaches the src.
  ICON = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==';
var
  LOptions: THelpChatPanelOptions;
  LPage: string;
  LJson: TJSONObject;
begin
  LOptions := THelpChatPanelOptions.Default;
  LOptions.Token := 'tok';
  LOptions.Language := hclItalian;
  LOptions.AssistantName := 'Aida';
  LOptions.AssistantIcon := ICON;
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.DoesNotContain(LPage, '{{');
  Assert.Contains(LPage, '<title>Aida</title>');
  Assert.Contains(LPage, '<span class="hc-chat-title">Aida</span>');
  Assert.Contains(LPage, '<img class="hc-chat-icon" src="' + ICON + '"');
  Assert.IsTrue(LPage.IndexOf('hc-chat-icon') < LPage.IndexOf('hc-chat-title'),
    'the icon is drawn left of the name');

  LJson := TJSONObject.ParseJSONValue(
    THelpChatPanel.LabelsJson(hclItalian, 'Aida')) as TJSONObject;
  try
    Assert.AreEqual('Aida', LJson.GetValue<string>('title'),
      'the labels of the page carry the same name');
  finally
    LJson.Free;
  end;

  // Nothing set: the localized default, and no icon at all.
  LOptions.AssistantName := '';
  LOptions.AssistantIcon := '';
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.Contains(LPage, '<title>Assistente</title>');
  Assert.DoesNotContain(LPage, '<img class="hc-chat-icon"',
    'no icon: no img at all - the class itself stays in the stylesheet');
end;

procedure TPanelTests.Page_TakesOnlyADataImageIcon;
var
  LOptions: THelpChatPanelOptions;
begin
  LOptions := THelpChatPanelOptions.Default;
  // The CSP of the page allows 'self' and data: for an image, so anything else
  // would be a broken icon at best; and a value that is not a URI at all must
  // never become markup.
  Assert.AreEqual('', THelpChatPanel.AssistantIconTag(''));
  Assert.AreEqual('', THelpChatPanel.AssistantIconTag('https://example.com/a.png'));
  Assert.AreEqual('', THelpChatPanel.AssistantIconTag('javascript:alert(1)'));
  Assert.AreEqual('', THelpChatPanel.AssistantIconTag('"><script>alert(1)</script>'));
  Assert.Contains(THelpChatPanel.AssistantIconTag('data:image/png;base64,AAA'),
    'src="data:image/png;base64,AAA"');

  LOptions.AssistantName := '<b>x</b>';
  Assert.Contains(THelpChatPanel.RenderPage(LOptions), '&lt;b&gt;x&lt;/b&gt;',
    'the name is text, not markup');
end;

procedure TPanelTests.Page_ThemeIsInjectedAfterTheStylesheet;
var
  LOptions: THelpChatPanelOptions;
  LPage: string;
begin
  LOptions := THelpChatPanelOptions.Default;
  LOptions.Token := 'tok';
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.Contains(LPage, '<style id="hc-theme"></style>', 'no theme: empty rule, page defaults apply');

  LOptions.Theme := THelpChatTheme.Dark;
  LPage := THelpChatPanel.RenderPage(LOptions);
  Assert.Contains(LPage, '<style id="hc-theme">:root{--hc-bg:#17191d;');
  Assert.IsTrue(LPage.IndexOf('id="hc-theme"') > LPage.IndexOf('.hc-chat-bubble'), 'the theme rule comes after the stylesheet so it wins');
  Assert.Contains(LPage, 'window.hcApplyTheme', 'runtime re-theming entry point');
end;

end.
