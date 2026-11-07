# HelpChatAI provider benchmark

Run on 2026-11-06 18:16. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); a new conversation per question; language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 9.9 s | 8 | 0 | 6.4 s | 5.2 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 19.8 s | 8 | 0 | 3.0 s | 2.1 s | 75% (6/8) | 100% (11/11) | 88% (7/8) |
| qwen3-coder:30b | 28.5 s | 8 | 0 | 5.6 s | 2.2 s | 88% (7/8) | 91% (10/11) | 62% (5/8) |
| claude | 2.8 s | 8 | 0 | 2.0 s | 0.7 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |
| gemini | 2.4 s | 8 | 0 | 4.7 s | 4.1 s | 88% (7/8) | 100% (11/11) | 100% (8/8) |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 7.2 s | 4.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 5.9 s | 4.1 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 5.4 s | 2.5 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude | 2.7 s | 0.5 s | - | **no** | 3/3 | - | yes |
| Q1 | gemini | 5.2 s | 3.8 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 5.6 s | 4.0 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 2.9 s | 1.5 s | - | **no** | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 5.7 s | 2.4 s | - | **no** | 3/3 | - | yes |
| Q2 | claude | 2.5 s | 0.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini | 3.8 s | 3.0 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 5.1 s | 4.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 2.5 s | 1.7 s | - | **no** | 2/2 | - | yes |
| Q3 | qwen3-coder:30b | 4.3 s | 2.5 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude | 1.7 s | 0.5 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini | 4.1 s | 3.8 s | FAQ.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 6.3 s | 5.1 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 3.3 s | 2.4 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 6.7 s | 2.9 s | FAQ.md Accounts.md | yes | 1/1 | open_screen | **no** |
| Q4 | claude | 1.7 s | 0.5 s | Accounts.md | yes | 1/1 | - | yes |
| Q4 | gemini | 3.5 s | 3.1 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 8.9 s | 7.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 3.1 s | 1.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 10.3 s | 2.0 s | Leads.md | yes | 1/2 | open_screen | **no** |
| Q5 | claude | 2.8 s | 0.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini | 4.7 s | 3.5 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 5.7 s | 4.2 s | Dashboard.md Home.md Users.md | **no** | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.2 s | 1.0 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 1.3 s | 0.2 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 1.4 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 4.1 s | 3.8 s | Home.md | **no** | 0/0 | - | yes |
| Q7 | gemma4:12b | 4.8 s | 4.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 2.9 s | 2.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 3.4 s | 2.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 1.5 s | 1.3 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 5.4 s | 5.3 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 8.0 s | 7.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 2.1 s | 1.7 s | - | yes | 0/0 | - | **no** |
| Q8 | qwen3-coder:30b | 7.2 s | 2.5 s | - | yes | 0/0 | open_screen, create_lead | **no** |
| Q8 | claude | 1.7 s | 1.4 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 7.0 s | 6.6 s | - | yes | 0/0 | create_lead | yes |

## Questions

- **Q1** (screen Leads): How do I move a lead from one column of the board to another, and what happens to its dates? - expected page: Leads.md - facts: drag, status, date - no action
- **Q2** (screen Dashboard): Where is my data stored, and how do I start over with the sample data? - expected page: FAQ.md or Getting-Started.md - facts: w10crmdemo.sdb, Documents, delete - no action
- **Q3** (screen Sales): Can I change a proposal after I saved it? - expected page: FAQ.md or Draft-Proposal.md or Sales.md - facts: No, delete - no action
- **Q4** (screen Accounts): Which export gives me a file I can open in Excel? - expected page: FAQ.md or Marketing.md or Accounts.md - facts: Marketing - no action
- **Q5** (screen Leads): Come faccio a cercare un lead a partire dal suo indirizzo e-mail? - expected page: Leads.md - facts: Search, mail - no action
- **Q6** (screen Dashboard): What is the weather in Milan today? - no action
- **Q7** (screen Dashboard): Open the Accounts screen for me. - action: open_screen(Accounts)
- **Q8** (screen Leads): Create a lead named Mario Rossi for the company Apollo Orange, LLC., e-mail mario.rossi@example.com. - action: create_lead(Mario Rossi)

## Answers

### gemma4:12b

**warm-up** (9.9 s)

> Hello! How can I help you with the application today?

**Q1** (7.2 s)

