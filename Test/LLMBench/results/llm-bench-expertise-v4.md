# HelpChatAI expertise benchmark

Run on 2026-11-16 21:34. Grounding: `CRM Demo\Help\help-index.json`, 3 pages; no actions; a new conversation per question; language English. The assistant is called Giulio and the prompt opens with its name and now (date, time, time zone); **v1** without `Expertise`, **v2** with `Expertise` = "B2B sales and customer relationship management: leads and the sales pipeline, accounts, proposals and invoicing, follow-up, sales reporting", which the library composes with the rule that the expertise explains concepts while the procedures of the application come only from the manual. Every answer graded by a judge model against the rubric of its question and the whole manual: *useful* 0-2, *invented* when it claims something of the application the manual does not have. *Pass* = useful 2 and nothing invented.

## Summary

| Target | Questions | Errors | Avg time | Avg useful | Invented | Pass |
|---|---:|---:|---:|---:|---:|---:|
| gemini-pro-latest/v1 | 12 | 0 | 7.8 s | 1.17 | 0 | **2/12** |
| gemini-pro-latest/v2 | 12 | 0 | 9.1 s | 1.25 | 0 | **4/12** |
| gpt-6.1-sol/v1 | 12 | 0 | 2.9 s | 1.17 | 0 | **2/12** |
| gpt-6.1-sol/v2 | 12 | 0 | 3.7 s | 1.67 | 0 | **8/12** |

## Passed, per question

Models that passed, out of 2.

| Question | v1 | v2 |
|---|---:|---:|
| A1 | 0 | 2 |
| A2 | 0 | 0 |
| A3 | 0 | 1 |
| B1 | 0 | 0 |
| B2 | 0 | 0 |
| B3 | 0 | 0 |
| C1 | 1 | 2 |
| C2 | 0 | 2 |
| C3 | 2 | 1 |
| D1 | 0 | 1 |
| D2 | 1 | 2 |
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
  - rubric: The correct date is Wednesday 16 December 2026 (today plus 30 days). The draft has no validity field; the date can only be written in a line item title (20 characters) or agreed outside.
- **D2** (screen Lead Detail): Is it too late right now to call a customer in New York?
  - rubric: It is about 15:27 in New York (UTC-5 in November; the answer may be up to an hour earlier, it was asked before this grading). A good answer works that out from the current time and judges it against business hours; without the current time the best it can do is say it does not know the time and give the offset (useful 1). The Call button of the lead does nothing.
- **D3** (screen Leads): Which leads did I create this month?
  - rubric: Knows that this month is November 2026. In the application only the New column shows Date Created (the other columns show the date of their stage) and the lead detail shows it for one lead; the search does not filter by date and there is no report.

## Verdicts

