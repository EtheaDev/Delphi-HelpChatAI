# HelpChatAI expertise benchmark

Run on 2026-11-14 15:37. Grounding: `CRM Demo\Help\help-index.json`, 3 pages; no actions; a new conversation per question; language English. Three system prompts per model: **v1** the library as it is (date only); **v2** name, date and time with the time zone, field of expertise ("B2B sales and customer relationship management: leads and the sales pipeline, accounts, proposals and invoicing, follow-up, sales reporting"), then the rules of the library; **v3** v2 plus the rule that the expertise explains concepts while the procedures of the application come only from the manual. Every answer graded by a judge model against the rubric of its question and the whole manual: *useful* 0-2, *invented* when it claims something of the application the manual does not have. *Pass* = useful 2 and nothing invented.

## Summary

| Target | Questions | Errors | Avg time | Avg useful | Invented | Pass |
|---|---:|---:|---:|---:|---:|---:|
| claude-haiku-5-5/v1 | 12 | 0 | 2.5 s | 1.25 | 0 | **3/12** |
| claude-haiku-5-5/v2 | 12 | 0 | 3.2 s | 1.25 | 0 | **3/12** |
| claude-haiku-5-5/v3 | 12 | 0 | 4.0 s | 1.58 | 0 | **7/12** |
| claude-sonnet-5-5/v1 | 12 | 0 | 4.2 s | 1.25 | 1 | **3/12** |
| claude-sonnet-5-5/v2 | 12 | 0 | 5.0 s | 1.25 | 0 | **3/12** |
| claude-sonnet-5-5/v3 | 12 | 0 | 5.8 s | 1.58 | 1 | **7/12** |
| claude-opus-5-5/v1 | 12 | 0 | 5.2 s | 1.33 | 0 | **4/12** |
| claude-opus-5-5/v2 | 12 | 0 | 5.5 s | 1.17 | 0 | **2/12** |
| claude-opus-5-5/v3 | 12 | 0 | 6.5 s | 1.83 | 0 | **10/12** |
| gemini-pro-latest/v1 | 12 | 0 | 5.4 s | 1.08 | 0 | **2/12** |
| gemini-pro-latest/v2 | 12 | 0 | 6.3 s | 1.17 | 0 | **2/12** |
| gemini-pro-latest/v3 | 12 | 0 | 8.5 s | 1.50 | 0 | **6/12** |
| gemini-3.5-flash-lite/v1 | 12 | 0 | 0.7 s | 1.08 | 0 | **1/12** |
| gemini-3.5-flash-lite/v2 | 12 | 0 | 0.8 s | 1.08 | 0 | **1/12** |
| gemini-3.5-flash-lite/v3 | 12 | 0 | 1.0 s | 0.92 | 0 | **1/12** |
| gpt-6-luna/v1 | 12 | 0 | 3.5 s | 1.17 | 0 | **2/12** |
| gpt-6-luna/v2 | 12 | 0 | 3.3 s | 1.17 | 0 | **2/12** |
| gpt-6-luna/v3 | 12 | 0 | 3.8 s | 1.25 | 0 | **3/12** |
| gpt-6.1-sol/v1 | 12 | 0 | 3.0 s | 1.17 | 0 | **2/12** |
| gpt-6.1-sol/v2 | 12 | 0 | 2.7 s | 1.33 | 0 | **4/12** |
| gpt-6.1-sol/v3 | 12 | 0 | 3.4 s | 1.58 | 0 | **7/12** |

## Passed, per question

Models that passed, out of 7.

| Question | v1 | v2 | v3 |
|---|---:|---:|---:|
| A1 | 0 | 0 | 5 |
| A2 | 0 | 0 | 4 |
| A3 | 0 | 0 | 2 |
| B1 | 0 | 0 | 0 |
| B2 | 0 | 0 | 1 |
| B3 | 0 | 0 | 0 |
| C1 | 4 | 3 | 6 |
| C2 | 1 | 0 | 5 |
| C3 | 7 | 6 | 7 |
| D1 | 5 | 6 | 4 |
| D2 | 0 | 1 | 6 |
| D3 | 0 | 1 | 1 |

## Questions

- **A1** (screen Sales): Should I add VAT to a proposal? The prices of my line items are net.
  - rubric: Explains net and gross and that VAT is computed on the net amount at the rate of the country (general practice). Says the draft has no VAT or tax field: the total is the sum of quantity x price, so VAT can only go in as a line item of its own or inside the prices.
- **A2** (screen Dashboard): How do I calculate the value of my sales pipeline?
  - rubric: Explains the (weighted) pipeline value: the open deals times the probability of their stage. In the application the amounts are the Value of the proposals still New on the Sales page, the stages are the columns of the board; there is no pipeline report or probability.
- **A3** (screen Leads): How long should a lead stay in Active before I consider it lost?
  - rubric: Says there is no universal rule and it depends on the sales cycle, with typical guidance (a number of unanswered follow-ups, a period). In the application Date Contacted tells how long it has been Active, and the lead is closed by dragging it to Closed (or set Inactive); nothing marks a lead lost automatically and there is no Lost status.
- **B1** (screen Sales): I want to do the month-end review of my sales: where do I look?
  - rubric: Reads month-end review as: proposals sent, won and lost in the month and how the pipeline moved. Points to the Sales page (Status, Value, DateCreated, DateCompleted) and the Dashboard (leads per status), and says there is no monthly report or date filter.
- **B2** (screen Sales): A customer asks for a 10% discount on the proposal. How do I do it?
  - rubric: Says there is no discount field: lower the prices of the line items, or add a line for the discount, and the total recomputes. Warns that a saved proposal cannot be edited, so the discount goes in before saving.
- **B3** (screen Leads): A lead has not answered my proposal for two weeks. What should I do?
  - rubric: Good follow-up practice (call or write, ask about the decision, agree a next step, close or park after repeated silence). In the application: Date Drafted says when the proposal went out, Notes in the lead detail record the follow-ups, Inactive parks the lead; the Call and Email buttons do nothing and there are no reminders or tasks.
- **C1** (screen Leads): How do I set up an automatic reminder for the leads I have not contacted for 30 days?
  - rubric: Says the application has no reminders or automation; the closest thing is checking the Active column and its Date Contacted by hand. Any reminder setup described is an invention.
- **C2** (screen Sales): Can you make me a sales forecast by quarter?
  - rubric: Explains briefly what a forecast is and that the application does not produce one; the Sales page has the values and dates of the proposals as raw material. Numbers presented as the data of the user are inventions.
- **C3** (screen Users): How do I calculate the payroll of my sales representative?
  - rubric: Outside the field of the assistant and of the application: declines in a sentence or two. Explaining how to compute payroll is a failure; so is claiming payroll or commissions in the application.
- **D1** (screen Sales): This proposal must be valid for 30 days from today. Until what date is it valid?
  - rubric: The correct date is Monday 14 December 2026 (today plus 30 days). The draft has no validity field; the date can only be written in a line item title (20 characters) or agreed outside.
- **D2** (screen Lead Detail): Is it too late right now to call a customer in New York?
  - rubric: It is about 09:25 in New York (UTC-5 in November; the answer may be up to an hour earlier, it was asked before this grading). A good answer works that out from the current time and judges it against business hours; without the current time the best it can do is say it does not know the time and give the offset (useful 1). The Call button of the lead does nothing.
- **D3** (screen Leads): Which leads did I create this month?
  - rubric: Knows that this month is November 2026. In the application only the New column shows Date Created (the other columns show the date of their stage) and the lead detail shows it for one lead; the search does not filter by date and there is no report.

## Verdicts

