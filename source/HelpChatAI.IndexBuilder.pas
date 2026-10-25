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
///  Builds the documentation index consumed by <c>THelpChatDocIndex</c> from a
///  folder of Markdown pages. For each page: title (front matter, first heading,
///  else the link text in the table of contents, else the file name), URL
///  (relative path with the extension swapped), summary (first meaningful
///  paragraph), plain text for scoring, and keywords: the breadcrumb of the
///  page in the table of contents (<c>index.md</c>), when present, so a page
///  titled "Esecuzione Report" also answers to "Report Player". Encoding is
///  detected per file (BOM, UTF-8 validation, else ANSI). Pure RTL: the CLI in
///  <c>Tools/HelpIndexBuilder</c> is a thin wrapper, and a host application can
///  rebuild its index at runtime.
/// </summary>
unit HelpChatAI.IndexBuilder;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

const
  HELPCHAT_INDEXBUILDER_DEF_URLEXT = '.html';
  HELPCHAT_INDEXBUILDER_DEF_MAXTEXT = 8000;
  HELPCHAT_INDEXBUILDER_DEF_SUMMARYMAX = 320;
  HELPCHAT_INDEXBUILDER_DEF_SUMMARYMIN = 40;
  HELPCHAT_INDEXBUILDER_DEF_TOCFILE = 'index.md';

type
  THelpChatIndexBuilderOptions = record
    /// <summary>Folder holding the Markdown pages.</summary>
    SourceFolder: string;
    /// <summary>Include sub-folders (images folders hold no .md and are harmless).</summary>
    Recursive: Boolean;
    /// <summary>Table of contents file, relative to SourceFolder (case-insensitive);
    /// gives titles and breadcrumbs and is never indexed as a page.</summary>
    TocFile: string;
    /// <summary>Extension of the published pages ('.html'); empty keeps '.md'.</summary>
    UrlExtension: string;
    /// <summary>Prepended to every relative URL (e.g. 'manual/').</summary>
    UrlPrefix: string;
    MaxTextLength: Integer;
    SummaryMaxLength: Integer;
    SummaryMinLength: Integer;
    class function Default: THelpChatIndexBuilderOptions; static;
  end;

  THelpChatIndexPage = record
    Id: string;
    Title: string;
    Url: string;
    Summary: string;
    Text: string;
    Keywords: TArray<string>;
    /// <summary>Relative source path, for diagnostics.</summary>
    SourceFile: string;
  end;

  /// <summary>A page as described by the table of contents.</summary>
  THelpChatTocEntry = record
    Title: string;
    /// <summary>Titles of the ancestors, outermost first.</summary>
    Breadcrumb: TArray<string>;
  end;

  THelpChatIndexBuilder = class
  strict private
    FWarnings: TStrings;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Reads a text file detecting its encoding: BOM if present, else
    /// UTF-8 when the bytes are valid UTF-8, else the ANSI code page.</summary>
    class function ReadTextFile(const AFileName: string): string; static;
    /// <summary>True when ABytes is a well-formed UTF-8 sequence.</summary>
    class function IsValidUtf8(const ABytes: TBytes): Boolean; static;
    /// <summary>Removes a leading YAML front matter block, returning it in AFrontMatter.</summary>
    class function StripFrontMatter(const AMarkdown: string; out AFrontMatter: string): string; static;
    /// <summary>Title from the front matter "title:" or the first heading (any level).</summary>
    class function ExtractTitle(const AMarkdown, AFrontMatter: string): string; static;
    /// <summary>Markdown to plain text: code fences, images, link targets,
    /// heading/list/quote markers, emphasis, tables and HTML tags removed,
    /// entities decoded, paragraphs kept apart by a blank line.</summary>
    class function MarkdownToPlainText(const AMarkdown: string): string; static;
    /// <summary>First paragraph of at least AMinLength characters that is not
    /// ATitle, cut at a word boundary to AMaxLength (ellipsis appended).</summary>
    class function ExtractSummary(const APlainText, ATitle: string;
      const AMinLength, AMaxLength: Integer): string; static;
    /// <summary>All whitespace collapsed to single spaces, cut to AMaxLength.</summary>
    class function CollapseText(const APlainText: string; const AMaxLength: Integer): string; static;
    /// <summary>Parses a table of contents made of Markdown links, nested by
    /// indentation and list markers: "[**Section**](a.md)", "- [Page](b.md)",
    /// "    - [_Sub page_](c.md)". Keys are the linked file names, lower-case,
    /// with forward slashes. Entries without a link are ignored.</summary>
    class function ParseToc(const AMarkdown: string): TDictionary<string, THelpChatTocEntry>; static;
    /// <summary>Cleans a TOC/heading title: emphasis markers, surrounding spaces.</summary>
    class function CleanTitle(const ATitle: string): string; static;

    /// <summary>Builds the pages of every Markdown file under the source folder.</summary>
    function Build(const AOptions: THelpChatIndexBuilderOptions): TArray<THelpChatIndexPage>;
    /// <summary>Serializes pages to the JSON array THelpChatDocIndex loads.</summary>
    class function ToJSON(const APages: TArray<THelpChatIndexPage>; const APretty: Boolean = True): string; static;
    /// <summary>Build + ToJSON + write (UTF-8). Returns the number of pages.</summary>
    function BuildToFile(const AOptions: THelpChatIndexBuilderOptions; const AOutputFile: string): Integer;

    /// <summary>Non-fatal findings of the last Build (pages without title or text...).</summary>
    property Warnings: TStrings read FWarnings;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.JSON,
  System.NetEncoding,
  System.RegularExpressions,
  System.Generics.Defaults;

