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
///  Dictation for the question box, on Windows.
///
///  Two ways of listening, behind one class, and the application picks one
///  (<see cref="THelpChatVoiceEngine" />): nothing is swapped underneath, an
///  engine that fails says so.
///
///  The dictation of the system, the one Win+H starts, is the default: the
///  keystroke is simulated and Windows types into whatever control has the
///  focus, which is the question box of the panel. Nothing comes back here —
///  no text, no state — but it works wherever Win+H works.
///
///  The Windows speech recognizer (Windows.Media.SpeechRecognition, in the
///  RTL from Delphi 11 on) is a continuous session whose text comes back
///  here, so the component can write it into the box while the user talks
///  and stop on command. It needs the consent to online speech recognition,
///  and on some Windows builds it hears a voice and transcribes nothing,
///  which is why it is not the default.
///
///  Events are raised on the main thread: the recognizer answers on its own
///  threads, so every event is marshalled with TThread.Queue.
///
///  The unit knows nothing of the chat - no engine, no server, no page: it
///  gives text and state to whoever listens to its events. Each assistant
///  creates its own instance; the dictation bar of Windows and the
///  microphone are still one per desktop.
/// </summary>
unit Vcl.HelpChatAI.Voice;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows;

type
  /// <summary>
  ///  Which engine listens. The application picks one and gets that one: an
  ///  engine that does not work says so, it is never swapped underneath.
  ///  <para><c>hveNone</c>: no dictation at all. Nothing is asked of Windows
  ///  and the microphone button does not appear.</para>
  ///  <para><c>hveSystemDictation</c>: the dictation of Windows (Win+H).
  ///  Windows types into the focused control and reports nothing back, so the
  ///  component only knows that it asked. It works wherever Win+H works.</para>
  ///  <para><c>hveRecognizer</c>: Windows.Media.SpeechRecognition. It reports
  ///  the text, so the box fills while the user talks and the application sees
  ///  every piece; but it needs the online speech consent, and on recent
  ///  Windows 11 builds it may hear the voice and transcribe nothing.</para>
  /// </summary>
  THelpChatVoiceEngine = (hveNone, hveSystemDictation, hveRecognizer);

  /// <summary>Recognized text: AFinal is a settled sentence, otherwise it is a
  /// hypothesis that the next one replaces.</summary>
  THelpChatVoiceTextEvent = procedure(Sender: TObject; const AText: string;
    const AFinal: Boolean) of object;
  /// <summary>The engine started or stopped listening.</summary>
  THelpChatVoiceStateEvent = procedure(Sender: TObject; const AListening: Boolean) of object;
  /// <summary>Dictation could not start, or died: AMessage is for the user.</summary>
  THelpChatVoiceErrorEvent = procedure(Sender: TObject; const AMessage: string) of object;

  /// <summary>
  ///  What the component uses to listen. Create one with
  ///  <see cref="CreateHelpChatVoiceInput" />, which builds the engine asked
  ///  for and no other. The caller owns it and frees it on the main thread;
  ///  freeing it stops a session that is running. A new engine (a cloud
  ///  service, a local model) is another descendant: override
  ///  <c>DoStart</c>, <c>DoStop</c>, <c>IsAvailable</c> and
  ///  <c>EngineName</c>, and report through <c>DoText</c>, <c>DoState</c>
  ///  and <c>DoError</c> from whatever thread the engine answers on.
  /// </summary>
  THelpChatVoiceInput = class abstract
  strict private
    FListening: Boolean;
    FHeardSpeech: Boolean;
    FOnText: THelpChatVoiceTextEvent;
    FOnState: THelpChatVoiceStateEvent;
    FOnError: THelpChatVoiceErrorEvent;
  strict protected
    /// <summary>Raises OnText on the main thread. Callable from any thread;
    /// an empty text is dropped. The handler is the one assigned at the
    /// time of the call, not at the time it runs.</summary>
    procedure DoText(const AText: string; const AFinal: Boolean);
    /// <summary>Records the state and raises OnState on the main thread.
    /// The state is recorded at once, on the calling thread; a state equal
    /// to the current one raises nothing.</summary>
    procedure DoState(const AListening: Boolean);
    /// <summary>Raises OnError on the main thread. An empty message means
    /// "could not start, no reason known": the component then says it in
    /// the language of the user.</summary>
    procedure DoError(const AMessage: string);
    /// <summary>The engine reports that someone is speaking.</summary>
    procedure DoHeardSpeech;
    /// <summary>Starts listening. Must not block the main thread; reports
    /// success with <c>DoState(True)</c> and failure with <c>DoError</c>.</summary>
    procedure DoStart; virtual; abstract;
    /// <summary>Stops listening and reports <c>DoState(False)</c>. Also
    /// called by the destructor, when the events are already detached.</summary>
    procedure DoStop; virtual; abstract;
  public
    /// <summary>Detaches the events, then stops a session still running.
    /// Calls already queued for the main thread captured their handler
    /// before this and still run after it.</summary>
    destructor Destroy; override;
    /// <summary>True when this way of listening can be used here and now.
    /// May take a moment the first time (the recognizer asks its own thread
    /// and waits for it); the answer is then remembered.</summary>
    function IsAvailable: Boolean; virtual; abstract;
    /// <summary>True when the text reaches the application through OnText.
    /// False for the system dictation, which types into the focused control
    /// and tells us nothing.</summary>
    function ReportsText: Boolean; virtual;
    /// <summary>Short name of the engine, for logs and for the About box.</summary>
    function EngineName: string; virtual; abstract;
    /// <summary>Asks the engine to listen; nothing when it already does.
    /// Returns at once: listening has begun when <c>OnState</c> says so,
    /// and a failure arrives through <c>OnError</c>.</summary>
    procedure Start;
    /// <summary>Asks the engine to stop; nothing when it is not listening.</summary>
    procedure Stop;
    /// <summary>What the engine last reported. For the system dictation it
    /// only means "we sent the shortcut": the user may have closed the
    /// dictation bar, and nobody tells us.</summary>
    property Listening: Boolean read FListening;
    /// <summary>True once the engine reported speech in this session. Heard
    /// but never transcribed is a failing engine, not a silent user.</summary>
    property HeardSpeech: Boolean read FHeardSpeech;
    /// <summary>Recognized text, on the main thread. Never raised by an
    /// engine whose <c>ReportsText</c> is False.</summary>
    property OnText: THelpChatVoiceTextEvent read FOnText write FOnText;
    /// <summary>Listening began or ended, on the main thread.</summary>
    property OnState: THelpChatVoiceStateEvent read FOnState write FOnState;
    /// <summary>The engine could not start or stopped by itself, on the
    /// main thread; the message may be empty.</summary>
    property OnError: THelpChatVoiceErrorEvent read FOnError write FOnError;
  end;

  /// <summary>
  ///  The dictation of Windows, started by simulating Win+H. It types into the
  ///  control that has the focus and reports nothing back - so the caller
  ///  must put the focus in the question box before <c>Start</c>. The same
  ///  shortcut opens and closes the dictation bar, which is one for the
  ///  whole desktop: two instances that both believe they are listening
  ///  toggle the same bar.
  /// </summary>
  THelpChatSystemDictation = class(THelpChatVoiceInput)
  strict protected
    procedure DoStart; override;
    procedure DoStop; override;
  public
    function IsAvailable: Boolean; override;
    function ReportsText: Boolean; override;
    function EngineName: string; override;
  end;