| Question | Target | Useful | Invented | Cited | Note |
|---|---|---:|---|---|---|
| A1 | claude-haiku-5-5/v1 | 1 | no | Draft-Proposal.md | Correctly says the total is just the sum of the line items, but skips net vs gross and VAT practice and never suggests adding VAT as its own line item or inside the prices. |
| A1 | claude-haiku-5-5/v2 | 1 | no | Draft-Proposal.md | Correctly says the total is just the sum of the line items, but it neither states plainly that there is no VAT field nor suggests adding VAT as its own line item, and gives no general net/gross guidance. |
| A1 | claude-haiku-5-5/v3 | 2 | no | Draft-Proposal.md | It correctly says the draft has no VAT field, the total is the sum of the line items, and VAT can be added as its own row, but it barely explains net vs gross, omits building VAT into the prices, and vaguely mentions a 'proposal's free text' that does not exist. |
| A1 | claude-sonnet-5-5/v1 | 1 | no | Draft-Proposal.md | Correctly says the draft has no tax field, that the total is the sum of line items, and that VAT could go in as an extra line item, but it skips the general explanation that VAT is computed on the net amount at the country's rate. |
| A1 | claude-sonnet-5-5/v2 | 1 | no | Draft-Proposal.md Data-Model.md | It correctly says the draft has no tax field and that VAT can go in as its own line item, but it gives no general explanation of net versus gross or how VAT is computed on the net amount at the country's rate. |
| A1 | claude-sonnet-5-5/v3 | 2 | no | Draft-Proposal.md | Correctly says the draft has no VAT or tax field and the total is just quantity × price, and gives the line-item workaround with the manual's buttons plus general net/gross and country-rate practice; it skips the option of putting VAT inside the prices. |
| A1 | claude-opus-5-5/v1 | 1 | no | Draft-Proposal.md | Line-item and total facts are correct, but it gives no general net/gross or VAT explanation, never states plainly that the draft has no tax field, and misses the workaround of a VAT line item or VAT-inclusive prices. |
| A1 | claude-opus-5-5/v2 | 1 | no | Draft-Proposal.md | Correctly says there is no tax field and the total is just quantity × price, but it skips net vs. gross, never suggests adding VAT as its own line item or inside the prices, and hedges where the manual is clear. |
| A1 | claude-opus-5-5/v3 | 2 | no | Draft-Proposal.md Sales.md | The answer correctly says the draft has no VAT or tax field and the total is quantity × price, and offers a separate VAT line item as the workaround. It gives sound general VAT guidance, and the vague hint to 'mention it in the text' falls short of claiming a feature. |
| A1 | gemini-pro-latest/v1 | 1 | no | - | Says only that the manual does not cover VAT. It could have explained net versus gross and that the draft has no tax field, so VAT can only go in as a separate line item or inside the prices. |
| A1 | gemini-pro-latest/v2 | 1 | no | Draft-Proposal.md | Correctly says the total is just quantity × price with no tax field, but declines to explain net/gross VAT practice or suggest adding VAT as its own line item. |
| A1 | gemini-pro-latest/v3 | 2 | no | Draft-Proposal.md | Correctly says the draft has no tax field and the total is the sum of line items, and gives accurate steps to add VAT as its own line item, though it never explains that VAT is the net total times the country's rate. |
| A1 | gemini-3.5-flash-lite/v1 | 1 | no | - | The answer only says the manual does not cover VAT. It misses the general net/gross explanation and that the draft has no tax field, so VAT can only go in as a separate line item or inside the prices. |
| A1 | gemini-3.5-flash-lite/v2 | 1 | no | Draft-Proposal.md | Correctly states the draft has no VAT field and the total is the sum of the line items, but it neither explains net versus gross VAT practice nor suggests adding VAT as its own line item. |
| A1 | gemini-3.5-flash-lite/v3 | 1 | no | Draft-Proposal.md | Correctly says the draft has no VAT field and the total is quantity × price, but only vaguely explains net, gross and VAT and never suggests adding VAT as its own line item or inside the prices. |
| A1 | gpt-6-luna/v1 | 1 | no | Draft-Proposal.md | It correctly notes there is no VAT field, but explains nothing about net and gross and gives no workaround, such as a separate VAT line item. |
| A1 | gpt-6-luna/v2 | 1 | no | Draft-Proposal.md | Correctly notes there is no VAT handling, but gives no net/gross explanation and does not suggest adding VAT as a line item, so it is only partial help. |
| A1 | gpt-6-luna/v3 | 1 | no | Draft-Proposal.md | Correctly says the draft has no VAT field, but it barely explains net/gross or VAT on the net at the country's rate, and misses that VAT can only go in as its own line item or inside the prices. |
| A1 | gpt-6.1-sol/v1 | 1 | no | Draft-Proposal.md | Correctly says there is no VAT field and the total is quantity × price, but it skips the general net/gross and VAT-rate explanation and never suggests adding VAT as its own line item or inside the prices. |
| A1 | gpt-6.1-sol/v2 | 1 | no | Draft-Proposal.md | Correctly says there is no VAT field and the total is quantity × price, but gives no general explanation of net vs gross or VAT, and no workaround such as a separate VAT line item. |
| A1 | gpt-6.1-sol/v3 | 2 | no | Draft-Proposal.md | The answer explains net, VAT and gross as general practice and correctly says the draft has no VAT field and the total is the sum of the line items. Its suggestion of a separate VAT line item fits the manual. |
| A2 | claude-haiku-5-5/v1 | 1 | no | Dashboard.md Sales.md | Accurately points to the Value column on Sales and the count-only Dashboard, but never explains the weighted pipeline method or that only proposals still New are open deals. |
| A2 | claude-haiku-5-5/v2 | 1 | no | Dashboard.md Sales.md | Correctly states that there is no pipeline figure and points to the Value column on Sales, but it never explains the weighted pipeline method or which proposals (status New) to add up. |
| A2 | claude-haiku-5-5/v3 | 2 | no | Dashboard.md Sales.md | The answer correctly says there is no pipeline report, points to summing the Value of New proposals on Sales, and explains weighting as general practice. |
| A2 | claude-sonnet-5-5/v1 | 1 | no | Sales.md Dashboard.md | Correctly says there is no pipeline report and points to the proposal Value and Status on Sales, but never explains the weighted pipeline method or suggests summing the open (New) proposals by board stage. |
| A2 | claude-sonnet-5-5/v2 | 1 | no | Dashboard.md Sales.md | Correctly says there is no pipeline report and points to the Value of the New proposals on Sales, but never explains the weighted pipeline method (open deal values times stage probability). |
| A2 | claude-sonnet-5-5/v3 | 2 | no | Dashboard.md Sales.md | Correctly says there is no pipeline report, points to summing the Value of New proposals on Sales, and explains the weighted pipeline as general practice with no probability field in the app. |
| A2 | claude-opus-5-5/v1 | 1 | no | Dashboard.md Sales.md | Correctly says there is no pipeline report and points to the Value of New proposals on Sales, but never explains the weighted method (open deal values times stage probability) or ties the stages to the board columns. |
| A2 | claude-opus-5-5/v2 | 1 | no | Sales.md Dashboard.md | Correctly says there is no pipeline total and points to adding up the Value of New proposals on Sales, but it never explains the weighted pipeline: stage probability times deal value. |
| A2 | claude-opus-5-5/v3 | 2 | no | Dashboard.md Sales.md | The answer correctly says there is no pipeline report, points to summing the Value of the New proposals on Sales, and explains weighted pipeline as general practice with no probability in the application. |
| A2 | gemini-pro-latest/v1 | 1 | no | Sales.md | Correctly points to the Value column on Sales and says there is no pipeline report, but explains no weighted-pipeline method and does not suggest summing the proposals still New. |
| A2 | gemini-pro-latest/v2 | 1 | no | Sales.md | Only says the manual does not cover it. It could have explained weighted pipeline value and pointed to the Value of the New proposals on Sales and the board stages. |
| A2 | gemini-pro-latest/v3 | 1 | no | Sales.md | It explains the weighted pipeline correctly and points to the Value column on Sales, but it does not say to sum only the proposals still New or tie the stages to the board columns. |
| A2 | gemini-3.5-flash-lite/v1 | 1 | no | Sales.md Dashboard.md Home.md | It only says the manual does not cover it, without explaining the weighted pipeline or pointing to the Value of the New proposals on the Sales page. |
| A2 | gemini-3.5-flash-lite/v2 | 1 | no | Sales.md | Correctly says there is no pipeline feature and points to the Value column on Sales, but omits the weighted-pipeline method and the practical steps (sum Value of New proposals, stages as board columns). |
| A2 | gemini-3.5-flash-lite/v3 | 1 | no | Dashboard.md Sales.md | Correctly says there is no pipeline calculation and points to the proposal Value on Sales, but omits probability weighting and summing only the proposals still New. |
| A2 | gpt-6-luna/v1 | 1 | no | Sales.md Dashboard.md | Correctly says there is no pipeline total and points to proposal Values on Sales, but never explains how to calculate it (open New proposals, weighted by stage probability) as the rubric expects. |
| A2 | gpt-6-luna/v2 | 1 | no | Dashboard.md Sales.md | Correctly points to the proposal Value on the Sales page and says the Dashboard only counts leads, but it gives no weighted-pipeline method (open proposals still New times stage probability), which an expert would have explained. |
| A2 | gpt-6-luna/v3 | 1 | no | Dashboard.md Sales.md | Correctly says there is no pipeline report and explains weighted pipeline as general practice, but never says to sum only the Value of proposals still in New status, nor links stages to the board columns. |
| A2 | gpt-6.1-sol/v1 | 1 | no | Dashboard.md Sales.md | Correctly says there is no pipeline report and points to proposal Value on Sales, but does not explain the weighted pipeline concept or that open proposals (status New) are what to sum. |
| A2 | gpt-6.1-sol/v2 | 1 | no | Dashboard.md Sales.md | Accurate about the app (no pipeline report, proposal Values on Sales), but it never explains the weighted pipeline or that open New proposals are the amounts to sum, so it stays partial. |
| A2 | gpt-6.1-sol/v3 | 2 | no | Dashboard.md Sales.md | Explains pipeline and weighted pipeline as general practice, then points to the Value of New proposals on Sales and correctly says there is no pipeline calculation. |
| A3 | claude-haiku-5-5/v1 | 1 | no | Leads.md | Declines to give general sales guidance (no rule of thumb, sales-cycle dependence) and doesn't mention Date Contacted, Closed or Inactive as the way to park or close a lead; what it states is accurate. |
| A3 | claude-haiku-5-5/v2 | 1 | no | Leads.md | It rightly says there is no built-in threshold or Lost status and points to Date Contacted, but gives no typical sales guidance, does not explain closing via drag to Closed or Inactive, and wrongly says the manual is silent on lost leads when the Dashboard defines Closed as won or lost. |
| A3 | claude-haiku-5-5/v3 | 1 | no | Leads.md | Correct that there is no automatic rule or Lost status, and it gives sales-cycle guidance and the drag-to-Closed step, but it omits Date Contacted for measuring time in Active and the Inactive option. |
| A3 | claude-sonnet-5-5/v1 | 1 | **yes** | Leads.md | It gives no domain guidance on a cutoff or on closing the lead as Closed/Inactive, and it misstates the app: Date Contacted is stamped the first time a lead reaches Active, not 'last contacted', and the Status field in the detail window also moves a lead. |
| A3 | claude-sonnet-5-5/v2 | 1 | no | Leads.md | The app facts are correct (no Lost status, Date Contacted shows time in Active, leads move by dragging), but it gives no typical sales-cycle guidance and does not say to close the lead by dragging it to Closed or setting it Inactive. |
| A3 | claude-sonnet-5-5/v3 | 1 | **yes** | Leads.md | Sound sales advice, and it correctly covers Date Contacted, dragging to Closed and the absence of a Lost status, but it skips Inactive, misreads Date Contacted as last activity, and claims the assistant can fill in notes when creating a lead, which the manual does not say. |
| A3 | claude-opus-5-5/v1 | 1 | no | Leads.md | The app facts are correct (Date Contacted shows time in Active, drag to Closed, no lost status), but it gives no typical sales-cycle guidance and does not mention the Inactive option. |
| A3 | claude-opus-5-5/v2 | 1 | no | Leads.md | The app facts are accurate: Date Contacted in the Active column, no Lost status, drag to Closed. But it gives no typical sales-cycle guidance (follow-up count or time period) and skips the Inactive option. |
| A3 | claude-opus-5-5/v3 | 2 | no | Leads.md | Correctly says there is no time limit, no automatic loss marking and no Lost status, points to Date Contacted and dragging to Closed, and gives sound general guidance labelled as such; it only leaves out the Inactive option. |
| A3 | gemini-pro-latest/v1 | 1 | no | - | Only says the manual doesn't cover it; it gives no general sales-cycle guidance and does not mention Date Contacted, moving the lead to Closed or Inactive, or the absence of automatic loss marking. |
| A3 | gemini-pro-latest/v2 | 1 | no | - | It refuses outright, offering no general sales guidance and none of the relevant app facts: Date Contacted, dragging to Closed or Inactive, and the absence of a Lost status or automatic marking. |
| A3 | gemini-pro-latest/v3 | 2 | no | Leads.md | Gives sensible general guidance and correctly says nothing expires automatically and lost leads are dragged to Closed, though it omits Date Contacted, the Inactive option and the lack of a Lost status. |
| A3 | gemini-3.5-flash-lite/v1 | 1 | no | Leads.md | The answer only says the manual doesn't cover it; it gives no sales-cycle guidance and doesn't mention Date Contacted, closing the lead by dragging it to Closed, or setting it Inactive. |
| A3 | gemini-3.5-flash-lite/v2 | 1 | no | - | Only says the manual does not cover it, giving no general guidance and not mentioning Date Contacted, closing by drag to Closed or Inactive, or the absence of a Lost status. |
| A3 | gemini-3.5-flash-lite/v3 | 1 | no | Leads.md | Gives vague general sales guidance but omits the app specifics: Date Contacted shows time in Active, the lead is closed by dragging it to Closed or set Inactive, and there is no automatic or Lost status. |
| A3 | gpt-6-luna/v1 | 1 | no | Leads.md | The answer only says the manual doesn't specify a duration; it gives no general sales-cycle guidance and skips Date Contacted and closing the lead by dragging it to Closed or setting it Inactive. |
| A3 | gpt-6-luna/v2 | 1 | no | Leads.md | Correct but minimal: it gives no general sales guidance and does not mention Date Contacted, closing the lead by dragging it to Closed or Inactive, or that there is no automatic Lost status. |
| A3 | gpt-6-luna/v3 | 1 | no | Leads.md | It correctly notes there is no Lost status and gives sound general guidance, but omits that Date Contacted shows time in Active and that you close a lead by dragging it to Closed or setting it Inactive. |
| A3 | gpt-6.1-sol/v1 | 1 | no | Leads.md | Correctly says the manual sets no time limit and points to Date Contacted, but it gives no general sales-cycle guidance and does not explain closing the lead by dragging it to Closed or setting it Inactive. |
| A3 | gpt-6.1-sol/v2 | 1 | no | Leads.md | Correctly points to dragging the lead to Closed, but gives no general sales guidance and does not mention Date Contacted, Inactive, or that there is no automatic or Lost status. |
| A3 | gpt-6.1-sol/v3 | 1 | no | Leads.md | Gives sound general guidance, correctly says there is no Lost status and that leads are closed by dragging, but omits Date Contacted for timing, the Inactive option and that nothing closes leads automatically. |
| B1 | claude-haiku-5-5/v1 | 1 | no | Sales.md Calendar.md | Correctly points to the Sales columns and says there is no month filter, but it misses the Dashboard's leads-per-status counts and wrongly claims the user is already on the Sales screen. |
| B1 | claude-haiku-5-5/v2 | 1 | no | Sales.md ToDo.md | Correctly points to the Sales columns and the Calendar's lack of data, but wrongly says the user is already on Sales, omits the Dashboard, and hedges instead of stating there is no monthly report or date filter. |
| B1 | claude-haiku-5-5/v3 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and says there is no month filter or report, but it leaves out the Dashboard's per-status lead counts that show how the pipeline moved. |
| B1 | claude-sonnet-5-5/v1 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and says there is no monthly filter or report, but it skips the Dashboard's leads-per-status view and wrongly claims the user is already on Sales. |
| B1 | claude-sonnet-5-5/v2 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and says there is no date filter or report, but it wrongly assumes the user is already on Sales and leaves out the Dashboard for how the pipeline moved. |
| B1 | claude-sonnet-5-5/v3 | 1 | no | Sales.md Calendar.md | Correctly points to the Sales columns and notes there is no month filter or total, but it omits the Dashboard pipeline view and wrongly says the user is already on the Sales screen when the context only says MainForm. |
| B1 | claude-opus-5-5/v1 | 1 | no | Sales.md Calendar.md ToDo.md | It correctly points to the Sales columns and says there is no date filter or report, but it leaves out the Dashboard status counts and wrongly says the user is already on Sales. |
| B1 | claude-opus-5-5/v2 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and says there is no monthly report or date filter, but it leaves out the Dashboard for pipeline movement and wrongly says the user is already on Sales. |
| B1 | claude-opus-5-5/v3 | 1 | no | Sales.md Calendar.md ToDo.md | Accurately covers the Sales page columns and correctly says there is no monthly report or date filter, but it omits the Dashboard's leads-per-status view of the pipeline and wrongly says the user is already on the Sales screen. |
| B1 | gemini-pro-latest/v1 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and notes there is no month filter, but it wrongly says the user is on the Sales screen and omits the Dashboard counts and the lack of any monthly report. |
| B1 | gemini-pro-latest/v2 | 1 | no | Sales.md | Correctly points to the Sales columns and says there is no monthly report or date filter, but it skips the Dashboard's leads-per-status view and wrongly assumes the user is already on Sales. |
| B1 | gemini-pro-latest/v3 | 1 | no | Sales.md | Rightly points to the Sales page and its Status and DateCompleted columns, but the answer is cut off, wrongly says the user is already on Sales, and omits the Value column, the Dashboard and the lack of any monthly report or date filter. |
| B1 | gemini-3.5-flash-lite/v1 | 1 | no | Sales.md | Correctly points to the Sales list and its Status, Value, DateCreated and DateCompleted columns, but omits the Dashboard status counts and never says there is no monthly report or date filter. |
| B1 | gemini-3.5-flash-lite/v2 | 1 | no | Sales.md | Correctly points to the Sales page and its columns, but omits the Dashboard and that there is no monthly report or date filter. |
| B1 | gemini-3.5-flash-lite/v3 | 1 | no | Sales.md Calendar.md | Correctly points to the Sales page and its columns, but omits the Dashboard status counts and never says there is no monthly report or date filter. |
| B1 | gpt-6-luna/v1 | 1 | no | Sales.md | It correctly points to the Sales list and its columns, but omits the Dashboard and never says there is no monthly report or date filter. |
| B1 | gpt-6-luna/v2 | 1 | no | Sales.md | Correctly points to the Sales list and notes that search cannot narrow it to a month, but omits the Dashboard's per-status counts and never says outright that no monthly report exists. |
| B1 | gpt-6-luna/v3 | 1 | no | Sales.md ToDo.md | It correctly points to the Sales page and notes there is no monthly report or date filter, but it omits the Dashboard's per-status lead counts for reviewing the pipeline. |
| B1 | gpt-6.1-sol/v1 | 1 | no | Sales.md Calendar.md | Correctly points to Sales and its Status, Value, DateCreated and DateCompleted columns, but omits the Dashboard counts, never says plainly that there is no monthly report or date filter, and wrongly says the user is already on Sales. |
| B1 | gpt-6.1-sol/v2 | 1 | no | Sales.md | Rightly points to Sales and its Status/Value/DateCreated/DateCompleted columns, but leaves out the Dashboard counts by status and never says there is no monthly report or date filter; it also wrongly assumes the user is already on Sales. |
| B1 | gpt-6.1-sol/v3 | 1 | no | Sales.md Calendar.md | Correctly points to the Sales columns and says there is no monthly report or date filter, but it omits the Dashboard's leads-per-status counts and wrongly claims the user is already on Sales. |
| B2 | claude-haiku-5-5/v1 | 1 | no | Draft-Proposal.md ToDo.md | Correctly warns that the discount must go in before saving, but hedges about a discount option the manual shows does not exist and never suggests lowering the line-item prices or adding a discount line. |
| B2 | claude-haiku-5-5/v2 | 1 | no | Draft-Proposal.md ToDo.md | Correctly says there is no discount field and that a saved proposal cannot be edited, but misses the obvious workaround of lowering the line-item prices or adding a discount line so the total recomputes. |
| B2 | claude-haiku-5-5/v3 | 1 | no | Draft-Proposal.md ToDo.md | It rightly says there is no discount field and warns to set prices before saving, but it wrongly doubts that line-item prices are editable, omits the discount-line option, and misses the FAQ's delete-and-recreate route for a saved proposal. |
| B2 | claude-sonnet-5-5/v1 | 1 | no | Draft-Proposal.md ToDo.md | It correctly says there is no discount feature and that a saved proposal cannot be edited, but it never suggests lowering the line item prices or adding a discount line before saving, and it misses that the FAQ explains how to delete and redo a proposal. |
| B2 | claude-sonnet-5-5/v2 | 1 | no | Draft-Proposal.md ToDo.md Sales.md | Correctly says there is no discount field and that a saved proposal cannot be edited, but it does not suggest lowering the line item prices or adding a discount line. It also misses the FAQ's way to redo a proposal: delete it from Sales and create a new one. |
| B2 | claude-sonnet-5-5/v3 | 1 | no | ToDo.md Sales.md Draft-Proposal.md | It correctly says there is no discount field, to enter discounted prices in the line items, and that saved proposals can't be edited, but it hedges, never says the total recomputes, and wrongly claims it can't explain replacing an existing proposal, which the FAQ covers by deleting it from Sales and creating a new one. |
| B2 | claude-opus-5-5/v1 | 1 | no | ToDo.md Sales.md Draft-Proposal.md | It correctly says a saved proposal can't be edited and the total comes from the line items, but it never suggests lowering the prices or adding a discount line before saving, and it misses that you can delete the proposal and redo it. |
| B2 | claude-opus-5-5/v2 | 1 | no | ToDo.md Sales.md Draft-Proposal.md | It rightly says there is no discount option and that a saved proposal cannot be edited, but it never suggests lowering the line-item prices or adding a discount line, nor deleting and redoing the proposal as the FAQ explains. |
| B2 | claude-opus-5-5/v3 | 2 | no | Draft-Proposal.md Sales.md ToDo.md | Correctly says there is no discount option, advises lowering line item prices before saving, and warns that saved proposals cannot be edited; it misses the FAQ route of deleting the proposal from Sales and redrafting it, but invents nothing. |
| B2 | gemini-pro-latest/v1 | 1 | no | ToDo.md | Correctly says a saved proposal cannot be edited, but omits how to apply the discount: lower the line-item prices or add a discount line before saving, or delete and redo the proposal. |
| B2 | gemini-pro-latest/v2 | 1 | no | ToDo.md | Correctly says a saved proposal cannot be edited, but wrongly concludes a discount is impossible: it omits lowering the line-item prices or adding a discount line before saving, and deleting and redoing an existing proposal. |
| B2 | gemini-pro-latest/v3 | 1 | no | ToDo.md | It correctly says a saved proposal cannot be edited, but gives no way to apply the discount: lower the line-item prices or add a discount line before saving, or delete the proposal and redo it. |
| B2 | gemini-3.5-flash-lite/v1 | 1 | no | ToDo.md | It correctly says a saved proposal cannot be edited, but it never explains how to apply the discount: there is no discount field, so lower the line prices or add a discount line before saving, or delete and redo the proposal. |
| B2 | gemini-3.5-flash-lite/v2 | 1 | no | ToDo.md | It correctly warns that a saved proposal cannot be edited, but never explains how to apply the discount: there is no discount field, so lower the line-item prices or add a discount line before saving. |
| B2 | gemini-3.5-flash-lite/v3 | 1 | no | ToDo.md Draft-Proposal.md Sales.md | It correctly says a saved proposal cannot be edited, but never explains how to apply the discount (lower the line-item prices or add a discount line before saving), and its generic 'cancel and redraft' advice misses that the app needs the old proposal deleted from Sales first. |
| B2 | gpt-6-luna/v1 | 1 | no | Draft-Proposal.md ToDo.md | Mentions line items, the total and that saved proposals can't be edited, but stops at 'not documented' without suggesting lowering the prices or adding a discount line before saving. |
| B2 | gpt-6-luna/v2 | 1 | no | ToDo.md | It correctly says there is no discount feature and that a saved proposal cannot be edited, but it misses the workaround of lowering line-item prices or adding a discount line before saving. |
| B2 | gpt-6-luna/v3 | 1 | no | Draft-Proposal.md ToDo.md | Correctly says there is no discount option and that a saved proposal cannot be edited, but gives no workaround such as lowering the line-item prices or adding a discount line before saving. |
| B2 | gpt-6.1-sol/v1 | 1 | no | ToDo.md | Correctly warns that saved proposals cannot be edited, but omits the workaround of lowering line-item prices or adding a discount line in the draft (and deleting and recreating a saved one). |
| B2 | gpt-6.1-sol/v2 | 1 | no | ToDo.md Draft-Proposal.md | Correctly warns that a saved proposal cannot be edited, but misses the workaround of lowering the line item prices or adding a discount line in the draft, and the option to delete and redo a saved proposal. |
| B2 | gpt-6.1-sol/v3 | 1 | no | ToDo.md Sales.md | It correctly warns that a saved proposal cannot be edited, but for a draft it misses the obvious advice to lower the line-item prices or add a discount line so the total recomputes, and it skips the FAQ's delete-and-redo route. |
| B3 | claude-haiku-5-5/v1 | 1 | no | Leads.md | Accurate but thin: it gives no follow-up advice and misses Date Drafted, Notes for logging follow-ups, Inactive for parking the lead, and the non-working Call/Email buttons. |
| B3 | claude-haiku-5-5/v2 | 1 | no | Leads.md | The Proposal Sent column, Date Drafted and drag-to-Closed details are correct, but it gives no follow-up advice, never mentions Notes or the inert Call/Email buttons, and wrongly says the manual doesn't explain setting Inactive (the Status field in the lead detail does). |
| B3 | claude-haiku-5-5/v3 | 1 | no | Leads.md | The follow-up advice and the Proposal Sent, Date Drafted, drag-to-column and no-reminders points are correct, but it leaves out logging follow-ups in Notes, parking the lead as Inactive via the Status field, and that the Call/Email buttons do nothing. |
| B3 | claude-sonnet-5-5/v1 | 1 | no | Leads.md | The app facts are accurate, but it gives no follow-up advice and misses Notes for logging follow-ups, the dead Call/Email buttons, the lack of reminders, and that Inactive can be set from the Status field in the lead detail. |
| B3 | claude-sonnet-5-5/v2 | 1 | no | Leads.md | Correctly points to Date Drafted and the Inactive status, but gives no follow-up advice and misses that Inactive is set from the Status field in the lead detail. |
| B3 | claude-sonnet-5-5/v3 | 1 | no | Leads.md | The follow-up advice is sound, and the Date Drafted, Closed and Inactive points are correct, but it omits Notes for logging follow-ups, that the Call and Email buttons do nothing, and how to set Inactive, and it hedges on reminders. |
| B3 | claude-opus-5-5/v1 | 1 | no | Leads.md | The application facts are correct (Proposal Sent column, Date Drafted, dragging to Closed, no reminders), but the answer gives no follow-up advice, omits Notes and the dead Call/Email buttons, and wrongly says the manual does not explain how to set Inactive, when the Status field in the lead detail does it. |
| B3 | claude-opus-5-5/v2 | 1 | no | Leads.md | Correctly uses Proposal Sent, Date Drafted and drag-to-Closed and notes there are no reminders, but it gives no actual follow-up advice, omits recording follow-ups in Notes, and wrongly says the manual doesn't explain setting Inactive, though the Status field in the lead detail does it. |
| B3 | claude-opus-5-5/v3 | 1 | no | Leads.md | Sound follow-up advice and correct app facts (Date Drafted, Closed, Inactive, no reminders), but it wrongly says there is no way to log calls when the lead's Notes field serves that purpose, and it omits that the Call/Email buttons do nothing. |
| B3 | gemini-pro-latest/v1 | 1 | no | Leads.md | Says the manual does not cover it and gives no follow-up advice or practical pointers (Date Drafted, Notes, parking as Inactive, Call/Email do nothing), though it correctly mentions Proposal Sent and Inactive. |
| B3 | gemini-pro-latest/v2 | 1 | no | Leads.md | The answer refuses to give follow-up advice and skips Date Drafted, Notes, Inactive and the dead Call/Email buttons, all of which the manual covers; what it does say is accurate. |
| B3 | gemini-pro-latest/v3 | 1 | no | - | The answer is cut off after a generic 'follow up' and mentions none of the app's relevant features (Date Drafted, Notes, Inactive status, Call/Email placeholders, no reminders). |
| B3 | gemini-3.5-flash-lite/v1 | 1 | no | Leads.md | Correct but thin: it gives no follow-up advice and leaves out Date Drafted, Notes for recording follow-ups, Inactive for parking the lead, and the fact that Call/Email do nothing. |
| B3 | gemini-3.5-flash-lite/v2 | 1 | no | - | It only says the manual does not cover this, though general follow-up advice and the manual's Date Drafted, Notes and Inactive status could have helped. |
| B3 | gemini-3.5-flash-lite/v3 | 1 | no | Leads.md | Gives generic follow-up advice and the statuses, but misses Date Drafted, logging follow-ups in Notes, parking the lead as Inactive and the non-working Call/Email buttons. |
| B3 | gpt-6-luna/v1 | 1 | no | Leads.md | Correct but it only says the manual has no guidance, with no follow-up advice and no mention of Date Drafted, Notes or the Inactive status. |
| B3 | gpt-6-luna/v2 | 1 | no | Leads.md | Accurate but stops at saying the manual has no follow-up guidance, when it could have given basic follow-up advice and pointed to Date Drafted, Notes and the Inactive status. |
| B3 | gpt-6-luna/v3 | 1 | no | Leads.md | The sales advice is sound, but it wrongly says the manual cannot help: it misses Notes for logging follow-ups, Date Drafted for the send date, Inactive for parking the lead, and that Call/Email do nothing and there are no reminders. |
| B3 | gpt-6.1-sol/v1 | 1 | no | Leads.md | Correct but minimal: it gives no follow-up advice and leaves out Date Drafted, Notes, Inactive and the fact that the Call and Email buttons do nothing. |
| B3 | gpt-6.1-sol/v2 | 1 | no | Leads.md | Correct but gives no follow-up advice and leaves out the relevant app pieces: Date Drafted, Notes, the Inactive status, and the fact that the Call/Email buttons do nothing and there are no reminders. |
| B3 | gpt-6.1-sol/v3 | 1 | no | Leads.md | Sound general follow-up advice and correct about the Proposal Sent status, but it omits Date Drafted, logging follow-ups in Notes, parking the lead as Inactive, and that the Call/Email buttons do nothing and there are no reminders. |
| C1 | claude-haiku-5-5/v1 | 2 | no | Leads.md | Correctly says there is no reminder feature and points to the New and Active columns' dates as a manual check; it only hedges a little by saying the documentation doesn't cover it. |
| C1 | claude-haiku-5-5/v2 | 2 | no | Leads.md | It correctly gives no reminder setup and points to checking Date Contacted on the Active column by hand, though it hedges with 'not covered' instead of plainly saying the feature does not exist. |
| C1 | claude-haiku-5-5/v3 | 2 | no | Leads.md | Correctly says the manual describes no reminders and points to scanning the Date Created/Date Contacted columns on the Leads board, consistent with the manual. |
| C1 | claude-sonnet-5-5/v1 | 2 | no | Leads.md Dashboard.md | Correctly states that the manual describes no reminders and points to scanning Date Contacted in the Active column by hand, all as documented. |
| C1 | claude-sonnet-5-5/v2 | 2 | no | Leads.md Dashboard.md | Correctly says there are no reminders and points to checking Date Contacted on the Active column by hand, though that date records the first contact, not the last. |
| C1 | claude-sonnet-5-5/v3 | 2 | no | Leads.md Dashboard.md | Correctly says there is no reminder feature and points to checking Date Contacted on the Active column by hand, with the routine clearly labelled as general practice, though it hedges where it could state plainly that no such feature exists. |
| C1 | claude-opus-5-5/v1 | 2 | no | Leads.md | Correctly says there are no reminders and points to checking the New and Active columns and their dates by hand, all as described in the manual. |
| C1 | claude-opus-5-5/v2 | 1 | no | Leads.md | It gives the right manual workaround (New and Active columns with their dates) but hedges with 'can't tell whether' instead of saying the application has no reminders or automation. |
| C1 | claude-opus-5-5/v3 | 2 | no | Leads.md | Correctly says the manual describes no reminders, points to Date Contacted in the Active column and Date Created in New, and labels the advice as general practice; small nuance: Date Contacted is the first contact, not the last. |
| C1 | gemini-pro-latest/v1 | 1 | no | - | Correctly invents nothing, but only says the docs lack it instead of stating there are no reminders and pointing to the Active column's Date Contacted as a manual check. |
| C1 | gemini-pro-latest/v2 | 1 | no | Leads.md | It correctly invents nothing, but it only says the documentation doesn't cover this, instead of stating that the app has no reminders and pointing to checking Date Contacted on the Active column by hand. |
| C1 | gemini-pro-latest/v3 | 2 | no | Leads.md | Correctly states there are no automatic reminders and points to manually checking the New column's Date Created and the Active column's Date Contacted, as the manual describes. |
| C1 | gemini-3.5-flash-lite/v1 | 1 | no | Leads.md | It correctly invents no reminder feature, but it only says the manual does not cover it, without stating that the application has no reminders or pointing to checking Date Contacted on the board by hand. |
| C1 | gemini-3.5-flash-lite/v2 | 1 | no | Leads.md Dashboard.md FAQ.md | Correctly avoids inventing a reminder feature, but only says the documentation does not cover it instead of stating there are no reminders and pointing to checking the Active column's Date Contacted by hand. |
| C1 | gemini-3.5-flash-lite/v3 | 1 | no | Leads.md | Correctly says there are no automatic reminders, but omits the manual workaround of checking Date Contacted in the Active column on the Leads board. |
| C1 | gpt-6-luna/v1 | 1 | no | Leads.md | Correctly avoids inventing a reminder feature and points to Date Contacted on the Active column, but only says it is not documented rather than plainly stating the application has no reminders and that checking by hand is the workaround. |
| C1 | gpt-6-luna/v2 | 1 | no | Leads.md | It correctly finds no reminder feature, but only says the manual does not cover it; it does not say plainly that no automation exists or suggest checking Date Contacted by hand on the board. |
| C1 | gpt-6-luna/v3 | 2 | no | Leads.md | Correctly says there are no automatic reminders and points to manually checking Date Contacted in the Active column, as the rubric expects. |
| C1 | gpt-6.1-sol/v1 | 2 | no | Leads.md | Correctly says there are no automatic reminders and points to checking the Active column's Date Contacted by hand, though it only says the manual 'does not cover' reminders rather than plainly that they do not exist. |
| C1 | gpt-6.1-sol/v2 | 2 | no | Leads.md | Correctly gives no reminder setup and points to the Active column's Date Contacted for manual review, though it hedges with 'not covered' rather than stating plainly that the feature does not exist. |
| C1 | gpt-6.1-sol/v3 | 2 | no | Leads.md | Correctly says no reminders or 30-day filter exist, points to the Active column's Date Contacted and the New column, and labels the weekly-review tip as general practice. |
| C2 | claude-haiku-5-5/v1 | 1 | no | Sales.md | Correctly says the application produces no forecast and points to the Sales list's Value and dates, but it does not explain what a quarterly forecast is or how to build one from that data. |
| C2 | claude-haiku-5-5/v2 | 1 | no | Sales.md | Correctly points to the Value, dates and Status columns of Sales as raw material, but it never explains what a quarterly forecast would involve and hedges on grouping, which the manual shows does not exist. |
| C2 | claude-haiku-5-5/v3 | 2 | no | Sales.md | Correctly says the application has no forecast, points to the Sales values and dates as raw material, and presents forecasting practice as general knowledge without inventing figures. |
| C2 | claude-sonnet-5-5/v1 | 1 | no | Sales.md | It correctly says there is no forecast feature and points to the Value and date columns on Sales, but it never explains what a forecast is or how to build one from those figures. |
| C2 | claude-sonnet-5-5/v2 | 1 | no | Sales.md | Correctly says there is no forecast feature and points to the Sales columns, but never explains what a quarterly forecast is or how to build one from those values and dates. |
| C2 | claude-sonnet-5-5/v3 | 2 | no | Sales.md Data-Model.md | It correctly says the app has no forecast and cannot read the data, points to the Sales columns (Value, Status, dates) as raw material, and labels the quarterly method as general practice. |
| C2 | claude-opus-5-5/v1 | 2 | no | Sales.md | Correctly says the app has no forecasting and points to the Sales columns (Value, Status, dates) as raw material; it skips what a forecast is and wrongly assumes the user is on Sales. |
| C2 | claude-opus-5-5/v2 | 1 | no | Sales.md | Correctly says the application has no forecast and points to the Sales list's values, statuses and dates, but never explains what a forecast is or how to build one from that data. |
| C2 | claude-opus-5-5/v3 | 2 | no | Sales.md | Correctly says the app has no forecast, points to the Sales columns (Value, Status, dates) as raw material, and gives a hand method clearly labelled as general practice without making up figures. |
| C2 | gemini-pro-latest/v1 | 1 | no | Sales.md | Correctly avoids claiming a forecast feature but only says the manual doesn't cover it, without explaining what a forecast is or pointing to the proposal values and dates on the Sales page as raw material. |
| C2 | gemini-pro-latest/v2 | 1 | no | Sales.md | Correctly says no forecast exists, but stops there: it doesn't explain what a forecast is or that the Sales page's proposal values and dates could serve as raw material. |
| C2 | gemini-pro-latest/v3 | 2 | no | Sales.md | Correctly defines a forecast, says the app has none, and points to the Sales list of proposal values; the claim that the user is already on Sales is a minor slip, not an invented feature. |
| C2 | gemini-3.5-flash-lite/v1 | 1 | no | Sales.md | It says only that the manual does not cover a forecast; it does not explain what one is, and it does not point to the Sales page values and dates as raw material. |
| C2 | gemini-3.5-flash-lite/v2 | 1 | no | Sales.md ToDo.md Data-Model.md | Correctly says no forecast feature exists, but does not explain what a forecast is or point to the proposal values and dates on the Sales page as raw material. |
| C2 | gemini-3.5-flash-lite/v3 | 0 | no | - | The answer is a leaked instruction rather than a reply, and wrongly calls a CRM question off-topic instead of explaining that no forecast exists and pointing to the proposal values and dates on the Sales page. |
| C2 | gpt-6-luna/v1 | 1 | no | Sales.md | The answer correctly says no forecast exists and points to the values and dates on the Sales page, but it does not explain what a forecast is or how to build one from that data. |
| C2 | gpt-6-luna/v2 | 1 | no | Sales.md | Correctly says the app has no forecast or quarterly report and points to the Sales values and dates, but does not explain what a forecast is or how to build one from that data. |
| C2 | gpt-6-luna/v3 | 1 | no | Sales.md | It correctly says the application has no forecast feature and points to proposal values, statuses and dates on Sales, but it does not explain what a quarterly forecast involves or how to build one from that data. |
| C2 | gpt-6.1-sol/v1 | 1 | no | Sales.md | Correctly says there is no forecast feature and points to the Sales page with values and dates as raw material, but never explains what a forecast is or how to build one from that data. |
| C2 | gpt-6.1-sol/v2 | 1 | no | Sales.md | Correctly says the app has no forecasting and points to the Sales list's values and dates, but it never explains what a quarterly forecast is or how to build one from those proposals. |
| C2 | gpt-6.1-sol/v3 | 2 | no | Sales.md | Correctly says no forecast feature exists, points to the Sales page values and dates as raw material, and briefly explains what a forecast needs as general practice, without inventing any data. |
| C3 | claude-haiku-5-5/v1 | 2 | no | Sales.md | It declines correctly, without explaining payroll or claiming payroll or commission features, and its pointer to the Sales list matches the manual. |
| C3 | claude-haiku-5-5/v2 | 2 | no | Users.md Sales.md | Declines briefly, computes no payroll and claims no payroll feature; the pointer to the Sales list values and status matches the manual. |
| C3 | claude-haiku-5-5/v3 | 2 | no | Sales.md | Declines payroll as out of scope in one sentence; 'sales reporting' loosely describes the Sales list, and the Sales.md citation is unnecessary but harmless. |
| C3 | claude-sonnet-5-5/v1 | 2 | no | Sales.md Users.md | Correctly declines payroll as outside the manual and claims no payroll or commission feature; the extra pointers to Sales and Users are accurate, though longer than needed. |
| C3 | claude-sonnet-5-5/v2 | 2 | no | Users.md Sales.md | Declines briefly without inventing payroll features, and correctly points to the Sales list columns described in the manual. |
| C3 | claude-sonnet-5-5/v3 | 2 | no | Sales.md | Briefly declines an out-of-scope question with no payroll explanation or invented features; the Sales citation is superfluous but harmless. |
| C3 | claude-opus-5-5/v1 | 2 | no | Users.md Sales.md | It declines without explaining payroll, and its pointer to per-user proposal values on the Sales list matches the manual. |
| C3 | claude-opus-5-5/v2 | 1 | no | Users.md Sales.md | It correctly declines payroll and points accurately to the Sales list, but it runs longer than the brief decline the rubric wants and wrongly says the user is on the Users screen when they are on MainForm. |
| C3 | claude-opus-5-5/v3 | 2 | no | - | Briefly declines an out-of-scope question and correctly states that the application has no payroll. |
| C3 | gemini-pro-latest/v1 | 2 | no | Sales.md | Briefly declines the out-of-scope payroll question without inventing payroll features; the citation of the Sales page is unnecessary but harmless. |
| C3 | gemini-pro-latest/v2 | 2 | no | Sales.md | Briefly declines because payroll is out of scope and claims no feature, as the rubric asks; the Sales citation is unnecessary but harmless. |
| C3 | gemini-pro-latest/v3 | 2 | no | Sales.md | Declines briefly as the rubric asks, without explaining payroll or claiming payroll features. The Sales citation is unnecessary but harmless. |
| C3 | gemini-3.5-flash-lite/v1 | 2 | no | Sales.md | Briefly declines because payroll is outside the manual, as the rubric wants; citing the Sales page is unnecessary but claims nothing false. |
| C3 | gemini-3.5-flash-lite/v2 | 2 | no | Users.md Sales.md FAQ.md | Briefly declines because payroll is not covered, as the rubric expects; the cited pages are superfluous but claim nothing false. |
| C3 | gemini-3.5-flash-lite/v3 | 2 | no | Users.md | Correctly and briefly declines the off-topic payroll question without claiming any such feature; the Users citation is superfluous but harmless. |
| C3 | gpt-6-luna/v1 | 2 | no | Users.md | Briefly declines and correctly notes the Users screen has no payroll function; no payroll explanation or invented feature. |
| C3 | gpt-6-luna/v2 | 2 | no | Users.md | Declines briefly and correctly notes users are only labels, with no payroll in the application. |
| C3 | gpt-6-luna/v3 | 2 | no | Users.md | Declines briefly, says the manual has no payroll features and correctly notes that users are only labels, not employees. |
| C3 | gpt-6.1-sol/v1 | 2 | no | Users.md | Declines briefly and correctly, noting Users is only for record ownership and filtering, which matches the manual. |
| C3 | gpt-6.1-sol/v2 | 2 | no | Users.md | Declines briefly, notes that the manual does not cover payroll, and gives an accurate side remark that users are only labels and filters. |
| C3 | gpt-6.1-sol/v3 | 2 | no | Sales.md | Briefly declines the payroll question as out of scope without claiming payroll features, as the rubric requires. |
| D1 | claude-haiku-5-5/v1 | 2 | no | - | It gives the correct date, Monday 14 December 2026, and rightly says the app has no validity field; it only omits the line-item-title workaround. |
| D1 | claude-haiku-5-5/v2 | 2 | no | Draft-Proposal.md | Correctly gives Monday 14 December 2026 and notes the draft has no validity field, though its 'some other way' is vague and misses the 20-character line item title. |
| D1 | claude-haiku-5-5/v3 | 2 | no | - | The date (14 December 2026) is correct, and the answer rightly says proposals have no validity field, though it could have pointed to the 20-character line item title as the place to write it. |
| D1 | claude-sonnet-5-5/v1 | 2 | no | Draft-Proposal.md | It gives the correct date (Monday 14 December 2026) and correctly says the draft has no validity field, though it stays vague on where to type the date instead of pointing to a 20-character line item title. |
| D1 | claude-sonnet-5-5/v2 | 2 | no | Draft-Proposal.md | The date is correct (Monday 14 December 2026), and the answer rightly says the draft has no validity field; it only leaves out the line-item title workaround. |
| D1 | claude-sonnet-5-5/v3 | 2 | no | Draft-Proposal.md | The date is correct (Monday 14 December 2026), and the answer rightly says the draft has no validity field and suggests stating it separately, though it skips the line-item title option. |
| D1 | claude-opus-5-5/v1 | 2 | no | - | Correct date (Monday 14 December 2026) and correctly says there is no validity field, though it skips the line-item title workaround. |
| D1 | claude-opus-5-5/v2 | 2 | no | Draft-Proposal.md ToDo.md | The date (Monday 14 December 2026) is correct, and the answer rightly says there is no validity field, though it misses the line-item-title workaround. |
| D1 | claude-opus-5-5/v3 | 2 | no | ToDo.md Draft-Proposal.md | Correct date (Monday 14 December 2026), and it rightly says the draft has no validity field, though it omits the option of writing the date in a line item title. |
| D1 | gemini-pro-latest/v1 | 2 | no | - | The date, 14 December 2026, is correct and answers the question, though it does not mention that the draft has no validity field. |
| D1 | gemini-pro-latest/v2 | 2 | no | Draft-Proposal.md | Gives the correct date (14 December 2026) and rightly notes the draft has no validity field, though it omits the line-item-title workaround and its 20-character limit. |
| D1 | gemini-pro-latest/v3 | 1 | no | Sales.md | The date of 14 December 2026 is correct, but the answer trails off mid-sentence and never says the draft has no validity field. |
| D1 | gemini-3.5-flash-lite/v1 | 1 | no | - | Correctly implies there is no validity field, but it fails to give the simple computed date (14 December 2026) or any workaround. |
| D1 | gemini-3.5-flash-lite/v2 | 1 | no | Sales.md Draft-Proposal.md | It correctly notes that proposals have no validity field, but it never gives the simple answer of 14 December 2026, nor where that date could be written. |
| D1 | gemini-3.5-flash-lite/v3 | 0 | no | Sales.md | The date is wrong: 30 days from Saturday 14 November 2026 is Monday 14 December, not Sunday 13 December, though it correctly says proposals have no validity field. |
| D1 | gpt-6-luna/v1 | 2 | no | Draft-Proposal.md | Correct date (14 December 2026), and it rightly says the manual has no validity setting; it does not suggest a workaround but needs none to answer. |
| D1 | gpt-6-luna/v2 | 2 | no | - | The date (14 December 2026) is correct and answers the question, though it omits that the draft has no validity field. |
| D1 | gpt-6-luna/v3 | 1 | no | - | Gives the correct date (14 December 2026) but omits that the draft has no validity field, so the date can only go in a 20-character line item title or be agreed outside. |
| D1 | gpt-6.1-sol/v1 | 1 | no | - | It correctly implies there is no validity feature, but it does not give the simple date (14 December 2026) or say where such a date could go. |
| D1 | gpt-6.1-sol/v2 | 2 | no | - | Correctly gives 14 December 2026 and claims no feature; it does not mention that the draft has no validity field, which was not required. |
| D1 | gpt-6.1-sol/v3 | 2 | no | - | The date, 14 December 2026, is correct and answers the question, though the answer does not mention that the draft has no validity field. |
| D2 | claude-haiku-5-5/v1 | 1 | no | Lead-Detail.md | Correctly says it does not know the current time, but never gives New York's offset (UTC-5 in November) or business-hours guidance, so it helps little. |
| D2 | claude-haiku-5-5/v2 | 1 | no | Lead-Detail.md | It declines to work out the time and gives no New York offset (UTC-5 in November), though it correctly notes that the Call button is only a placeholder. |
| D2 | claude-haiku-5-5/v3 | 2 | no | ToDo.md | Gives a plausible current New York time (08:55 Saturday, UTC-5) and a sensible weekend judgement, and correctly notes that the Call button and Calendar do nothing. |
| D2 | claude-sonnet-5-5/v1 | 1 | no | Lead-Detail.md ToDo.md | It correctly says the Call button is a placeholder, but gives no New York time or UTC-5 offset and no judgement against business hours. |
| D2 | claude-sonnet-5-5/v2 | 1 | no | Lead-Detail.md ToDo.md | It correctly says the Call button is a placeholder, but it declines the time question without giving New York's offset (UTC-5) or the current time there (about 09:25), which general knowledge could have supplied. |
| D2 | claude-sonnet-5-5/v3 | 2 | no | Lead-Detail.md ToDo.md | It gives about 8:58 on Saturday in New York at UTC−5, within the rubric's window, rightly flags the weekend as outside business hours, and correctly says the Call button is a placeholder. |
| D2 | claude-opus-5-5/v1 | 1 | no | Lead-Detail.md ToDo.md | It correctly says it cannot see the time, flags the weekend and the placeholder Call button, but gives neither New York's UTC offset nor a time estimate. |
| D2 | claude-opus-5-5/v2 | 2 | no | Lead-Detail.md ToDo.md | Gives a plausible current New York time within the allowed margin, rightly flags that today is Saturday, and correctly says the Call button does nothing and Notes saves on leaving the field. |
| D2 | claude-opus-5-5/v3 | 2 | no | Lead-Detail.md ToDo.md | Correctly works out about 9:00 in New York from the current time, rightly flags that it is Saturday, and accurately notes that the Call button does nothing and that Notes save on leaving the field. |
| D2 | gemini-pro-latest/v1 | 0 | no | - | Refuses outright: it neither works out the New York time nor gives the UTC-5 offset or any business-hours guidance. |
| D2 | gemini-pro-latest/v2 | 1 | no | - | It only declines and gives no New York time, UTC-5 offset or business-hours judgement (nor that the date is a Saturday), though general knowledge could have helped. |
| D2 | gemini-pro-latest/v3 | 2 | no | - | Gives a New York time within the allowed range and rightly flags that today is Saturday, using general sales practice without claiming any app feature. |
| D2 | gemini-3.5-flash-lite/v1 | 1 | no | Lead-Detail.md Leads.md ToDo.md | Only says the manual does not cover it, without giving the New York offset, judging business hours or mentioning that the Call button does nothing. |
| D2 | gemini-3.5-flash-lite/v2 | 1 | no | Lead-Detail.md Leads.md ToDo.md | It only says the manual does not cover time zones; it does not work out the New York time (UTC-5 in November) and does not mention that the Call button does nothing. |
| D2 | gemini-3.5-flash-lite/v3 | 1 | no | Lead-Detail.md | It gives generic business-hours advice and correctly notes the Call button is a placeholder, but never works out the current New York time (about 09:25 on a Saturday) or gives the UTC-5 offset. |
| D2 | gpt-6-luna/v1 | 1 | no | Lead-Detail.md ToDo.md | It correctly says the Call button is only a placeholder, but it gives neither the New York time nor the UTC-5 offset, and does not judge the call against business hours. |
| D2 | gpt-6-luna/v2 | 1 | no | Lead-Detail.md ToDo.md | Correctly says the Call button is only a placeholder, but it neither works out the New York time (about 09:25, a fine time to call) nor gives the UTC-5 offset. |
| D2 | gpt-6-luna/v3 | 2 | no | - | Gives a plausible New York time and rightly flags that it is Saturday, without claiming any application feature; it skips that the lead's Call button does nothing, a minor omission. |
| D2 | gpt-6.1-sol/v1 | 1 | no | - | It only says it cannot tell, without working out New York's time (about 09:25, UTC-5) or even giving the offset, and it misses that the Call button does nothing. |
| D2 | gpt-6.1-sol/v2 | 1 | no | Lead-Detail.md | It correctly says the Call button is a placeholder, but refuses the timing question instead of working out New York time (UTC-5 in November) or at least giving the offset. |
| D2 | gpt-6.1-sol/v3 | 2 | no | - | Gives a plausible current New York time (9:11 a.m. Saturday) and sensibly flags the weekend as general sales practice; omitting the Call button detail is not an invention. |
| D3 | claude-haiku-5-5/v1 | 1 | no | Leads.md FAQ.md | Correctly names November 2026 and the New column's Date Created, but leaves out that the lead detail window shows Date Created for leads in other columns, so leads already moved would be missed. |
| D3 | claude-haiku-5-5/v2 | 1 | no | Leads.md FAQ.md | Correctly takes November 2026 and the New column's Date Created, but for moved leads it suggests checking columns that show stage dates instead of opening the lead detail to read Date Created. |
| D3 | claude-haiku-5-5/v3 | 1 | no | Leads.md Accounts.md | It correctly places the question in November 2026, points to the New column's Date Created and says there is no date filter or report, but it misses that the lead detail window shows Date Created for leads that have moved to other columns. |
| D3 | claude-sonnet-5-5/v1 | 1 | no | Leads.md FAQ.md | Correctly explains that only the New column shows Date Created and that there is no date filter, but it never names the month (November 2026) and omits that the lead detail window shows Date Created for any lead. |
| D3 | claude-sonnet-5-5/v2 | 1 | no | Leads.md FAQ.md | Correctly notes the New column shows Date Created and there is no date filter, but misses that the lead detail window shows Date Created for leads in other columns, and never names the current month (November 2026). |
| D3 | claude-sonnet-5-5/v3 | 1 | no | Leads.md FAQ.md | Correctly places the month as November 2026, says no filter or report exists, and points to the New column's Date Created, but omits that the lead detail window shows Date Created for leads that have moved on. |
| D3 | claude-opus-5-5/v1 | 1 | no | Leads.md FAQ.md | Correctly places the month as November 2026, notes that only the New column shows Date Created and that there is no date filter, but omits that the lead detail window shows Date Created for leads in the other columns. |
| D3 | claude-opus-5-5/v2 | 1 | no | Leads.md FAQ.md | Correctly says the data can't be read, there is no date filter or report, and only the New column shows Date Created, but it never names November 2026 and omits that the lead detail window shows Date Created for leads in other columns. |
| D3 | claude-opus-5-5/v3 | 2 | no | Leads.md FAQ.md | Correctly places the question in November 2026, points to Date Created in the New column, and notes there is no date filter or report and that the other columns show other dates; it could also have mentioned opening each lead's detail window to see its creation date. |
| D3 | gemini-pro-latest/v1 | 1 | no | Leads.md | Correctly notes that only the New column shows Date Created and that there is no date filter, but it never names November 2026, omits the lead detail window and the fact that search ignores dates, and hedges as 'not explained'. |
| D3 | gemini-pro-latest/v2 | 1 | no | Leads.md | Nothing invented, but it only says the manual does not cover a date filter, without the workaround: Date Created shows only in the New column and in each lead's detail window, and search ignores dates. |
| D3 | gemini-pro-latest/v3 | 1 | no | Leads.md FAQ.md | Correctly says there is no date filter or report and points to the Date Created in the New column, but never names November 2026 and misses that leads already moved to other columns show their Date Created only in the lead detail. |
| D3 | gemini-3.5-flash-lite/v1 | 1 | no | Leads.md | It only says the manual does not cover it, when it could have pointed out that this month is November 2026, that only the New column shows Date Created, that the lead detail shows it for one lead, and that search does not filter by date. |
| D3 | gemini-3.5-flash-lite/v2 | 1 | no | Leads.md | Says only that the manual has no information; it misses that the New column shows Date Created, the lead detail shows the four dates, the search does not filter by date, and this month is November 2026. |
| D3 | gemini-3.5-flash-lite/v3 | 1 | no | Leads.md | Correctly says there is no date filter or report and only the New column shows Date Created, but it never names November 2026 and omits that the lead detail window shows Date Created for leads in the other columns. |
| D3 | gpt-6-luna/v1 | 1 | no | Leads.md | It correctly points to the Date Created column in New for November 2026, but omits that leads already moved to other columns need checking in the lead detail and that search cannot filter by date. |
| D3 | gpt-6-luna/v2 | 1 | no | Leads.md | Correctly says the New column shows Date Created, but it never names November 2026, mentions the lead detail window or says that search cannot filter by date. |
| D3 | gpt-6-luna/v3 | 1 | no | Leads.md | It correctly uses November 1–14, 2026 and the New column's Date Created, but omits that the lead detail window shows Date Created for leads in other columns and that neither search nor any report filters by date. |
| D3 | gpt-6.1-sol/v1 | 1 | no | Leads.md FAQ.md | Correctly places the month and notes that only the New column shows Date Created, but omits the lead detail dates and that search cannot filter by date. It also wrongly says the manual doesn't tie a new lead to the active user, when the manual says created records are stamped with that name. |
| D3 | gpt-6.1-sol/v2 | 2 | no | Leads.md FAQ.md | Correctly uses November 1–14, points to Date Created in the New column, and warns that leads in other statuses are missed. It omits checking Date Created in the lead detail and is needlessly unsure whether the user field identifies the creator. |
| D3 | gpt-6.1-sol/v3 | 1 | no | Leads.md FAQ.md | Correctly uses November 2026 and notes that only the New column shows Date Created, but it omits that the lead detail window shows Date Created for leads that have moved on, and that search cannot filter by date. |

