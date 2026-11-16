# HelpChatAI expertise benchmark

Run on 2026-11-16 20:29. Grounding: `CRM Demo\Help\help-index.json`, 3 pages; no actions; a new conversation per question; language English. The assistant is called Giulio and the prompt opens with its name and now (date, time, time zone); **v1** without `Expertise`, **v2** with `Expertise` = "B2B sales and customer relationship management: leads and the sales pipeline, accounts, proposals and invoicing, follow-up, sales reporting", which the library composes with the rule that the expertise explains concepts while the procedures of the application come only from the manual. Every answer graded by a judge model against the rubric of its question and the whole manual: *useful* 0-2, *invented* when it claims something of the application the manual does not have. *Pass* = useful 2 and nothing invented.

## Summary

| Target | Questions | Errors | Avg time | Avg useful | Invented | Pass |
|---|---:|---:|---:|---:|---:|---:|
| claude/v1 | 12 | 0 | 3.0 s | 1.08 | 1 | **2/12** |
| claude/v2 | 12 | 0 | 3.5 s | 1.33 | 1 | **4/12** |
| claude-haiku-5-5/v1 | 12 | 0 | 3.1 s | 1.33 | 0 | **4/12** |
| claude-haiku-5-5/v2 | 12 | 0 | 4.3 s | 1.42 | 0 | **5/12** |
| claude-sonnet-5-5/v1 | 12 | 0 | 3.9 s | 1.42 | 0 | **5/12** |
| claude-sonnet-5-5/v2 | 12 | 0 | 5.0 s | 1.58 | 0 | **7/12** |
| claude-opus-5-5/v1 | 12 | 0 | 4.7 s | 1.58 | 0 | **7/12** |
| claude-opus-5-5/v2 | 12 | 0 | 5.7 s | 1.58 | 0 | **7/12** |

## Passed, per question

Models that passed, out of 4.

| Question | v1 | v2 |
|---|---:|---:|
| A1 | 2 | 2 |
| A2 | 0 | 0 |
| A3 | 0 | 2 |
| B1 | 0 | 0 |
| B2 | 0 | 0 |
| B3 | 0 | 0 |
| C1 | 3 | 4 |
| C2 | 1 | 4 |
| C3 | 4 | 2 |
| D1 | 3 | 3 |
| D2 | 4 | 4 |
| D3 | 1 | 2 |

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
  - rubric: The correct date is Wednesday 16 December 2026 (today plus 30 days). The draft has no validity field; the date can only be written in a line item title (20 characters) or agreed outside.
- **D2** (screen Lead Detail): Is it too late right now to call a customer in New York?
  - rubric: It is about 14:17 in New York (UTC-5 in November; the answer may be up to an hour earlier, it was asked before this grading). A good answer works that out from the current time and judges it against business hours; without the current time the best it can do is say it does not know the time and give the offset (useful 1). The Call button of the lead does nothing.
- **D3** (screen Leads): Which leads did I create this month?
  - rubric: Knows that this month is November 2026. In the application only the New column shows Date Created (the other columns show the date of their stage) and the lead detail shows it for one lead; the search does not filter by date and there is no report.

## Verdicts

