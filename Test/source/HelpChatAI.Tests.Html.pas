unit HelpChatAI.Tests.Html;

interface

uses
  DUnitX.TestFramework,
  HelpChatAI.Types,
  HelpChatAI.Html;

type
  [TestFixture]
  THtmlTests = class
  public
    [Test] procedure TextToHtml_EscapesAndBreaksLines;
    [Test] procedure Markdown_RendersBasicStructure;
    [Test] procedure Markdown_RendersGfmTables;
    [Test] procedure Markdown_NeutralizesActiveHtml;
    [Test] procedure Markdown_BlocksDangerousLinkTargets;
    [Test] procedure IsSafeUrl_Rules;
    [Test] procedure SanitizeUrls_RewritesOnlyUnsafe;
    [Test] procedure Markdown_Empty_IsEmpty;
    [Test] procedure AutoLink_BareUrls;
    [Test] procedure Bubble_PendingEmpty_ShowsTyping;
    [Test] procedure Bubble_PendingWithText_ShowsPartial;
    [Test] procedure Bubble_Error;
    [Test] procedure Bubble_User_IsPlainText;
    [Test] procedure Bubble_Assistant_IsMarkdown;
    [Test] procedure Greeting_And_History;
  end;

implementation

uses
  System.SysUtils;

procedure THtmlTests.TextToHtml_EscapesAndBreaksLines;
begin
  Assert.AreEqual('&lt;b&gt;x&lt;/b&gt; &amp; y', HelpChatTextToHtml('<b>x</b> & y'));
  Assert.AreEqual('a<br>b<br>c<br>d', HelpChatTextToHtml('a'#13#10'b'#10'c'#13'd'));
  Assert.AreEqual('', HelpChatTextToHtml(''));
end;

procedure THtmlTests.Markdown_RendersBasicStructure;
var
  LHtml: string;
begin
  LHtml := HelpChatMarkdownToSafeHtml('**Orders**'#10#10'Some text with [a link](https://docs.example.com/x.html).'#10#10'- one'#10'- two');
  Assert.Contains(LHtml, '<strong>Orders</strong>');
  Assert.Contains(LHtml, 'href="https://docs.example.com/x.html"');
  Assert.Contains(LHtml, '<li>');
  Assert.Contains(LHtml, '<p>');
end;

procedure THtmlTests.Markdown_RendersGfmTables;
var
  LHtml: string;
begin
  // I modelli rispondono spesso con una tabella: deve diventare una tabella.
  LHtml := HelpChatMarkdownToSafeHtml(
    '| Column | Meaning |'#10 +
    '| --- | --- |'#10 +
    '| New | Nobody has called yet |'#10 +
    '| Active | Being worked on |');
  Assert.Contains(LHtml, '<table', 'the pipes are a table, not text');
  Assert.Contains(LHtml, '<th', 'the first row is the header');
  Assert.Contains(LHtml, 'Nobody has called yet');
  Assert.DoesNotContain(LHtml, '| New |', 'no raw pipes left');
  // le altre estensioni GFM che un modello usa
  LHtml := HelpChatMarkdownToSafeHtml('~~gone~~ and a list:'#10'- [x] done'#10'- [ ] todo');
  Assert.Contains(LHtml, '<del', 'strikethrough');
  Assert.DoesNotContain(LHtml, '[x]', 'task list markers are rendered');
end;

procedure THtmlTests.Markdown_NeutralizesActiveHtml;
var
  LHtml: string;
begin
  LHtml := HelpChatMarkdownToSafeHtml('Hi <script>alert(1)</script> and <iframe src="x"></iframe>');
  Assert.DoesNotContain(LHtml, '<script>');
  Assert.DoesNotContain(LHtml, '<iframe');
  Assert.Contains(LHtml, 'alert(1)', 'the text survives, escaped');
end;

procedure THtmlTests.Markdown_BlocksDangerousLinkTargets;
var
  LHtml: string;
begin
  LHtml := HelpChatMarkdownToSafeHtml('[click](javascript:alert(1))');
  Assert.DoesNotContain(LHtml.ToLower, 'javascript:');
  Assert.Contains(LHtml, 'href="#"');
  Assert.Contains(LHtml, '>click</a>', 'the link text survives');
  LHtml := HelpChatMarkdownToSafeHtml('![x](data:text/html;base64,AAAA)');
  Assert.DoesNotContain(LHtml.ToLower, 'data:');
  LHtml := HelpChatMarkdownToSafeHtml('[ok](https://docs.example.com/a.html) and [rel](grid/export.html)');
  Assert.Contains(LHtml, 'href="https://docs.example.com/a.html"');
  Assert.Contains(LHtml, 'href="grid/export.html"');
end;

procedure THtmlTests.IsSafeUrl_Rules;
begin
  Assert.IsTrue(HelpChatIsSafeUrl('https://a.b/c'));
  Assert.IsTrue(HelpChatIsSafeUrl('http://a.b'));
  Assert.IsTrue(HelpChatIsSafeUrl('mailto:x@y.z'));
  Assert.IsTrue(HelpChatIsSafeUrl('#top'));
  Assert.IsTrue(HelpChatIsSafeUrl('/docs/a.html'));
  Assert.IsTrue(HelpChatIsSafeUrl('grid/export.html'));
  Assert.IsTrue(HelpChatIsSafeUrl('page.html?x=1:2'), 'colon after the query start is not a scheme');
  Assert.IsTrue(HelpChatIsSafeUrl(''));
  Assert.IsFalse(HelpChatIsSafeUrl('javascript:alert(1)'));
  Assert.IsFalse(HelpChatIsSafeUrl('JavaScript:alert(1)'));
  Assert.IsFalse(HelpChatIsSafeUrl(' java'#9'script:alert(1)'), 'whitespace and control chars are stripped first');
  Assert.IsFalse(HelpChatIsSafeUrl('java&#115;cript:alert(1)'), 'entities are decoded first');
  Assert.IsFalse(HelpChatIsSafeUrl('data:text/html,<b>x</b>'));
  Assert.IsFalse(HelpChatIsSafeUrl('vbscript:msgbox'));
  Assert.IsFalse(HelpChatIsSafeUrl('file:///C:/x'));
end;

procedure THtmlTests.SanitizeUrls_RewritesOnlyUnsafe;
begin
  Assert.AreEqual('<a href="#">x</a><a href="https://ok">y</a>',
    HelpChatSanitizeUrls('<a href="javascript:x()">x</a><a href="https://ok">y</a>'));
  Assert.AreEqual('<img src="#" alt="i">',
    HelpChatSanitizeUrls('<img src=''data:image/png;base64,AA'' alt="i">'));
  Assert.AreEqual('<a HREF="#">x</a>', HelpChatSanitizeUrls('<a HREF="JAVASCRIPT:x">x</a>'));
  Assert.AreEqual('plain text', HelpChatSanitizeUrls('plain text'));
end;

procedure THtmlTests.AutoLink_BareUrls;
var
  LHtml: string;
begin
  // The way a model writes it: no Markdown syntax, punctuation glued to the URL.
  LHtml := HelpChatMarkdownToSafeHtml('Per maggiori dettagli: https://help.example.com/crm/Leads.html.');
  Assert.Contains(LHtml, '<a href="https://help.example.com/crm/Leads.html">https://help.example.com/crm/Leads.html</a>.');

  // Query strings keep their (encoded) ampersand; a comma ends the link.
  LHtml := HelpChatMarkdownToSafeHtml('see http://x.example.com/a?b=1&c=2, then');
  Assert.Contains(LHtml, '<a href="http://x.example.com/a?b=1&amp;c=2">http://x.example.com/a?b=1&amp;c=2</a>, then');

  // Already a link, or inside code: untouched (no nested anchors).
  LHtml := HelpChatMarkdownToSafeHtml('[doc](https://docs.example.com/x.html) and <https://docs.example.com/y.html> and `https://docs.example.com/z.html`');
  Assert.AreEqual(2, Integer(Length(LHtml.Split(['<a '])) - 1), LHtml);
  Assert.Contains(LHtml, '<code>https://docs.example.com/z.html</code>');

  // Plain text and no URL: identity.
  Assert.AreEqual('<p>nothing here</p>', HelpChatAutoLinkUrls('<p>nothing here</p>'));
  Assert.AreEqual('<pre><code>https://a.b/c</code></pre>', HelpChatAutoLinkUrls('<pre><code>https://a.b/c</code></pre>'));
end;

procedure THtmlTests.Markdown_Empty_IsEmpty;
begin
  Assert.AreEqual('', HelpChatMarkdownToSafeHtml(''));
  Assert.AreEqual('', HelpChatMarkdownToSafeHtml('   '#10));
end;

procedure THtmlTests.Bubble_PendingEmpty_ShowsTyping;
var
  LMessage: THelpChatMessage;
  LHtml: string;
begin
  LMessage := Default(THelpChatMessage);
  LMessage.Id := 'abc';
  LMessage.Role := hcrAssistant;
  LMessage.Pending := True;
  LHtml := HelpChatRenderBubble(LMessage);
  Assert.Contains(LHtml, 'data-msgid="abc"');
  Assert.Contains(LHtml, 'data-pending="1"');
  Assert.Contains(LHtml, HELPCHAT_CSS_PREFIX + '-typing');
  Assert.Contains(LHtml, HELPCHAT_CSS_PREFIX + '-assistant');
  Assert.DoesNotContain(LHtml, 'data-error');
end;

procedure THtmlTests.Bubble_PendingWithText_ShowsPartial;
var
  LMessage: THelpChatMessage;
  LHtml: string;
begin
  LMessage := Default(THelpChatMessage);
  LMessage.Id := 'abc';
  LMessage.Role := hcrAssistant;
  LMessage.Pending := True;
  LMessage.Content := 'Partial **bold**';
  LHtml := HelpChatRenderBubble(LMessage);
  Assert.Contains(LHtml, 'data-pending="1"');
  Assert.Contains(LHtml, '<strong>bold</strong>');
  Assert.DoesNotContain(LHtml, HELPCHAT_CSS_PREFIX + '-typing');
end;

procedure THtmlTests.Bubble_Error;
var
  LMessage: THelpChatMessage;
  LHtml: string;
begin
  LMessage := Default(THelpChatMessage);
  LMessage.Id := 'e1';
  LMessage.Role := hcrAssistant;
  LMessage.IsError := True;
  LMessage.Content := 'HTTP <401>';
  LHtml := HelpChatRenderBubble(LMessage);
  Assert.Contains(LHtml, 'data-error="1"');
  Assert.Contains(LHtml, HELPCHAT_CSS_PREFIX + '-msg-error');
  Assert.Contains(LHtml, 'HTTP &lt;401&gt;', 'errors are plain text');
  Assert.DoesNotContain(LHtml, 'data-pending');
end;

procedure THtmlTests.Bubble_User_IsPlainText;
var
  LMessage: THelpChatMessage;
  LHtml: string;
begin
  LMessage := Default(THelpChatMessage);
  LMessage.Id := 'u1';
  LMessage.Role := hcrUser;
  LMessage.Content := '**not bold** <i>x</i>';
  LHtml := HelpChatRenderBubble(LMessage);
  Assert.Contains(LHtml, HELPCHAT_CSS_PREFIX + '-user');
  Assert.Contains(LHtml, '**not bold** &lt;i&gt;x&lt;/i&gt;', 'what the user writes is never interpreted');
  Assert.DoesNotContain(LHtml, 'data-pending');
  Assert.DoesNotContain(LHtml, 'data-error');
end;

procedure THtmlTests.Bubble_Assistant_IsMarkdown;
var
  LMessage: THelpChatMessage;
  LHtml: string;
begin
  LMessage := Default(THelpChatMessage);
  LMessage.Id := 'a1';
  LMessage.Role := hcrAssistant;
  LMessage.Content := 'Use `Export`.';
  LHtml := HelpChatRenderBubble(LMessage);
  Assert.Contains(LHtml, '<code>Export</code>');
end;

procedure THtmlTests.Greeting_And_History;
var
  LMessages: TArray<THelpChatMessage>;
  LHtml: string;
begin
  LHtml := HelpChatRenderHistory(nil, 'Hi <there>');
  Assert.Contains(LHtml, HELPCHAT_CSS_PREFIX + '-greeting');
  Assert.Contains(LHtml, 'Hi &lt;there&gt;');

  SetLength(LMessages, 2);
  LMessages[0].Id := '1'; LMessages[0].Role := hcrUser; LMessages[0].Content := 'q';
  LMessages[1].Id := '2'; LMessages[1].Role := hcrAssistant; LMessages[1].Content := 'a';
  LHtml := HelpChatRenderHistory(LMessages, 'greeting');
  Assert.DoesNotContain(LHtml, HELPCHAT_CSS_PREFIX + '-greeting');
  Assert.Contains(LHtml, 'data-msgid="1"');
  Assert.Contains(LHtml, 'data-msgid="2"');
end;

end.
