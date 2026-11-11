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
///  The colour theme of the panel, framework independent. The page CSS is
///  written entirely in terms of <c>--hc-*</c> variables; a theme is a set of
///  values for those variables, rendered as a <c>:root</c> rule injected after
///  the default stylesheet (first load) or applied at runtime through
///  <c>window.hcApplyTheme</c> (style change). Colours are <c>#rrggbb</c>
///  strings so that VCL and FMX can each produce a theme from their own style
///  engine; a producer fills the five base colours (background, surface,
///  text, border, accent - as many as it knows) and <c>Complete</c> derives
///  the rest.
/// </summary>
unit HelpChatAI.Theme;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///  A set of values for the <c>--hc-*</c> variables of the page. A record
  ///  of strings: copied by value, so a transport can keep one under a lock
  ///  and hand out copies. It never reaches a server as a record - a remote
  ///  client sends <see cref="ToCss" />, a running page is given
  ///  <see cref="ToJson" /> - and nothing here depends on a framework: VCL
  ///  and FMX each fill one from their own style engine.
  /// </summary>
  THelpChatTheme = record
    /// <summary>Name of the source style (informational).</summary>
    Name: string;
    /// <summary>Decides the <c>color-scheme</c> of the page (scroll bars,
    /// form controls) and which defaults <c>Complete</c> picks for the
    /// system and error bubbles and the shadow. The producer sets it: it is
    /// not deduced from the background.</summary>
    IsDark: Boolean;
    // ---- base colours (set by the producer) ----------------------------------
    /// <summary>Page background.</summary>
    Background: string;
    /// <summary>Header, footer and assistant bubbles.</summary>
    Surface: string;
    /// <summary>Text on the background and on the surface; black or white,
    /// whichever contrasts with the background, when empty.</summary>
    Text: string;
    /// <summary>Every line of the page - under the header, around a bubble,
    /// the input, the cells of a table; a blend of surface and text when
    /// empty.</summary>
    Border: string;
    /// <summary>Send button and user bubbles.</summary>
    Accent: string;
    // ---- derived by Complete when empty ---------------------------------------
    /// <summary>Text drawn on the accent; black or white, whichever
    /// contrasts with it.</summary>
    AccentText: string;
    /// <summary>Secondary text: the greeting, the small buttons, a
    /// quotation; a blend of text and background when empty.</summary>
    Muted: string;
    /// <summary>Bubble of the user and its text; the accent and its contrast
    /// by default.</summary>
    UserBubble: string;
    UserText: string;
    /// <summary>Bubble of the assistant and its text; the surface and the
    /// text by default.</summary>
    AssistantBubble: string;
    AssistantText: string;
    /// <summary>Bubble of a system message (the answer to a command) and of
    /// an error, with their texts: fixed warm and red tones, light or dark,
    /// because a style has no colour for either.</summary>
    SystemBubble: string;
    SystemText: string;
    ErrorBubble: string;
    ErrorText: string;
    /// <summary>Background of code, inline and in blocks.</summary>
    CodeBackground: string;
    /// <summary>Colour of the shadow the header and the footer cast on the
    /// conversation, so that the bars read as the frame and not as a bubble
    /// that touched the edge.</summary>
    Shadow: string;
    /// <summary>Links, and the accent wherever it is drawn as a foreground
    /// (a focus ring, the tick of a copied answer). The accent itself when it
    /// reads on the assistant bubble; otherwise the accent moved towards the
    /// text until it does - Windows10 gives #cccccc as its accent, which on a
    /// light bubble is a link nobody can see.</summary>
    Link: string;
    /// <summary>CSS font-family list.</summary>
    FontFamily: string;
    /// <summary>CSS of the application, added to the page after its own
    /// stylesheet: the place for what a colour cannot say - a radius, a
    /// spacing, a hidden button. The components fill it from
    /// <c>PanelStyleSheet</c> before <c>OnGetTheme</c>, which may change it.
    /// It is written before the <c>:root</c> rule of the colours, so the
    /// <c>--hc-*</c> variables stay the theme's: a rule here that sets one is
    /// overridden whenever a colour is set. Not a colour, so it does not make
    /// a theme non-empty.</summary>
    StyleSheet: string;

    /// <summary>True when none of background, surface, text and accent is
    /// set (the page keeps its defaults, light or dark from the OS). A
    /// border or a derived colour alone does not make a theme and is not
    /// written; the stylesheet is not a colour and is written either
    /// way.</summary>
    function IsEmpty: Boolean;
    /// <summary>Normalizes the five base colours and fills every empty
    /// colour from them; a colour the producer set is kept. Changes the
    /// record it is called on, and can be called again. Two things it does
    /// beyond filling in: it moves the two bubbles apart when both were
    /// derived and came out the same colour, and it moves the link towards
    /// the text until it can be read on the assistant bubble.</summary>
    procedure Complete;
    /// <summary>The <c>StyleSheet</c>, then a ":root{...}" rule assigning every
    /// --hc-* variable (plus color-scheme) when a colour is set. Works on a
    /// completed copy: the record is left as it is. This string is what a
    /// session keeps and what a remote client posts; the values are written
    /// as they are, so the caller answers for them.</summary>
    function ToCss: string;
    /// <summary>A JSON object {"--hc-bg":"#...", ...} for window.hcApplyTheme,
    /// plus "css" with the <c>StyleSheet</c> when there is one. An empty
    /// theme gives an object without colours, which the page reads as "back
    /// to the defaults".</summary>
    function ToJson: string;
    /// <summary>The built-in light theme (the values of panel.css), already
    /// completed: what FireMonkey's <c>ThemeMode</c> uses, having no style
    /// to read colours from.</summary>
    class function Light: THelpChatTheme; static;
    /// <summary>The built-in dark theme, already completed.</summary>
    class function Dark: THelpChatTheme; static;
  end;