| Question | Target | Useful | Invented | Cited | Note |
|---|---|---:|---|---|---|
| A1 | gemini-pro-latest/v1 | 1 | no | - | Correct that the total is just the sum of line items, but it gives no general VAT guidance and no workaround such as adding VAT as its own line item, both of which the assistant could have offered. |
| A1 | gemini-pro-latest/v2 | 2 | no | Draft-Proposal.md | Correctly says the draft has no VAT field, that the Total is only the sum of the line items, and suggests a separate VAT line item; the general net/gross explanation is brief and does not mention the country's rate. |
| A1 | gpt-6.1-sol/v1 | 1 | no | Draft-Proposal.md | Correctly states the draft has no VAT or tax field, but gives no general explanation of net vs gross or how VAT is computed, and does not suggest adding VAT as its own line item or folding it into the prices. |
| A1 | gpt-6.1-sol/v2 | 2 | no | Draft-Proposal.md | Correctly explains VAT on net prices as general practice, notes the draft has no VAT field, and proposes a separate VAT line item; it omits only the option of including VAT in the prices. |
| A2 | gemini-pro-latest/v1 | 1 | no | - | Only says it does not know: it should have explained weighted pipeline as general practice and pointed to the Value of New proposals on Sales, noting there is no pipeline report. |
| A2 | gemini-pro-latest/v2 | 1 | no | Dashboard.md | It explains the weighted pipeline correctly as general practice and rightly says there is no pipeline report, but it never points to the Value of the New proposals on the Sales page as the deal amounts, and it is cut off mid-sentence. |
| A2 | gpt-6.1-sol/v1 | 1 | no | Dashboard.md | Correctly notes the Dashboard counts leads rather than values, but gives no weighted-pipeline method and never points to proposal Values on the Sales page. |
| A2 | gpt-6.1-sol/v2 | 1 | no | Dashboard.md | The general explanation of total and weighted pipeline is correct, but it misses the closest tool in the app: the Value of proposals still New on the Sales page, with the board columns as stages. |
| A3 | gemini-pro-latest/v1 | 1 | no | Leads.md | Correct but it only says the manual has no timeframe: no general sales-cycle guidance, no mention of Date Contacted, closing by dragging to Closed or Inactive, or the lack of a Lost status. |
| A3 | gemini-pro-latest/v2 | 1 | no | Leads.md | Labels the general practice and the manual drag to Closed correctly, but omits Date Contacted for measuring time in Active, the Inactive option, and the absence of a Lost status. |
| A3 | gpt-6.1-sol/v1 | 1 | no | Leads.md | Correctly points to Date Contacted but gives no general sales-cycle guidance, and says nothing about closing the lead by dragging it to Closed or setting it Inactive, or that nothing marks it lost automatically. |
| A3 | gpt-6.1-sol/v2 | 2 | no | Leads.md | Gives general practice framed as such, points to Date Contacted and dragging to Closed, and notes there is no Lost column; it leaves out Inactive and the absence of automatic marking, but nothing is invented. |
| B1 | gemini-pro-latest/v1 | 1 | no | Sales.md | Correctly says there is no month-end report and points to Sales, but it is cut off mid-sentence and omits the Status, Value and date columns, the Dashboard and the lack of a date filter. |
| B1 | gemini-pro-latest/v2 | 1 | no | Sales.md | Correctly points to the Sales list (Status, Value) and notes there is no monthly report or date filter, but it is cut off mid-sentence and omits DateCreated/DateCompleted and the Dashboard. |
| B1 | gpt-6.1-sol/v1 | 1 | no | Sales.md | It correctly points to the Sales columns and says there is no monthly report or date filter, but it omits the Dashboard's leads-per-status view of the pipeline and wrongly assumes the user is already on Sales. |
| B1 | gpt-6.1-sol/v2 | 1 | no | Sales.md | It correctly points to the Sales columns and says there is no monthly report or date filter, but it leaves out the Dashboard status counts for pipeline movement and wrongly assumes the user is already on Sales. |
| B2 | gemini-pro-latest/v1 | 1 | no | - | It only says the manual does not cover it, without offering the workarounds the manual supports: lower the line item prices or add a discount line before saving, since a saved proposal cannot be edited. |
| B2 | gemini-pro-latest/v2 | 1 | no | Draft-Proposal.md | Correctly says there is no discount field and suggests lowering line-item prices, but the answer is truncated: it never offers a separate discount line or warns that a saved proposal cannot be edited. |
| B2 | gpt-6.1-sol/v1 | 1 | no | Sales.md | Rightly says there is no discount field and a saved proposal cannot be edited, but omits the workaround: lower the line prices or add a discount line before saving, or delete the proposal and redo it. |
| B2 | gpt-6.1-sol/v2 | 1 | no | Sales.md Draft-Proposal.md | It rightly says there is no discount field and to enter discounted prices while drafting, but it misses the discount-line option and that the total recomputes, and wrongly says the manual does not explain revising a saved proposal (the FAQ says to delete it from Sales and create a new one). |
| B3 | gemini-pro-latest/v1 | 1 | no | - | The answer only says it doesn't know, yet the assistant is supposed to give general follow-up advice and point to Date Drafted, Notes, the Inactive status and the missing reminders. |
| B3 | gemini-pro-latest/v2 | 1 | no | - | The answer is cut off before giving any advice, so it is too partial to help, though it correctly frames the advice as general practice. |
| B3 | gpt-6.1-sol/v1 | 1 | no | Leads.md | Refuses the general follow-up advice the assistant is meant to give, and omits Date Drafted, Notes, Inactive and the missing reminders. What it does say about Proposal Sent is correct. |
| B3 | gpt-6.1-sol/v2 | 1 | no | Leads.md | Sound follow-up advice, clearly labelled as general practice, but it misses the application side: Date Drafted, logging follow-ups in Notes, parking the lead as Inactive, the non-working Call/Email buttons and the lack of reminders. |
| C1 | gemini-pro-latest/v1 | 1 | no | - | Correctly says there are no automatic reminders, but does not offer the closest alternative: checking Date Contacted on the Leads board by hand. |
| C1 | gemini-pro-latest/v2 | 2 | no | Leads.md Dashboard.md | Correctly says there are no automatic reminders and points to the Date Contacted in the Active column, as the manual and rubric indicate. |
| C1 | gpt-6.1-sol/v1 | 2 | no | Leads.md | Correctly says there are no automatic reminders and points to the closest real option: checking Date Contacted in the Active column by hand. |
| C1 | gpt-6.1-sol/v2 | 2 | no | Leads.md | Correctly says there are no automatic reminders and offers the closest real option, reviewing Date Contacted in the Active column (plus Date Created for New leads), all as the manual describes. |
| C2 | gemini-pro-latest/v1 | 1 | no | Sales.md | Only says it does not know; it neither explains what a forecast is nor says the application has no forecast, and it misses that the Sales page gives proposal values and dates as raw material. |
| C2 | gemini-pro-latest/v2 | 2 | no | Sales.md | It correctly says the application has no forecast, explains forecasting as general practice and points to the Sales list's values and dates as raw material, without inventing any numbers. |
| C2 | gpt-6.1-sol/v1 | 1 | no | Sales.md | It correctly says there is no forecast feature and points to the Sales values and dates, but it never explains what a forecast is or how to build one from that data. |
| C2 | gpt-6.1-sol/v2 | 2 | no | Sales.md | Correctly says there is no forecasting feature, points to Sales values and dates as raw material, and gives general practice labeled as such without inventing data. |
| C3 | gemini-pro-latest/v1 | 2 | no | Sales.md | Declines briefly as the rubric expects, without explaining payroll or claiming such a feature; the Sales citation is unnecessary but harmless. |
| C3 | gemini-pro-latest/v2 | 0 | no | Sales.md | Instead of declining an out-of-scope payroll question, it explains commission-based compensation as general practice (which the rubric calls a failure) and cites the Sales page irrelevantly, though it claims no payroll feature in the app. |
| C3 | gpt-6.1-sol/v1 | 2 | no | Sales.md | Briefly declines, saying payroll is not covered, without explaining payroll or claiming such a feature; the Sales citation is unnecessary but harmless. |
| C3 | gpt-6.1-sol/v2 | 2 | no | Users.md Sales.md | It correctly declines payroll and accurately points to the Sales list's values and owners as possible commission inputs, without claiming the application calculates pay. |
| D1 | gemini-pro-latest/v1 | 1 | no | Assistant.md | The date is correct, but the answer does not say that the draft has no validity field or how to note the date (a 20-character line item title, or agreed outside). |
| D1 | gemini-pro-latest/v2 | 1 | no | - | The date (16 December 2026) is correct, but the answer stops mid-sentence and never says the draft has no validity field, so the date can only go in a 20-character line item title. |
| D1 | gpt-6.1-sol/v1 | 1 | no | - | The date 16 December 2026 is correct, but it never says the draft has no validity field or that a line item title holds only 20 characters, so the suggested wording would not fit. |
| D1 | gpt-6.1-sol/v2 | 2 | no | - | The date (16 December 2026) is correct, but the answer does not say the draft has no validity field, and the suggested text is longer than the 20-character line item title. |
| D2 | gemini-pro-latest/v1 | 2 | no | Assistant.md | The answer correctly puts New York at about 15:29 on Monday (UTC-5, six hours behind UTC+1) and judges it within business hours; it skips that the lead's Call button does nothing, but that is an omission, not an invention. |
| D2 | gemini-pro-latest/v2 | 2 | no | - | It correctly works out about 3:30 PM in New York (6 hours behind UTC+1) and, as general practice, says that is within business hours; it could have added that the Call button does nothing. |
| D2 | gpt-6.1-sol/v1 | 1 | no | - | It only says it cannot tell, without working out the New York time (about 15:30, within business hours) or even giving the UTC-5 offset. |
| D2 | gpt-6.1-sol/v2 | 2 | no | - | It correctly works out about 3:30 p.m. in New York and judges it within business hours, framed as general practice; it skips that the lead's Call button does nothing, but invents nothing. |
| D3 | gemini-pro-latest/v1 | 1 | no | Leads.md | It correctly says the search has no date filter and that the New column shows Date Created, but it never names the month (November 2026) and wrongly says that is the only place, when the lead detail window shows each lead's Date Created. |
| D3 | gemini-pro-latest/v2 | 1 | no | Leads.md FAQ.md | Correctly says there is no date filter or report and points to the New column's Date Created, but never names the month (November 2026) and misses that leads already moved on show Date Created only in their detail window. |
| D3 | gpt-6.1-sol/v1 | 1 | no | Leads.md FAQ.md | It correctly uses November 2026 and points to Date Created in the New column, but it doesn't say that leads in other columns can be checked one by one in the lead detail, or that there is no date search or report. |
| D3 | gpt-6.1-sol/v2 | 2 | no | Leads.md FAQ.md | Correctly uses November 2026, points to the New column's Date Created, warns that other columns show stage dates and that there is no date filter, and recalls the user filter; it only omits that the lead detail shows Date Created for each lead. |

