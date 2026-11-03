{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                            }
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
{  See the License for the specific language governing permissions and        }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

/// <summary>
///  Saving a document as PDF: the sheet of paper, the file name offered to the
///  user, the printable document built out of Markdown or out of a
///  conversation, and the settings round trip. The last test writes a real
///  PDF with the WebView2 runtime of the machine and skips itself where there
///  is none - everything else is pure RTL and needs nothing installed.
/// </summary>
unit HelpChatAI.Tests.Pdf;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPdfTests = class
  public
    [Test] procedure Page_A4_IsTheDefault;
    [Test] procedure Page_Letter_AndByName;
    [Test] procedure Page_SetMargins_SetsAllFour;
    [Test] procedure FileName_DropsWhatWindowsRefuses;
    [Test] procedure FileName_EmptyTitle_HasAName;
    [Test] procedure FileName_LongTitle_IsCut;
    [Test] procedure Document_IsSelfContained;
    [Test] procedure Document_TitleBlock_OnlyWhenTheBodyHasNone;
    [Test] procedure Document_EncodesTheTitle;
    [Test] procedure Document_FromMarkdown_RendersIt;
    [Test] procedure Document_FromMarkdown_IsStillSafe;
    [Test] procedure Conversation_HasBothSides;
    [Test] procedure Conversation_LeavesOutPendingAndErrors;
    [Test] procedure Settings_RoundTrip;
    [Test] procedure Settings_Page_CarriesWhatWasSet;
    [Test] procedure Bands_Expand_ReplacesAndEscapes;
    [Test] procedure Bands_DefaultInfo_SaysWhoAndWhen;
    [Test] procedure Bands_Page_KnowsWhenItHasThem;
    [Test] procedure Bands_Templates_ComeFromTheResources;
    [Test] procedure Exporter_WritesARealPdf;
    [Test] procedure Exporter_WritesARealPdfWithBands;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
{$IFDEF MSWINDOWS}
  Winapi.ActiveX,
{$ENDIF}
  HelpChatAI.Types,
  HelpChatAI.Html,
  HelpChatAI.Pdf,
  HelpChatAI.Panel,
  HelpChatAI.Settings;

function NewMessage(const ARole: THelpChatRole; const AContent: string;
  const APending: Boolean = False; const AError: Boolean = False): THelpChatMessage;
begin
  Result := Default(THelpChatMessage);
  Result.Id := THelpChatMessage.NewId;
  Result.Role := ARole;
  Result.Content := AContent;
  Result.Pending := APending;
  Result.IsError := AError;
end;

procedure TPdfTests.Page_A4_IsTheDefault;
var
  LPage: THelpChatPdfPage;
begin
  LPage := THelpChatPdfPage.A4;
  Assert.AreEqual(210.0, LPage.WidthMm, 0.01);
  Assert.AreEqual(297.0, LPage.HeightMm, 0.01);
  Assert.IsTrue(LPage.Orientation = hcpoPortrait);
  Assert.IsTrue(LPage.PrintBackgrounds, 'a table without its header shading is not the document');
  Assert.IsFalse(LPage.HasBands, 'a sheet has no header and no footer until asked');
  Assert.AreEqual(Double(HELPCHAT_PDF_DEF_BANDMM), LPage.BandMm, 0.01);
end;

procedure TPdfTests.Page_Letter_AndByName;
begin
  Assert.AreEqual(215.9, THelpChatPdfPage.Letter.WidthMm, 0.01);
  Assert.AreEqual(215.9, THelpChatPdfPage.FromName('Letter').WidthMm, 0.01);
  Assert.AreEqual(215.9, THelpChatPdfPage.FromPaper(hcppLetter).WidthMm, 0.01);
  Assert.AreEqual(210.0, THelpChatPdfPage.FromName('a4').WidthMm, 0.01);
  Assert.AreEqual(210.0, THelpChatPdfPage.FromName('foolscap').WidthMm, 0.01, 'unknown = A4');
end;

procedure TPdfTests.Page_SetMargins_SetsAllFour;
var
  LPage: THelpChatPdfPage;
