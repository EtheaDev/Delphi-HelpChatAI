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
///  Areas of one manual: the index builder writes the area of each page (its
///  sub-folder, or its front matter), the index answers an assistant from its
///  areas and from the pages of no area, and the settings say which areas an
///  assistant knows.
/// </summary>
unit HelpChatAI.Tests.Areas;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  TAreasTests = class
  public
    [Test]
    procedure Builder_AreaIsTheSubFolder;
    [Test]
    procedure Builder_FrontMatterWins;
    [Test]
    procedure Builder_WritesAreasOnlyWhenThereAreSome;
    [Test]
    procedure Index_AnswersFromTheAreasAndFromThePagesOfNone;
    [Test]
    procedure Index_NoAreas_IsTheWholeManual;
    [Test]
    procedure Index_OtherAreas_AreNotSearched;
    [Test]
    procedure Settings_DocAreas_StringOrArray;
    [Test]
    procedure Engine_GivesTheAreasToTheIndex;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Engine,
  HelpChatAI.DocIndex,
  HelpChatAI.IndexBuilder;

const
  // Orders and Planning are two areas, Welcome belongs to everybody.
  INDEX =
    '[' +
    '{"title": "Welcome", "url": "Welcome.md", "summary": "", "keywords": [],' +
    ' "text": "Welcome to the application: orders, planning and everything else."},' +
    '{"title": "New order", "url": "Orders/New-Order.md", "summary": "", "keywords": [],' +
    ' "areas": ["Orders"], "text": "To create an order press New order and add the lines."},' +
    '{"title": "Order lines", "url": "Orders/Lines.md", "summary": "", "keywords": [],' +
    ' "areas": ["Orders"], "text": "Every line of an order has a product and a quantity."},' +
    '{"title": "Shifts", "url": "Planning/Shifts.md", "summary": "", "keywords": [],' +
    ' "areas": ["Planning"], "text": "A shift is planned for a week. An order of the customer moves it."},' +
    '{"title": "Customers", "url": "Shared/Customers.md", "summary": "", "keywords": [],' +
    ' "areas": ["Orders", "Planning"], "text": "A customer places orders and has shifts."}' +
    ']';

function Titles(const APages: TArray<THelpChatDocPage>): string;
var
  LPage: THelpChatDocPage;
begin
  Result := '';
  for LPage in APages do
    Result := Result + '|' + LPage.Title;
  Result := Result + '|';
end;

procedure TAreasTests.Builder_AreaIsTheSubFolder;
var
  LAreas: TArray<string>;
begin
  LAreas := THelpChatIndexBuilder.ExtractAreas('', 'Orders/New-Order.md');
  Assert.AreEqual(1, Length(LAreas));
  Assert.AreEqual('Orders', LAreas[0]);
  LAreas := THelpChatIndexBuilder.ExtractAreas('', 'Orders/Returns/Refund.md');
  Assert.AreEqual('Orders', LAreas[0], 'the first folder: an area is one level');
  Assert.AreEqual(0, Length(THelpChatIndexBuilder.ExtractAreas('', 'Welcome.md')),
    'a page at the root belongs to everybody');
end;

procedure TAreasTests.Builder_FrontMatterWins;
var
  LAreas: TArray<string>;
