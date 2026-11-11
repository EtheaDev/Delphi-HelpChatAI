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
///  One engine per profile: shared by the assistants that name it, freed by
///  the last; the secret handler of whoever still holds it; the actions of
///  the assistant that asks, carried by the question and not by the engine.
/// </summary>
unit HelpChatAI.Tests.SharedEngine;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  HelpChatAI.Settings,
  HelpChatAI.Engine;

type
  [TestFixture]
  TSharedEngineTests = class
  strict private
    FSecretsAsked: string;
    procedure DecryptA(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
    procedure DecryptB(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
    function NewSettings(const AProfile: string): THelpChatSettings;
  public
    [Test]
    procedure SameProfile_SameEngine_FreedByTheLast;
    [Test]
    procedure OtherProfile_OtherEngine;
    [Test]
    procedure TheEngine_OwnsACopyOfTheSettings;
    [Test]
    procedure Secrets_AreAskedOfWhoStillHoldsTheEngine;
    [Test]
    procedure Actions_TravelWithTheCommand;
  end;

implementation

uses
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Actions,
  HelpChatAI.Commands;

function TSharedEngineTests.NewSettings(const AProfile: string): THelpChatSettings;
begin
  Result := THelpChatSettings.Create;
  Result.Profile := AProfile;
  Result.Provider := 'stub';
  Result.PersistConversation := False;
  Result.Language := hclEnglish;
end;

procedure TSharedEngineTests.DecryptA(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  FSecretsAsked := FSecretsAsked + 'A';
  AResult := 'A:' + AValue;
  AHandled := True;
end;

procedure TSharedEngineTests.DecryptB(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  FSecretsAsked := FSecretsAsked + 'B';
  AResult := 'B:' + AValue;
  AHandled := True;
end;

procedure TSharedEngineTests.SameProfile_SameEngine_FreedByTheLast;
var
  LFirst, LSecond: THelpChatSettings;
  LHolderA, LHolderB: TObject;
  LEngineA, LEngineB, LKept: THelpChatEngine;
begin
  LFirst := NewSettings('Orders');
  LSecond := NewSettings('orders'); // a profile is a name: case apart
  LHolderA := TObject.Create;
  LHolderB := TObject.Create;
  try
    LEngineA := THelpChatEngines.Acquire(LHolderA, LFirst);
    LEngineB := THelpChatEngines.Acquire(LHolderB, LSecond);
    Assert.AreSame(LEngineA, LEngineB, 'two order windows, one order expert');
    Assert.AreEqual(2, THelpChatEngines.HolderCount(LEngineA));
    LKept := LEngineA;
    THelpChatEngines.Release(LHolderA, LEngineA);
    Assert.IsNull(LEngineA, 'the reference of who released it is cleared');
    Assert.AreEqual(1, THelpChatEngines.HolderCount(LKept), 'still held by the other window');
    THelpChatEngines.Release(LHolderB, LEngineB);
    Assert.AreEqual(0, THelpChatEngines.HolderCount(LKept), 'the last one freed it');
  finally
    LHolderB.Free;
    LHolderA.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TSharedEngineTests.OtherProfile_OtherEngine;
var
  LOrders, LDefault: THelpChatSettings;
  LHolderA, LHolderB: TObject;
  LEngineA, LEngineB: THelpChatEngine;
begin
  LOrders := NewSettings('Orders');
  LDefault := NewSettings('');
  LHolderA := TObject.Create;
  LHolderB := TObject.Create;
  try
    LEngineA := THelpChatEngines.Acquire(LHolderA, LOrders);
    LEngineB := THelpChatEngines.Acquire(LHolderB, LDefault);
    try
      Assert.AreNotSame(LEngineA, LEngineB);
      Assert.AreEqual('Orders', LEngineA.Settings.Profile);
      Assert.AreEqual('', LEngineB.Settings.Profile, 'the default assistant is a profile too');
    finally
      THelpChatEngines.Release(LHolderB, LEngineB);
      THelpChatEngines.Release(LHolderA, LEngineA);
    end;
  finally
    LHolderB.Free;
    LHolderA.Free;
    LDefault.Free;
    LOrders.Free;
  end;
end;

procedure TSharedEngineTests.TheEngine_OwnsACopyOfTheSettings;
var
  LSettings: THelpChatSettings;
  LHolder: TObject;
  LEngine: THelpChatEngine;
begin
  LSettings := NewSettings('Planning');
  LSettings.Instructions := 'You plan.';
  LHolder := TObject.Create;
  try
    LEngine := THelpChatEngines.Acquire(LHolder, LSettings);
    try
      Assert.AreNotSame(LSettings, LEngine.Settings,
        'the first holder may go while the others still use the engine');
      Assert.AreEqual('You plan.', LEngine.Settings.Instructions);
    finally
      THelpChatEngines.Release(LHolder, LEngine);
    end;
  finally
    LHolder.Free;
    LSettings.Free;
  end;
end;

procedure TSharedEngineTests.Secrets_AreAskedOfWhoStillHoldsTheEngine;
var
  LFirst, LSecond: THelpChatSettings;
  LHolderA, LHolderB: TObject;
  LEngineA, LEngineB: THelpChatEngine;
begin
  LFirst := NewSettings('Secrets');
  LFirst.SetSecretHandler(DecryptA);
  LSecond := NewSettings('Secrets');
  LSecond.SetSecretHandler(DecryptB);
  LHolderA := TObject.Create;
  LHolderB := TObject.Create;
  try
    LEngineA := THelpChatEngines.Acquire(LHolderA, LFirst);
    LEngineB := THelpChatEngines.Acquire(LHolderB, LSecond);
    try
      Assert.AreEqual('A:x', LEngineB.Settings.RevealSecret('Claude.ApiKey', 'x'),
        'the handler of the first holder');
      THelpChatEngines.Release(LHolderA, LEngineA);
      // The first window closed: its handler must not be called any more.
      Assert.AreEqual('B:x', LEngineB.Settings.RevealSecret('Claude.ApiKey', 'x'));
      Assert.AreEqual('AB', FSecretsAsked);
    finally
      THelpChatEngines.Release(LHolderB, LEngineB);
    end;
  finally
    LHolderB.Free;
    LHolderA.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TSharedEngineTests.Actions_TravelWithTheCommand;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LOrders, LPlanning: THelpChatActionBroker;
  LOrdersRef, LPlanningRef: IHelpChatActionInvoker;
  LRequest: THelpChatCommandRequest;
  LHtml: string;
begin
  LSettings := NewSettings('');
  LEngine := THelpChatEngine.Create(LSettings, True);
  LOrders := THelpChatActionBroker.Create;
  LOrdersRef := LOrders;
  LPlanning := THelpChatActionBroker.Create;
  LPlanningRef := LPlanning;
  try
    LOrders.Add('create_order', 'Creates an order.',
      procedure(const AArgs: THelpChatActionArgs; var AResult: string)
      begin
        AResult := 'ok';
      end);
    LPlanning.Add('move_shift', 'Moves a shift.',
      procedure(const AArgs: THelpChatActionArgs; var AResult: string)
      begin
        AResult := 'ok';
      end);
    // The engine's own, which a question that brings its actions overrides.
    LEngine.Actions := LPlanningRef;
    LEngine.Start;
    LRequest := Default(THelpChatCommandRequest);
    LRequest.Command := hccActions;
    LRequest.ConversationKey := LEngine.ConversationKey;
    LRequest.Language := hclEnglish;
    LRequest.Actions := LOrdersRef;
    LHtml := HelpChatRunCommand(LEngine, LRequest);
    Assert.Contains(LHtml, 'create_order', 'the actions of the assistant that asks');
    Assert.DoesNotContain(LHtml, 'move_shift');
    LRequest.Actions := nil;
    LHtml := HelpChatRunCommand(LEngine, LRequest);
    Assert.Contains(LHtml, 'move_shift', 'none brought: the engine''s');
  finally
    LEngine.Free;
    LPlanningRef := nil;
    LOrdersRef := nil;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSharedEngineTests);

end.
