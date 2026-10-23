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
///  The chat as a VCL control: a panel filled by a WebView2 that renders the
///  HTML chat. It knows nothing about where it is shown — the component parents
///  it to its own tool window by default, or to any container the application
///  provides (a side panel of the main form, a page, a dock site). It does the
///  browser work: navigation confined to the panel origin (other links open in
///  the system browser), scripts queued until the page is ready, the 'close'
///  message of the page reported to the owner, VCL style changes reported so
///  the theme can be re-applied.
/// </summary>
unit Vcl.HelpChatAI.Panel;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
{$IFDEF D11+}
  Winapi.WebView2,
{$ELSE}
  WebView2, // Delphi 10.4 ships the interfaces without the Winapi namespace
{$ENDIF}
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Edge,
  HelpChatAI.Types;

type
  TVclHelpChatAIPanel = class(TCustomPanel)
  strict private
    FBrowser: TEdgeBrowser;
    FUrl: string;
    FOrigin: string;
    FPageReady: Boolean;
    FPendingScripts: TStringList;
    FOnCloseRequested: TNotifyEvent;
    FOnStyleChanged: TNotifyEvent;
    FOnPageReady: TNotifyEvent;
    FOnOpenLink: THelpChatOpenLinkEvent;
    procedure BrowserCreateCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure BrowserNavigationStarting(Sender: TCustomEdgeBrowser; Args: TNavigationStartingEventArgs);
    procedure BrowserNavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
      WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure BrowserNewWindowRequested(Sender: TCustomEdgeBrowser; Args: TNewWindowRequestedEventArgs);
    procedure BrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    procedure FlushScripts;
  protected
    procedure WndProc(var Message: TMessage); override;
    /// <summary>Applied when the WebView is created: context menus, dev tools,
    /// status bar and zoom off. Override to change them.</summary>
    procedure ConfigureWebView; virtual;
    /// <summary>A message posted by the page (window.chrome.webview.postMessage).
    /// The base understands 'close'. Override to add messages.</summary>
    procedure HandleWebMessage(const AMessage: string); virtual;
    /// <summary>True for URLs the panel may show itself; everything else opens
    /// in the system browser.</summary>
    function IsPanelUrl(const AUrl: string): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Loads the panel page (creating the WebView on first use).</summary>
    procedure OpenUrl(const AUrl, AOrigin: string);
    /// <summary>Runs JavaScript in the page, now or as soon as it is loaded.</summary>
    procedure RunScript(const AScript: string);
    /// <summary>
    ///  Gives the keyboard focus to the browser window and asks the page to put
    ///  the caret in its question box. Focusing inside the page is not enough:
    ///  without the native focus the window has no caret to give.
    /// </summary>
    procedure FocusInput;
    /// <summary>Opens a URL in the default browser of the system.</summary>
    class procedure OpenExternal(const AUrl: string); static;
    /// <summary>A link leaving the panel: OnOpenLink first, else OpenExternal.</summary>
    procedure OpenLink(const AUrl: string);
    property Browser: TEdgeBrowser read FBrowser;
    property PageReady: Boolean read FPageReady;
    property PanelUrl: string read FUrl;
    property PanelOrigin: string read FOrigin;
    /// <summary>The page asked to close (its ✕ button or Esc).</summary>
    property OnCloseRequested: TNotifyEvent read FOnCloseRequested write FOnCloseRequested;
    /// <summary>The VCL style changed (CM_STYLECHANGED): the owner re-themes the page.</summary>
    property OnStyleChanged: TNotifyEvent read FOnStyleChanged write FOnStyleChanged;
    /// <summary>The page finished loading (also after a reload): the owner pushes its state.</summary>
    property OnPageReady: TNotifyEvent read FOnPageReady write FOnPageReady;
    /// <summary>A link is leaving the panel; set AHandled to open it yourself.</summary>
    property OnOpenLink: THelpChatOpenLinkEvent read FOnOpenLink write FOnOpenLink;
  published
    property Align;
    property Anchors;
    property Visible;
  end;

implementation

uses
  System.IOUtils,
  Winapi.ShellAPI,
  Winapi.ActiveX,
  HelpChatAI.Settings;

function PWideCharToStr(const AValue: PWideChar): string;
begin
  if AValue = nil then
    Result := ''
  else
  begin
    Result := AValue;
    CoTaskMemFree(AValue);
  end;
end;

{ TVclHelpChatAIPanel }

constructor TVclHelpChatAIPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPendingScripts := TStringList.Create;
  BevelOuter := bvNone;
  BevelInner := bvNone;
  Caption := '';
  ShowCaption := False;
  ParentBackground := False;
  FBrowser := TEdgeBrowser.Create(Self);
  FBrowser.Parent := Self;
  FBrowser.Align := alClient;
  // Cache and history of the panel go to a per-user writable folder.
  FBrowser.UserDataFolder := TPath.Combine(HelpChatAppDataFolder, 'WebView2');
  FBrowser.OnCreateWebViewCompleted := BrowserCreateCompleted;
  FBrowser.OnNavigationStarting := BrowserNavigationStarting;
  FBrowser.OnNavigationCompleted := BrowserNavigationCompleted;
  FBrowser.OnNewWindowRequested := BrowserNewWindowRequested;
  FBrowser.OnWebMessageReceived := BrowserWebMessageReceived;