/// <summary>
///  The engine asked for, or nil for <c>hveNone</c> and when this Delphi
///  cannot build it (the recognizer needs Delphi 11). Ask the result whether
///  it <c>IsAvailable</c>: built is not the same as usable here and now.
/// </summary>
function CreateHelpChatVoiceInput(
  const AEngine: THelpChatVoiceEngine = hveSystemDictation): THelpChatVoiceInput;

/// <summary>
///  True when the user accepted online speech recognition, which is what free
///  dictation goes through: without it the recognizer compiles its grammar and
///  then refuses to start. A missing key means never accepted.
/// </summary>
function HelpChatOnlineSpeechAccepted: Boolean;

/// <summary>
///  Opens the Windows page where that consent is given (Settings, Privacy and
///  security, Speech). No application can give it on the user's behalf.
/// </summary>
procedure HelpChatOpenSpeechSettings;

implementation

uses
  System.Win.Registry,
  Winapi.ShellAPI
{$IFDEF D11+}
  , System.SyncObjs
  , System.Generics.Collections
  , Winapi.WinRT
  , System.Win.WinRT
  , Winapi.CommonTypes
  , Winapi.Foundation
  , Winapi.Media       // Windows.Media.SpeechRecognition, from Delphi 11 on
{$ENDIF}
  ;