{ THelpChatIndexBuilderOptions }

class function THelpChatIndexBuilderOptions.Default: THelpChatIndexBuilderOptions;
begin
  Result := System.Default(THelpChatIndexBuilderOptions);
  Result.Recursive := True;
  Result.TocFile := HELPCHAT_INDEXBUILDER_DEF_TOCFILE;
  Result.UrlExtension := HELPCHAT_INDEXBUILDER_DEF_URLEXT;
  Result.MaxTextLength := HELPCHAT_INDEXBUILDER_DEF_MAXTEXT;
  Result.SummaryMaxLength := HELPCHAT_INDEXBUILDER_DEF_SUMMARYMAX;
  Result.SummaryMinLength := HELPCHAT_INDEXBUILDER_DEF_SUMMARYMIN;
end;

{ THelpChatIndexBuilder }

constructor THelpChatIndexBuilder.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor THelpChatIndexBuilder.Destroy;
begin
  FWarnings.Free;
  inherited;
end;

class function THelpChatIndexBuilder.IsValidUtf8(const ABytes: TBytes): Boolean;
var
  I, LNeed: Integer;
  B: Byte;
begin
  I := 0;
  while I < Length(ABytes) do
  begin
    B := ABytes[I];
    if B < $80 then
      LNeed := 0
    else if (B and $E0) = $C0 then
      LNeed := 1
    else if (B and $F0) = $E0 then
      LNeed := 2
    else if (B and $F8) = $F0 then
      LNeed := 3
    else
      Exit(False);
    Inc(I);
    while LNeed > 0 do
    begin
      if (I >= Length(ABytes)) or ((ABytes[I] and $C0) <> $80) then
        Exit(False);
      Inc(I);
      Dec(LNeed);
    end;
  end;
  Result := True;
end;

class function THelpChatIndexBuilder.ReadTextFile(const AFileName: string): string;
var
  LBytes: TBytes;
  LEncoding: TEncoding;
  LOffset: Integer;