> To move a lead to a different column, use the drag and drop method:
> 
> 1. **Drag a row** from one column and **drop it** onto another column. 
> 2. **Status Change:** The lead will automatically take the status of the column where you dropped it.
> 3. **Date Handling:** 
>     * If the date for that new stage is currently empty, it will be stamped with the current time (e.g., moving to *Active* stamps *Date Contacted*, moving to *Proposal Sent* stamps *Date Drafted*, and moving to *Closed* stamps *Date Closed*).
>     * If the date already has a value, it will remain unchanged, ensuring the lead's history is preserved.
> 
> Dropping a lead into the column it is already in will have no effect.
> 
> Source: [Leads.md](Leads.md)

**Q2** (5.6 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, which is encrypted with AES-256.
> 
> To start over with the original sample data, follow these steps:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder.
> 3. Start the application again; the file will be rebuilt with the original sample data.
> 
> Sources:
> - [Data model](Data-Model.md)
> - [Getting started](Getting-Started.md)

**Q3** (5.1 s)

> No, you cannot change a proposal after it has been saved because the document is stored exactly as it was generated. You can, however, mark it as **Accepted** or **Canceled**.
> 
> To redo a proposal, you must delete the existing one from the Sales list using the navigator and then create a new one.
> 
> Source: [FAQ.md](FAQ.md)

**Q4** (6.3 s)

> To get a file that you can open in Excel, you should use the export option on the **Marketing** page, which writes a delimited text file. The exports on the Accounts and Leads pages are in a format meant to be read back by the application and are not spreadsheet files.
> 
> Source: [Accounts.md](Accounts.md), [FAQ.md](FAQ.md)

**Q5** (8.9 s)

> Puoi cercare un lead inserendo l'indirizzo e-mail direttamente nella casella di ricerca (**Search box**) sulla schermata "Leads".
> 
> Il sistema filtra i risultati mentre digiti, ignorando le maiuscole e cercando la corrispondenza in qualsiasi parte del valore dell'e-mail.
> 
> Fonte: [Leads.md](Leads.md)

**Q6** (5.7 s)

> I'm sorry, but I don't have any information about the weather in Milan. My purpose is to help you use this CRM application based on its documentation.
> 
> You can find more information about the application in the documentation:
> - [Dashboard.md](Dashboard.md)
> - [Home.md](Home.md)
> - [Users.md](Users.md)

**Q7** (4.8 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (8.0 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have successfully created the lead for Mario Rossi at Apollo Orange, LLC. (ID 101).

### gpt-oss:20b

**warm-up** (19.8 s)

> Hello! How can I help you with the CRM application today?

**Q1** (5.9 s)

> **Move a lead**
> 
> 1. On the Leads board, click the row you want to move and drag it to the desired column.  
> 2. Drop the row in that column – the lead automatically changes to the status of that column.  
> 
> **Effect on dates**  
> - If the date for that stage is still blank, it is filled with the current time.  
>   * *Date Contacted* → “Active” column, *Date Drafted* → “Proposal Sent”, *Date Closed* → “Closed”.  
> - If the date already has a value, it stays unchanged – moving a lead back and forth does not rewrite its history.  
> - Dropping a lead in the column it already occupies does nothing.
> 
> (Source: *Leads.md*)

**Q2** (2.9 s)

> Your data lives in a single SQLite database file named **`w10crmdemo.sdb`** that is created in your **Documents** folder when you first launch the app. The file is encrypted with AES‑256.
> 
> **To reset to the original sample data**
> 
> 1. Close the application.  
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder.  
> 3. Start the application again – it will rebuild the file and load the original sample data.  
> 
> (See *Getting Started* and *Data model* documentation.)

**Q3** (2.5 s)

> **No.**  
> Once a proposal is saved, the generated HTML document is stored in the database and cannot be edited. You can only change its status (Accepted or Canceled) or delete it and create a new one.  
> (See FAQ, “Can I change a proposal after saving it?”)

**Q4** (3.3 s)

> The only export that produces a spreadsheet‑friendly file is the **Marketing page export**.  
> It writes a delimited text file (CSV/TSV) with a header row that Excel can open directly.  
> The Accounts and Leads exports use FireDAC’s own binary/XML/JSON format, which Excel cannot read.  
> 
> *(Accounts.md; FAQ.md)*

**Q5** (3.1 s)

> Per cercare un lead tramite il suo indirizzo e‑mail, usa la **Search box** in alto sullo schermo Leads.  
> - Digita l’indirizzo (o un frammento, ad esempio `example.com`).  
> - Il filtro cercherà automaticamente in tutti i record, ignorando maiuscole/minuscole e abbinando la stringa ovunque compaia nell’e‑mail.  
> - Quando vuoi tornare al board completo, cancella il contenuto della casella di ricerca.  
> 
> Questa funzionalità è descritta nella sezione *Search* di Leads.md.

**Q6** (1.2 s)

> I’m sorry, but I don’t have that information.  
> Please check the help documentation for more details.

**Q7** (2.9 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Accounts screen opened.

**Q8** (2.1 s)

> I need a few more details to create the lead:
> 
> * **Phone number** (Office Phone)
> * **Notes** (Anything worth remembering)
> 
> Could you provide those?

### qwen3-coder:30b

**warm-up** (28.5 s)

- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> Hello! I can help you with using this CRM application. 
> 
> I see you're on the Dashboard screen, which shows counts of leads for the active user, organized by status (New Leads, Active Leads, etc.). The numbers update when you return to the Dashboard from other screens.
> 
> Is there anything specific you'd like to do with the application? I can help you navigate or perform actions like creating leads, switching users, or viewing different sections.
> 
> I've opened the Leads screen for you. This is where you can see all the leads assigned to the active user, organized by their status. You can add new leads here or update existing ones.
> 
> The Leads board shows all your leads filtered by the currently selected user in the dropdown at the top of the window. If you need to create a new lead, I can help with that too.
> 
> Is there anything specific you'd like to do with the leads now?

**Q1** (5.4 s)

> To move a lead from one column to another on the Leads board, **drag and drop** the lead row from one column to another [^1].
> 
> When you move a lead:
> - It takes the **status** of the column you dropped it on.
> - If the date field for that stage is **empty**, it gets stamped with the current date:
>   - **Date Contacted** when moving to **Active**
>   - **Date Drafted** when moving to **Proposal Sent**
>   - **Date Closed** when moving to **Closed**
> - If the date field already has a value, it remains unchanged, so moving a lead back and forth does not rewrite its history [^1].
> 
> [^1]: Leads.md

**Q2** (5.7 s)

> Your data is stored in a single SQLite file named **w10crmdemo.sdb**, located in your **Documents** folder. This file is encrypted with AES-256.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete the file **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again.
> 
> The application will recreate the file with the original sample data, including 8 leads, 8 accounts, one user, and three proposals [^1].
> 
> [^1]: See [Data model](file:///C:/Users/USER/OneDrive/Documents/w10crmdemo.sdb) and [Getting started](file:///C:/Users/USER/OneDrive/Documents/w10crmdemo.sdb).

**Q3** (4.3 s)

> According to the documentation, **no**, you cannot change a proposal after saving it. The document is stored as it was generated. You can mark it *Accepted* or *Canceled*, but not edit it, and the lead cannot be given a second one.
> 
> To redo a proposal, you need to:
> 1. Delete the existing one from the **Sales** list using the navigator.
> 2. Create a new one.
> 
> Source: [FAQ.md](FAQ.md)

**Q4** (6.7 s)

- action `open_screen` {"name":"Marketing"} -> Opened the Marketing screen.

> According to the documentation, the export on the **Marketing** page writes a delimited text file with a header row, which can be opened directly in Excel [^1]. The exports on the **Accounts** and **Leads** pages write FireDAC's own format, meant to be read back by this application [^2].
> 
> To perform this action, I will open the Marketing screen.
> 
> The export on the **Marketing** page saves a delimited text file with a header row, which you can open directly in Excel [^1]. The exports on the **Accounts** and **Leads** pages write FireDAC's own format, meant to be read back by this application [^2].
> 
> To access this export, I have opened the Marketing screen for you.
> 
> [^1]: FAQ.md
> [^2]: Accounts.md

**Q5** (10.3 s)

- action `open_screen` {"name":"Leads"} -> Opened the Leads screen.

> Nella schermata **Leads**, puoi cercare un lead in base all’indirizzo email utilizzando la casella di ricerca.
> 
> La funzione di ricerca filtra tutte e quattro le colonne contemporaneamente mentre digiti. La ricerca è **insensibile a maiuscole/minuscole** e trova l’email **ovunque sia contenuta nel campo**.
> 
> ### Passaggi:
> 1. Vai alla schermata **Leads**.
> 2. Nella casella di ricerca, digita l'indirizzo email (ad esempio, `example.com`).
> 3. I lead che corrispondono saranno visualizzati immediatamente nella board.
> 
> Per ulteriori dettagli, consulta la sezione [Leads](https://github.com/your-docs/Leads.md).
> 
> Se desideri cercare un lead specifico per email, puoi anche utilizzare lo strumento `open_screen` per andare direttamente alla schermata **Leads**.
> 
> Nella schermata **Leads**, puoi cercare un lead in base all’indirizzo email utilizzando la casella di ricerca.
> 
> La funzione di ricerca filtra tutte e quattro le colonne contemporaneamente mentre digiti. La ricerca è **insensibile a maiuscole/minuscole** e trova l’email **ovunque sia contenuta nel campo**.
> 
> ### Passaggi:
> 1. Nella casella di ricerca, digita l'indirizzo email (ad esempio, `example.com`).
> 2. I lead che corrispondono saranno visualizzati immediatamente nella board.
> 
> Per ulteriori dettagli, consulta la sezione [Leads](https://github.com/your-docs/Leads.md).

**Q6** (1.3 s)

> I cannot provide weather information. The application helps you manage leads, accounts, proposals, and other CRM-related tasks, but it does not include a weather feature.
> 
> To see the current weather in Milan, you might want to check a dedicated weather website or app.<tool_call>

**Q7** (3.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open. You can view and manage the accounts listed in the application. Let me know if you need to perform any actions there.

**Q8** (7.2 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.
- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> The application needs to verify that the company "Apollo Orange, LLC." exists in the Accounts list before creating the lead. If it doesn't exist, the assistant will first add it.
> 
> Since the company name is not confirmed to be in the Accounts list, I will ask the assistant to add the company first.
> 
> I've opened the Accounts screen to check if "Apollo Orange, LLC." exists. If it doesn't, I'll need to add it first before creating the lead.
> 
> I've created the lead for Mario Rossi at Apollo Orange, LLC. The lead has been added to the Leads board with the status "New" and is ready for you to fill in additional details.

### claude

**warm-up** (2.8 s)

> Hello! I'm here to help you with the CRM application. 
> 
> You're currently on the **Dashboard**, which shows you a summary of your leads organized by status:
> 
> - **New** — leads nobody has contacted yet
> - **Active** — leads being worked on
> - **Proposal Sent** — leads waiting for an answer to a proposal
> - **Closed** — leads that ended, won or lost
> - **Inactive** — leads that are parked
> - **Total** — all your leads, whatever the status
> 
> These counts are filtered by the active user (you can select a different user from the drop-down in the title bar). The tiles update when you return to the Dashboard after making changes elsewhere.
> 
> What would you like to do? I can help you navigate the application or explain how to work with leads, accounts, proposals, and more.

**Q1** (2.7 s)

> Based on the Leads documentation:
> 
> **To move a lead:**
> Drag a row from one column and drop it on another.
> 
> **What happens to dates:**
> Two things occur when you move a lead:
> 
> 1. **The lead takes the status** of the column you dropped it on
> 2. **The stage date is stamped** — but only if it's empty:
>    - Date Contacted is stamped when moving to Active
>    - Date Drafted is stamped when moving to Proposal Sent
>    - Date Closed is stamped when moving to Closed
> 
> **Important:** A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history.
> 
> After every move, the lists refresh and the lead you dragged stays selected.

**Q2** (2.5 s)

> Your data is stored in a single encrypted file called **w10crmdemo.sdb** in your Documents folder. It's encrypted with AES-256 and contains all your leads, accounts, users, and proposals.
> 
> To start over with the sample data, follow these steps:
> 
> 1. **Close the application**
> 2. **Delete w10crmdemo.sdb** from your Documents folder
> 3. **Start the application again** — it will rebuild the file with the original sample data
> 
> That's the only way to reset everything. Note that the application has no transaction system and no undo/confirmation on most deletes, so there's no other way to recover deleted data.
> 
> ([Source: Data-Model.md](Data-Model.md) and [Getting-Started.md](Getting-Started.md))

**Q3** (1.7 s)

> No. According to the documentation, the document is stored as it was generated and cannot be edited after saving. You can mark it **Accepted** or **Canceled**, but not modify its contents, and the lead cannot be given a second proposal.
> 
> If you need to redo a proposal, you must:
> 1. Delete the existing one from the Sales list using the navigator
> 2. Create a new one from the lead detail window
> 
> [Source: FAQ.md](FAQ.md)

**Q4** (1.7 s)

> The export on the **Marketing page** gives you a file you can open in Excel — it writes a delimited text file with a header row that a spreadsheet opens directly.
> 
> The exports on the Accounts and Leads pages (like the one you're on now) write FireDAC's own format, which is meant to be read back by this application, not by Excel. ([Accounts.md](source))

**Q5** (2.8 s)

> Sulla schermata **Leads** dove sei ora, puoi usare il **Search box** per trovare un lead dal suo indirizzo e-mail.
> 
> Ecco come funziona:
> 
> 1. **Digita l'indirizzo e-mail** (o una parte di esso) nella casella di ricerca
> 2. La ricerca **filtra in tempo reale** mentre scrivi, cercando in tutte e quattro le colonne della board
> 3. La ricerca è **case-insensitive** e corrisponde a qualsiasi parte dell'indirizzo — ad esempio digitando `example.com` troverai tutti i lead con quell'indirizzo di dominio
> 
> La ricerca confronta il testo che digiti contro il nome del lead, il nome dell'azienda, il telefono dell'ufficio e l'e-mail. Per tornare alla visualizzazione completa della board, cancella la casella di ricerca.
> 
> Fonte: [Leads.md](Leads.md)

**Q6** (1.4 s)

> I can't help with that. I'm the help assistant for this CRM application, and I only have access to tools that operate within the application itself. I don't have access to weather information or the internet.
> 
> If you have questions about how to use this CRM application, I'm happy to help!

**Q7** (1.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open. This is where you can view and manage the companies in your CRM.

**Q8** (1.7 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Done. The lead has been created with status **New** and the detail window should now be open so you can fill in any additional information.

### gemini

**warm-up** (2.4 s)

> Hello! How can I help you with the application today?

**Q1** (5.2 s)

> To move a lead from one column to another on the Leads board:
> 
> * **Drag and drop:** Drag a row from one column and drop it onto another.
> 
> ### What happens to the lead and its dates:
> * The lead updates to the status of the column you dropped it into.
> * If the date for that stage is still empty, it is stamped with the current date/time:
>   * **Date Contacted** when moving to **Active**
>   * **Date Drafted** when moving to **Proposal Sent**
>   * **Date Closed** when moving to **Closed**
> * If a date already has a value, it is left untouched, so moving a lead back and forth does not overwrite its history.
> * Dropping a lead on the column it is already in does nothing. The lists refresh automatically, and the dragged lead remains selected.
> 
> Source: [Leads](Leads.md)

**Q2** (3.8 s)

> Your data is stored in a single SQLite file named **`w10crmdemo.sdb`** located in your **Documents** folder (encrypted with AES-256).
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. 
> 
> The application will rebuild the database file with the original sample records on startup.
> 
> For more details, see [Getting started](Getting-Started.md) and [Data model](Data-Model.md).

**Q3** (4.1 s)

> No. The document is stored as it was generated. You can mark it **Accepted** or **Canceled**, but you cannot edit it, and the lead cannot be given a second one. 
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator and create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (3.5 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row that can be opened directly in a spreadsheet like Excel. 
> 
> By contrast, the exports on the Accounts and Leads pages save in FireDAC's proprietary format (binary, XML, or JSON), which is only meant to be read back by this application.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (4.7 s)

> Per cercare un lead tramite il suo indirizzo e-mail nella schermata **Leads**:
> 
> 1. Digita l'indirizzo e-mail (o una parte di esso) nella casella **Search**.
> 2. La ricerca filtra automaticamente tutte e quattro le colonne della bacheca mentre scrivi, ignorando maiuscole/minuscole e cercando la corrispondenza in qualsiasi punto dell'indirizzo (ad esempio digitando `example.com` verranno mostrati tutti i lead corrispondenti).
> 3. Per tornare alla visualizzazione completa di tutti i lead, cancella il testo dalla casella di ricerca.
> 
> Fonte: [Leads.md](Leads.md)

**Q6** (4.1 s)

> I can only answer questions about using this CRM application. The provided documentation does not cover weather information. Please refer to [Home.md](Home.md) for information on what this application covers.

**Q7** (5.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen for you.

**Q8** (7.0 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for **Mario Rossi** under **Apollo Orange, LLC.** (e-mail: `mario.rossi@example.com`) with status **New**, and opened its detail window.

