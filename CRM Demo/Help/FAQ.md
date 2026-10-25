# FAQ

## Where is my data?

In `w10crmdemo.sdb`, in your **Documents** folder. It is a SQLite database encrypted with
AES-256, and it is the only thing the application writes — there is no settings file and no
registry key.

## How do I start over with the sample data?

Close the application, delete `w10crmdemo.sdb`, start it again. The file is rebuilt with the
original leads, accounts and proposals.

## Why did all my leads disappear?

Almost certainly the **user drop-down** in the title bar changed. Nearly every list is
filtered by it. Put it back on the user that owns the records — `CRMUser` in the sample data.

If the user itself was removed from the [Users](Users.md) page, its records are still in the
database but nothing can see them: create a user with exactly the same name and they come
back.

## Can two people use it at the same time?

No. The database is a file on your machine and the application opens it for itself. The
users in the application are labels for filtering, not accounts on a server.

## Does the user drop-down protect anything?

No. There is no password, and anybody can switch user from the title bar. It organizes
work, it does not secure it.

## Why is the total of my proposal $0.00?

Because the draft has no line items yet, or because the row you typed has not been confirmed.
Press `✓` under the grid, or move to another row: the total recomputes as soon as the row is
posted.

## Why is the amount written with a dot when my computer uses a comma?

On purpose. The invoice is an English document, so its amounts are written the English way —
`$1,234.50` — whatever the regional settings of the machine are. What you type in the draft,
and what you see in the **Total** box, follows your own settings.

## Can I change a proposal after saving it?

No. The document is stored as it was generated. You can mark it *Accepted* or *Canceled*, but
not edit it, and the lead cannot be given a second one. To redo a proposal, delete the
existing one from the [Sales](Sales.md) list with the navigator and create a new one.

## Why does a lead stay in its column after I accept its proposal?

Because **Complete** and **Cancel** act on the proposal, not on the lead. Moving the lead to
*Closed* is a separate decision — drag it on the [board](Leads.md).

## Which export should I use?

The one on the [Marketing](Marketing.md) page: it writes a delimited text file with a header
row, which a spreadsheet opens directly. The exports on the Accounts and Leads pages write
FireDAC's own format, meant to be read back by this application.

## Does the assistant need an internet connection?

Yes, and an API key: it uses Anthropic's Claude. Put the key in `helpchatai.json` under
`%APPDATA%\HelpChatAI`. Without it the assistant opens and says the key is missing, and the
rest of the application works exactly as before — see
[Asking the assistant](Assistant.md).

## Does my data leave the machine when I use the assistant?

Your question, the name of the screen you are on, the excerpts of this manual that look
relevant and the outcome of any action it runs. **Not the database**: leads, accounts,
proposals and attached documents are never sent, and the assistant cannot read them.

## Can the assistant change my data?

Only in the three ways listed in [Asking the assistant](Assistant.md), and the two that
write something stop and ask first, showing what they are about to do. It never saves a
proposal and never deletes anything.

## Can I attach a big file to a lead?

It will work, but the file goes **inside** the database, so the `.sdb` grows by that much and
every backup carries it. Also, the document name is stored in a 20-character field: longer
file names are cut.

## Why are the icons hard to see when I change style?

They are white images. They are made for a dark background: the three styles shipped with
this build — SlateGray, Dark and Blue — all work. A light style would wash them out.

## Is this a product?

No, it is a demonstration of VCL controls — the split view, the relative and card panels, the
calendar view, LiveBindings over FireDAC, styles, scaling. Read [Known
limitations](ToDo.md) before using any of it as a starting point.