/// <summary>Normalizes a colour to lowercase "#rrggbb"; accepts "#rgb", "rrggbb", "#rrggbb".
/// Returns '' when the input is not a colour.</summary>
function HelpChatNormalizeColor(const AColor: string): string;
/// <summary>"#rrggbb" from components.</summary>
function HelpChatRgbToHex(const R, G, B: Integer): string;
/// <summary>Components of a "#rrggbb" colour; False when it cannot be parsed.</summary>
function HelpChatHexToRgb(const AColor: string; out R, G, B: Integer): Boolean;
/// <summary>Linear blend of two colours: 0 = A, 1 = B. When one of them is
/// not a colour the other is returned, normalized.</summary>
function HelpChatBlend(const AColorA, AColorB: string; const ARatio: Double): string;
/// <summary>Perceived luminance 0..1 (0.299 R + 0.587 G + 0.114 B). 1 for
/// what is not a colour: an unknown background counts as light.</summary>
function HelpChatLuminance(const AColor: string): Double;
/// <summary>True when the colour reads as dark (luminance below 0.5).</summary>
function HelpChatIsDarkColor(const AColor: string): Boolean;
/// <summary>Black or white, whichever contrasts with the given colour.</summary>
function HelpChatContrastText(const AColor: string): string;
/// <summary>Saturation 0..1 (max - min of the components).</summary>
function HelpChatSaturation(const AColor: string): Double;
/// <summary>How far apart two colours are, 0..1: the largest difference of
/// their components. 1 when either of them cannot be parsed.</summary>
function HelpChatColorDistance(const AColorA, AColorB: string): Double;

implementation

uses
  System.Character,
  System.JSON;

const
  /// The font of the page when the producer names none: the one of the
  /// system, whichever system the WebView runs on.
  HELPCHAT_DEF_FONT = 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';
  /// Below this, the bubble of the user and the one of the assistant read as
  /// one colour (0..1, the scale of HelpChatColorDistance).
  HELPCHAT_BUBBLE_MIN_DISTANCE = 0.12;
  /// Below this difference of luminance (0..1) a link does not read on the
  /// bubble it sits in. The dark defaults of the page (#3b82f6 on #22252b)
  /// are just above it.
  HELPCHAT_LINK_MIN_LUMA = 0.33;
  HELPCHAT_DEF_SHADOW_LIGHT = 'rgba(0,0,0,0.16)';
  HELPCHAT_DEF_SHADOW_DARK = 'rgba(0,0,0,0.55)';

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