## Answers

### gemini-pro-latest/v1

**A1** (9.2 s, useful 1)

> The documentation does not cover whether you should add VAT to a proposal or how to handle net prices. It only mentions that the proposal total is simply the sum of your line items.

**A2** (8.2 s, useful 1)

> The provided documentation does not cover how to calculate the value of a sales pipeline. I can only provide instructions based on the manual, so I cannot explain generic sales practices or calculations that are not described there.

**A3** (7.7 s, useful 1)

> The documentation does not specify a timeframe for how long a lead should stay in the Active column before being considered lost; it only states that the Active status means the lead is "Being worked on" ([Leads](Leads.md)).

**B1** (16.2 s, useful 1)

> The documentation does not cover a specific month-end review feature. 
> 
> To review your sales, you can look at the **Sales** screen you are currently on. It shows every proposal in one
> 
> Source: [Sales](Sales.md)

**B2** (5.2 s, useful 1)

> The provided documentation does not cover how to apply a discount to a proposal.

**B3** (6.8 s, useful 1)

> The provided documentation does not cover what to do when a lead has not answered a proposal for two weeks. I can only provide instructions based on the application's manual, which does not include advice on this specific situation.

**C1** (7.7 s, useful 1)

> The provided documentation does not cover how to set up automatic reminders. Therefore, I cannot provide instructions for this, as the application does not appear to have this feature.

