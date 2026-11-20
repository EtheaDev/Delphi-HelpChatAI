{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       The FireMonkey screen of the skills: the form the user is on, its      }
{       fields (LiveBindings included), buttons, lists and tabs.               }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
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
///  The FireMonkey screen of the four skills of <c>HelpChatAI.Skills.Screen</c>,
///  registered as a screen provider and linked by <c>FMX.HelpChatAI</c>: naming
///  them in <c>Settings.Skills</c> is enough, as in the VCL.
///  The screen is the form the user is working on (<see cref="HelpChatFmxWorkingForm" />:
///  the active one, else the one activated last, never the window of the chat
///  or its confirmation), and it holds what the user sees: the controls that
///  are visible and enabled, in tab order, outside the chat.
///  A field is a control bound to a field by LiveBindings
///  (<c>TLinkControlToField</c>: the value goes through the <c>TField</c> of
///  its <c>TBindSourceDB</c>; <c>TLinkFillControlToField</c> makes it a lookup
///  by code or description), or a control an adapter accepts
///  (<see cref="THelpChatFmxFieldAdapter" />): edits, number and spin boxes,
///  memos, combo boxes and combo edits, check boxes and switches, radio
///  buttons, date and time edits. The bindings are read through RTTI, so the
///  package needs none of the LiveBindings units. The caption is the label
///  whose <c>FocusControl</c> is the control, else its own text, the display
///  label of its field, the nearest label on its left or above it, its text
///  prompt. The lists are the grids and list views a link fills with a data
///  set, the bind navigators, and the record of the form; the pages the tabs
///  of a <c>TTabControl</c> whose tabs the user can click (one with
///  <c>TabPosition = None</c> is a card panel of the application, reached by
///  its own actions).
/// </summary>
unit FMX.HelpChatAI.Skills;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, Data.DB,
  HelpChatAI.Skills, HelpChatAI.Skills.Screen;

type
  THelpChatFmxField = class;

  /// <summary>What a kind of plain control is to the skills: the FireMonkey
  /// twin of <c>THelpChatVclFieldAdapter</c>. The adapters registered last
  /// are asked first; a control bound by LiveBindings never reaches
  /// them.</summary>
  THelpChatFmxFieldAdapter = class abstract
  public
    /// <summary>True for a control this adapter reads and writes.</summary>
    class function Accepts(const AControl: TControl): Boolean; virtual; abstract;
    /// <summary>Fills what the model is told of the field: kind, choices,
    /// read-only, secret.</summary>
    class procedure Describe(const AField: THelpChatFmxField); virtual; abstract;
    /// <summary>The value of the control, as text.</summary>
    class function ReadValue(const AField: THelpChatFmxField): string; virtual; abstract;
    /// <summary>Writes <c>AText</c> into the control: empty when written
    /// (<c>AShown</c> is what the control now shows), else why not.</summary>
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; virtual; abstract;
  end;

  THelpChatFmxFieldAdapterClass = class of THelpChatFmxFieldAdapter;

  /// <summary>One field of the form, with the control behind it.</summary>
  THelpChatFmxField = class(THelpChatDataField)
  public
    /// <summary>The control of the field.</summary>
    Control: TControl;
    /// <summary>The radio buttons of a group, which are one field.</summary>
    Controls: TArray<TControl>;
    /// <summary>nil for a field bound by LiveBindings.</summary>
    Adapter: THelpChatFmxFieldAdapterClass;
    /// <summary>The caption the control carries itself.</summary>
    OwnCaption: string;
    /// <summary>The text prompt of an edit: the last resort of a
    /// caption.</summary>
    Placeholder: string;
    /// <summary>The LiveBindings link that binds it, if any.</summary>
    Link: TComponent;
    function ReadValue: string; override;
    function WriteValue(const AText: string; out AShown: string): string; override;
    procedure Focus; override;
  end;

  /// <summary>One button the skills may press.</summary>
  THelpChatFmxCommand = class(THelpChatSkillCommand)
  public
    /// <summary>The control that is pressed.</summary>
    Control: TControl;
  end;

  THelpChatFmxTargetEvent = procedure(Sender: TObject; var ATarget: TFmxObject) of object;
  /// <summary>Every field the skills found, before the model hears of it:
  /// correct what it says or set <c>AAccept</c> False to hide it.</summary>
  THelpChatFmxFieldEvent = procedure(Sender: TObject; const AField: THelpChatFmxField;
    var AAccept: Boolean) of object;
  /// <summary>Every button the skills found: <c>AAccept</c> arrives False
  /// for one that looks like a save, True otherwise.</summary>
  THelpChatFmxCommandEvent = procedure(Sender: TObject; const ACommand: THelpChatFmxCommand;
    var AAccept: Boolean) of object;

  /// <summary>What an application may change about the FireMonkey skills
  /// (<see cref="HelpChatFmxSkills" />): the same hooks as the VCL.</summary>
  THelpChatFmxSkillOptions = class
  strict private
    FOnGetTarget: THelpChatFmxTargetEvent;
    FOnDescribeField: THelpChatFmxFieldEvent;
    FOnCommand: THelpChatFmxCommandEvent;
    function GetHideFieldValues: Boolean;
    procedure SetHideFieldValues(const Value: Boolean);
  public
    /// <summary>The model is told whether a field is filled, never its
    /// value (<c>HelpChatSkillsHideFieldValues</c>, the same for every
    /// framework). A password is never read anyway.</summary>
    property HideFieldValues: Boolean read GetHideFieldValues write SetHideFieldValues;
    /// <summary>Which form or control the skills work on, when it is not
    /// the form the user is on.</summary>
    property OnGetTarget: THelpChatFmxTargetEvent read FOnGetTarget write FOnGetTarget;
    /// <summary>Corrects or hides a field before the model hears of it.</summary>
    property OnDescribeField: THelpChatFmxFieldEvent read FOnDescribeField write FOnDescribeField;
    /// <summary>Decides which buttons the assistant may press.</summary>
    property OnCommand: THelpChatFmxCommandEvent read FOnCommand write FOnCommand;
  end;

