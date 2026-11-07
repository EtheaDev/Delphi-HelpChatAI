# HelpChatAI provider benchmark

Run on 2026-11-07 11:16. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 13.1 s | 8 | 0 | 4.0 s | 3.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 21.6 s | 8 | 0 | 2.8 s | 2.0 s | 75% (6/8) | 100% (11/11) | 88% (7/8) |
| qwen3-coder:30b | 34.0 s | 8 | 0 | 5.0 s | 2.5 s | 50% (4/8) | 100% (11/11) | 75% (6/8) |
| claude | 2.4 s | 8 | 0 | 1.8 s | 0.7 s | 75% (6/8) | 100% (11/11) | 100% (8/8) |
| gemini | 2.3 s | 8 | 0 | 3.8 s | 3.4 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 5.7 s | 4.1 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 2.8 s | 1.5 s | - | **no** | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 6.4 s | 3.0 s | - | **no** | 3/3 | - | yes |
| Q1 | claude | 2.6 s | 0.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini | 4.2 s | 3.2 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 4.2 s | 3.2 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 4.1 s | 2.6 s | Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 4.8 s | 2.6 s | - | **no** | 3/3 | - | yes |
| Q2 | claude | 1.7 s | 0.4 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini | 4.0 s | 3.4 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 3.3 s | 2.7 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 3.2 s | 2.2 s | - | **no** | 2/2 | - | yes |
| Q3 | qwen3-coder:30b | 4.3 s | 2.7 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude | 1.6 s | 0.5 s | Draft-Proposal.md | yes | 2/2 | - | yes |
| Q3 | gemini | 2.6 s | 2.4 s | FAQ.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 4.5 s | 3.8 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 2.9 s | 2.3 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 8.0 s | 3.2 s | - | **no** | 1/1 | open_screen | **no** |
| Q4 | claude | 1.4 s | 0.4 s | - | **no** | 1/1 | - | yes |
| Q4 | gemini | 3.7 s | 3.0 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 3.9 s | 3.2 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 2.6 s | 1.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 4.9 s | 2.7 s | - | **no** | 2/2 | - | yes |
| Q5 | claude | 2.3 s | 0.4 s | - | **no** | 2/2 | - | yes |
| Q5 | gemini | 3.0 s | 2.4 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 3.2 s | 3.1 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.4 s | 1.2 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 1.2 s | 0.2 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 1.3 s | 0.4 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 2.9 s | 2.3 s | - | yes | 0/0 | - | yes |
| Q7 | gemma4:12b | 3.0 s | 2.9 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 1.6 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 4.0 s | 3.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 1.4 s | 1.3 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 4.9 s | 4.8 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 4.5 s | 4.3 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 4.2 s | 3.3 s | - | yes | 0/0 | - | **no** |
| Q8 | qwen3-coder:30b | 6.5 s | 2.7 s | - | yes | 0/0 | open_screen, create_lead | **no** |
| Q8 | claude | 2.0 s | 1.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 5.4 s | 5.2 s | Assistant.md | **no** | 0/0 | create_lead | yes |

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

### gemma4:12b

**warm-up** (13.1 s)

> Hello! How can I help you with the application today? 
> 
> You are currently on the **Dashboard**, which provides a summary of your leads. It displays tiles for different statuses like New Leads, Active Leads, Proposal Sent, Closed Leads, and Inactive Leads. 
> 
> Feel free to ask if you have any questions about how to use the app!

**Q1** (5.7 s)

> To move a lead to a different column, you can **drag and drop** a row from one column to another. [Leads](Leads.md)
> 
> When you do this, the following happens regarding dates:
> 1. The lead takes on the status of the new column.
> 2. If the date for that stage is currently empty, it will be stamped with the current time. This applies to:
>     * **Date Contacted** moving to **Active**
>     * **Date Drafted** moving to **Proposal Sent**
>     * **Date Closed** moving to **Closed**
> 3. If a date already has a value, it is left alone so that moving a lead back and forth does not rewrite its history. [Leads](Leads.md)

