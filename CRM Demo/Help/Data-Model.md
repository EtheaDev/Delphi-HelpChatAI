# Data model

Everything is in one SQLite file, `w10crmdemo.sdb`, in your **Documents** folder, encrypted
with AES-256. Five tables are stored in it; two more exist only in memory while a proposal
is being drafted.

## Leads

The central table. One row per person you are working on.

| Field | Type | Notes |
| - | - | - |
| `LeadId` | auto-increment | The key. Shown in the detail window and in some columns of the board |
| `Name` | text (100) | The person |
| `Status` | text (100) | `New`, `Active`, `Proposal Sent`, `Closed`, `Inactive` — free text, not a foreign key |
| `AccountName` | text (100) | The **name** of the account, copied, not its id: renaming an account does not follow here |
| `OfficePhone` | text (100) | |
| `Email` | text (100) | Feeds the [Marketing](Marketing.md) list |
| `User` | text (100) | The owner. Every screen filters on it |
| `DateCreated` | date/time | Stamped when the lead is created |
| `DateContacted` | date/time | Stamped the first time it reaches *Active* |
| `DateDrafted` | date/time | Stamped the first time it reaches *Proposal Sent* |
| `DateClosed` | date/time | Stamped the first time it reaches *Closed* |
| `Notes` | text (2048) | |

The three date stamps are written **only if the field is still empty**, so moving a lead
backwards and forwards does not rewrite them.

## Accounts

| Field | Type | Notes |
| - | - | - |
| `AccountId` | auto-increment | |
| `AccountName` | text (100) | Offered in the lead's **Account Name** box, printed as "Bill To" |

Not filtered by user: the list is shared.

## Users

| Field | Type | Notes |
| - | - | - |
| `UserId` | auto-increment | |
| `Username` | text (20) | The value stored in the `User` column of the other tables |

## Docs

The files attached to a lead, stored whole inside the database.

| Field | Type | Notes |
| - | - | - |
| `DocId` | auto-increment | |
| `LeadId` | integer | Which lead it belongs to |
| `DocumentName` | text (**20**) | The file name — a short limit, long names are cut |
| `Document` | blob | The file itself |
| `User` | text (20) | Who attached it |

## Proposals

| Field | Type | Notes |
| - | - | - |
| `ProposalId` | auto-increment | |
| `LeadId` | integer | One proposal per lead is what the application enforces |
| `ProposalName` | text (20) | Always `New Proposal` |
| `Status` | text (20) | `New`, `Accepted`, `Canceled` |
| `Value` | currency | The total of the invoice when it was saved |
| `Proposal` | blob | The HTML document |
| `DateCreated` | date/time | |
| `DateCompleted` | date/time | Written when the proposal is accepted |
| `User` | text (20) | |

## While a proposal is being drafted

Two tables live in memory only and are emptied each time the draft window opens.

**LineItems** — `RecordId` (auto-increment), `Title` (text 20), `Quantity` (integer),
`Price` (currency).

**DraftProposal** — `CompanyName`, `Address1`, `Address2`, `Phone` (text 128 each),
`Date`, `Total` (currency).

## The queries behind each screen

| Screen | Query |
| - | - |
| Leads, column *New* | `SELECT * FROM Leads WHERE Status = 'New' AND User = :Username` |
| Leads, *Active* / *Proposal Sent* / *Closed* | the same, with the other status |
| Lead detail, documents | `SELECT * FROM Docs WHERE LeadId = :LeadId AND User = :Username` |
| Sales | `SELECT * FROM Proposals WHERE User = :Username` |
| Marketing | `SELECT Email, Name FROM Leads WHERE Status <> 'Inactive' AND User = :Username` |
| Accounts | `SELECT * FROM Accounts` |
| Dashboard, one per tile | `SELECT COUNT(LeadId) FROM Leads WHERE Status = '…' AND User = :Username` |
| Draft, the total | `SELECT coalesce(sum(Quantity * Price), 0) FROM LineItems` |

Each one has a place where the **Search** box injects a condition, which is how filtering as
you type works. The searches match with `LIKE '%…%'` on the upper-cased value, so they ignore
case and match anywhere inside the field:

| Search box | Looks at |
| - | - |
| Leads | name, account name, office phone, e-mail |
| Accounts | account name |
| Sales | proposal name |
| Marketing | e-mail |

## Resetting

Close the application, delete `w10crmdemo.sdb`, start it again: the file is rebuilt with the
original sample data. There is no other way to undo anything — the application has no
transaction you can roll back and no confirmation on most deletes.
