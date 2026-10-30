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
///  What the user attaches: which types are taken and which are refused, the
///  three limits, how a text file is decoded, and the blocks the three
///  providers build out of it. No network anywhere.
/// </summary>
unit HelpChatAI.Tests.Attachments;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TAttachmentsTests = class
  public
    [Test] procedure MediaType_ByExtension;
    [Test] procedure Accepts_Pdf_AsDocument;
    [Test] procedure Accepts_Image_AsImage;
    [Test] procedure Accepts_Text_Decoded;
    [Test] procedure Refuses_Word_ByName;
    [Test] procedure Refuses_Empty;
    [Test] procedure Limit_Count;
    [Test] procedure Limit_SingleSize;
    [Test] procedure Limit_TotalSize;
    [Test] procedure DecodeText_Utf8WithBom;
    [Test] procedure DecodeText_Utf8NoBom;
    [Test] procedure DecodeText_AnsiFallback;
    [Test] procedure Remove_And_Clear;
    [Test] procedure Keys_AreIndependent;
    [Test] procedure TextAttachments_GoIntoTheQuestion;
    [Test] procedure Claude_SendsDocumentBlock;
    [Test] procedure Claude_SendsImageBlock;
    [Test] procedure Claude_NoAttachments_KeepsPlainContent;
    [Test] procedure OpenAI_SendsFilePart;
    [Test] procedure Gemini_SendsInlineData;
    [Test] procedure FormatSize_IsReadable;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Attachments,
  HelpChatAI.Settings,
  HelpChatAI.Provider.Claude,
  HelpChatAI.Provider.OpenAI,
  HelpChatAI.Provider.Gemini;

const
  KEY = 'test';

