{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
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
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  HTML rendering of chat messages as fragments the panel inserts into its
///  DOM: safe Markdown to HTML for assistant replies (CommonMark, safe mode:
///  script/iframe/object and friends are escaped, never emitted), plain-text
///  encoding for user, system and error messages. Transport-agnostic: the
///  local HTTP server, a remote server and the FMX bridge all emit the same
///  fragments. The reply of a model is untrusted content that ends up inside a
///  WebView with a bridge to native code: safe mode is not optional.
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

/// <summary>Markdown to a safe HTML fragment (CommonMark, active HTML escaped,
/// link and image URLs restricted to <see cref="HelpChatIsSafeUrl" />).
/// Tolerant of partial input, so it also renders the growing partial of a
/// streaming reply. On any error it falls back to HTML-encoded text.</summary>
function HelpChatMarkdownToSafeHtml(const AMarkdown: string): string;

/// <summary>True for URLs a chat bubble may link to: http(s), mailto, ftp(s),
/// anchors and relative paths. Anything with another scheme (javascript:,
/// data:, vbscript:, file:...) is rejected. Entity-encoded and whitespace-padded
/// schemes are normalized before the check.</summary>
function HelpChatIsSafeUrl(const AUrl: string): Boolean;

/// <summary>Rewrites every href/src attribute of an HTML fragment whose URL is
/// not <see cref="HelpChatIsSafeUrl" /> to "#" (the original is dropped). The
/// Markdown library escapes active elements but not dangerous link targets.</summary>
function HelpChatSanitizeUrls(const AHtml: string): string;

/// <summary>Turns bare http(s) URLs in the text of an HTML fragment into
/// links. Models often write "see https://..." without Markdown syntax and
/// CommonMark leaves it as text. Text inside a, code and pre elements and
/// inside tags is left alone; trailing punctuation stays outside the link.</summary>
function HelpChatAutoLinkUrls(const AHtml: string): string;

/// <summary>CSS class fragment of a role: user, assistant, system.</summary>
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
/// </summary>
function HelpChatRenderBubble(const AMessage: THelpChatMessage): string;

/// <summary>Renders the greeting as an assistant bubble with the greeting class.</summary>
function HelpChatRenderGreeting(const AGreeting: string): string;

/// <summary>Renders the whole conversation, or the greeting when it is empty.</summary>
function HelpChatRenderHistory(const AMessages: TArray<THelpChatMessage>;
  const AGreeting: string): string;

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
    // GFM, non CommonMark: i modelli rispondono con tabelle, barrato e
    // liste di spunta, e CommonMark le stamperebbe come testo coi pipe.
    // GFM in piu' vieta l'HTML grezzo pericoloso, che e' una garanzia in piu'
    // sopra al safe mode.
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

end.
