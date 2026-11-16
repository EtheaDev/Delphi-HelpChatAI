# HelpChatAI provider benchmark

Run on 2026-11-16 21:51. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 19.1 s | 8 | 0 | 3.6 s | 3.1 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 22.7 s | 8 | 0 | 2.9 s | 2.1 s | 100% (8/8) | 100% (11/11) | 88% (7/8) |
| qwen3-coder:30b | 32.5 s | 8 | 0 | 3.7 s | 1.0 s | 100% (8/8) | 100% (11/11) | 88% (7/8) |
| claude | 2.6 s | 8 | 0 | 1.8 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 1.3 s | 8 | 0 | 1.8 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 1.5 s | 8 | 0 | 1.9 s | 0.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 1.7 s | 8 | 0 | 2.7 s | 1.4 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini | 1.3 s | 8 | 0 | 1.0 s | 0.8 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-argon | 4.1 s | 8 | 0 | 8.5 s | 7.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-carbon | 5.9 s | 8 | 0 | 15.6 s | 14.7 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-pro-latest | 4.9 s | 8 | 0 | 6.1 s | 5.7 s | 100% (8/8) | 91% (10/11) | 100% (8/8) |
| gemini-3.5-flash-lite | 0.9 s | 8 | 0 | 1.0 s | 0.8 s | 100% (8/8) | 91% (10/11) | 100% (8/8) |
| gpt-6-luna | 2.1 s | 8 | 0 | 2.0 s | 1.5 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-6.1-sol | 1.4 s | 8 | 0 | 2.6 s | 1.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

### Tokens

Prompt cache on (`Claude.PromptCaching`, the default). The questions, warm-up excluded, of each target in a row, as one session would ask them.

| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |
|---|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 10 | 15576 | 0 | 3770 | 1984 | - |
| gpt-oss:20b | 9 | 15341 | 0 | 1719 | 1796 | - |
| qwen3-coder:30b | 11 | 9232 | 0 | 15309 | 1078 | - |
| claude | 10 | 20 | 15360 | 14734 | 2259 | 20693 |
| claude-haiku-5-5 | 10 | 20 | 5728 | 24306 | 1854 | 9611 |
| claude-sonnet-5-5 | 10 | 20 | 15096 | 14734 | 1353 | 20363 |
| claude-opus-5-5 | 10 | 20 | 15096 | 14734 | 1673 | 20363 |
| gemini | 10 | 19184 | 0 | 0 | 531 | - |
| gemini-4-argon | 10 | 19581 | 0 | 0 | 843 | - |
| gemini-4-carbon | 10 | 19734 | 0 | 0 | 2569 | - |
| gemini-pro-latest | 10 | 19530 | 0 | 0 | 3621 | - |
| gemini-3.5-flash-lite | 10 | 19184 | 0 | 0 | 589 | - |
| gpt-6-luna | 10 | 14594 | 3671 | 0 | 539 | - |
| gpt-6.1-sol | 10 | 14594 | 3640 | 0 | 548 | - |

"Input": tokens at the full price. "Input as billed", claude only: input + 1.25 x cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), in tokens of the full price. OpenAI and Gemini cache by themselves, at prices of their own; a local server reports its prefix cache, which costs nothing.

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 4.5 s | 3.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 3.3 s | 1.8 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 4.2 s | 1.2 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude | 2.3 s | 1.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 1.5 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 1.9 s | 0.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 3.0 s | 1.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini | 1.1 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-argon | 7.2 s | 5.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-carbon | 9.5 s | 8.2 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-pro-latest | 5.1 s | 4.2 s | Leads.md | yes | 2/3 | - | yes |
| Q1 | gemini-3.5-flash-lite | 1.1 s | 0.7 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-6-luna | 2.8 s | 2.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-6.1-sol | 2.6 s | 1.1 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 4.6 s | 3.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 4.1 s | 2.7 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 2.7 s | 0.9 s | - | yes | 3/3 | - | yes |
| Q2 | claude | 1.9 s | 1.1 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 2.2 s | 1.4 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 1.8 s | 0.4 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 2.9 s | 0.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini | 0.8 s | 0.5 s | Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-argon | 5.2 s | 3.8 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-carbon | 10.7 s | 9.6 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-pro-latest | 6.2 s | 5.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini-3.5-flash-lite | 1.0 s | 0.6 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gpt-6-luna | 2.1 s | 1.2 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gpt-6.1-sol | 2.7 s | 1.4 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 3.2 s | 2.5 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 2.8 s | 2.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | qwen3-coder:30b | 2.8 s | 1.1 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude | 2.0 s | 1.5 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 1.5 s | 1.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 1.7 s | 0.5 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 3.1 s | 1.3 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini | 1.0 s | 0.7 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-argon | 9.1 s | 7.2 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-carbon | 9.7 s | 8.5 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini-pro-latest | 7.5 s | 7.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-3.5-flash-lite | 0.9 s | 0.8 s | FAQ.md | yes | 1/2 | - | yes |
| Q3 | gpt-6-luna | 2.1 s | 1.5 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-6.1-sol | 1.8 s | 1.2 s | FAQ.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 3.8 s | 3.4 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 2.4 s | 1.6 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 6.5 s | 1.2 s | - | yes | 1/1 | open_screen | **no** |
| Q4 | claude | 1.6 s | 1.2 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 1.5 s | 1.0 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 2.4 s | 1.1 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.1 s | 0.8 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini | 0.8 s | 0.6 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-argon | 4.1 s | 2.8 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-carbon | 6.1 s | 5.2 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-pro-latest | 5.5 s | 5.1 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-3.5-flash-lite | 1.0 s | 0.8 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-6-luna | 1.2 s | 0.6 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-6.1-sol | 1.7 s | 1.1 s | FAQ.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 3.7 s | 3.0 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 2.6 s | 1.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 3.8 s | 1.2 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude | 1.2 s | 0.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.3 s | 0.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 2.5 s | 1.2 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 2.9 s | 1.1 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini | 0.7 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-argon | 7.2 s | 5.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-carbon | 10.9 s | 8.9 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-pro-latest | 5.6 s | 5.3 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-3.5-flash-lite | 0.7 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-6-luna | 1.8 s | 1.1 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-6.1-sol | 2.5 s | 1.5 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 3.4 s | 3.2 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.9 s | 1.7 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 1.7 s | 0.7 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 0.9 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 0.9 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 1.2 s | 0.4 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.8 s | 0.8 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 0.7 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-4-argon | 5.7 s | 5.2 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-4-carbon | 29.3 s | 29.2 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-pro-latest | 4.5 s | 4.5 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-3.5-flash-lite | 0.6 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-6-luna | 1.3 s | 0.9 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-6.1-sol | 2.0 s | 1.4 s | - | yes | 0/0 | - | yes |
| Q7 | gemma4:12b | 2.2 s | 2.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 1.8 s | 1.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 2.8 s | 0.7 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 2.5 s | 2.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 3.2 s | 3.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.3 s | 1.3 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.6 s | 1.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 1.4 s | 1.4 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-argon | 12.4 s | 12.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-carbon | 27.7 s | 27.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-pro-latest | 6.3 s | 6.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-3.5-flash-lite | 1.2 s | 1.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-6-luna | 1.6 s | 1.4 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-6.1-sol | 3.0 s | 2.8 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 3.8 s | 3.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 4.4 s | 3.6 s | - | yes | 0/0 | - | **no** |
| Q8 | qwen3-coder:30b | 5.0 s | 1.2 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude | 2.3 s | 2.1 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 2.1 s | 1.8 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.2 s | 2.2 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 4.1 s | 4.1 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 1.5 s | 1.4 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-argon | 16.8 s | 16.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-carbon | 20.9 s | 20.7 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-pro-latest | 7.7 s | 7.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-3.5-flash-lite | 1.6 s | 1.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-6-luna | 3.2 s | 2.9 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-6.1-sol | 4.9 s | 4.6 s | - | yes | 0/0 | create_lead | yes |

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

