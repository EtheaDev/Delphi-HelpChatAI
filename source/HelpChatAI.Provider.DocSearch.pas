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
///  Deterministic provider (<c>docsearch</c>): answers by searching the
///  documentation index through the engine's <see cref="IHelpChatRetriever" />
///  and pointing to the best matching page. No API key, no network, immediate.
///  Reply in Markdown: bold title, summary, a "read more" link and, when a
///  second page scores meaningfully, a "see also" line. Works well on keywords
///  and screen names, less on natural-language questions: that boundary is
///  where the AI provider begins.
/// </summary>
unit HelpChatAI.Provider.DocSearch;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  HelpChatAI.Types,
  HelpChatAI.Settings,
  HelpChatAI.Provider;

const
  HELPCHAT_PROVIDER_DOCSEARCH = 'docsearch';
  /// <summary>Minimum score of the second page to be offered as "see also".</summary>
  HELPCHAT_DOCSEARCH_SEEALSO_MINSCORE = 2;

type
  THelpChatDocSearchProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

implementation

uses
  System.IOUtils,
  HelpChatAI.Messages;

{ THelpChatDocSearchProvider }

function THelpChatDocSearchProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_DOCSEARCH;
end;

class function THelpChatDocSearchProvider.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
var
  LIndexFile: string;
begin
  Result := '';
  if not Assigned(ASettings) then
    Exit;
  // This provider has nothing but the index: without it every question gets
  // the "documentation not available" answer.
  LIndexFile := ASettings.ResolveDocIndexFile;
  if not TFile.Exists(LIndexFile) then
    Result := Format('No documentation index: "%s" does not exist. Build it ' +
      'with Tools\HelpIndexBuilder and set Settings.DocIndexFile.', [LIndexFile]);
end;

function THelpChatDocSearchProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
var
  LPages: TArray<THelpChatDocPage>;
  LBase: string;
begin
  CheckCancelled(ACancel);

  if Assigned(Retriever) then
    LBase := Retriever.GetBaseUrl
  else
    LBase := '';
  if (LBase = '') and Assigned(Settings) then
    LBase := Settings.DocBaseUrl;

  if not Assigned(Retriever) or not Retriever.IsAvailable then
    Exit(MsgFmt(hcmIndexUnavailable, [LBase]));

  // The last user message is the question; the screen context biases the search
  // so a chat opened from a screen surfaces the page about that screen.
  LPages := Retriever.Search(LastUserMessage(AHistory), AContext.SearchHint, 2);
  if Length(LPages) = 0 then
    Exit(MsgFmt(hcmNoPageFound, [LBase]));

  Result := Format('**%s**'#10#10'%s'#10#10'[%s](%s)',
    [LPages[0].Title, LPages[0].Summary, Msg(hcmReadMore), LPages[0].Url]);

  if (Length(LPages) > 1) and (LPages[1].Score >= HELPCHAT_DOCSEARCH_SEEALSO_MINSCORE) then
    Result := Result + Format(#10#10'%s [%s](%s)',
      [Msg(hcmSeeAlso), LPages[1].Title, LPages[1].Url]);
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_DOCSEARCH, THelpChatDocSearchProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_DOCSEARCH);

end.
