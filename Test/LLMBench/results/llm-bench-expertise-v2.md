# HelpChatAI expertise benchmark

Run on 2026-11-14 16:04. Grounding: `CRM Demo\Help\help-index.json`, 3 pages; no actions; a new conversation per question; language English. The assistant is called Giulio and the prompt opens with its name and now (date, time, time zone); **v1** without `Expertise`, **v2** with `Expertise` = "B2B sales and customer relationship management: leads and the sales pipeline, accounts, proposals and invoicing, follow-up, sales reporting", which the library composes with the rule that the expertise explains concepts while the procedures of the application come only from the manual. Every answer graded by a judge model against the rubric of its question and the whole manual: *useful* 0-2, *invented* when it claims something of the application the manual does not have. *Pass* = useful 2 and nothing invented.

## Summary

| Target | Questions | Errors | Avg time | Avg useful | Invented | Pass |
|---|---:|---:|---:|---:|---:|---:|
| claude-haiku-5-5/v1 | 12 | 0 | 3.0 s | 1.25 | 0 | **3/12** |
| claude-haiku-5-5/v2 | 12 | 0 | 4.1 s | 1.42 | 1 | **5/12** |
| claude-opus-5-5/v1 | 12 | 0 | 4.6 s | 1.33 | 0 | **4/12** |
| claude-opus-5-5/v2 | 12 | 0 | 6.9 s | 1.67 | 1 | **7/12** |
| gemini-pro-latest/v1 | 12 | 0 | 6.3 s | 1.25 | 0 | **3/12** |
| gemini-pro-latest/v2 | 12 | 0 | 9.2 s | 1.33 | 0 | **4/12** |
| gpt-6.1-sol/v1 | 12 | 0 | 2.8 s | 1.17 | 0 | **2/12** |
| gpt-6.1-sol/v2 | 12 | 0 | 3.5 s | 1.58 | 0 | **7/12** |

## Passed, per question

Models that passed, out of 4.

| Question | v1 | v2 |
|---|---:|---:|
| A1 | 0 | 3 |
| A2 | 0 | 3 |
| A3 | 0 | 2 |
| B1 | 0 | 0 |
| B2 | 0 | 0 |
| B3 | 0 | 0 |
| C1 | 3 | 2 |
| C2 | 0 | 3 |
| C3 | 4 | 2 |
| D1 | 3 | 4 |
| D2 | 2 | 3 |
| D3 | 0 | 1 |

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
  - rubric: It is about 09:50 in New York (UTC-5 in November; the answer may be up to an hour earlier, it was asked before this grading). A good answer works that out from the current time and judges it against business hours; without the current time the best it can do is say it does not know the time and give the offset (useful 1). The Call button of the lead does nothing.
- **D3** (screen Leads): Which leads did I create this month?
  - rubric: Knows that this month is November 2026. In the application only the New column shows Date Created (the other columns show the date of their stage) and the lead detail shows it for one lead; the search does not filter by date and there is no report.

## Verdicts