{$IFDEF D11+}
type
  THelpChatWinRTVoice = class;

  /// <summary>
  ///  The one thread that talks to WinRT. A thread that never called
  ///  RoInitialize cannot even get the activation factory ("Cannot get factory
  ///  for class"), and an apartment dies with the thread that opened it: so the
  ///  recognizer is created, started and stopped here, and this thread lives as
  ///  long as the engine does. It also keeps the panel responsive, because
  ///  compiling the dictation constraints takes a moment.
  /// </summary>
  TVoiceApartment = class(TThread)
  strict private
    FQueue: TThreadedQueue<TProc>;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Runs AProc on the WinRT thread.</summary>
    procedure Post(const AProc: TProc);
  end;

  /// <summary>A sentence the recognizer settled on.</summary>
  TVoiceResultHandler = class(TInspectableObject,
    TypedEventHandler_2__SpeechRecognition_ISpeechContinuousRecognitionSession__SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs)
  strict private
    [Weak] FOwner: THelpChatWinRTVoice;
  public
    constructor Create(const AOwner: THelpChatWinRTVoice);
    procedure Invoke(sender: SpeechRecognition_ISpeechContinuousRecognitionSession;
      args: SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs); safecall;
  end;

  /// <summary>The session ended, by itself or because we stopped it.</summary>
  TVoiceCompletedHandler = class(TInspectableObject,
    TypedEventHandler_2__SpeechRecognition_ISpeechContinuousRecognitionSession__SpeechRecognition_ISpeechContinuousRecognitionCompletedEventArgs)
  strict private
    [Weak] FOwner: THelpChatWinRTVoice;
  public
    constructor Create(const AOwner: THelpChatWinRTVoice);
    procedure Invoke(sender: SpeechRecognition_ISpeechContinuousRecognitionSession;
      args: SpeechRecognition_ISpeechContinuousRecognitionCompletedEventArgs); safecall;
  end;

  /// <summary>What the recognizer thinks it is hearing, while it hears it.</summary>
  TVoiceHypothesisHandler = class(TInspectableObject,
    TypedEventHandler_2__SpeechRecognition_ISpeechRecognizer__SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs)
  strict private
    [Weak] FOwner: THelpChatWinRTVoice;
  public
    constructor Create(const AOwner: THelpChatWinRTVoice);
    procedure Invoke(sender: SpeechRecognition_ISpeechRecognizer;
      args: SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs); safecall;
  end;

  /// <summary>What the engine is doing: we only care that it hears a voice,
  /// which tells a failing engine apart from a silent user.</summary>
  TVoiceStateHandler = class(TInspectableObject,
    TypedEventHandler_2__SpeechRecognition_ISpeechRecognizer__SpeechRecognition_ISpeechRecognizerStateChangedEventArgs)
  strict private
    [Weak] FOwner: THelpChatWinRTVoice;
  public
    constructor Create(const AOwner: THelpChatWinRTVoice);
    procedure Invoke(sender: SpeechRecognition_ISpeechRecognizer;
      args: SpeechRecognition_ISpeechRecognizerStateChangedEventArgs); safecall;
  end;

  /// <summary>
  ///  Windows.Media.SpeechRecognition in continuous dictation: hypotheses while
  ///  the user talks, settled sentences when it recognizes them, until the
  ///  caller stops it.
  /// </summary>
  THelpChatWinRTVoice = class(THelpChatVoiceInput)
  strict private
    FRecognizer: SpeechRecognition_ISpeechRecognizer;
    FRecognizer2: SpeechRecognition_ISpeechRecognizer2;
    FSession: SpeechRecognition_ISpeechContinuousRecognitionSession;
    // Held as the interface, not the class: the refcount keeps them alive.
    FResultHandler: TypedEventHandler_2__SpeechRecognition_ISpeechContinuousRecognitionSession__SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs;
    FCompletedHandler: TypedEventHandler_2__SpeechRecognition_ISpeechContinuousRecognitionSession__SpeechRecognition_ISpeechContinuousRecognitionCompletedEventArgs;
    FHypothesisHandler: TypedEventHandler_2__SpeechRecognition_ISpeechRecognizer__SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs;
    FStateHandler: TypedEventHandler_2__SpeechRecognition_ISpeechRecognizer__SpeechRecognition_ISpeechRecognizerStateChangedEventArgs;
    FResultToken, FCompletedToken, FHypothesisToken, FStateToken: EventRegistrationToken;
    // Recognizer built, constraints compiled, handlers attached.
    FReady: Boolean;
    // A start is on its way on the WinRT thread: a second one is ignored.
    FStarting: Boolean;
    FApartment: TVoiceApartment;
    // The main thread waits on it for an answer of the WinRT thread.
    FSignal: TEvent;
    // IsAvailable asked once, and what it was told.
    FChecked: Boolean;
    FAvailable: Boolean;
    /// <summary>Builds the recognizer for free dictation and attaches the
    /// handlers. On the WinRT thread only; False when any step fails.</summary>
    function Prepare: Boolean;
    /// <summary>Detaches the handlers and lets them go. On the WinRT
    /// thread, which is the one that attached them.</summary>
    procedure Unhook;
  strict protected
    /// <summary>Prepares the recognizer if need be and starts the session,
    /// all on the WinRT thread: the call returns at once.</summary>
    procedure DoStart; override;
    /// <summary>Stops the session on the WinRT thread; the state changes
    /// when that thread gets to it.</summary>
    procedure DoStop; override;
  public
    /// <summary>Starts the WinRT thread; the recognizer itself is created
    /// by the first <c>Start</c>.</summary>
    constructor Create;
    /// <summary>Stops, lets the WinRT thread release the recognizer (up to
    /// three seconds), then ends that thread. Blocks the caller meanwhile.</summary>
    destructor Destroy; override;
    /// <summary>Whether Windows has a speech language at all, asked on the
    /// WinRT thread (up to eight seconds, once). True does not promise a
    /// transcription: the consent and the language pack show at start.</summary>
    function IsAvailable: Boolean; override;
    function EngineName: string; override;
    /// <summary>Called by the handlers, on a WinRT thread.</summary>
    procedure ReportHeard;
    procedure ReportResult(const AText: string);
    procedure ReportHypothesis(const AText: string);
    procedure ReportCompleted(const AStatus: Integer);
  end;

