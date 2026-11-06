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
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  The FireMonkey dialog that asks the user whether an action of the
///  assistant may run: the twin of <c>Vcl.HelpChatAI.ConfirmDialog</c>.
///
///  What the component needs of it is <see cref="IFmxHelpChatConfirmDialog" />:
///  show a request and answer, and go away when told to.
///  <see cref="TFmxHelpChatConfirmDialog" /> is the one the library ships, a
///  form with an FMX laid out like a task dialog - a warning sign, the name
///  of the action as the instruction, the description the application wrote,
///  then the values the model wants to pass, one per line, each labelled and
///  in bold, a note at the foot saying who wrote them, and No as the default
///  button, counting down to an automatic No. An application that wants
///  another one writes a form of its own, implements the interface and names
///  it with <see cref="RegisterFmxHelpChatConfirmDialog" />.
///
///  It is a form of ours and not <c>TDialogService.MessageDialog</c> because
///  on Windows that one is the message box of the system, which no FireMonkey
///  style paints: an application with a dark style got a white dialog. A form
///  follows the style of the application like every other form.
///
///  It answers on the desktop only: there <c>ShowModal</c> returns the
///  answer, and a worker of the model is waiting for it. On a mobile platform
///  a modal form answers in a callback later on, so without
///  <c>OnActionConfirm</c> the action is refused, as before.
/// </summary>
unit FMX.HelpChatAI.ConfirmDialog;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  System.UITypes,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Objects,
  HelpChatAI.Messages,
  HelpChatAI.Actions;

const
  /// <summary>How long the dialog waits for the user before answering No
  /// by itself. Shorter than the timeout of the action broker (60 s), so the
  /// model is told "not allowed" rather than "did not answer".</summary>
  HELPCHAT_CONFIRM_TIMEOUT_MS = 30000;

type
  /// <summary>Everything a confirmation dialog may want to show: the same
  /// record as the VCL one, with a FireMonkey host.</summary>
  TFmxHelpChatConfirmRequest = record
    /// <summary>The form the chat belongs to: the dialog is centred on it.
    /// May be nil.</summary>
    Host: TCommonCustomForm;
    /// <summary>Title of the window: the name of the assistant.</summary>
    Caption: string;
    /// <summary>The instruction: "The assistant wants to run ...".</summary>
    Title: string;
    /// <summary>What the action does, as the application described it.</summary>
    Description: string;
    /// <summary>The values the model wants to pass: label (the description of
    /// the parameter, cut short) and value, safe for display, in the order of
    /// the declaration. Empty when the action takes none.</summary>
    Values: TArray<TPair<string, string>>;
    /// <summary>The note under the values, saying who wrote them.</summary>
    Footer: string;
    /// <summary>After this many milliseconds without an answer the dialog
    /// closes as No; zero means no limit.</summary>
    TimeoutMs: Integer;
    /// <summary>Language of the component, for a dialog with texts of its own.</summary>
    Language: THelpChatLanguage;
    /// <summary>Name of the action.</summary>
    ActionName: string;
    /// <summary>The action, with its description and parameters; nil when
    /// nobody registered one by that name.</summary>
    Action: THelpChatAction;
    /// <summary>The arguments as the model sent them.</summary>
    Args: THelpChatActionArgs;
  end;

  /// <summary>What the component asks of a confirmation dialog. A form that
  /// implements it, registered with <see cref="RegisterFmxHelpChatConfirmDialog" />,
  /// replaces the one of the library.</summary>
  IFmxHelpChatConfirmDialog = interface
    ['{6D2F8A1B-3C44-4E79-A0B5-9F1D2C3E4B57}']
    /// <summary>Shows the question modally and returns True when the user
    /// allowed the action. Called on the main thread, while a worker of the
    /// model waits for the answer with a timeout of its own.</summary>
    function Execute(const ARequest: TFmxHelpChatConfirmRequest): Boolean;
    /// <summary>Closes as No from outside its own modal loop: another
    /// question arrived while this one was open.</summary>
    procedure Dismiss;
  end;

  /// <summary>The confirmation dialog of the library.</summary>
  TFmxHelpChatConfirmDialog = class(TForm, IFmxHelpChatConfirmDialog)
    HeaderLayout: TLayout;
    TitleLabel: TLabel;
    DescriptionLabel: TLabel;
    ValuesLayout: TLayout;
    FooterLayout: TLayout;
    FooterLine: TLine;
    FooterLabel: TLabel;
    ButtonsLayout: TLayout;
    YesButton: TButton;
    NoButton: TButton;
    CountdownTimer: TTimer;
    procedure CountdownTimerTimer(Sender: TObject);
  private
    FSecondsLeft: Integer;
    procedure ShowSecondsLeft;
    procedure AddWarningSign(const AParent: TControl; const AX, AY, ASize: Single);
    procedure AddInfoSign(const AParent: TControl; const AX, AY, ASize: Single);
    /// <summary>Gives a label the height its text needs at its width: the
    /// text is measured with a layout, so no canvas and no style is needed
    /// before the form is shown.</summary>
    procedure FitLabel(const ALabel: TLabel);
    function NewLabel(const AText: string; const AX, AY, AWidth: Single;
      const ABold: Boolean): TLabel;
  public
    function Execute(const ARequest: TFmxHelpChatConfirmRequest): Boolean;
    procedure Dismiss;
  end;

