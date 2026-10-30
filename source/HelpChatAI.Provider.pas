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
///  Provider abstraction of the help chat. A provider turns the conversation
///  history plus the screen context into an assistant reply; a streaming
///  provider also emits the reply token by token. Providers register by name
///  in <see cref="THelpChatProviderRegistry" /> from their unit initialization,
///  so the active one is selected by <c>Settings.Provider</c> with no code
///  change on the call site. Ships the always-available <c>stub</c> provider.
/// </summary>
unit HelpChatAI.Provider;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  HelpChatAI.Types,
  HelpChatAI.Messages,
  HelpChatAI.Settings,
  HelpChatAI.Actions,
  HelpChatAI.Attachments;

const
  /// <summary>Name of the always-available placeholder provider.</summary>
  HELPCHAT_PROVIDER_STUB = 'stub';

type
  /// <summary>
  ///  Contract every chat back-end implements. <c>Generate</c> returns the full
  ///  assistant reply; a streaming provider (<c>SupportsStreaming = True</c>)
  ///  additionally calls <c>AOnToken</c> for each token as it is produced. A
  ///  provider checks <c>ACancel</c> between steps and raises
  ///  <see cref="EHelpChatCancelled" /> when it flips.
  /// </summary>
  IHelpChatProvider = interface
    ['{4C6F8A21-2B3D-4E5F-9A10-7C1B2D3E4F50}']
    /// <summary>The registered provider name.</summary>
    function GetName: string;
    /// <summary>True if the provider emits tokens incrementally via AOnToken.</summary>
    function SupportsStreaming: Boolean;
    /// <summary>True if the provider can call the actions of the application
    /// (tool use). One that cannot simply ignores them.</summary>
    function SupportsActions: Boolean;
    /// <summary>True if the provider can be given documents and images. One
    /// that cannot says so in the conversation instead of answering as though
    /// it had read them.</summary>
    function SupportsDocuments: Boolean;
    /// <summary>What the user attached to this conversation. The runner hands
    /// it over before <c>Generate</c>, from its own copy: a provider never
    /// reads the live set.</summary>
    procedure SetAttachments(const AValue: TArray<THelpChatAttachment>);
    /// <summary>Produces the assistant reply for the given history and context.</summary>
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string;
  end;

  /// <summary>
  ///  One action the model asked for, as it arrives in the stream. The three
  ///  APIs deliver it differently - Anthropic in typed blocks, OpenAI in
  ///  fragments tied by an index, Gemini whole - and all three end up here.
  /// </summary>
  THelpChatToolCall = record
    /// <summary>Id of the call, quoted back with its result. Gemini may send none.</summary>
    Id: string;
    /// <summary>Name of the action.</summary>
    Name: string;
    /// <summary>Arguments, as a JSON object.</summary>
    InputJson: string;
    /// <summary>Opaque metadata the service attached to the call and wants
    /// back, unchanged, when the conversation continues: the
    /// <c>thoughtSignature</c> of a thinking Gemini model, which refuses the
    /// next request without it. Empty for everybody else.</summary>
    Signature: string;
    class function Create(const AId, AName, AInputJson: string;
      const ASignature: string = ''): THelpChatToolCall; static;
  end;

  /// <summary>
  ///  Convenience base class for providers: reference-counted, non-streaming by
  ///  default, holding the settings snapshot and the retriever handed by the
  ///  registry. Providers are short-lived: one instance per request.
  /// </summary>
  THelpChatProviderBase = class abstract(TInterfacedObject, IHelpChatProvider)
  strict private
    FSettings: THelpChatSettings;
    FRetriever: IHelpChatRetriever;
    FActions: IHelpChatActionInvoker;
    FAttachments: TArray<THelpChatAttachment>;
  protected
    /// <summary>Settings snapshot of the request (not owned).</summary>
    property Settings: THelpChatSettings read FSettings;
    /// <summary>Documentation retriever, may be nil.</summary>
    property Retriever: IHelpChatRetriever read FRetriever;
    /// <summary>What the application lets the assistant do, may be nil.</summary>
    property Actions: IHelpChatActionInvoker read FActions;
    /// <summary>The attachments of the conversation; empty when there are none.</summary>
    property Attachments: TArray<THelpChatAttachment> read FAttachments;
    /// <summary>The question with the text attachments in front of it, which
    /// is what every provider sends: only the bytes of a PDF or of an image
    /// travel differently from one API to the next.</summary>
    function QuestionWithAttachments(const AQuestion: string): string;
    /// <summary>The sentence to append to a reply when documents were attached
    /// and this provider cannot read them; empty when there is nothing to say.</summary>
    function UnreadDocumentsNotice: string;
    /// <summary>Localized string in the language of the settings.</summary>
    function Msg(const AId: THelpChatMsgId): string;
    function MsgFmt(const AId: THelpChatMsgId; const AArgs: array of const): string;
    /// <summary>Raises <see cref="EHelpChatCancelled" /> when the token is set.</summary>
    procedure CheckCancelled(const ACancel: IHelpChatCancelToken);
  public
    /// <summary>Content of the most recent user message (the current question).</summary>
    class function LastUserMessage(const AHistory: TArray<THelpChatMessage>): string; static;
    /// <summary>Virtual so the registry can instantiate providers polymorphically.
    /// <c>ASettings</c> must outlive the provider (the runner guarantees it).</summary>
    constructor Create(const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever;
      const AActions: IHelpChatActionInvoker = nil); virtual;
    /// <summary>Why this provider could not answer with these settings, as one
    /// sentence; empty when everything it needs is there. Asked on the class,
    /// before any request, by <c>HelpChatAI.Diagnostics</c> and by the design-time
    /// check: a provider that needs a key or a file says so here, so adding a
    /// provider still means a new unit and nothing else.</summary>
    class function ConfigurationIssue(const ASettings: THelpChatSettings): string; virtual;
    /// <summary>The system prompt every model gets: the instruction (the one
    /// of the active section when it overrides it), the language rule, the
    /// screen the user is on and the documentation excerpts the retriever
    /// found. Nothing in it is provider specific, which is why it lives here:
    /// two providers that ground their answers differently would answer
    /// differently to the same question.</summary>
    class function BuildSystemPrompt(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever): string; static;
    function GetName: string; virtual; abstract;
    function SupportsStreaming: Boolean; virtual;
    function SupportsActions: Boolean; virtual;
    function SupportsDocuments: Boolean; virtual;
    procedure SetAttachments(const AValue: TArray<THelpChatAttachment>);
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; virtual; abstract;
  end;

  THelpChatProviderClass = class of THelpChatProviderBase;

  /// <summary>
  ///  Process-global registry of providers, keyed by (case-insensitive) name.
  ///  An empty name is <c>stub</c>. A name nobody registered (a typo, or a
  ///  provider unit the application did not link) is not silently replaced by
  ///  the stub, whose polite placeholder would pass for a real answer: it gets
  ///  <see cref="THelpChatUnavailableProvider" />, which turns every request
  ///  into an error bubble naming the provider and the unit to add.
  /// </summary>
  THelpChatProviderRegistry = class
  strict private
    class var FProviders: TDictionary<string, THelpChatProviderClass>;
    class var FLock: TObject;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure RegisterProvider(const AName: string; const AClass: THelpChatProviderClass);
    class procedure UnregisterProvider(const AName: string);
    class function IsRegistered(const AName: string): Boolean;
    /// <summary>The class registered under <c>AName</c>, or nil.</summary>
    class function FindProviderClass(const AName: string): THelpChatProviderClass;
    /// <summary>Instantiates the named provider: stub when AName is empty,
    /// THelpChatUnavailableProvider when nobody registered it.</summary>
    class function CreateProvider(const AName: string; const ASettings: THelpChatSettings;
      const ARetriever: IHelpChatRetriever;
      const AActions: IHelpChatActionInvoker = nil): IHelpChatProvider;
    /// <summary>Sorted names of all registered providers.</summary>
    class function ProviderNames: TArray<string>;
    /// <summary>True when the named provider can be given documents. Asked
    /// before the panel shows its paper clip: offering to attach a PDF to a
    /// provider that cannot read one is a promise the answer would break.
    /// False for a name nobody registered.</summary>
    class function SupportsDocuments(const AName: string): Boolean;
  end;

  /// <summary>
  ///  Default provider (<c>stub</c>): returns a fixed, honest placeholder reply.
  ///  Validates the whole pipeline without any external dependency or API key.
  /// </summary>
  THelpChatStubProvider = class(THelpChatProviderBase)
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
  end;

  /// <summary>
  ///  Stands in for a provider that is configured but not registered: every
  ///  request fails with a configuration error saying which provider is
  ///  missing and which ones are available. Never registered itself.
  /// </summary>
  THelpChatUnavailableProvider = class(THelpChatProviderBase)
  strict private
    FRequestedName: string;
  public
    function GetName: string; override;
    function Generate(const AHistory: TArray<THelpChatMessage>;
      const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
      const ACancel: IHelpChatCancelToken): string; override;
    /// <summary>The name the settings asked for.</summary>
    property RequestedName: string read FRequestedName write FRequestedName;
  end;

