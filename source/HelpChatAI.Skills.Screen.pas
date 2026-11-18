{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       The skills that work on the user's screen, for any framework: the      }
{       rules, the texts and the data sets; a framework gives the screen.      }
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
///  The four screen skills - <c>forms</c>, <c>commands</c>, <c>records</c>,
///  <c>pages</c> - written once. What they need from a framework is a
///  <see cref="THelpChatScreen" />: the form the user is working on, seen as
///  fields, lists, pages and buttons. A framework registers a
///  <see cref="THelpChatScreenProvider" /> that builds one for its component
///  (<c>Vcl.HelpChatAI.Skills</c>, <c>FMX.HelpChatAI.Skills</c>); everything
///  else - what the model is told, how a value is read, when a data set is put
///  in insert or edit, the rule that nothing is ever saved - is here, so that
///  the two frameworks behave and speak alike.
///  RTL and Data.DB only: no VCL, no FireMonkey.
/// </summary>
unit HelpChatAI.Skills.Screen;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  Data.DB,
  HelpChatAI.Messages, HelpChatAI.Actions, HelpChatAI.Skills;

type
  /// <summary>
  ///  One field of a screen, with what the data behind it says: the
  ///  <c>TField</c> of a data-aware control, where its lookup records are,
  ///  the values a choice or a check box stores. A framework descends from
  ///  it to keep the control and overrides <see cref="ReadValue" /> and
  ///  <see cref="WriteValue" /> for the plain controls; a field with a
  ///  <c>Field</c> is read and written here.
  /// </summary>
  THelpChatDataField = class(THelpChatSkillField)
  public
    /// <summary>The field of the data set behind the control; nil for a plain
    /// control.</summary>
    Field: TField;
    /// <summary>The data source starts the edit by itself (a VCL
    /// <c>TDataSource.AutoEdit</c>, a LiveBindings source): what mode
    /// <c>current</c> relies on. True by default.</summary>
    AutoEdit: Boolean;
    /// <summary>For a lookup: the data set its records are in.</summary>
    LookupDataSet: TDataSet;
    /// <summary>For a lookup: the field of that data set that holds the
    /// code.</summary>
    LookupKeyField: string;
    /// <summary>For a lookup: the field of that data set the user
    /// reads.</summary>
    LookupListField: string;
    /// <summary>The field the code of a lookup is written to.</summary>
    LookupTarget: TField;
    /// <summary>For a choice: the value each choice stores, when it is not
    /// its text (the <c>Values</c> of a <c>TDBRadioGroup</c>).</summary>
    ChoiceValues: TArray<string>;
    /// <summary>For a yes/no on a field that is not boolean: what checked
    /// and unchecked store ("Y;S", "N").</summary>
    CheckedValue: string;
    /// <summary>What unchecked stores: see <c>CheckedValue</c>.</summary>
    UncheckedValue: string;
    /// <summary>A field with <c>AutoEdit</c> on and nothing else set.</summary>
    constructor Create; virtual;
    /// <summary>The data set whose record holds the value; nil for a plain
    /// control.</summary>
    function DataSet: TDataSet; virtual;
    /// <summary>The value as text, empty when the field is: through the
    /// <c>Field</c> by default (<see cref="ReadDataValue" />).</summary>
    function ReadValue: string; virtual;
    /// <summary>Writes it; empty when done, else why not: through the
    /// <c>Field</c> by default (<see cref="WriteDataValue" />).</summary>
    function WriteValue(const AText: string; out AShown: string): string; virtual;
    /// <summary>The value of the <c>Field</c>, as the kind of the field reads
    /// it (a lookup with its description, a choice by its text).</summary>
    function ReadDataValue: string;
    /// <summary>Writes the <c>Field</c>, the record being already in insert
    /// or edit: a lookup by code or description, a choice by text or
    /// position, yes/no with the stored values of a check box.</summary>
    function WriteDataValue(const AText: string; out AShown: string): string;
    /// <summary>Puts the caret on the control, when the form is the active
    /// one.</summary>
    procedure Focus; virtual;
  end;

  THelpChatDataFieldList = TObjectList<THelpChatDataField>;

  /// <summary>A list of records of the screen: a grid, a navigator, the
  /// record of a form.</summary>
  THelpChatDataList = record
    /// <summary>What the model names the list by: the name of its control, else
    /// of its data set.</summary>
    Id: string;
    /// <summary>What the user reads for it.</summary>
    Caption: string;
    /// <summary>The records of the list.</summary>
    DataSet: TDataSet;
    /// <summary>The fields it is searched by (the visible columns); empty =
    /// the visible fields of the data set.</summary>
    SearchFields: TArray<TField>;
  end;

  /// <summary>One button of the screen.</summary>
  THelpChatSkillCommand = class
  public
    /// <summary>What the model names the button by.</summary>
    Id: string;
    /// <summary>What the user reads on it.</summary>
    Caption: string;
    /// <summary>Its hint, when it says more than the caption.</summary>
    Hint: string;
    /// <summary>Its keyboard shortcut as text ("Ctrl+N"), when it has
    /// one.</summary>
    ShortCut: string;
    /// <summary>What the skills take for a button that saves or confirms:
    /// not offered unless the application says otherwise.</summary>
    IsSave: Boolean;
  end;

  THelpChatSkillCommandList = TObjectList<THelpChatSkillCommand>;

  /// <summary>One page (tab) of the screen.</summary>
  THelpChatSkillPage = record
    /// <summary>What the model names the page by.</summary>
    Name: string;
    /// <summary>What the user reads on the tab.</summary>
    Caption: string;
    /// <summary>The captions from the outermost page in: "Notes > Private".</summary>
    Path: string;
    /// <summary>True for the page that is in front.</summary>
    Shown: Boolean;
    /// <summary>The control of the page, for the framework.</summary>
    Control: TObject;
  end;

  /// <summary>
  ///  The form the user is working on, as the skills see it, for the time of
  ///  one call. A framework implements it over its controls.
  /// </summary>
  THelpChatScreen = class abstract
  strict private
    FSender: TObject;
  public
    /// <summary>ASender is what the events of the framework receive: the
    /// assistant.</summary>
    constructor Create(const ASender: TObject);
    /// <summary>The caption of the form ("Customer").</summary>
    function Title: string; virtual; abstract;
    /// <summary>Its class name.</summary>
    function TypeName: string; virtual; abstract;
    /// <summary>What tells this form from another one: the previous values
    /// of what the assistant filled belong to one form.</summary>
    function Identity: string; virtual; abstract;
    /// <summary>The fields, in the order of the form. The caller frees the
    /// list.</summary>
    function Fields: THelpChatDataFieldList; virtual; abstract;
    /// <summary>The lists of records the form shows (grids, list views).</summary>
    function Lists: TArray<THelpChatDataList>; virtual; abstract;
    /// <summary>The pages of the form (tab sheets), shown or not.</summary>
    function Pages: TArray<THelpChatSkillPage>; virtual; abstract;
    /// <summary>Shows a page as a click on its tab: empty when shown, else
    /// why not.</summary>
    function ActivatePage(const APage: THelpChatSkillPage): string; virtual; abstract;
    /// <summary>The buttons the assistant may press (the saves already left
    /// out). The caller frees the list.</summary>
    function Commands: THelpChatSkillCommandList; virtual; abstract;
    /// <summary>Presses the button of that id; with <c>AQueued</c> right
    /// after the action answered.</summary>
    procedure Press(const ACommandId: string; const AQueued: Boolean); virtual; abstract;
    /// <summary>What the events of the framework receive as Sender.</summary>
    property Sender: TObject read FSender;
  end;

  /// <summary>What a framework registers: whether it serves an assistant,
  /// and the screen it is working on (nil when there is none).</summary>
  THelpChatScreenProvider = class abstract
  public
    /// <summary>True for an assistant of this framework.</summary>
    class function Supports(const AHost: TComponent): Boolean; virtual; abstract;
    /// <summary>The screen that assistant is working on; nil when there is
    /// none. The caller frees it.</summary>
    class function CreateScreen(const AHost: TComponent): THelpChatScreen; virtual; abstract;
  end;

  THelpChatScreenProviderClass = class of THelpChatScreenProvider;

/// <summary>What a framework unit calls in its initialization.</summary>
procedure HelpChatRegisterScreenProvider(const AProvider: THelpChatScreenProviderClass);
/// <summary>And in its finalization.</summary>
procedure HelpChatUnregisterScreenProvider(const AProvider: THelpChatScreenProviderClass);
/// <summary>The provider that serves that assistant (the first registered
/// when AHost is nil); nil when none.</summary>
function HelpChatScreenProviderFor(const AHost: TComponent): THelpChatScreenProviderClass;

{ The data behind a field }

/// <summary>The kind of field the model is told a <c>TField</c> is.</summary>
function HelpChatFieldKindOf(const AField: TField): THelpChatFieldKind;
/// <summary>What the TField says of a field: kind, size, required, key,
/// read-only, and the records of a lookup field.</summary>
procedure HelpChatDescribeDataField(const AItem: THelpChatDataField; const AField: TField);
/// <summary>True for a data set in edit or insert.</summary>
function HelpChatIsEditing(const ADataSet: TDataSet): Boolean;
/// <summary>The name a data set is called by in what the model reads.</summary>
function HelpChatDataSetName(const ADataSet: TDataSet): string;
/// <summary>"browsing the record shown", "inserting a new record, not saved
/// yet"...</summary>
function HelpChatDataSetState(const ADataSet: TDataSet): string;
/// <summary>Lists the values of a lookup in its Choices, when they are few
/// enough (<c>HELPCHAT_SKILL_MAX_CHOICES</c>).</summary>
procedure HelpChatFillLookupChoices(const AField: THelpChatDataField);
/// <summary>Makes a data set editable as the mode says; empty when it is,
/// else why not. Never posts: an insert asked while a record is in edit is
/// refused.</summary>
function HelpChatEnterEditing(const ADataSet: TDataSet; const AAutoEdit: Boolean;
  const AMode: THelpChatFillMode): string;

{ What the actions do, on any screen. They answer with the text the model
  reads; the ones that cannot do anything raise, with the reason. }

/// <summary><c>describe_form</c>.</summary>
function HelpChatScreenDescribe(const AScreen: THelpChatScreen; const AHideValues: Boolean): string;
/// <summary><c>fill_form</c>. Never posts; <c>ASnapshot</c> receives what
/// the fields held before.</summary>
function HelpChatScreenFill(const AScreen: THelpChatScreen; const AValues: TJSONObject;
  const AMode: THelpChatFillMode; const AHideValues: Boolean;
  const ASnapshot: TDictionary<string, string>): string;
/// <summary><c>cancel_edit</c>.</summary>
function HelpChatScreenCancel(const AScreen: THelpChatScreen;
  const ASnapshot: TDictionary<string, string>): string;
/// <summary><c>find_choice</c>.</summary>
function HelpChatScreenFindChoice(const AScreen: THelpChatScreen; const AFieldId, AText: string): string;
/// <summary><c>list_commands</c>.</summary>
function HelpChatScreenListCommands(const AScreen: THelpChatScreen): string;
/// <summary><c>press_command</c>.</summary>
function HelpChatScreenPress(const AScreen: THelpChatScreen; const ACommand: string;
  const AQueued: Boolean): string;
/// <summary><c>count_records</c>.</summary>
function HelpChatScreenCount(const AScreen: THelpChatScreen; const AList: string): string;
/// <summary><c>find_record</c>. Refused while the list, or a detail of it,
/// is being edited: moving would save.</summary>
function HelpChatScreenFindRecord(const AScreen: THelpChatScreen; const AText, AField, AList: string;
  const AHideValues: Boolean): string;
/// <summary><c>list_pages</c>.</summary>
function HelpChatScreenPagesText(const AScreen: THelpChatScreen): string;
/// <summary><c>show_page</c>.</summary>
function HelpChatScreenShowPage(const AScreen: THelpChatScreen; const APage: string): string;

/// <summary>A caption or a name that saves or confirms (Save, OK, Salva,
/// Speichern...).</summary>
function HelpChatLooksLikeSave(const ACaption, AName: string): Boolean;
/// <summary>The field of that id, data field or caption; nil when none.</summary>
function HelpChatFindScreenField(const AFields: THelpChatDataFieldList;
  const AKey: string): THelpChatDataField;
/// <summary>The button of that id, caption, or the only caption containing
/// the text; nil when none or several.</summary>
function HelpChatFindScreenCommand(const ACommands: THelpChatSkillCommandList;
  const AText: string): THelpChatSkillCommand;

var
  /// <summary>The model is told whether a field is filled, never its value,
  /// in every framework: for an application whose data must not leave the
  /// machine. A password is never read anyway.</summary>
  HelpChatSkillsHideFieldValues: Boolean = False;

implementation

uses
  System.StrUtils, System.Math, System.Variants;

const
  MSG_NO_FORM = 'No form is active: the user is not working on any screen of the application.';
  // A lookup table is scanned at most this far: past it, find_choice.
  LOOKUP_SCAN_MAX = 5000;
  FIND_CHOICE_MAX = 20;

var
  GProviders: TList<THelpChatScreenProviderClass>;

{ providers }

procedure HelpChatRegisterScreenProvider(const AProvider: THelpChatScreenProviderClass);
begin
  if Assigned(AProvider) and not GProviders.Contains(AProvider) then
    GProviders.Add(AProvider);
end;

procedure HelpChatUnregisterScreenProvider(const AProvider: THelpChatScreenProviderClass);
begin
  if Assigned(GProviders) then
    GProviders.Remove(AProvider);
end;

function HelpChatScreenProviderFor(const AHost: TComponent): THelpChatScreenProviderClass;
var
  LProvider: THelpChatScreenProviderClass;
begin
  for LProvider in GProviders do
    if LProvider.Supports(AHost) then
      Exit(LProvider);
  Result := nil;
end;

{ THelpChatScreen }

constructor THelpChatScreen.Create(const ASender: TObject);
begin
  inherited Create;
  FSender := ASender;
end;

{ data helpers }

function HelpChatFieldKindOf(const AField: TField): THelpChatFieldKind;
begin
  case AField.DataType of
    ftString, ftWideString, ftFixedChar, ftFixedWideChar, ftGuid:
      Result := hfkText;
    ftMemo, ftWideMemo, ftFmtMemo:
      Result := hfkMemo;
    ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc, ftShortint, ftByte, ftLongWord:
      Result := hfkInteger;
    ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle:
      Result := hfkNumber;
    ftDate:
      Result := hfkDate;
    ftDateTime, ftTimeStamp:
      Result := hfkDateTime;
    ftTime:
      Result := hfkTime;
    ftBoolean:
      Result := hfkBoolean;
  else
    Result := hfkOther; // blobs, graphics, arrays...
  end;
end;

function HelpChatIsEditing(const ADataSet: TDataSet): Boolean;
begin
  Result := Assigned(ADataSet) and (ADataSet.State in dsEditModes);
end;

/// <summary>The detail data set of ADataSet that is in edit or insert, at
/// any depth; nil when none is.</summary>
function EditingDetailOf(const ADataSet: TDataSet; const ADepth: Integer): TDataSet;
var
  LDetails: TList<TDataSet>;
  LDetail: TDataSet;
begin
  Result := nil;
  if (ADataSet = nil) or (ADepth > 8) then
    Exit;
  LDetails := TList<TDataSet>.Create;
  try
    ADataSet.GetDetailDataSets(LDetails);
    for LDetail in LDetails do
    begin
      if HelpChatIsEditing(LDetail) then
        Exit(LDetail);
      Result := EditingDetailOf(LDetail, ADepth + 1);
      if Result <> nil then
        Exit;
    end;
  finally
    LDetails.Free;
  end;
end;

function HelpChatDataSetName(const ADataSet: TDataSet): string;
begin
  Result := ADataSet.Name;
  if Result = '' then
    Result := ADataSet.ClassName;
end;

function HelpChatDataSetState(const ADataSet: TDataSet): string;
begin
  if not ADataSet.Active then
    Result := 'not open'
  else
    case ADataSet.State of
      dsInsert: Result := 'inserting a new record, not saved yet';
      dsEdit: Result := 'editing the record shown, not saved yet';
    else
      if ADataSet.IsEmpty then
        Result := 'browsing, no record'
      else
        Result := 'browsing the record shown';
    end;
end;

procedure HelpChatDescribeDataField(const AItem: THelpChatDataField; const AField: TField);
var
  LTarget: TField;
begin
  AItem.Field := AField;
  AItem.DataField := AField.FieldName;
  AItem.Kind := HelpChatFieldKindOf(AField);
  LTarget := AField;
  if AField.FieldKind = fkLookup then
  begin
    // A lookup field: the code goes to its key field, the records are its own.
    AItem.Kind := hfkLookup;
    AItem.LookupDataSet := AField.LookupDataSet;
    AItem.LookupKeyField := AField.LookupKeyFields;
    AItem.LookupListField := AField.LookupResultField;
    LTarget := AField.DataSet.FindField(AField.KeyFields);
    if (LTarget = nil) or (Pos(';', AField.KeyFields) > 0) or (AItem.LookupDataSet = nil) then
      AItem.Kind := hfkOther;
  end;
  AItem.LookupTarget := LTarget;
  if (AField is TStringField) or (AField is TWideStringField) then
    AItem.MaxLength := AField.Size;
  AItem.Required := Assigned(LTarget) and LTarget.Required;
  AItem.Key := Assigned(LTarget) and (pfInKey in LTarget.ProviderFlags);
  AItem.ReadOnly := AField.ReadOnly or (Assigned(LTarget) and LTarget.ReadOnly) or
    (AField.FieldKind in [fkCalculated, fkInternalCalc, fkAggregate]) or
    not AField.DataSet.Active or not AField.DataSet.CanModify;
end;

function FieldText(const AField: TField; const AKind: THelpChatFieldKind): string;
begin
  if (AField = nil) or AField.IsNull then
    Exit('');
  case AKind of
    hfkDate, hfkDateTime, hfkTime:
      Result := HelpChatFormatDateTime(AField.AsDateTime, AKind);
    hfkNumber:
      Result := HelpChatFormatNumber(AField.AsFloat);
    hfkBoolean:
      Result := IfThen(AField.AsBoolean, 'true', 'false');
  else
    Result := AField.AsString;
  end;
end;

function WriteFieldText(const AField: TField; const AKind: THelpChatFieldKind;
  const AText: string; const AMaxLength: Integer): string;
var
  LText: string;
  LInteger: Int64;
  LNumber: Double;
  LDate: TDateTime;
  LBoolean: Boolean;
begin
  Result := '';
  LText := Trim(AText);
  case AKind of
    hfkText, hfkMemo:
      begin
        if (AKind = hfkText) and (AMaxLength > 0) and (LText.Length > AMaxLength) then
          Exit(Format('too long: %d characters, the maximum is %d', [LText.Length, AMaxLength]));
        AField.AsString := IfThen(AKind = hfkMemo, AText, LText);
      end;
    hfkInteger:
      if TryStrToInt64(LText, LInteger) then
        AField.AsLargeInt := LInteger
      else
        Exit(Format('"%s" is not an integer number', [LText]));
    hfkNumber:
      if HelpChatParseNumber(LText, LNumber) then
        AField.AsFloat := LNumber
      else
        Exit(Format('"%s" is not a number', [LText]));
    hfkDate, hfkDateTime, hfkTime:
      if HelpChatParseDateTime(LText, AKind, LDate) then
        AField.AsDateTime := LDate
      else
        Exit(Format('"%s" is not a valid date/time (use YYYY-MM-DD, HH:MM)', [LText]));
    hfkBoolean:
      if HelpChatParseBoolean(LText, LBoolean) then
        AField.AsBoolean := LBoolean
      else
        Exit(Format('"%s" is not yes/no', [LText]));
  else
    Exit('this field cannot be filled by the assistant');
  end;
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

// The index of a choice: its text, else - for a list of fixed values - its
// position.
function ChoiceIndex(const AChoices: TArray<string>; const AText: string): Integer;
var
  LIndex: Integer;
begin
  Result := HelpChatMatchChoice(AChoices, AText);
  if (Result < 0) and TryStrToInt(Trim(AText), LIndex) and (LIndex >= 0) and
    (LIndex <= High(AChoices)) then
    Result := LIndex;
end;

function NotAllowed(const AField: THelpChatDataField; const AText: string): string;
begin
  Result := Format('"%s" is not allowed: %s', [AText, AField.TypeText]);
end;

{ lookups }

type
  TLookupMatch = record
    Key: Variant;
    Code: string;
    Text: string;
  end;

function ScanLookup(const AField: THelpChatDataField; const AText: string;
  out AExactKey: TArray<TLookupMatch>; out AExactText: TArray<TLookupMatch>;
  out AContaining: TArray<TLookupMatch>; const AMaxContaining: Integer): string;
var
  LDataSet: TDataSet;
  LKey, LList: TField;
  LBookmark: TBookmark;
  LMatch: TLookupMatch;
  LScanned: Integer;
begin
  Result := '';
  AExactKey := nil;
  AExactText := nil;
  AContaining := nil;
  LDataSet := AField.LookupDataSet;
  if (LDataSet = nil) or not LDataSet.Active then
    Exit('the list of the values of this field is not open');
  LKey := LDataSet.FindField(AField.LookupKeyField);
  LList := LDataSet.FindField(AField.LookupListField);
  if (LKey = nil) or (LList = nil) then
    Exit('the list of the values of this field cannot be read');
  // Walking it would save it: First posts a record being edited (or drops
  // one nobody changed), and the lookup table may be open for editing on
  // this screen or on another. Reading must never do that.
  if HelpChatIsEditing(LDataSet) then
    Exit('the list of the values of this field is being edited: it can be read once that is saved or cancelled');
  // The cursor goes back where it was: the lookup table may be shown too.
  LDataSet.DisableControls;
  try
    LBookmark := LDataSet.GetBookmark;
    try
      LDataSet.First;
      LScanned := 0;
      while not LDataSet.Eof and (LScanned < LOOKUP_SCAN_MAX) do
      begin
        LMatch.Key := LKey.Value;
        LMatch.Code := LKey.AsString;
        LMatch.Text := LList.AsString;
        if SameText(LMatch.Code, Trim(AText)) then
          AExactKey := AExactKey + [LMatch]
        else if SameText(LMatch.Text, Trim(AText)) then
          AExactText := AExactText + [LMatch]
        else if (Trim(AText) = '') or ContainsText(LMatch.Text, Trim(AText)) then
        begin
          if Length(AContaining) < AMaxContaining then
            AContaining := AContaining + [LMatch];
        end;
        Inc(LScanned);
        LDataSet.Next;
      end;
      if LDataSet.BookmarkValid(LBookmark) then
        LDataSet.GotoBookmark(LBookmark);
    finally
      LDataSet.FreeBookmark(LBookmark);
    end;
  finally
    LDataSet.EnableControls;
  end;
end;

function MatchesText(const AMatches: TArray<TLookupMatch>; const AMax: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Min(High(AMatches), AMax - 1) do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + Format('%s (%s)', [AMatches[I].Code, AMatches[I].Text]);
  end;
end;

function ResolveLookup(const AField: THelpChatDataField; const AText: string;
  out AMatch: TLookupMatch): string;
var
  LExactKey, LExactText, LContaining: TArray<TLookupMatch>;
begin
  Result := ScanLookup(AField, AText, LExactKey, LExactText, LContaining, 11);
  if Result <> '' then
    Exit;
  if Length(LExactKey) = 1 then
    AMatch := LExactKey[0]
  else if Length(LExactText) = 1 then
    AMatch := LExactText[0]
  else if Length(LExactKey) + Length(LExactText) > 1 then
    Exit(Format('"%s" matches more than one record: %s. Ask the user which one, then ' +
      'fill the field with its code', [AText, MatchesText(LExactKey + LExactText, 10)]))
  else if Length(LContaining) = 1 then
    AMatch := LContaining[0]
  else if Length(LContaining) > 1 then
    Exit(Format('"%s" matches more than one record: %s. Ask the user which one, then ' +
      'fill the field with its code', [AText, MatchesText(LContaining, 10)]))
  else
    Exit(Format('"%s" was not found among the values of this field: find_choice ' +
      'searches them by part of the description', [AText]));
end;

function LookupDisplay(const AField: THelpChatDataField; const AKey: Variant): string;
var
  LValue: Variant;
begin
  Result := '';
  if (AField.LookupDataSet = nil) or not AField.LookupDataSet.Active or VarIsNull(AKey) then
    Exit;
  // Lookup is a read, but not for every data set: FireDAC's leaves edit
  // mode first (CheckBrowseMode), which posts the record somebody is editing
  // in the lookup table. Then the code alone is shown.
  if HelpChatIsEditing(AField.LookupDataSet) then
    Exit;
  try
    LValue := AField.LookupDataSet.Lookup(AField.LookupKeyField, AKey, AField.LookupListField);
    if not VarIsNull(LValue) and not VarIsEmpty(LValue) then
      Result := VarToStr(LValue);
  except
    Result := '';
  end;
end;

procedure HelpChatFillLookupChoices(const AField: THelpChatDataField);
var
  LExactKey, LExactText, LAll: TArray<TLookupMatch>;
  I: Integer;
begin
  AField.Choices := nil;
  if (AField.LookupDataSet = nil) or not AField.LookupDataSet.Active or
    (AField.LookupDataSet.RecordCount > HELPCHAT_SKILL_MAX_CHOICES) then
    Exit;
  if ScanLookup(AField, '', LExactKey, LExactText, LAll, HELPCHAT_SKILL_MAX_CHOICES) <> '' then
    Exit;
  SetLength(AField.Choices, Length(LAll));
  for I := 0 to High(LAll) do
    AField.Choices[I] := Format('%s = %s', [LAll[I].Code, LAll[I].Text]);
end;

{ THelpChatDataField }

constructor THelpChatDataField.Create;
begin
  inherited Create;
  AutoEdit := True;
end;

function THelpChatDataField.DataSet: TDataSet;
begin
  if Assigned(Field) then
    Result := Field.DataSet
  else
    Result := nil;
end;

procedure THelpChatDataField.Focus;
begin
end;

function THelpChatDataField.ReadValue: string;
begin
  Result := ReadDataValue;
end;

function THelpChatDataField.WriteValue(const AText: string; out AShown: string): string;
begin
  Result := WriteDataValue(AText, AShown);
end;

function THelpChatDataField.ReadDataValue: string;
var
  LIndex: Integer;
begin
  Result := '';
  if (Field = nil) or not Field.DataSet.Active then
    Exit;
  case Kind of
    hfkLookup:
      if Assigned(LookupTarget) and not LookupTarget.IsNull then
      begin
        Result := LookupTarget.AsString;
        if Field.FieldKind = fkLookup then
        begin
          if Field.AsString <> '' then
            Result := Result + ' (' + Field.AsString + ')';
        end
        else if LookupDisplay(Self, LookupTarget.Value) <> '' then
          Result := Result + ' (' + LookupDisplay(Self, LookupTarget.Value) + ')';
      end;
    hfkBoolean:
      if Field.IsNull then
        Result := ''
      else if CheckedValue <> '' then
        Result := IfThen(MatchText(Field.AsString, CheckedValue.Split([';'])), 'true', 'false')
      else
        Result := FieldText(Field, hfkBoolean);
    hfkChoice:
      begin
        if Length(ChoiceValues) > 0 then
          LIndex := IndexText(Field.AsString, ChoiceValues)
        else
          LIndex := IndexText(Field.AsString, Choices);
        if (LIndex >= 0) and (LIndex <= High(Choices)) then
          Result := Choices[LIndex]
        else
          Result := Field.AsString;
      end;
  else
    Result := FieldText(Field, Kind);
  end;
end;

function THelpChatDataField.WriteDataValue(const AText: string; out AShown: string): string;
var
  LMatch: TLookupMatch;
  LIndex: Integer;
  LBoolean: Boolean;
begin
  Result := '';
  AShown := AText;
  if Field = nil then
    Exit('this field cannot be filled by the assistant');
  if not HelpChatIsEditing(Field.DataSet) then
    Exit('the record is not being edited');
  if Trim(AText) = '' then
  begin
    if Assigned(LookupTarget) then
      LookupTarget.Clear
    else
      Field.Clear;
    AShown := '(empty)';
    Exit;
  end;
  case Kind of
    hfkLookup:
      begin
        Result := ResolveLookup(Self, AText, LMatch);
        if Result <> '' then
          Exit;
        LookupTarget.Value := LMatch.Key;
        AShown := Format('%s (%s)', [LMatch.Code, LMatch.Text]);
      end;
    hfkBoolean:
      begin
        if not HelpChatParseBoolean(AText, LBoolean) then
          Exit(Format('"%s" is not yes/no', [AText]));
        if (CheckedValue <> '') and not (Field is TBooleanField) then
          Field.AsString := FirstToken(IfThen(LBoolean, CheckedValue, UncheckedValue))
        else
          Field.AsBoolean := LBoolean;
        AShown := IfThen(LBoolean, 'true', 'false');
      end;
    hfkChoice:
      begin
        LIndex := ChoiceIndex(Choices, AText);
        if LIndex >= 0 then
        begin
          if LIndex <= High(ChoiceValues) then
            Field.AsString := ChoiceValues[LIndex]
          else
            Field.AsString := Choices[LIndex];
          AShown := Choices[LIndex];
        end
        else if ChoicesOnly then
          Exit(NotAllowed(Self, AText))
        else
          Field.AsString := Trim(AText);
      end;
  else
    Result := WriteFieldText(Field, Kind, AText, MaxLength);
  end;
end;

{ editing }

function HelpChatEnterEditing(const ADataSet: TDataSet; const AAutoEdit: Boolean;
  const AMode: THelpChatFillMode): string;
begin
  Result := '';
  if not ADataSet.Active then
    Exit(Format('%s has no data open', [HelpChatDataSetName(ADataSet)]));
  if not ADataSet.CanModify then
    Exit(Format('the data of %s cannot be modified', [HelpChatDataSetName(ADataSet)]));
  try
    case AMode of
      hfmInsert:
        if ADataSet.State = dsEdit then
          // Insert would post the record being edited: that is saving.
          Exit('the form is editing an existing record, not a new one: the user saves it, ' +
            'or cancel_edit abandons it, before inserting')
        else if ADataSet.State <> dsInsert then
          ADataSet.Insert;
      hfmEdit:
        if not HelpChatIsEditing(ADataSet) then
        begin
          if ADataSet.IsEmpty then
            Exit('there is no record to edit: use mode=insert to add one');
          ADataSet.Edit;
        end;
    else
      if not HelpChatIsEditing(ADataSet) then
      begin
        if not AAutoEdit then
          Exit('the form is not editing and does not start by itself: mode=insert adds a ' +
            'new record, mode=edit changes the record shown');
        if ADataSet.IsEmpty then
          ADataSet.Insert
        else
          ADataSet.Edit;
      end;
    end;
  except
    on E: Exception do
      Exit(E.Message);
  end;
end;

{ fields, commands, lists }

function HelpChatFindScreenField(const AFields: THelpChatDataFieldList;
  const AKey: string): THelpChatDataField;
var
  LField: THelpChatDataField;
begin
  // The id, the data field, the caption.
  for LField in AFields do
    if SameText(LField.Id, Trim(AKey)) then
      Exit(LField);
  for LField in AFields do
    if (LField.DataField <> '') and SameText(LField.DataField, Trim(AKey)) then
      Exit(LField);
  for LField in AFields do
    if SameText(LField.Caption, HelpChatCleanCaption(AKey)) then
      Exit(LField);
  Result := nil;
end;

function ContainsDataSet(const ADataSets: TArray<TDataSet>; const ADataSet: TDataSet): Boolean;
var
  LDataSet: TDataSet;
begin
  for LDataSet in ADataSets do
    if LDataSet = ADataSet then
      Exit(True);
  Result := False;
end;

function DataSetsOf(const AFields: THelpChatDataFieldList): TArray<TDataSet>;
var
  LField: THelpChatDataField;
begin
  Result := nil;
  for LField in AFields do
    if (LField.DataSet <> nil) and not ContainsDataSet(Result, LField.DataSet) then
      Result := Result + [LField.DataSet];
end;

function RecordCountText(const ADataSet: TDataSet): string;
begin
  if not ADataSet.Active then
    Exit('not open');
  if ADataSet.RecordCount >= 0 then
    Result := Format('%d record(s)', [ADataSet.RecordCount])
  else
    Result := 'an unknown number of records';
  if ADataSet.Filtered and (Trim(ADataSet.Filter) <> '') then
    Result := Result + Format(', filtered by: %s', [ADataSet.Filter]);
end;

function ListsText(const ALists: TArray<THelpChatDataList>): string;
var
  LItem: THelpChatDataList;
begin
  Result := '';
  for LItem in ALists do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + Format('%s (%s: %s)', [LItem.Id, LItem.Caption, RecordCountText(LItem.DataSet)]);
  end;
end;

function CheckScreen(const AScreen: THelpChatScreen): THelpChatScreen;
begin
  if AScreen = nil then
    raise Exception.Create(MSG_NO_FORM);
  Result := AScreen;
end;

{ describe and fill }

function HelpChatScreenPagesText(const AScreen: THelpChatScreen): string;
var
  LPage: THelpChatSkillPage;
begin
  Result := '';
  for LPage in CheckScreen(AScreen).Pages do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + '"' + LPage.Path + '"' + IfThen(LPage.Shown, ' (shown)');
  end;
end;

function HelpChatScreenDescribe(const AScreen: THelpChatScreen; const AHideValues: Boolean): string;
var
  LFields: THelpChatDataFieldList;
  LField: THelpChatDataField;
  LText: TStringBuilder;
  LDataSet: TDataSet;
  LDataSets: TArray<TDataSet>;
  LPages, LLists: string;
begin
  LPages := HelpChatScreenPagesText(AScreen);
  LFields := AScreen.Fields;
  LText := TStringBuilder.Create;
  try
    if LFields.Count = 0 then
      raise Exception.CreateFmt('The screen "%s" has no data-entry fields%s.',
        [AScreen.Title, IfThen(LPages <> '',
          Format(' on the page shown (its pages: %s; show_page shows another)', [LPages]))]);
    LText.AppendFormat('Form: %s (%s)', [AScreen.Title, AScreen.TypeName]).AppendLine;
    LDataSets := DataSetsOf(LFields);
    if Length(LDataSets) = 0 then
      LText.AppendLine('State: plain fields, no record: what is written stays on the screen ' +
        'until the user confirms it.')
    else
      for LDataSet in LDataSets do
        LText.AppendFormat('State of %s: %s.', [HelpChatDataSetName(LDataSet),
          HelpChatDataSetState(LDataSet)]).AppendLine;
    LText.AppendLine('Fields (id | label | type | flags | current value), then the full description:');
    for LField in LFields do
      LText.AppendLine(LField.DescribeLines(AHideValues));
    if LPages <> '' then
      LText.AppendFormat('Pages: %s. Only the fields of the pages shown are listed: show_page ' +
        'shows another one.', [LPages]).AppendLine;
    LLists := ListsText(AScreen.Lists);
    if LLists <> '' then
      LText.AppendFormat('Lists: %s.', [LLists]).AppendLine;
    LText.AppendLine('When the user gives values without naming the fields, they follow the ' +
      'order of the fields above.');
    LText.Append('fill_form fills them: it asks the user to confirm the values and never ' +
      'saves - the user reviews and saves.');
    Result := LText.ToString;
  finally
    LText.Free;
    LFields.Free;
  end;
end;

function HelpChatScreenFill(const AScreen: THelpChatScreen; const AValues: TJSONObject;
  const AMode: THelpChatFillMode; const AHideValues: Boolean;
  const ASnapshot: TDictionary<string, string>): string;
var
  LFields: THelpChatDataFieldList;
  LField, LFirstError, LFirstDone: THelpChatDataField;
  LPair: TJSONPair;
  LText: TStringBuilder;
  LDataSets: TArray<TDataSet>;
  LError, LShown, LMissing: string;
  LDone, LFailed: Integer;
begin
  CheckScreen(AScreen);
  if (AValues = nil) or (AValues.Count = 0) then
    raise Exception.Create('No values: pass "values" as a JSON object {"field id": "value"} ' +
      '(see describe_form).');
  LFields := AScreen.Fields;
  LText := TStringBuilder.Create;
  try
    if LFields.Count = 0 then
      raise Exception.CreateFmt('The screen "%s" has no data-entry fields.', [AScreen.Title]);
    // The records the values go to, made editable first.
    LDataSets := nil;
    for LPair in AValues do
    begin
      LField := HelpChatFindScreenField(LFields, LPair.JsonString.Value);
      if Assigned(LField) and (LField.DataSet <> nil) and
        not ContainsDataSet(LDataSets, LField.DataSet) then
      begin
        LError := HelpChatEnterEditing(LField.DataSet, LField.AutoEdit, AMode);
        if LError <> '' then
          raise Exception.Create('Cannot fill the form: ' + LError + '.');
        LDataSets := LDataSets + [LField.DataSet];
      end;
    end;

    LDone := 0;
    LFailed := 0;
    LFirstError := nil;
    LFirstDone := nil;
    for LPair in AValues do
    begin
      LField := HelpChatFindScreenField(LFields, LPair.JsonString.Value);
      if LField = nil then
      begin
        Inc(LFailed);
        LText.AppendFormat('- %s: unknown field (use the ids of describe_form)',
          [LPair.JsonString.Value]).AppendLine;
        Continue;
      end;
      if LField.ReadOnly or (LField.Kind = hfkOther) then
        LError := 'read-only field'
      else
      begin
        if Assigned(ASnapshot) and (LField.DataSet = nil) and not ASnapshot.ContainsKey(LField.Id) then
          ASnapshot.Add(LField.Id, LField.ReadValue);
        try
          LError := LField.WriteValue(HelpChatJsonValueText(LPair.JsonValue), LShown);
        except
          on E: Exception do
            LError := E.Message; // a validation of the field, an event of the form
        end;
      end;
      if LError = '' then
      begin
        Inc(LDone);
        if LFirstDone = nil then
          LFirstDone := LField;
        if AHideValues or LField.Secret then
          LText.AppendFormat('- %s (%s): set', [LField.Caption, LField.Id]).AppendLine
        else
          LText.AppendFormat('- %s (%s): set to %s', [LField.Caption, LField.Id,
            HelpChatSkillCut(LShown)]).AppendLine;
      end
      else
      begin
        Inc(LFailed);
        if LFirstError = nil then
          LFirstError := LField;
        LText.AppendFormat('- %s (%s): NOT set, %s', [LField.Caption, LField.Id, LError]).AppendLine;
      end;
    end;

    LMissing := '';
    for LField in LFields do
      if not LField.ReadOnly and LField.Required and (LField.ReadValue = '') then
        LMissing := LMissing + IfThen(LMissing <> '', ', ') +
          Format('%s (%s)', [LField.Caption, LField.Id]);

    // The caret goes where the user has something to do: the first field
    // that was refused, else the first one filled.
    try
      if Assigned(LFirstError) then
        LFirstError.Focus
      else if Assigned(LFirstDone) then
        LFirstDone.Focus;
    except
      // a form that refuses the focus is not a reason to fail the fill
    end;

    if Length(LDataSets) > 0 then
      Result := Format('%s: %d field(s) set, %d not set. Nothing was saved: the form is %s; ' +
        'the user reviews the values and saves (cancel_edit abandons them).',
        [AScreen.Title, LDone, LFailed, HelpChatDataSetState(LDataSets[0])])
    else
      Result := Format('%s: %d field(s) set, %d not set. Nothing was confirmed: the user ' +
        'reviews the values on the screen (cancel_edit puts the previous ones back).',
        [AScreen.Title, LDone, LFailed]);
    Result := Result + sLineBreak + LText.ToString;
    if LMissing <> '' then
      Result := Result + 'Required fields still empty: ' + LMissing + '.';
  finally
    LText.Free;
    LFields.Free;
  end;
end;

function HelpChatScreenCancel(const AScreen: THelpChatScreen;
  const ASnapshot: TDictionary<string, string>): string;
var
  LFields: THelpChatDataFieldList;
  LField: THelpChatDataField;
  LDataSet: TDataSet;
  LOld, LShown, LDone: string;
  LRestored: Integer;
begin
  CheckScreen(AScreen);
  LDone := '';
  LRestored := 0;
  LFields := AScreen.Fields;
  try
    for LDataSet in DataSetsOf(LFields) do
      if HelpChatIsEditing(LDataSet) then
      begin
        LDone := LDone + IfThen(LDone <> '', ', ') +
          IfThen(LDataSet.State = dsInsert, 'the new record of ', 'the changes to ') +
          HelpChatDataSetName(LDataSet);
        LDataSet.Cancel;
      end;
    if Assigned(ASnapshot) then
    begin
      for LField in LFields do
        if ASnapshot.TryGetValue(LField.Id, LOld) and (LField.DataSet = nil) then
          if LField.WriteValue(LOld, LShown) = '' then
            Inc(LRestored);
      ASnapshot.Clear;
    end;
  finally
    LFields.Free;
  end;
  if LRestored > 0 then
    LDone := LDone + IfThen(LDone <> '', '; ') +
      Format('%d field(s) filled by the assistant got their previous value back', [LRestored]);
  if LDone = '' then
    Result := Format('Nothing to cancel on "%s": no record is being edited and the assistant ' +
      'filled nothing.', [AScreen.Title])
  else
    Result := Format('Abandoned on "%s": %s.', [AScreen.Title, LDone]);
end;

function HelpChatScreenFindChoice(const AScreen: THelpChatScreen; const AFieldId, AText: string): string;
var
  LFields: THelpChatDataFieldList;
  LField: THelpChatDataField;
  LExactKey, LExactText, LContaining, LAll: TArray<TLookupMatch>;
  LError: string;
  I: Integer;
begin
  CheckScreen(AScreen);
  LFields := AScreen.Fields;
  try
    LField := HelpChatFindScreenField(LFields, AFieldId);
    if LField = nil then
      raise Exception.CreateFmt('The form has no field "%s" (use the ids of describe_form).', [AFieldId]);
    if LField.Kind = hfkLookup then
    begin
      LError := ScanLookup(LField, AText, LExactKey, LExactText, LContaining, FIND_CHOICE_MAX);
      if LError <> '' then
        raise Exception.Create(LError + '.');
      LAll := LExactKey + LExactText + LContaining;
      if Length(LAll) = 0 then
        Exit(Format('No value of "%s" matches "%s".', [LField.Caption, AText]));
      Result := Format('Values of "%s" matching "%s" (code = description):', [LField.Caption, AText]);
      for I := 0 to Min(High(LAll), FIND_CHOICE_MAX - 1) do
        Result := Result + sLineBreak + Format('- %s = %s', [LAll[I].Code, LAll[I].Text]);
      if Length(LAll) >= FIND_CHOICE_MAX then
        Result := Result + sLineBreak + 'There may be more: ask the user for a longer part of the description.';
    end
    else if LField.Kind = hfkChoice then
    begin
      Result := '';
      for I := 0 to High(LField.Choices) do
        if (Trim(AText) = '') or ContainsText(LField.Choices[I], Trim(AText)) then
          Result := Result + sLineBreak + '- ' + LField.Choices[I];
      if Result = '' then
        Result := Format('No value of "%s" matches "%s"; it accepts: %s.',
          [LField.Caption, AText, LField.TypeText])
      else
        Result := Format('Values of "%s" matching "%s":', [LField.Caption, AText]) + Result;
    end
    else
      Result := Format('"%s" is not a choice: it is %s.', [LField.Caption, LField.TypeText]);
  finally
    LFields.Free;
  end;
end;

{ commands }

function HelpChatLooksLikeSave(const ACaption, AName: string): Boolean;
const
  SAVE_WORDS: array[0..21] of string = ('save', 'salva', 'salvare', 'registra', 'conferma',
    'confirm', 'ok', 'post', 'apply', 'applica', 'submit', 'invia', 'speichern', 'übernehmen',
    'enregistrer', 'valider', 'appliquer', 'guardar', 'aplicar', 'salvar', 'gravar', 'confirmar');
var
  LWords: TArray<string>;
  LWord: string;
begin
  LWords := LowerCase(ACaption).Split([' ', '.', ',', ';', ':', '!', '?', '-', '/', '(', ')', '&', #9],
    TStringSplitOptions.ExcludeEmpty);
  for LWord in LWords do
    if MatchText(LWord, SAVE_WORDS) then
      Exit(True);
  Result := ContainsText(AName, 'save') or ContainsText(AName, 'salva') or
    ContainsText(AName, 'confirm') or ContainsText(AName, 'conferma');
end;

function HelpChatFindScreenCommand(const ACommands: THelpChatSkillCommandList;
  const AText: string): THelpChatSkillCommand;
var
  LCommand: THelpChatSkillCommand;
begin
  for LCommand in ACommands do
    if SameText(LCommand.Id, Trim(AText)) then
      Exit(LCommand);
  for LCommand in ACommands do
    if SameText(LCommand.Caption, HelpChatCleanCaption(AText)) then
      Exit(LCommand);
  Result := nil;
  if Trim(AText) <> '' then
    for LCommand in ACommands do
      if ContainsText(LCommand.Caption, Trim(AText)) then
      begin
        if Assigned(Result) then
          Exit(nil); // two of them: the model has to say which
        Result := LCommand;
      end;
end;

function HelpChatScreenListCommands(const AScreen: THelpChatScreen): string;
var
  LCommands: THelpChatSkillCommandList;
  LCommand: THelpChatSkillCommand;
begin
  LCommands := CheckScreen(AScreen).Commands;
  try
    if LCommands.Count = 0 then
      Exit(Format('The screen "%s" has no button the assistant may press now.', [AScreen.Title]));
    Result := Format('Buttons of "%s" the assistant may press now (id | caption | shortcut), ' +
      'then what each does:', [AScreen.Title]);
    for LCommand in LCommands do
    begin
      Result := Result + sLineBreak + Format('- %s | %s | %s', [LCommand.Id, LCommand.Caption,
        IfThen(LCommand.ShortCut <> '', LCommand.ShortCut, '-')]);
      if LCommand.Hint <> '' then
        Result := Result + sLineBreak + '  ' + LCommand.Hint;
    end;
    Result := Result + sLineBreak + 'Saving or confirming is never among them: the user does it. ' +
      'press_command presses one; never mention buttons, keys or menus that are not listed.';
  finally
    LCommands.Free;
  end;
end;

function HelpChatScreenPress(const AScreen: THelpChatScreen; const ACommand: string;
  const AQueued: Boolean): string;
var
  LCommands: THelpChatSkillCommandList;
  LCommand: THelpChatSkillCommand;
  LId, LCaption: string;
begin
  LCommands := CheckScreen(AScreen).Commands;
  try
    LCommand := HelpChatFindScreenCommand(LCommands, ACommand);
    if LCommand = nil then
      raise Exception.CreateFmt('The screen "%s" has no button "%s" the assistant may press: ' +
        'list_commands lists them.', [AScreen.Title, ACommand]);
    LId := LCommand.Id;
    LCaption := LCommand.Caption;
  finally
    LCommands.Free;
  end;
  AScreen.Press(LId, AQueued);
  Result := Format('Pressed "%s" on "%s". What it does is up to the screen: describe_form or ' +
    'list_commands show it now.', [LCaption, AScreen.Title]);
end;

{ records }

function FindList(const ALists: TArray<THelpChatDataList>; const AText: string;
  out AList: THelpChatDataList): Boolean;
var
  LItem: THelpChatDataList;
begin
  for LItem in ALists do
    if SameText(LItem.Id, Trim(AText)) or SameText(LItem.Caption, Trim(AText)) or
      SameText(HelpChatDataSetName(LItem.DataSet), Trim(AText)) then
    begin
      AList := LItem;
      Exit(True);
    end;
  Result := False;
end;

function HelpChatScreenCount(const AScreen: THelpChatScreen; const AList: string): string;
var
  LLists: TArray<THelpChatDataList>;
  LList: THelpChatDataList;
begin
  LLists := CheckScreen(AScreen).Lists;
  if Length(LLists) = 0 then
    raise Exception.CreateFmt('The screen "%s" shows no list of records.', [AScreen.Title]);
  if Trim(AList) <> '' then
  begin
    if not FindList(LLists, AList, LList) then
      raise Exception.CreateFmt('The screen has no list "%s": its lists are %s.', [AList, ListsText(LLists)]);
    Exit(Format('%s: %s.', [LList.Id, RecordCountText(LList.DataSet)]));
  end;
  Result := '';
  for LList in LLists do
    Result := Result + IfThen(Result <> '', sLineBreak) +
      Format('%s (%s): %s.', [LList.Id, LList.Caption, RecordCountText(LList.DataSet)]);
end;

function SearchFields(const AList: THelpChatDataList): TArray<TField>;
var
  LField: TField;
begin
  Result := AList.SearchFields;
  if Length(Result) = 0 then
    for LField in AList.DataSet.Fields do
      if LField.Visible and (HelpChatFieldKindOf(LField) in [hfkText, hfkInteger, hfkNumber, hfkDate]) then
        Result := Result + [LField];
end;

function RecordText(const AFields: TArray<TField>): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Min(High(AFields), 9) do
    Result := Result + IfThen(Result <> '', ', ') +
      Format('%s = %s', [AFields[I].DisplayLabel, HelpChatSkillCut(AFields[I].DisplayText)]);
end;

/// <summary>AFields without the ones a control of the screen shows as a
/// password: such a field is neither searched - a search that finds would
/// tell what it holds - nor reported.</summary>
function WithoutSecrets(const AScreen: THelpChatScreen;
  const AFields: TArray<TField>): TArray<TField>;
var
  LScreenFields: THelpChatDataFieldList;
  LScreenField: THelpChatDataField;
  LField: TField;
  LSecret: Boolean;
begin
  Result := nil;
  LScreenFields := AScreen.Fields;
  try
    for LField in AFields do
    begin
      LSecret := False;
      for LScreenField in LScreenFields do
        if LScreenField.Secret and (LScreenField.Field = LField) then
          LSecret := True;
      if not LSecret then
        Result := Result + [LField];
    end;
  finally
    LScreenFields.Free;
  end;
end;

function HelpChatScreenFindRecord(const AScreen: THelpChatScreen; const AText, AField, AList: string;
  const AHideValues: Boolean): string;
var
  LLists: TArray<THelpChatDataList>;
  LList: THelpChatDataList;
  LFields, LSearch: TArray<TField>;
  LField: TField;
  LDetail: TDataSet;
  LFound: Boolean;
  LText: string;
begin
  CheckScreen(AScreen);
  LText := Trim(AText);
  if LText = '' then
    raise Exception.Create('Say what to look for: a code or a description.');
  LLists := AScreen.Lists;
  if Length(LLists) = 0 then
    raise Exception.CreateFmt('The screen "%s" shows no list of records.', [AScreen.Title]);
  if Trim(AList) <> '' then
  begin
    if not FindList(LLists, AList, LList) then
      raise Exception.CreateFmt('The screen has no list "%s": its lists are %s.', [AList, ListsText(LLists)]);
  end
  else
    LList := LLists[0];
  if not LList.DataSet.Active then
    raise Exception.CreateFmt('The list %s is not open.', [LList.Id]);
  // Moving would post the record being edited: that is saving.
  if HelpChatIsEditing(LList.DataSet) then
    raise Exception.CreateFmt('The list %s is %s: moving to another record would save it. The user ' +
      'saves it first, or cancel_edit abandons it.', [LList.Id, HelpChatDataSetState(LList.DataSet)]);
  // The same for a detail of it: a master that moves posts the detail record
  // being edited.
  LDetail := EditingDetailOf(LList.DataSet, 0);
  if LDetail <> nil then
    raise Exception.CreateFmt('A detail of the list %s (%s) is %s: moving to another record would save ' +
      'it. The user saves it first, or cancels it.', [LList.Id, HelpChatDataSetName(LDetail),
      HelpChatDataSetState(LDetail)]);
  LFields := WithoutSecrets(AScreen, SearchFields(LList));
  if Trim(AField) <> '' then
  begin
    LSearch := nil;
    for LField in LList.DataSet.Fields do
      if SameText(LField.FieldName, Trim(AField)) or SameText(LField.DisplayLabel, Trim(AField)) then
        LSearch := [LField];
    LSearch := WithoutSecrets(AScreen, LSearch);
    if Length(LSearch) = 0 then
      raise Exception.CreateFmt('The list %s has no field "%s".', [LList.Id, AField]);
  end
  else
    LSearch := LFields;
  LFound := False;
  // The same value first, in any of the fields; then a value that starts with it.
  for LField in LSearch do
    if not LFound then
      try
        LFound := LList.DataSet.Locate(LField.FieldName, LText, [loCaseInsensitive]);
      except
        LFound := False; // a text where the field wants a number
      end;
  for LField in LSearch do
    if not LFound and (HelpChatFieldKindOf(LField) = hfkText) then
      try
        LFound := LList.DataSet.Locate(LField.FieldName, LText, [loCaseInsensitive, loPartialKey]);
      except
        LFound := False;
      end;
  if not LFound then
    Exit(Format('"%s" was not found in the list %s.', [LText, LList.Id]));
  Result := Format('The list %s is on the record found for "%s".', [LList.Id, LText]);
  if not AHideValues then
    Result := Result + ' ' + RecordText(LFields) + '.';
end;

{ pages }

function HelpChatScreenShowPage(const AScreen: THelpChatScreen; const APage: string): string;
var
  LPages: TArray<THelpChatSkillPage>;
  LFound, I: Integer;
  LError: string;
begin
  LPages := CheckScreen(AScreen).Pages;
  if Length(LPages) = 0 then
    raise Exception.CreateFmt('The screen "%s" has no pages.', [AScreen.Title]);
  LFound := -1;
  for I := 0 to High(LPages) do
    if SameText(LPages[I].Caption, HelpChatCleanCaption(APage)) or
      SameText(LPages[I].Path, Trim(APage)) or SameText(LPages[I].Name, Trim(APage)) then
    begin
      LFound := I;
      Break;
    end;
  if LFound < 0 then
    for I := 0 to High(LPages) do
      if (Trim(APage) <> '') and ContainsText(LPages[I].Path, Trim(APage)) then
      begin
        if LFound >= 0 then
          raise Exception.CreateFmt('More than one page matches "%s": %s.',
            [APage, HelpChatScreenPagesText(AScreen)]);
        LFound := I;
      end;
  if LFound < 0 then
    raise Exception.CreateFmt('The screen "%s" has no page "%s": its pages are %s.',
      [AScreen.Title, APage, HelpChatScreenPagesText(AScreen)]);
  if LPages[LFound].Shown then
    Exit(Format('The page "%s" was already shown.', [LPages[LFound].Path]));
  LError := AScreen.ActivatePage(LPages[LFound]);
  if LError <> '' then
    Exit(LError);
  Result := Format('The page "%s" is shown: describe_form lists its fields.', [LPages[LFound].Path]);
end;

{ the skills }

type
  /// The skills over a screen: the one of the provider that serves the host.
  TScreenSkill = class(THelpChatSkill)
  protected
    function Screen: THelpChatScreen;
    function TitleOf(const AScreen: THelpChatScreen): string;
  public
    class function Supports(const AHost: TComponent): Boolean; override;
  end;

  TFormsSkill = class(TScreenSkill)
  strict private
    FSnapshot: TDictionary<string, string>;
    FSnapshotKey: string;
    function Snapshot(const AScreen: THelpChatScreen): TDictionary<string, string>;
  protected
    procedure RegisterActions; override;
  public
    constructor Create(const AHost: TComponent; const ABroker: THelpChatActionBroker); override;
    destructor Destroy; override;
    class function SkillName: string; override;
    class function SkillDescription(const ALanguage: THelpChatLanguage = hclAuto): string; override;
  end;

  TCommandsSkill = class(TScreenSkill)
  protected
    procedure RegisterActions; override;
  public
    class function SkillName: string; override;
    class function SkillDescription(const ALanguage: THelpChatLanguage = hclAuto): string; override;
  end;

  TRecordsSkill = class(TScreenSkill)
  protected
    procedure RegisterActions; override;
  public
    class function SkillName: string; override;
    class function SkillDescription(const ALanguage: THelpChatLanguage = hclAuto): string; override;
  end;

  TPagesSkill = class(TScreenSkill)
  protected
    procedure RegisterActions; override;
  public
    class function SkillName: string; override;
    class function SkillDescription(const ALanguage: THelpChatLanguage = hclAuto): string; override;
  end;

{ TScreenSkill }

class function TScreenSkill.Supports(const AHost: TComponent): Boolean;
begin
  Result := Assigned(HelpChatScreenProviderFor(AHost));
end;

function TScreenSkill.Screen: THelpChatScreen;
var
  LProvider: THelpChatScreenProviderClass;
begin
  LProvider := HelpChatScreenProviderFor(Host);
  if LProvider = nil then
    raise Exception.Create('No screen: the skills of this framework are not linked.');
  Result := LProvider.CreateScreen(Host);
end;

function TScreenSkill.TitleOf(const AScreen: THelpChatScreen): string;
begin
  if Assigned(AScreen) then
    Result := AScreen.Title
  else
    Result := '';
end;

{ TFormsSkill }

constructor TFormsSkill.Create(const AHost: TComponent; const ABroker: THelpChatActionBroker);
begin
  inherited;
  FSnapshot := TDictionary<string, string>.Create;
end;

destructor TFormsSkill.Destroy;
begin
  inherited;
  FSnapshot.Free;
end;

class function TFormsSkill.SkillName: string;
begin
  Result := HELPCHAT_SKILL_FORMS;
end;

class function TFormsSkill.SkillDescription(const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatMsg(hcmSkillForms, ALanguage);
end;

// The previous values belong to one form: another form starts a new snapshot.
function TFormsSkill.Snapshot(const AScreen: THelpChatScreen): TDictionary<string, string>;
var
  LKey: string;
begin
  LKey := '';
  if Assigned(AScreen) then
    LKey := AScreen.Identity;
  if LKey <> FSnapshotKey then
  begin
    FSnapshot.Clear;
    FSnapshotKey := LKey;
  end;
  Result := FSnapshot;
end;

procedure TFormsSkill.RegisterActions;
var
  LAction: THelpChatAction;
begin
  AddAction('describe_form',
    'Describes the data-entry form the user is working on: for each field its id, label, ' +
    'type, whether it is required or read-only, the allowed values, the current value and ' +
    'its full description; then its pages and its lists. Call it before fill_form, and ' +
    'follow the descriptions of the fields to fill them precisely.',
    [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenDescribe(CheckScreen(LScreen), HelpChatSkillsHideFieldValues);
      finally
        LScreen.Free;
      end;
    end, False);

  LAction := AddAction('fill_form',
    'Fills fields of the form the user is working on, by the ids of describe_form. Where ' +
    'the form edits a record it starts the insert or the edit by itself: never ask the user ' +
    'to press a button first. Choose the mode from what the user asks: "insert/add/create/' +
    'new ..." -> mode=insert (a new record); "modify/change/correct ..." -> mode=edit (the ' +
    'record shown); "fill/complete ..." -> mode=current (the form as it is). Values given ' +
    'without field names follow the order of the form. The user is asked to confirm the ' +
    'values first. It never saves: the user reviews the values and saves. Reports the ' +
    'outcome of each field and the required fields still empty.',
    [THelpChatActionParam.Create('values',
      'JSON object {"field id": "value"} with the ids of describe_form. Dates as ' +
      'YYYY-MM-DD, numbers with "." as decimal separator, yes/no as true/false, choices and ' +
      'references by code or exact description; an empty string clears the field.'),
     THelpChatActionParam.Create('mode',
      'insert, edit or current (see the description of the action).', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LValues: TJSONObject;
      LScreen: THelpChatScreen;
    begin
      LValues := HelpChatSkillValues(AArgs.RawJson);
      LScreen := Screen;
      try
        AResult := HelpChatScreenFill(CheckScreen(LScreen), LValues,
          HelpChatParseFillMode(AArgs.AsString('mode')), HelpChatSkillsHideFieldValues,
          Snapshot(LScreen));
      finally
        LScreen.Free;
        LValues.Free;
      end;
    end, True);
  if Assigned(LAction) then
    // The confirmation reads "Name: Mario", not a JSON object.
    LAction.OnDisplay :=
      procedure(const AArgs: THelpChatActionArgs; var ASummary: string;
        var AValues: TArray<TPair<string, string>>)
      var
        LValues: TJSONObject;
        LScreen: THelpChatScreen;
        LFields: THelpChatDataFieldList;
        LField: THelpChatDataField;
        LPair: TJSONPair;
        LName: string;
      begin
        LScreen := Screen;
        LValues := HelpChatSkillValues(AArgs.RawJson);
        LFields := nil;
        try
          if LScreen = nil then
            Exit;
          ASummary := HelpChatMsgFmt(hcmSkillFill, [LScreen.Title]);
          LFields := LScreen.Fields;
          if Assigned(LValues) then
          begin
            AValues := nil;
            for LPair in LValues do
            begin
              LField := HelpChatFindScreenField(LFields, LPair.JsonString.Value);
              if Assigned(LField) then
                LName := LField.Caption
              else
                LName := LPair.JsonString.Value;
              AValues := AValues + [TPair<string, string>.Create(LName,
                HelpChatJsonValueText(LPair.JsonValue))];
            end;
          end;
        finally
          LFields.Free;
          LValues.Free;
          LScreen.Free;
        end;
      end;

  AddAction('find_choice',
    'Searches the values a choice or reference field of the form accepts (the customer of ' +
    'an order, say) by part of their description, and returns them with their code. Use ' +
    'it when fill_form reports that a value was not found or is ambiguous, then fill the ' +
    'field with the one chosen with the user.',
    [THelpChatActionParam.Create('field', 'Id of the field, as returned by describe_form.'),
     THelpChatActionParam.Create('text', 'Part of the description to search for.', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenFindChoice(CheckScreen(LScreen), AArgs.AsString('field'),
          AArgs.AsString('text'));
      finally
        LScreen.Free;
      end;
    end, False);

  LAction := AddAction('cancel_edit',
    'Abandons the changes not saved on the form the user is working on: the record being ' +
    'inserted or edited goes back as it was, and the fields the assistant filled get their ' +
    'previous values back (after a fill_form the user does not want, for example).',
    [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenCancel(CheckScreen(LScreen), Snapshot(LScreen));
      finally
        LScreen.Free;
      end;
    end, True);
  if Assigned(LAction) then
    LAction.OnDisplay :=
      procedure(const AArgs: THelpChatActionArgs; var ASummary: string;
        var AValues: TArray<TPair<string, string>>)
      var
        LScreen: THelpChatScreen;
      begin
        LScreen := Screen;
        try
          if Assigned(LScreen) then
            ASummary := HelpChatMsgFmt(hcmSkillCancel, [LScreen.Title]);
        finally
          LScreen.Free;
        end;
      end;
end;

{ TCommandsSkill }

class function TCommandsSkill.SkillName: string;
begin
  Result := HELPCHAT_SKILL_COMMANDS;
end;

class function TCommandsSkill.SkillDescription(const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatMsg(hcmSkillCommands, ALanguage);
end;

procedure TCommandsSkill.RegisterActions;
var
  LAction: THelpChatAction;
begin
  AddAction('list_commands',
    'Lists the buttons the user can press now on the screen they are working on: id, ' +
    'caption, shortcut and what each does. Call it before press_command. Saving or ' +
    'confirming is never among them: the user does that.',
    [],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenListCommands(CheckScreen(LScreen));
      finally
        LScreen.Free;
      end;
    end, False);

  LAction := AddAction('press_command',
    'Presses a button of the screen the user is working on, as if the user clicked it ' +
    '(its id or caption from list_commands): you CAN press the buttons with this action, ' +
    'never ask the user to do it. Never invent buttons, keys or menus that list_commands ' +
    'does not show.',
    [THelpChatActionParam.Create('command', 'Id or caption of the button, as returned by list_commands.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenPress(CheckScreen(LScreen), AArgs.AsString('command'), True);
      finally
        LScreen.Free;
      end;
    end, True);
  if Assigned(LAction) then
    LAction.OnDisplay :=
      procedure(const AArgs: THelpChatActionArgs; var ASummary: string;
        var AValues: TArray<TPair<string, string>>)
      var
        LScreen: THelpChatScreen;
        LCommands: THelpChatSkillCommandList;
        LCommand: THelpChatSkillCommand;
      begin
        LScreen := Screen;
        LCommands := nil;
        try
          if LScreen = nil then
            Exit;
          LCommands := LScreen.Commands;
          LCommand := HelpChatFindScreenCommand(LCommands, AArgs.AsString('command'));
          if Assigned(LCommand) then
          begin
            ASummary := HelpChatMsgFmt(hcmSkillPress, [LCommand.Caption, LScreen.Title]);
            AValues := nil;
          end;
        finally
          LCommands.Free;
          LScreen.Free;
        end;
      end;
end;

{ TRecordsSkill }

class function TRecordsSkill.SkillName: string;
begin
  Result := HELPCHAT_SKILL_RECORDS;
end;

class function TRecordsSkill.SkillDescription(const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatMsg(hcmSkillRecords, ALanguage);
end;

procedure TRecordsSkill.RegisterActions;
begin
  AddAction('count_records',
    'Counts the records of the lists of the screen the user is working on, as they are ' +
    'filtered now, and reports the active filter if any. Use it when the user asks how ' +
    'many records there are.',
    [THelpChatActionParam.Create('list', 'Id of the list (optional: all of them).', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenCount(CheckScreen(LScreen), AArgs.AsString('list'));
      finally
        LScreen.Free;
      end;
    end, False);

  AddAction('find_record',
    'Moves a list of the screen the user is working on to a record, by its code or its ' +
    'description (the same value first, then one starting with it), and reports its ' +
    'values. Use it before editing, deleting or opening a record the user names ("edit the ' +
    'customer Rossi"). It refuses while a record is being edited: moving would save it.',
    [THelpChatActionParam.Create('text', 'Code or description of the record.'),
     THelpChatActionParam.Create('field', 'Name or label of the field to search (optional).',
       apkString, False),
     THelpChatActionParam.Create('list', 'Id of the list (optional: the first one).', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenFindRecord(CheckScreen(LScreen), AArgs.AsString('text'),
          AArgs.AsString('field'), AArgs.AsString('list'), HelpChatSkillsHideFieldValues);
      finally
        LScreen.Free;
      end;
    end, False);
end;

{ TPagesSkill }

class function TPagesSkill.SkillName: string;
begin
  Result := HELPCHAT_SKILL_PAGES;
end;

class function TPagesSkill.SkillDescription(const ALanguage: THelpChatLanguage): string;
begin
  Result := HelpChatMsg(hcmSkillPages, ALanguage);
end;

procedure TPagesSkill.RegisterActions;
begin
  AddAction('show_page',
    'Shows a page (tab) of the screen the user is working on, by its caption, as if the ' +
    'user clicked the tab: the fields of the other pages are neither described nor filled ' +
    'until their page is shown.',
    [THelpChatActionParam.Create('page', 'Caption of the page, as describe_form lists it.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LScreen: THelpChatScreen;
    begin
      LScreen := Screen;
      try
        AResult := HelpChatScreenShowPage(CheckScreen(LScreen), AArgs.AsString('page'));
      finally
        LScreen.Free;
      end;
    end, False);
end;

initialization
  GProviders := TList<THelpChatScreenProviderClass>.Create;
  HelpChatRegisterSkill(TFormsSkill);
  HelpChatRegisterSkill(TCommandsSkill);
  HelpChatRegisterSkill(TRecordsSkill);
  HelpChatRegisterSkill(TPagesSkill);

finalization
  HelpChatUnregisterSkill(TFormsSkill);
  HelpChatUnregisterSkill(TCommandsSkill);
  HelpChatUnregisterSkill(TRecordsSkill);
  HelpChatUnregisterSkill(TPagesSkill);
  FreeAndNil(GProviders);

end.
