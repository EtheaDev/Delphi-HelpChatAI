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
///  The HTML panel: one self-contained page (HTML + CSS + htmx + the panel
///  script, all compiled into <c>HelpChatAI.Panel.res</c> from the
///  <c>resources</c> folder) rendered with the labels of the configured
///  language, the API secret and the polling parameters. The same page is
///  served by the local HTTP server and by a remote one: the API contract
///  (paths, token header, form fields) is defined here, and
///  <c>resources/panel.js</c> is its other half.
///
///  Nothing in this unit knows the engine, the settings or a provider: it
///  takes a <see cref="THelpChatPanelOptions" /> and returns text. Whatever
///  answers the paths below with the fragments <c>HelpChatAI.Html</c> renders
///  can serve this page.
///
///  Some paths say "assistant" where the library now says "model": until 1.7
///  what the panel switches between was called an assistant, and the paths
///  kept their names on purpose: they are a contract, and renaming one breaks
///  whoever calls it.
/// </summary>
unit HelpChatAI.Panel;

{$I HelpChatAI.inc}

{$R HelpChatAI.Panel.res}

interface

uses
  System.SysUtils,
  System.Classes,
  HelpChatAI.Messages,
  HelpChatAI.Attachments,
  HelpChatAI.Theme;

const
  /// <summary>Header every API call must carry; its value is the per-process
  /// secret the page received in its URL. Without it any local process, or
  /// any page open in the user's browser, could drive the assistant.</summary>
  HELPCHAT_TOKEN_HEADER = 'X-HelpChat-Token';
  /// <summary>Query parameter carrying the secret to the panel page.</summary>
  HELPCHAT_TOKEN_QUERY = 't';
  /// <summary>Everything below this prefix needs the token header; the page
  /// itself (<c>/</c>) takes the token from its query instead.</summary>
  HELPCHAT_API_PREFIX = '/api/';
  /// <summary>GET: the whole conversation as HTML bubbles, or the greeting
  /// when it is empty. The page asks for it when it loads.</summary>
  HELPCHAT_API_HISTORY = '/api/history';
  /// <summary>POST <c>message=</c>: records the question and answers at once
  /// with two bubbles, the question and the pending reply
  /// (<c>data-pending</c>, which the page then polls). An empty body for an
  /// empty message. The request never waits for the model.</summary>
  HELPCHAT_API_SEND = '/api/send';
  /// <summary>GET /api/poll/{message id}: that bubble as it is now - the
  /// growing partial while it is pending, the final one once. Empty for an
  /// id that is not of this conversation.</summary>
  HELPCHAT_API_POLL = '/api/poll/';
  /// <summary>POST /api/cancel/{message id}: stops that reply and answers
  /// with its bubble. Only a reply of the caller's own conversation.</summary>
  HELPCHAT_API_CANCEL = '/api/cancel/';
  /// <summary>POST: stops the pending replies, empties the conversation and
  /// its attachments, answers with the greeting bubble.</summary>
  HELPCHAT_API_CLEAR = '/api/clear';
  /// <summary>POST /api/ui/{command}: the page asks the host something it cannot
  /// do itself ('close'). The transport hands it to the UI layer.</summary>
  HELPCHAT_API_UI = '/api/ui/';
  /// <summary>The UI command a local server raises by itself after the
  /// language of the chat changed: the host rewrites the captions it owns
  /// (its window, the hint of the bubble) while the page reloads.</summary>
  HELPCHAT_UI_LANGUAGE = 'language';
  /// <summary>The UI command a local server raises by itself after the user
  /// switched model in the panel (the badge, or /use): the host may need to
  /// know - a model whose key is missing is something the application can
  /// ask for. The components turn it into <c>OnModelChanged</c>.</summary>
  HELPCHAT_UI_MODEL = 'model';
  /// <summary>POST /api/context: the native client hands the transport the screen
  /// the user is on. Local transports keep it in memory; a remote one posts it.</summary>
  HELPCHAT_API_CONTEXT = '/api/context';
  /// <summary>POST /api/theme: the colours of the host application, so a page
  /// (re)load is already themed.</summary>
  HELPCHAT_API_THEME = '/api/theme';
  /// <summary>POST /api/assistant: the name and the icon the panel writes in its
  /// header. They belong to the client for the same reason the theme does - an
  /// image list is a VCL object, and only the client knows which one the
  /// application gave the bubble.</summary>
  HELPCHAT_API_ASSISTANT = '/api/assistant';
  /// <summary>GET: the models the user may switch between
  /// (<c>Settings.Models</c>), as JSON (<c>items</c> with name, provider,
  /// model, icon id, the icon as SVG and <c>active</c>; <c>active</c> the
  /// name in use; <c>canSelect</c> whether a POST to
  /// <see cref="HELPCHAT_API_ASSISTANT_SELECT" /> is accepted). The path and
  /// the constant say "assistants", the name these had before 1.7, and stay
  /// that way: the assistant is now the profile, which no endpoint
  /// switches.</summary>
  HELPCHAT_API_ASSISTANTS = '/api/assistants';
  /// <summary>POST <c>name=</c>: makes that model the one in use for the
  /// questions that follow - of every panel on the same engine, since the
  /// choice is the engine's - and answers with the list as above. 404 for a
  /// name that is not in the list, 403 when the server does not let a client
  /// choose (a remote engine is everybody's). Same old name as
  /// <see cref="HELPCHAT_API_ASSISTANTS" />.</summary>
  HELPCHAT_API_ASSISTANT_SELECT = '/api/assistant/select';
  /// <summary>GET: the languages the user may pick, as JSON (<c>items</c> with
  /// the ISO <c>code</c>, the <c>name</c> in that language, the English
  /// <c>english</c>, the round flag as <c>svg</c> and <c>active</c>;
  /// <c>canSelect</c> whether a POST to
  /// <see cref="HELPCHAT_API_LANGUAGE_SELECT" /> is accepted).</summary>
  HELPCHAT_API_LANGUAGES = '/api/languages';
  /// <summary>POST <c>code=</c>: makes that language the language of the chat
  /// and answers with the list as above; the page then reloads itself, since
  /// its labels are written into it. 404 for a language that is not offered,
  /// 403 when the server does not let a client choose (a remote engine is
  /// everybody's, exactly as for the model).</summary>
  HELPCHAT_API_LANGUAGE_SELECT = '/api/language/select';
  /// <summary>GET: every slash command, as JSON (<c>name</c>, localized
  /// <c>title</c> and <c>description</c>, <c>local</c> when the page answers
  /// it by itself, <c>enabled</c> when the user may type it). The host may
  /// run the others (<c>window.hcCommand(line, true)</c>). See
  /// <c>HelpChatAI.Commands</c>.</summary>
  HELPCHAT_API_COMMANDS = '/api/commands';
  /// <summary>POST <c>name=</c>, <c>args=</c>: answers a command of the
  /// engine with <c>{"html": ...}</c>, the content of a system bubble. 403
  /// for a command that does not exist, or that the session does not enable
  /// unless <c>host=1</c> says the application asked for it, which only a
  /// server living in the application's own process accepts.</summary>
  HELPCHAT_API_COMMAND = '/api/command';
  /// <summary>GET /api/doc?page=...: a page of the documentation folder as an
  /// HTML fragment (&lt;article class="hc-chat-doc-page" data-page data-title&gt;),
  /// 404 when it is not one.</summary>
  HELPCHAT_API_DOC = '/api/doc';
  /// <summary>Query parameter of /api/doc.</summary>
  HELPCHAT_DOC_QUERY = 'page';
  /// <summary>POST /api/attach?name=...: the bytes of a file the user picked,
  /// as the whole body (no multipart: Indy would not decode it, and a chat
  /// sends one file at a time anyway). Answers a JSON object - the attachment
  /// as the page draws it, or <c>{"error":"..."}</c> with the sentence to
  /// show, which is also what a refused type gets.</summary>
  HELPCHAT_API_ATTACH = '/api/attach';
  /// <summary>POST /api/attach/remove, form field <c>id</c>: the user took an
  /// attachment away before asking.</summary>
  HELPCHAT_API_ATTACH_REMOVE = '/api/attach/remove';
  /// <summary>GET /api/attachments: what this conversation currently holds,
  /// as <c>{"items":[...]}</c>. The page asks for it when it loads, the way
  /// it asks for the history: the attachments belong to the conversation, so
  /// a reload - a VCL style change recreates the window and reloads the page -
  /// must not lose sight of documents that are still being sent.</summary>
  HELPCHAT_API_ATTACHMENTS = '/api/attachments';
  /// <summary>Query parameter of /api/attach carrying the file name.</summary>
  HELPCHAT_ATTACH_NAME_QUERY = 'name';
  /// <summary>Form field of /api/attach/remove.</summary>
  HELPCHAT_FIELD_ATTACH_ID = 'id';
  /// <summary>POST /session opens a conversation on a remote server and
  /// returns its token as JSON (<c>session</c>, <c>token</c>, <c>pollMs</c>,
  /// <c>maxPolls</c>, <c>lang</c>). Called by the native client, never by
  /// the page; a local server has no such route.</summary>
  HELPCHAT_SESSION_PATH = '/session';
  /// <summary>POST /session/end, with the token header: closes that
  /// session.</summary>
  HELPCHAT_SESSION_END_PATH = '/session/end';
  /// <summary>Header carrying the application key to a remote server.</summary>
  HELPCHAT_KEY_HEADER = 'X-HelpChat-Key';
  /// <summary>Form field of the message in POST /api/send.</summary>
  HELPCHAT_FIELD_MESSAGE = 'message';
  /// <summary>How often the page asks for a pending bubble, in
  /// milliseconds.</summary>
  HELPCHAT_DEF_POLL_MS = 800;
  /// <summary>Poll attempts before the client gives up on a pending bubble
  /// (900 x 800 ms = 12 minutes: bounded, unlike the KittoX original).</summary>
  HELPCHAT_DEF_MAX_POLLS = 900;

  /// <summary>POST /api/pdf: the page asks for a document to be saved as
  /// PDF. The engine builds it, the client prints it - only the client has a
  /// browser engine and a place to put the file. 403 when PDF is off, 501
  /// when no host in the server's process can print (a remote engine), 404
  /// when there is nothing to print.</summary>
  HELPCHAT_API_PDF = '/api/pdf';
  /// <summary>What to print: answer, conversation or page.</summary>
  HELPCHAT_FIELD_PDF_KIND = 'kind';
  /// <summary>The message id, or the documentation page.</summary>
  HELPCHAT_FIELD_PDF_ID = 'id';
  /// <summary>The three values of <c>kind</c>: one completed answer (its
  /// message id in <c>id</c>), the whole conversation (no id), a page of the
  /// documentation folder (its name in <c>id</c>).</summary>
  HELPCHAT_PDF_KIND_ANSWER = 'answer';
  HELPCHAT_PDF_KIND_CONVERSATION = 'conversation';
  HELPCHAT_PDF_KIND_PAGE = 'page';

  /// <summary>Names of the RCDATA resources of <c>HelpChatAI.Panel.res</c>:
  /// the page, its stylesheet, its script and htmx, each from the file of
  /// the same kind in <c>resources</c>.</summary>
  HELPCHAT_RES_HTML = 'HELPCHAT_PANEL_HTML';
  HELPCHAT_RES_CSS = 'HELPCHAT_PANEL_CSS';
  HELPCHAT_RES_JS = 'HELPCHAT_PANEL_JS';
  HELPCHAT_RES_HTMX = 'HELPCHAT_HTMX_JS';
  /// <summary>The stylesheet of a printable document - not of the panel:
  /// a PDF has no bubbles and no theme.</summary>
  HELPCHAT_RES_PRINTCSS = 'HELPCHAT_PRINT_CSS';
  /// <summary>The two bands printed on every sheet
  /// (<c>print-header.html</c>, <c>print-footer.html</c>).</summary>
  HELPCHAT_RES_PRINTHEADER = 'HELPCHAT_PRINT_HEADER';
  HELPCHAT_RES_PRINTFOOTER = 'HELPCHAT_PRINT_FOOTER';

