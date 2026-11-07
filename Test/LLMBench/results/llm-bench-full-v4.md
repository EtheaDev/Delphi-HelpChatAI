# HelpChatAI provider benchmark

Run on 2026-11-07 11:32. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 14.0 s | 8 | 0 | 4.2 s | 3.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 21.3 s | 8 | 0 | 2.7 s | 1.8 s | 100% (8/8) | 91% (10/11) | 88% (7/8) |
| qwen3-coder:30b | 29.6 s | 8 | 0 | 5.0 s | 2.7 s | 75% (6/8) | 100% (11/11) | 75% (6/8) |
| claude | 2.7 s | 8 | 0 | 1.8 s | 0.6 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini | 2.2 s | 8 | 0 | 4.4 s | 3.9 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 5.5 s | 3.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 3.4 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 6.0 s | 2.9 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude | 2.8 s | 0.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini | 5.3 s | 4.2 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 4.4 s | 3.3 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 4.4 s | 2.5 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 4.4 s | 2.2 s | - | **no** | 3/3 | - | yes |
| Q2 | claude | 2.2 s | 0.4 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini | 4.6 s | 3.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 3.5 s | 2.9 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 2.0 s | 1.2 s | FAQ.md | yes | 1/2 | - | yes |
| Q3 | qwen3-coder:30b | 4.2 s | 2.6 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude | 1.6 s | 0.5 s | Draft-Proposal.md | yes | 2/2 | - | yes |
| Q3 | gemini | 2.8 s | 2.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 4.3 s | 3.4 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 3.1 s | 2.1 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 7.0 s | 3.1 s | - | **no** | 1/1 | open_screen | **no** |
| Q4 | claude | 1.5 s | 0.4 s | Accounts.md | yes | 1/1 | - | yes |
| Q4 | gemini | 3.7 s | 3.2 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 4.0 s | 3.1 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 3.4 s | 2.0 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 5.0 s | 2.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude | 1.7 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini | 4.6 s | 4.0 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 3.1 s | 3.0 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.2 s | 1.0 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 3.3 s | 2.0 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 1.0 s | 0.4 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 3.0 s | 2.9 s | - | yes | 0/0 | - | yes |
| Q7 | gemma4:12b | 4.1 s | 4.0 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 1.6 s | 1.3 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 3.9 s | 3.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 1.2 s | 1.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 5.0 s | 4.9 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 4.4 s | 4.2 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 2.9 s | 2.5 s | - | yes | 0/0 | - | **no** |
| Q8 | qwen3-coder:30b | 6.3 s | 2.7 s | - | yes | 0/0 | open_screen, create_lead | **no** |
| Q8 | claude | 1.9 s | 1.3 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 6.1 s | 5.9 s | Assistant.md | **no** | 0/0 | create_lead | yes |

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

**warm-up** (14.0 s)

> Hello! How can I help you with the application today?

**Q1** (5.5 s)

> To move a lead between columns on the board, you can use the drag and drop method:
> 
> 1. **Drag and drop** a row from one column and drop it onto another. [Leads](Leads.md)
> 2. When you do this, the lead takes on the status of the new column. [Leads](Leads.md)
> 3. **Regarding dates:**
>    * If the date for that stage is currently empty, it will be automatically stamped with the current time. [Leads](Leads.md)
>    * If a date already has a value, it will be left alone to preserve the lead's history. [Leads](Leads.md)
> 4. Note that dropping a lead on the column it is already in will have no effect. [Leads](Leads.md)

**Q2** (4.4 s)

> Your data is stored in an SQLite file named `w10crmdemo.sdb` located in your Documents folder, which is encrypted with AES-256. [Data model](Data-Model.md)
> 
> To start over with the original sample data, you must:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again, and the file will be rebuilt with the original sample data. [Getting started](Getting-Started.md) [Data model](Data-Model.md)

**Q3** (3.5 s)

> No, you cannot change a proposal after saving it because the document is stored exactly as it was generated. [FAQ](FAQ.md)
> 
> To redo a proposal, you must delete the existing one from the Sales list and create a new one. [FAQ](FAQ.md)

**Q4** (4.3 s)

> To get a file that you can open in Excel, you should use the export on the **Marketing** page, which writes a delimited text file with a header row [FAQ](FAQ.md). 
> 
> The export on the Accounts page is not a spreadsheet file; it saves in FireDAC's own format, which is meant to be read back by the application [Accounts](Accounts.md).

**Q5** (4.0 s)

