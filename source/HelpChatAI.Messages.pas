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
///  French, German and Portuguese), selectable at runtime. Two channels,
///  kept distinct on purpose: the Pascal side reads them through
///  <see cref="HelpChatMsg" />; the JavaScript side of the panel receives
///  the UI labels as a dictionary produced by the transport layer.
///  Strings are <c>resourcestring</c>s so the classic resource-DLL translation
///  path also works for further languages.
///
///  A word on the words: since 1.7 what the user switches between in the
///  panel is a <i>model</i>, and the assistant is the profile. Several
///  identifiers here were named before that (<c>hcmUiChangeAssistant</c>,
///  <c>hcmCmdNoAssistant</c>) and still say "assistant" for a model: they
///  are kept because code refers to them by name.
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
    hclGerman, hclPortuguese, hclNorwegian, hclSwedish, hclDanish);
  /// <summary>A choice of languages (<c>hclAuto</c> is never one of them).</summary>
  THelpChatLanguages = set of THelpChatLanguage;

const
  /// <summary>Every language the strings are translated into.</summary>
  HELPCHAT_ALL_LANGUAGES = [hclEnglish, hclItalian, hclSpanish, hclFrench, hclGerman,
    hclPortuguese, hclNorwegian, hclSwedish, hclDanish];

type

  /// <summary>Identifiers of every localized string used by the engine.
  /// Every member has a string in each of the six tables (a test fails
  /// when one is missing, another when a translation loses or adds a
  /// placeholder).</summary>
  THelpChatMsgId = (
    // Engine / providers
    /// <summary>First bubble of an empty conversation.</summary>
    hcmGreeting,
    /// <summary>The whole answer of the <c>stub</c> provider.</summary>
    hcmStubReply,
    /// <summary>The <c>docsearch</c> answer without an index: %s is the
    /// base URL of the documentation, as the target of a Markdown link.</summary>
    hcmIndexUnavailable,
    /// <summary>The <c>docsearch</c> answer when no page scores: %s is the
    /// base URL of the documentation.</summary>
    hcmNoPageFound,
    /// <summary>The docsearch provider: the label of the link to the page the
    /// answer came from.</summary>
    hcmReadMore,
    /// <summary>The docsearch provider: introduces the other pages that may
    /// help.</summary>
    hcmSeeAlso,
    /// <summary>The <c>claude</c> provider without a key: %s twice, the
    /// folder of the shared configuration file and the folder of the
    /// per-user one.</summary>
    hcmClaudeNotConfigured,
    /// <summary>A provider that needs a key and has none: %0:s is its name,
    /// %1:s the settings section, %2:s the environment variable, %3:s and %4:s
    /// the two folders where a helpchatai.json would be read.</summary>
    hcmProviderKeyMissing,
    /// <summary>The configured provider is not linked into the application:
    /// %s is its name, %s the registered ones.</summary>
    hcmProviderNotAvailable,
    /// <summary>A stream that reports an error without a message.</summary>
    hcmProviderError,
    /// <summary>A refused request whose body carries no message: %d is the
    /// HTTP status, %s its text. Used by every provider with a model.</summary>
    hcmApiError,
    /// <summary>The same, with the address that was called (%s, no query)
    /// and the model asked for (%s): a provider pointed at the endpoint of
    /// another service says so at a glance.</summary>
    hcmApiErrorAt,
    /// <summary>A reply that ended with no text at all.</summary>
    hcmEmptyReply,
    /// <summary>Content of a reply cancelled before its first token, and
    /// message of <c>EHelpChatCancelled</c>.</summary>
    hcmCancelled,
    /// <summary>The sentence of the system prompt about where the user is:
    /// %s is the label of the screen, %s its type. Goes to the model, in
    /// the language of the chat.</summary>
    hcmScreenContext,
    /// <summary>Heading of the documentation excerpts in the system prompt.</summary>
    hcmRelevantDocs,
    /// <summary>The word in front of a citation ("Source"), in the prompt
    /// and in the line the engine adds to an answer that cited nothing.</summary>
    hcmSource,
    /// <summary>The question asked on behalf of a user who opened the chat
    /// from a screen without typing one: %s is the label of the screen.</summary>
    hcmContextQuestion,
    // Panel UI labels (injected into the page by the transport)
    /// <summary>Header of the page when the component names no assistant.</summary>
    hcmUiTitle,
    /// <summary>Caption of the chat window when the component gives none.</summary>
    hcmUiHelp,
    /// <summary>Panel: the button that clears the conversation.</summary>
    hcmUiClear,
    /// <summary>Panel: the label of a button that closes something.</summary>
    hcmUiClose,
    /// <summary>Panel: what the empty question box says.</summary>
    hcmUiPlaceholder,
    /// <summary>Panel: the button that sends the question.</summary>
    hcmUiSend,
    /// <summary>Panel: the button that stops a reply while it is being
    /// written.</summary>
    hcmUiStop,
    /// <summary>Panel: the button that asks the last question again.</summary>
    hcmUiRetry,
    /// <summary>Panel: a request of the page did not reach the server, or was
    /// refused.</summary>
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
    /// something: %s is the action, %s its description, %s the block of the
    /// values the model wrote.</summary>
    hcmActionConfirm,
    /// <summary>Label over the parameter values in that question: they were
    /// written by the model, and the user is told so.</summary>
    hcmActionValues,
    /// <summary>Main instruction of the confirmation dialog, with the name
    /// of the action.</summary>
    hcmActionConfirmTitle,
    /// <summary>Footer of the confirmation dialog, under the values.</summary>
    hcmActionValuesFooter,
    /// <summary>Added to a reply whose last allowed step still asked for an
    /// action: it was not run, and the user is told instead of being left
    /// with a reply that says it did something.</summary>
    hcmActionsNotRun,
    /// <summary>Paper-clip button, left of the question box.</summary>
    hcmUiAttach,
    /// <summary>Title of the button that takes an attachment away.</summary>
    hcmUiAttachRemove,
    /// <summary>Tooltip of the model badge when there is a list of models
    /// to pick from (the name predates 1.7, when a model of the list was
    /// called an assistant).</summary>
    hcmUiChangeAssistant,
    /// <summary>Tooltip of the flag, when more than one language can be chosen.</summary>
    hcmUiChangeLanguage,
    // The slash commands of the panel (HelpChatAI.Commands): one description
    // each, in the order of THelpChatCommand, then what their answers say.
    hcmCmdHelp,
    /// <summary>Description of <c>/who</c>.</summary>
    hcmCmdWho,
    /// <summary>Description of <c>/use</c>.</summary>
    hcmCmdUse,
    /// <summary>Description of <c>/lang</c>.</summary>
    hcmCmdLang,
    /// <summary>Description of <c>/retry</c>.</summary>
    hcmCmdRetry,
    /// <summary>Description of <c>/search</c>.</summary>
    hcmCmdSearch,
    /// <summary>Description of <c>/doc</c>.</summary>
    hcmCmdDoc,
    /// <summary>Description of <c>/pages</c>.</summary>
    hcmCmdPages,
    /// <summary>Description of <c>/context</c>.</summary>
    hcmCmdContext,
    /// <summary>Description of <c>/actions</c>.</summary>
    hcmCmdActions,
    /// <summary>Description of <c>/check</c>.</summary>
    hcmCmdCheck,
    /// <summary>Description of <c>/stats</c>.</summary>
    hcmCmdStats,
    /// <summary>Description of <c>/clear</c>.</summary>
    hcmCmdClear,
    /// <summary>Description of <c>/pdf</c>.</summary>
    hcmCmdPdf,
    /// <summary>Description of <c>/copy</c>.</summary>
    hcmCmdCopy,
    /// <summary>Description of <c>/attach</c>.</summary>
    hcmCmdAttach,
    /// <summary>Description of <c>/prompt</c>.</summary>
    hcmCmdPrompt,
    /// <summary>Description of <c>/run</c>.</summary>
    hcmCmdRun,
    /// <summary>%s is the word typed after the slash.</summary>
    hcmCmdUnknown,
    /// <summary>Answer of <c>/who</c>: the label of the provider.</summary>
    hcmCmdProvider,
    /// <summary>Answer of <c>/who</c>: the label of the endpoint.</summary>
    hcmCmdEndpoint,
    /// <summary>Answer of <c>/search</c> and <c>/pages</c> when no index is
    /// loaded.</summary>
    hcmCmdNoIndex,
    /// <summary>Answer of a command about the last question, when none was
    /// asked yet.</summary>
    hcmCmdNoQuestion,
    /// <summary>%s is what was searched.</summary>
    hcmCmdNoResults,
    /// <summary>Answer of <c>/prompt</c>: %s is the terms the model translated
    /// the question into for the search.</summary>
    hcmCmdSearchTerms,
    /// <summary>Answer of <c>/prompt</c>: heading of the part of the prompt
    /// that does not change from one question to the next.</summary>
    hcmCmdPromptStable,
    /// <summary>Answer of <c>/prompt</c>: heading of the part that goes with
    /// the question (now, the screen, the excerpts).</summary>
    hcmCmdPromptContext,
    /// <summary>Answer of <c>/prompt</c>: heading of the prompt of a provider
    /// that does not split it.</summary>
    hcmCmdPromptWhole,
    /// <summary>Answer of <c>/context</c> when the host sent no
    /// screen.</summary>
    hcmCmdNoContext,
    /// <summary>Answer of <c>/actions</c> when there is none.</summary>
    hcmCmdNoActions,
    /// <summary>Answer of <c>/run</c> with no action named.</summary>
    hcmCmdRunUsage,
    /// <summary>Answer of a command that needs the engine, when it is not
    /// running here.</summary>
    hcmCmdNoEngine,
    /// <summary>/use or /retry named a model that is not in the list: %s is
    /// the name asked for.</summary>
    hcmCmdNoAssistant,
    /// <summary>/lang named a language that is not offered: %s is what was typed.</summary>
    hcmCmdNoLanguage,
    /// <summary>%s twice: time to the first token, time to the end.</summary>
    hcmCmdStatsLine,
    /// <summary>Answer of <c>/stats</c> before the first answer.</summary>
    hcmCmdNoStats,
    /// <summary>Answer of <c>/doc</c> with no page named.</summary>
    hcmCmdDocUsage,
    /// <summary>Answer of <c>/use</c> with no model named.</summary>
    hcmCmdUseUsage,
    /// <summary>Answer of <c>/copy</c> when there is nothing to copy.</summary>
    hcmCmdNoAnswer,
    /// <summary>The first line of the answer of a command ("Available actions"):
    /// the page adds " (/name):" after it.</summary>
    hcmCmdTitleHelp,
    /// <summary>Heading of the answer of <c>/who</c>.</summary>
    hcmCmdTitleWho,
    /// <summary>Heading of the answer of <c>/use</c>.</summary>
    hcmCmdTitleUse,
    /// <summary>Heading of the answer of <c>/lang</c>.</summary>
    hcmCmdTitleLang,
    /// <summary>Heading of the answer of <c>/search</c>: %s is what was
    /// searched.</summary>
    hcmCmdTitleSearch,
    /// <summary>Heading of the answer of <c>/pages</c>.</summary>
    hcmCmdTitlePages,
    /// <summary>Heading of the answer of <c>/context</c>.</summary>
    hcmCmdTitleContext,
    /// <summary>Heading of the answer of <c>/actions</c>.</summary>
    hcmCmdTitleActions,
    /// <summary>Heading of the answer of <c>/check</c>.</summary>
    hcmCmdTitleCheck,
    /// <summary>Heading of the answer of <c>/stats</c>.</summary>
    hcmCmdTitleStats,
    /// <summary>Heading of the answer of <c>/prompt</c>.</summary>
    hcmCmdTitlePrompt,
    /// <summary>Heading of the answer of <c>/run</c>.</summary>
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
    /// <summary>Heading of the text attachments, in front of the question
    /// they travel with (the user turn, not the system prompt).</summary>
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
    hcmPdfHandedOver,
    /// <summary>The confirmation of <c>fill_form</c> (skill "forms"): %s is
    /// the form.</summary>
    hcmSkillFill,
    /// <summary>The confirmation of <c>press_command</c> (skill "commands"):
    /// %0:s the button, %1:s the form.</summary>
    hcmSkillPress,
    /// <summary>The confirmation of <c>cancel_edit</c> (skill "forms"): %s is
    /// the form.</summary>
    hcmSkillCancel,
    /// <summary>Description of <c>/skills</c>.</summary>
    hcmCmdSkills,
    /// <summary>Heading of the answer of <c>/skills</c>.</summary>
    hcmCmdTitleSkills,
    /// <summary><c>/skills</c> when <c>Settings.Skills</c> names none.</summary>
    hcmCmdNoSkills,
    /// <summary><c>/skills</c>, next to a name no skill of the application has.</summary>
    hcmCmdSkillUnknown,
    /// <summary>What the skill "forms" does, as the user reads it in <c>/skills</c>.</summary>
    hcmSkillForms,
    /// <summary>What the skill "commands" does, for <c>/skills</c>.</summary>
    hcmSkillCommands,
    /// <summary>What the skill "records" does, for <c>/skills</c>.</summary>
    hcmSkillRecords,
    /// <summary>What the skill "pages" does, for <c>/skills</c>.</summary>
    hcmSkillPages,
    /// <summary>Added to a reply the service stopped at the limit of tokens
    /// (<c>MaxTokens</c>): the user is told it is not whole, instead of being
    /// left with a sentence that ends in the middle.</summary>
    hcmReplyCut,
    /// <summary>The button that allows an action, in the confirmation
    /// dialog: in the language of the chat, not in the one the RTL was
    /// built with.</summary>
    hcmConfirmYes,
    /// <summary>The button that refuses an action.</summary>
    hcmConfirmNo);

/// <summary>Returns the string <c>AId</c> in <c>ALanguage</c> (<c>hclAuto</c> =
/// <see cref="HelpChatDefaultLanguage" />, resolved against the OS locale).
/// Safe from any thread. Never empty for a member of the enumeration.</summary>
function HelpChatMsg(const AId: THelpChatMsgId;
  const ALanguage: THelpChatLanguage = hclAuto): string;

