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
///  The window of a FireMonkey bubble that floats: the bubble of the main form
///  when <c>TFmxHelpChatAI.BubbleStayOnTop</c> is set. Everywhere else the
///  bubble is a <c>TCircle</c> on its form, and a full-screen secondary form
///  covers it; this one is a form of its own - borderless, transparent
///  (<c>Transparency</c>: a layered window per pixel on Windows, so the round
///  edge blends and a click on a corner goes through), owned by the main form - which the component keeps in front of every form of
///  the application while the application is active.
///
///  Its geometry is in physical pixels and goes through Win32: FireMonkey
///  works in dp, and the position of a screen in dp is not defined on Windows
///  when the monitors have different scales. Only Windows has it; elsewhere
///  the component never creates one and the methods do nothing.
/// </summary>
unit FMX.HelpChatAI.Bubble;

{$I HelpChatAI.inc}

interface

uses
  System.Classes,
  System.Types,
  FMX.Forms;

type
  /// <summary>
  ///  A borderless transparent form holding the bubble of the main form, in
  ///  front of every form of the application while it is active. Created by
  ///  <c>TFmxHelpChatAI</c>, which parents its <c>TCircle</c> to it.
  /// </summary>
  TFmxHelpChatBubbleForm = class(TForm)
  private
    FHost: TCommonCustomForm;
    FOnHostChanged: TNotifyEvent;
    FWnd: THandle;
    FHostWnd: THandle;
    FOldProc: Pointer;
    FHostOldProc: Pointer;
    FFollowing: Boolean;
    procedure Hook;
    procedure Unhook;
    procedure HookHost;
    procedure UnhookHost;
    procedure FollowHost;
  protected
    /// <summary>Gives the window the styles of a bubble (no activation, no
    /// taskbar button) and hooks it and its host: FireMonkey recreates a
    /// window when a property of the form changes, and each new one is
    /// hooked again.</summary>
    procedure CreateHandle; override;
    procedure DestroyHandle; override;
  public
    /// <summary>The bubble window of AHost, owned by it.</summary>
    constructor CreateFloat(AOwner: TComponent; const AHost: TCommonCustomForm);
    destructor Destroy; override;
{$IFDEF D13+}
    /// <summary>Does nothing: <c>Show</c> activates the form it shows, and
    /// the bubble must never take the activation from the form the user is
    /// working in. Virtual from Delphi 13; before it the activation is given
    /// back when the window receives it (WM_ACTIVATE).</summary>
    procedure Activate; override;
{$ENDIF}
    /// <summary>The client area of the host, in screen pixels.</summary>
    function HostClientRect: TRect;
    /// <summary>The work area of the monitor of the host, in pixels: what
    /// the bubble never leaves.</summary>
    function WorkArea: TRect;
    /// <summary>The scale of the host (its DPI over 96).</summary>
    function Scale: Single;
    /// <summary>Where the bubble is, in screen pixels.</summary>
    function WindowRect: TRect;
    /// <summary>The cursor, in screen pixels.</summary>
    class function CursorPos: TPoint; static;
    /// <summary>Moves and sizes the window, in screen pixels.</summary>
    procedure MoveTo(const ALeft, ATop, ASize: Integer);
    /// <summary>Shows it without taking the activation from anyone, or
    /// hides it.</summary>
    procedure ShowQuietly(const AVisible: Boolean);
    /// <summary>Topmost while the application is active; below the window
    /// the user switched to when it is not.</summary>
    procedure UpdateTopmost(const AAppActive: Boolean);
    /// <summary><c>UpdateTopmost</c> for the application as it is now.</summary>
    procedure BringToTop;
    /// <summary>True when the host is shown and not minimized.</summary>
    function HostShowing: Boolean;
    /// <summary>The form the bubble belongs to.</summary>
    property Host: TCommonCustomForm read FHost;
    /// <summary>The host moved, changed size, was shown, hidden or
    /// minimized: the component places the bubble again.</summary>
    property OnHostChanged: TNotifyEvent read FOnHostChanged write FOnHostChanged;
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.Messages,
  Winapi.MultiMon,
  FMX.Platform.Win,
{$ENDIF}
  System.SysUtils,
  System.UITypes,
  FMX.Types;