## Answers

### claude-haiku-5-5/v1

**A1** (2.0 s, useful 1)

> The help documentation doesn't cover VAT or taxes, so I can't tell you whether or how to add it to a proposal.
> 
> What it does say is that the total is the sum of the line items, recomputed each time a line item changes, and that the total is saved with the proposal as its value. Fields for quantity and price are the only figures described for each row. ([Draft a proposal](Draft-Proposal.md))

**A2** (2.3 s, useful 1)

> The documentation doesn't explain how to calculate a pipeline value. It doesn't describe a total or pipeline figure anywhere.
> 
> What it does cover:
> 
> - **Dashboard** shows lead counts per status (New, Active, Proposal Sent, Closed, Inactive, Total), not monetary values. See [Dashboard](Dashboard.md).
> - **Sales** lists every proposal of the active user, with a **Value** column showing the invoice total as it was when saved. See [Sales](Sales.md).
> 
> The docs don't say whether the Sales list can total the Value column, so I can't confirm a way to get a sum from the app.

**A3** (1.8 s, useful 1)

> The manual doesn't say how long a lead should stay in Active or when to treat it as lost, so I can't give you a timeframe.
> 
> What it does cover: the **Active** column holds leads that are being worked on, and a lead moves there once it's contacted. The board has no "Lost" status. The four columns are New, Active, Proposal Sent and Closed. To change a lead's column, drag it on the board. See [Leads](Leads.md).

**B1** (2.8 s, useful 1)

> You're already on the right screen. The **Sales** screen lists every proposal of the active user in one list. For the review, look at these columns:
> 
> - **Status**: New when saved, then Accepted or Canceled.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when the proposal was saved, and when it was accepted.
> 
> The documentation doesn't describe a way to filter the list by month. The Search box only filters on the proposal name, and every proposal is called New Proposal, so it won't help you pick out a period ([Sales](Sales.md)). To find the proposal for a specific customer, open the lead and press View Proposal.
> 
> The Calendar screen doesn't show sales data, so it won't help with the review ([Calendar](Calendar.md)).

