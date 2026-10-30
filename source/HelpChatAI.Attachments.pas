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
///  What the user attaches to a question, and what the application offers the
///  user to take away. An attachment is a value record (name, media type, the
///  bytes) kept per conversation in <see cref="THelpChatAttachmentSet" />,
///  which the engine owns; providers that can read documents turn it into
///  whatever block their API wants.
///
///  Three kinds, because that is what the models accept: a <c>document</c>
///  (PDF) and an <c>image</c> travel as bytes, everything textual
///  (.txt, .md, .csv, .json, ...) is decoded here and travels as text - no
///  model reads a .docx or a .xlsx, so those are refused with a sentence
///  saying so rather than sent and silently ignored.
///
///  Pure RTL: no VCL, no FMX, no web. Thread-safe, because the HTTP threads of
///  the panel add attachments while a worker reads them.
/// </summary>
unit HelpChatAI.Attachments;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  HelpChatAI.Types,
  HelpChatAI.Messages;

const
  /// <summary>Attachments allowed on one question, by default.</summary>
  HELPCHAT_DEF_ATTACH_MAXCOUNT = 5;
  /// <summary>Largest single attachment, in KB (the Claude limit for one
  /// request is 32 MB in total, and an image of more than a few MB is a
  /// scanned page nobody needs at that size).</summary>
  HELPCHAT_DEF_ATTACH_MAXSIZEKB = 8192;
  /// <summary>Largest total of the attachments of one conversation, in KB.</summary>
  HELPCHAT_DEF_ATTACH_MAXTOTALKB = 20480;
  /// <summary>Attachments are off until the application turns them on: what
  /// the user attaches leaves the machine, and that is the application's
  /// decision to make, not the library's.</summary>
  HELPCHAT_DEF_ATTACH_ENABLED = False;

  /// <summary>Media type of a PDF, the one document every model reads.</summary>
  HELPCHAT_MEDIA_PDF = 'application/pdf';
  HELPCHAT_MEDIA_TEXT = 'text/plain';

type
  /// <summary>
  ///  How an attachment reaches the model. <c>hcakDocument</c> is a PDF and
  ///  <c>hcakImage</c> a picture: both travel as base64 bytes in the block the
  ///  provider builds. <c>hcakText</c> was decoded when it arrived and travels
  ///  as text inside the question.
  /// </summary>
  THelpChatAttachmentKind = (hcakDocument, hcakImage, hcakText);

  /// <summary>
  ///  One attached file. A value record - copied into a request and handed to
  ///  a worker thread with no ownership concern, exactly like
  ///  <see cref="THelpChatMessage" />.
  /// </summary>
  THelpChatAttachment = record
    /// <summary>URL-safe id (hyphenated GUID without braces).</summary>
    Id: string;
    /// <summary>Name as the user sees it: no path, no directory separator.</summary>
    FileName: string;
    /// <summary>IANA media type, as the provider must declare it.</summary>
    MediaType: string;
    Kind: THelpChatAttachmentKind;
    /// <summary>The bytes, for a document or an image. Empty for text.</summary>
    Data: TBytes;
    /// <summary>The decoded content, for a text attachment. Empty otherwise.</summary>
    Text: string;
    Created: TDateTime;
    /// <summary>Bytes of the file as it arrived (before any decoding).</summary>
    OriginalSize: Int64;
    /// <summary>Formats a fresh URL-safe attachment id.</summary>
    class function NewId: string; static;
    /// <summary>True when nothing was ever put in it.</summary>
    function IsEmpty: Boolean;
    /// <summary>The bytes as the JSON of every provider wants them.</summary>
    function Base64: string;
    /// <summary>Extension without the dot, lowercase ("pdf"); empty when none.</summary>
    function Extension: string;
  end;

  /// <summary>
  ///  What an attachment may not exceed. A plain record so this unit does not
  ///  depend on the settings: <c>THelpChatAttachmentSettings</c> produces one.
  /// </summary>
  THelpChatAttachmentLimits = record
    MaxCount: Integer;
    MaxSizeBytes: Int64;
    MaxTotalBytes: Int64;
    class function Default: THelpChatAttachmentLimits; static;
  end;

  /// <summary>
  ///  The attachments of every conversation, keyed the way the store is. The
  ///  engine owns one; a request takes a copy of the array, so a worker never
  ///  reads the live list.
  ///
  ///  They live here and not in the conversation store on purpose: the bytes
  ///  of a PDF have no business in the JSON file the conversation is persisted
  ///  to. An attachment lasts as long as the panel is open, and
  ///  <c>Clear</c> - the ↺ of the page - takes it away with the conversation.
  /// </summary>
  THelpChatAttachmentSet = class
  strict private
    FLock: TCriticalSection;
    FItems: TObjectDictionary<string, TList<THelpChatAttachment>>;
    function ListOf(const AKey: string; const ACreate: Boolean): TList<THelpChatAttachment>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Accepts a file for the conversation AKey. False with a
    /// localized sentence in AError when the type is not one a model reads, or
    /// a limit is reached: the page shows it as it is.</summary>
    function TryAdd(const AKey, AFileName: string; const AData: TBytes;
      const ALimits: THelpChatAttachmentLimits; const ALanguage: THelpChatLanguage;
      out AAttachment: THelpChatAttachment; out AError: string): Boolean;
    /// <summary>Copy of the attachments of AKey, oldest first.</summary>
    function ItemsOf(const AKey: string): TArray<THelpChatAttachment>;
    /// <summary>The one with this id, if the conversation has it.</summary>
    function TryGet(const AKey, AId: string; out AAttachment: THelpChatAttachment): Boolean;
    /// <summary>Drops one attachment; True when it was there.</summary>
    function Remove(const AKey, AId: string): Boolean;
    /// <summary>Drops every attachment of a conversation (what Clear does).</summary>
    procedure ClearKey(const AKey: string);
    /// <summary>Drops everything, of every conversation.</summary>
    procedure ClearAll;
    function Count(const AKey: string): Integer;
    /// <summary>Bytes held by the conversation, as they arrived.</summary>
    function TotalSize(const AKey: string): Int64;
  end;