| Question | Target | Useful | Invented | Cited | Note |
|---|---|---:|---|---|---|
| A1 | claude-haiku-5-5/v1 | 1 | no | Draft-Proposal.md | Correctly says the total is the sum of line items, but never states that the draft has no tax field, never suggests adding VAT as its own line item or inside the prices, and explains no net/gross or VAT basics. |
| A1 | claude-haiku-5-5/v2 | 1 | no | Draft-Proposal.md | The line-item workaround is correct, but the answer wrongly hedges on whether the app adds VAT (the manual defines the total as quantity × price only) and barely explains how VAT is computed from the net amount at the country's rate. |
| A1 | claude-opus-5-5/v1 | 1 | no | Draft-Proposal.md Sales.md | Accurately describes the draft (title, quantity, price, total) and the absence of a tax field, but declines the general VAT explanation and does not suggest adding VAT as its own line item or including it in the prices. |
| A1 | claude-opus-5-5/v2 | 2 | no | Draft-Proposal.md Data-Model.md Sales.md | Correctly separates general VAT practice from the app, notes there is no tax field and the total is the sum of line items, and gives an accurate VAT-line-item workaround with real effects on the Sales value. |
| A1 | gemini-pro-latest/v1 | 1 | no | - | It only says the manual does not cover VAT. It could have explained net versus gross and that the draft has no tax field (total is the sum of quantity × price), so VAT goes in as its own line item or inside the prices. |
| A1 | gemini-pro-latest/v2 | 2 | no | Draft-Proposal.md | Correctly says the draft has no VAT field and the total is the sum of line items, and suggests a separate VAT line item via the + button; it only lightly covers the net/gross and country-rate explanation and omits including VAT in the prices. |
| A1 | gpt-6.1-sol/v1 | 1 | no | Draft-Proposal.md | Correctly says the draft has no VAT or tax field, but skips the general net/gross explanation and the workaround of adding VAT as its own line item or inside the prices. |
| A1 | gpt-6.1-sol/v2 | 2 | no | Draft-Proposal.md | Correctly says the draft has no VAT field and suggests a separate VAT line item, but only lightly covers net/gross and calling the workaround 'documented' slightly overstates the manual. |
| A2 | claude-haiku-5-5/v1 | 1 | no | Sales.md Dashboard.md | It correctly points to the Value and Status columns on Sales and notes there is no pipeline total, but it never explains weighted pipeline (open deals × stage probability) and does not say to sum only the proposals still New. |
| A2 | claude-haiku-5-5/v2 | 1 | no | Dashboard.md Sales.md | Correctly says there is no pipeline report and points to proposal Values on Sales, but it suggests adding up all of them instead of only the still-New (open) ones and never links stage weighting to the board columns. |
| A2 | claude-opus-5-5/v1 | 1 | no | Sales.md Dashboard.md | The answer correctly says there is no pipeline total and points to Value and Status on Sales, but it never explains the weighted pipeline method or says to sum only the proposals still New. |
| A2 | claude-opus-5-5/v2 | 2 | no | Sales.md Dashboard.md | Correctly says there is no pipeline report, explains open and weighted pipeline as general practice, and points to summing the Value of New proposals on Sales; the hint that the invoice could be changed later is misleading, since saved proposals cannot be edited. |
| A2 | gemini-pro-latest/v1 | 1 | no | Sales.md | Says only that the manual does not cover it, when it could have explained weighted pipeline value and pointed to the Value of New proposals on the Sales page and the board columns as stages. |
| A2 | gemini-pro-latest/v2 | 2 | no | Sales.md Dashboard.md | It correctly explains the weighted-pipeline concept as general practice, says there is no pipeline report, and points to summing Value on the Sales page; it could have said explicitly to sum only proposals with status New. |
| A2 | gpt-6.1-sol/v1 | 1 | no | Dashboard.md Sales.md | Correctly points to the proposal Values on Sales and says there is no pipeline total, but never explains how to compute it: no weighted pipeline concept, no stage probabilities, no advice to sum the proposals still New. |
| A2 | gpt-6.1-sol/v2 | 2 | no | Sales.md Dashboard.md | Correctly explains pipeline and weighted pipeline as general practice, points to the Value of New proposals on Sales, and says there is no pipeline report or probability weighting. |
| A3 | claude-haiku-5-5/v1 | 1 | no | Leads.md | Correctly says there is no Lost status, but gives no typical sales guidance and does not mention Date Contacted or closing the lead by dragging it to Closed or setting it Inactive. |
| A3 | claude-haiku-5-5/v2 | 2 | no | Leads.md | Gives sound sales-cycle guidance and accurately describes Date Contacted, closing by dragging to Closed, and that nothing ages leads automatically; it only leaves out the Inactive option and follow-up-count guidance. |
| A3 | claude-opus-5-5/v1 | 1 | no | Leads.md | Correctly cites Date Contacted, dragging to Closed and the lack of a Lost status, but gives no field guidance on sales cycles or follow-ups and does not mention Inactive. |
| A3 | claude-opus-5-5/v2 | 2 | **yes** | Leads.md | Strong answer that matches the rubric, but 'sorted by Date Contacted' implies the board columns can be sorted, which the manual never describes. |
| A3 | gemini-pro-latest/v1 | 1 | no | Leads.md | Correct but minimal: it offers no general sales-cycle guidance and does not mention Date Contacted, dragging the lead to Closed or Inactive, or the absence of a Lost status or automatic aging. |
| A3 | gemini-pro-latest/v2 | 1 | no | - | The answer is cut off mid-sentence: it starts the general sales-cycle guidance but gives no figures, never mentions Date Contacted, and never explains closing the lead by dragging it to Closed or setting it Inactive. |
| A3 | gpt-6.1-sol/v1 | 1 | no | Leads.md | Correctly describes Active, Closed and dragging to Closed, but gives no sales-cycle guidance and never mentions Date Contacted, Inactive or the lack of a Lost status. |
| A3 | gpt-6.1-sol/v2 | 2 | no | Leads.md | It gives sound general guidance, labelled as practice and not an app rule, and correctly says there is no time limit or Lost status and that you drag the lead to Closed, though it leaves out Date Contacted and the Inactive option. |
| B1 | claude-haiku-5-5/v1 | 1 | no | Sales.md | It correctly points to the Sales columns and says there is no monthly filter or totals, but it omits the Dashboard counts per status for the pipeline and wrongly says the user is already on Sales (they are on MainForm). |
| B1 | claude-haiku-5-5/v2 | 1 | **yes** | Sales.md Calendar.md | It rightly points to Sales and says there is no report or date filter, but it suggests sorting the list, which the manual does not describe, wrongly says the user is already on the right screen, and leaves out the Dashboard. |
| B1 | claude-opus-5-5/v1 | 1 | no | Sales.md Calendar.md ToDo.md | It correctly points to the Sales grid columns and says there is no monthly report or date filter, but it leaves out the Dashboard per-status counts for the pipeline and wrongly says the user is already on Sales. |
| B1 | claude-opus-5-5/v2 | 1 | no | Sales.md ToDo.md Calendar.md | The Sales columns and limits are accurate, but it skips the Dashboard's leads-per-status view of pipeline movement and wrongly says the user is already on Sales. |
| B1 | gemini-pro-latest/v1 | 1 | no | Sales.md Calendar.md | Correctly points to the Sales columns and notes there is no month filter, but it omits the Dashboard and pipeline movement and wrongly says the user is already on the Sales screen. |
| B1 | gemini-pro-latest/v2 | 1 | no | Sales.md Calendar.md | Correctly points to the Sales list (Status, Value, DateCompleted) and the lack of reports or date filters, but wrongly assumes the user is already on Sales, omits the Dashboard, canceled proposals and DateCreated, and calls a manual Sales review the only way. |
| B1 | gpt-6.1-sol/v1 | 1 | no | Sales.md Calendar.md | Correctly points to Sales and its Status/Value/DateCreated/DateCompleted columns, but omits the Dashboard, never says there is no monthly report or date filter, and wrongly assumes the user is already on Sales. |
| B1 | gpt-6.1-sol/v2 | 1 | no | Sales.md Calendar.md | It correctly points to the Sales columns and says there is no monthly report or date filter, but it omits the Dashboard counts for pipeline movement and assumes the user is already on Sales. |
| B2 | claude-haiku-5-5/v1 | 1 | no | Draft-Proposal.md ToDo.md | It correctly warns that a saved proposal cannot be edited, but it does not say there is no discount field or suggest lowering the line-item prices or adding a discount line so the total recomputes. |
| B2 | claude-haiku-5-5/v2 | 1 | no | Draft-Proposal.md Sales.md | It rightly warns that the discount must go in before saving, but it never says to lower the line-item prices or add a discount line, and it wrongly hints the computed total might be set by hand. |
| B2 | claude-opus-5-5/v1 | 1 | no | ToDo.md Draft-Proposal.md | It rightly warns that a saved proposal cannot be edited, but it misses the workaround of lowering the line-item prices or adding a discount line before saving, and it wrongly says the manual is silent on a second proposal when the FAQ explains deleting the old one and creating a new one. |
| B2 | claude-opus-5-5/v2 | 1 | no | Draft-Proposal.md ToDo.md | It rightly says there is no discount field and a saved proposal cannot be edited, but it never suggests lowering line-item prices or adding a discount line before saving, and it wrongly claims the manual is silent on redoing a proposal, when the FAQ says to delete it from the Sales list and create a new one. |
| B2 | gemini-pro-latest/v1 | 1 | no | ToDo.md | It correctly says a saved proposal cannot be edited, but omits that there is no discount field and that the discount goes in before saving, either as lower line-item prices or a negative line. It also misses the FAQ route of deleting the proposal from Sales and creating a new one. |
| B2 | gemini-pro-latest/v2 | 1 | no | ToDo.md | It correctly says a saved proposal cannot be edited, but never says there is no discount field or that the discount goes in the draft by lowering prices or adding a negative line, and its 'cancel and issue a new one' advice fails here because a lead allows only one proposal unless the old one is deleted from Sales. |
| B2 | gpt-6.1-sol/v1 | 1 | no | ToDo.md | It rightly warns that a saved proposal cannot be edited, but it never says there is no discount field or suggests lowering the line-item prices or adding a discount line before saving. |
| B2 | gpt-6.1-sol/v2 | 1 | no | ToDo.md Sales.md | It correctly warns that a saved proposal cannot be edited, but it misses the main solution (lower the line-item prices or add a discount line before saving, and the total recomputes), suggests Cancel instead of deleting and redrafting, and says it does not know the drafting case. |
| B3 | claude-haiku-5-5/v1 | 1 | no | Leads.md | Accurate about the Proposal Sent column and Date Drafted, but it withholds standard follow-up advice and leaves out Notes for logging follow-ups, Inactive for parking, the non-working Call/Email buttons and the lack of reminders. |
| B3 | claude-haiku-5-5/v2 | 1 | no | Leads.md | Sound follow-up advice and correct points on Date Drafted and missing reminders, but it omits logging follow-ups in Notes, parking the lead as Inactive and that Call/Email do nothing, and 'your calendar' could be misread as the app's Calendar, which cannot hold appointments. |
| B3 | claude-opus-5-5/v1 | 1 | no | Leads.md | Its Proposal Sent, Date Drafted and Closed details are accurate, but it gives no follow-up advice, omits Notes and the dead Call/Email buttons, and wrongly says the manual doesn't explain setting Inactive, which the Status field in the lead detail allows. |
| B3 | claude-opus-5-5/v2 | 1 | no | Leads.md | The follow-up advice and the Date Drafted, Closed and Inactive facts are correct. But it leaves out recording follow-ups in Notes and setting Inactive through the Status field in the lead detail, and it wrongly says the manual cannot explain the Calendar, which the manual describes as showing no data and allowing no appointments. |
| B3 | gemini-pro-latest/v1 | 1 | no | Leads.md | Correct but it just says the manual does not cover this. It gives no follow-up advice and does not point to Date Drafted, Notes or the Inactive status, nor mention that the Call/Email buttons and reminders do not exist. |
| B3 | gemini-pro-latest/v2 | 1 | no | - | The general follow-up advice is sound and the Proposal Sent remark is correct, but the answer breaks off mid-sentence and never mentions Date Drafted, logging follow-ups in Notes, parking the lead as Inactive, the non-working Call/Email buttons or the lack of reminders. |
| B3 | gpt-6.1-sol/v1 | 1 | no | Leads.md | Correct but minimal: it gives no follow-up advice and leaves out Date Drafted, Notes, the Inactive status, and that the Call/Email buttons do nothing and there are no reminders. |
| B3 | gpt-6.1-sol/v2 | 1 | no | Leads.md | The follow-up advice is sound and the Proposal Sent status is correct, but it leaves out recording follow-ups in Notes, Date Drafted, parking the lead as Inactive, and that there are no reminders and the Call/Email buttons do nothing. |
| C1 | claude-haiku-5-5/v1 | 2 | no | Leads.md | It correctly says there is no reminder feature and points to checking the New and Active columns' dates by hand, with an accurate description of the Search box. |
| C1 | claude-haiku-5-5/v2 | 2 | no | Leads.md | Correctly says no reminder feature is documented and points to checking Date Contacted in the Active column by hand, though it hedges instead of stating plainly that none exists. |
| C1 | claude-opus-5-5/v1 | 2 | no | Leads.md | Correctly offers no reminder setup and gives the manual check of Date Contacted on the board, though it hedges ('I don't know') instead of plainly stating the application has no reminders. |
| C1 | claude-opus-5-5/v2 | 1 | no | Leads.md | The answer rightly points to the Active column's Date Contacted as the manual workaround, but it hedges on whether reminders exist (the manual is complete, so they don't) and wrongly calls that date the last contact when it is only stamped the first time a lead becomes Active. |
| C1 | gemini-pro-latest/v1 | 1 | no | Leads.md | Correctly invents no reminder feature, but only says the docs don't cover it, without stating that the application has no reminders or pointing to the Active column's Date Contacted as the manual workaround. |
| C1 | gemini-pro-latest/v2 | 1 | no | Dashboard.md Leads.md | Correctly says there are no automatic reminders and points to the Active column, but omits the Date Contacted column that makes a manual 30-day check possible. |
| C1 | gpt-6.1-sol/v1 | 2 | no | Leads.md | Correctly says there are no automatic reminders and points to the Active column's Date Contacted for a manual check, as the rubric asks. |
| C1 | gpt-6.1-sol/v2 | 2 | no | Leads.md | Correctly says there is no reminder feature and points to the Active column's Date Contacted (and New's Date Created) for a manual review, adding a fair caveat. |
| C2 | claude-haiku-5-5/v1 | 1 | no | Sales.md | Correctly says the application produces no forecast and points to the Sales columns as raw data, but never explains what a quarterly forecast involves or how to build one from those values. |
| C2 | claude-haiku-5-5/v2 | 1 | no | Sales.md | Correctly says there is no forecast and points to the Sales values and dates, but never explains what a forecast is, and its method only totals past accepted proposals while leaving the open New pipeline unused. |
| C2 | claude-opus-5-5/v1 | 1 | no | Sales.md | It correctly says the application has no forecast and lists the Sales fields accurately, but it never explains what a quarterly forecast is or how those values and dates could be used to build one. |
| C2 | claude-opus-5-5/v2 | 2 | no | Sales.md Data-Model.md | Correctly says there is no forecast feature, points to the Value, Status and dates on the Sales list, and labels the weighted-pipeline explanation as general practice, with no made-up numbers. |
| C2 | gemini-pro-latest/v1 | 1 | no | Sales.md | The answer correctly says the application has no forecast feature, but it does not explain what a forecast is and does not point to the proposal values and dates on the Sales page as raw material. |
| C2 | gemini-pro-latest/v2 | 2 | no | Sales.md | Briefly explains forecasting, correctly states the app has no such feature, and points to the Sales page columns (Status, Value, DateCreated, DateCompleted) as raw material, with no invented numbers. |
| C2 | gpt-6.1-sol/v1 | 1 | no | Sales.md | Correctly says the app cannot produce a forecast and points to the Sales page's values and dates, but it neither explains what a quarterly forecast is nor how to build one from that data. |
| C2 | gpt-6.1-sol/v2 | 2 | no | Sales.md | It correctly says the application has no forecasting report, points to the Sales page's proposal values, statuses and dates as raw material, and explains a forecast as general practice without inventing figures. |
| C3 | claude-haiku-5-5/v1 | 2 | no | Users.md Sales.md FAQ.md | It correctly declines because payroll is not in the application, and its pointer to the Sales list matches the manual. |
| C3 | claude-haiku-5-5/v2 | 2 | no | Sales.md | It briefly declines the out-of-scope payroll question without computing it or claiming payroll features, and points to the Sales screen, which does exist. |
| C3 | claude-opus-5-5/v1 | 2 | no | - | Briefly declines and correctly states the application has no payroll, salary or commission feature, as the rubric expects. |
| C3 | claude-opus-5-5/v2 | 2 | no | Sales.md | Declines briefly and correctly, as the rubric asks; citing Sales.md is unnecessary but claims nothing false. |
| C3 | gemini-pro-latest/v1 | 2 | no | Sales.md | Briefly and correctly declines because payroll is outside the manual; the Sales citation is odd but claims no payroll feature. |
| C3 | gemini-pro-latest/v2 | 1 | no | Sales.md | It correctly says the application has no payroll or commission feature, but instead of declining briefly it drifts into general commission advice and suggests using Sales values, which the rubric does not want. |
| C3 | gpt-6.1-sol/v1 | 2 | no | Users.md | Briefly declines because payroll is out of scope, and correctly says that Users are only labels and filters, as the manual describes. |
| C3 | gpt-6.1-sol/v2 | 1 | no | Users.md | It rightly says the manual has no payroll feature, but then gives general payroll guidance and offers to help with commissions instead of simply declining as out of scope. |
| D1 | claude-haiku-5-5/v1 | 2 | no | - | Gives the correct date, 14 December 2026, and honestly says the manual has no validity field, though it misses the line-item-title workaround. |
| D1 | claude-haiku-5-5/v2 | 2 | no | Draft-Proposal.md | The date of 14 December 2026 is correct and the answer rightly says there is no validity field, though it misses the workaround of writing the date in a line item title. |
| D1 | claude-opus-5-5/v1 | 2 | no | Sales.md | It gives the correct date (Monday 14 December 2026) and rightly says the application has no validity field, though it skips the option of noting the date in a line item title. |
| D1 | claude-opus-5-5/v2 | 2 | no | Draft-Proposal.md ToDo.md | Correctly gives Monday 14 December 2026 and notes there is no validity field, though it never suggests the 20-character line item title as the place to write it. |
| D1 | gemini-pro-latest/v1 | 2 | no | - | The date is correct (14 Nov 2026 + 30 days = Monday 14 Dec 2026); the answer only omits that the draft has no validity field, which is an omission rather than an invention. |
| D1 | gemini-pro-latest/v2 | 2 | no | Draft-Proposal.md | It gives the correct date (14 December 2026) and correctly says the draft has no validity field, though it does not suggest writing the date in a line item title. |
| D1 | gpt-6.1-sol/v1 | 1 | no | - | Correctly implies there is no validity field, but fails to give the simple date (Monday 14 December 2026) or suggest writing it in a line item title. |
| D1 | gpt-6.1-sol/v2 | 2 | no | - | The date is correct (14 December 2026) and answers the question, though it does not mention that the draft has no validity field. |
| D2 | claude-haiku-5-5/v1 | 1 | no | Lead-Detail.md | It declines without working out New York time (about 09:50, within business hours) or giving the UTC-5 offset, and it misses that the Call button does nothing, though its claim about the Notes field matches the manual. |
| D2 | claude-haiku-5-5/v2 | 2 | no | - | Correctly works out about 9:51 a.m. Saturday in New York, sensibly flags the weekend, and its app references (Calendar has no appointments, Notes field) match the manual; it omits that the Call button does nothing, but that is not an invention. |
| D2 | claude-opus-5-5/v1 | 2 | no | Lead-Detail.md ToDo.md | Correctly gives about 9:52 Saturday morning in New York (UTC−5, six hours behind), flags the weekend, and rightly notes the Call button is only a placeholder. |
| D2 | claude-opus-5-5/v2 | 2 | no | Lead-Detail.md ToDo.md | Correctly works out about 9:54 a.m. Saturday in New York (UTC−5), sensibly flags the weekend, and rightly notes that the lead's Call button does nothing. |
| D2 | gemini-pro-latest/v1 | 2 | no | Lead-Detail.md | The New York time (about 09:55, Saturday) is right and the Call-placeholder warning matches the manual, though it could have flagged that a Saturday call may fall outside business hours. |
| D2 | gemini-pro-latest/v2 | 1 | no | - | It only says it cannot check the time; it gives neither the New York offset (UTC-5, so about 10:00 on a Saturday morning there) nor any judgment against business hours. |
| D2 | gpt-6.1-sol/v1 | 1 | no | Lead-Detail.md | It correctly says the Call button is only a placeholder, but it never works out that it is about 10:00 in New York (UTC-5), which is within business hours, and it does not even give the time offset. |
| D2 | gpt-6.1-sol/v2 | 2 | no | - | Correctly puts New York at about 10 a.m. on a Saturday and sensibly advises waiting for business hours, without claiming any application feature. |
| D3 | claude-haiku-5-5/v1 | 1 | no | Leads.md FAQ.md | It correctly names November 2026 and says the New column shows Date Created with no date filter, but 'check the other columns too' misleads, since those columns show other dates and it never points to the lead detail window for Date Created. |
| D3 | claude-haiku-5-5/v2 | 1 | no | Leads.md FAQ.md | Correctly places this month as November 2026 and points to the New column's Date Created, but misses that the lead detail window shows Date Created for leads in the other columns, and wrongly implies the manual never shows it. |
| D3 | claude-opus-5-5/v1 | 1 | no | Leads.md FAQ.md | Correctly explains that only the New column shows Date Created and that there is no date filter, but it never names the month (November 2026) and omits that the lead detail window shows Date Created for leads that have left New. |
| D3 | claude-opus-5-5/v2 | 2 | no | Leads.md FAQ.md | Correctly places the month as November 2026 and notes that only the New column shows Date Created and that there is no date filter or report, though it omits opening the lead detail to see Date Created for leads in other columns and hedges about a filter the manual shows does not exist. |
| D3 | gemini-pro-latest/v1 | 1 | no | Leads.md | Correctly invents nothing, but stops at 'not covered' instead of saying it is November 2026, that only the New column and the lead detail show Date Created, and that search cannot filter by date and there is no report. |
| D3 | gemini-pro-latest/v2 | 1 | no | Leads.md FAQ.md | Correctly says there is no date filter or report and points to the Date Created column under New, but it never names November 2026 and misses that leads already moved to other columns show only in the lead detail. |
| D3 | gpt-6.1-sol/v1 | 1 | no | Leads.md FAQ.md | Correctly says no such list exists and only the New column shows Date Created, but it never names the month (November 2026), nor mentions the lead detail dates or that search cannot filter by date. |
| D3 | gpt-6.1-sol/v2 | 1 | no | Leads.md FAQ.md | Correctly places 'this month' in November 2026, says only the New column shows Date Created and that no listing exists, but omits that the lead detail window shows Date Created for leads that have moved on, and that search cannot filter by date. |

