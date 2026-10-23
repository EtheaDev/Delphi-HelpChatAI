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
///  Localized strings of the HelpChat engine (English and Italian), selectable
///  at runtime. Two channels, kept distinct on purpose: the Pascal side reads
///  them through <see cref="HelpChatMsg" />; the JavaScript side of the panel
///  receives the UI labels as a dictionary produced by the transport layer.
///  Strings are <c>resourcestring</c>s so the classic resource-DLL translation
///  path also works for further languages.
/// </summary>
unit HelpChatAI.Messages;

{$I HelpChatAI.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>UI language of the chat. <c>hclAuto</c> follows the OS user locale
  /// and falls back to English.</summary>
  THelpChatLanguage = (hclAuto, hclEnglish, hclItalian);

  /// <summary>Identifiers of every localized string used by the engine.</summary>
  THelpChatMsgId = (
    // Engine / providers
    hcmGreeting,
    hcmStubReply,
    hcmIndexUnavailable,
    hcmNoPageFound,
    hcmReadMore,
    hcmSeeAlso,
    hcmClaudeNotConfigured,
    /// <summary>A provider that needs a key and has none: %0:s is its name,
    /// %1:s the settings section, %2:s the environment variable, %3:s and %4:s
    /// the two folders where a helpchatai.json would be read.</summary>
    hcmProviderKeyMissing,
    /// <summary>The configured provider is not linked into the application:
    /// %s is its name, %s the registered ones.</summary>
    hcmProviderNotAvailable,
    hcmProviderError,
    hcmApiError,
    hcmEmptyReply,
    hcmCancelled,
    hcmScreenContext,
    hcmRelevantDocs,
    hcmSource,
    hcmContextQuestion,
    // Panel UI labels (injected into the page by the transport)
    hcmUiTitle,
    hcmUiHelp,
    hcmUiClear,
    hcmUiClose,
    hcmUiPlaceholder,
    hcmUiSend,
    hcmUiStop,
    hcmUiRetry,
    hcmUiSendError,
    /// <summary>Button of the documentation view that returns to the chat.</summary>
    hcmUiBack,
    /// <summary>Microphone button, left of the question box (VCL on Windows).</summary>
    hcmUiMic,
    /// <summary>Said in the conversation when dictation cannot start.</summary>
    hcmVoiceUnavailable,
    /// <summary>Shown before opening the Windows page of the speech consent.</summary>
    hcmVoiceConsentNeeded,
    /// <summary>A documentation page that cannot be shown: %s is the page.</summary>
    hcmDocNotFound,
    /// <summary>Asked before the assistant runs an action that changes
    /// something: %s is the action, %s its parameters.</summary>
    hcmActionConfirm);

/// <summary>Returns the string <c>AId</c> in <c>ALanguage</c> (<c>hclAuto</c> =
/// <see cref="HelpChatDefaultLanguage" />, resolved against the OS locale).</summary>
function HelpChatMsg(const AId: THelpChatMsgId;
  const ALanguage: THelpChatLanguage = hclAuto): string;

/// <summary>Like <see cref="HelpChatMsg" /> followed by <c>Format</c>.</summary>
function HelpChatMsgFmt(const AId: THelpChatMsgId; const AArgs: array of const;
  const ALanguage: THelpChatLanguage = hclAuto): string;

/// <summary>Resolves <c>hclAuto</c> to a concrete language using the OS user
/// locale (Italian when the primary language is Italian, English otherwise).</summary>
function HelpChatResolveLanguage(const ALanguage: THelpChatLanguage): THelpChatLanguage;

/// <summary>Two-letter ISO code of a resolved language ("en", "it").</summary>
function HelpChatLanguageCode(const ALanguage: THelpChatLanguage): string;

/// <summary>English name of a resolved language ("English", "Italian"), the form
/// used when instructing the model.</summary>
function HelpChatLanguageName(const ALanguage: THelpChatLanguage): string;

var
  /// <summary>Language used when a caller passes <c>hclAuto</c>. Default
  /// <c>hclAuto</c> (OS locale); the component sets it from its Language property.</summary>
  HelpChatDefaultLanguage: THelpChatLanguage = hclAuto;

implementation

resourcestring
  // ---- English -------------------------------------------------------------
  SEnGreeting = 'Hi! Ask me anything about how to use the application.';
  SEnStubReply = 'Sorry, I have no elements to help you on this topic at the moment.';
  SEnIndexUnavailable = 'The help index is not available. See the [documentation](%s).';
  SEnNoPageFound = 'I could not find a specific page for your question. Browse the [documentation](%s).';
  SEnReadMore = 'Read more';
  SEnSeeAlso = 'See also:';
  SEnClaudeNotConfigured = 'The Claude provider is not configured: put the API key in ' +
    'Settings.Claude.ApiKey, in the ANTHROPIC_API_KEY environment variable, or in a helpchatai.json ' +
    'file as { "Claude": { "ApiKey": "..." } } in %s (shared by every HelpChat application) or in %s.';
  SEnProviderKeyMissing = 'The "%0:s" provider has no API key: put it in Settings.%1:s.ApiKey, ' +
    'in the %2:s environment variable, or in a helpchatai.json file as ' +
    '{ "%1:s": { "ApiKey": "..." } } in %3:s (shared by every HelpChat application) or in %4:s.';
  SEnProviderNotAvailable = 'The "%s" provider is not available in this application: its unit ' +
    'registers it when linked, so add it to the uses (HelpChatAI.Provider.Claude for "claude", ' +
    'HelpChatAI.Provider.DocSearch for "docsearch"). Available providers: %s.';
  SEnProviderError = 'The AI provider returned an error.';
  SEnApiError = 'Claude API error (HTTP %d %s).';
  SEnEmptyReply = 'The assistant did not return any content.';
  SEnCancelled = 'The request was cancelled.';
  SEnScreenContext = 'The user is currently on the "%s" screen (type: %s).';
  SEnRelevantDocs = 'Relevant documentation excerpts:';
  SEnSource = 'Source';
  SEnContextQuestion = 'How do I use the "%s" screen?';
  SEnUiTitle = 'Assistant';
  SEnUiHelp = 'Help';
  SEnUiClear = 'Clear conversation';
  SEnUiClose = 'Close';
  SEnUiPlaceholder = 'Ask a question about the application...';
  SEnUiSend = 'Send';
  SEnUiStop = 'Stop';
  SEnUiRetry = 'Retry';
  SEnUiSendError = 'The message could not be sent.';
  SEnUiBack = 'Back to the chat';
  SEnUiMic = 'Dictate the question';
  SEnVoiceConsentNeeded = 'Dictation goes through the online speech recognition of Windows, which is not enabled on this computer.' + sLineBreak + sLineBreak + 'The Windows settings will now open: turn on Online speech recognition, then press the microphone again.';
  SEnVoiceUnavailable = 'Speech recognition is not available on this computer. Check Settings, Privacy, Speech, and that the language pack is installed.';
  SEnDocNotFound = 'The page "%s" is not available.';
  SEnActionConfirm = 'The assistant wants to run "%s" (%s).' + sLineBreak + 'Do you allow it?';

  // ---- Italian -------------------------------------------------------------
  SItGreeting = 'Ciao! Chiedimi qualsiasi cosa su come usare l''applicazione.';
  SItStubReply = 'Mi dispiace, al momento non ho elementi per aiutarti su questo argomento.';
  SItIndexUnavailable = 'L''indice della guida non è disponibile. Consulta la [documentazione](%s).';
  SItNoPageFound = 'Non ho trovato una pagina specifica per la tua domanda. Consulta la [documentazione](%s).';
  SItReadMore = 'Leggi tutto';
  SItSeeAlso = 'Vedi anche:';
  SItClaudeNotConfigured = 'Il provider Claude non è configurato: metti la chiave API in ' +
    'Settings.Claude.ApiKey, nella variabile d''ambiente ANTHROPIC_API_KEY, oppure in un file helpchatai.json ' +
    'come { "Claude": { "ApiKey": "..." } } in %s (condiviso da tutte le applicazioni HelpChat) o in %s.';
  SItProviderKeyMissing = 'Il provider "%0:s" non ha una chiave API: mettila in Settings.%1:s.ApiKey, ' +
    'nella variabile d''ambiente %2:s, oppure in un file helpchatai.json come ' +
    '{ "%1:s": { "ApiKey": "..." } } in %3:s (condiviso da tutte le applicazioni HelpChat) o in %4:s.';
  SItProviderNotAvailable = 'Il provider "%s" non è disponibile in questa applicazione: la sua unit ' +
    'lo registra quando è linkata, quindi va aggiunta alla uses (HelpChatAI.Provider.Claude per "claude", ' +
    'HelpChatAI.Provider.DocSearch per "docsearch"). Provider disponibili: %s.';
  SItProviderError = 'Il provider AI ha restituito un errore.';
  SItApiError = 'Errore API Claude (HTTP %d %s).';
  SItEmptyReply = 'L''assistente non ha restituito alcun contenuto.';
  SItCancelled = 'La richiesta è stata annullata.';
  SItScreenContext = 'L''utente si trova nella schermata "%s" (tipo: %s).';
  SItRelevantDocs = 'Estratti di documentazione pertinenti:';
  SItSource = 'Fonte';
  SItContextQuestion = 'Come si usa la schermata "%s"?';
  SItUiTitle = 'Assistente';
  SItUiHelp = 'Aiuto';
  SItUiClear = 'Azzera conversazione';
  SItUiClose = 'Chiudi';
  SItUiPlaceholder = 'Fai una domanda sull''applicazione...';
  SItUiSend = 'Invia';
  SItUiStop = 'Interrompi';
  SItUiRetry = 'Riprova';
  SItUiSendError = 'Non è stato possibile inviare il messaggio.';
  SItUiBack = 'Torna alla chat';
  SItUiMic = 'Detta la domanda';
  SItVoiceConsentNeeded = 'La dettatura passa dal riconoscimento vocale online di Windows, che su questo computer non è abilitato.' + sLineBreak + sLineBreak + 'Verrà aperta la pagina delle impostazioni di Windows: attiva Riconoscimento vocale online, poi premi di nuovo il microfono.';
  SItVoiceUnavailable = 'Il riconoscimento vocale non è disponibile su questo computer. Controlla Impostazioni, Privacy, Riconoscimento vocale, e che il pacchetto della lingua sia installato.';
  SItDocNotFound = 'La pagina "%s" non è disponibile.';
  SItActionConfirm = 'L''assistente vuole eseguire "%s" (%s).' + sLineBreak + 'Consenti?';

const
  LANG_ITALIAN_PRIMARY = $10;

function HelpChatResolveLanguage(const ALanguage: THelpChatLanguage): THelpChatLanguage;
begin
  Result := ALanguage;
  if Result = hclAuto then
    Result := HelpChatDefaultLanguage;
  if Result = hclAuto then
  begin
    if SysLocale.PriLangID = LANG_ITALIAN_PRIMARY then
      Result := hclItalian
    else
      Result := hclEnglish;
  end;
end;

function HelpChatLanguageCode(const ALanguage: THelpChatLanguage): string;
begin
  if HelpChatResolveLanguage(ALanguage) = hclItalian then
    Result := 'it'
  else
    Result := 'en';
end;

function HelpChatLanguageName(const ALanguage: THelpChatLanguage): string;
begin
  if HelpChatResolveLanguage(ALanguage) = hclItalian then
    Result := 'Italian'
  else
    Result := 'English';
end;

function EnglishMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SEnGreeting;
    hcmStubReply: Result := SEnStubReply;
    hcmIndexUnavailable: Result := SEnIndexUnavailable;
    hcmNoPageFound: Result := SEnNoPageFound;
    hcmReadMore: Result := SEnReadMore;
    hcmSeeAlso: Result := SEnSeeAlso;
    hcmClaudeNotConfigured: Result := SEnClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SEnProviderKeyMissing;
    hcmProviderNotAvailable: Result := SEnProviderNotAvailable;
    hcmProviderError: Result := SEnProviderError;
    hcmApiError: Result := SEnApiError;
    hcmEmptyReply: Result := SEnEmptyReply;
    hcmCancelled: Result := SEnCancelled;
    hcmScreenContext: Result := SEnScreenContext;
    hcmRelevantDocs: Result := SEnRelevantDocs;
    hcmSource: Result := SEnSource;
    hcmContextQuestion: Result := SEnContextQuestion;
    hcmUiTitle: Result := SEnUiTitle;
    hcmUiHelp: Result := SEnUiHelp;
    hcmUiClear: Result := SEnUiClear;
    hcmUiClose: Result := SEnUiClose;
    hcmUiPlaceholder: Result := SEnUiPlaceholder;
    hcmUiSend: Result := SEnUiSend;
    hcmUiStop: Result := SEnUiStop;
    hcmUiRetry: Result := SEnUiRetry;
    hcmUiSendError: Result := SEnUiSendError;
    hcmUiBack: Result := SEnUiBack;
    hcmUiMic: Result := SEnUiMic;
    hcmVoiceUnavailable: Result := SEnVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SEnVoiceConsentNeeded;
    hcmDocNotFound: Result := SEnDocNotFound;
    hcmActionConfirm: Result := SEnActionConfirm;
  else
    Result := '';
  end;
end;

function ItalianMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SItGreeting;
    hcmStubReply: Result := SItStubReply;
    hcmIndexUnavailable: Result := SItIndexUnavailable;
    hcmNoPageFound: Result := SItNoPageFound;
    hcmReadMore: Result := SItReadMore;
    hcmSeeAlso: Result := SItSeeAlso;
    hcmClaudeNotConfigured: Result := SItClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SItProviderKeyMissing;
    hcmProviderNotAvailable: Result := SItProviderNotAvailable;
    hcmProviderError: Result := SItProviderError;
    hcmApiError: Result := SItApiError;
    hcmEmptyReply: Result := SItEmptyReply;
    hcmCancelled: Result := SItCancelled;
    hcmScreenContext: Result := SItScreenContext;
    hcmRelevantDocs: Result := SItRelevantDocs;
    hcmSource: Result := SItSource;
    hcmContextQuestion: Result := SItContextQuestion;
    hcmUiTitle: Result := SItUiTitle;
    hcmUiHelp: Result := SItUiHelp;
    hcmUiClear: Result := SItUiClear;
    hcmUiClose: Result := SItUiClose;
    hcmUiPlaceholder: Result := SItUiPlaceholder;
    hcmUiSend: Result := SItUiSend;
    hcmUiStop: Result := SItUiStop;
    hcmUiRetry: Result := SItUiRetry;
    hcmUiSendError: Result := SItUiSendError;
    hcmUiBack: Result := SItUiBack;
    hcmUiMic: Result := SItUiMic;
    hcmVoiceUnavailable: Result := SItVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SItVoiceConsentNeeded;
    hcmDocNotFound: Result := SItDocNotFound;
    hcmActionConfirm: Result := SItActionConfirm;
  else
    Result := '';
  end;
end;

function HelpChatMsg(const AId: THelpChatMsgId; const ALanguage: THelpChatLanguage): string;
begin
  if HelpChatResolveLanguage(ALanguage) = hclItalian then
    Result := ItalianMsg(AId)
  else
    Result := EnglishMsg(AId);
end;

function HelpChatMsgFmt(const AId: THelpChatMsgId; const AArgs: array of const;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := Format(HelpChatMsg(AId, ALanguage), AArgs);
end;

end.
