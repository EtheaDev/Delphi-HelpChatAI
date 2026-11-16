# HelpChatAI provider benchmark

Run on 2026-11-16 18:57. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 16.1 s | 8 | 0 | 3.6 s | 2.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 20.5 s | 8 | 0 | 3.7 s | 2.9 s | 100% (8/8) | 100% (11/11) | 88% (7/8) |
| qwen3-coder:30b | 30.6 s | 8 | 0 | 4.0 s | 1.9 s | 100% (8/8) | 100% (11/11) | 88% (7/8) |
| claude | 0.9 s | 8 | 0 | 1.9 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 0.9 s | 8 | 0 | 1.7 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.0 s | 8 | 0 | 2.2 s | 1.2 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 1.8 s | 8 | 0 | 2.4 s | 1.2 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini | 1.1 s | 8 | 0 | 1.3 s | 1.1 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-argon | 3.3 s | 8 | 0 | 10.7 s | 9.7 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-carbon | 5.1 s | 8 | 0 | 14.0 s | 13.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-pro-latest | 3.8 s | 8 | 0 | 6.1 s | 5.7 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-3.5-flash-lite | 1.2 s | 8 | 0 | 1.1 s | 0.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-6-luna | 1.8 s | 8 | 0 | 2.3 s | 1.7 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-6.1-sol | 1.4 s | 8 | 0 | 3.0 s | 2.0 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 4.8 s | 3.1 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 5.6 s | 3.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 5.1 s | 1.9 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude | 2.1 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 2.1 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 2.5 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 3.3 s | 1.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini | 1.5 s | 1.1 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-argon | 7.3 s | 5.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-carbon | 8.2 s | 6.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-pro-latest | 5.3 s | 4.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-3.5-flash-lite | 1.3 s | 0.9 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-6-luna | 1.2 s | 0.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-6.1-sol | 3.5 s | 1.4 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 4.3 s | 3.3 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 3.5 s | 2.2 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 3.8 s | 1.8 s | - | yes | 3/3 | - | yes |
| Q2 | claude | 2.3 s | 1.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 2.0 s | 1.3 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 2.2 s | 0.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 3.1 s | 1.1 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini | 1.0 s | 0.7 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-argon | 6.7 s | 5.5 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-carbon | 11.7 s | 10.8 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-pro-latest | 6.4 s | 5.8 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-3.5-flash-lite | 0.9 s | 0.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-6-luna | 2.4 s | 1.7 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-6.1-sol | 3.4 s | 1.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 3.2 s | 2.6 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 2.4 s | 1.6 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | qwen3-coder:30b | 3.3 s | 1.7 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude | 1.7 s | 1.2 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 1.6 s | 1.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.6 s | 1.3 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 2.3 s | 0.6 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini | 0.8 s | 0.6 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-argon | 4.3 s | 3.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-carbon | 8.0 s | 7.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-pro-latest | 4.8 s | 4.4 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-3.5-flash-lite | 0.9 s | 0.7 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-6-luna | 2.4 s | 1.8 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-6.1-sol | 3.1 s | 2.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 4.3 s | 3.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 3.1 s | 2.2 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 6.6 s | 2.0 s | - | yes | 1/1 | open_screen | **no** |
| Q4 | claude | 1.7 s | 1.3 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 1.7 s | 1.2 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 2.3 s | 1.3 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.1 s | 0.9 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini | 1.3 s | 1.2 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-argon | 6.6 s | 5.4 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-carbon | 9.9 s | 9.1 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-pro-latest | 6.0 s | 5.5 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gemini-3.5-flash-lite | 0.7 s | 0.6 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-6-luna | 2.0 s | 1.2 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-6.1-sol | 2.4 s | 1.5 s | FAQ.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 3.4 s | 2.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 2.3 s | 1.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 4.1 s | 1.9 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude | 1.5 s | 1.1 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.5 s | 1.0 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.4 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 2.3 s | 0.9 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini | 0.9 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-argon | 18.0 s | 17.0 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-carbon | 12.3 s | 11.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-pro-latest | 5.0 s | 4.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-3.5-flash-lite | 0.8 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-6-luna | 2.1 s | 1.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-6.1-sol | 2.2 s | 1.2 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 3.1 s | 3.0 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.5 s | 1.4 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 2.4 s | 1.3 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 2.5 s | 2.1 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 2.4 s | 1.8 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 2.1 s | 1.1 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.5 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 0.9 s | 0.8 s | Home.md | yes | 0/0 | - | yes |
| Q6 | gemini-4-argon | 3.2 s | 2.7 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-4-carbon | 4.9 s | 4.8 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-pro-latest | 4.2 s | 3.9 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-3.5-flash-lite | 0.7 s | 0.6 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-6-luna | 1.6 s | 1.2 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-6.1-sol | 2.1 s | 1.6 s | - | yes | 0/0 | - | yes |
| Q7 | gemma4:12b | 2.4 s | 2.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 1.7 s | 1.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 2.7 s | 2.0 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 1.2 s | 1.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 1.0 s | 1.0 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.7 s | 1.7 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 2.1 s | 2.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 2.1 s | 2.0 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-argon | 9.6 s | 9.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-carbon | 12.0 s | 11.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-pro-latest | 8.9 s | 8.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-3.5-flash-lite | 1.9 s | 1.9 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-6-luna | 4.4 s | 4.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-6.1-sol | 3.8 s | 3.6 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 3.0 s | 2.7 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 9.9 s | 9.7 s | - | yes | 0/0 | - | **no** |
| Q8 | qwen3-coder:30b | 3.8 s | 3.0 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude | 2.0 s | 1.8 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 1.7 s | 1.4 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.4 s | 2.4 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 2.7 s | 2.7 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 1.7 s | 1.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-argon | 30.2 s | 29.8 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-carbon | 45.2 s | 44.9 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-pro-latest | 7.8 s | 7.8 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-3.5-flash-lite | 1.5 s | 1.4 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-6-luna | 2.1 s | 1.7 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-6.1-sol | 3.2 s | 2.8 s | - | yes | 0/0 | create_lead | yes |

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

