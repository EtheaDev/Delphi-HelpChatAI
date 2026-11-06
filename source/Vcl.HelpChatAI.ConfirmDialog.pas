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
///  The dialog that asks the user whether an action of the assistant may run.
///
///  What the component needs of it is the interface
///  <see cref="IVclHelpChatConfirmDialog" />: show a request and answer, and
///  go away when told to. <see cref="TVclHelpChatConfirmDialog" /> is the one
///  the library ships, a form with a DFM laid out like a task dialog - a
///  warning sign, the name of the action as the instruction, the description
///  the application wrote, then the values the model wants to pass, one per
///  line, each labelled and in bold, a note at the foot saying who wrote them,
///  and No as the default button, counting down to an automatic No. An
///  application that wants another one writes a form of its own, implements
///  the interface on it and names it with
///  <see cref="RegisterVclHelpChatConfirmDialog" />: the component creates
///  it, owned by the host form, for each question.
///
///  It is a form of ours and not the task dialog of Windows because a VCL
///  style paints a form and not a common control (an application with a dark
///  style got a white dialog), and because the text of a task dialog has no
///  bold. It is a form with a DFM and not one built in code because the VCL
///  scales a form it loads for the monitor it is on, at creation and again
///  when it moves - a form built by hand got the font of one screen and the
///  layout of another.
///
///  One dialog at a time: a second request arriving while one is open (the
///  model asked again, from inside the modal loop of the first) dismisses the
///  first as No and takes its place.
/// </summary>
unit Vcl.HelpChatAI.ConfirmDialog;