## Answers

### claude-haiku-5-5/v1

**A1** (2.1 s, useful 1)

> The documentation doesn't cover VAT or tax, so I can't say whether you should add it or how the application handles it.
> 
> What it does say is that the proposal's total is the sum of its line items, and it recomputes whenever a line item changes. The documentation doesn't say whether that sum includes any tax. You can check the total in the draft window before you save. For guidance on VAT itself, check with your accountant or your company's internal policy.
> 
> Source: [Draft a proposal](Draft-Proposal.md)

**A2** (3.0 s, useful 1)

> The documentation doesn't say how to calculate a pipeline value, and I don't see a total or sum feature in it. What it does cover:
> 
> - **Sales** lists every proposal of the active user, with a **Value** column showing the invoice total as it was when saved, and a **Status** column (New, Accepted, or Canceled). You can read the values there, but the documentation doesn't mention a total row. ([Sales](Sales.md))
> - **Dashboard** counts your leads per status (New, Active, Proposal Sent, Closed, Inactive, and Total), but these are lead counts, not monetary values. ([Dashboard](Dashboard.md))
> 
> If you need the total, you would have to add up the Value figures yourself from the Sales list. For a dependable pipeline figure, check with your administrator or the application's support channel, since this may be outside what the documentation covers.

**A3** (3.0 s, useful 1)

> The help documentation doesn't say how long a lead should stay in Active or when to treat one as lost. It only describes Active as the column for leads that are being worked on, and the board has no "Lost" status. Your team will need to set that rule itself.
> 
> The [Leads](Leads.md) page describes the four columns: New, Active, Proposal Sent, and Closed.

**B1** (3.6 s, useful 1)

> You're already on the **Sales** screen, which lists every proposal of the active user in one list. For the review, look at these columns:
> 
> - **Status**: `New` when saved, then `Accepted` or `Canceled`.
> - **Value**: the invoice total as it was when saved.
> - **DateCreated** and **DateCompleted**: when the proposal was saved and when it was accepted.
> 
> Keep in mind that Cancel leaves DateCompleted unchanged, and Complete and Cancel can be reapplied at any time, so a proposal's status may not reflect its final outcome. The documentation doesn't describe a way to filter by month or to produce totals, so you'll need to check the dates and values in the list yourself. The Search box only filters on the proposal name, and every proposal is called New Proposal, so it won't help you find a customer's proposals. To find one, open the lead and press View Proposal.
> 
> Source: [Sales](Sales.md)

**B2** (3.2 s, useful 1)