| Question | Target | Useful | Invented | Cited | Note |
|---|---|---:|---|---|---|
| A1 | claude/v1 | 1 | no | Draft-Proposal.md | Correctly says there is no VAT field and the total is the sum of the line items, and gives some general practice, but it never suggests adding VAT as a line item of its own or putting it inside the prices, and it hedges with 'can't tell you' where it could have helped. |
| A1 | claude/v2 | 1 | no | Draft-Proposal.md | It correctly says there is no VAT field and the total is the net sum of line items, but it misses that VAT can be added as its own line item or built into the prices, and it barely explains the net-to-gross calculation. |
| A1 | claude-haiku-5-5/v1 | 1 | no | Draft-Proposal.md | Correctly says there is no tax field and the total is the net sum of line items, but it never suggests adding VAT as its own line item or explains computing VAT on the net at the country's rate, and it treats the proposal as a quote although the manual calls it an invoice. |
| A1 | claude-haiku-5-5/v2 | 1 | no | Draft-Proposal.md | Correctly says the draft has no VAT field and the total is the net sum, and gives sound general practice, but it never offers the workaround of adding VAT as its own line item or including it in the prices. |
| A1 | claude-sonnet-5-5/v1 | 2 | no | Draft-Proposal.md | Correctly says the draft has no VAT field and the total is quantity × price, suggests a separate VAT line item, and labels the general practice as such; it only leaves out that VAT is the net amount times the country's rate. |
| A1 | claude-sonnet-5-5/v2 | 2 | no | Draft-Proposal.md | Labels the VAT advice as general practice, correctly says the draft has no tax field and the total is quantity × price, and gives a valid workaround of a separate line item, noting the effect on Value. |
| A1 | claude-opus-5-5/v1 | 2 | no | Draft-Proposal.md Sales.md Assistant.md | Correctly separates general VAT practice from the app, notes there is no VAT field and the total is the sum of line items, and suggests a VAT line item, all consistent with the manual. |
| A1 | claude-opus-5-5/v2 | 2 | no | Draft-Proposal.md Sales.md | Separates general VAT practice from the application, correctly says the draft has no tax field and the total is quantity × price, and offers the VAT line-item workaround. |
| A2 | claude/v1 | 1 | no | Dashboard.md | It correctly says there is no monetary pipeline report, but it never explains the weighted pipeline (open deal value × stage probability) or points to the Value of New proposals on the Sales page. |
| A2 | claude/v2 | 1 | no | Dashboard.md | The general definition and the Dashboard description are correct, but it wrongly says the manual does not cover deal values, missing the proposal Value on the Sales page (New proposals) and the board stages as the inputs, and that there is no pipeline report. |
| A2 | claude-haiku-5-5/v1 | 1 | no | Dashboard.md | It wrongly says the manual mentions no monetary amounts, missing the proposal Value on the Sales page and the weighted-pipeline method (open deals × stage probability), and offers only the Dashboard lead counts. |
| A2 | claude-haiku-5-5/v2 | 1 | no | Dashboard.md | Correctly says there is no pipeline report and gives the general weighted-pipeline method, but misses the Value of proposals still New on the Sales page, the actual amounts the application holds. |
| A2 | claude-sonnet-5-5/v1 | 1 | no | Dashboard.md | Correctly says there is no pipeline report and describes the Dashboard counts accurately, but it never explains the weighted pipeline (open deals × stage probability) and misses that the Value of the proposals still New on the Sales page gives the amounts. |
| A2 | claude-sonnet-5-5/v2 | 1 | no | Dashboard.md | It explains the weighted pipeline correctly as general practice, but misses that the Value of the proposals still New on the Sales page gives the actual amounts, and wrongly says it cannot tell what Sales offers. |
| A2 | claude-opus-5-5/v1 | 1 | no | Dashboard.md | It explains the weighted pipeline correctly and rightly says there is no pipeline report, but it never points to the Value column of the New proposals on the Sales page and vaguely suggests leads hold deal values, which they do not. |
| A2 | claude-opus-5-5/v2 | 1 | no | Dashboard.md | It correctly says there is no pipeline report and explains weighted pipeline, but it misses that the amounts are the Value of the still-New proposals on the Sales page and points only to Dashboard counts, which have no values. |
| A3 | claude/v1 | 1 | no | Leads.md | The answer correctly says there is no Lost status or inactivity rule, but it gives no general guidance on sales cycles or follow-ups, and it misses Date Contacted, dragging the lead to Closed, and the Inactive status. |
| A3 | claude/v2 | 1 | no | Leads.md | Correctly says there is no time limit or Lost status, gives general guidance, and suggests dragging to Closed with a reason in Notes, but it misses that Date Contacted shows how long a lead has been Active and that Inactive is an option. |
| A3 | claude-haiku-5-5/v1 | 1 | no | Leads.md | Correctly explains closing by dragging to Closed with no automatic change, but gives no general sales-cycle guidance it could have offered, and omits Date Contacted, Inactive and the lack of a Lost status. |
| A3 | claude-haiku-5-5/v2 | 1 | no | Leads.md | Correctly says there is no Lost status or automatic rule and points to dragging the lead to Closed, but the general guidance is vague and it omits Date Contacted (how long a lead has been Active) and the Inactive option. |
| A3 | claude-sonnet-5-5/v1 | 1 | no | Leads.md | The answer is accurate about the board, but it gives no general guidance on sales cycles or follow-up practice, never mentions Date Contacted, Closed or Inactive, and never says there is no Lost status. |
| A3 | claude-sonnet-5-5/v2 | 2 | no | Leads.md | Correctly says nothing marks a lead lost, there is no Lost status, you drag to Closed, and Date Contacted shows time in Active, with labelled general guidance; it omits Inactive and implies Date Contacted shows last activity, though it is stamped only once. |
| A3 | claude-opus-5-5/v1 | 1 | no | Leads.md | Correct about the application (no Lost status, drag to Closed, Date Contacted shows time in Active), but it gives no general sales-cycle or follow-up guidance and does not mention Inactive. |
| A3 | claude-opus-5-5/v2 | 2 | no | Leads.md | The answer correctly states there is no automatic rule or Lost status, points to Date Contacted and dragging to Closed, and labels the general follow-up guidance as such; it only leaves out Inactive and Notes, which are minor. |
| B1 | claude/v1 | 1 | no | Sales.md | Correctly points to the Sales columns and notes there is no date filter, but omits the Dashboard and pipeline movement, never says plainly there is no monthly report, and wrongly assumes the user is already on Sales. |
| B1 | claude/v2 | 1 | no | Sales.md | Correctly points to Sales (Status, Value, DateCreated, DateCompleted) and says there is no monthly report or date filter, but omits the Dashboard for pipeline movement and that cancellations carry no date. |
| B1 | claude-haiku-5-5/v1 | 1 | no | Sales.md | Correctly points to the Sales columns and says there is no monthly report or date filter, but it omits the Dashboard for pipeline movement and wrongly assumes the user is on the Sales screen. |
| B1 | claude-haiku-5-5/v2 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales page and its columns and notes there is no date filter or monthly report, but it leaves out the Dashboard's per-status lead counts for reviewing how the pipeline moved. |
| B1 | claude-sonnet-5-5/v1 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and notes there is no date filter or monthly report, but it omits the Dashboard counts for the pipeline and wrongly assumes the user is already on Sales. |
| B1 | claude-sonnet-5-5/v2 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns (Status, Value, DateCreated, DateCompleted) and says the search and Calendar won't filter by month, but it hedges about a monthly report and omits the Dashboard's per-status lead counters, which the manual does describe. |
| B1 | claude-opus-5-5/v1 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales page and its Status, Value, DateCreated and DateCompleted columns, and says there is no date filter or report, but it leaves out the Dashboard lead-per-status counts that show how the pipeline moved. |
| B1 | claude-opus-5-5/v2 | 1 | no | Sales.md Calendar.md | The Sales columns, the lack of a date filter or report, and the cancel-without-date point are all correct, but it skips the Dashboard's leads-per-status tiles for the pipeline view and wrongly assumes the user is on Sales. |
| B2 | claude/v1 | 0 | **yes** | Draft-Proposal.md | The answer claims a 'discount option' in the proposal window, which the manual does not describe, and it gives neither the workaround (lower the prices or add a discount line) nor the warning that a saved proposal cannot be edited. |
| B2 | claude/v2 | 1 | no | Draft-Proposal.md | Correctly says there is no discount field and suggests lowering line item prices, but hedges on editable prices (the manual says they are), omits a discount line, and never warns that a saved proposal cannot be edited. |
| B2 | claude-haiku-5-5/v1 | 1 | no | Draft-Proposal.md | Correctly says there is no discount field, but omits the obvious workaround (lower the line-item prices or add a discount line so the total recomputes) and doesn't warn that a saved proposal can't be edited. |
| B2 | claude-haiku-5-5/v2 | 1 | no | Draft-Proposal.md | Rightly says there is no discount feature and points to the draft, but it does not suggest lowering the item prices or adding a discount line, does not warn that a saved proposal cannot be edited, and wrongly implies the total is typed in. |
| B2 | claude-sonnet-5-5/v1 | 1 | no | Draft-Proposal.md Sales.md | It correctly says there is no discount field, but it misses the obvious workarounds (lower the line prices or add a negative discount line so the total recomputes) and never warns that the discount must go in before saving because a saved proposal cannot be edited. |
| B2 | claude-sonnet-5-5/v2 | 1 | no | Draft-Proposal.md Sales.md | It rightly says there is no discount field and suggests lowering prices or adding a discount line, but it does not say the total recomputes or warn that a saved proposal cannot be edited (the manual says so), so the discount must go in before saving. |
| B2 | claude-opus-5-5/v1 | 1 | no | Draft-Proposal.md Sales.md | It correctly says there is no discount option and that a saved proposal cannot be edited, but it omits the workaround (lower the line item prices or add a discount line before saving, so the total recomputes) and needlessly defers to support. |
| B2 | claude-opus-5-5/v2 | 1 | no | Draft-Proposal.md Sales.md | Rightly says there is no discount option, but never suggests lowering the line-item prices or adding a negative discount line before saving, and misses the FAQ workaround of deleting the saved proposal from Sales and redrafting it. |
| B3 | claude/v1 | 1 | no | Leads.md | The follow-up advice and the drag-to-Closed behaviour are correct, but it misses that Notes can log follow-ups, Date Drafted shows when the proposal went out, Inactive can park the lead, and the Call/Email buttons do nothing. |
| B3 | claude/v2 | 1 | no | Leads.md | The follow-up advice and the use of Date Drafted are sound, but it wrongly says it cannot tell how to park a lead (the Status field in Lead detail offers Inactive), and it misses using Notes to record follow-ups and the fact that the Call/Email buttons do nothing. |
| B3 | claude-haiku-5-5/v1 | 1 | no | Leads.md | The Proposal Sent and Date Drafted details and the labelled general follow-up advice are correct, but the answer wrongly says it cannot confirm how to park a lead, when the manual allows setting the Status to Inactive in the lead detail, and it omits that the Call and Email buttons do nothing and that there are no reminders. |
| B3 | claude-haiku-5-5/v2 | 1 | no | Leads.md | Sound follow-up advice and correctly points to Date Drafted in the Proposal Sent column, but the answer is cut off mid-sentence and never covers Notes, parking the lead as Inactive, the missing reminders or the non-working Call and Email buttons. |
| B3 | claude-sonnet-5-5/v1 | 1 | no | Leads.md Assistant.md | The follow-up advice is sound, and the Date Drafted and drag-to-Closed details are correct, but it leaves out recording follow-ups in Notes, parking the lead as Inactive, the Call/Email buttons doing nothing, and the absence of reminders. |
| B3 | claude-sonnet-5-5/v2 | 1 | no | Leads.md | Sound follow-up advice and correct points on the Proposal Sent column, Date Drafted and Inactive, but it misses the lead's Notes field for logging follow-ups, implies no such place exists, and never says the Call/Email buttons do nothing. |
| B3 | claude-opus-5-5/v1 | 1 | no | Leads.md Assistant.md | The follow-up advice and the Date Drafted and Closed details are correct, but the answer wrongly says the manual doesn't explain how to set Inactive (the Status field in the lead detail does it) and leaves out Notes for logging follow-ups and the do-nothing Call/Email buttons. |
| B3 | claude-opus-5-5/v2 | 1 | no | Leads.md | The follow-up advice is sound and the Date Drafted and Closed details are correct, but it leaves out Notes for logging follow-ups and wrongly says the manual doesn't explain how to set Inactive, which can be picked in the lead detail's Status list. |
| C1 | claude/v1 | 1 | no | Leads.md | It correctly says there are no reminders and points to the Active column's Date Contacted, but wrongly calls that the last contact when it is only stamped the first time a lead reaches Active, and it needlessly hedges about the New column. |
| C1 | claude/v2 | 2 | no | Leads.md | Correctly finds no reminder feature and points to checking Date Contacted in the Active column by hand, though it needlessly hedges on whether a reminder exists elsewhere. |
| C1 | claude-haiku-5-5/v1 | 2 | no | Leads.md | Correctly says there are no reminders and points to the Active column's Date Contacted as the closest manual check, matching the rubric. |
| C1 | claude-haiku-5-5/v2 | 2 | no | Leads.md | Correctly says there are no reminders and points to scanning Date Created and Date Contacted on the Leads board, but Date Contacted records the first contact, not the latest. |
| C1 | claude-sonnet-5-5/v1 | 2 | no | Leads.md | The answer correctly says there are no reminders and points to checking Date Contacted in the Active column by hand, as the rubric asks, though it hedges where it could have been firm. |
| C1 | claude-sonnet-5-5/v2 | 2 | no | Leads.md Dashboard.md | Correctly says there are no reminders and points to the Active column's Date Contacted, as the rubric expects, with general practice clearly labelled. |
| C1 | claude-opus-5-5/v1 | 2 | no | Leads.md | It correctly says there are no reminders and points to the Active column's Date Contacted, with a correct 30-day cutoff date and an accurate note on what Search covers. |
| C1 | claude-opus-5-5/v2 | 2 | no | Leads.md | Correctly says there are no reminders and points to checking Date Contacted in the Active column (and Date Created in New) by hand, with the right 30-day cutoff and labelled general advice, though it hedges with 'may not have' where the manual is definitive. |
| C2 | claude/v1 | 1 | no | Sales.md | Correctly says there is no forecast feature and points to the Sales values and dates, but never explains what a quarterly forecast is or how to build one from that data (e.g. weighting by status), as an expert would. |
| C2 | claude/v2 | 2 | no | Sales.md | It correctly says there is no forecast and uses the Sales values and dates as raw material with general weighting advice, though it could have stated plainly that Sales has no export and searches only by proposal name. |
| C2 | claude-haiku-5-5/v1 | 1 | no | Sales.md | Correctly says there is no forecast and points to the Sales columns, but never explains what a quarterly forecast is or how to build one from those values and dates. |
| C2 | claude-haiku-5-5/v2 | 2 | no | Sales.md | It correctly says there is no forecast or report, points to the Sales columns (Value, Status, DateCreated, DateCompleted) as raw material, and labels the weighting advice as general practice without inventing numbers or features. |
| C2 | claude-sonnet-5-5/v1 | 1 | no | Sales.md | It correctly says there is no forecast and points to the Sales columns as raw material, but it never explains what a quarterly forecast is or how to build one (e.g. weighting open New proposals), and it wrongly limits its own actions to opening screens and creating leads. |
| C2 | claude-sonnet-5-5/v2 | 2 | no | Sales.md | It correctly says there is no forecast feature, points to the Sales values and dates as raw material, and labels the weighted-pipeline explanation as general practice. |
| C2 | claude-opus-5-5/v1 | 2 | no | Sales.md | Correctly says the application has no forecast feature, points to the Value, Status and dates on the Sales page, and gives a quarterly method clearly labelled as general practice, with no made-up figures. |
| C2 | claude-opus-5-5/v2 | 2 | no | Sales.md | Correctly says the app has no quarterly forecast, points to the Sales columns (Status, Value, DateCreated, DateCompleted) as raw data, and labels the weighted-forecast method as general practice. |
| C3 | claude/v1 | 2 | no | Sales.md | It correctly declines payroll as outside the application, and its pointer to the Sales list's Value and Status columns is accurate to the manual and makes no payroll or commission claim. |
| C3 | claude/v2 | 2 | no | Sales.md | Correctly says payroll is not in the application and gives no payroll calculation; the pointer to the Sales list and user filter is accurate, if longer than the brief decline the rubric expects. |
| C3 | claude-haiku-5-5/v1 | 2 | no | Sales.md | Correctly declines payroll as outside the application, and its pointer to the Sales list's Value and User columns matches the manual without claiming any pay calculation. |
| C3 | claude-haiku-5-5/v2 | 2 | no | Sales.md | It declines payroll and says the app computes no pay or commissions; its pointer to the Sales list's Value column matches the manual. |
| C3 | claude-sonnet-5-5/v1 | 2 | no | Sales.md | It correctly declines, says the application has no payroll feature, and points accurately to the Sales screen without explaining payroll. |
| C3 | claude-sonnet-5-5/v2 | 1 | no | Users.md Sales.md | It correctly says the application has no payroll or commission feature, and its Sales screen and user-filter details match the manual, but instead of declining in a sentence or two it outlines how sales pay is computed, which the rubric counts against it. |
| C3 | claude-opus-5-5/v1 | 2 | no | Sales.md Users.md | Correctly says payroll is not in the application and points to the Sales list, described accurately per the manual, without explaining how to compute payroll. |
| C3 | claude-opus-5-5/v2 | 1 | no | Sales.md Users.md | It correctly says the application has no payroll or commission feature, and its Sales-list steps match the manual, but the rubric asks for a brief decline and the answer adds a lengthy commission workaround. |
| D1 | claude/v1 | 1 | no | - | The date of 16 December 2026 is correct, but the answer wrongly says it cannot tell whether the draft can record it, when the manual shows there is no validity field and a line item title (20 characters) could hold it. |
| D1 | claude/v2 | 1 | **yes** | Draft-Proposal.md | The date (16 December 2026) and the absence of a validity field are correct, but the answer suggests writing the validity in the thank-you line, which the manual does not describe as editable, and misses the line-item title workaround. |
| D1 | claude-haiku-5-5/v1 | 2 | no | Draft-Proposal.md | The date 16 December 2026 is correct and the answer rightly says there is no validity field, though it does not say where to write the date (e.g. a line item title). |
| D1 | claude-haiku-5-5/v2 | 2 | no | Draft-Proposal.md | Correct date (16 December 2026) and correctly says the draft has no validity field; it omits the line-item title workaround, but the calendar reminder is labelled as general practice. |
| D1 | claude-sonnet-5-5/v1 | 2 | no | Draft-Proposal.md | The date is correct (16 December 2026) and the answer rightly says the draft has no validity field, though it could have pointed to the 20-character line item title. |
| D1 | claude-sonnet-5-5/v2 | 2 | no | Assistant.md Draft-Proposal.md | The date of Wednesday 16 December 2026 is correct, and the answer rightly says the draft has no validity field, though it does not suggest putting the date in a line item title. |
| D1 | claude-opus-5-5/v1 | 2 | no | Draft-Proposal.md | Gives the correct date (Wednesday 16 December 2026) and rightly says the draft has no validity field, though it does not suggest writing the date in a line item title. |
| D1 | claude-opus-5-5/v2 | 2 | no | Draft-Proposal.md | The date (Wednesday, 16 December 2026) is correct, and it rightly says the draft has no validity field, though it does not mention the 20-character line item title as the only place to write it. |
| D2 | claude/v1 | 2 | no | Assistant.md | It correctly works out about 14:17 Eastern Standard Time in New York and judges it a normal business hour; it leaves out that the lead's Call button does nothing, which is a minor gap. |
| D2 | claude/v2 | 2 | no | - | Correctly works out about 14:18 in New York (6 hours behind UTC+1) and judges it within business hours; it skips that the Call button does nothing, but that is minor. |
| D2 | claude-haiku-5-5/v1 | 2 | no | Assistant.md | Correctly works out about 14:19 on Monday in New York from the current time and judges it within business hours; the claim that the assistant knows the time is in the manual, though it does not mention that the Call button does nothing. |
| D2 | claude-haiku-5-5/v2 | 2 | no | - | It correctly works out about 14:20 in New York from the local time and judges it business hours; it only leaves out that the Call button does nothing. |
| D2 | claude-sonnet-5-5/v1 | 2 | no | Lead-Detail.md | The answer correctly puts New York at about 14:20, six hours behind, judges it against business hours, and rightly says the Call button is a placeholder. |
| D2 | claude-sonnet-5-5/v2 | 2 | no | Lead-Detail.md | It correctly works out about 2:20 pm in New York (UTC-5, 6 hours behind), judges it against business hours as general practice, and rightly says the Call button is only a placeholder. |
| D2 | claude-opus-5-5/v1 | 2 | no | Lead-Detail.md | Correctly works out about 14:22 in New York (EST, UTC−5), says it is fine to call, and rightly notes the Call button is a placeholder, though it is on the Lead detail window rather than 'this screen'. |
| D2 | claude-opus-5-5/v2 | 2 | no | Lead-Detail.md | It correctly gives 14:24 Monday in New York (UTC−5), judges it within business hours and notes, as the manual says, that the Call button is a placeholder. |
| D3 | claude/v1 | 1 | no | Leads.md FAQ.md | Correctly says there is no date filter and that only the New column shows Date Created, but it never names the month (November 2026) and does not say that leads in other columns show Date Created only in their detail window. |
| D3 | claude/v2 | 1 | no | Leads.md | Correctly points to the New column, the user filter, and the lack of a date filter or report, but never names November 2026 and omits that the lead detail window shows Date Created for leads that have moved on. |
| D3 | claude-haiku-5-5/v1 | 1 | no | Leads.md FAQ.md | It correctly says there is no date filter and that only the New column shows Date Created, but it misses the lead detail window (which shows Date Created for any lead) and never says that this month is November 2026. |
| D3 | claude-haiku-5-5/v2 | 1 | no | Accounts.md Leads.md | It correctly names November 2026, the New column's Date Created and the lack of a date filter, but only says 'check it another way' for older leads instead of pointing to the Date Created in the lead detail window. |
| D3 | claude-sonnet-5-5/v1 | 1 | no | Leads.md FAQ.md | It correctly says there is no by-month list and that only the New column shows Date Created, but it never names November 2026, misses the Date Created field in the lead detail, and is unsure about the other columns although the manual says they show their stage date. |
| D3 | claude-sonnet-5-5/v2 | 2 | no | FAQ.md Leads.md | Correctly uses November 2026, says there is no date filter, search or report, and points to the Date Created column in New, though it leaves out that the lead detail window shows Date Created for leads in other columns. |
| D3 | claude-opus-5-5/v1 | 2 | no | Leads.md FAQ.md | Correctly uses November 2026, notes only the New column shows Date Created and that there is no date filter, but it does not mention that the lead detail window shows Date Created for leads that have moved on. |
| D3 | claude-opus-5-5/v2 | 2 | no | Leads.md FAQ.md | Correctly uses November 2026 and explains that only the New column shows Date Created and that there is no date filter or report, though it omits that the lead detail window shows Date Created for leads that have moved on. |