/// <summary>The options of the FireMonkey skills.</summary>
function HelpChatFmxSkills: THelpChatFmxSkillOptions;
/// <summary>Teaches the skills a kind of control. Asked before the ones
/// registered earlier and the built-in ones.</summary>
procedure RegisterHelpChatFmxFieldAdapter(const AAdapter: THelpChatFmxFieldAdapterClass);
/// <summary>Takes an adapter of the application away again.</summary>
procedure UnregisterHelpChatFmxFieldAdapter(const AAdapter: THelpChatFmxFieldAdapterClass);

/// <summary>The form the user is working on: the active form, unless it is
/// the window of the chat or a dialog of the library, else the visible form
/// activated last. nil when none.</summary>
function HelpChatFmxWorkingForm: TCommonCustomForm;
/// <summary>What the skills of that assistant work on:
/// <see cref="HelpChatFmxWorkingForm" />, as <c>OnGetTarget</c> may change it.</summary>
function HelpChatFmxTarget(const AHost: TComponent): TFmxObject;

/// <summary>The screen of a form or a control, for code of the application
/// and for the tests: the functions of <c>HelpChatAI.Skills.Screen</c> take
/// it. The caller frees it.</summary>
function HelpChatFmxScreen(const ARoot: TFmxObject; const ASender: TObject = nil): THelpChatScreen;
/// <summary>The fields of a form or a control, in tab order. The caller
/// frees the list.</summary>
function HelpChatFmxCollectFields(const ARoot: TFmxObject;
  const ASender: TObject = nil): TObjectList<THelpChatFmxField>;

implementation

uses
  System.StrUtils, System.Math, System.TypInfo, System.Rtti, System.UITypes, System.Messaging,
  System.Actions, System.Generics.Defaults, System.Types,
  FMX.StdCtrls, FMX.Edit, FMX.Memo, FMX.ListBox, FMX.ComboEdit, FMX.DateTimeCtrls,
  FMX.TabControl, FMX.ActnList,
  FMX.HelpChatAI, FMX.HelpChatAI.Panel, FMX.HelpChatAI.ConfirmDialog, FMX.HelpChatAI.Bubble;

type
  TControlAccess = class(TControl);
  TDateTimeEditAccess = class(TCustomDateTimeEdit);

  TFmxScreen = class(THelpChatScreen)
  strict private
    FRoot: TFmxObject;
  public
    constructor Create(const ARoot: TFmxObject; const ASender: TObject);
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

  TFmxScreenProvider = class(THelpChatScreenProvider)
  public
    class function Supports(const AHost: TComponent): Boolean; override;
    class function CreateScreen(const AHost: TComponent): THelpChatScreen; override;
  end;

var
  GOptions: THelpChatFmxSkillOptions;
  GAdapters: TList<THelpChatFmxFieldAdapterClass>;
  GLastForm: TCommonCustomForm;
  GActivateId: TMessageSubscriptionId;

{ options and registry }

function HelpChatFmxSkills: THelpChatFmxSkillOptions;
begin
  Result := GOptions;
end;

function THelpChatFmxSkillOptions.GetHideFieldValues: Boolean;
begin
  Result := HelpChatSkillsHideFieldValues;
end;

procedure THelpChatFmxSkillOptions.SetHideFieldValues(const Value: Boolean);
begin
  HelpChatSkillsHideFieldValues := Value;
end;

procedure RegisterHelpChatFmxFieldAdapter(const AAdapter: THelpChatFmxFieldAdapterClass);
begin
  if Assigned(AAdapter) and not GAdapters.Contains(AAdapter) then
    GAdapters.Add(AAdapter);
end;

procedure UnregisterHelpChatFmxFieldAdapter(const AAdapter: THelpChatFmxFieldAdapterClass);
begin
  if Assigned(GAdapters) then
    GAdapters.Remove(AAdapter);
end;

function FindAdapter(const AControl: TControl): THelpChatFmxFieldAdapterClass;
var
  I: Integer;
begin
  for I := GAdapters.Count - 1 downto 0 do
    if GAdapters[I].Accepts(AControl) then
      Exit(GAdapters[I]);
  Result := nil;
end;

{ RTTI helpers: the bindings are read by name, no LiveBindings unit needed }

function HasProp(const AObject: TObject; const AName: string; const AKinds: TTypeKinds): Boolean;
var
  LInfo: PPropInfo;
begin
  LInfo := GetPropInfo(AObject, AName);
  Result := Assigned(LInfo) and (LInfo^.PropType^^.Kind in AKinds);
end;

function PropBool(const AObject: TObject; const AName: string; const ADefault: Boolean = False): Boolean;
begin
  if HasProp(AObject, AName, [tkEnumeration]) then
    Result := GetOrdProp(AObject, AName) <> 0
  else
    Result := ADefault;
end;

function PropStr(const AObject: TObject; const AName: string): string;
begin
  if Assigned(AObject) and HasProp(AObject, AName, [tkString, tkLString, tkWString, tkUString]) then
    Result := GetStrProp(AObject, AName)
  else
    Result := '';
end;

function PropObj(const AObject: TObject; const AName: string): TObject;
begin
  if Assigned(AObject) and HasProp(AObject, AName, [tkClass]) then
    Result := GetObjectProp(AObject, AName)
  else
    Result := nil;
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

// The data set of a bind source (TBindSourceDB) or of anything with a
// published DataSet.
function DataSetOfSource(const ASource: TObject): TDataSet;
begin
  Result := HelpChatSourceDataSet(ASource);
end;

function ControlText(const AObject: TObject): string;
begin
  Result := PropStr(AObject, 'Text');
end;

function RootCaption(const ARoot: TFmxObject): string;
begin
  if ARoot is TCommonCustomForm then
    Result := HelpChatCleanCaption(TCommonCustomForm(ARoot).Caption)
  else
    Result := HelpChatCleanCaption(ControlText(ARoot));
  if Result = '' then
    Result := ARoot.Name;
end;

function IsInsideChat(const AObject: TFmxObject): Boolean;
var
  LObject: TFmxObject;
begin
  LObject := AObject;
  while Assigned(LObject) do
  begin
    if (LObject is TFmxHelpChatAIPanel) or (LObject.Owner is TFmxHelpChatAI) then
      Exit(True);
    LObject := LObject.Parent;
  end;
  Result := False;
end;