{$I HelpChatAI.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  HelpChatAI.Messages,
  HelpChatAI.Actions;

const
  /// <summary>How long the dialog waits for the user before answering No
  /// by itself. Shorter than the timeout of the action broker (60 s), so the
  /// model is told "not allowed" rather than "did not answer".</summary>
  HELPCHAT_CONFIRM_TIMEOUT_MS = 30000;

type
  /// <summary>Everything a confirmation dialog may want to show. The texts
  /// are ready to display, in the language of the component; the action and
  /// the arguments are there for a dialog that wants to read the raw values
  /// or the declared parameters itself.</summary>
  TVclHelpChatConfirmRequest = record
    /// <summary>The form the chat belongs to: the dialog is modal over it
    /// and centred on it. May be nil.</summary>
    Host: TCustomForm;
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
  /// implements it, registered with <see cref="RegisterVclHelpChatConfirmDialog" />,
  /// replaces the one of the library.</summary>
  IVclHelpChatConfirmDialog = interface
    ['{B7E1C2A4-5F60-4D8B-9C3E-2A1F7D6E8B90}']
    /// <summary>Shows the question modally and returns True when the user
    /// allowed the action. Called on the main thread, while a worker of the
    /// model waits for the answer with a timeout of its own.</summary>
    function Execute(const ARequest: TVclHelpChatConfirmRequest): Boolean;
    /// <summary>Closes as No from outside its own modal loop: another
    /// question arrived while this one was open. The dialog hides at once
    /// and ends its loop as soon as it gets the control back.</summary>
    procedure Dismiss;
  end;

  /// <summary>The confirmation dialog of the library.</summary>
  TVclHelpChatConfirmDialog = class(TForm, IVclHelpChatConfirmDialog)
    HeaderPanel: TPanel;
    IconImage: TImage;
    TitleLabel: TLabel;
    DescriptionLabel: TLabel;
    ValuesPanel: TPanel;
    FooterPanel: TPanel;
    FooterBevel: TBevel;
    FooterImage: TImage;
    FooterLabel: TLabel;
    ButtonsPanel: TPanel;
    YesButton: TButton;
    NoButton: TButton;
    CountdownTimer: TTimer;
    procedure CountdownTimerTimer(Sender: TObject);
  private
    FSecondsLeft: Integer;
    procedure LoadStockIcon(const AImage: TImage; const AId: PChar);
    procedure ShowSecondsLeft;
    function NewLabel(const AText: string; const ALeft, ATop, AWidth: Integer;
      const ABold: Boolean): TLabel;
  public
    function Execute(const ARequest: TVclHelpChatConfirmRequest): Boolean;
    procedure Dismiss;
  end;

var
  /// <summary>The class the component creates for each question: the dialog
  /// of the library unless <see cref="RegisterVclHelpChatConfirmDialog" />
  /// named another.</summary>
  VclHelpChatConfirmDialogClass: TComponentClass = TVclHelpChatConfirmDialog;

/// <summary>Names the form class to ask with. It must implement
/// <see cref="IVclHelpChatConfirmDialog" />; nil goes back to the dialog of
/// the library.</summary>
procedure RegisterVclHelpChatConfirmDialog(const AClass: TComponentClass);

/// <summary>Asks with the registered dialog, created for the question and
/// owned by the host, and returns True when the user allowed the action.
/// A dialog still open from a previous question is dismissed first.</summary>
function HelpChatVclConfirmAction(const ARequest: TVclHelpChatConfirmRequest): Boolean;

implementation

{$R *.dfm}

uses
  System.Math,
  System.UITypes,
  Vcl.Consts,
  Winapi.CommCtrl,
  HelpChatAI.Types;

var
  /// <summary>The dialog that is open, if one is: there is one at a time.</summary>
  OpenDialog: IVclHelpChatConfirmDialog = nil;

procedure RegisterVclHelpChatConfirmDialog(const AClass: TComponentClass);
begin
  if AClass = nil then
    VclHelpChatConfirmDialogClass := TVclHelpChatConfirmDialog
  else if not Supports(AClass, IVclHelpChatConfirmDialog) then
    raise EHelpChatError.CreateFmt('%s does not implement IVclHelpChatConfirmDialog',
      [AClass.ClassName])
  else
    VclHelpChatConfirmDialogClass := AClass;
end;

function HelpChatVclConfirmAction(const ARequest: TVclHelpChatConfirmRequest): Boolean;
var
  LComponent: TComponent;
  LDialog: IVclHelpChatConfirmDialog;
begin
  // A dialog is open: this call runs inside its modal loop (a queued
  // request of the broker got through). The old question is dismissed as
  // No - the model that asked it has moved on - and the new one takes over.
  if Assigned(OpenDialog) then
    OpenDialog.Dismiss;
  // Owned by the host so that poOwnerFormCenter centres it there.
  LComponent := VclHelpChatConfirmDialogClass.Create(ARequest.Host);
  try
    if not Supports(LComponent, IVclHelpChatConfirmDialog, LDialog) then
      raise EHelpChatError.CreateFmt('%s does not implement IVclHelpChatConfirmDialog',
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

{ TVclHelpChatConfirmDialog }

procedure TVclHelpChatConfirmDialog.LoadStockIcon(const AImage: TImage; const AId: PChar);
var
  LHandle: HICON;
  LIcon: TIcon;
begin
  // The stock icon at the size the image has after the scaling of the form.
  // LoadImage with a size does not promise it for a system icon (it handed
  // back the one of the system DPI, which the image then cut);
  // LoadIconWithScaleDown exists for this, and the handle it returns is ours.
  if Failed(LoadIconWithScaleDown(0, AId, AImage.Width, AImage.Height, LHandle)) then
    LHandle := CopyIcon(LoadIcon(0, AId));
  if LHandle = 0 then
    Exit;
  LIcon := TIcon.Create;
  try
    LIcon.Handle := LHandle;
    AImage.Picture.Assign(LIcon);
  finally
    LIcon.Free;
  end;
end;

function TVclHelpChatConfirmDialog.NewLabel(const AText: string;
  const ALeft, ATop, AWidth: Integer; const ABold: Boolean): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := ValuesPanel;
  Result.WordWrap := True;
  Result.ShowAccelChar := False; // a value may carry an ampersand
  if ABold then
    Result.Font.Style := Result.Font.Style + [fsBold];
  Result.SetBounds(ALeft, ATop, AWidth, 0);
  Result.Caption := AText;
  // AutoSize with WordWrap keeps the width and grows the height.
  Result.AutoSize := True;
end;

function TVclHelpChatConfirmDialog.Execute(const ARequest: TVclHelpChatConfirmRequest): Boolean;
var
  LGap, LMargin, LTop, LLeft, LLabelWidth, LHeight, I: Integer;
  LLabel, LValue: TLabel;
begin
  if Assigned(ARequest.Host) then
    PopupParent := ARequest.Host; // above the host, and above the window of the chat
  Caption := ARequest.Caption;
  LoadStockIcon(IconImage, IDI_WARNING);
  LoadStockIcon(FooterImage, IDI_INFORMATION);
  YesButton.Caption := SMsgDlgYes;
  NoButton.Caption := SMsgDlgNo;
  // The form was scaled for its monitor when it was created: what the DFM
  // says in 96-DPI pixels is already converted, and ScaleValue converts the
  // few distances computed here. The designed labels have AutoSize off so
  // that they keep their width; on, with WordWrap, they grow in height.
  LGap := ScaleValue(8);
  LMargin := ScaleValue(16);
  LLeft := DescriptionLabel.Left;

  // The header: the instruction, then the description under it.
  TitleLabel.Caption := ARequest.Title;
  TitleLabel.AutoSize := True;
  DescriptionLabel.Caption := Trim(ARequest.Description);
  DescriptionLabel.AutoSize := True;
  DescriptionLabel.Visible := DescriptionLabel.Caption <> '';
  DescriptionLabel.Top := TitleLabel.Top + TitleLabel.Height + LGap;
  if DescriptionLabel.Visible then
    LTop := DescriptionLabel.Top + DescriptionLabel.Height
  else
    LTop := TitleLabel.Top + TitleLabel.Height;
  HeaderPanel.Height := LTop + LMargin;

  // The values, two columns: the labels as wide as the widest of them,
  // within reason, the values in bold taking the rest and wrapping.
  ValuesPanel.Visible := Length(ARequest.Values) > 0;
  LHeight := 0;
  if ValuesPanel.Visible then
  begin
    Canvas.Font := Font;
    LLabelWidth := 0;
    for I := Low(ARequest.Values) to High(ARequest.Values) do
      LLabelWidth := Max(LLabelWidth, Canvas.TextWidth(ARequest.Values[I].Key + ':'));
    LLabelWidth := Min(LLabelWidth + LGap, (ValuesPanel.ClientWidth - LLeft - LMargin) div 2);
    LTop := 0;
    for I := Low(ARequest.Values) to High(ARequest.Values) do
    begin
      LLabel := NewLabel(ARequest.Values[I].Key + ':', LLeft, LTop, LLabelWidth, False);
      LValue := NewLabel(ARequest.Values[I].Value, LLeft + LLabelWidth, LTop,
        ValuesPanel.ClientWidth - LLeft - LLabelWidth - LMargin, True);
      LTop := LTop + Max(LLabel.Height, LValue.Height) + LGap div 2;
    end;
    ValuesPanel.Height := LTop + LGap;
    LHeight := ValuesPanel.Height;
  end;

  // The footer: only under values, because it is about them.
  FooterLabel.Caption := Trim(ARequest.Footer);
  FooterLabel.AutoSize := True;
  FooterPanel.Visible := ValuesPanel.Visible and (FooterLabel.Caption <> '');
  if FooterPanel.Visible then
  begin
    FooterPanel.Height := FooterLabel.Top + FooterLabel.Height + LGap;
    LHeight := LHeight + FooterPanel.Height;
  end;

  ClientHeight := HeaderPanel.Height + LHeight + ButtonsPanel.Height;

  if ARequest.TimeoutMs > 0 then
  begin
    FSecondsLeft := (ARequest.TimeoutMs + 999) div 1000;
    ShowSecondsLeft;
    CountdownTimer.Enabled := True;
  end;
  ActiveControl := NoButton;
  Result := ShowModal = mrYes;
end;

procedure TVclHelpChatConfirmDialog.ShowSecondsLeft;
begin
  NoButton.Caption := Format('%s (%d)', [SMsgDlgNo, FSecondsLeft]);
end;

procedure TVclHelpChatConfirmDialog.CountdownTimerTimer(Sender: TObject);
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

procedure TVclHelpChatConfirmDialog.Dismiss;
begin
  CountdownTimer.Enabled := False;
  Hide;
  ModalResult := mrNo;
end;

end.
