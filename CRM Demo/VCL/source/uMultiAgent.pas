{******************************************************************************}
{                                                                              }
{       HelpChat: an in-app AI Help Chat component for Delphi (VCL and FMX)    }
{       CRM Demo - the multi-assistant edition (VCL)                           }
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
///  What turns the CRM demo into a demo of several assistants. It is compiled
///  only by VCL_CRMDemo_MultiAgent.dproj, which defines MULTIAGENT; the plain
///  demo, VCL_CRMDemo.dproj, never sees it. Everything the multi-assistant
///  edition adds is here, apart from the two lines of TMainForm that call it
///  and the place where draft_proposal is registered.
///
///  Two assistants, each on the form that owns it:
///  - the general one, on the main window (the component of the form file):
///    the whole manual, and the actions of the main window - open a screen,
///    create an account, create a lead;
///  - the Sales one, on the lead window (created here): the pages of the
///    manual in the area Sales, an Expertise of its own, and the only one
///    that may prepare a proposal.
///
///  draft_proposal is registered once, among the actions every assistant may
///  use (HelpChatSharedActions), and it is the configuration that decides who
///  uses it: AllowedActions of the general assistant leaves it out, the one of
///  the Sales assistant names it. Nothing in the handler knows who called it.
///  The same keys - Expertise, DocAreas, AllowedActions, Instructions - may go
///  under "Profiles" in helpchatai.json instead of in code.
///
///  The areas are in the front matter of the pages ("areas: [Sales]"): one
///  manual and one index for both editions, and the plain demo, which sets no
///  DocAreas, still reads every page.
/// </summary>
unit uMultiAgent;

interface

uses
  Vcl.Forms,
  Vcl.HelpChatAI;

const
  /// <summary>The profile of the Sales assistant: the key of its section
  /// under "Profiles" in a configuration file, and the suffix of its
  /// conversation file.</summary>
  SALES_PROFILE = 'Sales';

/// <summary>What the general assistant may do and who it sends the user to.
/// Called before it is activated: an engine takes a copy of the settings when
/// it starts.</summary>
procedure ConfigureGeneralAssistant(const AChat: TVclHelpChatAI);

/// <summary>The Sales assistant, on AHost (the lead window): the provider,
/// the models, the manual and the key handler of AGeneral, then what makes it
/// the expert of proposals. Owned by AHost, which makes AHost its form: its
/// bubble, its window and its F1 are there.</summary>
function CreateSalesAssistant(const AGeneral: TVclHelpChatAI;
  const AHost: TForm): TVclHelpChatAI;

implementation

uses
  HelpChatAI.Assistant;

procedure ConfigureGeneralAssistant(const AChat: TVclHelpChatAI);
begin
  // Its own actions, by name. draft_proposal is a shared action, so without
  // this list the general assistant would be offered it too.
  AChat.Settings.AllowedActions := 'open_screen, create_account, create_lead';
  AChat.Settings.Instructions :=
    'Proposals are the job of the Sales assistant, in the window of the lead: when the ' +
    'user asks you to prepare, change or price a proposal, say so and tell them to open ' +
    'the lead and ask there.';
end;

function CreateSalesAssistant(const AGeneral: TVclHelpChatAI;
  const AHost: TForm): TVclHelpChatAI;
begin
  Result := TVclHelpChatAI.Create(AHost);
  Result.Name := 'SalesHelpChat';
  // The same provider, models, manual and key as the general assistant...
  Result.Settings.Assign(AGeneral.Settings);
  Result.OnDecryptSecret := AGeneral.OnDecryptSecret;
  // ...and what makes it another assistant. The profile gives it an engine
  // and a conversation of its own.
  Result.Profile := SALES_PROFILE;
  Result.AssistantName := 'Sales';
  Result.ImageName := HELPCHAT_ICON_AI_FEMALE;
  Result.Settings.Expertise :=
    'B2B sales: proposals, pricing, discounts and VAT, following a customer up';
  Result.Settings.Instructions :=
    'You prepare and explain the proposals of the leads: their line items, their total, ' +
    'when to send them and how to follow them up.';
  // The pages of the area Sales, plus those of no area (the FAQ, getting
  // started...); the general assistant reads them all.
  Result.Settings.DocAreas := 'Sales';
  // The one action it may use: a shared one, registered by the main window.
  Result.Settings.AllowedActions := 'draft_proposal';
  Result.Active := True;
end;

end.
