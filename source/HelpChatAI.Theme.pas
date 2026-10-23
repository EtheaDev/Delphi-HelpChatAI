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
///  The colour theme of the panel, framework independent. The page CSS is
///  written entirely in terms of <c>--hc-*</c> variables; a theme is a set of
///  values for those variables, rendered as a <c>:root</c> rule injected after
///  the default stylesheet (first load) or applied at runtime through
///  <c>window.hcApplyTheme</c> (style change). Colours are <c>#rrggbb</c>
///  strings so that VCL and FMX can each produce a theme from their own style
///  engine; a producer fills the seven base colours and calls <c>Complete</c>
///  to derive the rest.
/// </summary>
unit HelpChatAI.Theme;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils;

type
  THelpChatTheme = record
    /// <summary>Name of the source style (informational).</summary>
    Name: string;
    IsDark: Boolean;
    // ---- base colours (set by the producer) ----------------------------------
    /// <summary>Page background.</summary>
    Background: string;
    /// <summary>Header, footer and assistant bubbles.</summary>
    Surface: string;
    Text: string;
    Border: string;
    /// <summary>Send button and user bubbles.</summary>
    Accent: string;
    // ---- derived by Complete when empty ---------------------------------------
    AccentText: string;
    Muted: string;
    UserBubble: string;
    UserText: string;
    AssistantBubble: string;
    AssistantText: string;
    SystemBubble: string;
    SystemText: string;
    ErrorBubble: string;
    ErrorText: string;
    CodeBackground: string;
    /// <summary>CSS font-family list.</summary>
    FontFamily: string;

    /// <summary>True when no base colour is set (the page keeps its defaults).</summary>
    function IsEmpty: Boolean;
    /// <summary>Fills every empty derived colour from the base ones.</summary>
    procedure Complete;
    /// <summary>A ":root{...}" rule assigning every --hc-* variable (plus color-scheme).</summary>
    function ToCss: string;
    /// <summary>A JSON object {"--hc-bg":"#...", ...} for window.hcApplyTheme.</summary>
    function ToJson: string;
    /// <summary>The built-in light and dark themes (the values of panel.css).</summary>
    class function Light: THelpChatTheme; static;
    class function Dark: THelpChatTheme; static;
  end;

/// <summary>Normalizes a colour to lowercase "#rrggbb"; accepts "#rgb", "rrggbb", "#rrggbb".
/// Returns '' when the input is not a colour.</summary>
function HelpChatNormalizeColor(const AColor: string): string;
/// <summary>"#rrggbb" from components.</summary>
function HelpChatRgbToHex(const R, G, B: Integer): string;
/// <summary>Components of a "#rrggbb" colour; False when it cannot be parsed.</summary>
function HelpChatHexToRgb(const AColor: string; out R, G, B: Integer): Boolean;
/// <summary>Linear blend of two colours: 0 = A, 1 = B.</summary>
function HelpChatBlend(const AColorA, AColorB: string; const ARatio: Double): string;
/// <summary>Perceived luminance 0..1 (0.299 R + 0.587 G + 0.114 B).</summary>
function HelpChatLuminance(const AColor: string): Double;
/// <summary>True when the colour reads as dark (luminance below 0.5).</summary>
function HelpChatIsDarkColor(const AColor: string): Boolean;
/// <summary>Black or white, whichever contrasts with the given colour.</summary>
function HelpChatContrastText(const AColor: string): string;
/// <summary>Saturation 0..1 (max - min of the components).</summary>
function HelpChatSaturation(const AColor: string): Double;

implementation

uses
  System.Character,
  System.JSON;

const
  HELPCHAT_DEF_FONT = 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

function HelpChatNormalizeColor(const AColor: string): string;
var
  S: string;
  C: Char;
begin
  Result := '';
  S := AColor.Trim;
  if S.StartsWith('#') then
    S := S.Substring(1);
  if S.Length = 3 then
    S := S[1] + S[1] + S[2] + S[2] + S[3] + S[3];
  if S.Length <> 6 then
    Exit;
  for C in S do
    if not CharInSet(C, ['0'..'9', 'a'..'f', 'A'..'F']) then
      Exit;
  Result := '#' + S.ToLower;