implementation

uses
  System.Generics.Defaults;

class function THelpChatProviderRegistry.SupportsDocuments(const AName: string): Boolean;
var
  LClass: THelpChatProviderClass;
  LProvider: IHelpChatProvider;
begin
  LClass := FindProviderClass(AName);
  Result := Assigned(LClass);
  if Result then
  begin
    // The answer belongs to the provider, so it is asked - on an instance
    // that is created for the question and freed with the interface. No
    // settings, no retriever: nothing of what it needs to answer this.
    LProvider := LClass.Create(nil, nil, nil);
    Result := LProvider.SupportsDocuments;
  end;
end;

{ THelpChatProviderBase }

constructor THelpChatProviderBase.Create(const ASettings: THelpChatSettings;
  const ARetriever: IHelpChatRetriever; const AActions: IHelpChatActionInvoker);
begin
  inherited Create;
  FSettings := ASettings;
  FRetriever := ARetriever;
  FActions := AActions;
end;

procedure THelpChatProviderBase.SetAttachments(const AValue: TArray<THelpChatAttachment>);
begin
  FAttachments := AValue;
end;

function THelpChatProviderBase.SupportsDocuments: Boolean;
begin
  Result := False;
end;

function THelpChatProviderBase.QuestionWithAttachments(const AQuestion: string): string;
var
  LLanguage: THelpChatLanguage;
