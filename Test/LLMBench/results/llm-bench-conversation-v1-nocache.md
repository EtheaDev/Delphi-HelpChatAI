# HelpChatAI provider benchmark

Run on 2026-11-16 22:44. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); **the questions of a target in one conversation**, the history never cleared (`--suite=conversation`); language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude | 0.9 s | 8 | 0 | 1.7 s | 1.2 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 1.3 s | 8 | 0 | 1.8 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.2 s | 8 | 0 | 1.8 s | 0.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 1.9 s | 8 | 0 | 2.7 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

### Tokens

Prompt cache **off** (`--nocache`). The questions, warm-up excluded, of each target in a row, as one session would ask them.

| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |
|---|---:|---:|---:|---:|---:|---:|
| claude | 10 | 36757 | 0 | 0 | 2045 | 36757 |
| claude-haiku-5-5 | 10 | 36417 | 0 | 0 | 2192 | 36417 |
| claude-sonnet-5-5 | 10 | 38548 | 0 | 0 | 1396 | 38548 |
| claude-opus-5-5 | 10 | 39721 | 0 | 0 | 1888 | 39721 |

"Input": tokens at the full price. "Input as billed", claude only: input + 1.25 x cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), in tokens of the full price. OpenAI and Gemini cache by themselves, at prices of their own; a local server reports its prefix cache, which costs nothing.

### Tokens per question

Read from the cache / the whole input of the requests of each question, the questions of a target in one conversation.

| Target | Q1 | Q2 | Q3 | Q4 | Q5 | Q6 | Q7 | Q8 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| claude | 0 / 3166 | 0 / 3000 | 0 / 3471 | 0 / 3876 | 0 / 3973 | 0 / 3394 | 0 / 7467 | 0 / 8410 |
| claude-haiku-5-5 | 0 / 3166 | 0 / 2985 | 0 / 3451 | 0 / 3832 | 0 / 3906 | 0 / 3333 | 0 / 7336 | 0 / 8408 |
| claude-sonnet-5-5 | 0 / 3166 | 0 / 3016 | 0 / 3531 | 0 / 4069 | 0 / 4183 | 0 / 3668 | 0 / 8015 | 0 / 8900 |
| claude-opus-5-5 | 0 / 3166 | 0 / 3017 | 0 / 3571 | 0 / 4135 | 0 / 4281 | 0 / 3844 | 0 / 8409 | 0 / 9298 |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | claude | 1.5 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 2.1 s | 1.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 1.9 s | 0.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 2.7 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | claude | 1.1 s | 0.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 1.9 s | 1.2 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 1.8 s | 0.6 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 2.9 s | 0.7 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | claude | 2.1 s | 1.7 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 1.4 s | 1.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.5 s | 1.1 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 3.4 s | 1.1 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q4 | claude | 2.1 s | 1.6 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 2.0 s | 1.6 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.5 s | 0.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.8 s | 1.1 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q5 | claude | 1.5 s | 1.0 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.4 s | 0.9 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.6 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 3.2 s | 1.3 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | claude | 1.4 s | 1.1 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 1.5 s | 1.0 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 1.2 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.7 s | 0.5 s | Home.md | yes | 0/0 | - | yes |
| Q7 | claude | 1.6 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 1.3 s | 1.3 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.6 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.8 s | 1.8 s | - | yes | 0/0 | open_screen | yes |
| Q8 | claude | 1.9 s | 1.7 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 2.7 s | 2.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.1 s | 2.1 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.4 s | 3.3 s | Assistant.md | yes | 0/0 | create_lead | yes |

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

