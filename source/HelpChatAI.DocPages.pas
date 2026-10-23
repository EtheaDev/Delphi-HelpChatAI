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
///  The documentation pages shown inside the panel: the Markdown files of a
///  local folder (<c>Settings.DocFolder</c>), rendered on request as a safe
///  HTML fragment. A page link in a reply or in another page opens here instead
///  of in a browser, so a desktop application needs no web server for its
///  manual.
///
///  Rules that keep it safe: a page name is a relative path that must stay
///  inside the folder (no drive, no scheme, no way out with "..") and end in
///  .md; the Markdown goes through <see cref="HelpChatMarkdownToSafeHtml" />
///  like a model reply; images of the folder are inlined as data: URIs (the
///  page needs no token-less route and its CSP already allows data: images),
///  everything else keeps the URL the sanitizer let through.
/// </summary>
unit HelpChatAI.DocPages;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils;

const
  /// <summary>Extension added to a page name that has none ("110" -> "110.md").</summary>
  HELPCHAT_DOCPAGE_DEF_EXT = '.md';
  /// <summary>Images larger than this are not inlined (their URL is left as is).</summary>
  HELPCHAT_DOCPAGE_IMAGE_MAXBYTES = 2 * 1024 * 1024;

type
  /// <summary>Lets the application adjust the Markdown of a page before it is
  /// rendered (placeholders, variables). Called on an HTTP thread: it must not
  /// touch the UI.</summary>
  THelpChatDocPageFilter = reference to procedure(const APage: string; var AMarkdown: string);

  /// <summary>A rendered documentation page.</summary>
  THelpChatRenderedDoc = record
    /// <summary>Normalized relative path, forward slashes ("guide/110.md").</summary>
    Page: string;
    /// <summary>Front matter title, first heading or file name.</summary>
    Title: string;
    /// <summary>Safe HTML fragment of the page body.</summary>
    Html: string;
  end;

  THelpChatDocPages = class
  strict private
    FFolder: string;
  public
    /// <summary>AFolder is the root of the pages; relative paths are resolved
    /// against the current directory by the caller, not here.</summary>
    constructor Create(const AFolder: string);
    /// <summary>A relative path cleaned of query, fragment, "." and ".."
    /// segments, with forward slashes and no leading slash; empty when it is
    /// not a relative path that stays below the root.</summary>
    class function NormalizePath(const APath: string): string; static;
    /// <summary>NormalizePath plus the page rules: ".md" added when there is no
    /// extension, only .md/.markdown accepted. Empty when not a page.</summary>
    class function NormalizePage(const APage: string): string; static;
    /// <summary>Full name of a normalized relative path when the file exists
    /// inside the folder.</summary>
    function ResolveFile(const ARelative: string; out AFileName: string): Boolean;
    /// <summary>True when the folder exists.</summary>
    function IsAvailable: Boolean;
    /// <summary>Renders APage (a link as written in a page or a reply). False
    /// when it is not a page of the folder.</summary>
    function Render(const APage: string; const AFilter: THelpChatDocPageFilter;
      out ADoc: THelpChatRenderedDoc): Boolean;
    property Folder: string read FFolder;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.NetEncoding,
  System.RegularExpressions,
  HelpChatAI.Html,
  HelpChatAI.IndexBuilder;

type
  // TMatchEvaluator is a method pointer: one holder per call keeps Render
  // thread-safe (the HTTP server renders on its connection threads).
  TDocImageInliner = class
  strict private
    FPages: THelpChatDocPages;
    FPageDir: string;
    function ImageMime(const AFileName: string): string;
  public
    constructor Create(const APages: THelpChatDocPages; const APage: string);
    function Evaluate(const AMatch: TMatch): string;
  end;

{ TDocImageInliner }

constructor TDocImageInliner.Create(const APages: THelpChatDocPages; const APage: string);
var
  P: Integer;
begin
  inherited Create;
  FPages := APages;
  P := APage.LastIndexOf('/');
  if P >= 0 then
    FPageDir := APage.Substring(0, P + 1)
  else
    FPageDir := '';
end;

/// <summary>
///  Size of a file without opening it. TFile.GetSize arrived in Delphi 11 and
///  the library still compiles on 10.4, where TSearchRec is the way.
/// </summary>
function HelpChatFileSize(const AFileName: string): Int64;
var
  LRec: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, LRec) = 0 then
  try
    Result := LRec.Size;
  finally
    System.SysUtils.FindClose(LRec);
  end;
end;

function TDocImageInliner.ImageMime(const AFileName: string): string;
var
  LExt: string;
begin
  LExt := TPath.GetExtension(AFileName).ToLower;
  if LExt = '.png' then
    Result := 'image/png'
  else if (LExt = '.jpg') or (LExt = '.jpeg') then
    Result := 'image/jpeg'
  else if LExt = '.gif' then
    Result := 'image/gif'
  else if LExt = '.webp' then
    Result := 'image/webp'
  else if LExt = '.bmp' then
    Result := 'image/bmp'
  else if LExt = '.svg' then
    Result := 'image/svg+xml' // as <img>: scripts inside never run
  else
    Result := '';
end;

function TDocImageInliner.Evaluate(const AMatch: TMatch): string;
var
  LQuoted, LUrl, LRelative, LFileName, LMime: string;
  LEncoder: TBase64Encoding;