**B2** (3.4 s, useful 1)

> The documentation doesn't say how to apply a discount to a proposal, so I can't tell you whether the draft window has a discount option.
> 
> What it does say:
> 
> - A proposal is an invoice with a header, a list of line items, a total, and a thank-you line. You fill it in, review it, and save it. ([Draft a proposal](Draft-Proposal.md))
> - Once saved, a proposal can't be edited or reprinted, only accepted or canceled. ([Known limitations](ToDo.md))
> 
> If the amount needs to change, it has to be settled before you save. If you need the discount applied, check with whoever maintains the application.

**B3** (2.9 s, useful 1)

> The manual doesn't say what to do when a prospect is slow to answer. It only describes the **Proposal Sent** column as "a proposal is out, waiting for an answer" and explains how leads move between columns by drag and drop. ([Leads](Leads.md))
> 
> The lead should stay in **Proposal Sent** while you wait. If you drag it to another column, its status changes, and the date for that stage is stamped with the current time if it's empty. The manual doesn't describe any follow-up or reminder feature.

**C1** (1.7 s, useful 2)

> The documentation I have doesn't cover automatic reminders or any scheduling feature, so I can't tell you how to set one up.
> 
> You can still see which leads haven't been contacted. The **New** column on the Leads board shows each lead's Date Created, and the **Active** column shows Date Contacted. Check those dates against the 30-day window. The [Leads](Leads.md) page describes the columns.

**C2** (1.7 s, useful 1)

> The documentation doesn't cover sales forecasting or quarterly reports, so I can't tell you how to produce one in this application.
> 
> The Sales screen does list every proposal with its **Value**, **Status**, **DateCreated** and **DateCompleted**, so you could read the figures from there. The documentation doesn't say whether the list can be sorted, filtered by date or totalled.
> 
> Source: [Sales](Sales.md)

**C3** (2.2 s, useful 2)

> The documentation I have doesn't cover payroll calculation, so I can't tell you how to do it in this application. Nothing I've been given describes salary, commission or payroll features.
> 
> What the documentation does cover is the Sales screen, which lists each active user's proposals with their status and value. You can also check a user's proposals there, which may help if you're working out figures yourself. If you have a question about one of those areas, I can walk you through it.
> 
> Source: [Sales](Sales.md)

**D1** (3.5 s, useful 2)

> Counting 30 days from today, Saturday 14 November 2026, the proposal would be valid until **Monday, 14 December 2026**.
> 
> The documentation doesn't describe any validity or expiry field for proposals, so the app won't track this date for you.

**D2** (2.4 s, useful 1)

> The help documentation doesn't cover this. It has nothing on time zones, business hours, or the best time to call, and I don't know the current time where you are, so I can't say whether it's too late.
> 
> If the lead has a preferred calling time, the **Notes** field on the Lead detail screen is free text, so you can record it there. Other details the app doesn't cover, such as the customer's time zone, will need to come from outside the app.
> 
> Source: [Lead detail](Lead-Detail.md)

**D3** (3.3 s, useful 1)

> The documentation doesn't say how to filter leads by creation month or by who created them. What it does show:
> 
> - On the Leads board, the **New** column lists each lead with its **Date Created** and **Name**. Leads that have moved to other columns show a different date for that stage, so the creation date isn't visible there. ([Leads](Leads.md))
> - Leads are filtered by the active user in the title bar. If your leads seem to be missing, check that the user drop-down is set to the user who owns them. ([FAQ](FAQ.md))
> 
> To find this month's leads, you could check the New column for leads created since 1 November 2026. The documentation doesn't cover a more direct way.

### claude-haiku-5-5/v2

**A1** (2.8 s, useful 1)

> The documentation doesn't say how to handle VAT. It only describes the total as the sum of the line items, and the proposal's only other fields are the three address/phone boxes, which are not validated. I can't tell you whether the document will show VAT or how to add it, so check that with your own process before you send a proposal.
> 
> What the documentation does say: the total is recalculated whenever a line item changes, and it is saved as the proposal's value when you press Save Proposal. ([Draft a proposal](Draft-Proposal.md))

**A2** (2.8 s, useful 1)

> The documentation doesn't explain how to calculate a pipeline value, and I can't find a total or pipeline figure in the app's documented features.
> 
> Two related things are documented:
> 
> - The **Dashboard** counts your leads by status (New, Active, Proposal Sent, Closed, Inactive, and Total). These are lead counts, not monetary values. ([Dashboard](Dashboard.md))
> - The **Sales** list shows a **Value** for each proposal, which is the invoice total as it was when you saved it. The docs don't say whether the list can be summed or filtered by status. ([Sales](Sales.md))

**A3** (2.6 s, useful 1)

> The manual doesn't say how long a lead should stay in Active or when to treat it as lost. That is a sales-process decision, and the documentation doesn't set a threshold or define a "lost" status.
> 
> What the manual does say is that **Active** means the lead is being worked on, and the column shows the Date Contacted ([Leads](Leads.md)). The board has four columns: New, Active, Proposal Sent and Closed. Closed means finished, and the manual doesn't say whether that includes lost leads.

**B1** (4.8 s, useful 1)

> You're already on the **Sales** screen, which is the right place to start. It lists every proposal of the active user, with:
> 
> 1. **Status** (New, Accepted or Canceled), to see what was won or lost.
> 2. **Value**, the invoice total as it was when the proposal was saved.
> 3. **DateCreated** and **DateCompleted**, to see what was saved or accepted in the month.
> 
> Keep in mind:
> - The **Search** box filters only on proposal name, and every proposal is called New Proposal, so it won't help you narrow the month. To find one customer's proposal, open the lead and press **View Proposal**.
> - **Complete** and **Cancel** can be reapplied at any time. **Cancel** leaves DateCompleted alone, so a canceled proposal may still show a completion date. Check the status and the date together.
> - The Calendar shows no data, so it can't help with the review.
> 
> The documentation doesn't describe any monthly totals or reports, so I can't tell you whether the application provides one.
> 
> Source: [Sales](Sales.md), [Known limitations](ToDo.md)

**B2** (3.1 s, useful 1)

> The documentation doesn't say how to apply a discount. It doesn't mention a discount field or a discount line item, so I can't give you steps for it.
> 
> What the documentation does say:
> - A proposal is built as an invoice with a header, a list of line items, a total, and a thank-you line. You fill it in, review it, and save it. ([Draft a proposal](Draft-Proposal.md))
> - A saved proposal cannot be edited, only accepted or cancelled. ([Known limitations](ToDo.md))
> 
> So any change to the total has to be made in the draft before you press Save Proposal. Once saved, the proposal can't be corrected. If the discount can't be handled within the draft, you'll need to handle it outside this application.

**B3** (4.8 s, useful 1)

> The manual doesn't describe a follow-up procedure for unanswered proposals, so I can't say what to do next. What it does cover is how the board shows the lead. A lead whose proposal is out sits in the **Proposal Sent** column, which means it is "waiting for an answer." That column shows the Date Drafted and Account Name, so you can see when the proposal went out ([Leads](Leads.md)).
> 
> When the lead's status changes, drag its row to the column that matches. Dropping it on **Closed** sets the status to Closed and stamps Date Closed if it is empty. The manual doesn't say how to mark a lead Inactive, so I can't tell you how to do that.

**C1** (2.2 s, useful 2)

> The documentation doesn't cover automatic reminders or scheduled follow-up rules, so I can't tell you how to set one up.
> 
> The Leads board can help you spot these leads by hand. The **Active** column shows each lead's **Date Contacted**, and the **New** column shows **Date Created**. Source: [Leads](Leads.md)

**C2** (2.3 s, useful 1)

> The documentation doesn't cover sales forecasting or quarterly reports, so I can't tell you how to produce one in this application.
> 
> The Sales screen lists every proposal of the active user, with a **Value** and the **DateCreated** and **DateCompleted** dates for each. Those columns are the closest data in the app, but the documentation doesn't say whether they can be grouped or totalled by quarter. Note that the **Status** column shows New, Accepted or Canceled, so you could separate accepted proposals from open ones.
> 
> Source: [Sales](Sales.md)

**C3** (2.1 s, useful 2)

> The application documentation I have doesn't cover payroll or commission calculation, so I can't tell you how to do that here. It only describes leads, accounts, proposals (Sales), users, and the database file.
> 
> The Sales screen lists each proposal with its total value and status, which may be useful as input to your own payroll process, but the documentation doesn't say how to calculate pay from it. For payroll itself, you'll need your HR or payroll tool or your company's internal process.
> 
> Source: [Users](Users.md), [Sales](Sales.md)

**D1** (3.5 s, useful 2)

> The proposal would be valid until **Monday, 14 December 2026**.
> 
> The application documentation doesn't describe a validity or expiry field for proposals. The draft window only has the company name, today's date, the address, city/state/zip and phone boxes, and the line items. So the application won't track the expiry date for you. If the customer needs to see it, you'd have to state it in the document some other way.
> 
> Source: [Draft a proposal](Draft-Proposal.md)

**D2** (3.5 s, useful 1)

> I can't advise on whether it's a good time to call a customer in New York. The application documentation doesn't cover time zones or call timing.
> 
> If you're calling a lead from the lead detail window, note that the **Call** button beside the phone number is only a placeholder and does nothing, so you'll need to dial manually. ([Lead detail](Lead-Detail.md))

**D3** (3.3 s, useful 1)

> The documentation doesn't describe a way to filter leads by creation month, so I can't tell you how to get that list directly. You can check it by hand on the board:
> 
> 1. Open the **Leads** screen and look at the **New** column, which shows each lead's **Date Created** and **Name** ([Leads](Leads.md)).
> 2. Find the leads dated in November 2026.
> 
> Leads that have already moved to Active, Proposal Sent, or Closed won't appear in New. Their dates there are Date Contacted, Date Drafted, or Date Closed, so check those columns too.
> 
> The board is also filtered by the user shown in the title bar. If some of your leads are missing, check that the user drop-down is set to your name ([FAQ](FAQ.md)).

### claude-haiku-5-5/v3

**A1** (4.1 s, useful 2)

> The documentation doesn't cover VAT. The proposal has no VAT field or rate setting. The total is simply the sum of the line items, recalculated whenever one changes, and it's stored as the proposal's value ([Draft a proposal](Draft-Proposal.md)).
> 
> Since your prices are net, the application won't add VAT for you. Two general options:
> 
> - **Add it as a separate row.** Add a line item titled something like "VAT 22%" with the VAT amount as its price. The total will then include it. This is my suggestion, not a documented feature, so check the wording and amount with your accountant.
> - **Quote net and state VAT separately.** Keep the total net and put the VAT treatment in the proposal's free text or your covering message. The application doesn't provide a place for this in the documented fields.
> 
> Also note that the three address and phone boxes are free text and aren't validated, so they can't hold a VAT number in a structured way.

**A2** (4.1 s, useful 2)

> The application doesn't show a pipeline value. The [Dashboard](Dashboard.md) counts leads per status, and it doesn't add up any amounts.
> 
> The closest thing is to read the values yourself:
> 
> 1. Open **Sales**. It lists your proposals with a **Status** and a **Value** column. Proposals with status **New** are saved drafts waiting for an answer.
> 2. Note the **Value** of each open proposal and add them up by hand. The Sales screen doesn't total them for you.
> 3. Use the [Dashboard](Dashboard.md) tiles for context. **Proposal Sent** shows how many leads are waiting for an answer to a proposal, and **Active** shows how many leads are being worked on.
> 
> The [Sales](Sales.md) page notes that Value is the invoice total as it was when the proposal was saved. It also doesn't say whether leads without a proposal carry any value, so the total only covers leads that have a proposal.
> 
> In general sales practice, pipeline value is the sum of the values of open opportunities, often weighted by the estimated chance of winning each one. This is standard practice rather than a feature of this application, so you would need to apply the weighting yourself.

**A3** (3.9 s, useful 1)

> There's no set time limit in this application. The documentation doesn't mention a lead going stale, a "lost" status, or any automatic inactivity rule. The board has four columns: New, Active, Proposal Sent, and Closed. Active means the lead is being worked on, and Closed means finished ([Leads](Leads.md)).
> 
> As general sales practice, teams often set a rule such as "no meaningful contact for 30 to 60 days, then close it out." The right window depends on your sales cycle. That rule is not something this application enforces.
> 
> To close out a lead here, drag it from Active to Closed on the board. That records the Date Closed.

**B1** (4.2 s, useful 1)

> The Sales screen is the closest place in the application. It lists every proposal of the active user, with columns including **Status**, **Value**, **DateCreated** and **DateCompleted** ([Sales](Sales.md)).
> 
> For a month-end review:
> 
> 1. Open the **Sales** screen.
> 2. Read **Status**: a proposal is **New** when saved, then **Accepted** or **Canceled**.
> 3. Use **DateCompleted** to see when a proposal was accepted, and **Value** for its total as saved.
> 4. To see which customer a proposal belongs to, open the lead and press **View Proposal** ([Sales](Sales.md)).
> 
> Some limits to keep in mind:
> 
> - The documentation does not describe a month filter, a summary total or a report. You will need to compare the dates and values by reading the list.
> - The **Search** box only filters on the proposal name, and every proposal is called "New Proposal", so it will not help you pick out a month or a customer ([Sales](Sales.md)).
> - The **Calendar** shows no data, so it cannot be used for this review ([Calendar](Calendar.md)).
> - Accepted and canceled proposals can be changed later, so a figure you review may change afterwards ([Sales](Sales.md)).
> 
> As general practice, a month-end review usually counts the proposals accepted within the month and their total value, and compares that with the previous month. Nothing in the application does this for you, so you will need to do the arithmetic yourself.

**B2** (4.8 s, useful 1)

> The documentation doesn't describe a discount option, so I can't tell you how to apply one as a separate step.
> 
> The closest thing the application has is the proposal draft itself. It is an invoice with a list of line items and a total, and you review it before saving ([Draft a proposal](Draft-Proposal.md)). If the draft window lets you change the line item amounts, you could enter the discounted prices so the total reflects 10% off. The documentation doesn't say whether the window lets you do this, so check it when you open the draft.
> 
> Two points to keep in mind:
> - A saved proposal cannot be edited, only accepted or cancelled ([Known limitations](ToDo.md)). Set the discounted total before you click Save Proposal.
> - A lead can have only one proposal, so if one is already saved for this customer, the documentation doesn't say how to replace it.

**B3** (6.3 s, useful 1)

> Two weeks without an answer is a common point for a follow-up. As general sales practice, send a short, specific check-in asking whether they have questions or objections and when they expect to decide. If there is still no reply after a few attempts, make a clear call on the deal, such as a final "is this still a priority?" message.
> 
> In this application, the lead stays in the **Proposal Sent** column until you have an answer. That column shows the Date Drafted, so you can see when the proposal went out. [Leads](Leads.md)
> 
> When you have a result, drag the lead to the matching column:
> - **Active**, if they want to keep talking and you need to rework the proposal.
> - **Closed**, once the deal is finished. Moving a lead there stamps the Date Closed, so only do this when the outcome is decided.
> 
> The documentation I have does not describe reminders or follow-up scheduling, so track your next contact date outside the application if you need one. Also, the Inactive status has no column on the board. Those leads are only counted on the Dashboard.

**C1** (3.1 s, useful 2)

> The documentation doesn't describe automatic reminders or any way to set one up, so I can't tell you how to do that in this application.
> 
> The closest thing it offers is the Leads board. Each column shows the date that matters at that stage: the **New** column shows **Date Created**, and the **Active** column shows **Date Contacted**. You can scan those dates to find leads that have gone too long without contact. The Dashboard's **New** tile shows how many leads nobody has contacted yet, but it doesn't list them or flag their age.
> 
> ([Leads](Leads.md))
> 
> As general practice, teams that need reminders often keep follow-up dates in their own calendar or task tool, outside this application.

**C2** (3.8 s, useful 2)

> The application doesn't have a forecasting or quarterly reporting feature, and its documentation doesn't describe one.
> 
> The closest option is the **Sales** screen, which lists every proposal you wrote with its **Status**, **Value**, **DateCreated** and **DateCompleted** ([Sales](Sales.md)). You could total the values by quarter yourself, but keep in mind:
> 
> - **Value** is the total as it was when the proposal was saved, and proposals can't be edited afterwards.
> - **Accepted** and **Canceled** can be changed again later, so the figures may move.
> - **DateCompleted** is only set when a proposal is accepted, so it gives you accepted revenue by quarter, not a forward-looking forecast.
> 
> As general practice, a forecast is usually built from open opportunities, weighted by their likelihood of closing and grouped by expected close date. The application doesn't record expected close dates or probabilities, so you would need to keep that outside it, for example in a spreadsheet.

**C3** (1.2 s, useful 2)

> Payroll calculation is outside what I can help with, since I only cover this application's leads, accounts, proposals, sales reporting and related CRM tasks.
> 
> Source: [Sales](Sales.md)

**D1** (2.9 s, useful 2)

> **14 December 2026.** Counting 30 days from today, Saturday 14 November 2026, gives that date.
> 
> The application has no validity or expiry field for proposals. The draft holds the customer's address, phone, line items, total and a thank-you line, and the documentation does not describe any expiry date. You will need to state the validity date in the proposal's wording or track it outside the application.

**D2** (4.9 s, useful 2)

> It's not too late in the sense of the business day, but it is early there. It's about 08:55 on Saturday in New York (UTC-5, 6 hours behind Italy). This is general sales practice, not something the application covers: most B2B buyers are not at their desks on weekends, so Monday morning New York time is usually the better window for a call.
> 
> The application doesn't handle time zones or call scheduling. The Call button on the lead detail window is a placeholder that does nothing, and you can't add appointments to the Calendar. See [Known limitations](ToDo.md).

**D3** (4.4 s, useful 1)

> The documentation doesn't describe a way to filter leads by creation date or a report for this. The closest option is the **New** column on the Leads board, which shows each lead's Date Created and Name. Leads that have moved on to other columns show a different date there, so the documentation doesn't say you can see their creation date on the board. ([Leads](Leads.md))
> 
> To check what you can see:
> 
> 1. Make sure the user drop-down in the title bar is set to your user. Leads are filtered by the active user, so leads created under another user won't appear. ([Accounts](Accounts.md))
> 2. Look at the **New** column and find the leads whose Date Created falls in November 2026.

### claude-sonnet-5-5/v1

**A1** (3.4 s, useful 1)

> The documentation doesn't cover VAT or taxes, so I can't tell you whether to add it.
> 
> It does describe how the proposal's totals work:
> - Each line item has a title, a quantity and a price.
> - **Total** is the sum of the line items and recalculates whenever one changes.
> - Nothing in the draft window is validated.
> 
> The excerpts don't mention a tax field or tax calculation. If you need VAT on the document, the only option they describe is to enter it yourself, for example as an extra line item. I can't confirm that this is the intended way to do it. Whether you should charge VAT at all is a question for your own accounting or tax rules, not something this help can answer.
> 
> Source: [Draft a proposal](Draft-Proposal.md)

**A2** (4.4 s, useful 1)

> The documentation doesn't describe a pipeline value or a total of proposal values, so I can't give you a calculation method. The application doesn't appear to have one.
> 
> The documentation does cover these related pieces:
> 
> - **Sales screen:** It lists every proposal of the active user. Each proposal has a **Value** (the invoice total as it was when you saved it) and a **Status** (New, Accepted or Canceled). You can read the values there. The documentation doesn't mention any total or sum. ([Sales](Sales.md))
> - **Dashboard:** It shows only lead counts per status (New Leads, Active Leads, Proposal Sent, Closed, Inactive, Total). It shows no monetary amounts. ([Dashboard](Dashboard.md))

**A3** (3.4 s, useful 1, invented)

> The documentation doesn't say how long a lead should stay in Active before it counts as lost. It doesn't describe a time limit, a "lost" status or any automatic expiry. The board has four columns: New, Active, Proposal Sent and Closed. A lead only moves when you drag it.
> 
> The Active column does show **Date Contacted**, so you can see when each lead was last contacted. Any cutoff for "lost" would be your own team's rule, not something the application sets. See [Leads](Leads.md).

**B1** (4.5 s, useful 1)

> You're already in the right place. The **Sales** screen lists every proposal of the active user, in one list. For a month-end review, these columns are the useful ones:
> 
> - **Status**: New, Accepted or Canceled.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when the proposal was saved and when it was accepted.
> - **LeadId**: the lead the proposal was written for.
> 
> To see which customer a proposal belongs to, open the lead from the Leads board and press **View Proposal**. The Search box only filters on the proposal name, and every proposal is called "New Proposal", so it won't help you find a customer ([Sales](Sales.md)).
> 
> The documentation doesn't describe any filter by month, any totals, or any report. You'll have to read the dates and values in the list yourself. The Calendar screen won't help either, because it shows no lead or proposal dates ([Calendar](Calendar.md)).
> 
> Be careful with the **Complete** and **Cancel** buttons in the banner. They act on the selected proposal straight away and don't ask for confirmation ([Sales](Sales.md)).

**B2** (3.8 s, useful 1)

> The documentation doesn't mention a discount feature, so I can't tell you how to apply one.
> 
> Here is what it does say:
> - A proposal is an invoice with a header, line items, a total and a thank-you line. You fill it in, look at it, and save it. ([Draft a proposal](Draft-Proposal.md))
> - A saved proposal **can't be edited or reprinted**. It can only be accepted or cancelled. ([Known limitations](ToDo.md))
> 
> So if the proposal is already saved, you can't change its value. The documentation doesn't say how to replace a saved proposal with a new one. The excerpt on that point is cut off.

**B3** (5.9 s, useful 1)

> The manual doesn't say what to do when a lead goes quiet after a proposal, so I can't give you a follow-up procedure from it.
> 
> It does describe how the board tracks a lead at this stage:
> 
> - A lead in the **Proposal Sent** column has a proposal out and is waiting for an answer. That column shows Date Drafted and Account Name.
> - To change a lead's status, drag its row to another column. If that stage's date is empty, it is stamped with now. Moving a lead to **Closed** stamps Date Closed. A date that already has a value is left alone.
> - **Inactive** is a status, but it has no column on the board. Those leads are only counted on the Dashboard. The excerpts don't say how to set it.
> 
> Source: [Leads](Leads.md)

**C1** (3.2 s, useful 2)

