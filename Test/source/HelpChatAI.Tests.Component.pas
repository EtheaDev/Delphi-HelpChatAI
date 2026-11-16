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
///  The VCL component as a whole: what <c>Assign</c> copies, which is what the
///  design-time preview is made of.
/// </summary>
unit HelpChatAI.Tests.Component;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TComponentTests = class
  public
    [Test]
    procedure Assign_CopiesEveryPublishedProperty;
    [Test]
    procedure Assign_CopiesTheIconAndTheContainer_NotActive;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.ImgList,
  Vcl.Forms,
  HelpChatAI.Tests.Helpers,
  Vcl.HelpChatAI;

const
  // What the test sets by hand (references, and the index checked against
  // its list), what Assign leaves alone on purpose, and the profile of the
  // settings, which the component always overwrites with its own; Name and
  // Tag are the identity of a component, not its configuration.
  NOT_FILLED: array[0..7] of string = ('Active', 'Images', 'ImageIndex', 'ImageName',
    'Container', 'Settings.Profile', 'Name', 'Tag');

procedure TComponentTests.Assign_CopiesEveryPublishedProperty;
var
  LSource, LCopy: TVclHelpChatAI;
begin
  // Every published property, the ones added after this test was written
  // included: one missing from Assign is one the preview does not show.
  LSource := TVclHelpChatAI.Create(nil);
  LCopy := TVclHelpChatAI.Create(nil);
  try
    FillPublishedProperties(LSource, NOT_FILLED);
    LCopy.Assign(LSource);
    Assert.AreNotEqual('', LCopy.PanelStyleSheet, 'the filling reached the component');
    Assert.AreNotEqual('', LCopy.Settings.Skills, 'and its settings');
    Assert.AreEqual('', FirstPublishedDifference(LSource, LCopy, NOT_FILLED));
  finally
    LCopy.Free;
    LSource.Free;
  end;
end;

procedure TComponentTests.Assign_CopiesTheIconAndTheContainer_NotActive;
var
  LSource, LCopy: TVclHelpChatAI;
  LImages: TImageList;
  LBitmap: TBitmap;
  LPanel: TPanel;
  I: Integer;
begin
  LImages := TImageList.Create(nil);
  LPanel := TPanel.Create(nil);
  LSource := TVclHelpChatAI.Create(nil);
  LCopy := TVclHelpChatAI.Create(nil);
  try
    LBitmap := TBitmap.Create;
    try
      LBitmap.SetSize(16, 16);
      for I := 1 to 3 do
        LImages.Add(LBitmap, nil);
    finally
      LBitmap.Free;
    end;
    LSource.Images := LImages;
    LSource.ImageIndex := 2;
    LSource.Container := LPanel;
    LCopy.Assign(LSource);
    // The icon changed in the editor is the icon of the preview.
    Assert.AreSame(LImages, LCopy.Images);
    Assert.AreEqual(2, Integer(LCopy.ImageIndex));
    Assert.AreSame(TObject(LPanel), TObject(LCopy.Container));
    Assert.IsFalse(LCopy.Active);
  finally
    LCopy.Free;
    LSource.Free;
    LPanel.Free;
    LImages.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TComponentTests);

end.