end;

function HelpChatRgbToHex(const R, G, B: Integer): string;

  function Clamp(const V: Integer): Integer;
  begin
    if V < 0 then
      Result := 0
    else if V > 255 then
      Result := 255
    else
      Result := V;
  end;

begin
  Result := Format('#%.2x%.2x%.2x', [Clamp(R), Clamp(G), Clamp(B)]).ToLower;
end;

function HelpChatHexToRgb(const AColor: string; out R, G, B: Integer): Boolean;
var
  S: string;
begin
  S := HelpChatNormalizeColor(AColor);
  Result := S <> '';
  if not Result then
  begin
    R := 0; G := 0; B := 0;
    Exit;
  end;
  R := StrToInt('$' + S.Substring(1, 2));
  G := StrToInt('$' + S.Substring(3, 2));
  B := StrToInt('$' + S.Substring(5, 2));
end;

function HelpChatBlend(const AColorA, AColorB: string; const ARatio: Double): string;
var
  R1, G1, B1, R2, G2, B2: Integer;
begin
  if not HelpChatHexToRgb(AColorA, R1, G1, B1) then
    Exit(HelpChatNormalizeColor(AColorB));
  if not HelpChatHexToRgb(AColorB, R2, G2, B2) then
    Exit(HelpChatNormalizeColor(AColorA));
  Result := HelpChatRgbToHex(Round(R1 + (R2 - R1) * ARatio), Round(G1 + (G2 - G1) * ARatio),
    Round(B1 + (B2 - B1) * ARatio));
end;

function HelpChatLuminance(const AColor: string): Double;
var
  R, G, B: Integer;
begin
  if HelpChatHexToRgb(AColor, R, G, B) then
    Result := (0.299 * R + 0.587 * G + 0.114 * B) / 255
  else
    Result := 1;
end;

function HelpChatIsDarkColor(const AColor: string): Boolean;
begin
  Result := HelpChatLuminance(AColor) < 0.5;
end;

function HelpChatContrastText(const AColor: string): string;
begin
  if HelpChatIsDarkColor(AColor) then
    Result := '#ffffff'
  else
    Result := '#000000';
end;

function HelpChatSaturation(const AColor: string): Double;
var
  R, G, B, LMax, LMin: Integer;
begin
  if not HelpChatHexToRgb(AColor, R, G, B) then
    Exit(0);
  LMax := R; if G > LMax then LMax := G; if B > LMax then LMax := B;
  LMin := R; if G < LMin then LMin := G; if B < LMin then LMin := B;
  Result := (LMax - LMin) / 255;
end;

{ THelpChatTheme }

function THelpChatTheme.IsEmpty: Boolean;
begin
  Result := (Background = '') and (Surface = '') and (Text = '') and (Accent = '');
end;

procedure THelpChatTheme.Complete;
begin
  Background := HelpChatNormalizeColor(Background);
  Surface := HelpChatNormalizeColor(Surface);
  Text := HelpChatNormalizeColor(Text);
  Border := HelpChatNormalizeColor(Border);
  Accent := HelpChatNormalizeColor(Accent);
  if Background = '' then
    Background := Surface;
  if Surface = '' then
    Surface := Background;
  if Text = '' then
    Text := HelpChatContrastText(Background);
  if Accent = '' then
    Accent := '#2563eb';
  if Border = '' then
    Border := HelpChatBlend(Surface, Text, 0.15);
  if AccentText = '' then
    AccentText := HelpChatContrastText(Accent);
  if Muted = '' then
    Muted := HelpChatBlend(Text, Background, 0.45);
  if UserBubble = '' then
    UserBubble := Accent;
  if UserText = '' then
    UserText := HelpChatContrastText(UserBubble);
  if AssistantBubble = '' then
    AssistantBubble := Surface;
  if AssistantText = '' then
    AssistantText := Text;
  if CodeBackground = '' then
    CodeBackground := HelpChatBlend(Surface, Text, 0.08);
  if IsDark then
  begin
    if SystemBubble = '' then SystemBubble := '#3a2a1a';
    if SystemText = '' then SystemText := '#fcd9b6';
    if ErrorBubble = '' then ErrorBubble := '#3b1d1d';
    if ErrorText = '' then ErrorText := '#fca5a5';
  end
  else
  begin
    if SystemBubble = '' then SystemBubble := '#fff7ed';
    if SystemText = '' then SystemText := '#7c2d12';
    if ErrorBubble = '' then ErrorBubble := '#fef2f2';
    if ErrorText = '' then ErrorText := '#991b1b';
  end;
  if FontFamily = '' then
    FontFamily := HELPCHAT_DEF_FONT;