/// <summary>The media type of a file name, by extension; empty when it is not
/// one of the types a model can be given.</summary>
function HelpChatMediaTypeOf(const AFileName: string): string;
/// <summary>How a media type travels. Meaningless when the type is not one of
/// the accepted ones - ask <c>HelpChatIsAcceptedType</c> first.</summary>
function HelpChatKindOf(const AMediaType: string): THelpChatAttachmentKind;
/// <summary>True when a model can be given a file of this name.</summary>
function HelpChatIsAcceptedFile(const AFileName: string): Boolean;
/// <summary>The extensions the page offers in its file dialog
/// (".pdf,.png,..."), which is also what this unit accepts.</summary>
function HelpChatAcceptedExtensions: string;
/// <summary>Text of a file that arrived as bytes: honours a UTF-8, UTF-16 LE
/// or BE BOM, else reads UTF-8 and falls back to the ANSI code page when the
/// bytes are not valid UTF-8 - the same rule the index builder follows for the
/// pages of a manual, and for the same reason: a .txt written by Notepad in
/// 2003 is still a .txt.</summary>
function HelpChatDecodeText(const AData: TBytes): string;
/// <summary>A size as the panel shows it next to the file name ("1,4 MB").</summary>
function HelpChatFormatSize(const ABytes: Int64): string;
/// <summary>The text attachments as one block, to put in front of the
/// question: a heading, then every file between two fences carrying its name.
/// Empty when none of them is textual. Lives here and not in a provider
/// because all three say it the same way - what differs between the APIs is
/// only how the <i>bytes</i> of a PDF travel.</summary>
function HelpChatAttachmentsText(const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage): string;
/// <summary>True when at least one attachment travels as bytes (a PDF or an
/// image): what a provider that cannot read documents has to report.</summary>
function HelpChatHasBinary(const AAttachments: TArray<THelpChatAttachment>): Boolean;
/// <summary>The question as the model receives it: the text attachments, then
/// what the user typed.</summary>
function HelpChatQuestionWithText(const AQuestion: string;
  const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage): string;

implementation

uses
  System.NetEncoding,
  System.Math,
  System.StrUtils,
  HelpChatAI.IndexBuilder;

type
  TAcceptedType = record
    Ext: string;
    MediaType: string;
    Kind: THelpChatAttachmentKind;
  end;