// Shown: the control and every control above it are visible, up to a
// visible form. The content of a tab that is not active is hidden, so its
// controls are not shown.
function IsShown(const AControl: TControl): Boolean;
var
  LObject: TFmxObject;
begin
  LObject := AControl;
  while Assigned(LObject) do
  begin
    if (LObject is TControl) and not TControl(LObject).Visible then
      Exit(False);
    if LObject is TCommonCustomForm then
      Exit(TCommonCustomForm(LObject).Visible);
    LObject := LObject.Parent;
  end;
  Result := False;
end;

function IsUsable(const AControl: TControl): Boolean;
begin
  Result := IsShown(AControl) and AControl.AbsoluteEnabled and not IsInsideChat(AControl);
end;

// The controls under a parent, in tab order (the order of the children
// breaks the ties), each followed by the ones it holds.
procedure CollectInTabOrder(const AParent: TFmxObject; const AList: TList<TControl>);
var
  LChildren: TList<TControl>;
  I: Integer;
begin
  if AParent.ChildrenCount = 0 then
    Exit;
  LChildren := TList<TControl>.Create;
  try
    for I := 0 to AParent.ChildrenCount - 1 do
      if AParent.Children[I] is TControl then
        LChildren.Add(TControl(AParent.Children[I]));
    // By tab order, the order of the children breaking the ties.
    LChildren.Sort(TComparer<TControl>.Construct(
      function(const A, B: TControl): Integer
      begin
        Result := CompareValue(A.TabOrder, B.TabOrder);
        if Result = 0 then
          Result := CompareValue(A.Index, B.Index);
      end));
    for I := 0 to LChildren.Count - 1 do
    begin
      AList.Add(LChildren[I]);
      CollectInTabOrder(LChildren[I], AList);
    end;
  finally
    LChildren.Free;
  end;
end;

{ the bindings of a form }

type
  TFmxBindings = class
  public
    /// control -> the link that binds it to a field
    FieldLinks: TDictionary<TComponent, TComponent>;
    /// the links that fill a grid or a list with a data set
    ListLinks: TList<TComponent>;
    constructor Create(const ARoot: TFmxObject);
    destructor Destroy; override;
  end;

constructor TFmxBindings.Create(const ARoot: TFmxObject);
var
  LOwner: TComponent;
begin
  inherited Create;
  FieldLinks := TDictionary<TComponent, TComponent>.Create;
  ListLinks := TList<TComponent>.Create;
  // The links belong to the form (or the frame) that holds the controls.
  LOwner := ARoot;
  if not (ARoot is TCommonCustomForm) and Assigned(ARoot.Owner) then
    LOwner := ARoot.Owner;
  // The same scan as the VCL's (HelpChatAI.Skills.Screen).
  HelpChatScanBindings(LOwner, FieldLinks, ListLinks);
end;

destructor TFmxBindings.Destroy;
begin
  ListLinks.Free;
  FieldLinks.Free;
  inherited;
end;

{ THelpChatFmxField }

function THelpChatFmxField.ReadValue: string;
begin
  if Assigned(Field) then
    Result := ReadDataValue
  else
    Result := Adapter.ReadValue(Self);
end;

function THelpChatFmxField.WriteValue(const AText: string; out AShown: string): string;
begin
  if Assigned(Field) then
    Result := WriteDataValue(AText, AShown)
  else
    Result := Adapter.WriteValue(Self, AText, AShown);
end;

procedure THelpChatFmxField.Focus;
begin
  // Only on the active form: a FireMonkey SetFocus on another form would
  // take the focus away from the chat.
  if Assigned(Control.Root) and (Control.Root.GetObject = Screen.ActiveForm) and Control.CanFocus then
    Control.SetFocus;
end;

{ the adapters }

function CleanItems(const AItems: TStrings): TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, AItems.Count);
  for I := 0 to AItems.Count - 1 do
    Result[I] := HelpChatCleanCaption(AItems[I]);
end;

function NotAllowed(const AField: THelpChatFmxField; const AText: string): string;
begin
  Result := Format('"%s" is not allowed: %s', [AText, AField.TypeText]);
end;

type
  TEditAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

  TMemoAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

  TComboEditAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

  TComboAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

  TCheckAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

  TRadioAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

  TDateAdapter = class(THelpChatFmxFieldAdapter)
  public
    class function Accepts(const AControl: TControl): Boolean; override;
    class procedure Describe(const AField: THelpChatFmxField); override;
    class function ReadValue(const AField: THelpChatFmxField): string; override;
    class function WriteValue(const AField: THelpChatFmxField; const AText: string;
      out AShown: string): string; override;
  end;

{ TEditAdapter: TEdit, and the edit boxes (TNumberBox, TSpinBox) with a Value }

class function TEditAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomEdit;
end;

class procedure TEditAdapter.Describe(const AField: THelpChatFmxField);
var
  LEdit: TCustomEdit;
begin
  LEdit := TCustomEdit(AField.Control);
  if HasProp(LEdit, 'Value', [tkFloat]) then
  begin
    if HasProp(LEdit, 'ValueType', [tkEnumeration]) and
      SameText(GetEnumProp(LEdit, 'ValueType'), 'Integer') then
      AField.Kind := hfkInteger
    else
      AField.Kind := hfkNumber;
  end
  else
    AField.Kind := hfkText;
  AField.MaxLength := LEdit.MaxLength;
  AField.ReadOnly := LEdit.ReadOnly;
  AField.Secret := LEdit.Password;
  AField.Placeholder := LEdit.TextPrompt;
end;

class function TEditAdapter.ReadValue(const AField: THelpChatFmxField): string;
var
  LEdit: TCustomEdit;
begin
  LEdit := TCustomEdit(AField.Control);
  if Trim(LEdit.Text) = '' then
    Exit('');
  case AField.Kind of
    hfkInteger: Result := IntToStr(Round(GetFloatProp(LEdit, 'Value')));
    hfkNumber: Result := HelpChatFormatNumber(GetFloatProp(LEdit, 'Value'));
  else
    Result := LEdit.Text;
  end;
end;

class function TEditAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
var
  LEdit: TCustomEdit;
  LText: string;
  LInteger: Int64;
  LNumber: Double;