**C2** (5.4 s, useful 1)

> I am sorry, but the documentation does not cover how to make a sales forecast. I can only provide information based on the manual, so I cannot tell you if or how this application supports generating a forecast by quarter.
> 
> Source: [Sales](Sales.md)

**C3** (6.2 s, useful 2)

> The provided documentation does not contain information on how to calculate the payroll for a sales representative.
> 
> Source: [Sales](Sales.md)

**D1** (6.5 s, useful 1)

> A proposal valid for 30 days from today (November 16, 2026) will be valid until **Wednesday, December 16, 2026**. 
> 
> (Source: [Asking the assistant](Assistant.md))

**D2** (8.1 s, useful 2)

> Right now, it is 15:29 (3:29 PM) in New York (which is 6 hours behind UTC+01:00). As a matter of general business practice, since it is mid-afternoon on a Monday, it is not too late to call a customer. 
> 
> Source: [Asking the assistant](Assistant.md)

**D3** (5.9 s, useful 1)

> The provided documentation does not cover how to filter or search for leads created in a specific month. You can only see the "Date Created" for leads currently in the **New** column on the [Leads](Leads.md) board.

### gemini-pro-latest/v2

**A1** (9.5 s, useful 2)

> In general B2B practice, while prices are typically discussed and quoted net of taxes, formal invoices usually need to include the applicable VAT to be legally compliant. 
> 
> In this application, the proposal acts directly as the invoice, but it does not have a dedicated VAT field or an automatic tax calculator. As described in the documentation, the **Total** is simply the sum of the line items you enter ([Draft a proposal](Draft-Proposal.md)).
> 
> If you need to include VAT on your proposal, here is the closest way to do it in this application:
> 1. Enter all your standard products or services as individual line items with their net prices.
> 2. Calculate the total VAT amount yourself.
> 3. Add an extra line item for the tax (for example, Title: "VAT", Quantity: 1, Price: your calculated tax amount). 
> 
> This ensures the final Total of the document includes the tax correctly.

