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
///  Localized strings of the HelpChat engine (English, Italian, Spanish,
///  French, German and Portuguese), selectable at runtime. Two channels, kept distinct on purpose: the Pascal side reads
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
  /// <summary>Language of the chat: the strings of the panel and of the
  /// engine, and the language the model is told to reply in. <c>hclAuto</c>
  /// follows the OS user locale and falls back to English. New languages go
  /// at the end: a DFM stores the identifier, a configuration file the code.</summary>
  THelpChatLanguage = (hclAuto, hclEnglish, hclItalian, hclSpanish, hclFrench,
    hclGerman, hclPortuguese);
  /// <summary>A choice of languages (<c>hclAuto</c> is never one of them).</summary>
  THelpChatLanguages = set of THelpChatLanguage;

const
  /// <summary>Every language the strings are translated into.</summary>
  HELPCHAT_ALL_LANGUAGES = [hclEnglish, hclItalian, hclSpanish, hclFrench, hclGerman,
    hclPortuguese];

type

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
    hcmActionConfirm,
    /// <summary>Label over the parameter values in that question: they were
    /// written by the model, and the user is told so.</summary>
    hcmActionValues,
    /// <summary>Main instruction of the confirmation dialog, with the name
    /// of the action.</summary>
    hcmActionConfirmTitle,
    /// <summary>Footer of the confirmation dialog, under the values.</summary>
    hcmActionValuesFooter,
    /// <summary>Paper-clip button, left of the question box.</summary>
    hcmUiAttach,
    /// <summary>Title of the button that takes an attachment away.</summary>
    hcmUiAttachRemove,
    /// <summary>Tooltip of the assistant badge when there is a list to pick from.</summary>
    hcmUiChangeAssistant,
    /// <summary>Tooltip of the flag, when more than one language can be chosen.</summary>
    hcmUiChangeLanguage,
    // The slash commands of the panel (HelpChatAI.Commands): one description
    // each, in the order of THelpChatCommand, then what their answers say.
    hcmCmdHelp,
    hcmCmdWho,
    hcmCmdUse,
    hcmCmdLang,
    hcmCmdRetry,
    hcmCmdSearch,
    hcmCmdDoc,
    hcmCmdPages,
    hcmCmdContext,
    hcmCmdActions,
    hcmCmdCheck,
    hcmCmdStats,
    hcmCmdClear,
    hcmCmdPdf,
    hcmCmdCopy,
    hcmCmdAttach,
    hcmCmdPrompt,
    hcmCmdRun,
    /// <summary>%s is the word typed after the slash.</summary>
    hcmCmdUnknown,
    hcmCmdProvider,
    hcmCmdEndpoint,
    hcmCmdNoIndex,
    hcmCmdNoQuestion,
    /// <summary>%s is what was searched.</summary>
    hcmCmdNoResults,
    hcmCmdNoContext,
    hcmCmdNoActions,
    hcmCmdRunUsage,
    hcmCmdNoEngine,
    /// <summary>%s is the name asked for.</summary>
    hcmCmdNoAssistant,
    /// <summary>/lang named a language that is not offered: %s is what was typed.</summary>
    hcmCmdNoLanguage,
    /// <summary>%s twice: time to the first token, time to the end.</summary>
    hcmCmdStatsLine,
    hcmCmdNoStats,
    hcmCmdDocUsage,
    hcmCmdUseUsage,
    hcmCmdNoAnswer,
    /// <summary>The first line of the answer of a command ("Available actions"):
    /// the page adds " (/name):" after it.</summary>
    hcmCmdTitleHelp,
    hcmCmdTitleWho,
    hcmCmdTitleUse,
    hcmCmdTitleLang,
    hcmCmdTitleSearch,
    hcmCmdTitlePages,
    hcmCmdTitleContext,
    hcmCmdTitleActions,
    hcmCmdTitleCheck,
    hcmCmdTitleStats,
    hcmCmdTitlePrompt,
    hcmCmdTitleRun,
    /// <summary>A file of a type no model reads: %s is the extension,
    /// %s the list of the accepted ones.</summary>
    hcmAttachTypeRefused,
    /// <summary>%s is the file name, %s the largest size allowed.</summary>
    hcmAttachTooLarge,
    /// <summary>%d is the number of attachments allowed at a time.</summary>
    hcmAttachTooMany,
    /// <summary>%s is the largest total size of the attachments.</summary>
    hcmAttachTooMuch,
    /// <summary>%s is the name of a file with nothing in it.</summary>
    hcmAttachEmpty,
    /// <summary>The attachment did not arrive (a transfer that failed).</summary>
    hcmAttachFailed,
    /// <summary>Said in the conversation when the configured provider cannot
    /// be given documents: %s is its name.</summary>
    hcmAttachNotSupported,
    /// <summary>Heading of the attached documents in the system prompt.</summary>
    hcmAttachedDocuments,
    /// <summary>What a text attachment is introduced with: %s is its name.</summary>
    hcmAttachedTextFile,
    /// <summary>Button that saves an answer as PDF.</summary>
    hcmUiPdfAnswer,
    /// <summary>Button that saves the whole conversation as PDF.</summary>
    hcmUiPdfConversation,
    /// <summary>Title of the button that copies one answer.</summary>
    hcmUiCopyAnswer,
    /// <summary>Title of the button that copies the whole conversation.</summary>
    hcmUiCopyConversation,
    /// <summary>Title of the button that copies a documentation page.</summary>
    hcmUiCopyPage,
    /// <summary>Said on the button itself once the clipboard has it.</summary>
    hcmUiCopied,
    /// <summary>Said when the browser would not take it.</summary>
    hcmUiCopyFailed,
    /// <summary>Button that saves the documentation page being read.</summary>
    hcmUiPdfPage,
    /// <summary>Title of a document made of one answer.</summary>
    hcmPdfAnswerTitle,
    /// <summary>Title of a document made of the whole conversation.</summary>
    hcmPdfConversationTitle,
    /// <summary>Who asked, above a question in the printed conversation.</summary>
    hcmPdfUser,
    /// <summary>Who answered, above a reply in the printed conversation.</summary>
    hcmPdfAssistant,
    /// <summary>Filter of the save dialog.</summary>
    hcmPdfFilter,
    /// <summary>Asked once the file is written: %s is its name.</summary>
    hcmPdfOpen,
    /// <summary>The PDF was not written: %s is the reason.</summary>
    hcmPdfFailed,
    /// <summary>The PDF was written, but the runtime would not take the
    /// header and the footer: %s is the name of the file.</summary>
    hcmPdfNoBands,
    /// <summary>Said in the conversation when there is nothing to print.</summary>
    hcmPdfNothing,
    /// <summary>Said when nobody on this side can write a PDF: a remote
    /// engine builds the document where there is no screen to save it
    /// from.</summary>
    hcmPdfUnavailable,
    /// <summary>What the assistant is told after it asked for a document:
    /// the work is done, the user is choosing where to put it.</summary>
    hcmPdfHandedOver);

/// <summary>Returns the string <c>AId</c> in <c>ALanguage</c> (<c>hclAuto</c> =
/// <see cref="HelpChatDefaultLanguage" />, resolved against the OS locale).</summary>
function HelpChatMsg(const AId: THelpChatMsgId;
  const ALanguage: THelpChatLanguage = hclAuto): string;

/// <summary>Like <see cref="HelpChatMsg" /> followed by <c>Format</c>.</summary>
function HelpChatMsgFmt(const AId: THelpChatMsgId; const AArgs: array of const;
  const ALanguage: THelpChatLanguage = hclAuto): string;

/// <summary>Resolves <c>hclAuto</c> to a concrete language:
/// <see cref="HelpChatDefaultLanguage" /> when that is set, the OS user
/// locale otherwise.</summary>
function HelpChatResolveLanguage(const ALanguage: THelpChatLanguage): THelpChatLanguage;

/// <summary>The language of the OS user locale, when it is one of ours;
/// English otherwise.</summary>
function HelpChatSystemLanguage: THelpChatLanguage;

/// <summary>Two-letter ISO code of a resolved language ("en", "it", "es"...).</summary>
function HelpChatLanguageCode(const ALanguage: THelpChatLanguage): string;

/// <summary>English name of a resolved language ("English", "Italian"...), the
/// form used when instructing the model.</summary>
function HelpChatLanguageName(const ALanguage: THelpChatLanguage): string;

/// <summary>The name of a resolved language in that language ("Italiano",
/// "Español"...): what the menu of the panel shows, so that a user who
/// does not read the current language still finds their own.</summary>
function HelpChatLanguageNativeName(const ALanguage: THelpChatLanguage): string;

/// <summary>The language of an ISO code, an English name or a native name
/// ("es", "Spanish", "Español"), case-insensitive; "auto" is <c>hclAuto</c>.
/// False when the value is none of them.</summary>
function HelpChatLanguageFromCode(const AValue: string;
  out ALanguage: THelpChatLanguage): Boolean;

