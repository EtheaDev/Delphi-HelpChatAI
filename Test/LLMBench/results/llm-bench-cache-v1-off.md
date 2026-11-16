# HelpChatAI provider benchmark

Run on 2026-11-16 19:50. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude | 1.0 s | 8 | 0 | 1.8 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 0.9 s | 8 | 0 | 1.8 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.9 s | 8 | 0 | 1.8 s | 1.0 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 1.5 s | 8 | 0 | 2.6 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

### Tokens

Prompt cache **off** (`--nocache`). The questions, warm-up excluded, of each target in a row, as one session would ask them.

| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |
|---|---:|---:|---:|---:|---:|---:|
| claude | 10 | 30092 | 0 | 0 | 2308 | 30092 |
| claude-haiku-5-5 | 10 | 30046 | 0 | 0 | 2114 | 30046 |
| claude-sonnet-5-5 | 10 | 29850 | 0 | 0 | 1310 | 29850 |
| claude-opus-5-5 | 10 | 29850 | 0 | 0 | 1632 | 29850 |

"Input": tokens at the full price. "Input as billed": input + 1.25 x cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), in tokens of the full price.

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | claude | 2.2 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 2.2 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 2.2 s | 0.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 3.1 s | 1.2 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | claude | 2.2 s | 1.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 1.7 s | 1.1 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 2.1 s | 0.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 3.2 s | 0.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | claude | 1.4 s | 1.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 1.6 s | 1.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 1.4 s | 0.5 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 2.8 s | 0.8 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q4 | claude | 1.7 s | 1.3 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 1.8 s | 1.3 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.5 s | 0.6 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.2 s | 1.1 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | claude | 1.2 s | 0.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.2 s | 0.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.6 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 2.8 s | 0.9 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | claude | 1.3 s | 0.8 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 1.2 s | 0.8 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 2.3 s | 1.4 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.6 s | 0.7 s | - | yes | 0/0 | - | yes |
| Q7 | claude | 1.7 s | 1.7 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 1.6 s | 1.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.6 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.9 s | 1.9 s | - | yes | 0/0 | open_screen | yes |
| Q8 | claude | 2.8 s | 2.4 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 2.7 s | 2.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.2 s | 2.2 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.1 s | 3.1 s | Assistant.md | yes | 0/0 | create_lead | yes |

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

### claude

