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
///  HTML to PDF, locally, with the engine that is already in the process: the
///  WebView2 runtime the panel needs anyway. <see cref="THelpChatPdfExporter" />
///  puts a WebView2 on a window of its own that is never shown, loads the
///  document and calls <c>ICoreWebView2_7.PrintToPdf</c>. Measured end to end,
///  environment and browser process included: under half a second.
///
///  <para>The interfaces are declared here instead of taken from the RTL on
///  purpose. Delphi 12 and 13 import the whole WebView2 SDK, but 11 imports
///  only the base <c>ICoreWebView2</c> and 10.4 has it under another unit name
///  (<c>WebView2</c>, not <c>Winapi.WebView2</c>): one set of declarations of
///  ours is one source for all four versions, with no IFDEF on a unit name and
///  no dependency of the engine package on a WebView unit. A COM interface is
///  its IID plus the position of its methods in the vtable, so the reserved
///  slots below are not padding - they are what makes the real method land on
///  the right entry. The counts come from the import of Delphi 13: 58 methods
///  in ICoreWebView2, then 7, 5, 4, 2 and 1 in _2 to _6, which puts PrintToPdf
///  on entry 80.</para>
///
///  <para>Two things the page cannot decide for itself. The paper is not the
///  <c>@page</c> rule of the stylesheet: with no print settings the runtime
///  prints Letter and ignores it, so the size, the margins and the background
///  colours travel in <see cref="THelpChatPdfPage" /> and are pushed into
///  <c>ICoreWebView2PrintSettings</c>. And an environment is not free: two of
///  them over the same user data folder with different options are refused by
///  the runtime, and two over different folders are two browser processes - so
///  the exporter takes the environment of the panel when the caller has one
///  (<c>TEdgeBrowser.EnvironmentInterface</c>) and only builds its own when
///  nobody offers it.</para>
///
///  <para>Pure RTL and Windows only: outside Windows the unit compiles and
///  <c>IsAvailable</c> answers False, so nothing in the engine has to ask what
///  platform it is on.</para>
/// </summary>
unit HelpChatAI.Pdf;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes;

const
  /// <summary>How long an export may take before it is given up on. A page of
  /// text takes well under a second; the ceiling is here for the case where
  /// the runtime never answers at all.</summary>
  HELPCHAT_PDF_DEF_TIMEOUTMS = 30000;

  /// <summary>Above this, the document is written to a temporary file instead
  /// of being handed to the runtime as a string: NavigateToString has a limit
  /// of about 2 MB, and a document with images inlined can reach it.</summary>
  HELPCHAT_PDF_INLINE_MAXCHARS = 1000000;

  /// <summary>The action the assistant calls to hand over a document it has
  /// written. Registered by the components when
  /// <c>Settings.Pdf.Action</c> says so.</summary>
  HELPCHAT_PDF_ACTION = 'export_pdf';

  /// <summary>A4 and Letter, in millimetres, and the margins of a document
  /// rather than of a web page.</summary>
  HELPCHAT_PDF_A4_WIDTHMM = 210.0;
  HELPCHAT_PDF_A4_HEIGHTMM = 297.0;
  HELPCHAT_PDF_LETTER_WIDTHMM = 215.9;
  HELPCHAT_PDF_LETTER_HEIGHTMM = 279.4;
  /// <summary>Margin of the text on all four sides, in millimetres. A band
  /// is added to it, never taken from it.</summary>
  HELPCHAT_PDF_DEF_MARGINMM = 10;

/// <summary>A file name out of the title of a document: what a save dialog
/// offers before the user changes it. Everything Windows refuses in a name is
/// dropped, and the result never grows past 60 characters.</summary>
function HelpChatPdfFileName(const ATitle: string): string;

/// <summary>Opens a document that has just been written, with whatever the
/// system opens it with. Only ever called on a file the user named in a save
/// dialog a moment earlier - this is not the place to open a URL a model
/// wrote. Does nothing outside Windows.</summary>
procedure HelpChatOpenDocument(const AFileName: string);

