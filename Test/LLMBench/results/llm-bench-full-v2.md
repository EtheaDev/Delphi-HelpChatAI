# HelpChatAI provider benchmark

Run on 2026-11-06 18:38. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 13.0 s | 8 | 0 | 5.3 s | 4.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 18.8 s | 8 | 0 | 3.5 s | 2.6 s | 100% (8/8) | 100% (11/11) | 88% (7/8) |
| qwen3-coder:30b | 29.9 s | 8 | 0 | 4.9 s | 2.4 s | 50% (4/8) | 100% (11/11) | 75% (6/8) |
| claude | 2.4 s | 8 | 0 | 1.9 s | 0.7 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini | 2.5 s | 8 | 0 | 4.5 s | 4.0 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 7.4 s | 4.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 3.3 s | 1.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 6.2 s | 2.9 s | - | **no** | 3/3 | - | yes |
| Q1 | claude | 2.9 s | 0.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini | 5.3 s | 4.0 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 5.6 s | 4.0 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 4.5 s | 2.8 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 4.8 s | 2.6 s | - | **no** | 3/3 | - | yes |
| Q2 | claude | 2.3 s | 0.5 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini | 4.6 s | 3.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 5.3 s | 4.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 3.0 s | 2.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | qwen3-coder:30b | 3.6 s | 2.5 s | - | **no** | 2/2 | - | yes |
| Q3 | claude | 1.6 s | 0.4 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini | 5.4 s | 4.9 s | FAQ.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 6.5 s | 5.3 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 3.1 s | 2.1 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 6.7 s | 3.0 s | - | **no** | 1/1 | open_screen | **no** |
| Q4 | claude | 1.7 s | 0.4 s | Marketing.md | yes | 1/1 | - | yes |
| Q4 | gemini | 3.8 s | 3.2 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 5.1 s | 4.2 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 3.4 s | 2.3 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 4.8 s | 2.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude | 1.8 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini | 3.7 s | 3.2 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 3.7 s | 3.2 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.6 s | 1.4 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 1.0 s | 0.3 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 1.2 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 2.9 s | 2.8 s | - | yes | 0/0 | - | yes |
| Q7 | gemma4:12b | 3.4 s | 3.3 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 5.1 s | 5.0 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 3.6 s | 3.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 1.3 s | 1.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 5.3 s | 5.3 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 5.7 s | 5.3 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 4.1 s | 3.4 s | - | yes | 0/0 | - | **no** |
| Q8 | qwen3-coder:30b | 8.3 s | 2.4 s | - | yes | 0/0 | open_screen, create_lead, open_screen | **no** |
| Q8 | claude | 2.1 s | 1.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 5.1 s | 4.8 s | - | yes | 0/0 | create_lead | yes |

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

**warm-up** (13.0 s)

> Hello! How can I help you with the application today?

**Q1** (7.4 s)

> To move a lead to a different column, you can use the drag and drop method:
> 
> 1. Drag a row from one column and drop it onto another [Leads](Leads.md).
> 2. The lead will take the status of the column you dropped it on.
> 3. Regarding the dates:
>     * If the date for that stage is currently empty, it will be stamped with the current time (e.g., moving to Active stamps the "Date Contacted," moving to Proposal Sent stamps "Date Drafted," and moving to Closed stamps "Date Closed").
>     * If the date already has a value, it remains unchanged, ensuring the lead's history is not rewritten [Leads](Leads.md).
>     * Dropping a lead on the column it is already in will have no effect.

