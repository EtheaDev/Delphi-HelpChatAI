# HelpChatAI provider benchmark

Run on 2026-11-16 22:53. Grounding: `CRM Demo\Help\help-index.json`, 3 pages x 2000 chars; two actions registered (`open_screen`, `create_lead`, the second confirmed with Yes); **the questions of a target in one conversation**, the history never cleared (`--suite=conversation`); language rule English.

## Summary

| Target | Warm-up | Questions | Errors | Avg time | Avg first token | Citations ok | Facts found | Actions ok |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 14.1 s | 8 | 0 | 4.6 s | 4.0 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-oss:20b | 27.2 s | 8 | 0 | 3.3 s | 2.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| qwen3-coder:30b | 29.8 s | 8 | 0 | 3.4 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude | 1.3 s | 8 | 0 | 1.7 s | 1.2 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-haiku-5-5 | 1.4 s | 8 | 0 | 1.8 s | 1.3 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-sonnet-5-5 | 2.0 s | 8 | 0 | 1.8 s | 0.9 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| claude-opus-5-5 | 2.2 s | 8 | 0 | 2.9 s | 1.5 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini | 0.8 s | 8 | 0 | 1.0 s | 0.8 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-argon | 5.4 s | 8 | 0 | 9.8 s | 8.5 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-4-carbon | 7.2 s | 8 | 0 | 15.9 s | 15.0 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gemini-pro-latest | 4.9 s | 8 | 0 | 6.0 s | 5.7 s | 100% (8/8) | 91% (10/11) | 100% (8/8) |
| gemini-3.5-flash-lite | 1.0 s | 8 | 0 | 1.0 s | 0.8 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-6-luna | 2.8 s | 8 | 0 | 2.4 s | 1.6 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |
| gpt-6.1-sol | 1.5 s | 8 | 0 | 2.6 s | 1.7 s | 100% (8/8) | 100% (11/11) | 100% (8/8) |

### Tokens

Prompt cache on (`Claude.PromptCaching`, the default). The questions, warm-up excluded, of each target in a row, as one session would ask them.

| Target | Requests | Input | Cache write | Cache read | Output | Input as billed |
|---|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 10 | 18710 | 0 | 4988 | 2528 | - |
| gpt-oss:20b | 10 | 19365 | 0 | 5323 | 1969 | - |
| qwen3-coder:30b | 10 | 10973 | 0 | 16240 | 878 | - |
| claude | 10 | 20 | 15882 | 22166 | 2341 | 22089 |
| claude-haiku-5-5 | 10 | 20 | 13615 | 23296 | 2210 | 19368 |
| claude-sonnet-5-5 | 10 | 20 | 15723 | 22681 | 1379 | 21942 |
| claude-opus-5-5 | 10 | 20 | 15901 | 23614 | 1859 | 22258 |
| gemini | 10 | 23931 | 0 | 0 | 629 | - |
| gemini-4-argon | 10 | 24413 | 0 | 1255 | 870 | - |
| gemini-4-carbon | 10 | 24474 | 0 | 1236 | 2570 | - |
| gemini-pro-latest | 10 | 23743 | 0 | 0 | 3337 | - |
| gemini-3.5-flash-lite | 10 | 23524 | 0 | 0 | 557 | - |
| gpt-6-luna | 10 | 14021 | 3627 | 4513 | 779 | - |
| gpt-6.1-sol | 10 | 13061 | 3692 | 5847 | 588 | - |

"Input": tokens at the full price. "Input as billed", claude only: input + 1.25 x cache write + 0.1 x cache read, the multipliers of Haiku (Sonnet and Opus 5.5 read at 0.05), in tokens of the full price. OpenAI and Gemini cache by themselves, at prices of their own; a local server reports its prefix cache, which costs nothing.

### Tokens per question

Read from the cache / the whole input of the requests of each question, the questions of a target in one conversation.

| Target | Q1 | Q2 | Q3 | Q4 | Q5 | Q6 | Q7 | Q8 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| gemma4:12b | 0 / 2117 | 0 / 1883 | 0 / 2277 | 0 / 2591 | 0 / 2588 | 0 / 2164 | 2322 / 4679 | 2666 / 5399 |
| gpt-oss:20b | 0 / 2091 | 0 / 1877 | 0 / 2296 | 0 / 2665 | 0 / 2681 | 0 / 2337 | 2502 / 5036 | 2821 / 5705 |
| qwen3-coder:30b | 953 / 2361 | 916 / 2131 | 1099 / 2553 | 1246 / 2893 | 1364 / 2895 | 1469 / 2524 | 4318 / 5494 | 4875 / 6362 |
| claude | 1114 / 3166 | 1211 / 3008 | 1457 / 3542 | 1723 / 3989 | 1901 / 4116 | 2090 / 3558 | 6078 / 7824 | 6592 / 8865 |
| claude-haiku-5-5 | 3164 / 3166 | 1211 / 3010 | 1459 / 3478 | 1659 / 3918 | 1830 / 4012 | 1986 / 3418 | 5757 / 7476 | 6230 / 8453 |
| claude-sonnet-5-5 | 1114 / 3166 | 1211 / 3027 | 1476 / 3533 | 1714 / 4073 | 1985 / 4185 | 2159 / 3649 | 6256 / 7953 | 6766 / 8838 |
| claude-opus-5-5 | 1114 / 3166 | 1211 / 3048 | 1497 / 3609 | 1790 / 4139 | 2051 / 4255 | 2229 / 3815 | 6600 / 8309 | 7122 / 9194 |
| gemini | 0 / 2101 | 0 / 1892 | 0 / 2303 | 0 / 2633 | 0 / 2593 | 0 / 2213 | 0 / 4746 | 0 / 5450 |
| gemini-4-argon | 0 / 2135 | 0 / 1936 | 0 / 2355 | 0 / 2736 | 0 / 2758 | 0 / 2449 | 577 / 5296 | 678 / 6003 |
| gemini-4-carbon | 0 / 2135 | 0 / 1926 | 0 / 2344 | 0 / 2701 | 0 / 2730 | 0 / 2434 | 558 / 5323 | 678 / 6117 |
| gemini-pro-latest | 0 / 2101 | 0 / 1822 | 0 / 2224 | 0 / 2521 | 0 / 2532 | 0 / 2140 | 0 / 4773 | 0 / 5630 |
| gemini-3.5-flash-lite | 0 / 2101 | 0 / 1877 | 0 / 2287 | 0 / 2621 | 0 / 2582 | 0 / 2144 | 0 / 4604 | 0 / 5308 |
| gpt-6-luna | 0 / 2001 | 0 / 1732 | 0 / 2135 | 0 / 2439 | 0 / 2417 | 0 / 2008 | 2218 / 4382 | 2295 / 5047 |
| gpt-6.1-sol | 0 / 2001 | 0 / 1724 | 0 / 2147 | 0 / 2488 | 0 / 2473 | 1069 / 2076 | 2352 / 4514 | 2426 / 5177 |