/// <summary>The languages of a set, in the order of the enumeration.</summary>
function HelpChatLanguageList(const ALanguages: THelpChatLanguages): TArray<THelpChatLanguage>;

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
  SEnUiChangeAssistant = 'Change assistant';
  SEnUiChangeLanguage = 'Change language';
  SEnCmdHelp = 'The commands you can type';
  SEnCmdWho = 'Who is answering: assistant, model, provider';
  SEnCmdUse = 'Switch to the named assistant: /use Gemini';
  SEnCmdLang = 'Switch the language of the chat: /lang it';
  SEnCmdRetry = 'Ask the last question again, to another assistant if named';
  SEnCmdSearch = 'The documentation pages that would ground the answer';
  SEnCmdDoc = 'Open a page of the documentation: /doc Leads.md';
  SEnCmdPages = 'The pages of the documentation index';
  SEnCmdContext = 'The screen the assistant thinks you are on';
  SEnCmdActions = 'What the assistant can do in this application';
  SEnCmdCheck = 'The configuration check of the assistant';
  SEnCmdStats = 'Timing of the last answer';
  SEnCmdClear = 'Clear the conversation';
  SEnCmdPdf = 'Save the conversation as PDF';
  SEnCmdCopy = 'Copy the last answer';
  SEnCmdAttach = 'Attach a file';
  SEnCmdPrompt = 'The instructions and excerpts the last question went with';
  SEnCmdRun = 'Run an action by hand: /run open_screen name=Leads';
  SEnCmdUnknown = 'Unknown command %s. Type /help for the list.';
  SEnCmdProvider = 'Provider';
  SEnCmdEndpoint = 'Endpoint';
  SEnCmdNoIndex = 'There is no documentation index.';
  SEnCmdNoQuestion = 'No question yet.';
  SEnCmdNoResults = 'Nothing found for "%s".';
  SEnCmdNoContext = 'No screen context was sent.';
  SEnCmdNoActions = 'This application registered no actions.';
  SEnCmdRunUsage = 'Usage: /run action name=value name2="a value with spaces"';
  SEnCmdNoEngine = 'The engine is not running.';
  SEnCmdNoAssistant = 'No assistant named "%s".';
  SEnCmdNoLanguage = 'No language "%s" among those this chat offers.';
  SEnCmdStatsLine = 'Last answer: first token after %s, complete after %s.';
  SEnCmdNoStats = 'No answer yet.';
  SEnCmdDocUsage = 'Usage: /doc page';
  SEnCmdUseUsage = 'Usage: /use assistant';
  SEnCmdNoAnswer = 'No answer to copy.';
  SEnCmdTitleHelp = 'Available commands';
  SEnCmdTitleWho = 'Assistant in use';
  SEnCmdTitleUse = 'Assistant changed';
  SEnCmdTitleLang = 'Languages of the chat';
  SEnCmdTitleSearch = 'Documentation pages for "%s"';
  SEnCmdTitlePages = 'Documentation pages';
  SEnCmdTitleContext = 'Screen context';
  SEnCmdTitleActions = 'Available actions';
  SEnCmdTitleCheck = 'Configuration check';
  SEnCmdTitleStats = 'Timing of the last answer';
  SEnCmdTitlePrompt = 'System prompt of the last question';
  SEnCmdTitleRun = 'Action run';
  SEnUiMic = 'Dictate the question';
  SEnVoiceConsentNeeded = 'Dictation goes through the online speech recognition of Windows, which is not enabled on this computer.' + sLineBreak + sLineBreak + 'The Windows settings will now open: turn on Online speech recognition, then press the microphone again.';
  SEnVoiceUnavailable = 'Speech recognition is not available on this computer. Check Settings, Privacy, Speech, and that the language pack is installed.';
  SEnDocNotFound = 'The page "%s" is not available.';
  SEnActionConfirm = 'The assistant wants to run "%s": %s' + sLineBreak + sLineBreak +
    '%s' + 'Do you allow it?';
  SEnActionValues = 'Values written by the assistant:';
  SEnActionConfirmTitle = 'The assistant wants to run "%s"';
  SEnActionValuesFooter = 'The values above were written by the assistant, not by you: ' +
    'check them before allowing.';
  SEnUiAttach = 'Attach a document';
  SEnUiAttachRemove = 'Remove this attachment';
  SEnAttachTypeRefused = 'A %s file is not one the assistant can read. Accepted: %s.';
  SEnAttachTooLarge = '"%s" is too large: an attachment may not exceed %s.';
  SEnAttachTooMany = 'No more than %d attachments at a time.';
  SEnAttachTooMuch = 'The attachments of one conversation may not exceed %s in total.';
  SEnAttachEmpty = 'There is nothing in "%s".';
  SEnAttachFailed = 'The document could not be attached.';
  SEnAttachNotSupported = 'The attached documents were not sent: the %s provider cannot read them.';
  SEnUiPdfAnswer = 'Save this answer as PDF';
  SEnUiPdfConversation = 'Save the conversation as PDF';
  SEnUiCopyAnswer = 'Copy this answer';
  SEnUiCopyConversation = 'Copy the conversation';
  SEnUiCopyPage = 'Copy this page';
  SEnUiCopied = 'Copied';
  SEnUiCopyFailed = 'The text could not be copied to the clipboard.';
  SEnUiPdfPage = 'Save this page as PDF';
  SEnPdfAnswerTitle = 'Answer';
  SEnPdfConversationTitle = 'Conversation';
  SEnPdfUser = 'Question';
  SEnPdfAssistant = 'Answer';
  SEnPdfFilter = 'PDF document (*.pdf)|*.pdf';
  SEnPdfOpen = 'The PDF has been saved as "%s". Open it now?';
  SEnPdfFailed = 'The PDF could not be created: %s';
  SEnPdfNoBands = '"%s" has been saved, but this version of the browser engine ' +
    'would not print the header and the footer of the document.';
  SEnPdfNothing = 'There is nothing to save yet.';
  SEnPdfUnavailable = 'Saving as PDF is not available in this application.';
  SEnPdfHandedOver = 'The document is ready: the user is choosing where to save it.';
  SEnAttachedDocuments = 'Documents the user attached to the question';
  SEnAttachedTextFile = 'Content of the attached file "%s"';

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
  SItUiChangeAssistant = 'Cambia assistente';
  SItUiChangeLanguage = 'Cambia lingua';
  SItCmdHelp = 'I comandi che puoi scrivere';
  SItCmdWho = 'Chi sta rispondendo: assistente, modello, provider';
  SItCmdUse = 'Passa all''assistente indicato: /use Gemini';
  SItCmdLang = 'Cambia la lingua della chat: /lang en';
  SItCmdRetry = 'Ripete l''ultima domanda, a un altro assistente se indicato';
  SItCmdSearch = 'Le pagine della documentazione su cui si baserebbe la risposta';
  SItCmdDoc = 'Apre una pagina della documentazione: /doc Leads.md';
  SItCmdPages = 'Le pagine dell''indice della documentazione';
  SItCmdContext = 'La schermata in cui l''assistente pensa che tu sia';
  SItCmdActions = 'Cosa l''assistente può fare in questa applicazione';
  SItCmdCheck = 'Il controllo della configurazione dell''assistente';
  SItCmdStats = 'I tempi dell''ultima risposta';
  SItCmdClear = 'Azzera la conversazione';
  SItCmdPdf = 'Salva la conversazione in PDF';
  SItCmdCopy = 'Copia l''ultima risposta';
  SItCmdAttach = 'Allega un file';
  SItCmdPrompt = 'Le istruzioni e gli estratti con cui è partita l''ultima domanda';
  SItCmdRun = 'Esegue un''azione a mano: /run open_screen name=Leads';
  SItCmdUnknown = 'Comando sconosciuto %s. Scrivi /help per l''elenco.';
  SItCmdProvider = 'Provider';
  SItCmdEndpoint = 'Endpoint';
  SItCmdNoIndex = 'Non c''è un indice della documentazione.';
  SItCmdNoQuestion = 'Nessuna domanda ancora.';
  SItCmdNoResults = 'Niente trovato per "%s".';
  SItCmdNoContext = 'Nessun contesto di schermata è stato inviato.';
  SItCmdNoActions = 'Questa applicazione non ha registrato azioni.';
  SItCmdRunUsage = 'Uso: /run azione nome=valore nome2="un valore con spazi"';
  SItCmdNoEngine = 'Il motore non è in esecuzione.';
  SItCmdNoAssistant = 'Nessun assistente di nome "%s".';
  SItCmdNoLanguage = 'Nessuna lingua "%s" tra quelle offerte da questa chat.';
  SItCmdStatsLine = 'Ultima risposta: primo token dopo %s, completa dopo %s.';
  SItCmdNoStats = 'Nessuna risposta ancora.';
  SItCmdDocUsage = 'Uso: /doc pagina';
  SItCmdUseUsage = 'Uso: /use assistente';
  SItCmdNoAnswer = 'Nessuna risposta da copiare.';
  SItCmdTitleHelp = 'Comandi disponibili';
  SItCmdTitleWho = 'Assistente in uso';
  SItCmdTitleUse = 'Assistente cambiato';
  SItCmdTitleLang = 'Lingue della chat';
  SItCmdTitleSearch = 'Pagine della documentazione per "%s"';
  SItCmdTitlePages = 'Pagine della documentazione';
  SItCmdTitleContext = 'Contesto della schermata';
  SItCmdTitleActions = 'Azioni disponibili';
  SItCmdTitleCheck = 'Controllo della configurazione';
  SItCmdTitleStats = 'Tempi dellultima risposta';
  SItCmdTitlePrompt = 'Prompt di sistema dellultima domanda';
  SItCmdTitleRun = 'Azione eseguita';
  SItUiMic = 'Detta la domanda';
  SItVoiceConsentNeeded = 'La dettatura passa dal riconoscimento vocale online di Windows, che su questo computer non è abilitato.' + sLineBreak + sLineBreak + 'Verrà aperta la pagina delle impostazioni di Windows: attiva Riconoscimento vocale online, poi premi di nuovo il microfono.';
  SItVoiceUnavailable = 'Il riconoscimento vocale non è disponibile su questo computer. Controlla Impostazioni, Privacy, Riconoscimento vocale, e che il pacchetto della lingua sia installato.';
  SItDocNotFound = 'La pagina "%s" non è disponibile.';
  SItActionConfirm = 'L''assistente vuole eseguire "%s": %s' + sLineBreak + sLineBreak +
    '%s' + 'Consenti?';
  SItActionValues = 'Valori scritti dall''assistente:';
  SItActionConfirmTitle = 'L''assistente vuole eseguire "%s"';
  SItActionValuesFooter = 'I valori qui sopra li ha scritti l''assistente, non tu: ' +
    'controllali prima di consentire.';
  SItUiAttach = 'Allega un documento';
  SItUiAttachRemove = 'Togli questo allegato';
  SItAttachTypeRefused = 'Un file %s non è fra quelli che l''assistente può leggere. Sono accettati: %s.';
  SItAttachTooLarge = '"%s" è troppo grande: un allegato non può superare %s.';
  SItAttachTooMany = 'Non più di %d allegati per volta.';
  SItAttachTooMuch = 'Gli allegati di una conversazione non possono superare %s in tutto.';
  SItAttachEmpty = 'Il file "%s" è vuoto.';
  SItAttachFailed = 'Non è stato possibile allegare il documento.';
  SItAttachNotSupported = 'I documenti allegati non sono stati inviati: il provider %s non li sa leggere.';
  SItUiPdfAnswer = 'Salva questa risposta in PDF';
  SItUiPdfConversation = 'Salva la conversazione in PDF';
  SItUiCopyAnswer = 'Copia questa risposta';
  SItUiCopyConversation = 'Copia la conversazione';
  SItUiCopyPage = 'Copia questa pagina';
  SItUiCopied = 'Copiato';
  SItUiCopyFailed = 'Non è stato possibile copiare il testo negli appunti.';
  SItUiPdfPage = 'Salva questa pagina in PDF';
  SItPdfAnswerTitle = 'Risposta';
  SItPdfConversationTitle = 'Conversazione';
  SItPdfUser = 'Domanda';
  SItPdfAssistant = 'Risposta';
  SItPdfFilter = 'Documento PDF (*.pdf)|*.pdf';
  SItPdfOpen = 'Il PDF è stato salvato come "%s". Vuoi aprirlo?';
  SItPdfFailed = 'Non è stato possibile creare il PDF: %s';
  SItPdfNoBands = '"%s" è stato salvato, ma questa versione del motore del ' +
    'browser non ha accettato l''intestazione e il piè di pagina del documento.';
  SItPdfNothing = 'Non c''è ancora niente da salvare.';
  SItPdfUnavailable = 'Il salvataggio in PDF non è disponibile in questa applicazione.';
  SItPdfHandedOver = 'Il documento è pronto: l''utente sta scegliendo dove salvarlo.';
  SItAttachedDocuments = 'Documenti allegati dall''utente alla domanda';
  SItAttachedTextFile = 'Contenuto del file allegato "%s"';

  // ---- Spanish -------------------------------------------------------------
  SEsGreeting = '¡Hola! Pregúntame lo que quieras sobre cómo usar la aplicación.';
  SEsStubReply = 'Lo siento, por ahora no tengo elementos para ayudarte con este tema.';
  SEsIndexUnavailable = 'El índice de la ayuda no está disponible. Consulta la [documentación](%s).';
  SEsNoPageFound = 'No he encontrado una página específica para tu pregunta. Consulta la [documentación](%s).';
  SEsReadMore = 'Leer más';
  SEsSeeAlso = 'Véase también:';
  SEsClaudeNotConfigured = 'El proveedor Claude no está configurado: pon la clave API en ' +
    'Settings.Claude.ApiKey, en la variable de entorno ANTHROPIC_API_KEY o en un archivo helpchatai.json ' +
    'como { "Claude": { "ApiKey": "..." } } en %s (compartido por todas las aplicaciones HelpChat) o en %s.';
  SEsProviderKeyMissing = 'El proveedor "%0:s" no tiene clave API: ponla en Settings.%1:s.ApiKey, ' +
    'en la variable de entorno %2:s o en un archivo helpchatai.json como ' +
    '{ "%1:s": { "ApiKey": "..." } } en %3:s (compartido por todas las aplicaciones HelpChat) o en %4:s.';
  SEsProviderNotAvailable = 'El proveedor "%s" no está disponible en esta aplicación: su unit ' +
    'lo registra cuando se enlaza, así que hay que añadirla a la uses (HelpChatAI.Provider.Claude para "claude", ' +
    'HelpChatAI.Provider.DocSearch para "docsearch"). Proveedores disponibles: %s.';
  SEsProviderError = 'El proveedor de IA ha devuelto un error.';
  SEsApiError = 'Error de la API de Claude (HTTP %d %s).';
  SEsEmptyReply = 'El asistente no ha devuelto ningún contenido.';
  SEsCancelled = 'La solicitud se ha cancelado.';
  SEsScreenContext = 'El usuario está en la pantalla "%s" (tipo: %s).';
  SEsRelevantDocs = 'Fragmentos relevantes de la documentación:';
  SEsSource = 'Fuente';
  SEsContextQuestion = '¿Cómo se usa la pantalla "%s"?';
  SEsUiTitle = 'Asistente';
  SEsUiHelp = 'Ayuda';
  SEsUiClear = 'Borrar la conversación';
  SEsUiClose = 'Cerrar';
  SEsUiPlaceholder = 'Haz una pregunta sobre la aplicación...';
  SEsUiSend = 'Enviar';
  SEsUiStop = 'Detener';
  SEsUiRetry = 'Reintentar';
  SEsUiSendError = 'No se ha podido enviar el mensaje.';
  SEsUiBack = 'Volver al chat';
  SEsUiChangeAssistant = 'Cambiar de asistente';
  SEsUiChangeLanguage = 'Cambiar de idioma';
  SEsCmdHelp = 'Los comandos que puedes escribir';
  SEsCmdWho = 'Quién responde: asistente, modelo, proveedor';
  SEsCmdUse = 'Cambia al asistente indicado: /use Gemini';
  SEsCmdLang = 'Cambia el idioma del chat: /lang en';
  SEsCmdRetry = 'Repite la última pregunta, a otro asistente si se indica';
  SEsCmdSearch = 'Las páginas de la documentación en las que se basaría la respuesta';
  SEsCmdDoc = 'Abre una página de la documentación: /doc Leads.md';
  SEsCmdPages = 'Las páginas del índice de la documentación';
  SEsCmdContext = 'La pantalla en la que el asistente cree que estás';
  SEsCmdActions = 'Lo que el asistente puede hacer en esta aplicación';
  SEsCmdCheck = 'La comprobación de la configuración del asistente';
  SEsCmdStats = 'Tiempos de la última respuesta';
  SEsCmdClear = 'Borra la conversación';
  SEsCmdPdf = 'Guarda la conversación como PDF';
  SEsCmdCopy = 'Copia la última respuesta';
  SEsCmdAttach = 'Adjunta un archivo';
  SEsCmdPrompt = 'Las instrucciones y los fragmentos que acompañaron la última pregunta';
  SEsCmdRun = 'Ejecuta una acción a mano: /run open_screen name=Leads';
  SEsCmdUnknown = 'Comando desconocido %s. Escribe /help para ver la lista.';
  SEsCmdProvider = 'Proveedor';
  SEsCmdEndpoint = 'Endpoint';
  SEsCmdNoIndex = 'No hay índice de la documentación.';
  SEsCmdNoQuestion = 'Todavía no hay ninguna pregunta.';
  SEsCmdNoResults = 'No se ha encontrado nada para "%s".';
  SEsCmdNoContext = 'No se ha enviado ningún contexto de pantalla.';
  SEsCmdNoActions = 'Esta aplicación no ha registrado ninguna acción.';
  SEsCmdRunUsage = 'Uso: /run acción nombre=valor nombre2="un valor con espacios"';
  SEsCmdNoEngine = 'El motor no está en marcha.';
  SEsCmdNoAssistant = 'No hay ningún asistente llamado "%s".';
  SEsCmdNoLanguage = 'No hay ningún idioma "%s" entre los que ofrece este chat.';
  SEsCmdStatsLine = 'Última respuesta: primer token tras %s, completa tras %s.';
  SEsCmdNoStats = 'Todavía no hay ninguna respuesta.';
  SEsCmdDocUsage = 'Uso: /doc página';
  SEsCmdUseUsage = 'Uso: /use asistente';
  SEsCmdNoAnswer = 'No hay ninguna respuesta que copiar.';
  SEsCmdTitleHelp = 'Comandos disponibles';
  SEsCmdTitleWho = 'Asistente en uso';
  SEsCmdTitleUse = 'Asistente cambiado';
  SEsCmdTitleLang = 'Idiomas del chat';
  SEsCmdTitleSearch = 'Páginas de la documentación para "%s"';
  SEsCmdTitlePages = 'Páginas de la documentación';
  SEsCmdTitleContext = 'Contexto de pantalla';
  SEsCmdTitleActions = 'Acciones disponibles';
  SEsCmdTitleCheck = 'Comprobación de la configuración';
  SEsCmdTitleStats = 'Tiempos de la última respuesta';
  SEsCmdTitlePrompt = 'Prompt de sistema de la última pregunta';
  SEsCmdTitleRun = 'Acción ejecutada';
  SEsUiMic = 'Dictar la pregunta';
  SEsVoiceConsentNeeded = 'El dictado usa el reconocimiento de voz en línea de Windows, que no está activado en este equipo.' + sLineBreak + sLineBreak + 'Ahora se abrirá la configuración de Windows: activa Reconocimiento de voz en línea y vuelve a pulsar el micrófono.';
  SEsVoiceUnavailable = 'El reconocimiento de voz no está disponible en este equipo. Revisa Configuración, Privacidad, Voz, y que el paquete de idioma esté instalado.';
  SEsDocNotFound = 'La página "%s" no está disponible.';
  SEsActionConfirm = 'El asistente quiere ejecutar "%s": %s' + sLineBreak + sLineBreak +
    '%s' + '¿Lo permites?';
  SEsActionValues = 'Valores escritos por el asistente:';
  SEsActionConfirmTitle = 'El asistente quiere ejecutar "%s"';
  SEsActionValuesFooter = 'Los valores anteriores los ha escrito el asistente, no tú: ' +
    'revísalos antes de permitirlo.';
  SEsUiAttach = 'Adjuntar un documento';
  SEsUiAttachRemove = 'Quitar este adjunto';
  SEsAttachTypeRefused = 'Un archivo %s no es uno que el asistente pueda leer. Se aceptan: %s.';
  SEsAttachTooLarge = '"%s" es demasiado grande: un adjunto no puede superar %s.';
  SEsAttachTooMany = 'No más de %d adjuntos a la vez.';
  SEsAttachTooMuch = 'Los adjuntos de una conversación no pueden superar %s en total.';
  SEsAttachEmpty = 'No hay nada en "%s".';
  SEsAttachFailed = 'No se ha podido adjuntar el documento.';
  SEsAttachNotSupported = 'Los documentos adjuntos no se han enviado: el proveedor %s no puede leerlos.';
  SEsUiPdfAnswer = 'Guardar esta respuesta como PDF';
  SEsUiPdfConversation = 'Guardar la conversación como PDF';
  SEsUiCopyAnswer = 'Copiar esta respuesta';
  SEsUiCopyConversation = 'Copiar la conversación';
  SEsUiCopyPage = 'Copiar esta página';
  SEsUiCopied = 'Copiado';
  SEsUiCopyFailed = 'No se ha podido copiar el texto al portapapeles.';
  SEsUiPdfPage = 'Guardar esta página como PDF';
  SEsPdfAnswerTitle = 'Respuesta';
  SEsPdfConversationTitle = 'Conversación';
  SEsPdfUser = 'Pregunta';
  SEsPdfAssistant = 'Respuesta';
  SEsPdfFilter = 'Documento PDF (*.pdf)|*.pdf';
  SEsPdfOpen = 'El PDF se ha guardado como "%s". ¿Abrirlo ahora?';
  SEsPdfFailed = 'No se ha podido crear el PDF: %s';
  SEsPdfNoBands = '"%s" se ha guardado, pero esta versión del motor del navegador ' +
    'no ha impreso el encabezado ni el pie del documento.';
  SEsPdfNothing = 'Todavía no hay nada que guardar.';
  SEsPdfUnavailable = 'Guardar como PDF no está disponible en esta aplicación.';
  SEsPdfHandedOver = 'El documento está listo: el usuario está eligiendo dónde guardarlo.';
  SEsAttachedDocuments = 'Documentos que el usuario adjuntó a la pregunta';
  SEsAttachedTextFile = 'Contenido del archivo adjunto "%s"';

  // ---- French --------------------------------------------------------------
  SFrGreeting = 'Bonjour ! Posez-moi toutes vos questions sur l''utilisation de l''application.';
  SFrStubReply = 'Désolé, je n''ai pour l''instant aucun élément pour vous aider sur ce sujet.';
  SFrIndexUnavailable = 'L''index de l''aide n''est pas disponible. Consultez la [documentation](%s).';
  SFrNoPageFound = 'Je n''ai pas trouvé de page précise pour votre question. Parcourez la [documentation](%s).';
  SFrReadMore = 'Lire la suite';
  SFrSeeAlso = 'Voir aussi :';
  SFrClaudeNotConfigured = 'Le fournisseur Claude n''est pas configuré : placez la clé API dans ' +
    'Settings.Claude.ApiKey, dans la variable d''environnement ANTHROPIC_API_KEY ou dans un fichier helpchatai.json ' +
    'sous la forme { "Claude": { "ApiKey": "..." } } dans %s (partagé par toutes les applications HelpChat) ou dans %s.';
  SFrProviderKeyMissing = 'Le fournisseur "%0:s" n''a pas de clé API : placez-la dans Settings.%1:s.ApiKey, ' +
    'dans la variable d''environnement %2:s ou dans un fichier helpchatai.json sous la forme ' +
    '{ "%1:s": { "ApiKey": "..." } } dans %3:s (partagé par toutes les applications HelpChat) ou dans %4:s.';
  SFrProviderNotAvailable = 'Le fournisseur "%s" n''est pas disponible dans cette application : son unit ' +
    'l''enregistre quand elle est liée, il faut donc l''ajouter à la clause uses (HelpChatAI.Provider.Claude pour "claude", ' +
    'HelpChatAI.Provider.DocSearch pour "docsearch"). Fournisseurs disponibles : %s.';
  SFrProviderError = 'Le fournisseur d''IA a renvoyé une erreur.';
  SFrApiError = 'Erreur de l''API Claude (HTTP %d %s).';
  SFrEmptyReply = 'L''assistant n''a renvoyé aucun contenu.';
  SFrCancelled = 'La demande a été annulée.';
  SFrScreenContext = 'L''utilisateur se trouve sur l''écran "%s" (type : %s).';
  SFrRelevantDocs = 'Extraits pertinents de la documentation :';
  SFrSource = 'Source';
  SFrContextQuestion = 'Comment utiliser l''écran "%s" ?';
  SFrUiTitle = 'Assistant';
  SFrUiHelp = 'Aide';
  SFrUiClear = 'Effacer la conversation';
  SFrUiClose = 'Fermer';
  SFrUiPlaceholder = 'Posez une question sur l''application...';
  SFrUiSend = 'Envoyer';
  SFrUiStop = 'Arrêter';
  SFrUiRetry = 'Réessayer';
  SFrUiSendError = 'Le message n''a pas pu être envoyé.';
  SFrUiBack = 'Retour à la conversation';
  SFrUiChangeAssistant = 'Changer d''assistant';
  SFrUiChangeLanguage = 'Changer de langue';
  SFrCmdHelp = 'Les commandes que vous pouvez taper';
  SFrCmdWho = 'Qui répond : assistant, modèle, fournisseur';
  SFrCmdUse = 'Passe à l''assistant indiqué : /use Gemini';
  SFrCmdLang = 'Change la langue de la conversation : /lang en';
  SFrCmdRetry = 'Repose la dernière question, à un autre assistant s''il est indiqué';
  SFrCmdSearch = 'Les pages de la documentation sur lesquelles la réponse s''appuierait';
  SFrCmdDoc = 'Ouvre une page de la documentation : /doc Leads.md';
  SFrCmdPages = 'Les pages de l''index de la documentation';
  SFrCmdContext = 'L''écran sur lequel l''assistant pense que vous êtes';
  SFrCmdActions = 'Ce que l''assistant peut faire dans cette application';
  SFrCmdCheck = 'La vérification de la configuration de l''assistant';
  SFrCmdStats = 'Temps de la dernière réponse';
  SFrCmdClear = 'Efface la conversation';
  SFrCmdPdf = 'Enregistre la conversation en PDF';
  SFrCmdCopy = 'Copie la dernière réponse';
  SFrCmdAttach = 'Joint un fichier';
  SFrCmdPrompt = 'Les instructions et les extraits qui accompagnaient la dernière question';
  SFrCmdRun = 'Exécute une action à la main : /run open_screen name=Leads';
  SFrCmdUnknown = 'Commande inconnue %s. Tapez /help pour la liste.';
  SFrCmdProvider = 'Fournisseur';
  SFrCmdEndpoint = 'Point d''accès';
  SFrCmdNoIndex = 'Il n''y a pas d''index de la documentation.';
  SFrCmdNoQuestion = 'Aucune question pour l''instant.';
  SFrCmdNoResults = 'Rien trouvé pour "%s".';
  SFrCmdNoContext = 'Aucun contexte d''écran n''a été envoyé.';
  SFrCmdNoActions = 'Cette application n''a enregistré aucune action.';
  SFrCmdRunUsage = 'Utilisation : /run action nom=valeur nom2="une valeur avec des espaces"';
  SFrCmdNoEngine = 'Le moteur n''est pas démarré.';
  SFrCmdNoAssistant = 'Aucun assistant nommé "%s".';
  SFrCmdNoLanguage = 'Aucune langue "%s" parmi celles que propose cette conversation.';
  SFrCmdStatsLine = 'Dernière réponse : premier token après %s, complète après %s.';
  SFrCmdNoStats = 'Aucune réponse pour l''instant.';
  SFrCmdDocUsage = 'Utilisation : /doc page';
  SFrCmdUseUsage = 'Utilisation : /use assistant';
  SFrCmdNoAnswer = 'Aucune réponse à copier.';
  SFrCmdTitleHelp = 'Commandes disponibles';
  SFrCmdTitleWho = 'Assistant utilisé';
  SFrCmdTitleUse = 'Assistant changé';
  SFrCmdTitleLang = 'Langues de la conversation';
  SFrCmdTitleSearch = 'Pages de la documentation pour "%s"';
  SFrCmdTitlePages = 'Pages de la documentation';
  SFrCmdTitleContext = 'Contexte de l''écran';
  SFrCmdTitleActions = 'Actions disponibles';
  SFrCmdTitleCheck = 'Vérification de la configuration';
  SFrCmdTitleStats = 'Temps de la dernière réponse';
  SFrCmdTitlePrompt = 'Prompt système de la dernière question';
  SFrCmdTitleRun = 'Action exécutée';
  SFrUiMic = 'Dicter la question';
  SFrVoiceConsentNeeded = 'La dictée passe par la reconnaissance vocale en ligne de Windows, qui n''est pas activée sur cet ordinateur.' + sLineBreak + sLineBreak + 'Les paramètres de Windows vont s''ouvrir : activez Reconnaissance vocale en ligne, puis appuyez de nouveau sur le microphone.';
  SFrVoiceUnavailable = 'La reconnaissance vocale n''est pas disponible sur cet ordinateur. Vérifiez Paramètres, Confidentialité, Voix, et que le module linguistique est installé.';
  SFrDocNotFound = 'La page "%s" n''est pas disponible.';
  SFrActionConfirm = 'L''assistant veut exécuter "%s" : %s' + sLineBreak + sLineBreak +
    '%s' + 'L''autorisez-vous ?';
  SFrActionValues = 'Valeurs écrites par l''assistant :';
  SFrActionConfirmTitle = 'L''assistant veut exécuter "%s"';
  SFrActionValuesFooter = 'Les valeurs ci-dessus ont été écrites par l''assistant, pas par vous : ' +
    'vérifiez-les avant d''autoriser.';
  SFrUiAttach = 'Joindre un document';
  SFrUiAttachRemove = 'Retirer cette pièce jointe';
  SFrAttachTypeRefused = 'Un fichier %s n''est pas un fichier que l''assistant sait lire. Acceptés : %s.';
  SFrAttachTooLarge = '"%s" est trop volumineux : une pièce jointe ne peut pas dépasser %s.';
  SFrAttachTooMany = 'Pas plus de %d pièces jointes à la fois.';
  SFrAttachTooMuch = 'Les pièces jointes d''une conversation ne peuvent pas dépasser %s au total.';
  SFrAttachEmpty = 'Il n''y a rien dans "%s".';
  SFrAttachFailed = 'Le document n''a pas pu être joint.';
  SFrAttachNotSupported = 'Les documents joints n''ont pas été envoyés : le fournisseur %s ne sait pas les lire.';
  SFrUiPdfAnswer = 'Enregistrer cette réponse en PDF';
  SFrUiPdfConversation = 'Enregistrer la conversation en PDF';
  SFrUiCopyAnswer = 'Copier cette réponse';
  SFrUiCopyConversation = 'Copier la conversation';
  SFrUiCopyPage = 'Copier cette page';
  SFrUiCopied = 'Copié';
  SFrUiCopyFailed = 'Le texte n''a pas pu être copié dans le presse-papiers.';
  SFrUiPdfPage = 'Enregistrer cette page en PDF';
  SFrPdfAnswerTitle = 'Réponse';
  SFrPdfConversationTitle = 'Conversation';
  SFrPdfUser = 'Question';
  SFrPdfAssistant = 'Réponse';
  SFrPdfFilter = 'Document PDF (*.pdf)|*.pdf';
  SFrPdfOpen = 'Le PDF a été enregistré sous "%s". L''ouvrir maintenant ?';
  SFrPdfFailed = 'Le PDF n''a pas pu être créé : %s';
  SFrPdfNoBands = '"%s" a été enregistré, mais cette version du moteur du navigateur ' +
    'n''a pas imprimé l''en-tête ni le pied de page du document.';
  SFrPdfNothing = 'Il n''y a encore rien à enregistrer.';
  SFrPdfUnavailable = 'L''enregistrement en PDF n''est pas disponible dans cette application.';
  SFrPdfHandedOver = 'Le document est prêt : l''utilisateur choisit où l''enregistrer.';
  SFrAttachedDocuments = 'Documents que l''utilisateur a joints à la question';
  SFrAttachedTextFile = 'Contenu du fichier joint "%s"';

  // ---- German --------------------------------------------------------------
  SDeGreeting = 'Hallo! Fragen Sie mich alles zur Bedienung der Anwendung.';
  SDeStubReply = 'Leider habe ich im Moment keine Informationen, um Ihnen bei diesem Thema zu helfen.';
  SDeIndexUnavailable = 'Der Hilfeindex ist nicht verfügbar. Siehe die [Dokumentation](%s).';
  SDeNoPageFound = 'Ich habe keine passende Seite zu Ihrer Frage gefunden. Durchsuchen Sie die [Dokumentation](%s).';
  SDeReadMore = 'Weiterlesen';
  SDeSeeAlso = 'Siehe auch:';
  SDeClaudeNotConfigured = 'Der Anbieter Claude ist nicht konfiguriert: Tragen Sie den API-Schlüssel in ' +
    'Settings.Claude.ApiKey, in die Umgebungsvariable ANTHROPIC_API_KEY oder in eine Datei helpchatai.json ' +
    'als { "Claude": { "ApiKey": "..." } } in %s (von allen HelpChat-Anwendungen gemeinsam genutzt) oder in %s ein.';
  SDeProviderKeyMissing = 'Der Anbieter "%0:s" hat keinen API-Schlüssel: Tragen Sie ihn in Settings.%1:s.ApiKey, ' +
    'in die Umgebungsvariable %2:s oder in eine Datei helpchatai.json als ' +
    '{ "%1:s": { "ApiKey": "..." } } in %3:s (von allen HelpChat-Anwendungen gemeinsam genutzt) oder in %4:s ein.';
  SDeProviderNotAvailable = 'Der Anbieter "%s" ist in dieser Anwendung nicht verfügbar: Seine Unit ' +
    'registriert ihn, wenn sie gelinkt wird, also fügen Sie sie der uses-Klausel hinzu (HelpChatAI.Provider.Claude für "claude", ' +
    'HelpChatAI.Provider.DocSearch für "docsearch"). Verfügbare Anbieter: %s.';
  SDeProviderError = 'Der KI-Anbieter hat einen Fehler gemeldet.';
  SDeApiError = 'Fehler der Claude-API (HTTP %d %s).';
  SDeEmptyReply = 'Der Assistent hat keinen Inhalt geliefert.';
  SDeCancelled = 'Die Anfrage wurde abgebrochen.';
  SDeScreenContext = 'Der Benutzer befindet sich gerade in der Ansicht "%s" (Typ: %s).';
  SDeRelevantDocs = 'Relevante Auszüge aus der Dokumentation:';
  SDeSource = 'Quelle';
  SDeContextQuestion = 'Wie verwende ich die Ansicht "%s"?';
  SDeUiTitle = 'Assistent';
  SDeUiHelp = 'Hilfe';
  SDeUiClear = 'Unterhaltung löschen';
  SDeUiClose = 'Schließen';
  SDeUiPlaceholder = 'Stellen Sie eine Frage zur Anwendung...';
  SDeUiSend = 'Senden';
  SDeUiStop = 'Anhalten';
  SDeUiRetry = 'Wiederholen';
  SDeUiSendError = 'Die Nachricht konnte nicht gesendet werden.';
  SDeUiBack = 'Zurück zum Chat';
  SDeUiChangeAssistant = 'Assistent wechseln';
  SDeUiChangeLanguage = 'Sprache wechseln';
  SDeCmdHelp = 'Die Befehle, die Sie eingeben können';
  SDeCmdWho = 'Wer antwortet: Assistent, Modell, Anbieter';
  SDeCmdUse = 'Wechselt zum genannten Assistenten: /use Gemini';
  SDeCmdLang = 'Wechselt die Sprache des Chats: /lang en';
  SDeCmdRetry = 'Stellt die letzte Frage erneut, an einen anderen Assistenten, falls genannt';
  SDeCmdSearch = 'Die Seiten der Dokumentation, auf die sich die Antwort stützen würde';
  SDeCmdDoc = 'Öffnet eine Seite der Dokumentation: /doc Leads.md';
  SDeCmdPages = 'Die Seiten des Dokumentationsindex';
  SDeCmdContext = 'Die Ansicht, in der Sie sich nach Meinung des Assistenten befinden';
  SDeCmdActions = 'Was der Assistent in dieser Anwendung tun kann';
  SDeCmdCheck = 'Die Konfigurationsprüfung des Assistenten';
  SDeCmdStats = 'Zeiten der letzten Antwort';
  SDeCmdClear = 'Löscht die Unterhaltung';
  SDeCmdPdf = 'Speichert die Unterhaltung als PDF';
  SDeCmdCopy = 'Kopiert die letzte Antwort';
  SDeCmdAttach = 'Hängt eine Datei an';
  SDeCmdPrompt = 'Die Anweisungen und Auszüge, mit denen die letzte Frage gestellt wurde';
  SDeCmdRun = 'Führt eine Aktion von Hand aus: /run open_screen name=Leads';
  SDeCmdUnknown = 'Unbekannter Befehl %s. Geben Sie /help für die Liste ein.';
  SDeCmdProvider = 'Anbieter';
  SDeCmdEndpoint = 'Endpunkt';
  SDeCmdNoIndex = 'Es gibt keinen Dokumentationsindex.';
  SDeCmdNoQuestion = 'Noch keine Frage.';
  SDeCmdNoResults = 'Nichts gefunden für "%s".';
  SDeCmdNoContext = 'Es wurde kein Ansichtskontext gesendet.';
  SDeCmdNoActions = 'Diese Anwendung hat keine Aktionen registriert.';
  SDeCmdRunUsage = 'Verwendung: /run aktion name=wert name2="ein Wert mit Leerzeichen"';
  SDeCmdNoEngine = 'Die Engine läuft nicht.';
  SDeCmdNoAssistant = 'Kein Assistent mit dem Namen "%s".';
  SDeCmdNoLanguage = 'Keine Sprache "%s" unter den Sprachen dieses Chats.';
  SDeCmdStatsLine = 'Letzte Antwort: erstes Token nach %s, vollständig nach %s.';
  SDeCmdNoStats = 'Noch keine Antwort.';
  SDeCmdDocUsage = 'Verwendung: /doc seite';
  SDeCmdUseUsage = 'Verwendung: /use assistent';
  SDeCmdNoAnswer = 'Keine Antwort zum Kopieren.';
  SDeCmdTitleHelp = 'Verfügbare Befehle';
  SDeCmdTitleWho = 'Verwendeter Assistent';
  SDeCmdTitleUse = 'Assistent gewechselt';
  SDeCmdTitleLang = 'Sprachen des Chats';
  SDeCmdTitleSearch = 'Seiten der Dokumentation zu "%s"';
  SDeCmdTitlePages = 'Seiten der Dokumentation';
  SDeCmdTitleContext = 'Ansichtskontext';
  SDeCmdTitleActions = 'Verfügbare Aktionen';
  SDeCmdTitleCheck = 'Konfigurationsprüfung';
  SDeCmdTitleStats = 'Zeiten der letzten Antwort';
  SDeCmdTitlePrompt = 'System-Prompt der letzten Frage';
  SDeCmdTitleRun = 'Aktion ausgeführt';
  SDeUiMic = 'Frage diktieren';
  SDeVoiceConsentNeeded = 'Das Diktieren nutzt die Online-Spracherkennung von Windows, die auf diesem Computer nicht aktiviert ist.' + sLineBreak + sLineBreak + 'Jetzt werden die Windows-Einstellungen geöffnet: Aktivieren Sie die Online-Spracherkennung und klicken Sie dann erneut auf das Mikrofon.';
  SDeVoiceUnavailable = 'Die Spracherkennung ist auf diesem Computer nicht verfügbar. Prüfen Sie Einstellungen, Datenschutz, Spracherkennung und ob das Sprachpaket installiert ist.';
  SDeDocNotFound = 'Die Seite "%s" ist nicht verfügbar.';
  SDeActionConfirm = 'Der Assistent möchte "%s" ausführen: %s' + sLineBreak + sLineBreak +
    '%s' + 'Erlauben Sie das?';
  SDeActionValues = 'Vom Assistenten geschriebene Werte:';
  SDeActionConfirmTitle = 'Der Assistent möchte "%s" ausführen';
  SDeActionValuesFooter = 'Die obigen Werte hat der Assistent geschrieben, nicht Sie: ' +
    'prüfen Sie sie, bevor Sie zustimmen.';
  SDeUiAttach = 'Dokument anhängen';
  SDeUiAttachRemove = 'Diesen Anhang entfernen';
  SDeAttachTypeRefused = 'Eine %s-Datei kann der Assistent nicht lesen. Zulässig: %s.';
  SDeAttachTooLarge = '"%s" ist zu groß: Ein Anhang darf %s nicht überschreiten.';
  SDeAttachTooMany = 'Nicht mehr als %d Anhänge auf einmal.';
  SDeAttachTooMuch = 'Die Anhänge einer Unterhaltung dürfen insgesamt %s nicht überschreiten.';
  SDeAttachEmpty = '"%s" ist leer.';
  SDeAttachFailed = 'Das Dokument konnte nicht angehängt werden.';
  SDeAttachNotSupported = 'Die angehängten Dokumente wurden nicht gesendet: Der Anbieter %s kann sie nicht lesen.';
  SDeUiPdfAnswer = 'Diese Antwort als PDF speichern';
  SDeUiPdfConversation = 'Die Unterhaltung als PDF speichern';
  SDeUiCopyAnswer = 'Diese Antwort kopieren';
  SDeUiCopyConversation = 'Die Unterhaltung kopieren';
  SDeUiCopyPage = 'Diese Seite kopieren';
  SDeUiCopied = 'Kopiert';
  SDeUiCopyFailed = 'Der Text konnte nicht in die Zwischenablage kopiert werden.';
  SDeUiPdfPage = 'Diese Seite als PDF speichern';
  SDePdfAnswerTitle = 'Antwort';
  SDePdfConversationTitle = 'Unterhaltung';
  SDePdfUser = 'Frage';
  SDePdfAssistant = 'Antwort';
  SDePdfFilter = 'PDF-Dokument (*.pdf)|*.pdf';
  SDePdfOpen = 'Das PDF wurde als "%s" gespeichert. Jetzt öffnen?';
  SDePdfFailed = 'Das PDF konnte nicht erstellt werden: %s';
  SDePdfNoBands = '"%s" wurde gespeichert, aber diese Version der Browser-Engine ' +
    'hat Kopf- und Fußzeile des Dokuments nicht gedruckt.';
  SDePdfNothing = 'Es gibt noch nichts zu speichern.';
  SDePdfUnavailable = 'Das Speichern als PDF ist in dieser Anwendung nicht verfügbar.';
  SDePdfHandedOver = 'Das Dokument ist fertig: Der Benutzer wählt gerade aus, wo es gespeichert wird.';
  SDeAttachedDocuments = 'Dokumente, die der Benutzer an die Frage angehängt hat';
  SDeAttachedTextFile = 'Inhalt der angehängten Datei "%s"';

  // ---- Portuguese ----------------------------------------------------------
  SPtGreeting = 'Olá! Pergunte-me o que quiser sobre como utilizar a aplicação.';
  SPtStubReply = 'Lamento, de momento não tenho elementos para o ajudar neste assunto.';
  SPtIndexUnavailable = 'O índice da ajuda não está disponível. Consulte a [documentação](%s).';
  SPtNoPageFound = 'Não encontrei uma página específica para a sua pergunta. Consulte a [documentação](%s).';
  SPtReadMore = 'Ler mais';
  SPtSeeAlso = 'Ver também:';
  SPtClaudeNotConfigured = 'O fornecedor Claude não está configurado: coloque a chave API em ' +
    'Settings.Claude.ApiKey, na variável de ambiente ANTHROPIC_API_KEY ou num ficheiro helpchatai.json ' +
    'como { "Claude": { "ApiKey": "..." } } em %s (partilhado por todas as aplicações HelpChat) ou em %s.';
  SPtProviderKeyMissing = 'O fornecedor "%0:s" não tem chave API: coloque-a em Settings.%1:s.ApiKey, ' +
    'na variável de ambiente %2:s ou num ficheiro helpchatai.json como ' +
    '{ "%1:s": { "ApiKey": "..." } } em %3:s (partilhado por todas as aplicações HelpChat) ou em %4:s.';
  SPtProviderNotAvailable = 'O fornecedor "%s" não está disponível nesta aplicação: a sua unit ' +
    'regista-o quando é ligada, por isso adicione-a à cláusula uses (HelpChatAI.Provider.Claude para "claude", ' +
    'HelpChatAI.Provider.DocSearch para "docsearch"). Fornecedores disponíveis: %s.';
  SPtProviderError = 'O fornecedor de IA devolveu um erro.';
  SPtApiError = 'Erro da API do Claude (HTTP %d %s).';
  SPtEmptyReply = 'O assistente não devolveu nenhum conteúdo.';
  SPtCancelled = 'O pedido foi cancelado.';
  SPtScreenContext = 'O utilizador está no ecrã "%s" (tipo: %s).';
  SPtRelevantDocs = 'Excertos relevantes da documentação:';
  SPtSource = 'Fonte';
  SPtContextQuestion = 'Como utilizo o ecrã "%s"?';
  SPtUiTitle = 'Assistente';
  SPtUiHelp = 'Ajuda';
  SPtUiClear = 'Limpar a conversa';
  SPtUiClose = 'Fechar';
  SPtUiPlaceholder = 'Faça uma pergunta sobre a aplicação...';
  SPtUiSend = 'Enviar';
  SPtUiStop = 'Parar';
  SPtUiRetry = 'Tentar novamente';
  SPtUiSendError = 'Não foi possível enviar a mensagem.';
  SPtUiBack = 'Voltar à conversa';
  SPtUiChangeAssistant = 'Mudar de assistente';
  SPtUiChangeLanguage = 'Mudar de idioma';
  SPtCmdHelp = 'Os comandos que pode escrever';
  SPtCmdWho = 'Quem responde: assistente, modelo, fornecedor';
  SPtCmdUse = 'Muda para o assistente indicado: /use Gemini';
  SPtCmdLang = 'Muda o idioma da conversa: /lang en';
  SPtCmdRetry = 'Repete a última pergunta, a outro assistente se for indicado';
  SPtCmdSearch = 'As páginas da documentação em que a resposta se basearia';
  SPtCmdDoc = 'Abre uma página da documentação: /doc Leads.md';
  SPtCmdPages = 'As páginas do índice da documentação';
  SPtCmdContext = 'O ecrã em que o assistente pensa que está';
  SPtCmdActions = 'O que o assistente pode fazer nesta aplicação';
  SPtCmdCheck = 'A verificação da configuração do assistente';
  SPtCmdStats = 'Tempos da última resposta';
  SPtCmdClear = 'Limpa a conversa';
  SPtCmdPdf = 'Guarda a conversa em PDF';
  SPtCmdCopy = 'Copia a última resposta';
  SPtCmdAttach = 'Anexa um ficheiro';
  SPtCmdPrompt = 'As instruções e os excertos que acompanharam a última pergunta';
  SPtCmdRun = 'Executa uma ação manualmente: /run open_screen name=Leads';
  SPtCmdUnknown = 'Comando desconhecido %s. Escreva /help para ver a lista.';
  SPtCmdProvider = 'Fornecedor';
  SPtCmdEndpoint = 'Endpoint';
  SPtCmdNoIndex = 'Não existe índice da documentação.';
  SPtCmdNoQuestion = 'Ainda não há nenhuma pergunta.';
  SPtCmdNoResults = 'Nada encontrado para "%s".';
  SPtCmdNoContext = 'Não foi enviado nenhum contexto de ecrã.';
  SPtCmdNoActions = 'Esta aplicação não registou nenhuma ação.';
  SPtCmdRunUsage = 'Utilização: /run ação nome=valor nome2="um valor com espaços"';
  SPtCmdNoEngine = 'O motor não está em execução.';
  SPtCmdNoAssistant = 'Não existe nenhum assistente chamado "%s".';
  SPtCmdNoLanguage = 'Não existe nenhum idioma "%s" entre os que esta conversa oferece.';
  SPtCmdStatsLine = 'Última resposta: primeiro token após %s, completa após %s.';
  SPtCmdNoStats = 'Ainda não há nenhuma resposta.';
  SPtCmdDocUsage = 'Utilização: /doc página';
  SPtCmdUseUsage = 'Utilização: /use assistente';
  SPtCmdNoAnswer = 'Não há nenhuma resposta para copiar.';
  SPtCmdTitleHelp = 'Comandos disponíveis';
  SPtCmdTitleWho = 'Assistente em uso';
  SPtCmdTitleUse = 'Assistente alterado';
  SPtCmdTitleLang = 'Idiomas da conversa';
  SPtCmdTitleSearch = 'Páginas da documentação para "%s"';
  SPtCmdTitlePages = 'Páginas da documentação';
  SPtCmdTitleContext = 'Contexto do ecrã';
  SPtCmdTitleActions = 'Ações disponíveis';
  SPtCmdTitleCheck = 'Verificação da configuração';
  SPtCmdTitleStats = 'Tempos da última resposta';
  SPtCmdTitlePrompt = 'Prompt de sistema da última pergunta';
  SPtCmdTitleRun = 'Ação executada';
  SPtUiMic = 'Ditar a pergunta';
  SPtVoiceConsentNeeded = 'O ditado usa o reconhecimento de voz online do Windows, que não está ativado neste computador.' + sLineBreak + sLineBreak + 'As definições do Windows vão abrir-se agora: ative o Reconhecimento de voz online e depois prima novamente o microfone.';
  SPtVoiceUnavailable = 'O reconhecimento de voz não está disponível neste computador. Verifique Definições, Privacidade, Voz, e se o pacote de idioma está instalado.';
  SPtDocNotFound = 'A página "%s" não está disponível.';
  SPtActionConfirm = 'O assistente quer executar "%s": %s' + sLineBreak + sLineBreak +
    '%s' + 'Permite?';
  SPtActionValues = 'Valores escritos pelo assistente:';
  SPtActionConfirmTitle = 'O assistente quer executar "%s"';
  SPtActionValuesFooter = 'Os valores acima foram escritos pelo assistente, não por si: ' +
    'verifique-os antes de permitir.';
  SPtUiAttach = 'Anexar um documento';
  SPtUiAttachRemove = 'Remover este anexo';
  SPtAttachTypeRefused = 'Um ficheiro %s não é um que o assistente consiga ler. Aceites: %s.';
  SPtAttachTooLarge = '"%s" é demasiado grande: um anexo não pode exceder %s.';
  SPtAttachTooMany = 'No máximo %d anexos de cada vez.';
  SPtAttachTooMuch = 'Os anexos de uma conversa não podem exceder %s no total.';
  SPtAttachEmpty = 'Não há nada em "%s".';
  SPtAttachFailed = 'Não foi possível anexar o documento.';
  SPtAttachNotSupported = 'Os documentos anexados não foram enviados: o fornecedor %s não os consegue ler.';
  SPtUiPdfAnswer = 'Guardar esta resposta em PDF';
  SPtUiPdfConversation = 'Guardar a conversa em PDF';
  SPtUiCopyAnswer = 'Copiar esta resposta';
  SPtUiCopyConversation = 'Copiar a conversa';
  SPtUiCopyPage = 'Copiar esta página';
  SPtUiCopied = 'Copiado';
  SPtUiCopyFailed = 'Não foi possível copiar o texto para a área de transferência.';
  SPtUiPdfPage = 'Guardar esta página em PDF';
  SPtPdfAnswerTitle = 'Resposta';
  SPtPdfConversationTitle = 'Conversa';
  SPtPdfUser = 'Pergunta';
  SPtPdfAssistant = 'Resposta';
  SPtPdfFilter = 'Documento PDF (*.pdf)|*.pdf';
  SPtPdfOpen = 'O PDF foi guardado como "%s". Abri-lo agora?';
  SPtPdfFailed = 'Não foi possível criar o PDF: %s';
  SPtPdfNoBands = '"%s" foi guardado, mas esta versão do motor do navegador ' +
    'não imprimiu o cabeçalho nem o rodapé do documento.';
  SPtPdfNothing = 'Ainda não há nada para guardar.';
  SPtPdfUnavailable = 'Guardar em PDF não está disponível nesta aplicação.';
  SPtPdfHandedOver = 'O documento está pronto: o utilizador está a escolher onde guardá-lo.';
  SPtAttachedDocuments = 'Documentos que o utilizador anexou à pergunta';
  SPtAttachedTextFile = 'Conteúdo do ficheiro anexado "%s"';