begin
  Result := '';
  LEdit := TCustomEdit(AField.Control);
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
        SetFloatProp(LEdit, 'Value', LInteger);
      end;
    hfkNumber:
      begin
        if not HelpChatParseNumber(LText, LNumber) then
          Exit(Format('"%s" is not a number', [LText]));
        SetFloatProp(LEdit, 'Value', LNumber);
      end;
  else
    if (AField.MaxLength > 0) and (LText.Length > AField.MaxLength) then
      Exit(Format('too long: %d characters, the maximum is %d', [LText.Length, AField.MaxLength]));
    LEdit.Text := LText;
  end;
end;

{ TMemoAdapter }

class function TMemoAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomMemo;
end;

class procedure TMemoAdapter.Describe(const AField: THelpChatFmxField);
begin
  AField.Kind := hfkMemo;
  AField.MaxLength := TCustomMemo(AField.Control).MaxLength;
  AField.ReadOnly := TCustomMemo(AField.Control).ReadOnly;
end;

class function TMemoAdapter.ReadValue(const AField: THelpChatFmxField): string;
begin
  Result := TCustomMemo(AField.Control).Text;
  if Trim(Result) = '' then
    Result := '';
end;

class function TMemoAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
begin
  Result := '';
  TCustomMemo(AField.Control).Text := AText;
  AShown := IfThen(Trim(AText) = '', '(empty)', AText);
end;

{ TComboEditAdapter: a combo the user may type in }

class function TComboEditAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomComboEdit;
end;

class procedure TComboEditAdapter.Describe(const AField: THelpChatFmxField);
begin
  TEditAdapter.Describe(AField);
  AField.Choices := CleanItems(TCustomComboEdit(AField.Control).Items);
  AField.ChoicesOnly := False;
  if Length(AField.Choices) > 0 then
    AField.Kind := hfkChoice;
end;

class function TComboEditAdapter.ReadValue(const AField: THelpChatFmxField): string;
begin
  Result := TCustomComboEdit(AField.Control).Text;
end;

class function TComboEditAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  AShown := Trim(AText);
  LIndex := HelpChatMatchChoice(AField.Choices, AText);
  if LIndex >= 0 then
  begin
    TCustomComboEdit(AField.Control).ItemIndex := LIndex;
    AShown := AField.Choices[LIndex];
  end
  else
    TCustomComboEdit(AField.Control).Text := AShown;
  if AShown = '' then
    AShown := '(empty)';
end;

{ TComboAdapter: a drop-down list }

class function TComboAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomComboBox;
end;

class procedure TComboAdapter.Describe(const AField: THelpChatFmxField);
begin
  AField.Kind := hfkChoice;
  AField.ChoicesOnly := True;
  AField.Choices := CleanItems(TCustomComboBox(AField.Control).Items);
end;

class function TComboAdapter.ReadValue(const AField: THelpChatFmxField): string;
var
  LIndex: Integer;
begin
  LIndex := TCustomComboBox(AField.Control).ItemIndex;
  if (LIndex >= 0) and (LIndex <= High(AField.Choices)) then
    Result := AField.Choices[LIndex]
  else
    Result := '';
end;

class function TComboAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  if Trim(AText) = '' then
  begin
    TCustomComboBox(AField.Control).ItemIndex := -1;
    AShown := '(empty)';
    Exit;
  end;
  LIndex := HelpChatMatchChoice(AField.Choices, AText);
  if LIndex < 0 then
    Exit(NotAllowed(AField, AText));
  TCustomComboBox(AField.Control).ItemIndex := LIndex; // fires OnChange
  AShown := AField.Choices[LIndex];
end;

{ TCheckAdapter: a check box, a switch }

class function TCheckAdapter.Accepts(const AControl: TControl): Boolean;
begin
  // Not a button: in FireMonkey every TSpeedButton is IIsChecked, and each
  // one of a tool bar was described as a yes/no field that fill_form could
  // set.
  Result := Supports(AControl, IIsChecked) and not (AControl is TRadioButton) and
    not (AControl is TCustomButton);
end;

class procedure TCheckAdapter.Describe(const AField: THelpChatFmxField);
begin
  AField.Kind := hfkBoolean;
  AField.OwnCaption := ControlText(AField.Control);
end;

class function TCheckAdapter.ReadValue(const AField: THelpChatFmxField): string;
var
  LCheck: IIsChecked;
begin
  if Supports(AField.Control, IIsChecked, LCheck) then
    Result := IfThen(LCheck.IsChecked, 'true', 'false')
  else
    Result := '';
end;

class function TCheckAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
var
  LValue: Boolean;
  LCheck: IIsChecked;
begin
  Result := '';
  if Trim(AText) = '' then
    LValue := False
  else if not HelpChatParseBoolean(AText, LValue) then
    Exit(Format('"%s" is not yes/no', [AText]));
  if Supports(AField.Control, IIsChecked, LCheck) then
    LCheck.IsChecked := LValue; // fires OnChange
  AShown := IfThen(LValue, 'true', 'false');
end;

{ TRadioAdapter: the radio buttons of a group (GroupName, else the parent) are one field }

function RadioGroupKey(const AControl: TControl): string;
begin
  Result := TRadioButton(AControl).GroupName;
  if Result = '' then
    Result := Format('parent:%p', [Pointer(AControl.Parent)]);
end;

class function TRadioAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TRadioButton;
end;

class procedure TRadioAdapter.Describe(const AField: THelpChatFmxField);
var
  LKey: string;
  LAll: TList<TControl>;
  LRoot: TFmxObject;
  LControl: TControl;
begin
  AField.Kind := hfkChoice;
  AField.ChoicesOnly := True;
  AField.Controls := nil;
  AField.Choices := nil;
  LKey := RadioGroupKey(AField.Control);
  LRoot := AField.Control;
  while Assigned(LRoot.Parent) do
    LRoot := LRoot.Parent;
  LAll := TList<TControl>.Create;
  try
    CollectInTabOrder(LRoot, LAll);
    for LControl in LAll do
      if (LControl is TRadioButton) and (RadioGroupKey(LControl) = LKey) and IsUsable(LControl) then
      begin
        AField.Controls := AField.Controls + [LControl];
        AField.Choices := AField.Choices + [HelpChatCleanCaption(ControlText(LControl))];
      end;
  finally
    LAll.Free;
  end;
  // A group box names the group, and gives it its id.
  if AField.Control.Parent is TGroupBox then
  begin
    AField.OwnCaption := TGroupBox(AField.Control.Parent).Text;
    if TGroupBox(AField.Control.Parent).Name <> '' then
      AField.Id := TGroupBox(AField.Control.Parent).Name;
  end
  else if TRadioButton(AField.Control).GroupName <> '' then
    AField.Id := TRadioButton(AField.Control).GroupName;
