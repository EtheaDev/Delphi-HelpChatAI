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
    procedure BrowserShouldLoadURL(Sender: TObject; const AURL: string; var ACancel: Boolean);
{$ELSE}
    procedure BrowserShouldStartLoad(Sender: TObject; const AURL: string);
{$ENDIF}
    procedure BrowserDidFinishLoad(ASender: TObject);
    procedure BrowserDidFailLoad(ASender: TObject);
    procedure FlushScripts;
  protected
    /// <summary>True for URLs the panel may show itself; everything else opens
    /// in the system browser.</summary>
    function IsPanelUrl(const AUrl: string): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Loads the panel page.</summary>
    procedure OpenUrl(const AUrl, AOrigin: string);
    /// <summary>Runs JavaScript in the page, now or as soon as it is loaded.</summary>
    procedure RunScript(const AScript: string);
    /// <summary>Opens a URL in the default browser of the platform.</summary>
    class procedure OpenExternal(const AUrl: string); static;
    /// <summary>A link leaving the panel: OnOpenLink first, else OpenExternal.</summary>
    procedure OpenLink(const AUrl: string);
    property Browser: TWebBrowser read FBrowser;
    property PageReady: Boolean read FPageReady;
    property PanelUrl: string read FUrl;
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
  Result := (AUrl = '') or SameText(AUrl, 'about:blank') or (FOrigin = '') or
    AUrl.StartsWith(FOrigin, True);
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