type
  /// <summary>Which way round the paper is.</summary>
  THelpChatPdfOrientation = (hcpoPortrait, hcpoLandscape);

  /// <summary>The two sheets worth naming. Anything else is a width and a
  /// height in <see cref="THelpChatPdfPage" />.</summary>
  THelpChatPdfPaper = (hcppA4, hcppLetter);

  /// <summary>The paper: what the stylesheet is not allowed to decide.</summary>
  THelpChatPdfPage = record
    /// <summary>Paper width in millimetres (of the portrait sheet).</summary>
    WidthMm: Double;
    /// <summary>Paper height in millimetres (of the portrait sheet).</summary>
    HeightMm: Double;
    /// <summary>Top margin in millimetres.</summary>
    MarginTopMm: Double;
    /// <summary>Bottom margin in millimetres.</summary>
    MarginBottomMm: Double;
    /// <summary>Left margin in millimetres.</summary>
    MarginLeftMm: Double;
    /// <summary>Right margin in millimetres.</summary>
    MarginRightMm: Double;
    /// <summary>Portrait or landscape.</summary>
    Orientation: THelpChatPdfOrientation;
    /// <summary>Print the background colours of the stylesheet. Off, a table
    /// with a shaded header row comes out white.</summary>
    PrintBackgrounds: Boolean;
    /// <summary>The band printed at the top of every sheet, as a little HTML
    /// document of its own, placeholders already replaced. Empty means no
    /// band. It is laid out inside the top margin, so the margin grows by
    /// <see cref="BandMm" /> when it is there: what is in
    /// <see cref="MarginTopMm" /> stays the margin of the text.</summary>
    HeaderHtml: string;
    /// <summary>The band printed at the foot of every sheet. See
    /// <see cref="HeaderHtml" />.</summary>
    FooterHtml: string;
    /// <summary>How much room a band gets, in millimetres. Whatever does not
    /// fit in it is cut off by the runtime.</summary>
    BandMm: Double;
    /// <summary>The title of the document: what the band builder put in
    /// <c>{title}</c>, kept here for whoever names the file.</summary>
    Title: string;
    /// <summary>True when there is a band to print, which is what decides
    /// whether the document goes through Page.printToPDF.</summary>
    function HasBands: Boolean;
    /// <summary>A4 upright, the default margin all round, backgrounds on,
    /// no bands.</summary>
    class function A4: THelpChatPdfPage; static;
    /// <summary>The same, on Letter paper.</summary>
    class function Letter: THelpChatPdfPage; static;
    /// <summary>The page named by <paramref name="AName" /> (a4 or letter),
    /// A4 for anything else.</summary>
    class function FromName(const AName: string): THelpChatPdfPage; static;
    /// <summary>The page of one of the two named sheets.</summary>
    class function FromPaper(const APaper: THelpChatPdfPaper): THelpChatPdfPage; static;
    /// <summary>All four margins at once.</summary>
    procedure SetMargins(const AMm: Double);
  end;

  /// <summary>What a band can say. The library fills it with what it can
  /// find out by itself - the version information of the executable, the user
  /// Windows is logged on as, the clock - and the application corrects it,
  /// because the user of an application is rarely the user of the
  /// machine.</summary>
  THelpChatPdfInfo = record
    /// <summary>Name of the application. <c>{app}</c>.</summary>
    AppName: string;
    /// <summary>Its version. <c>{version}</c>.</summary>
    AppVersion: string;
    /// <summary>Who is printing. <c>{user}</c>.</summary>
    UserName: string;
    /// <summary>Title of the document. <c>{title}</c>.</summary>
    Title: string;
    /// <summary>The day the document was made, already written out in the
    /// format of the machine. <c>{date}</c>.</summary>
    DateText: string;
    /// <summary>The time of day, likewise. <c>{time}</c>.</summary>
    TimeText: string;
    /// <summary>Anything else the application wants in its band - a customer,
    /// a department, "confidential". <c>{extra}</c>.</summary>
    Extra: string;
  end;

  /// <summary>Lets the application correct what the bands of a document say
  /// before it is printed. It is declared here, with the record, so that the
  /// two frameworks cannot name the same thing differently.</summary>
  THelpChatPdfInfoEvent = procedure(Sender: TObject;
    var AInfo: THelpChatPdfInfo) of object;

  /// <summary>Turns a self-contained HTML document into a PDF file, with the
  /// WebView2 runtime, on a window that is never shown. One export at a
  /// time per exporter, on the thread that created it - the main thread of
  /// the application, in practice. An exporter keeps its window and its
  /// environment between exports and builds a new browser for each. Several
  /// exporters may live in one process (one per component): they share the
  /// loader and the window class, nothing else. It knows nothing about the
  /// engine or the conversation: it is given HTML and a paper.</summary>
  THelpChatPdfExporter = class
  private
    // An export is a chain of asynchronous steps of the runtime - the
    // environment, the controller, the navigation, the print - each started
    // by a method below and finished by a callback that moves FStage, while
    // Wait pumps the message queue the callbacks arrive through.
    FEnvironment: IInterface;
    FWindow: NativeUInt;
    FController: IInterface;
    FWebView: IInterface;
    FStage: Integer;
    FError: string;
    FFileName: string;
    FPage: THelpChatPdfPage;
    FBandsDropped: Boolean;
    FHandlers: TInterfaceList;
    /// <summary>The hidden host window, created at the first export and
    /// kept until the exporter is freed.</summary>
    function EnsureWindow: Boolean;
    /// <summary>The environment given to the constructor, else one of our
    /// own over the user data folder the VCL browser uses by default, else
    /// - when the runtime refuses that - one over a folder of ours, which
    /// costs a second browser process.</summary>
    function EnsureEnvironment(ATimeoutMs: Cardinal): Boolean;
    /// <summary>A new browser on the hidden window, waited for.</summary>
    function CreateController(ATimeoutMs: Cardinal): Boolean;
    /// <summary>The paper of <c>FPage</c> as print settings of the runtime,
    /// in inches; nil when the runtime is too old to make them, and the PDF
    /// then comes out on Letter with the default margins.</summary>
    function PrintSettings: IInterface;
    /// <summary>The same paper as the JSON parameters of
    /// <c>Page.printToPDF</c>, with the bands and the margins grown to make
    /// room for them. Numbers are written with a point whatever the locale
    /// of the machine.</summary>
    function CdpParameters: string;
    /// <summary>The ordinary road: <c>PrintToPdf</c>, which writes the file
    /// by itself and takes no band.</summary>
    procedure StartPrint;
    /// <summary>The road of the bands: <c>Page.printToPDF</c> through the
    /// DevTools protocol. False when the call could not even be made, and
    /// the caller falls back on <see cref="StartPrint" />.</summary>
    function StartCdpPrint: Boolean;
    /// <summary>The answer of the protocol: the PDF as base64, written to
    /// the file here; with anything else the document goes out the ordinary
    /// way, without bands.</summary>
    procedure CdpDone(const AErrorCode: Integer; const AJson: string);
    /// <summary>Closes the browser of the export that just ended and lets
    /// go of its callbacks. The environment and the window stay.</summary>
    procedure CloseController;
    procedure EnvironmentReady(const AErrorCode: Integer; const AEnvironment: IInterface);
    procedure ControllerReady(const AErrorCode: Integer; const AController: IInterface);
    /// <summary>The document is laid out: this is where the print starts,
    /// by one road or the other.</summary>
    procedure NavigationDone(const ASuccess: Boolean);
    procedure PrintDone(const AErrorCode: Integer; const ASuccess: Boolean);
    /// <summary>Pumps the message queue of the calling thread until the
    /// current step succeeds or fails, or the time is up. Every message of
    /// the thread is dispatched meanwhile, the application's own
    /// included.</summary>
    function Wait(ATimeoutMs: Cardinal): Boolean;
  public
    /// <summary>True when there is something to ask: the loader is next to
    /// the application and a WebView2 runtime is installed. Whether that
    /// runtime is new enough to know PrintToPdf is answered by the export
    /// itself, with a sentence.</summary>
    class function IsAvailable: Boolean;
    /// <summary>The version of the installed WebView2 runtime, empty when
    /// there is none.</summary>
    class function RuntimeVersion: string;
    /// <summary>Takes the environment of a WebView2 that already exists in the
    /// process - <c>TEdgeBrowser.EnvironmentInterface</c> - so that no second
    /// browser process is started. With nil it builds its own, at the first
    /// export. Nothing is created here: no window, no browser.</summary>
    constructor Create(const AEnvironment: IInterface = nil);
    /// <summary>Closes the browser and destroys the hidden window. Must run
    /// on the thread that exported, and not from inside an export.</summary>
    destructor Destroy; override;
    /// <summary>Writes <paramref name="AHtml" /> to <paramref name="AFileName" />
    /// as PDF. Synchronous: it pumps the message queue of the calling thread
    /// while it waits, because that is how the runtime answers - so it must be
    /// called from the thread that owns the window, never from a worker, and
    /// the application keeps receiving its own messages meanwhile: the
    /// caller must not let the exporter be freed, or a second export start
    /// on it, before this returns. The folder of the file is created.
    /// <paramref name="ATimeoutMs" /> is given to each step, not to the
    /// whole export. The error sentences are English and start in lower
    /// case: they are reasons, made to follow a localized sentence.
    /// Returns False and fills <paramref name="AError" /> with a sentence when
    /// anything goes wrong, and raises nothing.</summary>
    function ExportHtml(const AHtml, AFileName: string; const APage: THelpChatPdfPage;
      out AError: string; ATimeoutMs: Cardinal = HELPCHAT_PDF_DEF_TIMEOUTMS): Boolean;
    /// <summary>The environment in use, to hand to another exporter.</summary>
    property Environment: IInterface read FEnvironment;
    /// <summary>True when the document was asked for bands and came out
    /// without them: the runtime refused Page.printToPDF and the file was
    /// written the ordinary way. The document is there and is right - only
    /// the header and the footer are missing - so this is something to say,
    /// not an error.</summary>
    property BandsDropped: Boolean read FBandsDropped;
  end;

/// <summary>Replaces the placeholders of a band template with the values of
/// <paramref name="AInfo" />, escaped as HTML: the name of an application is
/// text, and a band is a document. <c>{page}</c> and <c>{pages}</c> become
/// the two spans the runtime fills, because only it knows the numbers.</summary>
function HelpChatPdfExpand(const ATemplate: string;
  const AInfo: THelpChatPdfInfo): string;

/// <summary>What the library can find out by itself: the name and the version
/// in the version information of the executable (its file name when it
/// carries none), the user Windows is logged on as, and the clock. An
/// application corrects any of it before the band is built.</summary>
function HelpChatPdfDefaultInfo: THelpChatPdfInfo;

const
  /// <summary>Printing a document is local and sends nothing anywhere, so it
  /// is on unless the application says otherwise.</summary>
  HELPCHAT_PDF_DEF_ENABLED = True;
  /// <summary>Letting the assistant produce a document by itself is another
  /// matter: it is one more tool in every request, and an answer that turns
  /// into a file without being asked. Off by default.</summary>
  HELPCHAT_PDF_DEF_ACTION = False;
  /// <summary>A header and a footer are what an archived document wants and
  /// a printed answer does not, so they are off until the application asks
  /// for them.</summary>
  HELPCHAT_PDF_DEF_HEADERFOOTER = False;
  /// <summary>How tall a band is, in millimetres: enough for one line of
  /// eight points with air around it.</summary>
  HELPCHAT_PDF_DEF_BANDMM = 12;
  /// <summary>A4 until the application says Letter.</summary>
  HELPCHAT_PDF_DEF_PAPER = hcppA4;
  HELPCHAT_PDF_DEF_ORIENTATION = hcpoPortrait;
  /// <summary>Background colours are printed: a table with a shaded header
  /// keeps it.</summary>
  HELPCHAT_PDF_DEF_BACKGROUNDS = True;

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  Winapi.ShellAPI,
  System.Types,
  System.JSON,
  System.NetEncoding,
  System.IOUtils;
{$ENDIF}