function Bytes(const AText: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(AText);
end;

function BytesOfSize(const ASize: Integer): TBytes;
begin
  SetLength(Result, ASize);
  if ASize > 0 then
    FillChar(Result[0], ASize, Ord('x'));
end;

/// <summary>A history of one question, which is what a first attachment
/// arrives with.</summary>
function OneQuestion(const AText: string): TArray<THelpChatMessage>;
begin
  SetLength(Result, 1);
  Result[0] := Default(THelpChatMessage);
  Result[0].Id := 'm1';
  Result[0].Role := hcrUser;
  Result[0].Content := AText;
end;

function OnePdf(const AName: string = 'invoice.pdf'): TArray<THelpChatAttachment>;
begin
  SetLength(Result, 1);
  Result[0] := Default(THelpChatAttachment);
  Result[0].Id := 'a1';
  Result[0].FileName := AName;
  Result[0].MediaType := HELPCHAT_MEDIA_PDF;
  Result[0].Kind := hcakDocument;
  Result[0].Data := Bytes('%PDF-1.7 not really');
  Result[0].OriginalSize := Length(Result[0].Data);
end;

/// <summary>The content of the first message of a request body, whatever the
/// provider calls the array it lives in.</summary>
function FirstUserContent(const ABody, AMessagesField, AContentField: string): TJSONValue;
var
  LRoot: TJSONValue;
  LMessages: TJSONArray;
begin
  Result := nil;
  LRoot := TJSONObject.ParseJSONValue(ABody);
  try
    if not (LRoot is TJSONObject) then
      Exit;
    LMessages := TJSONObject(LRoot).GetValue(AMessagesField) as TJSONArray;
    if (LMessages = nil) or (LMessages.Count = 0) then
      Exit;
    // Cloned: the root is freed here and the caller owns what it gets.
    Result := (LMessages.Items[0] as TJSONObject).GetValue(AContentField).Clone as TJSONValue;
  finally
    LRoot.Free;
  end;
end;

{ TAttachmentsTests }

procedure TAttachmentsTests.MediaType_ByExtension;
begin
  Assert.AreEqual(HELPCHAT_MEDIA_PDF, HelpChatMediaTypeOf('a.pdf'));
  Assert.AreEqual(HELPCHAT_MEDIA_PDF, HelpChatMediaTypeOf('A.PDF'), 'case does not matter');
  Assert.AreEqual('image/jpeg', HelpChatMediaTypeOf('photo.JPEG'));
  Assert.AreEqual('text/csv', HelpChatMediaTypeOf('orders.csv'));
  Assert.AreEqual('', HelpChatMediaTypeOf('report.docx'), 'no model reads it');
  Assert.AreEqual('', HelpChatMediaTypeOf('noextension'));
  Assert.IsTrue(HelpChatAcceptedExtensions.Contains('.pdf'));
  Assert.IsFalse(HelpChatAcceptedExtensions.Contains('.docx'));
end;

procedure TAttachmentsTests.Accepts_Pdf_AsDocument;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'C:\tmp\invoice.pdf', Bytes('%PDF-1.7'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError), LError);
    Assert.AreEqual('invoice.pdf', LItem.FileName, 'the path is not kept');
    Assert.AreEqual(HELPCHAT_MEDIA_PDF, LItem.MediaType);
    Assert.IsTrue(LItem.Kind = hcakDocument);
    Assert.AreEqual('pdf', LItem.Extension);
    Assert.IsTrue(Length(LItem.Data) > 0, 'a document keeps its bytes');
    Assert.AreEqual('', LItem.Text);
    Assert.AreNotEqual('', LItem.Base64);
    Assert.IsFalse(LItem.Base64.Contains(#13), 'base64 with newlines is refused by the API');
    Assert.IsFalse(LItem.Base64.Contains(#10));
    Assert.AreEqual(1, LSet.Count(KEY));
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Accepts_Image_AsImage;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'scan.png', Bytes('PNG'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError), LError);
    Assert.IsTrue(LItem.Kind = hcakImage);
    Assert.AreEqual('image/png', LItem.MediaType);
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Accepts_Text_Decoded;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'notes.txt', Bytes('città'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError), LError);
    Assert.IsTrue(LItem.Kind = hcakText);
    Assert.AreEqual('città', LItem.Text, 'decoded once, when it arrives');
    Assert.AreEqual(0, Length(LItem.Data), 'and the bytes are not kept twice');
    Assert.IsTrue(LItem.OriginalSize > 0, 'the size is still the one of the file');
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Refuses_Word_ByName;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsFalse(LSet.TryAdd(KEY, 'contract.docx', Bytes('PK'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError));
    Assert.IsTrue(LError.Contains('DOCX'), 'the sentence names the type: ' + LError);
    Assert.IsTrue(LError.Contains('.pdf'), 'and says what is accepted: ' + LError);
    Assert.AreEqual(0, LSet.Count(KEY));
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Refuses_Empty;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsFalse(LSet.TryAdd(KEY, 'empty.pdf', nil,
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError));
    Assert.IsTrue(LError.Contains('empty.pdf'), LError);
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Limit_Count;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LLimits: THelpChatAttachmentLimits;
  LError: string;
begin
  LLimits := THelpChatAttachmentLimits.Default;
  LLimits.MaxCount := 2;
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'a.pdf', Bytes('a'), LLimits, hclEnglish, LItem, LError));
    Assert.IsTrue(LSet.TryAdd(KEY, 'b.pdf', Bytes('b'), LLimits, hclEnglish, LItem, LError));
    Assert.IsFalse(LSet.TryAdd(KEY, 'c.pdf', Bytes('c'), LLimits, hclEnglish, LItem, LError));
    Assert.IsTrue(LError.Contains('2'), LError);
    Assert.AreEqual(2, LSet.Count(KEY));
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Limit_SingleSize;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LLimits: THelpChatAttachmentLimits;
  LError: string;
begin
  LLimits := THelpChatAttachmentLimits.Default;
  LLimits.MaxSizeBytes := 1024;
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'small.pdf', BytesOfSize(1024), LLimits,
      hclEnglish, LItem, LError), 'exactly at the limit is still in');
    Assert.IsFalse(LSet.TryAdd(KEY, 'big.pdf', BytesOfSize(1025), LLimits,
      hclEnglish, LItem, LError));
    Assert.IsTrue(LError.Contains('big.pdf'), LError);
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Limit_TotalSize;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LLimits: THelpChatAttachmentLimits;
  LError: string;
begin
  LLimits := THelpChatAttachmentLimits.Default;
  LLimits.MaxTotalBytes := 2048;
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'a.pdf', BytesOfSize(1500), LLimits, hclEnglish, LItem, LError));
    Assert.IsFalse(LSet.TryAdd(KEY, 'b.pdf', BytesOfSize(1000), LLimits, hclEnglish, LItem, LError),
      'the two together are over the total');
    Assert.AreEqual(Int64(1500), LSet.TotalSize(KEY));
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.DecodeText_Utf8WithBom;
var
  LData: TBytes;
begin
  LData := TEncoding.UTF8.GetPreamble + TEncoding.UTF8.GetBytes('perché');
  Assert.AreEqual('perché', HelpChatDecodeText(LData));
end;

procedure TAttachmentsTests.DecodeText_Utf8NoBom;
begin
  Assert.AreEqual('perché', HelpChatDecodeText(TEncoding.UTF8.GetBytes('perché')));
end;

procedure TAttachmentsTests.DecodeText_AnsiFallback;
var
  LData: TBytes;
begin
  // A .txt written by Notepad in 2003: one byte per character, not valid
  // UTF-8, and still a .txt. The bytes are written out instead of asking
  // TEncoding.ANSI for them, because the answer depends on the code page of
  // the machine - and on one set to UTF-8 there is no ANSI to fall back to,
  // so there is nothing to test either.
  if TEncoding.ANSI.CodePage = CP_UTF8 then
  begin
    Assert.Pass('the ANSI code page of this machine is UTF-8: no fallback exists');
    Exit;
  end;
  LData := TBytes.Create($70, $65, $72, $63, $68, $E9);   // "perché" in CP1252
  Assert.AreEqual('perché', HelpChatDecodeText(LData));
