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
///  The UI state without any form: the place of a dragged bubble (nearest
///  corner, distances at 96 DPI, kept inside a smaller form) and the file
///  that remembers it next to the bounds of the chat window, one key never
///  erasing the other.
/// </summary>
unit HelpChatAI.Tests.UiState;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  HelpChatAI.UiState;

type
  [TestFixture]
  TUiStateTests = class
  strict private
    FFile: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Place_TakesTheNearestCorner;
    [Test]
    procedure Place_IsAt96Dpi_AndComesBackAtAnotherDpi;
    [Test]
    procedure Place_StaysInsideASmallerForm;
    [Test]
    procedure Bubbles_PerForm_KeepThePanel;
    [Test]
    procedure Panel_KeepsTheBubbles;
    [Test]
    procedure Forget_TakesOneFormAway;
    [Test]
    procedure BrokenFile_RemembersNothing_AndIsWrittenAgain;
  end;

implementation

uses
  System.IOUtils,
  System.JSON;

procedure TUiStateTests.Setup;
begin
  FFile := TPath.Combine(TPath.GetTempPath, 'helpchatai-uistate-test.json');
  if TFile.Exists(FFile) then
    TFile.Delete(FFile);
end;

procedure TUiStateTests.TearDown;
begin
  if TFile.Exists(FFile) then
    TFile.Delete(FFile);
end;

procedure TUiStateTests.Place_TakesTheNearestCorner;
var
  LPlace: THelpChatBubblePlace;
begin
  // A form of 800 x 600, a bubble of 44.
  LPlace := THelpChatBubblePlace.FromBounds(20, 30, 44, 800, 600, 1);
  Assert.AreEqual(Ord(hbcTopLeft), Ord(LPlace.Corner));
  Assert.AreEqual(20, LPlace.OffsetX);
  Assert.AreEqual(30, LPlace.OffsetY);

  LPlace := THelpChatBubblePlace.FromBounds(700, 40, 44, 800, 600, 1);
  Assert.AreEqual(Ord(hbcTopRight), Ord(LPlace.Corner));
  Assert.AreEqual(800 - 700 - 44, LPlace.OffsetX);
  Assert.AreEqual(40, LPlace.OffsetY);

  LPlace := THelpChatBubblePlace.FromBounds(10, 500, 44, 800, 600, 1);
  Assert.AreEqual(Ord(hbcBottomLeft), Ord(LPlace.Corner));
  Assert.AreEqual(10, LPlace.OffsetX);
  Assert.AreEqual(600 - 500 - 44, LPlace.OffsetY);

  // The default place is the bottom-right corner it always was.
  LPlace := THelpChatBubblePlace.FromBounds(800 - 44 - 16, 600 - 44 - 16, 44, 800, 600, 1);
  Assert.AreEqual(Ord(hbcBottomRight), Ord(LPlace.Corner));
  Assert.AreEqual(16, LPlace.OffsetX);
  Assert.AreEqual(16, LPlace.OffsetY);
end;

procedure TUiStateTests.Place_IsAt96Dpi_AndComesBackAtAnotherDpi;
var
  LPlace: THelpChatBubblePlace;
  LLeft, LTop: Single;
begin
  // Taken at 150%: 30 pixels from the left are 20 at 96 DPI.
  LPlace := THelpChatBubblePlace.FromBounds(30, 60, 66, 1200, 900, 1.5);
  Assert.AreEqual(Ord(hbcTopLeft), Ord(LPlace.Corner));
  Assert.AreEqual(20, LPlace.OffsetX);
  Assert.AreEqual(40, LPlace.OffsetY);
  // Shown at 200%, on a form whose size is another.
  LPlace.ToPosition(88, 1600, 1200, 2, LLeft, LTop);
  Assert.AreEqual(40.0, Double(LLeft), 0.01);
  Assert.AreEqual(80.0, Double(LTop), 0.01);

  // A right corner counts from the right edge, whatever the width.
  LPlace := THelpChatBubblePlace.Create(hbcBottomRight, 16, 16);
  LPlace.ToPosition(88, 1600, 1200, 2, LLeft, LTop);
  Assert.AreEqual(1600.0 - 88 - 32, Double(LLeft), 0.01);
  Assert.AreEqual(1200.0 - 88 - 32, Double(LTop), 0.01);
end;

procedure TUiStateTests.Place_StaysInsideASmallerForm;
var
  LPlace: THelpChatBubblePlace;
  LLeft, LTop: Single;
begin
  // Left 700 from the left of a wide form, shown on a narrow one.
  LPlace := THelpChatBubblePlace.Create(hbcTopLeft, 700, 500);
  LPlace.ToPosition(44, 400, 300, 1, LLeft, LTop);
  Assert.AreEqual(400.0 - 44, Double(LLeft), 0.01);
  Assert.AreEqual(300.0 - 44, Double(LTop), 0.01);
  // A form narrower than the bubble: at the left edge, never negative.
  LPlace := THelpChatBubblePlace.Create(hbcBottomRight, 16, 16);
  LPlace.ToPosition(44, 30, 30, 1, LLeft, LTop);
  Assert.AreEqual(0.0, Double(LLeft), 0.01);
  Assert.AreEqual(0.0, Double(LTop), 0.01);
end;

