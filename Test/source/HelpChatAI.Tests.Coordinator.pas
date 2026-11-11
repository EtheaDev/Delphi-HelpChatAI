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
///  Several VCL assistants in one application: where each one lives (the form
///  that owns it, not the main form) and which one F1 goes to (the one of the
///  active form, else the one whose form was active last). Real forms, real
///  activation: the coordinator reads Screen.ActiveCustomForm like the
///  application does.
/// </summary>
unit HelpChatAI.Tests.Coordinator;

interface

uses
  System.SysUtils,
  System.Classes,
  Vcl.Forms,
  DUnitX.TestFramework,
  Vcl.HelpChatAI;

type
  [TestFixture]
  TCoordinatorTests = class
  strict private
    FConfigFile: string;
    FForms: TList;
    function NewForm(const AName: string): TForm;
    function NewAssistant(const AOwner: TComponent): TVclHelpChatAI;
    /// <summary>Activates AForm as the user would, and says whether Windows
    /// let it: a test runner without the foreground cannot activate a form.</summary>
    function Activate(const AForm: TForm): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure HostForm_IsTheFormThatOwnsTheComponent;
    [Test]
    procedure HostForm_OfAComponentOnAFrame_IsTheFormOfTheFrame;
    [Test]
    procedure HostForm_OfAComponentOnADataModule_IsTheMainForm;
    [Test]
    procedure HostForm_SetInCode_Wins;
    [Test]
    procedure CurrentAssistant_NoneActive_IsNil;
    [Test]
    procedure TwoBubblesOnOneForm_LeaveInAnyOrder;
    [Test]
    procedure CurrentAssistant_IsTheOneOfTheActiveForm;
    [Test]
    procedure CurrentAssistant_OnAFormWithoutOne_IsTheLastActive;
    [Test]
    procedure CurrentAssistant_SkipsOneThatDoesNotTakeF1;
    [Test]
    procedure CurrentAssistant_Deactivated_IsForgotten;
    [Test]
    procedure SameProfile_ShareTheEngine;
    [Test]
    procedure SelectLanguage_IsWhatEveryAssistantOfTheProfileAnswers;
    [Test]
    procedure Actions_OfAnAssistantThatWentAway_AnswerAtOnce;
  end;

implementation

uses
  System.IOUtils,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.HelpChatAI.Bubble,
  HelpChatAI.Engine,
  HelpChatAI.Actions,
  HelpChatAI.Messages,
  Vcl.HelpChatAI.Voice;

{ TCoordinatorTests }

procedure TCoordinatorTests.TwoBubblesOnOneForm_LeaveInAnyOrder;
var
  LForm: TForm;
  LFirst, LSecond: TVclHelpChatAIBubble;
  LProc: TWndMethod;
begin
  // Two assistants hosted on one form are two bubbles listening to it. The
  // first to arrive is the first to go - the order in which a chain of
  // WindowProc hooks could not be undone, leaving the form calling a method
  // of a freed bubble.
  LForm := NewForm('Shared');
  LFirst := TVclHelpChatAIBubble.Create(nil);
  LSecond := TVclHelpChatAIBubble.Create(nil);
  try
    LFirst.Parent := LForm;
    LSecond.Parent := LForm;
    LProc := LForm.WindowProc;
    Assert.IsFalse(TMethod(LProc).Data = Pointer(LForm), 'the form is hooked');
    FreeAndNil(LFirst);
    LForm.Perform(WM_SIZE, 0, 0);   // goes through whatever is still hooked
    FreeAndNil(LSecond);
    LProc := LForm.WindowProc;
    Assert.IsTrue(TMethod(LProc).Data = Pointer(LForm), 'and its own procedure is back');
    LForm.Perform(WM_SIZE, 0, 0);
  finally
    LFirst.Free;
    LSecond.Free;
  end;
end;

procedure TCoordinatorTests.Setup;
begin
  FForms := TList.Create;
  // A configuration of its own: the stub provider, nothing persisted, and
  // above all not the file of the developer's machine.
  FConfigFile := TPath.Combine(TPath.GetTempPath, 'helpchatai-coordinator-test.json');
  TFile.WriteAllText(FConfigFile,
    '{"Provider": "stub", "PersistConversation": false, "Languages": ["en"]}',
    TEncoding.UTF8);
end;

procedure TCoordinatorTests.TearDown;
var
  I: Integer;
begin
  // Freeing a form frees its assistants, which deactivate and leave the
  // coordinator.
  for I := FForms.Count - 1 downto 0 do
    TObject(FForms[I]).Free;
  FForms.Free;
  TFile.Delete(FConfigFile);
end;

function TCoordinatorTests.NewForm(const AName: string): TForm;
begin
  Result := TForm.CreateNew(nil);
  Result.Name := AName;
  Result.Caption := AName;
  Result.SetBounds(100 + 40 * FForms.Count, 100 + 40 * FForms.Count, 300, 200);
  FForms.Add(Result);
end;