type
  /// <summary>
  ///  Everything that varies from one rendering of the page to the next: who
  ///  may call the API, in which language the labels are written, where the
  ///  host listens, how the page looks and which buttons it offers. A server
  ///  fills one per request from its session and its engine; the page keeps
  ///  what it was rendered with until it is reloaded.
  /// </summary>
  THelpChatPanelOptions = record
    /// <summary>Secret the page sends back in the token header.</summary>
    Token: string;
    /// <summary>Language of the labels, written into the page when it is
    /// rendered - which is why a change of language reloads it.
    /// <c>hclAuto</c> resolves to the language of the process.</summary>
    Language: THelpChatLanguage;
    /// <summary>Base of the API URLs; empty = same origin as the page.</summary>
    ApiBase: string;
    /// <summary>Where the page posts what it asks of its host (/api/ui/...).
    /// Empty = the API origin itself (local transport). With a remote server it
    /// is the loopback host channel of the client.</summary>
    UiBase: string;
    /// <summary>Token of the host channel; empty = the API token.</summary>
    UiToken: string;
    /// <summary>False when no host is reachable: Esc does not close (the
    /// application closes the panel its own way) and the PDF buttons are not
    /// shown. The page has no close button of its own either way. Both
    /// servers serve True today, a remote one too.</summary>
    HostCommands: Boolean;
    /// <summary>Milliseconds between two polls of a pending bubble.</summary>
    PollIntervalMs: Integer;
    /// <summary>Polls after which the page gives up on a pending bubble, so
    /// that a reply that never completes does not poll for ever.</summary>
    MaxPolls: Integer;
    /// <summary>Colours of the host application; empty = the page defaults
    /// (light/dark from the OS preference).</summary>
    Theme: THelpChatTheme;
    /// <summary>The same colours already rendered as CSS, which wins over
    /// <c>Theme</c> when set: what a remote client sends its server, since the
    /// theme is produced by the framework running on the client.</summary>
    ThemeCss: string;
    /// <summary>True when the server renders documentation pages (/api/doc):
    /// the page then opens page links in its documentation view.</summary>
    DocsAvailable: Boolean;
    /// <summary>Prefix of the documentation links (<c>Settings.DocBaseUrl</c>):
    /// a link starting with it is a page too.</summary>
    DocBaseUrl: string;
    /// <summary>Name written in the header of the panel; empty = the localized
    /// <c>hcmUiTitle</c> ("Assistant" / "Assistente").</summary>
    AssistantName: string;
    /// <summary>True when the panel offers the paper clip: the engine accepts
    /// attachments (<c>Settings.Attachments.Enabled</c>) and the configured
    /// provider can read documents. False = no clip, and the page never posts
    /// to /api/attach.</summary>
    AttachmentsEnabled: Boolean;
    /// <summary>Largest attachment in KB, so the page can refuse an oversized
    /// file before uploading it. 0 = no limit.</summary>
    AttachMaxKB: Integer;
    /// <summary>What the file dialog of the page offers (".pdf,.png,...").</summary>
    AttachAccept: string;
    /// <summary>Show the buttons that save an answer, a documentation page or
    /// the conversation as PDF.</summary>
    PdfEnabled: Boolean;
    /// <summary>Icon drawn left of the name, as a <c>data:image/...</c> URI -
    /// the only kind the page may load, since its CSP allows images from
    /// <c>'self'</c> and <c>data:</c> alone. Empty = no icon.</summary>
    AssistantIcon: string;
    /// <summary>Everything empty or off, except what a page cannot work
    /// without: host commands on, the default polling parameters, the
    /// language of the process. Start from this, never from an uninitialized
    /// record.</summary>
    class function Default: THelpChatPanelOptions; static;
  end;

  /// <summary>
  ///  The page and its pieces, as class functions: there is no state, so any
  ///  thread may call them - the servers do, from their connection threads.
  ///  The resources are read from the module this unit is linked into, the
  ///  engine package when packages are used.
  /// </summary>
  THelpChatPanel = class
  public
    /// <summary>Text of an RCDATA resource of this module (UTF-8, BOM tolerated).
    /// Raises when the resource is missing (the .res was not linked).</summary>
    class function LoadResourceText(const AName: string): string; static;
    /// <summary>True when the panel resources are linked into this module.</summary>
    class function HasResources: Boolean; static;
    /// <summary>The name the header shows: <c>AName</c> trimmed, or the
    /// localized <c>hcmUiTitle</c> when it is empty. One place decides it, so
    /// the page, the labels and the components cannot disagree.</summary>
    class function AssistantNameOf(const AName: string;
      const ALanguage: THelpChatLanguage): string; static;
    /// <summary>The <c>img</c> tag of the header icon, empty when there is no
    /// icon. Only a <c>data:image/</c> URI is accepted: it is what the CSP of
    /// the page allows, and it keeps a wrong value from becoming markup.</summary>
    class function AssistantIconTag(const AIconDataUri: string): string; static;
    /// <summary>Every sentence <c>panel.js</c> writes by itself, as a JSON
    /// object in <c>ALanguage</c>: the tooltips, what the page answers to the
    /// commands it handles alone, the messages about attachments, copying
    /// and PDF. The page has no table of strings of its own, so a label it
    /// needs is added here. <c>title</c> is the assistant name, resolved as
    /// <c>AssistantNameOf</c> does.</summary>
    class function LabelsJson(const ALanguage: THelpChatLanguage;
      const AAssistantName: string = ''): string; static;
    /// <summary>The configuration object the page reads as window.HC: the
    /// options under the names <c>panel.js</c> knows them by, plus
    /// <c>labels</c>. A new option the script must see is added here.</summary>
    class function ConfigJson(const AOptions: THelpChatPanelOptions): string; static;
    /// <summary>The complete panel page: <c>panel.html</c> with stylesheet,
    /// htmx, script, configuration and theme written into it, so that it
    /// loads nothing else. <c>ApiBase</c> and <c>UiBase</c> also go into its
    /// Content-Security-Policy, which is the list of the only origins the
    /// page may call. Raises <c>EResNotFound</c> when the resources are not
    /// linked.</summary>
    class function RenderPage(const AOptions: THelpChatPanelOptions): string; static;
    /// <summary>The stylesheet a printable document is built with: the file
    /// the application named in <c>PdfStyleSheet</c>, or the built-in one when
    /// it did not. A named file that is not there raises, exactly like a named
    /// configuration file: an application that asked for its own look and
    /// prints with ours is an application shipped with the wrong files. A
    /// relative path resolves against the executable.</summary>
    class function PrintCss(const AStyleSheetFile: string = ''): string; static;
    /// <summary>The CSS of the file the application named in
    /// <c>PanelStyleSheet</c>, '' when it named none; a relative path
    /// resolves against the executable. A named file that is not there
    /// raises <c>EHelpChatConfigError</c>: the application asked for a look
    /// and would run with another.</summary>
    class function PanelCss(const AStyleSheetFile: string): string; static;
    /// <summary>CSS made safe to sit inside a &lt;style&gt; element: a
    /// "&lt;/" cannot close it. The theme of a remote session is posted by a
    /// client, and the stylesheet comes from a file.</summary>
    class function CssForStyleTag(const ACss: string): string; static;
    /// <summary>The band printed at the top of every sheet, as HTML: the file
    /// the application named in <c>PdfHeaderFile</c>, or the built-in one. It
    /// is a little document of its own - the stylesheet of the page does not
    /// reach it - and it still carries its placeholders, which
    /// <see cref="HelpChatPdfExpand" /> replaces. Same rule as
    /// <see cref="PrintCss" /> for a named file that is not there.</summary>
    class function PrintHeader(const AHeaderFile: string = ''): string; static;
    /// <summary>The band printed at the foot of every sheet. See
    /// <see cref="PrintHeader" />.</summary>
    class function PrintFooter(const AFooterFile: string = ''): string; static;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.NetEncoding,
  System.Types,
  HelpChatAI.Types;