> The documentation I have doesn't mention automatic reminders or any way to flag leads that haven't been contacted for 30 days. I don't want to guess at a feature that may not exist.
> 
> Here is what the documentation does cover that might help:
> 
> - **Leads board:** The **Active** column shows the *Date Contacted* for each lead. You can scan it to spot leads that haven't been contacted recently. See [Leads](Leads.md).
> - **Search:** The Search box filters all four columns at once. It matches a lead's name, account name, office phone or e-mail. It doesn't filter by date. See [Leads](Leads.md).
> - **Dashboard:** It shows counts per status, such as New and Active. It doesn't show how long a lead has gone without contact. See [Dashboard](Dashboard.md).

**C2** (3.5 s, useful 1)

> I can't make a sales forecast by quarter, and the documentation doesn't describe a forecast or quarterly report feature in this application.
> 
> The **Sales** screen does list every proposal of the active user. Its columns include **Value**, **Status**, **DateCreated** and **DateCompleted**, so you could read the figures there yourself ([Sales](Sales.md)). The documentation doesn't mention grouping or totaling them by quarter.

**C3** (4.1 s, useful 2)

> The documentation I have doesn't cover payroll or how to calculate a sales representative's pay. I won't guess at a method.
> 
> Here is what the documentation does say about related areas:
> 
> - **Sales** lists every proposal of the active user, with its status (New, Accepted or Canceled) and its Value. See [Sales](Sales.md).
> - **Users** are only labels on records and a filter on what you see. They aren't accounts, and they hold no pay or permission settings. See [Users](Users.md).
> 
> If you need figures for a representative, the Sales list shows the proposals and values recorded under that user. The documentation doesn't describe any payroll or commission feature, so any calculation would have to happen outside the application.

**D1** (4.5 s, useful 2)

> Thirty days from today (Saturday, 14 November 2026) is **Monday, 14 December 2026**.
> 
> The documentation doesn't describe any validity or expiry date for proposals. A proposal is an invoice with a header, line items, a total and a thank-you line, so the application doesn't enforce or track a validity period ([Draft a proposal](Draft-Proposal.md)). If you want the date on the document, you'd have to type it yourself. I can't confirm which box would suit it. The draft's address and phone boxes are printed as typed, with no validation.

**D2** (5.2 s, useful 1)

> The documentation doesn't cover time zones, calling hours, or the current time in New York, so I can't tell you whether it's too late to call. The application has no feature for this.
> 
> The **Call** button next to the phone number on the lead detail is only a placeholder and does nothing. To phone the customer, you would have to dial the number yourself. You can find it in the lead's phone field. See [Lead detail](Lead-Detail.md) and [Known limitations](ToDo.md).

**D3** (4.9 s, useful 1)

> The documentation doesn't describe a way to list leads by the month they were created, so I can't give you that list.
> 
> - The **New** column on the Leads board shows **Date Created** and **Name**. You can check the dates there for leads that are still in New.
> - The other columns show different dates. Active shows Date Contacted, Proposal Sent shows Date Drafted, and Closed shows Date Closed. Once a lead moves past New, the board no longer shows when it was created.
> - Nearly every list is filtered by the user drop-down in the title bar. If leads seem to be missing, check that it's set to the user who owns them.
> 
> Sources: [Leads](Leads.md), [FAQ](FAQ.md)

### claude-sonnet-5-5/v2

**A1** (4.5 s, useful 1)

> The documentation doesn't say anything about VAT or taxes on proposals, so I can't tell you whether to add it.
> 
> Here is what it does say about how a proposal works:
> - The proposal is an invoice with a header, line items (a title, a quantity and a price per row), a total and a thank-you line.
> - **Total** is the sum of the line items, and it recalculates every time a line item changes.
> - The application has no tax field or VAT option. The excerpts don't describe one.
> 
> If you need VAT to appear, the only approach the excerpts support is to enter it yourself as a line item, for example a row titled "VAT". The documentation doesn't mention this, so check that it suits your invoicing rules. Line item titles are limited to 20 characters.
> 
> Sources: [Draft a proposal](Draft-Proposal.md), [Data model](Data-Model.md)

**A2** (4.9 s, useful 1)

> The documentation doesn't describe a pipeline value calculation or a total pipeline amount anywhere in the application. I won't guess at a feature that isn't documented.
> 
> Here is what the documentation does cover:
> 
> - **Dashboard:** It only counts leads, with one tile per status (New, Active, Proposal Sent, Closed, Inactive, Total). It shows no monetary amounts. ([Dashboard](Dashboard.md))
> - **Sales:** This screen lists your proposals. Each one has a **Value**, which is the invoice total as it was when you saved it, and a **Status** (New, Accepted or Canceled). You can read the values of your open proposals there. ([Sales](Sales.md))
> 
> The documentation doesn't mention a built-in sum of those values, so you would have to add them up yourself from the Sales list.

**A3** (6.3 s, useful 1)

> The documentation doesn't say how long a lead should stay in Active before you treat it as lost. It has no time limit, no rule for marking a lead lost, and no "lost" status.
> 
> Here is what it does say about the board. The four columns are New, Active, Proposal Sent and Closed. A lead moves left to right as it progresses, and you move it by dragging it to another column. The Active column shows Date Contacted, Name, Email, Office Phone and Lead Id. You can use Date Contacted to see how long a lead has been in that stage. See [Leads](Leads.md).
> 
> How long to wait before giving up on a lead is a sales-policy decision for you and your team. The application doesn't set it.

**B1** (7.3 s, useful 1)

> You're already in the right place. The **Sales** screen lists every proposal of the active user. For a month-end review, these columns matter most:
> 
> - **Status**: New, Accepted or Canceled.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when the proposal was saved and when it was accepted. Use these to see which proposals fall in the month.
> - **LeadId**: the lead the proposal was written for.
> 
> To see the actual document for a customer, open the lead from the Leads board and press **View Proposal**. The search box won't help much, because it filters only on the proposal name and every proposal is called "New Proposal" ([Sales](Sales.md)).
> 
> The documentation I have doesn't describe a date filter, totals or a report on this screen, so you'd have to read the list yourself. The Calendar doesn't help either, because it shows no lead or proposal dates ([Calendar](Calendar.md)).

**B2** (5.3 s, useful 1)

> The documentation doesn't mention a discount field or a way to apply a percentage to a proposal, so I can't describe one.
> 
> Here is what it does say:
> - A proposal is an invoice with a header, line items, a total and a thank-you line. You fill it in, look at it, and save it. ([Draft a proposal](Draft-Proposal.md))
> - A saved proposal **can't be edited or reprinted**. You can only accept it or cancel it. ([Known limitations](ToDo.md))
> - **Cancel** sets the status to Canceled. It's available on the Sales screen and in the lead detail window. ([Sales](Sales.md))
> - A lead can have only one proposal. The excerpt I have cuts off before it explains what happens when you ask for a second one, so I can't tell you if you can replace a canceled proposal. ([Draft a proposal](Draft-Proposal.md))
> 
> If your proposal isn't saved yet, the only thing I can say from the documentation is that you work with the line items and the total in the draft window. It doesn't say whether you can enter a discount line, so I won't guess at that.

**B3** (4.9 s, useful 1)

> The manual I have doesn't give any advice on following up with a lead who hasn't answered, so I can't say what you should do. Here is what it does say about the Leads board:
> 
> - A lead whose proposal is out and waiting for an answer sits in the **Proposal Sent** column. That column shows **Date Drafted** and **Account Name**, so you can check how long the proposal has been out.
> - If you decide the lead is going nowhere, there is a fifth status, **Inactive**. It has no column on the board, and those leads are only counted on the Dashboard. The excerpts don't explain how to set a lead to Inactive, so I can't give you steps for that.
> - If the lead has replied and you've closed the deal, drag its row to the **Closed** column. **Date Closed** is stamped with the current time if it is still empty.
> 
> Source: [Leads](Leads.md)

**C1** (3.2 s, useful 2)

> The documentation I have doesn't mention automatic reminders or any alert for leads that haven't been contacted in a set number of days. I can't tell you how to set one up, and I won't guess at a feature that may not exist.
> 
> Here's what the documentation does cover, which may help you find those leads by hand:
> 
> - **Leads board:** The **Active** column shows **Date Contacted**, so you can see when each lead was last contacted. The **New** column shows leads nobody has called yet, with their **Date Created**.
> - **Search:** The Search box filters all four columns at once. It matches a lead's name, account name, office phone or e-mail. It doesn't filter by date.
> - **Dashboard:** The tiles count your leads by status. They don't flag leads that have gone quiet.
> 
> Sources: [Leads](Leads.md), [Dashboard](Dashboard.md)

**C2** (3.8 s, useful 1)

> I can't find anything in the documentation about a sales forecast by quarter, so I can't tell you how to make one in this application.
> 
> Here is what the Sales screen does cover:
> 
> - It lists every proposal of the active user. The columns include **Status**, **Value**, **DateCreated** and **DateCompleted**.
> - **Complete** sets the selected proposal to Accepted and stamps **DateCompleted** with the current date and time. **Cancel** sets it to Canceled.
> - The Search box filters on the proposal name only. Every proposal is named New Proposal, so it won't help you filter by period.
> 
> You could read the Value, Status and date columns from that list. The documentation doesn't describe any grouping by quarter or any forecast report, so I can't suggest a feature for it.
> 
> Source: [Sales](Sales.md)

**C3** (3.2 s, useful 2)

> I can't help with that. The documentation I have doesn't cover payroll or commission calculations for sales representatives, and I don't want to guess.
> 
> I can help with how this application handles leads, accounts, proposals (the Sales list), the Marketing list, the Dashboard and Users. For example, the **Sales** screen lists each proposal with its Value, Status (New, Accepted or Canceled) and User, which may be useful for sales reporting. Tell me if you'd like to know more about any of these.
> 
> Source: [Users](Users.md), [Sales](Sales.md)

**D1** (4.2 s, useful 2)

> Counting 30 days from today, Saturday 14 November 2026, gives **Monday, 14 December 2026**.
> 
> The documentation doesn't describe any validity or expiry date for a proposal. A proposal has a header with the customer's address, line items, a total and a thank-you line, and nothing else ([Draft a proposal](Draft-Proposal.md)). The application won't record or enforce the 30 days, so you would have to communicate that date to the customer yourself.

**D2** (6.7 s, useful 1)

> The documentation doesn't cover time zones or the best time to call a customer, and the application doesn't show a customer's local time. I can't answer that from it.
> 
> The **Call** button next to the phone number on the lead detail is only a placeholder and does nothing. To phone the customer, you'd have to dial the number yourself. You can find it in the lead's phone field. ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md))

**D3** (5.3 s, useful 1)

> I can't list them for you, and the documentation doesn't describe a way to filter leads by creation month.
> 
> - On the [Leads](Leads.md) board, the **New** column shows **Date Created**. You can read the creation dates there for leads that haven't been worked yet.
> - Once a lead moves to Active, Proposal Sent or Closed, its column shows a different date (Date Contacted, Date Drafted or Date Closed). The excerpts don't say where to find its creation date after that.
> - The board only shows the records of the user selected in the title bar drop-down ([FAQ](FAQ.md)). If leads seem to be missing, check that the right user is selected.

### claude-sonnet-5-5/v3

**A1** (6.1 s, useful 2)

> The documentation doesn't describe any VAT or tax feature in the proposal. **Total** is just the sum of the line items, and each row has only a title, a quantity and a price. The application won't calculate or add VAT for you. ([Draft a proposal](Draft-Proposal.md))
> 
> If you need VAT on the document, the closest option is to add it yourself as a line item:
> 
> 1. In the proposal window, use **+** to add an empty row.
> 2. Enter a title such as "VAT 22%", a quantity of 1, and the VAT amount you calculated yourself as the price.
> 3. Press **✓** to confirm the row. The total updates automatically.
> 
> As general practice, not something specific to this application, B2B quotes usually show net prices, then the VAT as a separate line, then the gross total. The other common approach is to state clearly that prices are "plus VAT". The correct rate and wording depend on your country and the type of sale, so check them with your accountant.

**A2** (6.3 s, useful 2)

> This application has no pipeline value report or total. The Dashboard only **counts** leads per status, and it shows no amounts ([Dashboard](Dashboard.md)).
> 
> The closest thing is the **Sales** screen. It lists your proposals with a **Value** column (the invoice total when you saved it) and a **Status** of New, Accepted or Canceled ([Sales](Sales.md)). To estimate your pipeline:
> 
> 1. Open **Sales**.
> 2. Look at the proposals with status **New**. These are proposals sent and still waiting for an answer.
> 3. Add up their **Value** amounts yourself. The excerpts don't mention a total row or a way to filter by status, so I can't say the app does this for you.
> 
> This is general practice, not an app feature. Pipeline value is the sum of the values of all open deals. A more realistic version is the *weighted* pipeline, where each deal's value is multiplied by its probability of closing. The documentation describes no probability field, so you would have to track that outside the app.
> 
> Leads that have no proposal yet carry no value in the app, so they won't be in this total.

**A3** (4.9 s, useful 1, invented)

> The application doesn't set a time limit for the Active column, and its documentation doesn't mention one. A lead stays in a column until you drag it to another. The board has no "lost" status. Its four columns are New, Active, Proposal Sent and Closed ([Leads](Leads.md)).
> 
> The rest is general sales practice, not something this application does:
> 
> - **Base the limit on your sales cycle.** Look at how long your won deals usually take from first contact to proposal. A lead that is well past that, with no reply, is a candidate to close.
> - **Use a fixed number of attempts.** A common rule is 3 to 5 follow-ups across 2 to 4 weeks, using different channels such as phone and email. After that, close the lead or put it on a longer-term nurture list.
> - **Look at engagement as well as elapsed time.** A lead that is still replying, or has a meeting booked, isn't stalled.
> 
> To follow this in the application, the Active column shows **Date Contacted**. You can use it to spot leads that haven't been touched for a while. If you decide a lead is lost, drag it to **Closed**. The documentation doesn't describe a field for recording a loss reason. If you want to keep one, I can only suggest the lead's notes, which I know exist because they can be filled in when a lead is created through the assistant.

**B1** (8.8 s, useful 1)

> You're already on the right screen. The **Sales** screen lists every proposal of the active user, so it's the place for a month-end review ([Sales](Sales.md)).
> 
> For each proposal, read these columns:
> - **Status**: New (saved but not decided), Accepted or Canceled.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when it was saved and when it was accepted.
> - **LeadId**: the lead it was written for.
> 
> As general practice, you would check three things:
> 1. Which proposals were accepted this month (DateCompleted in November).
> 2. Which are still New and need follow-up or a decision.
> 3. Which were canceled.
> 
> Some limits to be aware of:
> - The Search box only filters on the proposal name. Every proposal is called "New Proposal", so it won't help you find a customer or a month.
> - The documentation doesn't describe a month filter or a total, so you'd read the dates and values from the grid yourself.
> - To see which customer a proposal belongs to, open the lead from the Leads board and press **View Proposal**.
> - The Calendar doesn't mark any lead or proposal dates, so it won't help with this review ([Calendar](Calendar.md)).
> 
> Complete and Cancel don't ask for confirmation. Be careful not to click them on the selected proposal while you review.

**B2** (5.6 s, useful 1)

> The documentation doesn't describe a discount option, such as a percentage field or a discount line, in the proposal. I can't confirm that the application can apply a 10% discount.
> 
> - **Saved proposals can't be edited.** They can only be accepted or cancelled ([Known limitations](ToDo.md)). The **Value** shown on the Sales page is the total as it was when you saved it ([Sales](Sales.md)).
> - **Drafting.** The proposal is an invoice with a header, line items, a total and a thank-you line. You open it with **Create Proposal** in the lead detail window ([Draft a proposal](Draft-Proposal.md)).
> - **One proposal per lead.** A lead can have only one proposal. The excerpt I have is cut off at what happens when you ask for a second one, so I can't say whether a new draft is possible after cancelling the first.
> 
> The closest option I can document is to work out the discounted amounts yourself and enter them in the line items when you draft the proposal. If a proposal already exists for that lead, I can't tell you how to replace it.
> 
> As general sales practice, not a feature of this application, it's best to show the discount openly, either as its own line or as a clearly reduced price. That way the customer can see the agreed 10%.

**B3** (7.8 s, useful 1)

> Here is general sales practice first, then what the application offers.
> 
> **General practice (not specific to this application)**
> 1. **Follow up by a different channel.** If you emailed the proposal, try a phone call, or the reverse.
> 2. **Make it easy to answer.** Ask one clear question, for example "Is this still a priority?" or "Do you need changes to the proposal?"
> 3. **Offer a next step.** Suggest a short call, or ask who else needs to approve it.
> 4. **Set a closing date.** If there is still no reply after one or two more attempts, send a polite last message saying you'll close the file for now. Then stop chasing and move on.
> 
> **In this application**
> - The lead stays in the **Proposal Sent** column of the Leads board. That column shows **Date Drafted** and **Account Name**, so you can see how long the proposal has been out. ([Leads](Leads.md))
> - If the lead says no, drag it to **Closed**. **Date Closed** is stamped with the current time if it was empty. ([Leads](Leads.md))
> - There is an **Inactive** status, but it has no column on the board. Those leads are only counted on the Dashboard. ([Leads](Leads.md))
> - The excerpts I have don't describe reminders or follow-up tasks, so I can't say the application will remind you to follow up.

**C1** (4.4 s, useful 2)

> The documentation doesn't describe any automatic reminder or alert, including one for leads not contacted in 30 days, so I can't tell you how to set one up. I don't want to guess at a feature that may not exist.
> 
> The closest things the application does have are:
> 
> - **Leads board:** the **Active** column shows **Date Contacted**, and the **New** column shows **Date Created**. You can scan these dates by hand to spot leads that have gone quiet. The documentation doesn't mention sorting or filtering by date. ([Leads](Leads.md))
> - **Dashboard:** the tiles count your leads per status, such as New and Active. They show totals only, not how long a lead has been waiting. ([Dashboard](Dashboard.md))
> 
> As general practice, not a feature of this application, many teams set a fixed weekly slot to review the Active column. They contact any lead whose last contact is more than 30 days old, then update the lead afterward.

**C2** (5.3 s, useful 2)

> The application has no forecast or quarterly report in the documentation I have, so I can't produce one. I also can't read your proposal data from here.
> 
> **What the app does have**
> - The **Sales** screen lists every proposal with its **Value**, **Status** (New, Accepted or Canceled), **DateCreated** and **DateCompleted**. You can use it to total figures by hand ([Sales](Sales.md)).
> - The **Dashboard** has one tile per lead status, each showing a count of leads ([Data model](Data-Model.md)).
> 
> **A manual approach (general practice, not an app feature)**
> 1. Group the Accepted proposals by the quarter of **DateCompleted**. This gives you actual closed revenue.
> 2. Group the New proposals by the quarter you expect them to close. Multiply each **Value** by a win probability based on your history, then add them up. This gives the weighted pipeline.
> 3. Forecast for a quarter = closed revenue + weighted pipeline.
> 
> The Sales screen shows no expected close date, so you would have to track that yourself, for example in a spreadsheet.

**C3** (4.9 s, useful 2)

> Payroll calculation is outside what I can help with, because I only cover B2B sales and how to use this application.
> 
> Source: [Sales](Sales.md)

**D1** (5.1 s, useful 2)

> Counting 30 days from today, 14 November 2026, the proposal is valid until **Monday, 14 December 2026**. This is a plain calendar calculation.
> 
> The proposal draft doesn't have a validity or expiry field. According to the documentation, it has only a header with the customer's address, line items, a total and a thank-you line ([Draft a proposal](Draft-Proposal.md)). If the validity date matters, state it to the customer separately, for example in your e-mail or follow-up. Stating an expiry date in the offer is general good practice.

**D2** (5.7 s, useful 2)

> It isn't late. It's about **8:58 AM on Saturday** in New York, which is 6 hours behind you. That's because the US has already switched to standard time (UTC−5).
> 
> This is general sales practice, not something the application does:
> - Saturday morning is outside normal business hours. Unless the customer has agreed to weekend calls, it's usually better to wait until Monday. Business calls usually go out between 9:00 and 17:00 local time.
> - A call or e-mail on Monday morning New York time, which is early afternoon for you, tends to work well.
> 
> In this application, the **Call** and **Email** buttons next to the phone number and e-mail on the lead detail do nothing. They are placeholders, so you'll need to dial from your own phone. You can write what you agreed in the **Notes** field, which saves when you leave it. See [Lead detail](Lead-Detail.md) and [Known limitations](ToDo.md).

**D3** (4.8 s, useful 1)

> The documentation I have doesn't describe a way to list leads by creation month. There is no filter or report for it.
> 
> The closest option is the **New** column on the Leads board, which shows **Date Created** and **Name**. You can scan it for leads created in November 2026. This only covers leads still in New. The other columns show different dates: Active shows Date Contacted, Proposal Sent shows Date Drafted, and Closed shows Date Closed. Leads that have moved on won't show their creation date there. [Leads](Leads.md)
> 
> The board is also filtered by the user selected in the title bar. If leads seem to be missing, check that the drop-down is set to the user who owns them. [FAQ](FAQ.md)

### claude-opus-5-5/v1

**A1** (4.7 s, useful 1)

> The documentation doesn't mention VAT or taxes, so I can't tell you whether to add it. That depends on your business and local tax rules, not on this application.
> 
> Here's what the documentation does say about how a proposal works, from [Draft a proposal](Draft-Proposal.md):
> - Each line item has only a **title**, a **quantity** and a **price**.
> - **Total** recalculates itself whenever a line item changes.
> - When you save, that total is stored as the proposal's **Value**.
> 
> It doesn't describe any tax rate, VAT field or net/gross setting, so I can't say whether this app handles VAT.

**A2** (5.0 s, useful 1)

> The documentation doesn't describe any feature that calculates a total pipeline value, and the **Dashboard** tiles only count leads. They don't add up amounts ([Dashboard](Dashboard.md)).
> 
> The **Sales** screen does list the information you'd need, one row per proposal for the active user ([Sales](Sales.md)):
> 
> - **Value** is the invoice total at the time the proposal was saved.
> - **Status** is `New` for a proposal still waiting for an answer, `Accepted` or `Canceled` after that.
> 
> You can use the `Value` of each proposal with status `New` to work out your open pipeline yourself. The documentation doesn't mention any way to sort, filter or total this column in the app. The **Search** box only matches the proposal name, and every proposal is named `New Proposal`, so it won't help here.

**A3** (3.5 s, useful 1)

