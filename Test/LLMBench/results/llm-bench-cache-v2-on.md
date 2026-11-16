# HelpChatAI provider benchmark

Run on 2026-11-16 20:17. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude | 1.4 s | 8 | 0 | 1.8 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 1.3 s | 8 | 0 | 1.7 s | 1.2 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.1 s | 8 | 0 | 2.3 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 2.0 s | 8 | 0 | 2.5 s | 1.2 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

### Tokens

Prompt cache on (`Claude.PromptCaching`, the default). The questions, warm-up excluded, of each target in a row, as one session would ask them.

| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |
|---|---:|---:|---:|---:|---:|---:|
| claude | 10 | 20 | 15366 | 14734 | 2372 | 20701 |
| claude-haiku-5-5 | 10 | 20 | 399 | 29625 | 2028 | 3481 |
| claude-sonnet-5-5 | 10 | 20 | 15096 | 14734 | 1387 | 20363 |
| claude-opus-5-5 | 10 | 20 | 15096 | 14734 | 1575 | 20363 |

"Input": tokens at the full price. "Input as billed": input + 1.25 x cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), in tokens of the full price.

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | claude | 1.7 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 1.6 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 2.5 s | 1.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 2.6 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | claude | 2.6 s | 1.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 1.6 s | 0.9 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 1.8 s | 0.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 2.5 s | 0.5 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q3 | claude | 2.5 s | 2.0 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 2.3 s | 1.9 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.6 s | 1.3 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 3.0 s | 0.7 s | Sales.md FAQ.md | yes | 2/2 | - | yes |
| Q4 | claude | 1.9 s | 1.4 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 2.0 s | 1.5 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.9 s | 1.0 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.4 s | 1.2 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | claude | 1.2 s | 0.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.2 s | 0.9 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.7 s | 0.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 1.8 s | 0.4 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | claude | 1.2 s | 0.8 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 1.1 s | 0.9 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 2.0 s | 0.7 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 2.2 s | 1.2 s | - | yes | 0/0 | - | yes |
| Q7 | claude | 1.4 s | 1.4 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 1.3 s | 1.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.6 s | 1.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 2.2 s | 2.2 s | - | yes | 0/0 | open_screen | yes |
| Q8 | claude | 2.3 s | 2.1 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 2.1 s | 1.9 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 4.3 s | 4.2 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.0 s | 3.0 s | - | yes | 0/0 | create_lead | yes |

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