"Citations ok": the answer names one of the expected pages (`Page.md`), or none when nothing was expected. "Facts found": expected substrings present in the answer. "Actions ok": the expected action was invoked with the expected argument and no other action was, or no action at all when none was expected. Time includes the tool rounds.

## Per question

| Question | Target | Time | First token | Cited | Citation ok | Facts | Actions | Actions ok |
|---|---|---:|---:|---|---|---:|---|---|
| Q1 | gemma4:12b | 5.3 s | 4.0 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-oss:20b | 3.2 s | 1.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | qwen3-coder:30b | 4.0 s | 1.2 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude | 1.4 s | 0.8 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-haiku-5-5 | 1.7 s | 0.8 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-sonnet-5-5 | 2.6 s | 0.8 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | claude-opus-5-5 | 3.8 s | 1.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini | 1.0 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-argon | 6.3 s | 4.3 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-4-carbon | 8.2 s | 6.4 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gemini-pro-latest | 5.2 s | 4.6 s | Leads.md | yes | 2/3 | - | yes |
| Q1 | gemini-3.5-flash-lite | 1.1 s | 0.6 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-6-luna | 2.2 s | 0.9 s | Leads.md | yes | 3/3 | - | yes |
| Q1 | gpt-6.1-sol | 2.5 s | 1.1 s | Leads.md | yes | 3/3 | - | yes |
| Q2 | gemma4:12b | 3.7 s | 3.0 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-oss:20b | 4.1 s | 2.8 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | qwen3-coder:30b | 3.5 s | 1.2 s | Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude | 2.4 s | 1.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | claude-haiku-5-5 | 2.1 s | 1.4 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | claude-sonnet-5-5 | 1.8 s | 0.5 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | claude-opus-5-5 | 3.1 s | 0.8 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini | 0.9 s | 0.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-argon | 5.3 s | 4.0 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-4-carbon | 9.0 s | 8.0 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-pro-latest | 6.2 s | 5.7 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gemini-3.5-flash-lite | 0.8 s | 0.5 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q2 | gpt-6-luna | 1.8 s | 0.5 s | Getting-Started.md Data-Model.md | yes | 3/3 | - | yes |
| Q2 | gpt-6.1-sol | 2.8 s | 1.6 s | Data-Model.md Getting-Started.md | yes | 3/3 | - | yes |
| Q3 | gemma4:12b | 5.5 s | 5.1 s | Sales.md FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-oss:20b | 3.8 s | 2.4 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | qwen3-coder:30b | 3.1 s | 1.2 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | claude | 1.3 s | 0.7 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-haiku-5-5 | 2.4 s | 1.8 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-sonnet-5-5 | 2.0 s | 0.5 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | claude-opus-5-5 | 3.5 s | 1.0 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini | 0.9 s | 0.6 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-argon | 5.6 s | 3.4 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini-4-carbon | 13.7 s | 12.9 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q3 | gemini-pro-latest | 5.4 s | 5.0 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gemini-3.5-flash-lite | 0.7 s | 0.4 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-6-luna | 2.5 s | 1.9 s | FAQ.md | yes | 2/2 | - | yes |
| Q3 | gpt-6.1-sol | 2.1 s | 1.1 s | FAQ.md Sales.md | yes | 2/2 | - | yes |
| Q4 | gemma4:12b | 4.5 s | 3.8 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-oss:20b | 2.8 s | 1.8 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | qwen3-coder:30b | 3.2 s | 1.5 s | FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude | 2.0 s | 1.4 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-haiku-5-5 | 2.3 s | 1.8 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | claude-sonnet-5-5 | 1.3 s | 0.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | claude-opus-5-5 | 2.2 s | 1.1 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gemini | 0.8 s | 0.7 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-argon | 10.0 s | 8.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-4-carbon | 16.7 s | 15.4 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-pro-latest | 5.8 s | 5.3 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gemini-3.5-flash-lite | 0.7 s | 0.5 s | Accounts.md FAQ.md | yes | 1/1 | - | yes |
| Q4 | gpt-6-luna | 2.8 s | 2.1 s | FAQ.md Accounts.md | yes | 1/1 | - | yes |
| Q4 | gpt-6.1-sol | 2.4 s | 1.4 s | FAQ.md | yes | 1/1 | - | yes |
| Q5 | gemma4:12b | 3.8 s | 3.2 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-oss:20b | 4.0 s | 2.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | qwen3-coder:30b | 3.2 s | 1.3 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude | 1.2 s | 0.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-haiku-5-5 | 1.1 s | 0.8 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-sonnet-5-5 | 1.5 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | claude-opus-5-5 | 3.8 s | 1.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini | 0.9 s | 0.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-argon | 8.7 s | 6.7 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-4-carbon | 23.8 s | 22.0 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-pro-latest | 7.0 s | 6.6 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gemini-3.5-flash-lite | 0.6 s | 0.5 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-6-luna | 2.2 s | 1.4 s | Leads.md | yes | 2/2 | - | yes |
| Q5 | gpt-6.1-sol | 2.1 s | 1.2 s | Leads.md | yes | 2/2 | - | yes |
| Q6 | gemma4:12b | 3.3 s | 3.1 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-oss:20b | 1.6 s | 1.3 s | - | yes | 0/0 | - | yes |
| Q6 | qwen3-coder:30b | 2.2 s | 1.0 s | - | yes | 0/0 | - | yes |
| Q6 | claude | 1.6 s | 1.1 s | - | yes | 0/0 | - | yes |
| Q6 | claude-haiku-5-5 | 0.8 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-sonnet-5-5 | 1.4 s | 0.5 s | - | yes | 0/0 | - | yes |
| Q6 | claude-opus-5-5 | 1.7 s | 0.6 s | - | yes | 0/0 | - | yes |
| Q6 | gemini | 0.8 s | 0.7 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-4-argon | 5.9 s | 5.1 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-4-carbon | 8.5 s | 8.3 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-pro-latest | 3.0 s | 3.0 s | - | yes | 0/0 | - | yes |
| Q6 | gemini-3.5-flash-lite | 0.9 s | 0.8 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-6-luna | 2.9 s | 2.5 s | - | yes | 0/0 | - | yes |
| Q6 | gpt-6.1-sol | 2.4 s | 1.6 s | - | yes | 0/0 | - | yes |
| Q7 | gemma4:12b | 2.7 s | 2.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-oss:20b | 3.2 s | 3.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | qwen3-coder:30b | 3.4 s | 1.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude | 1.2 s | 1.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-haiku-5-5 | 1.5 s | 1.4 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-sonnet-5-5 | 1.5 s | 1.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | claude-opus-5-5 | 1.8 s | 1.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini | 1.3 s | 1.2 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-argon | 16.8 s | 16.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-4-carbon | 31.6 s | 31.6 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-pro-latest | 7.5 s | 7.5 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gemini-3.5-flash-lite | 1.2 s | 1.1 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-6-luna | 2.0 s | 1.8 s | - | yes | 0/0 | open_screen | yes |
| Q7 | gpt-6.1-sol | 3.1 s | 2.8 s | - | yes | 0/0 | open_screen | yes |
| Q8 | gemma4:12b | 7.8 s | 7.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-oss:20b | 3.7 s | 3.3 s | - | yes | 0/0 | create_lead | yes |
| Q8 | qwen3-coder:30b | 4.7 s | 1.2 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude | 2.5 s | 2.2 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | claude-haiku-5-5 | 2.2 s | 2.1 s | - | yes | 0/0 | create_lead | yes |
| Q8 | claude-sonnet-5-5 | 2.2 s | 2.2 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | claude-opus-5-5 | 3.3 s | 3.3 s | Assistant.md | yes | 0/0 | create_lead | yes |
| Q8 | gemini | 1.5 s | 1.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-argon | 19.8 s | 19.3 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-4-carbon | 16.0 s | 15.7 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-pro-latest | 7.6 s | 7.5 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gemini-3.5-flash-lite | 1.7 s | 1.6 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-6-luna | 2.6 s | 2.2 s | - | yes | 0/0 | create_lead | yes |
| Q8 | gpt-6.1-sol | 3.3 s | 3.0 s | - | yes | 0/0 | create_lead | yes |

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