procedure TUiStateTests.Bubbles_PerForm_KeepThePanel;
var
  LPanel: TJSONObject;
  LRoot: TJSONObject;
  LPlace: THelpChatBubblePlace;
begin
  LPanel := TJSONObject.Create;
  LPanel.AddPair('left', TJSONNumber.Create(100));
  Assert.IsTrue(HelpChatUiStateWrite(FFile, HELPCHAT_UI_STATE_PANEL, LPanel));

  Assert.IsTrue(HelpChatSaveBubblePlace(FFile, 'TMainForm',
    THelpChatBubblePlace.Create(hbcTopLeft, 20, 30)));
  Assert.IsTrue(HelpChatSaveBubblePlace(FFile, 'TOrderForm',
    THelpChatBubblePlace.Create(hbcBottomLeft, 5, 6)));

  Assert.IsTrue(HelpChatLoadBubblePlace(FFile, 'TMainForm', LPlace));
  Assert.AreEqual(Ord(hbcTopLeft), Ord(LPlace.Corner));
  Assert.AreEqual(20, LPlace.OffsetX);
  Assert.AreEqual(30, LPlace.OffsetY);
  Assert.IsTrue(HelpChatLoadBubblePlace(FFile, 'TOrderForm', LPlace));
  Assert.AreEqual(Ord(hbcBottomLeft), Ord(LPlace.Corner));
  Assert.IsFalse(HelpChatLoadBubblePlace(FFile, 'TOtherForm', LPlace));

  LRoot := HelpChatUiStateLoad(FFile);
  try
    Assert.IsTrue(LRoot.GetValue(HELPCHAT_UI_STATE_PANEL) is TJSONObject,
      'moving the bubble forgot the window');
    Assert.AreEqual(100, TJSONObject(LRoot.GetValue(HELPCHAT_UI_STATE_PANEL)).GetValue<Integer>('left'));
  finally
    LRoot.Free;
  end;
end;

procedure TUiStateTests.Panel_KeepsTheBubbles;
var
  LPanel: TJSONObject;
  LPlace: THelpChatBubblePlace;
begin
  HelpChatSaveBubblePlace(FFile, 'TMainForm', THelpChatBubblePlace.Create(hbcTopRight, 7, 8));
  // What SavePanelBounds of both components does.
  LPanel := TJSONObject.Create;
  LPanel.AddPair('left', TJSONNumber.Create(1));
  HelpChatUiStateWrite(FFile, HELPCHAT_UI_STATE_PANEL, LPanel);
  Assert.IsTrue(HelpChatLoadBubblePlace(FFile, 'TMainForm', LPlace),
    'saving the window forgot the bubble');
  Assert.AreEqual(Ord(hbcTopRight), Ord(LPlace.Corner));
  Assert.AreEqual(7, LPlace.OffsetX);
  Assert.AreEqual(8, LPlace.OffsetY);
end;

procedure TUiStateTests.Forget_TakesOneFormAway;
var
  LPlace: THelpChatBubblePlace;
  LRoot: TJSONObject;
begin
  HelpChatSaveBubblePlace(FFile, 'TMainForm', THelpChatBubblePlace.Create(hbcTopLeft, 1, 2));
  HelpChatSaveBubblePlace(FFile, 'TOrderForm', THelpChatBubblePlace.Create(hbcTopLeft, 3, 4));
  Assert.IsTrue(HelpChatForgetBubblePlace(FFile, 'TMainForm'));
  Assert.IsFalse(HelpChatLoadBubblePlace(FFile, 'TMainForm', LPlace));
  Assert.IsTrue(HelpChatLoadBubblePlace(FFile, 'TOrderForm', LPlace));
  // The last one forgotten takes the key away, not an empty object.
  HelpChatForgetBubblePlace(FFile, 'TOrderForm');
  LRoot := HelpChatUiStateLoad(FFile);
  try
    Assert.IsNull(LRoot.GetValue(HELPCHAT_UI_STATE_BUBBLES));
  finally
    LRoot.Free;
  end;
end;

procedure TUiStateTests.BrokenFile_RemembersNothing_AndIsWrittenAgain;
var
  LPlace: THelpChatBubblePlace;
  LRoot: TJSONObject;
begin
  TFile.WriteAllText(FFile, '{ not json', TEncoding.UTF8);
  Assert.IsFalse(HelpChatLoadBubblePlace(FFile, 'TMainForm', LPlace));
  LRoot := HelpChatUiStateLoad(FFile);
  try
    Assert.AreEqual(0, LRoot.Count);
  finally
    LRoot.Free;
  end;
  // A corner nobody knows is no place either.
  TFile.WriteAllText(FFile, '{"bubbles":{"TMainForm":{"corner":"middle","x":1,"y":2}}}', TEncoding.UTF8);
  Assert.IsFalse(HelpChatLoadBubblePlace(FFile, 'TMainForm', LPlace));
  Assert.IsTrue(HelpChatSaveBubblePlace(FFile, 'TMainForm', THelpChatBubblePlace.Create(hbcTopLeft, 1, 2)));
  Assert.IsTrue(HelpChatLoadBubblePlace(FFile, 'TMainForm', LPlace));
end;

initialization
  TDUnitX.RegisterTestFixture(TUiStateTests);

end.