{ TVoiceApartment }

constructor TVoiceApartment.Create;
begin
  FQueue := TThreadedQueue<TProc>.Create(32, INFINITE, 100);
  inherited Create(False);
end;

destructor TVoiceApartment.Destroy;
begin
  FQueue.DoShutDown;
  Terminate;
  inherited Destroy;      // waits for Execute to leave its apartment
  FQueue.Free;
end;

procedure TVoiceApartment.Post(const AProc: TProc);
begin
  if not Terminated then
    FQueue.PushItem(AProc);
end;

procedure TVoiceApartment.Execute;
var
  LProc: TProc;
begin
  NameThreadForDebugging('HelpChat voice');
  // S_FALSE means somebody got here first, which is fine; only a real failure
  // leaves this thread unable to reach WinRT at all.
  RoInitialize(RO_INIT_MULTITHREADED);
  try
    while not Terminated do
      if (FQueue.PopItem(LProc) = TWaitResult.wrSignaled) and Assigned(LProc) then
        try
          LProc();
        except
          // an engine that throws must not take the thread down with it
        end;
  finally
    RoUninitialize;
  end;
end;

/// <summary>Waits for a WinRT async call, polling its IAsyncInfo.</summary>
function WaitAsync(const AOperation: IInterface; const ATimeoutMs: Cardinal): AsyncStatus;
var
  LInfo: IAsyncInfo;
  LStart: UInt64;