**warm-up** (1.0 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, for example the Dashboard tiles, the main window, or how users filter records. What would you like to know?

**Q1** (2.2 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates change as follows:
> - If the date for the new stage is still empty, it is stamped with the current date and time. Moving to Active sets Date Contacted, moving to Proposal Sent sets Date Drafted, and moving to Closed sets Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not overwrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> After each move the four lists refresh, and the lead you dragged stays selected. For more detail, see [Leads](Leads.md).

**Q2** (2.2 s)

> Your data is stored in one encrypted SQLite file, **w10crmdemo.sdb**, in your Documents folder. It is encrypted with AES-256. The file holds the five stored tables, and the proposal-drafting tables exist only in memory while you work. ([Data model](Data-Model.md))
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data.
> 
> ([Getting started](Getting-Started.md))
> 
> Deleting the file erases all your current data, and the application has no way to undo this.

**Q3** (1.4 s)

> No. The document is stored as it was generated, so you can't edit it after saving. You can mark it Accepted or Canceled, but not change its content. To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (1.7 s)

> Use the **export on the Marketing page**. It writes a delimited text file with a header row, which a spreadsheet opens directly. ([FAQ](FAQ.md))
> 
> The **Export button on the Accounts page** does not work for this. It writes FireDAC's own binary, XML or JSON format, which only this application can read back. ([Accounts](Accounts.md))

**Q5** (1.2 s)

> On the Leads board, type the e-mail address (or part of it) into the **Search** box. It filters all four columns as you type, matching the lead's name, account name, office phone or e-mail, ignoring case. Clear the box to get the full board back. ([Leads](Leads.md))

**Q6** (1.3 s)

> I can't help with that. I only answer questions about how to use this CRM application, and its documentation doesn't cover weather. I can help with things like the Dashboard tiles, Leads, Accounts, or switching users.

**Q7** (1.7 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.8 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column, and its detail window should be open so you can fill in the rest.

### claude-haiku-5-5

**warm-up** (0.9 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, for example the Dashboard tiles, the main window, or how users filter the records you see. What would you like to know?

**Q1** (2.2 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on. [Leads](Leads.md)
> 
> Its dates change as follows:
> 
> - If the date for that stage is still empty, it is stamped with the current date and time. Moving to Active fills Date Contacted, moving to Proposal Sent fills Date Drafted, and moving to Closed fills Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> After each move, the four lists refresh and the lead you dragged stays selected. [Leads](Leads.md)

**Q2** (1.7 s)

> Your data is stored in one encrypted SQLite file, **w10crmdemo.sdb**, in your Documents folder. It is encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data ([Getting started](Getting-Started.md)).
> 
> Deleting the file is permanent. The application has no undo, no rollback, and on most deletes no confirmation ([Data model](Data-Model.md)).

**Q3** (1.6 s)

> No. A saved proposal is stored as it was generated, so it can't be edited. You can mark it Accepted or Canceled, but not change its content. The lead also can't receive a second proposal.
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (1.8 s)

> Use the **export on the Marketing page**. It writes a delimited text file with a header row, which a spreadsheet opens directly ([FAQ](FAQ.md)).
> 
> The exports on the **Accounts** and **Leads** pages write FireDAC's own binary, XML, or JSON format, meant to be read back by this application, so they won't open usefully in Excel ([Accounts](Accounts.md)).

**Q5** (1.2 s)

> On the Leads board, type part or all of the e-mail address into the **Search** box. It filters all four columns as you type and matches anywhere inside the value, so even a partial address such as `example.com` will work. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (1.2 s)

> I can't help with that. I'm the help assistant for the CRM Demo application, and its documentation doesn't cover weather or any external information. I can explain how to use the application, such as what the Dashboard tiles count or how to manage users.

**Q7** (1.6 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.7 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It starts in the New column.

### claude-sonnet-5-5

**warm-up** (1.9 s)

> Hello! I'm the in-app help assistant for this application. I can explain how to use it, for example the Dashboard, Accounts, Leads, Sales, Marketing, Calendar and Users screens. I can also create a lead for you if you give me the details.
> 
> What would you like to know?

**Q1** (2.2 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on, and the four lists refresh. The lead you dragged stays selected.
> 
> **What happens to the dates**
> - If the date for that stage is still empty, it is stamped with the current date and time:
>   - moving to **Active** sets *Date Contacted*
>   - moving to **Proposal Sent** sets *Date Drafted*
>   - moving to **Closed** sets *Date Closed*
> - If that date already has a value, it is left alone. Moving a lead back and forth therefore doesn't rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> Leads with the status Inactive have no column on the board. They are only counted on the Dashboard.
> 
> Source: [Leads](Leads.md)

**Q2** (2.1 s)

> **Where your data is stored:** everything is in a single SQLite file, `w10crmdemo.sdb`, in your Documents folder. It is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user and three proposals. ([Getting started](Getting-Started.md))
> 
> Deleting the file is the only way to undo changes. The application has no rollback, and most deletes have no confirmation. Anything you've added or changed will be lost. ([Data model](Data-Model.md))

**Q3** (1.4 s)

> No. A saved proposal can't be edited, because the document is stored exactly as it was generated. You can only mark it **Accepted** or **Canceled**. The lead also can't be given a second proposal.
> 
> To redo a proposal:
> 1. On the **Sales** screen, delete the existing proposal with the navigator.
> 2. Create a new proposal for the lead.
> 
> Source: [FAQ](FAQ.md)

**Q4** (1.5 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet can open that file directly.
> 
> The exports on the Accounts and Leads pages don't work for this. They write FireDAC's own format (binary, XML or JSON), which only this application can read back, and Excel can't use it as a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.6 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or just part of it, into the Search box.
> 2. The four columns filter as you type. The match ignores case and looks anywhere inside the value, so `example.com` finds every lead with that domain.
> 3. Clear the box to get the full board back.
> 
> Search also matches the lead's name, account name and office phone.
> 
> To open the lead you found, double-click its row, or select it and press **View Lead**.
> 
> Source: [Leads](Leads.md)

**Q6** (2.3 s)

> I can't help with the weather in Milan. I only explain how to use this application, and the documentation I have doesn't cover weather. A weather service or website will have the forecast.
> 
> If you have a question about the Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users screens, I can help with that.

**Q7** (1.6 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is open.

**Q8** (2.2 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for Apollo Orange, LLC. with the e-mail mario.rossi@example.com. It starts with status New, so you'll find it in the New column of the Leads board.

### claude-opus-5-5

**warm-up** (1.5 s)

> Hello! I'm the in-app help assistant. I can explain how to use this CRM, for example what the Dashboard tiles count, how users work or how to move between screens. I can also do some things for you, like opening a screen or creating a lead. What would you like to do?

**Q1** (3.1 s)

> To move a lead, **drag its row from one column and drop it on another**.
> 
> When you drop it:
> 
> 1. **The status changes.** The lead takes the status of the column you dropped it on.
> 2. **The date for that stage is filled in if it's empty.** It gets the current date and time:
>    - Moving to **Active** fills in `Date Contacted`
>    - Moving to **Proposal Sent** fills in `Date Drafted`
>    - Moving to **Closed** fills in `Date Closed`
> 3. **Dates that are already filled in don't change.** So moving a lead back and forth won't rewrite its history.
> 
> Also:
> - Dropping a lead on the column it's already in does nothing.
> - All four columns refresh after every move, and the lead you dragged stays selected.
> - To open a lead's details, double-click its row, or select it and press **View Lead**.
> 
> Source: [Leads](Leads.md)

**Q2** (3.2 s)

> **Where it's stored:** All your data is in one SQLite file, `w10crmdemo.sdb`, in your **Documents** folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **How to start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (CRMUser) and three proposals. Then it opens on the Dashboard.
> 
> ([Getting started](Getting-Started.md))
> 
> **Note:** Deleting the file removes all your changes for good. Resetting this way is the only way to undo anything, because the application can't roll back changes and doesn't ask you to confirm most deletes. ([Data model](Data-Model.md))

**Q3** (2.8 s)

> **No.** A proposal is saved exactly as it was generated, and you can't edit it afterwards.
> 
> What you can do:
> 
> - **Change its status:** select it in the Sales list and press **Complete** to mark it Accepted, or **Cancel** to mark it Canceled. Neither button asks you to confirm. You can use them again later, because nothing is locked once a proposal is accepted.
> - **Redo it:** each lead can only have one proposal. To make a new one, first delete the existing proposal from the Sales list using the navigator, then create a new one.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.2 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and Excel can open that directly.
> 
> The **Export** on this Accounts page won't give you that. It saves the whole table in FireDAC's own format (binary, XML or JSON, depending on the file extension you choose). Only this application can read that file back, and it isn't a spreadsheet file. The export on the Leads page uses the same format.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (2.8 s)

> Type the e-mail address, or any part of it, into the **Search** box on the Leads board. The board filters all four columns as you type. The search ignores upper and lower case and matches text anywhere in a lead's name, account name, office phone or e-mail. For example, typing `example.com` finds every lead with that domain.
> 
> When the lead shows up, double-click its row (or select it and press **View Lead**) to open its details. Clear the Search box to see the whole board again.
> 
> Leads with the **Inactive** status don't appear on the board, so you can't find those this way.
> 
> Source: [Leads](Leads.md)

**Q6** (1.6 s)

> I can't help with the weather. I only answer questions about using this CRM application, and the documentation doesn't cover weather. The app also doesn't need or use a network connection.
> 
> If you have a question about the Dashboard or any other screen, just ask.

**Q7** (1.9 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I opened the **Accounts** screen for you.

**Q8** (3.1 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`. New leads start with the status **New**, so it's in the first column of the Leads board ([Asking the assistant](Assistant.md)). You can add a phone number or notes in its detail window.