/// <summary>Like <see cref="HelpChatMsg" /> followed by <c>Format</c>: the
/// arguments must be those the string of <c>AId</c> expects, or
/// <c>Format</c> raises <c>EConvertError</c>.</summary>
function HelpChatMsgFmt(const AId: THelpChatMsgId; const AArgs: array of const;
  const ALanguage: THelpChatLanguage = hclAuto): string;

/// <summary>Replaces the string <c>AId</c> for the whole process: in
/// <c>ALanguage</c>, or in every language with <c>hclAuto</c> (a text for one
/// language wins over one for all). An empty <c>AText</c> takes the
/// replacement away. What <see cref="HelpChatMsg" /> answers from then on -
/// the labels of the panel too, which are read through it when the page is
/// rendered. A string with placeholders must keep them: a <c>%s</c> lost or
/// added makes <c>Format</c> raise where the string is used. Safe from any
/// thread.</summary>
procedure HelpChatSetMsg(const AId: THelpChatMsgId; const AText: string;
  const ALanguage: THelpChatLanguage = hclAuto);

/// <summary>Takes every replacement of <see cref="HelpChatSetMsg" /> away.</summary>
procedure HelpChatClearMsgs;

/// <summary>Resolves <c>hclAuto</c> to a concrete language:
/// <see cref="HelpChatDefaultLanguage" /> when that is set, the OS user
/// locale otherwise.</summary>
function HelpChatResolveLanguage(const ALanguage: THelpChatLanguage): THelpChatLanguage;

/// <summary>The language of the OS user locale, when it is one of ours;
/// English otherwise.</summary>
function HelpChatSystemLanguage: THelpChatLanguage;

/// <summary>Two-letter ISO code of a language ("en", "it", "es"...): what a
/// configuration file and the state file store. <c>hclAuto</c> is resolved
/// first, so the answer is never "auto".</summary>
function HelpChatLanguageCode(const ALanguage: THelpChatLanguage): string;

/// <summary>English name of a language ("English", "Italian"...), the form
/// used when instructing the model; <c>hclAuto</c> is resolved first.</summary>
function HelpChatLanguageName(const ALanguage: THelpChatLanguage): string;

/// <summary>The name of a resolved language in that language ("Italiano",
/// "Español"...): what the menu of the panel shows, so that a user who
/// does not read the current language still finds their own.</summary>
function HelpChatLanguageNativeName(const ALanguage: THelpChatLanguage): string;

/// <summary>The language of an ISO code, an English name or a native name
/// ("es", "Spanish", "Español"), case-insensitive; "auto" is <c>hclAuto</c>,
/// and "nb" (Bokmål, what Windows calls it) is Norwegian like "no".
/// False when the value is none of them.</summary>
function HelpChatLanguageFromCode(const AValue: string;
  out ALanguage: THelpChatLanguage): Boolean;

/// <summary>The languages of a set, in the order of the enumeration;
/// <c>hclAuto</c>, which is not a language, is left out.</summary>
function HelpChatLanguageList(const ALanguages: THelpChatLanguages): TArray<THelpChatLanguage>;

var
  /// <summary>Language used when a caller passes <c>hclAuto</c>. Default
  /// <c>hclAuto</c> (OS locale). An engine sets it when it starts, from
  /// <c>Settings.ResolveLanguage</c>, and again when the user picks a
  /// language in the panel. It is one variable for the whole process: with
  /// several assistants, each with its own engine, the last one to start or
  /// to switch decides for every <c>hclAuto</c> - which is why whoever has
  /// settings at hand should pass their resolved language instead of
  /// relying on it. Written and read without a lock.</summary>
  HelpChatDefaultLanguage: THelpChatLanguage = hclAuto;

implementation

