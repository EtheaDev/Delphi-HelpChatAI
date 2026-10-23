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