**warm-up** (16.1 s)

> Hello! How can I help you with the application today? You are currently on the **Dashboard** screen.

**Q1** (4.8 s)

> To move a lead between columns on the board, you can use **drag and drop**:
> 
> 1. Drag a row from one column and drop it on another.
> 2. The lead will take the status of the column you dropped it on.
> 
> **How dates are handled:**
> * If the date for that stage is currently empty, it will be automatically stamped with the current date (e.g., moving to **Active** stamps the **Date Contacted**, moving to **Proposal Sent** stamps the **Date Drafted**, and moving to **Closed** stamps the **Date Closed**).
> * If the date already has a value, it is left alone so that moving a lead back and forth does not overwrite its history.
> * Dropping a lead on the column it is already in will have no effect.
> 
> Source: [Leads](Leads.md)

**Q2** (4.3 s)

> Your data is stored in an SQLite file named `w10crmdemo.sdb` located in your Documents folder, which is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data, you must:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again, which will rebuild the file with the sample data [Getting started](Getting-Started.md) [Data model](Data-Model.md).

**Q3** (3.2 s)

> No, you cannot change a proposal after it has been saved because the document is stored exactly as it was generated. [FAQ](FAQ.md)
> 
> To redo a proposal, you must delete the existing one from the Sales list using the navigator and then create a new one. [FAQ](FAQ.md)

**Q4** (4.3 s)

> To get a file that you can open in Excel, you should use the export on the **Marketing** page, which writes a delimited text file. The exports on the Accounts and Leads pages are in a format meant to be read back by the application, not for use in spreadsheets.
> 
> Source: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (3.4 s)

> To find a lead by its e-mail address, use the **Search box** on the Leads screen. As you type into this box, it filters all four columns (including e-mail) and matches any value regardless of case.
> 
> Source: [Leads](Leads.md)

**Q6** (3.1 s)

> I'm sorry, but the documentation does not provide information about the weather.

