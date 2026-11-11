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
///  What an assistant may do: the actions of its component, those every
///  assistant shares, and what its profile allows of both - narrowed, never
///  widened. A shared action runs through the broker of the assistant that
///  was asked, confirmation included.
/// </summary>
unit HelpChatAI.Tests.ActionScope;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  HelpChatAI.Actions;

type
  [TestFixture]
  TActionScopeTests = class
  strict private
    FOwn, FShared: THelpChatActionBroker;
    FOwnRef, FSharedRef: IHelpChatActionInvoker;
    FRan: string;
    FConfirmed: string;
    procedure Pending(Sender: TObject);
    procedure Confirm(Sender: TObject; const AName: string;
      const AArgs: THelpChatActionArgs; var AAllow: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Shared_AreOfferedAfterTheOwn;
    [Test]
    procedure Shared_AnOwnActionOfTheSameNameRedefinesIt;
    [Test]
    procedure Shared_RunsThroughTheBrokerThatWasAsked;
    [Test]
    procedure Allowed_NarrowsOwnAndShared;
    [Test]
    procedure Allowed_NothingLeft_NoActions;
    [Test]
    procedure Settings_AllowedActions_StringOrArray;
    [Test]
    procedure SharedActions_IsOnePerProcess;
    [Test]
    procedure HostGone_AnswersCancelledAtOnce_AndComesBack;
  end;

implementation

uses
  HelpChatAI.Settings;

procedure TActionScopeTests.Setup;
begin
  FRan := '';
  FConfirmed := '';
  FOwn := THelpChatActionBroker.Create;
  FOwnRef := FOwn;
  FShared := THelpChatActionBroker.Create;
  FSharedRef := FShared;
  FShared.Add('open_screen', 'Brings a screen to the front.',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan := FRan + 'shared:open_screen ';
      AResult := 'opened';
    end, False);
  FShared.Add('find_customer', 'Finds a customer.',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan := FRan + 'shared:find_customer ';
      AResult := 'found';
    end);
  FOwn.Add('create_order', 'Creates an order.',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan := FRan + 'own:create_order ';
      AResult := 'created';
    end);
  FOwn.Shared := FShared;
  // The host: what a component does on its main thread, done at once.
  FOwn.OnPending := Pending;
  FOwn.OnConfirm := Confirm;
end;

procedure TActionScopeTests.TearDown;
begin
  FOwn.Shared := nil;
  FOwn.OnPending := nil;
  FOwn.OnConfirm := nil;
  FOwn := nil;
  FShared := nil;
  FOwnRef := nil;
  FSharedRef := nil;
end;

procedure TActionScopeTests.Pending(Sender: TObject);
begin
  THelpChatActionBroker(Sender).ExecutePending;
end;

procedure TActionScopeTests.Confirm(Sender: TObject; const AName: string;
  const AArgs: THelpChatActionArgs; var AAllow: Boolean);
begin
  FConfirmed := FConfirmed + AName + ' ';
  AAllow := True;
end;

procedure TActionScopeTests.Shared_AreOfferedAfterTheOwn;
var
  LNames: TArray<string>;
begin
  LNames := FOwn.AvailableNames;
  Assert.AreEqual(3, Length(LNames));
  Assert.AreEqual('create_order', LNames[0], 'the own first');
  Assert.AreEqual('open_screen', LNames[1]);
  Assert.Contains(FOwn.ToolsJson, 'find_customer');
  Assert.AreEqual(1, Length(FOwn.Names), 'the own registry is untouched');
end;

procedure TActionScopeTests.Shared_AnOwnActionOfTheSameNameRedefinesIt;
var
  LResult: string;
begin
  FOwn.Add('open_screen', 'Opens a page of the order form.',
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    begin
      FRan := FRan + 'own:open_screen ';
    end, False);
  Assert.AreEqual(3, Length(FOwn.AvailableNames), 'not twice');
  Assert.Contains(FOwn.ToolsJson, 'Opens a page of the order form.');
  Assert.DoesNotContain(FOwn.ToolsJson, 'Brings a screen to the front.');
  FOwn.Invoke('open_screen', '{}', nil, LResult);
  Assert.AreEqual('own:open_screen ', FRan);
end;

procedure TActionScopeTests.Shared_RunsThroughTheBrokerThatWasAsked;
var
  LResult: string;
begin
  Assert.AreEqual(Ord(aoDone), Ord(FOwn.Invoke('find_customer', '{}', nil, LResult)));
  Assert.AreEqual('found', LResult);
  Assert.AreEqual('shared:find_customer ', FRan);
  Assert.AreEqual('find_customer ', FConfirmed,
    'asked by the assistant that was asked, with its own dialog');
end;

procedure TActionScopeTests.Allowed_NarrowsOwnAndShared;
var
  LResult: string;
begin
  FOwn.Allowed := ['CREATE_ORDER', ' open_screen ', 'delete_everything'];
  Assert.AreEqual(2, Length(FOwn.AvailableNames),
    'an allowed name that nobody registered gives nothing');
  Assert.DoesNotContain(FOwn.ToolsJson, 'find_customer');
  Assert.AreEqual(Ord(aoUnknown), Ord(FOwn.Invoke('find_customer', '{}', nil, LResult)),
    'not offered, and not callable either');
  Assert.AreEqual('', FRan);
  Assert.AreEqual(Ord(aoDone), Ord(FOwn.Invoke('create_order', '{}', nil, LResult)));
end;

procedure TActionScopeTests.Allowed_NothingLeft_NoActions;
begin
  FOwn.Allowed := ['delete_everything'];
  Assert.IsFalse(FOwn.HasActions);
  Assert.AreEqual('[]', FOwn.ToolsJson);
  FOwn.Allowed := nil;
  Assert.IsTrue(FOwn.HasActions, 'empty = all of them');
end;

procedure TActionScopeTests.Settings_AllowedActions_StringOrArray;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Profile := 'Orders';
    LSettings.LoadFromJSON('{"AllowedActions": "open_screen", ' +
      '"Profiles": {"Orders": {"AllowedActions": ["create_order", "open_screen"]}}}');
    Assert.AreEqual('create_order, open_screen', LSettings.AllowedActions);
    Assert.AreEqual(2, Length(LSettings.ResolveAllowedActions));
  finally
    LSettings.Free;
  end;
end;

procedure TActionScopeTests.SharedActions_IsOnePerProcess;
begin
  Assert.IsNotNull(HelpChatSharedActions);
  Assert.AreSame(HelpChatSharedActions, HelpChatSharedActions);
end;

procedure TActionScopeTests.HostGone_AnswersCancelledAtOnce_AndComesBack;
var
  LResult: string;
begin
  // The component of an assistant deactivated: nobody will run its actions,
  // and a reply still in flight on the shared engine must be told at once.
  FOwn.HostActive := False;
  Assert.AreEqual(Ord(aoCancelled), Ord(FOwn.Invoke('create_order', '{}', nil, LResult)));
  Assert.AreEqual('', FRan, 'nothing ran');
  Assert.AreEqual(0, FOwn.PendingCount, 'and nothing is left waiting');
  Assert.IsTrue(FOwn.HasActions, 'the actions stay registered');
  // Activated again: everything works as before.
  FOwn.HostActive := True;
  Assert.AreEqual(Ord(aoDone), Ord(FOwn.Invoke('create_order', '{}', nil, LResult)));
  Assert.AreEqual('created', LResult);
end;

initialization
  TDUnitX.RegisterTestFixture(TActionScopeTests);

end.
