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
///  The VCL skills on a form bound with LiveBindings, the way the CRM demo is:
///  edits, a combo filled from another table, a check box, a string grid and a
///  bind navigator, all over a <c>TBindSourceDB</c> - and not one data-aware
///  control. The bindings are read by the names of their classes, the way the
///  FireMonkey skills read them.
/// </summary>
unit HelpChatAI.Tests.Skills.Bindings;

interface

uses
  System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Grids, Data.DB,
  FireDAC.Comp.Client,
  Data.Bind.Components, Data.Bind.DBScope, Data.Bind.Grid, Data.Bind.EngExt,
  Vcl.Bind.DBEngExt, Vcl.Bind.Editors, Vcl.Bind.Grid, Vcl.Bind.Navigator,
  DUnitX.TestFramework;

type
  [TestFixture]
  TVclBindingSkillTests = class
  strict private
    FForm: TForm;
    FTable, FRegions: TFDMemTable;
    FNavigator: TBindNavigator;
    procedure BuildBoundForm;
  public
    [TearDown] procedure TearDown;
    [Test] procedure Describe_ReadsTheFieldsOfTheLinks;
    [Test] procedure Fill_WritesThroughTheField_AndNeverPosts;
    [Test] procedure Lookup_OfAFillLink_ByDescription_WritesTheCode;
    [Test] procedure Records_TheGridOfALink_IsAList;
    [Test] procedure Commands_TheBindNavigator_LeavesOutSavesAndMovesWhileEditing;
  end;

implementation

uses
  System.SysUtils, System.JSON,
  FireDAC.Comp.DataSet, FireDAC.Stan.Intf,
  HelpChatAI.Skills,
  Vcl.HelpChatAI.Skills;

{ TVclBindingSkillTests }

procedure TVclBindingSkillTests.TearDown;
begin
  // The form first: its links talk to the tables while they go.
  FreeAndNil(FForm);
  FreeAndNil(FTable);
  FreeAndNil(FRegions);
end;

function NewLabel(const AParent: TWinControl; const ACaption: string; const ALeft, ATop: Integer;
  const AFocus: TWinControl): TLabel;
begin
  Result := TLabel.Create(AParent.Owner);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(ALeft, ATop, 80, 15);
  Result.FocusControl := AFocus;
end;

procedure TVclBindingSkillTests.BuildBoundForm;
var
  LSource, LRegionSource: TBindSourceDB;
  LList: TBindingsList;
  LEdit: TEdit;
  LCombo: TComboBox;
  LCheck: TCheckBox;
  LGrid: TStringGrid;
  LLink: TLinkControlToField;
  LFill: TLinkFillControlToField;
  LGridLink: TLinkGridToDataSource;
begin
  FRegions := TFDMemTable.Create(nil);
  FRegions.Name := 'Regions';
  FRegions.FieldDefs.Add('Id', ftInteger);
  FRegions.FieldDefs.Add('Description', ftString, 30);
  FRegions.CreateDataSet;
  FRegions.AppendRecord([1, 'Lombardia']);
  FRegions.AppendRecord([2, 'Piemonte']);
  FRegions.AppendRecord([3, 'Liguria']);

  FTable := TFDMemTable.Create(nil);
  FTable.Name := 'Customers';
  FTable.FieldDefs.Add('Code', ftString, 10);
  FTable.FieldDefs.Add('CompanyName', ftString, 40);
  FTable.FieldDefs.Add('Region', ftInteger);
  FTable.FieldDefs.Add('Active', ftBoolean);
  FTable.CreateDataSet;
  FTable.FieldByName('Code').Required := True;
  FTable.FieldByName('CompanyName').DisplayLabel := 'Company';
  FTable.AppendRecord(['C1', 'Acme', 1, True]);
  FTable.AppendRecord(['C2', 'Rossi Srl', 2, False]);
  FTable.First;

  FForm := TForm.CreateNew(nil);
  FForm.Caption := 'Customers';
  FForm.Position := poDesigned;
  FForm.SetBounds(-3000, 100, 700, 600);
  LList := TBindingsList.Create(FForm);
  LSource := TBindSourceDB.Create(FForm);
  LSource.DataSet := FTable;
  LRegionSource := TBindSourceDB.Create(FForm);
  LRegionSource.DataSet := FRegions;

  LEdit := TEdit.Create(FForm);
  LEdit.Name := 'edCode';
  LEdit.Parent := FForm;
  LEdit.SetBounds(100, 10, 100, 21);
  NewLabel(FForm, 'Code', 10, 12, LEdit);
  LLink := TLinkControlToField.Create(FForm);
  LLink.BindingsList := LList;
  LLink.DataSource := LSource;
  LLink.FieldName := 'Code';
  LLink.Control := LEdit;

  LEdit := TEdit.Create(FForm);
  LEdit.Name := 'edCompany';
  LEdit.Parent := FForm;
  LEdit.SetBounds(100, 40, 200, 21); // no label at all: the display label
  LLink := TLinkControlToField.Create(FForm);
  LLink.BindingsList := LList;
  LLink.DataSource := LSource;
  LLink.FieldName := 'CompanyName';
  LLink.Control := LEdit;

  LCombo := TComboBox.Create(FForm);
  LCombo.Name := 'cbRegion';
  LCombo.Parent := FForm;
  LCombo.SetBounds(100, 70, 200, 21);
  NewLabel(FForm, 'Region', 10, 72, LCombo);
  LFill := TLinkFillControlToField.Create(FForm);
  LFill.BindingsList := LList;
  LFill.DataSource := LSource;
  LFill.FieldName := 'Region';
  LFill.Control := LCombo;
  LFill.FillDataSource := LRegionSource;
  LFill.FillValueFieldName := 'Id';
  LFill.FillDisplayFieldName := 'Description';

  LCheck := TCheckBox.Create(FForm);
  LCheck.Name := 'chkActive';
  LCheck.Parent := FForm;
  LCheck.SetBounds(100, 100, 100, 17);
  LCheck.Caption := 'Active';
  LLink := TLinkControlToField.Create(FForm);
  LLink.BindingsList := LList;
  LLink.DataSource := LSource;
  LLink.FieldName := 'Active';
  LLink.Control := LCheck;

  LGrid := TStringGrid.Create(FForm);
  LGrid.Name := 'grdCustomers';
  LGrid.Parent := FForm;
  LGrid.SetBounds(10, 150, 600, 200);
  LGridLink := TLinkGridToDataSource.Create(FForm);
  LGridLink.BindingsList := LList;
  LGridLink.DataSource := LSource;
  LGridLink.GridControl := LGrid;

  FNavigator := TBindNavigator.Create(FForm);
  FNavigator.Name := 'navCustomers';
  FNavigator.Parent := FForm;
  FNavigator.SetBounds(10, 370, 300, 25);
  FNavigator.DataSource := LSource;

  FForm.Show;