begin
  Result := AMatch.Value;
  LQuoted := AMatch.Groups[2].Value;
  LUrl := TNetEncoding.URL.Decode(TNetEncoding.HTML.Decode(LQuoted.Substring(1, LQuoted.Length - 2)));
  // Only a path of the folder: "/x" from the root, "x" from the page's folder.
  if (LUrl = '') or LUrl.StartsWith('#') or LUrl.StartsWith('//') or LUrl.Contains(':') then
    Exit;
  if LUrl.StartsWith('/') then
    LRelative := THelpChatDocPages.NormalizePath(LUrl)
  else
    LRelative := THelpChatDocPages.NormalizePath(FPageDir + LUrl);
  if (LRelative = '') or not FPages.ResolveFile(LRelative, LFileName) then
    Exit;
  LMime := ImageMime(LFileName);
  if (LMime = '') or (HelpChatFileSize(LFileName) > HELPCHAT_DOCPAGE_IMAGE_MAXBYTES) then
    Exit;
  LEncoder := TBase64Encoding.Create(0); // no line breaks inside the attribute
  try
    Result := AMatch.Groups[1].Value + '"data:' + LMime + ';base64,' +
      LEncoder.EncodeBytesToString(TFile.ReadAllBytes(LFileName)) + '"';
  finally
    LEncoder.Free;
  end;
end;

{ THelpChatDocPages }

constructor THelpChatDocPages.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := ExcludeTrailingPathDelimiter(AFolder);
end;

class function THelpChatDocPages.NormalizePath(const APath: string): string;
var
  LPath, LSegment: string;
  LSegments: TArray<string>;
  LCount, P: Integer;
begin
  LPath := Trim(APath);
  P := LPath.IndexOfAny(['?', '#']);
  if P >= 0 then
    LPath := LPath.Substring(0, P);
  LPath := LPath.Replace('\', '/');
  // A scheme or a drive ("http:", "C:") is never a page of the folder.
  if (LPath = '') or LPath.Contains(':') or LPath.StartsWith('//') then
    Exit('');
  SetLength(LSegments, 0);
  LCount := 0;
  for LSegment in LPath.Split(['/']) do
  begin
    if (LSegment = '') or (LSegment = '.') then
      Continue;
    if LSegment = '..' then
    begin
      if LCount = 0 then
        Exit(''); // above the root
      Dec(LCount);
      Continue;
    end;
    if Length(LSegments) <= LCount then
      SetLength(LSegments, LCount + 1);
    LSegments[LCount] := LSegment;
    Inc(LCount);
  end;
  if LCount = 0 then
    Exit('');
  Result := string.Join('/', LSegments, 0, LCount);
end;

class function THelpChatDocPages.NormalizePage(const APage: string): string;
var
  LExt: string;
begin
  Result := NormalizePath(APage);
  if Result = '' then
    Exit;
  LExt := TPath.GetExtension(Result).ToLower;
  if LExt = '' then
    Result := Result + HELPCHAT_DOCPAGE_DEF_EXT
  else if (LExt <> '.md') and (LExt <> '.markdown') then
    Result := '';
end;

function THelpChatDocPages.ResolveFile(const ARelative: string; out AFileName: string): Boolean;
var
  LRoot: string;
begin
  AFileName := '';
  if (FFolder = '') or (ARelative = '') then
    Exit(False);
  LRoot := IncludeTrailingPathDelimiter(ExpandFileName(FFolder));
  AFileName := ExpandFileName(LRoot + ARelative.Replace('/', PathDelim));
  // NormalizePath already keeps it below the root: checked again on the real
  // path, which is what the file system will open.
  Result := AFileName.StartsWith(LRoot, True) and TFile.Exists(AFileName);
  if not Result then
    AFileName := '';
end;

function THelpChatDocPages.IsAvailable: Boolean;
begin
  Result := (FFolder <> '') and TDirectory.Exists(FFolder);
end;

function THelpChatDocPages.Render(const APage: string; const AFilter: THelpChatDocPageFilter;
  out ADoc: THelpChatRenderedDoc): Boolean;
var
  LFileName, LMarkdown, LFrontMatter: string;
  LInliner: TDocImageInliner;
begin
  ADoc := Default(THelpChatRenderedDoc);
  ADoc.Page := NormalizePage(APage);
  if not ResolveFile(ADoc.Page, LFileName) then
    Exit(False);
  LMarkdown := THelpChatIndexBuilder.ReadTextFile(LFileName);
  if Assigned(AFilter) then
    AFilter(ADoc.Page, LMarkdown);
  LMarkdown := THelpChatIndexBuilder.StripFrontMatter(LMarkdown, LFrontMatter);
  ADoc.Title := THelpChatIndexBuilder.CleanTitle(
    THelpChatIndexBuilder.ExtractTitle(LMarkdown, LFrontMatter));
  if ADoc.Title = '' then
    ADoc.Title := TPath.GetFileNameWithoutExtension(LFileName);
  LInliner := TDocImageInliner.Create(Self, ADoc.Page);
  try
    ADoc.Html := TRegEx.Replace(HelpChatMarkdownToSafeHtml(LMarkdown),
      '(<img\b[^>]*?\bsrc\s*=\s*)("[^"]*"|''[^'']*'')', LInliner.Evaluate, [roIgnoreCase]);
  finally
    LInliner.Free;
  end;
  Result := True;
end;

end.
