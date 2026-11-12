# HelpChatAI provider benchmark

Run on 2026-11-12 17:51. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemini-4-argon | 7.6 s | 8 | 0 | 7.0 s | 6.1 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-carbon | 9.4 s | 8 | 0 | 8.6 s | 7.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-pro-latest | 4.7 s | 8 | 0 | 6.1 s | 5.7 s | 100% (8/8) | 91% (10/11) | 100% (8/8) |
| gemini-3.5-flash-lite | 1.4 s | 8 | 0 | 1.1 s | 0.9 s | 100% (8/8) | 91% (10/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemini-4-argon | 8.2 s | 5.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-carbon | 9.0 s | 7.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-pro-latest | 6.2 s | 5.3 s | Leads.md | yes | 2/3 | - | yes |
| Q1 | gemini-3.5-flash-lite | 1.3 s | 0.8 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-argon | 4.3 s | 3.2 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-carbon | 5.0 s | 4.0 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-pro-latest | 8.2 s | 7.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini-3.5-flash-lite | 1.0 s | 0.7 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | gemini-4-argon | 6.6 s | 5.5 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-carbon | 9.9 s | 8.9 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-pro-latest | 6.1 s | 5.8 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-3.5-flash-lite | 1.2 s | 1.1 s | FAQ.md | yes | 1/2 | - | yes |
| Q4 | gemini-4-argon | 5.6 s | 4.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-carbon | 10.4 s | 9.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-pro-latest | 5.6 s | 5.1 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gemini-3.5-flash-lite | 1.0 s | 0.7 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q5 | gemini-4-argon | 5.3 s | 4.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-carbon | 5.3 s | 4.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-pro-latest | 4.7 s | 4.1 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-3.5-flash-lite | 0.9 s | 0.7 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemini-4-argon | 4.6 s | 4.3 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-4-carbon | 5.3 s | 5.0 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-pro-latest | 4.8 s | 4.7 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-3.5-flash-lite | 1.0 s | 0.9 s | - | yes | 0/0 | - | yes |
| Q7 | gemini-4-argon | 7.2 s | 7.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-carbon | 12.9 s | 12.9 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-pro-latest | 4.9 s | 4.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-3.5-flash-lite | 1.5 s | 1.4 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemini-4-argon | 14.2 s | 13.9 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-carbon | 11.1 s | 10.9 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-pro-latest | 8.4 s | 8.2 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-3.5-flash-lite | 1.2 s | 1.1 s | - | yes | 0/0 | create_lead | yes |

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

### gemini-4-argon

**warm-up** (7.6 s)

> Hello! How can I help you with the application today? You are currently on the **Dashboard** screen. Feel free to ask how anything works or let me know if you would like to open another section.
> 
> Source: [Dashboard](Dashboard.md)

**Q1** (8.2 s)

> To move a lead on the board, **drag a row from one column and drop it onto another**. 
> 
> When you drop a lead into a new column:
> * The lead takes the status of the column you dropped it on.
> * If the date for that stage is still empty, it is automatically stamped with the current date and time (`now`):
>   * Moving to **Active** stamps **Date Contacted**.
>   * Moving to **Proposal Sent** stamps **Date Drafted**.
>   * Moving to **Closed** stamps **Date Closed**.
> * If that stage's date already has a value, it is left alone so that moving a lead back and forth does not rewrite its history.
> * Dropping a lead onto the column it is already in does nothing.
> 
> After every move, the four lists refresh and the lead you dragged remains selected.
> 
> Source: [Leads](Leads.md)

**Q2** (4.3 s)

> All your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb` inside your **Documents** folder.
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again (it will recreate the file with the sample data).
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (6.6 s)

> No, you cannot edit a proposal after saving it because the document is stored as it was generated, and a lead cannot be given a second one. 
> 
> After saving, you can only change its status to **Accepted** (using **Complete**) or **Canceled** (using **Cancel**). If you need to redo a proposal, delete the existing one from the **Sales** list using the navigator and then create a new one from the lead detail window.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (5.6 s)

> You should use the export on the **Marketing** page, which writes a delimited text file with a header row that a spreadsheet like Excel can open directly.
> 
> The **Export** button on the **Accounts** (and **Leads**) page saves the table in FireDAC's own format (binary, XML, or JSON depending on the file extension), which is meant to be read back by this application rather than opened in a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (5.3 s)

> Type the e-mail address (or part of it) into the **Search** box on the **Leads** screen. 
> 
> As you type, the **Search** box filters all four columns at once, matching case-insensitively anywhere inside the lead's name, account name, office phone, or e-mail address. Clear the box when you want to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (4.6 s)

> I cannot answer that question. I am the in-app help assistant for this application, and my only job is to explain how to use it based on its documentation.

**Q7** (7.2 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (14.2 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for **Mario Rossi** at **Apollo Orange, LLC.** (`mario.rossi@example.com`).

### gemini-4-carbon

**warm-up** (9.4 s)

> Hello! How can I help you with the application today?

**Q1** (9.0 s)

> To move a lead, drag its row from one column and drop it onto another. Dropping a lead onto the column it is already in does nothing.
> 
> When you drop it onto a new column:
> * **Status:** The lead takes the status of the target column, the four lists refresh, and the dragged lead stays selected.
> * **Empty dates:** If the date for that stage is empty, it is stamped with the current date and time (`Date Contacted` for **Active**, `Date Drafted` for **Proposal Sent**, and `Date Closed` for **Closed**).
> * **Existing dates:** Any date that already has a value is left unchanged, so moving a lead back and forth does not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (5.0 s)

> All of your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb` inside your **Documents** folder.
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again — it will automatically recreate the file with the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (9.9 s)

> No, you cannot edit a proposal once it has been saved, because the document is stored exactly as it was generated. You can only change its status to **Accepted** or **Canceled**, and a lead cannot be given a second proposal while one exists.
> 
> To redo a proposal:
> 1. Delete the existing proposal from the **Sales** list (the screen you are currently on) using the navigator.
> 2. Create a new proposal for that lead.
> 
> Source: [FAQ](FAQ.md)

**Q4** (10.4 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel (or any spreadsheet) can open directly.
> 
> By contrast, the **Export** buttons on the **Accounts** (your current screen) and **Leads** pages save in FireDAC's own format, which is only meant to be read back by this application.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (5.3 s)

> Type the e-mail address (or part of it) into the **Search** box on the **Leads** screen. 
> 
> As you type, it filters all four columns at once and matches against the lead's e-mail, name, account name, or office phone (ignoring case). Clear the box to show the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (5.3 s)

> I can only help you with using this application, so I don't have information about the weather. Let me know if you have any questions about the app!

**Q7** (12.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the **Accounts** screen.

**Q8** (11.1 s)

- action `create_lead` {"email":"mario.rossi@example.com","account":"Apollo Orange, LLC.","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** for **Apollo Orange, LLC.** (`mario.rossi@example.com`).

### gemini-pro-latest

**warm-up** (4.7 s)

> Hello! I am the help assistant for this application. How can I help you with it today?

**Q1** (6.2 s)

> To move a lead to another column, simply drag its row from the current column and drop it onto the new one. 
> 
> When you drop the lead into a new column, the date corresponding to that stage (Date Contacted for Active, Date Drafted for Proposal Sent, or Date Closed for Closed) is updated as follows:
> * If the date for that stage is currently empty, it is stamped with the current date and time.
> * If the date already has a value, it is left alone so its history is not rewritten. 
> 
> Source: [Leads](Leads.md)

**Q2** (8.2 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb`, which is located in your Documents folder and encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the original sample data, follow these steps:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder.
> 3. Start the application again. It will automatically rebuild the file with the original sample data ([Getting started](Getting-Started.md), [Data model](Data-Model.md)).

**Q3** (6.1 s)

> No, you cannot change a proposal after saving it. The document is stored exactly as it was generated. While you can mark it as Accepted or Canceled, you cannot edit it, and a lead cannot be given a second one. 
> 
> To redo a proposal, delete the existing one from the Sales list using the navigator and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (5.6 s)

> To get a file you can open in Excel, use the Export button on the **Marketing** page. It creates a delimited text file with a header row that a spreadsheet can open directly. 
> 
> The Export button on the Accounts and Leads pages saves the data in a format (binary, XML, or JSON) meant to be read back by this application, and is not a spreadsheet file.
> 
> Source: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (4.7 s)

> You can find the lead by using the Search box on the Leads board. 
> 
> Simply type the e-mail address into the Search box. It filters all four columns at once as you type, and matches against the lead's name, account name, office phone, or e-mail address. The search ignores case and matches anywhere inside the value. To get the full board back, just clear the box.
> 
> Source: [Leads](Leads.md)

**Q6** (4.8 s)

> The documentation does not cover this question. I can only assist you with using this application.

**Q7** (4.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (8.4 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi at Apollo Orange, LLC., and added their e-mail address.

### gemini-3.5-flash-lite

**warm-up** (1.4 s)

> Hello! You are currently on the Dashboard screen [Dashboard](Dashboard.md), which displays tiles counting your leads by their status [Dashboard](Dashboard.md). How can I help you use the application today?

**Q1** (1.3 s)

> To move a lead from one column to another on the Leads board, use drag and drop: drag a row from one column and drop it on another [Leads](Leads.md). 
> 
> When you move a lead:
> * The lead takes the status of the column you dropped it on [Leads](Leads.md).
> * If the date for that stage is still empty, it is stamped with the current time (Date Contacted for Active, Date Drafted for Proposal Sent, Date Closed for Closed) [Leads](Leads.md).
> * A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history [Leads](Leads.md).
> * Dropping a lead on the column it is already in does nothing [Leads](Leads.md).

**Q2** (1.0 s)

> Your data is stored in a file named `w10crmdemo.sdb` in your Documents folder, which is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md) [Data model](Data-Model.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md) [Data model](Data-Model.md).
> 3. Start the application again [Getting started](Getting-Started.md) [Data model](Data-Model.md).

**Q3** (1.2 s)

> No, you cannot change a proposal after saving it. The document is stored as it was generated, and you cannot edit it [FAQ](FAQ.md).

**Q4** (1.0 s)

> The export on the Marketing page writes a delimited text file with a header row, which a spreadsheet can open directly ([FAQ](FAQ.md)). In contrast, the export on the Accounts page saves the table in FireDAC's own binary, XML, or JSON format to be read back by the application ([Accounts](Accounts.md), [FAQ](FAQ.md)).

**Q5** (0.9 s)

> You can find a lead by its e-mail address using the Search box on the Leads board. As you type, the search box filters all four columns at once, matching anywhere inside the value against the lead's name, account name, office phone, or e-mail [Leads](Leads.md).

**Q6** (1.0 s)

> The documentation and application features do not cover weather information, so I cannot answer this question.

**Q7** (1.5 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (1.2 s)

- action `create_lead` {"email":"mario.rossi@example.com","name":"Mario Rossi","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> Created the lead Mario Rossi.