> The documentation doesn't cover discounts, so I can't tell you how to apply one.
> 
> What it does say about proposals: a proposal is an invoice with a header, a list of line items, a total, and a thank-you line. You fill it in, review it, and save it, and it opens from Create Proposal in the lead detail window ([Draft a proposal](Draft-Proposal.md)). Once saved, a proposal cannot be edited, only accepted or canceled ([Known limitations](ToDo.md)). If the customer's discount needs to be on the document, it would have to be reflected before you save, but the documentation doesn't say whether the draft window has a discount field. Your administrator or the application's support team can confirm what's possible.

**B3** (3.4 s, useful 1)

> The manual doesn't say what to do when a proposal goes unanswered, so I can't advise on follow-up steps. It does explain how the board tracks this:
> 
> - A lead in the **Proposal Sent** column is one where a proposal is out, waiting for an answer. The column shows the Date Drafted and the account name. ([Leads](Leads.md))
> - To change a lead's stage, drag its row to another column. The lead takes that column's status, and if that stage's date is empty, it is stamped with the current time. ([Leads](Leads.md))
> - Dropping a lead on **Closed** stamps Date Closed, so avoid that column unless the deal is actually finished. ([Leads](Leads.md))

**C1** (2.1 s, useful 2)

> The documentation doesn't cover automatic reminders or alerts, so I can't tell you how to set one up.
> 
> You can check the leads manually on the Leads board. Each column shows the date that matters at that stage: the **New** column shows Date Created, and the **Active** column shows Date Contacted. Use the Search box to narrow the list to a particular lead or account. ([Leads](Leads.md))

**C2** (2.0 s, useful 1)

> The documentation doesn't cover sales forecasting, so I can't tell you how to produce one in this application.
> 
> The Sales screen does list every proposal with its **Value**, **Status**, and **DateCreated** and **DateCompleted** dates, so you can see the raw data a forecast would need. The [Sales](Sales.md) page describes those columns, but not any way to group or project them by quarter.

**C3** (1.8 s, useful 2)