const
  LANGUAGE_CODES: array[THelpChatLanguage] of string = (
    'auto', 'en', 'it', 'es', 'fr', 'de', 'pt');
  LANGUAGE_NAMES: array[THelpChatLanguage] of string = (
    '', 'English', 'Italian', 'Spanish', 'French', 'German', 'Portuguese');
  LANGUAGE_NATIVE_NAMES: array[THelpChatLanguage] of string = (
    '', 'English', 'Italiano', 'Español', 'Français', 'Deutsch', 'Português');
  /// <summary>Primary language ids of Windows (LANG_* of WinNT.h), so that
  /// the engine stays free of Winapi units.</summary>
  LANGUAGE_PRIMARY_IDS: array[THelpChatLanguage] of Word = (
    0, $09, $10, $0A, $0C, $07, $16);

function HelpChatSystemLanguage: THelpChatLanguage;
var
  L: THelpChatLanguage;
begin
  for L in HELPCHAT_ALL_LANGUAGES do
    if SysLocale.PriLangID = LANGUAGE_PRIMARY_IDS[L] then
      Exit(L);
  Result := hclEnglish;
end;

function HelpChatResolveLanguage(const ALanguage: THelpChatLanguage): THelpChatLanguage;
begin
  Result := ALanguage;
  if Result = hclAuto then
    Result := HelpChatDefaultLanguage;
  if Result = hclAuto then
    Result := HelpChatSystemLanguage;
