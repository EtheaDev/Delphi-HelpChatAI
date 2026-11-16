# HelpChatAI provider benchmark

Run on 2026-11-16 19:51. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude | 1.0 s | 8 | 0 | 2.0 s | 1.5 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 0.8 s | 8 | 0 | 1.8 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 2.2 s | 8 | 0 | 2.0 s | 1.1 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 1.7 s | 8 | 0 | 2.4 s | 1.0 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

### Tokens

Prompt cache on (`Claude.PromptCaching`, the default). The questions, warm-up excluded, of each target in a row, as one session would ask them.

| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |
|---|---:|---:|---:|---:|---:|---:|
| claude | 10 | 36 | 19668 | 10146 | 2138 | 25636 |
| claude-haiku-5-5 | 10 | 36 | 0 | 29814 | 2180 | 3017 |
| claude-sonnet-5-5 | 10 | 36 | 19668 | 10146 | 1406 | 25636 |
| claude-opus-5-5 | 10 | 36 | 19668 | 10146 | 1566 | 25636 |

"Input": tokens at the full price. "Input as billed": input + 1.25 x cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), in tokens of the full price.

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | claude | 2.1 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 2.0 s | 1.2 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 3.3 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 2.9 s | 0.8 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | claude | 2.5 s | 1.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 2.7 s | 2.0 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 1.8 s | 0.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 3.0 s | 0.7 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | claude | 1.5 s | 1.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 1.5 s | 1.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.4 s | 1.2 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 2.4 s | 0.6 s | Sales.md FAQ.md | yes | 2/2 | - | yes |
| Q4 | claude | 3.4 s | 2.3 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 2.3 s | 1.8 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.5 s | 0.7 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.0 s | 0.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | claude | 1.3 s | 0.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.3 s | 0.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.7 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 2.5 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | claude | 1.4 s | 0.8 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 1.3 s | 0.7 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 1.1 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.7 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q7 | claude | 1.2 s | 1.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 1.1 s | 1.0 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.5 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.5 s | 1.4 s | - | yes | 0/0 | open_screen | yes |
| Q8 | claude | 2.9 s | 2.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 2.4 s | 2.1 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.4 s | 2.4 s | Assistant.md Leads.md | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.2 s | 3.2 s | Assistant.md | yes | 0/0 | create_lead | yes |

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

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, including the Dashboard tiles, the main window, and Users. What would you like to know?

**Q1** (2.1 s)

> To move a lead, drag its row from its current column and drop it on the column for the new status. The lead takes that column's status.
> 
> Its dates change as follows:
> 
> - If the date for that stage is still empty, it is stamped with the current date and time. Moving a lead to Active fills Date Contacted, moving it to Proposal Sent fills Date Drafted, and moving it to Closed fills Date Closed.
> - If the date already has a value, it is left alone. Moving a lead back and forth does not overwrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> The four lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.5 s)

> **Where your data is stored:** Everything is in one SQLite file, `w10crmdemo.sdb`, in your Documents folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data.
> 
> Deleting the file removes all your current records, and the application has no way to undo this. ([Data model](Data-Model.md), [Getting started](Getting-Started.md))

**Q3** (1.5 s)

> No. A saved proposal is stored as it was generated, so it can't be edited. You can mark it Accepted or Canceled with the buttons in the Sales banner, but not change its content. To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (3.4 s)

> Use the **export on the Marketing page**. It writes a delimited text file with a header row, which a spreadsheet such as Excel opens directly.
> 
> The export on the Accounts page does not work for this. It writes FireDAC's own binary, XML or JSON format, meant to be read back by this application, not a spreadsheet file.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.3 s)

> On the Leads board, type part or all of the e-mail address into the **Search** box. It filters all four columns as you type, and it matches anywhere inside the value, ignoring case. Typing `example.com` shows every lead with an address at that domain. Clear the box to get the full board back.
> 
> Source: [Leads](Leads.md)

**Q6** (1.4 s)

> I can't help with that. I'm the help assistant for the CRM Demo application, and I only have its documentation, which doesn't cover weather. I can explain how to use the app's screens, such as the Dashboard, Leads, Accounts, or Users, if you have a question about them.

