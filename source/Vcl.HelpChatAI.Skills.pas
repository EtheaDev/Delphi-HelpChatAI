{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       The VCL screen of the skills: the form the user is on, its fields,     }
{       buttons, lists and pages, seen through the controls of the VCL.        }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{       you may not use this file except in compliance with the License.       }
{       You may obtain a copy of the License at                                }
{                                                                              }
{       http://www.apache.org/licenses/LICENSE-2.0                             }
{                                                                              }
{       Unless required by applicable law or agreed to in writing, software    }
{       distributed under the License is distributed on an "AS IS" BASIS,      }
{       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.}
{       See the License for the specific language governing permissions and    }
{       limitations under the License.                                         }
{                                                                              }
{******************************************************************************}
/// <summary>
///  The four screen skills - <c>forms</c>, <c>commands</c>, <c>records</c>,
///  <c>pages</c> - are written once, in <c>HelpChatAI.Skills.Screen</c>; this
///  unit gives them the VCL screen (registered as a screen provider, and
///  linked by <c>Vcl.HelpChatAI</c>, so naming them in <c>Settings.Skills</c>
///  is enough).
///  The screen is the form the user is working on (<see cref="HelpChatVclWorkingForm" />:
///  the active one, else the one active last, never the window of the chat;
///  its active MDI child for an MDI form), and it holds what the user sees:
///  the controls that are visible and enabled, in tab order, outside the
///  chat. A field is a control bound to a field by LiveBindings
///  (<c>TLinkControlToField</c>: the value goes through the <c>TField</c> of
///  its <c>TBindSourceDB</c>; <c>TLinkFillControlToField</c> makes it a lookup),
///  or a control an adapter accepts (<see cref="THelpChatVclFieldAdapter" />):
///  any data-aware control (a published <c>DataSource</c> and
///  <c>DataField</c>: the value goes through the <c>TField</c>), edits,
///  memos, combo boxes, check boxes, radio groups and buttons, date pickers.
///  The bindings are read through RTTI, by the names of their classes, the
///  way FireMonkey reads them (<c>HelpChatScanBindings</c>): a grid or a list
///  a link fills with a data set is a list, a <c>TBindNavigator</c> is a
///  navigator.
///  Its id is the name of the control; its caption the label whose
///  <c>FocusControl</c> it is, else its own caption, the display label of its
///  field, the nearest label on its left or above it, its text hint; its
///  description the hint. An application teaches the skills a control of its
///  own with <see cref="RegisterHelpChatVclFieldAdapter" />, and corrects what
///  they see with the events of <see cref="HelpChatVclSkills" />.
/// </summary>
unit Vcl.HelpChatAI.Skills;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Data.DB,
  HelpChatAI.Actions, HelpChatAI.Skills, HelpChatAI.Skills.Screen;

type
  THelpChatVclField = class;

  /// <summary>
  ///  What a kind of control is to the skills: whether it is a field, how it
  ///  is described, how its value is read and written. Class methods only;
  ///  the built-in ones cover the controls of the VCL, an application
  ///  registers one for a control of its own (a third-party edit, say) with
  ///  <see cref="RegisterHelpChatVclFieldAdapter" />. The adapters registered
  ///  last are asked first. A field whose adapter sets <c>Field</c> is read
  ///  and written through it, by the library.
  /// </summary>
  THelpChatVclFieldAdapter = class abstract
  public
    /// <summary>True when the control is a field of this kind.</summary>
    class function Accepts(const AControl: TControl): Boolean; virtual; abstract;
    /// <summary>Fills <c>Kind</c>, the choices, the flags, and
    /// <c>OwnCaption</c> when the control carries its caption (a check box).
    /// The caption, the hint and the value are found by the skills.</summary>
    class procedure Describe(const AField: THelpChatVclField); virtual; abstract;
    /// <summary>The value of a plain control as text (dates ISO, numbers with
    /// a point), empty when the field is.</summary>
    class function ReadValue(const AField: THelpChatVclField): string; virtual;
    /// <summary>Writes the value of a plain control; empty when done, else
    /// why not, in one sentence for the model. <c>AShown</c> is what was
    /// written. An empty text clears the field.</summary>
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; virtual;
  end;

  THelpChatVclFieldAdapterClass = class of THelpChatVclFieldAdapter;

  /// <summary>One field of the form, with the control behind it.</summary>
  THelpChatVclField = class(THelpChatDataField)
  public
    /// <summary>The control of the field.</summary>
    Control: TControl;
    /// <summary>The radio buttons of a group, which are one field.</summary>
    Controls: TArray<TControl>;
    /// <summary>The adapter that accepted the control: what reads and writes
    /// it.</summary>
    Adapter: THelpChatVclFieldAdapterClass;
    /// <summary>The caption the control carries itself.</summary>
    OwnCaption: string;
    /// <summary>The text hint of an edit: the last resort of a caption.</summary>
    Placeholder: string;
    /// <summary>Data-aware: the source of the control.</summary>
    DataSource: TDataSource;
    /// <summary>The LiveBindings link that binds the control, if any: the
    /// field is then read and written through its <c>TField</c>, and
    /// <c>Adapter</c> is nil.</summary>
    Link: TComponent;
    function ReadValue: string; override;
    function WriteValue(const AText: string; out AShown: string): string; override;
    procedure Focus; override;
  end;

  /// <summary>One button the skills may press.</summary>
  THelpChatVclCommand = class(THelpChatSkillCommand)
  public
    /// <summary>The control that is pressed.</summary>
    Control: TControl;
    /// <summary>For a button of a <c>TDBNavigator</c>: its
    /// <c>TNavigateBtn</c>, else -1.</summary>
    NavigatorButton: Integer;
  end;

  /// <summary>Which control the skills work on: <c>ATarget</c> arrives as
  /// the form the user is working on, and may be replaced (a frame, a panel,
  /// another form). Sender is the assistant.</summary>
  THelpChatVclTargetEvent = procedure(Sender: TObject; var ATarget: TWinControl) of object;
  /// <summary>Every field the skills found, before the model hears of it:
  /// correct what it says (a caption, Required, a description) or set
  /// <c>AAccept</c> False to hide it.</summary>
  THelpChatVclFieldEvent = procedure(Sender: TObject; const AField: THelpChatVclField;
    var AAccept: Boolean) of object;
  /// <summary>Every button the skills found: <c>AAccept</c> arrives False
  /// for one that looks like a save, True otherwise.</summary>
  THelpChatVclCommandEvent = procedure(Sender: TObject; const ACommand: THelpChatVclCommand;
    var AAccept: Boolean) of object;

  /// <summary>What an application may change about the VCL skills, for the
  /// whole process (<see cref="HelpChatVclSkills" />).</summary>
  THelpChatVclSkillOptions = class
  strict private
    FOnGetTarget: THelpChatVclTargetEvent;
    FOnDescribeField: THelpChatVclFieldEvent;
    FOnCommand: THelpChatVclCommandEvent;
    function GetHideFieldValues: Boolean;
    procedure SetHideFieldValues(const Value: Boolean);
  public
    /// <summary>The model is told whether a field is filled, never its
    /// value (<c>HelpChatSkillsHideFieldValues</c>, the same for every
    /// framework). A password is never read anyway.</summary>
    property HideFieldValues: Boolean read GetHideFieldValues write SetHideFieldValues;
    /// <summary>Which control the skills work on, when it is not the form
    /// the user is on.</summary>
    property OnGetTarget: THelpChatVclTargetEvent read FOnGetTarget write FOnGetTarget;
    /// <summary>Corrects or hides a field before the model hears of it.</summary>
    property OnDescribeField: THelpChatVclFieldEvent read FOnDescribeField write FOnDescribeField;
    /// <summary>Decides which buttons the assistant may press.</summary>
    property OnCommand: THelpChatVclCommandEvent read FOnCommand write FOnCommand;
  end;

/// <summary>The options of the VCL skills.</summary>
function HelpChatVclSkills: THelpChatVclSkillOptions;

/// <summary>Teaches the skills a kind of control. Asked before the ones
/// registered earlier and the built-in ones.</summary>
procedure RegisterHelpChatVclFieldAdapter(const AAdapter: THelpChatVclFieldAdapterClass);
/// <summary>Takes an adapter of the application away again.</summary>
procedure UnregisterHelpChatVclFieldAdapter(const AAdapter: THelpChatVclFieldAdapterClass);

/// <summary>The form the user is working on: the active form, unless it is
/// the window of the chat or a dialog of the library, else the visible form
/// that was active last; the active child of an MDI form. nil when none.</summary>
function HelpChatVclWorkingForm: TCustomForm;
/// <summary>Whether a form is one the user may be working on: visible, and
/// neither the window of a chat nor a dialog of the library.</summary>
function HelpChatVclIsWorkingForm(const AForm: TCustomForm): Boolean;
/// <summary>What the skills of that assistant work on:
/// <see cref="HelpChatVclWorkingForm" />, as <c>OnGetTarget</c> may change it.</summary>
function HelpChatVclTarget(const AHost: TComponent): TWinControl;

{ What the actions do, on any control: the skills do the same through the
  screen, and so may an application that writes actions of its own or a
  test. ASender is what the events receive as Sender. }

/// <summary>The fields of a control, in tab order. The caller frees the list.</summary>
function HelpChatVclCollectFields(const ARoot: TWinControl;
  const ASender: TObject = nil): TObjectList<THelpChatVclField>;
/// <summary><c>describe_form</c>: the fields with their kind, state and -
/// unless <c>AHideValues</c> - value, and the state of their data sets.</summary>
function HelpChatVclDescribeForm(const ARoot: TWinControl; const AHideValues: Boolean;
  const ASender: TObject = nil): string;
/// <summary><c>fill_form</c>: writes the values of a JSON object into the
/// fields it names, putting the data set in edit or insert as <c>AMode</c>
/// says. Never posts. <c>ASnapshot</c> receives what the fields held before,
/// for <c>cancel_edit</c>. Raises when nothing can be written.</summary>
function HelpChatVclFillForm(const ARoot: TWinControl; const AValues: TJSONObject;
  const AMode: THelpChatFillMode; const AHideValues: Boolean;
  const ASnapshot: TDictionary<string, string> = nil; const ASender: TObject = nil): string;
/// <summary><c>cancel_edit</c>: cancels the data sets being edited and puts
/// back what <c>ASnapshot</c> remembers of the plain controls.</summary>
function HelpChatVclCancelEdit(const ARoot: TWinControl;
  const ASnapshot: TDictionary<string, string> = nil; const ASender: TObject = nil): string;
/// <summary><c>find_choice</c>: the values of a choice or lookup field that
/// match <c>AText</c>, for a list too long to be described whole.</summary>
function HelpChatVclFindChoice(const ARoot: TWinControl; const AFieldId, AText: string;
  const ASender: TObject = nil): string;
/// <summary><c>list_commands</c>: the buttons the assistant may press,
/// the saves left out.</summary>
function HelpChatVclListCommands(const ARoot: TWinControl; const ASender: TObject = nil): string;
/// <summary><c>press_command</c>: clicks the button of that id or caption;
/// with <c>AQueued</c> after the action answered, so that a modal window it
/// opens does not keep the model waiting.</summary>
function HelpChatVclPressCommand(const ARoot: TWinControl; const ACommand: string;
  const AQueued: Boolean; const ASender: TObject = nil): string;
/// <summary><c>count_records</c>: how many records a list holds, and its
/// filter; every list when <c>AList</c> is empty.</summary>
function HelpChatVclCountRecords(const ARoot: TWinControl; const AList: string): string;
/// <summary><c>find_record</c>: moves a list to the first record matching
/// <c>AText</c> and answers with it. Refused while the list, or a detail of
/// it, is being edited: moving would save.</summary>
function HelpChatVclFindRecord(const ARoot: TWinControl; const AText, AField, AList: string;
  const AHideValues: Boolean): string;
/// <summary><c>list_pages</c>: the pages of the form and which is shown.</summary>
function HelpChatVclPagesText(const ARoot: TWinControl): string;
/// <summary><c>show_page</c>: shows the page of that name or caption, as a
/// click on its tab would.</summary>
function HelpChatVclShowPage(const ARoot: TWinControl; const APage: string): string;

implementation

uses
  System.StrUtils, System.Math, System.TypInfo, System.Rtti, System.UITypes,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ActnList, Vcl.Menus,
  Vcl.DBCtrls, Vcl.DBGrids,
  Vcl.HelpChatAI, Vcl.HelpChatAI.Panel, Vcl.HelpChatAI.Bubble, Vcl.HelpChatAI.ConfirmDialog;

type
  // Protected members the skills need (the usual class cracker).
  TControlAccess = class(TControl);
  TCustomLabelAccess = class(TCustomLabel);
  TCustomEditAccess = class(TCustomEdit);
  TCustomComboBoxAccess = class(TCustomComboBox);
  TCustomCheckBoxAccess = class(TCustomCheckBox);
  TCustomRadioGroupAccess = class(TCustomRadioGroup);
  TDateTimePickerAccess = class(TDateTimePicker);
  TCustomButtonAccess = class(TCustomButton);
  TPageControlAccess = class(TPageControl);
  TCustomDBGridAccess = class(TCustomDBGrid);

  TVclScreen = class(THelpChatScreen)
  strict private
    FRoot: TWinControl;
  public
    constructor Create(const ARoot: TWinControl; const ASender: TObject);
    function Title: string; override;
    function TypeName: string; override;
    function Identity: string; override;
    function Fields: THelpChatDataFieldList; override;
    function Lists: TArray<THelpChatDataList>; override;
    function Pages: TArray<THelpChatSkillPage>; override;
    function ActivatePage(const APage: THelpChatSkillPage): string; override;
    function Commands: THelpChatSkillCommandList; override;
    procedure Press(const ACommandId: string; const AQueued: Boolean); override;
  end;

  TVclScreenProvider = class(THelpChatScreenProvider)
  public
    class function Supports(const AHost: TComponent): Boolean; override;
    class function CreateScreen(const AHost: TComponent): THelpChatScreen; override;
  end;

const
  MSG_NO_FORM = 'No form is active: the user is not working on any screen of the application.';

var
  GOptions: THelpChatVclSkillOptions;
  GAdapters: TList<THelpChatVclFieldAdapterClass>;

{ helpers }

function HelpChatVclSkills: THelpChatVclSkillOptions;
begin
  Result := GOptions;
end;

function THelpChatVclSkillOptions.GetHideFieldValues: Boolean;
begin
  Result := HelpChatSkillsHideFieldValues;
end;

procedure THelpChatVclSkillOptions.SetHideFieldValues(const Value: Boolean);
begin
  HelpChatSkillsHideFieldValues := Value;
end;

procedure RegisterHelpChatVclFieldAdapter(const AAdapter: THelpChatVclFieldAdapterClass);
begin
  if Assigned(AAdapter) and not GAdapters.Contains(AAdapter) then
    GAdapters.Add(AAdapter);
end;

procedure UnregisterHelpChatVclFieldAdapter(const AAdapter: THelpChatVclFieldAdapterClass);
begin
  if Assigned(GAdapters) then
    GAdapters.Remove(AAdapter);
end;

function FindAdapter(const AControl: TControl): THelpChatVclFieldAdapterClass;
var
  I: Integer;
begin
  for I := GAdapters.Count - 1 downto 0 do
    if GAdapters[I].Accepts(AControl) then
      Exit(GAdapters[I]);
  Result := nil;
end;

function ControlCaption(const AControl: TControl): string;
begin
  Result := TControlAccess(AControl).Caption;
end;

function RootCaption(const ARoot: TWinControl): string;
begin
  Result := HelpChatCleanCaption(ControlCaption(ARoot));
  if Result = '' then
    Result := ARoot.Name;
end;

function IsInsideChat(const AControl: TControl): Boolean;
var
  LControl: TControl;
begin
  LControl := AControl;
  while Assigned(LControl) do
  begin
    if (LControl is TVclHelpChatAIPanel) or (LControl is TVclHelpChatAIBubble) then
      Exit(True);
    LControl := LControl.Parent;
  end;
  Result := False;
end;

// The control and every parent up to the root are enabled: a disabled panel
// disables what it holds without saying so.
function IsEnabledChain(const AControl: TControl; const ARoot: TWinControl): Boolean;
var
  LControl: TControl;
begin
  LControl := AControl;
  while Assigned(LControl) and (LControl <> ARoot) do
  begin
    if not LControl.Enabled then
      Exit(False);
    LControl := LControl.Parent;
  end;
  Result := True;
end;

// Shown on the screen: the control and every parent are visible. Not
// Showing, which the VCL does not take back from the children of a parent
// that is hidden - the controls of a tab that is no longer the active one
// stay Showing.
function IsShown(const AControl: TControl): Boolean;
var
  LControl: TControl;
begin
  LControl := AControl;
  while Assigned(LControl) do
  begin
    if not LControl.Visible then
      Exit(False);
    if LControl.Parent = nil then
      Exit((LControl is TWinControl) and TWinControl(LControl).Showing);
    LControl := LControl.Parent;
  end;
  Result := False;
end;

function HasProp(const AObject: TObject; const AName: string; const AKinds: TTypeKinds): Boolean;
var
  LInfo: PPropInfo;
begin
  LInfo := GetPropInfo(AObject, AName);
  Result := Assigned(LInfo) and (LInfo^.PropType^^.Kind in AKinds);
end;

function PropBool(const AObject: TObject; const AName: string): Boolean;
begin
  Result := HasProp(AObject, AName, [tkEnumeration]) and (GetOrdProp(AObject, AName) <> 0);
end;

function PropStr(const AObject: TObject; const AName: string): string;
begin
  if HasProp(AObject, AName, [tkString, tkLString, tkWString, tkUString]) then
    Result := GetStrProp(AObject, AName)
  else
    Result := '';
end;

function InheritsFromName(const AObject: TObject; const AClassName: string): Boolean;
var
  LClass: TClass;
begin
  Result := False;
  if AObject = nil then
    Exit;
  LClass := AObject.ClassType;
  while Assigned(LClass) do
  begin
    if SameText(LClass.ClassName, AClassName) then
      Exit(True);
    LClass := LClass.ClassParent;
  end;
end;

// The form (or the frame) that owns the controls under ARoot, and so the
// links that bind them.
function BindingsOwner(const ARoot: TWinControl): TComponent;
begin
  Result := ARoot;
  if not (ARoot is TCustomForm) and Assigned(ARoot.Owner) then
    Result := ARoot.Owner;
end;

function PropObj(const AObject: TObject; const AName: string): TObject;
begin
  if HasProp(AObject, AName, [tkClass]) then
    Result := GetObjectProp(AObject, AName)
  else
    Result := nil;
end;

function CleanItems(const AItems: TStrings): TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, AItems.Count);
  for I := 0 to AItems.Count - 1 do
    Result[I] := HelpChatCleanCaption(AItems[I]);
