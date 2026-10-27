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
///  The HTML panel: one self-contained page (HTML + CSS + htmx + the panel
///  script, all compiled into <c>HelpChatAI.Panel.res</c> from the
///  <c>resources</c> folder) rendered with the labels of the configured
///  language, the API secret and the polling parameters. The same page is
///  served by the local HTTP server and, later, by a remote one: the API
///  contract (paths, token header, HTML fragments) is defined here.
/// </summary>
unit HelpChatAI.Panel;

{$I HelpChatAI.inc}

{$R HelpChatAI.Panel.res}

interface

uses
  System.SysUtils,
  System.Classes,
  HelpChatAI.Messages,
  HelpChatAI.Theme;

const
  /// <summary>Header every API call must carry; its value is the per-process
  /// secret the page received in its URL. Without it any local process, or
  /// any page open in the user's browser, could drive the assistant.</summary>
  HELPCHAT_TOKEN_HEADER = 'X-HelpChat-Token';
  /// <summary>Query parameter carrying the secret to the panel page.</summary>
  HELPCHAT_TOKEN_QUERY = 't';
  HELPCHAT_API_PREFIX = '/api/';
  HELPCHAT_API_HISTORY = '/api/history';
  HELPCHAT_API_SEND = '/api/send';
  HELPCHAT_API_POLL = '/api/poll/';
  HELPCHAT_API_CANCEL = '/api/cancel/';
  HELPCHAT_API_CLEAR = '/api/clear';
  /// <summary>POST /api/ui/{command}: the page asks the host something it cannot
  /// do itself ('close'). The transport hands it to the UI layer.</summary>
  HELPCHAT_API_UI = '/api/ui/';
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
  /// <summary>GET /api/doc?page=...: a page of the documentation folder as an
  /// HTML fragment (&lt;article class="hc-chat-doc-page" data-page data-title&gt;),
  /// 404 when it is not one.</summary>
  HELPCHAT_API_DOC = '/api/doc';
  /// <summary>Query parameter of /api/doc.</summary>
  HELPCHAT_DOC_QUERY = 'page';
  /// <summary>POST /session opens a conversation on a remote server and returns
  /// its token; POST /session/end closes it.</summary>
  HELPCHAT_SESSION_PATH = '/session';
  HELPCHAT_SESSION_END_PATH = '/session/end';
  /// <summary>Header carrying the application key to a remote server.</summary>
  HELPCHAT_KEY_HEADER = 'X-HelpChat-Key';
  /// <summary>Form field of the message in POST /api/send.</summary>
  HELPCHAT_FIELD_MESSAGE = 'message';
  HELPCHAT_DEF_POLL_MS = 800;
  /// <summary>Poll attempts before the client gives up on a pending bubble
  /// (900 x 800 ms = 12 minutes: bounded, unlike the KittoX original).</summary>
  HELPCHAT_DEF_MAX_POLLS = 900;

  HELPCHAT_RES_HTML = 'HELPCHAT_PANEL_HTML';
  HELPCHAT_RES_CSS = 'HELPCHAT_PANEL_CSS';
  HELPCHAT_RES_JS = 'HELPCHAT_PANEL_JS';
  HELPCHAT_RES_HTMX = 'HELPCHAT_HTMX_JS';

type
  THelpChatPanelOptions = record
    /// <summary>Secret the page sends back in the token header.</summary>
    Token: string;
    Language: THelpChatLanguage;
    /// <summary>Base of the API URLs; empty = same origin as the page.</summary>
    ApiBase: string;
    /// <summary>Where the page posts what it asks of its host (/api/ui/...).
    /// Empty = the API origin itself (local transport). With a remote server it
    /// is the loopback host channel of the client.</summary>
    UiBase: string;
    /// <summary>Token of the host channel; empty = the API token.</summary>
    UiToken: string;
    /// <summary>False when no host is reachable: the page hides its ✕ and Esc
    /// does not close (the application closes the panel its own way).</summary>
    HostCommands: Boolean;
    PollIntervalMs: Integer;
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
    /// <summary>Icon drawn left of the name, as a <c>data:image/...</c> URI -
    /// the only kind the page may load, since its CSP allows images from
    /// <c>'self'</c> and <c>data:</c> alone. Empty = no icon.</summary>
    AssistantIcon: string;
    class function Default: THelpChatPanelOptions; static;
  end;

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
    /// <summary>The UI labels of the page as a JSON object (title, help, clear,
    /// close, placeholder, send, stop, retry, sendError, back, docNotFound).
    /// <c>title</c> is the assistant name, resolved as <c>AssistantNameOf</c>
    /// does.</summary>
    class function LabelsJson(const ALanguage: THelpChatLanguage;
      const AAssistantName: string = ''): string; static;
    /// <summary>The configuration object the page reads as window.HC.</summary>
    class function ConfigJson(const AOptions: THelpChatPanelOptions): string; static;
    /// <summary>The complete panel page.</summary>
    class function RenderPage(const AOptions: THelpChatPanelOptions): string; static;
  end;

implementation

uses
  System.JSON,
  System.NetEncoding,
  System.Types;

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
    LRoot.AddPair('docNotFound', HelpChatMsg(hcmDocNotFound, ALanguage));
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
  Result := LoadResourceText(HELPCHAT_RES_HTML);
  Result := Result.Replace('{{LANG}}', HelpChatLanguageCode(AOptions.Language));
  // The same name in the document title and in the header of the panel.
  Result := Result.Replace('{{TITLE}}', TNetEncoding.HTML.Encode(
    AssistantNameOf(AOptions.AssistantName, AOptions.Language)));
  Result := Result.Replace('{{ICON}}', AssistantIconTag(AOptions.AssistantIcon));
  Result := Result.Replace('{{L_CLEAR}}', Attr(hcmUiClear));
  Result := Result.Replace('{{L_CLOSE}}', Attr(hcmUiClose));
  Result := Result.Replace('{{L_PLACEHOLDER}}', Attr(hcmUiPlaceholder));
  Result := Result.Replace('{{L_SEND}}', Attr(hcmUiSend));
  Result := Result.Replace('{{L_STOP}}', Attr(hcmUiStop));
  Result := Result.Replace('{{L_BACK}}', Attr(hcmUiBack));
  Result := Result.Replace('{{API_BASE}}', TNetEncoding.HTML.Encode(AOptions.ApiBase));
  // The page may only talk to its API and, when there is one, to the loopback
  // channel of its host: the policy names both, and nothing else.
  Result := Result.Replace('{{UI_BASE}}', TNetEncoding.HTML.Encode(AOptions.UiBase));
  Result := Result.Replace('{{CONFIG}}', ConfigJson(AOptions));
  Result := Result.Replace('{{CSS}}', LoadResourceText(HELPCHAT_RES_CSS));
  // After the default stylesheet: the host theme overrides the --hc-* variables.
  if AOptions.ThemeCss <> '' then
    Result := Result.Replace('{{THEME_CSS}}', AOptions.ThemeCss)
  else
    Result := Result.Replace('{{THEME_CSS}}', AOptions.Theme.ToCss);
  Result := Result.Replace('{{HTMX}}', LoadResourceText(HELPCHAT_RES_HTMX));
  Result := Result.Replace('{{JS}}', LoadResourceText(HELPCHAT_RES_JS));
end;

end.
