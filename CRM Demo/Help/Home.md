# CRM Demo

A small customer-relationship manager: it keeps the **leads** you are working on, the
**accounts** they belong to, the **proposals** you send them, and the documents attached to
each one. Everything lives in a single encrypted SQLite file on your own machine, so the
application needs no server and no network.

![The main window](Images/dashboard.png)

## The main window

Four things are always on screen.

| Where | What it is |
| - | - |
| The dark strip on the left | The **navigation menu**: Dashboard, Accounts, Leads, Sales, Marketing, Calendar, Users. The ☰ button at the top collapses it to icons |
| The tabs along the top | The same seven sections. Clicking a tab and clicking a menu entry do the same thing |
| The banner under the tabs | The name of the section, and on the right the buttons that act on it, plus a **Search** box |
| The title bar | Two drop-downs: the **visual style** of the application, and the **active user** |

The window remembers nothing between runs: it opens maximized on the Dashboard.

## The active user is a filter, not a login

The drop-down on the right of the title bar chooses who you are working as. It is **not** a
login — there is no password — but it filters nearly everything: the leads, the proposals, the
documents and the marketing e-mails you see are only those whose `User` field matches the name
selected there, and the Dashboard counters are counted the same way.

Change it and the lists change under you. Any detail window that was open is closed first.

## Where your data is

On the first run the application creates `w10crmdemo.sdb` in your **Documents** folder, fills
it with the sample data this manual uses, and encrypts it with AES-256. From then on it opens
that file. Delete it and the next run builds a fresh one with the original sample data — which
is the simplest way to start over.

See [Data model](Data-Model.md) for what is inside it.

## Asking instead of reading

Press **F1** anywhere, or click the round button in the bottom right corner. The assistant
answers from these pages, and it can also do three things for you — open a screen, create a
lead, prepare a proposal — asking first whenever it is about to write something. See
[Asking the assistant](Assistant.md).

## Where to go next

- [Index](Index.md) — every page of this manual
- [Asking the assistant](Assistant.md) — the help built into the application
- [Leads](Leads.md) — the board where the work actually happens
- [Lead detail](Lead-Detail.md) — one lead, its documents and its proposal
- [FAQ](FAQ.md) — the questions that come up first