function TCoordinatorTests.NewAssistant(const AOwner: TComponent): TVclHelpChatAI;
begin
  Result := TVclHelpChatAI.Create(AOwner);
  Result.ConfigFileName := FConfigFile;
  Result.ShowBubble := False;
  Result.VoiceEngine := hveNone;
end;

function TCoordinatorTests.Activate(const AForm: TForm): Boolean;
var
  I: Integer;
begin
  AForm.Show;
  for I := 1 to 20 do
  begin
    SetForegroundWindow(AForm.Handle);
    AForm.BringToFront;
    Application.ProcessMessages;
    if Screen.ActiveCustomForm = AForm then
      Exit(True);
    Sleep(10);
  end;
  Result := False;
end;

procedure TCoordinatorTests.HostForm_IsTheFormThatOwnsTheComponent;
var
  LForm: TForm;
begin
  LForm := NewForm('OrderForm');
  Assert.AreSame(LForm, NewAssistant(LForm).ResolvedHostForm,
    'an assistant on an order form lives on the order form, not on the main one');
end;

procedure TCoordinatorTests.HostForm_OfAComponentOnAFrame_IsTheFormOfTheFrame;
var
  LForm: TForm;
  LFrame: TFrame;
begin
  LForm := NewForm('PlanningForm');
  LFrame := TFrame.Create(LForm);
  Assert.AreSame(LForm, NewAssistant(LFrame).ResolvedHostForm);
end;

procedure TCoordinatorTests.HostForm_OfAComponentOnADataModule_IsTheMainForm;
var
  LModule: TDataModule;
begin
  LModule := TDataModule.CreateNew(nil);
  try
    Assert.IsTrue(NewAssistant(LModule).ResolvedHostForm = Application.MainForm,
      'nothing on a data module to live on: the main form');
  finally
    LModule.Free;
  end;
end;

procedure TCoordinatorTests.HostForm_SetInCode_Wins;
var
  LOwner, LHost: TForm;
  LChat: TVclHelpChatAI;
begin
  LOwner := NewForm('OwnerForm');
  LHost := NewForm('HostForm');
  LChat := NewAssistant(LOwner);
  LChat.HostForm := LHost;
  Assert.AreSame(LHost, LChat.ResolvedHostForm);
end;

procedure TCoordinatorTests.CurrentAssistant_NoneActive_IsNil;
begin
  NewAssistant(NewForm('IdleForm')); // created, never activated
  Assert.IsNull(TVclHelpChatAI.CurrentAssistant);
end;

procedure TCoordinatorTests.CurrentAssistant_IsTheOneOfTheActiveForm;
var
  LMain, LOrders: TForm;
  LGeneral, LExpert: TVclHelpChatAI;
begin
  LMain := NewForm('MainForm');
  LOrders := NewForm('OrderForm');
  LGeneral := NewAssistant(LMain);
  LExpert := NewAssistant(LOrders);
  LGeneral.Active := True;
  LExpert.Active := True;
  if not Activate(LOrders) then
    Assert.Pass('Windows did not let the test runner activate a form');
  Assert.AreSame(LExpert, TVclHelpChatAI.CurrentAssistant, 'the order form is active');
  Assert.IsTrue(Activate(LMain));
  Assert.AreSame(LGeneral, TVclHelpChatAI.CurrentAssistant, 'back on the main form');
end;

procedure TCoordinatorTests.CurrentAssistant_OnAFormWithoutOne_IsTheLastActive;
var
  LMain, LOrders, LDialog: TForm;
  LGeneral, LExpert: TVclHelpChatAI;
begin
  LMain := NewForm('MainForm');
  LOrders := NewForm('OrderForm');
  LDialog := NewForm('PrintPreview');
  LGeneral := NewAssistant(LMain);
  LExpert := NewAssistant(LOrders);
  LGeneral.Active := True;
  LExpert.Active := True;
  if not Activate(LMain) then
    Assert.Pass('Windows did not let the test runner activate a form');
  Assert.IsTrue(Activate(LOrders));
  Assert.IsTrue(Activate(LDialog));
  Assert.AreSame(LExpert, TVclHelpChatAI.CurrentAssistant,
    'a preview opened from the order form: the order expert answers');
  Assert.IsTrue(Activate(LMain));
  Assert.IsTrue(Activate(LDialog));
  Assert.AreSame(LGeneral, TVclHelpChatAI.CurrentAssistant,
    'the same preview opened from the main form: the general one');
end;

procedure TCoordinatorTests.CurrentAssistant_SkipsOneThatDoesNotTakeF1;
var
  LMain, LOrders: TForm;
  LGeneral, LSilent: TVclHelpChatAI;
begin
  LMain := NewForm('MainForm');
  LOrders := NewForm('OrderForm');
  LGeneral := NewAssistant(LMain);
  LSilent := NewAssistant(LOrders);
  LSilent.HandleF1 := False;
  LGeneral.Active := True;
  LSilent.Active := True;
  if not Activate(LOrders) then
    Assert.Pass('Windows did not let the test runner activate a form');
  Assert.AreSame(LGeneral, TVclHelpChatAI.CurrentAssistant);