uses
  System.SyncObjs;

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
  SEnApiError = '%s API error (HTTP %d %s).';
  SEnApiErrorAt = '%s API error (HTTP %d %s) from %s, model %s.';
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
  SEnUiChangeAssistant = 'Change model';
  SEnUiChangeLanguage = 'Change language';
  SEnCmdHelp = 'The commands you can type';
  SEnCmdWho = 'Who is answering: model and provider';
  SEnCmdUse = 'Switch to the named model: /use Gemini';
  SEnCmdLang = 'Switch the language of the chat: /lang it';
  SEnCmdRetry = 'Ask the last question again, to another model if named';
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
  SEnCmdPromptStable = 'Cached prompt';
  SEnCmdPromptContext = 'Context';
  SEnCmdPromptWhole = 'System prompt';
  SEnCmdSearchTerms = 'The question was searched together with these terms of the model (TranslateSearch): %s';
  SEnCmdNoContext = 'No screen context was sent.';
  SEnCmdNoActions = 'This application registered no actions.';
  SEnCmdRunUsage = 'Usage: /run action name=value name2="a value with spaces"';
  SEnCmdNoEngine = 'The engine is not running.';
  SEnCmdNoAssistant = 'No model named "%s".';
  SEnCmdNoLanguage = 'No language "%s" among those this chat offers.';
  SEnCmdStatsLine = 'Last answer: first token after %s, complete after %s.';
  SEnCmdNoStats = 'No answer yet.';
  SEnCmdDocUsage = 'Usage: /doc page';
  SEnCmdUseUsage = 'Usage: /use model';
  SEnCmdNoAnswer = 'No answer to copy.';
  SEnCmdTitleHelp = 'Available commands';
  SEnCmdTitleWho = 'Model in use';
  SEnCmdTitleUse = 'Model changed';
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
  SEnConfirmYes = 'Yes';
  SEnConfirmNo = 'No';
  SEnReplyCut =
    '(The answer was cut: it reached the length limit of a reply. Ask to continue.)';
  SEnActionsNotRun =
    '(One more action was requested but not run: the limit of steps for one reply was reached. Ask again to continue.)';
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
  SEnSkillFill = 'The assistant wants to fill these fields of "%s". Nothing is saved: you review the values and save.';
  SEnSkillPress = 'The assistant wants to press "%0:s" on "%1:s".';
  SEnSkillCancel = 'The assistant wants to abandon the changes not saved on "%s".';
  SEnCmdSkills = 'The skills of the assistant: what it can do on any window';
  SEnCmdTitleSkills = 'Skills of the assistant';
  SEnCmdNoSkills = 'This assistant has no skills.';
  SEnCmdSkillUnknown = 'not available in this application';
  SEnSkillForms = 'Describes the window in front of you and fills its fields, asking first and never saving.';
  SEnSkillCommands = 'Lists the buttons of the window and presses one, asking first; never one that saves.';
  SEnSkillRecords = 'Counts the records of the lists of the window and moves to the one you name.';
  SEnSkillPages = 'Brings a page (a tab) of the window to the front.';

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
  SItApiError = 'Errore API %s (HTTP %d %s).';
  SItApiErrorAt = 'Errore API %s (HTTP %d %s) da %s, modello %s.';
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
  SItUiChangeAssistant = 'Cambia modello';
  SItUiChangeLanguage = 'Cambia lingua';
  SItCmdHelp = 'I comandi che puoi scrivere';
  SItCmdWho = 'Chi sta rispondendo: modello e provider';
  SItCmdUse = 'Passa al modello indicato: /use Gemini';
  SItCmdLang = 'Cambia la lingua della chat: /lang en';
  SItCmdRetry = 'Ripete l''ultima domanda, a un altro modello se indicato';
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
  SItCmdPromptStable = 'Prompt in cache';
  SItCmdPromptContext = 'Contesto';
  SItCmdPromptWhole = 'Prompt di sistema';
  SItCmdSearchTerms = 'La domanda è stata cercata insieme a questi termini del modello (TranslateSearch): %s';
  SItCmdNoContext = 'Nessun contesto di schermata è stato inviato.';
  SItCmdNoActions = 'Questa applicazione non ha registrato azioni.';
  SItCmdRunUsage = 'Uso: /run azione nome=valore nome2="un valore con spazi"';
  SItCmdNoEngine = 'Il motore non è in esecuzione.';
  SItCmdNoAssistant = 'Nessun modello di nome "%s".';
  SItCmdNoLanguage = 'Nessuna lingua "%s" tra quelle offerte da questa chat.';
  SItCmdStatsLine = 'Ultima risposta: primo token dopo %s, completa dopo %s.';
  SItCmdNoStats = 'Nessuna risposta ancora.';
  SItCmdDocUsage = 'Uso: /doc pagina';
  SItCmdUseUsage = 'Uso: /use modello';
  SItCmdNoAnswer = 'Nessuna risposta da copiare.';
  SItCmdTitleHelp = 'Comandi disponibili';
  SItCmdTitleWho = 'Modello in uso';
  SItCmdTitleUse = 'Modello cambiato';
  SItCmdTitleLang = 'Lingue della chat';
  SItCmdTitleSearch = 'Pagine della documentazione per "%s"';
  SItCmdTitlePages = 'Pagine della documentazione';
  SItCmdTitleContext = 'Contesto della schermata';
  SItCmdTitleActions = 'Azioni disponibili';
  SItCmdTitleCheck = 'Controllo della configurazione';
  SItCmdTitleStats = 'Tempi dell''ultima risposta';
  SItCmdTitlePrompt = 'Prompt di sistema dell''ultima domanda';
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
  SItConfirmYes = 'Sì';
  SItConfirmNo = 'No';
  SItReplyCut =
    '(La risposta è stata interrotta: ha raggiunto il limite di lunghezza di una risposta. Chiedi di continuare.)';
  SItActionsNotRun =
    '(È stata richiesta un''altra azione ma non è stata eseguita: raggiunto il limite di passaggi per una risposta. Chiedi di nuovo per continuare.)';
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
  SItSkillFill = 'L''assistente vuole compilare questi campi di "%s". Nulla viene salvato: controlli tu i valori e salvi.';
  SItSkillPress = 'L''assistente vuole premere "%0:s" in "%1:s".';
  SItSkillCancel = 'L''assistente vuole abbandonare le modifiche non salvate in "%s".';
  SItCmdSkills = 'Le skill dell''assistente: cosa sa fare su qualsiasi finestra';
  SItCmdTitleSkills = 'Skill dell''assistente';
  SItCmdNoSkills = 'Questo assistente non ha skill.';
  SItCmdSkillUnknown = 'non disponibile in questa applicazione';
  SItSkillForms = 'Descrive la finestra che hai davanti e ne compila i campi, chiedendo prima e senza mai salvare.';
  SItSkillCommands = 'Elenca i pulsanti della finestra e ne preme uno, chiedendo prima; mai uno che salva.';
  SItSkillRecords = 'Conta i record delle liste della finestra e si sposta su quello che nomini.';
  SItSkillPages = 'Porta in primo piano una pagina (una scheda) della finestra.';

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
  SEsApiError = 'Error de la API de %s (HTTP %d %s).';
  SEsApiErrorAt = 'Error de la API de %s (HTTP %d %s) desde %s, modelo %s.';
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
  SEsUiChangeAssistant = 'Cambiar de modelo';
  SEsUiChangeLanguage = 'Cambiar de idioma';
  SEsCmdHelp = 'Los comandos que puedes escribir';
  SEsCmdWho = 'Quién responde: modelo y proveedor';
  SEsCmdUse = 'Cambia al modelo indicado: /use Gemini';
  SEsCmdLang = 'Cambia el idioma del chat: /lang en';
  SEsCmdRetry = 'Repite la última pregunta, a otro modelo si se indica';
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
  SEsCmdPromptStable = 'Prompt en caché';
  SEsCmdPromptContext = 'Contexto';
  SEsCmdPromptWhole = 'Prompt del sistema';
  SEsCmdSearchTerms = 'La pregunta se buscó junto con estos términos del modelo (TranslateSearch): %s';
  SEsCmdNoContext = 'No se ha enviado ningún contexto de pantalla.';
  SEsCmdNoActions = 'Esta aplicación no ha registrado ninguna acción.';
  SEsCmdRunUsage = 'Uso: /run acción nombre=valor nombre2="un valor con espacios"';
  SEsCmdNoEngine = 'El motor no está en marcha.';
  SEsCmdNoAssistant = 'No hay ningún modelo llamado "%s".';
  SEsCmdNoLanguage = 'No hay ningún idioma "%s" entre los que ofrece este chat.';
  SEsCmdStatsLine = 'Última respuesta: primer token tras %s, completa tras %s.';
  SEsCmdNoStats = 'Todavía no hay ninguna respuesta.';
  SEsCmdDocUsage = 'Uso: /doc página';
  SEsCmdUseUsage = 'Uso: /use modelo';
  SEsCmdNoAnswer = 'No hay ninguna respuesta que copiar.';
  SEsCmdTitleHelp = 'Comandos disponibles';
  SEsCmdTitleWho = 'Modelo en uso';
  SEsCmdTitleUse = 'Modelo cambiado';
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
  SEsConfirmYes = 'Sí';
  SEsConfirmNo = 'No';
  SEsReplyCut =
    '(La respuesta se cortó: alcanzó el límite de longitud de una respuesta. Pide que continúe.)';
  SEsActionsNotRun =
    '(Se pidió otra acción pero no se ejecutó: se alcanzó el límite de pasos de una respuesta. Vuelve a preguntar para continuar.)';
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
  SEsSkillFill = 'El asistente quiere rellenar estos campos de "%s". No se guarda nada: tú revisas los valores y guardas.';
  SEsSkillPress = 'El asistente quiere pulsar "%0:s" en "%1:s".';
  SEsSkillCancel = 'El asistente quiere descartar los cambios no guardados en "%s".';
  SEsCmdSkills = 'Las habilidades del asistente: lo que sabe hacer en cualquier ventana';
  SEsCmdTitleSkills = 'Habilidades del asistente';
  SEsCmdNoSkills = 'Este asistente no tiene habilidades.';
  SEsCmdSkillUnknown = 'no disponible en esta aplicación';
  SEsSkillForms = 'Describe la ventana que tienes delante y rellena sus campos, preguntando antes y sin guardar nunca.';
  SEsSkillCommands = 'Enumera los botones de la ventana y pulsa uno, preguntando antes; nunca uno que guarde.';
  SEsSkillRecords = 'Cuenta los registros de las listas de la ventana y se mueve al que tú nombres.';
  SEsSkillPages = 'Trae al frente una página (una pestaña) de la ventana.';

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
  SFrApiError = 'Erreur de l''API %s (HTTP %d %s).';
  SFrApiErrorAt = 'Erreur de l''API %s (HTTP %d %s) depuis %s, modèle %s.';
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
  SFrUiChangeAssistant = 'Changer de modèle';
  SFrUiChangeLanguage = 'Changer de langue';
  SFrCmdHelp = 'Les commandes que vous pouvez taper';
  SFrCmdWho = 'Qui répond : modèle et fournisseur';
  SFrCmdUse = 'Passe au modèle indiqué : /use Gemini';
  SFrCmdLang = 'Change la langue de la conversation : /lang en';
  SFrCmdRetry = 'Repose la dernière question, à un autre modèle s''il est indiqué';
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
  SFrCmdPromptStable = 'Prompt en cache';
  SFrCmdPromptContext = 'Contexte';
  SFrCmdPromptWhole = 'Prompt système';
  SFrCmdSearchTerms = 'La question a été cherchée avec ces termes du modèle (TranslateSearch) : %s';
  SFrCmdNoContext = 'Aucun contexte d''écran n''a été envoyé.';
  SFrCmdNoActions = 'Cette application n''a enregistré aucune action.';
  SFrCmdRunUsage = 'Utilisation : /run action nom=valeur nom2="une valeur avec des espaces"';
  SFrCmdNoEngine = 'Le moteur n''est pas démarré.';
  SFrCmdNoAssistant = 'Aucun modèle nommé "%s".';
  SFrCmdNoLanguage = 'Aucune langue "%s" parmi celles que propose cette conversation.';
  SFrCmdStatsLine = 'Dernière réponse : premier token après %s, complète après %s.';
  SFrCmdNoStats = 'Aucune réponse pour l''instant.';
  SFrCmdDocUsage = 'Utilisation : /doc page';
  SFrCmdUseUsage = 'Utilisation : /use modèle';
  SFrCmdNoAnswer = 'Aucune réponse à copier.';
  SFrCmdTitleHelp = 'Commandes disponibles';
  SFrCmdTitleWho = 'Modèle utilisé';
  SFrCmdTitleUse = 'Modèle changé';
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
  SFrConfirmYes = 'Oui';
  SFrConfirmNo = 'Non';
  SFrReplyCut =
    '(La réponse a été coupée : elle a atteint la limite de longueur d''une réponse. Demandez de continuer.)';
  SFrActionsNotRun =
    '(Une autre action a été demandée mais n''a pas été exécutée : la limite d''étapes d''une réponse est atteinte. Redemandez pour continuer.)';
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
  SFrSkillFill = 'L''assistant veut remplir ces champs de "%s". Rien n''est enregistré : vous vérifiez les valeurs et enregistrez.';
  SFrSkillPress = 'L''assistant veut appuyer sur "%0:s" dans "%1:s".';
  SFrSkillCancel = 'L''assistant veut abandonner les modifications non enregistrées dans "%s".';
  SFrCmdSkills = 'Les compétences de l''assistant : ce qu''il sait faire sur n''importe quelle fenêtre';
  SFrCmdTitleSkills = 'Compétences de l''assistant';
  SFrCmdNoSkills = 'Cet assistant n''a aucune compétence.';
  SFrCmdSkillUnknown = 'non disponible dans cette application';
  SFrSkillForms = 'Décrit la fenêtre devant vous et remplit ses champs, en demandant d''abord et sans jamais enregistrer.';
  SFrSkillCommands = 'Liste les boutons de la fenêtre et appuie sur l''un d''eux, en demandant d''abord ; jamais un qui enregistre.';
  SFrSkillRecords = 'Compte les enregistrements des listes de la fenêtre et se place sur celui que vous nommez.';
  SFrSkillPages = 'Affiche une page (un onglet) de la fenêtre.';

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
  SDeApiError = 'Fehler der %s-API (HTTP %d %s).';
  SDeApiErrorAt = 'Fehler der %s-API (HTTP %d %s) von %s, Modell %s.';
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
  SDeUiChangeAssistant = 'Modell wechseln';
  SDeUiChangeLanguage = 'Sprache wechseln';
  SDeCmdHelp = 'Die Befehle, die Sie eingeben können';
  SDeCmdWho = 'Wer antwortet: Modell und Anbieter';
  SDeCmdUse = 'Wechselt zum genannten Modell: /use Gemini';
  SDeCmdLang = 'Wechselt die Sprache des Chats: /lang en';
  SDeCmdRetry = 'Stellt die letzte Frage erneut, an ein anderes Modell, falls genannt';
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
  SDeCmdPromptStable = 'Prompt im Cache';
  SDeCmdPromptContext = 'Kontext';
  SDeCmdPromptWhole = 'System-Prompt';
  SDeCmdSearchTerms = 'Die Frage wurde zusammen mit diesen Begriffen des Modells gesucht (TranslateSearch): %s';
  SDeCmdNoContext = 'Es wurde kein Ansichtskontext gesendet.';
  SDeCmdNoActions = 'Diese Anwendung hat keine Aktionen registriert.';
  SDeCmdRunUsage = 'Verwendung: /run aktion name=wert name2="ein Wert mit Leerzeichen"';
  SDeCmdNoEngine = 'Die Engine läuft nicht.';
  SDeCmdNoAssistant = 'Kein Modell mit dem Namen "%s".';
  SDeCmdNoLanguage = 'Keine Sprache "%s" unter den Sprachen dieses Chats.';
  SDeCmdStatsLine = 'Letzte Antwort: erstes Token nach %s, vollständig nach %s.';
  SDeCmdNoStats = 'Noch keine Antwort.';
  SDeCmdDocUsage = 'Verwendung: /doc seite';
  SDeCmdUseUsage = 'Verwendung: /use modell';
  SDeCmdNoAnswer = 'Keine Antwort zum Kopieren.';
  SDeCmdTitleHelp = 'Verfügbare Befehle';
  SDeCmdTitleWho = 'Verwendetes Modell';
  SDeCmdTitleUse = 'Modell gewechselt';
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
  SDeConfirmYes = 'Ja';
  SDeConfirmNo = 'Nein';
  SDeReplyCut =
    '(Die Antwort wurde abgeschnitten: Die Längengrenze einer Antwort ist erreicht. Bitten Sie um Fortsetzung.)';
  SDeActionsNotRun =
    '(Eine weitere Aktion wurde angefordert, aber nicht ausgeführt: Die Schrittgrenze einer Antwort ist erreicht. Fragen Sie erneut, um fortzufahren.)';
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
  SDeSkillFill = 'Der Assistent möchte diese Felder von "%s" ausfüllen. Nichts wird gespeichert: Sie prüfen die Werte und speichern.';
  SDeSkillPress = 'Der Assistent möchte "%0:s" in "%1:s" drücken.';
  SDeSkillCancel = 'Der Assistent möchte die nicht gespeicherten Änderungen in "%s" verwerfen.';
  SDeCmdSkills = 'Die Fähigkeiten des Assistenten: was er in jedem Fenster kann';
  SDeCmdTitleSkills = 'Fähigkeiten des Assistenten';
  SDeCmdNoSkills = 'Dieser Assistent hat keine Fähigkeiten.';
  SDeCmdSkillUnknown = 'in dieser Anwendung nicht verfügbar';
  SDeSkillForms = 'Beschreibt das Fenster vor Ihnen und füllt seine Felder aus, fragt vorher und speichert nie.';
  SDeSkillCommands = 'Listet die Schaltflächen des Fensters auf und drückt eine, fragt vorher; nie eine, die speichert.';
  SDeSkillRecords = 'Zählt die Datensätze der Listen des Fensters und springt zu dem, den Sie nennen.';
  SDeSkillPages = 'Bringt eine Seite (einen Reiter) des Fensters nach vorne.';

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
  SPtApiError = 'Erro da API de %s (HTTP %d %s).';
  SPtApiErrorAt = 'Erro da API de %s (HTTP %d %s) de %s, modelo %s.';
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
  SPtUiChangeAssistant = 'Mudar de modelo';
  SPtUiChangeLanguage = 'Mudar de idioma';
  SPtCmdHelp = 'Os comandos que pode escrever';
  SPtCmdWho = 'Quem responde: modelo e fornecedor';
  SPtCmdUse = 'Muda para o modelo indicado: /use Gemini';
  SPtCmdLang = 'Muda o idioma da conversa: /lang en';
  SPtCmdRetry = 'Repete a última pergunta, a outro modelo se for indicado';
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
  SPtCmdPromptStable = 'Prompt em cache';
  SPtCmdPromptContext = 'Contexto';
  SPtCmdPromptWhole = 'Prompt de sistema';
  SPtCmdSearchTerms = 'A pergunta foi pesquisada junto com estes termos do modelo (TranslateSearch): %s';
  SPtCmdNoContext = 'Não foi enviado nenhum contexto de ecrã.';
  SPtCmdNoActions = 'Esta aplicação não registou nenhuma ação.';
  SPtCmdRunUsage = 'Utilização: /run ação nome=valor nome2="um valor com espaços"';
  SPtCmdNoEngine = 'O motor não está em execução.';
  SPtCmdNoAssistant = 'Não existe nenhum modelo chamado "%s".';
  SPtCmdNoLanguage = 'Não existe nenhum idioma "%s" entre os que esta conversa oferece.';
  SPtCmdStatsLine = 'Última resposta: primeiro token após %s, completa após %s.';
  SPtCmdNoStats = 'Ainda não há nenhuma resposta.';
  SPtCmdDocUsage = 'Utilização: /doc página';
  SPtCmdUseUsage = 'Utilização: /use modelo';
  SPtCmdNoAnswer = 'Não há nenhuma resposta para copiar.';
  SPtCmdTitleHelp = 'Comandos disponíveis';
  SPtCmdTitleWho = 'Modelo em uso';
  SPtCmdTitleUse = 'Modelo alterado';
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
  SPtConfirmYes = 'Sim';
  SPtConfirmNo = 'Não';
  SPtReplyCut =
    '(A resposta foi cortada: atingiu o limite de comprimento de uma resposta. Peça para continuar.)';
  SPtActionsNotRun =
    '(Foi pedida mais uma ação, mas não foi executada: foi atingido o limite de passos de uma resposta. Pergunte de novo para continuar.)';
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
  SPtSkillFill = 'O assistente quer preencher estes campos de "%s". Nada é guardado: reveja os valores e guarde.';
  SPtSkillPress = 'O assistente quer premir "%0:s" em "%1:s".';
  SPtSkillCancel = 'O assistente quer abandonar as alterações não guardadas em "%s".';
  SPtCmdSkills = 'As competências do assistente: o que sabe fazer em qualquer janela';
  SPtCmdTitleSkills = 'Competências do assistente';
  SPtCmdNoSkills = 'Este assistente não tem competências.';
  SPtCmdSkillUnknown = 'não disponível nesta aplicação';
  SPtSkillForms = 'Descreve a janela à sua frente e preenche os seus campos, perguntando antes e sem nunca guardar.';
  SPtSkillCommands = 'Lista os botões da janela e prime um, perguntando antes; nunca um que guarde.';
  SPtSkillRecords = 'Conta os registos das listas da janela e passa para o que indicar.';
  SPtSkillPages = 'Traz para a frente uma página (um separador) da janela.';

  // ---- Norwegian ------------------------------------------------------
  SNoGreeting = 'Hei! Spør meg om hva som helst om hvordan du bruker programmet.';
  SNoStubReply = 'Beklager, jeg har ingen opplysninger som kan hjelpe deg med dette akkurat nå.';
  SNoIndexUnavailable = 'Hjelpeindeksen er ikke tilgjengelig. Se [dokumentasjonen](%s).';
  SNoNoPageFound = 'Jeg fant ingen bestemt side for spørsmålet ditt. Bla i [dokumentasjonen](%s).';
  SNoReadMore = 'Les mer';
  SNoSeeAlso = 'Se også:';
  SNoClaudeNotConfigured = 'Claude-leverandøren er ikke konfigurert: legg API-nøkkelen i Settings.Claude.ApiKey, i miljøvariabelen ANTHROPIC_API_KEY, eller i en helpchatai.json-fil som { "Claude": { "ApiKey": "..." } } i %s (delt av alle HelpChat-programmer) eller i %s.';
  SNoProviderKeyMissing = 'Leverandøren "%0:s" har ingen API-nøkkel: legg den i Settings.%1:s.ApiKey, i miljøvariabelen %2:s, eller i en helpchatai.json-fil som { "%1:s": { "ApiKey": "..." } } i %3:s (delt av alle HelpChat-programmer) eller i %4:s.';
  SNoProviderNotAvailable = 'Leverandøren "%s" er ikke tilgjengelig i dette programmet: unit-en registrerer den når den lenkes inn, så legg den til i uses (HelpChatAI.Provider.Claude for "claude", HelpChatAI.Provider.DocSearch for "docsearch"). Tilgjengelige leverandører: %s.';
  SNoProviderError = 'KI-leverandøren returnerte en feil.';
  SNoApiError = 'API-feil fra %s (HTTP %d %s).';
  SNoApiErrorAt = 'API-feil fra %s (HTTP %d %s) ved %s, modell %s.';
  SNoEmptyReply = 'Assistenten returnerte ikke noe innhold.';
  SNoCancelled = 'Forespørselen ble avbrutt.';
  SNoScreenContext = 'Brukeren er nå på skjermbildet "%s" (type: %s).';
  SNoRelevantDocs = 'Relevante utdrag fra dokumentasjonen:';
  SNoSource = 'Kilde';
  SNoContextQuestion = 'Hvordan bruker jeg skjermbildet "%s"?';
  SNoUiTitle = 'Assistent';
  SNoUiHelp = 'Hjelp';
  SNoUiClear = 'Tøm samtalen';
  SNoUiClose = 'Lukk';
  SNoUiPlaceholder = 'Still et spørsmål om programmet...';
  SNoUiSend = 'Send';
  SNoUiStop = 'Stopp';
  SNoUiRetry = 'Prøv igjen';
  SNoUiSendError = 'Meldingen kunne ikke sendes.';
  SNoUiBack = 'Tilbake til samtalen';
  SNoUiChangeAssistant = 'Bytt modell';
  SNoUiChangeLanguage = 'Bytt språk';
  SNoCmdHelp = 'Kommandoene du kan skrive';
  SNoCmdWho = 'Hvem som svarer: modell og leverandør';
  SNoCmdUse = 'Bytt til den angitte modellen: /use Gemini';
  SNoCmdLang = 'Bytt språk i samtalen: /lang it';
  SNoCmdRetry = 'Still det siste spørsmålet på nytt, til en annen modell hvis den er angitt';
  SNoCmdSearch = 'Dokumentasjonssidene som svaret ville bygge på';
  SNoCmdDoc = 'Åpne en side i dokumentasjonen: /doc Leads.md';
  SNoCmdPages = 'Sidene i dokumentasjonsindeksen';
  SNoCmdContext = 'Skjermbildet assistenten tror du er på';
  SNoCmdActions = 'Hva assistenten kan gjøre i dette programmet';
  SNoCmdCheck = 'Kontroll av assistentens konfigurasjon';
  SNoCmdStats = 'Tidsbruk for det siste svaret';
  SNoCmdClear = 'Tøm samtalen';
  SNoCmdPdf = 'Lagre samtalen som PDF';
  SNoCmdCopy = 'Kopier det siste svaret';
  SNoCmdAttach = 'Legg ved en fil';
  SNoCmdPrompt = 'Instruksjonene og utdragene som fulgte det siste spørsmålet';
  SNoCmdRun = 'Kjør en handling manuelt: /run open_screen name=Leads';
  SNoCmdUnknown = 'Ukjent kommando %s. Skriv /help for å se listen.';
  SNoCmdProvider = 'Leverandør';
  SNoCmdEndpoint = 'Endepunkt';
  SNoCmdNoIndex = 'Det finnes ingen dokumentasjonsindeks.';
  SNoCmdNoQuestion = 'Ingen spørsmål ennå.';
  SNoCmdNoResults = 'Fant ingenting for "%s".';
  SNoCmdPromptStable = 'Bufret prompt';
  SNoCmdPromptContext = 'Kontekst';
  SNoCmdPromptWhole = 'Systemprompt';
  SNoCmdSearchTerms = 'Det ble søkt etter spørsmålet sammen med disse søkeordene fra modellen (TranslateSearch): %s';
  SNoCmdNoContext = 'Ingen skjermkontekst ble sendt.';
  SNoCmdNoActions = 'Dette programmet har ikke registrert noen handlinger.';
  SNoCmdRunUsage = 'Bruk: /run handling navn=verdi navn2="en verdi med mellomrom"';
  SNoCmdNoEngine = 'Motoren kjører ikke.';
  SNoCmdNoAssistant = 'Ingen modell med navnet "%s".';
  SNoCmdNoLanguage = 'Språket "%s" er ikke blant dem denne samtalen tilbyr.';
  SNoCmdStatsLine = 'Siste svar: første token etter %s, ferdig etter %s.';
  SNoCmdNoStats = 'Ingen svar ennå.';
  SNoCmdDocUsage = 'Bruk: /doc side';
  SNoCmdUseUsage = 'Bruk: /use modell';
  SNoCmdNoAnswer = 'Ingen svar å kopiere.';
  SNoCmdTitleHelp = 'Tilgjengelige kommandoer';
  SNoCmdTitleWho = 'Modell i bruk';
  SNoCmdTitleUse = 'Modell byttet';
  SNoCmdTitleLang = 'Samtalens språk';
  SNoCmdTitleSearch = 'Dokumentasjonssider for "%s"';
  SNoCmdTitlePages = 'Dokumentasjonssider';
  SNoCmdTitleContext = 'Skjermkontekst';
  SNoCmdTitleActions = 'Tilgjengelige handlinger';
  SNoCmdTitleCheck = 'Konfigurasjonskontroll';
  SNoCmdTitleStats = 'Tidsbruk for det siste svaret';
  SNoCmdTitlePrompt = 'Systemprompt for det siste spørsmålet';
  SNoCmdTitleRun = 'Handling kjørt';
  SNoUiMic = 'Dikter spørsmålet';
  SNoVoiceConsentNeeded = 'Diktering går gjennom den nettbaserte talegjenkjenningen i Windows, som ikke er aktivert på denne datamaskinen.' + sLineBreak + sLineBreak + 'Windows-innstillingene åpnes nå: slå på nettbasert talegjenkjenning, og trykk deretter på mikrofonen igjen.';
  SNoVoiceUnavailable = 'Talegjenkjenning er ikke tilgjengelig på denne datamaskinen. Sjekk Innstillinger, Personvern, Tale, og at språkpakken er installert.';
  SNoDocNotFound = 'Siden "%s" er ikke tilgjengelig.';
  SNoActionConfirm = 'Assistenten vil kjøre "%s": %s' + sLineBreak + sLineBreak + '%sTillater du det?';
  SNoActionValues = 'Verdier skrevet av assistenten:';
  SNoActionConfirmTitle = 'Assistenten vil kjøre "%s"';
  SNoActionValuesFooter = 'Verdiene over ble skrevet av assistenten, ikke av deg: kontroller dem før du tillater handlingen.';
  SNoConfirmYes = 'Ja';
  SNoConfirmNo = 'Nei';
  SNoReplyCut = '(Svaret ble avkortet: det nådde lengdegrensen for et svar. Be meg om å fortsette.)';
  SNoActionsNotRun = '(Det ble bedt om enda en handling, men den ble ikke kjørt: grensen for antall trinn i ett svar ble nådd. Spør igjen for å fortsette.)';
  SNoUiAttach = 'Legg ved et dokument';
  SNoUiAttachRemove = 'Fjern dette vedlegget';
  SNoAttachTypeRefused = 'En %s-fil kan ikke leses av assistenten. Godtatt: %s.';
  SNoAttachTooLarge = '"%s" er for stor: et vedlegg kan ikke være større enn %s.';
  SNoAttachTooMany = 'Høyst %d vedlegg om gangen.';
  SNoAttachTooMuch = 'Vedleggene i én samtale kan til sammen ikke overstige %s.';
  SNoAttachEmpty = 'Det er ingenting i "%s".';
  SNoAttachFailed = 'Dokumentet kunne ikke legges ved.';
  SNoAttachNotSupported = 'De vedlagte dokumentene ble ikke sendt: leverandøren %s kan ikke lese dem.';
  SNoUiPdfAnswer = 'Lagre dette svaret som PDF';
  SNoUiPdfConversation = 'Lagre samtalen som PDF';
  SNoUiCopyAnswer = 'Kopier dette svaret';
  SNoUiCopyConversation = 'Kopier samtalen';
  SNoUiCopyPage = 'Kopier denne siden';
  SNoUiCopied = 'Kopiert';
  SNoUiCopyFailed = 'Teksten kunne ikke kopieres til utklippstavlen.';
  SNoUiPdfPage = 'Lagre denne siden som PDF';
  SNoPdfAnswerTitle = 'Svar';
  SNoPdfConversationTitle = 'Samtale';
  SNoPdfUser = 'Spørsmål';
  SNoPdfAssistant = 'Svar';
  SNoPdfFilter = 'PDF-dokument (*.pdf)|*.pdf';
  SNoPdfOpen = 'PDF-filen er lagret som "%s". Vil du åpne den nå?';
  SNoPdfFailed = 'PDF-filen kunne ikke opprettes: %s';
  SNoPdfNoBands = '"%s" er lagret, men denne versjonen av nettlesermotoren kunne ikke skrive ut topptekst og bunntekst i dokumentet.';
  SNoPdfNothing = 'Det er ingenting å lagre ennå.';
  SNoPdfUnavailable = 'Lagring som PDF er ikke tilgjengelig i dette programmet.';
  SNoPdfHandedOver = 'Dokumentet er klart: brukeren velger hvor det skal lagres.';
  SNoAttachedDocuments = 'Dokumenter brukeren la ved spørsmålet';
  SNoAttachedTextFile = 'Innholdet i den vedlagte filen "%s"';
  SNoSkillFill = 'Assistenten vil fylle ut disse feltene i "%s". Ingenting lagres: du kontrollerer verdiene og lagrer.';
  SNoSkillPress = 'Assistenten vil trykke på "%0:s" i "%1:s".';
  SNoSkillCancel = 'Assistenten vil forkaste endringene som ikke er lagret i "%s".';
  SNoCmdSkills = 'Assistentens ferdigheter: hva den kan gjøre i ethvert vindu';
  SNoCmdTitleSkills = 'Assistentens ferdigheter';
  SNoCmdNoSkills = 'Denne assistenten har ingen ferdigheter.';
  SNoCmdSkillUnknown = 'ikke tilgjengelig i dette programmet';
  SNoSkillForms = 'Beskriver vinduet foran deg og fyller ut feltene, spør først og lagrer aldri.';
  SNoSkillCommands = 'Lister opp knappene i vinduet og trykker på én, spør først; aldri en som lagrer.';
  SNoSkillRecords = 'Teller postene i listene i vinduet og går til den du nevner.';
  SNoSkillPages = 'Henter frem en side (en fane) i vinduet.';

  // ---- Swedish --------------------------------------------------------
  SSvGreeting = 'Hej! Fråga mig vad som helst om hur du använder programmet.';
  SSvStubReply = 'Tyvärr har jag inget underlag som kan hjälpa dig med detta just nu.';
  SSvIndexUnavailable = 'Hjälpindexet är inte tillgängligt. Se [dokumentationen](%s).';
  SSvNoPageFound = 'Jag hittade ingen särskild sida för din fråga. Bläddra i [dokumentationen](%s).';
  SSvReadMore = 'Läs mer';
  SSvSeeAlso = 'Se även:';
  SSvClaudeNotConfigured = 'Claude-leverantören är inte konfigurerad: lägg API-nyckeln i Settings.Claude.ApiKey, i miljövariabeln ANTHROPIC_API_KEY, eller i en helpchatai.json-fil som { "Claude": { "ApiKey": "..." } } i %s (delad av alla HelpChat-program) eller i %s.';
  SSvProviderKeyMissing = 'Leverantören "%0:s" har ingen API-nyckel: lägg den i Settings.%1:s.ApiKey, i miljövariabeln %2:s, eller i en helpchatai.json-fil som { "%1:s": { "ApiKey": "..." } } i %3:s (delad av alla HelpChat-program) eller i %4:s.';
  SSvProviderNotAvailable = 'Leverantören "%s" är inte tillgänglig i det här programmet: dess unit registrerar den när den länkas in, så lägg till den i uses (HelpChatAI.Provider.Claude för "claude", HelpChatAI.Provider.DocSearch för "docsearch"). Tillgängliga leverantörer: %s.';
  SSvProviderError = 'AI-leverantören returnerade ett fel.';
  SSvApiError = 'API-fel från %s (HTTP %d %s).';
  SSvApiErrorAt = 'API-fel från %s (HTTP %d %s) vid %s, modell %s.';
  SSvEmptyReply = 'Assistenten returnerade inget innehåll.';
  SSvCancelled = 'Begäran avbröts.';
  SSvScreenContext = 'Användaren befinner sig nu på skärmbilden "%s" (typ: %s).';
  SSvRelevantDocs = 'Relevanta utdrag ur dokumentationen:';
  SSvSource = 'Källa';
  SSvContextQuestion = 'Hur använder jag skärmbilden "%s"?';
  SSvUiTitle = 'Assistent';
  SSvUiHelp = 'Hjälp';
  SSvUiClear = 'Rensa konversationen';
  SSvUiClose = 'Stäng';
  SSvUiPlaceholder = 'Ställ en fråga om programmet...';
  SSvUiSend = 'Skicka';
  SSvUiStop = 'Stoppa';
  SSvUiRetry = 'Försök igen';
  SSvUiSendError = 'Meddelandet kunde inte skickas.';
  SSvUiBack = 'Tillbaka till chatten';
  SSvUiChangeAssistant = 'Byt modell';
  SSvUiChangeLanguage = 'Byt språk';
  SSvCmdHelp = 'Kommandona du kan skriva';
  SSvCmdWho = 'Vem som svarar: modell och leverantör';
  SSvCmdUse = 'Byt till den angivna modellen: /use Gemini';
  SSvCmdLang = 'Byt språk i chatten: /lang it';
  SSvCmdRetry = 'Ställ den senaste frågan igen, till en annan modell om den anges';
  SSvCmdSearch = 'Dokumentationssidorna som svaret skulle bygga på';
  SSvCmdDoc = 'Öppna en sida i dokumentationen: /doc Leads.md';
  SSvCmdPages = 'Sidorna i dokumentationsindexet';
  SSvCmdContext = 'Skärmbilden som assistenten tror att du är på';
  SSvCmdActions = 'Vad assistenten kan göra i det här programmet';
  SSvCmdCheck = 'Kontroll av assistentens konfiguration';
  SSvCmdStats = 'Tidsåtgång för det senaste svaret';
  SSvCmdClear = 'Rensa konversationen';
  SSvCmdPdf = 'Spara konversationen som PDF';
  SSvCmdCopy = 'Kopiera det senaste svaret';
  SSvCmdAttach = 'Bifoga en fil';
  SSvCmdPrompt = 'Instruktionerna och utdragen som följde med den senaste frågan';
  SSvCmdRun = 'Kör en åtgärd manuellt: /run open_screen name=Leads';
  SSvCmdUnknown = 'Okänt kommando %s. Skriv /help för att se listan.';
  SSvCmdProvider = 'Leverantör';
  SSvCmdEndpoint = 'Slutpunkt';
  SSvCmdNoIndex = 'Det finns inget dokumentationsindex.';
  SSvCmdNoQuestion = 'Ingen fråga ännu.';
  SSvCmdNoResults = 'Inget hittades för "%s".';
  SSvCmdPromptStable = 'Cachad prompt';
  SSvCmdPromptContext = 'Kontext';
  SSvCmdPromptWhole = 'Systemprompt';
  SSvCmdSearchTerms = 'Sökningen gjordes på frågan tillsammans med dessa söktermer från modellen (TranslateSearch): %s';
  SSvCmdNoContext = 'Ingen skärmkontext skickades.';
  SSvCmdNoActions = 'Det här programmet har inte registrerat några åtgärder.';
  SSvCmdRunUsage = 'Användning: /run åtgärd namn=värde namn2="ett värde med mellanslag"';
  SSvCmdNoEngine = 'Motorn körs inte.';
  SSvCmdNoAssistant = 'Ingen modell med namnet "%s".';
  SSvCmdNoLanguage = 'Språket "%s" finns inte bland dem som den här chatten erbjuder.';
  SSvCmdStatsLine = 'Senaste svaret: första token efter %s, klart efter %s.';
  SSvCmdNoStats = 'Inget svar ännu.';
  SSvCmdDocUsage = 'Användning: /doc sida';
  SSvCmdUseUsage = 'Användning: /use modell';
  SSvCmdNoAnswer = 'Inget svar att kopiera.';
  SSvCmdTitleHelp = 'Tillgängliga kommandon';
  SSvCmdTitleWho = 'Modell som används';
  SSvCmdTitleUse = 'Modellen har bytts';
  SSvCmdTitleLang = 'Chattens språk';
  SSvCmdTitleSearch = 'Dokumentationssidor för "%s"';
  SSvCmdTitlePages = 'Dokumentationssidor';
  SSvCmdTitleContext = 'Skärmkontext';
  SSvCmdTitleActions = 'Tillgängliga åtgärder';
  SSvCmdTitleCheck = 'Konfigurationskontroll';
  SSvCmdTitleStats = 'Tidsåtgång för det senaste svaret';
  SSvCmdTitlePrompt = 'Systemprompt för den senaste frågan';
  SSvCmdTitleRun = 'Åtgärd körd';
  SSvUiMic = 'Diktera frågan';
  SSvVoiceConsentNeeded = 'Diktering går via onlinetaligenkänningen i Windows, som inte är aktiverad på den här datorn.' + sLineBreak + sLineBreak + 'Windows-inställningarna öppnas nu: aktivera taligenkänning online och tryck sedan på mikrofonen igen.';
  SSvVoiceUnavailable = 'Taligenkänning är inte tillgänglig på den här datorn. Kontrollera Inställningar, Sekretess, Tal, och att språkpaketet är installerat.';
  SSvDocNotFound = 'Sidan "%s" är inte tillgänglig.';
  SSvActionConfirm = 'Assistenten vill köra "%s": %s' + sLineBreak + sLineBreak + '%sTillåter du det?';
  SSvActionValues = 'Värden skrivna av assistenten:';
  SSvActionConfirmTitle = 'Assistenten vill köra "%s"';
  SSvActionValuesFooter = 'Värdena ovan skrevs av assistenten, inte av dig: kontrollera dem innan du tillåter åtgärden.';
  SSvConfirmYes = 'Ja';
  SSvConfirmNo = 'Nej';
  SSvReplyCut = '(Svaret kortades av: det nådde längdgränsen för ett svar. Be mig fortsätta.)';
  SSvActionsNotRun = '(Ytterligare en åtgärd begärdes men kördes inte: gränsen för antalet steg i ett svar nåddes. Fråga igen för att fortsätta.)';
  SSvUiAttach = 'Bifoga ett dokument';
  SSvUiAttachRemove = 'Ta bort den här bilagan';
  SSvAttachTypeRefused = 'En %s-fil kan assistenten inte läsa. Godkända: %s.';
  SSvAttachTooLarge = '"%s" är för stor: en bilaga får inte överstiga %s.';
  SSvAttachTooMany = 'Högst %d bilagor åt gången.';
  SSvAttachTooMuch = 'Bilagorna i en konversation får sammanlagt inte överstiga %s.';
  SSvAttachEmpty = 'Det finns ingenting i "%s".';
  SSvAttachFailed = 'Dokumentet kunde inte bifogas.';
  SSvAttachNotSupported = 'De bifogade dokumenten skickades inte: leverantören %s kan inte läsa dem.';
  SSvUiPdfAnswer = 'Spara det här svaret som PDF';
  SSvUiPdfConversation = 'Spara konversationen som PDF';
  SSvUiCopyAnswer = 'Kopiera det här svaret';
  SSvUiCopyConversation = 'Kopiera konversationen';
  SSvUiCopyPage = 'Kopiera den här sidan';
  SSvUiCopied = 'Kopierat';
  SSvUiCopyFailed = 'Texten kunde inte kopieras till urklipp.';
  SSvUiPdfPage = 'Spara den här sidan som PDF';
  SSvPdfAnswerTitle = 'Svar';
  SSvPdfConversationTitle = 'Konversation';
  SSvPdfUser = 'Fråga';
  SSvPdfAssistant = 'Svar';
  SSvPdfFilter = 'PDF-dokument (*.pdf)|*.pdf';
  SSvPdfOpen = 'PDF-filen har sparats som "%s". Vill du öppna den nu?';
  SSvPdfFailed = 'PDF-filen kunde inte skapas: %s';
  SSvPdfNoBands = '"%s" har sparats, men den här versionen av webbläsarmotorn skrev inte ut dokumentets sidhuvud och sidfot.';
  SSvPdfNothing = 'Det finns inget att spara ännu.';
  SSvPdfUnavailable = 'Att spara som PDF är inte tillgängligt i det här programmet.';
  SSvPdfHandedOver = 'Dokumentet är klart: användaren väljer var det ska sparas.';
  SSvAttachedDocuments = 'Dokument som användaren bifogade till frågan';
  SSvAttachedTextFile = 'Innehållet i den bifogade filen "%s"';
  SSvSkillFill = 'Assistenten vill fylla i dessa fält i "%s". Inget sparas: du granskar värdena och sparar.';
  SSvSkillPress = 'Assistenten vill trycka på "%0:s" i "%1:s".';
  SSvSkillCancel = 'Assistenten vill förkasta de ändringar som inte har sparats i "%s".';
  SSvCmdSkills = 'Assistentens färdigheter: vad den kan göra i vilket fönster som helst';
  SSvCmdTitleSkills = 'Assistentens färdigheter';
  SSvCmdNoSkills = 'Den här assistenten har inga färdigheter.';
  SSvCmdSkillUnknown = 'inte tillgänglig i det här programmet';
  SSvSkillForms = 'Beskriver fönstret framför dig och fyller i dess fält, frågar först och sparar aldrig.';
  SSvSkillCommands = 'Listar fönstrets knappar och trycker på en, frågar först; aldrig en som sparar.';
  SSvSkillRecords = 'Räknar posterna i fönstrets listor och går till den du nämner.';
  SSvSkillPages = 'Tar fram en sida (en flik) i fönstret.';

  // ---- Danish ---------------------------------------------------------
  SDaGreeting = 'Hej! Spørg mig om hvad som helst om, hvordan du bruger programmet.';
  SDaStubReply = 'Beklager, jeg har ikke noget, der kan hjælpe dig med dette lige nu.';
  SDaIndexUnavailable = 'Hjælpeindekset er ikke tilgængeligt. Se [dokumentationen](%s).';
  SDaNoPageFound = 'Jeg kunne ikke finde en bestemt side til dit spørgsmål. Gennemse [dokumentationen](%s).';
  SDaReadMore = 'Læs mere';
  SDaSeeAlso = 'Se også:';
  SDaClaudeNotConfigured = 'Claude-udbyderen er ikke konfigureret: angiv API-nøglen i Settings.Claude.ApiKey, i miljøvariablen ANTHROPIC_API_KEY eller i en helpchatai.json-fil som { "Claude": { "ApiKey": "..." } } i %s (delt af alle HelpChat-programmer) eller i %s.';
  SDaProviderKeyMissing = 'Udbyderen "%0:s" har ingen API-nøgle: angiv den i Settings.%1:s.ApiKey, i miljøvariablen %2:s eller i en helpchatai.json-fil som { "%1:s": { "ApiKey": "..." } } i %3:s (delt af alle HelpChat-programmer) eller i %4:s.';
  SDaProviderNotAvailable = 'Udbyderen "%s" er ikke tilgængelig i dette program: dens unit registrerer den, når den linkes ind, så tilføj den til uses (HelpChatAI.Provider.Claude for "claude", HelpChatAI.Provider.DocSearch for "docsearch"). Tilgængelige udbydere: %s.';
  SDaProviderError = 'AI-udbyderen returnerede en fejl.';
  SDaApiError = 'API-fejl fra %s (HTTP %d %s).';
  SDaApiErrorAt = 'API-fejl fra %s (HTTP %d %s) ved %s, model %s.';
  SDaEmptyReply = 'Assistenten returnerede intet indhold.';
  SDaCancelled = 'Forespørgslen blev annulleret.';
  SDaScreenContext = 'Brugeren er lige nu på skærmbilledet "%s" (type: %s).';
  SDaRelevantDocs = 'Relevante uddrag fra dokumentationen:';
  SDaSource = 'Kilde';
  SDaContextQuestion = 'Hvordan bruger jeg skærmbilledet "%s"?';
  SDaUiTitle = 'Assistent';
  SDaUiHelp = 'Hjælp';
  SDaUiClear = 'Ryd samtalen';
  SDaUiClose = 'Luk';
  SDaUiPlaceholder = 'Stil et spørgsmål om programmet...';
  SDaUiSend = 'Send';
  SDaUiStop = 'Stop';
  SDaUiRetry = 'Prøv igen';
  SDaUiSendError = 'Beskeden kunne ikke sendes.';
  SDaUiBack = 'Tilbage til chatten';
  SDaUiChangeAssistant = 'Skift model';
  SDaUiChangeLanguage = 'Skift sprog';
  SDaCmdHelp = 'De kommandoer, du kan skrive';
  SDaCmdWho = 'Hvem der svarer: model og udbyder';
  SDaCmdUse = 'Skift til den angivne model: /use Gemini';
  SDaCmdLang = 'Skift chattens sprog: /lang it';
  SDaCmdRetry = 'Stil det seneste spørgsmål igen, til en anden model, hvis den angives';
  SDaCmdSearch = 'De dokumentationssider, svaret ville bygge på';
  SDaCmdDoc = 'Åbn en side i dokumentationen: /doc Leads.md';
  SDaCmdPages = 'Siderne i dokumentationsindekset';
  SDaCmdContext = 'Det skærmbillede, assistenten tror, du er på';
  SDaCmdActions = 'Hvad assistenten kan gøre i dette program';
  SDaCmdCheck = 'Kontrol af assistentens konfiguration';
  SDaCmdStats = 'Tidsforbrug for det seneste svar';
  SDaCmdClear = 'Ryd samtalen';
  SDaCmdPdf = 'Gem samtalen som PDF';
  SDaCmdCopy = 'Kopiér det seneste svar';
  SDaCmdAttach = 'Vedhæft en fil';
  SDaCmdPrompt = 'De instruktioner og uddrag, der fulgte med det seneste spørgsmål';
  SDaCmdRun = 'Kør en handling manuelt: /run open_screen name=Leads';
  SDaCmdUnknown = 'Ukendt kommando %s. Skriv /help for at se listen.';
  SDaCmdProvider = 'Udbyder';
  SDaCmdEndpoint = 'Endepunkt';
  SDaCmdNoIndex = 'Der er intet dokumentationsindeks.';
  SDaCmdNoQuestion = 'Intet spørgsmål endnu.';
  SDaCmdNoResults = 'Intet fundet for "%s".';
  SDaCmdPromptStable = 'Cachelagret prompt';
  SDaCmdPromptContext = 'Kontekst';
  SDaCmdPromptWhole = 'Systemprompt';
  SDaCmdSearchTerms = 'Der blev søgt på spørgsmålet sammen med disse søgeord fra modellen (TranslateSearch): %s';
  SDaCmdNoContext = 'Der blev ikke sendt nogen skærmkontekst.';
  SDaCmdNoActions = 'Dette program har ikke registreret nogen handlinger.';
  SDaCmdRunUsage = 'Brug: /run handling navn=værdi navn2="en værdi med mellemrum"';
  SDaCmdNoEngine = 'Motoren kører ikke.';
  SDaCmdNoAssistant = 'Ingen model ved navn "%s".';
  SDaCmdNoLanguage = 'Sproget "%s" er ikke blandt dem, denne chat tilbyder.';
  SDaCmdStatsLine = 'Seneste svar: første token efter %s, færdigt efter %s.';
  SDaCmdNoStats = 'Intet svar endnu.';
  SDaCmdDocUsage = 'Brug: /doc side';
  SDaCmdUseUsage = 'Brug: /use model';
  SDaCmdNoAnswer = 'Intet svar at kopiere.';
  SDaCmdTitleHelp = 'Tilgængelige kommandoer';
  SDaCmdTitleWho = 'Model i brug';
  SDaCmdTitleUse = 'Model skiftet';
  SDaCmdTitleLang = 'Chattens sprog';
  SDaCmdTitleSearch = 'Dokumentationssider for "%s"';
  SDaCmdTitlePages = 'Dokumentationssider';
  SDaCmdTitleContext = 'Skærmkontekst';
  SDaCmdTitleActions = 'Tilgængelige handlinger';
  SDaCmdTitleCheck = 'Konfigurationskontrol';
  SDaCmdTitleStats = 'Tidsforbrug for det seneste svar';
  SDaCmdTitlePrompt = 'Systemprompt for det seneste spørgsmål';
  SDaCmdTitleRun = 'Handling kørt';
  SDaUiMic = 'Diktér spørgsmålet';
  SDaVoiceConsentNeeded = 'Diktering går gennem onlinetalegenkendelsen i Windows, som ikke er slået til på denne computer.' + sLineBreak + sLineBreak + 'Windows-indstillingerne åbnes nu: slå onlinetalegenkendelse til, og tryk derefter på mikrofonen igen.';
  SDaVoiceUnavailable = 'Talegenkendelse er ikke tilgængelig på denne computer. Kontrollér Indstillinger, Beskyttelse af personlige oplysninger, Tale, og at sprogpakken er installeret.';
  SDaDocNotFound = 'Siden "%s" er ikke tilgængelig.';
  SDaActionConfirm = 'Assistenten vil køre "%s": %s' + sLineBreak + sLineBreak + '%sTillader du det?';
  SDaActionValues = 'Værdier skrevet af assistenten:';
  SDaActionConfirmTitle = 'Assistenten vil køre "%s"';
  SDaActionValuesFooter = 'Værdierne ovenfor er skrevet af assistenten, ikke af dig: kontrollér dem, før du tillader handlingen.';
  SDaConfirmYes = 'Ja';
  SDaConfirmNo = 'Nej';
  SDaReplyCut = '(Svaret blev afkortet: det nåede længdegrænsen for et svar. Bed mig om at fortsætte.)';
  SDaActionsNotRun = '(Der blev anmodet om endnu en handling, men den blev ikke kørt: grænsen for antal trin i ét svar blev nået. Spørg igen for at fortsætte.)';
  SDaUiAttach = 'Vedhæft et dokument';
  SDaUiAttachRemove = 'Fjern denne vedhæftede fil';
  SDaAttachTypeRefused = 'En %s-fil kan assistenten ikke læse. Accepteret: %s.';
  SDaAttachTooLarge = '"%s" er for stor: en vedhæftet fil må ikke overstige %s.';
  SDaAttachTooMany = 'Højst %d vedhæftede filer ad gangen.';
  SDaAttachTooMuch = 'De vedhæftede filer i én samtale må samlet ikke overstige %s.';
  SDaAttachEmpty = 'Der er intet i "%s".';
  SDaAttachFailed = 'Dokumentet kunne ikke vedhæftes.';
  SDaAttachNotSupported = 'De vedhæftede dokumenter blev ikke sendt: udbyderen %s kan ikke læse dem.';
  SDaUiPdfAnswer = 'Gem dette svar som PDF';
  SDaUiPdfConversation = 'Gem samtalen som PDF';
  SDaUiCopyAnswer = 'Kopiér dette svar';
  SDaUiCopyConversation = 'Kopiér samtalen';
  SDaUiCopyPage = 'Kopiér denne side';
  SDaUiCopied = 'Kopieret';
  SDaUiCopyFailed = 'Teksten kunne ikke kopieres til udklipsholderen.';
  SDaUiPdfPage = 'Gem denne side som PDF';
  SDaPdfAnswerTitle = 'Svar';
  SDaPdfConversationTitle = 'Samtale';
  SDaPdfUser = 'Spørgsmål';
  SDaPdfAssistant = 'Svar';
  SDaPdfFilter = 'PDF-dokument (*.pdf)|*.pdf';
  SDaPdfOpen = 'PDF-filen er gemt som "%s". Vil du åbne den nu?';
  SDaPdfFailed = 'PDF-filen kunne ikke oprettes: %s';
  SDaPdfNoBands = '"%s" er gemt, men denne version af browsermotoren kunne ikke udskrive dokumentets sidehoved og sidefod.';
  SDaPdfNothing = 'Der er intet at gemme endnu.';
  SDaPdfUnavailable = 'Det er ikke muligt at gemme som PDF i dette program.';
  SDaPdfHandedOver = 'Dokumentet er klar: brugeren vælger, hvor det skal gemmes.';
  SDaAttachedDocuments = 'Dokumenter, som brugeren vedhæftede til spørgsmålet';
  SDaAttachedTextFile = 'Indholdet af den vedhæftede fil "%s"';
  SDaSkillFill = 'Assistenten vil udfylde disse felter i "%s". Intet gemmes: du gennemgår værdierne og gemmer.';
  SDaSkillPress = 'Assistenten vil trykke på "%0:s" i "%1:s".';
  SDaSkillCancel = 'Assistenten vil kassere de ændringer, der ikke er gemt i "%s".';
  SDaCmdSkills = 'Assistentens færdigheder: hvad den kan gøre i ethvert vindue';
  SDaCmdTitleSkills = 'Assistentens færdigheder';
  SDaCmdNoSkills = 'Denne assistent har ingen færdigheder.';
  SDaCmdSkillUnknown = 'ikke tilgængelig i dette program';
  SDaSkillForms = 'Beskriver vinduet foran dig og udfylder dets felter, spørger først og gemmer aldrig.';
  SDaSkillCommands = 'Viser vinduets knapper og trykker på én, spørger først; aldrig én, der gemmer.';
  SDaSkillRecords = 'Tæller posterne i vinduets lister og går til den, du nævner.';
  SDaSkillPages = 'Bringer en side (en fane) i vinduet frem.';