begin
  Result := AsyncStatus.Error;
  if not Supports(AOperation, IAsyncInfo, LInfo) then
    Exit;
  LStart := GetTickCount64;
  while LInfo.Status = AsyncStatus.Started do
  begin
    if GetTickCount64 - LStart > ATimeoutMs then
    begin
      LInfo.Cancel;
      Break;
    end;
    Sleep(5);
  end;
  Result := LInfo.Status;
end;

{ handlers }

constructor TVoiceResultHandler.Create(const AOwner: THelpChatWinRTVoice);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TVoiceResultHandler.Invoke(
  sender: SpeechRecognition_ISpeechContinuousRecognitionSession;
  args: SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs);
var
  LResult: SpeechRecognition_ISpeechRecognitionResult;
begin
  if (FOwner = nil) or (args = nil) then
    Exit;
  LResult := args.get_Result;
  if LResult = nil then
    Exit;
  if LResult.get_Confidence = SpeechRecognition_SpeechRecognitionConfidence.Rejected then
    Exit;
  FOwner.ReportResult(LResult.get_Text.ToString);
end;

constructor TVoiceCompletedHandler.Create(const AOwner: THelpChatWinRTVoice);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TVoiceCompletedHandler.Invoke(
  sender: SpeechRecognition_ISpeechContinuousRecognitionSession;
  args: SpeechRecognition_ISpeechContinuousRecognitionCompletedEventArgs);
var
  LStatus: Integer;
begin
  if FOwner = nil then
    Exit;
  LStatus := 0;
  if args <> nil then
    LStatus := Ord(args.get_Status);
  FOwner.ReportCompleted(LStatus);
end;

constructor TVoiceStateHandler.Create(const AOwner: THelpChatWinRTVoice);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TVoiceStateHandler.Invoke(sender: SpeechRecognition_ISpeechRecognizer;
  args: SpeechRecognition_ISpeechRecognizerStateChangedEventArgs);
begin
  if (FOwner <> nil) and (args <> nil) and
     (args.get_State = SpeechRecognition_SpeechRecognizerState.SpeechDetected) then
    FOwner.ReportHeard;
end;

constructor TVoiceHypothesisHandler.Create(const AOwner: THelpChatWinRTVoice);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TVoiceHypothesisHandler.Invoke(sender: SpeechRecognition_ISpeechRecognizer;
  args: SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs);
begin
  if (FOwner = nil) or (args = nil) or (args.get_Hypothesis = nil) then
    Exit;
  FOwner.ReportHypothesis(args.get_Hypothesis.get_Text.ToString);
end;

{ THelpChatWinRTVoice }

constructor THelpChatWinRTVoice.Create;
begin
  inherited Create;
  FSignal := TEvent.Create(nil, True, False, '');
  FApartment := TVoiceApartment.Create;
end;

destructor THelpChatWinRTVoice.Destroy;
begin
  inherited Destroy;      // stops the session while the handlers are still there
  // Let the WinRT thread let go of everything before it leaves its apartment.
  if Assigned(FApartment) then
  begin
    FSignal.ResetEvent;
    FApartment.Post(
      procedure
      begin
        try
          Unhook;
          FSession := nil;
          FRecognizer2 := nil;
          FRecognizer := nil;
        finally
          FSignal.SetEvent;
        end;
      end);
    FSignal.WaitFor(3000);
    FreeAndNil(FApartment);
  end;
  FSession := nil;
  FRecognizer2 := nil;
  FRecognizer := nil;
  FreeAndNil(FSignal);