**Q2** (5.6 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, which is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data, you must:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again to rebuild the file with the original data [Getting started](Getting-Started.md), [Data model](Data-Model.md).

**Q3** (5.3 s)

> No, you cannot change a proposal after it has been saved because the document is stored exactly as it was generated. [FAQ](FAQ.md)
> 
> While you cannot edit it, you can mark the proposal as **Accepted** or **Canceled**. To redo a proposal, you must delete the existing one from the Sales list and create a new one. [FAQ](FAQ.md)

**Q4** (6.5 s)

> For a file that you can open directly in Excel, use the export on the **Marketing** page, which writes a delimited text file. [FAQ](FAQ.md)
> 
> The exports on the Accounts and Leads pages use a FireDAC format that is intended to be read back by the application, not by spreadsheet software. [Accounts](Accounts.md)

**Q5** (5.1 s)

> To find a lead by its e-mail address, you can use the **Search box** on the Leads screen. As you type, the box filters all four columns and matches the value anywhere inside the e-mail field (ignoring case).
> 
> Source: [Leads](Leads.md)

**Q6** (3.7 s)

> I am sorry, but I do not have information about the weather in Milan as it is not covered in the application documentation.

**Q7** (3.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (5.7 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi at Apollo Orange, LLC. with the email mario.rossi@example.com.

### gpt-oss:20b

**warm-up** (18.8 s)

> Hi! I’m here to help you with the CRM Demo. What would you like to do today?

**Q1** (3.3 s)

> To move a lead on the board:
> 
> 1. **Drag the lead’s row** from its current column.
> 2. **Drop it onto the target column**.
> 
> After dropping:
> 
> - The lead’s status changes to match the column you dropped it into.
> - If the date column for that status is still empty, the system writes the current date into it (e.g., *Date Contacted*, *Date Drafted*, or *Date Closed*).  
> - If that date already has a value, it stays unchanged, so moving the lead back and forth does not overwrite its history.  
> 
> The lead you moved remains selected, and the four lists refresh automatically.  
> 
> *Source: [Leads](Leads.md)*

**Q2** (4.5 s)

> **Where your data lives**
> 
> The application stores everything in a single SQLite file named `w10crmdemo.sdb` in your *Documents* folder.  
> It is encrypted with AES‑256.  
> *Source: [Getting started](Getting-Started.md), [Data model](Data-Model.md)*
> 
> **How to reset to the original sample data**
> 
> 1. Close the application.  
> 2. Delete the `w10crmdemo.sdb` file from your *Documents* folder.  
> 3. Launch the app again – it will rebuild the database with the original sample data.  
> *Source: [Getting started](Getting-Started.md), [Data model](Data-Model.md)*

**Q3** (3.0 s)

> No. Once you click **Save Proposal** the document is stored exactly as generated, and the lead can receive only that one proposal. You can only mark it **Accepted** or **Canceled**; you cannot edit it. To make a new version you must delete the old proposal from the Sales list (using the navigator) and create a new one.  
> > Source: [FAQ](FAQ.md)

**Q4** (3.1 s)

> The only export that produces a file you can open directly in Excel is the one on the **Marketing** screen. It writes a delimited‑text file (CSV/TSV) with a header row that Excel recognises automatically.  
> 
> *Accounts* and *Leads* exports write FireDAC’s binary/XML/JSON format, which is only readable by this application.  
> 
> Source: [FAQ](FAQ.md)

**Q5** (3.4 s)

> Use the **Search** box on the Leads board.  
> - Click the Search field (usually at the top of the board).  
> - Type the e‑mail address you remember.  
> - As you type, the board will filter and show any lead whose e‑mail matches.  
> 
> The search ignores case and matches against the lead’s name, account name, office phone, or e‑mail.  
> 
> [Leads](Leads.md)

**Q6** (1.6 s)

> I’m sorry, but this application doesn’t provide weather information.

**Q7** (5.1 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (4.1 s)

> I need a couple more details to add the lead:
> 
> - Phone number (Office Phone)  
> - Any notes you’d like saved with the lead
> 
> Once I have those, I’ll create the lead for **Apollo Orange, LLC.** and open its detail window.

### qwen3-coder:30b

**warm-up** (29.9 s)

- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> Hello! I'm here to help you navigate the CRM Demo application. Based on your current screen, you're on the Dashboard.
> 
> The Dashboard shows you counts of leads organized by status:
> - New Leads (not contacted yet)
> - Active Leads (being worked on)
> - Proposal Sent (waiting for an answer)
> - Closed Leads (won or lost)
> - Inactive Leads (parked)
> 
> Each count is filtered by the active user selected in the dropdown at the top right. The "Total" tile shows all leads for that user.
> 
> To see the actual leads behind any of these counts, you can click on the "Leads" tab in the navigation menu.
> 
> I've opened the Leads screen for you. This shows all the leads filtered by the currently selected user. You can see the leads organized by their status, and each lead has details like the company it belongs to, contact information, and notes.
> 
> From here you can:
> - View individual leads
> - Create new leads using the "New Lead" button
> - Change a lead's status
> - Edit lead details
> 
> Is there anything specific about the leads you'd like to do or see?

**Q1** (6.2 s)

> To move a lead from one column to another on the Leads board, **drag and drop** the lead row from one column and drop it on another.
> 
> When you move a lead:
> 
> - It takes the **status** of the column you dropped it on.
> - If the date of that stage is still empty, it is **stamped with the current date**:
>   - **Date Contacted** when moving to Active
>   - **Date Drafted** when moving to Proposal Sent
>   - **Date Closed** when moving to Closed
> - A date that already has a value is **left alone**, so moving a lead back and forth does not rewrite its history.
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

**Q3** (3.6 s)

> According to the documentation, **no**. Once you save a proposal, you cannot edit it. The document is stored as it was generated.
> 
> If you need to make changes, you must **delete the existing proposal** from the Sales list and create a new one.

**Q4** (6.7 s)

- action `open_screen` {"name":"Marketing"} -> Opened the Marketing screen.

> According to the documentation, the export on the **Marketing** page writes a delimited text file with a header row, which can be opened directly in Excel. The exports on the **Accounts** and **Leads** pages write FireDAC's own format, meant to be read back by the application.
> 
> To proceed with this export:
> 1. Click on the **Marketing** screen.
> 2. Look for the export option there.
> 
> The export option is available on the **Marketing** screen. You can use that to save the data as a delimited text file, which can be opened in Excel. The other exports (Accounts and Leads) write FireDAC's own format, not suitable for Excel.
> 
> If you need help with the export process itself, let me know!

**Q5** (4.8 s)

> To find a lead using its email address on the **Leads** screen:
> 
> 1. Use the **Search** box at the top of the board.
> 2. Type the email address into the search box.
>    - The search matches, ignoring case and anywhere inside the value, against the lead's name, account name, office phone, or email.
> 3. As you type, the board filters all four columns automatically to show only leads matching the email address.
> 
> This will display the relevant lead(s) in the appropriate column based on their status.
> 
> Source: [Leads](Leads.md)

**Q6** (1.0 s)

> I cannot provide weather information. The application documentation does not contain any details about weather forecasts or external data retrieval capabilities. My role is limited to explaining how to use this CRM application.<tool_call>

**Q7** (3.6 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open. You can view and manage the company accounts here. Let me know if you need any further assistance.<tool_call>

**Q8** (8.3 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.
- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).
- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> The company "Apollo Orange, LLC." is not in the Accounts list. I will first add it and then create the lead.
> 
> I need to create the company "Apollo Orange, LLC." in the Accounts list before creating the lead. I will use the assistant to add this company.
> 
> I have created the lead for Mario Rossi at Apollo Orange, LLC. The lead has been added to the Leads board with the status "New". You can now view and edit the lead details as needed.
> 
> I have created the lead for Mario Rossi at Apollo Orange, LLC. The lead has been added to the Leads board with the status "New". You can now view and edit the lead details as needed.

### claude

**warm-up** (2.4 s)

> Hello! I'm the in-app help assistant for this CRM application. I'm here to help you understand how to use the different features.
> 
> You're currently on the **Dashboard**, which shows you a summary of your leads organized by status:
> 
> - **New** – Leads nobody has contacted yet
> - **Active** – Leads being worked on
> - **Proposal Sent** – Leads waiting for an answer to a proposal
> - **Closed** – Leads that ended (won or lost)
> - **Inactive** – Leads that are parked
> - **Total** – All your leads regardless of status
> 
> The numbers update whenever you return to the Dashboard after making changes elsewhere.
> 
> Is there anything specific you'd like to know about how to use this application?

**Q1** (2.9 s)

> According to the [Leads](Leads.md) documentation, you move a lead by **dragging and dropping**:
> 
> 1. **Drag** a row from one column and **drop it on another column**.
> 
> When you do this, two things happen:
> 
> - The lead takes the status of the column you dropped it on.
> - If the date for that stage is still empty, it is automatically stamped with the current date. For example:
>   - Moving to **Active** stamps the Date Contacted
>   - Moving to **Proposal Sent** stamps the Date Drafted
>   - Moving to **Closed** stamps the Date Closed
> 
> **Important:** A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> 
> If you drop a lead on the column it already is in, nothing happens. After every move, the lists refresh and the lead you dragged stays selected.

**Q2** (2.3 s)

> Your data is stored in a single SQLite file called **w10crmdemo.sdb** in your Documents folder. It is encrypted with AES-256.
> 
> To start over with the original sample data, follow these steps:
> 
> 1. **Close the application**
> 2. **Delete w10crmdemo.sdb** from your Documents folder
> 3. **Start the application again** — it will rebuild the file with the original sample data
> 
> That's it. The application will recreate the file with the sample leads (named after colours), accounts (named after Greek gods), and restore everything to its initial state.
> 
> Source: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (1.6 s)

> No, you cannot change a proposal after saving it. [According to the documentation](FAQ.md):
> 
> > The document is stored as it was generated. You can mark it Accepted or Canceled, but not edit it, and the lead cannot be given a second one.
> 
> If you need to make changes, you must delete the existing proposal from the Sales list and create a new one.

**Q4** (1.7 s)

> According to the documentation, [the export on the Marketing page](Marketing.md) is the one you should use: it writes a delimited text file with a header row, which a spreadsheet opens directly.
> 
> The exports on the Accounts and Leads pages (which is where you are now) write FireDAC's own format, meant to be read back by this application — not for opening in Excel.

**Q5** (1.8 s)

> Use the **Search box** on the Leads board. Type the e-mail address (or part of it) and it will filter all four columns to show matching leads. The search matches anywhere inside the value and ignores case — so typing `example.com` finds everybody with that domain in their e-mail. Clear the box to get the full board back.
> 
> [Leads](Leads.md)

**Q6** (1.2 s)

> I can't help with that. I'm the help assistant for this CRM application, and I only have information about how to use it. For weather information, you'd need to check a weather service or website.
> 
> Is there anything about the application I can help you with?

**Q7** (1.3 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> Done — the Accounts screen is now open.

**Q8** (2.1 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Done. I've created a lead for Mario Rossi at Apollo Orange, LLC. with the email mario.rossi@example.com. The lead has been assigned id 101 and placed in the New status column.

### gemini

**warm-up** (2.5 s)

> Hello! How can I help you with the application today?

**Q1** (5.3 s)

> To move a lead from one column to another, drag its row from one column and drop it onto another. 
> 
> When you drop it:
> * **The status changes** to the column you dropped it on.
> * **Stage dates are updated if empty:** If the date for that stage is still empty, it is stamped with the current time:
>   * Moving to **Active** sets **Date Contacted**.
>   * Moving to **Proposal Sent** sets **Date Drafted**.
>   * Moving to **Closed** sets **Date Closed**.
> * **Existing dates are preserved:** A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> 
> Dropping a lead on the column it is already in does nothing, and the lead remains selected after the lists refresh.
> 
> Source: [Leads](Leads.md)

**Q2** (4.6 s)

> Your data is stored in a single SQLite file named **`w10crmdemo.sdb`**, located in your **Documents** folder and encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete the file **`w10crmdemo.sdb`** from your Documents folder.
> 3. Start the application again. 
> 
> On startup, the application will recreate the file with the original sample data ([Getting started](Getting-Started.md), [Data model](Data-Model.md)).

**Q3** (5.4 s)

> No. The document is stored as it was generated. You can mark it **Accepted** or **Canceled**, but you cannot edit it, and a lead cannot be given a second proposal. 
> 
> To redo a proposal, you must delete the existing one from the Sales list using the navigator and create a new one ([FAQ](FAQ.md)).

**Q4** (3.8 s)

> Use the export on the **Marketing** page. It writes a delimited text file (with a header row) that a spreadsheet program like Excel opens directly. 
> 
> The exports on the Accounts and Leads pages save files in FireDAC's proprietary format (binary, XML, or JSON), which is intended to be read back by this application rather than opened in Excel.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (3.7 s)

> Type the e-mail address into the **Search** box on the Leads board. 
> 
> The search box filters all four columns at once as you type, matching anywhere inside the lead's name, account name, office phone, or e-mail address (case-insensitive). Clear the box when you are done to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (2.9 s)

> I am sorry, but the provided documentation does not cover weather information. I can only assist with questions about using this application.

**Q7** (5.3 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (5.1 s)

- action `create_lead` {"name":"Mario Rossi","email":"mario.rossi@example.com","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> I have created the lead for **Mario Rossi** under **Apollo Orange, LLC.** with the email `mario.rossi@example.com`.