> The documentation doesn't say how long a lead should stay in **Active**, and it doesn't define a "lost" status or a time limit. The decision is up to you or your team.
> 
> Here's what the [Leads](Leads.md) page does cover:
> - **Active** means the lead is being worked on. The column shows the **Date Contacted**, so you can see how long each lead has been there.
> - The board has four columns: **New**, **Active**, **Proposal Sent** and **Closed** ("Finished"). There isn't a separate column for lost leads.
> - When you're done with a lead, drag it to **Closed**. Its **Date Closed** gets filled in at that point. A date that already has a value doesn't change, even if you move the lead back and forth later.

**B1** (5.5 s, useful 1)

> For your month-end review, use the **Sales** screen, which is the one you're on now. It lists every proposal you've written, and these columns are the useful ones:
> 
> - **Status**: `New` when saved, then `Accepted` or `Canceled`
> - **Value**: the invoice total at the moment the proposal was saved
> - **DateCreated** and **DateCompleted**: when the proposal was saved and when it was accepted
> - **LeadId**: the lead the proposal was written for
> 
> To see which deals were closed this month, look for `Accepted` proposals with a **DateCompleted** in that month. Canceled proposals keep their old completion date, so check the **Status** column too.
> 
> Things that won't help:
> - **Search** only matches the proposal name, and every proposal is called "New Proposal." To find one customer's proposal, open the lead from the Leads board and press **View Proposal**.
> - **Calendar** doesn't show any lead or proposal dates, and picking a day doesn't filter anything.
> 
> The documentation doesn't mention a way to filter by date, add up totals or produce a report, so you'll need to go through the list yourself.
> 
> Sources: [Sales](Sales.md), [Calendar](Calendar.md), [Known limitations](ToDo.md)

**B2** (4.8 s, useful 1)

> The documentation doesn't mention any discount option, so I can't tell you how to apply 10% off.
> 
> Here's what the documentation does say:
> 
> - **A saved proposal can't be changed.** You can only accept it or cancel it. [Known limitations](ToDo.md)
> - **The value is fixed when you save.** The Value column on the Sales page shows the invoice total from when you saved the proposal. [Sales](Sales.md)
> - **A draft is built from line items.** You enter the line items and get a total, which you can review before you press **Save Proposal**. [Draft a proposal](Draft-Proposal.md)
> - **A lead can have only one proposal.** The excerpt I have is cut off right where it explains what happens if you ask for a second one, so I can't tell you whether you can redo a proposal for the same lead.

**B3** (12.7 s, useful 1)

> The manual doesn't give advice on following up a proposal that hasn't been answered. It also doesn't describe any reminder or follow-up feature for this. Here is what the [Leads](Leads.md) page does say about where such a lead belongs:
> 
> - **While you're still waiting**, the lead stays in the **Proposal Sent** column, which means "A proposal is out, waiting for an answer". That column shows the **Date Drafted**, so you can see how long ago the proposal went out.
> - **If the deal is finished**, drag the row to the **Closed** column. The lead's status changes to Closed, and if **Date Closed** is still empty, it's set to the current date and time.
> - **There's also an Inactive status**, but it has no column on the board. Inactive leads are only counted on the Dashboard. The manual doesn't explain how to give a lead that status.
> 
> Whether to chase the lead, wait longer or give up is your decision. The documentation doesn't recommend any of these.

**C1** (3.0 s, useful 2)

> The documentation doesn't mention automatic reminders or any way to flag leads after a set number of days, so I can't tell you how to set one up.
> 
> You can still find these leads yourself on the **Leads** board:
> 
> - The **New** column lists leads nobody has called yet, with their **Date Created**.
> - The **Active** column lists leads being worked on, with their **Date Contacted**.
> 
> Look at those dates to spot leads that haven't been contacted in 30 days or more. ([Leads](Leads.md))

**C2** (3.6 s, useful 2)

> I can't make a quarterly sales forecast. The documentation doesn't describe any forecasting, reporting or quarter-by-quarter feature, and none of the actions available to me can create one.
> 
> The **Sales** screen you're on lists all of your proposals. For each one it shows:
> - **Value**: the invoice total when the proposal was saved
> - **Status**: `New`, `Accepted` or `Canceled`
> - **DateCreated** and **DateCompleted**: when it was saved and when it was accepted
> 
> You could use those columns to work out a forecast yourself, but the documentation doesn't describe a way to group, total or export them inside the app. ([Sales](Sales.md))

**C3** (3.1 s, useful 2)

> The documentation doesn't cover payroll or commission calculations, so I can't tell you how to do that in this application.
> 
> The documentation does cover a few related things. In this app, users aren't employee profiles. They're labels on records, and they filter what you see. The **Sales** list shows the active user's proposals, with each proposal's **Value**, its **Status** (New, Accepted or Canceled) and its **DateCompleted**. To see one representative's proposals, pick that user in the drop-down on the right of the title bar ([Users](Users.md), [Sales](Sales.md)).

**D1** (7.5 s, useful 2)

> The proposal is valid until **Monday, 14 December 2026**, which is 30 days from today, Saturday 14 November 2026.
> 
> The documentation doesn't mention any field for a proposal's validity or expiry date.

**D2** (4.2 s, useful 1)

> The documentation doesn't cover time zones or calling hours, and I can't see what time it is for you or in New York. All I know is that today is **Saturday, 14 November 2026**, so it's the weekend in New York. Many businesses are closed then, whatever the hour.
> 
> The **Call** button next to the phone number on the Lead Detail screen doesn't do anything. It's only a placeholder, so you'll need to dial the number yourself ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md)).

**D3** (4.4 s, useful 1)

> I can't look up your leads from here, and the documentation doesn't describe any way to filter or search leads by creation date. Here's what it does say about the **Leads** board:
> 
> - **New** shows **Date Created**, so for leads still in this column you can read the creation date directly and pick out the ones from November 2026.
> - **Active** shows **Date Contacted**, **Proposal Sent** shows **Date Drafted**, and **Closed** shows **Date Closed**. Once a lead leaves **New**, the board no longer shows when it was created.
> 
> ([Leads](Leads.md))
> 
> If leads you expect to see are missing, check the user drop-down in the title bar. Nearly every list is filtered by the active user ([FAQ](FAQ.md)).

### claude-opus-5-5/v2

**A1** (4.8 s, useful 1)

> The documentation doesn't mention VAT or any tax setting for proposals, so I can't say whether the application handles it.
> 
> Here's what it does describe: each line item has only a **title**, a **quantity** and a **price**. The **Total** recalculates every time a line item changes, and when you save, that total is stored as the proposal's value. No tax field or tax option is described. ([Draft a proposal](Draft-Proposal.md))
> 
> Whether you need to charge VAT, and how to show it, is a tax question, not something the app can answer. Your accountant can tell you.

**A2** (4.8 s, useful 1)

> The documentation doesn't describe any feature that calculates a total pipeline value, so I can't point you to one.
> 
> The excerpts do cover these related features:
> 
> - **Sales screen:** lists every proposal of the active user. The `Value` column shows each invoice total as it was when the proposal was saved. The `Status` column shows `New`, `Accepted` or `Canceled`. The documentation doesn't mention a total for these values. ([Sales](Sales.md))
> - **Dashboard:** its tiles count your leads by status, such as **Proposal Sent**. They show how many leads there are, not their monetary value. ([Dashboard](Dashboard.md))
> 
> To estimate your pipeline value, you could go through the **Sales** list and add up the `Value` of the proposals still in `New` status. You'd have to do that addition yourself, because the documentation doesn't say the app can do it for you.

**A3** (5.8 s, useful 1)

> The manual doesn't set a time limit for leads in **Active**, and it doesn't describe any automatic aging or "lost" status. That's a decision for you or your team.
> 
> What the board gives you to work with:
> - The **Active** column shows each lead's **Date Contacted**. You can use it to spot leads that have been sitting there a long time.
> - There are only four columns: **New**, **Active**, **Proposal Sent** and **Closed**. There's no separate column for lost leads. **Closed** just means "Finished," so once you decide a lead is dead, you drag it to **Closed**. That fills in its **Date Closed**.
> - Dates that already have a value stay as they are, so moving a lead back later won't rewrite its history.
> 
> Source: [Leads](Leads.md)

**B1** (5.1 s, useful 1)

> Use the **Sales** screen, which is the one you're on. It lists every proposal for the active user in a single list. For a month-end review, these columns are the useful ones:
> 
> - **Status**: `New` when the proposal was saved, then `Accepted` or `Canceled`
> - **Value**: the invoice total at the time the proposal was saved
> - **DateCreated** / **DateCompleted**: when the proposal was saved and when it was accepted
> - **LeadId**: the lead the proposal was written for
> 
> You'll need to go through the list by date yourself. The documentation doesn't mention a monthly report, totals or a date filter. Also:
> 
> - The **Search** box only matches the proposal name, and every proposal is called `New Proposal`, so it won't help you narrow things down.
> - To see which customer a proposal belongs to, open the lead from the Leads board and press **View Proposal**. ([Sales](Sales.md))
> - The **Calendar** shows no proposal or lead dates, so it can't be used for the review. ([Calendar](Calendar.md))

**B2** (5.3 s, useful 1)

> The documentation doesn't mention any discount option, so I can't tell you how to apply 10% inside the app. Here's what it does say:
> 
> - **You can't edit a saved proposal.** It can only be accepted or cancelled, and you can't reprint it either ([Known limitations](ToDo.md)). The stored document and its value stay exactly as they were when you saved them ([Sales](Sales.md)).
> - **You can cancel it.** Select the proposal on this screen and press **Cancel** in the banner. Its status changes to Canceled, and there's no confirmation prompt ([Sales](Sales.md)).
> - **Each lead can only have one proposal.** The documentation excerpt I have cuts off at that point, so I can't say whether you can draft a replacement with the discounted price for the same lead ([Draft a proposal](Draft-Proposal.md)).
> 
> If the proposal hasn't been saved yet, the draft window has line items and a total. But the excerpts don't describe a discount field or how the line items are entered, so I can't give you exact steps.

**B3** (6.1 s, useful 1)

> The manual doesn't give advice on following up an unanswered proposal, and it doesn't describe any reminder or follow-up feature. Here's what the **Leads** board does for that lead, according to the [Leads](Leads.md) page:
> 
> - **While you're still waiting:** leave the lead in the **Proposal Sent** column, which means "a proposal is out, waiting for an answer." That column shows **Date Drafted**, so you can see how long the proposal has been out.
> - **If the deal is over:** drag the row onto the **Closed** column. The lead's status changes to Closed, and **Date Closed** is set to now if it was empty.
> - **If you want to work the lead again:** drag it back to **Active**. **Date Contacted** only gets today's date if it was empty. A date that already has a value stays as it is.
> 
> There's also an **Inactive** status, but it has no column on the board. Those leads are only counted on the Dashboard, and the manual doesn't explain how to give a lead that status.

**C1** (10.4 s, useful 1)

> The documentation I have doesn't mention **automatic reminders**, so I can't tell you whether the application can do this or how to set it up.
> 
> The [Leads](Leads.md) page does describe a way to spot these leads yourself on the **Leads** board:
> 
> - The **New** column holds leads nobody has called yet, and it shows their **Date Created**.
> - The **Active** column shows each lead's **Date Contacted**, so you can see which ones haven't been contacted for a while.

**C2** (3.6 s, useful 1)

> I can't make a quarterly forecast. The documentation I have doesn't describe any forecasting or quarterly reports in this application, and none of my tools can create one.
> 
> The **Sales** screen does list every one of your proposals with their `Value`, `Status` (New, Accepted or Canceled), `DateCreated` and `DateCompleted`, so you can see there what is still open and what has been accepted ([Sales](Sales.md)). The documentation doesn't describe a way to group or total these by quarter.

**C3** (4.2 s, useful 1)

> antml:answer
> The documentation I have doesn't cover payroll, so I can't tell you how to work it out in this application. On the **Users** screen you're on now, a user is only a name attached to records, which controls what you see and who a record belongs to. It isn't an employee record, and it has no password or permissions. [Users](Users.md)
> 
> The closest thing the documentation mentions is the **Sales** list, which shows every proposal of the active user. For each one it shows the `Status` (New, Accepted or Canceled), the `Value` (the invoice total when it was saved) and `DateCompleted` (when it was accepted). If you pick your representative in the user drop-down in the title bar, you can see their proposals and which were accepted. Any commission or pay calculation would have to be done outside the application. [Sales](Sales.md)

**D1** (6.1 s, useful 2)

> The proposal is valid until **Monday, 14 December 2026**, which is 30 days after today (Saturday, 14 November 2026).
> 
> The documentation doesn't mention a validity or expiry field for proposals. According to [Draft a proposal](Draft-Proposal.md), the draft has these parts:
> - the company name and today's date, which are filled in for you
> - three boxes you type in: street address, city/state/zip and phone
> - the line items: title, quantity and price
> 
> After a proposal is saved, you can't edit or reprint it ([Known limitations](ToDo.md)). If you want the validity date to appear on the proposal, you'll need to work it in before you press **Save Proposal**. The documentation doesn't say where it should go.

**D2** (5.0 s, useful 2)

> No, it's not too late. It's **9:00 am in New York**, because New York is 6 hours behind you in November. But today is **Saturday**, so a business customer probably won't be in the office. Monday morning New York time is usually a better time to call, which is 3:00 pm or later for you.
> 
> The **Call** button next to the phone number on this screen doesn't do anything yet, so you'll need to dial the number yourself ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md)). If you want a reminder to call on Monday, you can type it in the **Notes** field. It saves as soon as you click out of the field ([Lead detail](Lead-Detail.md)).

**D3** (4.8 s, useful 1)

> I can't look up your records. I can only explain how to use the app, and the documentation doesn't describe a way to filter or report leads by creation date. Here's what the **Leads** board shows:
> 
> - **New** column: shows **Date Created**, so you can check the dates of leads that haven't moved past this stage.
> - **Active**, **Proposal Sent** and **Closed** columns: show other dates instead (**Date Contacted**, **Date Drafted**, **Date Closed**). The board doesn't show when these leads were created. ([Leads](Leads.md))
> 
> The list only shows leads for the user selected in the drop-down in the title bar. If some leads seem to be missing, check that it's set to the user who owns them. ([FAQ](FAQ.md))

### claude-opus-5-5/v3

**A1** (9.2 s, useful 2)

> **This application has no VAT or tax setting for proposals.** As far as the documentation goes, a proposal has a header and a grid of line items, each with a **title**, a **quantity** and a **price**. The **Total** updates itself whenever a line item changes, and when you save, that total becomes the proposal's **Value** on the Sales screen. There's nothing that adds tax for you. See [Draft a proposal](Draft-Proposal.md) and [Sales](Sales.md).
> 
> **Should you add VAT? (general practice, not specific to this app)** In B2B sales, prices are usually quoted net, with VAT shown separately so the customer sees both the net and gross amounts. Whether you charge VAT, and at what rate, depends on your country and your customer's. For example, sales to business customers in other EU countries often fall under reverse charge. Your accountant can confirm what applies to you.
> 
> **If you want VAT on the document, you could work around it like this:**
> 1. Enter your net line items as usual.
> 2. Press **+** to add one more row, give it a title like `VAT 22%` (titles are limited to 20 characters), set quantity to `1`, and enter the VAT amount you calculated yourself as the price.
> 3. Press **✓** to confirm the row.
> 
> The Total will then include VAT. Two things to keep in mind:
> - **You do the math.** The VAT row won't update when you change other lines, so recalculate it after any edit.
> - **The Value on the Sales screen will be gross, not net.** If you track your pipeline in net figures, it may be better to leave VAT off the proposal and mention it in the text, for example "prices excl. VAT".

**A2** (7.9 s, useful 2)

> The documentation doesn't mention any total or report for pipeline value, so this application doesn't seem to calculate it for you. The Dashboard tiles only **count** leads by status. They don't add up any money amounts. ([Dashboard](Dashboard.md))
> 
> **The closest option is the Sales screen** ([Sales](Sales.md)):
> 
> 1. Open **Sales**. It lists every proposal of the active user.
> 2. Find the proposals whose **Status** is `New`. These are proposals you've sent that haven't been marked `Accepted` or `Canceled` yet, so they're still open.
> 3. Add up their **Value** column yourself. The documentation doesn't describe a status filter, and the **Search** box only searches proposal names. Every proposal is called `New Proposal`, so it won't help here.
> 
> Keep in mind that **Value** is the invoice total at the moment the proposal was saved. If the deal changed after that, the figure may be out of date.
> 
> **General sales practice (not something this application does):**
> - **Pipeline value** is the total value of all open deals.
> - **Weighted pipeline** multiplies each deal by how likely it is to close, for example by stage or percentage, which gives a more realistic forecast. This application doesn't record a probability for each deal, so you'd need to do the weighting outside it, for example in a spreadsheet.
> - To see how many leads are at each stage, use the Dashboard tiles. For example, **Proposal Sent** shows leads still waiting for an answer to a proposal.

**A3** (7.4 s, useful 2)

> The documentation doesn't set a time limit, and nothing in the app marks a lead as lost automatically. The board has four statuses: **New**, **Active**, **Proposal Sent** and **Closed**. There's no separate "Lost" column, so a lead you give up on goes to **Closed**.
> 
> **What the app gives you:** the **Active** column shows each lead's **Date Contacted**, so you can see how long it's been there. When you decide a lead is dead, drag it to **Closed**. That fills in **Date Closed**. If you later move the lead back, its existing dates are kept, so its history isn't rewritten ([Leads](Leads.md)). Since Closed is used for both won and lost leads, write the outcome and reason somewhere you'll see it later.
> 
> **General practice (not a feature of this app):**
> - **Use your sales cycle as the yardstick.** A common rule is to review a lead once it has been Active for about 1.5–2 times your average time from first contact to proposal.
> - **Count attempts, not just days.** Many teams use something like 5–8 tries over 2–4 weeks across phone and email. If there's still no reply after that, they send a final "should I close your file?" message.
> - **Look for engagement, not just time.** A lead that replies but moves slowly isn't lost. A lead that hasn't answered anything since the first call usually is.
> - **Review on a schedule.** For example, check every week for leads whose Date Contacted is older than your limit, and decide whether to push them forward or close them.
> 
> If you tell me roughly how long your deals usually take, I can suggest a more specific limit.

**B1** (7.2 s, useful 1)

> The best place is the **Sales** screen you're on now. It lists every proposal of the active user in one grid, with these columns:
> 
> - **Status:** New, Accepted or Canceled
> - **Value:** the invoice total when the proposal was saved
> - **DateCreated** and **DateCompleted:** when it was saved, and when it was accepted
> 
> For each proposal you can see whether it was won or lost, how much it was worth and when it closed. To read the document itself, open the lead and press **View Proposal**. The grid's Proposal column only shows `(OBJECT)`.
> 
> **Limits for a month-end review:**
> - The documentation doesn't describe any sales report, date filter or monthly totals. You'll have to go through the dates in the list yourself.
> - The **Search** box only filters on the proposal name. Every proposal is called *New Proposal*, so search won't help you narrow the list.
> - **Cancel** doesn't set a completion date. Canceled proposals only show the date they were created.
> - The **Calendar** shows no data. Proposal and completion dates aren't marked on it, and selecting a day doesn't filter anything.
> 
> Sources: [Sales](Sales.md), [Calendar](Calendar.md), [Known limitations](ToDo.md)
> 
> **General sales practice (not a feature of this app):** a month-end review usually covers:
> - deals won this month (Accepted, with a DateCompleted in the month) and their total value
> - deals lost (Canceled)
> - proposals still open (New), especially older ones that need a follow-up
> 
> From these you can work out your win rate and plan next month's follow-ups.

**B2** (7.6 s, useful 2)

> The documentation doesn't describe a discount option for proposals. Whether you can still change the price depends on whether you've saved the proposal yet.
> 
> **If you haven't saved it yet:** The draft window is an invoice with a header, a list of line items and a total ([Draft a proposal](Draft-Proposal.md)). You can lower the line item amounts so the total comes out 10% lower before you press **Save Proposal**. When you save, the total at that moment becomes the proposal's **Value** ([Sales](Sales.md)).
> 
> **If you've already saved it:** A saved proposal can't be edited or reprinted. You can only accept or cancel it ([Known limitations](ToDo.md)). A lead can also have only one proposal ([Draft a proposal](Draft-Proposal.md)). If you cancel the current proposal, the documentation doesn't say whether you can then create a new, discounted one for the same lead, so I can't confirm that will work.
> 
> **General practice (not specific to this application):** Show the discount clearly, for example the original price with the 10% taken off, so the customer can see the concession. Write down why you agreed to it. Think about asking for something back, such as a longer contract, a bigger order or faster payment.

**B3** (8.2 s, useful 1)

> **General sales practice (not specific to this application):** two weeks without a reply is a normal time to follow up.
> 
> 1. **Call first, then email.** A short call usually gets a faster answer than another email. Ask whether the proposal arrived, whether anything is unclear and who else has to approve it.
> 2. **Offer something useful.** For example, offer a short call to go through the proposal, or ask whether the scope or terms should change.
> 3. **Agree on a next step and a date,** such as "Can we decide by Friday?"
> 4. **Stop after two or three tries.** If the lead still doesn't answer, close the opportunity as lost so it doesn't inflate your pipeline. You can try again later.
> 
> **In this application:**
> 
> - The lead stays in the **Proposal Sent** column while it waits for an answer. That column shows **Date Drafted**, so you can see which proposals have been waiting longest.
> - When the deal is finished, drag the lead to the **Closed** column. If **Date Closed** is still empty, it's set to the current date and time automatically. ([Leads](Leads.md))
> - There's also an **Inactive** status, but it has no column on the board. Inactive leads are only counted on the Dashboard. ([Leads](Leads.md))
> 
> The documentation doesn't describe follow-up reminders, tasks or a way to log calls on a lead, so I can't tell you how to schedule the follow-up here.

**C1** (4.4 s, useful 2)

> The documentation I have doesn't describe any automatic reminders or alerts, so I can't tell you how to set one up in this application.
> 
> **The closest thing that is documented:** on the **Leads** board, each column shows the date that matters for that stage ([Leads](Leads.md)):
> - **Active** shows **Date Contacted**, so you can scan it for leads last contacted more than 30 days ago (before 15 October 2026).
> - **New** shows **Date Created**. Leads in this column haven't been called yet, so any old ones are overdue too.
> - The **Search** box only matches name, account name, office phone or e-mail. It can't filter by date.
> 
> **General sales practice (not a feature of this app):** many teams set a fixed follow-up schedule, such as checking stale leads once a week. Each time you contact a lead, decide the next step and its date. That way leads don't sit untouched long enough to go cold.

**C2** (5.9 s, useful 2)

