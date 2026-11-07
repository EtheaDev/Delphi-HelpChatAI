# Local LLMs available for comparative tests (Ollama)

Written 2026-11-06 by the Claude session that set up the local LLM environment in `D:\LocalLLM`
(see `D:\LocalLLM\README.md`). It is versioned in SVN as the record of the work done with the
local models (2026-11-06/07): the environment, the benchmark, how the prompt was tuned and
measured. It is not part of the library, and the GitHub sync does not publish it (it copies
only `Test/source`, `Test/Delphi13` and `Test/data`): keep it that way, it names a machine
and an address of the internal LAN.

## What is running

Ollama 0.40.15 runs natively on this machine (no Docker), starts at login and listens on
`http://localhost:11434`. Its OpenAI-compatible endpoint is `http://localhost:11434/v1`, which is
exactly what the `openai` provider of HelpChatAI speaks (`BaseUrl` + `Model`, no key).

The same server is reachable from the internal LAN as `http://192.168.1.10:11434/v1` (host ETHEASERVER, static IP), once the Windows firewall rule in `D:\LocalLLM\Firewall-Ollama-LAN.ps1` is in place: useful to test the HelpChatAI server or a client on another machine. No authentication.

| Model (`Model` value) | Good for | VRAM | Speed (measured) | Notes |
|---|---|---|---|---|
| `gemma4:12b` | general chat, best Italian, vision | 8.8 GB | ~100 tok/s | reasoning on by default (streamed as `delta.reasoning`, which the provider ignores) |
| `gpt-oss:20b` | reasoning, tool use, agentic | 12.4 GB | ~90 tok/s | reasons in English before answering (`delta.reasoning`) |
| `qwen3-coder:30b` | coding, tool use | 13.5 GB + RAM | ~55 tok/s | MoE; the cleanest tool caller of the three in a quick test |

GPU: RTX 5060 Ti 16 GB. **Only one model is resident at a time** (`OLLAMA_MAX_LOADED_MODELS=1`):
switching model costs 12-20 s, so comparative tests should run per model, not interleaved.
Context is 8192 tokens (`OLLAMA_CONTEXT_LENGTH`); HelpChat grounding (3 pages x 2000 chars) +
system prompt + history fits.