**warm-up** (14.1 s)

> Hello! How can I help you with the application today?

**Q1** (5.3 s)

> To move a lead, drag a row from one column and drop it into another [Leads](Leads.md).
> 
> When you do this:
> *   The lead takes on the status of the new column.
> *   If the date for that stage is empty, it is automatically stamped with the current time (e.g., **Date Contacted** for **Active**, **Date Drafted** for **Proposal Sent**, or **Date Closed** for **Closed**).
> *   If a date already has a value, it is left alone so that moving a lead back and forth does not rewrite its history.
> *   Dropping a lead into the column it is already in has no effect.

**Q2** (3.7 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` in your Documents folder, which is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again [Getting started](Getting-Started.md).

**Q3** (5.5 s)

> No, you cannot change a proposal after saving it because the document is stored exactly as it was generated [FAQ].
> 
> To redo a proposal, you must delete the existing one from the Sales list using the navigator and then create a new one [FAQ].
> 
> Source: [Sales](Sales.md), [FAQ](FAQ.md)

**Q4** (4.5 s)

> To get a file you can open in Excel, use the export on the **Marketing** page, which writes a delimited text file [Accounts](Accounts.md), [FAQ](FAQ.md).
> 
> The exports on the Accounts and Leads pages use a FireDAC format that is not compatible with spreadsheets [Accounts](Accounts.md), [FAQ](FAQ.md).

**Q5** (3.8 s)

> You can use the **Search** box on the Leads board. It filters all columns simultaneously as you type, matching the e-mail address regardless of case or where it appears in the string [Leads](Leads.md).

**Q6** (3.3 s)

> I am sorry, but the provided documentation does not contain information about the weather in Milan.

**Q7** (2.7 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (7.8 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi (id 101) at Apollo Orange, LLC.

### gpt-oss:20b

**warm-up** (27.2 s)

> **Dashboard overview**
> 
> | Tile | What it counts | Notes |
> |------|----------------|-------|
> | **New Leads** | Leads nobody has contacted yet | |
> | **Active Leads** | Leads being worked on | |
> | **Proposal Sent** | Leads waiting for an answer to a proposal | |
> | **Closed** | Leads that ended, won or lost | |
> | **Inactive** | Leads parked | This is the *only* place you’ll see them – there’s no column for them on the Leads board. |
> | **Total** | Every lead of the active user | Not the sum of the five tiles unless every lead has one of those statuses. |
> 
> - The counters are filtered by the **User** selected in the drop‑down at the right of the title bar.  
> - Tiles are decorative – clicking them does nothing.  
> - To see the leads behind a number, open the **Leads** screen.  
> - Counters refresh only when you leave the Dashboard and come back. If you move a lead in another screen, click Dashboard again to update the numbers.  
> - The tiles wrap onto a second row if the window is too narrow; they do not change the layout beyond that.  
> 
> *Source: [Dashboard](Dashboard.md)*
> 
> If you need help navigating from here or want to create or manage leads, just let me know!

**Q1** (3.2 s)

> To move a lead on the Leads board:
> 
> 1. Click the row for the lead you want to move.
> 2. Drag it and drop it onto the desired column.
> 3. Release the mouse button.
> 
> When a lead is dropped into a new column:
> 
> - It changes to the status of that column.  
> - If the date for that stage is still empty, the application stamps it with the current date/time.  
>   * e.g., dropping from **New** to **Active** records **Date Contacted**.  
> - If the date already has a value, it is left unchanged (moving back and forth does not rewrite history).  
> - Dropping a lead onto the column it already occupies does nothing.
> 
> After the move, the board refreshes and the moved lead remains selected.  
> Source: [Leads](Leads.md)

**Q2** (4.1 s)

> Your data is kept in the file **w10crmdemo.sdb** inside the **Documents** folder of the user’s account.  
> The file is an encrypted SQLite database (AES‑256).  
> 
> To reset everything to the original sample data:
> 
> 1. Close the application.  
> 2. Delete **w10crmdemo.sdb** from the Documents folder.  
> 3. Start the application again – it will recreate the file and load the sample data.  
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (3.8 s)

> No.  
> The proposal document is stored exactly as it was when you saved it. Once it’s in the database you can only mark it **Accepted** or **Canceled** – you can’t edit its contents or line items.  
> To change a proposal you must delete the existing one from the Sales list (via the navigator) and create a new proposal.  
> 
> > “Can I change a proposal after I saved it? No. The document is stored as it was generated. You can mark it Accepted or Canceled, but not edit it…” — FAQ (FAQ.md)

**Q4** (2.8 s)

> The export you need for Excel is the one on the **Marketing** page.  
> It writes a delimited‑text file (CSV or TSV) with a header row, which Excel can open directly.  
> 
> The **Accounts** and **Leads** pages export in FireDAC’s own binary/XML/JSON format, which is meant to be read back by the application only.  
> 
> Source: [Accounts](Accounts.md) and [FAQ](FAQ.md)

**Q5** (4.0 s)

> Use the search box at the top of the Leads board.  
> Type the e‑mail address (or part of it) and press **Enter**.  
> The board filters all four columns—lead name, account name, office phone, and e‑mail—so the row with that e‑mail will be shown.  
> Clearing the box restores the full board.  
> > “The Search box filters all four columns at once… it matches… against the lead's name, account name, office phone or e‑mail.” — Leads.md
> 
> Source: [Leads](Leads.md)

**Q6** (1.6 s)

> I’m sorry, but the documentation and the current screen do not include any information about weather.

**Q7** (3.2 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (3.7 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi","notes":"","phone":""} -> Created the lead Mario Rossi (id 101).

> I’ve added the lead **Mario Rossi** for **Apollo Orange, LLC** with the e‑mail *mario.rossi@example.com*.

### qwen3-coder:30b

**warm-up** (29.8 s)

> Hello! I'm here to help you use the CRM application.
> 
> You're currently on the **Dashboard** screen, which shows counters for your leads grouped by status:
> - New Leads
> - Active Leads
> - Proposal Sent
> - Closed Leads
> - Inactive Leads
> - Total Leads
> 
> Each counter only includes leads assigned to the currently selected user (shown in the top-right dropdown). The numbers update when you return to the Dashboard after making changes elsewhere.
> 
> To see the actual leads behind any counter, click on the **Leads** tab in the navigation menu.
> 
> If you want to create a new lead, you can do so from the Leads board. You'll need to specify:
> - Lead name
> - Account (must already exist in the Accounts list)
> - Phone number (optional)
> - Email address (optional)
> - Notes (optional)
> 
> Would you like to create a new lead or navigate to another section?

**Q1** (4.0 s)

> To move a lead from one column to another on the Leads board:
> 
> 1. **Drag and drop** the lead row from one column to another.
> 2. When you drop the lead:
>    - It takes the **status** of the column it was dropped on.
>    - If the date for that stage is **empty**, it gets stamped with the current date (e.g., **Date Contacted** when moving to Active, **Date Drafted** when moving to Proposal Sent, or **Date Closed** when moving to Closed).
>    - If the date already has a value, it remains unchanged — this prevents overwriting history.
> 
> The lists refresh after every move, and the lead stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (3.5 s)

> Your data is stored in a single SQLite file named **w10crmdemo.sdb** located in your **Documents** folder. This file is encrypted with AES-256.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete the file **w10crmdemo.sdb** from your Documents folder.
> 3. Start the application again.
> 
> The application will recreate the file with the original sample data, including 8 leads, 8 accounts, one user, and three proposals.
> 
> Source: [Getting started](Getting-Started.md)

**Q3** (3.1 s)

> No, you cannot change a proposal after saving it. The document is stored as it was generated.
> 
> If you need to make changes, you must:
> 
> 1. **Delete** the existing proposal from the Sales list using the navigator.
> 2. **Create a new proposal**.
> 
> This applies whether you are on the Sales screen or the lead detail window. The "Complete" and "Cancel" actions only affect the proposal's status, not its content.
> 
> Source: [FAQ](FAQ.md)

**Q4** (3.2 s)

> The export that gives you a file you can open in Excel is on the **Marketing** page. It writes a **delimited text file with a header row**, which spreadsheet applications can open directly.
> 
> The exports on the **Accounts** and **Leads** pages write files in FireDAC's own format, meant to be read back by this application — not for Excel.
> 
> Source: [FAQ](FAQ.md)

**Q5** (3.2 s)

> To find a lead using only its email address:
> 
> 1. Use the **Search box** on the Leads board.
> 2. Type the email address into the search box.
> 3. The board will filter the leads in real time, showing only those matching the email address.
> 
> The search function matches against the lead's name, account name, office phone, or email — so typing an email address will find any lead associated with that email.
> 
> Source: [Leads](Leads.md)

**Q6** (2.2 s)

> I cannot provide weather information. The documentation provided does not contain any details about weather or external services.
> 
> To find the weather in Milan today, you might want to use a dedicated weather application or website such as Weather.com, AccuWeather, or check your operating system's built-in weather app.

**Q7** (3.4 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen for you. You can now view and manage the accounts in your CRM. 
> 
> The Accounts screen shows all the companies that leads belong to. From here, you can:
> - View account details
> - Add new accounts
> - Edit existing accounts
> - Search for specific accounts using the search box
> 
> Is there anything specific you'd like to do with the accounts now?

**Q8** (4.7 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I will create a new lead named Mario Rossi for the company Apollo Orange, LLC. with the email mario.rossi@example.com.
> 
> I have created the lead **Mario Rossi** for the company **Apollo Orange, LLC.** with the email **mario.rossi@example.com**.
> 
> The lead has been added to the board with the status "New" and has been assigned ID 101. The detail window for this lead is now open, where you can add additional information such as phone number or notes.
> 
> Is there anything else you'd like to do with this lead?

### claude

**warm-up** (1.3 s)

> Hello! I'm the help assistant for CRM Demo. I can explain how to use the application, for example the Dashboard counters you're looking at now, the Users drop-down, or how to find your leads. What would you like to know?

**Q1** (1.4 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates change as follows:
> 
> - If the date for that stage is still empty, it is stamped with the current time. Moving to **Active** sets Date Contacted, moving to **Proposal Sent** sets Date Drafted, and moving to **Closed** sets Date Closed.
> - If the date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it's already in does nothing.
> 
> The four lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.4 s)

> Your data is stored in one encrypted SQLite file, **w10crmdemo.sdb**, in your Documents folder. The file is encrypted with AES-256. ([Data model](Data-Model.md))
> 
> To restore the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the sample data: 8 leads, 8 accounts, one user, and three proposals.
> 
> Deleting the file also removes any changes you made, and the application has no way to undo that. ([Getting started](Getting-Started.md), [Data model](Data-Model.md))
> 
> Sources:
> [Getting started](Getting-Started.md)
> [Data model](Data-Model.md)

**Q3** (1.3 s)

> No. A saved proposal is stored as it was generated, and you can't edit its document. You can change its status: **Complete** marks it Accepted and **Cancel** marks it Canceled. Both can be applied again later. ([FAQ](FAQ.md), [Sales](Sales.md))
> 
> To redo a proposal, delete the existing one from the Sales list with the navigator, then create a new one. The lead can't have a second proposal while the first one exists. ([FAQ](FAQ.md))

**Q4** (2.0 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which a spreadsheet can open directly.
> 
> The exports on the **Accounts** and **Leads** pages write FireDAC's own format (binary, XML or JSON), meant to be read back by this application, so Excel won't open them as spreadsheets. ([FAQ](FAQ.md), [Accounts](Accounts.md))
> 
> Sources:
> [FAQ](FAQ.md)
> [Accounts](Accounts.md)

**Q5** (1.2 s)

> On the Leads board, type the e-mail address, or any part of it, into the **Search** box. The four columns filter as you type, and the search matches e-mail addresses along with names, account names and office phones. It ignores case and matches anywhere inside the value, so `example.com` will show every lead with that domain. Clear the box to see the full board again. ([Leads](Leads.md))

**Q6** (1.6 s)

> I can't help with the weather. I'm the help assistant for CRM Demo and can only answer questions about using this application. For the forecast, try a weather service or app outside of CRM Demo.
> 
> I can help with things like managing leads, accounts, proposals, users, or the Dashboard counters.

**Q7** (1.2 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.5 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the **New** column, and its detail window should be open so you can fill it in. ([Assistant](Assistant.md))

### claude-haiku-5-5

**warm-up** (1.4 s)

> Hello! I'm the help assistant for CRM Demo. I can explain how to use the application, such as the Dashboard counters, Users, and the main sections (Accounts, Leads, Sales, Marketing, Calendar). I can also create a lead for you if you give me the contact's name and the company name, which must already exist in Accounts.
> 
> What would you like to do?

**Q1** (1.7 s)

> To move a lead, drag its row from one column and drop it on another. The lead takes the status of the column you dropped it on.
> 
> Its dates follow these rules:
> 
> - If the date for the new stage is still empty, it is stamped with the current date and time. Moving a lead to **Active** sets Date Contacted, to **Proposal Sent** sets Date Drafted, and to **Closed** sets Date Closed.
> - If that date already has a value, it is left alone. Moving a lead back and forth does not rewrite its history.
> - Dropping a lead on the column it is already in does nothing.
> 
> The lists refresh after each move, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (2.1 s)

> Your data is stored in one SQLite file, **w10crmdemo.sdb**, in your Documents folder. The file is encrypted with AES-256.
> 
> To restore the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the sample data.
> 
> Deleting the file also removes any changes you have made, and the application has no other way to undo them.
> 
> Source: [Getting started](Getting-Started.md)
> Source: [Data model](Data-Model.md)

**Q3** (2.4 s)

> No. A saved proposal is stored as it was generated, so its document can't be edited. You can change its status to **Accepted** or **Canceled** with the Complete and Cancel buttons, and you can apply those again later.
> 
> To redo a proposal, delete the existing one from the Sales list using the navigator, then create a new one. The lead can't have a second proposal while the first one exists.
> 
> Source: [FAQ](FAQ.md)
> Source: [Sales](Sales.md)

**Q4** (2.3 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel opens directly.
> 
> The **Export** buttons on the Accounts and Leads pages write FireDAC's own binary, XML, or JSON format, meant to be read back by this application, not opened in a spreadsheet.
> 
> Source: [FAQ](FAQ.md)
> Source: [Accounts](Accounts.md)

**Q5** (1.1 s)

> On the Leads board, type the e-mail address, or part of it, into the **Search** box. It filters all four columns as you type and matches anywhere inside the value, ignoring case. Clear the box to see the full board again.
> 
> Source: [Leads](Leads.md)

**Q6** (0.8 s)

> I can't check the weather. The application is a CRM for managing leads, accounts, proposals and documents, and its documentation doesn't cover weather or any external information.

**Q7** (1.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.2 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead Mario Rossi (id 101) for Apollo Orange, LLC., with e-mail mario.rossi@example.com. It starts in the New column.

### claude-sonnet-5-5

**warm-up** (2.0 s)

> Hello! I can help you with using this application. You're on the **Dashboard**, which shows lead counts for the active user, one tile per status. I can also create a new lead for you. What would you like to do?

**Q1** (2.6 s)

> To move a lead, drag its row from one column and drop it on another column on the Leads board. Two things happen:
> 
> 1. **Status:** the lead takes the status of the column you dropped it on.
> 2. **Dates:** if the date for that stage is still empty, it is stamped with the current date and time. The stage dates are:
>    - **Active:** Date Contacted
>    - **Proposal Sent:** Date Drafted
>    - **Closed:** Date Closed
> 
> A date that already has a value is left alone. Moving a lead back and forth therefore doesn't rewrite its history.
> 
> Dropping a lead on the column it's already in does nothing. After each move the four lists refresh, and the lead you dragged stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (1.8 s)

> **Where your data is stored:** everything is in one SQLite file, `w10crmdemo.sdb`, in your **Documents** folder. It's encrypted with AES-256.
> 
> **How to start over with the sample data:**
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (CRMUser) and three proposals.
> 
> Deleting the file can't be undone. The application has no other way to undo changes and no rollback.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (2.0 s)

> **No, a saved proposal can't be edited.** The document is stored exactly as it was generated. You can only change its status:
> 
> - **Complete** marks it Accepted and stamps DateCompleted with now.
> - **Cancel** marks it Canceled and leaves the completion date alone.
> 
> Both buttons are in the banner of the Sales screen, and also in the lead detail window. Neither asks for confirmation. Since nothing is locked once a proposal is accepted, you can apply either one again later.
> 
> **To redo a proposal:**
> 1. On the Sales list, delete the existing proposal with the navigator.
> 2. Create a new one. A lead can't have a second proposal, so the old one has to go first.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (1.3 s)

> **Use the export on the Marketing page.** It writes a delimited text file with a header row, which a spreadsheet such as Excel opens directly.
> 
> The exports on the Accounts and Leads pages don't work for this. They write FireDAC's own format (binary, XML or JSON, depending on the extension), which is meant to be read back by this application. It isn't a spreadsheet file.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (1.5 s)

> Use the **Search** box on the Leads board, which you're on now.
> 
> 1. Click the Search box.
> 2. Type the e-mail address, or just part of it.
> 
> It filters all four columns at once as you type. It ignores case and matches anywhere inside the value, so `example.com` finds everybody with that domain. It also searches the lead's name, account name and office phone.
> 
> Clear the box to get the full board back.
> 
> Source: [Leads](Leads.md)

**Q6** (1.4 s)

> I can't help with the weather. I only explain how to use this application, and the documentation doesn't cover weather or any other outside information.
> 
> I can help with the app itself. For example, I can explain the Dashboard tiles you're looking at, or how to work with leads, accounts or proposals.

**Q7** (1.5 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is now open.

**Q8** (2.2 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for Apollo Orange, LLC., with the e-mail mario.rossi@example.com. It starts with status New, and its detail window should open so you can fill in the rest.
> 
> Source: [Asking the assistant](Assistant.md)

### claude-opus-5-5

**warm-up** (2.2 s)

> Hello! I'm the in-app help assistant. You're on the **Dashboard**, which shows how many leads the active user has, with one tile for each status (New, Active, Proposal Sent, Closed, Inactive, and Total) ([Dashboard](Dashboard.md)).
> 
> What would you like to know or do? For example, I can explain how the screens work or create a new lead for you.

**Q1** (3.8 s)

> **To move a lead**, drag its row from one column and drop it on another column of the board.
> 
> **What happens when you drop it:**
> 1. The lead takes the status of the column you dropped it on.
> 2. If that stage's date is still empty, it gets set to the current date and time:
>    - Moving to **Active** sets **Date Contacted**
>    - Moving to **Proposal Sent** sets **Date Drafted**
>    - Moving to **Closed** sets **Date Closed**
> 3. If that date already has a value, it stays the same. Moving a lead back and forth doesn't change the dates it already has.
> 
> **Also good to know:**
> - If you drop a lead on the column it's already in, nothing happens.
> - After each move, all four columns refresh and the lead you moved stays selected.
> 
> Source: [Leads](Leads.md)

**Q2** (3.1 s)

> **Where your data is stored**
> 
> Everything is in one SQLite file, `w10crmdemo.sdb`, in your **Documents** folder. The file is encrypted with AES-256. The application creates it the first time you start it, and every later run just opens that same file.
> 
> **How to start over with the sample data**
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again. It rebuilds the file with the original sample data: 8 leads, 8 accounts, one user (`CRMUser`) and three proposals.
> 
> **Before you delete it:** this is the only way to undo anything. The application has no rollback, and most deletes don't ask for confirmation. Deleting the file erases everything you've entered.
> 
> Sources: [Data model](Data-Model.md), [Getting started](Getting-Started.md)

**Q3** (3.5 s)

> **No, you can't edit a saved proposal.** The document stays exactly as it was when it was generated. Its **Value** also stays at the invoice total from the moment you saved it.
> 
> **What you can still do:**
> - **Change its status:** select it in the Sales list and press **Complete** (sets it to Accepted and records the completion date as now) or **Cancel** (sets it to Canceled). Neither button asks for confirmation. You can press either one again later, even after a proposal is accepted.
> - **Redo it:** a lead can't have a second proposal. To replace one, first delete the existing proposal from the Sales list using the navigator, then create a new one for the lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (2.2 s)

> Use the export on the **Marketing** page. It saves a delimited text file with a header row, and Excel can open that directly.
> 
> The **Export** buttons on the **Accounts** and **Leads** pages save in FireDAC's own format, not as a spreadsheet. That format is meant to be opened again by this application. On the Accounts page, Export also saves the whole table even if you've filtered the list.
> 
> Sources: [FAQ](FAQ.md), [Accounts](Accounts.md)

**Q5** (3.8 s)

> Use the **Search** box on the **Leads** board:
> 
> 1. Type all or part of the e-mail address into **Search**. All four columns filter as you type.
> 2. The search ignores upper and lower case and matches text anywhere in the address. For example, typing `example.com` finds everyone with that domain.
> 3. Double-click the lead you find, or select it and press **View Lead**, to open it.
> 4. Clear the box to see the full board again.
> 
> Search also matches the lead's name, account name and office phone. That means a short piece of text might also show leads that match on one of those instead of the e-mail. The **E-mail** column only appears in the **Active** column, but leads in the other columns are still found by their e-mail.
> 
> Source: [Leads](Leads.md)

**Q6** (1.7 s)

> I can't help with the weather. I can only answer questions about using this CRM application. The application doesn't provide weather information. According to its documentation, it runs entirely from a local file and doesn't need a network connection.
> 
> If you have a question about the app, like what the tiles on this **Dashboard** count, I'm happy to help.

**Q7** (1.8 s)

- action `open_screen` {"name": "Accounts"} -> Opened the Accounts screen.

> The Accounts screen is open now.

**Q8** (3.3 s)

- action `create_lead` {"name": "Mario Rossi", "account": "Apollo Orange, LLC.", "email": "mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> I created the lead **Mario Rossi** (id 101) for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`. It starts with the status **New** and its detail window opens, so you can add anything else there ([Asking the assistant](Assistant.md)).

### gemini

**warm-up** (0.8 s)

> Hello! How can I help you use the application today?

**Q1** (1.0 s)

> You can move a lead from one column to another by using drag and drop: drag a row from one column and drop it on another [Leads](Leads.md). 
> 
> When you move a lead:
> * The lead takes the status of the column you dropped it on [Leads](Leads.md).
> * If the date for that stage is still empty, it is stamped with the current time (Date Contacted when moving to Active, Date Drafted when moving to Proposal Sent, or Date Closed when moving to Closed) [Leads](Leads.md).
> * A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history [Leads](Leads.md).
> * Dropping a lead on the column it is already in does nothing [Leads](Leads.md).

**Q2** (0.9 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, and it is encrypted with AES-256 [Data model](Data-Model.md). 
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md).
> 3. Start the application again [Getting started](Getting-Started.md).

**Q3** (0.9 s)

> No, you cannot change a proposal after it has been saved [FAQ](FAQ.md). The document is stored as it was generated [FAQ](FAQ.md). 
> 
> However, you can mark it as Accepted or Canceled, though the lead cannot be given a second one [FAQ](FAQ.md). If you need to redo a proposal, delete the existing one from the Sales list with the navigator and create a new one [FAQ](FAQ.md).

**Q4** (0.8 s)

> For something you can open in Excel, use the export on the Marketing page, which writes a delimited text file with a header row that a spreadsheet opens directly [Accounts](Accounts.md), [FAQ](FAQ.md).

**Q5** (0.9 s)

> To find a lead by its e-mail address, use the **Search** box on the Leads screen [Leads](Leads.md). As you type, the search box filters all four columns at once, ignoring case and matching anywhere inside the value—so typing an e-mail domain like `example.com` will find everybody with that address [Leads](Leads.md). Clear the box to get the full board back [Leads](Leads.md).

**Q6** (0.8 s)

> The documentation excerpts do not cover the weather in Milan.

**Q7** (1.3 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (1.5 s)

- action `create_lead` {"name":"Mario Rossi","email":"mario.rossi@example.com","account":"Apollo Orange, LLC."} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi at Apollo Orange, LLC.

### gemini-4-argon

**warm-up** (5.4 s)

> Hello! How can I help you with the application today? You are currently on the **Dashboard** screen. Feel free to ask how anything works or tell me what you would like to do.

**Q1** (6.3 s)

> To move a lead on the **Leads** board, **drag a row from one column and drop it on another**. Dropping a lead onto the column it is already in does nothing. After a move, the four lists refresh and the moved lead stays selected.
> 
> When you drop a lead into a new column, its status changes to match that column and its dates are updated as follows:
> * **If the date for that stage is empty**, it is stamped with the current date and time:
>   * Moving to **Active** stamps **Date Contacted**.
>   * Moving to **Proposal Sent** stamps **Date Drafted**.
>   * Moving to **Closed** stamps **Date Closed**.
> * **If that date already has a value**, it is left unchanged so that moving a lead back and forth does not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (5.3 s)

> All your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb`, located in your **Documents** folder.
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again — it will automatically recreate the file with the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (5.6 s)

> No, you cannot edit a proposal's document or contents after saving it, and a lead cannot be given a second proposal while one exists.
> 
> What you can do instead:
> * **Change its status:** Use the **Complete** button (to set the status to **Accepted** and stamp **DateCompleted**) or the **Cancel** button (to set the status to **Canceled**) in the **Sales** banner or the lead detail window.
> * **Redo the proposal:** Delete the existing proposal from the **Sales** list using the navigator, and then create a new one for the lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (10.0 s)

> Use the export on the **Marketing** page: it writes a delimited text file with a header row that you can open directly in Excel.
> 
> The exports on the **Accounts** (which you are currently on) and **Leads** pages are not spreadsheet files — they save data in FireDAC's own format (binary, XML, or JSON depending on the file extension), which is meant to be read back by this application.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (8.7 s)

> On the **Leads** screen (which you are currently on), type the e-mail address—or part of it—into the **Search** box. 
> 
> As you type, the **Search** box filters all four columns (**New**, **Active**, **Proposal Sent**, and **Closed**) at once. It matches case-insensitively anywhere inside the lead's e-mail address (as well as their name, account name, or office phone). Clear the box when you want to see the full board again.
> 
> *(Note: Even though the **Email** column is only displayed directly in the **Active** column, the search matches against the e-mail address across all four columns.)*
> 
> Source: [Leads](Leads.md)

**Q6** (5.9 s)

> I can only help you with how to use this application, so I do not have access to weather information. Let me know if you have any questions about using the app!

**Q7** (16.8 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen for you.

**Q8** (19.8 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead **Mario Rossi** for **Apollo Orange, LLC.** with the e-mail `mario.rossi@example.com`.

### gemini-4-carbon

**warm-up** (7.2 s)

> Hello! I am Assistant, your in-app help assistant. How can I help you use the application today?

**Q1** (8.2 s)

> To move a lead on the **Leads** board, **drag its row** from one column and **drop it** onto another. The lead takes the status of the target column, the four lists refresh, and the moved lead stays selected (dropping it onto its current column does nothing).
> 
> Here is what happens to its dates:
> 
> - If the date for the new stage is still empty, it is stamped with the current date and time:
>   - Moving to **Active** sets **Date Contacted**.
>   - Moving to **Proposal Sent** sets **Date Drafted**.
>   - Moving to **Closed** sets **Date Closed**.
> - If a date already has a value, it is **left unchanged**, so moving a lead back and forth does not overwrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (9.0 s)

> All your data is stored in a single AES-256 encrypted SQLite file named `w10crmdemo.sdb` inside your **Documents** folder.
> 
> To start over with the original sample data:
> 
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your **Documents** folder.
> 3. Start the application again — it will recreate the file and reload the sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (13.7 s)

> No, you cannot edit a proposal document after saving it, and a lead cannot be given a second one. Once saved, you can only change its status using **Complete** (sets it to `Accepted`) or **Cancel** (sets it to `Canceled`).
> 
> If you need to redo a proposal:
> 1. Delete the existing proposal from the **Sales** list (the screen you are currently on) using the navigator.
> 2. Create a new proposal for the lead.
> 
> Sources: [FAQ](FAQ.md), [Sales](Sales.md)

**Q4** (16.7 s)

> Use the export on the **Marketing** page. It writes a delimited text file with a header row, which Excel can open directly.
> 
> By contrast, the **Export** button on the **Accounts** screen (where you are now) and on the **Leads** page saves files in FireDAC's own format (binary, XML, or JSON depending on the file extension), which is meant to be read back by this application rather than opened in a spreadsheet.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (23.8 s)

> On the **Leads** screen (where you are now), type the e-mail address—or part of it—into the **Search** box.
> 
> - It filters all four columns (**New**, **Active**, **Proposal Sent**, and **Closed**) at once as you type, matching anywhere inside the e-mail address and ignoring case.
> - Even though only the **Active** column displays the **Email** column on the board, matching leads in the other columns will still appear. Double-click a result (or select it and click **View Lead**) to open its detail window.
> - Clear the **Search** box to show the full board again.
> 
> *(Note: Leads with the `Inactive` status do not have a column on the Leads board.)*
> 
> Source: [Leads](Leads.md)

**Q6** (8.5 s)

> I can only explain how to use this application, and the documentation does not cover weather information. Let me know if you have any questions about the CRM!

**Q7** (31.6 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the **Accounts** screen for you.

**Q8** (16.0 s)

- action `create_lead` {"email":"mario.rossi@example.com","account":"Apollo Orange, LLC.","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead **Mario Rossi** (ID 101) for **Apollo Orange, LLC.** with the e-mail address `mario.rossi@example.com`.

### gemini-pro-latest

**warm-up** (4.9 s)

> Hello! I am the in-app help assistant for the CRM Demo application. How can I help you today?

**Q1** (5.2 s)

> To move a lead, drag its row from one column and drop it onto another. 
> 
> When you move a lead, here is what happens to its dates:
> * If the date for the stage you dropped it on (Date Contacted, Date Drafted, or Date Closed) is empty, it is stamped with the current time.
> * If that date already has a value, it is left alone, so moving a lead back and forth does not rewrite its history.
> 
> Source: [Leads](Leads.md)

**Q2** (6.2 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb`, located in your Documents folder, and is encrypted with AES-256.
> 
> To start over with the sample data:
> 1. Close the application.
> 2. Delete the `w10crmdemo.sdb` file.
> 3. Start the application again. It will rebuild the file with the original sample data.
> 
> Sources: [Getting started](Getting-Started.md), [Data model](Data-Model.md)

**Q3** (5.4 s)

> No. You cannot edit a proposal after it has been saved, as the document is stored exactly as it was generated. 
> 
> To redo a proposal, you must delete the existing one from the Sales list using the navigator, and then create a new one.
> 
> Source: [FAQ](FAQ.md)

**Q4** (5.8 s)

> To get a file you can open in Excel, use the export on the **Marketing** page. It writes a delimited text file with a header row that a spreadsheet can open directly. 
> 
> The exports on the Accounts and Leads pages write FireDAC's own format (binary, XML, or JSON), which is meant to be read back by the application and is not a spreadsheet file.
> 
> Sources: [Accounts](Accounts.md), [FAQ](FAQ.md)

**Q5** (7.0 s)

> To find a lead using its e-mail address, simply type the e-mail address into the **Search** box on the Leads board. 
> 
> The Search box filters all four columns at once as you type, and it matches your text against the lead's e-mail address (as well as their name, account name, or office phone), ignoring case.
> 
> Source: [Leads](Leads.md)

**Q6** (3.0 s)

> The documentation does not cover the weather.

**Q7** (7.5 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (7.6 s)

- action `create_lead` {"email":"mario.rossi@example.com","account":"Apollo Orange, LLC.","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead for Mario Rossi at Apollo Orange, LLC., and set the e-mail address.

### gemini-3.5-flash-lite

**warm-up** (1.0 s)

> Hello! How can I help you use the application today?

**Q1** (1.1 s)

> To move a lead, drag and drop a row from one column onto another [Leads](Leads.md). 
> 
> When you move a lead:
> * The lead takes the status of the column you dropped it on [Leads](Leads.md).
> * If the date for that stage is still empty, it is stamped with the current time (e.g., Date Contacted for Active, Date Drafted for Proposal Sent, Date Closed for Closed) [Leads](Leads.md).
> * A date that already has a value is left alone, so moving a lead back and forth does not rewrite its history [Leads](Leads.md).
> * Dropping a lead on the column it is already in does nothing [Leads](Leads.md).

**Q2** (0.8 s)

> Your data is stored in a single SQLite file named `w10crmdemo.sdb` located in your Documents folder, and it is encrypted with AES-256 [Data model](Data-Model.md).
> 
> To start over with the original sample data:
> 1. Close the application [Getting started](Getting-Started.md).
> 2. Delete the `w10crmdemo.sdb` file from your Documents folder [Getting started](Getting-Started.md).
> 3. Start the application again [Getting started](Getting-Started.md).

**Q3** (0.7 s)

> No, you cannot edit a proposal after it has been saved because the document is stored as it was generated [FAQ](FAQ.md). 
> 
> However, you can mark it as Accepted or Canceled, and if you need to redo a proposal, you can delete the existing one from the Sales list using the navigator and then create a new one [FAQ](FAQ.md). (Note that a lead cannot be given a second proposal while one already exists [FAQ](FAQ.md).)

**Q4** (0.7 s)

> For a file you can open in Excel, use the export on the Marketing page, which writes a delimited text file with a header row that a spreadsheet opens directly [Accounts](Accounts.md), [FAQ](FAQ.md).

**Q5** (0.6 s)

> Type in the **Search** box on the Leads board, as it filters all four columns at once and matches anywhere inside the value against the e-mail address [Leads](Leads.md).

**Q6** (0.9 s)

> The documentation excerpts do not cover the weather.

**Q7** (1.2 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> I have opened the Accounts screen for you.

**Q8** (1.7 s)

- action `create_lead` {"account":"Apollo Orange, LLC.","email":"mario.rossi@example.com","name":"Mario Rossi"} -> Created the lead Mario Rossi (id 101).

> I have created the lead Mario Rossi for Apollo Orange, LLC.

### gpt-6-luna

**warm-up** (2.8 s)

> Hello! How can I help you use the application?

**Q1** (2.2 s)

> Drag the lead’s row from its current column and drop it in the column you want. Its status changes to match that column.
> 
> If the date for the new stage is empty, it’s stamped with the current date and time: **Date Contacted** for Active, **Date Drafted** for Proposal Sent, or **Date Closed** for Closed. If that date already has a value, it’s left unchanged, so moving a lead back and forth won’t rewrite its history. Dropping it in its current column does nothing. [Leads](Leads.md)

**Q2** (1.8 s)

> Your data is stored in `w10crmdemo.sdb` in your **Documents** folder, encrypted with AES-256.
> 
> To restore the original sample data, close the application, delete `w10crmdemo.sdb`, then start the application again. It will recreate the file with the sample data. **This resets all data in that file**, and there’s no other undo method. [Getting started](Getting-Started.md) [Data model](Data-Model.md)

**Q3** (2.5 s)

> No. A saved proposal is stored as generated and can’t be edited, and its lead can’t be given a second proposal. To redo it, delete the existing proposal from the Sales list with the navigator, then create a new one. [FAQ](FAQ.md)

**Q4** (2.8 s)

> Use the **Export** on the **Marketing** page. It creates a delimited text file with a header row that Excel can open. The export on the Accounts page uses the application’s own format instead. [FAQ](FAQ.md) [Accounts](Accounts.md)

**Q5** (2.2 s)

> On the Leads screen, type the e-mail address—or just part of it—into the **Search** box. It filters all four columns as you type and matches e-mail addresses without regard to case. Clear the box to show the full board again. [Leads](Leads.md)

**Q6** (2.9 s)

> I can’t provide today’s weather in Milan; the information available to me doesn’t include weather data.

**Q7** (2.0 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> The Accounts screen is open.

**Q8** (2.6 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC." ,"email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** for **Apollo Orange, LLC.**, with e-mail `mario.rossi@example.com`.

### gpt-6.1-sol

**warm-up** (1.5 s)

> Hello! How can I help you use the application?

**Q1** (2.5 s)

> **Drag the lead’s row from its current column and drop it into the destination column.** Its status changes to match that column.
> 
> If the destination stage’s date is empty, it is set to the current date and time:
> - **Active:** Date Contacted
> - **Proposal Sent:** Date Drafted
> - **Closed:** Date Closed
> 
> Existing dates are left unchanged, so moving a lead back and forth does not rewrite its history. Dropping it into its current column does nothing. [Leads](Leads.md)

**Q2** (2.8 s)

> Your data is stored in **`w10crmdemo.sdb` in your Documents folder**. It is a single SQLite file encrypted with AES-256. [Data model](Data-Model.md)
> 
> To start over with the original sample data:
> 1. Close the application.
> 2. Delete `w10crmdemo.sdb` from your Documents folder.
> 3. Start the application again.
> 
> **This removes your current data.** The application rebuilds the file with 8 leads, 8 accounts, one user and three proposals. [Getting started](Getting-Started.md)

**Q3** (2.1 s)

> No—the saved proposal document cannot be edited, and a lead cannot have a second proposal. To redo it, **delete the existing proposal from the Sales list using the navigator**, then create a new one. [FAQ](FAQ.md)
> 
> You can still change its status: **Complete** marks it Accepted and sets the completion date to now; **Cancel** marks it Canceled without changing that date. Neither asks for confirmation. [Sales](Sales.md)

**Q4** (2.4 s)

> Use the **export on the Marketing page**. It creates a delimited text file with a header row that Excel can open directly.
> 
> The exports on **Accounts** (your current screen) and **Leads** use FireDAC’s own format, not a spreadsheet format. [FAQ](FAQ.md)

**Q5** (2.1 s)

> On the **Leads** screen, type the e-mail address—or part of it—into the **Search** box. It filters all four columns as you type, matching anywhere in the address and ignoring case.
> 
> Double-click a matching row to open the lead. Clear the Search box to restore the full board. [Leads](Leads.md)

**Q6** (2.4 s)

> I can only help with using this application. The provided documentation does not cover weather in Milan.

**Q7** (3.1 s)

- action `open_screen` {"name":"Accounts"} -> Opened the Accounts screen.

> Opened the Accounts screen.

**Q8** (3.3 s)

- action `create_lead` {"name":"Mario Rossi","account":"Apollo Orange, LLC.","email":"mario.rossi@example.com"} -> Created the lead Mario Rossi (id 101).

> Created the lead **Mario Rossi** for **Apollo Orange, LLC.** with e-mail **mario.rossi@example.com**.