{ THelpChatPanelOptions }

class function THelpChatPanelOptions.Default: THelpChatPanelOptions;
begin
  Result := System.Default(THelpChatPanelOptions);
  Result.Language := hclAuto;
  Result.HostCommands := True;
  Result.PollIntervalMs := HELPCHAT_DEF_POLL_MS;
  Result.MaxPolls := HELPCHAT_DEF_MAX_POLLS;
end;

{ THelpChatPanel }

class function THelpChatPanel.HasResources: Boolean;
begin
  Result := FindResource(HInstance, PChar(HELPCHAT_RES_HTML), RT_RCDATA) <> 0;
end;

class function THelpChatPanel.LoadResourceText(const AName: string): string;
var
  LStream: TResourceStream;
  LBytes: TBytes;
  LOffset: Integer;
  LEncoding: TEncoding;
begin
  if FindResource(HInstance, PChar(AName), RT_RCDATA) = 0 then
    raise EResNotFound.CreateFmt('HelpChat panel resource not found: %s (is HelpChatAI.Panel.res linked?)', [AName]);
  LStream := TResourceStream.Create(HInstance, AName, RT_RCDATA);
  try
    SetLength(LBytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(LBytes[0], LStream.Size);
  finally
    LStream.Free;
  end;
  LEncoding := nil;
  LOffset := TEncoding.GetBufferEncoding(LBytes, LEncoding, TEncoding.UTF8);
  Result := LEncoding.GetString(LBytes, LOffset, Length(LBytes) - LOffset);
end;

class function THelpChatPanel.AssistantNameOf(const AName: string;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := AName.Trim;
  if Result = '' then
    Result := HelpChatMsg(hcmUiTitle, ALanguage);
end;

class function THelpChatPanel.AssistantIconTag(const AIconDataUri: string): string;
var
  LUri: string;
begin
  Result := '';
  LUri := AIconDataUri.Trim;
  if (LUri = '') or not LUri.ToLower.StartsWith('data:image/') then
    Exit;
  Result := '<img class="hc-chat-icon" src="' + TNetEncoding.HTML.Encode(LUri) +
    '" alt="" aria-hidden="true">';
end;

class function THelpChatPanel.LabelsJson(const ALanguage: THelpChatLanguage;
  const AAssistantName: string = ''): string;
var
  LRoot: TJSONObject;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('title', AssistantNameOf(AAssistantName, ALanguage));
    LRoot.AddPair('help', HelpChatMsg(hcmUiHelp, ALanguage));
    LRoot.AddPair('clear', HelpChatMsg(hcmUiClear, ALanguage));
    LRoot.AddPair('close', HelpChatMsg(hcmUiClose, ALanguage));
    LRoot.AddPair('placeholder', HelpChatMsg(hcmUiPlaceholder, ALanguage));
    LRoot.AddPair('send', HelpChatMsg(hcmUiSend, ALanguage));
    LRoot.AddPair('stop', HelpChatMsg(hcmUiStop, ALanguage));
    LRoot.AddPair('retry', HelpChatMsg(hcmUiRetry, ALanguage));
    LRoot.AddPair('sendError', HelpChatMsg(hcmUiSendError, ALanguage));
    LRoot.AddPair('back', HelpChatMsg(hcmUiBack, ALanguage));
    LRoot.AddPair('changeAssistant', HelpChatMsg(hcmUiChangeAssistant, ALanguage));
    LRoot.AddPair('changeLanguage', HelpChatMsg(hcmUiChangeLanguage, ALanguage));
    // What the page says about the commands it answers by itself.
    LRoot.AddPair('cmdUnknown', HelpChatMsg(hcmCmdUnknown, ALanguage));
    LRoot.AddPair('cmdNoAssistant', HelpChatMsg(hcmCmdNoAssistant, ALanguage));
    LRoot.AddPair('cmdNoLanguage', HelpChatMsg(hcmCmdNoLanguage, ALanguage));
    LRoot.AddPair('cmdNoQuestion', HelpChatMsg(hcmCmdNoQuestion, ALanguage));
    LRoot.AddPair('cmdStats', HelpChatMsg(hcmCmdStatsLine, ALanguage));
    LRoot.AddPair('cmdNoStats', HelpChatMsg(hcmCmdNoStats, ALanguage));
    LRoot.AddPair('cmdDocUsage', HelpChatMsg(hcmCmdDocUsage, ALanguage));
    LRoot.AddPair('cmdUseUsage', HelpChatMsg(hcmCmdUseUsage, ALanguage));
    LRoot.AddPair('cmdNoAnswer', HelpChatMsg(hcmCmdNoAnswer, ALanguage));
    LRoot.AddPair('docNotFound', HelpChatMsg(hcmDocNotFound, ALanguage));
    LRoot.AddPair('attach', HelpChatMsg(hcmUiAttach, ALanguage));
    LRoot.AddPair('attachRemove', HelpChatMsg(hcmUiAttachRemove, ALanguage));
    LRoot.AddPair('attachFailed', HelpChatMsg(hcmAttachFailed, ALanguage));
    LRoot.AddPair('pdfAnswer', HelpChatMsg(hcmUiPdfAnswer, ALanguage));
    LRoot.AddPair('pdfConversation', HelpChatMsg(hcmUiPdfConversation, ALanguage));
    LRoot.AddPair('pdfPage', HelpChatMsg(hcmUiPdfPage, ALanguage));
    LRoot.AddPair('copyAnswer', HelpChatMsg(hcmUiCopyAnswer, ALanguage));
    LRoot.AddPair('copyConversation', HelpChatMsg(hcmUiCopyConversation, ALanguage));
    LRoot.AddPair('copyPage', HelpChatMsg(hcmUiCopyPage, ALanguage));
    LRoot.AddPair('copied', HelpChatMsg(hcmUiCopied, ALanguage));
    LRoot.AddPair('copyFailed', HelpChatMsg(hcmUiCopyFailed, ALanguage));
    // The two sides of a conversation: the same words the printed
    // document uses, because the clipboard carries the same thing.
    LRoot.AddPair('roleUser', HelpChatMsg(hcmPdfUser, ALanguage));
    LRoot.AddPair('roleAssistant', HelpChatMsg(hcmPdfAssistant, ALanguage));
    LRoot.AddPair('pdfNothing', HelpChatMsg(hcmPdfNothing, ALanguage));
    LRoot.AddPair('pdfUnavailable', HelpChatMsg(hcmPdfUnavailable, ALanguage));
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatPanel.ConfigJson(const AOptions: THelpChatPanelOptions): string;
var
  LRoot: TJSONObject;
  LLabels: TJSONValue;
begin
  LRoot := TJSONObject.Create;
  try
    LRoot.AddPair('token', AOptions.Token);
    LRoot.AddPair('apiBase', AOptions.ApiBase);
    LRoot.AddPair('uiBase', AOptions.UiBase);
    LRoot.AddPair('uiToken', AOptions.UiToken);
    LRoot.AddPair('hostCommands', TJSONBool.Create(AOptions.HostCommands));
    LRoot.AddPair('pollMs', TJSONNumber.Create(AOptions.PollIntervalMs));
    LRoot.AddPair('maxPolls', TJSONNumber.Create(AOptions.MaxPolls));
    LRoot.AddPair('lang', HelpChatLanguageCode(AOptions.Language));
    LRoot.AddPair('docs', TJSONBool.Create(AOptions.DocsAvailable));
    LRoot.AddPair('docBase', AOptions.DocBaseUrl);
    LRoot.AddPair('attach', TJSONBool.Create(AOptions.AttachmentsEnabled));
    LRoot.AddPair('attachMaxKB', TJSONNumber.Create(AOptions.AttachMaxKB));
    LRoot.AddPair('attachAccept', AOptions.AttachAccept);
    LRoot.AddPair('pdf', TJSONBool.Create(AOptions.PdfEnabled));
    // Already carrying the limit, so the page can refuse an oversized file
    // without transferring it: what is left for it to fill in is the name.
    if AOptions.AttachMaxKB > 0 then
      LRoot.AddPair('attachTooLarge',
        Format(HelpChatMsg(hcmAttachTooLarge, AOptions.Language),
          ['%s', HelpChatFormatSize(Int64(AOptions.AttachMaxKB) * 1024)]));
    LLabels := TJSONObject.ParseJSONValue(
      LabelsJson(AOptions.Language, AOptions.AssistantName));
    LRoot.AddPair('labels', LLabels);
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatPanel.RenderPage(const AOptions: THelpChatPanelOptions): string;

  function Attr(const AId: THelpChatMsgId): string;
  begin
    Result := TNetEncoding.HTML.Encode(HelpChatMsg(AId, AOptions.Language));
  end;

begin
  // The placeholders are replaced one after the other on the growing page:
  // a value written in is scanned by the replacements that follow it. The
  // values a client can set (name, theme) are encoded for where they land,
  // not checked for the name of a later placeholder.
  Result := LoadResourceText(HELPCHAT_RES_HTML);
  Result := Result.Replace('{{LANG}}', HelpChatLanguageCode(AOptions.Language));
  // The same name in the document title and in the header of the panel.
  Result := Result.Replace('{{TITLE}}', TNetEncoding.HTML.Encode(
    AssistantNameOf(AOptions.AssistantName, AOptions.Language)));
  Result := Result.Replace('{{ICON}}', AssistantIconTag(AOptions.AssistantIcon));
  Result := Result.Replace('{{L_CLEAR}}', Attr(hcmUiClear));
  Result := Result.Replace('{{L_PLACEHOLDER}}', Attr(hcmUiPlaceholder));
  Result := Result.Replace('{{L_SEND}}', Attr(hcmUiSend));
  Result := Result.Replace('{{L_STOP}}', Attr(hcmUiStop));
  Result := Result.Replace('{{L_BACK}}', Attr(hcmUiBack));
  Result := Result.Replace('{{L_ATTACH}}', Attr(hcmUiAttach));
  Result := Result.Replace('{{API_BASE}}', TNetEncoding.HTML.Encode(AOptions.ApiBase));
  // The page may only talk to its API and, when there is one, to the loopback
  // channel of its host: the policy names both, and nothing else.
  Result := Result.Replace('{{UI_BASE}}', TNetEncoding.HTML.Encode(AOptions.UiBase));
  Result := Result.Replace('{{CONFIG}}', ConfigJson(AOptions));
  Result := Result.Replace('{{CSS}}', LoadResourceText(HELPCHAT_RES_CSS));
  // After the default stylesheet: the host theme overrides the --hc-* variables.
  // The application's stylesheet travels in it, ahead of the colours.
  if AOptions.ThemeCss <> '' then
    Result := Result.Replace('{{THEME_CSS}}', CssForStyleTag(AOptions.ThemeCss))
  else
    Result := Result.Replace('{{THEME_CSS}}', CssForStyleTag(AOptions.Theme.ToCss));
  Result := Result.Replace('{{HTMX}}', LoadResourceText(HELPCHAT_RES_HTMX));
  Result := Result.Replace('{{JS}}', LoadResourceText(HELPCHAT_RES_JS));
end;

/// <summary>A file of the application or the resource behind it. The three
/// pieces a printed document is made of follow the same rule, so the rule is
/// written once.</summary>
function PrintPart(const AFileName, AResource, AWhat: string): string;
var
  LFileName: string;
begin
  LFileName := AFileName.Trim;
  if LFileName = '' then
    Exit(THelpChatPanel.LoadResourceText(AResource));
  if not TPath.IsPathRooted(LFileName) then
    LFileName := TPath.Combine(ExtractFilePath(ParamStr(0)), LFileName);
  if not TFile.Exists(LFileName) then
    raise EHelpChatConfigError.CreateFmt('The PDF %s "%s" was not found',
      [AWhat, LFileName]);
  Result := TFile.ReadAllText(LFileName, TEncoding.UTF8);
end;

class function THelpChatPanel.PrintCss(const AStyleSheetFile: string): string;
begin
  Result := PrintPart(AStyleSheetFile, HELPCHAT_RES_PRINTCSS, 'stylesheet');
end;

class function THelpChatPanel.PanelCss(const AStyleSheetFile: string): string;
var
  LFileName: string;
begin
  LFileName := AStyleSheetFile.Trim;
  if LFileName = '' then
    Exit('');
  if not TPath.IsPathRooted(LFileName) then
    LFileName := TPath.Combine(ExtractFilePath(ParamStr(0)), LFileName);
  if not TFile.Exists(LFileName) then
    raise EHelpChatConfigError.CreateFmt('The panel stylesheet "%s" was not found',
      [LFileName]);
  Result := TFile.ReadAllText(LFileName, TEncoding.UTF8);
end;

class function THelpChatPanel.CssForStyleTag(const ACss: string): string;
begin
  // "<\/" is still "</" to CSS (an escaped solidus), never the end of the tag.
  Result := StringReplace(ACss, '</', '<\/', [rfReplaceAll]);
end;

class function THelpChatPanel.PrintHeader(const AHeaderFile: string): string;
begin
  Result := PrintPart(AHeaderFile, HELPCHAT_RES_PRINTHEADER, 'header');
end;

class function THelpChatPanel.PrintFooter(const AFooterFile: string): string;
begin
  Result := PrintPart(AFooterFile, HELPCHAT_RES_PRINTFOOTER, 'footer');
end;

end.