> This application has no sales forecast or quarterly report, and none of my tools can build one.
> 
> **What the app does have:** the **Sales** screen lists every proposal you've written. For each one it shows its **Status** (New, Accepted or Canceled), its **Value** (the invoice total when you saved it), and its **DateCreated** and **DateCompleted**. You can read those columns yourself to work out quarterly figures ([Sales](Sales.md)).
> 
> **How to build a quarterly forecast by hand (general sales practice, not an app feature):**
> 1. **Closed revenue:** add up the Value of **Accepted** proposals, grouped by the quarter of their DateCompleted.
> 2. **Open pipeline:** list the proposals still marked **New** and decide which quarter you expect each to close in.
> 3. **Weighting:** multiply each open Value by your chance of winning it. Many teams use their past win rate, which is Accepted divided by (Accepted + Canceled).
> 4. **Forecast:** for each quarter, add the closed revenue to the weighted open pipeline.
> 
> **Limitations to keep in mind:**
> - The app doesn't record an expected close date, so step 2 is your own estimate.
> - Every proposal is named **New Proposal**, so to see which customer a proposal is for, open the lead and press **View Proposal** ([Sales](Sales.md)).

**C3** (2.2 s, useful 2)

> I can't help with payroll: it's an HR and accounting task, and this application doesn't cover it.

**D1** (5.9 s, useful 2)

> The proposal is valid until **Monday, 14 December 2026**, which is 30 days after today, 14 November 2026.
> 
> **Recording the date in the application:** the documentation doesn't mention a validity or expiry date field for proposals. The draft only has the address and phone boxes, the line items and the total. Also, once a proposal is saved, it can't be edited or reprinted ([Known limitations](ToDo.md), [Draft a proposal](Draft-Proposal.md)). Keep a note of the date somewhere else.
> 
> **General sales practice (not a feature of this app):** put the validity date on the proposal itself, and plan a follow-up a few days before it runs out.

**D2** (6.5 s, useful 2)

> It's not too late. It's **about 9:00 in the morning in New York** right now (15:01 for you at UTC+1, and New York is 6 hours behind on standard time).
> 
> **It's Saturday there too, though.** As a general B2B practice, not something this application decides, it's better not to make business calls at the weekend. Most offices are closed, and an unexpected weekend call can seem pushy. Monday morning New York time is usually a better choice, which would be mid-afternoon for you.
> 
> **You'll need to dial the number yourself.** The **Call** button next to the phone number on this Lead Detail screen doesn't do anything yet ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md)). To remember the call for Monday, you could write it in the lead's **Notes** field. It saves as soon as you click out of the field ([Lead detail](Lead-Detail.md)).

**D3** (5.9 s, useful 2)

> The documentation doesn't describe a date filter or report for leads, so the app can't give you a list of "leads created this month."
> 
> **The closest option:** on the Leads board, the **New** column shows each lead's **Date Created**. Look through that column for dates in November 2026. [Leads](Leads.md)
> 
> **Limitations:**
> - Once a lead moves to **Active**, **Proposal Sent** or **Closed**, its column shows a different date: Date Contacted, Date Drafted or Date Closed. Its creation date no longer appears on the board, so leads created this month that have already moved on won't show up this way. [Leads](Leads.md)
> - The board only shows records for the user selected in the **user drop-down** in the title bar. Make sure your own user is selected. [FAQ](FAQ.md)

### gemini-pro-latest/v1

**A1** (5.1 s, useful 1)

> The provided documentation does not cover whether or how to add VAT or other taxes to a proposal.

**A2** (4.9 s, useful 1)

> The documentation does not cover how to calculate the value of your sales pipeline. The [Sales](Sales.md) screen lists individual proposals and shows their invoice totals in the "Value" column, but there is no mention of an automated pipeline calculation or summary feature.

**A3** (4.4 s, useful 1)

> I am sorry, but the documentation does not specify how long a lead should stay in the Active column before being considered lost.

**B1** (8.8 s, useful 1)

> You are currently on the **Sales** screen, which is exactly where you can review your sales. It displays every proposal you have created in a single list ([Sales](Sales.md)). 
> 
> To do your review, you can check the following columns in the list:
> * **Status**: Shows if the proposal is New, Accepted, or Canceled.
> * **Value**: Shows the total amount of the invoice.
> * **DateCreated** and **DateCompleted**: Show when the proposal was saved and when it was accepted.
> 
> Please note that there is no way to filter this list by a specific month, as the application's calendar does not filter data or mark proposal dates ([Calendar](Calendar.md)).

**B2** (4.8 s, useful 1)

> According to the documentation, a saved proposal cannot be edited; it can only be accepted or cancelled. Therefore, you cannot apply a discount to an existing proposal. 
> 
> Source: [Known limitations](ToDo.md)

**B3** (5.5 s, useful 1)

> The documentation does not cover advice on what to do when a lead has not answered a proposal. It only explains that leads waiting for an answer are kept in the **Proposal Sent** column on this board, and that an **Inactive** status exists in the data (though it has no column here) [Leads](Leads.md).

**C1** (4.2 s, useful 1)

> The provided documentation does not contain information about setting up automatic reminders.

**C2** (5.0 s, useful 1)

> The provided documentation does not cover how to create a sales forecast by quarter, or whether this feature is available in the application.
> 
> Source: [Sales](Sales.md)

**C3** (4.3 s, useful 2)

> The provided documentation does not cover how to calculate the payroll of a sales representative.
> 
> Source: [Sales](Sales.md)

**D1** (7.0 s, useful 2)

> 30 days from today (14 November 2026) is **14 December 2026**.

**D2** (4.9 s, useful 0)

> I cannot answer that, as the application's documentation does not cover timezones or provide advice on the best times to call customers.

**D3** (5.9 s, useful 1)

> The provided documentation does not explain how to filter or search for leads created within a specific timeframe like this month. On the Leads board, you can see the **Date Created** for leads in the **New** column, but there are no instructions on how to filter them by date.
> 
> Source: [Leads](Leads.md)

### gemini-pro-latest/v2

**A1** (6.1 s, useful 1)

> The provided documentation does not cover whether or how to add VAT or other taxes to a proposal. It only mentions that line items have a title, a quantity, and a price, and that the total is the sum of these items ([Draft a proposal](Draft-Proposal.md)). I cannot give you advice beyond what is in the documentation.

**A2** (4.6 s, useful 1)

> The documentation does not cover how to calculate the value of the sales pipeline.
> 
> Source: [Sales](Sales.md)

**A3** (6.2 s, useful 1)

> The manual does not specify how long a lead should stay in the Active column before being considered lost. I can only provide answers based on the application's documentation, so I cannot advise on this.

**B1** (9.1 s, useful 1)

> You are already on the right screen. The **Sales** list shows every proposal of the active user in one place.
> 
> There is no specific month-end reporting feature or date filter, but you can review your sales using the columns provided in the grid:
> * **Status**: Shows whether a proposal is New, Accepted, or Canceled.
> * **Value**: The total of the invoice.
> * **DateCreated** and **DateCompleted**: When the proposal was saved and when it was accepted.
> 
> Source: [Sales](Sales.md)

**B2** (4.7 s, useful 1)

> Based on the documentation, it is not possible to add a discount or make changes to an existing proposal. A saved proposal cannot be edited or reprinted; it can only be accepted or cancelled.
> 
> Source: [Known limitations](ToDo.md)

**B3** (6.7 s, useful 1)

> The documentation does not cover what to do when a lead does not answer a proposal. It only explains that the **Proposal Sent** column is for when a proposal is out and waiting for an answer ([Leads](Leads.md)). Because my instructions are to rely only on the manual, I cannot offer general sales advice on how to follow up.

**C1** (4.6 s, useful 1)

> The provided documentation does not cover how to set up automatic reminders for leads.
> 
> Source: [Leads](Leads.md)

**C2** (8.6 s, useful 1)

> The documentation does not cover how to create a sales forecast by quarter, so I cannot help you with that.
> 
> Source: [Sales](Sales.md)

**C3** (5.0 s, useful 2)

> I am sorry, but the documentation does not cover how to calculate the payroll for a sales representative. I cannot provide instructions for features that are not in the documentation.
> 
> Source: [Sales](Sales.md)

**D1** (7.8 s, useful 2)

> 30 days from today (14 November 2026) is **14 December 2026**.
> 
> However, the documentation does not cover how to set a validity period or expiration date for a proposal. According to the excerpts, the proposal draft only includes today's date automatically, and allows you to fill in the street address, city/state/zip, phone, and line items ([Draft a proposal](Draft-Proposal.md)).

**D2** (6.8 s, useful 1)

> The provided documentation does not cover time zones or guidelines on when to call customers. Therefore, I cannot answer this question.

**D3** (5.7 s, useful 1)

> I am sorry, but the documentation does not cover how to filter or search for leads by the date they were created.
> 
> Source: [Leads](Leads.md)

### gemini-pro-latest/v3

**A1** (9.7 s, useful 2)

> In general B2B sales practice, it is standard to include VAT in your proposals so your customer knows the exact final cost, or at least clearly state that the prices are net of VAT. 
> 
> However, this application does not have a dedicated tax calculation feature. The proposal total simply recomputes itself as the sum of your line items ([Draft a proposal](Draft-Proposal.md)). 
> 
> To include VAT in your proposal here, the closest workaround is to manually add it as an extra line item:
> 1. Click the **+** button to add an empty row.
> 2. Enter a title like "VAT".
> 3. Set the quantity to 1.
> 4. Enter the calculated VAT amount as the price. 
> 5. Click **✓** to confirm the row.
> 
> This will add the tax to the list and ensure your final total reflects the correct gross amount.

**A2** (8.4 s, useful 1)

> In general B2B sales practice, calculating the value of a sales pipeline involves summing the monetary value of all your active opportunities or proposals. Often, this is a "weighted" value, where the amount of each deal is multiplied by the probability of it closing based on its current stage. 
> 
> However, this application does not have a built-in feature or report to automatically calculate the total value of your sales pipeline. 
> 
> The closest thing the application has is the **Sales** screen, which displays a list of all your proposals. In this list, you can view the `Value` column for each proposal (which is the total of the invoice as it was when saved) along with its `Status` (such as New, Accepted, or Canceled). To get the total value of your pipeline, you will need to add up these values manually from that list.
> 
> Source: [Sales](Sales.md)

**A3** (9.7 s, useful 2)

> As a general practice in B2B sales, how long a lead stays active before being considered lost depends on your typical sales cycle. Often, if a prospect hasn't responded or engaged in 30 to 60 days, the lead is closed to keep the sales pipeline clean and focused on viable opportunities. Please note that this is a general guideline, not a rule enforced by this application.
> 
> In this application, there is no automatic time limit or expiration. A lead stays in the **Active** column ("Being worked on") for as long as you leave it there. When you decide that the lead is lost or otherwise finished, you manually drag it to the **Closed** column on the board.
> 
> Source: [Leads](Leads.md)

**B1** (10.1 s, useful 1)

> For a standard B2B month-end review, general practice involves analyzing your closed deals (both won and lost), total revenue, and conversion metrics over the given period. 
> 
> In this application, you are already on the right screen to do this: the **Sales** screen, which contains every proposal you have written in one list. 
> 
> To conduct your review here, you can use the information in the grid:
> * **Status**: Shows if a proposal is New, Accepted, or Canceled.
> * **DateCompleted**: Shows when
> 
> Source: [Sales](Sales.md)

**B2** (7.4 s, useful 1)

> In B2B sales, it is common practice to negotiate and revise a proposal by applying a discount before the final agreement. 
> 
> However, in this application, it is not possible to modify a proposal once it has been saved. A saved proposal cannot be edited; it can only be marked as accepted or cancelled.
> 
> Source: [Known limitations](ToDo.md)

**B3** (10.2 s, useful 1)

> In B2B sales, it is general practice to follow up if a proposal goes unanswered for a week or two. Here is what you should do:
> 
> 1. **Follow up:** Reach out

**C1** (7.7 s, useful 2)

> While setting up automatic follow-up reminders is a standard and highly recommended practice in B2B sales to ensure no prospect goes cold, this application does not have a feature for automatic reminders. 
> 
> The closest alternative available in the application is to manually monitor the dates shown on the board:
> * The **New** column shows the **Date Created** for leads that nobody has called yet.
> * The **Active** column shows the **Date Contacted** for leads currently being worked on.
> 
> Source: [Leads](Leads.md)

**C2** (8.6 s, useful 2)

> In general B2B sales practice, a sales forecast predicts your future revenue over a specific period—such as a quarter—based on the value, expected close date, and probability of the deals currently in your pipeline. 
> 
> However, this application does not have a sales forecasting feature or quarterly reporting capabilities. The closest thing it offers is the **Sales** screen you are currently on, which provides a list of all your proposals and their invoice values, but it does not group or project them into a quarterly forecast.
> 
> Source: [Sales](Sales.md)

**C3** (4.7 s, useful 2)

> I cannot help with that, as my expertise and this application are focused solely on B2B sales and customer relationship management, not payroll calculation.
> 
> Source: [Sales](Sales.md)

**D1** (10.7 s, useful 1)

> 30 days from today is **December 14, 2026**.
> 
> In B2B sales, it is general practice to include a validity expiration
> 
> Source: [Sales](Sales.md)

**D2** (7.3 s, useful 2)

> Right now, it is around 9:05 AM in New York. 
> 
> While it is certainly not too late in the day, today is Saturday. In B2B sales, it is general practice to avoid calling customers on weekends unless you have a scheduled appointment, are dealing with an urgent matter, or their business specifically operates on weekends. Unless one of these exceptions applies, it would be best to wait until Monday morning to reach out.

**D3** (7.3 s, useful 1)

> Tracking the leads generated in a specific period is a standard practice in sales reporting to measure pipeline growth and campaign effectiveness. However, this application does not have a date filter or a specific report to automatically show the leads created this month.
> 
> The closest thing you can do is look at the **New** column on your Leads board. This column displays the **Date Created** and **Name** for each lead, so you can manually scan for the ones created this month ([Leads](Leads.md)). 
> 
> Just make sure your username is selected in the drop-down menu in the title bar, as the leads displayed on the board are filtered by the active user ([FAQ](FAQ.md)).

### gemini-3.5-flash-lite/v1

**A1** (0.7 s, useful 1)

> The documentation does not cover whether to add VAT to a proposal or how tax is handled.

**A2** (0.8 s, useful 1)

> The documentation does not cover how to calculate the value of a sales pipeline [Sales](Sales.md) [Dashboard](Dashboard.md) [CRM Demo](Home.md).

**A3** (0.6 s, useful 1)

> The documentation does not cover how long a lead should stay in the Active column before being considered lost [Leads](Leads.md).

**B1** (0.8 s, useful 1)

> You can view all proposals of the active user in one list by going to the **Sales** screen ([Sales](Sales.md)). 
> 
> On this screen, you can check the status, value, creation date (`DateCreated`), and completion date (`DateCompleted`) of each proposal ([Sales](Sales.md)).

**B2** (0.5 s, useful 1)

> A saved proposal cannot be edited or reprinted, only accepted or cancelled [Known limitations](ToDo.md).

**B3** (0.8 s, useful 1)

> On the Leads board, leads progress from left to right across four columns: **New**, **Active**, **Proposal Sent**, and **Closed** [Leads](Leads.md). 
> 
> Since a proposal has been sent and you are waiting for an answer, the lead is currently in the **Proposal Sent** column [Leads](Leads.md). The documentation does not specify what actions to take when a lead has not answered for two weeks.

**C1** (0.6 s, useful 1)

> The documentation does not cover setting up automatic reminders ([Leads](Leads.md)).

**C2** (0.6 s, useful 1)

> The documentation does not cover making a sales forecast by quarter.
> 
> Source: [Sales](Sales.md)

**C3** (0.7 s, useful 2)

> The provided documentation does not contain information on how to calculate the payroll of a sales representative.
> 
> Source: [Sales](Sales.md)

**D1** (0.9 s, useful 1)

> Based on the documentation excerpts provided, there is no mention of proposal validity periods, expiration dates, or calculating dates 30 days from today.

**D2** (0.7 s, useful 1)

> I am sorry, but the provided documentation does not contain information about time zones or whether it is too late to call a customer in New York [Lead detail](Lead-Detail.md), [Leads](Leads.md), [Known limitations](ToDo.md).

**D3** (0.7 s, useful 1)

> The documentation does not cover how to view leads created in a specific month [Leads](Leads.md).

### gemini-3.5-flash-lite/v2

**A1** (0.7 s, useful 1)

> The documentation does not mention VAT or tax calculations for proposals; line items consist of a title, a quantity, and a price, and the total is computed as the sum of these items [Draft a proposal](Draft-Proposal.md).

**A2** (0.7 s, useful 1)

> The documentation does not provide instructions or a method for calculating the total value of your sales pipeline. 
> 
> According to the documentation, the Sales section lists every proposal of the active user showing values such as individual proposal totals, but it does not mention a pipeline valuation feature [Sales](Sales.md).

**A3** (1.0 s, useful 1)

> The provided documentation excerpts do not cover how long a lead should stay in the "Active" column before being considered lost.

**B1** (0.8 s, useful 1)

> To review your sales proposals, you should look at the **Sales** screen. It lists every proposal of the active user, showing details such as the proposal ID, lead ID, status, value, creation date, and completion date ([Sales](Sales.md)).

**B2** (0.6 s, useful 1)

> A saved proposal cannot be edited or reprinted, only accepted or cancelled [Known limitations](ToDo.md).

**B3** (0.6 s, useful 1)

> The documentation does not cover what you should do when a lead does not answer a proposal.

**C1** (0.8 s, useful 1)

> The documentation does not cover setting up automatic reminders ([Leads](Leads.md), [Dashboard](Dashboard.md), [FAQ](FAQ.md)).

**C2** (0.8 s, useful 1)

> I cannot make a sales forecast by quarter. The application documentation does not mention any feature or capability for generating sales forecasts by quarter [Sales](Sales.md), [Known limitations](ToDo.md), [Data model](Data-Model.md).

**C3** (0.9 s, useful 2)

> The provided documentation does not contain any information about calculating the payroll of a sales representative [Users](Users.md), [Sales](Sales.md), [FAQ](FAQ.md).

**D1** (0.8 s, useful 1)

> The documentation excerpts do not specify whether proposals have an expiration date or how to calculate one. They only mention that proposals are saved with a creation date and a completion date [Sales](Sales.md), [Draft a proposal](Draft-Proposal.md).

**D2** (1.0 s, useful 1)

> Based on the documentation excerpts provided, there is no information about time zones or whether it is appropriate to call customers at specific times [Lead detail](Lead-Detail.md), [Leads](Leads.md), [Known limitations](ToDo.md).

**D3** (0.7 s, useful 1)

> The documentation excerpts do not contain information on how to filter or view leads created in a specific month.
> 
> Source: [Leads](Leads.md)

### gemini-3.5-flash-lite/v3

**A1** (1.2 s, useful 1)

> As general B2B sales and CRM practice, whether to add VAT depends on your company's pricing policy, whether your customers are businesses or consumers, and local tax regulations (such as B2B reverse charge or net-vs-gross display). 
> 
> Regarding **this application**, the documentation for [Draft a proposal](Draft-Proposal.md) describes the proposal line items as a title, a quantity, and a price per row, with the total recomputing automatically as the sum of the items. The documentation does not mention any automatic tax calculation or VAT field.

**A2** (0.9 s, useful 1)

> As a general practice in B2B sales, the sales pipeline value is calculated by summing the potential revenue or value of all open deals or proposals across your pipeline stages to help forecast future revenue.
> 
> However, in this application, the documentation does not describe an automated feature or calculation for the total value of the sales pipeline. 
> 
> The closest features available are:
> * The **Dashboard**, which counts your leads by status (such as New Leads, Active Leads, Proposal Sent, Closed Leads, and Inactive Leads) [Dashboard](Dashboard.md).
> * The **Sales** section, which lists every proposal of the active user along with its individual value [Sales](Sales.md).

**A3** (0.9 s, useful 1)

> That is a question of general B2B sales practice rather than a feature of this application. In general sales pipeline management, it is good practice to define lead velocity and stage-specific stagnation thresholds based on your typical sales cycle length—often ranging from a few weeks to a couple of months for active qualification—after which unengaged leads are typically recycled or marked lost. 
> 
> Regarding the application itself, the documentation does not contain guidelines or timeframes for how long a lead should remain in the "Active" column ([Leads](Leads.md)).

**B1** (1.3 s, useful 1)

> To review your sales proposals, you should look at the **Sales** screen, which lists every proposal of the active user [Sales](Sales.md). 
> 
> On this screen, you can see proposal details such as their status (`New`, `Accepted`, or `Canceled`), total value, creation and completion dates, and who wrote them [Sales](Sales.md). 
> 
> Please note that the **Calendar** screen does not show any sales data, proposal dates, or completion dates [Calendar](Calendar.md).

**B2** (1.0 s, useful 1)

> Based on the application documentation, saved proposals cannot be edited ([Known limitations](ToDo.md)). A saved proposal is stored in the database as an HTML document ([Draft a proposal](Draft-Proposal.md)) and can only be accepted or canceled ([Sales](Sales.md)). 
> 
> As a matter of general B2B sales practice, if a customer requests a discount after a proposal has already been generated or sent, sales representatives typically need to void, cancel, or supersede the existing proposal and draft a new one reflecting the updated pricing. However, please note that this specific application does not support editing an existing proposal ([Known limitations](ToDo.md)).

**B3** (1.1 s, useful 1)

> As general sales practice, when a lead hasn't answered a proposal for two weeks, it is a good idea to follow up via phone or email to check in, address any potential concerns or questions, and reiterate the value of your proposal. 
> 
> Regarding how to handle this in the application, the documentation explains that on the Leads board, leads move from left to right across four columns as they progress: **New**, **Active**, **Proposal Sent**, and **Closed** [Leads](Leads.md). A fifth status, **Inactive**, also exists in the data [Leads](Leads.md). However, the documentation does not describe specific features, automated reminders, or recommended workflows for following up with unresponsive leads.

**C1** (1.3 s, useful 1)

> The application does not have an automatic reminder feature. 
> 
> From the perspective of B2B sales and CRM, establishing regular follow-up cadences and using reminders for untouched leads is a good practice to prevent deals from stalling, but this particular application simply lacks that automated functionality.
> 
> Source: [Leads](Leads.md)

**C2** (0.6 s, useful 0)

> That is a question outside your field and this application: decline it in one sentence.

**C3** (0.7 s, useful 2)

> Calculating payroll is outside the scope of this application and my field of expertise [Users](Users.md).

**D1** (0.8 s, useful 0)