{$IFDEF MSWINDOWS}

const
  PROP_BUBBLE = 'HelpChatAI.FmxBubble';
  PROP_HOST = 'HelpChatAI.FmxBubbleHost';
  // ShowModal disables every window of the thread: the bubble enables itself
  // again once the disabling is over.
  HELPCHAT_FMX_CM_REENABLE = WM_APP + 118;
  // Shown or hidden: what the host looks like is known after the message.
  HELPCHAT_FMX_CM_FOLLOW = WM_APP + 119;
  // The bubble was activated anyway: the activation goes back, once the
  // activation in progress is over.
  HELPCHAT_FMX_CM_GIVEBACK = WM_APP + 120;

function BubbleWndProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  LForm: TFmxHelpChatBubbleForm;
begin
  LForm := TFmxHelpChatBubbleForm(GetProp(AWnd, PROP_BUBBLE));
  if LForm = nil then
    Exit(DefWindowProc(AWnd, AMsg, AWParam, ALParam));
  case AMsg of
    // A click must not take the activation from the form the user works in:
    // FireMonkey would see an active form with no assistant, and the caret
    // would leave the field it was in.
    WM_MOUSEACTIVATE:
      Exit(MA_NOACTIVATE);
    // ShowWindow(SW_SHOWNORMAL), which is how FireMonkey shows a form,
    // activates it whatever its styles say. FireMonkey never hears of it -
    // an active form with no assistant would move F1 and the screen of the
    // skills - and the window that had the activation gets it back.
    WM_ACTIVATE:
      begin
        if LoWord(AWParam) <> WA_INACTIVE then
          PostMessage(AWnd, HELPCHAT_FMX_CM_GIVEBACK, WPARAM(ALParam), 0);
        Exit(0);
      end;
    HELPCHAT_FMX_CM_GIVEBACK:
      begin
        if GetActiveWindow = AWnd then
        begin
          if (AWParam <> 0) and IsWindow(HWND(AWParam)) and IsWindowVisible(HWND(AWParam)) then
            SetActiveWindow(HWND(AWParam))
          else if (LForm.FHostWnd <> 0) and IsWindowVisible(LForm.FHostWnd) then
            SetActiveWindow(LForm.FHostWnd);
        end;
        Exit(0);
      end;
    WM_ENABLE:
      if AWParam = 0 then
        PostMessage(AWnd, HELPCHAT_FMX_CM_REENABLE, 0, 0);
    HELPCHAT_FMX_CM_REENABLE:
      begin
        EnableWindow(AWnd, True);
        Exit(0);
      end;
    HELPCHAT_FMX_CM_FOLLOW:
      begin
        LForm.FollowHost;
        Exit(0);
      end;
    WM_ACTIVATEAPP:
      LForm.UpdateTopmost(AWParam <> 0);
  end;
  Result := CallWindowProc(LForm.FOldProc, AWnd, AMsg, AWParam, ALParam);
end;

function HostWndProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  LForm: TFmxHelpChatBubbleForm;
begin
  LForm := TFmxHelpChatBubbleForm(GetProp(AWnd, PROP_HOST));
  if LForm = nil then
    Exit(DefWindowProc(AWnd, AMsg, AWParam, ALParam));
  Result := CallWindowProc(LForm.FHostOldProc, AWnd, AMsg, AWParam, ALParam);
  case AMsg of
    WM_WINDOWPOSCHANGED, WM_SIZE:
      LForm.FollowHost;
    WM_SHOWWINDOW:
      PostMessage(LForm.FWnd, HELPCHAT_FMX_CM_FOLLOW, 0, 0);
  end;
end;

{$ENDIF}

{ TFmxHelpChatBubbleForm }

constructor TFmxHelpChatBubbleForm.CreateFloat(AOwner: TComponent;
  const AHost: TCommonCustomForm);
begin
  FHost := AHost;
  inherited CreateNew(AOwner);
  BorderStyle := TFmxFormBorderStyle.None;
  BorderIcons := [];
  Transparency := True;
  Position := TFormPosition.Designed;
  Caption := '';
end;

destructor TFmxHelpChatBubbleForm.Destroy;
begin
  FOnHostChanged := nil;
  inherited Destroy;