function HelpChatColorDistance(const AColorA, AColorB: string): Double;
var
  R1, G1, B1, R2, G2, B2, LMax: Integer;
begin
  if not HelpChatHexToRgb(AColorA, R1, G1, B1) or not HelpChatHexToRgb(AColorB, R2, G2, B2) then
    Exit(1);
  LMax := Abs(R1 - R2);
  if Abs(G1 - G2) > LMax then
    LMax := Abs(G1 - G2);
  if Abs(B1 - B2) > LMax then
    LMax := Abs(B1 - B2);
  Result := LMax / 255;
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
var
  LUserDerived, LAssistantDerived: Boolean;
  LStep: Integer;
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
  LUserDerived := UserBubble = '';
  if UserBubble = '' then
    UserBubble := Accent;
  LAssistantDerived := AssistantBubble = '';
  if AssistantBubble = '' then
    AssistantBubble := Surface;
  // Two bubbles of the same colour are one bubble. What a style gives for the
  // user (its accent) and for the assistant (its surface) is now and then the
  // same colour - Windows10 answers #cccccc for both, Windows10 Dark #262626 -
  // so when they read as one, the user's takes a step away from the page and
  // the assistant's one towards it. Only colours derived here are moved: a
  // theme that sets both on purpose is left as it is.
  if LUserDerived and LAssistantDerived and
     (HelpChatColorDistance(UserBubble, AssistantBubble) < HELPCHAT_BUBBLE_MIN_DISTANCE) then
    if IsDark then
    begin
      UserBubble := HelpChatBlend(UserBubble, '#ffffff', 0.22);
      AssistantBubble := HelpChatBlend(AssistantBubble, '#000000', 0.22);
    end
    else
    begin
      UserBubble := HelpChatBlend(UserBubble, '#000000', 0.18);
      AssistantBubble := HelpChatBlend(AssistantBubble, '#ffffff', 0.35);
    end;
  if UserText = '' then
    UserText := HelpChatContrastText(UserBubble);
  if AssistantText = '' then
    AssistantText := Text;
  if CodeBackground = '' then
    CodeBackground := HelpChatBlend(Surface, Text, 0.08);
  // The accent as a foreground: towards the text of the bubble, a tenth at a
  // time, until it stands out from the bubble. The text always does, so the
  // loop ends; an accent that already reads is left exactly as it is.
  if Link = '' then
  begin
    Link := Accent;
    LStep := 0;
    while (LStep < 10) and
      (Abs(HelpChatLuminance(Link) - HelpChatLuminance(AssistantBubble)) < HELPCHAT_LINK_MIN_LUMA) do
    begin
      Inc(LStep);
      Link := HelpChatBlend(Accent, AssistantText, LStep / 10);
    end;
  end;
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
  if Shadow = '' then
    if IsDark then
      Shadow := HELPCHAT_DEF_SHADOW_DARK
    else
      Shadow := HELPCHAT_DEF_SHADOW_LIGHT;
  if FontFamily = '' then
    FontFamily := HELPCHAT_DEF_FONT;
end;

// The variable names are the contract with panel.css. ToCss and ToJson both
// go through here, so the page loads and is re-themed with the same list; a
// new variable is added here, in panel.css and in the names of hcApplyTheme
// in panel.js, which is what removes it again when a theme no longer sets it.
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
  AProc('--hc-link', ATheme.Link);
  AProc('--hc-shadow', ATheme.Shadow);
  AProc('--hc-font', ATheme.FontFamily);
end;

function THelpChatTheme.ToCss: string;
var
  LSb: TStringBuilder;
  LTheme: THelpChatTheme;
begin
  if IsEmpty then
    Exit(StyleSheet);
  LTheme := Self;
  LTheme.Complete;
  LSb := TStringBuilder.Create;
  try
    // First, so that the colours below win over a variable it sets.
    if StyleSheet <> '' then
      LSb.Append(StyleSheet).Append(sLineBreak);
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
    if StyleSheet <> '' then
      LRoot.AddPair('css', StyleSheet);
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