end;

function HelpChatLanguageCode(const ALanguage: THelpChatLanguage): string;
begin
  Result := LANGUAGE_CODES[HelpChatResolveLanguage(ALanguage)];
end;

function HelpChatLanguageName(const ALanguage: THelpChatLanguage): string;
begin
  Result := LANGUAGE_NAMES[HelpChatResolveLanguage(ALanguage)];
end;

function HelpChatLanguageNativeName(const ALanguage: THelpChatLanguage): string;
begin
  Result := LANGUAGE_NATIVE_NAMES[HelpChatResolveLanguage(ALanguage)];
end;

function HelpChatLanguageFromCode(const AValue: string;
  out ALanguage: THelpChatLanguage): Boolean;
var
  L: THelpChatLanguage;
  LValue: string;
begin
  LValue := Trim(AValue);
  for L := Low(THelpChatLanguage) to High(THelpChatLanguage) do
    if SameText(LValue, LANGUAGE_CODES[L]) or
       ((L <> hclAuto) and (SameText(LValue, LANGUAGE_NAMES[L]) or
                            SameText(LValue, LANGUAGE_NATIVE_NAMES[L]))) then
    begin
      ALanguage := L;
      Exit(True);
    end;
  ALanguage := hclAuto;
  Result := False;
end;