end;

procedure TCoordinatorTests.CurrentAssistant_Deactivated_IsForgotten;
var
  LMain, LOrders: TForm;
  LGeneral, LExpert: TVclHelpChatAI;
begin
  LMain := NewForm('MainForm');
  LOrders := NewForm('OrderForm');
  LGeneral := NewAssistant(LMain);
  LExpert := NewAssistant(LOrders);
  LGeneral.Active := True;
  LExpert.Active := True;
  if not Activate(LOrders) then
    Assert.Pass('Windows did not let the test runner activate a form');
  LExpert.Active := False;
  Assert.AreSame(LGeneral, TVclHelpChatAI.CurrentAssistant);
  LGeneral.Active := False;
  Assert.IsNull(TVclHelpChatAI.CurrentAssistant, 'nobody is left');
end;

procedure TCoordinatorTests.SameProfile_ShareTheEngine;
var
  LFirst, LSecond, LGeneral: TVclHelpChatAI;
begin
  // Two order windows open at once, and the main form.
  LFirst := NewAssistant(NewForm('OrderForm1'));
  LFirst.Profile := 'Orders';
  LSecond := NewAssistant(NewForm('OrderForm2'));
  LSecond.Profile := 'Orders';
  LGeneral := NewAssistant(NewForm('MainForm'));
  LFirst.Active := True;
  LSecond.Active := True;
  LGeneral.Active := True;
  Assert.AreSame(LFirst.Engine, LSecond.Engine, 'one order expert, one conversation');
  Assert.AreNotSame(LFirst.Engine, LGeneral.Engine);
  Assert.AreEqual(2, THelpChatEngines.HolderCount(LSecond.Engine));
  LFirst.Active := False;
  Assert.IsNull(LFirst.Engine);
  Assert.AreEqual(1, THelpChatEngines.HolderCount(LSecond.Engine),
    'the first window closed, the second keeps the engine');
end;

procedure TCoordinatorTests.SelectLanguage_IsWhatEveryAssistantOfTheProfileAnswers;
var
  LFirst, LSecond: TVclHelpChatAI;
  LSaved: THelpChatLanguage;
begin
  // The language the user picks is written on the settings of the engine,
  // which the assistants of a profile share: the component must answer with
  // those, not with the copy it was configured from.
  TFile.WriteAllText(FConfigFile,
    '{"Provider": "stub", "PersistConversation": false, "Language": "en", ' +
    '"Languages": ["en", "it"]}', TEncoding.UTF8);
  LSaved := HelpChatDefaultLanguage;
  try
    LFirst := NewAssistant(NewForm('OrderForm1'));
    LFirst.Profile := 'Orders';
    LFirst.Active := True;
    Assert.IsTrue(LFirst.SelectLanguage(hclItalian));
    Assert.AreEqual(Ord(hclItalian), Ord(LFirst.ActiveLanguage));
    Assert.AreEqual(Ord(hclItalian), Ord(HelpChatDefaultLanguage),
      'the language of the process is the one the user picked');
    // A second window of the same expert opens afterwards: same engine, same
    // language - and it must not take the process back to the configured one.
    LSecond := NewAssistant(NewForm('OrderForm2'));
    LSecond.Profile := 'Orders';
    LSecond.Active := True;
    Assert.AreEqual(Ord(hclItalian), Ord(LSecond.ActiveLanguage));
    Assert.AreEqual(Ord(hclItalian), Ord(HelpChatDefaultLanguage));
  finally
    HelpChatDefaultLanguage := LSaved;
  end;
end;

procedure TCoordinatorTests.Actions_OfAnAssistantThatWentAway_AnswerAtOnce;
var
  LFirst, LSecond: TVclHelpChatAI;
  LActions: IHelpChatActionInvoker;
  LResult: string;
  LTick: Cardinal;
begin
  // Two windows of one expert share the engine, so closing one no longer
  // stops the replies it asked for: a worker may call an action of a window
  // that is gone. Nobody will ever run it, and the worker must not be parked
  // for the whole timeout of the broker waiting for somebody who left.
  LFirst := NewAssistant(NewForm('OrderForm1'));
  LFirst.Profile := 'Orders';
  LSecond := NewAssistant(NewForm('OrderForm2'));
  LSecond.Profile := 'Orders';
  LSecond.Actions.Add('create_order', 'Creates an order.',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      AResult := 'created';
    end, False);
  LFirst.Active := True;
  LSecond.Active := True;
  LActions := LSecond.Transport.GetActions;   // what a reply in flight holds
  LSecond.Active := False;
  LTick := GetTickCount;
  Assert.AreEqual(Ord(aoCancelled), Ord(LActions.Invoke('create_order', '{}', nil, LResult)));
  Assert.IsTrue(GetTickCount - LTick < 2000, 'answered at once, not after the timeout');
end;

initialization
  TDUnitX.RegisterTestFixture(TCoordinatorTests);

end.
