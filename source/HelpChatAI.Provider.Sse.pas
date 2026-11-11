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
///  The part of a streaming reply that is the same whoever sends it: bytes
///  arrive in whatever chunks the socket decides, they have to be cut into
///  lines, decoded as UTF-8 only once a line is whole (a multi-byte character
///  is routinely split across two reads), and handed over one at a time.
///
///  <see cref="THelpChatSseStreamBase" /> is the sink
///  <c>THTTPClient.Post</c> writes into, so the tokens reach the user while
///  the model is still talking instead of after it stopped. What each provider
///  adds is <c>ProcessLine</c>: Anthropic sends typed events, OpenAI sends
///  deltas of a chat completion, Gemini sends whole candidates. They disagree
///  on everything except the shape of the pipe.
///
///  A malformed fragment is ignored rather than raised: half an answer is
///  better than an exception, and the provider checks <c>Error</c> and the
///  HTTP status afterwards anyway.
/// </summary>
unit HelpChatAI.Provider.Sse;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  HelpChatAI.Types;

type
  /// <summary>Write-only stream that cuts the body into lines and lets the
  /// descendant read them. Never seek it: it is a sink. Not thread-safe and
  /// not meant to be: one instance per request, written by the HTTP client
  /// on the thread that called <c>Post</c> and read by that same thread
  /// when the call returns. The token callback therefore runs on that
  /// thread too, inside <c>Write</c>, while the transfer is in progress.</summary>
  THelpChatSseStreamBase = class(TStream)
  strict private
    FPending: TBytes;
    FRaw: TStringBuilder;
    FWritten: Int64;
    FOnToken: THelpChatTokenProc;
    FText: TStringBuilder;
    /// <summary>Hands every whole line of the buffer to <c>ProcessLine</c>
    /// and keeps the bytes after the last line break for the next write;
    /// with <c>AFlushRemainder</c> those go out as a last line too.</summary>
    procedure Drain(const AFlushRemainder: Boolean);
    function GetText: string;
    function GetRaw: string;
  strict protected
    /// <summary>Message of a mid-stream error event; set by the descendant.</summary>
    FError: string;
    /// <summary>One decoded line of the body, without its line break: every
    /// line, the <c>event:</c> ones and the blank separators included, and
    /// the lines of a body that is not a stream at all (the JSON of a
    /// refused request). An override must not raise: it runs inside the
    /// <c>Write</c> the HTTP client is calling, and what it cannot read it
    /// skips.</summary>
    procedure ProcessLine(const ALine: string); virtual; abstract;
    /// <summary>Appends a piece of the reply and forwards it to the caller.
    /// Everything the user reads goes through here, so what is streamed and
    /// what is stored cannot drift apart.</summary>
    procedure EmitToken(const AToken: string);
    /// <summary>The payload of a <c>data:</c> line: empty for anything else,
    /// for a blank payload and for the <c>[DONE]</c> sentinel.</summary>
    class function DataPayload(const ALine: string): string;
    /// <summary>The line's payload parsed as a JSON object, or nil when it is
    /// empty, malformed or not an object: never raises. The caller owns the
    /// result.</summary>
    class function ParseObject(const AData: string): TJSONObject;
  public
    /// <summary><c>AOnToken</c> is called for every piece of the reply as it
    /// is decoded; nil for a caller that only wants <c>Text</c> at the
    /// end.</summary>
    constructor Create(const AOnToken: THelpChatTokenProc);
    destructor Destroy; override;
    /// <summary>Always reads nothing: the stream is a sink.</summary>
    function Read(var Buffer; Count: Longint): Longint; override;
    /// <summary>Takes a chunk of the body as the socket delivered it and
    /// processes every line that chunk completes. Always accepts the whole
    /// chunk.</summary>
    function Write(const Buffer; Count: Longint): Longint; override;
    /// <summary>Moves nothing and answers the number of bytes written so
    /// far, whatever is asked: the HTTP client asks for the size and the
    /// position of the stream it appends to.</summary>
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    /// <summary>Flushes a trailing partial line (the body may not end with a
    /// newline). To be called once, when the transfer is over and before
    /// <c>Text</c>, <c>Raw</c> or <c>Error</c> are read.</summary>
    procedure Finish;
    /// <summary>Accumulated assistant text: exactly the concatenation of
    /// what went through the token callback.</summary>
    property Text: string read GetText;
    /// <summary>Full decoded body, line breaks normalized, for error
    /// extraction: a refused request answers with plain JSON, not with a
    /// stream.</summary>
    property Raw: string read GetRaw;
    /// <summary>Message of a mid-stream error event, if any. Nothing is
    /// raised while the body arrives: the provider checks this once the
    /// transfer is over.</summary>
    property Error: string read FError;
  end;