function HelpChatLanguageList(const ALanguages: THelpChatLanguages): TArray<THelpChatLanguage>;
var
  L: THelpChatLanguage;
begin
  Result := nil;
  for L in HELPCHAT_ALL_LANGUAGES do
    if L in ALanguages then
      Result := Result + [L];
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
    hcmActionValues: Result := SEnActionValues;
    hcmActionConfirmTitle: Result := SEnActionConfirmTitle;
    hcmActionValuesFooter: Result := SEnActionValuesFooter;
    hcmUiAttach: Result := SEnUiAttach;
    hcmUiAttachRemove: Result := SEnUiAttachRemove;
    hcmUiChangeAssistant: Result := SEnUiChangeAssistant;
    hcmUiChangeLanguage: Result := SEnUiChangeLanguage;
    hcmCmdHelp: Result := SEnCmdHelp;
    hcmCmdWho: Result := SEnCmdWho;
    hcmCmdUse: Result := SEnCmdUse;
    hcmCmdLang: Result := SEnCmdLang;
    hcmCmdRetry: Result := SEnCmdRetry;
    hcmCmdSearch: Result := SEnCmdSearch;
    hcmCmdDoc: Result := SEnCmdDoc;
    hcmCmdPages: Result := SEnCmdPages;
    hcmCmdContext: Result := SEnCmdContext;
    hcmCmdActions: Result := SEnCmdActions;
    hcmCmdCheck: Result := SEnCmdCheck;
    hcmCmdStats: Result := SEnCmdStats;
    hcmCmdClear: Result := SEnCmdClear;
    hcmCmdPdf: Result := SEnCmdPdf;
    hcmCmdCopy: Result := SEnCmdCopy;
    hcmCmdAttach: Result := SEnCmdAttach;
    hcmCmdPrompt: Result := SEnCmdPrompt;
    hcmCmdRun: Result := SEnCmdRun;
    hcmCmdUnknown: Result := SEnCmdUnknown;
    hcmCmdProvider: Result := SEnCmdProvider;
    hcmCmdEndpoint: Result := SEnCmdEndpoint;
    hcmCmdNoIndex: Result := SEnCmdNoIndex;
    hcmCmdNoQuestion: Result := SEnCmdNoQuestion;
    hcmCmdNoResults: Result := SEnCmdNoResults;
    hcmCmdNoContext: Result := SEnCmdNoContext;
    hcmCmdNoActions: Result := SEnCmdNoActions;
    hcmCmdRunUsage: Result := SEnCmdRunUsage;
    hcmCmdNoEngine: Result := SEnCmdNoEngine;
    hcmCmdNoAssistant: Result := SEnCmdNoAssistant;
    hcmCmdNoLanguage: Result := SEnCmdNoLanguage;
    hcmCmdStatsLine: Result := SEnCmdStatsLine;
    hcmCmdNoStats: Result := SEnCmdNoStats;
    hcmCmdDocUsage: Result := SEnCmdDocUsage;
    hcmCmdUseUsage: Result := SEnCmdUseUsage;
    hcmCmdNoAnswer: Result := SEnCmdNoAnswer;
    hcmCmdTitleHelp: Result := SEnCmdTitleHelp;
    hcmCmdTitleWho: Result := SEnCmdTitleWho;
    hcmCmdTitleUse: Result := SEnCmdTitleUse;
    hcmCmdTitleLang: Result := SEnCmdTitleLang;
    hcmCmdTitleSearch: Result := SEnCmdTitleSearch;
    hcmCmdTitlePages: Result := SEnCmdTitlePages;
    hcmCmdTitleContext: Result := SEnCmdTitleContext;
    hcmCmdTitleActions: Result := SEnCmdTitleActions;
    hcmCmdTitleCheck: Result := SEnCmdTitleCheck;
    hcmCmdTitleStats: Result := SEnCmdTitleStats;
    hcmCmdTitlePrompt: Result := SEnCmdTitlePrompt;
    hcmCmdTitleRun: Result := SEnCmdTitleRun;
    hcmAttachTypeRefused: Result := SEnAttachTypeRefused;
    hcmAttachTooLarge: Result := SEnAttachTooLarge;
    hcmAttachTooMany: Result := SEnAttachTooMany;
    hcmAttachTooMuch: Result := SEnAttachTooMuch;
    hcmAttachEmpty: Result := SEnAttachEmpty;
    hcmAttachFailed: Result := SEnAttachFailed;
    hcmAttachNotSupported: Result := SEnAttachNotSupported;
    hcmAttachedDocuments: Result := SEnAttachedDocuments;
    hcmAttachedTextFile: Result := SEnAttachedTextFile;
    hcmUiPdfAnswer: Result := SEnUiPdfAnswer;
    hcmUiPdfConversation: Result := SEnUiPdfConversation;
    hcmUiCopyAnswer: Result := SEnUiCopyAnswer;
    hcmUiCopyConversation: Result := SEnUiCopyConversation;
    hcmUiCopyPage: Result := SEnUiCopyPage;
    hcmUiCopied: Result := SEnUiCopied;
    hcmUiCopyFailed: Result := SEnUiCopyFailed;
    hcmUiPdfPage: Result := SEnUiPdfPage;
    hcmPdfAnswerTitle: Result := SEnPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SEnPdfConversationTitle;
    hcmPdfUser: Result := SEnPdfUser;
    hcmPdfAssistant: Result := SEnPdfAssistant;
    hcmPdfFilter: Result := SEnPdfFilter;
    hcmPdfOpen: Result := SEnPdfOpen;
    hcmPdfFailed: Result := SEnPdfFailed;
    hcmPdfNoBands: Result := SEnPdfNoBands;
    hcmPdfNothing: Result := SEnPdfNothing;
    hcmPdfUnavailable: Result := SEnPdfUnavailable;
    hcmPdfHandedOver: Result := SEnPdfHandedOver;
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
    hcmActionValues: Result := SItActionValues;
    hcmActionConfirmTitle: Result := SItActionConfirmTitle;
    hcmActionValuesFooter: Result := SItActionValuesFooter;
    hcmUiAttach: Result := SItUiAttach;
    hcmUiAttachRemove: Result := SItUiAttachRemove;
    hcmUiChangeAssistant: Result := SItUiChangeAssistant;
    hcmUiChangeLanguage: Result := SItUiChangeLanguage;
    hcmCmdHelp: Result := SItCmdHelp;
    hcmCmdWho: Result := SItCmdWho;
    hcmCmdUse: Result := SItCmdUse;
    hcmCmdLang: Result := SItCmdLang;
    hcmCmdRetry: Result := SItCmdRetry;
    hcmCmdSearch: Result := SItCmdSearch;
    hcmCmdDoc: Result := SItCmdDoc;
    hcmCmdPages: Result := SItCmdPages;
    hcmCmdContext: Result := SItCmdContext;
    hcmCmdActions: Result := SItCmdActions;
    hcmCmdCheck: Result := SItCmdCheck;
    hcmCmdStats: Result := SItCmdStats;
    hcmCmdClear: Result := SItCmdClear;
    hcmCmdPdf: Result := SItCmdPdf;
    hcmCmdCopy: Result := SItCmdCopy;
    hcmCmdAttach: Result := SItCmdAttach;
    hcmCmdPrompt: Result := SItCmdPrompt;
    hcmCmdRun: Result := SItCmdRun;
    hcmCmdUnknown: Result := SItCmdUnknown;
    hcmCmdProvider: Result := SItCmdProvider;
    hcmCmdEndpoint: Result := SItCmdEndpoint;
    hcmCmdNoIndex: Result := SItCmdNoIndex;
    hcmCmdNoQuestion: Result := SItCmdNoQuestion;
    hcmCmdNoResults: Result := SItCmdNoResults;
    hcmCmdNoContext: Result := SItCmdNoContext;
    hcmCmdNoActions: Result := SItCmdNoActions;
    hcmCmdRunUsage: Result := SItCmdRunUsage;
    hcmCmdNoEngine: Result := SItCmdNoEngine;
    hcmCmdNoAssistant: Result := SItCmdNoAssistant;
    hcmCmdNoLanguage: Result := SItCmdNoLanguage;
    hcmCmdStatsLine: Result := SItCmdStatsLine;
    hcmCmdNoStats: Result := SItCmdNoStats;
    hcmCmdDocUsage: Result := SItCmdDocUsage;
    hcmCmdUseUsage: Result := SItCmdUseUsage;
    hcmCmdNoAnswer: Result := SItCmdNoAnswer;
    hcmCmdTitleHelp: Result := SItCmdTitleHelp;
    hcmCmdTitleWho: Result := SItCmdTitleWho;
    hcmCmdTitleUse: Result := SItCmdTitleUse;
    hcmCmdTitleLang: Result := SItCmdTitleLang;
    hcmCmdTitleSearch: Result := SItCmdTitleSearch;
    hcmCmdTitlePages: Result := SItCmdTitlePages;
    hcmCmdTitleContext: Result := SItCmdTitleContext;
    hcmCmdTitleActions: Result := SItCmdTitleActions;
    hcmCmdTitleCheck: Result := SItCmdTitleCheck;
    hcmCmdTitleStats: Result := SItCmdTitleStats;
    hcmCmdTitlePrompt: Result := SItCmdTitlePrompt;
    hcmCmdTitleRun: Result := SItCmdTitleRun;
    hcmAttachTypeRefused: Result := SItAttachTypeRefused;
    hcmAttachTooLarge: Result := SItAttachTooLarge;
    hcmAttachTooMany: Result := SItAttachTooMany;
    hcmAttachTooMuch: Result := SItAttachTooMuch;
    hcmAttachEmpty: Result := SItAttachEmpty;
    hcmAttachFailed: Result := SItAttachFailed;
    hcmAttachNotSupported: Result := SItAttachNotSupported;
    hcmAttachedDocuments: Result := SItAttachedDocuments;
    hcmAttachedTextFile: Result := SItAttachedTextFile;
    hcmUiPdfAnswer: Result := SItUiPdfAnswer;
    hcmUiPdfConversation: Result := SItUiPdfConversation;
    hcmUiCopyAnswer: Result := SItUiCopyAnswer;
    hcmUiCopyConversation: Result := SItUiCopyConversation;
    hcmUiCopyPage: Result := SItUiCopyPage;
    hcmUiCopied: Result := SItUiCopied;
    hcmUiCopyFailed: Result := SItUiCopyFailed;
    hcmUiPdfPage: Result := SItUiPdfPage;
    hcmPdfAnswerTitle: Result := SItPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SItPdfConversationTitle;
    hcmPdfUser: Result := SItPdfUser;
    hcmPdfAssistant: Result := SItPdfAssistant;
    hcmPdfFilter: Result := SItPdfFilter;
    hcmPdfOpen: Result := SItPdfOpen;
    hcmPdfFailed: Result := SItPdfFailed;
    hcmPdfNoBands: Result := SItPdfNoBands;
    hcmPdfNothing: Result := SItPdfNothing;
    hcmPdfUnavailable: Result := SItPdfUnavailable;
    hcmPdfHandedOver: Result := SItPdfHandedOver;
  else
    Result := '';
  end;