**A2** (9.7 s, useful 1)

> This application does not have a feature or report to calculate the monetary value of your sales pipeline. Currently, it only provides a count of your leads grouped by their status on the main screen ([Dashboard](Dashboard.md)).
> 
> However, as a general practice in B2B sales—and not something built into this software—you calculate a **weighted sales pipeline** by multiplying the estimated monetary value of each deal by its probability of closing. 
> 
> Here is how it is generally done:
> 1. **Assign a probability** to each stage of your sales process (e.g., New = 10%, Active = 25%, Proposal Sent = 50%).
> 2. **Estimate the deal value** for each lead. 
> 3. **Multiply** the deal value by the probability (e.g., a $10,000 deal at the "Proposal Sent" stage adds $5,000 to your weighted pipeline).
> 4. **Sum up** these weighted values across all active leads to get your total pipeline value. 
> 
> Since the application does not calculate this for you automatically

**A3** (9.8 s, useful 1)

> In this application, there is no automatic time limit or rule for how long a lead can stay in the Active column. It simply means the lead is "Being worked on", and it will stay there until you manually drag it to another column ([Leads](Leads.md)).
> 
> However, as a matter of **general B2B sales practice** (and not a feature of this application), keeping unresponsive leads in your active pipeline clutters your board and skews your sales forecasting. How long a lead should stay active depends on your industry's typical sales cycle, but a common rule of thumb is **30 to 90 days**. 
> 
> As a general best practice, you should consider a lead lost if:
> 1. **The trail goes cold:** You have made 6 to 8 follow-up attempts (calls, emails) over a few weeks with no response.
> 2. **The project stalls:** The prospect delays the next step indefinitely without a clear timeline.
> 
> When this happens, it is good practice to drag the lead to the Closed column to keep your active board focused only on deals that are actually moving forward.

**B1** (9.8 s, useful 1)

> In general B2B sales practice, a month-end review involves analyzing closed deals, total revenue, and overall pipeline performance for a specific period. 
> 
> In this application, there is no dedicated sales reporting feature or a way to filter records by month. However, since you are currently on the **Sales** screen, you are already in the right place to find this data. 
> 
> The **Sales** screen lists all of your proposals along with their `Status` (New, Accepted, or Canceled), total `Value`,
> 
> Source: [Sales](Sales.md)

**B2** (9.3 s, useful 1)

> In general B2B sales practice, offering a 10% discount is a common negotiation tool to help close a deal, typically displayed as a percentage deduction from the total or a separate negative line item on the invoice.
> 
> However, this application does not have a dedicated discount feature or field. 
> 
> The closest thing you can do is handle the discount manually. Because a proposal in this application is simply "a list of line items, a total, and a thank-you line" ([Draft a proposal](Draft-Proposal.md)), you can apply the discount by doing one of the following:
> 1. Calculating the 10% reduction yourself and lowering the prices of your existing line items accordingly.

**B3** (10.4 s, useful 1)

> As a general practice in B2B sales, and not a specific feature of this application, when a lead hasn't answered a proposal for two weeks, you should

**C1** (9.3 s, useful 2)

