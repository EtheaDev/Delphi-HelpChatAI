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
  System.Generics.Collections,
  HelpChatAI.Settings;

const
  /// <summary>Extension of a link when the manual is published as a site.</summary>
  HELPCHAT_INDEXBUILDER_DEF_URLEXT = '.html';
  /// <summary>Characters of plain text kept per page: what the search
  /// scores on and the excerpts are cut from. A longer page is indexed for
  /// its beginning only.</summary>
  HELPCHAT_INDEXBUILDER_DEF_MAXTEXT = 8000;
  /// <summary>Longest summary, in characters, cut at a word.</summary>
  HELPCHAT_INDEXBUILDER_DEF_SUMMARYMAX = 320;
  /// <summary>A paragraph shorter than this is a caption or a note, not a
  /// summary, as long as a longer one follows.</summary>
  HELPCHAT_INDEXBUILDER_DEF_SUMMARYMIN = 40;
  /// <summary>Name of the table of contents, looked for at the root of the
  /// folder without regard to case.</summary>
  HELPCHAT_INDEXBUILDER_DEF_TOCFILE = 'index.md';

type
  /// <summary>What a build needs to know. Start from <c>Default</c> and
  /// set <c>SourceFolder</c>: a record of zeroes is another build - not
  /// recursive, no table of contents, links in <c>.md</c>, texts and
  /// summaries uncut.</summary>
  THelpChatIndexBuilderOptions = record
    /// <summary>Folder holding the Markdown pages.</summary>
    SourceFolder: string;
    /// <summary>Include sub-folders (images folders hold no .md and are
    /// harmless). The first sub-folder of a page is also its area, unless
    /// its front matter says otherwise.</summary>
    Recursive: Boolean;
    /// <summary>Table of contents file, relative to SourceFolder (case-insensitive);
    /// gives titles and breadcrumbs and is never indexed as a page. Empty
    /// means there is none, and nothing is said about it; a name that is
    /// not found is a warning.</summary>
    TocFile: string;
    /// <summary>Extension of the published pages ('.html'); empty keeps '.md'.</summary>
    UrlExtension: string;
    /// <summary>Prepended to every relative URL (e.g. 'manual/').</summary>
    UrlPrefix: string;
    /// <summary>Characters of plain text kept per page (0 = the whole
    /// page).</summary>
    MaxTextLength: Integer;
    /// <summary>Longest summary, in characters (0 = uncut).</summary>
    SummaryMaxLength: Integer;
    /// <summary>Shortest paragraph taken as the summary when a longer one
    /// exists.</summary>
    SummaryMinLength: Integer;
    /// <summary>Recursive, <c>index.md</c> as table of contents, links in
    /// <c>.html</c> and the default sizes; the folder is left empty.</summary>
    class function Default: THelpChatIndexBuilderOptions; static;
  end;

  /// <summary>One page of the index being built: what <c>ToJSON</c> writes
  /// and <c>THelpChatDocIndex</c> reads back.</summary>
  THelpChatIndexPage = record
    /// <summary>Relative path without the extension, forward slashes.</summary>
    Id: string;
    /// <summary>Front matter, else first heading, else the text of its
    /// link in the table of contents, else the file name.</summary>
    Title: string;
    /// <summary>Prefix, relative path and the published extension.</summary>
    Url: string;
    Summary: string;
    /// <summary>The page as plain text on one line, cut to
    /// <c>MaxTextLength</c>.</summary>
    Text: string;
    /// <summary>Other names the page answers to: its title in the table of
    /// contents when it differs from its heading, and the titles of its
    /// ancestors there.</summary>
    Keywords: TArray<string>;
    /// <summary>The areas of the manual the page belongs to: the
    /// <c>areas:</c> of its front matter when it has one, else the first
    /// sub-folder of its path; none for a page at the root of the manual,
    /// which every assistant sees.</summary>
    Areas: TArray<string>;
    /// <summary>Relative source path, for diagnostics.</summary>
    SourceFile: string;
  end;

  /// <summary>A page as described by the table of contents.</summary>
  THelpChatTocEntry = record
    /// <summary>Text of the link, emphasis markers removed.</summary>
    Title: string;
    /// <summary>Titles of the ancestors, outermost first.</summary>
    Breadcrumb: TArray<string>;
  end;

  /// <summary>
  ///  The builder. An instance holds nothing but the warnings of its last
  ///  <c>Build</c>; every step of the work is a static class function, so
  ///  that each can be tested, and reused, on its own (the attachments
  ///  borrow <c>IsValidUtf8</c>). Not thread-safe: one instance per build.
  /// </summary>
  THelpChatIndexBuilder = class
  strict private
    FWarnings: TStrings;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Reads a text file detecting its encoding: BOM if present, else
    /// UTF-8 when the bytes are valid UTF-8, else the ANSI code page.</summary>
    class function ReadTextFile(const AFileName: string): string; static;
    /// <summary>True when ABytes is a well-formed UTF-8 sequence, as far as
    /// lead and continuation bytes go (overlong forms and surrogates are
    /// not looked for). Pure ASCII and an empty array are valid. It is the
    /// test that tells a UTF-8 file without BOM from an ANSI one.</summary>
    class function IsValidUtf8(const ABytes: TBytes): Boolean; static;
    /// <summary>Removes a leading YAML front matter block - between a first
    /// line of three dashes and the next line starting with three - and
    /// returns it, trimmed, in AFrontMatter. A page without one, or whose
    /// block is never closed, comes back unchanged.</summary>
    class function StripFrontMatter(const AMarkdown: string; out AFrontMatter: string): string; static;
    /// <summary>The areas of a page: the front matter <c>areas:</c> - a list
    /// in brackets or separated by commas, on the line of the key, an empty
    /// one for none - else the first folder of ARelative
    /// ("Orders/New-Order.md" -> Orders; only the first, however deep the
    /// page is). <c>ARelative</c> must use forward slashes, as <c>Build</c>
    /// passes it. A key that is there decides, even with no value: the
    /// folder is not consulted, which is how a page inside a folder is made
    /// everybody's. Names are returned as written; the index compares them
    /// without case. A YAML block list on the following lines
    /// ("areas:" alone, then "- Orders" lines) is read as well.</summary>
    class function ExtractAreas(const AFrontMatter, ARelative: string): TArray<string>; static;
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

    /// <summary>Builds the pages of every Markdown file under the source
    /// folder, in the order of their paths (case-insensitive), so that two
    /// builds of the same manual give the same file. The table of contents
    /// is not a page; a page with no text is skipped with a warning.
    /// Raises <c>EDirectoryNotFoundException</c> when the folder is not
    /// there, and whatever reading a file raises.</summary>
    function Build(const AOptions: THelpChatIndexBuilderOptions): TArray<THelpChatIndexPage>;
    /// <summary>Serializes pages to the JSON array THelpChatDocIndex loads.
    /// <c>areas</c> is written only for the pages that have some, so the
    /// index of a manual without areas is what it was before they
    /// existed.</summary>
    class function ToJSON(const APages: TArray<THelpChatIndexPage>; const APretty: Boolean = True): string; static;
    /// <summary>Build + ToJSON + write (UTF-8, with BOM), creating the
    /// folder of the file when it is missing. Returns the number of pages;
    /// a file is written even when that is zero. Raises what
    /// <c>Build</c> raises and what writing the file does.</summary>
    function BuildToFile(const AOptions: THelpChatIndexBuilderOptions; const AOutputFile: string): Integer;

    /// <summary>Non-fatal findings of the last Build (pages without title or text...).</summary>
    property Warnings: TStrings read FWarnings;
  end;

  /// <summary>
  ///  Rebuilding the index of an application that is configured already: the
  ///  settings say where the pages are (<c>DocFolder</c>) and where the index
  ///  goes (<c>DocIndexFile</c>), so nobody has to type a path again. Filled
  ///  by <see cref="HelpChatPlanIndexBuild" /> - which decides and explains,
  ///  without touching anything - and carried into
  ///  <see cref="HelpChatRunIndexBuild" />, which does the work and writes
  ///  back how it went.
  /// </summary>
  THelpChatIndexPlan = record
    /// <summary>Folder of the Markdown pages (<c>Settings.DocFolder</c>).</summary>
    SourceFolder: string;
    /// <summary>The JSON to write (<c>Settings.DocIndexFile</c>).</summary>
    OutputFile: string;
    /// <summary>Table of contents found in the folder; empty when there is none.</summary>
    TocFile: string;
    /// <summary>Extension the links get: empty when the pages are shown inside
    /// the panel, <c>.html</c> when they are published under <c>DocBaseUrl</c>.</summary>
    UrlExtension: string;
    /// <summary>An index is already there and will be replaced.</summary>
    OutputExists: Boolean;
    /// <summary>Markdown files found under the folder.</summary>
    MarkdownCount: Integer;
    /// <summary>Why it cannot be built, or why it failed; empty when all is well.</summary>
    Problem: string;
    /// <summary>Pages written, after the build.</summary>
    PageCount: Integer;
    /// <summary>What the builder had to say about single pages, after the build.</summary>
    Warnings: string;
    /// <summary>Nothing is in the way.</summary>
    function CanBuild: Boolean;
    /// <summary>The plan in four lines, for whoever has to confirm it:
    /// English, like every text of the design-time tools, and with what was
    /// deduced - the extension of the links - said in words.</summary>
    function Describe: string;
  end;

