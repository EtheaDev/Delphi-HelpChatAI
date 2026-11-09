{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       The icons of the providers and models, as SVG, for the assistant       }
{       badge of the panel. RTL only.                                          }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{       you may not use this file except in compliance with the License.       }
{       You may obtain a copy of the License at                                }
{                                                                              }
{       http://www.apache.org/licenses/LICENSE-2.0                             }
{                                                                              }
{       Unless required by applicable law or agreed to in writing, software    }
{       distributed under the License is distributed on an "AS IS" BASIS,      }
{       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied}
{       See the License for the specific language governing permissions and    }
{       limitations under the License.                                         }
{                                                                              }
{******************************************************************************}
/// <summary>
///  The icons of the AI providers and models the panel can show next to the
///  assistant in use: SVG files of lobe-icons (https://github.com/lobehub/lobe-icons,
///  MIT - the logos themselves stay trademarks of their owners), compiled into
///  <c>source\HelpChatAI.Providers.res</c> by <c>Tools\BuildResources.cmd</c>
///  from <c>Images\providers\*.svg</c>. An icon is an id (<c>claude</c>,
///  <c>openai</c>...), deduced from the model name first, from the endpoint
///  second and from the provider last: a <c>gemma4</c> on an Ollama served by
///  the <c>openai</c> provider shows Gemma, not OpenAI.
///  Adding an icon = the SVG in <c>Images\providers</c>, an entry in
///  <c>resources\HelpChatAI.Providers.rc</c>, the build, a name in
///  <c>HELPCHAT_PROVIDER_ICONS</c> and, when a model name points to it, a
///  prefix in <see cref="HelpChatProviderIconFor" />.
///  The same resource carries the flags of the languages of the chat
///  (circle-flags, MIT, from <c>Imageslags</c>), one per language code.
/// </summary>
unit HelpChatAI.Icons;

interface

const
  /// <summary>The icon ids shipped in <c>HelpChatAI.Providers.res</c>.</summary>
  HELPCHAT_PROVIDER_ICONS: array[0..13] of string = (
    'azure', 'claude', 'cohere', 'deepseek', 'gemini', 'gemma', 'groq',
    'llama', 'lmstudio', 'mistral', 'ollama', 'openai', 'openrouter', 'qwen');

/// <summary>True when AId is one of the shipped icons.</summary>
function HelpChatProviderIconExists(const AId: string): Boolean;

/// <summary>The SVG of the icon AId, with its <c>title</c> removed (the panel
/// puts its own tooltip on it); empty when there is no such icon.</summary>
function HelpChatProviderIconSvg(const AId: string): string;

/// <summary>The icon for a model served by a provider at an endpoint: the
/// model name decides when it can (claude, gemini, gpt, gemma, qwen, mistral,
/// deepseek, llama, command), the host of the endpoint next (an Ollama, an
/// OpenRouter, a Groq, an Azure, an LM Studio), the provider last; empty when
/// nothing is known, which is what docsearch and stub get.</summary>
function HelpChatProviderIconFor(const AModel, ABaseUrl, AProvider: string): string;

/// <summary>The round flag of a language, by ISO code ("en", "it", "es",
/// "fr", "de", "pt"), as SVG; empty for a code without one.</summary>
function HelpChatFlagSvg(const ALanguageCode: string): string;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Types,
  Winapi.Windows;   // FindResource and RT_RCDATA

{$R HelpChatAI.Providers.res}

function HelpChatProviderIconExists(const AId: string): Boolean;
begin
  Result := MatchText(Trim(AId), HELPCHAT_PROVIDER_ICONS);
end;

/// <summary>The SVG text of an RCDATA resource; empty when there is none.</summary>
function ResourceSvg(const AName: string): string;
var
  LStream: TResourceStream;
  LBytes: TBytes;
begin
  Result := '';
  if FindResource(HInstance, PChar(AName), RT_RCDATA) = 0 then
    Exit;
  LStream := TResourceStream.Create(HInstance, AName, RT_RCDATA);
  try
    SetLength(LBytes, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(LBytes[0], LStream.Size);
  finally
    LStream.Free;
  end;
  Result := TEncoding.UTF8.GetString(LBytes);
end;

function HelpChatFlagSvg(const ALanguageCode: string): string;
var
  LCode: string;
  C: Char;
begin
  Result := '';
  LCode := Trim(ALanguageCode).ToUpper;
  // Two letters and nothing else: the code becomes part of a resource name.
  if LCode.Length <> 2 then
    Exit;
  for C in LCode do
    if not CharInSet(C, ['A'..'Z']) then
      Exit;
  Result := ResourceSvg('HCFLAG_' + LCode);
end;

function HelpChatProviderIconSvg(const AId: string): string;
var
  LStart, LStop: Integer;
begin
  Result := '';
  if not HelpChatProviderIconExists(AId) then
    Exit;
  Result := ResourceSvg('HCICON_' + Trim(AId).ToUpper);
  if Result = '' then
    Exit;
  // The title of the file would become a tooltip of the browser's own.
  LStart := Result.IndexOf('<title>');
  if LStart >= 0 then
  begin
    LStop := Result.IndexOf('</title>', LStart);
    if LStop > LStart then
      Result := Result.Remove(LStart, LStop + Length('</title>') - LStart);
  end;
end;

function HelpChatProviderIconFor(const AModel, ABaseUrl, AProvider: string): string;

  function StartsWithAny(const AValue: string; const APrefixes: array of string): Boolean;
  var
    LPrefix: string;
  begin
    for LPrefix in APrefixes do
      if AValue.StartsWith(LPrefix) then
        Exit(True);
    Result := False;
  end;

var
  LModel, LHost, LProvider: string;
  LAt: Integer;
begin
  // The model: what is being talked to, whoever serves it. A provider prefix
  // the way OpenRouter writes it ("google/gemma-3") is skipped.
  LModel := Trim(AModel).ToLower;
  LAt := LModel.LastIndexOf('/');
  if LAt >= 0 then
    LModel := LModel.Substring(LAt + 1);
  if StartsWithAny(LModel, ['claude']) then
    Exit('claude');
  if StartsWithAny(LModel, ['gemini']) then
    Exit('gemini');
  if StartsWithAny(LModel, ['gemma']) then
    Exit('gemma');
  if StartsWithAny(LModel, ['gpt', 'chatgpt', 'o1', 'o3', 'o4', 'text-', 'davinci']) then
    Exit('openai');
  if StartsWithAny(LModel, ['qwen', 'qwq']) then
    Exit('qwen');
  if StartsWithAny(LModel, ['mistral', 'mixtral', 'codestral', 'ministral', 'magistral', 'devstral']) then
    Exit('mistral');
  if StartsWithAny(LModel, ['deepseek']) then
    Exit('deepseek');
  if StartsWithAny(LModel, ['llama', 'meta-llama', 'codellama']) then
    Exit('llama');
  if StartsWithAny(LModel, ['command']) then
    Exit('cohere');

  // The endpoint: a local or an aggregating service has a face of its own.
  LHost := Trim(ABaseUrl).ToLower;
  if LHost.Contains('openrouter.ai') then
    Exit('openrouter');
  if LHost.Contains('groq.com') then
    Exit('groq');
  if LHost.Contains('azure.com') or LHost.Contains('azure.us') then
    Exit('azure');
  if LHost.Contains(':11434') then
    Exit('ollama');
  if LHost.Contains(':1234') then
    Exit('lmstudio');

  // The provider: the API, when nothing says more.
  LProvider := Trim(AProvider).ToLower;
  if LProvider = 'claude' then
    Exit('claude');
  if LProvider = 'gemini' then
    Exit('gemini');
  if LProvider = 'openai' then
    Exit('openai');
  Result := '';
end;

end.