begin
  LAreas := THelpChatIndexBuilder.ExtractAreas('title: Customers'#10'areas: [Orders, Planning]',
    'Shared/Customers.md');
  Assert.AreEqual(2, Length(LAreas));
  Assert.AreEqual('Orders', LAreas[0]);
  Assert.AreEqual('Planning', LAreas[1]);
  LAreas := THelpChatIndexBuilder.ExtractAreas('areas: Orders, "Planning"', 'x/y.md');
  Assert.AreEqual('Planning', LAreas[1], 'commas and quotes as well');
  Assert.AreEqual(0, Length(THelpChatIndexBuilder.ExtractAreas('areas: []', 'Orders/Faq.md')),
    'said empty: everybody''s, whatever its folder');
  // The key with nothing after it, and another key on the next line: still
  // "none", not an area named after that line.
  Assert.AreEqual(0, Length(THelpChatIndexBuilder.ExtractAreas(
    'areas:'#10'title: Welcome', 'Orders/Faq.md')), 'an empty value is not the next line');
  Assert.AreEqual(0, Length(THelpChatIndexBuilder.ExtractAreas(
    'areas:'#13#10'title: Welcome', 'Orders/Faq.md')), 'nor with CRLF');
  // The block form of YAML.
  LAreas := THelpChatIndexBuilder.ExtractAreas(
    'title: Customers'#10'areas:'#10'  - Orders'#10'  - "Planning"'#10'keywords: x', 'x/y.md');
  Assert.AreEqual(2, Length(LAreas), 'a block list');
  Assert.AreEqual('Orders', LAreas[0]);
  Assert.AreEqual('Planning', LAreas[1]);
end;

procedure TAreasTests.Builder_WritesAreasOnlyWhenThereAreSome;
var
  LFolder: string;
  LBuilder: THelpChatIndexBuilder;
  LOptions: THelpChatIndexBuilderOptions;
  LJson: string;
  LValue: TJSONValue;
  LItem: TJSONValue;
  LAreas: TJSONValue;
begin
  LFolder := TPath.Combine(TPath.GetTempPath, 'helpchatai-areas-test');
  if TDirectory.Exists(LFolder) then
    TDirectory.Delete(LFolder, True);
  TDirectory.CreateDirectory(TPath.Combine(LFolder, 'Orders'));
  TFile.WriteAllText(TPath.Combine(LFolder, 'Welcome.md'), '# Welcome'#10'Hello.');
  TFile.WriteAllText(TPath.Combine(LFolder, 'Orders\New-Order.md'), '# New order'#10'Press New.');
  LBuilder := THelpChatIndexBuilder.Create;
  try
    LOptions := THelpChatIndexBuilderOptions.Default;
    LOptions.SourceFolder := LFolder;
    LOptions.TocFile := '';
    LJson := THelpChatIndexBuilder.ToJSON(LBuilder.Build(LOptions));
  finally
    LBuilder.Free;
    TDirectory.Delete(LFolder, True);
  end;
  LValue := TJSONObject.ParseJSONValue(LJson);
  try
    for LItem in TJSONArray(LValue) do
    begin
      LAreas := TJSONObject(LItem).GetValue('areas');
      if TJSONObject(LItem).GetValue<string>('title') = 'Welcome' then
        Assert.IsNull(LAreas, 'no "areas" for a page of the root')
      else
        Assert.AreEqual('["Orders"]', LAreas.ToJSON);
    end;
  finally
    LValue.Free;
  end;
end;

procedure TAreasTests.Index_AnswersFromTheAreasAndFromThePagesOfNone;
var
  LIndex: THelpChatDocIndex;
  LKeep: IInterface;
  LFound: string;
begin
  LIndex := THelpChatDocIndex.Create;
  LKeep := LIndex;
  LIndex.LoadFromJSON(INDEX);
  LIndex.Areas := ['orders']; // case apart
  LFound := Titles(LIndex.Search('order customer shift welcome', '', 10));
  Assert.Contains(LFound, '|New order|');
  Assert.Contains(LFound, '|Customers|', 'a page of two areas');
  Assert.Contains(LFound, '|Welcome|', 'a page of no area is everybody''s');
  Assert.DoesNotContain(LFound, '|Shifts|', 'the planning page is not the order expert''s');
  Assert.AreEqual(4, Length(LIndex.Pages), '/pages lists the same pages');
  Assert.AreEqual(5, LIndex.Count, 'the index still holds the whole manual');
end;

procedure TAreasTests.Index_NoAreas_IsTheWholeManual;
var
  LIndex: THelpChatDocIndex;
  LKeep: IInterface;
begin
  LIndex := THelpChatDocIndex.Create;
  LKeep := LIndex;
  LIndex.LoadFromJSON(INDEX);
  Assert.AreEqual(5, Length(LIndex.Pages));
  Assert.Contains(Titles(LIndex.Search('shift', '', 10)), '|Shifts|');
end;

procedure TAreasTests.Index_OtherAreas_AreNotSearched;
var
  LIndex: THelpChatDocIndex;
  LKeep: IInterface;
begin
  // The lines of an order are the order expert's: the planner finds nothing,
  // instead of answering about a part of the manual it was not given.
  LIndex := THelpChatDocIndex.Create;
  LKeep := LIndex;
  LIndex.LoadFromJSON(INDEX);
  LIndex.Areas := ['Planning'];
  Assert.AreEqual(0, Length(LIndex.Search('product quantity', '', 10)));
  // An index written by hand may say the area as a string: still an area.
  LIndex.LoadFromJSON('[{"title": "Lines", "url": "x.md", "summary": "", "keywords": [],' +
    ' "areas": "Orders", "text": "Every line has a product and a quantity."}]');
  Assert.AreEqual(0, Length(LIndex.Search('product quantity', '', 10)), 'not everybody''s');
  LIndex.LoadFromJSON(INDEX);
  LIndex.Areas := nil;
  Assert.Contains(Titles(LIndex.Search('product quantity', '', 10)), '|Order lines|');
end;

procedure TAreasTests.Settings_DocAreas_StringOrArray;
var
  LSettings: THelpChatSettings;
  LAreas: TArray<string>;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.LoadFromJSON('{"DocAreas": ["Orders", " Customers "]}');
    Assert.AreEqual('Orders, Customers', LSettings.DocAreas);
    LAreas := LSettings.ResolveDocAreas;
    Assert.AreEqual(2, Length(LAreas));
    Assert.AreEqual('Customers', LAreas[1]);
    LSettings.LoadFromJSON('{"DocAreas": "Planning; Shifts"}');
    Assert.AreEqual(2, Length(LSettings.ResolveDocAreas));
    LSettings.Profile := 'Orders';
    LSettings.LoadFromJSON('{"DocAreas": "", "Profiles": {"Orders": {"DocAreas": ["Orders"]}}}');
    Assert.AreEqual('Orders', LSettings.DocAreas, 'the expert of a profile knows its area');
  finally
    LSettings.Free;
  end;
end;

procedure TAreasTests.Engine_GivesTheAreasToTheIndex;
var
  LSettings: THelpChatSettings;
  LEngine: THelpChatEngine;
  LFile: string;
begin
  LFile := TPath.Combine(TPath.GetTempPath, 'helpchatai-areas-index.json');
  TFile.WriteAllText(LFile, INDEX, TEncoding.UTF8);
  LSettings := THelpChatSettings.Create;
  LSettings.Provider := 'stub';
  LSettings.PersistConversation := False;
  LSettings.DocIndexFile := LFile;
  LSettings.DocAreas := 'Planning';
  LEngine := THelpChatEngine.Create(LSettings, True);
  try
    LEngine.Start;
    Assert.AreEqual(1, Length(LEngine.DocIndex.Areas));
    Assert.DoesNotContain(Titles(LEngine.DocIndex.Pages), '|New order|');
  finally
    LEngine.Free;
    TFile.Delete(LFile);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAreasTests);

end.