begin
  LPage := THelpChatPdfPage.A4;
  LPage.SetMargins(25);
  Assert.AreEqual(25.0, LPage.MarginTopMm, 0.01);
  Assert.AreEqual(25.0, LPage.MarginBottomMm, 0.01);
  Assert.AreEqual(25.0, LPage.MarginLeftMm, 0.01);
  Assert.AreEqual(25.0, LPage.MarginRightMm, 0.01);
end;

procedure TPdfTests.FileName_DropsWhatWindowsRefuses;
begin
  Assert.AreEqual('Proposal 2026Q1.pdf', HelpChatPdfFileName('Proposal: 2026/Q1'));
  Assert.AreEqual('Report.pdf', HelpChatPdfFileName('Re|po*rt'));
  Assert.AreEqual('Offer Q1.pdf', HelpChatPdfFileName('Offer: Q1'),
    'the colon goes, the rest stays');
  Assert.AreEqual('ab.pdf', HelpChatPdfFileName('a"<>b'), 'four refused characters');
end;

procedure TPdfTests.FileName_EmptyTitle_HasAName;
begin
  Assert.AreEqual('document.pdf', HelpChatPdfFileName(''));
  Assert.AreEqual('document.pdf', HelpChatPdfFileName('   '));
  Assert.AreEqual('document.pdf', HelpChatPdfFileName('...'), 'a name of dots is no name');
end;

procedure TPdfTests.FileName_LongTitle_IsCut;
var
  LName: string;
begin
  LName := HelpChatPdfFileName(StringOfChar('x', 200));
  Assert.AreEqual(64, Length(LName), '60 characters and the extension');
  Assert.IsTrue(LName.EndsWith('.pdf'));
end;

procedure TPdfTests.Document_IsSelfContained;
var
  LDoc: THelpChatPrintableDoc;
  LHtml: string;
begin
  LDoc := Default(THelpChatPrintableDoc);
  LDoc.Title := 'Report';
  LDoc.Css := 'body{color:red}';
  LDoc.BodyHtml := '<p>Hello</p>';
  LDoc.LangCode := 'it';
  LHtml := LDoc.Render;
  Assert.StartsWith('<!doctype html>', LHtml);
  Assert.Contains(LHtml, '<html lang="it">');
  Assert.Contains(LHtml, '<title>Report</title>');
  Assert.Contains(LHtml, 'body{color:red}', 'the stylesheet travels inside the page');
  Assert.Contains(LHtml, '<p>Hello</p>');
  Assert.EndsWith('</article></body></html>', LHtml);
  Assert.DoesNotContain(LHtml, '<link', 'nothing to fetch: the WebView2 loads it as a string');
end;

procedure TPdfTests.Document_TitleBlock_OnlyWhenTheBodyHasNone;
var
  LDoc: THelpChatPrintableDoc;
begin
  LDoc := Default(THelpChatPrintableDoc);
  LDoc.Title := 'Report';
  LDoc.BodyHtml := '<p>x</p>';
  Assert.DoesNotContain(LDoc.Render, 'hc-doc-head', 'not asked for');
  LDoc.ShowTitle := True;
  Assert.Contains(LDoc.Render, '<header class="hc-doc-head"><h1>Report</h1>');
  LDoc.Subtitle := '31/10/2026';
  Assert.Contains(LDoc.Render, '<div class="hc-doc-meta">31/10/2026</div>');
end;

procedure TPdfTests.Document_EncodesTheTitle;
var
  LDoc: THelpChatPrintableDoc;
  LHtml: string;
begin
  LDoc := Default(THelpChatPrintableDoc);
  LDoc.Title := 'Rischi & <script>alert(1)</script>';
  LDoc.ShowTitle := True;
  LHtml := LDoc.Render;
  Assert.DoesNotContain(LHtml, '<script>', 'a title is text, wherever it came from');
  Assert.Contains(LHtml, '&amp;');
end;

procedure TPdfTests.Document_FromMarkdown_RendersIt;
var
  LDoc: THelpChatPrintableDoc;