end;

function RawItems(const AItems: TStrings): TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, AItems.Count);
  for I := 0 to AItems.Count - 1 do
    Result[I] := AItems[I];
end;

function FirstToken(const AValue: string): string;
var
  LPos: Integer;
begin
  LPos := Pos(';', AValue);
  if LPos > 0 then
    Result := Copy(AValue, 1, LPos - 1)
  else
    Result := AValue;
end;

function ChoiceIndex(const AChoices: TArray<string>; const AText: string): Integer;
var
  LIndex: Integer;
begin
  Result := HelpChatMatchChoice(AChoices, AText);
  if (Result < 0) and TryStrToInt(Trim(AText), LIndex) and (LIndex >= 0) and
    (LIndex <= High(AChoices)) then
    Result := LIndex;
end;

function NotAllowed(const AField: THelpChatVclField; const AText: string): string;
begin
  Result := Format('"%s" is not allowed: %s', [AText, AField.TypeText]);
end;

{ THelpChatVclFieldAdapter }

class function THelpChatVclFieldAdapter.ReadValue(const AField: THelpChatVclField): string;
begin
  Result := AField.ReadDataValue;
end;

class function THelpChatVclFieldAdapter.WriteValue(const AField: THelpChatVclField;
  const AText: string; out AShown: string): string;