var
  /// <summary>The class the component creates for each question: the dialog
  /// of the library unless <see cref="RegisterFmxHelpChatConfirmDialog" />
  /// named another.</summary>
  FmxHelpChatConfirmDialogClass: TComponentClass = TFmxHelpChatConfirmDialog;

/// <summary>Names the form class to ask with. It must implement
/// <see cref="IFmxHelpChatConfirmDialog" />; nil goes back to the dialog of
/// the library.</summary>
procedure RegisterFmxHelpChatConfirmDialog(const AClass: TComponentClass);

/// <summary>True where a modal form answers before returning (Windows and
/// macOS): where the dialog can be used at all.</summary>
function HelpChatFmxCanConfirm: Boolean;

/// <summary>Asks with the registered dialog, created for the question and
/// owned by the host, and returns True when the user allowed the action.
/// A dialog still open from a previous question is dismissed first. False,
/// without asking, where <see cref="HelpChatFmxCanConfirm" /> is False.</summary>
function HelpChatFmxConfirmAction(const ARequest: TFmxHelpChatConfirmRequest): Boolean;

implementation

{$R *.fmx}

uses
  System.Math,
  FMX.TextLayout,
  FMX.Graphics,
  FMX.Consts,
  HelpChatAI.Types;

var
  OpenDialog: IFmxHelpChatConfirmDialog = nil;

procedure RegisterFmxHelpChatConfirmDialog(const AClass: TComponentClass);
begin
  if AClass = nil then
    FmxHelpChatConfirmDialogClass := TFmxHelpChatConfirmDialog
  else if not Supports(AClass, IFmxHelpChatConfirmDialog) then
    raise EHelpChatError.CreateFmt('%s does not implement IFmxHelpChatConfirmDialog',
      [AClass.ClassName])
  else
    FmxHelpChatConfirmDialogClass := AClass;
end;

function HelpChatFmxCanConfirm: Boolean;
begin
  {$IF defined(MSWINDOWS) or (defined(MACOS) and not defined(IOS))}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function HelpChatFmxConfirmAction(const ARequest: TFmxHelpChatConfirmRequest): Boolean;
var
  LComponent: TComponent;
  LDialog: IFmxHelpChatConfirmDialog;
begin
  if not HelpChatFmxCanConfirm then
    Exit(False);
  // A dialog is open: this call runs inside its modal loop (a queued
  // request of the broker got through). The old question is dismissed as
  // No - the model that asked it has moved on - and the new one takes over.
  if Assigned(OpenDialog) then
    OpenDialog.Dismiss;
  LComponent := FmxHelpChatConfirmDialogClass.Create(ARequest.Host);
  try
    if not Supports(LComponent, IFmxHelpChatConfirmDialog, LDialog) then
      raise EHelpChatError.CreateFmt('%s does not implement IFmxHelpChatConfirmDialog',
        [LComponent.ClassName]);
    OpenDialog := LDialog;
    try
      Result := LDialog.Execute(ARequest);
    finally
      if OpenDialog = LDialog then
        OpenDialog := nil;
    end;
  finally
    // A TComponent is not reference counted: the interface goes before the object.
    LDialog := nil;
    LComponent.Free;
  end;
end;

{ TFmxHelpChatConfirmDialog }

procedure TFmxHelpChatConfirmDialog.AddWarningSign(const AParent: TControl;
  const AX, AY, ASize: Single);
var
  LPath: TPath;
  LMark: TLabel;