end;

destructor TVclHelpChatAIPanel.Destroy;
begin
  FPendingScripts.Free;
  inherited;
end;

procedure TVclHelpChatAIPanel.ConfigureWebView;
begin
  FBrowser.DefaultContextMenusEnabled := False;
  FBrowser.DevToolsEnabled := False;
  FBrowser.StatusBarEnabled := False;
  FBrowser.ZoomControlEnabled := False;
end;

procedure TVclHelpChatAIPanel.WndProc(var Message: TMessage);
begin
  inherited WndProc(Message);
  if (Message.Msg = CM_STYLECHANGED) and Assigned(FOnStyleChanged) then
    FOnStyleChanged(Self);
end;

class procedure TVclHelpChatAIPanel.OpenExternal(const AUrl: string);
var
  LUrl: string;
begin
  LUrl := AUrl.ToLower;
  // Only web and mail links leave the panel; anything else is dropped.
  if LUrl.StartsWith('http://') or LUrl.StartsWith('https://') or LUrl.StartsWith('mailto:') then
    ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TVclHelpChatAIPanel.OpenLink(const AUrl: string);
var
  LHandled: Boolean;
begin
  LHandled := False;
  if Assigned(FOnOpenLink) then
    FOnOpenLink(Self, AUrl, LHandled);
  if not LHandled then
    OpenExternal(AUrl);
end;

function TVclHelpChatAIPanel.IsPanelUrl(const AUrl: string): Boolean;
begin
  Result := (AUrl = '') or SameText(AUrl, 'about:blank') or (FOrigin = '') or
    AUrl.StartsWith(FOrigin, True);
end;

procedure TVclHelpChatAIPanel.OpenUrl(const AUrl, AOrigin: string);
begin
  FUrl := AUrl;
  FOrigin := AOrigin;
  FPageReady := False;
  if FBrowser.WebViewCreated then
    FBrowser.Navigate(FUrl)
  else
    // Asynchronous: the navigation happens in BrowserCreateCompleted.
    FBrowser.CreateWebView;
end;

procedure TVclHelpChatAIPanel.RunScript(const AScript: string);
begin
  if FPageReady and FBrowser.WebViewCreated then
    FBrowser.ExecuteScript(AScript)
  else
    FPendingScripts.Add(AScript);
end;

procedure TVclHelpChatAIPanel.FocusInput;
begin
  if Assigned(FBrowser) and FBrowser.CanFocus then
    FBrowser.SetFocus;
  RunScript('window.hcFocus && window.hcFocus();');
end;

procedure TVclHelpChatAIPanel.FlushScripts;
var
  I: Integer;
begin
  for I := 0 to FPendingScripts.Count - 1 do
    FBrowser.ExecuteScript(FPendingScripts[I]);
  FPendingScripts.Clear;
end;

procedure TVclHelpChatAIPanel.HandleWebMessage(const AMessage: string);
begin
  if (AMessage = 'close') and Assigned(FOnCloseRequested) then
    FOnCloseRequested(Self);
end;

procedure TVclHelpChatAIPanel.BrowserCreateCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LCurrent: string;
begin
  if Failed(AResult) then
    Exit; // TEdgeBrowser already raised/showed the reason (WebView2 runtime missing...)
  try
    ConfigureWebView;
  except
    // Settings are cosmetic: never block the panel for them.
  end;
  // After a window recreation (style change, reparenting) TEdgeBrowser reloads
  // its last URI by itself.
  LCurrent := FBrowser.LocationURL;
  if (FUrl <> '') and ((LCurrent = '') or SameText(LCurrent, 'about:blank')) then
    FBrowser.Navigate(FUrl);
end;

procedure TVclHelpChatAIPanel.BrowserNavigationStarting(Sender: TCustomEdgeBrowser;
  Args: TNavigationStartingEventArgs);
var
  LUri: PWideChar;
  LUrl: string;
begin
  if Failed(Args.ArgsInterface.Get_uri(LUri)) then
    Exit;
  LUrl := PWideCharToStr(LUri);
  // Confinement: the WebView shows only the panel; documentation links open outside.
  if not IsPanelUrl(LUrl) then
  begin
    Args.ArgsInterface.Set_Cancel(1);
    OpenLink(LUrl);
  end
  else
    FPageReady := False; // the page is (re)loading: queue scripts until it is ready
end;

procedure TVclHelpChatAIPanel.BrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  FPageReady := IsSuccess;
  if FPageReady then
  begin
    FlushScripts;
    if Assigned(FOnPageReady) then
      FOnPageReady(Self);
  end;
end;

procedure TVclHelpChatAIPanel.BrowserNewWindowRequested(Sender: TCustomEdgeBrowser;
  Args: TNewWindowRequestedEventArgs);
var
  LUri: PWideChar;
begin
  Args.ArgsInterface.Set_Handled(1);
  if Succeeded(Args.ArgsInterface.Get_uri(LUri)) then
    OpenLink(PWideCharToStr(LUri));
end;

procedure TVclHelpChatAIPanel.BrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  LMessage: PWideChar;
begin
  if Succeeded(Args.ArgsInterface.TryGetWebMessageAsString(LMessage)) then
    HandleWebMessage(PWideCharToStr(LMessage));
end;

end.