**Q7** (1.2 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.9 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It starts with status New, and its detail window should be open so you can fill in the rest.

### claude-haiku-5-5

**warm-up** (0.8 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, for example how the Dashboard counters work, how users filter records, or how to find your way around the main window. What would you like to know?

**Q1** (2.0 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you drop it on.
> 
> Its dates change as follows:
> 
> - If the date for that stage is still empty, it is stamped with the current date and time. Moving to Active fills Date Contacted, moving to Proposal Sent fills Date Drafted, and moving to Closed fills Date Closed.
> - If that date already has a value, it is left alone, so moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> The four lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.7 s)

> Your data is stored in one SQLite file, **w10crmdemo.sdb**, in your Documents folder. The file is encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again. It creates the file and copies the sample data into it ([Getting started](Getting-Started.md)).
> 
> Deleting the file is permanent. The application has no way to undo this, so any changes you made are lost.

**Q3** (1.5 s)

> No. A saved proposal is stored as it was generated, so it can't be edited. You can mark it Accepted or Canceled, but not change its content. To redo it, delete the existing proposal from the Sales list with the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (2.3 s)

> Use the **Export** on the **Marketing** page. It writes a delimited text file with a header row, which a spreadsheet such as Excel opens directly. ([FAQ](FAQ.md))
> 
> The **Export** on the **Accounts** page does not work for this. It writes FireDAC's own binary, XML or JSON format, meant to be read back by this application, not a spreadsheet file. ([Accounts](Accounts.md))

**Q5** (1.3 s)

> Type the e-mail address, or part of it, into the **Search** box at the top of the Leads board. The four columns filter as you type. The search matches against the lead's name, account name, office phone and e-mail, ignoring case and matching anywhere inside the value. So typing the full address or just the domain (for example, `example.com`) will narrow the board. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (1.3 s)

> I can't help with that. I'm the help assistant for the CRM Demo application, and my answers are limited to how to use it. I don't have weather information, so for Milan's forecast please check a weather service.
> 
> If you have a question about the CRM, such as reading the Dashboard tiles or managing users, I can help with that.

**Q7** (1.1 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I've opened the Accounts screen for you.

**Q8** (2.4 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts with status New, and its detail window should be open so you can fill in the rest.

### claude-sonnet-5-5

**warm-up** (2.2 s)

> Hello! I can help you use this CRM application. For example, I can explain the Dashboard tiles, the Leads board, Accounts or Users. I can also create a lead for you if you give me the person's name and the company, which must already be in the Accounts list. What would you like to do?

**Q1** (3.3 s)

> To move a lead, drag its row from one column and drop it on another. The user is already on the Leads board, so they can do this now.
> 
> **What happens when you drop it:**
> - The lead takes the status of the column you dropped it on.
> - If the date for that stage is still empty, it is stamped with the current date and time:
>   - Moving to **Active** fills *Date Contacted*.
>   - Moving to **Proposal Sent** fills *Date Drafted*.
>   - Moving to **Closed** fills *Date Closed*.
> - A date that already has a value is left alone. Moving a lead back and forth doesn't rewrite its history.
> 
> **Other points:**
> - Dropping a lead on the column it's already in does nothing.
> - The four lists refresh after every move, and the lead you dragged stays selected.
> - The *Inactive* status has no column on the board. Those leads are only counted on the Dashboard.
> 
> Source: [Leads](Leads.md)

**Q2** (1.8 s)

> **Where your data is stored:** Everything is in a single SQLite file named `w10crmdemo.sdb` in your Documents folder. It is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user and three proposals. ([Getting started](Getting-Started.md))
> 
> Deleting the file is the only way to undo anything, and it removes all your own changes. The application has no rollback and no confirmation on most deletes. ([Data model](Data-Model.md))

**Q3** (2.4 s)

> No. A saved proposal can't be edited, because the document is stored exactly as it was generated. You can only mark it **Accepted** or **Canceled**. A lead can't be given a second proposal either. ([FAQ](FAQ.md))
> 
> To redo a proposal:
> 1. Delete the existing one from the Sales list with the navigator.
> 2. Create a new one.
> 
> Complete and Cancel don't ask for confirmation, and you can apply them again later. Nothing is locked once a proposal is accepted. ([Sales](Sales.md))

**Q4** (1.5 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet can open that file directly.
> 
> The exports on the Accounts and Leads pages don't work for this. They write FireDAC's own format (binary, XML or JSON), which only this application can read back. They don't produce a spreadsheet file.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.7 s)

> Use the **Search** box on the Leads board:
> 
> 1. Click the Search box.
> 2. Type the e-mail address, or just part of it.
> 3. All four columns filter as you type. The search ignores case and matches anywhere inside the value.
> 4. Clear the box to get the full board back.
> 
> The search checks the lead's name, account name, office phone and e-mail. Typing `example.com` finds every lead with that domain.
> 
> Once the lead appears, double-click it, or select it and press **View Lead**, to open its details.
> 
> Source: [Leads](Leads.md)

**Q6** (1.1 s)

> I can't help with that. I only explain how to use this application, and the documentation doesn't cover weather. If you have a question about the Dashboard, Leads, Accounts, Sales, Marketing, Calendar or Users, ask me and I'll help.

**Q7** (1.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.4 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC. with the e-mail mario.rossi@example.com. It starts with the status New, and its detail window should now be open so you can fill in the rest. See [Asking the assistant](Assistant.md) and [Leads](Leads.md).

### claude-opus-5-5

**warm-up** (1.7 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard**, where each tile shows how many leads the active user has with a given status ([Dashboard](Dashboard.md)).
> 
> I can explain how any part of the application works. I can also do a couple of things for you: open a screen, or create a new lead for a company that's already in your Accounts list. What would you like to do?

**Q1** (2.9 s)

> **Moving a lead:** drag its row from one column and drop it on another column.
> 
> **What happens when you drop it:**
> 1. The lead takes the status of the column you dropped it on.
> 2. If that stage's date is still empty, it's set to the current date and time:
>    - Moving to **Active** sets **Date Contacted**
>    - Moving to **Proposal Sent** sets **Date Drafted**
>    - Moving to **Closed** sets **Date Closed**
> 3. If that date already has a value, it doesn't change. This means moving a lead back and forth won't overwrite its history.
> 
> **Also good to know:**
> - Dropping a lead on the column it's already in does nothing.
> - All four lists refresh after each move, and the lead you moved stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (3.0 s)

> All your data is kept in one SQLite file called `w10crmdemo.sdb` in your **Documents** folder. The file is encrypted with AES-256. It holds five tables: leads, accounts, proposals and so on ([Data model](Data-Model.md)).
> 
> **To start over with the original sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the sample data: 8 leads, 8 accounts, one user (`CRMUser`) and three proposals ([Getting started](Getting-Started.md)).
> 
> **Warning:** Resetting is the only way to undo anything. The application can't roll back changes, and most deletes don't ask you to confirm. Deleting the file erases everything you've added or changed ([Data model](Data-Model.md)).

**Q3** (2.4 s)

> No. A saved proposal is stored exactly as it was generated, so you can't edit it. You can only change its status. On the **Sales** screen, select the proposal and press one of the two banner buttons:
> 
> - **Complete** sets it to `Accepted` and records today as the completion date.
> - **Cancel** sets it to `Canceled`.
> 
> Neither button asks for confirmation, and you can use either one again later. Accepting a proposal doesn't lock anything. [Sales](Sales.md)
> 
> **To redo a proposal:** a lead can't have a second proposal. Delete the existing one from the Sales list with the navigator, then create a new one. [FAQ](FAQ.md)

**Q4** (2.0 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet like Excel can open that directly.
> 
> The **Export** button here on the Accounts screen (and the one on Leads) saves in FireDAC's own format: binary, XML or JSON. That format is for reading back into this application. It isn't a spreadsheet file. The Accounts export also saves the whole table, even if you've filtered the list with Search.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (2.5 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or any part of it, in the **Search** box.
> 2. All four columns filter as you type. The search ignores case and matches anywhere in the value. It checks the lead's name, account name, office phone and e-mail. Typing `example.com` would find everyone with that domain.
> 3. To open the lead, double-click its row, or select it and press **View Lead**.
> 4. Clear the box to see the full board again.
> 
> The e-mail address only appears as a column under **Active**. In the other columns you can still find the lead with the search, but you won't see the address until you open the lead.
> 
> Source: [Leads](Leads.md)

**Q6** (1.7 s)

> I can't help with the weather. I'm the help assistant for this CRM application, so I can only explain how to use it. The application also needs no network, so it has no way of getting weather information.
> 
> If you have a question about the app, like what the Dashboard tiles count or how to create a lead, just ask.

**Q7** (1.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I opened the **Accounts** screen for you.

**Q8** (3.2 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I've created the lead **Mario Rossi** for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`. Its lead ID is 101.
> 
> New leads start in the **New** column of the Leads board. The lead's detail window opens right away so you can add the rest, such as the office phone ([Asking the assistant](Assistant.md)).