**Q7** (2.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (3.0 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi at Apollo Orange, LLC. with the email mario.rossi@example.com.

### gpt-oss:20b

**warm-up** (20.5 s)

> Hello! I’m here to help you navigate the CRM Demo. If you have a question or need guidance on any part of the application, just let me know!

**Q1** (5.6 s)

> Move a lead by **drag‑and‑drop**:
> 
> 1. Click on the lead’s row in the current column.  
> 2. Drag it to the column you want it to move to.  
> 3. Drop it – the lead’s status changes to that column’s status.
> 
> What happens to dates  
> - The column you drop the lead into determines which date field is set.  
> - If that date is still empty, it’s stamped with *now* (e.g. dropping into *Active* writes *Date Contacted*).  
> - If the date already has a value, it’s left unchanged, so moving back and forth never rewrites history.  
> - Dropping a lead onto the same column it’s already in does nothing.
> 
> > *“Moving a lead: drag and drop … Two things happen: the lead takes the status of the column you dropped it on; if the date of that stage is still empty, it is stamped with now … A date that already has a value is left alone … Dropping a lead on the column it already is in does nothing.”*  
> > *(Source: [Leads](Leads.md))*

**Q2** (3.5 s)

> Your data lives in a single SQLite file called **`w10crmdemo.sdb`** in your Documents folder. It’s encrypted with AES‑256.
> 
> To reset the database to the original sample data:
> 
> 1. Close the application.  
> 2. Delete the `w10crmdemo.sdb` file from the Documents folder.  
> 3. Restart the app; it will recreate the file, copy the sample data, and show the Dashboard again.  
> 
> > **Sources**  
> > • [Getting started](Getting-Started.md)  
> > • [Data model](Data-Model.md)

**Q3** (2.4 s)

> No. Once a proposal is saved the document is stored exactly as it was generated. You can only change its status (Accepted or Canceled); you cannot edit the content. To redo a proposal you must delete the existing one from the Sales list and create a new one.  
> 
> Source: [FAQ](FAQ.md)

**Q4** (3.1 s)

> To get a file that Excel can open, use the **Marketing page export**.  
> It writes a delimited text file with a header row that spreadsheets (like Excel) read directly.  
> The exports on the Accounts and Leads pages use FireDAC’s own format, which is not a spreadsheet file.  
> 
> Sources:  
> - [Accounts](Accounts.md)  
> - [FAQ](FAQ.md)

**Q5** (2.3 s)

> Use the **Search** box on the Leads board.  
> Just type the lead’s e‑mail address into the box and press Enter – the board will filter to show any lead whose e‑mail (or name, account, or phone) contains that string.  
> *Source: [Leads](Leads.md)*

**Q6** (1.5 s)

> I’m sorry, but I can’t answer that.

**Q7** (1.7 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> **Accounts screen opened.**

**Q8** (9.9 s)

> I need the office phone number for the new lead. Could you please provide it?

### qwen3-coder:30b

**warm-up** (30.6 s)

- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> Hello! I can help you with using this CRM application. 
> 
> The Dashboard screen shows you counts of leads organized by status:
> - New Leads (not contacted yet)
> - Active Leads (being worked on)
> - Proposal Sent (waiting for an answer)
> - Closed Leads (won or lost)
> - Inactive Leads (parked)
> 
> Each count is filtered by the currently selected user in the dropdown at the top. The totals are refreshed when you return to the Dashboard from another screen.
> 
> Would you like me to help you with anything specific on the Dashboard or navigate you to another section?
> 
> I've opened the Leads screen for you. This is where you can see and manage all your leads in a board format, organized by their status. You can move leads between different status columns (New, Active, Proposal Sent, Closed, Inactive) as you work with them.
> 
> Is there anything specific you'd like to do with the leads now? For example, creating a new lead or changing the status of an existing one?

**Q1** (5.1 s)

> To move a lead from one column to another on the Leads board, you **drag and drop** the lead row from one column to another.
> 
> When you do this:
> - The lead takes the **status** of the column you dropped it into.
> - If the date field for that stage is **empty**, it gets stamped with the current date (for example, **Date Contacted** when moving to Active, **Date Drafted** when moving to Proposal Sent, or **Date Closed** when moving to Closed).
> - If the date field already has a value, it is **left unchanged**, so moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it already is in does nothing.
> 
> The lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (3.8 s)

> Your data is stored in a single SQLite file named **w10crmdemo.sdb**, located in your **Documents** folder. This file is encrypted with AES-256.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete the file **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again.
> 
> The application will recreate the file with the original sample data, including 8 leads, 8 accounts, one user, and three proposals.

**Q3** (3.3 s)

> According to the documentation, **no**, you cannot change a proposal after saving it.
> 
> The document is stored as it was generated. You can mark it as **Accepted** or **Canceled**, but not edit it. The lead also cannot be given a second proposal. If you need to make changes, you must delete the existing proposal from the Sales list and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (6.6 s)

- action `open_screen` {"name":"Marketing"} -> Opened the Marketing screen.

> According to the documentation, the export on the **Marketing** page writes a delimited text file with a header row, which can be opened directly in Excel. The exports on the **Accounts** and **Leads** pages write FireDAC's own format, meant to be read back by the application.
> 
> To perform this export:
> 1. Go to the **Marketing** screen.
> 2. Use the export function there to save the data as a text file.
> 
> On the Marketing screen, you can use the export function to save the data as a delimited text file with a header row. This type of file can be opened directly in Excel.
> 
> To export:
> 1. Use the export option available on this screen.
> 2. Choose a location and filename for the exported file.
> 3. The file will be saved in a format that Excel can open directly.
> 
> This is different from the exports available on the Accounts or Leads screens, which write in FireDAC's own format meant only for reading back into this application.

**Q5** (4.1 s)

> To find a lead using its email address on the **Leads** screen:
> 
> 1. Use the **Search box** at the top of the screen.
> 2. Type the email address into the Search box.
> 3. The leads matching the email will be shown in the four columns.
> 
> The search matches against the lead's name, account name, office phone, or email — so typing an email address will filter the results accordingly. Clear the box to see all leads again.
> 
> No action needed from you; this is how the search works on the Leads board.<tool_call>
> 
> Source: [Leads](Leads.md)

**Q6** (2.4 s)

> I cannot provide weather information or any data outside the application's functionality. The application helps manage leads, accounts, users, and related CRM tasks, but does not include a weather feature.
> 
> To check the weather in Milan, you would need to use a dedicated weather service or application.<tool_call>

**Q7** (2.7 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open. You can view and manage the companies associated with your leads here. Let me know if you need to perform any specific actions on this screen.

**Q8** (3.8 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> The lead for **Mario Rossi** at **Apollo Orange, LLC.** has been created successfully. The detail window for this lead is now open, where you can fill in additional information if needed.

### claude

**warm-up** (0.9 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, including the Dashboard, Leads, Accounts, Sales, Marketing, Calendar and Users screens. What would you like to know?

**Q1** (2.1 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on. The four lists refresh after each move, and the lead stays selected. ([Leads](Leads.md))
> 
> Dates work like this:
> 
> - If the date for the new stage is still empty, it is stamped with the current time. Moving to **Active** fills Date Contacted, moving to **Proposal Sent** fills Date Drafted, and moving to **Closed** fills Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.

**Q2** (2.3 s)

> Your data is stored in one SQLite file, **w10crmdemo.sdb**, in your Documents folder. The file is encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again. It rebuilds the file with the sample data and opens the Dashboard ([Getting started](Getting-Started.md)).
> 
> Deleting the file removes all of your current changes. The application has no undo, so back up the file first if you want to keep anything ([Data model](Data-Model.md)).

**Q3** (1.7 s)

> No. A saved proposal is stored as it was generated, so you can't edit it. You can mark it Accepted or Canceled, but not change its content. To redo it, delete the existing proposal from the Sales list with the navigator, then create a new one. The lead can't have a second proposal while the first one exists. ([FAQ](FAQ.md))

**Q4** (1.7 s)

> Use the **Marketing** page export. It writes a delimited text file with a header row, which a spreadsheet opens directly. The Accounts export does not work for Excel: it writes FireDAC's own binary, XML or JSON format, meant to be read back by this application.
> 
> To get the file:
> 1. Open the **Marketing** screen.
> 2. Use its export button.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.5 s)

> On the Leads screen, type the e-mail address, or any part of it, into the **Search** box. It filters all four columns as you type, and it matches against the lead's name, account name, office phone and e-mail. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (2.5 s)

> I can't help with that. I'm the help assistant for this CRM application, and its documentation doesn't cover weather. I can explain how to use the app, for example how to read the Dashboard tiles or manage users and leads.

**Q7** (1.2 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.0 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. Its status is New, and its detail window should be open so you can fill in the rest.

### claude-haiku-5-5

**warm-up** (0.9 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, for example how the Dashboard counters work, how users filter what you see, or how to navigate the sections. What would you like to know?

**Q1** (2.1 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates change as follows:
> 
> - If the date for the new stage is still empty, it is stamped with the current date and time. Moving to **Active** fills Date Contacted, moving to **Proposal Sent** fills Date Drafted, and moving to **Closed** fills Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> After each move the four lists refresh, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.0 s)

> Your data is stored in one SQLite file, **w10crmdemo.sdb**, in your Documents folder. The file is encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To start over with the sample data:
> 
> 1. Close the application.
> 2. Delete **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data ([Getting started](Getting-Started.md)).
> 
> Deleting the file cannot be undone. The application has no rollback and almost no delete confirmation ([Data model](Data-Model.md)).

**Q3** (1.6 s)

> No. The proposal is stored as it was generated, so you can't edit it after saving. You can mark it **Accepted** or **Canceled**, but not change its content. The lead also can't get a second proposal.
> 
> To redo it, delete the existing proposal from the Sales list using the navigator, then create a new one. ([FAQ](FAQ.md))

**Q4** (1.7 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which a spreadsheet opens directly. ([FAQ](FAQ.md))
> 
> The export on the **Accounts** page is not a spreadsheet file. It uses FireDAC's own binary, XML, or JSON format, depending on the extension you give it, and is meant to be read back by this application. ([Accounts](Accounts.md))

**Q5** (1.5 s)

> On the Leads board, type the e-mail address, or part of it, into the **Search** box. The four columns filter as you type. The search matches, ignoring case, against the lead's name, account name, office phone and e-mail, so a partial address such as `example.com` also works. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (2.4 s)

> I can't help with that. I'm the help assistant for this CRM application, and its documentation doesn't cover weather information. I can help with things like reading the Dashboard tiles, managing users, or the main window layout.

**Q7** (1.0 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (1.7 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It has status New.

### claude-sonnet-5-5

**warm-up** (1.0 s)

> Hello! I can help you use this CRM application: the Dashboard, Accounts, Leads, Sales, Marketing, Calendar and Users screens. What would you like to know?

**Q1** (2.5 s)

> To move a lead, drag its row from one column and drop it on another. Two things happen:
> 
> 1. **The status changes.** The lead takes the status of the column you dropped it on.
> 2. **The stage date may be stamped.** If the date for that stage is still empty, it is set to now:
>    - Moving to **Active** stamps *Date Contacted*.
>    - Moving to **Proposal Sent** stamps *Date Drafted*.
>    - Moving to **Closed** stamps *Date Closed*.
> 
> If a date already has a value, it is left alone. Moving a lead back and forth therefore doesn't rewrite its history.
> 
> - Dropping a lead on the column it is already in does nothing.
> - The four lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.2 s)

> **Where it's stored:** Everything is in one SQLite file, `w10crmdemo.sdb`, in your Documents folder. It is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **To start over with the sample data:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user and three proposals. ([Getting started](Getting-Started.md))
> 
> Resetting is the only way to undo changes. The application has no transaction you can roll back, so everything you added or changed is lost. ([Data model](Data-Model.md))

**Q3** (2.6 s)

> No. A saved proposal is stored exactly as it was generated, so you can't edit it. You can only mark it **Accepted** or **Canceled**. A lead also can't be given a second proposal.
> 
> To redo a proposal:
> 1. Delete the existing one from the Sales list with the navigator.
> 2. Create a new one.
> 
> Nothing is locked after a proposal is accepted. Complete and Cancel can be applied again later.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.3 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet can open that file directly.
> 
> The exports on the Accounts and Leads pages don't work for this. They write FireDAC's own format (binary, XML or JSON, depending on the extension you give). That format is meant to be read back by this application, and it isn't a spreadsheet file.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.4 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or just part of it, into the Search box.
> 2. The four columns filter at once as you type. The match ignores case and works anywhere inside the value, so `example.com` finds everybody with that domain.
> 3. To see the whole board again, clear the box.
> 
> Search also matches the lead's name, account name and office phone.
> 
> Source: [Leads](Leads.md)

**Q6** (2.1 s)

> I can't help with that. I only explain how to use this CRM application, and the documentation doesn't cover weather. If you have a question about the Dashboard, Accounts, Leads, Sales, Marketing, Calendar or Users screens, I'm happy to help.

**Q7** (1.7 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I've opened the Accounts screen.

**Q8** (2.4 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. According to the manual, a new lead starts with the status New and its detail window opens so you can fill in the rest. I didn't add a phone number or notes because you didn't give any.
> 
> Source: [Asking the assistant](Assistant.md)

### claude-opus-5-5

**warm-up** (1.8 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard** right now. It has one tile for each lead status (New, Active, Proposal Sent, Closed, Inactive) plus a Total, and they count the leads of the active user.
> 
> You can ask me how to do something in the application, or ask me to do it for you. For example, I can open a screen or create a new lead for an existing account. What would you like to do?

**Q1** (3.3 s)

> To move a lead on the **Leads** board, **drag its row from one column and drop it on another**.
> 
> When you drop it:
> 
> 1. **The status changes.** The lead takes the status of the column you dropped it on.
> 2. **The date for that stage is filled in, but only if it's empty.** It gets the current date and time:
>    - Moving to **Active** fills in **Date Contacted**
>    - Moving to **Proposal Sent** fills in **Date Drafted**
>    - Moving to **Closed** fills in **Date Closed**
> 3. **Dates that already have a value stay as they are.** Moving a lead back and forth doesn't rewrite its history.
> 
> Also:
> - Dropping a lead on the column it's already in does nothing.
> - All four columns refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (3.1 s)

> **Where your data is stored**
> 
> Everything is in one SQLite file called `w10crmdemo.sdb` in your **Documents** folder. The file is encrypted with AES-256. The application creates it the first time you run it and opens it on every later run. ([Data model](Data-Model.md), [Getting started](Getting-Started.md))
> 
> **How to start over with the sample data**
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (`CRMUser`) and three proposals.
> 
> **Before you delete the file:** Resetting removes all your changes, and this is the only way to undo anything. The application has no rollback, and most deletes don't ask for confirmation. ([Data model](Data-Model.md))

**Q3** (2.3 s)

> No, you can't edit a proposal once it's saved. The document is stored exactly as it was generated. You can only change its status:
> 
> - **Complete** sets it to Accepted.
> - **Cancel** sets it to Canceled.
> 
> Neither button asks for confirmation. You can apply either one again later, because accepting a proposal doesn't lock it.
> 
> A lead can only have one proposal. To redo one:
> 1. Delete the existing proposal from the Sales list with the navigator.
> 2. Create a new proposal for the lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.1 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet like Excel opens that directly.
> 
> The **Export** button on this Accounts screen won't give you that. It saves the whole table in FireDAC's own format (binary, XML or JSON depending on the extension you type), and that file is meant to be read back by this application. The export on the Leads page works the same way. ([Accounts](Accounts.md), [FAQ](FAQ.md))

**Q5** (2.3 s)

> Use the **Search** box on the Leads board:
> 
> 1. Type the e-mail address, or just part of it, in the **Search** box.
> 2. All four columns filter as you type. The search ignores case and matches text anywhere in the lead's name, account name, office phone or e-mail. For example, typing `example.com` finds every lead with that domain.
> 3. To open the lead, double-click its row, or select it and press **View Lead**.
> 4. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (1.5 s)

> I can't help with the weather. I only answer questions about using this CRM application, and its documentation doesn't cover weather or any other outside information.
> 
> I can explain things in the app, like what the **Dashboard** tiles count or how to create a lead.

**Q7** (2.1 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The **Accounts** screen is open now.

**Q8** (2.7 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.**, with the e-mail `mario.rossi@example.com`.
> 
> It goes on the Leads board with the status **New**, and its detail window opens so you can add anything else, like an office phone ([Asking the assistant](Assistant.md)).

### gemini

**warm-up** (1.1 s)

> Hello! How can I help you use the application today?

**Q1** (1.5 s)

> You can move a lead by dragging and dropping a row from one column to another [Leads](Leads.md). 
> 
> When you move a lead:
> * The lead takes the status of the column you dropped it on [Leads](Leads.md).
> * If the date for that stage is still empty, it is stamped with the current time (`Date Contacted` when moving to Active, `Date Drafted` when moving to Proposal Sent, and `Date Closed` when moving to Closed) [Leads](Leads.md).
> * A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history [Leads](Leads.md).
> * Dropping a lead on the column it is already in does nothing [Leads](Leads.md).

**Q2** (1.0 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md).
> 3. Start the application again [Getting started](Getting-Started.md).

**Q3** (0.8 s)

> No, you cannot change a proposal after saving it. The document is stored as it was generated; you can mark it as Accepted or Canceled, but you cannot edit it, and a lead cannot be given a second one. To redo a proposal, delete the existing one from the Sales list with the navigator and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (1.3 s)

> For something you can open in Excel, use the export on the Marketing page, which writes a delimited text file with a header row [[Accounts](Accounts.md), [FAQ](FAQ.md)].

**Q5** (0.9 s)

> You can use the **Search** box to find a lead by its e-mail address. As you type, the search box filters all four columns at once, matching anywhere inside the e-mail (or the lead's name, account name, or office phone) while ignoring case [Leads](Leads.md).

**Q6** (0.9 s)

> I am sorry, but the application documentation does not contain information about the weather, as this is a customer-relationship manager [CRM Demo](Home.md).

**Q7** (2.1 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (1.7 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead Mario Rossi for Apollo Orange, LLC.

### gemini-4-argon

**warm-up** (3.3 s)

> Hello! How can I help you use the application today? You are currently on the **Dashboard** screen. Let me know if you have any questions or if there is something you would like to do.

**Q1** (7.3 s)

> To move a lead on the **Leads** board, simply **drag a row from one column and drop it onto another**. 
> 
> When you drop a lead into a new column:
> 1. The lead takes the status of the column you dropped it on, the four lists refresh, and the lead stays selected. (Dropping a lead onto the column it is already in does nothing.)
> 2. **If the date for that new stage is still empty, it is stamped with the current date and time (`now`)**:
>    - Moving to **Active** stamps **Date Contacted**.
>    - Moving to **Proposal Sent** stamps **Date Drafted**.
>    - Moving to **Closed** stamps **Date Closed**.
> 3. **If a stage's date already has a value, it is left alone**, so moving a lead back and forth does not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (6.7 s)

> All data is stored in a single SQLite file named `w10crmdemo.sdb` inside your **Documents** folder, encrypted with AES-256.
> 
> To restore the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again — it will automatically recreate the file with the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (4.3 s)

> No. Once a proposal is saved, the document is stored as it was generated and cannot be edited (though you can still mark it as **Accepted** or **Canceled**). Also, a lead cannot be given a second proposal. 
> 
> To redo a proposal:
> 1. Delete the existing one from the **Sales** list using the navigator.
> 2. Create a new proposal for the lead.
> 
> Source: [FAQ](FAQ.md)

**Q4** (6.6 s)

> Use the export on the **Marketing** page: it writes a delimited text file with a header row that a spreadsheet like Excel can open directly.
> 
> By contrast, the **Export** buttons on the **Accounts** and **Leads** pages save files in FireDAC's own format (binary, XML, or JSON), which is meant to be read back by this application rather than opened in a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (18.0 s)

> Use the **Search** box on the **Leads** screen:
> 
> 1. Type the e-mail address (or part of it) into the **Search** box.
> 2. All four columns will filter automatically as you type, matching against the lead's name, account name, office phone, or e-mail address (ignoring case).
> 3. Clear the **Search** box to bring back the full board.
> 
> Source: [Leads](Leads.md)

**Q6** (3.2 s)

> I cannot answer that question. I am the in-app help assistant and can only explain how to use this application based on its documentation.

**Q7** (9.6 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen for you.

**Q8** (30.2 s)

- action `create_lead` {"email":"mario.rossi@example.com","name":"Mario Rossi","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> I have created the lead **Mario Rossi** for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`.

### gemini-4-carbon

**warm-up** (5.1 s)

> Hello! I am Assistant, your in-app help assistant. How can I help you use the application today?

**Q1** (8.2 s)

> To move a lead, drag its row from one column and drop it onto another. When you do this:
> 
> 1. The lead takes the status of the new column, the four lists refresh, and the dragged lead stays selected (dropping it onto the column it is already in does nothing).
> 2. If the date field for that stage is still empty, it is stamped with the current date and time:
>    - **Active**: `Date Contacted`
>    - **Proposal Sent**: `Date Drafted`
>    - **Closed**: `Date Closed`
> 3. If that stage's date already has a value, it is left unchanged, so moving a lead back and forth does not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (11.7 s)

> All your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb` in your **Documents** folder.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again — it will automatically recreate the file with the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (8.0 s)

> No, you cannot edit a proposal after saving it. The document is stored as it was generated, and a lead cannot be given a second proposal—you can only mark it **Accepted** or **Canceled**.
> 
> To redo a proposal:
> 1. Delete the existing one from the **Sales** list using the navigator.
> 2. Create a new proposal for that lead.
> 
> Source: [FAQ](FAQ.md)

**Q4** (9.9 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row that Excel can open directly.
> 
> By contrast, the **Export** button here on the **Accounts** screen (and on the **Leads** page) saves data in FireDAC's own format, which is meant to be read back by this application rather than opened as a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (12.3 s)

> Type the e-mail address (or part of it) into the **Search** box on the **Leads** screen. 
> 
> As you type, it filters all four columns at once, matching anywhere inside the e-mail address regardless of case. Clear the box when you want to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (4.9 s)

> I cannot check the weather. I am the in-app help assistant for this CRM application, and I can only help explain how to use it.

**Q7** (12.0 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen.

**Q8** (45.2 s)

- action `create_lead` {"email":"mario.rossi@example.com","account":"Apollo Orange, LLC.","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead **Mario Rossi** (ID 101) for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`.

### gemini-pro-latest

**warm-up** (3.8 s)

> Hello! I am the in-app help assistant. How can I help you with the application today?

**Q1** (5.3 s)

> To move a lead from one column to another, drag its row from the current column and drop it onto the new one. 
> 
> When you drop the lead:
> * The lead takes the status of the new column.
> * If the date for that new stage is empty, it is stamped with the current date and time (for example, Date Contacted when moving to Active). 
> * If the date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history. 
> 
> Source: [Leads](Leads.md)

**Q2** (6.4 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb`, which is located in your Documents folder and encrypted with AES-256.
> 
> To start over with the original sample data, follow these steps:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder.
> 3. Start the application again. The file will automatically be rebuilt with the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (4.8 s)

> No, you cannot change a proposal after saving it. The document is stored exactly as it was generated. You can mark it as Accepted or Canceled, but you cannot edit it, and a lead cannot be given a second proposal. 
> 
> To redo a proposal, you must delete the existing one from the Sales list with the navigator and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (6.0 s)

> To get a file you can open in Excel, you should use the export on the **Marketing** page. It writes a delimited text file with a header row that a spreadsheet can open directly (Source: [FAQ](FAQ.md)). 
> 
> The export button on the Accounts (and Leads) page writes the data in FireDAC's own format, which is meant to be read back by this application and is not a spreadsheet file (Source: [Accounts](Accounts.md)).

**Q5** (5.0 s)

> You can find the lead using the **Search** box on the Leads board. 
> 
> Simply type the e-mail address (or even a part of it, like the domain name) into the Search box. It will automatically filter all four columns as you type to show matching leads. To see the full board again, just clear the box.
> 
> Source: [Leads](Leads.md)

**Q6** (4.2 s)

> I am sorry, but the documentation does not cover that. I can only answer questions about how to use this CRM application.

**Q7** (8.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (7.8 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","name":"Mario Rossi","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi.

### gemini-3.5-flash-lite

**warm-up** (1.2 s)

> Hello! How can I help you use the application today?

**Q1** (1.3 s)

> To move a lead from one column to another, drag a row from one column and drop it on another [Leads](Leads.md). 
> 
> When you do this, two things happen:
> 1. The lead takes the status of the column you dropped it on [Leads](Leads.md).
> 2. If the date of that stage is still empty, it is stamped with the current time (e.g., Date Contacted for Active, Date Drafted for Proposal Sent, and Date Closed for Closed). A date that already has a value is left alone [Leads](Leads.md).
> 
> Source: [Leads](Leads.md)

**Q2** (0.9 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, and it is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md).
> 3. Start the application again, and the file will be rebuilt with the original sample data [Getting started](Getting-Started.md).

**Q3** (0.9 s)

> No, you cannot change a proposal after saving it. The document is stored as it was generated. While you can mark it as Accepted or Canceled, you cannot edit it, and a lead cannot be given a second one. To redo a proposal, delete the existing one from the Sales list with the navigator and create a new one ([FAQ](FAQ.md)).

**Q4** (0.7 s)

> The export on the Marketing page writes a delimited text file with a header row, which a spreadsheet opens directly [Source: [FAQ](FAQ.md)].

**Q5** (0.8 s)

> You can use the **Search** box at the top of the Leads board. As you type, it filters all four columns at once, matching anywhere inside the e-mail address (for example, typing `example.com` finds everyone with that domain) [Leads](Leads.md).

**Q6** (0.7 s)

> The documentation excerpts do not cover the weather.

**Q7** (1.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (1.5 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","name":"Mario Rossi","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead Mario Rossi for Apollo Orange, LLC.

### gpt-6-luna

**warm-up** (1.8 s)

> Hello! What can I help you with in the CRM?

**Q1** (1.2 s)

> Drag the lead’s row from its current column and drop it in the destination column. Its status changes to match the new column. If the date for that stage is empty, it is stamped with the current date and time; if it already has a value, it stays unchanged. Dropping it in its current column does nothing. [Leads](Leads.md)

**Q2** (2.4 s)

> Your data is stored in the encrypted `w10crmdemo.sdb` file in your Documents folder. To restore the original sample data, close the application, delete that file, then start the application again. [Data model](Data-Model.md) · [Getting started](Getting-Started.md)

**Q3** (2.4 s)

> No. A saved proposal can’t be edited. You can mark it Accepted or Canceled, but to redo it, delete the existing proposal from the Sales list with the navigator and create a new one. [FAQ](FAQ.md)

**Q4** (2.0 s)

> Use the export on the **Marketing** page. It creates a delimited text file with a header row that a spreadsheet can open. The export on Accounts saves the whole table in the application’s FireDAC format, not as a spreadsheet file. [FAQ](FAQ.md)

**Q5** (2.1 s)

> Type the e-mail address into the **Search** box. It filters all four columns as you type and matches e-mail addresses regardless of case. Clear the box to show the full board again. [Leads](Leads.md)

**Q6** (1.6 s)

> The app documentation doesn’t cover weather, so I can’t provide today’s forecast for Milan.

**Q7** (4.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is open.

**Q8** (2.1 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** for **Apollo Orange, LLC.** with email **mario.rossi@example.com**.

### gpt-6.1-sol

**warm-up** (1.4 s)

> Hello! How can I help you use the application?

**Q1** (3.5 s)

> On the **Leads** board, drag the lead’s row from its current column and drop it into the destination column. Its status changes to match that column.
> 
> If the destination stage’s date is empty, it is stamped with the current date and time:
> - **Active:** Date Contacted
> - **Proposal Sent:** Date Drafted
> - **Closed:** Date Closed
> 
> Existing dates are left unchanged, so moving a lead back and forth does not rewrite its history. Dropping it into its current column does nothing. [Leads](Leads.md)

**Q2** (3.4 s)

> Your data is stored in **`w10crmdemo.sdb` in your Documents folder**, a SQLite file encrypted with AES-256. [Data model](Data-Model.md)
> 
> To start over:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again—it rebuilds the file with the original sample data.
> 
> **This removes your current data**, so only do this if you want a complete reset. [Getting started](Getting-Started.md)

**Q3** (3.1 s)

> No—you can’t edit a saved proposal. Its document is stored exactly as generated. You can only mark it **Accepted** or **Canceled**.
> 
> To redo it, delete the existing proposal from the **Sales** list using the navigator, then create a new one. A lead cannot have a second proposal while the existing one remains. [FAQ](FAQ.md)

**Q4** (2.4 s)

> Use the export on the **Marketing** page: it creates a delimited text file with a header row that Excel can open directly. The **Accounts** export writes FireDAC’s own format, not a spreadsheet file. [FAQ](FAQ.md)

**Q5** (2.2 s)

> On the **Leads** screen, type the e-mail address into the **Search** box. It filters all four columns as you type; a partial address such as `example.com` also works, and matching ignores case. Clear the box to show the full board again. [Leads](Leads.md)

**Q6** (2.1 s)

> I can only help with this application, and the provided documentation doesn’t cover weather information.

**Q7** (3.8 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (3.2 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** for **Apollo Orange, LLC.**, with email **mario.rossi@example.com**.

