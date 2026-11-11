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
///  HTML rendering of chat messages as fragments the panel inserts into its
///  DOM: safe Markdown to HTML for assistant replies (GitHub Flavored
///  Markdown, safe mode: script/iframe/object and friends are escaped, never
///  emitted), plain-text encoding for user, system and error messages.
///  Transport-agnostic: the local HTTP server and a remote server emit the
///  same fragments, for the VCL and the FMX panel alike. The reply of a model
///  is untrusted content that ends up inside a WebView whose page can ask
///  things of the application: safe mode is not optional.
///
///  The unit also builds the printable documents (an answer, a conversation,
///  a page of the manual) the client turns into a PDF. It needs the message
///  record of <c>HelpChatAI.Types</c> and the Markdown processor, and nothing
///  else of the library: no engine, no settings, no language - localized
///  labels are passed in. Every routine is stateless and safe to call from
///  any thread.
/// </summary>
unit HelpChatAI.Html;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  HelpChatAI.Types;

const
  /// <summary>CSS class prefix of every element the engine emits.</summary>
  HELPCHAT_CSS_PREFIX = 'hc-chat';

/// <summary>Plain text to HTML: encodes the text and turns newlines into &lt;br&gt;.</summary>
function HelpChatTextToHtml(const AText: string): string;

/// <summary>Markdown to a safe HTML fragment (the GFM dialect - models answer
/// with tables, strikethrough and task lists, which CommonMark prints as
/// text - active HTML escaped, link and image URLs restricted to
/// <see cref="HelpChatIsSafeUrl" />, bare URLs turned into links).
/// Tolerant of partial input, so it also renders the growing partial of a
/// streaming reply. Never raises: on any error it falls back to HTML-encoded
/// text. Empty for blank input. The only way model output, a documentation
/// page or anything else written in Markdown may reach the page.</summary>
function HelpChatMarkdownToSafeHtml(const AMarkdown: string): string;

/// <summary>True for URLs a chat bubble may link to: http(s), mailto, ftp(s),
/// anchors and relative paths. Anything with another scheme (javascript:,
/// data:, vbscript:, file:...) is rejected. Entity-encoded and whitespace-padded
/// schemes are normalized before the check.</summary>
function HelpChatIsSafeUrl(const AUrl: string): Boolean;

/// <summary>Rewrites every href/src attribute of an HTML fragment whose URL is
/// not <see cref="HelpChatIsSafeUrl" /> to "#" (the original is dropped), and
/// an empty one too - <c>href=""</c> reloads the page, and a blocked link
/// must look dead. The Markdown engine blanks a dangerous target itself in
/// safe mode; this is the second layer, which does not rely on the first.
/// Only quoted attribute values are looked at, which is what that engine
/// writes.</summary>
function HelpChatSanitizeUrls(const AHtml: string): string;

/// <summary>Turns bare http(s) URLs in the text of an HTML fragment into
/// links. Models often write "see https://..." without Markdown syntax and
/// the Markdown engine leaves it as text. Text inside a, code and pre
/// elements and inside tags is left alone; trailing punctuation stays
/// outside the link.
/// The input must be HTML already (entity-encoded text): it is what
/// <see cref="HelpChatMarkdownToSafeHtml" /> produces, not raw text.</summary>
function HelpChatAutoLinkUrls(const AHtml: string): string;

/// <summary>CSS class fragment of a role: user, assistant, system. Anything
/// that is neither user nor assistant is drawn as system.</summary>
function HelpChatRoleClass(const ARole: THelpChatRole): string;

/// <summary>
///  Renders one message as a bubble:
///  <code>
///  &lt;div class="hc-chat-msg hc-chat-{role}[ hc-chat-msg-error]" data-msgid="..."
///       [data-pending="1"] [data-error="1"]&gt;&lt;div class="hc-chat-bubble"&gt;...&lt;/div&gt;&lt;/div&gt;
///  </code>
///  <c>data-pending</c> is the contract with the client: while present, keep
///  polling; when it disappears, stop. An empty pending bubble shows the typing
///  indicator.
///
///  Who wrote the content decides how it is rendered: a reply of the
///  assistant, pending or complete, is Markdown in safe mode; a question, a
///  system message and an error are plain text, never Markdown - an error
///  even when its role is the assistant's. The message id is written into
///  the attribute unencoded: it is expected to be an id the store generated
///  (a persisted conversation brings back the ids its file holds).
/// </summary>
function HelpChatRenderBubble(const AMessage: THelpChatMessage): string;