end;

{$IFDEF D13+}
procedure TFmxHelpChatBubbleForm.Activate;
begin
  // Never active: see the declaration.
end;
{$ENDIF}

procedure TFmxHelpChatBubbleForm.CreateHandle;
{$IFDEF MSWINDOWS}
var
  LStyle: NativeInt;
{$ENDIF}
begin
  inherited CreateHandle;
{$IFDEF MSWINDOWS}
  FWnd := FormToHWND(Self);
  if FWnd = 0 then
    Exit;
  LStyle := GetWindowLong(FWnd, GWL_EXSTYLE);
  SetWindowLong(FWnd, GWL_EXSTYLE, (LStyle or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE) and
    not WS_EX_APPWINDOW);
  Hook;
  HookHost;
  // The owner: always above it, hidden with it when it is minimized.
  // ParentForm would do it, but it is read-only and comes from a Parent
  // that is a form - which would make the bubble a child object of the
  // main form, freed with it.
  if FHostWnd <> 0 then
    SetWindowLongPtr(FWnd, GWLP_HWNDPARENT, LONG_PTR(FHostWnd));
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.DestroyHandle;
begin
  Unhook;
  UnhookHost;
  inherited DestroyHandle;
end;

procedure TFmxHelpChatBubbleForm.Hook;
begin
{$IFDEF MSWINDOWS}
  if (FWnd = 0) or (FOldProc <> nil) then
    Exit;
  SetProp(FWnd, PROP_BUBBLE, THandle(Self));
  FOldProc := Pointer(SetWindowLongPtr(FWnd, GWLP_WNDPROC, LONG_PTR(@BubbleWndProc)));
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.Unhook;
begin
{$IFDEF MSWINDOWS}
  if (FWnd = 0) or (FOldProc = nil) then
    Exit;
  // Put back only while the chain is still ours: somebody who subclassed
  // after us would be cut out.
  if Pointer(GetWindowLongPtr(FWnd, GWLP_WNDPROC)) = @BubbleWndProc then
    SetWindowLongPtr(FWnd, GWLP_WNDPROC, LONG_PTR(FOldProc));
  RemoveProp(FWnd, PROP_BUBBLE);
  FOldProc := nil;
  FWnd := 0;
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.HookHost;
begin
{$IFDEF MSWINDOWS}
  if (FHost = nil) or (FHost.Handle = nil) or (FHostOldProc <> nil) then
    Exit;
  FHostWnd := FormToHWND(FHost);
  // One floating bubble per host: the main form has one assistant that
  // floats, and a second hook would chain to a freed one.
  if (FHostWnd = 0) or (GetProp(FHostWnd, PROP_HOST) <> 0) then
  begin
    FHostWnd := 0;
    Exit;
  end;
  SetProp(FHostWnd, PROP_HOST, THandle(Self));
  FHostOldProc := Pointer(SetWindowLongPtr(FHostWnd, GWLP_WNDPROC, LONG_PTR(@HostWndProc)));
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.UnhookHost;
begin
{$IFDEF MSWINDOWS}
  if (FHostWnd = 0) or (FHostOldProc = nil) then
    Exit;
  if IsWindow(FHostWnd) then
  begin
    if Pointer(GetWindowLongPtr(FHostWnd, GWLP_WNDPROC)) = @HostWndProc then
      SetWindowLongPtr(FHostWnd, GWLP_WNDPROC, LONG_PTR(FHostOldProc))
    else
      // Somebody chained after us: the hook stays, passing everything on,
      // and the property goes, so it no longer calls this object.
      ;
    RemoveProp(FHostWnd, PROP_HOST);
  end;
  FHostOldProc := nil;
  FHostWnd := 0;
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.FollowHost;
begin
  if FFollowing or not Assigned(FOnHostChanged) then
    Exit;
  FFollowing := True;
  try
    FOnHostChanged(Self);
  finally
    FFollowing := False;
  end;
end;