implementation

{ THelpChatSseStreamBase }

constructor THelpChatSseStreamBase.Create(const AOnToken: THelpChatTokenProc);
begin
  inherited Create;
  FOnToken := AOnToken;
  FText := TStringBuilder.Create;
  FRaw := TStringBuilder.Create;
end;

destructor THelpChatSseStreamBase.Destroy;
begin
  FText.Free;
  FRaw.Free;
  inherited;
end;

procedure THelpChatSseStreamBase.EmitToken(const AToken: string);
begin
  if AToken = '' then
    Exit;
  FText.Append(AToken);
  if Assigned(FOnToken) then
    FOnToken(AToken);
end;

class function THelpChatSseStreamBase.DataPayload(const ALine: string): string;
begin
  // Only payload lines matter; "event:" lines and blank separators are skipped.
  if not ALine.StartsWith('data:') then
    Exit('');
  Result := Trim(Copy(ALine, 6, MaxInt));
  if Result = '[DONE]' then
    Result := '';
end;

class function THelpChatSseStreamBase.ParseObject(const AData: string): TJSONObject;
var
  LValue: TJSONValue;
begin
  if AData = '' then
    Exit(nil);
  try
    LValue := TJSONObject.ParseJSONValue(AData);
  except
    LValue := nil; // a malformed fragment must not fail the whole reply
  end;
  if LValue is TJSONObject then
    Result := TJSONObject(LValue)
  else
  begin
    LValue.Free;
    Result := nil;
  end;
end;

function THelpChatSseStreamBase.GetText: string;
begin
  Result := FText.ToString;
end;

function THelpChatSseStreamBase.GetRaw: string;
begin
  Result := FRaw.ToString;
end;

function THelpChatSseStreamBase.Read(var Buffer; Count: Longint): Longint;
begin
  Result := 0; // write-only sink
end;

function THelpChatSseStreamBase.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // THTTPClient treats the response stream as an append sink: report the end.
  Result := FWritten;
end;

function THelpChatSseStreamBase.Write(const Buffer; Count: Longint): Longint;
var
  LOld: Integer;
begin
  if Count > 0 then
  begin
    LOld := Length(FPending);
    SetLength(FPending, LOld + Count);
    Move(Buffer, FPending[LOld], Count);
    Inc(FWritten, Count);
    Drain(False);
  end;
  Result := Count;
end;

procedure THelpChatSseStreamBase.Finish;
begin
  Drain(True);
end;

procedure THelpChatSseStreamBase.Drain(const AFlushRemainder: Boolean);
var
  I, LStart, LLen: Integer;
  LRemainder: TBytes;

  procedure Emit(const ABytes: TBytes);
  var
    LDecoded: string;
    LN: Integer;
  begin
    LN := Length(ABytes);
    try
      // Strip a trailing #13 (CRLF line endings).
      if (LN > 0) and (ABytes[LN - 1] = 13) then
        LDecoded := TEncoding.UTF8.GetString(ABytes, 0, LN - 1)
      else
        LDecoded := TEncoding.UTF8.GetString(ABytes);
    except
      // Bytes that are not UTF-8 (a proxy answering in another encoding, a
      // truncated stream): the decoder raises, and from here that would
      // abort the transfer in the middle of the HTTP client. A fragment
      // that cannot be read is skipped, like one that cannot be parsed.
      Exit;
    end;
    FRaw.Append(LDecoded).Append(#10);
    ProcessLine(LDecoded);
  end;

begin
  // Cut on the byte 10 and decode afterwards: in UTF-8 that byte is never
  // part of a multi-byte character, so a line is always whole characters,
  // however the socket split them.
  LStart := 0;
  I := 0;
  while I < Length(FPending) do
  begin
    if FPending[I] = 10 then
    begin
      Emit(Copy(FPending, LStart, I - LStart));
      LStart := I + 1;
    end;
    Inc(I);
  end;

  LLen := Length(FPending) - LStart;
  if LLen > 0 then
    LRemainder := Copy(FPending, LStart, LLen)
  else
    LRemainder := nil;

  if AFlushRemainder and (Length(LRemainder) > 0) then
  begin
    Emit(LRemainder);
    LRemainder := nil;
  end;

  FPending := LRemainder;
end;

end.