function HelpChatPdfFileName(const ATitle: string): string;
const
  FORBIDDEN = '<>:"/\|?*';
var
  LChar: Char;
begin
  Result := '';
  for LChar in ATitle.Trim do
    if (FORBIDDEN.IndexOf(LChar) < 0) and (LChar >= ' ') then
      Result := Result + LChar;
  Result := Result.Trim(['.', ' ']);
  if Result = '' then
    Result := 'document';
  if Result.Length > 60 then
    Result := Result.Substring(0, 60).TrimRight;
  Result := Result + '.pdf';
end;

procedure HelpChatOpenDocument(const AFileName: string);
begin
{$IFDEF MSWINDOWS}
  if TFile.Exists(AFileName) then
    ShellExecute(0, 'open', PChar(AFileName), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
/// <summary>One string of the version information of the executable, empty
/// when the executable carries none - a build of a demo often does not.</summary>
function ExeVersionString(const AName: string): string;
var
  LHandle, LSize: DWORD;
  LBuffer: TBytes;
  LValue: Pointer;
  LLen: UINT;
  LTranslation: PDWORD;
  LFile, LKey: string;
begin
  Result := '';
  LFile := ParamStr(0);
  LHandle := 0;
  LSize := GetFileVersionInfoSize(PChar(LFile), LHandle);
  if LSize = 0 then
    Exit;
  SetLength(LBuffer, LSize);
  if not GetFileVersionInfo(PChar(LFile), LHandle, LSize, Pointer(LBuffer)) then
    Exit;
  // The strings live under the language the file was built with, so the
  // language has to be asked for first.
  if not VerQueryValue(Pointer(LBuffer), '\VarFileInfo\Translation',
       Pointer(LTranslation), LLen) or (LLen < 4) then
    Exit;
  LKey := Format('\StringFileInfo\%.4x%.4x\%s',
    [LoWord(LTranslation^), HiWord(LTranslation^), AName]);
  if VerQueryValue(Pointer(LBuffer), PChar(LKey), LValue, LLen) and (LLen > 0) then
    Result := string(PChar(LValue)).Trim;
end;

function WindowsUserName: string;
var
  LSize: DWORD;
begin
  LSize := 256;
  SetLength(Result, LSize);
  if GetUserName(PChar(Result), LSize) and (LSize > 1) then
    SetLength(Result, LSize - 1)
  else
    Result := '';
end;
{$ENDIF}

function HelpChatPdfDefaultInfo: THelpChatPdfInfo;
begin
  Result := Default(THelpChatPdfInfo);
{$IFDEF MSWINDOWS}
  Result.AppName := ExeVersionString('ProductName');
  if Result.AppName = '' then
    Result.AppName := ExeVersionString('FileDescription');
  Result.AppVersion := ExeVersionString('FileVersion');
  Result.UserName := WindowsUserName;
{$ENDIF}
  if Result.AppName = '' then
    Result.AppName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  Result.DateText := DateToStr(Date);
  // The short format, so that a band says 15:54 and not 15:54:24: nobody
  // files a document by the second.
  Result.TimeText := FormatDateTime(FormatSettings.ShortTimeFormat, Time);
end;

function HelpChatPdfExpand(const ATemplate: string;
  const AInfo: THelpChatPdfInfo): string;

  function Esc(const AValue: string): string;
  begin
    Result := TNetEncoding.HTML.Encode(AValue);
  end;

begin
  Result := ATemplate;
  Result := Result.Replace('{app}', Esc(AInfo.AppName), [rfReplaceAll]);
  Result := Result.Replace('{version}', Esc(AInfo.AppVersion), [rfReplaceAll]);
  Result := Result.Replace('{user}', Esc(AInfo.UserName), [rfReplaceAll]);
  Result := Result.Replace('{title}', Esc(AInfo.Title), [rfReplaceAll]);
  Result := Result.Replace('{date}', Esc(AInfo.DateText), [rfReplaceAll]);
  Result := Result.Replace('{time}', Esc(AInfo.TimeText), [rfReplaceAll]);
  Result := Result.Replace('{extra}', Esc(AInfo.Extra), [rfReplaceAll]);
  // These two the runtime fills, and it recognises them by the class name.
  Result := Result.Replace('{page}', '<span class="pageNumber"></span>', [rfReplaceAll]);
  Result := Result.Replace('{pages}', '<span class="totalPages"></span>', [rfReplaceAll]);
end;

{ THelpChatPdfPage }

function THelpChatPdfPage.HasBands: Boolean;
begin
  Result := (HeaderHtml.Trim <> '') or (FooterHtml.Trim <> '');
end;

class function THelpChatPdfPage.A4: THelpChatPdfPage;
begin
  Result.WidthMm := HELPCHAT_PDF_A4_WIDTHMM;
  Result.HeightMm := HELPCHAT_PDF_A4_HEIGHTMM;
  Result.Orientation := hcpoPortrait;
  Result.PrintBackgrounds := True;
  Result.HeaderHtml := '';
  Result.FooterHtml := '';
  Result.BandMm := HELPCHAT_PDF_DEF_BANDMM;
  Result.Title := '';
  Result.SetMargins(HELPCHAT_PDF_DEF_MARGINMM);
end;

class function THelpChatPdfPage.Letter: THelpChatPdfPage;
begin
  Result := A4;
  Result.WidthMm := HELPCHAT_PDF_LETTER_WIDTHMM;
  Result.HeightMm := HELPCHAT_PDF_LETTER_HEIGHTMM;
end;

class function THelpChatPdfPage.FromPaper(const APaper: THelpChatPdfPaper): THelpChatPdfPage;
begin
  if APaper = hcppLetter then
    Result := Letter
  else
    Result := A4;
end;

class function THelpChatPdfPage.FromName(const AName: string): THelpChatPdfPage;
begin
  if SameText(AName.Trim, 'letter') then
    Result := Letter
  else
    Result := A4;
end;

procedure THelpChatPdfPage.SetMargins(const AMm: Double);
begin
  MarginTopMm := AMm;
  MarginBottomMm := AMm;
  MarginLeftMm := AMm;
  MarginRightMm := AMm;
end;

{$IFDEF MSWINDOWS}

const
  /// <summary>Stages of one export, so that the waiting loop knows what it is
  /// waiting for and the handlers know they are still wanted.</summary>
  STAGE_IDLE = 0;
  STAGE_ENVIRONMENT = 1;
  STAGE_CONTROLLER = 2;
  STAGE_PRINTING = 3;
  STAGE_DONE = 4;
  STAGE_FAILED = 5;

  /// <summary>The viewport the document is laid out in. The paper decides the
  /// result, but a stylesheet with a media query has to see something
  /// sensible.</summary>
  VIEWPORT_WIDTH = 1240;
  VIEWPORT_HEIGHT = 1754;

  WINDOW_CLASS = 'HelpChatAIPdfHost';
  LOADER_DLL = 'WebView2Loader.dll';
  MM_PER_INCH = 25.4;

  /// <summary>HRESULT_FROM_WIN32(ERROR_INVALID_STATE): what the runtime
  /// answers when the same user data folder is already in use in this process
  /// with different options.</summary>
  E_WEBVIEW_WRONG_STATE = HResult($8007139F);

type
  TEventToken = Int64;

  IHcNavigationCompletedArgs = interface(IUnknown)
    ['{30D68B7D-20D9-4752-A9CA-EC8448FBB5C1}']
    function Get_IsSuccess(out AIsSuccess: Integer): HResult; stdcall;
  end;

  IHcNavigationCompletedHandler = interface(IUnknown)
    ['{D33A35BF-1C49-4F98-93AB-006E0533FE1C}']
    function Invoke(const ASender: IUnknown; const AArgs: IHcNavigationCompletedArgs): HResult; stdcall;
  end;

  IHcPrintToPdfCompletedHandler = interface(IUnknown)
    ['{CCF1EF04-FD8E-4D5F-B2DE-0983E41B8C36}']
    function Invoke(AErrorCode: HResult; AIsSuccessful: Integer): HResult; stdcall;
  end;

  IHcCdpCompletedHandler = interface(IUnknown)
    ['{5C4889F0-5EF6-4C5A-952C-D8F1B92D0574}']
    function Invoke(AErrorCode: HResult; AReturnObjectAsJson: PWideChar): HResult; stdcall;
  end;

  IHcPrintSettings = interface(IUnknown)
    ['{377F3721-C74E-48CA-8DB1-DF68E51D60E2}']
    function Get_Orientation(out AValue: Integer): HResult; stdcall;
    function Set_Orientation(AValue: Integer): HResult; stdcall;
    function Get_ScaleFactor(out AValue: Double): HResult; stdcall;
    function Set_ScaleFactor(AValue: Double): HResult; stdcall;
    function Get_PageWidth(out AValue: Double): HResult; stdcall;
    function Set_PageWidth(AValue: Double): HResult; stdcall;
    function Get_PageHeight(out AValue: Double): HResult; stdcall;
    function Set_PageHeight(AValue: Double): HResult; stdcall;
    function Get_MarginTop(out AValue: Double): HResult; stdcall;
    function Set_MarginTop(AValue: Double): HResult; stdcall;
    function Get_MarginBottom(out AValue: Double): HResult; stdcall;
    function Set_MarginBottom(AValue: Double): HResult; stdcall;
    function Get_MarginLeft(out AValue: Double): HResult; stdcall;
    function Set_MarginLeft(AValue: Double): HResult; stdcall;
    function Get_MarginRight(out AValue: Double): HResult; stdcall;
    function Set_MarginRight(AValue: Double): HResult; stdcall;
    function Get_ShouldPrintBackgrounds(out AValue: Integer): HResult; stdcall;
    function Set_ShouldPrintBackgrounds(AValue: Integer): HResult; stdcall;
    function Get_ShouldPrintSelectionOnly(out AValue: Integer): HResult; stdcall;
    function Set_ShouldPrintSelectionOnly(AValue: Integer): HResult; stdcall;
    function Get_ShouldPrintHeaderAndFooter(out AValue: Integer): HResult; stdcall;
    function Set_ShouldPrintHeaderAndFooter(AValue: Integer): HResult; stdcall;
    function Get_HeaderTitle(out AValue: PWideChar): HResult; stdcall;
    function Set_HeaderTitle(AValue: PWideChar): HResult; stdcall;
    function Get_FooterUri(out AValue: PWideChar): HResult; stdcall;
    function Set_FooterUri(AValue: PWideChar): HResult; stdcall;
  end;

  /// <summary>ICoreWebView2: only what we call, with the earlier methods
  /// reserved so that Navigate lands on entry 2 and add_NavigationCompleted
  /// on entry 12.</summary>
  IHcWebView = interface(IUnknown)
    ['{76ECEACB-0462-4D94-AC83-423A6793775E}']
    procedure Reserved_00; stdcall;  // Get_Settings, Get_Source
    procedure Reserved_01; stdcall;
    function Navigate(AUri: PWideChar): HResult; stdcall;
    function NavigateToString(AHtmlContent: PWideChar): HResult; stdcall;
    procedure Reserved_04; stdcall;  // NavigateToString ends at 3, add_NavigationCompleted is 12
    procedure Reserved_05; stdcall;
    procedure Reserved_06; stdcall;
    procedure Reserved_07; stdcall;
    procedure Reserved_08; stdcall;
    procedure Reserved_09; stdcall;
    procedure Reserved_10; stdcall;
    procedure Reserved_11; stdcall;
    function add_NavigationCompleted(const AHandler: IHcNavigationCompletedHandler;
      out AToken: TEventToken): HResult; stdcall;
    procedure Reserved_13; stdcall;  // and CallDevToolsProtocolMethod on 33
    procedure Reserved_14; stdcall;
    procedure Reserved_15; stdcall;
    procedure Reserved_16; stdcall;
    procedure Reserved_17; stdcall;
    procedure Reserved_18; stdcall;
    procedure Reserved_19; stdcall;
    procedure Reserved_20; stdcall;
    procedure Reserved_21; stdcall;
    procedure Reserved_22; stdcall;
    procedure Reserved_23; stdcall;
    procedure Reserved_24; stdcall;
    procedure Reserved_25; stdcall;
    procedure Reserved_26; stdcall;
    procedure Reserved_27; stdcall;
    procedure Reserved_28; stdcall;
    procedure Reserved_29; stdcall;
    procedure Reserved_30; stdcall;
    procedure Reserved_31; stdcall;
    procedure Reserved_32; stdcall;
    /// <summary>The Chrome DevTools Protocol, which WebView2 exposes on its
    /// own interface: a method by name, parameters and answer as JSON. It is
    /// how a page is printed with a header and a footer of our own, because
    /// PrintToPdf takes neither.</summary>
    function CallDevToolsProtocolMethod(AMethodName: PWideChar;
      AParametersAsJson: PWideChar; const AHandler: IHcCdpCompletedHandler): HResult; stdcall;
  end;

  /// <summary>ICoreWebView2_7, the one that can print. 77 reserved slots:
  /// ICoreWebView2 (58) and _2 (7), _3 (5), _4 (4), _5 (2), _6 (1).</summary>
  IHcWebViewPdf = interface(IUnknown)
    ['{79C24D83-09A3-45AE-9418-487F32A58740}']
    procedure Reserved_00; stdcall;  // ICoreWebView2 and _2 to _6
    procedure Reserved_01; stdcall;
    procedure Reserved_02; stdcall;
    procedure Reserved_03; stdcall;
    procedure Reserved_04; stdcall;
    procedure Reserved_05; stdcall;
    procedure Reserved_06; stdcall;
    procedure Reserved_07; stdcall;
    procedure Reserved_08; stdcall;
    procedure Reserved_09; stdcall;
    procedure Reserved_10; stdcall;
    procedure Reserved_11; stdcall;
    procedure Reserved_12; stdcall;
    procedure Reserved_13; stdcall;
    procedure Reserved_14; stdcall;
    procedure Reserved_15; stdcall;
    procedure Reserved_16; stdcall;
    procedure Reserved_17; stdcall;
    procedure Reserved_18; stdcall;
    procedure Reserved_19; stdcall;
    procedure Reserved_20; stdcall;
    procedure Reserved_21; stdcall;
    procedure Reserved_22; stdcall;
    procedure Reserved_23; stdcall;
    procedure Reserved_24; stdcall;
    procedure Reserved_25; stdcall;
    procedure Reserved_26; stdcall;
    procedure Reserved_27; stdcall;
    procedure Reserved_28; stdcall;
    procedure Reserved_29; stdcall;
    procedure Reserved_30; stdcall;
    procedure Reserved_31; stdcall;
    procedure Reserved_32; stdcall;
    procedure Reserved_33; stdcall;
    procedure Reserved_34; stdcall;
    procedure Reserved_35; stdcall;
    procedure Reserved_36; stdcall;
    procedure Reserved_37; stdcall;
    procedure Reserved_38; stdcall;
    procedure Reserved_39; stdcall;
    procedure Reserved_40; stdcall;
    procedure Reserved_41; stdcall;
    procedure Reserved_42; stdcall;
    procedure Reserved_43; stdcall;
    procedure Reserved_44; stdcall;
    procedure Reserved_45; stdcall;
    procedure Reserved_46; stdcall;
    procedure Reserved_47; stdcall;
    procedure Reserved_48; stdcall;
    procedure Reserved_49; stdcall;
    procedure Reserved_50; stdcall;
    procedure Reserved_51; stdcall;
    procedure Reserved_52; stdcall;
    procedure Reserved_53; stdcall;
    procedure Reserved_54; stdcall;
    procedure Reserved_55; stdcall;
    procedure Reserved_56; stdcall;
    procedure Reserved_57; stdcall;
    procedure Reserved_58; stdcall;
    procedure Reserved_59; stdcall;
    procedure Reserved_60; stdcall;
    procedure Reserved_61; stdcall;
    procedure Reserved_62; stdcall;
    procedure Reserved_63; stdcall;
    procedure Reserved_64; stdcall;
    procedure Reserved_65; stdcall;
    procedure Reserved_66; stdcall;
    procedure Reserved_67; stdcall;
    procedure Reserved_68; stdcall;
    procedure Reserved_69; stdcall;
    procedure Reserved_70; stdcall;
    procedure Reserved_71; stdcall;
    procedure Reserved_72; stdcall;
    procedure Reserved_73; stdcall;
    procedure Reserved_74; stdcall;
    procedure Reserved_75; stdcall;
    procedure Reserved_76; stdcall;
    function PrintToPdf(AResultFilePath: PWideChar; const APrintSettings: IHcPrintSettings;
      const AHandler: IHcPrintToPdfCompletedHandler): HResult; stdcall;
  end;

  /// <summary>ICoreWebView2Controller.</summary>
  IHcController = interface(IUnknown)
    ['{4D00C0D1-9434-4EB6-8078-8697A560334F}']
    procedure Reserved_00; stdcall;  // Get_IsVisible
    function Set_IsVisible(AIsVisible: Integer): HResult; stdcall;
    procedure Reserved_02; stdcall;  // Get_Bounds
    function Set_Bounds(ABounds: TRect): HResult; stdcall;
    procedure Reserved_04; stdcall;  // zoom, focus, accelerators, parent window
    procedure Reserved_05; stdcall;
    procedure Reserved_06; stdcall;
    procedure Reserved_07; stdcall;
    procedure Reserved_08; stdcall;
    procedure Reserved_09; stdcall;
    procedure Reserved_10; stdcall;
    procedure Reserved_11; stdcall;
    procedure Reserved_12; stdcall;
    procedure Reserved_13; stdcall;
    procedure Reserved_14; stdcall;
    procedure Reserved_15; stdcall;
    procedure Reserved_16; stdcall;
    procedure Reserved_17; stdcall;
    procedure Reserved_18; stdcall;
    procedure Reserved_19; stdcall;
    procedure Reserved_20; stdcall;
    function Close: HResult; stdcall;
    function Get_CoreWebView2(out AWebView: IHcWebView): HResult; stdcall;
  end;

  IHcControllerCompletedHandler = interface(IUnknown)
    ['{6C4819F3-C9B7-4260-8127-C9F5BDE7F68C}']
    function Invoke(AErrorCode: HResult; const AController: IHcController): HResult; stdcall;
  end;

  /// <summary>ICoreWebView2Environment.</summary>
  IHcEnvironment = interface(IUnknown)
    ['{B96D755E-0319-4E92-A296-23436F46A1FC}']
    function CreateCoreWebView2Controller(AParentWindow: HWND;
      const AHandler: IHcControllerCompletedHandler): HResult; stdcall;
    procedure Reserved_01; stdcall;  // CreateWebResourceResponse
    function Get_BrowserVersionString(out AVersion: PWideChar): HResult; stdcall;
  end;

  /// <summary>ICoreWebView2Environment6, the one that makes print settings.
  /// 11 reserved slots: Environment (5) and _2 (1), _3 (2), _4 (1), _5 (2).</summary>
  IHcEnvironment6 = interface(IUnknown)
    ['{E59EE362-ACBD-4857-9A8E-D3644D9459A9}']
    procedure Reserved_00; stdcall;  // Environment and _2 to _5
    procedure Reserved_01; stdcall;
    procedure Reserved_02; stdcall;
    procedure Reserved_03; stdcall;
    procedure Reserved_04; stdcall;
    procedure Reserved_05; stdcall;
    procedure Reserved_06; stdcall;
    procedure Reserved_07; stdcall;
    procedure Reserved_08; stdcall;
    procedure Reserved_09; stdcall;
    procedure Reserved_10; stdcall;
    function CreatePrintSettings(out ASettings: IHcPrintSettings): HResult; stdcall;
  end;

  IHcEnvironmentCompletedHandler = interface(IUnknown)
    ['{4E8A3389-C9D8-4BD2-B6B5-124FEE6CC14D}']
    function Invoke(AErrorCode: HResult; const AEnvironment: IHcEnvironment): HResult; stdcall;
  end;

  TCreateEnvironmentProc = function(ABrowserExecutableFolder, AUserDataFolder: PWideChar;
    const AOptions: IUnknown; const AHandler: IHcEnvironmentCompletedHandler): HResult; stdcall;
  TGetVersionProc = function(ABrowserExecutableFolder: PWideChar;
    var AVersion: PWideChar): HResult; stdcall;

  /// <summary>The three callbacks the runtime wants. Each one holds the
  /// exporter as a plain pointer: the exporter owns them for the length of one
  /// export and outlives them.</summary>
  THcEnvironmentHandler = class(TInterfacedObject, IHcEnvironmentCompletedHandler)
  private
    FOwner: THelpChatPdfExporter;
  public
    constructor Create(AOwner: THelpChatPdfExporter);
    function Invoke(AErrorCode: HResult; const AEnvironment: IHcEnvironment): HResult; stdcall;
  end;

  THcControllerHandler = class(TInterfacedObject, IHcControllerCompletedHandler)
  private
    FOwner: THelpChatPdfExporter;
  public
    constructor Create(AOwner: THelpChatPdfExporter);
    function Invoke(AErrorCode: HResult; const AController: IHcController): HResult; stdcall;
  end;

  THcNavigationHandler = class(TInterfacedObject, IHcNavigationCompletedHandler)
  private
    FOwner: THelpChatPdfExporter;
  public
    constructor Create(AOwner: THelpChatPdfExporter);
    function Invoke(const ASender: IUnknown; const AArgs: IHcNavigationCompletedArgs): HResult; stdcall;
  end;

  THcPrintHandler = class(TInterfacedObject, IHcPrintToPdfCompletedHandler)
  private
    FOwner: THelpChatPdfExporter;
  public
    constructor Create(AOwner: THelpChatPdfExporter);
    function Invoke(AErrorCode: HResult; AIsSuccessful: Integer): HResult; stdcall;
  end;

  THcCdpHandler = class(TInterfacedObject, IHcCdpCompletedHandler)
  private
    FOwner: THelpChatPdfExporter;
  public
    constructor Create(AOwner: THelpChatPdfExporter);
    function Invoke(AErrorCode: HResult; AReturnObjectAsJson: PWideChar): HResult; stdcall;
  end;

var
  GLoader: HMODULE = 0;
  GCreateEnvironment: TCreateEnvironmentProc = nil;
  GGetVersion: TGetVersionProc = nil;
  GClassRegistered: Boolean = False;

/// <summary>%LOCALAPPDATA% and friends, the way the VCL browser expands
/// them.</summary>
function ExpandEnvVars(const AValue: string): string;
var
  LSize: Integer;
begin
  LSize := ExpandEnvironmentStrings(PChar(AValue), nil, 0);
  if LSize <= 1 then
    Exit(AValue);
  SetLength(Result, LSize - 1);
  ExpandEnvironmentStrings(PChar(AValue), PChar(Result), LSize);
end;

function PdfWndProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall;
begin
  Result := DefWindowProc(AWnd, AMsg, AWParam, ALParam);
end;

/// <summary>Loads WebView2Loader.dll: the one already in the process if the
/// panel brought it in, otherwise the one next to the executable, otherwise
/// whatever the search path finds.</summary>
function LoadLoader: Boolean;
var
  LPath: string;
begin
  if GLoader = 0 then
  begin
    GLoader := GetModuleHandle(LOADER_DLL);
    if GLoader = 0 then
    begin
      LPath := TPath.Combine(ExtractFilePath(ParamStr(0)), LOADER_DLL);
      if TFile.Exists(LPath) then
        GLoader := LoadLibrary(PChar(LPath));
    end;
    if GLoader = 0 then
      GLoader := LoadLibrary(LOADER_DLL);
    if GLoader <> 0 then
    begin
      @GCreateEnvironment := GetProcAddress(GLoader, 'CreateCoreWebView2EnvironmentWithOptions');
      @GGetVersion := GetProcAddress(GLoader, 'GetAvailableCoreWebView2BrowserVersionString');
    end;
  end;
  Result := Assigned(GCreateEnvironment);
end;

{ the handlers }

constructor THcEnvironmentHandler.Create(AOwner: THelpChatPdfExporter);
begin
  inherited Create;
  FOwner := AOwner;
end;

function THcEnvironmentHandler.Invoke(AErrorCode: HResult;
  const AEnvironment: IHcEnvironment): HResult; stdcall;
begin
  Result := S_OK;
  try
    FOwner.EnvironmentReady(AErrorCode, AEnvironment);
  except
    // Nothing may be raised back into the runtime
  end;
end;

constructor THcControllerHandler.Create(AOwner: THelpChatPdfExporter);
begin
  inherited Create;
  FOwner := AOwner;
end;

function THcControllerHandler.Invoke(AErrorCode: HResult;
  const AController: IHcController): HResult; stdcall;
begin
  Result := S_OK;
  try
    FOwner.ControllerReady(AErrorCode, AController);
  except
  end;
end;

constructor THcNavigationHandler.Create(AOwner: THelpChatPdfExporter);
begin
  inherited Create;
  FOwner := AOwner;
end;

function THcNavigationHandler.Invoke(const ASender: IUnknown;
  const AArgs: IHcNavigationCompletedArgs): HResult; stdcall;
var
  LSuccess: Integer;
begin
  Result := S_OK;
  try
    LSuccess := 0;
    if AArgs <> nil then
      AArgs.Get_IsSuccess(LSuccess);
    FOwner.NavigationDone(LSuccess <> 0);
  except
  end;
end;

constructor THcPrintHandler.Create(AOwner: THelpChatPdfExporter);
begin
  inherited Create;
  FOwner := AOwner;
end;

function THcPrintHandler.Invoke(AErrorCode: HResult; AIsSuccessful: Integer): HResult; stdcall;
begin
  Result := S_OK;
  try
    FOwner.PrintDone(AErrorCode, AIsSuccessful <> 0);
  except
  end;
end;

constructor THcCdpHandler.Create(AOwner: THelpChatPdfExporter);
begin
  inherited Create;
  FOwner := AOwner;
end;

function THcCdpHandler.Invoke(AErrorCode: HResult;
  AReturnObjectAsJson: PWideChar): HResult; stdcall;
begin
  Result := S_OK;
  try
    FOwner.CdpDone(AErrorCode, string(AReturnObjectAsJson));
  except
  end;
end;

{$ENDIF MSWINDOWS}

{ THelpChatPdfExporter }

constructor THelpChatPdfExporter.Create(const AEnvironment: IInterface);
begin
  inherited Create;
  FEnvironment := AEnvironment;
{$IFDEF MSWINDOWS}
  FHandlers := TInterfaceList.Create;
{$ENDIF}
end;

destructor THelpChatPdfExporter.Destroy;
begin
{$IFDEF MSWINDOWS}
  CloseController;
  FEnvironment := nil;
  FHandlers.Free;
  if FWindow <> 0 then
    DestroyWindow(FWindow);
{$ENDIF}
  inherited;
end;

class function THelpChatPdfExporter.RuntimeVersion: string;
{$IFDEF MSWINDOWS}
var
  LVersion: PWideChar;
{$ENDIF}
begin
  Result := '';
{$IFDEF MSWINDOWS}
  if not LoadLoader or not Assigned(GGetVersion) then
    Exit;
  LVersion := nil;
  if (GGetVersion(nil, LVersion) = S_OK) and (LVersion <> nil) then
  begin
    Result := string(LVersion);
    CoTaskMemFree(LVersion);
  end;
{$ENDIF}
end;

class function THelpChatPdfExporter.IsAvailable: Boolean;
begin
{$IFDEF MSWINDOWS}
  Result := RuntimeVersion <> '';
{$ELSE}
  Result := False;
{$ENDIF}
end;

{$IFDEF MSWINDOWS}

function THelpChatPdfExporter.EnsureWindow: Boolean;
var
  LClass: TWndClass;
begin
  if FWindow = 0 then
  begin
    if not GClassRegistered then
    begin
      FillChar(LClass, SizeOf(LClass), 0);
      LClass.lpfnWndProc := @PdfWndProc;
      LClass.hInstance := HInstance;
      LClass.lpszClassName := WINDOW_CLASS;
      GClassRegistered := Winapi.Windows.RegisterClass(LClass) <> 0;
      if not GClassRegistered then
        GClassRegistered := GetLastError = ERROR_CLASS_ALREADY_EXISTS;
    end;
    // Off screen and never shown: the WebView2 wants a window, the user does
    // not want to see one.
    FWindow := CreateWindowEx(WS_EX_TOOLWINDOW, WINDOW_CLASS, 'HelpChatAI PDF',
      WS_POPUP, -32000, -32000, VIEWPORT_WIDTH, VIEWPORT_HEIGHT, 0, 0, HInstance, nil);
  end;
  Result := FWindow <> 0;
end;

function THelpChatPdfExporter.Wait(ATimeoutMs: Cardinal): Boolean;
var
  LStarted: UInt64;
  LMsg: TMsg;
begin
  LStarted := GetTickCount64;
  while (FStage <> STAGE_DONE) and (FStage <> STAGE_FAILED) and
        (GetTickCount64 - LStarted < ATimeoutMs) do
  begin
    // The runtime answers through the message queue of this thread, so there
    // is nothing to wait on but the queue itself. No filter: the callbacks
    // come as messages of windows of the runtime, which cannot be told from
    // here, so everything the thread receives is dispatched - input
    // included. Not WM_QUIT: dispatching it does nothing, and the message
    // loop of the application would never see that it was asked to end. It
    // is posted again for that loop, and the export gives up.
    if PeekMessage(LMsg, 0, 0, 0, PM_REMOVE) then
    begin
      if LMsg.message = WM_QUIT then
      begin
        PostQuitMessage(Integer(LMsg.wParam));
        if FError = '' then
          FError := 'the application is closing';
        Break;
      end;
      TranslateMessage(LMsg);
      DispatchMessage(LMsg);
    end
    else
      Sleep(1);
  end;
  Result := FStage = STAGE_DONE;
  if not Result and (FError = '') then
    FError := 'the WebView2 runtime did not answer in time';
end;

procedure THelpChatPdfExporter.EnvironmentReady(const AErrorCode: Integer;
  const AEnvironment: IInterface);
begin
  if (AErrorCode <> S_OK) or (AEnvironment = nil) then
  begin
    FError := Format('the WebView2 environment could not be created (0x%.8x)', [AErrorCode]);
    FStage := STAGE_FAILED;
  end
  else
  begin
    FEnvironment := AEnvironment;
    FStage := STAGE_DONE;
  end;
end;

function THelpChatPdfExporter.EnsureEnvironment(ATimeoutMs: Cardinal): Boolean;
var
  LHandler: IHcEnvironmentCompletedHandler;
  LFolder: string;
  LHr: HResult;

  function TryCreate(const AUserDataFolder: string): HResult;
  begin
    FStage := STAGE_ENVIRONMENT;
    FError := '';
    LHandler := THcEnvironmentHandler.Create(Self);
    FHandlers.Add(LHandler);
    Result := GCreateEnvironment(nil, PChar(AUserDataFolder), nil, LHandler);
  end;

begin
  Result := FEnvironment <> nil;
  if Result then
    Exit;
  if not LoadLoader then
  begin
    FError := 'WebView2Loader.dll was not found next to the application';
    Exit(False);
  end;
  // The user data folder of an export that has no environment to borrow
  // (the FireMonkey panel uses this one too; the VCL panel has its own,
  // and lends its environment instead).
  LFolder := ExpandEnvVars(TPath.Combine('%LOCALAPPDATA%',
    TPath.GetFileName(ParamStr(0)) + '.WebView2'));
  LHr := TryCreate(LFolder);
  if (LHr = S_OK) and Wait(ATimeoutMs) then
    Exit(True);
  // A second environment over the same folder with other options is refused:
  // then, and only then, a folder of our own and a second browser process.
  if (LHr = E_WEBVIEW_WRONG_STATE) or (FStage = STAGE_FAILED) then
  begin
    LHr := TryCreate(LFolder + '.pdf');
    if (LHr = S_OK) and Wait(ATimeoutMs) then
      Exit(True);
  end;
  if FError = '' then
    FError := Format('the WebView2 environment could not be created (0x%.8x)', [LHr]);
  Result := False;
end;

procedure THelpChatPdfExporter.ControllerReady(const AErrorCode: Integer;
  const AController: IInterface);
var
  LController: IHcController;
  LWebView: IHcWebView;
  LBounds: TRect;
begin
  if (AErrorCode <> S_OK) or (AController = nil) or
     not Supports(AController, IHcController, LController) then
  begin
    FError := Format('the WebView2 could not be created (0x%.8x)', [AErrorCode]);
    FStage := STAGE_FAILED;
    Exit;
  end;
  FController := LController;
  LBounds := TRect.Create(0, 0, VIEWPORT_WIDTH, VIEWPORT_HEIGHT);
  LController.Set_Bounds(LBounds);
  LController.Set_IsVisible(0);
  if LController.Get_CoreWebView2(LWebView) <> S_OK then
  begin
    FError := 'the WebView2 did not hand out its page';
    FStage := STAGE_FAILED;
    Exit;
  end;
  FWebView := LWebView;
  FStage := STAGE_DONE;
end;

function THelpChatPdfExporter.CreateController(ATimeoutMs: Cardinal): Boolean;
var
  LEnvironment: IHcEnvironment;
  LHandler: IHcControllerCompletedHandler;
begin
  if not Supports(FEnvironment, IHcEnvironment, LEnvironment) then
  begin
    FError := 'the WebView2 environment is not one this version can use';
    Exit(False);
  end;
  FStage := STAGE_CONTROLLER;
  LHandler := THcControllerHandler.Create(Self);
  FHandlers.Add(LHandler);
  if LEnvironment.CreateCoreWebView2Controller(FWindow, LHandler) <> S_OK then
  begin
    FError := 'the WebView2 could not be created';
    Exit(False);
  end;
  Result := Wait(ATimeoutMs);
end;

procedure THelpChatPdfExporter.CloseController;
var
  LController: IHcController;
begin
  FWebView := nil;
  if Supports(FController, IHcController, LController) then
    LController.Close;
  FController := nil;
  FHandlers.Clear;
end;

function THelpChatPdfExporter.PrintSettings: IInterface;
var
  LEnvironment6: IHcEnvironment6;
  LSettings: IHcPrintSettings;
  LWidth, LHeight: Double;
begin
  Result := nil;
  if not Supports(FEnvironment, IHcEnvironment6, LEnvironment6) then
    Exit;  // older runtime: Letter and the default margins, but still a PDF
  if LEnvironment6.CreatePrintSettings(LSettings) <> S_OK then
    Exit;
  LWidth := FPage.WidthMm / MM_PER_INCH;
  LHeight := FPage.HeightMm / MM_PER_INCH;
  LSettings.Set_PageWidth(LWidth);
  LSettings.Set_PageHeight(LHeight);
  LSettings.Set_Orientation(Ord(FPage.Orientation));
  LSettings.Set_MarginTop(FPage.MarginTopMm / MM_PER_INCH);
  LSettings.Set_MarginBottom(FPage.MarginBottomMm / MM_PER_INCH);
  LSettings.Set_MarginLeft(FPage.MarginLeftMm / MM_PER_INCH);
  LSettings.Set_MarginRight(FPage.MarginRightMm / MM_PER_INCH);
  LSettings.Set_ShouldPrintBackgrounds(Ord(FPage.PrintBackgrounds));
  // Never the browser's own header and footer: they carry the title, the date
  // and the URL in the style of Edge, which is not a document of ours. Ours
  // are HTML, and they travel the other road - see CdpParameters.
  LSettings.Set_ShouldPrintHeaderAndFooter(0);
  Result := LSettings;
end;

procedure THelpChatPdfExporter.NavigationDone(const ASuccess: Boolean);
begin
  if FStage <> STAGE_PRINTING then
    Exit;
  if not ASuccess then
  begin
    FError := 'the document could not be loaded';
    FStage := STAGE_FAILED;
    Exit;
  end;
  // With a band to print there is only one road, because PrintToPdf takes no
  // template; without one, the ordinary road, which is the one every PDF took
  // before bands existed.
  if FPage.HasBands and StartCdpPrint then
    Exit;
  if FPage.HasBands then
    FBandsDropped := True;
  StartPrint;
end;

procedure THelpChatPdfExporter.StartPrint;
var
  LPdf: IHcWebViewPdf;
  LSettings: IHcPrintSettings;
  LHandler: IHcPrintToPdfCompletedHandler;
  LHr: HResult;
begin
  if not Supports(FWebView, IHcWebViewPdf, LPdf) then
  begin
    FError := 'this WebView2 runtime is too old to write a PDF';
    FStage := STAGE_FAILED;
    Exit;
  end;
  Supports(PrintSettings, IHcPrintSettings, LSettings);
  LHandler := THcPrintHandler.Create(Self);
  FHandlers.Add(LHandler);
  LHr := LPdf.PrintToPdf(PChar(FFileName), LSettings, LHandler);
  if LHr <> S_OK then
  begin
    FError := Format('the PDF could not be started (0x%.8x)', [LHr]);
    FStage := STAGE_FAILED;
  end;
end;

function THelpChatPdfExporter.CdpParameters: string;
var
  LFmt: TFormatSettings;
  LTop, LBottom: Double;

  function Inches(const AMm: Double): string;
  begin
    Result := Format('%.4f', [AMm / MM_PER_INCH], LFmt);
  end;

  function Band(const AHtml: string): string;
  begin
    // An empty template is not "no band": with displayHeaderFooter on and an
    // empty string Chromium falls back to its own, which is a browser
    // printout. An empty span is a band that says nothing.
    if AHtml.Trim = '' then
      Result := '<span></span>'
    else
      Result := AHtml;
  end;

  function Quoted(const AHtml: string): string;
  var
    LValue: TJSONString;
  begin
    LValue := TJSONString.Create(AHtml);
    try
      Result := LValue.ToJSON;
    finally
      LValue.Free;
    end;
  end;

begin
  // A band lives inside the margin, so the margin has to make room for it:
  // MarginTopMm stays what the text is given.
  LFmt := TFormatSettings.Invariant;
  LTop := FPage.MarginTopMm;
  if FPage.HeaderHtml.Trim <> '' then
    LTop := LTop + FPage.BandMm;
  LBottom := FPage.MarginBottomMm;
  if FPage.FooterHtml.Trim <> '' then
    LBottom := LBottom + FPage.BandMm;
  Result := Format('{"landscape":%s,"displayHeaderFooter":true,' +
    '"printBackground":%s,"paperWidth":%s,"paperHeight":%s,' +
    '"marginTop":%s,"marginBottom":%s,"marginLeft":%s,"marginRight":%s,' +
    '"headerTemplate":%s,"footerTemplate":%s,' +
    '"preferCSSPageSize":false,"transferMode":"ReturnAsBase64"}',
    [LowerCase(BoolToStr(FPage.Orientation = hcpoLandscape, True)),
     LowerCase(BoolToStr(FPage.PrintBackgrounds, True)),
     Inches(FPage.WidthMm), Inches(FPage.HeightMm),
     Inches(LTop), Inches(LBottom),
     Inches(FPage.MarginLeftMm), Inches(FPage.MarginRightMm),
     Quoted(Band(FPage.HeaderHtml)), Quoted(Band(FPage.FooterHtml))]);
end;

function THelpChatPdfExporter.StartCdpPrint: Boolean;
var
  LWebView: IHcWebView;
  LHandler: IHcCdpCompletedHandler;
begin
  Result := False;
  if not Supports(FWebView, IHcWebView, LWebView) then
    Exit;
  LHandler := THcCdpHandler.Create(Self);
  FHandlers.Add(LHandler);
  Result := LWebView.CallDevToolsProtocolMethod('Page.printToPDF',
    PChar(CdpParameters), LHandler) = S_OK;
end;

procedure THelpChatPdfExporter.CdpDone(const AErrorCode: Integer; const AJson: string);
var
  LValue: TJSONValue;
  LData: string;
begin
  if FStage <> STAGE_PRINTING then
    Exit;
  LData := '';
  if AErrorCode = S_OK then
  begin
    LValue := TJSONObject.ParseJSONValue(AJson);
    try
      if LValue is TJSONObject then
        TJSONObject(LValue).TryGetValue<string>('data', LData);
    finally
      LValue.Free;
    end;
  end;
  if LData = '' then
  begin
    // The protocol said no. The document is still worth having, so it goes
    // out the ordinary way - and the caller is told what it lost.
    FBandsDropped := True;
    StartPrint;
    Exit;
  end;
  try
    TFile.WriteAllBytes(FFileName, TNetEncoding.Base64.DecodeStringToBytes(LData));
    FStage := STAGE_DONE;
  except
    on E: Exception do
    begin
      FError := E.Message;
      FStage := STAGE_FAILED;
    end;
  end;
end;

procedure THelpChatPdfExporter.PrintDone(const AErrorCode: Integer; const ASuccess: Boolean);
begin
  // The last step: whichever way it ends, the waiting loop of ExportHtml
  // stops here.
  if (AErrorCode <> S_OK) or not ASuccess then
  begin
    if FError = '' then
      FError := Format('the PDF was not written (0x%.8x)', [AErrorCode]);
    FStage := STAGE_FAILED;
  end
  else
    FStage := STAGE_DONE;
end;

function THelpChatPdfExporter.ExportHtml(const AHtml, AFileName: string;
  const APage: THelpChatPdfPage; out AError: string; ATimeoutMs: Cardinal): Boolean;
var
  LWebView: IHcWebView;
  LHandler: IHcNavigationCompletedHandler;
  LToken: TEventToken;
  LTempFile: string;
begin
  AError := '';
  FError := '';
  FBandsDropped := False;
  FPage := APage;
  FFileName := AFileName;
  LTempFile := '';
  if AHtml.Trim.IsEmpty then
  begin
    AError := 'there is nothing to print';
    Exit(False);
  end;
  if AFileName.Trim.IsEmpty then
  begin
    AError := 'no file name was given';
    Exit(False);
  end;
  try
    ForceDirectories(ExtractFilePath(AFileName));
    if not EnsureWindow then
    begin
      AError := 'the window the WebView2 needs could not be created';
      Exit(False);
    end;
    if not EnsureEnvironment(ATimeoutMs) then
    begin
      AError := FError;
      Exit(False);
    end;
    if not CreateController(ATimeoutMs) then
    begin
      AError := FError;
      Exit(False);
    end;
    if not Supports(FWebView, IHcWebView, LWebView) then
    begin
      AError := 'the WebView2 did not hand out its page';
      Exit(False);
    end;
    // From here on the stage stays "printing" until the file is written:
    // the print is started by the navigation callback, not by this method.
    FStage := STAGE_PRINTING;
    LHandler := THcNavigationHandler.Create(Self);
    FHandlers.Add(LHandler);
    LWebView.add_NavigationCompleted(LHandler, LToken);
    // Short documents never touch the disk; a long one has to, because
    // NavigateToString stops at about two megabytes.
    if Length(AHtml) <= HELPCHAT_PDF_INLINE_MAXCHARS then
      LWebView.NavigateToString(PChar(AHtml))
    else
    begin
      LTempFile := TPath.Combine(TPath.GetTempPath,
        'helpchatai-' + TGuid.NewGuid.ToString.Trim(['{', '}']) + '.html');
      TFile.WriteAllText(LTempFile, AHtml, TEncoding.UTF8);
      LWebView.Navigate(PChar('file:///' + LTempFile.Replace('\', '/')));
    end;
    Result := Wait(ATimeoutMs);
    if not Result then
      AError := FError;
  except
    on E: Exception do
    begin
      Result := False;
      AError := E.Message;
    end;
  end;
  // A browser per export: closed here whatever happened, so that the next
  // one starts clean. The environment is kept.
  CloseController;
  if (LTempFile <> '') and TFile.Exists(LTempFile) then
    TFile.Delete(LTempFile);
end;

{$ELSE}

function THelpChatPdfExporter.EnsureWindow: Boolean;
begin
  Result := False;
end;

function THelpChatPdfExporter.EnsureEnvironment(ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
end;

function THelpChatPdfExporter.CreateController(ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
end;

function THelpChatPdfExporter.PrintSettings: IInterface;
begin
  Result := nil;
end;

procedure THelpChatPdfExporter.CloseController;
begin
end;

procedure THelpChatPdfExporter.EnvironmentReady(const AErrorCode: Integer;
  const AEnvironment: IInterface);
begin
end;

procedure THelpChatPdfExporter.ControllerReady(const AErrorCode: Integer;
  const AController: IInterface);
begin
end;

procedure THelpChatPdfExporter.NavigationDone(const ASuccess: Boolean);
begin
end;

procedure THelpChatPdfExporter.StartPrint;
begin
end;

function THelpChatPdfExporter.StartCdpPrint: Boolean;
begin
  Result := False;
end;

function THelpChatPdfExporter.CdpParameters: string;
begin
  Result := '';
end;

procedure THelpChatPdfExporter.CdpDone(const AErrorCode: Integer; const AJson: string);
begin
end;

procedure THelpChatPdfExporter.PrintDone(const AErrorCode: Integer; const ASuccess: Boolean);
begin
end;

function THelpChatPdfExporter.Wait(ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
end;

function THelpChatPdfExporter.ExportHtml(const AHtml, AFileName: string;
  const APage: THelpChatPdfPage; out AError: string; ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
  AError := 'a PDF can only be written on Windows';
end;

{$ENDIF MSWINDOWS}

end.