const
  /// <summary>Everything a model actually reads. A PDF and the four image
  /// formats go up as bytes; the rest is text, and whatever is not here is
  /// refused by name - no provider accepts a .docx or a .xlsx, and sending one
  /// would look like it worked.</summary>
  ACCEPTED: array[0..14] of TAcceptedType = (
    (Ext: 'pdf';  MediaType: HELPCHAT_MEDIA_PDF;   Kind: hcakDocument),
    (Ext: 'png';  MediaType: 'image/png';          Kind: hcakImage),
    (Ext: 'jpg';  MediaType: 'image/jpeg';         Kind: hcakImage),
    (Ext: 'jpeg'; MediaType: 'image/jpeg';         Kind: hcakImage),
    (Ext: 'gif';  MediaType: 'image/gif';          Kind: hcakImage),
    (Ext: 'webp'; MediaType: 'image/webp';         Kind: hcakImage),
    (Ext: 'txt';  MediaType: HELPCHAT_MEDIA_TEXT;  Kind: hcakText),
    (Ext: 'md';   MediaType: 'text/markdown';      Kind: hcakText),
    (Ext: 'csv';  MediaType: 'text/csv';           Kind: hcakText),
    (Ext: 'json'; MediaType: 'application/json';   Kind: hcakText),
    (Ext: 'xml';  MediaType: 'text/xml';           Kind: hcakText),
    (Ext: 'log';  MediaType: HELPCHAT_MEDIA_TEXT;  Kind: hcakText),
    (Ext: 'ini';  MediaType: HELPCHAT_MEDIA_TEXT;  Kind: hcakText),
    (Ext: 'yaml'; MediaType: 'text/yaml';          Kind: hcakText),
    (Ext: 'yml';  MediaType: 'text/yaml';          Kind: hcakText));

function NormalizedExt(const AFileName: string): string;
begin
  Result := ExtractFileExt(AFileName).ToLower;
  if Result.StartsWith('.') then
    Result := Result.Substring(1);
end;

function HelpChatMediaTypeOf(const AFileName: string): string;
var
  LExt: string;
  I: Integer;
begin
  LExt := NormalizedExt(AFileName);
  for I := Low(ACCEPTED) to High(ACCEPTED) do
    if ACCEPTED[I].Ext = LExt then
      Exit(ACCEPTED[I].MediaType);
  Result := '';
end;

function HelpChatKindOf(const AMediaType: string): THelpChatAttachmentKind;
var
  LType: string;
begin
  LType := AMediaType.ToLower;
  if LType = HELPCHAT_MEDIA_PDF then
    Result := hcakDocument
  else if LType.StartsWith('image/') then
    Result := hcakImage
  else
    Result := hcakText;
end;

function HelpChatIsAcceptedFile(const AFileName: string): Boolean;
begin
  Result := HelpChatMediaTypeOf(AFileName) <> '';
end;

function HelpChatAcceptedExtensions: string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(ACCEPTED) to High(ACCEPTED) do
    Result := Result + IfThen(Result = '', '', ',') + '.' + ACCEPTED[I].Ext;
end;

function HelpChatDecodeText(const AData: TBytes): string;
var
  LEncoding: TEncoding;
  LOffset: Integer;
begin
  if Length(AData) = 0 then
    Exit('');
  LEncoding := nil;
  LOffset := TEncoding.GetBufferEncoding(AData, LEncoding, TEncoding.UTF8);
  if LOffset > 0 then                     // a BOM decided it
    Exit(LEncoding.GetString(AData, LOffset, Length(AData) - LOffset));
  // No BOM: UTF-8 when the bytes are valid UTF-8, else the ANSI code page -
  // the same rule, and the same code, the index builder uses for the pages of
  // a manual. The test has to come first: TEncoding.UTF8.GetString does not
  // substitute an invalid sequence, it raises.
  if THelpChatIndexBuilder.IsValidUtf8(AData) then
    Result := TEncoding.UTF8.GetString(AData)
  else
    Result := TEncoding.ANSI.GetString(AData);
end;

function HelpChatFormatSize(const ABytes: Int64): string;
begin
  if ABytes >= 1024 * 1024 then
    Result := FormatFloat('0.#', ABytes / (1024 * 1024)) + ' MB'
  else if ABytes >= 1024 then
    Result := FormatFloat('0', ABytes / 1024) + ' KB'
  else
    Result := IntToStr(ABytes) + ' B';
end;

function HelpChatAttachmentsText(const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage): string;
var
  LBuilder: TStringBuilder;
  I: Integer;