**warm-up** (1.4 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard counters, users, and the main window. What would you like to know?

**Q1** (1.7 s)

> To move a lead to another column, drag its row and drop it on the target column. Moving a lead also changes its status, and it can stamp the date for that stage:
> 
> 1. Drag the lead's row from its current column.
> 2. Drop it on the column you want. The lead takes that column's status.
> 3. If that stage's date is still empty, it is set to the current date and time. Moving to Active sets Date Contacted, moving to Proposal Sent sets Date Drafted, and moving to Closed sets Date Closed.
> 
> A date that already has a value is never overwritten, so moving a lead back and forth keeps its original history. Dropping a lead on the column it's already in does nothing. The lists refresh after each move, and the lead stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.6 s)

> **Where your data is stored:** Everything is in one SQLite file, `w10crmdemo.sdb`, in your Documents folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **How to start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data. ([Getting started](Getting-Started.md), [Data model](Data-Model.md))
> 
> The application has no undo for this. Deleting the file removes all current records, and there is no confirmation on most deletes.

**Q3** (2.5 s)

> No, you can't edit a proposal after you save it. The document is stored as it was generated ([FAQ](FAQ.md)). You can change its status to Accepted or Canceled, but not its content ([Sales](Sales.md)).
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one ([FAQ](FAQ.md)).

**Q4** (1.9 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel opens directly. The exports on the Accounts and Leads pages use FireDAC's own format, which only this application can read back.
> 
> To get there, open **Marketing** from the side menu and use its export.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.2 s)

> On the Leads board, type the e-mail address (or part of it) into the **Search** box. The four columns filter as you type. The search matches against the lead's name, account name, office phone and e-mail, ignoring case, so a partial address such as `example.com` also works. Clear the box to show the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (1.2 s)

> I can't help with that. I only answer questions about how to use the CRM Demo application, and its documentation doesn't cover weather information.
> 
> I can help with things like the Dashboard tiles, Users, or managing leads.

**Q7** (1.4 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.3 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It starts with status New.

### claude-haiku-5-5

**warm-up** (1.3 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard counters, users, and the main window. I can also create a lead for you. What would you like to know or do?

**Q1** (1.6 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates follow these rules:
> 
> - If the date for the new stage is still empty, it is stamped with the current date and time. Moving to Active sets Date Contacted, moving to Proposal Sent sets Date Drafted, and moving to Closed sets Date Closed.
> - If that date already has a value, it is left unchanged. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it's already in does nothing.
> 
> The lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (1.6 s)

> Your data is stored in one encrypted SQLite file, `w10crmdemo.sdb`, in your Documents folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data.
> 
> Deleting the file is the only way to undo changes. The application has no rollback and, on most deletes, no confirmation. ([Data model](Data-Model.md), [Getting started](Getting-Started.md))

**Q3** (2.3 s)

> No. A saved proposal is stored as it was generated, so you can't edit it. You can mark it Accepted or Canceled, but the lead can't have a second proposal.
> 
> To redo a proposal, delete the existing one from the Sales list using the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (2.0 s)

> Use the **Export** on the **Marketing** page. It writes a delimited text file with a header row, which Excel can open directly ([FAQ](FAQ.md)).
> 
> The **Export** on the Accounts and Leads pages writes FireDAC's own binary, XML or JSON format, which this application can read back but Excel cannot open ([Accounts](Accounts.md)).

**Q5** (1.2 s)

> On the Leads board, type the e-mail address (or part of it) in the **Search** box. The four columns filter as you type, and the search matches the lead's e-mail, so you don't need the full name. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (1.1 s)

> I can't help with that here. This application is a CRM demo for managing leads, accounts, proposals and documents, and its documentation doesn't cover weather information.

**Q7** (1.3 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.1 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column.

### claude-sonnet-5-5

**warm-up** (1.1 s)

> Hello! I can help you use this application. You're on the Dashboard, which shows lead counts for the active user, one tile per status (New, Active, Proposal Sent, Closed, Inactive, Total). What would you like to know or do?
> 
> Sources: [Dashboard](Dashboard.md)

**Q1** (2.5 s)

> To move a lead, **drag its row from one column and drop it on another** on the Leads board. Two things happen:
> 
> 1. The lead takes the status of the column you dropped it on.
> 2. If the date for that stage is still empty, it is stamped with the current date and time:
>    - **Active**: Date Contacted
>    - **Proposal Sent**: Date Drafted
>    - **Closed**: Date Closed
> 
> If a date already has a value, it is left alone. Moving a lead back and forth therefore doesn't rewrite its history.
> 
> Dropping a lead on the column it's already in does nothing. The four lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (1.8 s)

> **Where it's stored:** Everything lives in a single SQLite file, `w10crmdemo.sdb`, in your Documents folder. It's encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> **Starting over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data (8 leads, 8 accounts, one user, three proposals) ([Getting started](Getting-Started.md)).
> 
> Note that this erases everything you've added or changed. There's no other way to undo changes ([Data model](Data-Model.md)).

**Q3** (2.6 s)

> No, a saved proposal can't be edited. The document is stored exactly as it was generated. You can only mark it **Accepted** (Complete) or **Canceled** (Cancel). A lead also can't be given a second proposal.
> 
> To redo a proposal:
> 1. Open the **Sales** list.
> 2. Delete the existing proposal with the navigator.
> 3. Create a new one.
> 
> Complete and Cancel can be applied again later, because nothing is locked once a proposal is accepted. Neither button asks for confirmation.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (1.9 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet can open that file directly.
> 
> The exports on the Accounts and Leads pages use FireDAC's own format. That format is meant to be read back by this application, and it isn't a spreadsheet file. This applies to the Export on the Accounts page, where you are now. ([Accounts](Accounts.md), [FAQ](FAQ.md))

**Q5** (1.7 s)

> On the **Leads** board, use the Search box. It filters all four columns at once as you type, and it matches the lead's name, account name, office phone or e-mail. The match ignores case and works anywhere inside the value.
> 
> 1. Type the e-mail address (or just part of it) into the Search box.
> 2. The matching lead shows up in whichever column it belongs to.
> 3. Double-click the row, or select it and press **View Lead**, to open its details.
> 4. Clear the box to get the full board back.
> 
> Typing only the domain, such as `example.com`, shows every lead with that domain.
> 
> Source: [Leads](Leads.md)

**Q6** (2.0 s)

> I can't help with that. The documentation I have covers only how to use this CRM application, and it says nothing about weather in Milan or anywhere else. For a forecast, you'll need a weather service.
> 
> I can help with the Dashboard, Accounts, Leads, Sales, Marketing, Calendar and Users screens. I can also create a lead for you if you give me a name and an existing account.

**Q7** (1.6 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (4.3 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for Apollo Orange, LLC. with the e-mail mario.rossi@example.com. Its status is New, as with any new lead. See [Asking the assistant](Assistant.md) for more on what I can do for you.

### claude-opus-5-5

**warm-up** (2.0 s)

> Hello! I'm Assistant, the in-app help for this CRM. You're on the **Dashboard**, which shows a count of the active user's leads for each status. I can explain how any part of the app works, or do some tasks for you, like creating a lead. What would you like to do?

**Q1** (2.6 s)

> To move a lead, **drag its row from one column and drop it on another**. The board has four columns: **New**, **Active**, **Proposal Sent** and **Closed**.
> 
> **What happens when you drop it:**
> - The lead takes the status of the column you dropped it on.
> - If that stage's date is still empty, it's filled in with the current date and time:
>   - **Date Contacted** when it moves to **Active**
>   - **Date Drafted** when it moves to **Proposal Sent**
>   - **Date Closed** when it moves to **Closed**
> - If that date already has a value, it stays the same. Moving a lead back and forth won't change its history.
> - Dropping a lead on the column it's already in does nothing.
> 
> After every move, all four lists refresh and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.5 s)

> Your data is kept in a single SQLite file called `w10crmdemo.sdb` in your **Documents** folder. The file is encrypted with AES-256. The application creates it the first time it starts and opens the same file every time after that.
> 
> To get the original sample data back:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It will create a new file with the sample data: 8 leads, 8 accounts, one user (CRMUser) and three proposals.
> 
> This is the only way to undo changes. The application has no rollback, and most deletes don't ask for confirmation. Deleting the file also deletes everything you've added or changed.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (3.0 s)

> **No.** A saved proposal is stored exactly as it was generated, so you can't edit its content. A lead also can't have a second proposal.
> 
> **What you can change** is the status of the proposal you select in the Sales list:
> - **Complete** sets the status to **Accepted** and records the current date and time as the completion date.
> - **Cancel** sets the status to **Canceled**.
> 
> Neither button asks you to confirm, and you can press either one again later. Accepting a proposal doesn't lock it. ([Sales](Sales.md))
> 
> **To redo a proposal:**
> 1. Delete the old one from the **Sales** list using the navigator.
> 2. Create a new proposal for the lead. ([FAQ](FAQ.md))

**Q4** (2.4 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and Excel can open it directly.
> 
> The **Export** on the Accounts screen, where you are now, won't work for this. It saves the whole table in FireDAC's own format (binary, XML or JSON), which only this application can read back. It isn't a spreadsheet file. The export on the Leads page uses the same format.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.8 s)

> Type the e-mail address, or any part of it, into the **Search** box on the Leads board. The search starts as soon as you type and filters all four columns at once. Upper and lower case don't matter, and the text can match anywhere in the value. Besides e-mail it also checks the lead's name, account name and office phone.
> 
> For example, typing `example.com` would show every lead with an e-mail at that domain. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (2.2 s)

> I can't tell you the weather. I only help with using this application, and its documentation doesn't mention weather information. For today's weather in Milan, try a weather website or app.
> 
> If you have a question about the CRM, like the Dashboard tiles, leads or accounts, I can help with that.

**Q7** (2.2 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The **Accounts** screen is open now.

**Q8** (3.0 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`. It's in the **New** column of the Leads board.

