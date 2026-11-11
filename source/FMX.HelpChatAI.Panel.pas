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
///  The chat as a FireMonkey control: a layout filled by a TWebBrowser (WebView2
///  on Windows, WKWebView on macOS/iOS, WebView on Android) that renders the
///  HTML chat. As its VCL twin it knows nothing about where it is shown; it
///  confines the browser to the panel origin (other links open in the system
///  browser) and queues scripts until the page is ready. FMX exposes no message
///  bridge from the page: what the page asks its host (close) travels through
///  the server (<c>/api/ui/{command}</c>) and the transport.
/// </summary>
unit FMX.HelpChatAI.Panel;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  FMX.Types,
  FMX.Controls,
  FMX.Layouts,
  FMX.WebBrowser,
  HelpChatAI.Types;

type
  /// <summary>
  ///  The chat control: a layout with a <c>TWebBrowser</c> filling it. All it
  ///  needs is a URL and the origin to stay inside
  ///  (<see cref="OpenUrl" />): it knows neither the engine nor the
  ///  transport, so any server that speaks the contract of the panel page can
  ///  be shown in it. Main thread only, like every FireMonkey control.
  ///
  ///  Give it its parent once and leave it there: a native browser window is
  ///  not moved between forms, which is why <c>TFmxHelpChatAI</c> creates a
  ///  new panel for a new container instead of reparenting this one. Unlike
  ///  the VCL twin it has no web-message bridge (nothing like
  ///  <c>OnCloseRequested</c>), does not follow a style and has no
  ///  <c>FocusInput</c>: the owner asks the page (<c>window.hcFocus</c>).
  /// </summary>
  TFmxHelpChatAIPanel = class(TLayout)
  strict private
    FBrowser: TWebBrowser;
    FUrl: string;
    FOrigin: string;
    FPageReady: Boolean;
    FPendingScripts: TStringList;
    FGoHome: Boolean;
    FOnPageReady: TNotifyEvent;
    FOnOpenLink: THelpChatOpenLinkEvent;
{$IFDEF D13+}
    /// <summary>Delphi 13: a navigation is about to start and can still be
    /// cancelled. One that leaves the panel is cancelled and handed to
    /// <c>OpenLink</c>; one that stays marks the page as loading.</summary>
    procedure BrowserShouldLoadURL(Sender: TObject; const AURL: string; var ACancel: Boolean);
{$ELSE}
    /// <summary>Delphi 12: a navigation started and cannot be stopped. One
    /// that leaves the panel is also opened outside, and
    /// <c>BrowserDidFinishLoad</c> brings the panel back to its page.</summary>
    procedure BrowserShouldStartLoad(Sender: TObject; const AURL: string);
{$ENDIF}
    /// <summary>The page is loaded: runs the queued scripts, in order, then
    /// fires <c>OnPageReady</c> - or, in Delphi 12, navigates back to the
    /// panel when what loaded was a foreign page.</summary>
    procedure BrowserDidFinishLoad(ASender: TObject);
    /// <summary>A load failed: the page is not ready, and the queued scripts
    /// stay queued for the next load that succeeds.</summary>
    procedure BrowserDidFailLoad(ASender: TObject);
    procedure FlushScripts;
  protected
    /// <summary>True for URLs the panel may show itself; everything else opens
    /// in the system browser. The test is the origin given to
    /// <c>OpenUrl</c> (case-insensitive) followed by nothing, a path, a
    /// query or a fragment - never a longer port or a host after an "@";
    /// with no origin, or for an empty URL and about:blank, everything is
    /// the panel's.</summary>
    function IsPanelUrl(const AUrl: string): Boolean; virtual;
  public
    /// <summary>Creates the browser inside the layout. On Windows it asks for
    /// WebView2 and nothing else (<c>EdgeOnly</c>): the page needs fetch and
    /// htmx, which the Internet Explorer control cannot run, so there is no
    /// fallback on a machine without the WebView2 runtime.</summary>
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Loads the panel page. AUrl is what the transport gives
    /// (<c>GetPanelUrl</c>, secret included), AOrigin the scheme://host:port
    /// the browser is confined to (<c>GetPanelOrigin</c>). Scripts run from
    /// now on are queued until the page has loaded.</summary>
    procedure OpenUrl(const AUrl, AOrigin: string);
    /// <summary>Runs JavaScript in the page, now or as soon as it is loaded.
    /// Queued scripts run in the order they were given, once; they survive a
    /// reload of the page but not the panel. No result comes back: FMX gives
    /// none, which is why the page answers its host through the server.</summary>
    procedure RunScript(const AScript: string);
    /// <summary>Opens a URL in the default browser of the platform. Only
    /// http, https and mailto: anything else is dropped without a word. The
    /// macOS, iOS and Android branches compile but were never run.</summary>
    class procedure OpenExternal(const AUrl: string); static;
    /// <summary>A link leaving the panel: OnOpenLink first, else OpenExternal.</summary>
    procedure OpenLink(const AUrl: string);
    /// <summary>The native browser, for what this class does not wrap. Do
    /// not navigate it elsewhere: the confinement brings it back or opens
    /// the address outside.</summary>
    property Browser: TWebBrowser read FBrowser;
    /// <summary>True from the end of a load of the panel page to the start
    /// of the next navigation. While False, <c>RunScript</c> queues.</summary>
    property PageReady: Boolean read FPageReady;
    /// <summary>The URL last given to <c>OpenUrl</c>; in Delphi 12 it is
    /// also where the panel goes back to after a foreign page.</summary>
    property PanelUrl: string read FUrl;
    /// <summary>The origin last given to <c>OpenUrl</c>; empty = no
    /// confinement yet.</summary>
    property PanelOrigin: string read FOrigin;
    /// <summary>The page finished loading (also after a reload): the owner pushes its state.</summary>
    property OnPageReady: TNotifyEvent read FOnPageReady write FOnPageReady;
    /// <summary>A link is leaving the panel; set AHandled to open it yourself.</summary>
    property OnOpenLink: THelpChatOpenLinkEvent read FOnOpenLink write FOnOpenLink;
  end;