## Answers

### claude/v1

**A1** (3.4 s, useful 1)

> The documentation doesn't say whether the proposal draft handles VAT. The total is the sum of the line items, and there's no documented VAT field or tax rate setting. So I can't tell you how to add VAT in this application.
> 
> As general practice, whether VAT belongs on a B2B proposal depends on your country and your customer. Many businesses show net prices, then VAT, then the gross total, but that's general practice, not something this application defines. Check with your accountant or the rules where you operate.
> 
> The draft's total is the sum of the line items, and it's saved with the proposal as its value ([Draft a proposal](Draft-Proposal.md)). If you need VAT on the document, you'll have to confirm how to handle it outside the application's documented features.

**A2** (2.3 s, useful 1)

> The documentation doesn't explain how to calculate the value of your sales pipeline. It covers counts only: the Dashboard shows how many leads you have in each status, and it doesn't show monetary totals.
> 
> The Dashboard tiles are New Leads, Active Leads, Proposal Sent, Closed, Inactive, and Total. To see the leads behind a number, open Leads. The tiles are refreshed when you return to the Dashboard.
> 
> Source: [Dashboard](Dashboard.md)

**A3** (1.9 s, useful 1)

> The documentation doesn't say how long a lead should stay in Active or when to treat it as lost. It only defines Active as a lead that is being worked on ([Leads](Leads.md)). The board has four columns (New, Active, Proposal Sent, Closed), and nothing in the manual describes a "lost" status or an inactivity rule.

**B1** (2.7 s, useful 1)

> You're already on the right screen. The **Sales** list shows every proposal of the active user, in one list. For a month-end review, look at these columns:
> 
> - **Status**: `New` (saved, not yet decided), `Accepted`, or `Canceled`.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when the proposal was saved, and when it was accepted.
> - **User**: who wrote it.
> 
> The Search box filters only on the proposal name, and every proposal is called "New Proposal", so it won't help you pick out a month or a customer. To check a specific customer's proposal, open the lead and press **View Proposal**. The documentation does not describe filtering or sorting by date, so you'll need to scan the list yourself.
> 
> Also note that the Calendar shows no sales data, so it can't be used for this review.
> 
> Source: [Sales](Sales.md)

**B2** (2.9 s, useful 0, invented)

> The documentation I have doesn't cover discounts. It doesn't say whether the proposal window has a discount field or how to apply a percentage to the total, so I can't give you steps for a 10% discount without guessing.
> 
> What it does cover is creating the proposal: open the lead detail window and press **Create Proposal**, fill in the line items, check the total, and press **Save Proposal**. The total is saved as the proposal's value. You can find the discount option in that window, or ask your team how discounts are normally entered. ([Draft a proposal](Draft-Proposal.md))

**B3** (4.0 s, useful 1)

> A proposal with no answer after two weeks is normal to follow up, and it should still be in the **Proposal Sent** column, which holds proposals waiting for an answer ([Leads](Leads.md)). The manual doesn't describe a follow-up or reminder feature, so I can't tell you how to log one in the app.
> 
> General sales practice (not specific to this application) would be:
> 
> 1. Call or email the contact with a short follow-up that asks whether they had a chance to review the proposal and whether anything needs changing.
> 2. If there's still no reply after a second attempt, ask directly whether they're still interested.
> 3. If they've gone silent, consider moving the lead to **Closed** so your pipeline stays accurate. Drag the row to that column. The close date will be stamped if it's empty.

**C1** (2.7 s, useful 1)

> The documentation I have doesn't cover automatic reminders, so I can't tell you how to set one up. The application's manual doesn't describe a reminder or alert feature.
> 
> The closest thing I can point to is the Leads board, which shows a date for each lead in its column. The **Active** column shows **Date Contacted**, so you can see when each lead in that stage was last reached. The [Leads](Leads.md) page describes this. It doesn't say whether leads in the **New** column have a contact date or how to filter by age, so I can't confirm you could find 30-day-old leads from it.

**C2** (2.9 s, useful 1)

> The documentation doesn't cover sales forecasts, so I can't tell you how to create one in this application.
> 
> The **Sales** screen lists every proposal with its `Value`, `Status`, and `DateCreated` and `DateCompleted` dates, which you could use as source data if you build the forecast yourself. Only Accepted proposals show a completion date, since Complete stamps it. ([Sales](Sales.md))

**C3** (2.7 s, useful 2)

> The documentation doesn't cover payroll, so I can't tell you how to calculate it in this application.
> 
> The closest related material is the Sales list. It shows every proposal of the active user, with a **Value** column (the invoice total as saved) and a **Status** column. You can switch the active user from the drop-down at the right of the title bar. Nothing in the documentation explains how those values feed into a pay calculation.
> 
> [Sales](Sales.md)

**D1** (2.5 s, useful 1)

> The proposal would be valid until **16 December 2026**, counting 30 days from today, Monday 16 November 2026.
> 
> The application documentation I have doesn't cover validity periods or expiry dates for proposals, so I can't tell you whether the draft has a place to record this date.

**D2** (3.5 s, useful 2)

> No, it isn't too late. It's 20:17 for you (UTC+1), which is **14:17 in New York** (Eastern Standard Time, since daylight saving ended on 1 November). That's a normal afternoon for a business call.
> 
> The assistant knows the current date and time, so it can answer questions like this. ([Asking the assistant](Assistant.md))

**D3** (4.1 s, useful 1)

> The documentation doesn't include a way to filter leads by creation month, so I can't pull that list for you directly. Here's what you can do on the Leads screen:
> 
> 1. Open the **New** column. Each lead there shows its **Date Created** and **Name**, so you can see when it was added. Leads in the other columns show different dates for their stage.
> 2. Check the user drop-down in the title bar. Nearly every list is filtered by the active user, so make sure it's set to your user, or leads you created may not appear.
> 
> Source: [Leads](Leads.md)
> Source: [FAQ](FAQ.md)

### claude/v2

**A1** (3.8 s, useful 1)

> **General practice:** In B2B, quotes and proposals are often shown net, with VAT added as a separate line or stated as applicable on top. Whether you must show VAT, and at what rate, depends on your country and the customer's status, so confirm with your accountant.
> 
> **In this application:** The documentation doesn't describe any VAT or tax field on proposals. The total is simply the sum of the line items, so with net prices the proposal total will be net. The documentation doesn't say whether VAT can be shown as its own line, so I can't confirm how to present it here. Source: [Draft a proposal](Draft-Proposal.md)

**A2** (2.2 s, useful 1)

> The documentation doesn't say how to calculate a pipeline value. The Dashboard only counts leads per status (New, Active, Proposal Sent, Closed, Inactive) and shows a Total, with no amounts or currency. Clicking a tile does nothing, and to see the leads behind a number you open Leads. The [Dashboard](Dashboard.md) page covers this.
> 
> As general practice, pipeline value is usually the sum of the expected value of each open deal, often weighted by the chance of winning it. Whether this application can store deal values or compute that sum is not covered in the documentation, so I can't tell you the steps for it here.

**A3** (3.3 s, useful 1)

> The application doesn't define a time limit for Active or a "lost" status, so the manual doesn't say how long a lead should stay there. The four columns are New, Active (being worked on), Proposal Sent, and Closed, which the board describes as "Finished" ([Leads](Leads.md)).
> 
> As general practice, many teams pick an inactivity window, such as no contact for 30 days, and then decide whether to close the lead or follow up. Your team would set that threshold.
> 
> In this application, the closest option is to drag the lead to the Closed column when you decide it's finished. The application doesn't record why it was closed, so you may want to note the reason in the lead's notes.

**B1** (3.1 s, useful 1)