begin
  if Assigned(FSettings) then
    LLanguage := FSettings.Language
  else
    LLanguage := hclAuto;
  Result := HelpChatQuestionWithText(AQuestion, FAttachments, LLanguage);
end;

function THelpChatProviderBase.UnreadDocumentsNotice: string;
begin
  if SupportsDocuments or not HelpChatHasBinary(FAttachments) then
    Result := ''
  else
    Result := Format(Msg(hcmAttachNotSupported), [GetName]);
end;

{ THelpChatToolCall }

class function THelpChatToolCall.Create(const AId, AName, AInputJson: string;
  const ASignature: string): THelpChatToolCall;
begin
  Result.Id := AId;
  Result.Name := AName;
  Result.InputJson := AInputJson;
  Result.Signature := ASignature;
end;

class function THelpChatProviderBase.BuildSystemPrompt(
  const AHistory: TArray<THelpChatMessage>; const AContext: THelpChatContext;
  const ASettings: THelpChatSettings; const ARetriever: IHelpChatRetriever): string;
var
  LLang: THelpChatLanguage;
  LSb: TStringBuilder;
  LPages: TArray<THelpChatDocPage>;
  LMax, I: Integer;
begin
  if Assigned(ASettings) then
    LLang := ASettings.Language
  else
    LLang := hclAuto;

  LSb := TStringBuilder.Create;
  try
    // The instruction to the model is English only (see the constants); the
    // configured UI language becomes the default reply language.
    if Assigned(ASettings) then
      LSb.Append(ASettings.ActiveModel.ResolveSystemPrompt)
    else
      LSb.Append(HELPCHAT_MODEL_DEF_SYSTEMPROMPT);
    LSb.Append(' ');
    LSb.Append(Format(HELPCHAT_MODEL_DEF_LANGUAGE_RULE, [HelpChatLanguageName(LLang)]));

    if not AContext.IsEmpty then
    begin
      LSb.Append(#10#10);
      LSb.Append(HelpChatMsgFmt(hcmScreenContext, [AContext.DisplayName, AContext.ScreenType], LLang));
    end;

    if Assigned(ASettings) then
      LMax := ASettings.ActiveModel.GroundingMaxPages
    else
      LMax := HELPCHAT_MODEL_DEF_GROUNDING;
    if (LMax > 0) and Assigned(ARetriever) and ARetriever.IsAvailable then
    begin
      LPages := ARetriever.Search(LastUserMessage(AHistory), AContext.SearchHint, LMax);
      if Length(LPages) > 0 then
      begin
        LSb.Append(#10#10);
        LSb.Append(HelpChatMsg(hcmRelevantDocs, LLang));
        for I := Low(LPages) to High(LPages) do
        begin
          // Title, summary, the passages around the matching terms, source link.
          LSb.Append(#10#10);
          LSb.Append(Format('## %s'#10'%s', [LPages[I].Title, LPages[I].Summary]));
          if (LPages[I].Excerpt <> '') and (LPages[I].Excerpt <> LPages[I].Summary) then
            LSb.Append(#10#10).Append(LPages[I].Excerpt);
          LSb.Append(#10).Append(Format('%s: %s', [HelpChatMsg(hcmSource, LLang), LPages[I].Url]));
        end;
      end;
    end;
    Result := LSb.ToString;
  finally
    LSb.Free;
  end;
end;

class function THelpChatProviderBase.ConfigurationIssue(
  const ASettings: THelpChatSettings): string;
begin
  // A provider that needs nothing but the question answers with nothing to say.
  Result := '';
end;

function THelpChatProviderBase.SupportsStreaming: Boolean;
begin
  Result := False;
end;

function THelpChatProviderBase.SupportsActions: Boolean;
begin
  Result := False;
end;

function THelpChatProviderBase.Msg(const AId: THelpChatMsgId): string;
begin
  if Assigned(FSettings) then
    Result := HelpChatMsg(AId, FSettings.Language)
  else
    Result := HelpChatMsg(AId);
end;

function THelpChatProviderBase.MsgFmt(const AId: THelpChatMsgId;
  const AArgs: array of const): string;
begin
  Result := Format(Msg(AId), AArgs);
end;

procedure THelpChatProviderBase.CheckCancelled(const ACancel: IHelpChatCancelToken);
begin
  if Assigned(ACancel) and ACancel.IsCancelled then
    raise EHelpChatCancelled.Create(Msg(hcmCancelled));
end;

class function THelpChatProviderBase.LastUserMessage(
  const AHistory: TArray<THelpChatMessage>): string;
var
  I: Integer;
begin
  Result := '';
  for I := High(AHistory) downto Low(AHistory) do
    if AHistory[I].Role = hcrUser then
      Exit(AHistory[I].Content);
end;

{ THelpChatProviderRegistry }

class constructor THelpChatProviderRegistry.Create;
begin
  FLock := TObject.Create;
  FProviders := TDictionary<string, THelpChatProviderClass>.Create;
end;

class destructor THelpChatProviderRegistry.Destroy;
begin
  FProviders.Free;
  FLock.Free;
end;

class procedure THelpChatProviderRegistry.RegisterProvider(const AName: string;
  const AClass: THelpChatProviderClass);
begin
  TMonitor.Enter(FLock);
  try
    FProviders.AddOrSetValue(AName.Trim.ToLower, AClass);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class procedure THelpChatProviderRegistry.UnregisterProvider(const AName: string);
begin
  TMonitor.Enter(FLock);
  try
    FProviders.Remove(AName.Trim.ToLower);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function THelpChatProviderRegistry.IsRegistered(const AName: string): Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FProviders.ContainsKey(AName.Trim.ToLower);
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function THelpChatProviderRegistry.FindProviderClass(
  const AName: string): THelpChatProviderClass;
begin
  TMonitor.Enter(FLock);
  try
    if not FProviders.TryGetValue(AName.Trim.ToLower, Result) then
      Result := nil;
  finally
    TMonitor.Exit(FLock);
  end;
end;

class function THelpChatProviderRegistry.CreateProvider(const AName: string;
  const ASettings: THelpChatSettings; const ARetriever: IHelpChatRetriever;
  const AActions: IHelpChatActionInvoker): IHelpChatProvider;
var
  LClass: THelpChatProviderClass;
  LUnavailable: THelpChatUnavailableProvider;
begin
  if Trim(AName) = '' then
  begin
    LClass := FindProviderClass(HELPCHAT_PROVIDER_STUB);
    if LClass = nil then
      LClass := THelpChatStubProvider;
  end
  else
    LClass := FindProviderClass(AName);
  if LClass = nil then
  begin
    LUnavailable := THelpChatUnavailableProvider.Create(ASettings, ARetriever, AActions);
    LUnavailable.RequestedName := Trim(AName);
    Exit(LUnavailable);
  end;
  // Instantiated outside the lock: a constructor may do real work.
  Result := LClass.Create(ASettings, ARetriever, AActions);
end;

class function THelpChatProviderRegistry.ProviderNames: TArray<string>;
begin
  TMonitor.Enter(FLock);
  try
    Result := FProviders.Keys.ToArray;
  finally
    TMonitor.Exit(FLock);
  end;
  TArray.Sort<string>(Result);
end;

{ THelpChatStubProvider }

function THelpChatStubProvider.GetName: string;
begin
  Result := HELPCHAT_PROVIDER_STUB;
end;

function THelpChatStubProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  CheckCancelled(ACancel);
  Result := Msg(hcmStubReply);
end;

{ THelpChatUnavailableProvider }

function THelpChatUnavailableProvider.GetName: string;
begin
  Result := FRequestedName;
end;

function THelpChatUnavailableProvider.Generate(const AHistory: TArray<THelpChatMessage>;
  const AContext: THelpChatContext; const AOnToken: THelpChatTokenProc;
  const ACancel: IHelpChatCancelToken): string;
begin
  CheckCancelled(ACancel);
  raise EHelpChatConfigError.Create(MsgFmt(hcmProviderNotAvailable,
    [FRequestedName, string.Join(', ', THelpChatProviderRegistry.ProviderNames)]));
end;

initialization
  THelpChatProviderRegistry.RegisterProvider(HELPCHAT_PROVIDER_STUB, THelpChatStubProvider);

finalization
  THelpChatProviderRegistry.UnregisterProvider(HELPCHAT_PROVIDER_STUB);

end.