const
  LANGUAGE_CODES: array[THelpChatLanguage] of string = (
    'auto', 'en', 'it', 'es', 'fr', 'de', 'pt', 'no', 'sv', 'da');
  /// <summary>Another code for <c>hclNorwegian</c>, understood on the way
  /// in and never written.</summary>
  LANGUAGE_CODE_BOKMAL = 'nb';
  LANGUAGE_NAMES: array[THelpChatLanguage] of string = (
    '', 'English', 'Italian', 'Spanish', 'French', 'German', 'Portuguese', 'Norwegian',
    'Swedish', 'Danish');
  LANGUAGE_NATIVE_NAMES: array[THelpChatLanguage] of string = (
    '', 'English', 'Italiano', 'Español', 'Français', 'Deutsch', 'Português', 'Norsk',
    'Svenska', 'Dansk');
  /// <summary>Primary language ids of Windows (LANG_* of WinNT.h), so that
  /// the engine stays free of Winapi units.</summary>
  LANGUAGE_PRIMARY_IDS: array[THelpChatLanguage] of Word = (
    0, $09, $10, $0A, $0C, $07, $16, $14, $1D, $06);

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
  // The strings are Bokmål, and "nb" is the code Windows and many users
  // know it by.
  if SameText(LValue, LANGUAGE_CODE_BOKMAL) then
    LValue := LANGUAGE_CODES[hclNorwegian];
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
    hcmApiErrorAt: Result := SEnApiErrorAt;
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
    hcmActionsNotRun: Result := SEnActionsNotRun;
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
    hcmCmdPromptStable: Result := SEnCmdPromptStable;
    hcmCmdPromptContext: Result := SEnCmdPromptContext;
    hcmCmdPromptWhole: Result := SEnCmdPromptWhole;
    hcmCmdSearchTerms: Result := SEnCmdSearchTerms;
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
    hcmSkillFill: Result := SEnSkillFill;
    hcmSkillPress: Result := SEnSkillPress;
    hcmSkillCancel: Result := SEnSkillCancel;
    hcmCmdSkills: Result := SEnCmdSkills;
    hcmCmdTitleSkills: Result := SEnCmdTitleSkills;
    hcmCmdNoSkills: Result := SEnCmdNoSkills;
    hcmCmdSkillUnknown: Result := SEnCmdSkillUnknown;
    hcmSkillForms: Result := SEnSkillForms;
    hcmSkillCommands: Result := SEnSkillCommands;
    hcmSkillRecords: Result := SEnSkillRecords;
    hcmSkillPages: Result := SEnSkillPages;
    hcmReplyCut: Result := SEnReplyCut;
    hcmConfirmYes: Result := SEnConfirmYes;
    hcmConfirmNo: Result := SEnConfirmNo;
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
    hcmApiErrorAt: Result := SItApiErrorAt;
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
    hcmActionsNotRun: Result := SItActionsNotRun;
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
    hcmCmdPromptStable: Result := SItCmdPromptStable;
    hcmCmdPromptContext: Result := SItCmdPromptContext;
    hcmCmdPromptWhole: Result := SItCmdPromptWhole;
    hcmCmdSearchTerms: Result := SItCmdSearchTerms;
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
    hcmSkillFill: Result := SItSkillFill;
    hcmSkillPress: Result := SItSkillPress;
    hcmSkillCancel: Result := SItSkillCancel;
    hcmCmdSkills: Result := SItCmdSkills;
    hcmCmdTitleSkills: Result := SItCmdTitleSkills;
    hcmCmdNoSkills: Result := SItCmdNoSkills;
    hcmCmdSkillUnknown: Result := SItCmdSkillUnknown;
    hcmSkillForms: Result := SItSkillForms;
    hcmSkillCommands: Result := SItSkillCommands;
    hcmSkillRecords: Result := SItSkillRecords;
    hcmSkillPages: Result := SItSkillPages;
    hcmReplyCut: Result := SItReplyCut;
    hcmConfirmYes: Result := SItConfirmYes;
    hcmConfirmNo: Result := SItConfirmNo;
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
    hcmApiErrorAt: Result := SEsApiErrorAt;
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
    hcmActionsNotRun: Result := SEsActionsNotRun;
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
    hcmCmdPromptStable: Result := SEsCmdPromptStable;
    hcmCmdPromptContext: Result := SEsCmdPromptContext;
    hcmCmdPromptWhole: Result := SEsCmdPromptWhole;
    hcmCmdSearchTerms: Result := SEsCmdSearchTerms;
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
    hcmSkillFill: Result := SEsSkillFill;
    hcmSkillPress: Result := SEsSkillPress;
    hcmSkillCancel: Result := SEsSkillCancel;
    hcmCmdSkills: Result := SEsCmdSkills;
    hcmCmdTitleSkills: Result := SEsCmdTitleSkills;
    hcmCmdNoSkills: Result := SEsCmdNoSkills;
    hcmCmdSkillUnknown: Result := SEsCmdSkillUnknown;
    hcmSkillForms: Result := SEsSkillForms;
    hcmSkillCommands: Result := SEsSkillCommands;
    hcmSkillRecords: Result := SEsSkillRecords;
    hcmSkillPages: Result := SEsSkillPages;
    hcmReplyCut: Result := SEsReplyCut;
    hcmConfirmYes: Result := SEsConfirmYes;
    hcmConfirmNo: Result := SEsConfirmNo;
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
    hcmApiErrorAt: Result := SFrApiErrorAt;
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
    hcmActionsNotRun: Result := SFrActionsNotRun;
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
    hcmCmdPromptStable: Result := SFrCmdPromptStable;
    hcmCmdPromptContext: Result := SFrCmdPromptContext;
    hcmCmdPromptWhole: Result := SFrCmdPromptWhole;
    hcmCmdSearchTerms: Result := SFrCmdSearchTerms;
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
    hcmSkillFill: Result := SFrSkillFill;
    hcmSkillPress: Result := SFrSkillPress;
    hcmSkillCancel: Result := SFrSkillCancel;
    hcmCmdSkills: Result := SFrCmdSkills;
    hcmCmdTitleSkills: Result := SFrCmdTitleSkills;
    hcmCmdNoSkills: Result := SFrCmdNoSkills;
    hcmCmdSkillUnknown: Result := SFrCmdSkillUnknown;
    hcmSkillForms: Result := SFrSkillForms;
    hcmSkillCommands: Result := SFrSkillCommands;
    hcmSkillRecords: Result := SFrSkillRecords;
    hcmSkillPages: Result := SFrSkillPages;
    hcmReplyCut: Result := SFrReplyCut;
    hcmConfirmYes: Result := SFrConfirmYes;
    hcmConfirmNo: Result := SFrConfirmNo;
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
    hcmApiErrorAt: Result := SDeApiErrorAt;
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
    hcmActionsNotRun: Result := SDeActionsNotRun;
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
    hcmCmdPromptStable: Result := SDeCmdPromptStable;
    hcmCmdPromptContext: Result := SDeCmdPromptContext;
    hcmCmdPromptWhole: Result := SDeCmdPromptWhole;
    hcmCmdSearchTerms: Result := SDeCmdSearchTerms;
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
    hcmSkillFill: Result := SDeSkillFill;
    hcmSkillPress: Result := SDeSkillPress;
    hcmSkillCancel: Result := SDeSkillCancel;
    hcmCmdSkills: Result := SDeCmdSkills;
    hcmCmdTitleSkills: Result := SDeCmdTitleSkills;
    hcmCmdNoSkills: Result := SDeCmdNoSkills;
    hcmCmdSkillUnknown: Result := SDeCmdSkillUnknown;
    hcmSkillForms: Result := SDeSkillForms;
    hcmSkillCommands: Result := SDeSkillCommands;
    hcmSkillRecords: Result := SDeSkillRecords;
    hcmSkillPages: Result := SDeSkillPages;
    hcmReplyCut: Result := SDeReplyCut;
    hcmConfirmYes: Result := SDeConfirmYes;
    hcmConfirmNo: Result := SDeConfirmNo;
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
    hcmApiErrorAt: Result := SPtApiErrorAt;
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
    hcmActionsNotRun: Result := SPtActionsNotRun;
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
    hcmCmdPromptStable: Result := SPtCmdPromptStable;
    hcmCmdPromptContext: Result := SPtCmdPromptContext;
    hcmCmdPromptWhole: Result := SPtCmdPromptWhole;
    hcmCmdSearchTerms: Result := SPtCmdSearchTerms;
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
    hcmSkillFill: Result := SPtSkillFill;
    hcmSkillPress: Result := SPtSkillPress;
    hcmSkillCancel: Result := SPtSkillCancel;
    hcmCmdSkills: Result := SPtCmdSkills;
    hcmCmdTitleSkills: Result := SPtCmdTitleSkills;
    hcmCmdNoSkills: Result := SPtCmdNoSkills;
    hcmCmdSkillUnknown: Result := SPtCmdSkillUnknown;
    hcmSkillForms: Result := SPtSkillForms;
    hcmSkillCommands: Result := SPtSkillCommands;
    hcmSkillRecords: Result := SPtSkillRecords;
    hcmSkillPages: Result := SPtSkillPages;
    hcmReplyCut: Result := SPtReplyCut;
    hcmConfirmYes: Result := SPtConfirmYes;
    hcmConfirmNo: Result := SPtConfirmNo;
  else
    Result := '';
  end;