begin
  LBytes := TFile.ReadAllBytes(AFileName);
  LEncoding := nil;
  LOffset := TEncoding.GetBufferEncoding(LBytes, LEncoding, TEncoding.ANSI);
  // No BOM: an ANSI file with accented letters is never valid UTF-8, a UTF-8
  // file always is; pure ASCII decodes the same either way.
  if (LOffset = 0) and IsValidUtf8(LBytes) then
    LEncoding := TEncoding.UTF8;
  Result := LEncoding.GetString(LBytes, LOffset, Length(LBytes) - LOffset);
end;

class function THelpChatIndexBuilder.StripFrontMatter(const AMarkdown: string;
  out AFrontMatter: string): string;
var
  LText: string;
  LEnd: Integer;
begin
  AFrontMatter := '';
  Result := AMarkdown;
  LText := AMarkdown.TrimLeft([#$FEFF, ' ', #9, #13, #10]);
  if not (LText.StartsWith('---'#10) or LText.StartsWith('---'#13#10)) then
    Exit;
  LEnd := LText.IndexOf(#10'---', 3);
  if LEnd < 0 then
    Exit;
  AFrontMatter := LText.Substring(3, LEnd - 3).Trim;
  Result := LText.Substring(LEnd + 4); // past #10'---'
  // Drop the rest of the closing line.
  LEnd := Result.IndexOf(#10);
  if LEnd >= 0 then
    Result := Result.Substring(LEnd + 1)
  else
    Result := '';
end;

class function THelpChatIndexBuilder.CleanTitle(const ATitle: string): string;
begin
  Result := ATitle.Replace('**', '').Replace('__', '').Replace('`', '');
  Result := TRegEx.Replace(Result, '(?<!\w)[*_]+|[*_]+(?!\w)', '');
  // Trailing closing hashes of ATX headings ("## Title ##").
  Result := TRegEx.Replace(Result, '\s+#+\s*$', '');
  Result := TNetEncoding.HTML.Decode(Result).Trim;
end;

class function THelpChatIndexBuilder.ExtractTitle(const AMarkdown, AFrontMatter: string): string;
var
  LMatch: TMatch;
begin
  Result := '';
  if AFrontMatter <> '' then
  begin
    LMatch := TRegEx.Match(AFrontMatter, '^\s*title\s*:\s*(.+?)\s*$', [roMultiLine, roIgnoreCase]);
    if LMatch.Success then
      Exit(CleanTitle(LMatch.Groups[1].Value.Trim(['"', ''''])));
  end;
  LMatch := TRegEx.Match(AMarkdown.Replace(#$FEFF, ''), '^[ \t]{0,3}#{1,6}[ \t]+(.+?)[ \t]*$', [roMultiLine]);
  if LMatch.Success then
    Result := CleanTitle(LMatch.Groups[1].Value);
end;

class function THelpChatIndexBuilder.MarkdownToPlainText(const AMarkdown: string): string;
var
  S: string;
begin
  S := AMarkdown.Replace(#13#10, #10).Replace(#13, #10).Replace(#$FEFF, '').Replace(#$00A0, ' ');
  // Line-anchored patterns use [ \t], never \s: \s would swallow the newline of
  // a blank line and glue a heading to the previous paragraph.
  // Code fences: drop the fence lines, keep their content (placeholders and
  // range names are worth searching for).
  S := TRegEx.Replace(S, '^[ \t]*(```|~~~).*$', '', [roMultiLine]);
  // Images (before links: they share the bracket syntax).
  S := TRegEx.Replace(S, '!\[[^\]]*\]\([^)]*\)', '');
  // Links: keep the text.
  S := TRegEx.Replace(S, '\[([^\]]+)\]\([^)]*\)', '$1');
  // Reference-style link definitions.
  S := TRegEx.Replace(S, '^[ \t]*\[[^\]]+\]:[ \t]*\S+.*$', '', [roMultiLine]);
  // HTML tags and comments.
  S := TRegEx.Replace(S, '<!--.*?-->', '', [roSingleLine]);
  S := TRegEx.Replace(S, '<[^>]+>', '');
  // Heading, quote and list markers.
  S := TRegEx.Replace(S, '^[ \t]{0,3}#{1,6}[ \t]*', '', [roMultiLine]);
  S := TRegEx.Replace(S, '^[ \t]*>[ \t]?', '', [roMultiLine]);
  S := TRegEx.Replace(S, '^[ \t]*(?:[-*+]|\d+[.)])[ \t]+', '', [roMultiLine]);
  // Tables: separator rows go, pipes become spaces.
  S := TRegEx.Replace(S, '^[ \t]*\|?[ \t]*:?-{2,}:?[ \t]*(?:\|[ \t]*:?-{2,}:?[ \t]*)*\|?[ \t]*$', '', [roMultiLine]);
  S := S.Replace('|', ' ');
  // Horizontal rules.
  S := TRegEx.Replace(S, '^[ \t]*([-*_][ \t]*){3,}$', '', [roMultiLine]);
  // Emphasis and inline code markers (underscores inside words are kept).
  S := S.Replace('**', '').Replace('__', '').Replace('`', '');
  S := TRegEx.Replace(S, '(?<!\w)[*_]+|[*_]+(?!\w)', '');
  S := TNetEncoding.HTML.Decode(S);
  // Whitespace: single spaces, trimmed lines, paragraphs separated by one blank line.
  S := TRegEx.Replace(S, '[ \t]+', ' ');
  S := TRegEx.Replace(S, ' *\n *', #10);
  S := TRegEx.Replace(S, '\n{3,}', #10#10);
  Result := S.Trim;
end;

class function THelpChatIndexBuilder.ExtractSummary(const APlainText, ATitle: string;
  const AMinLength, AMaxLength: Integer): string;
var
  LParagraph, LCandidate: string;
  LCut: Integer;
begin
  Result := '';
  for LParagraph in APlainText.Split([#10#10]) do
  begin
    LCandidate := LParagraph.Replace(#10, ' ').Trim;
    if (LCandidate.Length >= AMinLength) and not SameText(LCandidate, ATitle) then
    begin
      Result := LCandidate;
      Break;
    end;
  end;
  if (Result = '') then
    // Nothing long enough: take the first non-title paragraph anyway.
    for LParagraph in APlainText.Split([#10#10]) do
    begin
      LCandidate := LParagraph.Replace(#10, ' ').Trim;
      if (LCandidate <> '') and not SameText(LCandidate, ATitle) then
      begin
        Result := LCandidate;
        Break;
      end;
    end;
  if (AMaxLength > 0) and (Result.Length > AMaxLength) then
  begin
    LCut := Result.LastIndexOf(' ', AMaxLength - 1);
    if LCut < AMaxLength div 2 then
      LCut := AMaxLength - 1;
    Result := Result.Substring(0, LCut).TrimRight([' ', ',', ';', ':']) + #$2026;
  end;
end;

class function THelpChatIndexBuilder.CollapseText(const APlainText: string;
  const AMaxLength: Integer): string;
begin
  Result := TRegEx.Replace(APlainText, '\s+', ' ').Trim;
  if (AMaxLength > 0) and (Result.Length > AMaxLength) then
    Result := Result.Substring(0, AMaxLength);
end;

class function THelpChatIndexBuilder.ParseToc(const AMarkdown: string): TDictionary<string, THelpChatTocEntry>;
var
  LLine, LTitle, LFile, LIndent: string;
  LMatch: TMatch;
  LLevel, I: Integer;
  LStack: TList<string>;
  LEntry: THelpChatTocEntry;
begin
  Result := TDictionary<string, THelpChatTocEntry>.Create;
  LStack := TList<string>.Create;
  try
    for LLine in AMarkdown.Replace(#13, '').Split([#10]) do
    begin
      // "[title](file.md)" optionally preceded by indentation, a list marker
      // or the bar of a table cell: a table of contents written as a Markdown
      // table is a table of contents too, and its rows are all top level.
      LMatch := TRegEx.Match(LLine, '^([ \t]*)(?:\|\s*)?(?:[-*+]\s+)?\[([^\]]+)\]\(([^)#]+\.md)(?:#[^)]*)?\)');
      if not LMatch.Success then
        Continue;
      LIndent := LMatch.Groups[1].Value.Replace(#9, '    ');
      // Level: 0 for a bare top-level link, 1 for "- [..]", +1 per 4 spaces.
      if TRegEx.IsMatch(LLine, '^[ \t]*[-*+]\s+') then
        LLevel := 1 + LIndent.Length div 4
      else
        LLevel := 0;
      LTitle := CleanTitle(LMatch.Groups[2].Value);
      LFile := LMatch.Groups[3].Value.Trim.Replace('\', '/').ToLower;
      if LFile.StartsWith('./') then
        LFile := LFile.Substring(2);

      while LStack.Count > LLevel do
        LStack.Delete(LStack.Count - 1);
      while LStack.Count < LLevel do
        LStack.Add(''); // a skipped level: no title to inherit

      LEntry.Title := LTitle;
      LEntry.Breadcrumb := nil;
      for I := 0 to LStack.Count - 1 do
        if LStack[I] <> '' then
          LEntry.Breadcrumb := LEntry.Breadcrumb + [LStack[I]];
      Result.AddOrSetValue(LFile, LEntry);
      LStack.Add(LTitle);
    end;
  finally
    LStack.Free;
  end;
end;

function THelpChatIndexBuilder.Build(const AOptions: THelpChatIndexBuilderOptions): TArray<THelpChatIndexPage>;
var
  LFiles: TArray<string>;
  LFile, LRelative, LKey, LMarkdown, LFrontMatter, LBody, LPlain, LTocPath: string;
  LToc: TDictionary<string, THelpChatTocEntry>;
  LTocEntry: THelpChatTocEntry;
  LHasToc: Boolean;
  LPage: THelpChatIndexPage;
  LPages: TList<THelpChatIndexPage>;
  LKeywords: TList<string>;
  LOption: TSearchOption;
  LSource, K: string;

  function AlreadyIn(const AList: TList<string>; const AValue: string): Boolean;
  var
    S: string;
  begin
    for S in AList do
      if SameText(S, AValue) then
        Exit(True);
    Result := False;
  end;

begin
  FWarnings.Clear;
  LSource := TPath.GetFullPath(AOptions.SourceFolder);
  if not TDirectory.Exists(LSource) then
    raise EDirectoryNotFoundException.CreateFmt('Source folder not found: %s', [LSource]);
  if AOptions.Recursive then
    LOption := TSearchOption.soAllDirectories
  else
    LOption := TSearchOption.soTopDirectoryOnly;
  LFiles := TDirectory.GetFiles(LSource, '*.md', LOption);
  TArray.Sort<string>(LFiles, TIStringComparer.Ordinal);

  // Table of contents: titles and breadcrumbs, keyed by relative file name.
  LToc := nil;
  LHasToc := False;
  LTocPath := '';
  if AOptions.TocFile <> '' then
  begin
    LTocPath := TPath.Combine(LSource, AOptions.TocFile);
    for LFile in LFiles do
      if SameText(LFile, LTocPath) then
      begin
        LTocPath := LFile; // actual casing on disk
        LToc := ParseToc(ReadTextFile(LFile));
        LHasToc := True;
        Break;
      end;
    if not LHasToc then
      FWarnings.Add(Format('Table of contents not found: %s (titles fall back to headings and file names)', [AOptions.TocFile]));
  end;

  LPages := TList<THelpChatIndexPage>.Create;
  LKeywords := TList<string>.Create;
  try
    for LFile in LFiles do
    begin
      if LHasToc and SameText(LFile, LTocPath) then
        Continue;
      LRelative := LFile.Substring(LSource.Length).TrimLeft(['\', '/']).Replace('\', '/');
      LKey := LRelative.ToLower;

      LMarkdown := ReadTextFile(LFile);
      LBody := StripFrontMatter(LMarkdown, LFrontMatter);
      LPage := System.Default(THelpChatIndexPage);
      LPage.SourceFile := LRelative;
      LPage.Id := TPath.ChangeExtension(LRelative, '').TrimRight(['.']);
      LPage.Url := AOptions.UrlPrefix + TPath.ChangeExtension(LRelative, '').TrimRight(['.']) +
        IfThen(AOptions.UrlExtension <> '', AOptions.UrlExtension, '.md');

      LPage.Title := ExtractTitle(LBody, LFrontMatter);
      LKeywords.Clear;
      if LHasToc and LToc.TryGetValue(LKey, LTocEntry) then
      begin
        if LPage.Title = '' then
          LPage.Title := LTocEntry.Title
        else if not SameText(LPage.Title, LTocEntry.Title) then
          LKeywords.Add(LTocEntry.Title);
        for K in LTocEntry.Breadcrumb do
          if not AlreadyIn(LKeywords, K) and not SameText(K, LPage.Title) then
            LKeywords.Add(K);
      end
      else if LHasToc then
        FWarnings.Add(Format('%s: not referenced by %s', [LRelative, AOptions.TocFile]));
      if LPage.Title = '' then
      begin
        LPage.Title := TPath.GetFileNameWithoutExtension(LRelative).Replace('_', ' ').Replace('-', ' ');
        FWarnings.Add(Format('%s: no title found, using the file name', [LRelative]));
      end;
      LPage.Keywords := LKeywords.ToArray;

      LPlain := MarkdownToPlainText(LBody);
      if LPlain = '' then
      begin
        FWarnings.Add(Format('%s: empty page, skipped', [LRelative]));
        Continue;
      end;
      LPage.Summary := ExtractSummary(LPlain, LPage.Title, AOptions.SummaryMinLength, AOptions.SummaryMaxLength);
      LPage.Text := CollapseText(LPlain, AOptions.MaxTextLength);
      LPages.Add(LPage);
    end;
    Result := LPages.ToArray;
  finally
    LKeywords.Free;
    LPages.Free;
    LToc.Free;
  end;
end;

class function THelpChatIndexBuilder.ToJSON(const APages: TArray<THelpChatIndexPage>;
  const APretty: Boolean): string;
var
  LArray, LKeywords: TJSONArray;
  LItem: TJSONObject;
  LPage: THelpChatIndexPage;
  K: string;
begin
  LArray := TJSONArray.Create;
  try
    for LPage in APages do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('id', LPage.Id);
      LItem.AddPair('title', LPage.Title);
      LItem.AddPair('url', LPage.Url);
      LItem.AddPair('summary', LPage.Summary);
      LKeywords := TJSONArray.Create;
      for K in LPage.Keywords do
        LKeywords.Add(K);
      LItem.AddPair('keywords', LKeywords);
      LItem.AddPair('text', LPage.Text);
      LArray.AddElement(LItem);
    end;
    if APretty then
      Result := LArray.Format(2)
    else
      Result := LArray.ToJSON;
  finally
    LArray.Free;
  end;
end;

function THelpChatIndexBuilder.BuildToFile(const AOptions: THelpChatIndexBuilderOptions;
  const AOutputFile: string): Integer;
var
  LPages: TArray<THelpChatIndexPage>;
  LDir: string;
begin
  LPages := Build(AOptions);
  LDir := TPath.GetDirectoryName(TPath.GetFullPath(AOutputFile));
  if (LDir <> '') and not TDirectory.Exists(LDir) then
    TDirectory.CreateDirectory(LDir);
  TFile.WriteAllText(AOutputFile, ToJSON(LPages), TEncoding.UTF8);
  Result := Length(LPages);
end;

end.