end;

// The variable names are the contract with panel.css.
procedure ForEachVariable(const ATheme: THelpChatTheme;
  const AProc: TProc<string, string>);
begin
  AProc('--hc-bg', ATheme.Background);
  AProc('--hc-surface', ATheme.Surface);
  AProc('--hc-text', ATheme.Text);
  AProc('--hc-muted', ATheme.Muted);
  AProc('--hc-border', ATheme.Border);
  AProc('--hc-accent', ATheme.Accent);
  AProc('--hc-accent-text', ATheme.AccentText);
  AProc('--hc-user-bg', ATheme.UserBubble);
  AProc('--hc-user-text', ATheme.UserText);
  AProc('--hc-assistant-bg', ATheme.AssistantBubble);
  AProc('--hc-assistant-text', ATheme.AssistantText);
  AProc('--hc-system-bg', ATheme.SystemBubble);
  AProc('--hc-system-text', ATheme.SystemText);
  AProc('--hc-error-bg', ATheme.ErrorBubble);
  AProc('--hc-error-text', ATheme.ErrorText);
  AProc('--hc-code-bg', ATheme.CodeBackground);
  AProc('--hc-font', ATheme.FontFamily);
end;

function THelpChatTheme.ToCss: string;
var
  LSb: TStringBuilder;
  LTheme: THelpChatTheme;
begin
  if IsEmpty then
    Exit('');
  LTheme := Self;
  LTheme.Complete;
  LSb := TStringBuilder.Create;
  try
    LSb.Append(':root{');
    ForEachVariable(LTheme,
      procedure(AName, AValue: string)
      begin
        if AValue <> '' then
          LSb.Append(AName).Append(':').Append(AValue).Append(';');
      end);
    if LTheme.IsDark then
      LSb.Append('color-scheme:dark;')
    else
      LSb.Append('color-scheme:light;');
    LSb.Append('}');
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

function THelpChatTheme.ToJson: string;
var
  LRoot: TJSONObject;
  LTheme: THelpChatTheme;
begin
  LRoot := TJSONObject.Create;
  try
    if not IsEmpty then
    begin
      LTheme := Self;
      LTheme.Complete;
      ForEachVariable(LTheme,
        procedure(AName, AValue: string)
        begin
          if AValue <> '' then
            LRoot.AddPair(AName, AValue);
        end);
      if LTheme.IsDark then
        LRoot.AddPair('color-scheme', 'dark')
      else
        LRoot.AddPair('color-scheme', 'light');
    end;
    Result := LRoot.ToJSON;
  finally
    LRoot.Free;
  end;
end;

class function THelpChatTheme.Light: THelpChatTheme;
begin
  Result := Default(THelpChatTheme);
  Result.Name := 'Light';
  Result.IsDark := False;
  Result.Background := '#f6f7f9';
  Result.Surface := '#ffffff';
  Result.Text := '#1f2328';
  Result.Muted := '#6b7280';
  Result.Border := '#e2e5ea';
  Result.Accent := '#2563eb';
  Result.AccentText := '#ffffff';
  Result.CodeBackground := '#f1f3f5';
  Result.Complete;
end;

class function THelpChatTheme.Dark: THelpChatTheme;
begin
  Result := Default(THelpChatTheme);
  Result.Name := 'Dark';
  Result.IsDark := True;
  Result.Background := '#17191d';
  Result.Surface := '#22252b';
  Result.Text := '#e6e8eb';
  Result.Muted := '#9aa1ab';
  Result.Border := '#33373f';
  Result.Accent := '#3b82f6';
  Result.AccentText := '#ffffff';
  Result.CodeBackground := '#2b2f36';
  Result.Complete;
end;

end.