end;

function NorwegianMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SNoGreeting;
    hcmStubReply: Result := SNoStubReply;
    hcmIndexUnavailable: Result := SNoIndexUnavailable;
    hcmNoPageFound: Result := SNoNoPageFound;
    hcmReadMore: Result := SNoReadMore;
    hcmSeeAlso: Result := SNoSeeAlso;
    hcmClaudeNotConfigured: Result := SNoClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SNoProviderKeyMissing;
    hcmProviderNotAvailable: Result := SNoProviderNotAvailable;
    hcmProviderError: Result := SNoProviderError;
    hcmApiError: Result := SNoApiError;
    hcmApiErrorAt: Result := SNoApiErrorAt;
    hcmEmptyReply: Result := SNoEmptyReply;
    hcmCancelled: Result := SNoCancelled;
    hcmScreenContext: Result := SNoScreenContext;
    hcmRelevantDocs: Result := SNoRelevantDocs;
    hcmSource: Result := SNoSource;
    hcmContextQuestion: Result := SNoContextQuestion;
    hcmUiTitle: Result := SNoUiTitle;
    hcmUiHelp: Result := SNoUiHelp;
    hcmUiClear: Result := SNoUiClear;
    hcmUiClose: Result := SNoUiClose;
    hcmUiPlaceholder: Result := SNoUiPlaceholder;
    hcmUiSend: Result := SNoUiSend;
    hcmUiStop: Result := SNoUiStop;
    hcmUiRetry: Result := SNoUiRetry;
    hcmUiSendError: Result := SNoUiSendError;
    hcmUiBack: Result := SNoUiBack;
    hcmUiMic: Result := SNoUiMic;
    hcmVoiceUnavailable: Result := SNoVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SNoVoiceConsentNeeded;
    hcmDocNotFound: Result := SNoDocNotFound;
    hcmActionConfirm: Result := SNoActionConfirm;
    hcmActionValues: Result := SNoActionValues;
    hcmActionConfirmTitle: Result := SNoActionConfirmTitle;
    hcmActionValuesFooter: Result := SNoActionValuesFooter;
    hcmActionsNotRun: Result := SNoActionsNotRun;
    hcmUiAttach: Result := SNoUiAttach;
    hcmUiAttachRemove: Result := SNoUiAttachRemove;
    hcmUiChangeAssistant: Result := SNoUiChangeAssistant;
    hcmUiChangeLanguage: Result := SNoUiChangeLanguage;
    hcmCmdHelp: Result := SNoCmdHelp;
    hcmCmdWho: Result := SNoCmdWho;
    hcmCmdUse: Result := SNoCmdUse;
    hcmCmdLang: Result := SNoCmdLang;
    hcmCmdRetry: Result := SNoCmdRetry;
    hcmCmdSearch: Result := SNoCmdSearch;
    hcmCmdDoc: Result := SNoCmdDoc;
    hcmCmdPages: Result := SNoCmdPages;
    hcmCmdContext: Result := SNoCmdContext;
    hcmCmdActions: Result := SNoCmdActions;
    hcmCmdCheck: Result := SNoCmdCheck;
    hcmCmdStats: Result := SNoCmdStats;
    hcmCmdClear: Result := SNoCmdClear;
    hcmCmdPdf: Result := SNoCmdPdf;
    hcmCmdCopy: Result := SNoCmdCopy;
    hcmCmdAttach: Result := SNoCmdAttach;
    hcmCmdPrompt: Result := SNoCmdPrompt;
    hcmCmdRun: Result := SNoCmdRun;
    hcmCmdUnknown: Result := SNoCmdUnknown;
    hcmCmdProvider: Result := SNoCmdProvider;
    hcmCmdEndpoint: Result := SNoCmdEndpoint;
    hcmCmdNoIndex: Result := SNoCmdNoIndex;
    hcmCmdNoQuestion: Result := SNoCmdNoQuestion;
    hcmCmdNoResults: Result := SNoCmdNoResults;
    hcmCmdPromptStable: Result := SNoCmdPromptStable;
    hcmCmdPromptContext: Result := SNoCmdPromptContext;
    hcmCmdPromptWhole: Result := SNoCmdPromptWhole;
    hcmCmdSearchTerms: Result := SNoCmdSearchTerms;
    hcmCmdNoContext: Result := SNoCmdNoContext;
    hcmCmdNoActions: Result := SNoCmdNoActions;
    hcmCmdRunUsage: Result := SNoCmdRunUsage;
    hcmCmdNoEngine: Result := SNoCmdNoEngine;
    hcmCmdNoAssistant: Result := SNoCmdNoAssistant;
    hcmCmdNoLanguage: Result := SNoCmdNoLanguage;
    hcmCmdStatsLine: Result := SNoCmdStatsLine;
    hcmCmdNoStats: Result := SNoCmdNoStats;
    hcmCmdDocUsage: Result := SNoCmdDocUsage;
    hcmCmdUseUsage: Result := SNoCmdUseUsage;
    hcmCmdNoAnswer: Result := SNoCmdNoAnswer;
    hcmCmdTitleHelp: Result := SNoCmdTitleHelp;
    hcmCmdTitleWho: Result := SNoCmdTitleWho;
    hcmCmdTitleUse: Result := SNoCmdTitleUse;
    hcmCmdTitleLang: Result := SNoCmdTitleLang;
    hcmCmdTitleSearch: Result := SNoCmdTitleSearch;
    hcmCmdTitlePages: Result := SNoCmdTitlePages;
    hcmCmdTitleContext: Result := SNoCmdTitleContext;
    hcmCmdTitleActions: Result := SNoCmdTitleActions;
    hcmCmdTitleCheck: Result := SNoCmdTitleCheck;
    hcmCmdTitleStats: Result := SNoCmdTitleStats;
    hcmCmdTitlePrompt: Result := SNoCmdTitlePrompt;
    hcmCmdTitleRun: Result := SNoCmdTitleRun;
    hcmAttachTypeRefused: Result := SNoAttachTypeRefused;
    hcmAttachTooLarge: Result := SNoAttachTooLarge;
    hcmAttachTooMany: Result := SNoAttachTooMany;
    hcmAttachTooMuch: Result := SNoAttachTooMuch;
    hcmAttachEmpty: Result := SNoAttachEmpty;
    hcmAttachFailed: Result := SNoAttachFailed;
    hcmAttachNotSupported: Result := SNoAttachNotSupported;
    hcmAttachedDocuments: Result := SNoAttachedDocuments;
    hcmAttachedTextFile: Result := SNoAttachedTextFile;
    hcmUiPdfAnswer: Result := SNoUiPdfAnswer;
    hcmUiPdfConversation: Result := SNoUiPdfConversation;
    hcmUiCopyAnswer: Result := SNoUiCopyAnswer;
    hcmUiCopyConversation: Result := SNoUiCopyConversation;
    hcmUiCopyPage: Result := SNoUiCopyPage;
    hcmUiCopied: Result := SNoUiCopied;
    hcmUiCopyFailed: Result := SNoUiCopyFailed;
    hcmUiPdfPage: Result := SNoUiPdfPage;
    hcmPdfAnswerTitle: Result := SNoPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SNoPdfConversationTitle;
    hcmPdfUser: Result := SNoPdfUser;
    hcmPdfAssistant: Result := SNoPdfAssistant;
    hcmPdfFilter: Result := SNoPdfFilter;
    hcmPdfOpen: Result := SNoPdfOpen;
    hcmPdfFailed: Result := SNoPdfFailed;
    hcmPdfNoBands: Result := SNoPdfNoBands;
    hcmPdfNothing: Result := SNoPdfNothing;
    hcmPdfUnavailable: Result := SNoPdfUnavailable;
    hcmPdfHandedOver: Result := SNoPdfHandedOver;
    hcmSkillFill: Result := SNoSkillFill;
    hcmSkillPress: Result := SNoSkillPress;
    hcmSkillCancel: Result := SNoSkillCancel;
    hcmCmdSkills: Result := SNoCmdSkills;
    hcmCmdTitleSkills: Result := SNoCmdTitleSkills;
    hcmCmdNoSkills: Result := SNoCmdNoSkills;
    hcmCmdSkillUnknown: Result := SNoCmdSkillUnknown;
    hcmSkillForms: Result := SNoSkillForms;
    hcmSkillCommands: Result := SNoSkillCommands;
    hcmSkillRecords: Result := SNoSkillRecords;
    hcmSkillPages: Result := SNoSkillPages;
    hcmReplyCut: Result := SNoReplyCut;
    hcmConfirmYes: Result := SNoConfirmYes;
    hcmConfirmNo: Result := SNoConfirmNo;
  else
    Result := '';
  end;