end;

class function TRadioAdapter.ReadValue(const AField: THelpChatFmxField): string;
var
  I: Integer;
begin
  for I := 0 to High(AField.Controls) do
    if TRadioButton(AField.Controls[I]).IsChecked then
      Exit(AField.Choices[I]);
  Result := '';
end;

class function TRadioAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
var
  LIndex, I: Integer;
begin
  Result := '';
  if Trim(AText) = '' then
  begin
    for I := 0 to High(AField.Controls) do
      TRadioButton(AField.Controls[I]).IsChecked := False;
    AShown := '(empty)';
    Exit;
  end;
  LIndex := HelpChatMatchChoice(AField.Choices, AText);
  if LIndex < 0 then
    Exit(NotAllowed(AField, AText));
  TRadioButton(AField.Controls[LIndex]).IsChecked := True;
  AShown := AField.Choices[LIndex];
end;

{ TDateAdapter: TDateEdit, TTimeEdit }

class function TDateAdapter.Accepts(const AControl: TControl): Boolean;
begin
  Result := AControl is TCustomDateTimeEdit;
end;

class procedure TDateAdapter.Describe(const AField: THelpChatFmxField);
begin
  if AField.Control is TCustomTimeEdit then
    AField.Kind := hfkTime
  else
    AField.Kind := hfkDate;
  AField.ReadOnly := TDateTimeEditAccess(AField.Control).ReadOnly;
end;

class function TDateAdapter.ReadValue(const AField: THelpChatFmxField): string;
var
  LEdit: TDateTimeEditAccess;
begin
  LEdit := TDateTimeEditAccess(AField.Control);
  if LEdit.IsEmpty or (LEdit.ShowCheckBox and not LEdit.IsChecked) then
    Result := ''
  else if AField.Kind = hfkTime then
    Result := HelpChatFormatDateTime(LEdit.Time, hfkTime)
  else
    Result := HelpChatFormatDateTime(LEdit.Date, hfkDate);
end;

class function TDateAdapter.WriteValue(const AField: THelpChatFmxField; const AText: string;
  out AShown: string): string;
var
  LEdit: TDateTimeEditAccess;
  LValue: TDateTime;
begin
  Result := '';
  LEdit := TDateTimeEditAccess(AField.Control);
  if Trim(AText) = '' then
  begin
    LEdit.IsEmpty := True;
    AShown := '(empty)';
    Exit;
  end;
  if not HelpChatParseDateTime(AText, AField.Kind, LValue) then
    Exit(Format('"%s" is not a valid date/time (use YYYY-MM-DD, HH:MM)', [AText]));
  if LEdit.ShowCheckBox then
    LEdit.IsChecked := True;
  LEdit.IsEmpty := False;
  if AField.Kind = hfkTime then
    LEdit.Time := LValue
  else
    LEdit.Date := LValue;
  AShown := HelpChatFormatDateTime(LValue, AField.Kind);
end;

{ the target }

function IsEligibleForm(const AForm: TCommonCustomForm): Boolean;
begin
  Result := Assigned(AForm) and AForm.Visible and not (AForm is TFmxHelpChatAIForm) and
    not (AForm is TFmxHelpChatConfirmDialog) and not (AForm is TFmxHelpChatBubbleForm);
end;

function IsAlive(const AForm: TCommonCustomForm): Boolean;
var
  I: Integer;
begin
  for I := 0 to Screen.FormCount - 1 do
    if Screen.Forms[I] = AForm then
      Exit(True);
  Result := False;
end;

function HelpChatFmxWorkingForm: TCommonCustomForm;
var
  I: Integer;
begin
  Result := Screen.ActiveForm;
  if IsEligibleForm(Result) then
    Exit;
  // The chat has the focus: the form activated last, as FireMonkey said.
  if Assigned(GLastForm) and IsAlive(GLastForm) and IsEligibleForm(GLastForm) then
    Exit(GLastForm);
  if IsEligibleForm(Application.MainForm) then
    Exit(Application.MainForm);
  for I := 0 to Screen.FormCount - 1 do
    if IsEligibleForm(Screen.Forms[I]) then
      Exit(Screen.Forms[I]);
  Result := nil;
end;

function HelpChatFmxTarget(const AHost: TComponent): TFmxObject;
begin
  Result := HelpChatFmxWorkingForm;
  if Assigned(GOptions.OnGetTarget) then
    GOptions.OnGetTarget(AHost, Result);
end;

{ fields }

procedure CollectLabels(const AControls: TList<TControl>; const AFocus: TDictionary<TControl, string>;
  const AFree: TList<TLabel>);
var
  LControl: TControl;
begin
  for LControl in AControls do
    if (LControl is TLabel) and LControl.Visible then
    begin
      if Assigned(TLabel(LControl).FocusControl) then
      begin
        if not AFocus.ContainsKey(TLabel(LControl).FocusControl) then
          AFocus.Add(TLabel(LControl).FocusControl, TLabel(LControl).Text);
      end
      else
        AFree.Add(TLabel(LControl));
    end;
end;

// The label without a FocusControl nearest to the control: on its left on
// the same row, else just above it.
function NearestLabel(const AControl: TControl; const AFree: TList<TLabel>): string;
var
  LLabel, LLeft, LAbove: TLabel;
  LDistance, LLeftDistance, LAboveDistance: Single;
  R, L: TRectF;