**Q2** (4.2 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb`, which is located in your Documents folder and encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data, you must:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again; the file will be rebuilt with the original sample data [Getting started](Getting-Started.md), [Data model](Data-Model.md).

**Q3** (3.3 s)

> No, you cannot change a proposal after it has been saved because the document is stored exactly as it was generated. To redo a proposal, you must delete the existing one from the Sales list using the navigator and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (4.5 s)

> To get a file you can open in Excel, use the export on the **Marketing** page, which writes a delimited text file [FAQ](FAQ.md) [Accounts](Accounts.md). The exports on the Accounts and Leads pages are in a different format meant only to be read back by the application.

**Q5** (3.9 s)

> To find a lead using an e-mail address, you can use the **Search** box. Typing the e-mail address into this box will filter all four columns at once, matching any value inside the e-mail field regardless of case.
> 
> Source: [Leads](Leads.md)

**Q6** (3.2 s)

> I'm sorry, but the documentation does not provide information about the weather.

**Q7** (3.0 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (4.5 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> The lead for Mario Rossi at Apollo Orange, LLC. has been created.

### gpt-oss:20b

**warm-up** (21.6 s)

> Hello! 👋  
> How can I help you explore or use the CRM today?

**Q1** (2.8 s)

> To move a lead on the board:
> 
> 1. **Drag the row** from its current column.  
> 2. **Drop it** onto the target column.  
> 
> After the drop the lead’s status changes to that of the destination column. The first date that belongs to that stage is set to the current time if it is still empty. If that date already has a value, it is left unchanged. Moving a lead back and forth does not overwrite past dates, and dropping it in the same column has no effect.  
> 
> > Source: **Leads** documentation.

**Q2** (4.1 s)

> Your data lives in a single encrypted SQLite file named **`w10crmdemo.sdb`** that is created in your **Documents** folder the first time you launch the application.  
> To reset the database back to the original sample data:
> 
> 1. **Close** the application.  
> 2. **Delete** the `w10crmdemo.sdb` file from your Documents folder.  
> 3. **Start** the application again – it will recreate the file, copy the sample data, and open the Dashboard.
> 
> This is the only way to revert to the original sample set.  
> 
> Source: [Getting started](Getting-Started.md)

**Q3** (3.2 s)

> No. Once a proposal is saved it is stored exactly as generated; you can only mark it **Accepted** or **Canceled**. To redo it you must delete the existing proposal from the Sales list and create a new one.  
> 
> > *“Can I change a proposal after saving it? No… To redo a proposal, delete the existing one from the Sales list with the navigator and create a new one.”*  
> > *Source: FAQ*

**Q4** (2.9 s)

> The export that produces a file you can open directly in Excel is the one on the **Marketing** screen. It writes a delimited text file with a header row, which Excel can import without any conversion.  
> 
> > *Source: [FAQ](FAQ.md)*

**Q5** (2.6 s)

> On the Leads board, use the **Search** box at the top:
> 
> 1. Click the Search field.
> 2. Type the lead’s e‑mail address (or part of it).
> 3. The board will automatically filter all four columns, showing any lead whose e‑mail matches the text you typed.  
>    *The search matches ignoring case and anywhere inside the value against the lead’s name, account name, office phone or e‑mail.*  
>    (Source: [Leads](Leads.md))

**Q6** (1.4 s)

> I’m sorry, but that question isn’t covered by this application’s documentation.

**Q7** (1.6 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now displayed.

**Q8** (4.2 s)

> I need a couple of things to create the lead:
> 
> 1. **Does the account “Apollo Orange, LLC.” already exist in the Accounts list?**  
> 2. **What office phone number should be recorded for Mario Rossi?**  
> 
> Once I have those, I’ll use the `create_lead` tool to add the lead.

### qwen3-coder:30b

**warm-up** (34.0 s)

- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> Hello! I'm here to help you use the CRM application. 
> 
> I can see you're currently on the Dashboard screen, which shows counts of leads for the active user, organized by status (New Leads, Active Leads, Proposal Sent, Closed Leads, Inactive Leads). 
> 
> Is there anything specific you'd like to do with the application? I can help you navigate between different screens or create new records.
> 
> If you want to see the actual leads behind any of these counts, I can open the Leads screen for you. Or if you need to create a new lead, I can help with that too.
> 
> I've opened the Leads screen for you. This is where you can see all the leads belonging to the currently active user, filtered by the user selected in the dropdown at the top right of the application window.
> 
> From here you can:
> - View details of each lead
> - Change the status of leads
> - Create new leads
> - See which accounts they belong to
> 
> Is there anything specific you'd like to do with the leads now? For example, would you like to create a new lead or change the status of an existing one?
> 
> If you want to go back to the Dashboard, I can open that for you as well.

**Q1** (6.4 s)

> To move a lead from one column to another on the Leads board, **drag and drop** the lead row from one column to another.
> 
> When you do this:
> - The lead takes the **status** of the column you dropped it on.
> - If the date for that stage is still empty, it gets stamped with the current date:
>   - **Date Contacted** when moving to *Active*,
>   - **Date Drafted** when moving to *Proposal Sent*,
>   - **Date Closed** when moving to *Closed*.
> - A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it already is in does nothing.
> 
> The four lists refresh after every move, and the lead you dragged stays selected.

**Q2** (4.8 s)

> Your data is stored in a single SQLite file named **w10crmdemo.sdb**, located in your **Documents** folder. This file is encrypted with AES-256.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete the file **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again.
> 
> The application will recreate the file with the original sample data, including 8 leads, 8 accounts, one user, and three proposals.

**Q3** (4.3 s)

> According to the documentation, **no**, you cannot change a proposal after saving it.
> 
> The document is stored as it was generated. You can mark it **Accepted** or **Canceled**, but not edit it, and the lead cannot be given a second one. To redo a proposal, you need to delete the existing one from the Sales list and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (8.0 s)

- action `open_screen` {"name":"Marketing"} -> Opened the Marketing screen.

> According to the documentation, the export on the **Marketing** page writes a delimited text file with a header row, which a spreadsheet application can open directly. In contrast, the exports on the **Accounts** and **Leads** pages write FireDAC's own format, meant to be read back by this application.
> 
> To proceed, you can open the Marketing screen and use its export feature.
> 
> The export on the **Marketing** page saves the data in a delimited text file format, which can be opened directly in Excel. This is different from the exports on the **Accounts** and **Leads** pages, which use FireDAC's own format intended for import back into this application.
> 
> To export your data:
> 
> 1. On the **Marketing** screen, look for the export button or option.
> 2. Choose a location to save the file.
> 3. The file will be saved with a text format that Excel can open directly.
> 
> If you need further assistance, let me know!

**Q5** (4.9 s)

> To find a lead using its email address on the **Leads** screen:
> 
> 1. Use the **Search** box at the top of the board.
> 2. Type the email address into the search box.
> 3. The board will filter all four columns in real-time, showing only leads matching that email address.
> 
> The search matches against the lead's name, account name, office phone, or email — so typing part of an email will also work.
> 
> If you want to clear the filter and see all leads again, simply clear the search box.

**Q6** (1.2 s)

> I cannot provide weather information. The application I assist with is a customer-relationship manager and does not have access to weather data.
> 
> To check the weather in Milan, you can use a dedicated weather service or search engine.<tool_call>

**Q7** (4.0 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open. You can view and manage the company accounts associated with your leads here. Let me know if you need to make any changes or look up specific information.

**Q8** (6.5 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.
- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> The company "Apollo Orange, LLC." is not in the Accounts list. The assistant will first add this company to the Accounts list and then create the lead for Mario Rossi.
> 
> I have opened the Accounts screen. Now I will add the company "Apollo Orange, LLC." to the list.
> 
> The company "Apollo Orange, LLC." has been added to the Accounts list, and the lead for Mario Rossi has been created successfully. The new lead is now visible on the Leads board with the status "New".

### claude

**warm-up** (2.4 s)

> Hello! I'm here to help you use this CRM application. 
> 
> You're currently on the **Dashboard**, which shows you a count of your leads organized by status:
> 
> - **New** — leads nobody has contacted yet
> - **Active** — leads being worked on
> - **Proposal Sent** — leads waiting for an answer to a proposal
> - **Closed** — leads that ended, won or lost
> - **Inactive** — leads parked
> - **Total** — all your leads combined
> 
> The numbers update when you come back to the Dashboard after making changes elsewhere.
> 
> What would you like to do? I can help you navigate the application or explain how to work with leads, accounts, proposals, and more.

**Q1** (2.6 s)

> To move a lead from one column to another, **drag and drop** the row from its current column to the column where you want it.
> 
> When you drop a lead on a new column, two things happen:
> 
> 1. **The lead takes the status of the column** you dropped it on.
> 2. **If the date for that stage is still empty, it gets stamped with the current time** — for example, Date Contacted when moving to Active, Date Drafted when moving to Proposal Sent, or Date Closed when moving to Closed.
> 
> A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> 
> The four lists refresh after every move, and the lead you dragged stays selected.
> 
> [Source: Leads](Leads.md)

**Q2** (1.7 s)

> Your data is stored in a single file called **w10crmdemo.sdb** in your Documents folder. It's encrypted with AES-256.
> 
> To start over with the original sample data, follow these steps:
> 
> 1. Close the application
> 2. Delete w10crmdemo.sdb from your Documents folder
> 3. Start the application again — it will rebuild the file with the original sample data
> 
> According to the documentation, there is no other way to undo changes, as the application has no transaction rollback feature.
> 
> Source: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (1.6 s)

> No. According to the documentation, [the document is stored as it was generated](Draft-Proposal.md). You can mark it Accepted or Canceled, but you cannot edit it, and the lead cannot be given a second proposal.
> 
> If you need to redo a proposal, you must delete the existing one from the Sales list and create a new one.

**Q4** (1.4 s)

> According to the documentation, **use the export on the Marketing page** — it writes a delimited text file that a spreadsheet can open directly.
> 
> The exports on the Accounts and Leads pages (where you are now) write FireDAC's own format, which is meant to be read back by this application, not by Excel.

**Q5** (2.3 s)

> Use the **Search box** on the Leads board. According to the documentation:
> 
> > The Search box filters all four columns at once, as you type. It matches, ignoring case and anywhere inside the value, against the lead's name, account name, office phone or **e-mail**.
> 
> So simply type the e-mail address (or part of it) into the Search box, and it will filter all columns to show only the lead(s) with that e-mail. For example, typing `example.com` finds everybody with that domain.
> 
> To clear the search and see the full board again, clear the Search box.

**Q6** (1.3 s)

> I can't help with that. I'm the help assistant for this CRM application, and I can only explain how to use it. Weather information is outside the scope of this application.
> 
> If you have questions about the CRM Demo application—such as how to manage leads, accounts, proposals, or any other feature—I'd be happy to help!

**Q7** (1.4 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> Done. The Accounts screen is now open.

**Q8** (2.0 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Done. The lead Mario Rossi for Apollo Orange, LLC. has been created with email mario.rossi@example.com, status New, and is now open in the detail window.

### gemini

**warm-up** (2.3 s)

> Hello! How can I help you with the application today?

**Q1** (4.2 s)

> To move a lead from one column to another, drag its row and drop it onto the destination column ([Leads](Leads.md)).
> 
> When you drop it:
> * The lead takes the status of the new column.
> * If the date for that stage is currently empty, it is stamped with the current date/time:
>   * **Date Contacted** when moving to **Active**
>   * **Date Drafted** when moving to **Proposal Sent**
>   * **Date Closed** when moving to **Closed**
> * If the stage date already has a value, it is left alone, meaning moving a lead back and forth does not rewrite its history.
> * Dropping a lead in the column it is already in does nothing ([Leads](Leads.md)).

**Q2** (4.0 s)

> Your data is stored in a single SQLite file named **`w10crmdemo.sdb`** in your **Documents** folder, encrypted with AES-256.
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete the **`w10crmdemo.sdb`** file from your Documents folder.
> 3. Start the application again. 
> 
> Upon restarting, the application will automatically recreate the file with the original sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (2.6 s)

> No. A proposal cannot be edited once saved, and the lead cannot be given a second proposal. You can only mark it **Accepted** or **Canceled**. 
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator and create a new one ([FAQ](FAQ.md)).

**Q4** (3.7 s)

> To get a file you can open in Excel, use the export on the **Marketing** page. It writes a delimited text file with a header row that spreadsheets open directly ([Accounts](Accounts.md), [FAQ](FAQ.md)). 
> 
> By contrast, the exports on the Accounts and Leads pages save in FireDAC's proprietary format (binary, XML, or JSON), which is intended only to be read back by this application ([Accounts](Accounts.md), [FAQ](FAQ.md)).

**Q5** (3.0 s)

> On the **Leads** board, type the e-mail address (or part of it) into the **Search** box. It filters all four columns at once as you type, matching anywhere inside the lead's name, account name, office phone, or e-mail regardless of case. Clear the box when you want to restore the full board.
> 
> Source: [Leads](Leads.md)

**Q6** (2.9 s)

> I am sorry, but the documentation does not cover weather information. I can only assist with questions about using this application.

**Q7** (4.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (5.4 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi under **Apollo Orange, LLC.** with the email `mario.rossi@example.com` ([Asking the assistant](Assistant.md)).