begin
  // No stock icons in FireMonkey: a triangle and an exclamation mark, in
  // the colours every platform uses for a warning.
  LPath := TPath.Create(Self);
  LPath.Parent := AParent;
  LPath.SetBounds(AX, AY, ASize, ASize);
  LPath.WrapMode := TPathWrapMode.Fit;
  LPath.Data.Data := 'M 50,4 L 96,92 L 4,92 Z';
  LPath.Fill.Color := $FFFFC107;
  LPath.Stroke.Kind := TBrushKind.None;
  LPath.HitTest := False;
  LMark := TLabel.Create(Self);
  LMark.Parent := AParent;
  LMark.SetBounds(AX, AY + ASize * 0.18, ASize, ASize * 0.8);
  LMark.StyledSettings := [];
  LMark.TextSettings.Font.Family := 'Segoe UI';
  LMark.TextSettings.Font.Size := ASize * 0.6;
  LMark.TextSettings.Font.Style := [TFontStyle.fsBold];
  LMark.TextSettings.FontColor := TAlphaColors.Black;
  LMark.TextSettings.HorzAlign := TTextAlign.Center;
  LMark.TextSettings.VertAlign := TTextAlign.Center;
  LMark.Text := '!';
  LMark.HitTest := False;
end;

procedure TFmxHelpChatConfirmDialog.AddInfoSign(const AParent: TControl;
  const AX, AY, ASize: Single);
var
  LCircle: TCircle;
  LMark: TLabel;
begin
  LCircle := TCircle.Create(Self);
  LCircle.Parent := AParent;
  LCircle.SetBounds(AX, AY, ASize, ASize);
  LCircle.Fill.Color := $FF1E88E5;
  LCircle.Stroke.Kind := TBrushKind.None;
  LCircle.HitTest := False;
  LMark := TLabel.Create(Self);
  LMark.Parent := AParent;
  LMark.SetBounds(AX, AY, ASize, ASize);
  LMark.StyledSettings := [];
  LMark.TextSettings.Font.Family := 'Segoe UI';
  LMark.TextSettings.Font.Size := ASize * 0.7;
  LMark.TextSettings.Font.Style := [TFontStyle.fsBold];
  LMark.TextSettings.FontColor := TAlphaColors.White;
  LMark.TextSettings.HorzAlign := TTextAlign.Center;
  LMark.TextSettings.VertAlign := TTextAlign.Center;
  LMark.Text := 'i';
  LMark.HitTest := False;
end;

procedure TFmxHelpChatConfirmDialog.FitLabel(const ALabel: TLabel);
var
  LLayout: TTextLayout;
begin
  LLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    LLayout.BeginUpdate;
    try
      LLayout.Font.Assign(ALabel.TextSettings.Font);
      LLayout.WordWrap := True;
      LLayout.MaxSize := TPointF.Create(ALabel.Width, 10000);
      LLayout.Text := ALabel.Text;
    finally
      LLayout.EndUpdate;
    end;
    // A little room for a style whose font is taller than the measured one.
    ALabel.Height := Ceil(LLayout.TextHeight) + 4;
  finally
    LLayout.Free;
  end;
end;

function TFmxHelpChatConfirmDialog.NewLabel(const AText: string;
  const AX, AY, AWidth: Single; const ABold: Boolean): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := ValuesLayout;
  Result.SetBounds(AX, AY, AWidth, 20);
  Result.TextSettings.WordWrap := True;
  Result.TextSettings.VertAlign := TTextAlign.Leading;
  Result.StyledSettings := Result.StyledSettings - [TStyledSetting.Other];
  if ABold then
  begin
    Result.StyledSettings := Result.StyledSettings - [TStyledSetting.Style];
    Result.TextSettings.Font.Style := [TFontStyle.fsBold];
  end;
  Result.Text := AText;
  FitLabel(Result);
end;

function TFmxHelpChatConfirmDialog.Execute(const ARequest: TFmxHelpChatConfirmRequest): Boolean;
const
  GAP = 8;
  MARGIN = 16;
var
  LTop, LLeft, LLabelWidth, LHeight: Single;
  LLabel, LValue: TLabel;
  LLayout: TTextLayout;
  I: Integer;