end;

function SwedishMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SSvGreeting;
    hcmStubReply: Result := SSvStubReply;
    hcmIndexUnavailable: Result := SSvIndexUnavailable;
    hcmNoPageFound: Result := SSvNoPageFound;
    hcmReadMore: Result := SSvReadMore;
    hcmSeeAlso: Result := SSvSeeAlso;
    hcmClaudeNotConfigured: Result := SSvClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SSvProviderKeyMissing;
    hcmProviderNotAvailable: Result := SSvProviderNotAvailable;
    hcmProviderError: Result := SSvProviderError;
    hcmApiError: Result := SSvApiError;
    hcmApiErrorAt: Result := SSvApiErrorAt;
    hcmEmptyReply: Result := SSvEmptyReply;
    hcmCancelled: Result := SSvCancelled;
    hcmScreenContext: Result := SSvScreenContext;
    hcmRelevantDocs: Result := SSvRelevantDocs;
    hcmSource: Result := SSvSource;
    hcmContextQuestion: Result := SSvContextQuestion;
    hcmUiTitle: Result := SSvUiTitle;
    hcmUiHelp: Result := SSvUiHelp;
    hcmUiClear: Result := SSvUiClear;
    hcmUiClose: Result := SSvUiClose;
    hcmUiPlaceholder: Result := SSvUiPlaceholder;
    hcmUiSend: Result := SSvUiSend;
    hcmUiStop: Result := SSvUiStop;
    hcmUiRetry: Result := SSvUiRetry;
    hcmUiSendError: Result := SSvUiSendError;
    hcmUiBack: Result := SSvUiBack;
    hcmUiMic: Result := SSvUiMic;
    hcmVoiceUnavailable: Result := SSvVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SSvVoiceConsentNeeded;
    hcmDocNotFound: Result := SSvDocNotFound;
    hcmActionConfirm: Result := SSvActionConfirm;
    hcmActionValues: Result := SSvActionValues;
    hcmActionConfirmTitle: Result := SSvActionConfirmTitle;
    hcmActionValuesFooter: Result := SSvActionValuesFooter;
    hcmActionsNotRun: Result := SSvActionsNotRun;
    hcmUiAttach: Result := SSvUiAttach;
    hcmUiAttachRemove: Result := SSvUiAttachRemove;
    hcmUiChangeAssistant: Result := SSvUiChangeAssistant;
    hcmUiChangeLanguage: Result := SSvUiChangeLanguage;
    hcmCmdHelp: Result := SSvCmdHelp;
    hcmCmdWho: Result := SSvCmdWho;
    hcmCmdUse: Result := SSvCmdUse;
    hcmCmdLang: Result := SSvCmdLang;
    hcmCmdRetry: Result := SSvCmdRetry;
    hcmCmdSearch: Result := SSvCmdSearch;
    hcmCmdDoc: Result := SSvCmdDoc;
    hcmCmdPages: Result := SSvCmdPages;
    hcmCmdContext: Result := SSvCmdContext;
    hcmCmdActions: Result := SSvCmdActions;
    hcmCmdCheck: Result := SSvCmdCheck;
    hcmCmdStats: Result := SSvCmdStats;
    hcmCmdClear: Result := SSvCmdClear;
    hcmCmdPdf: Result := SSvCmdPdf;
    hcmCmdCopy: Result := SSvCmdCopy;
    hcmCmdAttach: Result := SSvCmdAttach;
    hcmCmdPrompt: Result := SSvCmdPrompt;
    hcmCmdRun: Result := SSvCmdRun;
    hcmCmdUnknown: Result := SSvCmdUnknown;
    hcmCmdProvider: Result := SSvCmdProvider;
    hcmCmdEndpoint: Result := SSvCmdEndpoint;
    hcmCmdNoIndex: Result := SSvCmdNoIndex;
    hcmCmdNoQuestion: Result := SSvCmdNoQuestion;
    hcmCmdNoResults: Result := SSvCmdNoResults;
    hcmCmdPromptStable: Result := SSvCmdPromptStable;
    hcmCmdPromptContext: Result := SSvCmdPromptContext;
    hcmCmdPromptWhole: Result := SSvCmdPromptWhole;
    hcmCmdSearchTerms: Result := SSvCmdSearchTerms;
    hcmCmdNoContext: Result := SSvCmdNoContext;
    hcmCmdNoActions: Result := SSvCmdNoActions;
    hcmCmdRunUsage: Result := SSvCmdRunUsage;
    hcmCmdNoEngine: Result := SSvCmdNoEngine;
    hcmCmdNoAssistant: Result := SSvCmdNoAssistant;
    hcmCmdNoLanguage: Result := SSvCmdNoLanguage;
    hcmCmdStatsLine: Result := SSvCmdStatsLine;
    hcmCmdNoStats: Result := SSvCmdNoStats;
    hcmCmdDocUsage: Result := SSvCmdDocUsage;
    hcmCmdUseUsage: Result := SSvCmdUseUsage;
    hcmCmdNoAnswer: Result := SSvCmdNoAnswer;
    hcmCmdTitleHelp: Result := SSvCmdTitleHelp;
    hcmCmdTitleWho: Result := SSvCmdTitleWho;
    hcmCmdTitleUse: Result := SSvCmdTitleUse;
    hcmCmdTitleLang: Result := SSvCmdTitleLang;
    hcmCmdTitleSearch: Result := SSvCmdTitleSearch;
    hcmCmdTitlePages: Result := SSvCmdTitlePages;
    hcmCmdTitleContext: Result := SSvCmdTitleContext;
    hcmCmdTitleActions: Result := SSvCmdTitleActions;
    hcmCmdTitleCheck: Result := SSvCmdTitleCheck;
    hcmCmdTitleStats: Result := SSvCmdTitleStats;
    hcmCmdTitlePrompt: Result := SSvCmdTitlePrompt;
    hcmCmdTitleRun: Result := SSvCmdTitleRun;
    hcmAttachTypeRefused: Result := SSvAttachTypeRefused;
    hcmAttachTooLarge: Result := SSvAttachTooLarge;
    hcmAttachTooMany: Result := SSvAttachTooMany;
    hcmAttachTooMuch: Result := SSvAttachTooMuch;
    hcmAttachEmpty: Result := SSvAttachEmpty;
    hcmAttachFailed: Result := SSvAttachFailed;
    hcmAttachNotSupported: Result := SSvAttachNotSupported;
    hcmAttachedDocuments: Result := SSvAttachedDocuments;
    hcmAttachedTextFile: Result := SSvAttachedTextFile;
    hcmUiPdfAnswer: Result := SSvUiPdfAnswer;
    hcmUiPdfConversation: Result := SSvUiPdfConversation;
    hcmUiCopyAnswer: Result := SSvUiCopyAnswer;
    hcmUiCopyConversation: Result := SSvUiCopyConversation;
    hcmUiCopyPage: Result := SSvUiCopyPage;
    hcmUiCopied: Result := SSvUiCopied;
    hcmUiCopyFailed: Result := SSvUiCopyFailed;
    hcmUiPdfPage: Result := SSvUiPdfPage;
    hcmPdfAnswerTitle: Result := SSvPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SSvPdfConversationTitle;
    hcmPdfUser: Result := SSvPdfUser;
    hcmPdfAssistant: Result := SSvPdfAssistant;
    hcmPdfFilter: Result := SSvPdfFilter;
    hcmPdfOpen: Result := SSvPdfOpen;
    hcmPdfFailed: Result := SSvPdfFailed;
    hcmPdfNoBands: Result := SSvPdfNoBands;
    hcmPdfNothing: Result := SSvPdfNothing;
    hcmPdfUnavailable: Result := SSvPdfUnavailable;
    hcmPdfHandedOver: Result := SSvPdfHandedOver;
    hcmSkillFill: Result := SSvSkillFill;
    hcmSkillPress: Result := SSvSkillPress;
    hcmSkillCancel: Result := SSvSkillCancel;
    hcmCmdSkills: Result := SSvCmdSkills;
    hcmCmdTitleSkills: Result := SSvCmdTitleSkills;
    hcmCmdNoSkills: Result := SSvCmdNoSkills;
    hcmCmdSkillUnknown: Result := SSvCmdSkillUnknown;
    hcmSkillForms: Result := SSvSkillForms;
    hcmSkillCommands: Result := SSvSkillCommands;
    hcmSkillRecords: Result := SSvSkillRecords;
    hcmSkillPages: Result := SSvSkillPages;
    hcmReplyCut: Result := SSvReplyCut;
    hcmConfirmYes: Result := SSvConfirmYes;
    hcmConfirmNo: Result := SSvConfirmNo;
  else
    Result := '';
  end;