end;

procedure TVclBindingSkillTests.Describe_ReadsTheFieldsOfTheLinks;
var
  LText: string;
begin
  BuildBoundForm;
  LText := HelpChatVclDescribeForm(FForm, False);
  // Read through the TField of the link, not as a plain edit: the size, the
  // required flag and the display label come from the field.
  Assert.Contains(LText, 'State of Customers: browsing the record shown.');
  Assert.Contains(LText, '- edCode | Code | text, max 10 characters | required | "C1"');
  Assert.Contains(LText, '- edCompany | Company |', 'the display label');
  Assert.Contains(LText, 'reference to a record of "Regions"', 'the fill link is a lookup');
  Assert.Contains(LText, '"1 = Lombardia"');
  Assert.Contains(LText, '- chkActive | Active | yes/no');
  Assert.Contains(LText, 'grdCustomers (Customers: 2 record(s))', 'the grid of a link is a list');
end;

procedure TVclBindingSkillTests.Fill_WritesThroughTheField_AndNeverPosts;
var
  LValues: TJSONObject;
  LResult: string;
begin
  BuildBoundForm;
  LValues := TJSONObject.ParseJSONValue('{"Company": "Bianchi", "chkActive": "no"}') as TJSONObject;
  try
    LResult := HelpChatVclFillForm(FForm, LValues, hfmCurrent, False);
    Assert.Contains(LResult, '2 field(s) set, 0 not set');
    Assert.AreEqual(dsEdit, FTable.State, 'edited, never posted');
    Assert.AreEqual('Bianchi', FTable.FieldByName('CompanyName').AsString);
    Assert.IsFalse(FTable.FieldByName('Active').AsBoolean);
    LResult := HelpChatVclCancelEdit(FForm);
    Assert.AreEqual(dsBrowse, FTable.State);
    Assert.AreEqual('Acme', FTable.FieldByName('CompanyName').AsString, 'cancelled');
  finally
    LValues.Free;
  end;
end;

procedure TVclBindingSkillTests.Lookup_OfAFillLink_ByDescription_WritesTheCode;
var
  LValues: TJSONObject;
begin
  BuildBoundForm;
  LValues := TJSONObject.ParseJSONValue('{"cbRegion": "Liguria"}') as TJSONObject;
  try
    Assert.Contains(HelpChatVclFillForm(FForm, LValues, hfmCurrent, False), '1 field(s) set');
    Assert.AreEqual(3, FTable.FieldByName('Region').AsInteger, 'the code of the record');
    FTable.Cancel;
  finally
    LValues.Free;
  end;
end;

procedure TVclBindingSkillTests.Records_TheGridOfALink_IsAList;
begin
  BuildBoundForm;
  Assert.Contains(HelpChatVclCountRecords(FForm, 'grdCustomers'), '2 record(s)');
  Assert.Contains(HelpChatVclFindRecord(FForm, 'rossi', '', 'grdCustomers', False),
    'on the record found');
  Assert.AreEqual('C2', FTable.FieldByName('Code').AsString);
  FTable.Edit;
  try
    Assert.WillRaise(
      procedure
      begin
        HelpChatVclFindRecord(FForm, 'C1', '', 'grdCustomers', False);
      end, Exception);
    Assert.AreEqual(dsEdit, FTable.State, 'moving would have posted');
  finally
    FTable.Cancel;
  end;
end;

procedure TVclBindingSkillTests.Commands_TheBindNavigator_LeavesOutSavesAndMovesWhileEditing;
var
  LText: string;
begin
  BuildBoundForm;
  FTable.First;
  LText := HelpChatVclListCommands(FForm);
  Assert.Contains(LText, 'navCustomers.next', 'offered while browsing');
  Assert.DoesNotContain(LText, 'navCustomers.post', 'a save is never offered');
  FTable.Edit;
  try
    LText := HelpChatVclListCommands(FForm);
    Assert.DoesNotContain(LText, 'navCustomers.next', 'moving posts the record being edited');
    Assert.DoesNotContain(LText, 'navCustomers.insert');
    Assert.DoesNotContain(LText, 'navCustomers.post', 'a save is never offered');
    Assert.Contains(LText, 'navCustomers.cancel', 'cancelling is not saving');
  finally
    FTable.Cancel;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TVclBindingSkillTests);

end.