begin
  LDoc := HelpChatMarkdownDocument('Note', '## Heading'#10#10'| a | b |'#10'| --- | --- |'#10'| 1 | 2 |', '');
  Assert.AreEqual('Note', LDoc.Title);
  Assert.Contains(LDoc.BodyHtml, '<h2');
  Assert.Contains(LDoc.BodyHtml, '<table', 'GFM tables, as in a bubble');
  Assert.IsTrue(LDoc.ShowTitle, 'a ## is a section, not the title of the document');
  Assert.IsFalse(HelpChatMarkdownDocument('Note', '# Note'#10#10'text', '').ShowTitle,
    'a # in the first line is the title: no second one on top of it');
end;

procedure TPdfTests.Document_FromMarkdown_IsStillSafe;
var
  LDoc: THelpChatPrintableDoc;
begin
  LDoc := HelpChatMarkdownDocument('x',
    'before <script>alert(1)</script> [link](javascript:alert(1)) after', '');
  Assert.DoesNotContain(LDoc.BodyHtml, '<script>');
  Assert.DoesNotContain(LDoc.BodyHtml, 'javascript:');
  Assert.IsTrue(LDoc.ShowTitle, 'no heading of its own: the title block earns its place');
end;

procedure TPdfTests.Conversation_HasBothSides;
var
  LDoc: THelpChatPrintableDoc;
  LHtml: string;
begin
  LDoc := HelpChatConversationDocument('Conversation',
    [NewMessage(hcrUser, 'How do I <save>?'),
     NewMessage(hcrAssistant, '**Press** Ctrl+S')], '', 'Question', 'Answer');
  LHtml := LDoc.BodyHtml;
  Assert.Contains(LHtml, 'hc-doc-turn-user');
  Assert.Contains(LHtml, 'hc-doc-turn-assistant');
  Assert.Contains(LHtml, '>Question<');
  Assert.Contains(LHtml, '>Answer<');
  Assert.Contains(LHtml, '&lt;save&gt;', 'a question is text, never Markdown');
  Assert.Contains(LHtml, '<strong>Press</strong>', 'a reply is Markdown, as in the panel');
  Assert.IsTrue(LDoc.ShowTitle);
end;

procedure TPdfTests.Conversation_LeavesOutPendingAndErrors;
var
  LDoc: THelpChatPrintableDoc;
begin
  LDoc := HelpChatConversationDocument('C',
    [NewMessage(hcrUser, 'one'),
     NewMessage(hcrAssistant, 'still writing', True),
     NewMessage(hcrAssistant, 'it went wrong', False, True),
     NewMessage(hcrAssistant, '')], '', 'Q', 'A');
  Assert.Contains(LDoc.BodyHtml, 'one');
  Assert.DoesNotContain(LDoc.BodyHtml, 'still writing', 'half an answer is not a document');
  Assert.DoesNotContain(LDoc.BodyHtml, 'it went wrong');
end;

procedure TPdfTests.Settings_RoundTrip;
var
  LSource, LTarget: THelpChatSettings;
  LJson: string;
begin
  LSource := THelpChatSettings.Create;
  LTarget := THelpChatSettings.Create;
  try
    Assert.IsTrue(LSource.Pdf.Enabled, 'printing sends nothing anywhere: on by default');
    Assert.IsFalse(LSource.Pdf.Action, 'a tool the model can call is not');
    LSource.Pdf.Enabled := False;
    LSource.Pdf.Action := True;
    LSource.Pdf.Paper := hcppLetter;
    LSource.Pdf.Orientation := hcpoLandscape;
    LSource.Pdf.MarginMm := 22;
    LSource.Pdf.PrintBackgrounds := False;
    LSource.Pdf.HeaderFooter := True;
    LJson := LSource.SaveToJSON;
    Assert.Contains(LJson, '"Letter"', 'a name, not a number');
    Assert.Contains(LJson, '"Landscape"');
    LTarget.LoadFromJSON(LJson);
    Assert.IsFalse(LTarget.Pdf.Enabled);
    Assert.IsTrue(LTarget.Pdf.Action);
    Assert.IsTrue(LTarget.Pdf.Paper = hcppLetter);
    Assert.IsTrue(LTarget.Pdf.Orientation = hcpoLandscape);
    Assert.AreEqual(22, LTarget.Pdf.MarginMm);
    Assert.IsFalse(LTarget.Pdf.PrintBackgrounds);
    Assert.IsTrue(LTarget.Pdf.HeaderFooter);
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TPdfTests.Settings_Page_CarriesWhatWasSet;
var
  LSettings: THelpChatSettings;
  LPage: THelpChatPdfPage;
begin
  LSettings := THelpChatSettings.Create;
  try
    LSettings.Pdf.Paper := hcppLetter;
    LSettings.Pdf.MarginMm := 30;
    LSettings.Pdf.HeaderFooter := True;
    LPage := LSettings.Pdf.Page('The title');
    Assert.AreEqual(215.9, LPage.WidthMm, 0.01);
    Assert.AreEqual(30.0, LPage.MarginLeftMm, 0.01);
    Assert.AreEqual('The title', LPage.Title);
    // The bands themselves are not a setting: they are HTML, and the
    // component builds them. What the settings carry is the room they get.
    LSettings.Pdf.BandMm := 20;
    LPage := LSettings.Pdf.Page('The title');
    Assert.AreEqual(20.0, LPage.BandMm, 0.01);
    Assert.IsFalse(LPage.HasBands, 'HeaderFooter alone prints nothing: the HTML does');
  finally
    LSettings.Free;
  end;
end;

procedure TPdfTests.Bands_Expand_ReplacesAndEscapes;
var
  LInfo: THelpChatPdfInfo;
  LBand: string;
begin
  LInfo := Default(THelpChatPdfInfo);
  LInfo.AppName := 'Rossi & C.';
  LInfo.AppVersion := '1.4.2';
  LInfo.UserName := 'carlo';
  LInfo.Title := '<Riepilogo>';
  LInfo.DateText := '02/11/2026';
  LInfo.TimeText := '15:30';
  LInfo.Extra := 'riservato';
  LBand := HelpChatPdfExpand(
    '<i>{app} {version}</i> {title} | {user} {date} {time} {extra} | {page}/{pages}',
    LInfo);
  // A name is text, and a band is a document: what the application wrote
  // cannot become markup.
  Assert.IsTrue(LBand.Contains('Rossi &amp; C.'), 'the ampersand is escaped');
  Assert.IsTrue(LBand.Contains('&lt;Riepilogo&gt;'), 'and so are the angle brackets');
  Assert.IsTrue(LBand.Contains('<i>'), 'but the template itself stays HTML');
  Assert.IsTrue(LBand.Contains('carlo 02/11/2026 15:30 riservato'));
  // These two only the runtime can fill, and it knows them by the class.
  Assert.IsTrue(LBand.Contains('<span class="pageNumber"></span>/<span class="totalPages"></span>'));
  Assert.IsFalse(LBand.Contains('{'), 'no placeholder is left behind');
end;

procedure TPdfTests.Bands_DefaultInfo_SaysWhoAndWhen;
var
  LInfo: THelpChatPdfInfo;
begin
  LInfo := HelpChatPdfDefaultInfo;
  // The test executable carries no version information, so the name falls
  // back to its file name - which is the point: a band is never empty.
  Assert.IsTrue(LInfo.AppName <> '', 'an application always has a name');
  Assert.AreEqual(DateToStr(Date), LInfo.DateText);
  Assert.IsTrue(LInfo.TimeText <> '');
{$IFDEF MSWINDOWS}
  Assert.IsTrue(LInfo.UserName <> '', 'somebody is logged on');
{$ENDIF}
end;

procedure TPdfTests.Bands_Page_KnowsWhenItHasThem;
var
  LPage: THelpChatPdfPage;
begin
  LPage := THelpChatPdfPage.A4;
  Assert.IsFalse(LPage.HasBands);
  LPage.FooterHtml := '   ';
  Assert.IsFalse(LPage.HasBands, 'whitespace is not a band');
  LPage.FooterHtml := '<span>x</span>';
  Assert.IsTrue(LPage.HasBands, 'the footer alone is enough');
end;

procedure TPdfTests.Exporter_WritesARealPdfWithBands;
var
  LExporter: THelpChatPdfExporter;
  LPage: THelpChatPdfPage;
  LInfo: THelpChatPdfInfo;
  LFileName, LError: string;
  LBytes: TBytes;
begin
  if not THelpChatPdfExporter.IsAvailable then
  begin
    Assert.Pass('no WebView2 runtime on this machine: nothing to print with');
    Exit;
  end;
{$IFDEF MSWINDOWS}
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
{$ENDIF}
  LFileName := TPath.Combine(TPath.GetTempPath,
    'helpchatai-bands-' + TGuid.NewGuid.ToString.Trim(['{', '}']) + '.pdf');
  LInfo := HelpChatPdfDefaultInfo;
  LInfo.Title := 'Test';
  LPage := THelpChatPdfPage.A4;
  LPage.HeaderHtml := HelpChatPdfExpand(
    '<div style="font-size:8pt">{app} {version}</div>', LInfo);
  LPage.FooterHtml := HelpChatPdfExpand(
    '<div style="font-size:8pt">{user} {date} - {page}/{pages}</div>', LInfo);
  LExporter := THelpChatPdfExporter.Create;
  try
    // This one does not go through PrintToPdf at all: it is Page.printToPDF,
    // over the DevTools protocol, and it answers with the bytes.
    Assert.IsTrue(LExporter.ExportHtml(
      HelpChatMarkdownDocument('Test', '# Test'#10#10'One paragraph.',
        'body{font-family:sans-serif}').Render,
      LFileName, LPage, LError), 'export failed: ' + LError);
    Assert.IsFalse(LExporter.BandsDropped,
      'this runtime took the header and the footer');
    LBytes := TFile.ReadAllBytes(LFileName);
    Assert.IsTrue(Length(LBytes) > 1000, 'a PDF of a page is not 1 KB of nothing');
    Assert.AreEqual('%PDF-', TEncoding.ASCII.GetString(LBytes, 0, 5));
  finally
    LExporter.Free;
    if TFile.Exists(LFileName) then
      TFile.Delete(LFileName);
  end;
end;

procedure TPdfTests.Bands_Templates_ComeFromTheResources;
var
  LHeader, LFooter: string;
begin
  LHeader := THelpChatPanel.PrintHeader;
  LFooter := THelpChatPanel.PrintFooter;
  Assert.IsTrue(LHeader.Contains('{app}'), 'the built-in header names the application');
  Assert.IsTrue(LFooter.Contains('{user}') and LFooter.Contains('{date}'),
    'and the footer says who printed it and when');
  Assert.IsTrue(LFooter.Contains('{page}') and LFooter.Contains('{pages}'),
    'with the numbering, which is the whole reason for the band');
  Assert.IsTrue(THelpChatPanel.PrintCss.Contains('hc-doc'),
    'the three pieces come out of the same resource file');
  // A named file that is not there is a shipping mistake, exactly like a
  // named configuration file: it says so instead of printing ours.
  Assert.WillRaise(
    procedure
    begin
      THelpChatPanel.PrintHeader('no-such-band.html');
    end, EHelpChatConfigError);
end;

procedure TPdfTests.Exporter_WritesARealPdf;
var
  LExporter: THelpChatPdfExporter;
  LFileName, LError: string;
  LBytes: TBytes;
begin
  if not THelpChatPdfExporter.IsAvailable then
  begin
    Assert.Pass('no WebView2 runtime on this machine: nothing to print with');
    Exit;
  end;
{$IFDEF MSWINDOWS}
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
{$ENDIF}
  LFileName := TPath.Combine(TPath.GetTempPath,
    'helpchatai-test-' + TGuid.NewGuid.ToString.Trim(['{', '}']) + '.pdf');
  LExporter := THelpChatPdfExporter.Create;
  try
    Assert.IsTrue(LExporter.ExportHtml(
      HelpChatMarkdownDocument('Test', '# Test'#10#10'One paragraph.',
        'body{font-family:sans-serif}').Render,
      LFileName, THelpChatPdfPage.A4, LError), 'export failed: ' + LError);
    Assert.IsTrue(TFile.Exists(LFileName), 'the file is where it was asked for');
    LBytes := TFile.ReadAllBytes(LFileName);
    Assert.IsTrue(Length(LBytes) > 1000, 'a PDF of a page is not 1 KB of nothing');
    Assert.AreEqual('%PDF-', TEncoding.ASCII.GetString(LBytes, 0, 5));
    // Nothing to print: the sentence comes back, no exception leaves.
    Assert.IsFalse(LExporter.ExportHtml('', LFileName, THelpChatPdfPage.A4, LError));
    Assert.IsTrue(LError <> '', 'a refusal says why');
  finally
    LExporter.Free;
    if TFile.Exists(LFileName) then
      TFile.Delete(LFileName);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPdfTests);

end.