**warm-up** (19.1 s)

> Hello! How can I help you with the application today?

**Q1** (4.5 s)

> To move a lead from one column to another, you can **drag a row from one column and drop it on another**.
> 
> When you do this:
> 1. The lead takes the status of the column you dropped it on.
> 2. If the date for that stage is currently empty, it will be stamped with the current date.
> 3. If the date already has a value, it is left alone so that moving a lead back and forth does not rewrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (4.6 s)

> Your data is stored in an SQLite file named `w10crmdemo.sdb` located in your Documents folder, which is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data, you must:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again, which will rebuild the file with the sample data [Getting started](Getting-Started.md), [Data model](Data-Model.md).

**Q3** (3.2 s)

> No, you cannot change a proposal after it has been saved because the document is stored exactly as it was generated. While you can mark it as Accepted or Canceled, it cannot be edited. To redo a proposal, you must delete the existing one from the Sales list using the navigator and then create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (3.8 s)

> To get a file that can be opened in Excel, use the export on the **Marketing** page, which writes a delimited text file [Accounts](Accounts.md), [FAQ](FAQ.md).

**Q5** (3.7 s)

> To find a lead using an e-mail address, you can use the Search box, which filters all four columns simultaneously as you type. It matches the input (ignoring case) anywhere inside the lead's name, account name, office phone, or e-mail [Leads](Leads.md).

**Q6** (3.4 s)

> I'm sorry, but the documentation does not provide any information about the weather.