implementation

uses
{$IF DEFINED(MSWINDOWS)}
  Winapi.Windows,
  Winapi.ShellAPI,
{$ELSEIF DEFINED(IOS)}
  Macapi.Helpers,
  iOSapi.Foundation,
  iOSapi.UIKit,
  FMX.Helpers.iOS,
{$ELSEIF DEFINED(MACOS)}
  Macapi.Helpers,
  Macapi.Foundation,
  Macapi.AppKit,
{$ELSEIF DEFINED(ANDROID)}
  Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net,
  Androidapi.JNI.JavaTypes,
{$ENDIF}
  System.SysConst;

{ TFmxHelpChatAIPanel }

constructor TFmxHelpChatAIPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPendingScripts := TStringList.Create;
  HitTest := False;
  FBrowser := TWebBrowser.Create(Self);
  FBrowser.Stored := False;
  FBrowser.Parent := Self;
  FBrowser.Align := TAlignLayout.Client;
{$IFDEF MSWINDOWS}
  // htmx and fetch need a real browser: WebView2, never the IE control.
  FBrowser.WindowsEngine := TWindowsEngine.EdgeOnly;
{$ENDIF}
{$IFDEF D13+}
  FBrowser.OnShouldLoadURL := BrowserShouldLoadURL;
{$ELSE}
  // Delphi 12 cannot cancel a navigation (OnShouldLoadURL arrived in 13).
  FBrowser.OnShouldStartLoadWithRequest := BrowserShouldStartLoad;
{$ENDIF}
  FBrowser.OnDidFinishLoad := BrowserDidFinishLoad;
  FBrowser.OnDidFailLoadWithError := BrowserDidFailLoad;
end;

destructor TFmxHelpChatAIPanel.Destroy;
begin
  FPendingScripts.Free;
  inherited;
end;

class procedure TFmxHelpChatAIPanel.OpenExternal(const AUrl: string);
var
  LUrl: string;
{$IF DEFINED(ANDROID)}
  LIntent: JIntent;
{$ENDIF}
begin
  LUrl := AUrl.ToLower;
  // Only web and mail links leave the panel; anything else is dropped.
  if not (LUrl.StartsWith('http://') or LUrl.StartsWith('https://') or LUrl.StartsWith('mailto:')) then
    Exit;
{$IF DEFINED(MSWINDOWS)}
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
{$ELSEIF DEFINED(IOS)}
  SharedApplication.openURL(TNSUrl.Wrap(TNSUrl.OCClass.URLWithString(StrToNSStr(AUrl))));
{$ELSEIF DEFINED(MACOS)}
  TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace).openURL(
    TNSUrl.Wrap(TNSUrl.OCClass.URLWithString(StrToNSStr(AUrl))));
{$ELSEIF DEFINED(ANDROID)}
  LIntent := TJIntent.Create;
  LIntent.setAction(TJIntent.JavaClass.ACTION_VIEW);
  LIntent.setData(TJnet_Uri.JavaClass.parse(StringToJString(AUrl)));
  TAndroidHelper.Activity.startActivity(LIntent);
{$ENDIF}
end;