> The **Sales** screen is the place to start. It lists every proposal of the active user, with the columns you need for a review: **Status** (New, Accepted or Canceled), **Value**, **DateCreated** and **DateCompleted** ([Sales](Sales.md)).
> 
> The documentation doesn't describe a monthly report or a date filter, so you'll need to scan the list by hand for the month's accepted and canceled proposals. The Search box filters only on proposal name, and every proposal is called "New Proposal," so it won't help here. The Calendar shows no data, so it isn't useful for this ([Sales](Sales.md)).
> 
> Also keep in mind that Complete and Cancel can be applied again later and nothing is locked, so a proposal's status may have changed after month-end. Check the dates when you review.

**B2** (5.5 s, useful 1)

> The manual doesn't describe a discount field in the proposal window, so I can't confirm one exists.
> 
> What it does describe is that a proposal is an invoice with a header, a list of line items, a total, and a thank-you line. To create one, open the lead, press **Create Proposal** in the lead detail window, fill it in, check it, and press **Save Proposal**. ([Draft a proposal](Draft-Proposal.md))
> 
> As general practice, the usual way to give a 10% discount on an invoice is to lower the line item prices by 10%, so the total reflects the discount. If the window lets you edit the item prices, you can enter the discounted amounts. Check the total before you save, because the saved value is the total as it was when you saved. Afterward, the Value column on the Sales page shows that saved total.

**B3** (4.1 s, useful 1)

> Two weeks without an answer is a normal point to follow up. That's general sales practice, not something specific to this application: send a short, polite follow-up that asks whether the proposal raised any questions, and suggest a next step or a date to decide. If you get no reply after a couple of attempts, it's reasonable to stop chasing and close out the opportunity.
> 
> In this application, the lead should be in the **Proposal Sent** column, which holds leads with a proposal out and waiting for an answer. Its **Date Drafted** field shows when the proposal was drafted, so you can see how long it has been waiting. ([Leads](Leads.md))
> 
> The documentation doesn't describe reminders, activity logging, or a way to set a follow-up date, so I can't tell you how the app handles those. The board only moves leads between columns by drag and drop. The Inactive status has no column, so I can't say from the documentation how to mark a lead as inactive.

**C1** (3.4 s, useful 2)

> The documentation I have doesn't describe any reminder or automatic follow-up feature, so I can't tell you how to set one up. I also can't confirm whether one exists elsewhere in the application.
> 
> The closest thing it does have is the Leads board. The Active column shows each lead's **Date Contacted**, so you can see which leads have gone quiet ([Leads](Leads.md)). You can also use the Search box to find a specific lead quickly.
> 
> As general practice, many teams check their pipeline on a fixed day each week and follow up on any lead whose last contact is older than their chosen threshold, such as 30 days. Doing this by hand from the Date Contacted column is the workaround available here.

**C2** (3.3 s, useful 2)

> The application does not have a sales forecast or a quarterly report. The documentation covers only the Sales list, which shows each proposal's **Value**, **Status** (New, Accepted or Canceled), **DateCreated** and **DateCompleted**. Source: [Sales](Sales.md)
> 
> You could build a rough quarterly view by hand from that list:
> 
> 1. Open the **Sales** screen.
> 2. Group the proposals by quarter using **DateCompleted** for accepted ones and **DateCreated** for open ones.
> 3. Add up the **Value** of accepted proposals per quarter as your booked sales.
> 4. Add up the **Value** of proposals still in New for your open pipeline.
> 
> The documentation does not say whether the list can be sorted, filtered by date or exported, so check that on screen before relying on it.
> 
> As general practice, a forecast usually weights open proposals by your estimated chance of acceptance rather than counting their full value.

**C3** (2.9 s, useful 2)

> The documentation doesn't cover payroll, so I can't tell you how to calculate it in this application.
> 
> The closest thing it offers is the **Sales** screen, which lists every proposal of the active user with its Value and Status (New, Accepted or Canceled). You could use it to see which proposals a sales representative has accepted. The application doesn't calculate pay from them. Pick the representative in the user drop-down in the title bar to filter the list. See [Sales](Sales.md).
> 
> As general practice, sales commissions are often based on accepted deal value, but the rates and the payroll calculation itself would be handled outside this application.

**D1** (3.3 s, useful 1, invented)

> The proposal is valid until **16 December 2026**, counting 30 days from today, Monday 16 November 2026. This is simple date arithmetic, not a feature of the application.
> 
> The application doesn't seem to support a validity period. The [Draft a proposal](Draft-Proposal.md) page describes only the company name, today's date, the address, city and phone boxes, the line items, the total and the thank-you line. Nothing there sets or shows an expiry date. You could state the validity date in the proposal's thank-you line or in the lead's notes, if your team uses them that way.

**D2** (3.4 s, useful 2)