**Q7** (2.2 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (3.8 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have successfully created the lead for Mario Rossi at Apollo Orange, LLC. (ID 101).

### gpt-oss:20b

**warm-up** (22.7 s)

> You’re on the **Dashboard** screen.  
> - It shows one tile for each lead status that belongs to the active user (New, Active, Proposal Sent, Closed, Inactive) and a Total tile.  
> - The numbers update only when you leave and re‑open the Dashboard.  
> - Clicking a tile does nothing; to see the leads behind a number, open the **Leads** screen.
> 
> What would you like to do next?

**Q1** (3.3 s)

> To move a lead on the board:
> 
> 1. Click the lead row and drag it.
> 2. Drop it onto the target column.
> 3. The lead instantly changes to the status of that column.  
>    * If the date for that stage is still empty, the current date/time is stamped in that field (e.g., **Date Contacted**, **Date Drafted**, or **Date Closed**).  
>    * If the date already has a value, it is left unchanged, so moving back and forth does not rewrite history.  
> 4. The four lists refresh and the moved lead remains selected.
> 
> Source: [Leads](Leads.md)

**Q2** (4.1 s)

> Your data is kept in a single SQLite database file called **`w10crmdemo.sdb`**.  
> It is created the first time you run the app, stored in your **Documents** folder, and is encrypted with AES‑256.  
> To start over with the original sample data:
> 
> 1. Close the application.  
> 2. Delete the file `w10crmdemo.sdb` from your Documents folder.  
> 3. Re‑open the application – it will rebuild the file and load the original sample data.  
> 
> > Source: [Getting started](Getting-Started.md)  
> > Source: [Data model](Data-Model.md)

**Q3** (2.8 s)

> No – once a proposal is saved it is stored exactly as it was generated.  
> You can only change its status (Accepted or Canceled). If you need a new version, delete the existing proposal from the Sales list with the navigator and create a fresh one.  
> Source: [FAQ](FAQ.md)

**Q4** (2.4 s)

> The export that writes a delimited text file (CSV‑style) with a header row is the one on the **Marketing** page – that format opens directly in Excel.  
> Accounts and Leads export to FireDAC’s own binary/XML/JSON format, which Excel cannot open.  
> 
> *Source: [Accounts](Accounts.md) and [FAQ](FAQ.md)*

**Q5** (2.6 s)

> To locate a lead by e‑mail:
> 
> 1. Click the **Search** box at the top of the Leads board.  
> 2. Type the e‑mail address (or a part of it) and press *Enter*.  
> 3. The board will filter all columns, showing only the row(s) that contain that e‑mail.
> 
> The search matches against the lead’s name, account name, office phone or e‑mail, ignoring case.  
> Source: **[Leads](Leads.md)**

**Q6** (1.9 s)

> I’m sorry, but I don’t have information on the weather.

**Q7** (1.8 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I’ve switched to the **Accounts** screen. Let me know if you need anything else.

**Q8** (4.4 s)

> I can create that lead for you.  
> Could you please provide:
> 
> 1. The phone number for Mario Rossi  
> 2. Any notes you’d like to add for this lead (you can leave it blank if you don’t have anything to note)  
> 
> Once I have those, I’ll add the lead with status **New** and open its detail window.

### qwen3-coder:30b

**warm-up** (32.5 s)

- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> Hello! I'm here to help you use the CRM application. Based on your current position on the Dashboard screen and the documentation, I can explain how to navigate and use the application.
> 
> The Dashboard shows you counts of leads organized by status:
> - New Leads (not contacted yet)
> - Active Leads (being worked on)
> - Proposal Sent (waiting for answers)
> - Closed Leads (won or lost)
> - Inactive Leads (parked)
> - Total (all your leads)
> 
> To see the actual leads behind these numbers, click on the "Leads" tab in the navigation menu. The application uses a user filter system - you can switch between users using the dropdown in the title bar to see different sets of data.
> 
> Would you like me to help you with any specific action, such as creating a lead or switching users?
> 
> I've opened the Leads screen for you. This is where you can see all your leads organized by status. 
> 
> From here you can:
> - View individual leads in detail
> - Move leads between different status columns (New, Active, Proposal Sent, Closed, Inactive)
> - Create new leads using the "Create Lead" button
> 
> The screen shows all leads assigned to the currently selected user. You can change which user you're viewing by using the dropdown menu in the title bar.
> 
> Is there anything specific you'd like to do with the leads now? For example, would you like to create a new lead?

**Q1** (4.2 s)

> To move a lead from one column to another on the Leads board:
> 
> 1. **Drag and drop** the lead row from one column to another.
> 2. The lead will take the **status** of the column you dropped it on.
> 3. If the date for that stage is still empty, it will be **stamped with the current date**:
>    - **Date Contacted** when moving to Active
>    - **Date Drafted** when moving to Proposal Sent
>    - **Date Closed** when moving to Closed
> 
> If a date has already been set for that stage, it will **not be overwritten**, so moving a lead back and forth does not rewrite its history.
> 
> The four lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.7 s)

> Your data is stored in a single SQLite file named **w10crmdemo.sdb**, located in your **Documents** folder. This file is encrypted with AES-256.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete the file **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again.
> 
> The application will recreate the file with the original sample data.

**Q3** (2.8 s)

> According to the documentation, **no**, you cannot change a proposal after saving it.
> 
> The document states:
> 
> > "Can I change a proposal after saving it? No. The document is stored as it was generated."
> 
> You can only mark it as **Accepted** or **Canceled**, but not edit it further. If you need to make changes, you must delete the existing proposal and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (6.5 s)

- action `open_screen` {"name":"Marketing"} -> Opened the Marketing screen.

> The export on the **Marketing** page gives you a delimited text file with a header row, which can be opened directly in Excel. 
> 
> Exports from the **Accounts** and **Leads** pages write in FireDAC's own format, meant to be read back by the application, not Excel.
> 
> To perform this export:
> 
> 1. Go to the **Marketing** screen.
> 2. Look for the export option there — it is not described in detail in the provided excerpts, but based on the general information, you should find an export button or menu item on that page.
> 
> If you need further help navigating to that specific export function, please let me know!
> 
> The export option is available on the **Marketing** screen. You can use this to save the mailing list as a delimited text file that opens directly in Excel.
> 
> If you need to perform the export now:
> 
> 1. On the **Marketing** screen, look for an export button or menu item.
> 2. Choose the export option and specify the location and filename.
> 3. The exported file will be in a format compatible with Excel. 
> 
> Let me know if you'd like me to create a lead for you next!

**Q5** (3.8 s)

> To find a lead using only its email address, use the **Search** box on the Leads screen. Type the email address into the search field, and it will filter the leads displayed, matching the email address exactly.
> 
> The search function matches against the lead's name, account name, office phone, or email — so typing the email address will show any lead associated with that email.
> 
> 1. Go to the **Leads** screen.
> 2. Type the email address in the **Search** box at the top.
> 3. The list updates automatically to show matching leads.
> 
> If you need help with a specific email, let me know and I can guide you further.<tool_call>
> 
> Source: [Leads](Leads.md)

**Q6** (1.7 s)

> I cannot provide weather information. The application's documentation does not contain any details about weather forecasts or external data retrieval capabilities.
> 
> To get weather information for Milan, you might want to use a dedicated weather service or application outside of this CRM tool.<tool_call>

**Q7** (2.8 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> To open the Accounts screen, I will use the `open_screen` tool with the parameter `name` set to "Accounts". This action will bring the Accounts screen to the front, as requested by the user.
> 
> The Accounts screen is now open. You can view and manage the accounts in the application. If you need to perform any actions on this screen, let me know how I can assist you further.

**Q8** (5.0 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> The company **Apollo Orange, LLC.** is already in the Accounts list, so we can proceed to create the lead.
> 
> To create the lead, I will use the `create_lead` function with the following details:
> 1. **Name**: Mario Rossi
> 2. **Account**: Apollo Orange, LLC.
> 3. **Email**: mario.rossi@example.com
> 
> The phone number and notes are not provided, so they will be left blank.
> 
> The lead **Mario Rossi** has been successfully created for the company **Apollo Orange, LLC.** The lead is now in the "New" status. You can open its detail window to fill in additional information such as phone number or notes.

### claude

**warm-up** (2.6 s)

> Hello! I'm the in-app help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard counters, users, and the main window. I can also create a lead for you if you give me the contact's name and the company, which must already exist in Accounts.
> 
> What would you like to know or do?

**Q1** (2.3 s)

> To move a lead, drag its row from its current column and drop it on the target column. The lead takes that column's status, and the list refreshes with the lead still selected.
> 
> Its dates change as follows:
> 
> - If the target stage's date is empty, it is stamped with the current date and time:
>   - Moving to **Active** sets Date Contacted.
>   - Moving to **Proposal Sent** sets Date Drafted.
>   - Moving to **Closed** sets Date Closed.
> - If that date already has a value, it is left unchanged, so moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> Source: [Leads](Leads.md)

**Q2** (1.9 s)

> **Where your data is stored:** everything is in one encrypted SQLite file, `w10crmdemo.sdb`, in your Documents folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> **How to restore the sample data:**
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data. ([Getting started](Getting-Started.md))
> 
> Deleting the file also removes any changes you have made, and the application has no undo, so there is no way to recover them afterwards.

**Q3** (2.0 s)

> No. A saved proposal can't be edited. The document is stored as it was generated. You can change its status to Accepted or Canceled, but not its content, and a lead can't have a second proposal. ([FAQ](FAQ.md))
> 
> To redo a proposal:
> 1. Open the **Sales** screen.
> 2. Delete the existing proposal from the Sales list using the navigator.
> 3. Create a new proposal for the lead.

**Q4** (1.6 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel opens directly. The exports on the Accounts and Leads pages write FireDAC's own format, which only this application can read back, so they won't open properly in Excel.
> 
> Source: [FAQ](FAQ.md)

**Q5** (1.2 s)

> On the Leads board, type the e-mail address (or part of it) in the **Search** box. It filters all four columns as you type and matches anywhere inside the value, ignoring case. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (0.9 s)

> I can't help with that one. I'm the help assistant for the CRM Demo application, and I only have access to its documentation and tools. I have no access to live weather data, so I can't tell you the weather in Milan.

**Q7** (2.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.3 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column.

### claude-haiku-5-5

**warm-up** (1.3 s)

> Hello! I'm the help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard counters, Users, the navigation menu, or how to work with leads and accounts. What would you like to know?

**Q1** (1.5 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates change as follows:
> 
> - If the date for that stage is still empty, it is stamped with the current date and time. Moving to Active sets Date Contacted, moving to Proposal Sent sets Date Drafted, and moving to Closed sets Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> The four lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.2 s)

> Your data is stored in one encrypted SQLite file, `w10crmdemo.sdb`, in your Documents folder. It is encrypted with AES-256 ([Data model](Data-Model.md)).
> 
> To restore the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the sample data ([Data model](Data-Model.md), [Getting started](Getting-Started.md)).
> 
> Deleting the file also removes any data you have added, and the application has no way to undo this. Consider backing up the file first.

**Q3** (1.5 s)

> No. A saved proposal is stored as it was generated, so you can't edit it. You can mark it Accepted or Canceled, but the content stays the same.
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one. The lead also can't have a second proposal, so you'll need to remove the old one first. ([FAQ](FAQ.md))

**Q4** (1.5 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel opens directly.
> 
> Don't use the exports on the **Accounts** or **Leads** pages for this. They write FireDAC's own format (binary, XML or JSON), which only this application can read back, not a spreadsheet file.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (1.3 s)

> On the Leads board, type the e-mail address (or part of it) into the **Search** box. The four columns filter as you type, and the search matches against the lead's name, account name, office phone and e-mail. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (0.9 s)

> I can't help with that one. I'm the help assistant for the CRM Demo application, and I only have documentation about how to use this app, not access to weather information.

**Q7** (3.2 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.1 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column.

### claude-sonnet-5-5

**warm-up** (1.5 s)

> Hello! I'm the in-app help assistant for this CRM application. I can explain how to use its screens (Dashboard, Accounts, Leads, Sales, Marketing, Calendar, Users). I can also create a lead for you if you give me the person's name and their company, which must already be in Accounts.
> 
> What would you like to know or do?

**Q1** (1.9 s)

> **To move a lead:** on the Leads board, drag its row from one column and drop it on another. The board has four columns: New, Active, Proposal Sent and Closed.
> 
> **What happens:**
> - The lead takes the status of the column you dropped it on.
> - If the date for that stage is still empty, it is stamped with the current date and time:
>   - **Date Contacted** when it moves to Active
>   - **Date Drafted** when it moves to Proposal Sent
>   - **Date Closed** when it moves to Closed
> - A date that already has a value is left alone. Moving a lead back and forth therefore does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> The four lists refresh after every move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (1.8 s)

> Your data is in a single SQLite file, **w10crmdemo.sdb**, in your Documents folder. It's encrypted with AES-256. ([Data model](Data-Model.md))
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the sample data: 8 leads, 8 accounts, one user and three proposals. ([Getting started](Getting-Started.md))
> 
> **Warning:** this is the only way to undo changes. Deleting the file removes everything you've added or edited. Most deletes in the application also have no confirmation.

**Q3** (1.7 s)

> No, a saved proposal can't be edited. The document is stored exactly as it was generated. You can only mark it **Accepted** or **Canceled**, and the lead can't be given a second proposal. ([FAQ](FAQ.md))
> 
> To redo a proposal:
> 1. On the **Sales** screen, select the existing proposal and delete it with the navigator.
> 2. Create a new proposal for the lead.
> 
> Complete and Cancel don't ask for confirmation and can be applied again later. Nothing is locked once a proposal is accepted. ([Sales](Sales.md))

**Q4** (2.4 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, and a spreadsheet can open that file directly. ([FAQ](FAQ.md), [Accounts](Accounts.md))
> 
> The exports on the **Accounts** and **Leads** pages use FireDAC's own format (binary, XML or JSON, depending on the extension you choose). This application can read that format back, but it isn't a spreadsheet file, so Excel won't open it properly.
> 
> You're on the Accounts screen now, so open **Marketing** to find the right export.

**Q5** (2.5 s)

> On the **Leads** screen, type the e-mail address (or part of it) in the **Search** box. It filters all four columns at once as you type. The match ignores case and works anywhere inside the value, so a partial address such as `example.com` also works. Clear the box to get the full board back. ([Leads](Leads.md))
> 
> Search also checks the lead's name, account name and office phone, so any of those will find the lead too.

**Q6** (1.2 s)

> I can't help with that. The documentation I have covers how to use this application, and it says nothing about weather, so I can't tell you what the weather in Milan is. A weather service or website will give you that.
> 
> If you have a question about the application, such as the Dashboard tiles, leads or users, I'm happy to help.

**Q7** (1.3 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.2 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It starts with status New, so you'll find it in the New column on the Leads board.
> 
> Source: [Asking the assistant](Assistant.md)

### claude-opus-5-5

**warm-up** (1.7 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard**, which shows a tile for each lead status (New, Active, Proposal Sent, Closed, Inactive, plus Total) for the user picked in the title bar drop-down ([Dashboard](Dashboard.md)).
> 
> What can I help you with? I can answer questions about how the application works, or do things for you, like create a new lead.

**Q1** (3.0 s)

> To move a lead, **drag its row and drop it on another column** of the Leads board.
> 
> When you drop it:
> 
> 1. **Status:** the lead takes the status of the column you dropped it on.
> 2. **Dates:** if that stage's date is still empty, it's set to the current date and time:
>    - Moving to **Active** fills in `Date Contacted`
>    - Moving to **Proposal Sent** fills in `Date Drafted`
>    - Moving to **Closed** fills in `Date Closed`
> 3. **Dates already filled in don't change.** Moving a lead back and forth won't overwrite its history.
> 
> Dropping a lead on the column it's already in does nothing. All four lists refresh after each move, and the lead you moved stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.9 s)

> Your data is kept in one SQLite file called `w10crmdemo.sdb` in your **Documents** folder. The file is encrypted with AES-256. [Data model](Data-Model.md)
> 
> **To get the sample data back:**
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (`CRMUser`) and three proposals. [Getting started](Getting-Started.md)
> 
> **Be careful:** this erases everything you've added or changed, and it can't be undone. Deleting the file is also the only way to undo anything in the app, because there's no rollback and most deletes don't ask for confirmation. [Data model](Data-Model.md)

**Q3** (3.1 s)

> **No.** A saved proposal is stored exactly as it was generated, so you can't edit it. Each lead can only have one proposal. [FAQ](FAQ.md)
> 
> What you can do:
> 
> - **Change its status.** Select the proposal on this Sales screen and use **Complete** to mark it Accepted or **Cancel** to mark it Canceled. Neither button asks you to confirm. You can switch the status again later, because accepting a proposal doesn't lock it. [Sales](Sales.md)
> - **Redo it.** Delete the proposal from the Sales list with the navigator, then create a new one for the lead. [FAQ](FAQ.md)

**Q4** (2.1 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel can open directly.
> 
> The **Export** on the Accounts screen you're on won't work for this. It saves the whole table in FireDAC's own format (binary, XML or JSON, depending on the file extension you choose). Only this application can read that format back, and it isn't a spreadsheet file. The export on the Leads page works the same way.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (2.9 s)

> Use the **Search** box on the Leads board, which is the screen you're on now:
> 
> 1. Type the e-mail address, or any part of it, into the **Search** box.
> 2. All four columns filter as you type. Case doesn't matter, and the text can match anywhere in the address. For example, typing `example.com` finds everyone with an address at that domain.
> 3. Double-click the matching row, or select it and press **View Lead**, to open its details.
> 4. Clear the box to see the whole board again.
> 
> The search covers every column, but the **Active** column is the only one that displays the e-mail address. ([Leads](Leads.md))

**Q6** (1.8 s)

> I can't tell you the weather in Milan. I only help with using this CRM application, and it has no weather information. It also works offline, without a server or network connection. For today's forecast, try a weather website or app.
> 
> If you have questions about the Dashboard or any other part of the app, I'm happy to help.

**Q7** (1.6 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> I've opened the **Accounts** screen for you.

**Q8** (4.1 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.**, with the e-mail `mario.rossi@example.com`. New leads start with the status **New**, and their detail window opens so you can add more information, such as an office phone ([Asking the assistant](Assistant.md)).

### gemini

**warm-up** (1.3 s)

> Hello! You are currently on the **Dashboard** screen [Dashboard](Dashboard.md). 
> 
> The Dashboard is the opening screen of the application and counts the leads of the active user, showing one tile per status [Dashboard](Dashboard.md):
> * **New:** Leads nobody has contacted yet [Dashboard](Dashboard.md).
> * **Active:** Leads being worked on [Dashboard](Dashboard.md).
> * **Proposal Sent:** Leads waiting for an answer to a proposal [Dashboard](Dashboard.md).
> * **Closed:** Leads that ended, won or lost [Dashboard](Dashboard.md).
> * **Inactive:** Leads parked (this tile is the only place they are visible, as there is no column for them on the Leads board) [Dashboard](Dashboard.md).
> * **Total:** Every lead of the user, regardless of status [Dashboard](Dashboard.md).
> 
> Each tile is a separate count over the Leads table filtered by the User column and follows the user drop-down in the title bar [Dashboard](Dashboard.md). The counters refresh when you return to the Dashboard [Dashboard](Dashboard.md). The tiles are decorative (clicking them does nothing), so to see the leads behind a number, you should open the Leads section [Dashboard](Dashboard.md).

**Q1** (1.1 s)

> To move a lead from one column of the board to another, drag a row from one column and drop it on another [[Leads](Leads.md)].
> 
> When you move a lead:
> - The lead takes the status of the column you dropped it on [[Leads](Leads.md)].
> - If the date of that stage is still empty, it is stamped with the current time (Date Contacted moving to Active, Date Drafted moving to Proposal Sent, Date Closed moving to Closed) [[Leads](Leads.md)].
> - A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history [[Leads](Leads.md)].

**Q2** (0.8 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, and it is encrypted with AES-256 [Getting started](Getting-Started.md).
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md).
> 3. Start the application again [Getting started](Getting-Started.md).

**Q3** (1.0 s)

> No, you cannot edit a proposal after it has been saved; the document is stored as it was generated [FAQ](FAQ.md). However, you can mark it as Accepted or Canceled, and to redo a proposal you can delete the existing one from the Sales list using the navigator and create a new one [FAQ](FAQ.md).

**Q4** (0.8 s)

> For something you can open in Excel, use the export on the **Marketing** page, which writes a delimited text file ([Accounts](Accounts.md), [FAQ](FAQ.md)).

**Q5** (0.7 s)

> You can use the **Search** box to find a lead by its e-mail address. As you type, the search box filters all four columns at once, matching anywhere inside the e-mail address (such as typing `example.com` to find everyone with that domain) [Leads](Leads.md).

**Q6** (0.7 s)

> The documentation excerpts do not cover the weather.

**Q7** (1.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (1.5 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","name":"Mario Rossi","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead for Mario Rossi at Apollo Orange, LLC.

### gemini-4-argon

**warm-up** (4.1 s)

> Hello! I am Assistant, your in-app help assistant. You are currently on the **Dashboard** screen. How can I help you use the application today?

**Q1** (7.2 s)

> To move a lead on the **Leads** board, simply **drag a row from one column and drop it on another**. When you do this, the lead takes the status of the new column, the four lists refresh, and the moved lead stays selected. (Dropping a lead on the column it is already in does nothing.)
> 
> Here is what happens to the lead's dates:
> * **If the date for the target stage is empty**, it is stamped with the current time:
>   * **Date Contacted** when moving to **Active**
>   * **Date Drafted** when moving to **Proposal Sent**
>   * **Date Closed** when moving to **Closed**
> * **If that date already has a value**, it is left unchanged so that moving a lead back and forth does not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (5.2 s)

> All your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb` located in your **Documents** folder.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again — it will automatically recreate the file with the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (9.1 s)

> No, you cannot edit a proposal once it is saved, because the document is stored as it was generated, and a lead cannot be given a second proposal.
> 
> However, you can still change its status or replace it:
> * **Change the status:** Use the **Complete** or **Cancel** buttons in the banner (on the **Sales** screen or the lead detail window) to set the status to `Accepted` or `Canceled`. Both actions can be applied again later.
> * **Redo the proposal:** Delete the existing proposal from the **Sales** list using the navigator, and then create a new one for the lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (4.1 s)

> You should use the export on the **Marketing** page, which writes a delimited text file with a header row that Excel can open directly. 
> 
> The **Export** buttons on the **Accounts** (where you are now) and **Leads** pages save files in FireDAC's own format (binary, XML, or JSON), which are meant to be read back by this application rather than opened as a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (7.2 s)

> On the **Leads** screen, type the e-mail address (or part of it) into the **Search** box. 
> 
> It filters all four columns at once as you type, matching anywhere inside the lead's e-mail address, name, account name, or office phone (ignoring case). Clear the box to bring the full board back.
> 
> Note that even though the **Email** column is only displayed in the **Active** column, the search matches against the e-mail address across all four status columns (**New**, **Active**, **Proposal Sent**, and **Closed**).
> 
> Source: [Leads](Leads.md)

**Q6** (5.7 s)

> I cannot answer this question. I am the in-app help assistant and can only explain how to use this application based on its documentation.

**Q7** (12.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen for you.

**Q8** (16.8 s)

- action `create_lead` {"name":"Mario Rossi","email":"mario.rossi@example.com","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> I have created the lead **Mario Rossi** for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`.

### gemini-4-carbon

**warm-up** (5.9 s)

> Hello! I am Assistant, the in-app help assistant. How can I help you use the application today?

**Q1** (9.5 s)

> To move a lead on the **Leads** board, drag its row from one column and drop it onto another. The lead takes the status of the target column, the four lists refresh, and the moved lead stays selected (dropping it onto the column it is already in does nothing).
> 
> Here is what happens to its dates:
> * **Empty stage dates are stamped with the current date and time:**
>   * Moving to **Active** sets **Date Contacted**.
>   * Moving to **Proposal Sent** sets **Date Drafted**.
>   * Moving to **Closed** sets **Date Closed**.
> * **Existing dates are preserved:** If that stage's date already has a value, it is left unchanged, so moving a lead back and forth will not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (10.7 s)

> All your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb` inside your **Documents** folder.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again — it will automatically recreate the file with the original sample data (8 leads, 8 accounts, 1 user, and 3 proposals).
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (9.7 s)

> No, you cannot edit a proposal once it has been saved, as the document is stored exactly as it was generated. You can only change its status to **Accepted** (using **Complete**) or **Canceled** (using **Cancel**).
> 
> Since a lead cannot have a second proposal, if you need to redo one:
> 1. Delete the existing proposal from the **Sales** list using the navigator.
> 2. Create a new proposal for the lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (6.1 s)

> Use the export on the **Marketing** screen. It writes a delimited text file with a header row, which a spreadsheet like Excel can open directly.
> 
> By contrast, the **Export** buttons on the **Accounts** screen (where you currently are) and the **Leads** screen save files in FireDAC's own format (binary, XML, or JSON depending on the file extension), which is meant to be read back by this application rather than opened as a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (10.9 s)

> On the **Leads** screen you are currently on, use the **Search** box:
> 
> 1. Type the e-mail address (or part of it) into the **Search** box. It filters all four status columns (**New**, **Active**, **Proposal Sent**, and **Closed**) as you type, matching against e-mail (as well as name, account name, and office phone) regardless of case.
> 2. Note that the **Email** column is only visible in the **Active** list, even though matching leads in the other three columns will also appear. To inspect a matching lead, double-click its row or select it and press **View Lead**.
> 3. Clear the **Search** box when you want to see the full board again.
> 
> Keep in mind that leads with the **Inactive** status have no column on the Leads board, so they will not appear there.
> 
> Source: [Leads](Leads.md)

**Q6** (29.3 s)

> I can only answer questions about how to use this application, and the documentation does not cover weather information.

**Q7** (27.7 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen.

**Q8** (20.9 s)

- action `create_lead` {"name":"Mario Rossi","email":"mario.rossi@example.com","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** (ID 101) for **Apollo Orange, LLC.** with e-mail `mario.rossi@example.com`.

### gemini-pro-latest

**warm-up** (4.9 s)

> Hello! I am the in-app help assistant. I am here to help you understand how to use this CRM application. What would you like to know?

**Q1** (5.1 s)

> To move a lead from one column to another, simply drag the row from its current column and drop it onto the new one. 
> 
> When you drop the lead into a new column, the following happens to its dates:
> * If the date for that new stage is empty, it is immediately stamped with the current date and time (for example, *Date Contacted* when moving to Active, *Date Drafted* when moving to Proposal Sent, or *Date Closed* when moving to Closed).
> * If the date for that stage already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (6.2 s)

> Your data is stored in a single encrypted SQLite file named `w10crmdemo.sdb`, located in your Documents folder (Source: [Data model](Data-Model.md)).
> 
> To start over with the original sample data, follow these steps:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder.
> 3. Start the application again. It will automatically recreate the file and copy the sample data into it. 
> 
> Source: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (7.5 s)

> No, you cannot edit a proposal after it has been saved. The document is stored exactly as it was generated. 
> 
> While you can mark a proposal as Accepted or Canceled, you cannot change its contents, and a lead cannot be given a second proposal. If you need to redo a proposal, you must delete the existing one from the Sales list using the navigator and create a new one. 
> 
> Source: [FAQ](FAQ.md)

**Q4** (5.5 s)

> To get a file you can open in Excel, use the export on the **Marketing** page. It writes a delimited text file with a header row that a spreadsheet can open directly. 
> 
> The Export button on the Accounts and Leads pages writes in FireDAC's own format (binary, XML, or JSON), which is meant to be read back by the application and is not a spreadsheet file.
> 
> Source: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (5.6 s)

> You can find the lead by using the **Search** box on the Leads board. Simply type the e-mail address (or a part of it, like `example.com`) into the box. It filters all four columns at once as you type, matching the text against e-mail addresses, names, account names, and phone numbers. 
> 
> Source: [Leads](Leads.md)

**Q6** (4.5 s)

> The documentation does not cover information about the weather.

**Q7** (6.3 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (7.7 s)

- action `create_lead` {"email":"mario.rossi@example.com","name":"Mario Rossi","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi at Apollo Orange, LLC., and added their e-mail address. You can now see this lead on your Leads board.

### gemini-3.5-flash-lite

**warm-up** (0.9 s)

> Hello! How can I help you use the application today?

**Q1** (1.1 s)

> To move a lead, drag and drop a row from one column to another [Leads](Leads.md). 
> 
> As for its dates:
> * The lead takes the status of the column you dropped it on [Leads](Leads.md).
> * If the date of that stage is still empty, it is stamped with the current time (e.g., Date Contacted moving to Active, Date Drafted moving to Proposal Sent, or Date Closed moving to Closed) [Leads](Leads.md).
> * If a date already has a value, it is left alone, so moving a lead back and forth does not rewrite its history [Leads](Leads.md).
> * Dropping a lead on the column it is already in does nothing [Leads](Leads.md).
> 
> Source: [Leads](Leads.md)

**Q2** (1.0 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, and it is encrypted with AES-256 [Getting started](Getting-Started.md), [Data model](Data-Model.md).
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md), [Data model](Data-Model.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md), [Data model](Data-Model.md).
> 3. Start the application again [Getting started](Getting-Started.md), [Data model](Data-Model.md).

**Q3** (0.9 s)

> No, you cannot edit a proposal after it has been saved; the document is stored as it was generated [FAQ](FAQ.md). However, you can mark it as Accepted or Canceled, and you can redo a proposal by deleting the existing one from the Sales list using the navigator and creating a new one [FAQ](FAQ.md).

**Q4** (1.0 s)

> For something you can open in Excel, use the export on the **Marketing** page, which writes a delimited text file with a header row that a spreadsheet opens directly ([Accounts](Accounts.md), [FAQ](FAQ.md)).

**Q5** (0.7 s)

> You can find a lead by typing its e-mail address (or part of it, such as a domain name) into the **Search** box, which filters all four columns at once as you type [Leads](Leads.md).

**Q6** (0.6 s)

> The documentation does not cover the weather.

**Q7** (1.2 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (1.6 s)

- action `create_lead` {"name":"Mario Rossi","email":"mario.rossi@example.com","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> Created the lead for Mario Rossi at Apollo Orange, LLC.

### gpt-6-luna

**warm-up** (2.1 s)

> Hello! What can I help you with?

**Q1** (2.8 s)

> Drag the lead’s row from its current column and drop it in the column you want. Its status changes to match that column. If the date for that stage is empty, it’s stamped with the current date and time; if it already has a value, it stays unchanged. Dropping it back in the same column does nothing. [Leads](Leads.md)

**Q2** (2.1 s)

> The app stores all data in the encrypted SQLite file `w10crmdemo.sdb` in your Documents folder.
> 
> To restore the original sample data, close the application, delete that file, then start the application again. It will rebuild the file with the sample data. **This resets all data in the file**, and the app has no other undo method. [Getting started](Getting-Started.md) [Data model](Data-Model.md)

**Q3** (2.1 s)

> No. A saved proposal can’t be edited, and the lead can’t be given a second one. To redo it, delete the existing proposal from the Sales list using the navigator, then create a new proposal. [FAQ](FAQ.md)

**Q4** (1.2 s)

> Use the **Export on the Marketing page**. It writes a delimited text file with a header row that Excel can open. The Accounts and Leads exports use the application’s own format. [FAQ](FAQ.md)

**Q5** (1.8 s)

> On the Leads screen, type the e-mail address—or part of it—in the **Search** box. It filters all four columns as you type and matches e-mail addresses regardless of case. Clear the box to show the full board again. [Leads](Leads.md)

**Q6** (1.3 s)

> I can’t provide today’s weather in Milan; the information available here doesn’t cover weather.

**Q7** (1.6 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is open.

**Q8** (3.2 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created Mario Rossi for Apollo Orange, LLC. with the email mario.rossi@example.com.

### gpt-6.1-sol

**warm-up** (1.4 s)

> Hello! How can I help you use the application?

**Q1** (2.6 s)

> **Drag the lead’s row from its current column and drop it onto another.** Its status changes to match the destination column.
> 
> If the destination stage’s date is empty, it is set to the current date and time:
> - **Active:** Date Contacted
> - **Proposal Sent:** Date Drafted
> - **Closed:** Date Closed
> 
> Existing dates are left unchanged, so moving a lead back and forth does not rewrite its history. Dropping it onto its current column does nothing. [Leads](Leads.md)

**Q2** (2.7 s)

> Your data is stored in **`w10crmdemo.sdb` in your Documents folder**, a single SQLite file encrypted with AES-256. [Data model](Data-Model.md)
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again.
> 
> **This removes your current data.** The application rebuilds the file with 8 leads, 8 accounts, one user, and three proposals. [Getting started](Getting-Started.md)

**Q3** (1.8 s)

> No—the saved proposal document cannot be edited. You can only change its status to **Accepted** or **Canceled**.
> 
> To redo it, delete the existing proposal from the **Sales** list using the navigator, then create a new one. A lead cannot have a second proposal while the existing one remains. [FAQ](FAQ.md)

**Q4** (1.7 s)

> Use **Export on the Marketing page**. It creates a delimited text file with a header row that Excel can open directly. The Accounts and Leads exports use FireDAC’s own format, not a spreadsheet format. [FAQ](FAQ.md)

**Q5** (2.5 s)

> On the **Leads** screen, type the e-mail address into the **Search** box. It filters all four columns as you type; matching is case-insensitive, and part of an address works too.
> 
> Double-click the matching row to open the lead. Clear the Search box to restore the full board. [Leads](Leads.md)

**Q6** (2.0 s)

> I can only help with using this application. The provided documentation doesn’t cover weather in Milan.

**Q7** (3.0 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (4.9 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** for **Apollo Orange, LLC.** with email **mario.rossi@example.com**.