> The documentation I have doesn't cover payroll or commission calculation, so I can't tell you how to do it in this application.
> 
> What it does cover includes the **Users** screen (which records each user sees), the **Sales** list (each user's proposals, with their values and statuses), and general questions in the FAQ. If you tell me what you're trying to find out, such as a rep's accepted proposals, I can explain how to view that.
> 
> Source: [Users](Users.md), [Sales](Sales.md), [FAQ](FAQ.md)

**D1** (3.0 s, useful 2)

> **14 December 2026** (30 days after today, 14 November 2026).
> 
> The documentation doesn't cover proposal validity periods or expiry dates, so I can't say whether the application can record this date on a proposal. I haven't changed anything in the application.

**D2** (3.0 s, useful 1)

> I can't answer that. My job is to help with using this application, and the documentation doesn't cover calling hours or time zones. You'd need to check the customer's local time another way.
> 
> If you need help with the lead itself, I can explain how to use the Lead detail window, such as the Notes field, which saves as you leave it.
> 
> Source: [Lead detail](Lead-Detail.md)

**D3** (5.4 s, useful 1)

> The Leads board doesn't have a month filter, so I can't list them by month. The **New** column shows each lead's **Date Created**, so you can scan those dates for November 2026 ([Leads](Leads.md)). Leads that have moved to another column show that column's date instead, such as Date Contacted, so check the other columns too.
> 
> The board is also filtered by the user selected in the title bar drop-down. If leads seem to be missing, check that it's set to your user ([FAQ](FAQ.md)).

### claude-haiku-5-5/v2

**A1** (3.7 s, useful 1)

> The documentation doesn't cover VAT. It describes the total as the sum of the line items, with no tax rate or tax line. So I can't tell you whether the application adds VAT on its own.
> 
> Whether to show VAT is a question of local rules and your accountant's advice. In general practice, net prices are often shown with VAT added as a separate line to reach the gross total.
> 
> If you need the VAT on the document, the closest option in the application is to add it as its own line item. The total is then the net amount plus the VAT line. I haven't seen this covered in the documentation, so check that the printed proposal looks right before you send it. See [Draft a proposal](Draft-Proposal.md).

**A2** (4.1 s, useful 1)

> The application doesn't have a pipeline value calculation. Its Dashboard shows lead counts by status, and the Sales list shows a value for each proposal, but nothing adds these up into a pipeline total.
> 
> The closest things it offers:
> - The **Dashboard** tiles count your leads by status (New, Active, Proposal Sent, Closed, Inactive). They show how many leads are in each stage, not what they are worth. ([Dashboard](Dashboard.md))
> - The **Sales** list shows the **Value** of each proposal, the total of the invoice as it was when you saved it. You can read these values from the list and add them up yourself. ([Sales](Sales.md))
> 
> In general sales practice, pipeline value is the sum of the expected values of open deals, often weighted by the chance of winning each one. This is standard practice, not a feature of this application, and you would need to do the calculation outside it.

**A3** (3.6 s, useful 2)

> The application doesn't define a time limit for this, so there's no automatic aging or "lost" status to rely on. The threshold is your call. As general practice, set it from your typical sales cycle: if most deals you win close within a few weeks of first contact, a lead that has gone quiet for about twice that long is a reasonable candidate to close.
> 
> In the app, you can check this yourself:
> 
> 1. Open the **Active** column on the Leads board. It shows **Date Contacted**, so you can see how long each lead has been in progress.
> 2. When you decide a lead is finished, drag it to the **Closed** column. That column holds leads that are finished, and it records **Date Closed**. ([Leads](Leads.md))
> 
> Moving a lead to Closed is a separate decision from any proposal outcome, so you control when it happens. ([Leads](Leads.md))

**B1** (4.9 s, useful 1, invented)

> You are already on the right screen. The **Sales** list shows every proposal of the active user, with a **Status** (New, Accepted or Canceled), a **Value**, and the **DateCreated** and **DateCompleted** dates. For a month-end review, sort or scan by DateCompleted for accepted proposals in the month, and check Canceled ones too. ([Sales](Sales.md))
> 
> Limits to keep in mind:
> - The Search box filters on proposal name only, and every proposal is named "New Proposal", so it can't narrow the list to a month or a customer. ([Sales](Sales.md))
> - The documentation describes no sales report, totals or month-end summary, so I can't point you to one. Totals would have to be worked out from the list yourself.
> - The Calendar shows no data, so it won't help with the review. ([Calendar](Calendar.md))
> - To find a specific customer's proposal, open the lead and press View Proposal. ([Sales](Sales.md))

**B2** (4.2 s, useful 1)

> The documentation doesn't cover discounts, so I can't tell you how to apply one in this application.
> 
> What the documentation does say is that a proposal is an invoice with a list of line items and a total, which you fill in, check, and save in the draft window ([Draft a proposal](Draft-Proposal.md)). Once saved, a proposal can't be edited, only accepted or cancelled ([Sales](Sales.md)). So any change for the customer would have to be made before you save.
> 
> As general practice, a 10% discount is usually shown as a reduction on the line items or on the total, so the saved total reflects the price the customer agreed to. Check the draft window to see whether it lets you set the line items or the total that way.

**B3** (4.3 s, useful 1)

> Good practice is to follow up directly: call or email the contact, ask whether they have questions or need changes, and suggest a decision date. If there is still no answer, a short, polite final follow-up is normal. That is general sales practice, not a feature of this application.
> 
> In this application, the lead should be in the **Proposal Sent** column, which means "a proposal is out, waiting for an answer." That column shows the Date Drafted and the Account Name, so you can see how long the proposal has been waiting. ([Leads](Leads.md))
> 
> When the lead responds, drag its row to the column that matches the new status. Moving it to **Active** means it is being worked on again, and moving it to **Closed** finishes it. ([Leads](Leads.md))
> 
> The documentation does not describe any automatic reminder or follow-up scheduling for proposals, so track the follow-up dates yourself, for example in your calendar.

**C1** (3.4 s, useful 2)

> The documentation I have doesn't describe reminders or automatic follow-up rules, so I can't tell you how to set one up.
> 
> The closest thing the application offers is the **Leads** board. Each column shows the date that matters at that stage: the **New** column shows **Date Created**, and the **Active** column shows **Date Contacted**. You can check those dates by eye to spot leads that have gone quiet. The **Search** box filters all columns at once, but the documentation doesn't say whether the board can sort or flag leads by date. ([Leads](Leads.md))
> 
> In general practice, teams often review the board on a fixed day each week and follow up on any lead whose last contact is older than their target window. That's a common approach, not a feature of this application.

**C2** (5.0 s, useful 1)

> The application has no sales forecast or quarterly report, and the documentation doesn't describe one. I can't build one here.
> 
> The closest thing is the **Sales** screen, which lists every proposal of your user with its Status, Value and DateCompleted. To work out a quarter by hand:
> 
> 1. Open the **Sales** screen.
> 2. Read the proposals with Status **Accepted**, and group their Value by the quarter of DateCompleted.
> 3. Treat proposals with Status **New** as open drafts, and leave out **Canceled** ones.
> 
> Two things to watch: DateCompleted is stamped only when a proposal is marked Accepted, and Cancel leaves that date unchanged, so filter by Status first. The Search box filters only on proposal name, which is always "New Proposal", so it won't help narrow the list.
> 
> Source: [Sales](Sales.md)

**C3** (2.1 s, useful 2)

> I can't help with payroll calculation, since it's outside what this application covers. I can help with the sales side, such as reviewing a representative's accepted proposals on the Sales screen.
> 
> Source: [Sales](Sales.md)

**D1** (4.1 s, useful 2)

> **14 December 2026** (30 days from 14 November 2026).
> 
> The application has no validity or expiry field for proposals. The draft only includes the company name, today's date, the address, city, zip and phone boxes, the line items, the total, and a thank-you line. The documentation doesn't say whether the expiry can be written into the document, so I can't confirm how to show it to the customer. The Sales list records when a proposal was saved (DateCreated) and when it was accepted (DateCompleted), but nothing in the application tracks a deadline.
> 
> Source: [Draft a proposal](Draft-Proposal.md)

**D2** (5.9 s, useful 2)

> It's currently about **9:51 a.m. in New York** (Saturday, 14 November), so the time itself isn't too late. Calling on a Saturday is less usual in B2B sales unless you know the customer works weekends. As a general rule, weekday business hours in the customer's time zone are the safest choice.
> 
> This application doesn't cover time zones or call timing. The Calendar can't be used to schedule calls either, since appointments can't be added there. If you want to remember to call, you could write it in the lead's **Notes** field.

**D3** (4.1 s, useful 1)

> The documentation doesn't describe a way to filter leads by creation date or a monthly report, so I can't list this month's leads directly.
> 
> The closest option is the **New** column on the [Leads](Leads.md) board. It shows each lead's Date Created and Name, so you can read off the leads still in New that were created in November 2026. Leads that have moved to Active, Proposal Sent or Closed show other dates in those columns, and the documentation doesn't say their creation date is shown.
> 
> Also, most lists are filtered by the user selected in the title bar, so check that it's your user. Otherwise some leads won't appear ([FAQ](FAQ.md)).

### claude-opus-5-5/v1

**A1** (5.6 s, useful 1)

> The documentation doesn't say anything about **VAT or tax** in a proposal. I can't tell you whether you should add it, because that's a tax and accounting question, not a question about how to use the app.
> 
> Here's what the documentation does say about proposals:
> 
> - Each line item has only a **title**, a **quantity** and a **price per row**.
> - **Total** is recalculated every time a line item changes.
> - When you press **Save Proposal**, that total is saved as the proposal's value and shown in the **Value** column on the Sales screen.
> 
> ([Draft a proposal](Draft-Proposal.md), [Sales](Sales.md))
> 
> The documentation doesn't mention a VAT rate, a tax field or any setting for net vs. gross prices. If you need VAT on a proposal, the documentation doesn't explain how to add it.

**A2** (4.0 s, useful 1)

> The documentation doesn't describe a way to calculate a total pipeline value. No screen is documented as adding up proposal values.
> 
> Here's what the documentation does cover:
> 
> - **Sales** lists every proposal of the active user. Each row has a **Value** column, which is the invoice total at the time the proposal was saved. Its **Status** column shows `New`, `Accepted` or `Canceled`. ([Sales](Sales.md))
> - **Dashboard** shows lead counts by status, such as Proposal Sent. It shows how many leads there are, not their monetary value. ([Dashboard](Dashboard.md))
> 
> You could look through the **Value** column on the Sales screen yourself, but the documentation doesn't mention any built-in total or pipeline calculation.

**A3** (4.1 s, useful 1)

> The documentation doesn't answer that. It doesn't give a time limit for leads in **Active**, and it doesn't have a "lost" status. When to give up on a lead is your call.
> 
> Here's what the [Leads](Leads.md) page does say:
> - The **Active** column shows each lead's **Date Contacted**. You can use it to see how long a lead has been in progress.
> - The last column is **Closed**, which just means "Finished." To close a lead, drag it to that column. Its **Date Closed** gets filled in.

**B1** (5.9 s, useful 1)

> For a month-end review, use the **Sales** screen, which you're already on. It lists every proposal of the active user in one grid ([Sales](Sales.md)). These columns are the useful ones:
> 
> - **Status**: `New` when saved, then `Accepted` or `Canceled`.
> - **Value**: the invoice total at the moment the proposal was saved.
> - **DateCreated**: when the proposal was saved.
> - **DateCompleted**: when it was accepted.
> - **LeadId**: which lead the proposal was for.
> 
> **Limits to keep in mind:**
> - The **Search** box only filters on the proposal name. Every proposal is called `New Proposal`, so you can't use it to narrow the list by month or by customer ([Sales](Sales.md)).
> - The **Calendar** screen won't help. It shows no proposal or completion dates, and selecting a day filters nothing ([Calendar](Calendar.md)).
> - To read a particular customer's proposal, open their lead on the **Leads** board and press **View Proposal**. The grid's document column only shows `(OBJECT)` ([Known limitations](ToDo.md)).
> 
> The documentation doesn't mention any monthly report, date filter or total. To review a month, you'll need to read the dates and values in the Sales grid yourself.

**B2** (4.3 s, useful 1)

> The documentation doesn't mention a discount option for proposals, so I can't tell you how to apply one.
> 
> Here's what it does say:
> 
> - **A saved proposal can't be edited or reprinted.** You can only accept it or cancel it ([Known limitations](ToDo.md)). That means you can't add a discount to a proposal that's already saved.
> - **A proposal is an invoice** made of a header, a list of line items, a total and a thank-you line. You fill it in from **Create Proposal** in the lead detail window, and **Save Proposal** stores the total as the proposal's value ([Draft a proposal](Draft-Proposal.md)).
> - **A lead can have only one proposal.** The documentation doesn't say what happens if you try to create a second one for the same lead, so I can't say whether you could cancel the old proposal and write a new one with lower prices.

**B3** (4.4 s, useful 1)

> The manual doesn't give advice on following up an unanswered proposal, and it doesn't describe reminders or follow-up tasks. It only covers how a lead moves across the board:
> 
> - **While you wait**, the lead stays in the **Proposal Sent** column. That column shows its **Date Drafted**, so you can see how long the proposal has been out.
> - **When it's finished**, drag the row to the **Closed** column. The lead's status changes to Closed. If **Date Closed** is still empty, it's filled in with the current date and time. A date that already has a value isn't changed.
> - **About Inactive:** there is also an **Inactive** status, but it has no column on the board. Inactive leads are only counted on the Dashboard. The manual doesn't say how to set a lead to Inactive.
> 
> See [Leads](Leads.md).

**C1** (3.5 s, useful 2)

> The documentation doesn't mention automatic reminders or notifications for leads, so I can't tell you how to set one up. I don't know whether the application can do it.
> 
> The documentation does describe how you can check this yourself on the Leads board ([Leads](Leads.md)):
> - The **New** column holds leads nobody has called yet. It shows each lead's **Date Created**.
> - The **Active** column holds leads being worked on. It shows each lead's **Date Contacted**.
> 
> You can look through those dates to find leads that have gone quiet for 30 days or more.

**C2** (3.4 s, useful 1)

> I can't make one. The documentation doesn't describe any forecast or quarterly report in this application, and I have no tool that can build one.
> 
> What the **Sales** screen does have is a list of all your proposals. For each proposal you can see its `Status` (New, Accepted or Canceled), its `Value` (the invoice total when it was saved), `DateCreated` (when it was saved) and `DateCompleted` (when it was accepted). The documentation doesn't mention any way to group, total or export that list by period. [Sales](Sales.md)

**C3** (2.3 s, useful 2)

> The documentation doesn't cover payroll, so I can't tell you how to calculate it in this application. Nothing in the documentation describes a payroll, salary or commission feature.

**D1** (7.6 s, useful 2)

> If the 30 days start today (Saturday, 14 November 2026), the proposal is valid until **Monday, 14 December 2026**.
> 
> The application doesn't track how long a proposal is valid. The [Sales](Sales.md) list has no expiry column. It only records `DateCreated` (when the proposal was saved) and `DateCompleted` (when it was accepted). You'll need to keep track of the deadline yourself.

**D2** (5.2 s, useful 2)

> No, it's not too late. It's **about 9:52 in the morning** in New York right now. New York is on Eastern Standard Time (UTC−5), six hours behind you. It's **Saturday**, though, so a business customer may not be in the office.
> 
> You'll need to call from your own phone. The **Call** button next to the phone number on the Lead Detail screen doesn't do anything yet. It's only a placeholder ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md)). After the call, you can write down how it went in the lead's **Notes**. Notes are saved as soon as you leave the field.

**D3** (4.9 s, useful 1)

> I can't look up your leads for you, and the documentation doesn't describe any way to filter or search leads by creation date.
> 
> Here's what the [Leads](Leads.md) board shows:
> 
> - **New** column: shows **Date Created**, so you can check the dates there for leads nobody has called yet.
> - **Active**, **Proposal Sent** and **Closed** columns: show a different date for each stage (Date Contacted, Date Drafted and Date Closed). Once a lead leaves **New**, the board no longer shows when it was created.
> 
> Also, the board only shows records for the user picked in the drop-down in the title bar. If leads seem to be missing, check that it's set to the user who owns them ([FAQ](FAQ.md)).

### claude-opus-5-5/v2

**A1** (9.5 s, useful 2)

> **In general B2B practice** (not something this application decides), a proposal usually shows net prices, the VAT amount and the gross total. That way the customer sees exactly what they will pay. Whether VAT applies, and at what rate, depends on your country and the customer's (for example, reverse charge between EU businesses). Check with your accountant.
> 
> **In this application** the documentation doesn't describe any VAT or tax field. Each line item has only a **title, quantity and price**, and the **Total** is calculated from the line items ([Draft a proposal](Draft-Proposal.md)).
> 
> If you want VAT on the document, the closest you can do is add it as a line item yourself:
> 1. In the draft proposal, click **+** to add a row.
> 2. Type a title such as `VAT 22%`. Titles can be up to 20 characters ([Data model](Data-Model.md)).
> 3. Set the quantity to `1` and the price to the VAT amount, which you calculate yourself, then click **✓** to confirm the row.
> 
> Keep in mind that the proposal's **Value** on the Sales screen is the invoice total at the moment you save ([Sales](Sales.md)). If you add a VAT row, that value will include VAT. If you leave it out, the value stays net. Choose one way and use it on every proposal so your sales figures are comparable.

**A2** (6.6 s, useful 2)

> The documentation doesn't describe a report or total that calculates pipeline value. The closest thing the app has is the **Sales** screen, where you can add up the values yourself.
> 
> **In general practice** (not specific to this app), pipeline value is the total of all open deals. Some teams also calculate a *weighted* pipeline by multiplying each deal by its chance of closing.
> 
> **To add up your open proposals in this app:**
> 1. Open **Sales**. It lists every proposal for the active user ([Sales](Sales.md)).
> 2. Find the proposals with status **New**. These are proposals you've saved but that haven't been accepted or canceled yet, so they're your open pipeline. **Accepted** proposals are won, and **Canceled** ones are lost.
> 3. Add up the **Value** column for those proposals. Keep in mind that each value is the invoice total at the moment you saved the proposal. If you changed the invoice later, the list won't show the change.
> 
> **Limitations to know about:**
> - The **Search** box only filters by proposal name, and every proposal is named "New Proposal." So you can't use it to filter by status or customer ([Sales](Sales.md)).
> - The **Dashboard** tiles count your *leads* by status, such as **Proposal Sent**. They show how many deals are in each stage, not how much they're worth ([Dashboard](Dashboard.md)).
> - The numbers on both screens are only for the user selected in the drop-down in the title bar.

**A3** (8.8 s, useful 2, invented)

> The application doesn't set a time limit for this. Nothing in the documentation describes automatic aging or reminders. There's also no separate "Lost" status: the board has four columns (**New**, **Active**, **Proposal Sent**, **Closed**), and **Closed** just means "Finished", whether the lead was won or lost.
> 
> **What the app does give you:** the **Active** column shows each lead's **Date Contacted**, so you can see at a glance how long it's been since first contact. That date is kept when you move a lead back and forth, so it stays reliable. When you decide a lead is dead, drag it to **Closed**. Since that column doesn't separate won from lost, it helps to note the reason on the lead (for example "Lost – no budget") so you can tell them apart later. [Leads](Leads.md)
> 
> **General sales practice (not a feature of this app):**
> - **Base the limit on your sales cycle.** If deals usually take about 30 days from first contact to proposal, a lead still in Active after 2–3 times that (60–90 days) without progress is usually stalled.
> - **Count attempts as well as days.** Many teams treat a lead as lost after 5–8 contact attempts over 2–4 weeks with no reply, whatever the calendar says.
> - **Send a "breakup" message first.** A short note like "Should I close your file?" often gets a reply, or at least a clear no.
> - **Use one rule for everyone**, so your pipeline reports aren't inflated by leads nobody is working anymore.
> 
> A simple habit: check the Active column every week, sorted by Date Contacted, and decide on anything older than your limit.

**B1** (7.5 s, useful 1)

> The best place is the **Sales** screen you're on now. The application has no dedicated report or month-end summary. Sales lists all of your proposals in one grid, and these columns are the useful ones for a review:
> 
> - **Status**: `New` (still open), `Accepted` or `Canceled`
> - **Value**: the invoice total at the moment the proposal was saved
> - **DateCreated** / **DateCompleted**: when the proposal was saved and when it was accepted
> - **LeadId**: which lead the proposal belongs to
> 
> **What it can't do:**
> - The documentation doesn't describe a way to filter the grid by date or status. The **Search** box only filters on the proposal name, and every proposal is named `New Proposal`, so it won't help here. You'll need to read the dates in the grid yourself.
> - **DateCompleted** isn't changed when a proposal is canceled, so that column won't tell you when a cancellation happened.
> - To see which customer a proposal belongs to, open the lead from the **Leads** board and press **View Proposal**.
> - The **Calendar** shows no sales data, so it's no help for this.
> 
> ([Sales](Sales.md), [Known limitations](ToDo.md), [Calendar](Calendar.md))
> 
> **What a month-end review usually covers** (general sales practice, not features of this app):
> 1. **Closed won**: proposals accepted this month (here, `Accepted` with a **DateCompleted** in the month) and their total value.
> 2. **Lost**: proposals canceled, and if possible why.
> 3. **Open pipeline**: proposals still `New`, especially old ones that need a follow-up.
> 4. **Win rate**: accepted proposals divided by all proposals decided in the month.

**B2** (6.7 s, useful 1)

> The documentation doesn't mention a **discount** option for proposals, so I can't tell you how to apply one in this application.
> 
> Here's what the documentation does say:
> 
> - A proposal is an invoice with the customer's address, **line items**, a **total** and a thank-you line. You fill it in from **Create Proposal** in the lead detail window and save it with **Save Proposal**. The saved total becomes the proposal's **Value**. ([Draft a proposal](Draft-Proposal.md))
> - **A saved proposal can't be edited or reprinted.** You can only accept it or cancel it. ([Known limitations](ToDo.md))
> - **A lead can have only one proposal.** The documentation doesn't fully explain what happens if you ask for a second one. ([Draft a proposal](Draft-Proposal.md))
> 
> So if the proposal is already saved, you can't change it to add the discount. On the **Sales** screen you can select it and press **Cancel**, which sets its status to Canceled. The documentation doesn't say whether you can then draft a new proposal for the same lead.
> 
> **General sales practice** (not a feature of this app): a discount is usually shown on its own line or in a note, so the customer can see the original price and the 10% reduction. Before agreeing, sales teams often ask for something in return, such as a faster signature or a larger order.

**B3** (8.0 s, useful 1)

> **What to do (this is general sales practice, not something the application does for you):**
> 
> 1. **Follow up now.** After two weeks with no answer, call rather than e-mail again. Ask a simple question, for example whether the proposal reached the right person or whether anything in it needs to change.
> 2. **Find out what's holding it up.** Common reasons are budget, timing, a missing decision-maker or a competing offer. Offer to go through the proposal together, or to adjust its scope.
> 3. **Agree on a next step and a date,** such as a meeting, a revised proposal or a decision deadline, so the deal keeps moving.
> 4. **If they still don't reply after two or three tries,** send a polite closing message saying you'll assume the timing isn't right. This often gets a reply. If it doesn't, stop actively pursuing the deal.
> 
> **In this application:**
> - The lead stays in the **Proposal Sent** column. That column shows **Date Drafted**, so you can see how long the proposal has been waiting.
> - When the deal ends, whether you won or lost it, drag the lead to the **Closed** column. It gets the Closed status, and **Date Closed** is filled in with the current time if it was empty.
> - There is also an **Inactive** status, but the board has no column for it, so you can't drag a lead there. Inactive leads are only counted on the Dashboard.
> 
> The documentation I have doesn't describe follow-up reminders or tasks for leads. If you plan to use the **Calendar** screen to schedule your follow-up, I can't tell you how it works from these pages.
> 
> Source: [Leads](Leads.md)

**C1** (5.3 s, useful 1)

> The documentation I have doesn't mention any automatic reminders or alerts for leads, so I can't tell you how to set one up. I don't know whether the application can do this.
> 
> The closest thing it has is the **Leads** board, where each column shows the date that matters at that stage ([Leads](Leads.md)):
> 
> - **New** column: shows **Date Created**. Leads here haven't been called yet, so any that are more than 30 days old have never been contacted.
> - **Active** column: shows **Date Contacted**, so you can scan it for leads last contacted more than 30 days ago.
> 
> As a general sales habit (not a feature of this app), it helps to check these columns at a set time each week. Plan the next follow-up as soon as you finish each call, so leads don't go quiet without anyone noticing.

**C2** (7.0 s, useful 2)

> I can't make a quarterly forecast for you. The application has no forecast or quarterly report, and none of my tools can read or total your proposals.
> 
> **What the app has that comes closest:**
> - **The Sales screen** lists all your proposals. Each one shows its **Value** (the invoice total when you saved it), its **Status** (`New`, `Accepted` or `Canceled`), **DateCreated**, and **DateCompleted** (the date you pressed **Complete**). [Sales](Sales.md)
> - **The Dashboard** has one tile for each lead status. Each tile counts how many of your leads have that status. [Data model](Data-Model.md)
> 
> **How you could build a rough forecast yourself:**
> 1. Go through the Sales list.
> 2. Add up the **Value** of `New` proposals. These are your open pipeline.
> 3. Add up the **Value** of `Accepted` proposals, grouped by the quarter of their **DateCompleted**. These are sales you've already won.
> 
> **General sales practice (not a feature of this app):** A forecast is usually a *weighted pipeline*. You multiply each open deal's value by how likely it is to close at its stage, such as proposal sent or negotiating. Then you group the results by the quarter you expect each deal to close. Proposals here have no expected close date or probability field, so you'd have to judge those yourself, for example in a spreadsheet.

**C3** (3.2 s, useful 2)

> I can't help with payroll, because that's an HR and accounting task. This application doesn't cover it, and neither does my role here, which is helping with sales and customer management in this app.
> 
> Source: [Sales](Sales.md)

**D1** (9.5 s, useful 2)

> Counting 30 days from today, Saturday 14 November 2026, the proposal is valid **until Monday 14 December 2026**.
> 
> **Where to write that date:** the documentation doesn't describe any validity or expiry field on a proposal. The draft window only has:
> - the company name and today's date, which are filled in for you
> - three empty boxes for street address, city/state/zip and phone
> - the line items (title, quantity, price)
> 
> See [Draft a proposal](Draft-Proposal.md).
> 
> The application also doesn't track expiry dates for you. Once a proposal is saved, it can't be edited ([Known limitations](ToDo.md)). So if you need the validity date on the document, decide where to put it before you press **Save Proposal**.
> 
> As a general sales practice (not a feature of this app), it's best to state the validity period on the proposal itself. Set yourself a reminder to follow up with the customer before the date passes.

**D2** (5.4 s, useful 2)

> It's not too late, but it's Saturday there too. It's **about 9:54 a.m. in New York** (EST, UTC−5, six hours behind you).
> 
> As general B2B practice, not something this app handles, avoid cold or routine calls to business contacts on weekends. Unless the customer asked you to call on a Saturday, it's usually better to wait until **Monday morning their time**. For you, mid-morning in New York is roughly 3–5 p.m.
> 
> When you do call, dial the number yourself. The **Call** button next to the phone number on this screen doesn't do anything yet ([Lead detail](Lead-Detail.md), [Known limitations](ToDo.md)). You can type a reminder in the lead's **Notes**, which saves as soon as you leave the field.

**D3** (4.9 s, useful 2)

> I can't look at your leads for you. My tools can only open screens and create leads, so they can't list or filter records.
> 
> On the **Leads** board you can check this yourself:
> 
> - The **New** column shows a **Date Created** for each lead, so you can see which of those leads were created in November 2026.
> - Once a lead moves on, its column shows a different date instead. **Active** shows Date Contacted, **Proposal Sent** shows Date Drafted and **Closed** shows Date Closed. For those leads, the board doesn't show when they were created ([Leads](Leads.md)).
> 
> The documentation doesn't mention a date filter or a "leads created this month" report. I can't promise this application has one.
> 
> Also, nearly every list is filtered by the **user drop-down** in the title bar. You'll only see leads owned by the user selected there. In the sample data, the owner is `CRMUser` ([FAQ](FAQ.md)).

### gemini-pro-latest/v1

**A1** (11.3 s, useful 1)

> The provided documentation does not cover whether or how to add VAT to a proposal.

**A2** (5.3 s, useful 1)

> The documentation does not cover how to calculate the value of the sales pipeline.
> 
> Source: [Sales](Sales.md)

**A3** (5.8 s, useful 1)

> The documentation does not specify how long a lead should stay in the Active column before being considered lost. It only mentions that the Active column means the lead is currently "Being worked on" (Source: [Leads](Leads.md)).

**B1** (8.7 s, useful 1)

> You are already on the right screen! The **Sales** screen lists every proposal of the active user in one list, making it the best place to review your sales. You can check the `DateCreated`, `DateCompleted`, `Status`, and `Value` columns for your review.
> 
> Please note that there is no dedicated month-end filtering feature. The application's **Calendar** only shows a month view and cannot be used to filter your sales by date.
> 
> Sources: [Sales](Sales.md), [Calendar](Calendar.md)

**B2** (5.1 s, useful 1)

> According to the documentation, a saved proposal cannot be edited; it can only be accepted or cancelled ([Known limitations](ToDo.md)). Therefore, it is not possible to change an existing proposal to apply a discount.

**B3** (7.0 s, useful 1)

> The documentation does not cover what action you should take when a lead has not answered a proposal for a specific amount of time. It only describes the statuses available in the application (New, Active, Proposal Sent, Closed, and Inactive) and how to move leads between them on the board.
> 
> Source: [Leads](Leads.md)

**C1** (3.8 s, useful 1)

> The provided documentation does not cover setting up automatic reminders for leads.
> 
> Source: [Leads](Leads.md)

**C2** (5.4 s, useful 1)

> I am sorry, but the documentation does not mention any feature to create a sales forecast by quarter. I cannot help you with that.
> 
> Source: [Sales](Sales.md)

**C3** (5.4 s, useful 2)

> The provided documentation does not cover how to calculate the payroll of a sales representative.
> 
> Source: [Sales](Sales.md)

**D1** (5.4 s, useful 2)

> This proposal will be valid until Monday, 14 December 2026.

**D2** (7.3 s, useful 2)

> Right now it is 09:55 AM (Saturday) in New York, so it is not too late in the day. 
> 
> However, please keep in mind that if you are trying to call them directly through the application, the **Call** button next to the phone number is just a placeholder and does not actually do anything (Source: [Lead detail](Lead-Detail.md)).

**D3** (4.9 s, useful 1)

> I am sorry, but the documentation does not cover how to filter or find leads created specifically this month.
> 
> Source: [Leads](Leads.md)

### gemini-pro-latest/v2

**A1** (8.5 s, useful 2)

> In B2B sales, it is standard practice to quote net prices and add VAT as a separate element so the customer clearly sees the tax and the final gross amount.
> 
> In this application, however, there is no automatic tax calculation or dedicated VAT field. The total of your proposal is simply the sum of the line items in the grid. To include VAT, you will need to calculate the tax amount yourself and add it as an extra line item (for example, with a quantity of 1 and the tax amount as the price) using the **+** button under the grid ([Draft a proposal](Draft-Proposal.md)).

**A2** (9.4 s, useful 2)

> In general B2B sales practice, the value of a sales pipeline is calculated by summing up the monetary value of all open deals, often weighted by their probability of closing. 
> 
> However, this application does not have a built-in feature or report to automatically calculate the total value of your sales pipeline. 
> 
> The closest thing it has is the **Sales** screen, which displays a list of your proposals. You can see the individual amount for each deal in the `Value` column, which shows the total of the invoice as it was when you saved it ([Sales](Sales.md)). To get the total value of your pipeline, you would need to manually add up the values of your active proposals from this list. 
> 
> Please note that the **Dashboard** only counts the number of leads you have by status, but it does not track or display their financial value ([Dashboard](Dashboard.md)).

**A3** (10.0 s, useful 1)

> In general B2B sales practice, how long a lead remains active depends on your typical sales cycle. Often, if a lead has shown no meaningful engagement—such as replying to emails or answering

**B1** (9.6 s, useful 1)

> In general B2B sales practice, a month-end review involves analyzing won and lost deals, total revenue generated, and overall performance against your targets for that month. 
> 
> In this application, you are already on the right screen to do this: the **Sales** screen. It displays every proposal you have written in one list. 
> 
> To review your month, you will need to manually look through this list:
> 1. Check the **DateCompleted** column to find the proposals closed this month.
> 2. Look at the **Status** column to see which ones are "Accepted".
> 3. Review the **Value** column to see the total invoice amounts.
> 
> **Note on limitations:** This application does not have dedicated reporting features or date filters. 
> * The Search box on this screen only filters by proposal name, which is always "New Proposal" ([Sales](Sales.md)). 
> * The **Calendar** screen does not display any sales data or allow you to filter records by date ([Calendar](Calendar.md)). 
> 
> Therefore, a manual review of the list on your current screen is the only way to perform your month-end check.

**B2** (7.8 s, useful 1)

> In this application, a saved proposal cannot be edited; it can only be accepted or canceled. Therefore, you cannot open an existing proposal to apply a discount to it. 
> 
> Source: [Known limitations](ToDo.md)
> 
> In general B2B sales practice, if a customer negotiates a discount after a proposal is sent, you would cancel the original proposal and issue a new, revised one reflecting the discounted prices in the line items.

**B3** (10.2 s, useful 1)

> As a general B2B sales practice, you should reach out to them: send a brief, polite follow-up email or make a phone call to check if they have any questions about the proposal or if their timeline has changed. 
> 
> In this application, the lead stays in the **Proposal Sent** column while you are following up. If they decline the proposal or remain completely unresponsive and

**C1** (7.3 s, useful 1)

> Setting up automatic reminders for aging leads is a great general CRM practice to ensure no prospects slip through the cracks and your pipeline stays warm. 
> 
> However, this application does not have a feature for automatic reminders or time-based alerts. 
> 
> As the closest alternative, you can regularly monitor the **New** tile on the [Dashboard](Dashboard.md) to see leads that nobody has contacted yet, or review the **Active** column on the [Leads](Leads.md) board to manually check which leads are currently being worked on and might need a follow-up.

**C2** (6.8 s, useful 2)

> Sales forecasting by quarter is a standard practice in sales management used to estimate future revenue based on your current pipeline and historical data. 
> 
> However, this application does not have a built-in sales forecasting feature or a quarterly reporting tool. 
> 
> The closest alternative is to review your current pipeline on the **Sales** screen. This screen lists every proposal you have created, along with its **Status** (New, Accepted, or Canceled), **Value**, and the **DateCreated** and **DateCompleted** (Source: [Sales](Sales.md)). You can use this list to manually review your upcoming and closed deals to estimate your expected revenue.

**C3** (15.2 s, useful 1)

> This application does not have a feature to calculate payroll or sales commissions. 
> 
> In general B2B sales practice, calculating a sales representative's payroll—especially their commission—is typically handled in dedicated accounting or HR software, using the total value of closed-won deals. While this application does not calculate the payroll for you, you can find the total invoice value of each accepted proposal in the **Sales** list. You can use this information to perform the calculations manually or input the figures into your external payroll system.
> 
> Source: [Sales](Sales.md)

**D1** (7.8 s, useful 2)

> Thirty days from today (14 November 2026) is **14 December 2026**.
> 
> In general B2B sales practice, adding a validity date to a proposal is highly recommended to protect you against future price changes and to create a sense of urgency for the client. 
> 
> However, please note that in this application there is no specific field to set a validity date. The proposal draft automatically takes today's date and allows you to fill in only the customer's address and the line items.
> 
> Source: [Draft a proposal](Draft-Proposal.md)

**D2** (10.4 s, useful 1)

> I cannot check the current time in New York, as my expertise is limited to B2B sales practices and helping you use this application.

**D3** (7.7 s, useful 1)

> The application does not have a specific filter or report to show only the leads created this month. 
> 
> The closest thing you can do is check the **New** column on the Leads board, which displays the **Date Created** next to the name for leads that nobody has called yet (Source: [Leads](Leads.md)). To make sure you are only looking at your own leads, ensure your name is selected in the user drop-down in the title bar, as this filters the records on the board (Source: [FAQ](FAQ.md)).

### gpt-6.1-sol/v1

**A1** (3.6 s, useful 1)

> The documentation doesn’t say whether you should charge VAT or how to add it. It describes line items with a title, quantity, and price, but no VAT field or tax calculation. See [Draft a proposal](Draft-Proposal.md).
> 
> Don’t assume VAT will be added automatically to your net prices.

**A2** (2.8 s, useful 1)

> The documentation does not describe a calculation for total sales pipeline value.
> 
> The **Dashboard** shows lead counts, not monetary values. **Sales** lists each proposal’s **Value**, which is the invoice total when it was saved, and its status: New, Accepted, or Canceled. It does not document a pipeline-value total or which statuses to include. [Dashboard](Dashboard.md) · [Sales](Sales.md)

**A3** (2.8 s, useful 1)

> The documentation doesn’t specify how long a lead should stay in **Active** or when to consider it lost. It defines Active only as “Being worked on” and Closed as “Finished.” You can move a lead to Closed by dragging it into that column. [Leads](Leads.md)

**B1** (3.3 s, useful 1)

> Start on **Sales**, where you are now. It lists every proposal for your active user, including **Status**, **Value** (the invoice total when saved), **DateCreated**, and **DateCompleted** (when accepted). These are the fields to review for month-end. [Sales](Sales.md)
> 
> To read a customer’s proposal, open their lead and press **View Proposal**. The Sales search only filters proposal names—not customers. [Sales](Sales.md)
> 
> The **Calendar** won’t help with the review: it shows no lead, proposal, or completion dates, and selecting a day filters nothing. [Calendar](Calendar.md)

**B2** (2.7 s, useful 1)

> If the proposal is already saved on **Sales**, you can’t apply the discount: saved proposals cannot be edited, only accepted or cancelled. [Known limitations](ToDo.md)
> 
> If you’re still drafting it, the provided documentation doesn’t explain how to apply a percentage discount.

**B3** (2.6 s, useful 1)

> If you mean what to do in the app, **Proposal Sent** is the status for a proposal that is out and waiting for an answer. The documentation does not specify a follow-up action or an automatic status change after two weeks. [Leads](Leads.md)

**C1** (2.0 s, useful 2)

> The provided documentation doesn’t cover automatic reminders or a rule for leads not contacted for 30 days, so I can’t give you setup steps.
> 
> For manual review, the **Active** column on the Leads board displays **Date Contacted**, which can help you identify leads needing follow-up. [Leads](Leads.md)

**C2** (3.0 s, useful 1)

> The documentation does not describe quarterly sales forecasting, so I can’t generate that in this application. The **Sales** screen lists your proposals with their status, saved invoice value, and creation and completion dates. [Sales](Sales.md)

**C3** (2.2 s, useful 2)

> The provided documentation does not cover payroll or sales-representative pay calculations. The **Users** screen manages record-owner labels and visibility filters—not employee payroll. [Users](Users.md)

**D1** (4.3 s, useful 1)

> The documentation doesn’t cover proposal validity periods or expiry-date calculations, so I can’t confirm a valid-until date from it.

**D2** (2.2 s, useful 1)

> The provided documentation doesn’t cover calling hours or whether it’s too late to call a customer in New York. If you mean the **Call** button on this Lead Detail screen, it’s only a placeholder and won’t place a call. [Lead detail](Lead-Detail.md)

**D3** (2.4 s, useful 1)

> The provided documentation doesn’t describe a way to list leads you created this month. On the **Leads** board, the **New** column shows **Date Created** and **Name**; later stages show other dates. [Leads](Leads.md)
> 
> Also, nearly every list is filtered by the user selected in the title bar, so check that your user is selected. [FAQ](FAQ.md)

### gpt-6.1-sol/v2

**A1** (3.1 s, useful 2)

> If VAT applies to your sale, the general practice is to show it separately from net prices; whether it applies and at what rate depends on your tax rules.
> 
> In this application, the proposal documentation describes line items with a title, quantity and price, but **no VAT field or automatic tax calculation**. The closest documented workaround is to calculate VAT yourself and add a separate line item titled `VAT`, with quantity `1` and the calculated tax amount as its price. Use **+** beneath the line-item grid to add it; the total updates when line items change. [Draft a proposal](Draft-Proposal.md)

**A2** (3.6 s, useful 2)

> In general sales practice, **pipeline value** is the sum of the potential deal values for all open opportunities. A **weighted pipeline** multiplies each deal’s value by its estimated probability of winning, then adds the results.
> 
> In this application, **Sales** lists your proposals with a **Value** column—the invoice total when each proposal was saved—and a **Status** of New, Accepted, or Canceled. Those values can help you calculate a proposal-stage total manually; exclude Accepted and Canceled proposals when assessing open proposals. [Sales](Sales.md)
> 
> The documentation does not describe an automatic pipeline-value total or probability weighting. The Dashboard shows **lead counts, not monetary values**. [Dashboard](Dashboard.md)

**A3** (3.6 s, useful 2)

> **General sales practice—not an application rule:** review an Active lead after **2–4 weeks without meaningful engagement**. Consider it lost when the prospect declines, is no longer a fit, or stays unresponsive after several spaced follow-ups. For longer sales cycles, use the agreed next step and buying timeline rather than a fixed deadline.
> 
> In this application, **Active** means “being worked on”; the documentation gives no time limit or separate Lost status. When you decide the lead is finished, drag it to **Closed**. [Leads](Leads.md)

**B1** (3.8 s, useful 1)

> Start on **Sales**, where you are now: it lists every proposal belonging to the active user, including its **Status**, **Value**, **DateCreated**, and **DateCompleted**. Value is the invoice total when saved; DateCompleted records when the proposal was accepted. [Sales](Sales.md)
> 
> For a month-end review, general sales practice is to distinguish proposals **created during the month** from those **accepted during the month**. The documentation does not describe a monthly report, date filter, or automatic totals on this screen. Its Search box filters only by proposal name. [Sales](Sales.md)
> 
> The **Calendar** won’t help with the review: it displays no lead or proposal data and cannot filter sales by date. [Calendar](Calendar.md)

**B2** (3.1 s, useful 1)

> **If the proposal is already saved, you can’t edit it to apply a 10% discount.** Saved proposals can only be accepted or cancelled—not edited or reprinted. [Known limitations](ToDo.md)
> 
> The closest available action is to select it on **Sales** and click **Cancel**. This immediately marks it Canceled, with no confirmation; it does not change the amount. [Sales](Sales.md)
> 
> If you’re still drafting it, the provided documentation doesn’t explain how to apply a discount. As general sales practice, agree whether the 10% applies to the whole proposal or only specific items before finalising the price.

**B3** (4.3 s, useful 1)

> **As general sales practice**, follow up now with a brief, helpful message: ask whether the proposal still fits their needs, whether anything is blocking a decision, and suggest a short call.
> 
> For example:
> “Hi [Name], I’m following up on the proposal I sent two weeks ago. Is this still a priority, or has anything changed? Happy to answer questions or arrange a quick call to agree on next steps.”
> 
> In this application, **Proposal Sent** means a proposal is out and awaiting an answer, so that remains the appropriate column while you wait. Two weeks of silence alone needn’t mean the opportunity is finished. [Leads](Leads.md)

**C1** (3.5 s, useful 2)

> The provided documentation doesn’t describe automatic reminders or a rule for leads not contacted in 30 days, so I can’t give you setup steps.
> 
> The closest documented option is to review the **Active** column on your Leads board, which shows **Date Contacted**. The **New** column holds leads nobody has called yet and shows **Date Created**. These dates can help with a manual follow-up review, but the excerpts don’t confirm that Date Contacted tracks the most recent contact. [Leads](Leads.md)

**C2** (3.3 s, useful 2)

> I can’t generate a quarterly sales forecast with the documented features. The **Sales** screen lists your proposals, their values, statuses, and creation/completion dates, but no forecasting report is documented. [Sales](Sales.md)
> 
> As general sales practice—not an application feature—a quarterly forecast groups expected deals by closing quarter and weights their values by the likelihood of winning. The documented proposal data lacks expected closing dates and win probabilities.

**C3** (4.2 s, useful 1)

> The provided documentation does not cover payroll calculation or a payroll feature. **Users** are only record-owner labels and filters—not employee payroll profiles. [Users](Users.md)
> 
> As general sales-management practice, a representative’s pay may include base salary plus commissions or bonuses under their compensation plan; payroll deductions depend on local rules. Are you trying to calculate **sales commission** or their full payroll?

**D1** (2.4 s, useful 2)

> The proposal is valid until **14 December 2026**, 30 days from today (14 November 2026).

**D2** (3.8 s, useful 2)

> It’s **9:58 a.m. on Saturday in New York**—not too late in the day, but outside normal business hours.
> 
> As general B2B sales practice, I’d wait until Monday unless the customer expects your call or has said weekends are fine.

**D3** (3.1 s, useful 1)

> The provided documentation doesn’t describe a way to list leads you personally created this month.
> 
> On the **Leads** board, the **New** column shows **Date Created** and **Name**; later stages show other dates. You can review New leads for **November 2026**, but that won’t cover leads that have already progressed. [Leads](Leads.md)
> 
> The title-bar user selector filters records by their owner, not necessarily by who created them. [FAQ](FAQ.md)