/// <summary>Renders the greeting as an assistant bubble with the greeting
/// class. Plain text, and no <c>data-msgid</c>: the greeting is not a message
/// of the conversation, so it is neither polled nor counted.</summary>
function HelpChatRenderGreeting(const AGreeting: string): string;

/// <summary>Renders the whole conversation, or the greeting when it is empty.</summary>
function HelpChatRenderHistory(const AMessages: TArray<THelpChatMessage>;
  const AGreeting: string): string;

type
  /// <summary>
  ///  A whole HTML document to print, as opposed to the fragments the panel
  ///  swaps into its page. Self-contained on purpose: the stylesheet is
  ///  written inline and the images are expected to be <c>data:</c> URIs
  ///  already, because what renders it is a WebView2 that loads the document
  ///  as a string and has nowhere to fetch a relative file from.
  /// </summary>
  THelpChatPrintableDoc = record
    /// <summary>Document title: the window title and, when
    /// <see cref="ShowTitle" />, the heading at the top.</summary>
    Title: string;
    /// <summary>One line under the title: the application, the date.</summary>
    Subtitle: string;
    /// <summary>Language of the document ("en", "it"), for hyphenation.</summary>
    LangCode: string;
    /// <summary>The stylesheet, written inline.</summary>
    Css: string;
    /// <summary>The body, already HTML.</summary>
    BodyHtml: string;
    /// <summary>Print the title block. Off when the body already opens with
    /// the title of the document, which an answer in Markdown usually
    /// does.</summary>
    ShowTitle: Boolean;
    /// <summary>The complete page, from doctype to closing tag. Title,
    /// subtitle and language are encoded; <c>Css</c> and <c>BodyHtml</c>
    /// are written as they are, so the body must already be safe HTML and
    /// the stylesheet is trusted - it is the application's own file. An
    /// empty <c>LangCode</c> is English.</summary>
    function Render: string;
  end;

/// <summary>A printable document out of Markdown (the answer of a model, a
/// page of the manual): the Markdown goes through
/// <see cref="HelpChatMarkdownToSafeHtml" />, exactly like a bubble - what the
/// model writes is untrusted on paper too. The title block is left out when
/// the Markdown opens with its own first-level heading. Subtitle and
/// language are left for the caller to fill.</summary>
function HelpChatMarkdownDocument(const ATitle, AMarkdown, ACss: string): THelpChatPrintableDoc;

/// <summary>A printable document out of a conversation: one block per turn,
/// the question as text and the answer as Markdown. The two labels are the
/// localized names of who speaks, because this unit knows no language.
/// Pending replies, errors and empty messages are skipped; a system message
/// becomes a note between the turns. An empty <c>BodyHtml</c> means there
/// was nothing worth printing.</summary>
function HelpChatConversationDocument(const ATitle: string;
  const AMessages: TArray<THelpChatMessage>;
  const ACss, AUserLabel, AAssistantLabel: string): THelpChatPrintableDoc;

implementation

uses
  System.NetEncoding,
  System.StrUtils,
  System.RegularExpressions,
  MarkdownProcessor,
  MarkdownUtils;