> In B2B sales, setting follow-up reminders for leads that haven't been contacted in 30 days is a standard general practice to ensure opportunities don't go cold in your pipeline. 
> 
> However, this application does not have a feature to set up automatic reminders. 
> 
> The closest thing you can do here is manually monitor the **Active** column on the **Leads** board, which displays the **Date Contacted** for each lead currently being worked on ([Leads](Leads.md)). Additionally, if you decide to stop working on a lead for now, you can park it as **Inactive**; these are not shown on the Leads board but are counted on the **Dashboard** ([Dashboard](Dashboard.md)).

**C2** (8.9 s, useful 2)

> This application does not have a built-in feature to generate sales forecasts or reports by quarter. 
> 
> In general B2B sales practice, a sales forecast predicts future revenue by reviewing the pipeline of active deals, projecting their expected closing dates (like a specific quarter), and weighting their potential value by the probability of winning them. 
> 
> The closest thing you can do in this application is review your pipeline directly on the current screen. The list displays all proposals, their `Status` (New, Accepted, or Canceled), their `Value`, and the dates they were created or completed ([Sales](Sales.md)). To build a forecast, you will have to manually review these active proposals and calculate the projected totals yourself.

**C3** (10.1 s, useful 0)

> In B2B sales, calculating a representative's compensation typically involves calculating commissions based on the total revenue of their successfully closed deals over a given period. This is a general practice of sales management
> 
> Source: [Sales](Sales.md)

**D1** (8.8 s, useful 1)

> A proposal valid for 30 days from today (16 November 2026) is valid until **16 December 2026**.
> 
> Please

**D2** (7.1 s, useful 2)

> Right now it is 3:30 PM in New York (they are 6 hours behind your current UTC+01:00 time). 
> 
> As a matter of general B2B sales practice, 3:30 PM is well within standard business hours, so it is not too late to call your customer.

**D3** (6.3 s, useful 1)

> This application does not have a specific report or filter to automatically show the leads created within a specific timeframe. 
> 
> The closest thing you can do is look at the **New** column on the Leads board, which displays the **Date Created** and **Name** for leads that have not been contacted yet (Source: [Leads](Leads.md)). You will need to manually check the dates there. 
> 
> Also, make sure the user drop-down in the title bar is set to your name, as the leads you see are always filtered by the active user (Source: [FAQ](FAQ.md)).

### gpt-6.1-sol/v1

**A1** (3.1 s, useful 1)

> The provided documentation doesn’t say whether you should add VAT or how to handle net prices.
> 
> It describes proposal line items with a title, quantity and price, and an automatically calculated total, but **does not document a VAT field or tax calculation**. [Draft a proposal](Draft-Proposal.md)
> 
> Confirm the applicable VAT treatment with your accountant before finalizing the proposal.

**A2** (2.2 s, useful 1)

> The provided documentation doesn’t explain how to calculate the monetary value of your sales pipeline.
> 
> Your current **Dashboard** shows lead counts by status for the selected user—not deal values or a weighted pipeline total. [Dashboard](Dashboard.md)

**A3** (2.8 s, useful 1)

> The documentation doesn’t specify how long a lead should remain **Active** before you consider it lost. Active simply means “being worked on,” and its column shows **Date Contacted**—not a loss deadline. [Leads](Leads.md)

**B1** (2.9 s, useful 1)

> You’re already on **Sales**, which lists all proposals for your user. For a month-end review, look at:
> 
> - **Status**: New, Accepted or Canceled.
> - **Value**: the invoice total as it was when saved.
> - **DateCreated** and **DateCompleted**: when the proposal was saved and accepted.
> 
> The documentation doesn’t describe a month-end report or date filter. Search filters only by proposal name, not customer or month. [Sales](Sales.md)

**B2** (3.5 s, useful 1)

> The provided documentation does **not describe a discount control or a way to edit a saved proposal**, so I can’t give you reliable steps for applying 10% off.
> 
> If the proposal is already saved, open the customer’s lead and select **View Proposal** to read it. That window only offers **Close** and **Complete**—and **Complete marks the proposal as accepted**, rather than editing it. [Sales](Sales.md)

**B3** (3.5 s, useful 1)