begin
  Result := '';
  if Length(AAttachments) = 0 then
    Exit;
  LBuilder := TStringBuilder.Create;
  try
    for I := Low(AAttachments) to High(AAttachments) do
    begin
      if (AAttachments[I].Kind <> hcakText) or (AAttachments[I].Text = '') then
        Continue;
      if LBuilder.Length = 0 then
        LBuilder.AppendLine(HelpChatMsg(hcmAttachedDocuments, ALanguage)).AppendLine;
      LBuilder.AppendLine(Format(HelpChatMsg(hcmAttachedTextFile, ALanguage),
        [AAttachments[I].FileName]));
      // Fenced, so the model cannot mistake the content of a file for an
      // instruction of the user - and a CSV keeps its columns.
      LBuilder.AppendLine('```');
      LBuilder.AppendLine(AAttachments[I].Text);
      LBuilder.AppendLine('```').AppendLine;
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function HelpChatHasBinary(const AAttachments: TArray<THelpChatAttachment>): Boolean;
var
  I: Integer;
begin
  for I := Low(AAttachments) to High(AAttachments) do
    if (AAttachments[I].Kind <> hcakText) and (Length(AAttachments[I].Data) > 0) then
      Exit(True);
  Result := False;
end;

function HelpChatQuestionWithText(const AQuestion: string;
  const AAttachments: TArray<THelpChatAttachment>;
  const ALanguage: THelpChatLanguage): string;
var
  LText: string;
begin
  LText := HelpChatAttachmentsText(AAttachments, ALanguage);
  if LText = '' then
    Result := AQuestion
  else
    Result := LText + AQuestion;
end;

{ THelpChatAttachment }

class function THelpChatAttachment.NewId: string;
begin
  Result := THelpChatMessage.NewId;
end;

function THelpChatAttachment.IsEmpty: Boolean;
begin
  Result := (Id = '') or (FileName = '');
end;