function HelpChatTextToHtml(const AText: string): string;
begin
  Result := TNetEncoding.HTML.Encode(AText);
  Result := StringReplace(Result, #13#10, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '<br>', [rfReplaceAll]);
end;

function HelpChatIsSafeUrl(const AUrl: string): Boolean;
var
  LUrl: string;
  C: Char;
  LColon, LSlash: Integer;
begin
  // Normalize what a browser would tolerate: entities, control chars, spaces.
  LUrl := '';
  for C in TNetEncoding.HTML.Decode(AUrl) do
    if Ord(C) > 32 then
      LUrl := LUrl + C;
  if LUrl = '' then
    Exit(True); // empty: harmless
  LUrl := LUrl.ToLower;
  if LUrl.StartsWith('#') or LUrl.StartsWith('/') or LUrl.StartsWith('./') or LUrl.StartsWith('../') then
    Exit(True);
  if LUrl.StartsWith('http://') or LUrl.StartsWith('https://') or LUrl.StartsWith('mailto:') or
     LUrl.StartsWith('ftp://') or LUrl.StartsWith('ftps://') then
    Exit(True);
  // No scheme at all (no ':' before the first '/', '?' or '#'): a relative path.
  LColon := LUrl.IndexOf(':');
  if LColon < 0 then
    Exit(True);
  LSlash := LUrl.IndexOfAny(['/', '?', '#']);
  Result := (LSlash >= 0) and (LSlash < LColon);
end;

type
  // TMatchEvaluator is a method pointer ("of object"), hence the tiny holder.
  TUrlAttributeSanitizer = class
    function Evaluate(const AMatch: TMatch): string;
  end;

function TUrlAttributeSanitizer.Evaluate(const AMatch: TMatch): string;
var
  LQuoted, LUrl: string;
begin
  // Group 2 is the quoted value, whichever quote was used: strip the delimiters
  // (the optional inner groups are not reliable across RTL versions).
  LQuoted := AMatch.Groups[2].Value;
  LUrl := LQuoted.Substring(1, LQuoted.Length - 2);
  // An empty target is what the Markdown engine leaves behind when it drops a
  // dangerous one in safe mode. It is not dangerous, but href="" reloads the
  // page: the dead anchor is what a blocked link is supposed to look like.
  if Trim(LUrl) = '' then
    Result := AMatch.Groups[1].Value + '"#"'
  else if HelpChatIsSafeUrl(LUrl) then
    Result := AMatch.Value
  else
    Result := AMatch.Groups[1].Value + '"#"';
end;

function HelpChatSanitizeUrls(const AHtml: string): string;
var
  LSanitizer: TUrlAttributeSanitizer;
begin
  // (href|src) = "..." or '...': the value is checked, never rewritten in
  // place; an unsafe target becomes a harmless anchor.
  LSanitizer := TUrlAttributeSanitizer.Create;
  try
    Result := TRegEx.Replace(AHtml, '(\b(?:href|src)\s*=\s*)("[^"]*"|''[^'']*'')',
      LSanitizer.Evaluate, [roIgnoreCase]);
  finally
    LSanitizer.Free;
  end;
end;

type
  // Same reason as TUrlAttributeSanitizer: the evaluator must be a method.
  TBareUrlLinker = class
    function Evaluate(const AMatch: TMatch): string;
  end;

function TBareUrlLinker.Evaluate(const AMatch: TMatch): string;
var
  LUrl, LTail: string;
begin
  LUrl := AMatch.Value;
  // Sentence punctuation glued to the URL is not part of it; a closing
  // parenthesis is kept only when the URL opened one (Wikipedia-style).
  LTail := '';
  while (LUrl <> '') and CharInSet(LUrl[LUrl.Length], ['.', ',', ';', ':', '!', '?', ')', ']', #39, '"']) do
  begin
    if (LUrl[LUrl.Length] = ')') and (LUrl.CountChar('(') >= LUrl.CountChar(')')) then
      Break;
    LTail := LUrl[LUrl.Length] + LTail;
    LUrl := LUrl.Substring(0, LUrl.Length - 1);
  end;
  // The text is already entity-encoded (& is &amp;): valid as-is in an attribute.
  Result := '<a href="' + LUrl + '">' + LUrl + '</a>' + LTail;
end;

function HelpChatAutoLinkUrls(const AHtml: string): string;
var
  LLinker: TBareUrlLinker;
  LUrlRegEx: TRegEx;
  LBuilder: TStringBuilder;
  LPos, LTagStart, LTagEnd, LDepth: Integer;
  LTag, LName: string;
begin
  // Called for every poll of a streaming reply: most fragments have no URL
  // at all, and those cost one scan.
  if not AHtml.Contains('http') then
    Exit(AHtml);
  LLinker := TBareUrlLinker.Create;
  LBuilder := TStringBuilder.Create(AHtml.Length + 64);
  try
    LUrlRegEx := TRegEx.Create('https?://[^\s<>"'']+', [roIgnoreCase]);
    LDepth := 0; // nesting of a/code/pre: text inside them is left alone
    LPos := 0;
    while LPos < AHtml.Length do
    begin
      LTagStart := AHtml.IndexOf('<', LPos);
      if LTagStart < 0 then
        LTagStart := AHtml.Length;
      if LTagStart > LPos then
      begin
        if LDepth > 0 then
          LBuilder.Append(AHtml, LPos, LTagStart - LPos)
        else
          LBuilder.Append(LUrlRegEx.Replace(AHtml.Substring(LPos, LTagStart - LPos), LLinker.Evaluate));
      end;
      if LTagStart >= AHtml.Length then
        Break;
      LTagEnd := AHtml.IndexOf('>', LTagStart);
      if LTagEnd < 0 then
        LTagEnd := AHtml.Length - 1;
      LTag := AHtml.Substring(LTagStart, LTagEnd - LTagStart + 1);
      LBuilder.Append(LTag);
      // "<a ...>", "</a>", "<code>", "<pre ...>" — the name is the first token.
      LName := LTag.TrimLeft(['<', '/']).ToLower;
      LName := LName.Substring(0, LName.IndexOfAny([' ', '>', '/', #9, #10, #13]));
      if (LName = 'a') or (LName = 'code') or (LName = 'pre') then
      begin
        if LTag.StartsWith('</') then
        begin
          if LDepth > 0 then
            Dec(LDepth);
        end
        else
          Inc(LDepth);
      end;
      LPos := LTagEnd + 1;
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
    LLinker.Free;
  end;
end;

function HelpChatMarkdownToSafeHtml(const AMarkdown: string): string;
var
  LProcessor: TMarkdownProcessor;
begin
  if Trim(AMarkdown) = '' then
    Exit('');
  try
    // GFM, not CommonMark: models answer with tables, strikethrough and task
    // lists, and CommonMark would print them as text full of pipes. GFM also
    // forbids the dangerous raw HTML, one guarantee more on top of safe mode.
    // A processor per call: it is not shared between threads.
    LProcessor := TMarkdownProcessor.CreateDialect(mdGFM);
    try
      LProcessor.AllowUnsafe := False;
      Result := HelpChatAutoLinkUrls(HelpChatSanitizeUrls(LProcessor.Process(AMarkdown)));
    finally
      LProcessor.Free;
    end;
  except
    Result := HelpChatTextToHtml(AMarkdown);
  end;
end;

function HelpChatRoleClass(const ARole: THelpChatRole): string;
begin
  case ARole of
    hcrUser: Result := 'user';
    hcrAssistant: Result := 'assistant';
  else
    Result := 'system';
  end;
end;

function HelpChatRenderBubble(const AMessage: THelpChatMessage): string;
var
  LExtra, LBody: string;
begin
  LExtra := '';
  if AMessage.Pending then
  begin
    LExtra := ' data-pending="1"';
    if AMessage.Content <> '' then
      LBody := HelpChatMarkdownToSafeHtml(AMessage.Content)
    else
      LBody := '<span class="' + HELPCHAT_CSS_PREFIX + '-typing"><span></span><span></span><span></span></span>';
  end
  else if AMessage.IsError then
  begin
    LExtra := ' data-error="1"';
    LBody := HelpChatTextToHtml(AMessage.Content);
  end
  else if AMessage.Role = hcrAssistant then
    LBody := HelpChatMarkdownToSafeHtml(AMessage.Content)
  else
    LBody := HelpChatTextToHtml(AMessage.Content);

  Result :=
    '<div class="' + HELPCHAT_CSS_PREFIX + '-msg ' + HELPCHAT_CSS_PREFIX + '-' + HelpChatRoleClass(AMessage.Role) +
      IfThen(AMessage.IsError, ' ' + HELPCHAT_CSS_PREFIX + '-msg-error', '') + '"' +
      ' data-msgid="' + AMessage.Id + '"' + LExtra + '>' +
      '<div class="' + HELPCHAT_CSS_PREFIX + '-bubble">' + LBody + '</div>' +
    '</div>';
end;

function HelpChatRenderGreeting(const AGreeting: string): string;
begin
  Result :=
    '<div class="' + HELPCHAT_CSS_PREFIX + '-msg ' + HELPCHAT_CSS_PREFIX + '-assistant ' +
      HELPCHAT_CSS_PREFIX + '-greeting">' +
      '<div class="' + HELPCHAT_CSS_PREFIX + '-bubble">' + HelpChatTextToHtml(AGreeting) + '</div>' +
    '</div>';
end;

function HelpChatRenderHistory(const AMessages: TArray<THelpChatMessage>;
  const AGreeting: string): string;
var
  LMessage: THelpChatMessage;
  LSb: TStringBuilder;
begin
  if Length(AMessages) = 0 then
    Exit(HelpChatRenderGreeting(AGreeting));
  LSb := TStringBuilder.Create;
  try
    for LMessage in AMessages do
      LSb.Append(HelpChatRenderBubble(LMessage));
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

{ THelpChatPrintableDoc }

function THelpChatPrintableDoc.Render: string;
var
  LSb: TStringBuilder;
  LLang: string;
begin
  LSb := TStringBuilder.Create;
  try
    LLang := LangCode;
    if LLang = '' then
      LLang := 'en';
    LSb.Append('<!doctype html>'#13#10);
    LSb.Append('<html lang="').Append(TNetEncoding.HTML.Encode(LLang)).Append('">'#13#10);
    LSb.Append('<head>'#13#10);
    LSb.Append('<meta charset="utf-8">'#13#10);
    LSb.Append('<title>').Append(TNetEncoding.HTML.Encode(Title)).Append('</title>'#13#10);
    LSb.Append('<style>'#13#10).Append(Css).Append(#13#10'</style>'#13#10);
    LSb.Append('</head>'#13#10);
    LSb.Append('<body><article class="hc-doc">'#13#10);
    if ShowTitle and (Title.Trim <> '') then
    begin
      LSb.Append('<header class="hc-doc-head"><h1>');
      LSb.Append(TNetEncoding.HTML.Encode(Title)).Append('</h1>');
      if Subtitle.Trim <> '' then
        LSb.Append('<div class="hc-doc-meta">')
          .Append(TNetEncoding.HTML.Encode(Subtitle)).Append('</div>');
      LSb.Append('</header>'#13#10);
    end;
    LSb.Append(BodyHtml);
    LSb.Append(#13#10'</article></body></html>');
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

function HelpChatMarkdownDocument(const ATitle, AMarkdown, ACss: string): THelpChatPrintableDoc;
begin
  Result := Default(THelpChatPrintableDoc);
  Result.Title := ATitle;
  Result.Css := ACss;
  Result.BodyHtml := HelpChatMarkdownToSafeHtml(AMarkdown);
  // A document written by a model nearly always opens with its own "# Title":
  // a title block on top of it would say the same thing twice. A "##" is a
  // section, not the title of the document, so that one keeps its block.
  Result.ShowTitle := not AMarkdown.TrimLeft.StartsWith('# ');
end;

function HelpChatConversationDocument(const ATitle: string;
  const AMessages: TArray<THelpChatMessage>;
  const ACss, AUserLabel, AAssistantLabel: string): THelpChatPrintableDoc;
var
  LMessage: THelpChatMessage;
  LSb: TStringBuilder;
begin
  Result := Default(THelpChatPrintableDoc);
  Result.Title := ATitle;
  Result.Css := ACss;
  Result.ShowTitle := True;
  LSb := TStringBuilder.Create;
  try
    for LMessage in AMessages do
    begin
      // A reply still being written, and the errors, are not part of a
      // document somebody files away.
      if LMessage.Pending or LMessage.IsError or (LMessage.Content.Trim = '') then
        Continue;
      if LMessage.Role = hcrSystem then
      begin
        LSb.Append('<p class="hc-doc-note">')
          .Append(HelpChatTextToHtml(LMessage.Content)).Append('</p>'#13#10);
        Continue;
      end;
      LSb.Append('<section class="hc-doc-turn hc-doc-turn-')
        .Append(HelpChatRoleClass(LMessage.Role)).Append('">'#13#10);
      LSb.Append('<div class="hc-doc-who">');
      if LMessage.Role = hcrUser then
        LSb.Append(TNetEncoding.HTML.Encode(AUserLabel))
      else
        LSb.Append(TNetEncoding.HTML.Encode(AAssistantLabel));
      LSb.Append('</div>'#13#10);
      LSb.Append('<div class="hc-doc-body">');
      if LMessage.Role = hcrUser then
        LSb.Append('<p>').Append(HelpChatTextToHtml(LMessage.Content)).Append('</p>')
      else
        LSb.Append(HelpChatMarkdownToSafeHtml(LMessage.Content));
      LSb.Append('</div>'#13#10'</section>'#13#10);
    end;
    Result.BodyHtml := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

end.