end;

function SpanishMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SEsGreeting;
    hcmStubReply: Result := SEsStubReply;
    hcmIndexUnavailable: Result := SEsIndexUnavailable;
    hcmNoPageFound: Result := SEsNoPageFound;
    hcmReadMore: Result := SEsReadMore;
    hcmSeeAlso: Result := SEsSeeAlso;
    hcmClaudeNotConfigured: Result := SEsClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SEsProviderKeyMissing;
    hcmProviderNotAvailable: Result := SEsProviderNotAvailable;
    hcmProviderError: Result := SEsProviderError;
    hcmApiError: Result := SEsApiError;
    hcmEmptyReply: Result := SEsEmptyReply;
    hcmCancelled: Result := SEsCancelled;
    hcmScreenContext: Result := SEsScreenContext;
    hcmRelevantDocs: Result := SEsRelevantDocs;
    hcmSource: Result := SEsSource;
    hcmContextQuestion: Result := SEsContextQuestion;
    hcmUiTitle: Result := SEsUiTitle;
    hcmUiHelp: Result := SEsUiHelp;
    hcmUiClear: Result := SEsUiClear;
    hcmUiClose: Result := SEsUiClose;
    hcmUiPlaceholder: Result := SEsUiPlaceholder;
    hcmUiSend: Result := SEsUiSend;
    hcmUiStop: Result := SEsUiStop;
    hcmUiRetry: Result := SEsUiRetry;
    hcmUiSendError: Result := SEsUiSendError;
    hcmUiBack: Result := SEsUiBack;
    hcmUiMic: Result := SEsUiMic;
    hcmVoiceUnavailable: Result := SEsVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SEsVoiceConsentNeeded;
    hcmDocNotFound: Result := SEsDocNotFound;
    hcmActionConfirm: Result := SEsActionConfirm;
    hcmActionValues: Result := SEsActionValues;
    hcmActionConfirmTitle: Result := SEsActionConfirmTitle;
    hcmActionValuesFooter: Result := SEsActionValuesFooter;
    hcmUiAttach: Result := SEsUiAttach;
    hcmUiAttachRemove: Result := SEsUiAttachRemove;
    hcmUiChangeAssistant: Result := SEsUiChangeAssistant;
    hcmUiChangeLanguage: Result := SEsUiChangeLanguage;
    hcmCmdHelp: Result := SEsCmdHelp;
    hcmCmdWho: Result := SEsCmdWho;
    hcmCmdUse: Result := SEsCmdUse;
    hcmCmdLang: Result := SEsCmdLang;
    hcmCmdRetry: Result := SEsCmdRetry;
    hcmCmdSearch: Result := SEsCmdSearch;
    hcmCmdDoc: Result := SEsCmdDoc;
    hcmCmdPages: Result := SEsCmdPages;
    hcmCmdContext: Result := SEsCmdContext;
    hcmCmdActions: Result := SEsCmdActions;
    hcmCmdCheck: Result := SEsCmdCheck;
    hcmCmdStats: Result := SEsCmdStats;
    hcmCmdClear: Result := SEsCmdClear;
    hcmCmdPdf: Result := SEsCmdPdf;
    hcmCmdCopy: Result := SEsCmdCopy;
    hcmCmdAttach: Result := SEsCmdAttach;
    hcmCmdPrompt: Result := SEsCmdPrompt;
    hcmCmdRun: Result := SEsCmdRun;
    hcmCmdUnknown: Result := SEsCmdUnknown;
    hcmCmdProvider: Result := SEsCmdProvider;
    hcmCmdEndpoint: Result := SEsCmdEndpoint;
    hcmCmdNoIndex: Result := SEsCmdNoIndex;
    hcmCmdNoQuestion: Result := SEsCmdNoQuestion;
    hcmCmdNoResults: Result := SEsCmdNoResults;
    hcmCmdNoContext: Result := SEsCmdNoContext;
    hcmCmdNoActions: Result := SEsCmdNoActions;
    hcmCmdRunUsage: Result := SEsCmdRunUsage;
    hcmCmdNoEngine: Result := SEsCmdNoEngine;
    hcmCmdNoAssistant: Result := SEsCmdNoAssistant;
    hcmCmdNoLanguage: Result := SEsCmdNoLanguage;
    hcmCmdStatsLine: Result := SEsCmdStatsLine;
    hcmCmdNoStats: Result := SEsCmdNoStats;
    hcmCmdDocUsage: Result := SEsCmdDocUsage;
    hcmCmdUseUsage: Result := SEsCmdUseUsage;
    hcmCmdNoAnswer: Result := SEsCmdNoAnswer;
    hcmCmdTitleHelp: Result := SEsCmdTitleHelp;
    hcmCmdTitleWho: Result := SEsCmdTitleWho;
    hcmCmdTitleUse: Result := SEsCmdTitleUse;
    hcmCmdTitleLang: Result := SEsCmdTitleLang;
    hcmCmdTitleSearch: Result := SEsCmdTitleSearch;
    hcmCmdTitlePages: Result := SEsCmdTitlePages;
    hcmCmdTitleContext: Result := SEsCmdTitleContext;
    hcmCmdTitleActions: Result := SEsCmdTitleActions;
    hcmCmdTitleCheck: Result := SEsCmdTitleCheck;
    hcmCmdTitleStats: Result := SEsCmdTitleStats;
    hcmCmdTitlePrompt: Result := SEsCmdTitlePrompt;
    hcmCmdTitleRun: Result := SEsCmdTitleRun;
    hcmAttachTypeRefused: Result := SEsAttachTypeRefused;
    hcmAttachTooLarge: Result := SEsAttachTooLarge;
    hcmAttachTooMany: Result := SEsAttachTooMany;
    hcmAttachTooMuch: Result := SEsAttachTooMuch;
    hcmAttachEmpty: Result := SEsAttachEmpty;
    hcmAttachFailed: Result := SEsAttachFailed;
    hcmAttachNotSupported: Result := SEsAttachNotSupported;
    hcmAttachedDocuments: Result := SEsAttachedDocuments;
    hcmAttachedTextFile: Result := SEsAttachedTextFile;
    hcmUiPdfAnswer: Result := SEsUiPdfAnswer;
    hcmUiPdfConversation: Result := SEsUiPdfConversation;
    hcmUiCopyAnswer: Result := SEsUiCopyAnswer;
    hcmUiCopyConversation: Result := SEsUiCopyConversation;
    hcmUiCopyPage: Result := SEsUiCopyPage;
    hcmUiCopied: Result := SEsUiCopied;
    hcmUiCopyFailed: Result := SEsUiCopyFailed;
    hcmUiPdfPage: Result := SEsUiPdfPage;
    hcmPdfAnswerTitle: Result := SEsPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SEsPdfConversationTitle;
    hcmPdfUser: Result := SEsPdfUser;
    hcmPdfAssistant: Result := SEsPdfAssistant;
    hcmPdfFilter: Result := SEsPdfFilter;
    hcmPdfOpen: Result := SEsPdfOpen;
    hcmPdfFailed: Result := SEsPdfFailed;
    hcmPdfNoBands: Result := SEsPdfNoBands;
    hcmPdfNothing: Result := SEsPdfNothing;
    hcmPdfUnavailable: Result := SEsPdfUnavailable;
    hcmPdfHandedOver: Result := SEsPdfHandedOver;
  else
    Result := '';
  end;