function THelpChatAttachment.Base64: string;
begin
  if Length(Data) = 0 then
    Exit('');
  // No line breaks anywhere: every one of the three APIs refuses a base64
  // string that has them.
{$IFDEF D11+}
  Result := TNetEncoding.Base64String.EncodeBytesToString(Data);
{$ELSE}
  // Delphi 10.4 has no Base64String, and the classic encoder wraps at 76
  // characters: the wrapping has to come out again.
  Result := TNetEncoding.Base64.EncodeBytesToString(Data)
    .Replace(#13, '', [rfReplaceAll]).Replace(#10, '', [rfReplaceAll]);
{$ENDIF}
end;

function THelpChatAttachment.Extension: string;
begin
  Result := NormalizedExt(FileName);
end;

{ THelpChatAttachmentLimits }

class function THelpChatAttachmentLimits.Default: THelpChatAttachmentLimits;
begin
  Result.MaxCount := HELPCHAT_DEF_ATTACH_MAXCOUNT;
  Result.MaxSizeBytes := Int64(HELPCHAT_DEF_ATTACH_MAXSIZEKB) * 1024;
  Result.MaxTotalBytes := Int64(HELPCHAT_DEF_ATTACH_MAXTOTALKB) * 1024;
end;

{ THelpChatAttachmentSet }

constructor THelpChatAttachmentSet.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FItems := TObjectDictionary<string, TList<THelpChatAttachment>>.Create([doOwnsValues]);
end;

destructor THelpChatAttachmentSet.Destroy;
begin
  FreeAndNil(FItems);
  FreeAndNil(FLock);
  inherited;
end;

function THelpChatAttachmentSet.ListOf(const AKey: string;
  const ACreate: Boolean): TList<THelpChatAttachment>;
begin
  if not FItems.TryGetValue(AKey, Result) then
  begin
    if not ACreate then
      Exit(nil);
    Result := TList<THelpChatAttachment>.Create;
    FItems.Add(AKey, Result);
  end;
end;

function THelpChatAttachmentSet.TryAdd(const AKey, AFileName: string;
  const AData: TBytes; const ALimits: THelpChatAttachmentLimits;
  const ALanguage: THelpChatLanguage; out AAttachment: THelpChatAttachment;
  out AError: string): Boolean;
var
  LList: TList<THelpChatAttachment>;
  LMediaType, LName: string;
  LTotal: Int64;
  I: Integer;
begin
  Result := False;
  AError := '';
  AAttachment := Default(THelpChatAttachment);

  LName := ExtractFileName(AFileName.Trim);
  if LName = '' then
  begin
    AError := HelpChatMsg(hcmAttachFailed, ALanguage);
    Exit;
  end;

  LMediaType := HelpChatMediaTypeOf(LName);
  if LMediaType = '' then
  begin
    AError := Format(HelpChatMsg(hcmAttachTypeRefused, ALanguage),
      [NormalizedExt(LName).ToUpper, HelpChatAcceptedExtensions]);
    Exit;
  end;

  if Length(AData) = 0 then
  begin
    AError := Format(HelpChatMsg(hcmAttachEmpty, ALanguage), [LName]);
    Exit;
  end;

  if (ALimits.MaxSizeBytes > 0) and (Length(AData) > ALimits.MaxSizeBytes) then
  begin
    AError := Format(HelpChatMsg(hcmAttachTooLarge, ALanguage),
      [LName, HelpChatFormatSize(ALimits.MaxSizeBytes)]);
    Exit;
  end;

  FLock.Enter;
  try
    LList := ListOf(AKey, True);
    if (ALimits.MaxCount > 0) and (LList.Count >= ALimits.MaxCount) then
    begin
      AError := Format(HelpChatMsg(hcmAttachTooMany, ALanguage), [ALimits.MaxCount]);
      Exit;
    end;
    LTotal := 0;
    for I := 0 to LList.Count - 1 do
      LTotal := LTotal + LList[I].OriginalSize;
    if (ALimits.MaxTotalBytes > 0) and (LTotal + Length(AData) > ALimits.MaxTotalBytes) then
    begin
      AError := Format(HelpChatMsg(hcmAttachTooMuch, ALanguage),
        [HelpChatFormatSize(ALimits.MaxTotalBytes)]);
      Exit;
    end;

    AAttachment.Id := THelpChatAttachment.NewId;
    AAttachment.FileName := LName;
    AAttachment.MediaType := LMediaType;
    AAttachment.Kind := HelpChatKindOf(LMediaType);
    AAttachment.Created := Now;
    AAttachment.OriginalSize := Length(AData);
    // A text file is decoded once, here: what travels is the text, and the
    // bytes are not kept twice.
    if AAttachment.Kind = hcakText then
      AAttachment.Text := HelpChatDecodeText(AData)
    else
      AAttachment.Data := Copy(AData);

    LList.Add(AAttachment);
    Result := True;
  finally
    FLock.Leave;
  end;
end;

function THelpChatAttachmentSet.ItemsOf(const AKey: string): TArray<THelpChatAttachment>;
var
  LList: TList<THelpChatAttachment>;
begin
  FLock.Enter;
  try
    LList := ListOf(AKey, False);
    if LList = nil then
      Result := nil
    else
      Result := LList.ToArray;
  finally
    FLock.Leave;
  end;
end;

function THelpChatAttachmentSet.TryGet(const AKey, AId: string;
  out AAttachment: THelpChatAttachment): Boolean;
var
  LList: TList<THelpChatAttachment>;
  I: Integer;
begin
  Result := False;
  AAttachment := Default(THelpChatAttachment);
  if AId = '' then
    Exit;
  FLock.Enter;
  try
    LList := ListOf(AKey, False);
    if LList = nil then
      Exit;
    for I := 0 to LList.Count - 1 do
      if SameText(LList[I].Id, AId) then
      begin
        AAttachment := LList[I];
        Exit(True);
      end;
  finally
    FLock.Leave;
  end;
end;

function THelpChatAttachmentSet.Remove(const AKey, AId: string): Boolean;
var
  LList: TList<THelpChatAttachment>;
  I: Integer;
begin
  Result := False;
  FLock.Enter;
  try
    LList := ListOf(AKey, False);
    if LList = nil then
      Exit;
    for I := LList.Count - 1 downto 0 do
      if SameText(LList[I].Id, AId) then
      begin
        LList.Delete(I);
        Exit(True);
      end;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatAttachmentSet.ClearKey(const AKey: string);
var
  LList: TList<THelpChatAttachment>;
begin
  FLock.Enter;
  try
    LList := ListOf(AKey, False);
    if LList <> nil then
      LList.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure THelpChatAttachmentSet.ClearAll;
begin
  FLock.Enter;
  try
    FItems.Clear;
  finally
    FLock.Leave;
  end;
end;

function THelpChatAttachmentSet.Count(const AKey: string): Integer;
var
  LList: TList<THelpChatAttachment>;
begin
  FLock.Enter;
  try
    LList := ListOf(AKey, False);
    if LList = nil then
      Result := 0
    else
      Result := LList.Count;
  finally
    FLock.Leave;
  end;
end;

function THelpChatAttachmentSet.TotalSize(const AKey: string): Int64;
var
  LList: TList<THelpChatAttachment>;
  I: Integer;
begin
  Result := 0;
  FLock.Enter;
  try
    LList := ListOf(AKey, False);
    if LList = nil then
      Exit;
    for I := 0 to LList.Count - 1 do
      Result := Result + LList[I].OriginalSize;
  finally
    FLock.Leave;
  end;
end;

end.
