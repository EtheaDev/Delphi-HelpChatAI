{******************************************************************************}
{                                                                              }
{   HelpChatAI CRM demo - the actions of the assistant                         }
{                                                                              }
{   What the assistant may do in this application, declared once for both     }
{   demos: name, description and parameters are what the model reads, so two   }
{   copies would drift apart. The data is changed by the data module (uDataMod }
{   knows nothing about the assistant); what only a window can do - bring a    }
{   screen to the front, refresh its links, open the lead or the draft - the   }
{   main form of each demo passes in as hooks.                                 }
{                                                                              }
{******************************************************************************}

unit uCRMActions;

interface

uses
  System.SysUtils, HelpChatAI.Actions, uProposalReport;

type
  /// <summary>A proposal the assistant prepared: what the draft window is
  /// filled with.</summary>
  TCRMDraft = record
    LeadId: Integer;
    Company: string;
    Address1: string;
    Address2: string;
    Phone: string;
    Items: TArray<TProposalLineItem>;
  end;

  /// <summary>The visual half of the actions, one per demo. Every hook runs
  /// on the main thread, inside the action, and must return at once: a
  /// window is opened with Show, never ShowModal.</summary>
  TCRMActionHooks = record
    /// <summary>Brings the screen the model named to the front; returns its
    /// caption, or '' when there is no such screen.</summary>
    OpenScreen: TFunc<string, string>;
    /// <summary>The user the new records belong to (the combo of the main
    /// form).</summary>
    CurrentUser: TFunc<string>;
    /// <summary>A company was added: the grids and the combos that show the
    /// companies read them again.</summary>
    AccountCreated: TProc<string>;
    /// <summary>A lead was added (its id): the detail window shows it.</summary>
    LeadCreated: TProc<Integer>;
    /// <summary>A proposal is ready: the draft window shows it, unsaved.</summary>
    DraftReady: TProc<TCRMDraft>;
  end;

/// <summary>Registers open_screen, create_account and create_lead on
/// AActions, and draft_proposal on AProposalActions - the same broker with
/// one assistant, <c>HelpChatSharedActions</c> in the multi-assistant
/// edition, where the configuration decides who uses it.</summary>
procedure RegisterCRMActions(const AActions, AProposalActions: THelpChatActionBroker;
  const AHooks: TCRMActionHooks);

implementation

uses
  uDataMod;

procedure RegisterCRMActions(const AActions, AProposalActions: THelpChatActionBroker;
  const AHooks: TCRMActionHooks);
var
  LHooks: TCRMActionHooks;
begin
  LHooks := AHooks;

  AActions.Add('open_screen',
    'Brings one of the application screens to the front. Only when the user asks to ' +
    'go to a screen: never to show where something is while answering a question.',
    [THelpChatActionParam.Create('name',
      'Screen name: Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users.')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LCaption: string;
    begin
      LCaption := LHooks.OpenScreen(AArgs.AsString('name'));
      if LCaption = '' then
        raise Exception.CreateFmt('There is no "%s" screen.', [AArgs.AsString('name')]);
      AResult := 'Opened the ' + LCaption + ' screen.';
    end, False); // changes nothing: no confirmation

  // Writes a record: it asks for confirmation (the default), and the user
  // sees the name and the values before answering.
  AActions.Add('create_account',
    'Creates a company in the Accounts list. Use it before create_lead when the ' +
    'company of the lead is not there yet.',
    [THelpChatActionParam.Create('name', 'Company name')],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LName: string;
    begin
      LName := DM.CreateAccount(AArgs.AsString('name'));
      LHooks.AccountCreated(LName);
      AResult := Format('Account "%s" created.', [LName]);
    end);

  // The company must exist: the data module looks it up and, when it is
  // missing or the name is ambiguous, tells the model with an exception
  // that says what to do - create it with create_account, or ask the user.
  AActions.Add('create_lead',
    'Creates a new lead for the active user and opens its detail window so the ' +
    'user can check it. Does not send anything to anybody. The company must ' +
    'exist in the Accounts list: if it does not, create it with create_account first.',
    [THelpChatActionParam.Create('name', 'Name of the person'),
     THelpChatActionParam.Create('account',
       'Company name, as in the Accounts list (it must exist)', apkString, False),
     THelpChatActionParam.Create('phone', 'Office phone', apkString, False),
     THelpChatActionParam.Create('email', 'E-mail address', apkString, False),
     THelpChatActionParam.Create('notes', 'Anything worth remembering', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LLeadId: Integer;
    begin
      LLeadId := DM.CreateLead(AArgs.AsString('name'), AArgs.AsString('account'),
        AArgs.AsString('phone'), AArgs.AsString('email'), AArgs.AsString('notes'),
        LHooks.CurrentUser());
      LHooks.LeadCreated(LLeadId);
      AResult := Format('Lead "%s" created with status New (id %d).',
        [AArgs.AsString('name'), LLeadId]);
    end, True);

  // Fills the draft and stops there: Preview and Save Proposal stay the
  // user's. The format of the line items is in the description of the
  // parameter, and the model follows it.
  AProposalActions.Add('draft_proposal',
    'Opens the proposal draft for a lead with the address and the line items ' +
    'already filled in. It does not save it: the user presses Preview and Save Proposal.',
    [THelpChatActionParam.Create('lead', 'Name of the lead, or of its company'),
     THelpChatActionParam.Create('items',
       'The line items, one per line, written as "title x quantity @ price", ' +
       'for example "Consulting x 12 @ 150". The price uses a dot as decimal separator.'),
     THelpChatActionParam.Create('address1', 'Street address of the customer', apkString, False),
     THelpChatActionParam.Create('address2', 'City, state and postal code', apkString, False),
     THelpChatActionParam.Create('phone', 'Phone of the customer', apkString, False)],
    procedure(const AArgs: THelpChatActionArgs; var AResult: string)
    var
      LDraft: TCRMDraft;
    begin
      LDraft.Items := ParseProposalLineItems(AArgs.AsString('items'));
      DM.LeadForProposal(AArgs.AsString('lead'), LDraft.LeadId, LDraft.Company);
      LDraft.Address1 := AArgs.AsString('address1');
      LDraft.Address2 := AArgs.AsString('address2');
      LDraft.Phone := AArgs.AsString('phone');
      LHooks.DraftReady(LDraft);
      AResult := Format('Draft ready for %s with %d line item(s): check it and press Preview.',
        [LDraft.Company, Length(LDraft.Items)]);
    end, True);
end;

end.