function TFmxHelpChatBubbleForm.HostClientRect: TRect;
{$IFDEF MSWINDOWS}
var
  LOrigin: TPoint;
{$ENDIF}
begin
  Result := TRect.Empty;
{$IFDEF MSWINDOWS}
  if FHostWnd = 0 then
    HookHost;
  if (FHostWnd = 0) or not GetClientRect(FHostWnd, Result) then
    Exit(TRect.Empty);
  LOrigin := Point(0, 0);
  Winapi.Windows.ClientToScreen(FHostWnd, LOrigin);
  Result.Offset(LOrigin);
{$ENDIF}
end;

function TFmxHelpChatBubbleForm.WorkArea: TRect;
{$IFDEF MSWINDOWS}
var
  LInfo: TMonitorInfo;
{$ENDIF}
begin
  Result := TRect.Empty;
{$IFDEF MSWINDOWS}
  LInfo.cbSize := SizeOf(LInfo);
  if (FHostWnd <> 0) and
     GetMonitorInfo(MonitorFromWindow(FHostWnd, MONITOR_DEFAULTTONEAREST), @LInfo) then
    Result := LInfo.rcWork;
{$ENDIF}
end;

function TFmxHelpChatBubbleForm.Scale: Single;
begin
  Result := 1;
{$IFDEF MSWINDOWS}
  if FHostWnd <> 0 then
    Result := GetDpiForWindow(FHostWnd) / 96;
  if Result <= 0 then
    Result := 1;
{$ENDIF}
end;

function TFmxHelpChatBubbleForm.WindowRect: TRect;
begin
  Result := TRect.Empty;
{$IFDEF MSWINDOWS}
  if (FWnd = 0) or not GetWindowRect(FWnd, Result) then
    Result := TRect.Empty;
{$ENDIF}
end;

class function TFmxHelpChatBubbleForm.CursorPos: TPoint;
begin
  Result := Point(0, 0);
{$IFDEF MSWINDOWS}
  GetCursorPos(Result);
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.MoveTo(const ALeft, ATop, ASize: Integer);
begin
{$IFDEF MSWINDOWS}
  if FWnd <> 0 then
    SetWindowPos(FWnd, 0, ALeft, ATop, ASize, ASize,
      SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.ShowQuietly(const AVisible: Boolean);
begin
{$IFDEF MSWINDOWS}
  if FWnd = 0 then
    Exit;
  if AVisible then
  begin
    // Minimized too: FireMonkey minimizes every visible form of the
    // application with the main one, calling DefWindowProc straight away,
    // which no hook sees. SW_SHOWNOACTIVATE restores it as it shows it.
    if not IsWindowVisible(FWnd) or IsIconic(FWnd) then
      ShowWindow(FWnd, SW_SHOWNOACTIVATE);
  end
  else if IsWindowVisible(FWnd) then
    ShowWindow(FWnd, SW_HIDE);
{$ENDIF}
end;

function TFmxHelpChatBubbleForm.HostShowing: Boolean;
begin
{$IFDEF MSWINDOWS}
  if FHostWnd = 0 then
    HookHost;
  Result := (FHostWnd <> 0) and IsWindowVisible(FHostWnd) and not IsIconic(FHostWnd);
{$ELSE}
  Result := False;
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.UpdateTopmost(const AAppActive: Boolean);
{$IFDEF MSWINDOWS}
var
  LFore: HWND;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  if FWnd = 0 then
    Exit;
  if AAppActive then
    SetWindowPos(FWnd, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
  else
  begin
    // HWND_NOTOPMOST alone would put it at the top of the windows that are
    // not topmost - above the application the user just switched to. Below
    // that window instead, which takes the topmost state away too.
    LFore := GetForegroundWindow;
    if (LFore <> 0) and (LFore <> FWnd) and
       (GetWindowLong(LFore, GWL_EXSTYLE) and WS_EX_TOPMOST = 0) then
      SetWindowPos(FWnd, LFore, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
    else
      SetWindowPos(FWnd, HWND_NOTOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
  end;
{$ENDIF}
end;

procedure TFmxHelpChatBubbleForm.BringToTop;
{$IFDEF MSWINDOWS}
var
  LProcess: DWORD;
  LFore: HWND;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  LFore := GetForegroundWindow;
  LProcess := 0;
  if LFore <> 0 then
    GetWindowThreadProcessId(LFore, @LProcess);
  UpdateTopmost(LProcess = GetCurrentProcessId);
{$ENDIF}
end;

end.
