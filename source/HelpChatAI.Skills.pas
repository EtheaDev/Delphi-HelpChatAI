{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       Skills: ready-made sets of actions an assistant gets by name, and the  }
{       framework-neutral half of the ones that work on the user's screen.     }
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
///  A skill is a set of actions the library writes once and an assistant gets
///  by naming it in <c>Settings.Skills</c> - "forms, pages" - instead of
///  registering each action by hand. A skill is a class
///  (<see cref="THelpChatSkill" />) registered by name in the
///  <c>initialization</c> of its unit, the way a provider is; an assistant
///  creates one instance per skill when it activates
///  (<see cref="THelpChatSkillSet" />), the instance adds its actions to the
///  broker of that assistant and takes them away when it deactivates.
///  An action the application registered under the same name wins: a skill
///  never replaces what the code wrote. And a skill named in the configuration
///  is wanted by it, so its actions pass <c>AllowedActions</c> too.
///  The skills that read and fill the user's screen live in the framework
///  units (<c>Vcl.HelpChatAI.Skills</c>); what does not depend on a framework
///  - the kinds of field, how a field is described to the model, how the
///  values it writes are read - is here, so that the FireMonkey ones say the
///  same things in the same words.
/// </summary>
unit HelpChatAI.Skills;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  HelpChatAI.Messages, HelpChatAI.Actions;

const
  /// <summary>Describes the data-entry form the user is on and fills it:
  /// <c>describe_form</c>, <c>fill_form</c>, <c>find_choice</c>,
  /// <c>cancel_edit</c>.</summary>
  HELPCHAT_SKILL_FORMS = 'forms';
  /// <summary>Lists the buttons of the screen and presses one:
  /// <c>list_commands</c>, <c>press_command</c>. Never one that saves.</summary>
  HELPCHAT_SKILL_COMMANDS = 'commands';
  /// <summary>Counts the records of the lists of the screen and moves to
  /// one: <c>count_records</c>, <c>find_record</c>.</summary>
  HELPCHAT_SKILL_RECORDS = 'records';
  /// <summary>Shows a page of the screen: <c>show_page</c>.</summary>
  HELPCHAT_SKILL_PAGES = 'pages';

  /// <summary>A value longer than this is cut before the model reads it.</summary>
  HELPCHAT_SKILL_VALUE_MAXCHARS = 300;
  /// <summary>At most this many choices are listed in a description; a
  /// longer list is searched with <c>find_choice</c>.</summary>
  HELPCHAT_SKILL_MAX_CHOICES = 30;

type
  /// <summary>
  ///  One skill: a name, what it gives, and the actions it adds to the broker
  ///  of an assistant. A descendant overrides <see cref="SkillName" />,
  ///  <see cref="SkillDescription" /> and <see cref="RegisterActions" />,
  ///  where it calls <see cref="AddAction" />; it may keep state between the
  ///  calls of its actions (one instance per assistant, created at activation
  ///  and freed at deactivation). The handlers run on the main thread of the
  ///  application, like every action.
  /// </summary>
  THelpChatSkill = class abstract
  strict private
    FHost: TComponent;
    FBroker: THelpChatActionBroker;
    FAdded: TList<string>;
  protected
    /// <summary>Adds an action of the skill to the broker - unless the broker,
    /// or the shared actions it consults, already have one by that name:
    /// what the application registered wins. Returns the action, or nil
    /// when it was not added.</summary>
    function AddAction(const AName, ADescription: string;
      const AParams: array of THelpChatActionParam;
      const AHandler: THelpChatActionProc; const AConfirm: Boolean): THelpChatAction;
    /// <summary>Where the skill adds its actions.</summary>
    procedure RegisterActions; virtual; abstract;
  public
    constructor Create(const AHost: TComponent; const ABroker: THelpChatActionBroker); virtual;
    destructor Destroy; override;
    /// <summary>The name <c>Settings.Skills</c> uses, lower case.</summary>
    class function SkillName: string; virtual; abstract;
    /// <summary>One sentence for the user (<c>/skills</c>): what the assistant
    /// can do with it, in that language when the skill has it.</summary>
    class function SkillDescription(const ALanguage: THelpChatLanguage = hclAuto): string; virtual; abstract;
    /// <summary>Whether it works for that assistant: a VCL skill and a
    /// FireMonkey one may share a name, and each answers for its own
    /// component. True by default.</summary>
    class function Supports(const AHost: TComponent): Boolean; virtual;
    /// <summary>Adds the actions (<see cref="RegisterActions" />).</summary>
    procedure Attach;
    /// <summary>Takes away the actions it added, and only those.</summary>
    procedure Detach;
    /// <summary>The actions it added.</summary>
    function ActionNames: TArray<string>;
    /// <summary>The assistant (a <c>TVclHelpChatAI</c>, a
    /// <c>TFmxHelpChatAI</c>, or whatever created the set).</summary>
    property Host: TComponent read FHost;
    property Broker: THelpChatActionBroker read FBroker;
  end;

  THelpChatSkillClass = class of THelpChatSkill;

  /// <summary>The skills of one assistant, while it is active.</summary>
  THelpChatSkillSet = class
  strict private
    FSkills: TObjectList<THelpChatSkill>;
    FUnknown: TArray<string>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Creates and attaches the skill of each name (the registered
    /// class that supports <c>AHost</c>), after taking away the ones attached
    /// before. A name nobody registered is skipped - an application must
    /// start whatever its configuration says - and kept in
    /// <see cref="Unknown" />; the configuration check reports it. When the
    /// broker has an <c>Allowed</c> list, the actions of the skills are added
    /// to it: naming a skill is allowing it.</summary>
    procedure Attach(const AHost: TComponent; const ABroker: THelpChatActionBroker;
      const ANames: TArray<string>);
    /// <summary>Takes every action of the skills away and frees them.</summary>
    procedure Detach;
    /// <summary>The names of the skills attached.</summary>
    function Names: TArray<string>;
    /// <summary>The names of the last <see cref="Attach" /> that nobody
    /// registered.</summary>
    property Unknown: TArray<string> read FUnknown;
  end;

  /// <summary>What a field holds, as far as the model is concerned: it
  /// decides how the field is described and how a value is read.</summary>
  THelpChatFieldKind = (hfkText, hfkMemo, hfkInteger, hfkNumber, hfkDate,
    hfkDateTime, hfkTime, hfkBoolean, hfkChoice, hfkLookup, hfkOther);

  /// <summary>How <c>fill_form</c> makes a form editable, for the forms that
  /// edit a record (data-aware controls): <c>hfmInsert</c> a new record,
  /// <c>hfmEdit</c> the record shown, <c>hfmCurrent</c> the form as it is
  /// (already editing, or put in edit by the AutoEdit of its data source).
  /// Plain controls have no record and ignore it.</summary>
  THelpChatFillMode = (hfmCurrent, hfmInsert, hfmEdit);

  /// <summary>
  ///  One field of a screen as the model is told about it. The framework
  ///  units fill it from a control (and descend from it to keep the control);
  ///  everything a description says comes from here.
  /// </summary>
  THelpChatSkillField = class
  public
    /// <summary>What the model names the field by: the name of the control.</summary>
    Id: string;
    /// <summary>What the user reads next to it: the label that points to it,
    /// its own caption, the label of its data field.</summary>
    Caption: string;
    /// <summary>The full description (the hint), when there is one.</summary>
    Hint: string;
    /// <summary>The data field behind the control, when there is one.</summary>
    DataField: string;
    Kind: THelpChatFieldKind;
    /// <summary>For text: the longest value, 0 = no limit.</summary>
    MaxLength: Integer;
    Required: Boolean;
    ReadOnly: Boolean;
    /// <summary>A password: its value is never read to the model.</summary>
    Secret: Boolean;
    /// <summary>The code that identifies the record.</summary>
    Key: Boolean;
    /// <summary>For a choice: the values, as the user reads them.</summary>
    Choices: TArray<string>;
    /// <summary>For a choice: True when nothing else is accepted.</summary>
    ChoicesOnly: Boolean;
    /// <summary>For a lookup: what it points to ("Customers").</summary>
    LookupOf: string;
    /// <summary>The current value as text (dates ISO, numbers with a
    /// point), empty when the field is.</summary>
    Value: string;
    /// <summary>The type as the model is told: "date (YYYY-MM-DD)", "one
    /// of: ...".</summary>
    function TypeText: string; virtual;
    /// <summary>"KEY", "required", "read-only", "optional".</summary>
    function FlagsText: string;
    /// <summary>The line of the field in a description, and its hint on the
    /// next line when it says more than the caption. With
    /// <c>AHideValues</c> (or a secret) only "filled" or "empty".</summary>
    function DescribeLines(const AHideValues: Boolean): string;
  end;

{ The registry }

/// <summary>Makes a skill available by its name: called in the
/// <c>initialization</c> of its unit.</summary>
procedure HelpChatRegisterSkill(const AClass: THelpChatSkillClass);
procedure HelpChatUnregisterSkill(const AClass: THelpChatSkillClass);
/// <summary>The names registered, once each, in the order of
/// registration.</summary>
function HelpChatSkillNames: TArray<string>;
/// <summary>True when some class registered that name.</summary>
function HelpChatIsSkillRegistered(const AName: string): Boolean;
/// <summary>The class registered for that name that supports
/// <c>AHost</c> (any of them when <c>AHost</c> is nil); nil when none.</summary>
function HelpChatFindSkill(const AName: string; const AHost: TComponent): THelpChatSkillClass;
/// <summary>The description of the first class of that name; empty when
/// none.</summary>
function HelpChatSkillDescription(const AName: string;
  const ALanguage: THelpChatLanguage = hclAuto): string;
/// <summary>The actions a skill of that name adds, found by attaching one to
/// a broker of its own; empty when none.</summary>
function HelpChatSkillActionNames(const AName: string): TArray<string>;

{ What the screen skills share }

/// <summary>"&amp;Name:" -> "Name": the hotkey marks, a trailing colon or
/// asterisk and the spaces go.</summary>
function HelpChatCleanCaption(const ACaption: string): string;
/// <summary>True when a caption ends with "*", the usual mark of a required
/// field.</summary>
function HelpChatCaptionMarksRequired(const ACaption: string): Boolean;
/// <summary>true/yes/si/1... or false/no/0..., in the six languages.</summary>
function HelpChatParseBoolean(const AText: string; out AValue: Boolean): Boolean;
/// <summary>A number with a point (the format the model is told), then in
/// the format of the machine.</summary>
function HelpChatParseNumber(const AText: string; out AValue: Double): Boolean;
/// <summary>ISO first ("2026-10-19", "2026-10-19 14:30", with a T too), then
/// the format of the machine; a time for <c>hfkTime</c>; the date alone for
/// <c>hfkDate</c>.</summary>
function HelpChatParseDateTime(const AText: string; const AKind: THelpChatFieldKind;
  out AValue: TDateTime): Boolean;
/// <summary>A date, a time or both, as the model is told to write them.</summary>
function HelpChatFormatDateTime(const AValue: TDateTime; const AKind: THelpChatFieldKind): string;
/// <summary>A number with a point.</summary>
function HelpChatFormatNumber(const AValue: Double): string;
/// <summary>The index of the choice the text names: the same text (case
/// apart), else the only one that starts with it; -1 otherwise.</summary>
function HelpChatMatchChoice(const AChoices: TArray<string>; const AText: string): Integer;
/// <summary>A value of a JSON object as text: a string as it is, true/false,
/// a number with a point, null as empty.</summary>
function HelpChatJsonValueText(const AValue: TJSONValue): string;
/// <summary>The object of values of a call (<c>{"values": {...}}</c>): the
/// object, or a string holding one - models send both. nil otherwise; the
/// caller frees it.</summary>
function HelpChatSkillValues(const AArgsJson: string; const AParam: string = 'values'): TJSONObject;
/// <summary>"insert"/"new", "edit"/"modify"; anything else is
/// <c>hfmCurrent</c>.</summary>
function HelpChatParseFillMode(const AText: string): THelpChatFillMode;
/// <summary>A value cut at <see cref="HELPCHAT_SKILL_VALUE_MAXCHARS" />.</summary>
function HelpChatSkillCut(const AValue: string): string;

implementation

uses
  System.StrUtils, System.DateUtils, System.Math;

var
  GSkills: TList<THelpChatSkillClass>;

{ THelpChatSkill }

constructor THelpChatSkill.Create(const AHost: TComponent; const ABroker: THelpChatActionBroker);
begin
  inherited Create;
  FHost := AHost;
  FBroker := ABroker;
  FAdded := TList<string>.Create;
end;

destructor THelpChatSkill.Destroy;
begin
  Detach;
  FAdded.Free;
  inherited;
end;

class function THelpChatSkill.Supports(const AHost: TComponent): Boolean;
begin
  Result := True;
end;

function THelpChatSkill.AddAction(const AName, ADescription: string;
  const AParams: array of THelpChatActionParam; const AHandler: THelpChatActionProc;
  const AConfirm: Boolean): THelpChatAction;
begin
  Result := nil;
  if not Assigned(FBroker) then
    Exit;
  if Assigned(FBroker.Find(AName)) or
    (Assigned(FBroker.Shared) and Assigned(FBroker.Shared.Find(AName))) then
    Exit;
  Result := FBroker.Add(AName, ADescription, AParams, AHandler, AConfirm);
  FAdded.Add(AName);
end;

procedure THelpChatSkill.Attach;
begin
  if FAdded.Count = 0 then
    RegisterActions;
end;

procedure THelpChatSkill.Detach;
var
  LName: string;
begin
  if Assigned(FBroker) then
    for LName in FAdded do
      FBroker.Remove(LName);
  FAdded.Clear;
end;

function THelpChatSkill.ActionNames: TArray<string>;
begin
  Result := FAdded.ToArray;
end;

{ THelpChatSkillSet }

constructor THelpChatSkillSet.Create;
begin
  inherited Create;
  FSkills := TObjectList<THelpChatSkill>.Create(True);
end;

destructor THelpChatSkillSet.Destroy;
begin
  Detach;
  FSkills.Free;
  inherited;
end;

procedure THelpChatSkillSet.Attach(const AHost: TComponent;
  const ABroker: THelpChatActionBroker; const ANames: TArray<string>);
var
  LName: string;
  LClass: THelpChatSkillClass;
  LSkill: THelpChatSkill;
  LAllowed, LAdded: TArray<string>;
begin
  Detach;
  FUnknown := nil;
  LAdded := nil;
  for LName in ANames do
  begin
    if MatchText(LName, Names) then
      Continue;
    LClass := HelpChatFindSkill(LName, AHost);
    if LClass = nil then
    begin
      FUnknown := FUnknown + [LName];
      Continue;
    end;
    LSkill := LClass.Create(AHost, ABroker);
    FSkills.Add(LSkill);
    LSkill.Attach;
    LAdded := LAdded + LSkill.ActionNames;
  end;
  // The configuration that names a skill wants its actions: an AllowedActions
  // written for the actions of the code must not hide them.
  if Assigned(ABroker) and (Length(LAdded) > 0) then
  begin
    LAllowed := ABroker.Allowed;
    if Length(LAllowed) > 0 then
      ABroker.Allowed := LAllowed + LAdded;
  end;
end;

procedure THelpChatSkillSet.Detach;
begin
  FSkills.Clear; // each skill takes its actions away in its destructor
end;

function THelpChatSkillSet.Names: TArray<string>;
var
  LSkill: THelpChatSkill;
begin
  Result := nil;
  for LSkill in FSkills do
    Result := Result + [LSkill.SkillName];
end;

{ THelpChatSkillField }

function THelpChatSkillField.TypeText: string;
var
  I: Integer;
begin
  case Kind of
    hfkText:
      if MaxLength > 0 then
        Result := Format('text, max %d characters', [MaxLength])
      else
        Result := 'text';
    hfkMemo: Result := 'multi-line text';
    hfkInteger: Result := 'integer number';
    hfkNumber: Result := 'decimal number (use "." as decimal separator)';
    hfkDate: Result := 'date (YYYY-MM-DD)';
    hfkDateTime: Result := 'date and time (YYYY-MM-DD HH:MM)';
    hfkTime: Result := 'time (HH:MM)';
    hfkBoolean: Result := 'yes/no (true or false)';
    hfkChoice:
      begin
        Result := 'one of: ';
        for I := 0 to Min(High(Choices), HELPCHAT_SKILL_MAX_CHOICES - 1) do
        begin
          if I > 0 then
            Result := Result + ', ';
          Result := Result + '"' + Choices[I] + '"';
        end;
        if Length(Choices) > HELPCHAT_SKILL_MAX_CHOICES then
          Result := Result + Format(' and %d more (find_choice searches them)',
            [Length(Choices) - HELPCHAT_SKILL_MAX_CHOICES]);
        if not ChoicesOnly then
          Result := Result + ' (other values allowed)';
      end;
    hfkLookup:
      begin
        if LookupOf <> '' then
          Result := Format('reference to a record of "%s": give its code or its exact ' +
            'description', [LookupOf])
        else
          Result := 'reference to a record: give its code or its exact description';
        if Length(Choices) > 0 then
        begin
          Result := Result + '; one of: ';
          for I := 0 to High(Choices) do
          begin
            if I > 0 then
              Result := Result + ', ';
            Result := Result + '"' + Choices[I] + '"';
          end;
        end
        else
          Result := Result + ' (find_choice searches them)';
      end;
  else
    Result := 'not editable by the assistant';
  end;
end;

function THelpChatSkillField.FlagsText: string;
begin
  if ReadOnly or (Kind = hfkOther) then
    Result := 'read-only'
  else if Required then
    Result := 'required'
  else
    Result := 'optional';
  if Key then
    Result := 'KEY: the code that identifies the record, ' + Result;
  if Secret then
    Result := Result + ', secret: its value is never shown';
end;

function THelpChatSkillField.DescribeLines(const AHideValues: Boolean): string;
var
  LValue: string;
begin
  if Value = '' then
    LValue := 'empty'
  else if AHideValues or Secret then
    LValue := 'filled'
  else
    LValue := '"' + HelpChatSkillCut(Value) + '"';
  Result := Format('- %s | %s | %s | %s | %s', [Id, Caption, TypeText, FlagsText, LValue]);
  if (Hint <> '') and not SameText(Hint, Caption) then
    Result := Result + sLineBreak + '  ' + Hint;
end;

{ The registry }

procedure HelpChatRegisterSkill(const AClass: THelpChatSkillClass);
begin
  if Assigned(AClass) and not GSkills.Contains(AClass) then
    GSkills.Add(AClass);
end;

procedure HelpChatUnregisterSkill(const AClass: THelpChatSkillClass);
begin
  if Assigned(GSkills) then
    GSkills.Remove(AClass);
end;

function HelpChatSkillNames: TArray<string>;
var
  LClass: THelpChatSkillClass;
begin
  Result := nil;
  for LClass in GSkills do
    if not MatchText(LClass.SkillName, Result) then
      Result := Result + [LClass.SkillName];
end;

function HelpChatIsSkillRegistered(const AName: string): Boolean;
begin
  Result := Assigned(HelpChatFindSkill(AName, nil));
end;

function HelpChatFindSkill(const AName: string; const AHost: TComponent): THelpChatSkillClass;
var
  LClass: THelpChatSkillClass;
begin
  for LClass in GSkills do
    if SameText(LClass.SkillName, Trim(AName)) and
      ((AHost = nil) or LClass.Supports(AHost)) then
      Exit(LClass);
  Result := nil;
end;

function HelpChatSkillDescription(const AName: string; const ALanguage: THelpChatLanguage): string;
var
  LClass: THelpChatSkillClass;
begin
  LClass := HelpChatFindSkill(AName, nil);
  if Assigned(LClass) then
    Result := LClass.SkillDescription(ALanguage)
  else
    Result := '';
end;

function HelpChatSkillActionNames(const AName: string): TArray<string>;
var
  LClass: THelpChatSkillClass;
  LBroker: THelpChatActionBroker;
  LRef: IHelpChatActionInvoker;
  LSkill: THelpChatSkill;
begin
  Result := nil;
  LClass := HelpChatFindSkill(AName, nil);
  if LClass = nil then
    Exit;
  LBroker := THelpChatActionBroker.Create;
  LRef := LBroker; // freed with the reference
  LSkill := LClass.Create(nil, LBroker);
  try
    LSkill.Attach;
    Result := LSkill.ActionNames;
  finally
    LSkill.Free;
  end;
end;

{ What the screen skills share }

function HelpChatCleanCaption(const ACaption: string): string;
begin
  Result := ACaption.Replace('&&', #1).Replace('&', '').Replace(#1, '&');
  Result := Result.Replace(#13, ' ').Replace(#10, ' ').Trim;
  while (Result <> '') and CharInSet(Result[Result.Length], [':', '*', ' ', '.']) do
    Result := Result.Substring(0, Result.Length - 1);
end;

function HelpChatCaptionMarksRequired(const ACaption: string): Boolean;
var
  LText: string;
begin
  LText := ACaption.Trim;
  while (LText <> '') and CharInSet(LText[LText.Length], [':', ' ']) do
    LText := LText.Substring(0, LText.Length - 1);
  Result := LText.EndsWith('*');
end;

function HelpChatParseBoolean(const AText: string; out AValue: Boolean): Boolean;
begin
  Result := True;
  if MatchText(Trim(AText), ['true', 'yes', 'y', 'si', 's'#$EC, 's', '1', 'vero', 'ja', 'oui',
    'sim', 'on', 'checked']) then
    AValue := True
  else if MatchText(Trim(AText), ['false', 'no', 'n', '0', 'falso', 'nein', 'non', 'n'#$E3'o',
    'off', 'unchecked']) then
    AValue := False
  else
    Result := False;
end;

function HelpChatParseNumber(const AText: string; out AValue: Double): Boolean;
var
  LText: string;
begin
  LText := Trim(AText);
  Result := TryStrToFloat(LText, AValue, TFormatSettings.Invariant) or
    TryStrToFloat(LText, AValue);
end;

function HelpChatParseDateTime(const AText: string; const AKind: THelpChatFieldKind;
  out AValue: TDateTime): Boolean;
var
  LText: string;
begin
  LText := Trim(AText);
  if AKind = hfkTime then
  begin
    Result := TryStrToTime(LText, AValue, TFormatSettings.Invariant) or TryStrToTime(LText, AValue);
    if Result then
      AValue := TimeOf(AValue);
    Exit;
  end;
  // True: a time written without an offset is the one the user means, not
  // a UTC time to convert to local.
  Result := TryISO8601ToDate(LText.Replace(' ', 'T'), AValue, True) or
    TryStrToDateTime(LText, AValue);
  if Result and (AKind = hfkDate) then
    AValue := DateOf(AValue);
end;

function HelpChatFormatDateTime(const AValue: TDateTime; const AKind: THelpChatFieldKind): string;
begin
  case AKind of
    hfkDate: Result := FormatDateTime('yyyy-mm-dd', AValue);
    hfkTime: Result := FormatDateTime('hh:nn', AValue);
  else
    Result := FormatDateTime('yyyy-mm-dd hh:nn', AValue);
  end;
end;

function HelpChatFormatNumber(const AValue: Double): string;
begin
  Result := FloatToStr(AValue, TFormatSettings.Invariant);
end;

function HelpChatMatchChoice(const AChoices: TArray<string>; const AText: string): Integer;
var
  I, LFound: Integer;
  LText: string;
begin
  LText := Trim(AText);
  for I := 0 to High(AChoices) do
    if SameText(AChoices[I], LText) then
      Exit(I);
  LFound := -1;
  if LText <> '' then
    for I := 0 to High(AChoices) do
      if StartsText(LText, AChoices[I]) then
      begin
        if LFound >= 0 then
          Exit(-1); // two of them: the model has to say which
        LFound := I;
      end;
  Result := LFound;
end;

function HelpChatJsonValueText(const AValue: TJSONValue): string;
begin
  if (AValue = nil) or (AValue is TJSONNull) then
    Result := ''
  else if AValue is TJSONString then
    Result := TJSONString(AValue).Value
  else if AValue is TJSONBool then
    Result := IfThen(TJSONBool(AValue).AsBoolean, 'true', 'false')
  else if AValue is TJSONNumber then
    Result := TJSONNumber(AValue).ToString
  else
    Result := AValue.ToJSON;
end;

function HelpChatSkillValues(const AArgsJson, AParam: string): TJSONObject;
var
  LArgs, LValue: TJSONValue;
begin
  Result := nil;
  try
    LArgs := TJSONObject.ParseJSONValue(AArgsJson);
  except
    LArgs := nil; // nonsense from the model: no values
  end;
  if not (LArgs is TJSONObject) then
  begin
    LArgs.Free;
    Exit;
  end;
  try
    LValue := TJSONObject(LArgs).GetValue(AParam);
    if LValue is TJSONObject then
      Result := TJSONObject(LValue.Clone)
    else if LValue is TJSONString then
    begin
      try
        LValue := TJSONObject.ParseJSONValue(TJSONString(LValue).Value);
      except
        LValue := nil;
      end;
      if LValue is TJSONObject then
        Result := TJSONObject(LValue)
      else
        LValue.Free;
    end;
  finally
    LArgs.Free;
  end;
end;

function HelpChatParseFillMode(const AText: string): THelpChatFillMode;
begin
  if MatchText(Trim(AText), ['insert', 'new', 'add', 'create']) then
    Result := hfmInsert
  else if MatchText(Trim(AText), ['edit', 'modify', 'update', 'change']) then
    Result := hfmEdit
  else
    Result := hfmCurrent;
end;

function HelpChatSkillCut(const AValue: string): string;
begin
  if AValue.Length > HELPCHAT_SKILL_VALUE_MAXCHARS then
    Result := AValue.Substring(0, HELPCHAT_SKILL_VALUE_MAXCHARS) + '...'
  else
    Result := AValue;
end;

initialization
  GSkills := TList<THelpChatSkillClass>.Create;

finalization
  FreeAndNil(GSkills);

end.