end;

function DanishMsg(const AId: THelpChatMsgId): string;
begin
  case AId of
    hcmGreeting: Result := SDaGreeting;
    hcmStubReply: Result := SDaStubReply;
    hcmIndexUnavailable: Result := SDaIndexUnavailable;
    hcmNoPageFound: Result := SDaNoPageFound;
    hcmReadMore: Result := SDaReadMore;
    hcmSeeAlso: Result := SDaSeeAlso;
    hcmClaudeNotConfigured: Result := SDaClaudeNotConfigured;
    hcmProviderKeyMissing: Result := SDaProviderKeyMissing;
    hcmProviderNotAvailable: Result := SDaProviderNotAvailable;
    hcmProviderError: Result := SDaProviderError;
    hcmApiError: Result := SDaApiError;
    hcmApiErrorAt: Result := SDaApiErrorAt;
    hcmEmptyReply: Result := SDaEmptyReply;
    hcmCancelled: Result := SDaCancelled;
    hcmScreenContext: Result := SDaScreenContext;
    hcmRelevantDocs: Result := SDaRelevantDocs;
    hcmSource: Result := SDaSource;
    hcmContextQuestion: Result := SDaContextQuestion;
    hcmUiTitle: Result := SDaUiTitle;
    hcmUiHelp: Result := SDaUiHelp;
    hcmUiClear: Result := SDaUiClear;
    hcmUiClose: Result := SDaUiClose;
    hcmUiPlaceholder: Result := SDaUiPlaceholder;
    hcmUiSend: Result := SDaUiSend;
    hcmUiStop: Result := SDaUiStop;
    hcmUiRetry: Result := SDaUiRetry;
    hcmUiSendError: Result := SDaUiSendError;
    hcmUiBack: Result := SDaUiBack;
    hcmUiMic: Result := SDaUiMic;
    hcmVoiceUnavailable: Result := SDaVoiceUnavailable;
    hcmVoiceConsentNeeded: Result := SDaVoiceConsentNeeded;
    hcmDocNotFound: Result := SDaDocNotFound;
    hcmActionConfirm: Result := SDaActionConfirm;
    hcmActionValues: Result := SDaActionValues;
    hcmActionConfirmTitle: Result := SDaActionConfirmTitle;
    hcmActionValuesFooter: Result := SDaActionValuesFooter;
    hcmActionsNotRun: Result := SDaActionsNotRun;
    hcmUiAttach: Result := SDaUiAttach;
    hcmUiAttachRemove: Result := SDaUiAttachRemove;
    hcmUiChangeAssistant: Result := SDaUiChangeAssistant;
    hcmUiChangeLanguage: Result := SDaUiChangeLanguage;
    hcmCmdHelp: Result := SDaCmdHelp;
    hcmCmdWho: Result := SDaCmdWho;
    hcmCmdUse: Result := SDaCmdUse;
    hcmCmdLang: Result := SDaCmdLang;
    hcmCmdRetry: Result := SDaCmdRetry;
    hcmCmdSearch: Result := SDaCmdSearch;
    hcmCmdDoc: Result := SDaCmdDoc;
    hcmCmdPages: Result := SDaCmdPages;
    hcmCmdContext: Result := SDaCmdContext;
    hcmCmdActions: Result := SDaCmdActions;
    hcmCmdCheck: Result := SDaCmdCheck;
    hcmCmdStats: Result := SDaCmdStats;
    hcmCmdClear: Result := SDaCmdClear;
    hcmCmdPdf: Result := SDaCmdPdf;
    hcmCmdCopy: Result := SDaCmdCopy;
    hcmCmdAttach: Result := SDaCmdAttach;
    hcmCmdPrompt: Result := SDaCmdPrompt;
    hcmCmdRun: Result := SDaCmdRun;
    hcmCmdUnknown: Result := SDaCmdUnknown;
    hcmCmdProvider: Result := SDaCmdProvider;
    hcmCmdEndpoint: Result := SDaCmdEndpoint;
    hcmCmdNoIndex: Result := SDaCmdNoIndex;
    hcmCmdNoQuestion: Result := SDaCmdNoQuestion;
    hcmCmdNoResults: Result := SDaCmdNoResults;
    hcmCmdPromptStable: Result := SDaCmdPromptStable;
    hcmCmdPromptContext: Result := SDaCmdPromptContext;
    hcmCmdPromptWhole: Result := SDaCmdPromptWhole;
    hcmCmdSearchTerms: Result := SDaCmdSearchTerms;
    hcmCmdNoContext: Result := SDaCmdNoContext;
    hcmCmdNoActions: Result := SDaCmdNoActions;
    hcmCmdRunUsage: Result := SDaCmdRunUsage;
    hcmCmdNoEngine: Result := SDaCmdNoEngine;
    hcmCmdNoAssistant: Result := SDaCmdNoAssistant;
    hcmCmdNoLanguage: Result := SDaCmdNoLanguage;
    hcmCmdStatsLine: Result := SDaCmdStatsLine;
    hcmCmdNoStats: Result := SDaCmdNoStats;
    hcmCmdDocUsage: Result := SDaCmdDocUsage;
    hcmCmdUseUsage: Result := SDaCmdUseUsage;
    hcmCmdNoAnswer: Result := SDaCmdNoAnswer;
    hcmCmdTitleHelp: Result := SDaCmdTitleHelp;
    hcmCmdTitleWho: Result := SDaCmdTitleWho;
    hcmCmdTitleUse: Result := SDaCmdTitleUse;
    hcmCmdTitleLang: Result := SDaCmdTitleLang;
    hcmCmdTitleSearch: Result := SDaCmdTitleSearch;
    hcmCmdTitlePages: Result := SDaCmdTitlePages;
    hcmCmdTitleContext: Result := SDaCmdTitleContext;
    hcmCmdTitleActions: Result := SDaCmdTitleActions;
    hcmCmdTitleCheck: Result := SDaCmdTitleCheck;
    hcmCmdTitleStats: Result := SDaCmdTitleStats;
    hcmCmdTitlePrompt: Result := SDaCmdTitlePrompt;
    hcmCmdTitleRun: Result := SDaCmdTitleRun;
    hcmAttachTypeRefused: Result := SDaAttachTypeRefused;
    hcmAttachTooLarge: Result := SDaAttachTooLarge;
    hcmAttachTooMany: Result := SDaAttachTooMany;
    hcmAttachTooMuch: Result := SDaAttachTooMuch;
    hcmAttachEmpty: Result := SDaAttachEmpty;
    hcmAttachFailed: Result := SDaAttachFailed;
    hcmAttachNotSupported: Result := SDaAttachNotSupported;
    hcmAttachedDocuments: Result := SDaAttachedDocuments;
    hcmAttachedTextFile: Result := SDaAttachedTextFile;
    hcmUiPdfAnswer: Result := SDaUiPdfAnswer;
    hcmUiPdfConversation: Result := SDaUiPdfConversation;
    hcmUiCopyAnswer: Result := SDaUiCopyAnswer;
    hcmUiCopyConversation: Result := SDaUiCopyConversation;
    hcmUiCopyPage: Result := SDaUiCopyPage;
    hcmUiCopied: Result := SDaUiCopied;
    hcmUiCopyFailed: Result := SDaUiCopyFailed;
    hcmUiPdfPage: Result := SDaUiPdfPage;
    hcmPdfAnswerTitle: Result := SDaPdfAnswerTitle;
    hcmPdfConversationTitle: Result := SDaPdfConversationTitle;
    hcmPdfUser: Result := SDaPdfUser;
    hcmPdfAssistant: Result := SDaPdfAssistant;
    hcmPdfFilter: Result := SDaPdfFilter;
    hcmPdfOpen: Result := SDaPdfOpen;
    hcmPdfFailed: Result := SDaPdfFailed;
    hcmPdfNoBands: Result := SDaPdfNoBands;
    hcmPdfNothing: Result := SDaPdfNothing;
    hcmPdfUnavailable: Result := SDaPdfUnavailable;
    hcmPdfHandedOver: Result := SDaPdfHandedOver;
    hcmSkillFill: Result := SDaSkillFill;
    hcmSkillPress: Result := SDaSkillPress;
    hcmSkillCancel: Result := SDaSkillCancel;
    hcmCmdSkills: Result := SDaCmdSkills;
    hcmCmdTitleSkills: Result := SDaCmdTitleSkills;
    hcmCmdNoSkills: Result := SDaCmdNoSkills;
    hcmCmdSkillUnknown: Result := SDaCmdSkillUnknown;
    hcmSkillForms: Result := SDaSkillForms;
    hcmSkillCommands: Result := SDaSkillCommands;
    hcmSkillRecords: Result := SDaSkillRecords;
    hcmSkillPages: Result := SDaSkillPages;
    hcmReplyCut: Result := SDaReplyCut;
    hcmConfirmYes: Result := SDaConfirmYes;
    hcmConfirmNo: Result := SDaConfirmNo;
  else
    Result := '';
  end;