begin
  Result := AField.WriteDataValue(AText, AShown);
end;

{ THelpChatVclField }

function THelpChatVclField.ReadValue: string;
begin
  if Assigned(Field) then
    Result := ReadDataValue
  else
    Result := Adapter.ReadValue(Self);
end;

function THelpChatVclField.WriteValue(const AText: string; out AShown: string): string;
begin
  if Assigned(Field) then
    Result := WriteDataValue(AText, AShown)
  else
    Result := Adapter.WriteValue(Self, AText, AShown);
end;

procedure THelpChatVclField.Focus;
var
  LForm: TCustomForm;
begin
  // The active control of the form, which it gets back when the user
  // returns to it: the chat in its own window keeps the focus. A chat that
  // is a control of this same form does lose it.
  if (Control is TWinControl) and TWinControl(Control).CanFocus then
  begin
    LForm := GetParentForm(Control);
    if Assigned(LForm) then
      LForm.ActiveControl := TWinControl(Control);
  end;
end;

type
  /// Any control with a published DataSource and DataField.
  TDataAwareAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
  end;

  TEditAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
    class function ReadValue(const AField: THelpChatVclField): string; override;
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; override;
  end;

  TComboAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
    class function ReadValue(const AField: THelpChatVclField): string; override;
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; override;
  end;

  TCheckAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
    class function ReadValue(const AField: THelpChatVclField): string; override;
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; override;
  end;

  TRadioGroupAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
    class function ReadValue(const AField: THelpChatVclField): string; override;
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; override;
  end;

  TRadioButtonAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
    class function ReadValue(const AField: THelpChatVclField): string; override;
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; override;
  end;

  TDatePickerAdapter = class(THelpChatVclFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatVclField); override;
    class function ReadValue(const AField: THelpChatVclField): string; override;
    class function WriteValue(const AField: THelpChatVclField; const AText: string;
      out AShown: string): string; override;
  end;

{ TDataAwareAdapter }

class function TDataAwareAdapter.Accepts(const AControl: TControl): Boolean;
var
  LSource: TObject;
  LDataField: string;
begin
  LSource := PropObj(AControl, 'DataSource');
  LDataField := PropStr(AControl, 'DataField');
  Result := (LSource is TDataSource) and (LDataField <> '') and
    Assigned(TDataSource(LSource).DataSet) and
    Assigned(TDataSource(LSource).DataSet.FindField(LDataField));
end;

class procedure TDataAwareAdapter.Describe(const AField: THelpChatVclField);
var
  LControl: TControl;
  LListSource, LItems: TObject;
  LListField: string;
  LCheck: TDBCheckBox;
begin
  LControl := AField.Control;
  // A TDBEdit that hides what is typed: this adapter is asked before the
  // plain edit one, which is where a password was recognised - so a
  // data-aware one was read to the model in clear.
  if LControl is TCustomEdit then
    AField.Secret := TCustomEditAccess(LControl).PasswordChar <> #0;
  AField.DataSource := TDataSource(PropObj(LControl, 'DataSource'));
  AField.AutoEdit := AField.DataSource.AutoEdit;
  HelpChatDescribeDataField(AField,
    AField.DataSource.DataSet.FindField(PropStr(LControl, 'DataField')));
  if AField.Field.FieldKind <> fkLookup then
  begin
    // A lookup control on a plain field (TDBLookupComboBox, and the many
    // third-party ones with the same properties).
    LListSource := PropObj(LControl, 'ListSource');
    LListField := FirstToken(PropStr(LControl, 'ListField'));
    if (LListSource is TDataSource) and Assigned(TDataSource(LListSource).DataSet) and
      (PropStr(LControl, 'KeyField') <> '') and (LListField <> '') then
    begin
      AField.Kind := hfkLookup;
      AField.LookupDataSet := TDataSource(LListSource).DataSet;
      AField.LookupKeyField := PropStr(LControl, 'KeyField');
      AField.LookupListField := LListField;
    end;
  end;
  if AField.Kind = hfkLookup then
  begin
    AField.LookupOf := AField.LookupDataSet.Name;
    HelpChatFillLookupChoices(AField);
  end
  else if LControl is TDBCheckBox then
  begin
    LCheck := TDBCheckBox(LControl);
    AField.Kind := hfkBoolean;
    AField.OwnCaption := ControlCaption(LControl);
    if not (AField.Field is TBooleanField) then
    begin
      AField.CheckedValue := LCheck.ValueChecked;
      AField.UncheckedValue := LCheck.ValueUnchecked;
    end;
  end
  else if LControl is TDBRadioGroup then
  begin
    AField.Kind := hfkChoice;
    AField.Choices := CleanItems(TDBRadioGroup(LControl).Items);
    if TDBRadioGroup(LControl).Values.Count > 0 then
      AField.ChoiceValues := RawItems(TDBRadioGroup(LControl).Values)
    else
      AField.ChoiceValues := RawItems(TDBRadioGroup(LControl).Items);
    AField.ChoicesOnly := True;
    AField.OwnCaption := ControlCaption(LControl);
  end
  else
  begin
    LItems := PropObj(LControl, 'Items');
    if (LItems is TStrings) and (TStrings(LItems).Count > 0) and
      (AField.Kind in [hfkText, hfkInteger, hfkNumber]) then
    begin
      AField.Kind := hfkChoice;
      AField.Choices := CleanItems(TStrings(LItems));
      AField.ChoiceValues := RawItems(TStrings(LItems));
      AField.ChoicesOnly := (LControl is TDBComboBox) and
        (TDBComboBox(LControl).Style in [csDropDownList, csOwnerDrawFixed, csOwnerDrawVariable]);
    end;
  end;
  AField.ReadOnly := AField.ReadOnly or PropBool(LControl, 'ReadOnly');
end;

{ TEditAdapter }

class function TEditAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomEdit;
end;

class procedure TEditAdapter.Describe(const AField: THelpChatVclField);
var
  LEdit: TCustomEditAccess;
begin
  LEdit := TCustomEditAccess(AField.Control);
  // TSpinEdit, TNumberBox and their kind: a published Value says the number.
  if HasProp(LEdit, 'Value', [tkInteger, tkInt64]) then
    AField.Kind := hfkInteger
  else if HasProp(LEdit, 'Value', [tkFloat]) then
    AField.Kind := hfkNumber
  else if AField.Control is TCustomMemo then
    AField.Kind := hfkMemo
  else
    AField.Kind := hfkText;
  AField.MaxLength := LEdit.MaxLength;
  AField.ReadOnly := LEdit.ReadOnly;
  AField.Secret := LEdit.PasswordChar <> #0;
  AField.Placeholder := LEdit.TextHint;
end;

class function TEditAdapter.ReadValue(const AField: THelpChatVclField): string;
var
  LEdit: TCustomEditAccess;
begin
  LEdit := TCustomEditAccess(AField.Control);
  if Trim(LEdit.Text) = '' then
    Exit('');
  case AField.Kind of
    hfkInteger:
      if HasProp(LEdit, 'Value', [tkInt64]) then
        Result := IntToStr(GetInt64Prop(LEdit, 'Value'))
      else
        Result := IntToStr(GetOrdProp(LEdit, 'Value'));
    hfkNumber:
      Result := HelpChatFormatNumber(GetFloatProp(LEdit, 'Value'));
  else
    Result := LEdit.Text;
  end;
end;

class function TEditAdapter.WriteValue(const AField: THelpChatVclField; const AText: string;
  out AShown: string): string;
var
  LEdit: TCustomEditAccess;
  LText: string;
  LInteger: Int64;
  LNumber: Double;
