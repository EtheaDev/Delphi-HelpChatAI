# HelpChatAI provider benchmark

Run on 2026-11-12 18:06. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude-haiku-5-5 | 1.0 s | 8 | 0 | 1.8 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.1 s | 8 | 0 | 2.2 s | 1.3 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 2.2 s | 8 | 0 | 2.6 s | 1.3 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | claude-haiku-5-5 | 2.3 s | 1.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 2.3 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 3.3 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 2.3 s | 1.4 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 1.9 s | 0.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 3.1 s | 1.3 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | claude-haiku-5-5 | 1.7 s | 1.2 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.1 s | 1.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 2.9 s | 0.9 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q4 | claude-haiku-5-5 | 2.4 s | 1.9 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.7 s | 0.6 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.0 s | 0.6 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q5 | claude-haiku-5-5 | 1.5 s | 1.1 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.7 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 2.3 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | claude-haiku-5-5 | 1.1 s | 0.7 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 2.2 s | 1.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.3 s | 0.6 s | - | yes | 0/0 | - | yes |
| Q7 | claude-haiku-5-5 | 1.7 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 2.8 s | 2.7 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.8 s | 1.8 s | - | yes | 0/0 | open_screen | yes |
| Q8 | claude-haiku-5-5 | 1.6 s | 1.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.6 s | 2.6 s | Assistant.md | **no** | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.7 s | 3.7 s | Assistant.md | **no** | 0/0 | create_lead | yes |

## Questions

- **Q1** (screen Leads): How do I move a lead from one column of the board to another, and what happens to its dates? - expected page: Leads.md - facts: drag, status, date - no action
- **Q2** (screen Dashboard): Where is my data stored, and how do I start over with the sample data? - expected page: FAQ.md or Getting-Started.md - facts: w10crmdemo.sdb, Documents, delete - no action
- **Q3** (screen Sales): Can I change a proposal after I saved it? - expected page: FAQ.md or Draft-Proposal.md or Sales.md - facts: No, delete - no action
- **Q4** (screen Accounts): Which export gives me a file I can open in Excel? - expected page: FAQ.md or Marketing.md or Accounts.md - facts: Marketing - no action
- **Q5** (screen Leads): How do I find a lead when I only know its e-mail address? - expected page: Leads.md - facts: Search, mail - no action
- **Q6** (screen Dashboard): What is the weather in Milan today? - no action
- **Q7** (screen Dashboard): Open the Accounts screen for me. - action: open_screen(Accounts)
- **Q8** (screen Leads): Create a lead named Mario Rossi for the company Apollo Orange, LLC., e-mail mario.rossi@example.com. - action: create_lead(Mario Rossi)

## Answers

### claude-haiku-5-5