> To find a lead by its e-mail address, you can use the **Search box** on the Leads screen. As you type the e-mail address, the box will filter all four columns automatically, matching the value anywhere inside the e-mail field regardless of case.
> 
> Source: [Leads](Leads.md)

**Q6** (3.1 s)

> I'm sorry, but the documentation does not provide information about the weather.

**Q7** (4.1 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (4.4 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> The lead for Mario Rossi at Apollo Orange, LLC. has been successfully created.

### gpt-oss:20b

**warm-up** (21.3 s)

> Hi there! I’m here to help you navigate and use the CRM. Let me know what you’d like to do next.

**Q1** (3.4 s)

> To move a lead on the board:
> 
> 1. **Drag the row** – Click on the lead’s row, hold the mouse button, and drag it to the desired column.
> 2. **Drop it** – Release the mouse button in the target column.
> 
> When you drop the lead:
> 
> - The lead’s status changes to that of the new column.
> - If the date field for that stage is still empty, it is automatically stamped with the current date (e.g., *Date Contacted* when moving to **Active**, *Date Drafted* when moving to **Proposal Sent**, *Date Closed* when moving to **Closed**).  
> - If the date already has a value, it is left unchanged, so moving a lead back and forth does not rewrite its history.  
> 
> These actions refresh the lists and keep the dragged lead selected.  
> Source: **[Leads](Leads.md)**

**Q2** (4.4 s)

> Your data lives in a single encrypted SQLite file called **w10crmdemo.sdb** that the application creates in your **Documents** folder.  
> - The file is created on the first run and is updated whenever you add or change records.  
> - It contains the sample data that ships with the app (8 leads, 8 accounts, one user, three proposals).  
> 
> If you want to discard all changes and restore the original sample data, simply:
> 
> 1. Close the application.  
> 2. Delete the **w10crmdemo.sdb** file from your Documents folder.  
> 3. Start the application again; it will rebuild the file with the original sample data.
> 
> > Source: [Getting started](Getting-Started.md)  
> > Source: [Data model](Data-Model.md)

**Q3** (2.0 s)

> No – once a proposal is saved it’s stored exactly as generated. You can only mark it **Accepted** or **Canceled**; the proposal itself cannot be edited afterward.  
> Source: **FAQ** – “Can I change a proposal after saving it? No. … You can mark it Accepted or Canceled, but not edit it…”.
> 
> Source: [FAQ](FAQ.md)

**Q4** (3.1 s)

> The export that produces a file you can open directly in Excel is the one on the **Marketing** screen.  
> It writes a delimited text file with a header row, which a spreadsheet application opens without issues.  
> 
> The exports on the Accounts and Leads screens create files in FireDAC’s own format (binary, XML or JSON) that are meant to be read back by the application, not by Excel.  
> 
> Source: [FAQ](FAQ.md)

**Q5** (3.4 s)

> To locate a lead by e‑mail address:
> 
> 1. **Go to the Search box** at the top of the Leads board.  
> 2. **Type the e‑mail address** (or part of it) into the box.  
> 3. The board will instantly filter all four columns, showing only the lead(s) whose e‑mail matches the text you entered.
> 
> The search works case‑insensitively and matches anywhere in the e‑mail field, so you can enter a full address or just a unique part of it.  
> 
> Source: [Leads](/Leads.md)
> 
> Source: [Leads](Leads.md)

**Q6** (1.2 s)

> I’m sorry, but the application doesn’t provide weather information.

**Q7** (1.6 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I’ve taken you to the **Accounts** screen. Let me know what you’d like to do next.

**Q8** (2.9 s)

> I need a few more details to create the lead:
> 
> * A short note or reminder for the lead  
> * The office phone number
> 
> Could you please provide those?

### qwen3-coder:30b

**warm-up** (29.6 s)

> Hello! I'm here to help you use the application. 
> 
> I see you're on the Dashboard screen, which shows counts of leads for the active user, organized by status (New Leads, Active Leads, Proposal Sent, Closed Leads, Inactive Leads). The totals for each status are displayed in tiles.
> 
> Is there something specific you'd like to do or learn about? I can help you navigate to other sections like Accounts, Leads, or Users.
> 
> Source: [Dashboard](Dashboard.md), [Users](Users.md)

**Q1** (6.0 s)

> To move a lead from one column to another on the Leads board, you **drag and drop** the lead row from one column to another.
> 
> When you do this:
> - The lead takes the **status** of the column you dropped it into.
> - If the date field for that status is **empty**, it gets stamped with the current date:
>   - *Date Contacted* when moving to **Active**
>   - *Date Drafted* when moving to **Proposal Sent**
>   - *Date Closed* when moving to **Closed**
> - If the date field already has a value, it is **left unchanged** — this prevents overwriting history if you move the lead back and forth.
> 
> The four lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (4.4 s)

> Your data is stored in a single SQLite file named **w10crmdemo.sdb**, located in your **Documents** folder. This file is encrypted with AES-256.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete the file **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again.
> 
> The application will recreate the file with the original sample data, including 8 leads, 8 accounts, one user, and three proposals.

**Q3** (4.2 s)

> According to the documentation, **no**. Once you save a proposal, you cannot change it. The document is stored as it was generated.
> 
> If you need to make changes, you must:
> 
> 1. Delete the existing proposal from the Sales list using the navigator.
> 2. Create a new proposal.
> 
> This is mentioned in the [FAQ](FAQ.md) section of the documentation.

**Q4** (7.0 s)

- action `open_screen` {"name":"Marketing"} -> Opened the Marketing screen.

> According to the documentation, the export on the **Marketing** page writes a delimited text file with a header row, which can be opened directly in Excel. The exports on the **Accounts** and **Leads** pages write FireDAC's own format, meant to be read back by the application.
> 
> To proceed with this export:
> 1. Click on the **Marketing** screen.
> 2. Look for the export option on that page.
> 
> Would you like me to open the Marketing screen for you?
> 
> I have opened the Marketing screen for you. Look for the export option on this screen to create a file that can be opened in Excel. The export on this page writes a delimited text file with a header row, which is compatible with spreadsheet applications like Excel.

**Q5** (5.0 s)

> To find a lead using its email address on the **Leads** screen:
> 
> 1. Use the **Search** box at the top of the board.
> 2. Type the email address into the search box.
> 3. The board will filter all four columns in real-time, showing only leads matching that email address.
> 
> The search matches against the lead's name, account name, office phone, or email — so typing part of an email will also work.
> 
> If no results appear, make sure the email address is correctly typed. Clearing the box returns the full board view.
> 
> Source: [Leads](Leads.md)

**Q6** (3.3 s)

> I cannot provide weather information. The application documentation does not contain any information about weather forecasts or external data retrieval capabilities. My tools are limited to operating the CRM application itself, such as opening screens or creating leads.
> 
> To get weather information for Milan, you would need to use a dedicated weather service or application.<tool_call>

**Q7** (3.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open. You can view and manage the company accounts listed in the application. Let me know if you need help with anything else.<tool_call>

**Q8** (6.3 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.
- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> The company "Apollo Orange, LLC." is not in the Accounts list. I will first add it and then create the lead.
> 
> I need to add "Apollo Orange, LLC." to the Accounts list before creating the lead. I will use the assistant to do this for you.
> 
> I have created the lead for Mario Rossi at Apollo Orange, LLC. The lead has been added to the Leads board with the status "New". You can now view and edit its details.<tool_call>

### claude

**warm-up** (2.7 s)

> Hello! I'm the help assistant for this CRM application. I'm here to explain how to use it.
> 
> You're currently on the **Dashboard**, which shows you a summary of your leads organized by status:
> 
> - **New** — leads nobody has contacted yet
> - **Active** — leads being worked on
> - **Proposal Sent** — leads waiting for an answer to a proposal
> - **Closed** — leads that ended, won or lost
> - **Inactive** — leads parked
> - **Total** — every lead you have, whatever the status
> 
> The numbers you see are filtered by the active user (selected in the drop-down at the top right).
> 
> What would you like to do? I can help you navigate the application or explain how to work with leads, accounts, proposals, and more.
> 
> Source: [Dashboard](Dashboard.md)

**Q1** (2.8 s)

> According to the documentation, you move a lead by **dragging and dropping**:
> 
> 1. **Drag a row** from one column and **drop it on another column**.
> 
> When you do this, two things happen:
> 
> - **The lead takes the status** of the column you dropped it on.
> - **If the date for that stage is empty**, it gets stamped with the current date. For example:
>   - Moving to Active stamps the Date Contacted
>   - Moving to Proposal Sent stamps the Date Drafted
>   - Moving to Closed stamps the Date Closed
> 
> **Important:** A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> 
> After the move, the four columns refresh and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.2 s)

> Your data is stored in a single encrypted file called **w10crmdemo.sdb** in your Documents folder. It's encrypted with AES-256 and contains all your leads, accounts, users, and proposals.
> 
> To start over with the original sample data:
> 
> 1. Close the application
> 2. Delete the w10crmdemo.sdb file from your Documents folder
> 3. Start the application again — it will recreate the file with the original sample data
> 
> The sample data includes 8 leads (named after colours like Gary Orange and Cathy Black), 8 accounts (named after Greek gods like Zeus Red Inc.), one user (CRMUser), and three sample proposals.
> 
> Source: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (1.6 s)

> No. According to the documentation, [the document is stored as it was generated](Draft-Proposal.md). You can mark it Accepted or Canceled, but you cannot edit it after saving.
> 
> If you need to redo a proposal, you must delete the existing one from the Sales list and create a new one. Also note that a lead can only have one proposal at a time.

**Q4** (1.5 s)

> According to the documentation, **use the export on the Marketing page** — it writes a delimited text file with a header row, which a spreadsheet opens directly.
> 
> The exports on the Accounts and Leads pages (where you are now) write FireDAC's own format, which is meant to be read back by this application, not by Excel.
> 
> Source: [Accounts](Accounts.md)

**Q5** (1.7 s)

> Use the **Search box** on the Leads board. It filters all four columns as you type and matches against the lead's name, account name, office phone, or e-mail — matching anywhere inside the value and ignoring case.
> 
> So typing the e-mail address (or even part of it) will find the lead you're looking for. Clear the box to get the full board back.
> 
> Source: [Leads](Leads.md)

**Q6** (1.0 s)

> I can't help with that. I'm the help assistant for this CRM application, and I can only explain how to use it. Questions about weather are outside my scope.
> 
> Is there anything you'd like to know about how to use the application?

**Q7** (1.2 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (1.9 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Done. I've created the lead **Mario Rossi** for **Apollo Orange, LLC.** with email mario.rossi@example.com. The lead has been assigned id 101 and will appear in the **New** column of the Leads board.

### gemini

**warm-up** (2.2 s)

> Hello! How can I help you with the application today?

**Q1** (5.3 s)

> To move a lead, drag a row from one column and drop it onto another.
> 
> When you drop it:
> * **Status:** The lead takes the status of the destination column.
> * **Dates:** If the date for that stage is currently empty, it is stamped with the current date/time:
>   * **Date Contacted** when moving to **Active**
>   * **Date Drafted** when moving to **Proposal Sent**
>   * **Date Closed** when moving to **Closed**
> * If the date already has a value, it is left alone, so moving a lead back and forth does not rewrite its history.
> 
> Dropping a lead onto the column it is already in does nothing.
> 
> Source: [Leads](Leads.md)

**Q2** (4.6 s)

> Your data is stored in a single SQLite file named **`w10crmdemo.sdb`**, located in your **Documents** folder and encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete the **`w10crmdemo.sdb`** file from your Documents folder.
> 3. Start the application again. 
> 
> On startup, the application will automatically recreate the file with the default sample data ([Getting started](Getting-Started.md), [Data model](Data-Model.md)).

**Q3** (2.8 s)

> **No**, you cannot edit a proposal once it has been saved. The document is stored exactly as generated ([FAQ](FAQ.md)). 
> 
> While you can change its status to **Accepted** or **Canceled**, you cannot edit its contents, and a lead cannot have more than one proposal. If you need to redo a proposal, delete the existing one from the **Sales** list using the navigator, and then create a new one ([FAQ](FAQ.md)).

**Q4** (3.7 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which a spreadsheet program like Excel can open directly. 
> 
> In contrast, the exports on the Accounts and Leads pages write in FireDAC's own format (binary, XML, or JSON), which is intended to be read back by this application rather than opened as a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (4.6 s)

> To find a lead using an e-mail address, use the **Search** box on the Leads board:
> 
> * Type the e-mail address (or part of it) into the **Search** box.
> * The search filters all four columns at once as you type, matching case-insensitively anywhere inside the lead's name, account name, office phone, or e-mail address.
> * Clear the search box when you want to restore the full board.
> 
> Source: [Leads](Leads.md)

**Q6** (3.0 s)

> I am sorry, but the documentation does not cover weather information. I can only assist with questions about using this application.

**Q7** (5.0 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (6.1 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","name":"Mario Rossi","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> The lead for **Mario Rossi** at **Apollo Orange, LLC.** has been created with status New, and its detail window is open ([Asking the assistant](Assistant.md)).

