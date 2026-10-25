# Known limitations

What this demonstration does not do, and what to watch out for. The list comes from reading
the source, not from guessing.

## Not implemented

| Where | What |
| - | - |
| [The assistant](Assistant.md) | Three actions only: open a screen, create a lead, prepare a proposal. It cannot move a lead between columns, create an account, save a proposal or delete anything |
| [Lead detail](Lead-Detail.md) | The **Call** and **Email** buttons next to the phone number and the address have no action behind them |
| [Calendar](Calendar.md) | The month view is not bound to anything: no lead date is marked on it, selecting a day filters nothing, appointments cannot be added |
| [Sales](Sales.md) | Every proposal is called `New Proposal` — the draft window never asks for a name — which makes the search box on this page nearly useless |
| [Sales](Sales.md) | The document column of the list shows `(OBJECT)`, because a grid cannot render the stored HTML |
| Proposals | A saved proposal cannot be edited or reprinted, only accepted or cancelled |

## Easy to get wrong

- **Remove asks nothing.** Removing an account, a user or a row from a navigator happens
  immediately and cannot be undone. Only *Delete Document* asks for confirmation.
- **Removing a user hides its records** instead of reassigning or deleting them. They
  reappear if a user with the same name is created again.
- **Accounts are copied by name into a lead**, not referenced: renaming or deleting an
  account leaves the lead pointing at a name that no longer exists.
- **Nothing is validated**: an account with an empty name, two accounts with the same name,
  an e-mail that is not an e-mail, a quantity of zero — all accepted. The sample data itself
  contains an account with an empty name and id 0.
- **Accepting a proposal does not close its lead**, and nothing stops a proposal from being
  accepted and then cancelled.

## Field sizes worth knowing

`DocumentName`, `ProposalName`, `Status` and the line item `Title` are **20 characters**, and
`Username` is 20 too. Longer values are cut when stored. The lead's own fields are 100, and
the notes 2048.

## Security

The database is encrypted with AES-256, but **the password is written in the source code**
(`DB_PASSWORD` in `uDataMod.pas`). That is fine for a demonstration and worth nothing in a
real application: anyone with the executable has the key.

There is no login, and the user drop-down protects nothing.

## Technical notes for whoever reads the code

These were found and fixed while preparing this manual, and are worth knowing if you compare
the code with the original Embarcadero version:

- the total of a draft was computed with SQL `printf("%.2f", …)`, which returns a **string**
  with a dot, and then read as a currency: on a machine with Italian regional settings that
  raised *'0.00' is not a valid floating point value*. The query now returns a number;
- the generated invoice took its amounts from the screen and from `AsString`, so an Italian
  machine produced `$1.800,00` in an English document. They now go through an explicit
  en-US format;
- `AddInvoiceData` declared its parameters as `(AName, APrice, AQuantity)` but was called
  with `(Title, Quantity, Price)`: the output was right only because the two mistakes
  cancelled out;
- two resize handlers multiplied a size that was **already** in screen pixels by
  `ScaleFactor`, which at 150% or 175% made a grid column wider than its grid;
- two width comparisons (640 and 936) were raw constants, so the layout switched at the
  wrong size on a scaled display;
- the column widths of the bound grids are stored in design pixels and LiveBindings reapplies
  them **after** the VCL has scaled the grid, so at 175% the columns stayed narrow and cut
  the text. They are now scaled once at start-up.

Still open in the code: five in-memory tables are freed while they are still components of
the data module; the drag-and-drop handler repeats the same block four times and can call
`Locate` with `-1`; a temporary file written by *View Document* is never deleted; and the two
proposal windows use the legacy Internet Explorer control to display their HTML.