begin
  Result := '';
  LEdit := TCustomEditAccess(AField.Control);
  LText := Trim(AText);
  AShown := LText;
  if LText = '' then
  begin
    LEdit.Text := '';
    AShown := '(empty)';
    Exit;
  end;
  case AField.Kind of
    hfkInteger:
      begin
        if not TryStrToInt64(LText, LInteger) then
          Exit(Format('"%s" is not an integer number', [LText]));
        if HasProp(LEdit, 'Value', [tkInt64]) then
          SetInt64Prop(LEdit, 'Value', LInteger)
        else
          SetOrdProp(LEdit, 'Value', LInteger);
      end;
    hfkNumber:
      begin
        if not HelpChatParseNumber(LText, LNumber) then
          Exit(Format('"%s" is not a number', [LText]));
        SetFloatProp(LEdit, 'Value', LNumber);
      end;
    hfkMemo:
      begin
        LEdit.Text := AText;
        AShown := AText;
      end;
  else
    if (AField.MaxLength > 0) and (LText.Length > AField.MaxLength) then
      Exit(Format('too long: %d characters, the maximum is %d', [LText.Length, AField.MaxLength]));
    LEdit.Text := LText;
  end;
end;

{ TComboAdapter }

class function TComboAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomComboBox;
end;

class procedure TComboAdapter.Describe(const AField: THelpChatVclField);
var
  LCombo: TCustomComboBoxAccess;
begin
  LCombo := TCustomComboBoxAccess(AField.Control);
  AField.Choices := CleanItems(LCombo.Items);
  AField.ChoicesOnly := not (LCombo.Style in [csDropDown, csSimple]);
  if (Length(AField.Choices) = 0) and not AField.ChoicesOnly then
    AField.Kind := hfkText
  else
    AField.Kind := hfkChoice;
end;

class function TComboAdapter.ReadValue(const AField: THelpChatVclField): string;
var
  LCombo: TCustomComboBoxAccess;
begin
  LCombo := TCustomComboBoxAccess(AField.Control);
  if AField.ChoicesOnly then
  begin
    if (LCombo.ItemIndex >= 0) and (LCombo.ItemIndex <= High(AField.Choices)) then
      Result := AField.Choices[LCombo.ItemIndex]
    else
      Result := '';
  end
  else
    Result := LCombo.Text;
end;

class function TComboAdapter.WriteValue(const AField: THelpChatVclField; const AText: string;
  out AShown: string): string;
var
  LCombo: TCustomComboBoxAccess;
  LIndex: Integer;
begin
  Result := '';
  LCombo := TCustomComboBoxAccess(AField.Control);
  AShown := Trim(AText);
  if AShown = '' then
  begin
    LCombo.ItemIndex := -1;
    if not AField.ChoicesOnly then
      LCombo.Text := '';
    AShown := '(empty)';
  end
  else
  begin
    LIndex := HelpChatMatchChoice(AField.Choices, AText);
    if LIndex >= 0 then
    begin
      LCombo.ItemIndex := LIndex;
      AShown := AField.Choices[LIndex];
    end
    else if AField.ChoicesOnly then
      Exit(NotAllowed(AField, AText))
    else
      LCombo.Text := AShown;
  end;
  // Setting the index from code fires nothing: the form must hear of it as
  // it does when the user picks an item.
  LCombo.Select;
end;

{ TCheckAdapter }

class function TCheckAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomCheckBox;
end;

class procedure TCheckAdapter.Describe(const AField: THelpChatVclField);
begin
  AField.Kind := hfkBoolean;
  AField.OwnCaption := ControlCaption(AField.Control);
end;

class function TCheckAdapter.ReadValue(const AField: THelpChatVclField): string;
begin
  Result := IfThen(TCustomCheckBoxAccess(AField.Control).Checked, 'true', 'false');
end;

class function TCheckAdapter.WriteValue(const AField: THelpChatVclField; const AText: string;
  out AShown: string): string;
var
  LValue: Boolean;
begin
  Result := '';
  if Trim(AText) = '' then
    LValue := False
  else if not HelpChatParseBoolean(AText, LValue) then
    Exit(Format('"%s" is not yes/no', [AText]));
  TCustomCheckBoxAccess(AField.Control).Checked := LValue; // fires OnClick
  AShown := IfThen(LValue, 'true', 'false');
end;

{ TRadioGroupAdapter }

class function TRadioGroupAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomRadioGroup;
end;

class procedure TRadioGroupAdapter.Describe(const AField: THelpChatVclField);
begin
  AField.Kind := hfkChoice;
  AField.ChoicesOnly := True;
  AField.Choices := CleanItems(TCustomRadioGroupAccess(AField.Control).Items);
  AField.OwnCaption := ControlCaption(AField.Control);
end;

class function TRadioGroupAdapter.ReadValue(const AField: THelpChatVclField): string;
var
  LIndex: Integer;
begin
  LIndex := TCustomRadioGroupAccess(AField.Control).ItemIndex;
  if (LIndex >= 0) and (LIndex <= High(AField.Choices)) then
    Result := AField.Choices[LIndex]
  else
    Result := '';
end;