**warm-up** (1.0 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard tiles, the main window, or managing users. What would you like to know?

**Q1** (2.3 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on. Dropping it on the column it's already in does nothing. The four lists refresh after each move, and the lead you dragged stays selected ([Leads](Leads.md)).
> 
> Its dates work like this:
> - If the date for the new stage is still empty, it's stamped with the current date and time. Moving to **Active** fills Date Contacted, moving to **Proposal Sent** fills Date Drafted, and moving to **Closed** fills Date Closed.
> - If that date already has a value, it's left alone. Moving a lead back and forth doesn't overwrite its history.

**Q2** (2.3 s)

> **Where your data is stored:** Everything is in one SQLite file, `w10crmdemo.sdb`, in your Documents folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **How to start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data. ([Getting started](Getting-Started.md))
> 
> Deleting the file removes all your current records, and the application has no undo. Most deletes also have no confirmation prompt, so make sure you no longer need the current data before you delete the file.

**Q3** (1.7 s)

> No. Once saved, a proposal can't be edited. It is stored as it was generated. You can mark it Accepted or Canceled, but the lead can't be given a second proposal.
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (2.4 s)

> Use the **Export** on the **Marketing** page. It writes a delimited text file with a header row, which a spreadsheet such as Excel opens directly.
> 
> The exports on the Accounts and Leads pages use FireDAC's own format, which only this application can read back, so they won't open in Excel.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.5 s)

> On the Leads board, type the e-mail address into the **Search** box. It filters all four columns as you type, and it matches the e-mail field, so you can type the whole address or just part of it. Clear the box to get the full board back. ([Leads](Leads.md))

**Q6** (1.1 s)

> I can't help with that. This assistant only answers questions about the CRM Demo application, and its documentation doesn't cover weather.
> 
> I can help with the app itself, for example the Dashboard tiles, how users filter records, or how to create a lead.

**Q7** (1.7 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (1.6 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column.

### claude-sonnet-5-5

**warm-up** (1.1 s)

> Hello! I'm the in-app help assistant for this application. I can explain how to use things like the Dashboard, Accounts, Leads, Sales, Marketing, Calendar and Users screens. What would you like to know?

**Q1** (2.3 s)

> To move a lead, **drag its row from one column and drop it on another** on the Leads board.
> 
> Two things happen when you drop it:
> 
> 1. **The status changes.** The lead takes the status of the column you dropped it on.
> 2. **The date for that stage may be stamped.** If that stage's date is still empty, it is set to now:
>    - moving to **Active** stamps *Date Contacted*
>    - moving to **Proposal Sent** stamps *Date Drafted*
>    - moving to **Closed** stamps *Date Closed*
> 
> A date that already has a value is left alone. Moving a lead back and forth therefore doesn't rewrite its history.
> 
> - Dropping a lead on the column it's already in does nothing.
> - The four lists refresh after every move, and the lead you dragged stays selected.
> - Inactive leads have no column on the board. They are only counted on the Dashboard.
> 
> Source: [Leads](Leads.md)

**Q2** (1.9 s)

> **Where it's stored:** Everything is in a single SQLite file, `w10crmdemo.sdb`, in your Documents folder. It's encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again.
> 
> The file is rebuilt with the original sample data: 8 leads, 8 accounts, one user (CRMUser) and three proposals. ([Getting started](Getting-Started.md))
> 
> Deleting the file is the only way to undo changes. The application has no rollback, and most deletes ask for no confirmation. Anything you've added or changed will be lost. ([Data model](Data-Model.md))

**Q3** (2.1 s)

> No. Once a proposal is saved, you can't edit it. The document is stored exactly as it was generated. You can only mark it **Accepted** or **Canceled**. A lead also can't be given a second proposal.
> 
> To redo a proposal:
> 1. Delete the existing one from the Sales list with the navigator.
> 2. Create a new one from **Create Proposal** in the lead detail window.
> 
> Source: [FAQ](FAQ.md)

**Q4** (1.7 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet such as Excel can open that file directly.
> 
> The exports on the Accounts and Leads pages don't work for this. They write FireDAC's own format (binary, XML or JSON, depending on the extension you give), which only this application is meant to read back. It is not a spreadsheet file.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.7 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or just part of it, into the Search box.
> 2. All four columns filter as you type. The match ignores case and works anywhere inside the value, so `example.com` finds everybody at that domain.
> 3. To get the full board back, clear the box.
> 
> Search also matches the lead's name, account name and office phone.
> 
> Once the lead appears, double-click its row, or select it and press **View Lead**, to open its detail window.
> 
> Source: [Leads](Leads.md)

**Q6** (2.2 s)

> I can't help with the weather in Milan. I can only answer questions about how to use this application, and the documentation doesn't cover that.
> 
> If you have a question about the Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users screens, ask me and I'll help.

**Q7** (2.8 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I opened the Accounts screen.

**Q8** (2.6 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. Its id is 101. Per the [manual](Assistant.md), a new lead starts with status New and its detail window opens so you can fill in the rest.

### claude-opus-5-5

**warm-up** (2.2 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard**, which shows how many leads the active user has in each status: New, Active, Proposal Sent, Closed and Inactive, plus a Total ([Dashboard](Dashboard.md)).
> 
> You can ask me how to use any part of the application. I can also do some things for you, like opening a screen or creating a lead for a company that's already in your Accounts list.

**Q1** (3.3 s)

> On the Leads board you move a lead by **dragging and dropping** it:
> 
> 1. Drag the lead's row out of its current column.
> 2. Drop it on the column you want.
> 
> **What happens:**
> - The lead takes the status of the column you dropped it on.
> - If that stage's date is still empty, it gets set to the current date and time:
>   - moving to **Active** sets `Date Contacted`
>   - moving to **Proposal Sent** sets `Date Drafted`
>   - moving to **Closed** sets `Date Closed`
> - If the date already has a value, it doesn't change. So moving a lead back and forth won't overwrite its history.
> - Dropping a lead on the column it's already in does nothing.
> - All four lists refresh after each move, and the lead you dragged stays selected.
> 
> Note that **Inactive** has no column on the board, so you can't drag a lead there. Inactive leads only show up in the Dashboard counts.
> 
> Source: [Leads](Leads.md)

**Q2** (3.1 s)

> Your data is all in one SQLite file called **`w10crmdemo.sdb`**, in your **Documents** folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (`CRMUser`) and three proposals. ([Getting started](Getting-Started.md))
> 
> **Warning:** Deleting the file is the only way to undo changes, and it erases everything you've entered. There's no rollback, and most deletes don't ask you to confirm. ([Data model](Data-Model.md))

**Q3** (2.9 s)

> No, a saved proposal can't be edited. It's stored exactly as it was generated. All you can do is change its status: mark it **Accepted** with **Complete** or **Canceled** with **Cancel**. A lead also can't be given a second proposal. ([FAQ](FAQ.md))
> 
> **To redo a proposal:**
> 1. On the **Sales** list, select the proposal and delete it with the navigator.
> 2. Open the lead and press **Create Proposal** to draft a new one. ([FAQ](FAQ.md))
> 
> **About the status buttons:** **Complete** and **Cancel** don't ask for confirmation. You can apply either one again later, so an accepted proposal can still be canceled. ([Sales](Sales.md))

**Q4** (2.0 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet like Excel opens that directly.
> 
> The **Export** button on this Accounts screen, and the one on the Leads page, won't give you an Excel file. They save in FireDAC's own format (binary, XML or JSON), which only this application is meant to read back. The Accounts export also saves the whole table, not just the filtered list.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (2.3 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type all or part of the e-mail address into the **Search** box.
> 2. All four columns filter as you type. The search ignores case and matches text anywhere inside the value, so a fragment such as the domain (`example.com`) is enough.
> 3. Clear the box to see the full board again.
> 
> The same box also matches the lead's name, account name and office phone. Once you find the lead, double-click its row or select it and press **View Lead** to open it.
> 
> Search only covers the four columns on the board. Leads with the **Inactive** status don't have a column there, so they won't show up.
> 
> Source: [Leads](Leads.md)

**Q6** (1.3 s)

> I can't help with the weather. I can only explain how to use this CRM application, and the documentation doesn't cover weather.
> 
> If you have a question about the app, like what the Dashboard tiles count or how to add a lead, just ask.

**Q7** (1.8 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I've opened the **Accounts** screen for you.

**Q8** (3.7 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`.
> 
> New leads start with the status **New**. Their detail window should open right away so you can add the rest, such as the office phone ([Asking the assistant](Assistant.md)).

