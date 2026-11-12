# HelpChatAI provider benchmark

Run on 2026-11-12 17:41. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude-haiku-5-5 | 0.8 s | 8 | 0 | 2.0 s | 1.5 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.2 s | 8 | 0 | 2.3 s | 1.4 s | 75% (6/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 2.0 s | 8 | 0 | 2.6 s | 1.3 s | 75% (6/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | claude-haiku-5-5 | 2.3 s | 1.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 2.2 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 3.1 s | 0.9 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 2.1 s | 1.4 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 2.0 s | 0.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 2.5 s | 0.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | claude-haiku-5-5 | 2.1 s | 1.7 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.2 s | 1.3 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 2.6 s | 1.2 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q4 | claude-haiku-5-5 | 2.3 s | 1.9 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.7 s | 0.6 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.2 s | 0.8 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | claude-haiku-5-5 | 1.3 s | 0.9 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.8 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 2.8 s | 0.7 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | claude-haiku-5-5 | 1.5 s | 1.1 s | Dashboard.md Users.md | **no** | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 1.4 s | 0.7 s | Dashboard.md Users.md | **no** | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 2.0 s | 0.7 s | Dashboard.md | **no** | 0/0 | - | yes |
| Q7 | claude-haiku-5-5 | 1.7 s | 1.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 4.5 s | 4.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.8 s | 1.8 s | - | yes | 0/0 | open_screen | yes |
| Q8 | claude-haiku-5-5 | 2.6 s | 2.4 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.5 s | 2.5 s | Assistant.md | **no** | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.9 s | 3.8 s | Assistant.md | **no** | 0/0 | create_lead | yes |

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

**warm-up** (0.8 s)

> Hello! I'm the in-app help assistant for the CRM Demo. I can explain how to use the application, for example how the Dashboard counters work, how users filter what you see, or how the main window is laid out. What would you like to know?
> 
> Source: [Dashboard](Dashboard.md), [CRM Demo](Home.md), [Users](Users.md)

**Q1** (2.3 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates change as follows:
> 
> - If the date for that stage is empty, it is stamped with the current date and time. Moving a lead to **Active** fills Date Contacted, moving it to **Proposal Sent** fills Date Drafted, and moving it to **Closed** fills Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> The four lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.1 s)

> Your data is stored in one SQLite file, **w10crmdemo.sdb**, in your Documents folder. The file is encrypted with AES-256. Five tables are stored in it. Two more exist only in memory while a proposal is being drafted. ([Data model](Data-Model.md))
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data. ([Getting started](Getting-Started.md))
> 
> Deleting the file erases all your current data, and the application has no undo. ([Data model](Data-Model.md))

**Q3** (2.1 s)

> No. Once saved, a proposal is stored as it was generated, so it can't be edited. You can change its status to Accepted or Canceled, but the lead can't have a second proposal. To redo it, delete the existing proposal from the Sales list using the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (2.3 s)

> Use the **Export** on the **Marketing** page. It writes a delimited text file with a header row, which a spreadsheet can open directly ([FAQ](FAQ.md)).
> 
> The **Export** on the Accounts page does not produce an Excel-friendly file. It writes FireDAC's own binary, XML or JSON format, meant to be read back by this application ([Accounts](Accounts.md)).

**Q5** (1.3 s)

> On the Leads board, type the e-mail address, or any part of it, into the **Search** box. The board filters all four columns as you type, and it matches e-mail addresses. Typing `example.com` finds everyone with that domain. Clear the box to get the full board back.
> 
> Source: [Leads](Leads.md)

**Q6** (1.5 s)

> I can't help with that. I'm the help assistant for this CRM application, and its documentation doesn't cover weather information.
> 
> I can help with questions about the app, such as what the Dashboard tiles count or how users filter records.
> 
> Source: [Dashboard](Dashboard.md), [Users](Users.md)

**Q7** (1.7 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.6 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It has status New.

### claude-sonnet-5-5

**warm-up** (1.2 s)

> Hello! I'm the in-app help assistant for this application. I can explain how to use things like the Dashboard, Accounts, Leads, Sales, Marketing, Calendar and Users screens. What would you like to know?
> 
> Source: [Dashboard](Dashboard.md), [Users](Users.md)

**Q1** (2.2 s)

> To move a lead, **drag its row** from one column and **drop it on another** column of the Leads board.
> 
> Two things happen when you drop it:
> 
> 1. The lead takes the **status** of the column you dropped it on.
> 2. If the date for that stage is still empty, it is **stamped with the current date and time**:
>    - moving to **Active** sets *Date Contacted*
>    - moving to **Proposal Sent** sets *Date Drafted*
>    - moving to **Closed** sets *Date Closed*
> 
> A date that already has a value is **left alone**. Moving a lead back and forth therefore does not rewrite its history.
> 
> Other details:
> - Dropping a lead on the column it is already in does nothing.
> - The four lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.0 s)

> **Where it's stored:** Everything is in a single SQLite file, `w10crmdemo.sdb`, in your Documents folder. It's encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **Starting over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again.
> 
> The file is rebuilt with the original sample data: 8 leads, 8 accounts, one user (CRMUser) and three proposals. ([Getting started](Getting-Started.md))
> 
> Deleting the file is the only way to undo anything. The application has no rollback, so you lose every change you've made since the first run. ([Data model](Data-Model.md))

**Q3** (2.2 s)

> No. A saved proposal is stored exactly as it was generated, so you can't edit it. You can mark it **Accepted** or **Canceled**, but the lead can't be given a second proposal.
> 
> To redo a proposal:
> 1. Delete the existing one from the Sales list with the navigator.
> 2. Create a new one from the lead.
> 
> Source: [FAQ](FAQ.md)

**Q4** (1.7 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet such as Excel can open that file directly.
> 
> The exports on the Accounts and Leads pages don't work for this. They write FireDAC's own format (binary, XML or JSON, depending on the extension you choose), which only this application is meant to read back. That format is not a spreadsheet file.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.8 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or just part of it, into the Search box.
> 2. All four columns filter as you type. The match ignores case and works anywhere inside the value. Searching on `example.com` finds everybody with that domain, for instance.
> 3. When you find the lead, double-click its row, or select it and press **View Lead**, to open the lead detail window.
> 4. Clear the box to get the full board back.
> 
> Search checks the lead's name, account name, office phone and e-mail.
> 
> Source: [Leads](Leads.md)

**Q6** (1.4 s)

> I can't help with the weather in Milan. I only explain how to use this application, and the documentation doesn't cover that.
> 
> I can help with the Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users screens. Just ask.
> 
> Source: [Dashboard](Dashboard.md), [Users](Users.md)

**Q7** (4.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I've opened the Accounts screen.

**Q8** (2.5 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. Its id is 101. According to the manual, a new lead starts with status New and its detail window opens straight away, so you can fill in the rest. See [Asking the assistant](Assistant.md).

### claude-opus-5-5

**warm-up** (2.0 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard**, which shows a count of the active user's leads, with one tile for each status (New, Active, Proposal Sent, Closed, Inactive, Total) ([Dashboard](Dashboard.md)).
> 
> I can explain how any part of the application works, or do things for you, like opening a screen or creating a lead. What would you like to do?

**Q1** (3.1 s)

> To move a lead, **drag its row from one column and drop it on another**. Then:
> 
> 1. **The status changes:** the lead takes the status of the column you dropped it on.
> 2. **A date is filled in, but only if it's empty:** the date for that stage gets the current date and time:
>    - moving to **Active** fills in `Date Contacted`
>    - moving to **Proposal Sent** fills in `Date Drafted`
>    - moving to **Closed** fills in `Date Closed`
> 3. **Dates that are already set don't change.** Moving a lead back and forth won't rewrite its history.
> 4. **Dropping a lead on the column it's already in does nothing.**
> 
> After each move, all four columns refresh and the lead you moved stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.5 s)

> Your data is kept in a single SQLite file called `w10crmdemo.sdb` in your **Documents** folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (CRMUser) and three proposals. ([Getting started](Getting-Started.md))
> 
> Deleting the file is the only way to undo anything. The application has no rollback, and most deletes don't ask you to confirm. ([Data model](Data-Model.md))

**Q3** (2.6 s)

> No, you can't edit a proposal once it's saved. The document is stored exactly as it was generated. You can only mark it **Accepted** or **Canceled**, and a lead can't have a second proposal.
> 
> To redo a proposal:
> 1. Delete the existing proposal from the **Sales** list using the navigator.
> 2. Open the lead and press **Create Proposal** to draft a new one.
> 
> Marking a proposal doesn't lock it. **Complete** (Accepted) and **Cancel** (Canceled) can be applied again later, so you can switch between the two whenever you need to.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.2 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet like Excel opens it directly.
> 
> The **Export** on the Accounts screen you're on now won't give you that. It saves the whole table in FireDAC's own format (binary, XML or JSON, depending on the file extension), and that format is meant to be read back by this application. The Leads export works the same way. ([Accounts](Accounts.md), [FAQ](FAQ.md))

**Q5** (2.8 s)

> You can find it with the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or any part of it, in the **Search** box.
> 2. All four columns filter as you type. Upper and lower case don't matter, and the text can match anywhere inside the e-mail, so part of the address is enough. For example, `example.com` would find everyone with that domain.
> 3. To open the lead, double-click its row, or select it and press **View Lead**.
> 4. Clear the Search box to see the full board again.
> 
> Search also checks the lead's name, account name and office phone, so you may see a few extra results.
> 
> Leads with the **Inactive** status won't appear in the results because the board has no column for them. They're only counted on the Dashboard.
> 
> Source: [Leads](Leads.md)

**Q6** (2.0 s)

> I can't help with the weather. I'm the help assistant for this CRM application, and I can only answer questions about using it. This app also doesn't connect to any network, so it has no access to weather or other outside information.
> 
> I can help with things in the app, like what the Dashboard tiles mean or how to create a lead.
> 
> Source: [Dashboard](Dashboard.md)

**Q7** (1.8 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is open now.

**Q8** (3.9 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`. Its lead id is 101.
> 
> New leads get the status **New**, so it goes in the first column of the Leads board. Its detail window opens straight away, so you can add anything else you need there, such as an office phone. ([Asking the assistant](Assistant.md))