begin
  LLeft := nil;
  LAbove := nil;
  LLeftDistance := MaxInt;
  LAboveDistance := MaxInt;
  R := AControl.BoundsRect;
  for LLabel in AFree do
  begin
    if LLabel.Parent <> AControl.Parent then
      Continue;
    L := LLabel.BoundsRect;
    if (L.Right <= R.Left + 4) and (L.Top < R.Bottom) and (L.Bottom > R.Top) then
    begin
      LDistance := R.Left - L.Right;
      if LDistance < LLeftDistance then
      begin
        LLeftDistance := LDistance;
        LLeft := LLabel;
      end;
    end
    else if (L.Bottom <= R.Top + 2) and (L.Left < R.Right) and (L.Right > R.Left) then
    begin
      LDistance := R.Top - L.Bottom;
      if (LDistance <= R.Height * 2 + 8) and (LDistance < LAboveDistance) then
      begin
        LAboveDistance := LDistance;
        LAbove := LLabel;
      end;
    end;
  end;
  if Assigned(LLeft) and (LLeftDistance < 240) then
    Result := LLeft.Text
  else if Assigned(LAbove) then
    Result := LAbove.Text
  else
    Result := '';
end;

// A control bound to a field by a link: the field, its data set, its lookup.
function DescribeBound(const AField: THelpChatFmxField; const ALink: TComponent): Boolean;
var
  LItems: TObject;
begin
  // The field, its source, its lookup: the same for the VCL.
  Result := HelpChatDescribeBoundField(AField, ALink);
  if not Result then
    Exit;
  AField.Link := ALink;
  if AField.Kind = hfkLookup then
    // described by the link
  else if Supports(AField.Control, IIsChecked) and not (AField.Control is TCustomButton) then
  begin
    AField.Kind := hfkBoolean;
    AField.OwnCaption := ControlText(AField.Control);
  end
  else
  begin
    LItems := PropObj(AField.Control, 'Items');
    if (LItems is TStrings) and (TStrings(LItems).Count > 0) and
      (AField.Kind in [hfkText, hfkInteger, hfkNumber]) then
    begin
      AField.Kind := hfkChoice;
      AField.Choices := CleanItems(TStrings(LItems));
      AField.ChoicesOnly := AField.Control is TCustomComboBox;
    end;
  end;
  if AField.Control is TCustomEdit then
  begin
    AField.Secret := TCustomEdit(AField.Control).Password;
    AField.Placeholder := TCustomEdit(AField.Control).TextPrompt;
  end;
  AField.ReadOnly := AField.ReadOnly or PropBool(AField.Control, 'ReadOnly');
end;

function HelpChatFmxCollectFields(const ARoot: TFmxObject;
  const ASender: TObject): TObjectList<THelpChatFmxField>;
var
  LAll: TList<TControl>;
  LFocus: TDictionary<TControl, string>;
  LFree: TList<TLabel>;
  LGroups: TStringList;
  LIds: TStringList;
  LBindings: TFmxBindings;
  LControl: TControl;
  LLink: TComponent;
  LAdapter: THelpChatFmxFieldAdapterClass;
  LField: THelpChatFmxField;
  LCaption: string;
  LAccept, LBound: Boolean;
begin
  Result := TObjectList<THelpChatFmxField>.Create(True);
  if ARoot = nil then
    Exit;
  LAll := TList<TControl>.Create;
  LFocus := TDictionary<TControl, string>.Create;
  LFree := TList<TLabel>.Create;
  LGroups := TStringList.Create;
  LIds := TStringList.Create;
  LBindings := TFmxBindings.Create(ARoot);
  try
    LIds.CaseSensitive := False;
    CollectInTabOrder(ARoot, LAll);
    CollectLabels(LAll, LFocus, LFree);
    for LControl in LAll do
    begin
      if not IsUsable(LControl) then
        Continue;
      LBound := LBindings.FieldLinks.TryGetValue(LControl, LLink);
      LAdapter := nil;
      if not LBound then
      begin
        LAdapter := FindAdapter(LControl);
        if LAdapter = nil then
          Continue;
        if LAdapter = TRadioAdapter then
        begin
          if LGroups.IndexOf(RadioGroupKey(LControl)) >= 0 then
            Continue;
          LGroups.Add(RadioGroupKey(LControl));
        end;
      end;
      LField := THelpChatFmxField.Create;
      try
        LField.Control := LControl;
        LField.Adapter := LAdapter;
        LField.Id := LControl.Name;
        LField.Hint := Trim(LControl.Hint);
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
    LBindings.Free;
    LIds.Free;
    LGroups.Free;
    LFree.Free;
    LFocus.Free;
    LAll.Free;
  end;
end;

{ commands }