**warm-up** (0.9 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard tiles, managing users, or the main window layout. What would you like to know?

**Q1** (1.5 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates change as follows:
> 
> - If the date for that stage is still empty, it is stamped with the current time. That means Date Contacted when moving to Active, Date Drafted when moving to Proposal Sent, and Date Closed when moving to Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it's already in does nothing.
> 
> The four lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (1.1 s)

> Your data is stored in one encrypted SQLite file, `w10crmdemo.sdb`, in your Documents folder. It is encrypted with AES-256.
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data.
> 
> Be aware that there is no other way to undo changes, and most deletes ask for no confirmation.
> 
> Sources: [Data model](Data-Model.md), [Getting started](Getting-Started.md)

**Q3** (2.1 s)

> No. A saved proposal is stored as it was generated, so its document can't be edited. You can change its status to Accepted or Canceled, but the lead can't have a second proposal.
> 
> To redo it, delete the existing proposal from the Sales list with the navigator, then create a new one.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.1 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel opens directly.
> 
> Don't use the export on the **Accounts** or **Leads** pages for this. Those write FireDAC's own binary, XML or JSON format, meant to be read back by this application, not opened in a spreadsheet.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.5 s)

> On the Leads board, type part of the e-mail address in the **Search** box. The board filters all four columns as you type. The match ignores case and works anywhere inside the value, so typing `example.com` finds every lead with that domain. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (1.4 s)

> I can't check the weather. I'm the help assistant for CRM Demo, and the documentation doesn't cover weather. I can help with the application, for example finding leads, managing users, or reading the Dashboard counters.

**Q7** (1.6 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (1.9 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It has status New and is on the Leads board.

### claude-haiku-5-5

**warm-up** (1.3 s)

> Hello! I'm the help assistant for CRM Demo. I can explain how to use the application, including the screen you're on now, the Dashboard, which shows lead counts by status. What would you like to know?

**Q1** (2.1 s)

> To move a lead, **drag its row** from one column and drop it on another.
> 
> - The lead takes the status of the column you drop it on.
> - If that column's date is still empty, it is stamped with the current date and time: **Date Contacted** for Active, **Date Drafted** for Proposal Sent, and **Date Closed** for Closed.
> - A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it's already in does nothing.
> 
> The lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (1.9 s)

> Your data is stored in one encrypted SQLite file, `w10crmdemo.sdb`, in your Documents folder. It is encrypted with AES-256. There is no other way to undo changes, so back up the file first if you need to keep anything.
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data.
> 
> Sources: [Data model](Data-Model.md), [Getting started](Getting-Started.md)

**Q3** (1.4 s)

> No. A saved proposal is stored as it was generated and can't be edited. You can mark it Accepted or Canceled, but not change its content. To redo it, delete the existing proposal from the Sales list with the navigator, then create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (2.0 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel opens directly. The exports on the Accounts and Leads pages write FireDAC's own format, which only this application can read back, so they won't open usefully in Excel.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.4 s)

> On the Leads board, type the e-mail address, or part of it, into the **Search** box. The filter applies to all four columns as you type and matches anywhere inside the value, ignoring case. Typing `example.com` finds every lead with that domain. Clear the box to get the full board back.
> 
> Source: [Leads](Leads.md)

**Q6** (1.5 s)

> I can't help with that. I'm the help assistant for this CRM application, and I only have its documentation, which doesn't include weather information. I can help with using the app, such as managing leads, accounts, proposals, or the Dashboard.

**Q7** (1.3 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.7 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column.

### claude-sonnet-5-5

**warm-up** (1.2 s)

> Hello! I'm the in-app help assistant. I can explain how to use this application, for example the Dashboard, Leads, Accounts, Sales, Marketing, Calendar and Users screens. I can also create a lead for you if you give me the person's name and the account (company) it belongs to.
> 
> What would you like to know or do?

**Q1** (1.9 s)

> **To move a lead:** on the Leads board, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on, and the four lists refresh. The lead you dragged stays selected. Dropping it on the column it's already in does nothing.
> 
> **What happens to its dates:**
> - If the date for the new stage is still empty, it's stamped with the current date and time:
>   - **Date Contacted** when moving to Active
>   - **Date Drafted** when moving to Proposal Sent
>   - **Date Closed** when moving to Closed
> - If that date already has a value, it's left alone. Moving a lead back and forth doesn't rewrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (1.8 s)

> **Where it's stored:** everything is in a single SQLite file, `w10crmdemo.sdb`, in your Documents folder. It's encrypted with AES-256. The application creates it the first time you start it.
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. The file is rebuilt with the original sample data: 8 leads, 8 accounts, one user and three proposals.
> 
> Resetting is the only way to undo changes. The application has no rollback, and most deletes ask for no confirmation.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (2.5 s)

> **No, a saved proposal can't be edited.** The document is stored exactly as it was generated. You can only change its status:
> 
> - **Complete** sets it to Accepted and stamps DateCompleted with the current date and time.
> - **Cancel** sets it to Canceled and leaves the completion date alone.
> 
> Both are in the banner on the Sales screen, and also on the lead's detail window. Neither asks for confirmation. You can apply either again later, because nothing is locked once a proposal is accepted.
> 
> **To redo a proposal:**
> 1. Delete the existing one from the Sales list with the navigator. A lead can't have a second proposal, so this has to come first.
> 2. Create a new one.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (1.5 s)

> **Use the export on the Marketing page.** It writes a delimited text file with a header row, which Excel opens directly.
> 
> The exports on the Accounts and Leads pages (including the one on the screen you're on now) use FireDAC's own format. It's binary, XML or JSON depending on the extension you give it. Only this application is meant to read it back, and it isn't a spreadsheet file.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.6 s)

> **Use the Search box on the Leads board.** Type the e-mail address, or just part of it, and all four columns filter as you type.
> 
> - The match ignores case and works anywhere inside the value. Typing `example.com` finds everybody with that domain.
> - Search also covers the lead's name, account name and office phone.
> - Clear the box to get the full board back.
> 
> Once you've found the lead, double-click its row, or select it and press **View Lead**, to open its detail window.
> 
> Source: [Leads](Leads.md)

**Q6** (1.2 s)

> I can't help with that. Weather isn't covered by the documentation, and my role is limited to explaining how to use this application. The application also runs without a network, so it has no weather information.
> 
> I'm happy to answer questions about the Dashboard, Leads, Accounts, Sales, Marketing, Calendar or Users.

**Q7** (1.6 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.1 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. According to the documentation, it starts with status New and its detail window opens so you can fill in the rest.

### claude-opus-5-5

**warm-up** (1.9 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard**, which shows the active user's leads as tiles, one per status (New, Active, Proposal Sent, Closed, Inactive), plus a Total tile ([Dashboard](Dashboard.md)).
> 
> I can answer questions about how to use the application, or do some things for you, like creating a lead or opening a screen. What would you like to do?

**Q1** (2.7 s)

> On the Leads board, **drag the row** from its current column and **drop it on another column**.
> 
> When you drop it:
> - The lead gets the status of the new column.
> - If that stage's date is still empty, it's set to the current date and time:
>   - moving to **Active** sets **Date Contacted**
>   - moving to **Proposal Sent** sets **Date Drafted**
>   - moving to **Closed** sets **Date Closed**
> - If that date already has a value, it doesn't change. This means moving a lead back and forth won't rewrite its history.
> 
> Dropping a lead on the column it's already in does nothing. After each move, all four columns refresh and the lead you moved stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.9 s)

> Your data is kept in a single SQLite file named `w10crmdemo.sdb` in your **Documents** folder. The file is encrypted with AES-256. The application creates it the first time you run it and opens it every time after that.
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (`CRMUser`) and three proposals.
> 
> **Before you delete it:** resetting is the only way to undo anything. There's no rollback, and most deletes don't ask you to confirm. Deleting the file permanently erases everything you've entered.
> 
> Sources: [Data model](Data-Model.md), [Getting started](Getting-Started.md)

**Q3** (3.4 s)

> **No.** A proposal is saved exactly as it was generated, so you can't edit it later. A lead also can't have a second proposal.
> 
> **What you can do with a saved proposal:**
> - Change its status. In the Sales list, select the proposal and use the banner buttons:
>   - **Complete** sets the status to **Accepted** and records the current date and time as **DateCompleted**.
>   - **Cancel** sets the status to **Canceled** and doesn't change the completion date.
> - Change the status again later if you need to. Accepting a proposal doesn't lock it. Neither button asks you to confirm.
> 
> **To redo a proposal:**
> 1. In the **Sales** list, use the navigator to delete the existing proposal.
> 2. Create a new proposal for that lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.8 s)

> Use the **Marketing** page export. It saves a delimited text file with a header row, and Excel can open that directly.
> 
> The exports on the **Accounts** page (where you are now) and the **Leads** page won't work for this. They save in FireDAC's own format (binary, XML or JSON, depending on the file extension you choose). That format is meant to be read back by this application, not by a spreadsheet. Also, the Accounts export always saves the whole table, even if your Search box is filtering the list.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (3.2 s)

> Type the e-mail address, or any part of it, into the **Search** box on the Leads board. The box filters all four columns at once as you type.
> 
> - It ignores upper and lower case and finds the text anywhere in the value. For example, typing just the domain, like `example.com`, finds every lead with that domain.
> - It looks at the lead's name, account name and office phone as well as the e-mail address.
> - When you find the lead, double-click its row or select it and press **View Lead** to open it.
> - Clear the box to see the whole board again.
> 
> **If the lead doesn't show up:** it may be **Inactive**. Inactive leads have no column on the board, so the search can't show them. They're only counted on the Dashboard.
> 
> Source: [Leads](Leads.md)

**Q6** (1.7 s)

> I can't help with the weather. I'm the help assistant for this CRM app, so I can only answer questions about using it. The app doesn't have any weather features, and it doesn't need a network connection: everything is stored in one encrypted file on your own computer.
> 
> If you have questions about the Dashboard or any other part of the app, just ask.
> 
> Source: [CRM Demo](Home.md)

**Q7** (1.8 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I opened the Accounts screen for you.

**Q8** (3.4 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`. It starts in the **New** column, and its detail window opens so you can add the rest, such as the office phone.
> 
> Source: [Asking the assistant](Assistant.md)