end;

function FrenchMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SFrGreeting;
    hcmStubReply: Result := SFrStubReply;
    hcmIndexUnavailable: Result := SFrIndexUnavailable;
    hcmNoPageFound: Result := SFrNoPageFound;
    hcmReadMore: Result := SFrReadMore;
    hcmSeeAlso: Result := SFrSeeAlso;
    hcmClaudeNotConfigured: Result := SFrClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SFrProviderKeyMissing;
    hcmProviderNotAvailable: Result := SFrProviderNotAvailable;
    hcmProviderError: Result := SFrProviderError;
    hcmApiError: Result := SFrApiError;
    hcmEmptyReply: Result := SFrEmptyReply;
    hcmCancelled: Result := SFrCancelled;
    hcmScreenContext: Result := SFrScreenContext;
    hcmRelevantDocs: Result := SFrRelevantDocs;
    hcmSource: Result := SFrSource;
    hcmContextQuestion: Result := SFrContextQuestion;
    hcmUiTitle: Result := SFrUiTitle;
    hcmUiHelp: Result := SFrUiHelp;
    hcmUiClear: Result := SFrUiClear;
    hcmUiClose: Result := SFrUiClose;
    hcmUiPlaceholder: Result := SFrUiPlaceholder;
    hcmUiSend: Result := SFrUiSend;
    hcmUiStop: Result := SFrUiStop;
    hcmUiRetry: Result := SFrUiRetry;
    hcmUiSendError: Result := SFrUiSendError;
    hcmUiBack: Result := SFrUiBack;
    hcmUiMic: Result := SFrUiMic;
    hcmVoiceUnavailable: Result := SFrVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SFrVoiceConsentNeeded;
    hcmDocNotFound: Result := SFrDocNotFound;
    hcmActionConfirm: Result := SFrActionConfirm;
    hcmActionValues: Result := SFrActionValues;
    hcmActionConfirmTitle: Result := SFrActionConfirmTitle;
    hcmActionValuesFooter: Result := SFrActionValuesFooter;
    hcmUiAttach: Result := SFrUiAttach;
    hcmUiAttachRemove: Result := SFrUiAttachRemove;
    hcmUiChangeAssistant: Result := SFrUiChangeAssistant;
    hcmUiChangeLanguage: Result := SFrUiChangeLanguage;
    hcmCmdHelp: Result := SFrCmdHelp;
    hcmCmdWho: Result := SFrCmdWho;
    hcmCmdUse: Result := SFrCmdUse;
    hcmCmdLang: Result := SFrCmdLang;
    hcmCmdRetry: Result := SFrCmdRetry;
    hcmCmdSearch: Result := SFrCmdSearch;
    hcmCmdDoc: Result := SFrCmdDoc;
    hcmCmdPages: Result := SFrCmdPages;
    hcmCmdContext: Result := SFrCmdContext;
    hcmCmdActions: Result := SFrCmdActions;
    hcmCmdCheck: Result := SFrCmdCheck;
    hcmCmdStats: Result := SFrCmdStats;
    hcmCmdClear: Result := SFrCmdClear;
    hcmCmdPdf: Result := SFrCmdPdf;
    hcmCmdCopy: Result := SFrCmdCopy;
    hcmCmdAttach: Result := SFrCmdAttach;
    hcmCmdPrompt: Result := SFrCmdPrompt;
    hcmCmdRun: Result := SFrCmdRun;
    hcmCmdUnknown: Result := SFrCmdUnknown;
    hcmCmdProvider: Result := SFrCmdProvider;
    hcmCmdEndpoint: Result := SFrCmdEndpoint;
    hcmCmdNoIndex: Result := SFrCmdNoIndex;
    hcmCmdNoQuestion: Result := SFrCmdNoQuestion;
    hcmCmdNoResults: Result := SFrCmdNoResults;
    hcmCmdNoContext: Result := SFrCmdNoContext;
    hcmCmdNoActions: Result := SFrCmdNoActions;
    hcmCmdRunUsage: Result := SFrCmdRunUsage;
    hcmCmdNoEngine: Result := SFrCmdNoEngine;
    hcmCmdNoAssistant: Result := SFrCmdNoAssistant;
    hcmCmdNoLanguage: Result := SFrCmdNoLanguage;
    hcmCmdStatsLine: Result := SFrCmdStatsLine;
    hcmCmdNoStats: Result := SFrCmdNoStats;
    hcmCmdDocUsage: Result := SFrCmdDocUsage;
    hcmCmdUseUsage: Result := SFrCmdUseUsage;
    hcmCmdNoAnswer: Result := SFrCmdNoAnswer;
    hcmCmdTitleHelp: Result := SFrCmdTitleHelp;
    hcmCmdTitleWho: Result := SFrCmdTitleWho;
    hcmCmdTitleUse: Result := SFrCmdTitleUse;
    hcmCmdTitleLang: Result := SFrCmdTitleLang;
    hcmCmdTitleSearch: Result := SFrCmdTitleSearch;
    hcmCmdTitlePages: Result := SFrCmdTitlePages;
    hcmCmdTitleContext: Result := SFrCmdTitleContext;
    hcmCmdTitleActions: Result := SFrCmdTitleActions;
    hcmCmdTitleCheck: Result := SFrCmdTitleCheck;
    hcmCmdTitleStats: Result := SFrCmdTitleStats;
    hcmCmdTitlePrompt: Result := SFrCmdTitlePrompt;
    hcmCmdTitleRun: Result := SFrCmdTitleRun;
    hcmAttachTypeRefused: Result := SFrAttachTypeRefused;
    hcmAttachTooLarge: Result := SFrAttachTooLarge;
    hcmAttachTooMany: Result := SFrAttachTooMany;
    hcmAttachTooMuch: Result := SFrAttachTooMuch;
    hcmAttachEmpty: Result := SFrAttachEmpty;
    hcmAttachFailed: Result := SFrAttachFailed;
    hcmAttachNotSupported: Result := SFrAttachNotSupported;
    hcmAttachedDocuments: Result := SFrAttachedDocuments;
    hcmAttachedTextFile: Result := SFrAttachedTextFile;
    hcmUiPdfAnswer: Result := SFrUiPdfAnswer;
    hcmUiPdfConversation: Result := SFrUiPdfConversation;
    hcmUiCopyAnswer: Result := SFrUiCopyAnswer;
    hcmUiCopyConversation: Result := SFrUiCopyConversation;
    hcmUiCopyPage: Result := SFrUiCopyPage;
    hcmUiCopied: Result := SFrUiCopied;
    hcmUiCopyFailed: Result := SFrUiCopyFailed;
    hcmUiPdfPage: Result := SFrUiPdfPage;
    hcmPdfAnswerTitle: Result := SFrPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SFrPdfConversationTitle;
    hcmPdfUser: Result := SFrPdfUser;
    hcmPdfAssistant: Result := SFrPdfAssistant;
    hcmPdfFilter: Result := SFrPdfFilter;
    hcmPdfOpen: Result := SFrPdfOpen;
    hcmPdfFailed: Result := SFrPdfFailed;
    hcmPdfNoBands: Result := SFrPdfNoBands;
    hcmPdfNothing: Result := SFrPdfNothing;
    hcmPdfUnavailable: Result := SFrPdfUnavailable;
    hcmPdfHandedOver: Result := SFrPdfHandedOver;
  else
    Result := '';
  end;
end;

function GermanMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SDeGreeting;
    hcmStubReply: Result := SDeStubReply;
    hcmIndexUnavailable: Result := SDeIndexUnavailable;
    hcmNoPageFound: Result := SDeNoPageFound;
    hcmReadMore: Result := SDeReadMore;
    hcmSeeAlso: Result := SDeSeeAlso;
    hcmClaudeNotConfigured: Result := SDeClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SDeProviderKeyMissing;
    hcmProviderNotAvailable: Result := SDeProviderNotAvailable;
    hcmProviderError: Result := SDeProviderError;
    hcmApiError: Result := SDeApiError;
    hcmEmptyReply: Result := SDeEmptyReply;
    hcmCancelled: Result := SDeCancelled;
    hcmScreenContext: Result := SDeScreenContext;
    hcmRelevantDocs: Result := SDeRelevantDocs;
    hcmSource: Result := SDeSource;
    hcmContextQuestion: Result := SDeContextQuestion;
    hcmUiTitle: Result := SDeUiTitle;
    hcmUiHelp: Result := SDeUiHelp;
    hcmUiClear: Result := SDeUiClear;
    hcmUiClose: Result := SDeUiClose;
    hcmUiPlaceholder: Result := SDeUiPlaceholder;
    hcmUiSend: Result := SDeUiSend;
    hcmUiStop: Result := SDeUiStop;
    hcmUiRetry: Result := SDeUiRetry;
    hcmUiSendError: Result := SDeUiSendError;
    hcmUiBack: Result := SDeUiBack;
    hcmUiMic: Result := SDeUiMic;
    hcmVoiceUnavailable: Result := SDeVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SDeVoiceConsentNeeded;
    hcmDocNotFound: Result := SDeDocNotFound;
    hcmActionConfirm: Result := SDeActionConfirm;
    hcmActionValues: Result := SDeActionValues;
    hcmActionConfirmTitle: Result := SDeActionConfirmTitle;
    hcmActionValuesFooter: Result := SDeActionValuesFooter;
    hcmUiAttach: Result := SDeUiAttach;
    hcmUiAttachRemove: Result := SDeUiAttachRemove;
    hcmUiChangeAssistant: Result := SDeUiChangeAssistant;
    hcmUiChangeLanguage: Result := SDeUiChangeLanguage;
    hcmCmdHelp: Result := SDeCmdHelp;
    hcmCmdWho: Result := SDeCmdWho;
    hcmCmdUse: Result := SDeCmdUse;
    hcmCmdLang: Result := SDeCmdLang;
    hcmCmdRetry: Result := SDeCmdRetry;
    hcmCmdSearch: Result := SDeCmdSearch;
    hcmCmdDoc: Result := SDeCmdDoc;
    hcmCmdPages: Result := SDeCmdPages;
    hcmCmdContext: Result := SDeCmdContext;
    hcmCmdActions: Result := SDeCmdActions;
    hcmCmdCheck: Result := SDeCmdCheck;
    hcmCmdStats: Result := SDeCmdStats;
    hcmCmdClear: Result := SDeCmdClear;
    hcmCmdPdf: Result := SDeCmdPdf;
    hcmCmdCopy: Result := SDeCmdCopy;
    hcmCmdAttach: Result := SDeCmdAttach;
    hcmCmdPrompt: Result := SDeCmdPrompt;
    hcmCmdRun: Result := SDeCmdRun;
    hcmCmdUnknown: Result := SDeCmdUnknown;
    hcmCmdProvider: Result := SDeCmdProvider;
    hcmCmdEndpoint: Result := SDeCmdEndpoint;
    hcmCmdNoIndex: Result := SDeCmdNoIndex;
    hcmCmdNoQuestion: Result := SDeCmdNoQuestion;
    hcmCmdNoResults: Result := SDeCmdNoResults;
    hcmCmdNoContext: Result := SDeCmdNoContext;
    hcmCmdNoActions: Result := SDeCmdNoActions;
    hcmCmdRunUsage: Result := SDeCmdRunUsage;
    hcmCmdNoEngine: Result := SDeCmdNoEngine;
    hcmCmdNoAssistant: Result := SDeCmdNoAssistant;
    hcmCmdNoLanguage: Result := SDeCmdNoLanguage;
    hcmCmdStatsLine: Result := SDeCmdStatsLine;
    hcmCmdNoStats: Result := SDeCmdNoStats;
    hcmCmdDocUsage: Result := SDeCmdDocUsage;
    hcmCmdUseUsage: Result := SDeCmdUseUsage;
    hcmCmdNoAnswer: Result := SDeCmdNoAnswer;
    hcmCmdTitleHelp: Result := SDeCmdTitleHelp;
    hcmCmdTitleWho: Result := SDeCmdTitleWho;
    hcmCmdTitleUse: Result := SDeCmdTitleUse;
    hcmCmdTitleLang: Result := SDeCmdTitleLang;
    hcmCmdTitleSearch: Result := SDeCmdTitleSearch;
    hcmCmdTitlePages: Result := SDeCmdTitlePages;
    hcmCmdTitleContext: Result := SDeCmdTitleContext;
    hcmCmdTitleActions: Result := SDeCmdTitleActions;
    hcmCmdTitleCheck: Result := SDeCmdTitleCheck;
    hcmCmdTitleStats: Result := SDeCmdTitleStats;
    hcmCmdTitlePrompt: Result := SDeCmdTitlePrompt;
    hcmCmdTitleRun: Result := SDeCmdTitleRun;
    hcmAttachTypeRefused: Result := SDeAttachTypeRefused;
    hcmAttachTooLarge: Result := SDeAttachTooLarge;
    hcmAttachTooMany: Result := SDeAttachTooMany;
    hcmAttachTooMuch: Result := SDeAttachTooMuch;
    hcmAttachEmpty: Result := SDeAttachEmpty;
    hcmAttachFailed: Result := SDeAttachFailed;
    hcmAttachNotSupported: Result := SDeAttachNotSupported;
    hcmAttachedDocuments: Result := SDeAttachedDocuments;
    hcmAttachedTextFile: Result := SDeAttachedTextFile;
    hcmUiPdfAnswer: Result := SDeUiPdfAnswer;
    hcmUiPdfConversation: Result := SDeUiPdfConversation;
    hcmUiCopyAnswer: Result := SDeUiCopyAnswer;
    hcmUiCopyConversation: Result := SDeUiCopyConversation;
    hcmUiCopyPage: Result := SDeUiCopyPage;
    hcmUiCopied: Result := SDeUiCopied;
    hcmUiCopyFailed: Result := SDeUiCopyFailed;
    hcmUiPdfPage: Result := SDeUiPdfPage;
    hcmPdfAnswerTitle: Result := SDePdfAnswerTitle;
    hcmPdfConversationTitle: Result := SDePdfConversationTitle;
    hcmPdfUser: Result := SDePdfUser;
    hcmPdfAssistant: Result := SDePdfAssistant;
    hcmPdfFilter: Result := SDePdfFilter;
    hcmPdfOpen: Result := SDePdfOpen;
    hcmPdfFailed: Result := SDePdfFailed;
    hcmPdfNoBands: Result := SDePdfNoBands;
    hcmPdfNothing: Result := SDePdfNothing;
    hcmPdfUnavailable: Result := SDePdfUnavailable;
    hcmPdfHandedOver: Result := SDePdfHandedOver;
  else
    Result := '';
  end;
end;

function PortugueseMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SPtGreeting;
    hcmStubReply: Result := SPtStubReply;
    hcmIndexUnavailable: Result := SPtIndexUnavailable;
    hcmNoPageFound: Result := SPtNoPageFound;
    hcmReadMore: Result := SPtReadMore;
    hcmSeeAlso: Result := SPtSeeAlso;
    hcmClaudeNotConfigured: Result := SPtClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SPtProviderKeyMissing;
    hcmProviderNotAvailable: Result := SPtProviderNotAvailable;
    hcmProviderError: Result := SPtProviderError;
    hcmApiError: Result := SPtApiError;
    hcmEmptyReply: Result := SPtEmptyReply;
    hcmCancelled: Result := SPtCancelled;
    hcmScreenContext: Result := SPtScreenContext;
    hcmRelevantDocs: Result := SPtRelevantDocs;
    hcmSource: Result := SPtSource;
    hcmContextQuestion: Result := SPtContextQuestion;
    hcmUiTitle: Result := SPtUiTitle;
    hcmUiHelp: Result := SPtUiHelp;
    hcmUiClear: Result := SPtUiClear;
    hcmUiClose: Result := SPtUiClose;
    hcmUiPlaceholder: Result := SPtUiPlaceholder;
    hcmUiSend: Result := SPtUiSend;
    hcmUiStop: Result := SPtUiStop;
    hcmUiRetry: Result := SPtUiRetry;
    hcmUiSendError: Result := SPtUiSendError;
    hcmUiBack: Result := SPtUiBack;
    hcmUiMic: Result := SPtUiMic;
    hcmVoiceUnavailable: Result := SPtVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SPtVoiceConsentNeeded;
    hcmDocNotFound: Result := SPtDocNotFound;
    hcmActionConfirm: Result := SPtActionConfirm;
    hcmActionValues: Result := SPtActionValues;
    hcmActionConfirmTitle: Result := SPtActionConfirmTitle;
    hcmActionValuesFooter: Result := SPtActionValuesFooter;
    hcmUiAttach: Result := SPtUiAttach;
    hcmUiAttachRemove: Result := SPtUiAttachRemove;
    hcmUiChangeAssistant: Result := SPtUiChangeAssistant;
    hcmUiChangeLanguage: Result := SPtUiChangeLanguage;
    hcmCmdHelp: Result := SPtCmdHelp;
    hcmCmdWho: Result := SPtCmdWho;
    hcmCmdUse: Result := SPtCmdUse;
    hcmCmdLang: Result := SPtCmdLang;
    hcmCmdRetry: Result := SPtCmdRetry;
    hcmCmdSearch: Result := SPtCmdSearch;
    hcmCmdDoc: Result := SPtCmdDoc;
    hcmCmdPages: Result := SPtCmdPages;
    hcmCmdContext: Result := SPtCmdContext;
    hcmCmdActions: Result := SPtCmdActions;
    hcmCmdCheck: Result := SPtCmdCheck;
    hcmCmdStats: Result := SPtCmdStats;
    hcmCmdClear: Result := SPtCmdClear;
    hcmCmdPdf: Result := SPtCmdPdf;
    hcmCmdCopy: Result := SPtCmdCopy;
    hcmCmdAttach: Result := SPtCmdAttach;
    hcmCmdPrompt: Result := SPtCmdPrompt;
    hcmCmdRun: Result := SPtCmdRun;
    hcmCmdUnknown: Result := SPtCmdUnknown;
    hcmCmdProvider: Result := SPtCmdProvider;
    hcmCmdEndpoint: Result := SPtCmdEndpoint;
    hcmCmdNoIndex: Result := SPtCmdNoIndex;
    hcmCmdNoQuestion: Result := SPtCmdNoQuestion;
    hcmCmdNoResults: Result := SPtCmdNoResults;
    hcmCmdNoContext: Result := SPtCmdNoContext;
    hcmCmdNoActions: Result := SPtCmdNoActions;
    hcmCmdRunUsage: Result := SPtCmdRunUsage;
    hcmCmdNoEngine: Result := SPtCmdNoEngine;
    hcmCmdNoAssistant: Result := SPtCmdNoAssistant;
    hcmCmdNoLanguage: Result := SPtCmdNoLanguage;
    hcmCmdStatsLine: Result := SPtCmdStatsLine;
    hcmCmdNoStats: Result := SPtCmdNoStats;
    hcmCmdDocUsage: Result := SPtCmdDocUsage;
    hcmCmdUseUsage: Result := SPtCmdUseUsage;
    hcmCmdNoAnswer: Result := SPtCmdNoAnswer;
    hcmCmdTitleHelp: Result := SPtCmdTitleHelp;
    hcmCmdTitleWho: Result := SPtCmdTitleWho;
    hcmCmdTitleUse: Result := SPtCmdTitleUse;
    hcmCmdTitleLang: Result := SPtCmdTitleLang;
    hcmCmdTitleSearch: Result := SPtCmdTitleSearch;
    hcmCmdTitlePages: Result := SPtCmdTitlePages;
    hcmCmdTitleContext: Result := SPtCmdTitleContext;
    hcmCmdTitleActions: Result := SPtCmdTitleActions;
    hcmCmdTitleCheck: Result := SPtCmdTitleCheck;
    hcmCmdTitleStats: Result := SPtCmdTitleStats;
    hcmCmdTitlePrompt: Result := SPtCmdTitlePrompt;
    hcmCmdTitleRun: Result := SPtCmdTitleRun;
    hcmAttachTypeRefused: Result := SPtAttachTypeRefused;
    hcmAttachTooLarge: Result := SPtAttachTooLarge;
    hcmAttachTooMany: Result := SPtAttachTooMany;
    hcmAttachTooMuch: Result := SPtAttachTooMuch;
    hcmAttachEmpty: Result := SPtAttachEmpty;
    hcmAttachFailed: Result := SPtAttachFailed;
    hcmAttachNotSupported: Result := SPtAttachNotSupported;
    hcmAttachedDocuments: Result := SPtAttachedDocuments;
    hcmAttachedTextFile: Result := SPtAttachedTextFile;
    hcmUiPdfAnswer: Result := SPtUiPdfAnswer;
    hcmUiPdfConversation: Result := SPtUiPdfConversation;
    hcmUiCopyAnswer: Result := SPtUiCopyAnswer;
    hcmUiCopyConversation: Result := SPtUiCopyConversation;
    hcmUiCopyPage: Result := SPtUiCopyPage;
    hcmUiCopied: Result := SPtUiCopied;
    hcmUiCopyFailed: Result := SPtUiCopyFailed;
    hcmUiPdfPage: Result := SPtUiPdfPage;
    hcmPdfAnswerTitle: Result := SPtPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SPtPdfConversationTitle;
    hcmPdfUser: Result := SPtPdfUser;
    hcmPdfAssistant: Result := SPtPdfAssistant;
    hcmPdfFilter: Result := SPtPdfFilter;
    hcmPdfOpen: Result := SPtPdfOpen;
    hcmPdfFailed: Result := SPtPdfFailed;
    hcmPdfNoBands: Result := SPtPdfNoBands;
    hcmPdfNothing: Result := SPtPdfNothing;
    hcmPdfUnavailable: Result := SPtPdfUnavailable;
    hcmPdfHandedOver: Result := SPtPdfHandedOver;
  else
    Result := '';
  end;
end;

function HelpChatMsg(const AId: THelpChatMsgId; const ALanguage: THelpChatLanguage): string;
begin
  case HelpChatResolveLanguage(ALanguage) of
    hclItalian: Result := ItalianMsg(AId);
    hclSpanish: Result := SpanishMsg(AId);
    hclFrench: Result := FrenchMsg(AId);
    hclGerman: Result := GermanMsg(AId);
    hclPortuguese: Result := PortugueseMsg(AId);
  else
    Result := EnglishMsg(AId);
  end;
end;

function HelpChatMsgFmt(const AId: THelpChatMsgId; const AArgs: array of const;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := Format(HelpChatMsg(AId, ALanguage), AArgs);
end;

end.