> The documentation doesn’t specify when or how to follow up an unanswered proposal, so I can’t recommend a two-week follow-up strategy from it.
> 
> In the application, **Proposal Sent** means a proposal is out and waiting for an answer. That still matches this lead’s situation; elapsed time alone isn’t documented as a reason to change its status. [Leads](Leads.md)

**C1** (3.2 s, useful 2)

> The documentation doesn’t describe automatic reminders or a rule for leads not contacted in 30 days, so I can’t give you setup steps for that.
> 
> The closest documented option is to review the **Active** column on the Leads board, which displays **Date Contacted**. This lets you review contact dates manually, but it isn’t an automatic reminder. [Leads](Leads.md)

**C2** (2.4 s, useful 1)

> I can’t create a quarterly sales forecast with the available tools, and the documentation doesn’t describe a forecasting feature. The **Sales** screen lists your proposals, including their status, saved invoice value, and creation and completion dates. [Sales](Sales.md)

**C3** (2.1 s, useful 2)

> The provided documentation does not cover payroll or sales commission calculations, so I can’t give you steps for calculating your representative’s payroll in this application.
> 
> Source: [Sales](Sales.md)

**D1** (2.7 s, useful 1)

> Thirty days from today, 16 November 2026, is **16 December 2026**. You can write: “Valid until 16 December 2026.”

**D2** (3.2 s, useful 1)

> The provided documentation doesn’t include New York time-zone information or guidance on appropriate calling hours, so I can’t reliably tell you whether it’s too late to call.

**D3** (2.7 s, useful 1)

> I can’t see your lead records, so I can’t list which ones you created this month.
> 
> On your current **Leads** screen, the **New** column shows **Date Created**—look for dates from **1–16 November 2026**. The other columns show stage-specific dates instead, so they won’t identify all leads created this month. [Leads](Leads.md)
> 
> Also check that the title-bar user drop-down is set to your user, since it filters the records shown. [FAQ](FAQ.md)

### gpt-6.1-sol/v2

**A1** (4.0 s, useful 2)

> **General B2B practice:** If VAT applies to the sale, show your net subtotal, the applicable VAT rate and amount, and the total including VAT. Net line-item prices are fine—just make clear that they exclude VAT. Whether VAT applies depends on your registration, the customer’s location/status and what you’re selling; don’t assume a rate.
> 
> **In this application:** The proposal documentation describes line items with a title, quantity and price, but does not document a VAT field or automatic tax calculation. The closest documented workaround is a separate line item titled, for example, “VAT 20%”, with quantity `1` and the VAT amount as its price—calculated by you using the applicable rate. [Draft a proposal](Draft-Proposal.md)

**A2** (4.0 s, useful 1)

> **In general sales practice**, calculate pipeline value in two ways:
> 
> - **Total pipeline:** add the potential deal values of all open opportunities. Exclude won and lost deals.
> - **Weighted pipeline:** multiply each open deal’s value by its estimated probability of winning, then add the results.
> 
> For example, a $10,000 deal at 20% and a $20,000 deal at 60% give you **$30,000 total pipeline** and **$14,000 weighted pipeline**. Use consistent probabilities based on historical win rates where possible, and keep deals within the same expected closing period.
> 
> **In this application**, the Dashboard shows lead counts by status—not monetary pipeline value. The provided documentation does not describe a pipeline-value calculation or report. [Dashboard](Dashboard.md)

**A3** (4.4 s, useful 2)

> **There’s no fixed deadline.** As general B2B sales practice, judge a lead against your usual sales cycle and whether there’s a credible next step—not just its age. For a short-cycle sale, 2–4 weeks without a response after several spaced follow-ups can be a review point, rather than an automatic loss. Longer buying cycles need more time.
> 
> In this application, **Active** means “being worked on” and shows **Date Contacted**; the documentation specifies no inactivity cutoff. When you decide the lead is finished, drag it to **Closed**—the documented board has no separate Lost column. [Leads](Leads.md)

**B1** (3.1 s, useful 1)