begin
  // The style of the host, when it has one of its own; a style set through
  // the style manager reaches this form like every other.
  if Assigned(ARequest.Host) and Assigned(ARequest.Host.StyleBook) then
    StyleBook := ARequest.Host.StyleBook;
  Caption := ARequest.Caption;
  YesButton.Text := SMsgDlgYes;
  NoButton.Text := SMsgDlgNo;
  AddWarningSign(HeaderLayout, MARGIN, MARGIN, 32);
  LLeft := DescriptionLabel.Position.X;

  // The header: the instruction, a size larger, then the description.
  TitleLabel.StyledSettings := TitleLabel.StyledSettings - [TStyledSetting.Size, TStyledSetting.Other];
  TitleLabel.TextSettings.Font.Size := 16;
  TitleLabel.TextSettings.WordWrap := True;
  TitleLabel.Text := ARequest.Title;
  FitLabel(TitleLabel);
  DescriptionLabel.StyledSettings := DescriptionLabel.StyledSettings - [TStyledSetting.Other];
  DescriptionLabel.TextSettings.WordWrap := True;
  DescriptionLabel.Text := Trim(ARequest.Description);
  DescriptionLabel.Visible := DescriptionLabel.Text <> '';
  DescriptionLabel.Position.Y := TitleLabel.Position.Y + TitleLabel.Height + GAP;
  if DescriptionLabel.Visible then
  begin
    FitLabel(DescriptionLabel);
    LTop := DescriptionLabel.Position.Y + DescriptionLabel.Height;
  end
  else
    LTop := TitleLabel.Position.Y + TitleLabel.Height;
  HeaderLayout.Height := LTop + MARGIN;

  // The values, two columns: the labels as wide as the widest of them,
  // within reason, the values in bold taking the rest and wrapping.
  ValuesLayout.Visible := Length(ARequest.Values) > 0;
  LHeight := 0;
  if ValuesLayout.Visible then
  begin
    LLabelWidth := 0;
    LLayout := TTextLayoutManager.DefaultTextLayout.Create;
    try
      LLayout.Font.Assign(DescriptionLabel.TextSettings.Font);
      for I := Low(ARequest.Values) to High(ARequest.Values) do
      begin
        LLayout.Text := ARequest.Values[I].Key + ':';
        LLabelWidth := Max(LLabelWidth, LLayout.TextWidth);
      end;
    finally
      LLayout.Free;
    end;
    LLabelWidth := Min(LLabelWidth + GAP, (ValuesLayout.Width - LLeft - MARGIN) / 2);
    LTop := 0;
    for I := Low(ARequest.Values) to High(ARequest.Values) do
    begin
      LLabel := NewLabel(ARequest.Values[I].Key + ':', LLeft, LTop, LLabelWidth, False);
      LValue := NewLabel(ARequest.Values[I].Value, LLeft + LLabelWidth, LTop,
        ValuesLayout.Width - LLeft - LLabelWidth - MARGIN, True);
      LTop := LTop + Max(LLabel.Height, LValue.Height) + GAP / 2;
    end;
    ValuesLayout.Height := LTop + GAP;
    LHeight := ValuesLayout.Height;
  end;

  // The footer: only under values, because it is about them.
  FooterLabel.StyledSettings := FooterLabel.StyledSettings - [TStyledSetting.Other];
  FooterLabel.TextSettings.WordWrap := True;
  FooterLabel.Text := Trim(ARequest.Footer);
  FooterLayout.Visible := ValuesLayout.Visible and (FooterLabel.Text <> '');
  if FooterLayout.Visible then
  begin
    AddInfoSign(FooterLayout, MARGIN, FooterLabel.Position.Y, 16);
    FitLabel(FooterLabel);
    FooterLayout.Height := FooterLabel.Position.Y + FooterLabel.Height + GAP;
    LHeight := LHeight + FooterLayout.Height;
  end;

  ClientHeight := Round(HeaderLayout.Height + LHeight + ButtonsLayout.Height);

  if ARequest.TimeoutMs > 0 then
  begin
    FSecondsLeft := (ARequest.TimeoutMs + 999) div 1000;
    ShowSecondsLeft;
    CountdownTimer.Enabled := True;
  end;
  ActiveControl := NoButton;
  Result := ShowModal = mrYes;
end;

procedure TFmxHelpChatConfirmDialog.ShowSecondsLeft;
begin
  NoButton.Text := Format('%s (%d)', [SMsgDlgNo, FSecondsLeft]);
end;

procedure TFmxHelpChatConfirmDialog.CountdownTimerTimer(Sender: TObject);
begin
  Dec(FSecondsLeft);
  if FSecondsLeft > 0 then
    ShowSecondsLeft
  else
  begin
    CountdownTimer.Enabled := False;
    ModalResult := mrNo;
  end;
end;

procedure TFmxHelpChatConfirmDialog.Dismiss;
begin
  CountdownTimer.Enabled := False;
  Hide;
  ModalResult := mrNo;
end;

end.