end;

function THelpChatWinRTVoice.EngineName: string;
begin
  Result := 'Windows.Media.SpeechRecognition';
end;

function THelpChatWinRTVoice.IsAvailable: Boolean;
var
  LOk: Boolean;
begin
  if FChecked then
    Exit(FAvailable);
  Result := False;
  if not TOSVersion.Check(10) or (FApartment = nil) then
    Exit;
  // Asked on the WinRT thread: a thread without an apartment cannot even
  // reach the activation factory, and would report a working engine as absent.
  LOk := False;
  FSignal.ResetEvent;
  FApartment.Post(
    procedure
    begin
      try
        LOk := TSpeechRecognition_SpeechRecognizer.SystemSpeechLanguage <> nil;
      except
        LOk := False;
      end;
      FSignal.SetEvent;
    end);
  if FSignal.WaitFor(8000) <> TWaitResult.wrSignaled then
    LOk := False;
  FChecked := True;
  FAvailable := LOk;
  Result := LOk;
end;

function THelpChatWinRTVoice.Prepare: Boolean;
var
  LHint: TWindowsString;
  LConstraint: SpeechRecognition_ISpeechRecognitionTopicConstraint;
  LCompile: IAsyncOperation_1__SpeechRecognition_ISpeechRecognitionCompilationResult;
  LCompiled: SpeechRecognition_ISpeechRecognitionCompilationResult;
  LSilence: TimeSpan;
begin
  Result := FReady;
  if Result then
    Exit;
  FRecognizer := TSpeechRecognition_SpeechRecognizer.Create;
  if (FRecognizer = nil) or
     not Supports(FRecognizer, SpeechRecognition_ISpeechRecognizer2, FRecognizer2) then
    Exit(False);

  // Free dictation, the constraint Windows uses for "say anything".
  LHint := TWindowsString.Create('');
  LConstraint := TSpeechRecognition_SpeechRecognitionTopicConstraint.Create(
    SpeechRecognition_SpeechRecognitionScenario.Dictation, LHint);
  FRecognizer.get_Constraints.Append(
    LConstraint as SpeechRecognition_ISpeechRecognitionConstraint);

  LCompile := FRecognizer.CompileConstraintsAsync;
  if WaitAsync(LCompile, 20000) <> AsyncStatus.Completed then
    Exit(False);
  LCompiled := LCompile.GetResults;
  if (LCompiled = nil) or
     (LCompiled.get_Status <> SpeechRecognition_SpeechRecognitionResultStatus.Success) then
    Exit(False);

  FSession := FRecognizer2.get_ContinuousRecognitionSession;
  if FSession = nil then
    Exit(False);
  // The user stops the dictation, not a pause: keep listening through silence.
  LSilence.Duration := 30 * 10000000;   // TimeSpan counts 100 ns units
  FSession.put_AutoStopSilenceTimeout(LSilence);

  FResultHandler := TVoiceResultHandler.Create(Self);
  FResultToken := FSession.add_ResultGenerated(FResultHandler);
  FCompletedHandler := TVoiceCompletedHandler.Create(Self);
  FCompletedToken := FSession.add_Completed(FCompletedHandler);
  FHypothesisHandler := TVoiceHypothesisHandler.Create(Self);
  FHypothesisToken := FRecognizer2.add_HypothesisGenerated(FHypothesisHandler);
  FStateHandler := TVoiceStateHandler.Create(Self);
  FStateToken := FRecognizer.add_StateChanged(FStateHandler);

  FReady := True;
  Result := True;
end;