end;

var
  // The replacements of HelpChatSetMsg: [AId, hclAuto] is the one for every
  // language. GMsgCount keeps the lock out of the common case, nobody
  // having replaced anything.
  GMsgOverrides: array[THelpChatMsgId, THelpChatLanguage] of string;
  GMsgCount: Integer = 0;
  GMsgLock: TCriticalSection;

procedure HelpChatSetMsg(const AId: THelpChatMsgId; const AText: string;
  const ALanguage: THelpChatLanguage);
begin
  GMsgLock.Enter;
  try
    if (GMsgOverrides[AId, ALanguage] = '') and (AText <> '') then
      Inc(GMsgCount)
    else if (GMsgOverrides[AId, ALanguage] <> '') and (AText = '') then
      Dec(GMsgCount);
    GMsgOverrides[AId, ALanguage] := AText;
  finally
    GMsgLock.Leave;
  end;
end;

procedure HelpChatClearMsgs;
var
  LId: THelpChatMsgId;
  LLanguage: THelpChatLanguage;
begin
  GMsgLock.Enter;
  try
    for LId := Low(THelpChatMsgId) to High(THelpChatMsgId) do
      for LLanguage := Low(THelpChatLanguage) to High(THelpChatLanguage) do
        GMsgOverrides[LId, LLanguage] := '';
    GMsgCount := 0;
  finally
    GMsgLock.Leave;
  end;
end;

function OverriddenMsg(const AId: THelpChatMsgId; const ALanguage: THelpChatLanguage;
  out AText: string): Boolean;
begin
  AText := '';
  if GMsgCount = 0 then
    Exit(False);
  GMsgLock.Enter;
  try
    AText := GMsgOverrides[AId, ALanguage];
    if AText = '' then
      AText := GMsgOverrides[AId, hclAuto];
  finally
    GMsgLock.Leave;
  end;
  Result := AText <> '';
end;

function HelpChatMsg(const AId: THelpChatMsgId; const ALanguage: THelpChatLanguage): string;
var
  LLanguage: THelpChatLanguage;
begin
  LLanguage := HelpChatResolveLanguage(ALanguage);
  if OverriddenMsg(AId, LLanguage, Result) then
    Exit;
  case LLanguage of
    hclItalian: Result := ItalianMsg(AId);
    hclSpanish: Result := SpanishMsg(AId);
    hclFrench: Result := FrenchMsg(AId);
    hclGerman: Result := GermanMsg(AId);
    hclPortuguese: Result := PortugueseMsg(AId);
    hclNorwegian: Result := NorwegianMsg(AId);
    hclSwedish: Result := SwedishMsg(AId);
    hclDanish: Result := DanishMsg(AId);
  else
    Result := EnglishMsg(AId);
  end;
end;

function HelpChatMsgFmt(const AId: THelpChatMsgId; const AArgs: array of const;
  const ALanguage: THelpChatLanguage): string;
begin
  Result := Format(HelpChatMsg(AId, ALanguage), AArgs);
end;

initialization
  GMsgLock := TCriticalSection.Create;

finalization
  FreeAndNil(GMsgLock);

end.