> It's not too late. It's about **2:18 PM on Monday, 16 November in New York** (New York is 6 hours behind your time, UTC+01:00, so it's 14:18 there). That's within normal business hours.
> 
> As general practice, check the customer's local time before calling, since they may be in a different time zone. Mid-morning to late afternoon on their side is usually the safest window.

**D3** (3.9 s, useful 1)

> The **New** column on the Leads board shows each lead's Date Created and Name, so you can scan it for this month's dates. Leads are filtered by the active user in the title bar, so make sure the drop-down shows your user first. [Leads](Leads.md)
> 
> The documentation doesn't describe a date filter or a report of leads by creation date, so I can't list them automatically. Also, leads that have moved to Active, Proposal Sent or Closed show other dates in their columns, so this view only works for leads still in New.

### claude-haiku-5-5/v1

**A1** (3.4 s, useful 1)

> The application's documentation doesn't cover VAT or tax on proposals. There's no tax field or VAT setting described. What it does say is that the proposal total is the sum of the line items, so with net prices the total will be net, and the document has no separate VAT line ([Draft a proposal](Draft-Proposal.md)).
> 
> As general practice (not something this application defines), VAT is usually added on the final invoice rather than on a quote. Whether it belongs on your proposal depends on your country and your customer, so check with your accountant.

**A2** (2.5 s, useful 1)

> The documentation doesn't explain how to calculate the value of your sales pipeline. It doesn't mention monetary amounts or any pipeline total.
> 
> What it does cover is the Dashboard, which counts your leads by status: New Leads, Active Leads, Proposal Sent, Closed, Inactive, and Total. Each tile is a count, not a value. To see the leads behind a number, open Leads. The Dashboard counters refresh when you return to it, not while you work elsewhere. For more, see [Dashboard](Dashboard.md).

**A3** (1.9 s, useful 1)

> The documentation doesn't say how long a lead should stay in Active or when to treat it as lost, so I can't give you a time limit.
> 
> What it does say is that **Active** means the lead is being worked on, and that a lead moves to **Closed** (Finished) when you decide it's done. To do that, drag the lead to the Closed column on the board. Moving a lead is always your decision; the application doesn't change it automatically. ([Leads](Leads.md))

**B1** (2.6 s, useful 1)

> You're already on the **Sales** screen, which lists every proposal of the active user in one list. For the review, look at these columns:
> 
> - **Status**: New, Accepted or Canceled.
> - **Value**: the invoice total as it was when saved.
> - **DateCreated** and **DateCompleted**: when each proposal was saved and when it was accepted.
> 
> Use the **Complete** and **Cancel** buttons in the banner only to change a proposal's status. Those buttons don't require confirmation, so check the selected row first.
> 
> The documentation doesn't describe a month-end report, a date-range filter, or a way to total values. The Search box only filters by proposal name, and every proposal is named "New Proposal," so it won't help you narrow by month. The Calendar shows no sales data.
> 
> Source: [Sales](Sales.md)

**B2** (3.3 s, useful 1)

> The documentation doesn't cover applying a discount to a proposal. It doesn't mention a discount field or any discount option in the proposal window.
> 
> What it does cover is the general flow. A proposal is an invoice with line items and a total, opened from **Create Proposal** in the lead detail window. You fill it in, look at it, and click **Save Proposal**. (See [Draft a proposal](Draft-Proposal.md).)
> 
> If the draft window doesn't show a way to enter a discount, I can't tell you how to add one from the manual. Your administrator or the application's support team would be the right people to ask.

**B3** (6.1 s, useful 1)

> A proposal that gets no answer usually stays in the **Proposal Sent** column, which means "a proposal is out, waiting for an answer." The board shows the Date Drafted for each lead there, so you can see how long it has been waiting ([Leads](Leads.md)).
> 
> The manual doesn't cover how to follow up, so these steps are general sales practice:
> 
> 1. Open the lead in the **Proposal Sent** column and check the proposal's date and your notes.
> 2. Send a short follow-up by e-mail or phone, asking whether they had a chance to review it and whether they have questions.
> 3. If you have no reply after another attempt or two, decide whether to keep the lead open or stop pursuing it.
> 
> Moving a lead on the board is done by drag and drop. Dropping it on another column changes its status and stamps that column's date if it is still empty ([Leads](Leads.md)). The manual doesn't describe a "lost" status, and the Inactive status has no column on the board, so I can't confirm from the documentation how to mark a lead as dead.

**C1** (1.7 s, useful 2)

> The documentation doesn't cover automatic reminders, so I can't tell you how to set one up. The application doesn't describe any reminder or scheduling feature in the pages I have.
> 
> The closest thing is to check the leads by hand on the Leads board. The **Active** column shows each lead's Date Contacted, so you can see which leads have gone quiet ([Leads](Leads.md)).

**C2** (3.1 s, useful 1)

> The documentation doesn't describe a forecast or any quarterly report, so I can't tell you how to produce one in the application.
> 
> The Sales screen does list every proposal with its **Value**, **Status** (New, Accepted or Canceled), **DateCreated** and **DateCompleted**. Those columns may help if you build a forecast yourself. Note that the Value is the invoice total as it was when the proposal was saved.
> 
> Source: [Sales](Sales.md)

**C3** (2.0 s, useful 2)

> The documentation doesn't cover payroll calculation, so I can't tell you how to do it in this application.
> 
> The closest related feature is the **Sales** screen, which lists every proposal of the active user, with a **Value** column and a **User** column. You could use it to review a representative's proposals, but it doesn't calculate pay.
> 
> Source: [Sales](Sales.md)

**D1** (4.2 s, useful 2)

> A proposal dated today, Monday 16 November 2026, is valid for 30 days until **16 December 2026**.
> 
> The manual doesn't describe any validity or expiry field for proposals. The draft only holds the customer's address, the line items, the total and a thank-you line, as described in [Draft a proposal](Draft-Proposal.md). So the date is not stored in the application, and you'd need to state it on the document yourself.

**D2** (2.7 s, useful 2)

> It's not too late. It's currently 20:19 in your time zone (UTC+01:00), which is about **14:19 on Monday in New York**, so business hours there are still underway. This comes from the current time, not from the application's documentation. I can't see the customer's own office hours, so check those if you have them. The assistant can answer questions like this because it knows the current date and time, as described in the [Asking the assistant](Assistant.md) page.

**D3** (3.4 s, useful 1)

> The documentation doesn't say how to filter leads by creation month or by who created them, so I can't give you a list from it. Here's what the docs do cover:
> 
> - The **Leads** board has four columns. The **New** column shows each lead's **Date Created** and **Name**. Leads that have moved on show a different date for their stage, so a lead's creation date is visible only while it's still in New. ([Leads](Leads.md))
> - Most lists are filtered by the **user drop-down in the title bar**. If the leads you expect are missing, check that it's set to your user. ([FAQ](FAQ.md))

### claude-haiku-5-5/v2

**A1** (3.9 s, useful 1)

> The documentation doesn't cover VAT. A proposal has a header, line items, and a total, and the total is the sum of the line items. There is no VAT field or tax rate described, so the application won't add VAT for you. The saved total will be the net sum of your line items. ([Draft a proposal](Draft-Proposal.md))
> 
> As general practice, whether to show VAT on a proposal depends on your country and your customer. Many businesses show the net prices, then the VAT rate and amount, then the gross total. Your accountant can confirm what applies to you.

**A2** (3.1 s, useful 1)

> The Dashboard doesn't show a pipeline value. Its tiles count leads by status (New, Active, Proposal Sent, Closed, Inactive) and show a Total, so they don't add up any money. The documentation doesn't describe a value or amount field on leads, so I can't tell you how this application would total one.
> 
> The closest thing it offers is the lead count per stage. Open the [Dashboard](Dashboard.md) to see how many leads are in each status, then open Leads to see the leads behind each number. Leads in "Proposal Sent" are the ones waiting for an answer.
> 
> As general practice, pipeline value is the sum of the expected value of each open opportunity, often weighted by the probability of winning it at its current stage. This is standard sales practice, not a feature of this application.

**A3** (3.1 s, useful 1)

> The documentation doesn't say how long a lead should stay in Active, and it doesn't define a "lost" status. The board has four columns: New, Active, Proposal Sent and Closed ("Finished"). Active means the lead is being worked on, and Closed is where finished leads go ([Leads](Leads.md)).
> 
> As general sales practice, teams often set a fixed inactivity window, such as a few weeks without contact, after which a lead is reviewed and either re-engaged or closed. The application doesn't apply any such rule automatically, so you would need to set and track that threshold yourself.
> 
> The closest thing the application offers is to drag the lead to the Closed column when you decide it's finished. Note that the excerpts don't say whether Closed records a reason such as "lost."

**B1** (3.6 s, useful 1)

> The **Sales** screen is the place to start. It lists every proposal of the active user, with the Status, Value, DateCreated, and DateCompleted columns you need for a month-end review ([Sales](Sales.md)).
> 
> Things to keep in mind:
> - **Date filtering:** The documentation doesn't describe a way to filter the list by month. The Search box only filters on proposal name, and since every proposal is called "New Proposal," it won't help. Check the DateCreated and DateCompleted columns yourself.
> - **Changing statuses:** Complete and Cancel can be applied again later, and nothing is locked once a proposal is accepted. Proposals you review may still change after you look at them.
> - **Calendar:** The Calendar shows no sales data, so it won't help with this review ([Calendar](Calendar.md)).
> - **Totals and reports:** The documentation doesn't describe a month-end summary or sales report. You'll need to add up the Value figures yourself.
> 
> As general practice, you could count accepted proposals by DateCompleted for the month and review open or canceled ones by DateCreated.

**B2** (4.3 s, useful 1)

> The documentation doesn't describe a discount feature for proposals, so I can't tell you how the application applies a 10% discount.
> 
> The closest thing it does have is the proposal draft. You open it from **Create Proposal** in the lead detail window, fill in the line items and total, then press **Save Proposal**. The total you see when you save becomes the proposal's value ([Draft a proposal](Draft-Proposal.md)). Whether the discount should be a separate line or a lower price on the items is not covered, so check the draft window itself.
> 
> Some things to keep in mind:
> - A lead can have only one proposal, so check whether the lead already has one before creating another.
> - Saving doesn't move the lead to Proposal Sent. Do that yourself when you send the proposal.

**B3** (6.2 s, useful 1)

> Two weeks without an answer is a good point to follow up. This is general sales practice, not something specific to the application: send a short, specific message or call, ask directly whether they have a decision or an open question, and propose a concrete next step or date. If you still get no reply after a couple more attempts, either close the opportunity or park it for later.
> 
> In this application, the lead should be in the **Proposal Sent** column, which means "a proposal is out, waiting for an answer." Its **Date Drafted** shows when the proposal went out, so you can see the two-week gap on the board ([Leads](Leads.md)).
> 
> Depending on the reply, you can drag the lead to another column:
> - **Active**, if they re-eng

**C1** (3.1 s, useful 2)

> The documentation doesn't describe automatic reminders or any alerts for leads that haven't been contacted, so I can't show you how to set one up in this application.
> 
> The closest thing it offers is the Leads board. Each column shows the date that matters at that stage: the New column shows Date Created, and the Active column shows Date Contacted. You can scan those dates by eye to spot leads that have gone quiet. The Search box can then help you find a specific lead by name, account, phone or e-mail. ([Leads](Leads.md))
> 
> As general practice, you could check the Active column each week and follow up any lead whose Date Contacted is more than 30 days old. Some teams also keep a recurring calendar reminder for this review, though that would be outside this application.

**C2** (3.7 s, useful 2)

> The application doesn't have a sales forecast or a quarterly report. Its documentation covers only the proposal list, so I can't show you how to produce one here.
> 
> The closest thing is the **Sales** screen, which lists your proposals with:
> - **Value**: the total of each proposal as it was saved.
> - **Status**: New, Accepted or Canceled.
> - **DateCreated** and **DateCompleted**: when each proposal was saved and, for accepted ones, when it was accepted.
> 
> You could read the accepted proposals' values by completion quarter and add them up yourself. The search box won't help with this, since it filters on proposal name only ([Sales](Sales.md)).
> 
> As general practice, a quarterly forecast usually weights the open proposals (status New) by their likelihood of acceptance and groups them by expected closing quarter. The application doesn't store a expected close date or probability, so you would need to track those separately.

**C3** (2.6 s, useful 2)

> The application's documentation doesn't cover payroll, and I can't calculate it.
> 
> The closest thing it offers is the [Sales](Sales.md) list, which shows every proposal written by the active user, with the total of each one in the **Value** column. You could use those figures as input for a calculation made outside the application. The app does not compute pay, commissions or totals per user.

**D1** (4.1 s, useful 2)

> The proposal is valid until **16 December 2026**. That is 30 days after today, Monday 16 November 2026.
> 
> The application has no validity or expiry date for proposals. The draft holds the customer's address, phone, line items, total and a thank-you line ([Draft a proposal](Draft-Proposal.md)), so it does not track the expiry. Put the date in your follow-up, for example as a reminder in your own calendar. This is general practice, not a feature of this application.
> 
> Source: [Draft a proposal](Draft-Proposal.md)

**D2** (2.9 s, useful 2)

> It's not too late. Based on the current time in your zone (Monday, 16 November 2026, 20:20, UTC+01:00), it is about **14:20 in New York** (EST, UTC-5). That's a normal business hour. This assumes your clock is set to UTC+01:00.
> 
> The application's documentation doesn't cover time zones or customers' local hours, so I can't say whether it stores or displays them.

**D3** (11.5 s, useful 1)

> The documentation doesn't describe a way to filter leads by creation date or by month, so I can't give you a list directly. Here is what the application does show:
> 
> 1. Open the **Leads** screen and check that the user in the title bar is the one who created the leads. Leads are filtered by the active user, so other users' leads won't appear. ([Accounts](Accounts.md) notes that, unlike leads, accounts are shared by everyone.)
> 2. Look at the **New** column. It shows each lead's Date Created and Name, so you can read off the leads created in November 2026.
> 
> The other columns show different dates. Active shows Date Contacted, Proposal Sent shows Date Drafted, and Closed shows Date Closed. A lead that has moved past New no longer shows its creation date, so you may need to check it another way.
> 
> Source: [Leads](Leads.md)

### claude-sonnet-5-5/v1

**A1** (4.5 s, useful 2)

> The documentation doesn't mention VAT or any tax setting in the proposal. The **Total** is just the sum of the line items (quantity × price), so the application won't add VAT for you. [Draft a proposal](Draft-Proposal.md)
> 
> This part is general practice, not something specific to this application:
> - In B2B sales it's common to quote net prices and state that VAT will be added on the invoice. Whether you must show VAT on the proposal depends on your country and your customer, so check with your accountant if you're unsure.
> - If you want VAT to appear in the total, you could add it yourself as an extra line item, for example a "VAT" row with the amount calculated by hand. The manual doesn't describe this, but the line items are free-form (title, quantity, price) and the total includes every row.

**A2** (3.2 s, useful 1)

> The documentation doesn't describe a way to calculate the value of your sales pipeline, so I can't give you steps for it.
> 
> The only pipeline figures it covers are on the Dashboard. These are lead counts per status (New, Active, Proposal Sent, Closed, Inactive, and Total), not monetary amounts. See [Dashboard](Dashboard.md).
> 
> To see the leads behind a count, open the Leads screen. I can't say whether the Sales screen has anything useful for this, because the excerpts I have don't describe it.

**A3** (1.5 s, useful 1)

> The documentation doesn't say how long a lead should stay in Active before you consider it lost. It describes Active only as "Being worked on" and doesn't set any time limit or rule for marking a lead as lost. The board has just four columns: New, Active, Proposal Sent and Closed. See [Leads](Leads.md).
> 
> The decision about when to give up on a lead is yours to make. If you want to move one, drag it to another column on the board.

**B1** (7.9 s, useful 1)

> You're already on the right screen. The **Sales** screen lists every proposal of the active user in one list. For a month-end review, these columns are the useful ones:
> 
> - **Status**: New, Accepted or Canceled.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when each proposal was saved and when it was accepted.
> 
> The documentation doesn't describe any date filter or monthly summary. You'll have to read the dates in the list yourself.
> 
> - **Search:** The box filters on the proposal name only. Every proposal is called "New Proposal", so it won't help you narrow things down.
> - **Customer:** To see which customer a proposal belongs to, open the lead from the Leads board and press **View Proposal**.
> - **Complete and Cancel:** These buttons change the selected proposal's status straight away, with no confirmation. Use them with care during a review.
> - **Calendar:** The Calendar screen shows no lead or proposal dates, so it won't help here.
> 
> Sources: [Sales](Sales.md), [Calendar](Calendar.md)

**B2** (3.1 s, useful 1)

> The documentation I have doesn't say how to apply a discount, such as 10%, to a proposal. I don't want to guess at a field or option that may not exist.
> 
> The documentation says a proposal is an invoice with a header, a list of line items, a total and a thank-you line. You fill it in, look at it and save it with **Save Proposal**. It doesn't mention a discount field or any percentage calculation. See [Draft a proposal](Draft-Proposal.md).
> 
> Saved proposals show the total as it was when you saved it. See [Sales](Sales.md).

**B3** (7.6 s, useful 1)

> Waiting two weeks without a reply is common, and the usual next step is to follow up. This is general sales practice, not something the manual describes.
> 
> 1. **Follow up now.** Send a short, friendly e-mail that mentions the proposal. Ask one easy question, such as whether they've had a chance to review it or whether anything is unclear.
> 2. **Try another channel.** If e-mail gets no answer, call the office phone.
> 3. **Make replying easy.** Offer a quick call or to adjust the scope or price. Suggest a next step with a date.
> 4. **Don't keep chasing.** After two or three attempts over a couple of weeks, send a polite closing message saying you'll assume the timing isn't right. Then move on.
> 
> In the application, the lead should be in the **Proposal Sent** column of the Leads board. That column shows **Date Drafted**, so you can see how long the proposal has been out. If the lead replies and the deal ends, drag its row to **Closed**. The Closed date is stamped automatically if it's empty ([Leads](Leads.md)).
> 
> The assistant can also explain this kind of sales practice ([Asking the assistant](Assistant.md)).

**C1** (3.5 s, useful 2)

> The documentation doesn't describe any automatic reminder, so I can't tell you how to set one up. I don't want to guess at a feature that may not exist.
> 
> The closest option I can see is to check by hand. On the [Leads](Leads.md) board, the **Active** column shows **Date Contacted** for each lead. You can scan that column for leads you haven't contacted in about 30 days. The **Search** box filters all four columns by name, account, office phone or e-mail, so it can help you find a specific lead.

**C2** (2.9 s, useful 1)

> I can't make a quarterly sales forecast, and the documentation doesn't describe a forecast or report feature. I also have no tool for building one. My only actions are opening screens and creating leads.
> 
> What the **Sales** screen does show is a list of your proposals. Its columns include Status (New, Accepted or Canceled), Value, DateCreated and DateCompleted. You could read the figures there and group them by quarter yourself. The documentation doesn't mention any grouping, totals or export on that screen ([Sales](Sales.md)).

**C3** (2.5 s, useful 2)

> The documentation I have doesn't cover payroll or commission calculations, so I can't tell you how to do that here. As far as the excerpts show, the application has no payroll feature.
> 
> The nearest thing I can point to is the **Sales** screen. It lists each proposal of the active user with its status (New, Accepted or Canceled), its **Value** and its completion date. I can't say whether that is useful for your purpose, because the documentation doesn't link it to payroll.
> 
> Source: [Sales](Sales.md)

**D1** (3.2 s, useful 2)

> Counting 30 days from today, Monday 16 November 2026, the proposal is valid until **Wednesday, 16 December 2026**.
> 
> The draft window's documented fields are the customer's address, the line items, the total and the thank-you line. None of them is a validity date, so you would have to type the date yourself where it fits. See [Draft a proposal](Draft-Proposal.md).

**D2** (3.9 s, useful 2)

> No, it's not too late. It's 20:20 for you, which is about **14:20 in New York** (6 hours behind you). Standard business hours there run until roughly 17:00, so you have about two and a half hours left. This is general practice, not something the application tracks.
> 
> If you're on a lead's detail window, the **Call** button beside the phone number is a placeholder and does nothing, so you'll need to dial the number yourself ([Lead detail](Lead-Detail.md)).

**D3** (3.1 s, useful 1)

> The documentation doesn't describe a way to list leads by the month they were created, so I can't give you that list directly.
> 
> Here is what it does say:
> - The **New** column on the Leads board shows each lead's **Date Created**. You can read the dates there, but only for leads still in New. The excerpt doesn't say whether the other columns show a creation date. ([Leads](Leads.md))
> - Nearly every list is filtered by the user drop-down in the title bar, so you only see the active user's leads. ([FAQ](FAQ.md))

### claude-sonnet-5-5/v2

**A1** (9.2 s, useful 2)

> **In general (standard B2B practice, not specific to this application):** quote net prices and show VAT separately, so the customer sees net, VAT and gross. The proposal here is an invoice. If you're VAT-registered, the VAT rate and amount normally have to appear on it. The rate and rules depend on your country and on the customer, so check with your accountant.
> 
> **In this application:** the proposal has no VAT or tax field. Its **Total** is only the sum of the line items (quantity × price). Nothing adds VAT for you ([Draft a proposal](Draft-Proposal.md)).
> 
> As a workaround, you can add VAT as a line item of its own:
> 
> 1. In the proposal draft, add your net line items as usual.
> 2. Use **+** to add an empty row, then enter a title such as "VAT 22%". Use quantity 1 and the VAT amount as the price. You have to calculate that amount yourself.
> 3. Press **✓** to confirm the row. The total then includes VAT.
> 
> Keep in mind that the saved **Value** on the Sales page is this total, so it will be gross. If you'd rather report net values, leave VAT out of the proposal and add it when you issue the formal invoice.

**A2** (4.0 s, useful 1)

> This application has no pipeline value calculation that I can find in the documentation. The Dashboard only **counts** leads per status (New, Active, Proposal Sent, Closed, Inactive, Total). It shows no amounts. See [Dashboard](Dashboard.md).
> 
> **General practice, not a feature of this application:**
> 1. **Total pipeline:** add up the expected value of every open opportunity. Leave out closed and parked ones.
> 2. **Weighted pipeline:** multiply each opportunity's value by the probability of winning at its stage, then add the results. For example, 10,000 × 50% = 5,000.
> 3. Use probabilities based on your own past win rates per stage, such as New, Active and Proposal Sent.
> 
> The closest thing in the application is the Dashboard counts. You could multiply them by an average deal size and your stage win rates for a rough estimate. I can't say whether the Sales screen offers any totals, because the excerpts I have don't describe it.

**A3** (5.8 s, useful 2)

> This application has no time limit for the Active column. Nothing in the documentation moves a lead out of Active automatically or flags it as lost. You make that call yourself.
> 
> - **How it works here:** Active means "being worked on". You close a lead by dragging it to the **Closed** column, which stamps its Date Closed ([Leads](Leads.md)). The board has no separate "Lost" status. Closed is the only finished state, and the documentation doesn't describe a field for a loss reason.
> - **Tracking staleness:** The Active column shows **Date Contacted**, so you can scan it for leads that haven't been touched in a while ([Leads](Leads.md)).
> 
> **General practice, not specific to this application:**
> - Base the cutoff on your normal sales cycle. A common rule is to consider a lead lost after about 1.5 to 2 times your average cycle length with no real engagement.
> - For short-cycle B2B sales, a typical rule is 3 to 5 follow-up attempts over 2 to 4 weeks, spread across channels. If there's still no response, send a "closing the loop" message and then close the lead.
> - For longer enterprise cycles, allow 60 to 90 days without a meaningful reply before closing.
> - Record why you closed it, for example in the lead's notes, so your reporting stays useful.

**B1** (5.2 s, useful 1)

> The **Sales** screen, where you are now, is the best place to start. It lists every proposal of the active user. For a month-end review, these columns matter most:
> 
> - **Status**: New, Accepted or Canceled.
> - **Value**: the invoice total as it was when you saved it.
> - **DateCreated** and **DateCompleted**: when the proposal was saved and when it was accepted. Use these to decide which proposals belong to the month.
> 
> From there you can review the proposals and use **Complete** or **Cancel** on any that are still open. Neither button asks for confirmation. ([Sales](Sales.md))
> 
> - **Search:** the Search box only filters on proposal name. Every proposal is called "New Proposal", so it won't narrow the list to a month. To find a particular customer's proposal, open the lead and press **View Proposal**. ([Sales](Sales.md))
> - **Calendar:** the Calendar screen won't help. It shows no lead or proposal dates. ([Calendar](Calendar.md))
> - **Monthly totals:** the excerpts I have don't describe a monthly report, a date filter or totals on the Sales screen. I can't say whether the Dashboard offers any of this.
> 
> As general practice, not a feature of this application: a month-end review usually compares proposals accepted in the month with those still open, and flags open ones that need follow-up.

**B2** (5.2 s, useful 1)

> The documentation I have doesn't describe a discount field or a percentage option in the proposal window, so I can't tell you a built-in way to apply 10%.
> 
> **What the documentation does say**
> - The proposal is an invoice with a header, a list of line items, a total and a thank-you line. You open it from **Create Proposal** in the lead detail window. See [Draft a proposal](Draft-Proposal.md).
> - **Save Proposal** stores the total as the proposal's value. The Sales list shows that value "as it was when you saved it". See [Sales](Sales.md).
> - A lead can have only one proposal. The excerpt I have doesn't explain how to edit or replace a saved one, so I can't say how to change it after saving.
> 
> **General practice (not a feature of this application)**
> - Show the discount openly, either as its own line or by lowering the unit prices. Customers then see what they are getting, and your records show the concession.
> - Before agreeing to 10%, ask for something in return, such as a larger volume, a longer contract or faster payment.
> 
> If you're drafting the proposal now, you could reduce the line item amounts so the total reflects 10% off. I can't confirm from the documentation that the window handles a discount line or a negative amount.

**B3** (5.4 s, useful 1)

> After two weeks of silence, follow up now. This is general sales practice, not something specific to this application.
> 
> 1. **Send a short follow-up.** Call or email. Ask if they received the proposal and whether they have questions. Don't just ask whether they've decided.
> 2. **Find the blocker.** Common causes are price, a missing decision-maker, shifting priorities, or the proposal getting lost in their inbox. Offer a short call to walk through it.
> 3. **Set a deadline.** Suggest a next step with a date, for example "Can we talk Thursday?"
> 4. **Try again if needed.** If there is still no answer, try a second channel or another contact at the company. After two or three attempts spread over a couple of weeks, send a polite closing message. Then stop chasing and decide whether the lead is still worth your time.
> 
> **In this application:** a lead with a proposal out sits in the **Proposal Sent** column of the Leads board, which shows the Date Drafted and the account name. Use that date to spot proposals that have waited too long. The manual says leads move between columns by drag and drop, and that an **Inactive** status exists but has no column on the board. The excerpts I have don't describe a follow-up reminder or a way to log follow-up attempts, so I can't point you to one. See [Leads](Leads.md).

**C1** (4.1 s, useful 2)

> The documentation doesn't describe an automatic reminder, for 30 days without contact or for any other period. I can't tell you how to set one up, and I won't guess at a setting that may not exist.
> 
> The closest option is to check by hand:
> 
> 1. Open **Leads**.
> 2. Look at the **Active** column. It shows **Date Contacted**, so you can see which leads you haven't touched for a while.
> 3. Use the **Search** box to narrow the board to a specific person, account, phone or e-mail.
> 
> The **Dashboard** only counts leads per status, so it can't show how long a lead has gone without contact. ([Leads](Leads.md), [Dashboard](Dashboard.md))
> 
> As general practice, not a feature of this application, many teams review their Active leads on a fixed day each week. That way nothing goes 30 days without a follow-up.

**C2** (3.9 s, useful 2)

> This application has no sales forecast, and the documentation doesn't describe any quarterly report or grouping. I can't produce one for you.
> 
> The closest thing is the **Sales** screen. It lists every proposal with its **Status** (New, Accepted or Canceled), **Value**, **DateCreated** and **DateCompleted**. You can read it as a rough basis for a manual forecast ([Sales](Sales.md)):
> 
> - **Accepted proposals:** group them by the quarter of **DateCompleted**. This gives you actual closed sales.
> - **New proposals:** these are your open pipeline. Their **Value** is the amount at stake.
> 
> The excerpts don't mention an expected close date or a win probability, so the application can't assign open proposals to a future quarter.
> 
> **General practice, not a feature of this application:** a forecast is usually the closed revenue for the quarter plus the open proposals weighted by their likelihood of closing. You would apply that weighting yourself, for example in a spreadsheet.

**C3** (4.3 s, useful 1)

> This application has no payroll or commission feature, and the documentation doesn't cover calculating pay. I can't tell you how to do it here.
> 
> The closest thing it has is the **Sales** screen. It lists each proposal of the active user with its **Value**, **Status** (New, Accepted or Canceled) and **DateCompleted**. You can use it as a source of figures for a calculation you do elsewhere. To see one representative's proposals, pick that person in the user drop-down in the title bar. The drop-down filters the lists by user ([Users](Users.md)). Then read the Accepted proposals and their completion dates ([Sales](Sales.md)).
> 
> As general practice, not something this application does, sales pay is usually the base salary plus a commission. The commission is a percentage of the value of the deals closed in the period, and some companies add bonuses for reaching a quota. The payroll itself is normally done in accounting or HR software.

**D1** (4.3 s, useful 2)

> Thirty days from today (Monday, 16 November 2026) is **Wednesday, 16 December 2026**.
> 
> The documentation I have doesn't describe a validity or expiry field in the proposal draft. The draft only shows the company name, today's date, your address and phone boxes, the line items and the total. Counting from today is general practice. The application won't track or enforce the date. The assistant knowing today's date is described in [Asking the assistant](Assistant.md), and the fields of the draft are in [Draft a proposal](Draft-Proposal.md).

**D2** (4.1 s, useful 2)

> No, it isn't too late. It's about **2:20 pm on Monday** in New York. New York is 6 hours behind you right now, because the US has already switched to winter time.
> 
> This is general practice, not something the application does. Standard business hours run 9:00 to 17:00, so you have about 2½ hours left. Mid-afternoon is usually a good time to reach someone. After 17:00 New York time (23:00 for you), wait until tomorrow.
> 
> The **Call** button next to the phone number in the lead detail is only a placeholder and doesn't dial. You'll need to place the call with your own phone ([Lead detail](Lead-Detail.md)).

**D3** (4.0 s, useful 2)

> The documentation doesn't describe a filter, search or report that lists leads by the month they were created, so I can't give you that list directly.
> 
> The closest option is the **Leads** board. Its **New** column shows the **Date Created** for each lead, so you can scan that column for dates in November 2026. Once a lead moves to another column, that column shows a different date instead. Active shows Date Contacted, Proposal Sent shows Date Drafted, and Closed shows Date Closed. So this only works for leads still in New.
> 
> Also, the board only shows leads for the user selected in the title bar's drop-down, as described in the [FAQ](FAQ.md). Check it is set to the user who owns your leads.
> 
> Source: [Leads](Leads.md)

### claude-opus-5-5/v1

**A1** (7.5 s, useful 2)

> As a general business practice, **yes**: a proposal should make VAT clear. This isn't a rule of the application, though, and whether VAT applies depends on your country and your customer's.
> 
> - In B2B, it's common to quote **net prices** and show VAT **separately** (net, then VAT, then gross). At the very least, state that prices are "excl. VAT".
> - Some sales have no VAT or use a reverse charge, for example some cross-border B2B sales in the EU. Check with your accountant.
> 
> **In this application**, the proposal's **Total** is just the sum of your line items. The documentation doesn't mention a VAT field or VAT calculation. So if you want VAT on the proposal, you'd have to add it as a line item yourself ([Draft a proposal](Draft-Proposal.md)):
> 
> 1. Press **+** under the line items grid.
> 2. Enter a title like `VAT 22%`, quantity `1`, and the VAT amount you calculated as the price.
> 3. Press **✓**. The Total will then include VAT.
> 
> Keep in mind that the saved Total becomes the proposal's **Value** on the Sales page ([Sales](Sales.md)). If you add VAT, your sales figures will include tax. If you'd rather track net values, leave the VAT line out.
> 
> I can answer general questions like this one about VAT ([Asking the assistant](Assistant.md)).

**A2** (4.8 s, useful 1)

> The documentation doesn't describe any feature that calculates a pipeline value. The [Dashboard](Dashboard.md) only **counts** the active user's leads by status (New, Active, Proposal Sent, Closed, Inactive, Total). It doesn't show any amounts. Clicking a tile does nothing, so to see the leads behind a number, open **Leads**.
> 
> **General practice (not from this manual):** a common way to estimate a pipeline's value is a **weighted pipeline**:
> 
> 1. For each open lead, take the expected deal value.
> 2. Multiply it by the chance of winning at its stage. For example, New 10%, Active 30%, Proposal Sent 60%. Choose percentages that match your own past results.
> 3. Add up the results. Leave out Closed and Inactive leads, because they aren't in play.
> 
> You'd need to do this calculation yourself, using the deal values from your leads or proposals.

**A3** (3.3 s, useful 1)

> The documentation doesn't say how long a lead should stay in **Active**, and it doesn't set any time limit. The application has no "lost" status either. The four columns are **New**, **Active**, **Proposal Sent** and **Closed**, where Closed simply means "Finished."
> 
> When you decide a lead is done, you move it yourself by dragging it to the **Closed** column. Its **Date Closed** is filled in at that point. If you move the lead back and forth later, a date that already has a value isn't overwritten. ([Leads](Leads.md))
> 
> The **Active** column shows **Date Contacted**, so you can use it to see how long each lead has been there. The time limit is up to you or your team.

**B1** (4.9 s, useful 1)

> You're already in the right place: the **Sales** screen lists every proposal of the active user in one list. For a month-end review, the most useful columns are:
> 
> - **Status**: `New` when the proposal was saved, then `Accepted` or `Canceled`.
> - **Value**: the invoice total as it was when the proposal was saved.
> - **DateCreated** / **DateCompleted**: when the proposal was saved and when it was accepted.
> - **LeadId**: the lead the proposal was written for.
> 
> Some things to know:
> - **Search** only filters on the proposal name. Every proposal is called `New Proposal`, so it won't help you narrow down by month or customer. To find a specific customer's proposal, open the lead and press **View Proposal**.
> - **Complete** and **Cancel** act right away without asking for confirmation, so be careful clicking them while you review. If you make a mistake, you can apply them again.
> - The **Calendar** doesn't show any proposal or completion dates, so it won't help with this review.
> 
> The documentation doesn't describe a date filter, monthly totals or a report, so I can't point you to one.
> 
> Source: [Sales](Sales.md), [Calendar](Calendar.md)

**B2** (5.2 s, useful 1)

> The documentation doesn't explain how to apply a discount to a proposal. It says a proposal is an invoice with a header, **line items**, a **total** and a thank-you line. It doesn't describe a discount option. [Draft a proposal](Draft-Proposal.md)
> 
> It also doesn't describe a way to edit a proposal you've already saved:
> - **View Proposal** in the lead detail shows the document exactly as it was saved. That window only has **Close** and **Complete**. [Sales](Sales.md)
> - A lead can only have one proposal. [Draft a proposal](Draft-Proposal.md)
> 
> I can't tell you a reliable way to add the 10% discount here. Your application administrator or support team should be able to confirm how to do it.

**B3** (6.0 s, useful 1)

> **This is general sales practice, not a feature of the application:** after two weeks with no answer, follow up yourself.
> 
> 1. **Contact them directly.** A short call or e-mail works best. Ask if they had time to read the proposal and if they have any questions. Silence often just means they're busy.
> 2. **Offer something useful.** For example, offer to walk them through the proposal or to change its scope or terms.
> 3. **If there's still no answer, try once or twice more.** Leave about a week between tries. After that, ask them plainly whether it's still a priority. That usually gets a clear yes or no.
> 
> **On the Leads board:**
> - The lead stays in the **Proposal Sent** column while you wait. That column shows the **Date Drafted**, which tells you how long the proposal has been waiting.
> - When the lead decides, drag its row to the **Closed** column. If **Date Closed** is still empty, it's filled in with the current date and time.
> - There's also an **Inactive** status, but it has no column on the board. Inactive leads are only counted on the Dashboard. The documentation doesn't explain how to set a lead to Inactive.
> 
> The documentation doesn't mention reminders or automatic follow-ups, so you'll need to keep track of the follow-up date yourself.
> 
> Sources: [Leads](Leads.md), [Asking the assistant](Assistant.md)

**C1** (3.2 s, useful 2)

> The documentation doesn't describe any **automatic reminder** feature, so I can't tell you how to set one up. It doesn't seem to exist in this application.
> 
> The closest option is to check the board by hand. On the [Leads](Leads.md) board, the **Active** column shows each lead's **Date Contacted**. Any lead there with a date on or before **17 October 2026** hasn't been contacted for at least 30 days.
> 
> The **Search** box won't help with this, because it filters only by name, account name, office phone or e-mail, not by date.

**C2** (5.9 s, useful 2)

> I can't make a quarterly forecast for you. The documentation doesn't describe any forecast or report feature, and I have no tool that builds one.
> 
> **What the Sales screen shows** ([Sales](Sales.md)):
> - Every proposal of the active user, in one list.
> - **Value**: the invoice total when the proposal was saved.
> - **Status**: `New`, `Accepted` or `Canceled`.
> - **DateCreated**: when the proposal was saved.
> - **DateCompleted**: when it was accepted.
> 
> The documentation doesn't mention a way to group, total or export this list. You'd have to read the figures off the grid.
> 
> **How to build the forecast yourself (general sales practice, not from the manual):**
> 1. **Booked:** For each quarter, add up the Value of the `Accepted` proposals whose DateCompleted falls in that quarter.
> 2. **Pipeline:** Add up the Value of the `New` proposals, multiplied by how likely you think each one is to close. Put each one in the quarter you expect it to close.
> 3. **Canceled:** Leave these out.

**C3** (3.7 s, useful 2)

> The documentation doesn't cover payroll. It doesn't describe any payroll, salary or commission feature in this application, so I can't tell you how to do that here.
> 
> What it does describe is the **Sales** list. It shows every proposal of the active user, with its **Value** (the invoice total when saved), its **Status** (New, Accepted or Canceled) and the dates it was created and completed. To see a sales representative's proposals, pick that user in the drop-down at the right of the title bar, then open **Sales**. Any payroll calculation would have to be done outside the application. ([Sales](Sales.md), [Users](Users.md))

**D1** (4.2 s, useful 2)

> If 30 days starts today (Monday, 16 November 2026), the proposal is valid until **Wednesday, 16 December 2026**.
> 
> The documentation doesn't describe a validity or expiry field on the proposal. The draft fills in today's date for you, and you type the rest: the three address and phone boxes and the line items ([Draft a proposal](Draft-Proposal.md)).

**D2** (4.0 s, useful 2)

> No, it's not too late. It's **20:22** for you (UTC+01:00), which makes it about **14:22 on Monday afternoon in New York**. New York is on Eastern Standard Time (UTC−5) because daylight saving time ended on 1 November.
> 
> Early afternoon is usually a good time for a business call. You still have a few hours before the end of the working day there.
> 
> The **Call** button next to the phone number on this screen doesn't do anything yet. It's only a placeholder, so you'll need to dial the number yourself ([Lead detail](Lead-Detail.md)).

**D3** (4.3 s, useful 2)

> I can't list your leads for you. I have no tool for reading lead data, and the documentation doesn't describe a filter by creation date.
> 
> Here's how far you can get by looking at the board yourself:
> 
> - **New column:** this is the only column that shows **Date Created**. Look for dates in November 2026.
> - **Other columns:** **Active**, **Proposal Sent** and **Closed** show a different date (**Date Contacted**, **Date Drafted** and **Date Closed**). If a lead you created this month has already moved out of New, its creation date isn't shown on the board. [Leads](Leads.md)
> 
> Also, the board only shows leads for the user picked in the drop-down in the title bar. If some leads seem to be missing, check that it's set to the user who owns them. [FAQ](FAQ.md)

### claude-opus-5-5/v2

**A1** (7.6 s, useful 2)

> **General practice, not specific to this application:** In B2B, prices are usually quoted **net of VAT**, and the proposal says so clearly (for example "all prices excl. VAT"). It can also show the VAT amount and the gross total separately. The formal VAT details belong on the actual invoice. Rates and exemptions, such as reverse charge on cross-border EU sales, depend on your country and your customer, so check them with your accountant.
> 
> **In this application:** The documentation doesn't mention a VAT or tax field for proposals. A proposal has a list of line items, each with a title, a quantity and a price. The **Total** is worked out from those line items automatically, and that total is what gets saved as the proposal's value ([Draft a proposal](Draft-Proposal.md)).
> 
> Your options:
> - **Keep it net (simplest):** Enter your net prices as they are. The **Value** on the Sales screen will then be the net amount, which is usually better for judging your pipeline ([Sales](Sales.md)).
> - **Show VAT anyway:** Use **+** to add a separate line item, for example titled `VAT 22%`, and type in the VAT amount yourself. This is a workaround, not a tax feature. The Total and the saved Value will then include VAT.

**A2** (5.0 s, useful 1)

> This application doesn't calculate a pipeline value. The documentation doesn't mention any feature that totals deal amounts or weights them by stage.
> 
> **The closest the app gets:** the **Dashboard** you're on shows **how many** of the active user's leads are in each status (New, Active, Proposal Sent, Closed, Inactive, plus Total). It counts leads but doesn't add up any amounts. A few things to know:
> - The tiles only update when you come back to the Dashboard.
> - Clicking a tile does nothing. To see the leads behind a number, open **Leads**.
> - The counts follow the user drop-down in the title bar.
> 
> See [Dashboard](Dashboard.md).
> 
> **How it's usually done (general practice, not an app feature):**
> 1. **Unweighted pipeline:** add up the expected value of every open deal. Leave out closed and inactive ones.
> 2. **Weighted pipeline:** multiply each deal's value by a win probability for its stage, then add up the results. For example, New 10%, Active 30%, Proposal Sent 60%.
> 3. **Set the percentages from your own history:** use how many deals actually closed from each stage in the past, and update them now and then.
> 
> You could use the Dashboard counts per status as the starting point and do the weighting yourself in a spreadsheet.

**A3** (7.9 s, useful 2)

> The application has no rule for this. It doesn't flag stale leads or close them automatically, and it has no separate "lost" status. The board has four columns: **New**, **Active**, **Proposal Sent** and **Closed**, and **Closed** simply means "Finished" ([Leads](Leads.md)).
> 
> **What the app gives you:** the **Active** column shows each lead's **Date Contacted**, so you can see how long a lead has been there. When you decide a lead is dead, drag it to **Closed**. That fills in **Date Closed**. Dates that already have a value aren't overwritten, so the lead's history stays intact ([Leads](Leads.md)).
> 
> **General sales practice** (not a feature of this app):
> - **Use your own sales cycle.** If deals usually take 30 days to move from first contact to proposal, a lead that's been Active for 2 to 3 times that long without progress is probably not going anywhere.
> - **Count attempts, not just days.** A common rule is to stop after about 5 to 8 attempts over 2 to 4 weeks with no reply, using a mix of calls and e-mails.
> - **Send a "closing the file" message** before you give up. It often gets a reply.
> - **Record the reason.** "No budget" or "chose a competitor" helps with re-engaging the lead later and with reporting. The app's documentation doesn't mention a field for this.
> - **Review regularly.** For example, check the Active column once a week and decide for each lead: move it forward, keep working it, or close it.

**B1** (6.0 s, useful 1)

> The documentation describes no dedicated month-end report. The closest thing is the **Sales** screen, which you're already on. It lists [every proposal of the active user](Sales.md) with these columns:
> 
> - **Status**: `New`, `Accepted` or `Canceled`
> - **Value**: the invoice total at the moment the proposal was saved
> - **DateCreated** / **DateCompleted**: when the proposal was saved and when it was accepted
> 
> **What it can't do:**
> - The documentation doesn't describe any way to filter the grid by date.
> - The **Search** box only searches the proposal name, and every proposal is called `New Proposal`, so it won't help here. You'll need to read the dates in the grid yourself.
> - The [Calendar](Calendar.md) screen is just a month view and shows no data.
> - The excerpts I have don't describe what the **Dashboard** shows.
> 
> **How a month-end review usually goes** (general sales practice, not a feature of this app):
> 1. **Closed this month:** add up the **Value** of `Accepted` proposals whose **DateCompleted** falls in the month.
> 2. **Lost:** look at the `Canceled` ones and note why they fell through. Canceling doesn't record a date, so you can't tell from the grid when a proposal was lost.
> 3. **Still open:** `New` proposals are your pipeline. Old ones with no answer usually need a follow-up.
> 
> To check a specific customer's proposal, open the lead on the **Leads** board and press **View Proposal**.

**B2** (7.3 s, useful 1)

> The documentation I have doesn't describe a **discount** option for proposals, and it doesn't explain how to change a proposal after it's saved.
> 
> Here's what it does say:
> 
> - A proposal is an invoice with a header, line items, a total and a thank-you line. You fill it in from **Create Proposal** in the lead detail window and save it with **Save Proposal**. ([Draft a proposal](Draft-Proposal.md))
> - Saving stores the document whole in the database, and the proposal's **Value** is the invoice total at that moment. **View Proposal** shows it exactly as it was saved. ([Sales](Sales.md))
> - A lead can have only one proposal. ([Draft a proposal](Draft-Proposal.md))
> - The **Sales** screen only lets you mark a proposal **Complete** (accepted) or **Cancel** it. You can't edit it there. ([Sales](Sales.md))
> 
> So the documentation doesn't say how to put a 10% discount on a proposal that's already saved.
> 
> **Some general sales advice (not specific to this application):**
> - Show the discount clearly, for example list price, then the 10% discount, then the net total. The customer can see what they're getting, and your reports will show what you actually earned.
> - Record why you gave the discount and how long the offer is valid, so it doesn't become the expected price next time.
> - Consider asking for something in return, such as a longer contract, a bigger order or faster payment.

**B3** (6.3 s, useful 1)

> **General sales practice (not specific to this application):** Two weeks of silence after a proposal is normal, so a follow-up is due. Some good habits:
> 
> 1. **Call first, then e-mail.** A short call works better than a written reminder. Ask if they got the proposal, if they have questions, and who else is part of the decision.
> 2. **Bring something new.** Offer to go through the proposal together, clarify the scope, or adjust options. Avoid a plain "just checking in."
> 3. **Agree on a next step.** Ask for a date when they expect to decide.
> 4. **Set a limit.** If two or three follow-ups over the next few weeks get no answer, treat the deal as lost. Keeping dead leads makes your pipeline look bigger than it is.
> 
> **In this application:**
> - On the **Leads** board, the lead stays in the **Proposal Sent** column. That column shows **Date Drafted**, so you can check how long the proposal has been waiting for an answer.
> - When the deal is finished, either way, drag the lead to the **Closed** column. Its status changes and **Date Closed** gets today's date if it was empty. ([Leads](Leads.md))
> 
> The documentation doesn't mention any follow-up reminders, and it doesn't say how to mark a deal as lost rather than won. There is an **Inactive** status, but it has no column on the board, and the documentation doesn't say how to give a lead that status.

**C1** (4.6 s, useful 2)

> The documentation doesn't describe any **automatic reminders**, so I can't tell you how to set one up here. The application may not have this feature.
> 
> **The closest option is to check the Leads board yourself** ([Leads](Leads.md)):
> - The **Active** column shows each lead's **Date Contacted**. Look for dates more than 30 days ago, before 17 October 2026.
> - The **New** column shows **Date Created**. Leads there haven't been called yet, so any created more than 30 days ago have gone without contact for at least that long.
> 
> The **Search** box can't help here, because it only matches name, account name, office phone or e-mail.
> 
> **As general sales practice** (not a feature of this app), it helps to check for stale leads at a regular time, like once a week, and set a follow-up date every time you speak to a lead so none go cold.

**C2** (4.9 s, useful 2)

> The documentation doesn't describe a forecast or report by quarter, so I can't produce one in this application.
> 
> **What the app does have:** the **Sales** screen you're on lists every proposal of the active user. Each row has its **Status** (New, Accepted or Canceled), its **Value** (the invoice total when it was saved), **DateCreated** and **DateCompleted** (the date it was accepted). These columns are the raw data you'd need. You'd have to group and add them up by quarter yourself, outside the app. ([Sales](Sales.md))
> 
> **How a forecast is usually built (general sales practice, not an app feature):**
> 1. **Accepted** proposals count as closed revenue in the quarter of their DateCompleted.
> 2. **New** (open) proposals are your pipeline. Assign each one to the quarter you expect it to close in.
> 3. Multiply each open value by a probability of winning, for example 20–30% for a fresh proposal and more for one that's being negotiated. Adding these up gives a weighted forecast.
> 4. Leave **Canceled** proposals out.

**C3** (6.3 s, useful 1)

> This application **doesn't calculate payroll**, and the documentation doesn't describe any salary or commission feature. Payroll is also outside what I can help with.
> 
> If you pay your rep a **commission on closed deals**, the Sales list can give you the figures to start from:
> 
> 1. Pick the rep in the **user drop-down** at the right of the title bar. The [Sales](Sales.md) list then shows only proposals stamped with that user's name.
> 2. Open **Sales** and look for proposals with **Status** `Accepted`. **Value** is the invoice total at the time the proposal was saved, and **DateCompleted** is when it was accepted.
> 3. Use those values to work out the commission in your payroll or accounting tool.
> 
> Keep in mind:
> - Each [user](Users.md) is just a label on the records it owns, not a real login. So the list only shows what was created while that user was active, or what was later reassigned to them.
> - A proposal can be completed or canceled again at any time, and nothing gets locked. It's common practice to check the list on a fixed date before you pay commissions.

**D1** (4.7 s, useful 2)

> Counting 30 days from today (Monday, 16 November 2026), the proposal is valid until **Wednesday, 16 December 2026**.
> 
> The proposal draft has no field for a validity or expiry date. It only fills in today's date for you, and the rest is the address boxes, the line items and the total ([Draft a proposal](Draft-Proposal.md)). This means the application won't track the expiry or remind you about it.
> 
> It's common to put the expiry date on the proposal so the customer can see it, and to follow up a few days before it runs out.

**D2** (3.7 s, useful 2)

> No, it's not too late. It's **20:24 (UTC+01:00)** for you, which makes it **14:24 on Monday afternoon** in New York (Eastern Standard Time, UTC−5). That's normal business hours there.
> 
> In B2B sales it's usually best to call between mid-morning and late afternoon in the customer's own time zone. You have about 2½ to 3 hours left today.
> 
> Note that the **Call** button next to the phone number on this Lead Detail screen doesn't do anything yet. It's a placeholder, so you'll need to dial the number yourself ([Lead detail](Lead-Detail.md)).

**D3** (4.2 s, useful 2)

> I can't check your leads for you because I have no tool that reads them. The documentation also doesn't describe any date filter or report for "leads created this month."
> 
> The closest you can get is on the [Leads](Leads.md) board you're on now:
> 
> - **New column:** it shows **Date Created**, so you can look there for November 2026 dates. This only covers leads nobody has called yet.
> - **Other columns:** once a lead moves on, its column shows a different date. **Active** shows Date Contacted, **Proposal Sent** shows Date Drafted, and **Closed** shows Date Closed. So a lead you created this month that has already moved won't show its creation date on the board.
> 
> Also, nearly every list is filtered by the **user drop-down** in the title bar. Make sure it's set to your user, or you won't see your own leads ([FAQ](FAQ.md)).