/// <summary>Works out what rebuilding the index of these settings would do,
/// and changes nothing. Read <c>Problem</c> first. The folder and the file
/// are the resolved ones (<c>ResolveDocFolder</c>,
/// <c>ResolveDocIndexFile</c>), so the settings must already be those of the
/// application and not of the IDE. The one thing deduced is the extension
/// of the links: <c>.md</c> without a <c>DocBaseUrl</c>, <c>.html</c> with
/// one. The index is one for the whole manual: <c>DocAreas</c> plays no
/// part here, the areas are read back from the pages. Never raises for
/// settings that are nil or incomplete.</summary>
function HelpChatPlanIndexBuild(const ASettings: THelpChatSettings): THelpChatIndexPlan;

/// <summary>Runs the plan, writing the index. False, with <c>Problem</c> set,
/// when it could not: a plan that cannot be built, a folder that is read-only,
/// a file somebody has open, or a manual that produced no page (the empty
/// index is written all the same). Never raises. An engine that is running
/// keeps the index it loaded: the new one is read at the next start.</summary>
function HelpChatRunIndexBuild(var APlan: THelpChatIndexPlan): Boolean;

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

class function THelpChatIndexBuilder.ExtractAreas(const AFrontMatter, ARelative: string): TArray<string>;
var
  LMatch, LBlock: TMatch;
  LValue, LItem: string;
  LSlash: Integer;
