{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       CRM Demo - the multi-assistant edition (FireMonkey)                    }
{                                                                              }
{       Copyright (c) 2026 (Ethea S.r.l.)                                      }
{       Author: Carlo Barazzetta                                               }
{                                                                              }
{       https://github.com/EtheaDev/Delphi-HelpChatAI                          }
{                                                                              }
{       Licensed under the Apache License, Version 2.0                         }
{                                                                              }
{******************************************************************************}

/// <summary>
///  The FireMonkey twin of uMultiAgent: compiled only by
///  FMX_CRMDemo_MultiAgent.dproj, which defines MULTIAGENT. Two assistants -
///  the general one on the main window, the Sales one on the lead window - and
///  draft_proposal registered once among the shared actions, used only by the
///  assistant whose AllowedActions names it. See uMultiAgent (VCL) for the
///  whole story; what differs here is the context: a FireMonkey form has no
///  HelpKeyword, so the Sales assistant reads it through the OnGetContext of
///  the main window, which already knows the keyword of each window.
/// </summary>
unit uMultiAgentFmx;

interface

uses
  FMX.Forms,
  FMX.HelpChatAI;

const
  /// <summary>The profile of the Sales assistant: the key of its section
  /// under "Profiles" in a configuration file, and the suffix of its
  /// conversation file.</summary>
  SALES_PROFILE = 'Sales';

/// <summary>What the general assistant may do and who it sends the user to.
/// Called before it is activated.</summary>
procedure ConfigureGeneralAssistant(const AChat: TFmxHelpChatAI);

/// <summary>The Sales assistant, on AHost (the lead window), with the
/// provider, models, manual, key handler and context handler of AGeneral.</summary>
function CreateSalesAssistant(const AGeneral: TFmxHelpChatAI;
  const AHost: TCommonCustomForm): TFmxHelpChatAI;

implementation

uses
  HelpChatAI.Assistant;

procedure ConfigureGeneralAssistant(const AChat: TFmxHelpChatAI);
begin
  // Its own actions, by name. draft_proposal is a shared action, so without
  // this list the general assistant would be offered it too.
  AChat.Settings.AllowedActions := 'open_screen, create_account, create_lead';
  AChat.Settings.Instructions :=
    'Proposals are the job of the Sales assistant, in the window of the lead: when the ' +
    'user asks you to prepare, change or price a proposal, say so and tell them to open ' +
    'the lead and ask there.';
end;

function CreateSalesAssistant(const AGeneral: TFmxHelpChatAI;
  const AHost: TCommonCustomForm): TFmxHelpChatAI;
begin
  Result := TFmxHelpChatAI.Create(AHost);
  Result.Name := 'SalesHelpChat';
  Result.Settings.Assign(AGeneral.Settings);
  Result.OnDecryptSecret := AGeneral.OnDecryptSecret;
  // The keyword of the lead window comes from the handler of the main one.
  Result.OnGetContext := AGeneral.OnGetContext;
  Result.Profile := SALES_PROFILE;
  Result.AssistantName := 'Sales';
  Result.ImageName := HELPCHAT_ICON_AI_MALE;   // the general one wears the female icon
  Result.Settings.Expertise :=
    'B2B sales: proposals, pricing, discounts and VAT, following a customer up';
  Result.Settings.Instructions :=
    'You prepare and explain the proposals of the leads: their line items, their total, ' +
    'when to send them and how to follow them up.';
  Result.Settings.DocAreas := 'Sales';
  Result.Settings.AllowedActions := 'draft_proposal';
  Result.Active := True;
end;

end.