class function TRadioGroupAdapter.WriteValue(const AField: THelpChatVclField;
  const AText: string; out AShown: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  if Trim(AText) = '' then
  begin
    TCustomRadioGroupAccess(AField.Control).ItemIndex := -1;
    AShown := '(empty)';
    Exit;
  end;
  LIndex := ChoiceIndex(AField.Choices, AText);
  if LIndex < 0 then
    Exit(NotAllowed(AField, AText));
  TCustomRadioGroupAccess(AField.Control).ItemIndex := LIndex; // fires OnClick
  AShown := AField.Choices[LIndex];
end;

{ TRadioButtonAdapter: the radio buttons of one parent are one field }

class function TRadioButtonAdapter.Accepts(const AControl: TControl): Boolean;
begin
  // Not the buttons a TRadioGroup creates for its items: the group is the field.
  Result := (AControl is TRadioButton) and not (AControl.Parent is TCustomRadioGroup);
end;

class procedure TRadioButtonAdapter.Describe(const AField: THelpChatVclField);
var
  LParent: TWinControl;
  I: Integer;
begin
  LParent := AField.Control.Parent;
  AField.Kind := hfkChoice;
  AField.ChoicesOnly := True;
  AField.Controls := nil;
  AField.Choices := nil;
  for I := 0 to LParent.ControlCount - 1 do
    if (LParent.Controls[I] is TRadioButton) and LParent.Controls[I].Visible and
      LParent.Controls[I].Enabled then
    begin
      AField.Controls := AField.Controls + [LParent.Controls[I]];
      AField.Choices := AField.Choices + [HelpChatCleanCaption(ControlCaption(LParent.Controls[I]))];
    end;
  // A group box names the group, and gives it its id.
  if LParent is TCustomGroupBox then
  begin
    AField.OwnCaption := ControlCaption(LParent);
    if LParent.Name <> '' then
      AField.Id := LParent.Name;
  end;
end;

class function TRadioButtonAdapter.ReadValue(const AField: THelpChatVclField): string;
var
  I: Integer;
begin
  for I := 0 to High(AField.Controls) do
    if TRadioButton(AField.Controls[I]).Checked then
      Exit(AField.Choices[I]);
  Result := '';
end;

class function TRadioButtonAdapter.WriteValue(const AField: THelpChatVclField;
  const AText: string; out AShown: string): string;
var
  LIndex, I: Integer;
begin
  Result := '';
  if Trim(AText) = '' then
  begin
    for I := 0 to High(AField.Controls) do
      TRadioButton(AField.Controls[I]).Checked := False;
    AShown := '(empty)';
    Exit;
  end;
  LIndex := ChoiceIndex(AField.Choices, AText);
  if LIndex < 0 then
    Exit(NotAllowed(AField, AText));
  TRadioButton(AField.Controls[LIndex]).Checked := True;
  AShown := AField.Choices[LIndex];
end;

{ TDatePickerAdapter }

class function TDatePickerAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TDateTimePicker;
end;

class procedure TDatePickerAdapter.Describe(const AField: THelpChatVclField);
begin
  if TDateTimePicker(AField.Control).Kind = dtkTime then
    AField.Kind := hfkTime
  else
    AField.Kind := hfkDate;
end;

class function TDatePickerAdapter.ReadValue(const AField: THelpChatVclField): string;
var
  LPicker: TDateTimePicker;
begin
  LPicker := TDateTimePicker(AField.Control);
  if LPicker.ShowCheckbox and not LPicker.Checked then
    Result := ''
  else
    Result := HelpChatFormatDateTime(LPicker.DateTime, AField.Kind);
end;

class function TDatePickerAdapter.WriteValue(const AField: THelpChatVclField;
  const AText: string; out AShown: string): string;
var
  LPicker: TDateTimePicker;
  LValue: TDateTime;
begin
  Result := '';
  LPicker := TDateTimePicker(AField.Control);
  if Trim(AText) = '' then
  begin
    if not LPicker.ShowCheckbox then
      Exit('this date cannot be left empty');
    LPicker.Checked := False;
    AShown := '(empty)';
  end
  else
  begin
    if not HelpChatParseDateTime(AText, AField.Kind, LValue) then
      Exit(Format('"%s" is not a valid date/time (use YYYY-MM-DD, HH:MM)', [AText]));
    if LPicker.ShowCheckbox then
      LPicker.Checked := True;
    if AField.Kind = hfkTime then
      LPicker.Time := LValue
    else
      LPicker.Date := LValue;
    AShown := HelpChatFormatDateTime(LValue, AField.Kind);
  end;
  TDateTimePickerAccess(LPicker).Change; // as when the user picks a date
end;

{ the target }

function IsEligibleForm(const AForm: TCustomForm): Boolean;
begin
  Result := Assigned(AForm) and AForm.Visible and not (AForm is TVclHelpChatAIForm) and
    not (AForm is TVclHelpChatConfirmDialog);
end;

function HelpChatVclIsWorkingForm(const AForm: TCustomForm): Boolean;
begin
  Result := IsEligibleForm(AForm);
end;

function HelpChatVclWorkingForm: TCustomForm;
var
  I: Integer;
begin
  Result := Screen.ActiveCustomForm;
  if not IsEligibleForm(Result) then
  begin
    // The chat has the focus: the form the user was on is the one focused
    // last, and the VCL keeps that one first.
    Result := nil;
    for I := 0 to Screen.CustomFormCount - 1 do
      if IsEligibleForm(Screen.CustomForms[I]) then
        Exit(Screen.CustomForms[I]);
  end;
  if (Result is TForm) and (TForm(Result).FormStyle = fsMDIForm) and
    Assigned(TForm(Result).ActiveMDIChild) then
    Result := TForm(Result).ActiveMDIChild;
end;

function HelpChatVclTarget(const AHost: TComponent): TWinControl;
begin
  Result := HelpChatVclWorkingForm;
  if Assigned(GOptions.OnGetTarget) then
    GOptions.OnGetTarget(AHost, Result);
end;

{ fields }

procedure CollectLabels(const AParent: TWinControl; const AFocus: TDictionary<TWinControl, string>;
  const AFree: TList<TCustomLabel>);
var
  I: Integer;
  LControl: TControl;
  LFocus: TWinControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    LControl := AParent.Controls[I];
    if LControl is TCustomLabel then
    begin
      if not LControl.Visible then
        Continue;
      LFocus := TCustomLabelAccess(LControl).FocusControl;
      if Assigned(LFocus) then
      begin
        if not AFocus.ContainsKey(LFocus) then
          AFocus.Add(LFocus, ControlCaption(LControl));
      end
      else
        AFree.Add(TCustomLabel(LControl));
    end
    else if LControl is TWinControl then
      CollectLabels(TWinControl(LControl), AFocus, AFree);
  end;
end;

// The label without a FocusControl nearest to the control: on its left on
// the same row, else just above it.
function NearestLabel(const AControl: TControl; const AFree: TList<TCustomLabel>): string;
var
  LLabel, LLeft, LAbove: TCustomLabel;
  LDistance, LLeftDistance, LAboveDistance: Integer;
begin
  LLeft := nil;
  LAbove := nil;
  LLeftDistance := MaxInt;
  LAboveDistance := MaxInt;
  for LLabel in AFree do
  begin
    if LLabel.Parent <> AControl.Parent then
      Continue;
    if (LLabel.Left + LLabel.Width <= AControl.Left + 4) and
      (LLabel.Top < AControl.Top + AControl.Height) and
      (LLabel.Top + LLabel.Height > AControl.Top) then
    begin
      LDistance := AControl.Left - (LLabel.Left + LLabel.Width);
      if LDistance < LLeftDistance then
      begin
        LLeftDistance := LDistance;
        LLeft := LLabel;
      end;
    end
    else if (LLabel.Top + LLabel.Height <= AControl.Top + 2) and
      (LLabel.Left < AControl.Left + AControl.Width) and
      (LLabel.Left + LLabel.Width > AControl.Left) then
    begin
      LDistance := AControl.Top - (LLabel.Top + LLabel.Height);
      if (LDistance <= AControl.Height * 2 + 8) and (LDistance < LAboveDistance) then
      begin
        LAboveDistance := LDistance;
        LAbove := LLabel;
      end;
    end;
  end;
  if Assigned(LLeft) and (LLeftDistance < 240) then
    Result := ControlCaption(LLeft)
  else if Assigned(LAbove) then
    Result := ControlCaption(LAbove)
  else
    Result := '';
end;

// A control bound to a field by a link: the field, its source, its lookup
// (the same as FireMonkey), and what the control adds.
function DescribeBound(const AField: THelpChatVclField; const ALink: TComponent): Boolean;
var
  LControl: TControl;
  LItems: TObject;
begin
  Result := HelpChatDescribeBoundField(AField, ALink);
  if not Result then
    Exit;
  AField.Link := ALink;
  LControl := AField.Control;
  if LControl is TCustomEdit then
  begin
    AField.Secret := TCustomEditAccess(LControl).PasswordChar <> #0;
    AField.Placeholder := TCustomEditAccess(LControl).TextHint;
  end;
  if AField.Kind = hfkLookup then
    // described by the link
  else if LControl is TCustomCheckBox then
  begin
    AField.Kind := hfkBoolean;
    AField.OwnCaption := ControlCaption(LControl);
  end
  else
  begin
    LItems := PropObj(LControl, 'Items');
    if (LItems is TStrings) and (TStrings(LItems).Count > 0) and
      (AField.Kind in [hfkText, hfkInteger, hfkNumber]) then
    begin
      AField.Kind := hfkChoice;
      AField.Choices := CleanItems(TStrings(LItems));
      AField.ChoiceValues := RawItems(TStrings(LItems));
      AField.ChoicesOnly := (LControl is TCustomComboBox) and
        (TCustomComboBoxAccess(LControl).Style in [csDropDownList, csOwnerDrawFixed, csOwnerDrawVariable]);
    end;
  end;
  AField.ReadOnly := AField.ReadOnly or PropBool(LControl, 'ReadOnly');
end;

function HelpChatVclCollectFields(const ARoot: TWinControl;
  const ASender: TObject): TObjectList<THelpChatVclField>;
var
  LLinks: TDictionary<TComponent, TComponent>;
  LLink: TComponent;
  LBound: Boolean;
  LFocus: TDictionary<TWinControl, string>;
  LFree: TList<TCustomLabel>;
  LOrder: TList;
  LGroups: TList<TWinControl>;
  LIds: TStringList;
  LControl: TWinControl;
  LAdapter: THelpChatVclFieldAdapterClass;
  LField: THelpChatVclField;
  LCaption: string;
  LAccept: Boolean;
  I: Integer;
begin
  Result := TObjectList<THelpChatVclField>.Create(True);
  if ARoot = nil then
    Exit;
  LFocus := TDictionary<TWinControl, string>.Create;
  LFree := TList<TCustomLabel>.Create;
  LOrder := TList.Create;
  LGroups := TList<TWinControl>.Create;
  LIds := TStringList.Create;
  LLinks := TDictionary<TComponent, TComponent>.Create;
  try
    LIds.CaseSensitive := False;
    HelpChatScanBindings(BindingsOwner(ARoot), LLinks, nil);
    CollectLabels(ARoot, LFocus, LFree);
    // The tab order is the order of the form, the one the user fills it in.
    ARoot.GetTabOrderList(LOrder);
    for I := 0 to LOrder.Count - 1 do
    begin
      LControl := TWinControl(LOrder[I]);
      if not IsShown(LControl) or not IsEnabledChain(LControl, ARoot) or IsInsideChat(LControl) then
        Continue;
      // A control a link binds is read through its field, before any
      // adapter, as in FireMonkey.
      LBound := LLinks.TryGetValue(LControl, LLink);
      LAdapter := nil;
      if not LBound then
      begin
        LAdapter := FindAdapter(LControl);
        if LAdapter = nil then
          Continue;
        if LAdapter = TRadioButtonAdapter then
        begin
          if LGroups.Contains(LControl.Parent) then
            Continue;
          LGroups.Add(LControl.Parent);
        end;
      end;
      LField := THelpChatVclField.Create;
      try
        LField.Control := LControl;
        LField.Adapter := LAdapter;
        LField.Id := LControl.Name;
        LField.Hint := Trim(GetLongHint(LControl.Hint));
        if LBound then
        begin
          if not DescribeBound(LField, LLink) then
            Continue; // a link to nothing: nothing to fill
        end
        else
          LAdapter.Describe(LField);
        if LField.Id = '' then
          LField.Id := Format('field%d', [Result.Count + 1]);
        if LIds.IndexOf(LField.Id) >= 0 then
          LField.Id := Format('%s_%d', [LField.Id, Result.Count + 1]);
        // The words of the screen first: the label that points to the control.
        if not LFocus.TryGetValue(LControl, LCaption) then
          LCaption := LField.OwnCaption;
        if (HelpChatCleanCaption(LCaption) = '') and Assigned(LField.Field) then
          LCaption := LField.Field.DisplayLabel;
        if HelpChatCleanCaption(LCaption) = '' then
          LCaption := NearestLabel(LControl, LFree);
        if HelpChatCleanCaption(LCaption) = '' then
          LCaption := LField.Placeholder;
        if HelpChatCaptionMarksRequired(LCaption) then
          LField.Required := True;
        LField.Caption := HelpChatCleanCaption(LCaption);
        if LField.Caption = '' then
          LField.Caption := LField.Id;
        if SameText(LField.Hint, LField.Caption) then
          LField.Hint := '';
        LField.Value := LField.ReadValue;
        LAccept := True;
        if Assigned(GOptions.OnDescribeField) then
          GOptions.OnDescribeField(ASender, LField, LAccept);
        if LAccept then
        begin
          LIds.Add(LField.Id);
          Result.Add(LField);
          LField := nil;
        end;
      finally
        LField.Free;
      end;
    end;
  finally
    LLinks.Free;
    LIds.Free;
    LGroups.Free;
    LOrder.Free;
    LFree.Free;
    LFocus.Free;
  end;
end;

{ lists }

procedure CollectListControls(const AParent: TWinControl; var AList: TArray<THelpChatDataList>);
var
  I, J: Integer;
  LControl: TControl;
  LSource: TObject;
  LItem: THelpChatDataList;
  LKnown: Boolean;
  LGrid: TCustomDBGridAccess;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    LControl := AParent.Controls[I];
    if not IsShown(LControl) or IsInsideChat(LControl) then
      Continue;
    // A source without a field: a grid, a navigator, a control grid - a
    // TDataSource, or a bind source (a TBindNavigator).
    LSource := PropObj(LControl, 'DataSource');
    if Assigned(HelpChatSourceDataSet(LSource)) and
      not HasProp(LControl, 'DataField', [tkString, tkLString, tkWString, tkUString]) then
    begin
      LItem := Default(THelpChatDataList);
      LItem.DataSet := HelpChatSourceDataSet(LSource);
      LItem.Id := LControl.Name;
      if LItem.Id = '' then
        LItem.Id := HelpChatDataSetName(LItem.DataSet);
      LItem.Caption := HelpChatDataSetName(LItem.DataSet);
      // A grid is searched by its visible columns.
      if LControl is TCustomDBGrid then
      begin
        LGrid := TCustomDBGridAccess(LControl);
        for J := 0 to LGrid.Columns.Count - 1 do
          if LGrid.Columns[J].Visible and Assigned(LGrid.Columns[J].Field) then
            LItem.SearchFields := LItem.SearchFields + [LGrid.Columns[J].Field];
      end;
      LKnown := False;
      for J := 0 to High(AList) do
        if AList[J].DataSet = LItem.DataSet then
        begin
          // A grid says more than a navigator: it has the columns.
          if (Length(AList[J].SearchFields) = 0) and (Length(LItem.SearchFields) > 0) then
            AList[J] := LItem;
          LKnown := True;
        end;
      if not LKnown then
        AList := AList + [LItem];
    end;
    if LControl is TWinControl then
      CollectListControls(TWinControl(LControl), AList);
  end;
end;

// The grids and the lists a LiveBindings link fills with a data set, shown
// and outside the chat: a TStringGrid has no DataSource to tell it.
procedure CollectBoundLists(const ARoot: TWinControl; var AList: TArray<THelpChatDataList>);
var
  LLinks: TList<TComponent>;
  LLink: TComponent;
  LControl: TObject;
  LItem: THelpChatDataList;
  LKnown: Boolean;
  J: Integer;
begin
  LLinks := TList<TComponent>.Create;
  try
    HelpChatScanBindings(BindingsOwner(ARoot), nil, LLinks);
    for LLink in LLinks do
    begin
      LControl := HelpChatBindingListControl(LLink);
      if not (LControl is TControl) or not IsShown(TControl(LControl)) or
        IsInsideChat(TControl(LControl)) or
        not ((LControl = ARoot) or ARoot.ContainsControl(TControl(LControl))) then
        Continue;
      LItem := Default(THelpChatDataList);
      LItem.DataSet := HelpChatBindingListDataSet(LLink);
      if LItem.DataSet = nil then
        Continue;
      LItem.Id := TControl(LControl).Name;
      if LItem.Id = '' then
        LItem.Id := HelpChatDataSetName(LItem.DataSet);
      LItem.Caption := HelpChatDataSetName(LItem.DataSet);
      LKnown := False;
      for J := 0 to High(AList) do
        if AList[J].DataSet = LItem.DataSet then
        begin
          // A grid says more than a navigator: it is what the user reads.
          if InheritsFromName(TControl(LControl), 'TCustomGrid') then
            AList[J].Id := LItem.Id;
          LKnown := True;
        end;
      if not LKnown then
        AList := AList + [LItem];
    end;
  finally
    LLinks.Free;
  end;
end;

{ pages }

// Reachable: the tab is visible and so is everything above it - except that
// an outer page may be another tab, which show_page selects first.
function PageReachable(const ASheet: TTabSheet; const ARoot: TWinControl): Boolean;
var
  LControl: TControl;
begin
  if not ASheet.TabVisible or not ASheet.Enabled then
    Exit(False);
  LControl := ASheet.PageControl;
  while Assigned(LControl) and (LControl <> ARoot) do
  begin
    if LControl is TTabSheet then
    begin
      if not TTabSheet(LControl).TabVisible then
        Exit(False);
    end
    else if not LControl.Visible then
      Exit(False);
    LControl := LControl.Parent;
  end;
  Result := Assigned(LControl) and not IsInsideChat(ASheet);
end;

function PagePath(const ASheet: TTabSheet; const ARoot: TWinControl): string;
var
  LControl: TControl;
begin
  Result := HelpChatCleanCaption(ASheet.Caption);
  LControl := ASheet.PageControl.Parent;
  while Assigned(LControl) and (LControl <> ARoot) do
  begin
    if LControl is TTabSheet then
      Result := HelpChatCleanCaption(TTabSheet(LControl).Caption) + ' > ' + Result;
    LControl := LControl.Parent;
  end;
end;

procedure CollectSheets(const AParent: TWinControl; const ARoot: TWinControl;
  var APages: TArray<THelpChatSkillPage>);
var
  I: Integer;
  LPage: THelpChatSkillPage;
  LSheet: TTabSheet;
begin
  for I := 0 to AParent.ControlCount - 1 do
    if AParent.Controls[I] is TWinControl then
    begin
      if (AParent.Controls[I] is TTabSheet) and
        Assigned(TTabSheet(AParent.Controls[I]).PageControl) and
        PageReachable(TTabSheet(AParent.Controls[I]), ARoot) then
      begin
        LSheet := TTabSheet(AParent.Controls[I]);
        LPage := Default(THelpChatSkillPage);
        LPage.Control := LSheet;
        LPage.Name := LSheet.Name;
        LPage.Caption := HelpChatCleanCaption(LSheet.Caption);
        LPage.Path := PagePath(LSheet, ARoot);
        LPage.Shown := IsShown(LSheet);
        APages := APages + [LPage];
      end;
      CollectSheets(TWinControl(AParent.Controls[I]), ARoot, APages);
    end;
end;

{ commands }

function IsPostAction(const AAction: TBasicAction): Boolean;
var
  LClass: TClass;
begin
  LClass := nil;
  if Assigned(AAction) then
    LClass := AAction.ClassType;
  while Assigned(LClass) do
  begin
    if SameText(LClass.ClassName, 'TDataSetPost') then
      Exit(True);
    LClass := LClass.ClassParent;
  end;
  Result := False;
end;

procedure AddCommand(const AList: THelpChatSkillCommandList; const ACommand: THelpChatVclCommand;
  const ASender: TObject);
var
  LAccept: Boolean;
  LCommand: THelpChatSkillCommand;
  LBase: string;
  LCount: Integer;
begin
  LAccept := not ACommand.IsSave;
  if Assigned(GOptions.OnCommand) then
    GOptions.OnCommand(ASender, ACommand, LAccept);
  if not LAccept then
  begin
    ACommand.Free;
    Exit;
  end;
  // Unique ids: two buttons may have no name, or the same caption.
  LBase := ACommand.Id;
  LCount := 1;
  for LCommand in AList do
    if SameText(LCommand.Id, ACommand.Id) then
    begin
      Inc(LCount);
      ACommand.Id := Format('%s_%d', [LBase, LCount]);
    end;
  AList.Add(ACommand);
end;

// The TNavigateBtn of a button of a navigator. Its class moved from
// Vcl.DBCtrls to Vcl.Buttons, and its Index changed type, between the
// versions the library supports: the public property is read through RTTI,
// and the position among the buttons (created in the order of the
// enumeration) is the fallback.
function NavButtonIndex(const AButton: TControl; const APosition: Integer): Integer;
var
  LContext: TRttiContext;
  LProperty: TRttiProperty;
begin
  Result := APosition;
  LProperty := LContext.GetType(AButton.ClassType).GetProperty('Index');
  if Assigned(LProperty) and LProperty.IsReadable then
    try
      Result := LProperty.GetValue(AButton).AsOrdinal;
    except
      Result := APosition;
    end;
end;

// True when some data-aware control under ARoot shows a data set that is
// being edited - a TDataSource or a bind source of its own.
function AnyDataSetEditing(const ARoot: TWinControl): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ARoot.ControlCount - 1 do
  begin
    if HelpChatBindSourceEditing(PropObj(ARoot.Controls[I], 'DataSource')) then
      Exit(True);
    if (ARoot.Controls[I] is TWinControl) and AnyDataSetEditing(TWinControl(ARoot.Controls[I])) then
      Exit(True);
  end;
end;

// True when a source some link of the form binds a control to is being
// edited: the controls of LiveBindings have no DataSource of their own.
function AnyBindingEditing(const ARoot: TWinControl): Boolean;
var
  LLinks: TDictionary<TComponent, TComponent>;
  LLists: TList<TComponent>;
  LLink: TComponent;
begin
  Result := False;
  LLinks := TDictionary<TComponent, TComponent>.Create;
  LLists := TList<TComponent>.Create;
  try
    HelpChatScanBindings(BindingsOwner(ARoot), LLinks, LLists);
    for LLink in LLinks.Values do
      if HelpChatBindSourceEditing(PropObj(LLink, 'DataSource')) then
        Exit(True);
    for LLink in LLists do
      if HelpChatBindSourceEditing(PropObj(LLink, 'DataSource')) then
        Exit(True);
  finally
    LLists.Free;
    LLinks.Free;
  end;
end;

// A standard data set action that moves to another record, inserts one or
// reloads (TDataSetFirst, Prior, Next, Last, Insert, Refresh) while the data
// set it works on is being edited: pressing it posts the record, which is
// saving. The navigator buttons are left out for the same reason. An action
// with no DataSource of its own works on the data set of the focused
// control, which nobody can know now: any data set of the screen being
// edited is enough to leave it out.
function ActionMovesWhileEditing(const AAction: TBasicAction; const ARoot: TWinControl): Boolean;
const
  MOVING: array[0..5] of string = ('TDataSetFirst', 'TDataSetPrior', 'TDataSetNext',
    'TDataSetLast', 'TDataSetInsert', 'TDataSetRefresh');
var
  LClass: TClass;
  LName: string;
  LMoves: Boolean;
  LSource: TObject;
begin
  Result := False;
  if AAction = nil then
    Exit;
  LMoves := False;
  LClass := AAction.ClassType;
  while Assigned(LClass) and not LMoves do
  begin
    for LName in MOVING do
      if SameText(LClass.ClassName, LName) then
        LMoves := True;
    LClass := LClass.ClassParent;
  end;
  if not LMoves then
    Exit;
  LSource := PropObj(AAction, 'DataSource');
  if LSource is TDataSource then
    Result := HelpChatIsEditing(TDataSource(LSource).DataSet)
  else
    Result := AnyDataSetEditing(ARoot) or AnyBindingEditing(ARoot);
end;

procedure CollectCommandControls(const AParent: TWinControl; const ARoot: TWinControl;
  const AList: THelpChatSkillCommandList; const ASender: TObject);
var
  I, J: Integer;
  LControl, LButton: TControl;
  LCommand: THelpChatVclCommand;
  LNavigator: TDBNavigator;
  LIndex: Integer;
  LEditing: Boolean;
  LEnumName: string;
  LAction: TBasicAction;
  LIsPost, LMoves: Boolean;
  LBindSource: TObject;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    LControl := AParent.Controls[I];
    if not IsShown(LControl) or not IsEnabledChain(LControl, ARoot) or IsInsideChat(LControl) then
      Continue;
    if LControl is TDBNavigator then
    begin
      LNavigator := TDBNavigator(LControl);
      LEditing := Assigned(LNavigator.DataSource) and HelpChatIsEditing(LNavigator.DataSource.DataSet);
      for J := 0 to LNavigator.ControlCount - 1 do
        if (LNavigator.Controls[J] is TSpeedButton) and LNavigator.Controls[J].Visible and
          LNavigator.Controls[J].Enabled then
        begin
          LButton := LNavigator.Controls[J];
          LIndex := NavButtonIndex(LButton, J);
          if (LIndex < Ord(Low(TNavigateBtn))) or (LIndex > Ord(High(TNavigateBtn))) then
            Continue;
          // Moving or inserting while a record is edited posts it.
          if LEditing and (TNavigateBtn(LIndex) in [nbFirst, nbPrior, nbNext, nbLast, nbInsert, nbRefresh]) then
            Continue;
          LEnumName := GetEnumName(TypeInfo(TNavigateBtn), LIndex);
          LCommand := THelpChatVclCommand.Create;
          LCommand.Control := LNavigator;
          LCommand.NavigatorButton := LIndex;
          LCommand.Id := IfThen(LNavigator.Name <> '', LNavigator.Name, 'navigator') + '.' +
            LowerCase(Copy(LEnumName, 3, MaxInt));
          LCommand.Caption := HelpChatCleanCaption(GetShortHint(LButton.Hint));
          if LCommand.Caption = '' then
            LCommand.Caption := Copy(LEnumName, 3, MaxInt);
          LCommand.IsSave := SameText(LEnumName, 'nbPost') or SameText(LEnumName, 'nbApplyUpdates');
          AddCommand(AList, LCommand, ASender);
        end;
      Continue;
    end;
    // The navigator of the LiveBindings: its buttons are told by their index,
    // never by their hint, a localized text of the RTL. Pressed as a click.
    if InheritsFromName(LControl, 'TCustomBindNavigator') then
    begin
      LEditing := HelpChatBindSourceEditing(PropObj(LControl, 'DataSource'));
      for J := 0 to TWinControl(LControl).ControlCount - 1 do
      begin
        LButton := TWinControl(LControl).Controls[J];
        if not (LButton is TSpeedButton) or not LButton.Visible or not LButton.Enabled then
          Continue;
        if not HelpChatBindNavigateButton(LButton, LIndex, LIsPost, LMoves) then
          Continue;
        // Moving or inserting while a record is edited posts it.
        if LEditing and LMoves then
          Continue;
        // TNavigateButton has the order and the names of TNavigateBtn.
        LEnumName := GetEnumName(TypeInfo(TNavigateBtn), LIndex);
        LCommand := THelpChatVclCommand.Create;
        LCommand.Control := LButton;
        LCommand.NavigatorButton := -1;
        LCommand.Id := IfThen(LControl.Name <> '', LControl.Name, 'navigator') + '.' +
          LowerCase(Copy(LEnumName, 3, MaxInt));
        LCommand.Caption := HelpChatCleanCaption(GetShortHint(LButton.Hint));
        if LCommand.Caption = '' then
          LCommand.Caption := Copy(LEnumName, 3, MaxInt);
        LCommand.IsSave := LIsPost;
        AddCommand(AList, LCommand, ASender);
      end;
      Continue;
    end;
    if (LControl is TCustomButton) or (LControl is TSpeedButton) or
      ((LControl is TToolButton) and not (TToolButton(LControl).Style in [tbsSeparator, tbsDivider])) then
    begin
      LAction := TControlAccess(LControl).Action;
      // Moving or inserting while a record is edited posts it: not offered,
      // like the buttons of a navigator - the data set actions and the
      // bind navigator ones alike.
      if ActionMovesWhileEditing(LAction, ARoot) then
        Continue;
      LIsPost := False;
      if HelpChatBindNavigateAction(LAction, LIsPost, LMoves, LBindSource) and LMoves and
        HelpChatBindSourceEditing(LBindSource) then
        Continue;
      LCommand := THelpChatVclCommand.Create;
      LCommand.Control := LControl;
      LCommand.NavigatorButton := -1;
      LCommand.Caption := HelpChatCleanCaption(ControlCaption(LControl));
      if (LCommand.Caption = '') and (LControl.Hint <> '') then
        LCommand.Caption := HelpChatCleanCaption(GetShortHint(LControl.Hint));
      if (LCommand.Caption = '') and (LAction is TCustomAction) then
        LCommand.Caption := HelpChatCleanCaption(TCustomAction(LAction).Caption);
      if LCommand.Caption = '' then
        LCommand.Caption := LControl.Name;
      LCommand.Hint := Trim(GetLongHint(LControl.Hint));
      if SameText(LCommand.Hint, LCommand.Caption) then
        LCommand.Hint := '';
      if (LAction is TCustomAction) and (TCustomAction(LAction).ShortCut <> 0) then
        LCommand.ShortCut := ShortCutToText(TCustomAction(LAction).ShortCut);
      LCommand.Id := LControl.Name;
      if LCommand.Id = '' then
        LCommand.Id := 'button';
      LCommand.IsSave := IsPostAction(LAction) or LIsPost or
        ((LControl is TCustomButton) and
         (TCustomButtonAccess(LControl).ModalResult in [mrOk, mrYes, mrAll, mrYesToAll])) or
        HelpChatLooksLikeSave(LCommand.Caption, LControl.Name);
      AddCommand(AList, LCommand, ASender);
    end;
    if LControl is TWinControl then
      CollectCommandControls(TWinControl(LControl), ARoot, AList, ASender);
  end;
end;

procedure ClickCommand(const ACommand: THelpChatVclCommand);
begin
  if ACommand.NavigatorButton >= 0 then
    TDBNavigator(ACommand.Control).BtnClick(TNavigateBtn(ACommand.NavigatorButton))
  else
    TControlAccess(ACommand.Control).Click;
end;

{ TVclScreen }

constructor TVclScreen.Create(const ARoot: TWinControl; const ASender: TObject);
begin
  inherited Create(ASender);
  FRoot := ARoot;
end;

function TVclScreen.Title: string;
begin
  Result := RootCaption(FRoot);
end;

function TVclScreen.TypeName: string;
begin
  Result := FRoot.ClassName;
end;

function TVclScreen.Identity: string;
begin
  Result := Format('%s:%s:%p', [FRoot.ClassName, FRoot.Name, Pointer(FRoot)]);
end;

function TVclScreen.Fields: THelpChatDataFieldList;
var
  LFields: TObjectList<THelpChatVclField>;
  LField: THelpChatVclField;
begin
  Result := THelpChatDataFieldList.Create(True);
  LFields := HelpChatVclCollectFields(FRoot, Sender);
  try
    LFields.OwnsObjects := False;
    for LField in LFields do
      Result.Add(LField);
  finally
    LFields.Free;
  end;
end;

function TVclScreen.Lists: TArray<THelpChatDataList>;
var
  LFields: THelpChatDataFieldList;
  LField: THelpChatDataField;
  LItem: THelpChatDataList;
  LKnown: Boolean;
  I: Integer;
begin
  Result := nil;
  CollectListControls(FRoot, Result);
  // The grids and the lists a LiveBindings link fills with a data set.
  CollectBoundLists(FRoot, Result);
  // The record of a form with no grid is a list of one too, to count and move.
  LFields := Fields;
  try
    for LField in LFields do
      if (LField.DataSet <> nil) then
      begin
        LKnown := False;
        for I := 0 to High(Result) do
          LKnown := LKnown or (Result[I].DataSet = LField.DataSet);
        if not LKnown then
        begin
          LItem := Default(THelpChatDataList);
          LItem.DataSet := LField.DataSet;
          LItem.Id := HelpChatDataSetName(LField.DataSet);
          LItem.Caption := LItem.Id;
          Result := Result + [LItem];
        end;
      end;
  finally
    LFields.Free;
  end;
end;

function TVclScreen.Pages: TArray<THelpChatSkillPage>;
begin
  Result := nil;
  CollectSheets(FRoot, FRoot, Result);
end;

function TVclScreen.ActivatePage(const APage: THelpChatSkillPage): string;
var
  LChain: TList<TTabSheet>;
  LControl: TControl;
  LSheet: TTabSheet;
  LPageControl: TPageControlAccess;
  LForm: TCustomForm;
begin
  Result := '';
  // From the outermost page in: an inner tab shows only when its page does.
  LChain := TList<TTabSheet>.Create;
  try
    LControl := TTabSheet(APage.Control);
    while Assigned(LControl) and (LControl <> FRoot) do
    begin
      if LControl is TTabSheet then
        LChain.Insert(0, TTabSheet(LControl));
      LControl := LControl.Parent;
    end;
    for LSheet in LChain do
    begin
      LPageControl := TPageControlAccess(LSheet.PageControl);
      if LPageControl.ActivePage = LSheet then
        Continue;
      // As a click on the tab: OnChanging may refuse, OnChange follows. Not
      // through Change, which takes the page back from the tab index of the
      // control - the one of before.
      if not LPageControl.CanChange then
        Exit(Format('The screen refused to leave the page "%s".',
          [HelpChatCleanCaption(LPageControl.ActivePage.Caption)]));
      // The VCL keeps the page when the focus is inside it and cannot be
      // moved to the sheet (a form that is not active): it is the user's
      // caret, so it goes to the page shown, as a click would take it.
      LForm := GetParentForm(LPageControl);
      if Assigned(LForm) and Assigned(LPageControl.ActivePage) and
        LPageControl.ActivePage.ContainsControl(LForm.ActiveControl) then
        LForm.ActiveControl := nil;
      LPageControl.ActivePage := LSheet;
      if LPageControl.ActivePage <> LSheet then
        Exit(Format('The screen did not show the page "%s".', [HelpChatCleanCaption(LSheet.Caption)]));
      if Assigned(LPageControl.OnChange) then
        LPageControl.OnChange(LPageControl);
    end;
  finally
    LChain.Free;
  end;
end;

function TVclScreen.Commands: THelpChatSkillCommandList;
begin
  Result := THelpChatSkillCommandList.Create(True);
  CollectCommandControls(FRoot, FRoot, Result, Sender);
end;

procedure TVclScreen.Press(const ACommandId: string; const AQueued: Boolean);
var
  LRoot: TWinControl;
  LSender: TObject;
  LClick: TThreadProcedure;
begin
  LRoot := FRoot;
  LSender := Sender;
  // Looked up again when it is clicked: with AQueued the screen may have
  // changed meanwhile, and a button that vanished is not pressed.
  LClick :=
    procedure
    var
      LCommands: THelpChatSkillCommandList;
      LCommand: THelpChatSkillCommand;
      I: Integer;
      LAlive: Boolean;
    begin
      LAlive := False;
      for I := 0 to Screen.CustomFormCount - 1 do
        LAlive := LAlive or (Screen.CustomForms[I] = LRoot) or
          (Screen.CustomForms[I] = GetParentForm(LRoot));
      if not LAlive then
        Exit;
      LCommands := THelpChatSkillCommandList.Create(True);
      try
        CollectCommandControls(LRoot, LRoot, LCommands, LSender);
        for LCommand in LCommands do
          if SameText(LCommand.Id, ACommandId) then
          begin
            ClickCommand(THelpChatVclCommand(LCommand));
            Break;
          end;
      finally
        LCommands.Free;
      end;
    end;
  // After the answer: a button that opens a modal window would otherwise
  // keep the model waiting until the user closes it.
  if AQueued then
    TThread.ForceQueue(nil, LClick)
  else
    LClick;
end;

{ TVclScreenProvider }

class function TVclScreenProvider.Supports(const AHost: TComponent): Boolean;
begin
  // Any host but a FireMonkey one, whose screen these controls are not.
  Result := not Assigned(AHost) or not AHost.QualifiedClassName.StartsWith('FMX.', True);
end;

class function TVclScreenProvider.CreateScreen(const AHost: TComponent): THelpChatScreen;
var
  LTarget: TWinControl;
begin
  LTarget := HelpChatVclTarget(AHost);
  if Assigned(LTarget) then
    Result := TVclScreen.Create(LTarget, AHost)
  else
    Result := nil;
end;

{ the public functions }

function NewScreen(const ARoot: TWinControl; const ASender: TObject): TVclScreen;
begin
  if ARoot = nil then
    raise Exception.Create(MSG_NO_FORM);
  Result := TVclScreen.Create(ARoot, ASender);
end;

function HelpChatVclDescribeForm(const ARoot: TWinControl; const AHideValues: Boolean;
  const ASender: TObject): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, ASender);
  try
    Result := HelpChatScreenDescribe(LScreen, AHideValues);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclFillForm(const ARoot: TWinControl; const AValues: TJSONObject;
  const AMode: THelpChatFillMode; const AHideValues: Boolean;
  const ASnapshot: TDictionary<string, string>; const ASender: TObject): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, ASender);
  try
    Result := HelpChatScreenFill(LScreen, AValues, AMode, AHideValues, ASnapshot);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclCancelEdit(const ARoot: TWinControl;
  const ASnapshot: TDictionary<string, string>; const ASender: TObject): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, ASender);
  try
    Result := HelpChatScreenCancel(LScreen, ASnapshot);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclFindChoice(const ARoot: TWinControl; const AFieldId, AText: string;
  const ASender: TObject): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, ASender);
  try
    Result := HelpChatScreenFindChoice(LScreen, AFieldId, AText);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclListCommands(const ARoot: TWinControl; const ASender: TObject): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, ASender);
  try
    Result := HelpChatScreenListCommands(LScreen);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclPressCommand(const ARoot: TWinControl; const ACommand: string;
  const AQueued: Boolean; const ASender: TObject): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, ASender);
  try
    Result := HelpChatScreenPress(LScreen, ACommand, AQueued);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclCountRecords(const ARoot: TWinControl; const AList: string): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, nil);
  try
    Result := HelpChatScreenCount(LScreen, AList);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclFindRecord(const ARoot: TWinControl; const AText, AField, AList: string;
  const AHideValues: Boolean): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, nil);
  try
    Result := HelpChatScreenFindRecord(LScreen, AText, AField, AList, AHideValues);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclPagesText(const ARoot: TWinControl): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, nil);
  try
    Result := HelpChatScreenPagesText(LScreen);
  finally
    LScreen.Free;
  end;
