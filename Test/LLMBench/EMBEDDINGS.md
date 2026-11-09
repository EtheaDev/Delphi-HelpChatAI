# Semantic retrieval with embeddings - analysis and measurement brief

Brief for the agent working on the Ethea server, where Ollama runs. **Phase 1 is a
measurement, not an implementation**: nothing under `source/` changes until the numbers say it
is worth it and the owner of the repository has decided who writes the Delphi code. Two agents
editing the same units over SVN have already collided once: `svn update` before every commit,
and read what the other one committed.

## 1. The problem

Every answer is grounded on the excerpts that `THelpChatDocIndex.Search`
(`source/HelpChatAI.DocIndex.pas`, line ~611) returns. `BuildSystemPrompt`
(`source/HelpChatAI.Provider.pas`, line ~484) calls it with the last user message and the
screen label as hint (`AContext.SearchHint`), and pastes the top pages into the system prompt.

The search is **lexical**:

- `Tokenize` lower-cases and splits the text and drops `STOPWORDS` (English and Italian).
- `StemToken` truncates a token to 5 or 6 characters, which is "language-neutral" only in the
  sense that it knows no language.
- Each token is scored by prefix occurrences in title (x6), keywords (x3) and body (capped at
  5), weighted by an idf; the hint tokens weigh x2. Top 3 pages by default.
- The index (`CRM Demo/Help/help-index.json`, built by `HelpChatAI.IndexBuilder` /
  `Tools/HelpIndexBuilder`) has **one entry per page**, not per section.

Consequence, deduced from the code and **never measured**: a question in a language other than
the manual's shares almost no tokens with it. "Come sposto un lead in un'altra colonna?" against
an English manual matches "lead" and little else; "Dove sono salvati i miei dati?" matches
nothing. The model then receives the wrong excerpts, or none, and answers "the documentation
does not cover this" - the honest answer to the wrong excerpts. The same weakness exists in one
language for synonyms and paraphrases ("remove" vs "delete", "company" vs "account").

The library supports an English manual with Italian users (`THelpChatLanguage`, the language
rule in `HELPCHAT_MODEL_DEF_LANGUAGE_RULE`), so this is a real use case, not a corner.

## 2. The hypothesis

A multilingual embedding model maps texts with the same meaning to nearby vectors, whatever the
language and the wording. Ranking the documentation by cosine similarity between the question
vector and the vector of each chunk should find the right page across languages and through
paraphrases.

Embeddings alone are weak where the lexical search is strong: exact names (`w10crmdemo.sdb`),
codes, the literal caption of a button. So the candidate to beat is **hybrid**: both rankings,
fused (Reciprocal Rank Fusion, `score = sum 1/(k + rank)`, k = 60, is the usual start; a
weighted sum of normalised scores is the alternative).

## 3. Measurement protocol

Everything in Python (3.x, standard library + `requests` or `urllib`; `numpy` optional), under
`Test/LLMBench/embeddings/`. Results in `Test/LLMBench/results/`.

### 3.1 The corpus

The CRM demo manual, `CRM Demo/Help/*.md` (16 pages). Measure two chunkings:

- **page**: one vector per page, the same granularity as today's index;
- **section**: split on `##`/`###` headings, each chunk prefixed with the page title and the
  heading path ("Leads > Moving a lead"); a page ranks with its best chunk.

Long chunks: check the context length of the model (bge-m3 takes 8192 tokens) and say what
happened to any chunk that exceeded it.

### 3.2 The questions

Start from the five grounded questions of `HelpChatAI.LLMBench.pas` (`AddDefaultQuestions`,
Q1-Q5) with their expected pages and screen labels, plus Q6 (not in the manual: no page should
score high). For each, write:

- the English original;
- an **Italian** translation, natural, as a user would type it - not word for word;
- an **English paraphrase** that avoids the words of the manual (tests synonyms in one
  language).

Add about ten more, Italian and English, covering the other pages (Calendar, ToDo, Users,
Dashboard, Accounts, Draft-Proposal, Assistant...), each with its expected page(s). Keep them in
one JSON file (`questions.json`: id, lang, text, screen, expected) so the Delphi side can reuse
it later.

### 3.3 The three rankings

1. **Lexical (baseline)**: the ranking of the real `THelpChatDocIndex.Search`, query plus hint
   exactly as `BuildSystemPrompt` passes them. Do **not** port it to Python: a port measures a
   different algorithm. Add a small retrieval-only mode to the bench (or a tiny console next to
   it, under `Test/`) that loads `help-index.json`, runs `Search` for every question of
   `questions.json` and writes the ranked page ids to JSON. That is test code, allowed in
   phase 1.
2. **Embeddings**: question vector vs chunk vectors, cosine, pages ranked by best chunk. Embed
   the question alone and question + screen label, and report both.
3. **Hybrid**: fusion of 1 and 2.

### 3.4 Models

On the server's Ollama (`/api/embed`, or the OpenAI-compatible `/v1/embeddings`):

- `bge-m3` (multilingual, ~1.2 GB) - the main candidate;
- one other multilingual model for comparison (e.g. `embeddinggemma` or a multilingual E5
  variant, whatever Ollama offers). An English-only model such as `nomic-embed-text` is useful
  only as a control showing what multilingual buys.

Record the exact model tag and digest (`ollama show`): an index is bound to the model that
built it.

### 3.5 Metrics

Per ranking x model x chunking x question language:

- **hit@1** and **hit@3** (an expected page among the first 1/3 - 3 is what the prompt
  receives by default);
- **MRR**;
- for Q6-like questions, the top cosine score, to see whether a threshold can tell "not in the
  manual" apart;
- latency of one question embedding (warm), and the time to embed the whole corpus.

### 3.6 The report

`results/embeddings-v1.md`: the tables, the failures question by question (which page came
first instead), and a short conclusion. Commit the scripts, `questions.json` and the report;
never a configuration with a key.

## 4. Decision criterion

Go on to phase 2 only if the hybrid, on the **Italian** questions, raises hit@3 clearly (rule of
thumb: +25 points or more) and does not lose more than one question on the English ones versus
the lexical baseline. If the gain is small, the cheaper alternatives win: a
`search_documentation(query)` tool the model calls with an English query of its own, and a
`DocLanguage` setting that tells the model the manual's language.

## 5. Phases 2-5 (context only - not part of this brief)

Sketch of what would follow, to keep phase 1 measuring the right thing:

- **Embedding interface registered by name**, like the providers: `openai` (which covers Ollama
  through `/v1/embeddings`), `gemini`. Claude has no embedding API, so the default provider of
  the library is not enough on its own. A `Settings.Embeddings` section: provider, model,
  endpoint, key (through `OnDecryptSecret` like the others). Engine stays RTL-only.
- **The index carries the vectors** and the model that produced them (name + dimension), per
  section chunk; `HelpChatAI.IndexBuilder`, `Tools/HelpIndexBuilder` and the component editor
  can build them, which needs an embedding configuration at design time.
- **Search becomes hybrid** when the index has vectors and the configured model matches; it
  falls back to the lexical ranking when the model differs, the service does not answer, or
  the index has no vectors. `docsearch` keeps working offline. `/check` says which search is
  active.
- **Tests** with a fake deterministic embedder (the suite runs without network), and the bench
  extended with the Italian questions.
- With `Settings.Remote` the server does all of it; the clients change nothing.

Independently of embeddings, the model must keep quoting UI captions as the manual writes them
("Save Proposal"), with a translation in brackets if useful: retrieval finds the page, it does
not stop the model from translating the button.