procedure AddCommand(const AList: THelpChatSkillCommandList; const ACommand: THelpChatFmxCommand;
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

// A property read through extended RTTI: the public ones too, which the
// navigator of the LiveBindings keeps what matters in.
function RttiProp(const AObject: TObject; const AName: string; out AValue: TValue): Boolean;
var
  LContext: TRttiContext;
  LProperty: TRttiProperty;
begin
  Result := False;
  if AObject = nil then
    Exit;
  LProperty := LContext.GetType(AObject.ClassType).GetProperty(AName);
  if Assigned(LProperty) and LProperty.IsReadable then
    try
      AValue := LProperty.GetValue(AObject);
      Result := True;
    except
      Result := False;
    end;
end;

// What a button of a TBindNavigator, or a button with one of the bind
// navigator actions, does: AIsPost for the ones that save, and the result
// True for the ones that move to another record, insert one or reload while
// their source is editing - pressing those posts the record, which is
// saving. A button of the navigator is told by its Index (TNavigateButton),
// never by its hint: the hint is a localized text of the RTL.
function NavigationWhileEditing(const AControl: TControl; const AAction: TBasicAction;
  out AIsPost: Boolean): Boolean;
var
  LValue: TValue;
  LSource: TObject;
  LOwner: TFmxObject;
  LKind: Integer;
  LMoves: Boolean;
begin
  Result := False;
  AIsPost := False;
  LSource := nil;
  LMoves := False;
  if InheritsFromName(AControl, 'TBindNavButton') then
  begin
    if not HelpChatBindNavigateButton(AControl, LKind, AIsPost, LMoves) then
      Exit;
    LOwner := AControl.Parent;
    while Assigned(LOwner) and (LSource = nil) do
    begin
      if RttiProp(LOwner, 'DataSource', LValue) and LValue.IsObject then
        LSource := LValue.AsObject;
      LOwner := LOwner.Parent;
    end;
  end
  else if not HelpChatBindNavigateAction(AAction, AIsPost, LMoves, LSource) then
    Exit;
  Result := LMoves and Assigned(LSource) and HelpChatBindSourceEditing(LSource);
end;

procedure CollectCommands(const ARoot: TFmxObject; const AList: THelpChatSkillCommandList;
  const ASender: TObject);
var
  LIsPost: Boolean;
  LAll: TList<TControl>;
  LControl: TControl;
  LCommand: THelpChatFmxCommand;
  LAction: TBasicAction;
begin
  LAll := TList<TControl>.Create;
  try
    CollectInTabOrder(ARoot, LAll);
    for LControl in LAll do
    begin
      if not (LControl is TCustomButton) or not IsUsable(LControl) then
        Continue;
      LAction := TControlAccess(LControl).Action;
      // Moving or inserting while a record is edited posts it: not offered.
      if NavigationWhileEditing(LControl, LAction, LIsPost) then
        Continue;
      LCommand := THelpChatFmxCommand.Create;
      LCommand.Control := LControl;
      LCommand.Caption := HelpChatCleanCaption(ControlText(LControl));
      if (LCommand.Caption = '') and (LControl.Hint <> '') then
        LCommand.Caption := HelpChatCleanCaption(LControl.Hint);
      if (LCommand.Caption = '') and (LAction is TCustomAction) then
        LCommand.Caption := HelpChatCleanCaption(TCustomAction(LAction).Text);
      if LCommand.Caption = '' then
        LCommand.Caption := LControl.Name;
      LCommand.Hint := Trim(LControl.Hint);
      if SameText(LCommand.Hint, LCommand.Caption) then
        LCommand.Hint := '';
      LCommand.Id := LControl.Name;
      if LCommand.Id = '' then
        LCommand.Id := 'button';
      LCommand.IsSave := LIsPost or
        (TCustomButton(LControl).ModalResult in [mrOk, mrYes, mrAll, mrYesToAll]) or
        HelpChatLooksLikeSave(LCommand.Caption, LControl.Name);
      AddCommand(AList, LCommand, ASender);
    end;
  finally
    LAll.Free;
  end;
end;

{ pages }

function TabPath(const AItem: TTabItem; const ARoot: TFmxObject): string;
var
  LObject: TFmxObject;
begin
  Result := HelpChatCleanCaption(AItem.Text);
  LObject := AItem.TabControl;
  if Assigned(LObject) then
    LObject := LObject.Parent;
  while Assigned(LObject) and (LObject <> ARoot) do
  begin
    if LObject is TTabItem then
      Result := HelpChatCleanCaption(TTabItem(LObject).Text) + ' > ' + Result;
    LObject := LObject.Parent;
  end;
end;

// A tab the user can reach: its tab control shows its tabs, and everything
// above it is visible - the content of an outer tab apart, which show_page
// selects first, provided the user could click that one too.
function TabReachable(const AItem: TTabItem; const ARoot: TFmxObject): Boolean;
var
  LObject: TFmxObject;
begin
  Result := False;
  if not AItem.Visible or not AItem.Enabled or (AItem.TabControl = nil) or
    (AItem.TabControl.TabPosition = TTabPosition.None) or IsInsideChat(AItem) then
    Exit;
  LObject := AItem.TabControl;
  while Assigned(LObject) and (LObject <> ARoot) do
  begin
    if LObject is TTabItem then
    begin
      if not TTabItem(LObject).Visible or (TTabItem(LObject).TabControl = nil) then
        Exit;
      // Tabs nobody can click: only the active one counts.
      if (TTabItem(LObject).TabControl.TabPosition = TTabPosition.None) and
        (TTabItem(LObject).TabControl.ActiveTab <> TTabItem(LObject)) then
        Exit;
    end
    else if (LObject is TControl) and not TControl(LObject).Visible and
      not (LObject.Parent is TTabItem) then
      Exit;
    if LObject is TCommonCustomForm then
      Break;
    LObject := LObject.Parent;
  end;
  Result := True;
end;

{ TFmxScreen }

constructor TFmxScreen.Create(const ARoot: TFmxObject; const ASender: TObject);
begin
  inherited Create(ASender);
  FRoot := ARoot;
end;

function TFmxScreen.Title: string;
begin
  Result := RootCaption(FRoot);
end;

function TFmxScreen.TypeName: string;
begin
  Result := FRoot.ClassName;
end;

function TFmxScreen.Identity: string;
begin
  Result := Format('%s:%s:%p', [FRoot.ClassName, FRoot.Name, Pointer(FRoot)]);
end;

function TFmxScreen.Fields: THelpChatDataFieldList;
var
  LFields: TObjectList<THelpChatFmxField>;
  LField: THelpChatFmxField;
begin
  Result := THelpChatDataFieldList.Create(True);
  LFields := HelpChatFmxCollectFields(FRoot, Sender);
  try
    LFields.OwnsObjects := False;
    for LField in LFields do
      Result.Add(LField);
  finally
    LFields.Free;
  end;
end;

function TFmxScreen.Lists: TArray<THelpChatDataList>;

  procedure AddList(const AId: string; const ADataSet: TDataSet);
  var
    LItem: THelpChatDataList;
    I: Integer;
  begin
    if ADataSet = nil then
      Exit;
    for I := 0 to High(Result) do
      if Result[I].DataSet = ADataSet then
        Exit;
    LItem := Default(THelpChatDataList);
    LItem.DataSet := ADataSet;
    LItem.Id := AId;
    if LItem.Id = '' then
      LItem.Id := HelpChatDataSetName(ADataSet);
    LItem.Caption := HelpChatDataSetName(ADataSet);
    Result := Result + [LItem];
  end;

var
  LBindings: TFmxBindings;
  LLink: TComponent;
  LControl: TObject;
  LAll: TList<TControl>;
  LItem: TControl;
  LFields: THelpChatDataFieldList;
  LField: THelpChatDataField;
begin
  Result := nil;
  // The grids and the lists a link fills with a data set...
  LBindings := TFmxBindings.Create(FRoot);
  try
    for LLink in LBindings.ListLinks do
    begin
      LControl := PropObj(LLink, 'GridControl');
      if LControl = nil then
        LControl := PropObj(LLink, 'Control');
      if (LControl is TControl) and IsUsable(TControl(LControl)) then
        AddList(TControl(LControl).Name, DataSetOfSource(PropObj(LLink, 'DataSource')));
    end;
  finally
    LBindings.Free;
  end;
  // ...the bind navigators and anything else showing a source...
  LAll := TList<TControl>.Create;
  try
    CollectInTabOrder(FRoot, LAll);
    for LItem in LAll do
      if IsUsable(LItem) and Assigned(DataSetOfSource(PropObj(LItem, 'DataSource'))) then
        AddList(LItem.Name, DataSetOfSource(PropObj(LItem, 'DataSource')));
  finally
    LAll.Free;
  end;
  // ...and the record of the form.
  LFields := Fields;
  try
    for LField in LFields do
      AddList('', LField.DataSet);
  finally
    LFields.Free;
  end;
end;

function TFmxScreen.Pages: TArray<THelpChatSkillPage>;
var
  LAll: TList<TControl>;
  LControl: TControl;
  LItem: TTabItem;
  LPage: THelpChatSkillPage;
begin
  Result := nil;
  LAll := TList<TControl>.Create;
  try
    CollectInTabOrder(FRoot, LAll);
    for LControl in LAll do
      if (LControl is TTabItem) and TabReachable(TTabItem(LControl), FRoot) then
      begin
        LItem := TTabItem(LControl);
        LPage := Default(THelpChatSkillPage);
        LPage.Control := LItem;
        LPage.Name := LItem.Name;
        LPage.Caption := HelpChatCleanCaption(LItem.Text);
        LPage.Path := TabPath(LItem, FRoot);
        LPage.Shown := (LItem.TabControl.ActiveTab = LItem) and IsShown(LItem.TabControl);
        Result := Result + [LPage];
      end;
  finally
    LAll.Free;
  end;
end;

function TFmxScreen.ActivatePage(const APage: THelpChatSkillPage): string;
var
  LChain: TList<TTabItem>;
  LObject: TFmxObject;
  LItem: TTabItem;
begin
  Result := '';
  // From the outermost tab in: an inner tab shows only when its tab does.
  LChain := TList<TTabItem>.Create;
  try
    LObject := TTabItem(APage.Control);
    while Assigned(LObject) and (LObject <> FRoot) do
    begin
      if LObject is TTabItem then
        LChain.Insert(0, TTabItem(LObject));
      LObject := LObject.Parent;
    end;
    for LItem in LChain do
      if LItem.TabControl.ActiveTab <> LItem then
      begin
        LItem.TabControl.ActiveTab := LItem; // fires OnChange, as a click does
        if LItem.TabControl.ActiveTab <> LItem then
          Exit(Format('The screen did not show the page "%s".', [HelpChatCleanCaption(LItem.Text)]));
      end;
  finally
    LChain.Free;
  end;
end;

function TFmxScreen.Commands: THelpChatSkillCommandList;
begin
  Result := THelpChatSkillCommandList.Create(True);
  CollectCommands(FRoot, Result, Sender);
end;

procedure TFmxScreen.Press(const ACommandId: string; const AQueued: Boolean);
var
  LRoot: TFmxObject;
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
      LForm: TFmxObject;
    begin
      LForm := LRoot;
      while Assigned(LForm) and not (LForm is TCommonCustomForm) do
        LForm := LForm.Parent;
      if not (LForm is TCommonCustomForm) or not IsAlive(TCommonCustomForm(LForm)) then
        Exit;
      LCommands := THelpChatSkillCommandList.Create(True);
      try
        CollectCommands(LRoot, LCommands, LSender);
        for LCommand in LCommands do
          if SameText(LCommand.Id, ACommandId) then
          begin
            TControlAccess(THelpChatFmxCommand(LCommand).Control).Click;
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

{ TFmxScreenProvider }

class function TFmxScreenProvider.Supports(const AHost: TComponent): Boolean;
begin
  Result := not Assigned(AHost) or AHost.QualifiedClassName.StartsWith('FMX.', True);
end;

class function TFmxScreenProvider.CreateScreen(const AHost: TComponent): THelpChatScreen;
var
  LTarget: TFmxObject;
begin
  LTarget := HelpChatFmxTarget(AHost);
  if Assigned(LTarget) then
    Result := TFmxScreen.Create(LTarget, AHost)
  else
    Result := nil;
end;

function HelpChatFmxScreen(const ARoot: TFmxObject; const ASender: TObject): THelpChatScreen;
begin
  if ARoot = nil then
    raise Exception.Create('No form is active: the user is not working on any screen of the application.');
  Result := TFmxScreen.Create(ARoot, ASender);
end;

initialization
  GOptions := THelpChatFmxSkillOptions.Create;
  GAdapters := TList<THelpChatFmxFieldAdapterClass>.Create;
  // Asked from the last: a combo edit is an edit too.
  RegisterHelpChatFmxFieldAdapter(TEditAdapter);
  RegisterHelpChatFmxFieldAdapter(TComboEditAdapter);
  RegisterHelpChatFmxFieldAdapter(TMemoAdapter);
  RegisterHelpChatFmxFieldAdapter(TComboAdapter);
  RegisterHelpChatFmxFieldAdapter(TCheckAdapter);
  RegisterHelpChatFmxFieldAdapter(TRadioAdapter);
  RegisterHelpChatFmxFieldAdapter(TDateAdapter);
  HelpChatRegisterScreenProvider(TFmxScreenProvider);
  // The form activated last: the one the user was on when the chat took the focus.
  GActivateId := TMessageManager.DefaultManager.SubscribeToMessage(TFormActivateMessage,
    procedure(const Sender: TObject; const M: TMessage)
    var
      LForm: TCommonCustomForm;
    begin
      LForm := TFormActivateMessage(M).Value;
      if IsEligibleForm(LForm) then
        GLastForm := LForm;
    end);

finalization
  TMessageManager.DefaultManager.Unsubscribe(TFormActivateMessage, GActivateId);
  HelpChatUnregisterScreenProvider(TFmxScreenProvider);
  FreeAndNil(GAdapters);
  FreeAndNil(GOptions);

end.