end;

function HelpChatVclShowPage(const ARoot: TWinControl; const APage: string): string;
var
  LScreen: TVclScreen;
begin
  LScreen := NewScreen(ARoot, nil);
  try
    Result := HelpChatScreenShowPage(LScreen, APage);
  finally
    LScreen.Free;
  end;
end;

initialization
  GOptions := THelpChatVclSkillOptions.Create;
  GAdapters := TList<THelpChatVclFieldAdapterClass>.Create;
  // Asked from the last: the data-aware one before the plain edit it may be.
  RegisterHelpChatVclFieldAdapter(TEditAdapter);
  RegisterHelpChatVclFieldAdapter(TComboAdapter);
  RegisterHelpChatVclFieldAdapter(TCheckAdapter);
  RegisterHelpChatVclFieldAdapter(TRadioGroupAdapter);
  RegisterHelpChatVclFieldAdapter(TRadioButtonAdapter);
  RegisterHelpChatVclFieldAdapter(TDatePickerAdapter);
  RegisterHelpChatVclFieldAdapter(TDataAwareAdapter);
  HelpChatRegisterScreenProvider(TVclScreenProvider);

finalization
  HelpChatUnregisterScreenProvider(TVclScreenProvider);
  FreeAndNil(GAdapters);
  FreeAndNil(GOptions);

end.