begin
  Result := nil;
  if AFrontMatter <> '' then
  begin
    // Blanks and tabs, not \s: \s also matches the end of the line, and
    // "areas:" with nothing after it then took the whole next line as its
    // value - a page said to be everybody's ended up in an area called
    // "title: Welcome", which no assistant has.
    LMatch := TRegEx.Match(AFrontMatter, '^[ \t]*areas[ \t]*:[ \t]*(.*?)[ \t\r]*$',
      [roMultiLine, roIgnoreCase]);
    if LMatch.Success then
    begin
      // Said explicitly, even empty: that is the answer.
      LValue := LMatch.Groups[1].Value.Trim(['[', ']', ' ']);
      for LItem in LValue.Split([',']) do
        if LItem.Trim([' ', '"', '''']) <> '' then
          Result := Result + [LItem.Trim([' ', '"', ''''])];
      // Nothing on the line at all (not even "[]"): the block form of YAML,
      // one "- Area" per line right below the key.
      if LMatch.Groups[1].Value = '' then
      begin
        LBlock := TRegEx.Match(AFrontMatter.Substring(LMatch.Index - 1 + LMatch.Length),
          '\A(?:\r?\n[ \t]*-[ \t]*[^\r\n]*)+');
        if LBlock.Success then
          for LItem in LBlock.Value.Split([#10]) do
            if LItem.Trim([' ', #9, #13, '-', '"', '''']) <> '' then
              Result := Result + [LItem.Trim([' ', #9, #13, '-', '"', ''''])];
      end;
      Exit;
    end;
  end;
  // No key at all: the folder decides. A page at the root has no slash and
  // no area, which makes it a page of every assistant.
  LSlash := ARelative.IndexOf('/');
  if LSlash > 0 then
    Result := [ARelative.Substring(0, LSlash)];
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
      // Forward slashes from here on: the id, the URL, the key of the table
      // of contents and the area are all read off this one string.
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
      LPage.Areas := ExtractAreas(LFrontMatter, LRelative);

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
      // Only when there is something to say: a manual without areas keeps the
      // index it always had.
      if Length(LPage.Areas) > 0 then
      begin
        LKeywords := TJSONArray.Create;
        for K in LPage.Areas do
          LKeywords.Add(K);
        LItem.AddPair('areas', LKeywords);
      end;
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

{ THelpChatIndexPlan }

function THelpChatIndexPlan.CanBuild: Boolean;
begin
  Result := (Problem = '') and (SourceFolder <> '') and (OutputFile <> '');
end;

function THelpChatIndexPlan.Describe: string;
const
  SLine = '%-10s%s';
var
  LIndex, LToc, LLinks: string;
begin
  LIndex := OutputFile;
  if OutputExists then
    LIndex := LIndex + ' (replacing the one that is there)';
  if TocFile = '' then
    LToc := Format('none (no %s in the folder): titles come from the headings',
      [HELPCHAT_INDEXBUILDER_DEF_TOCFILE])
  else
    LToc := TocFile;
  if UrlExtension = '' then
    LLinks := 'page.md - the pages are shown inside the panel (DocBaseUrl is empty)'
  else
    LLinks := 'page' + UrlExtension + ' - the pages are published under DocBaseUrl';
  Result :=
    Format(SLine, ['Pages:', Format('%s (%d Markdown files)',
      [SourceFolder, MarkdownCount])]) + sLineBreak +
    Format(SLine, ['Index:', LIndex]) + sLineBreak +
    Format(SLine, ['Contents:', LToc]) + sLineBreak +
    Format(SLine, ['Links:', LLinks]);
end;

function HelpChatPlanIndexBuild(const ASettings: THelpChatSettings): THelpChatIndexPlan;
var
  LToc: TArray<string>;
begin
  Result := Default(THelpChatIndexPlan);
  if ASettings = nil then
  begin
    Result.Problem := 'No settings to build an index from.';
    Exit;
  end;
  Result.SourceFolder := ASettings.ResolveDocFolder;
  Result.OutputFile := ASettings.ResolveDocIndexFile;
  // Without DocBaseUrl the pages are read from DocFolder and rendered inside
  // the panel, so a link keeps the name of the file; with one they are
  // published somewhere, where a page is .html.
  if Trim(ASettings.DocBaseUrl) <> '' then
    Result.UrlExtension := HELPCHAT_INDEXBUILDER_DEF_URLEXT;
  if Result.SourceFolder = '' then
  begin
    Result.Problem := 'Settings.DocFolder is empty: there is no folder of ' +
      'Markdown pages to build an index from.';
    Exit;
  end;
  if not TDirectory.Exists(Result.SourceFolder) then
  begin
    Result.Problem := Format('Settings.DocFolder points to "%s", which does ' +
      'not exist.', [Result.SourceFolder]);
    Exit;
  end;
  if Result.OutputFile = '' then
  begin
    Result.Problem := 'There is nowhere to write the index: Settings.DocIndexFile ' +
      'resolves to nothing.';
    Exit;
  end;
  Result.MarkdownCount := Length(TDirectory.GetFiles(Result.SourceFolder, '*.md',
    TSearchOption.soAllDirectories));
  if Result.MarkdownCount = 0 then
  begin
    Result.Problem := Format('No Markdown page under "%s".', [Result.SourceFolder]);
    Exit;
  end;
  // The name as the folder spells it: the builder matches it case-insensitively
  // anyway, but what is shown has to be what is there.
  LToc := TDirectory.GetFiles(Result.SourceFolder, HELPCHAT_INDEXBUILDER_DEF_TOCFILE);
  if Length(LToc) > 0 then
    Result.TocFile := TPath.GetFileName(LToc[0]);
  Result.OutputExists := TFile.Exists(Result.OutputFile);
end;

function HelpChatRunIndexBuild(var APlan: THelpChatIndexPlan): Boolean;
var
  LBuilder: THelpChatIndexBuilder;
  LOptions: THelpChatIndexBuilderOptions;
begin
  APlan.PageCount := 0;
  APlan.Warnings := '';
  if not APlan.CanBuild then
    Exit(False);
  LOptions := THelpChatIndexBuilderOptions.Default;
  LOptions.SourceFolder := APlan.SourceFolder;
  LOptions.TocFile := APlan.TocFile;
  LOptions.UrlExtension := APlan.UrlExtension;
  LBuilder := THelpChatIndexBuilder.Create;
  try
    try
      APlan.PageCount := LBuilder.BuildToFile(LOptions, APlan.OutputFile);
      APlan.Warnings := LBuilder.Warnings.Text;
    except
      on E: Exception do
      begin
        APlan.Problem := E.Message;
        Exit(False);
      end;
    end;
  finally
    LBuilder.Free;
  end;
  Result := APlan.PageCount > 0;
  if not Result then
    APlan.Problem := Format('Nothing was indexed: the %d Markdown files under ' +
      '"%s" produced no page.', [APlan.MarkdownCount, APlan.SourceFolder]);
  APlan.OutputExists := TFile.Exists(APlan.OutputFile);
end;

end.