end;

procedure TAttachmentsTests.Remove_And_Clear;
var
  LSet: THelpChatAttachmentSet;
  LItem, LFound: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd(KEY, 'a.pdf', Bytes('a'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError));
    Assert.IsTrue(LSet.TryGet(KEY, LItem.Id, LFound));
    Assert.AreEqual('a.pdf', LFound.FileName);
    Assert.IsFalse(LSet.Remove(KEY, 'nope'));
    Assert.IsTrue(LSet.Remove(KEY, LItem.Id));
    Assert.AreEqual(0, LSet.Count(KEY));

    Assert.IsTrue(LSet.TryAdd(KEY, 'b.pdf', Bytes('b'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError));
    LSet.ClearKey(KEY);
    Assert.AreEqual(0, LSet.Count(KEY), 'clearing the conversation takes them');
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.Keys_AreIndependent;
var
  LSet: THelpChatAttachmentSet;
  LItem: THelpChatAttachment;
  LError: string;
begin
  LSet := THelpChatAttachmentSet.Create;
  try
    Assert.IsTrue(LSet.TryAdd('u:alice', 'a.pdf', Bytes('a'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError));
    Assert.IsTrue(LSet.TryAdd('u:bob', 'b.pdf', Bytes('b'),
      THelpChatAttachmentLimits.Default, hclEnglish, LItem, LError));
    Assert.AreEqual(1, LSet.Count('u:alice'));
    LSet.ClearKey('u:alice');
    Assert.AreEqual(0, LSet.Count('u:alice'));
    Assert.AreEqual(1, LSet.Count('u:bob'), 'one session does not clear another');
  finally
    LSet.Free;
  end;
end;

procedure TAttachmentsTests.TextAttachments_GoIntoTheQuestion;
var
  LItems: TArray<THelpChatAttachment>;
  LText: string;
begin
  SetLength(LItems, 2);
  LItems[0] := Default(THelpChatAttachment);
  LItems[0].FileName := 'orders.csv';
  LItems[0].Kind := hcakText;
  LItems[0].Text := 'id;total'#13#10'1;99';
  LItems[1] := OnePdf[0];     // a PDF is not text: it must not end up in there

  LText := HelpChatQuestionWithText('What is the total?', LItems, hclEnglish);
  Assert.IsTrue(LText.Contains('orders.csv'), 'the file is named');
  Assert.IsTrue(LText.Contains('id;total'), 'and its content is there');
  Assert.IsTrue(LText.Contains('```'), 'fenced, so it cannot read as an instruction');
  Assert.IsTrue(LText.EndsWith('What is the total?'), 'the question comes last');
  Assert.IsFalse(LText.Contains('invoice.pdf'), 'a PDF travels as bytes, not as text');
  Assert.IsTrue(HelpChatHasBinary(LItems));
  Assert.IsFalse(HelpChatHasBinary(nil));
end;

procedure TAttachmentsTests.Claude_SendsDocumentBlock;
var
  LSettings: THelpChatSettings;
  LContent: TJSONValue;
  LBlocks: TJSONArray;
  LBlock, LSource: TJSONObject;
begin
  LSettings := THelpChatSettings.Create;
  try
    LContent := FirstUserContent(THelpChatClaudeProvider.BuildRequestBody(
      OneQuestion('Read it'), 'sys', LSettings.Claude, '', '', OnePdf, hclEnglish),
      'messages', 'content');
    try
      Assert.IsTrue(LContent is TJSONArray, 'with attachments the content is an array');
      LBlocks := TJSONArray(LContent);
      Assert.AreEqual(2, LBlocks.Count, 'the document and the text');
      LBlock := LBlocks.Items[0] as TJSONObject;
      Assert.AreEqual('document', LBlock.GetValue<string>('type'));
      Assert.AreEqual('invoice.pdf', LBlock.GetValue<string>('title'));
      LSource := LBlock.GetValue('source') as TJSONObject;
      Assert.AreEqual('base64', LSource.GetValue<string>('type'));
      Assert.AreEqual(HELPCHAT_MEDIA_PDF, LSource.GetValue<string>('media_type'));
      Assert.AreNotEqual('', LSource.GetValue<string>('data'));
      LBlock := LBlocks.Items[1] as TJSONObject;
      Assert.AreEqual('text', LBlock.GetValue<string>('type'));
      Assert.AreEqual('Read it', LBlock.GetValue<string>('text'),
        'the document is a block, so the question stays what it was');
    finally
      LContent.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TAttachmentsTests.Claude_SendsImageBlock;
var
  LSettings: THelpChatSettings;
  LItems: TArray<THelpChatAttachment>;
  LContent: TJSONValue;
  LBlock: TJSONObject;
begin
  LItems := OnePdf;
  LItems[0].FileName := 'scan.png';
  LItems[0].MediaType := 'image/png';
  LItems[0].Kind := hcakImage;
  LSettings := THelpChatSettings.Create;
  try
    LContent := FirstUserContent(THelpChatClaudeProvider.BuildRequestBody(
      OneQuestion('What is in it?'), 'sys', LSettings.Claude, '', '', LItems, hclEnglish),
      'messages', 'content');
    try
      LBlock := (LContent as TJSONArray).Items[0] as TJSONObject;
      Assert.AreEqual('image', LBlock.GetValue<string>('type'));
      Assert.IsNull(LBlock.GetValue('title'), 'an image block takes no title');
    finally
      LContent.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TAttachmentsTests.Claude_NoAttachments_KeepsPlainContent;
var
  LSettings: THelpChatSettings;
  LContent: TJSONValue;
begin
  LSettings := THelpChatSettings.Create;
  try
    LContent := FirstUserContent(THelpChatClaudeProvider.BuildRequestBody(
      OneQuestion('Plain'), 'sys', LSettings.Claude), 'messages', 'content');
    try
      Assert.IsTrue(LContent is TJSONString, 'without attachments nothing changes');
      Assert.AreEqual('Plain', LContent.Value);
    finally
      LContent.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TAttachmentsTests.OpenAI_SendsFilePart;
var
  LSettings: THelpChatSettings;
  LContent: TJSONValue;
  LParts: TJSONArray;
  LPart, LFile: TJSONObject;
  I: Integer;
begin
  LSettings := THelpChatSettings.Create;
  try
    // The instruction is the first message here, so the user turn is looked
    // up by role instead of by position.
    LContent := nil;
    LParts := nil;
    LPart := nil;
    LFile := nil;
    LContent := TJSONObject.ParseJSONValue(THelpChatOpenAIProvider.BuildRequestBody(
      OneQuestion('Read it'), 'sys', LSettings.OpenAI, '', '', OnePdf, hclEnglish));
    try
      LParts := (LContent as TJSONObject).GetValue('messages') as TJSONArray;
      for I := 0 to LParts.Count - 1 do
        if (LParts.Items[I] as TJSONObject).GetValue<string>('role') = 'user' then
        begin
          LPart := LParts.Items[I] as TJSONObject;
          Break;
        end;
      Assert.IsNotNull(LPart, 'the user turn is there');
      LParts := LPart.GetValue('content') as TJSONArray;
      Assert.AreEqual(2, LParts.Count);
      LPart := LParts.Items[0] as TJSONObject;
      Assert.AreEqual('file', LPart.GetValue<string>('type'), 'a PDF is the one file it reads');
      LFile := LPart.GetValue('file') as TJSONObject;
      Assert.AreEqual('invoice.pdf', LFile.GetValue<string>('filename'));
      Assert.IsTrue(LFile.GetValue<string>('file_data').StartsWith('data:application/pdf;base64,'));
    finally
      LContent.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TAttachmentsTests.Gemini_SendsInlineData;
var
  LSettings: THelpChatSettings;
  LRoot: TJSONValue;
  LParts: TJSONArray;
  LInline: TJSONObject;
begin
  LSettings := THelpChatSettings.Create;
  try
    LRoot := TJSONObject.ParseJSONValue(THelpChatGeminiProvider.BuildRequestBody(
      OneQuestion('Read it'), 'sys', LSettings.Gemini, '', '[]', OnePdf, hclEnglish));
    try
      LParts := ((LRoot as TJSONObject).GetValue('contents') as TJSONArray)
        .Items[0].GetValue<TJSONArray>('parts');
      Assert.AreEqual(2, LParts.Count);
      LInline := (LParts.Items[0] as TJSONObject).GetValue('inlineData') as TJSONObject;
      Assert.AreEqual(HELPCHAT_MEDIA_PDF, LInline.GetValue<string>('mimeType'));
      Assert.AreNotEqual('', LInline.GetValue<string>('data'));
      Assert.AreEqual('Read it', (LParts.Items[1] as TJSONObject).GetValue<string>('text'));
    finally
      LRoot.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TAttachmentsTests.FormatSize_IsReadable;
begin
  Assert.AreEqual('512 B', HelpChatFormatSize(512));
  Assert.AreEqual('2 KB', HelpChatFormatSize(2048));
  Assert.IsTrue(HelpChatFormatSize(3 * 1024 * 1024).EndsWith('MB'));
end;

initialization
  TDUnitX.RegisterTestFixture(TAttachmentsTests);

end.