Known Ollama bug on this GPU family (Blackwell, issues ollama/ollama#19122, #17380, #18276): a
model load can die with `CUDA error: shared object initialization failed` (HTTP 500). The
workaround `CUDA_MODULE_LOADING=EAGER` is set as a user environment variable and made 14/14
loads succeed; if a test ever gets that 500, check the variable reached the Ollama process
(`%LOCALAPPDATA%\Ollama\server.log`) rather than blaming the provider.

## Verified against the endpoint the provider uses

A request shaped like `THelpChatOpenAIProvider.BuildRequestBody` (system + user, `tools`,
`stream: true`, `stream_options.include_usage`) returns HTTP 200 and a well-formed SSE stream
with a final `usage` chunk and `data: [DONE]` for all three models. `tool_calls` with
`finish_reason: "tool_calls"` was observed with `qwen3-coder:30b`. A non-streaming tool-call
request returned HTTP 500 (empty body) once for `gemma4:12b` and `gpt-oss:20b`: the provider
always streams, so it does not matter for HelpChatAI, but keep it in mind for ad-hoc scripts.

## How to point HelpChatAI at them

1. `%APPDATA%\HelpChatAI\helpchatai.json` (the `SharedUserConfigFile`) now contains an
   `OpenAI` section with `BaseUrl: http://localhost:11434/v1` and `Model: gemma4:12b`.
   `Provider` was left as it was: switch it to `openai` where you want the local model.
2. Ready-made per-model files: `D:\LocalLLM\helpchatai\helpchatai.<model>.json`
   (`Provider: openai`, `ResponseTimeoutMs: 300000`). Copy one next to the executable
   (`AppConfigFile`) or to `%APPDATA%\<ExeName>\helpchatai.json` (`UserConfigFile`, highest priority).
3. The CRM demos link `docsearch`, `claude` and `openai` (`uMainForm.pas` and
   `uMainFormFmx.pas`), and `gemini` (since 2026-11-07), so every entry of the `Assistants` list answers there. `HelpChatAIServerApp` links all four providers.
4. `Test/source/HelpChatAI.Tests.OpenAI.pas` already has a `localhost:11434/v1` case for the
   URL; live tests against the models can set `Settings.OpenAI.BaseUrl` to it and need no key.

5. Since 1.5.0 the shared file also carries an `Assistants` list: see below. The per-model
   files of step 2 are no longer needed to try a local model.

## Choosing the model from the chat (since 1.5.0)

The user can now pick the model in the panel, when more than one is configured. The shared
file `%APPDATA%\HelpChatAI\helpchatai.json` lists five assistants:

```json
"Assistant": "Claude",
"Assistants": [
  { "Name": "Claude",              "Provider": "claude", "Model": "claude-haiku-4-5" },
  { "Name": "Gemini",              "Provider": "gemini", "Model": "gemini-3.8-flash" },
  { "Name": "Gemma (locale)",      "Provider": "openai", "Model": "gemma4:12b" },
  { "Name": "GPT-OSS (locale)",    "Provider": "openai", "Model": "gpt-oss:20b" },
  { "Name": "Qwen Coder (locale)", "Provider": "openai", "Model": "qwen3-coder:30b" }
]
```

The three local ones take the endpoint of the `OpenAI` section (`http://localhost:11434/v1`).
In the panel the icon of the assistant in use is the last button on the right of the header:
hovering it shows name and model, clicking it opens the list, and the one picked answers from
the next question on. The choice is remembered in `helpchatai-state.json` next to the
conversation. From the question box, `/who` says which model is answering, `/use gemma`
switches, `/retry claude` asks the last question again to another model - the quickest way
to compare two answers by hand. With one assistant only, or none listed, nothing can be
switched. Switching to another local model costs the 12-20 s of loading it into the VRAM.

From another PC of the LAN: Ollama listens on `0.0.0.0:11434` and the firewall lets
`ollama.exe` in on the Private profile, so the same list with
`"BaseUrl": "http://192.168.1.10:11434/v1"` works there. No key: anybody on the LAN can use
the models.

## How the prompts of the assistant were improved with these models (2026-11-06)

The local models were the test bench for the system prompt of HelpChatAI: three of them plus
`claude` and `gemini` as references, the same questions, the measured difference between them.

1. **A repeatable benchmark first.** `Test\LLMBench` (console, Delphi 13,
   `Test\Bin\Win32\HelpChatAILLMBench.exe`) runs the real engine grounded on
   `CRM Demo\Help\help-index.json`, with two actions of the demo (`open_screen`, and
   `create_lead` confirmed with Yes), on eight fixed questions: five answered by one page of
   the manual, one the manual does not cover (the weather), two that ask for an action. All in
   English, because the demo, its manual and its UI are English. For every answer it measures
   time to the first token and to the end, the pages cited (`Page.md` in the text), the expected
   facts present, and the actions called with their arguments. The targets run **one after the
   other** - the three local models first, so that Ollama loads each one once - with a warm-up
   question each that absorbs the load. `--only=gemma,claude` picks some, `--out=` names the
   report.
2. **A baseline run** (`Test\LLMBench\results\llm-bench-full.md`), then reading the
   answers, not only the scores. What went wrong, by model:
   - citations in a form of their own: by title ("See Getting Started"), "based on the Leads
     documentation" without a link, footnotes, an invented `https://github.com/your-docs/` base;
   - pages listed at random under the weather question, because the prompt said "point the user
     to the documentation link" when the excerpts do not cover the question;
   - `gpt-oss` asking for the optional phone and notes instead of calling `create_lead`;
   - `qwen3-coder` calling `open_screen` while answering a question, and repeating its answer
     after every tool round.
3. **Each defect traced to a sentence of the prompt** (`BuildSystemPrompt` in
   `HelpChatAI.Provider`, the constants in `HelpChatAI.Settings`), and fixed there:
   - the source line of each excerpt became a Markdown link to copy, `Source: [Leads](Leads.md)`,
     instead of a bare `Leads.md`: models copy what they see;
   - "cite it with the link written on its Source line, copied exactly; never change, complete
     or invent a URL; cite only the pages you used, and none when the documentation does not
     cover the question", replacing "point the user to the documentation link";
   - the actions rule: "ask only for the required parameters you are missing, leave out the
     optional ones", "never open, show or check something with a tool while answering a
     question", "without repeating an answer you already gave";
   - the demo's `open_screen` description says when it is meant to be used.
4. **The same run again** (`llm-bench-full-v2.md`) and the two reports compared:

   | Model | Citations ok | Facts | Actions ok | Avg time |
   |---|---:|---:|---:|---:|
   | gemma4:12b | 7/8 -> 8/8 | 11/11 | 8/8 | 6.4 -> 5.3 s |
   | gpt-oss:20b | 6/8 -> 8/8 | 11/11 | 7/8 | 3.0 -> 3.5 s |
   | qwen3-coder:30b | 7/8 -> 4/8 | 10/11 -> 11/11 | 5/8 -> 6/8 | 5.6 -> 4.9 s |
   | claude-haiku-4-5 | 7/8 -> 8/8 | 11/11 | 8/8 | 2.0 -> 1.9 s |
   | gemini-3.8-flash | 7/8 -> 8/8 | 11/11 | 8/8 | 4.7 -> 4.5 s |

5. **What was left, and why it stays.** `gpt-oss` still asks for the optional parameters,
   although the schema declares them optional and the rule now says so: it is how that model
   treats tools, and in a real chat the action follows at the next turn. `qwen3-coder` stopped
   citing in text answers and still opens screens on its own: with these tools it is the least
   suited of the three as an assistant. The repetition after a tool round could only be cut in
   the provider loop, and was not, because with Claude and Gemini that text is useful.
6. **The suite updated with the prompt** (`HelpChatAI.Tests.Claude` checks the Markdown source
   line) and the reports kept in `Test\LLMBench\results` for the next comparison. Rerun the
   benchmark after any change to the prompt or to a provider: the scores are mechanical, so read
   the answers of the ones that drop.

7. **A third run, same prompt (2026-11-07)** (`llm-bench-full-v3.md`): Claude went from 8/8
   citations back to 6/8, gpt-oss from 8/8 to 6/8, Gemini from 8/8 to 7/8. Claude wrote
   "according to the documentation" without the link, gpt-oss "Source: **Leads** documentation"
   and "Source: FAQ". The prompt improved the citations but cannot make them certain: two runs
   of the same prompt differ.
8. **The engine makes the citation certain** (`HelpChatSourcesLine` in `HelpChatAI.Provider`,
   called by the runner on the final reply). When a reply of `claude`, `openai` or `gemini`
   links none of the pages the model was given but names one of them by its title or file
   name, the engine appends `Source: [Leads](Leads.md)` itself, in the language of the panel
   and through the stream. Nothing is added when the model linked a page, when the reply names
   none (the weather question: no invented source), or after an action.
9. **A fourth run with it** (`llm-bench-full-v4.md`), compared with the third:

   | Model | Citations, same prompt | Citations, with the line | Facts | Actions | Avg time |
   |---|---:|---:|---:|---:|---:|
   | gemma4:12b | 8/8 | 8/8 | 11/11 | 8/8 | 4.2 s |
   | gpt-oss:20b | 6/8 | 8/8 | 10/11 | 7/8 | 2.7 s |
   | qwen3-coder:30b | 4/8 | 6/8 | 11/11 | 6/8 | 5.0 s |
   | claude-haiku-4-5 | 6/8 | 8/8 | 11/11 | 8/8 | 1.8 s |
   | gemini-3.8-flash | 7/8 | 7/8 | 11/11 | 8/8 | 4.4 s |

   What is still marked wrong is not about the line: Gemini links the assistant page by itself
   after creating the lead (a citation where none was expected), the two qwen answers left name
   no page at all, and gpt-oss still asks for the optional parameters instead of creating the
   lead. Across the four runs `gemma4:12b` is the only local model that was right on everything
   every time, and it got faster (6.4 s on average in the first run, 4.2 s in the fourth).

`/search words` in the panel (since 1.5.0) shows the pages the retriever would ground an answer
on, and `/prompt` (off by default: `EnabledCommands`) the whole system prompt of the last
question: the two tools to start from when an answer misses a page.

Delphi 12 (23.0) and 13 (37.0) are installed under `C:\BDS\Studio`.

## Useful commands

    ollama list                                   # installed models
    ollama ps                                     # what is loaded, GPU/CPU split
    curl http://localhost:11434/v1/models         # the OpenAI-style model list
    ollama run gemma4:12b                         # interactive chat for a quick sanity check