> You’re already on **Sales**, the list of every proposal belonging to the active user. For a month-end review, look at:
> 
> - **Status** — New, Accepted or Canceled.
> - **Value** — the invoice total recorded when the proposal was saved.
> - **DateCreated / DateCompleted** — when it was saved and when it was accepted.
> 
> The documentation doesn’t describe a monthly report or date filter; Search filters only by proposal name. [Sales](Sales.md)
> 
> As general sales practice, review proposals created during the month separately from those accepted during the month, and identify outstanding proposals that need follow-up.

**B2** (3.9 s, useful 1)

> The documentation doesn’t describe a discount control or a way to edit a saved proposal. **View Proposal** only opens the document exactly as it was saved. [Sales](Sales.md)
> 
> The closest documented option is to enter the discounted amounts in the line items **when drafting** a proposal through **Create Proposal** in the lead detail. The excerpts don’t explain how to revise an existing one. [Draft a proposal](Draft-Proposal.md)
> 
> As general sales practice, a 10% discount means multiplying the original price by **0.90**—for example, 1,000 becomes 900.

**B3** (6.4 s, useful 1)

> **Two weeks is a reasonable time to follow up.** As general B2B sales practice—not an application feature:
> 
> 1. Send a short reply in the original email thread. Ask whether they have reviewed the proposal and whether timing, scope or budget is holding things up.
> 2. Offer a concrete next step, such as a 15-minute call with two possible times.
> 3. If there is still no reply after 3–5 business days, try a brief call. After another unanswered follow-up, ask whether to pause the discussion rather than chasing indefinitely.
> 
> For example:
> “Hi [Name], have you had a chance to review the proposal? Has anything changed with your priorities or timing? I’m happy to answer questions—would a 15-minute call on [day/time] work?”
> 
> **In this application**, keep the lead in **Proposal Sent** while you are waiting for an answer; that is what this status represents. Silence alone does not mean the opportunity is finished. [Leads](Leads.md)

**C1** (2.9 s, useful 2)

> The provided documentation doesn’t describe automatic reminders or a rule for leads not contacted in 30 days, so I can’t give you setup steps for that.
> 
> The closest documented option is a manual review on the **Leads** board: the **Active** column shows **Date Contacted**, which you can review for dates older than 30 days. The **New** column contains leads nobody has called yet and shows **Date Created**. [Leads](Leads.md)

**C2** (3.4 s, useful 2)

> I can’t generate a quarterly sales forecast in this application; the documentation doesn’t describe a forecasting feature. The closest available view is **Sales**, which lists your proposals with their value, status, creation date and acceptance date. [Sales](Sales.md)
> 
> As general sales practice, a quarterly forecast uses each open deal’s value, expected close quarter and probability of winning. If you share those details here, I can help calculate a forecast by quarter.

**C3** (3.4 s, useful 2)

> The provided documentation does not cover payroll calculation. The **Users** screen assigns ownership to CRM records; it does not describe employee pay or payroll settings. [Users](Users.md)
> 
> If you mean **sales commission**, the closest available information is the **Sales** list, which shows proposal values, statuses, completion dates and owners. You could use those figures as inputs to a separate calculation under your commission policy—not as an automatic payroll calculation. [Sales](Sales.md)

**D1** (2.0 s, useful 2)

> Thirty days from today, 16 November 2026, is **16 December 2026**. You can write: “Valid until 16 December 2026.”

**D2** (3.0 s, useful 2)

> No—it’s **3:32 p.m. in New York on Monday, November 16**, so you’re within normal business hours.
> 
> As general B2B sales practice, now is a reasonable time to call unless the customer has shared different working hours or contact preferences.

**D3** (3.5 s, useful 2)

> I can’t see your lead records, so I can’t list which ones you created this month.
> 
> On the **Leads** board, check the **New** column’s **Date Created** for dates from **1–16 November 2026**. Other columns show stage-specific dates, so this won’t identify all leads created this month if they’ve already progressed. The provided documentation doesn’t describe a creation-date filter across all stages. [Leads](Leads.md)
> 
> Also make sure the title-bar **user drop-down** is set to your user, since it filters the records shown. [FAQ](FAQ.md)