procedure THelpChatWinRTVoice.Unhook;
begin
  if Assigned(FSession) then
  begin
    if FResultToken.Value <> 0 then
      FSession.remove_ResultGenerated(FResultToken);
    if FCompletedToken.Value <> 0 then
      FSession.remove_Completed(FCompletedToken);
  end;
  if Assigned(FRecognizer2) and (FHypothesisToken.Value <> 0) then
    FRecognizer2.remove_HypothesisGenerated(FHypothesisToken);
  if Assigned(FRecognizer) and (FStateToken.Value <> 0) then
    FRecognizer.remove_StateChanged(FStateToken);
  FResultToken.Value := 0;
  FCompletedToken.Value := 0;
  FHypothesisToken.Value := 0;
  FStateToken.Value := 0;
  FResultHandler := nil;
  FCompletedHandler := nil;
  FHypothesisHandler := nil;
  FStateHandler := nil;
  FReady := False;
end;

procedure THelpChatWinRTVoice.DoStart;
begin
  if FStarting then
    Exit;
  if FApartment = nil then
  begin
    DoError('');
    Exit;
  end;
  FStarting := True;
  // Compiling the constraints takes a moment the first time, and StartAsync
  // waits for the microphone: neither belongs on the thread drawing the panel.
  FApartment.Post(
    procedure
    var
      LStarted: Boolean;
      LError: string;
    begin
      LStarted := False;
      LError := '';
      try
        if Prepare then
          LStarted := WaitAsync(FSession.StartAsync, 15000) = AsyncStatus.Completed;
      except
        on E: Exception do
          LError := E.Message;
      end;
      FStarting := False;
      if LStarted then
        DoState(True)
      else
        DoError(LError);      // empty: the component says it in the user's language
    end);
end;

procedure THelpChatWinRTVoice.DoStop;
begin
  if FApartment = nil then
  begin
    DoState(False);
    Exit;
  end;
  FApartment.Post(
    procedure
    begin
      try
        if Assigned(FSession) then
          WaitAsync(FSession.StopAsync, 5000);
      except
        // a recognizer that refuses to stop must not break the panel
      end;
      DoState(False);
    end);
end;

procedure THelpChatWinRTVoice.ReportHeard;
begin
  DoHeardSpeech;
end;

procedure THelpChatWinRTVoice.ReportResult(const AText: string);
begin
  DoText(AText, True);
end;

procedure THelpChatWinRTVoice.ReportHypothesis(const AText: string);
begin
  DoText(AText, False);
end;

procedure THelpChatWinRTVoice.ReportCompleted(const AStatus: Integer);
const
  // SpeechRecognitionResultStatus: why the session ended, in plain words
  REASON: array[1..10] of string = (
    'the language is not supported',
    'the grammar does not match the language',
    'the grammar could not be compiled',
    'the audio is too poor to work with',
    'it was cancelled',
    'an unknown failure',
    'nothing was heard in time',
    'it stayed paused too long',
    'the network failed',
    'no microphone is available');
begin
  DoState(False);
  if AStatus = 0 then       // Success: the caller stopped it
    Exit;
  if (AStatus >= Low(REASON)) and (AStatus <= High(REASON)) then
    DoError(Format('Dictation stopped: %s (status %d).', [REASON[AStatus], AStatus]))
  else
    DoError(Format('Dictation stopped with status %d.', [AStatus]));
end;
{$ENDIF}

{ THelpChatVoiceInput }

destructor THelpChatVoiceInput.Destroy;
begin
  FOnText := nil;
  FOnState := nil;
  FOnError := nil;
  if FListening then
    try
      DoStop;
    except
      // a dying engine must not take the application with it
    end;
  inherited Destroy;
end;

function THelpChatVoiceInput.ReportsText: Boolean;
begin
  Result := True;
end;

procedure THelpChatVoiceInput.DoText(const AText: string; const AFinal: Boolean);
var
  LHandler: THelpChatVoiceTextEvent;
  LText: string;
begin
  LHandler := FOnText;
  if not Assigned(LHandler) or (AText = '') then
    Exit;
  LText := AText;
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(LHandler) then
        LHandler(Self, LText, AFinal);
    end);
end;

procedure THelpChatVoiceInput.DoState(const AListening: Boolean);
var
  LHandler: THelpChatVoiceStateEvent;
