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
///  Two nodes per secret: the clear one of the developer, read by the IDE,
///  and the encrypted one of the application, read at run time through
///  OnDecryptSecret - which sees nothing else.
/// </summary>
unit HelpChatAI.Tests.SecretNodes;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  HelpChatAI.Settings;

type
  [TestFixture]
  TSecretNodesTests = class
  strict private
    FCalls: Integer;
    procedure Reverse(Sender: TObject; const AName, AValue: string;
      var AResult: string; var AHandled: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure RunTime_TheEncryptedNodeWins;
    [Test]
    procedure RunTime_OnlyTheClearNode_IsUsedAsItIs;
    [Test]
    procedure DesignTime_TheClearNodeWins;
    [Test]
    procedure DesignTime_OnlyTheEncryptedNode_ComesAsItIs;
    [Test]
    procedure Json_BothNodes_RoundTrip;
    [Test]
    procedure Model_BringsItsOwnNodes;
    [Test]
    procedure Remote_HasTwoNodesToo;
  end;

implementation

uses
  System.StrUtils;

procedure TSecretNodesTests.Setup;
begin
  FCalls := 0;
  HelpChatDesignTime := False;
end;

procedure TSecretNodesTests.TearDown;
begin
  HelpChatDesignTime := False;
end;

procedure TSecretNodesTests.Reverse(Sender: TObject; const AName, AValue: string;
  var AResult: string; var AHandled: Boolean);
begin
  Inc(FCalls);
  AResult := ReverseString(AValue);
  AHandled := True;
end;

procedure TSecretNodesTests.RunTime_TheEncryptedNodeWins;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetSecretHandler(Reverse);
    LSettings.Claude.ApiKey := 'sk-clear-of-the-developer';
    LSettings.Claude.ApiKeyEncrypted := 'tpyrcne';
    Assert.AreEqual('encrypt', LSettings.Claude.ResolveApiKey,
      'on the developer''s machine the application runs the path of the customer');
    Assert.AreEqual(1, FCalls);
  finally
    LSettings.Free;
  end;
end;

procedure TSecretNodesTests.RunTime_OnlyTheClearNode_IsUsedAsItIs;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetSecretHandler(Reverse);
    LSettings.Claude.ApiKey := 'sk-clear';
    Assert.AreEqual('sk-clear', LSettings.Claude.ResolveApiKey,
      'an application that encrypts nothing still runs');
    Assert.AreEqual(0, FCalls, 'a clear value never reaches the handler');
  finally
    LSettings.Free;
  end;
end;

procedure TSecretNodesTests.DesignTime_TheClearNodeWins;
var
  LSettings: THelpChatSettings;
begin
  HelpChatDesignTime := True;
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetSecretHandler(Reverse);
    LSettings.Claude.ApiKey := 'sk-clear';
    LSettings.Claude.ApiKeyEncrypted := 'tpyrcne';
    Assert.AreEqual('sk-clear', LSettings.Claude.ResolveApiKey,
      'the IDE works with the developer''s key');
    Assert.AreEqual(0, FCalls, 'no handler of the application runs in the IDE');
  finally
    LSettings.Free;
  end;
end;

procedure TSecretNodesTests.DesignTime_OnlyTheEncryptedNode_ComesAsItIs;
var
  LSettings: THelpChatSettings;
begin
  HelpChatDesignTime := True;
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Claude.ApiKeyEncrypted := 'tpyrcne';
    Assert.AreEqual('tpyrcne', LSettings.Claude.ResolveApiKey,
      'a check only asks whether there is a key');
    Assert.IsTrue(LSettings.Claude.HasConfiguredApiKey);
  finally
    LSettings.Free;
  end;
end;

procedure TSecretNodesTests.Json_BothNodes_RoundTrip;
var
  LSettings, LCopy: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  LCopy := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"Claude": {"ApiKey": "a", "ApiKeyEncrypted": "b"},' +
      ' "Remote": {"AppKey": "c", "AppKeyEncrypted": "d", "UserToken": "e", "UserTokenEncrypted": "f"},' +
      ' "Models": [{"Name": "M", "Provider": "claude", "ApiKey": "g", "ApiKeyEncrypted": "h"}]}');
    LCopy.LoadFromJSON(LSettings.SaveToJSON);
    Assert.AreEqual('a', LCopy.Claude.ApiKey);
    Assert.AreEqual('b', LCopy.Claude.ApiKeyEncrypted);
    Assert.AreEqual('d', LCopy.Remote.AppKeyEncrypted);
    Assert.AreEqual('f', LCopy.Remote.UserTokenEncrypted);
    Assert.AreEqual('h', LCopy.Models[0].ApiKeyEncrypted);
  finally
    LCopy.Free;
    LSettings.Free;
  end;
end;

procedure TSecretNodesTests.Model_BringsItsOwnNodes;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetSecretHandler(Reverse);
    LSettings.Claude.ApiKey := 'sk-section';
    with LSettings.Models.Add do
    begin
      Name := 'Own';
      Provider := 'claude';
      ApiKeyEncrypted := 'nwo';
    end;
    Assert.IsTrue(LSettings.ApplyModel('Own'));
    Assert.AreEqual('own', LSettings.Claude.ResolveApiKey,
      'the model chosen in the panel brings its key as a whole');
  finally
    LSettings.Free;
  end;
end;

procedure TSecretNodesTests.Remote_HasTwoNodesToo;
var
  LSettings: THelpChatSettings;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.SetSecretHandler(Reverse);
    LSettings.Remote.AppKey := 'app-clear';
    Assert.AreEqual('app-clear', LSettings.Remote.ResolveAppKey);
    LSettings.Remote.AppKeyEncrypted := 'ppa';
    Assert.AreEqual('app', LSettings.Remote.ResolveAppKey);
  finally
    LSettings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSecretNodesTests);

end.