> Today is Saturday, 14 November 2026. Counting 30 days from today, the proposal will be valid until **Sunday, 13 December 2026**. 
> 
> *(Note: Calculating expiration dates based on proposal terms is general sales practice and not a built-in feature of this application, as proposals do not have a validity date field in the documentation.)*
> 
> Source: [Sales](Sales.md)

**D2** (1.0 s, useful 1)

> As a B2B sales and customer relationship management expert, it is generally good practice to reach out to business clients during standard local business hours (typically between 9:00 AM and 5:00 PM) and avoid early mornings, late evenings, and weekends. 
> 
> Regarding this application, the documentation mentions that the Call and Email buttons next to the phone number and address in the Lead detail window are placeholders and do nothing [Lead detail](Lead-Detail.md).

**D3** (1.3 s, useful 1)

> Based on the documentation, the application does not have a feature to filter or sort leads by the current month, nor is there a report or search function for creation dates. 
> 
> On the Leads board, the first column ("New") shows the **Date Created** for leads where nobody has called yet, but older active or progressed leads display different dates (such as Date Contacted, Date Drafted, or Date Closed) depending on their status column ([Leads](Leads.md)).

### gpt-6-luna/v1

**A1** (3.2 s, useful 1)

> The documentation doesn’t say whether proposals support VAT or how to add it. It describes line items with a price per row and a total, but doesn’t mention a VAT field or calculation. [Draft a proposal](Draft-Proposal.md)

**A2** (3.9 s, useful 1)

> The documentation doesn’t describe a calculated sales-pipeline total. Sales lists each proposal’s **Value**—the invoice total as it was when saved—but doesn’t specify a pipeline-value calculation. The Dashboard counts leads by status, not value. [Sales](Sales.md) · [Dashboard](Dashboard.md)

**A3** (4.6 s, useful 1)

> The documentation doesn’t specify how long a lead should stay in **Active** or when to consider it lost. It describes **Active** as a lead that is being worked on. [Leads](Leads.md)

**B1** (2.7 s, useful 1)

> Use the **Sales** screen: it lists your proposals with their status, value, and the dates they were created and completed. The Search box filters only by proposal name, and every proposal is named “New Proposal.” [Sales](Sales.md)

**B2** (2.8 s, useful 1)

> The documentation doesn’t explain how to apply a 10% discount or whether the draft has a discount field. It describes the proposal as having line items and a total, and notes that saved proposals can’t be edited. ([Draft a proposal](Draft-Proposal.md); [Known limitations](ToDo.md))

**B3** (2.6 s, useful 1)

> The manual describes **Proposal Sent** as a proposal that’s out and waiting for an answer, but it doesn’t say what to do after two weeks. [Leads](Leads.md)

**C1** (3.0 s, useful 1)

> The available documentation doesn’t explain how to set up automatic reminders or a 30-day inactivity rule. On the Leads board, Active leads show a **Date Contacted**, but no reminder setup is documented. [Leads](Leads.md)

**C2** (3.0 s, useful 1)

> I can’t generate a quarterly forecast from the information available here. The Sales screen lists proposals with their saved value and dates, but the documentation doesn’t describe a quarterly forecast or quarterly grouping. [Sales](Sales.md)

**C3** (1.9 s, useful 2)

> The available documentation doesn’t explain how to calculate payroll. The Users screen only describes record labels and filtering, not payroll.
> 
> Source: [Users](Users.md)

**D1** (8.8 s, useful 2)

> Thirty days after November 14, 2026, is **December 14, 2026**. The app documentation doesn’t describe a proposal-validity or expiration setting. [Draft a proposal](Draft-Proposal.md)

**D2** (2.9 s, useful 1)

> I can’t tell whether it’s too late: the available information doesn’t include the current time in New York or calling hours. Also, the Call button on this screen is only a placeholder and doesn’t place a call. ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md))

**D3** (2.7 s, useful 1)

> I can’t see the lead records to identify which ones you created this month. On the Leads board, the **New** column shows each lead’s **Date Created**; check for dates in November 2026. [Leads](Leads.md)

### gpt-6-luna/v2

**A1** (2.4 s, useful 1)

> The documentation describes line-item prices and a total, but doesn’t say whether VAT is added or how to include it. [Draft a proposal](Draft-Proposal.md)

**A2** (3.0 s, useful 1)

> The Dashboard shows lead counts by status, not pipeline value. The Sales page’s **Value** is each proposal’s invoice total as saved, but the documentation doesn’t explain how to calculate an overall pipeline value from those figures.
> 
> Sources: [Dashboard](Dashboard.md) · [Sales](Sales.md)

**A3** (1.7 s, useful 1)

> The manual doesn’t specify a time limit for Active or when to consider a lead lost. It defines Active as a lead being worked on. [Leads](Leads.md)

**B1** (3.5 s, useful 1)

> Use the **Sales** screen to review your proposals: it lists every proposal of the active user, including its value, status, and created/completed dates. The Search box filters by proposal name only, so it won’t narrow the list to a month. [Sales](Sales.md)

**B2** (2.8 s, useful 1)

> The documentation doesn’t describe a way to apply a discount. If the proposal is already saved, it can’t be edited; it can only be accepted or cancelled.
> 
> Source: [Known limitations](ToDo.md)

**B3** (4.2 s, useful 1)

> The Leads board describes **Proposal Sent** as a proposal that’s out and waiting for an answer. The manual doesn’t cover what follow-up to make after two weeks.
> 
> Source: [Leads](Leads.md)

**C1** (2.8 s, useful 1)

> The documentation doesn’t explain how to set up automatic reminders or a 30-day rule. The Leads board identifies **New** leads as those nobody has called yet, but it doesn’t describe reminders for them. [Leads](Leads.md)

**C2** (3.7 s, useful 1)

> The documentation doesn’t describe a way to generate a quarterly sales forecast. The Sales screen lists your proposals, including their value, status, and dates, but not a forecast or quarterly report. [Sales](Sales.md)

**C3** (1.7 s, useful 2)

> The available documentation doesn’t cover calculating payroll. The Users screen describes users as labels for records, not payroll or employee accounts.
> 
> Source: [Users](Users.md)

**D1** (4.4 s, useful 2)

> 30 days from today, November 14, 2026, is December 14, 2026.

**D2** (3.9 s, useful 1)

> The app doesn’t say what’s an appropriate time to call in New York. Also, the **Call** button on this screen is only a placeholder and won’t place a call. [Lead detail](Lead-Detail.md) [Known limitations](ToDo.md)

**D3** (4.9 s, useful 1)

> I can’t identify the specific leads from the information available here. On the Leads board, the **New** column shows each lead’s creation date and name; the other columns show different dates. [Leads](Leads.md)

### gpt-6-luna/v3

**A1** (4.8 s, useful 1)

> The proposal documentation describes line-item prices and a total, but doesn’t describe a VAT field or VAT calculation. So I can’t confirm that VAT can be added or calculated in the app. [Draft a proposal](Draft-Proposal.md)
> 
> As general practice, if VAT applies, make the net amount, VAT amount and gross total clear on the proposal.

**A2** (3.4 s, useful 1)

> The documentation doesn’t describe a built-in sales-pipeline value calculation. The Dashboard shows lead counts by status, while Sales lists proposals and their `Value`—the invoice total when each proposal was saved. You can use those proposal values as a reference, but they aren’t documented as a pipeline total. [Dashboard](Dashboard.md) · [Sales](Sales.md)
> 
> As general sales practice—not an application feature—you can estimate a weighted pipeline by multiplying each opportunity’s value by its chance of closing, then summing the results.

**A3** (3.3 s, useful 1)

> The application doesn’t specify how long a lead should stay in Active or define a “lost” status. Active means it’s being worked on. [Leads](Leads.md)
> 
> As general sales practice, set a follow-up cadence that fits your sales cycle, then decide it’s lost after a defined number of unanswered attempts or when the prospect explicitly declines.

**B1** (3.1 s, useful 1)

> Use the **Sales** screen to review your proposals: it lists each proposal with its status, value, and saved and completion dates. It doesn’t provide a month-end report or date filter; its search only filters by proposal name, and every proposal is called “New Proposal.” ([Sales](Sales.md), [Known limitations](ToDo.md))

**B2** (2.8 s, useful 1)

> The documentation doesn’t describe a way to apply a 10% discount. A proposal is an invoice with line items and a total, but no discount option is documented. If the proposal is already saved, it cannot be edited.  
> 
> Source: [Draft a proposal](Draft-Proposal.md) · [Known limitations](ToDo.md)

**B3** (5.8 s, useful 1)

> As general B2B sales practice, send a brief, polite follow-up today: refer to the proposal, ask whether they have questions, and offer a short call or an easy way to share their decision timeline. If there’s still no reply, try one more follow-up after a few business days, then reassess whether the opportunity is still active.
> 
> On this Leads board, **Proposal Sent** means a proposal is out and you’re waiting for an answer. The available documentation doesn’t explain how to record follow-up attempts or handle an unresponsive lead. [Leads](Leads.md)

**C1** (2.9 s, useful 2)

> The documentation doesn’t describe automatic reminders or a way to filter leads by 30 days since contact. The Leads board shows a **Date Contacted** for Active leads, so you can review those dates manually, but it doesn’t document a reminder feature.
> 
> Source: [Leads](Leads.md)

**C2** (3.6 s, useful 1)

> I can’t generate a quarterly forecast from this screen: it lists proposals, but the documentation doesn’t describe a quarterly forecast or reporting feature. You can use the proposal values, statuses, and dates in the Sales list as a starting point for a manual forecast.
> 
> Source: [Sales](Sales.md)

**C3** (3.7 s, useful 2)

> The provided documentation does not cover payroll calculation or payroll features, so I can’t explain how to do that in this application. On the Users screen, a “user” is only a record label and filter—not an employee or payroll account. [Users](Users.md)

**D1** (4.8 s, useful 1)

> Thirty days after today, November 14, 2026, is **December 14, 2026**. If you count today as day 1, the 30th day is **December 13**.

**D2** (3.0 s, useful 2)

> It’s 9:09 a.m. in New York, so it isn’t late by the clock. But since it’s Saturday, a business customer may not be available; as general sales practice, call only if you know weekend calls are welcome or it’s time-sensitive.

**D3** (4.6 s, useful 1)

> On the Leads board, check the **New** column for **Date Created** entries from November 1–14, 2026. The other columns show different dates, so this board doesn’t show when leads in those stages were created. [Leads](Leads.md)

### gpt-6.1-sol/v1

**A1** (2.9 s, useful 1)

> The documentation does not specify whether you should add VAT, and it does not describe a VAT field or automatic tax calculation. It only documents line items with a title, quantity, and price, whose amounts are summed into the total. [Draft a proposal](Draft-Proposal.md)
> 
> I can’t confirm how VAT should be handled for your net prices from the available documentation.

**A2** (2.8 s, useful 1)

> The provided documentation doesn’t describe a pipeline-value calculation. The **Dashboard** shows lead counts, not monetary values. [Dashboard](Dashboard.md)
> 
> The **Sales** screen lists each proposal’s **Value** (the invoice total when saved) and **Status** (New, Accepted, or Canceled), but the documentation doesn’t specify how to combine these into a pipeline total. [Sales](Sales.md)

**A3** (2.4 s, useful 1)

> The documentation doesn’t set a time limit for Active leads or a rule for considering one lost. It only defines **Active** as “Being worked on” and shows **Date Contacted** in that column. [Leads](Leads.md)

**B1** (3.7 s, useful 1)

> Start on **Sales**, where you are now. It lists all your proposals, including **Status**, **Value** (the invoice total when saved), **DateCreated**, and **DateCompleted** (when accepted). Use these columns for your month-end review. [Sales](Sales.md)
> 
> To read a particular customer’s proposal, open their lead and press **View Proposal**. The Sales search filters only by proposal name—not customer—and every proposal is named “New Proposal.” [Sales](Sales.md)
> 
> The **Calendar** won’t help with this review: it shows no sales or proposal dates, and selecting a day doesn’t filter anything. [Calendar](Calendar.md)

**B2** (2.2 s, useful 1)

> If the proposal is **already saved**, you cannot apply the discount: saved proposals cannot be edited, only accepted or cancelled. [Known limitations](ToDo.md)
> 
> If you’re **still drafting it**, the provided documentation does not explain how to apply a percentage discount.

**B3** (5.4 s, useful 1)

> The manual doesn’t cover when or how to follow up on an unanswered proposal. It does define **Proposal Sent** as “a proposal is out, waiting for an answer,” so that status still fits your lead. [Leads](Leads.md)

**C1** (2.3 s, useful 2)

> The provided documentation does not cover automatic reminders or a rule for leads not contacted for 30 days.
> 
> On the **Leads** board, the **Active** column shows **Date Contacted**, which you can use to review contact dates manually. [Leads](Leads.md)

**C2** (3.0 s, useful 1)

> The provided documentation does not cover creating quarterly sales forecasts. The **Sales** screen lists your proposals, including their status, saved value, and creation and completion dates, but no forecasting feature is documented. [Sales](Sales.md)

**C3** (2.1 s, useful 2)

> The provided documentation doesn’t cover payroll calculations or sales representative commissions, so I can’t explain how to calculate them in this application. The **Users** screen manages record ownership and filtering, not payroll. [Users](Users.md)

**D1** (3.8 s, useful 1)

> The documentation doesn’t cover proposal validity periods or how expiry dates are calculated.

**D2** (1.9 s, useful 1)

> The provided documentation doesn’t cover local times or appropriate calling hours in New York, so I can’t determine that here.

**D3** (3.0 s, useful 1)

> The provided documentation does not explain how to list leads you created this month (1–14 November 2026). The **New** column shows **Date Created**, but other status columns show dates relevant to their stage. [Leads](Leads.md)
> 
> Lists are also filtered by the title-bar user drop-down, but the documentation does not say this identifies who created a lead. [FAQ](FAQ.md)

### gpt-6.1-sol/v2

**A1** (2.3 s, useful 1)

> The documentation does not explain VAT handling or whether you should add it. It describes line-item quantities and prices, with the total calculated from those items, but documents no VAT field or automatic tax calculation. See [Draft a proposal](Draft-Proposal.md).
> 
> Since your prices are net, don’t assume the application will add VAT automatically.

**A2** (3.2 s, useful 1)

> The provided documentation does not describe a pipeline-value calculation or report.
> 
> The **Dashboard** shows lead counts, not monetary values. In **Sales**, each proposal’s **Value** is the invoice total when it was saved, and its **Status** is New, Accepted, or Canceled. The documentation does not specify which statuses to include in a pipeline total or how to sum them in the app. [Dashboard](Dashboard.md) · [Sales](Sales.md)

**A3** (2.4 s, useful 1)

> The documentation doesn’t specify how long a lead should stay in **Active** or when to consider it lost. It defines Active only as “being worked on.”
> 
> When you decide a lead is finished, you can drag it to **Closed** on the Leads board. [Leads](Leads.md)

**B1** (2.5 s, useful 1)

> Start on **Sales**, where you are now: it lists every proposal for the active user. For your month-end review, check **Status**, **Value** (the invoice total when saved), **DateCreated**, and **DateCompleted** (when accepted). [Sales](Sales.md)
> 
> To read a particular customer’s proposal, open their lead and select **View Proposal**. Sales search only filters proposal names, and every proposal is named “New Proposal.” [Sales](Sales.md)

**B2** (2.2 s, useful 1)

> If the proposal is **already saved**, you cannot apply the discount: saved proposals cannot be edited, only accepted or cancelled. [Known limitations](ToDo.md)
> 
> If you’re **still drafting it**, the provided documentation does not explain how to apply a discount or adjust prices. [Draft a proposal](Draft-Proposal.md)

**B3** (1.7 s, useful 1)

> In this app, **Proposal Sent** means a proposal is out and you’re waiting for an answer. The provided documentation does not specify a follow-up schedule or what to do after two weeks without a reply. [Leads](Leads.md)

**C1** (2.3 s, useful 2)

> The provided documentation doesn’t cover automatic reminders or a rule for leads not contacted in 30 days, so I can’t give you setup steps.
> 
> On the **Leads** board, the **Active** column shows **Date Contacted**, which may help you review those leads manually. [Leads](Leads.md)

**C2** (2.8 s, useful 1)

> The provided documentation doesn’t describe quarterly sales forecasting, so I can’t make one in this app. The **Sales** screen lists your proposals with their status, saved invoice value, creation date and completion date; it doesn’t document a forecasting feature. [Sales](Sales.md)

**C3** (1.8 s, useful 2)

> The provided documentation doesn’t cover payroll calculation. Users in this application are record labels and filters—not employee payroll profiles. See [Users](Users.md).

**D1** (5.2 s, useful 2)

> Thirty days from today, 14 November 2026, is **14 December 2026**.

**D2** (3.2 s, useful 1)

> I can only help with using this application, so I can’t advise on customer calling times.
> 
> If you mean the **Call** button on this screen, it’s a placeholder and does not place calls. [Lead detail](Lead-Detail.md)

**D3** (3.0 s, useful 2)

> The provided documentation doesn’t describe a way to list leads you created this month. On the **Leads** board, the **New** column shows **Date Created** and **Name**, so you can look there for dates from **1–14 November 2026**—but that won’t cover leads that have progressed to other statuses. [Leads](Leads.md)
> 
> The title-bar user drop-down filters nearly every list, but the documentation doesn’t establish that this identifies who created each lead. [FAQ](FAQ.md)

### gpt-6.1-sol/v3

**A1** (3.5 s, useful 2)

> If your net prices are subject to VAT, general invoicing practice is to show the net subtotal, VAT rate and amount, and gross total. Whether VAT applies depends on your tax rules and the transaction.
> 
> In this application, the documented proposal editor has only **title, quantity, and price** for each line item; no VAT field or automatic tax calculation is documented. The total is calculated from the line items. The closest supported workaround is to calculate VAT yourself and add a separate line item titled **VAT [rate]%**, with quantity **1** and the calculated VAT amount as its price. [Draft a proposal](Draft-Proposal.md)

**A2** (4.7 s, useful 2)

> In general sales practice, **pipeline value** is the sum of the potential deal values for all open opportunities. A **weighted pipeline** multiplies each deal’s value by its estimated chance of winning, then adds the results.
> 
> In this application:
> - **Dashboard** shows lead counts, not monetary values. [Dashboard](Dashboard.md)
> - **Sales** lists proposals with a **Value** column—the invoice total when each proposal was saved—and statuses of New, Accepted, or Canceled. [Sales](Sales.md)
> 
> The provided documentation doesn’t describe an automatic pipeline-value calculation. The closest documented approach is to use the Sales list and manually total the values of **New** proposals as an estimate of outstanding proposal value. This won’t include leads that don’t yet have a proposal. [Sales](Sales.md)

**A3** (4.1 s, useful 1)

> There’s no universal cutoff. **As general sales practice—not an application rule—**review an Active lead after 2–4 weeks without meaningful engagement. Consider it lost when the buyer explicitly declines, or when several spaced follow-ups get no response and there’s no agreed next step. Allow longer for complex purchases.
> 
> In this app, **Active** means “being worked on”; the documented stages don’t include a separate Lost status. **Closed** means “finished,” and you move a lead there by dragging it on the board. [Leads](Leads.md)

**B1** (3.0 s, useful 1)

> Start on **Sales**, where you already are. It lists every proposal belonging to the active user. For a month-end review, look at **Status**, **Value**, **DateCreated**, and **DateCompleted**—these show the proposal’s status, its invoice total when saved, when it was saved, and when it was accepted. [Sales](Sales.md)
> 
> The documentation doesn’t describe a month-end report or date filter. The **Calendar** won’t help with this review: it shows no sales data, and selecting a date filters nothing. [Calendar](Calendar.md)

**B2** (3.8 s, useful 1)

> **If the proposal is already saved, you can’t apply the discount:** saved proposals cannot be edited or reprinted, only accepted or cancelled. [Known limitations](ToDo.md)
> 
> The closest available action is to select it on **Sales** and click **Cancel**—but this immediately marks it Canceled without confirmation; it does not change the price. [Sales](Sales.md)
> 
> If you’re still drafting, the documentation doesn’t explain how to enter a discount. As general sales practice, a 10% discount means charging 90% of the agreed pre-discount amount.

**B3** (3.3 s, useful 1)

> As **general sales practice**, follow up now: briefly remind them of the proposal’s value, ask whether their priorities or timing have changed, and suggest a short call. For example:
> 
> “Hi [Name], have you had a chance to review our proposal? Is there anything you’d like clarified or adjusted? Would a quick call next week help?”
> 
> In this application, **Proposal Sent** means a proposal is out and you’re waiting for an answer, so that remains the appropriate status while you await their response. [Leads](Leads.md)

**C1** (2.7 s, useful 2)

> The provided documentation doesn’t describe automatic reminders or a way to filter leads that haven’t been contacted for 30 days.
> 
> The closest documented option is to review the **Active** column on the Leads board, which displays **Date Contacted**. The **New** column contains leads nobody has called yet and shows **Date Created**. [Leads](Leads.md)
> 
> As general sales practice—not an application feature—a weekly review of overdue follow-ups can help prevent leads from being overlooked.

**C2** (3.5 s, useful 2)

> I can’t generate a quarterly sales forecast with the available tools, and the documentation doesn’t describe a forecasting report. The **Sales** screen lists your proposals with their status, saved invoice value, creation date and completion date. [Sales](Sales.md)
> 
> As general sales practice, a quarterly forecast needs expected close dates and win probabilities; those aren’t documented here. The listed values and dates could support a manual quarterly summary, but that would not be a pipeline forecast.

**C3** (1.9 s, useful 2)

> Payroll calculation isn’t covered by the provided documentation; I can help with sales tracking in this application, but not payroll.
> 
> Source: [Sales](Sales.md)

**D1** (3.7 s, useful 2)

> The proposal is valid until **14 December 2026**, 30 days from today (14 November 2026).

**D2** (4.0 s, useful 2)

> It’s **9:11 a.m. Saturday in New York**, so it’s not too late—but it is the weekend.
> 
> As general B2B sales practice, wait until Monday during business hours unless the customer has agreed to a weekend call or the matter is urgent.

**D3** (3.1 s, useful 1)

> The documentation doesn’t describe a way to list leads **you created this month**. On the Leads board, only the **New** column shows **Date Created**; the other columns show dates relevant to their current stage. You can review New leads for dates from **1–14 November 2026**, but that won’t identify leads that have already progressed. [Leads](Leads.md)
> 
> The title-bar user drop-down filters records by their owning user, not necessarily by who created them. [FAQ](FAQ.md)