begin
  if FListening = AListening then
    Exit;
  FListening := AListening;
  LHandler := FOnState;
  if not Assigned(LHandler) then
    Exit;
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(LHandler) then
        LHandler(Self, AListening);
    end);
end;

procedure THelpChatVoiceInput.DoError(const AMessage: string);
var
  LHandler: THelpChatVoiceErrorEvent;
  LText: string;
begin
  LHandler := FOnError;
  if not Assigned(LHandler) then
    Exit;
  LText := AMessage;
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(LHandler) then
        LHandler(Self, LText);
    end);
end;

procedure THelpChatVoiceInput.DoHeardSpeech;
begin
  FHeardSpeech := True;
end;

procedure THelpChatVoiceInput.Start;
begin
  if FListening then
    Exit;
  FHeardSpeech := False;
  DoStart;
end;

procedure THelpChatVoiceInput.Stop;
begin
  if not FListening then
    Exit;
  DoStop;
end;

{ THelpChatSystemDictation }

/// <summary>Sends Win+H, the shortcut that opens the dictation of Windows.</summary>
procedure SendDictationShortcut;
var
  LInput: array[0..3] of TInput;
  I: Integer;
begin
  FillChar(LInput, SizeOf(LInput), 0);
  for I := Low(LInput) to High(LInput) do
    LInput[I].Itype := INPUT_KEYBOARD;
  LInput[0].ki.wVk := VK_LWIN;
  LInput[1].ki.wVk := Ord('H');
  LInput[2].ki.wVk := Ord('H');
  LInput[2].ki.dwFlags := KEYEVENTF_KEYUP;
  LInput[3].ki.wVk := VK_LWIN;
  LInput[3].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(Length(LInput), LInput[0], SizeOf(TInput));
end;

function THelpChatSystemDictation.IsAvailable: Boolean;
begin
  // Win+H is there from Windows 10 on, and this unit is Windows only.
  Result := TOSVersion.Check(10);
end;

function THelpChatSystemDictation.ReportsText: Boolean;
begin
  Result := False;   // Windows types into the focused control, we never see it
end;

function THelpChatSystemDictation.EngineName: string;
begin
  Result := 'Windows dictation (Win+H)';
end;

procedure THelpChatSystemDictation.DoStart;
begin
  SendDictationShortcut;
  // Nothing reports back: we only know that we asked for it.
  DoState(True);
end;

procedure THelpChatSystemDictation.DoStop;
begin
  SendDictationShortcut;   // the same shortcut closes the dictation bar
  DoState(False);
end;

function HelpChatOnlineSpeechAccepted: Boolean;
const
  CONSENT_KEY = 'Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy';
var
  LReg: TRegistry;
begin
  Result := False;
  LReg := TRegistry.Create(KEY_READ);
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKeyReadOnly(CONSENT_KEY) then
    try
      Result := LReg.ValueExists('HasAccepted') and (LReg.ReadInteger('HasAccepted') <> 0);
    finally
      LReg.CloseKey;
    end;
  except
    Result := False;    // a registry we cannot read is not a consent
  end;
  LReg.Free;
end;

procedure HelpChatOpenSpeechSettings;
begin
  ShellExecute(0, 'open', 'ms-settings:privacy-speech', nil, nil, SW_SHOWNORMAL);
end;

function CreateHelpChatVoiceInput(
  const AEngine: THelpChatVoiceEngine): THelpChatVoiceInput;
begin
  Result := nil;
  if AEngine = hveNone then
    Exit;
  if AEngine = hveSystemDictation then
    Exit(THelpChatSystemDictation.Create);
  // hveRecognizer: that engine or nothing, never the dictation in its place.
{$IFDEF D11+}
  try
    Result := THelpChatWinRTVoice.Create;
  except
    FreeAndNil(Result);
  end;
{$ENDIF}
  // Delphi 10.4 has no WinRT speech in its RTL: nil, and the caller hides the
  // button rather than listening with something else.
end;

end.