procedure TFmxHelpChatAIPanel.OpenLink(const AUrl: string);
var
  LHandled: Boolean;
begin
  LHandled := False;
  if Assigned(FOnOpenLink) then
    FOnOpenLink(Self, AUrl, LHandled);
  if not LHandled then
    OpenExternal(AUrl);
end;

function TFmxHelpChatAIPanel.IsPanelUrl(const AUrl: string): Boolean;
begin
  // Empty and about:blank are what a browser reports before its first page;
  // no origin means OpenUrl was not called yet, and nothing is confined.
  // The origin has no trailing slash (http://127.0.0.1:5123): a plain prefix
  // would also accept http://127.0.0.1:51234/ and http://127.0.0.1:5123@host/,
  // so what follows the origin must be where a path, a query or a fragment
  // starts - or nothing at all.
  Result := (AUrl = '') or SameText(AUrl, 'about:blank') or (FOrigin = '') or
    (AUrl.StartsWith(FOrigin, True) and
     ((Length(AUrl) = Length(FOrigin)) or FOrigin.EndsWith('/') or
      CharInSet(AUrl[Length(FOrigin) + 1], ['/', '?', '#'])));
end;

procedure TFmxHelpChatAIPanel.OpenUrl(const AUrl, AOrigin: string);
begin
  FOrigin := AOrigin;
  FUrl := AUrl;
  FPageReady := False;
  FBrowser.Navigate(FUrl);
end;

procedure TFmxHelpChatAIPanel.RunScript(const AScript: string);
begin
  if FPageReady then
    FBrowser.EvaluateJavaScript(AScript)
  else
    FPendingScripts.Add(AScript);
end;

procedure TFmxHelpChatAIPanel.FlushScripts;
var
  I: Integer;
begin
  // In the order they were asked for: a question queued after a theme must
  // find the theme applied.
  for I := 0 to FPendingScripts.Count - 1 do
    FBrowser.EvaluateJavaScript(FPendingScripts[I]);
  FPendingScripts.Clear;
end;

{$IFDEF D13+}
procedure TFmxHelpChatAIPanel.BrowserShouldLoadURL(Sender: TObject; const AURL: string;
  var ACancel: Boolean);
begin
  // Confinement: the WebView shows only the panel; documentation links open outside.
  if not IsPanelUrl(AURL) then
  begin
    ACancel := True;
    OpenLink(AURL);
  end
  else
    FPageReady := False; // the page is (re)loading: queue scripts until it is ready
end;
{$ELSE}
procedure TFmxHelpChatAIPanel.BrowserShouldStartLoad(Sender: TObject; const AURL: string);
begin
  // Delphi 12 only tells us that a navigation started, it does not let us stop
  // it: the link is handed to the system browser and the panel is sent back to
  // its own page as soon as the intruder finishes loading. Links come from
  // sanitized Markdown (http, https, mailto only), so what can appear here is
  // an ordinary documentation page.
  if IsPanelUrl(AURL) then
  begin
    FPageReady := False; // the page is (re)loading: queue scripts until it is ready
    FGoHome := False;
  end
  else
  begin
    FGoHome := True;
    OpenLink(AURL);
  end;
end;
{$ENDIF}

procedure TFmxHelpChatAIPanel.BrowserDidFinishLoad(ASender: TObject);
begin
  if FGoHome then
  begin
    // Something else was loaded (see BrowserShouldStartLoad): back to the panel.
    FGoHome := False;
    FPageReady := False;
    if FUrl <> '' then
      FBrowser.Navigate(FUrl);
    Exit;
  end;
  FPageReady := True;
  FlushScripts;
  if Assigned(FOnPageReady) then
    FOnPageReady(Self);
end;

procedure TFmxHelpChatAIPanel.BrowserDidFailLoad(ASender: TObject);
begin
  FPageReady := False;
  if FGoHome then
  begin
    FGoHome := False;
    if FUrl <> '' then
      FBrowser.Navigate(FUrl);
  end;
end;

end.
