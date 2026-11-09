# Semantic retrieval with embeddings - phase 1 measurement (v1)

Run on 2026-11-08 on EtheaServer (RTX 5060 Ti 16 GB, Ollama 0.40.15, local). Brief:
`Test/LLMBench/EMBEDDINGS.md`. Nothing under `source/` changed.

## How it was measured

- **Corpus**: the 15 pages of `CRM Demo/Help/help-index.json` (`Index.md` is the table of
  contents and is not in the index). Two chunkings: **page** (title + the `text` of the index,
  what the lexical search scores) and **section** (the `.md` split on `##`/`###`, 90 chunks,
  each prefixed with "Page > Heading > Sub"; a page ranks with its best chunk).
- **Questions**: `embeddings/questions.json`, 34 questions. Q1-Q6 of the bench in three
  variants (English original, natural Italian, English paraphrase avoiding the manual's
  words), plus 16 extra (10 Italian, 6 English) covering Calendar, Users, Accounts,
  Draft-Proposal, Assistant, Data-Model, ToDo, Getting-Started. Q6 (3 variants) and X16 are
  not in the manual. 30 have an expected page.
- **Lexical baseline**: the real `THelpChatDocIndex.Search`, run by
  `HelpChatAILLMBench --retrieval=embeddings\questions.json` -> `retrieval-lexical.json`.
  Searched with the screen as hint, exactly as `BuildSystemPrompt` does (`lexical`), and
  without it (`lexical-nohint`), every page that scores > 0.
- **Embeddings**: `embeddings/embed_bench.py`, Ollama `/api/embed`, cosine. The question
  alone (`emb:q`) and question + "(screen: X)" (`emb:q+screen`). Each model gets the query and
  document prefixes it was trained with (bge-m3 none).
- **Hybrid**: Reciprocal Rank Fusion, k = 60. `hybrid:q` = lexical (with hint) + `emb:q`;
  `hybrid:q+screen` = lexical (with hint) + `emb:q+screen`; `hybrid-nohint:q` = lexical
  without hint + `emb:q`.
- **Metrics**: hit@1, hit@3 (3 = what the prompt receives by default), MRR. Two extra slices:
  **off-screen**, the questions whose expected page is not the page of the screen they are
  asked from (6 Italian, 6 English) - there the hint cannot help.

## Models

| Model | Digest | Params | Quant | Dim | Context | Corpus, page / section | One question (warm) |
|---|---|---:|---|---:|---:|---:|---:|
| bge-m3:latest | 790764642607 | 567M | F16 | 1024 | 8192 | 0.9 s* / 4.1 s | 22 ms |
| embeddinggemma:latest | 85462619ee72 | 308M | BF16 | 768 | 2048 | 11.9 s / 4.3 s | 10 ms |
| qwen3-embedding:0.6b | ac6da0dfba84 | 596M | Q8_0 | 1024 | 32768 | 11.0 s / 4.4 s | 19 ms |
| nomic-embed-text:latest (English-only control) | 0a109f422b47 | 137M | F16 | 768 | 2048 | 11.1 s / 4.6 s | 100 ms |

The page times include loading the model (cold, ~10 s); \*bge-m3 was already loaded. The
section times are 90 sequential calls, ~45 ms each: embedding the whole manual is seconds,
not minutes. The longest page is 1591 tokens (Assistant, bge-m3 tokenizer), the longest
section 440: **no chunk exceeded any context** - even the 2048 of embeddinggemma and nomic -
so nothing was truncated.

## Results - the rows that matter

hit@1 / hit@3 / MRR. Full table at the end.

| Ranking | Italian (14) | English original (5) | English paraphrase (5) | English extra (6) | Italian off-screen (6) | English off-screen (6) |
|---|---:|---:|---:|---:|---:|---:|
| lexical (today) | 9 / 11 / 0.74 | 4 / 5 / 0.90 | 4 / 4 / 0.83 | 3 / 6 / 0.72 | 1 / 3 / 0.40 | 1 / 5 / 0.50 |
| lexical, no hint | 8 / 9 / 0.62 | 4 / 4 / 0.85 | 2 / 3 / 0.54 | 4 / 5 / 0.78 | 4 / 4 / 0.67 | 4 / 5 / 0.78 |
| emb:q bge-m3 section | 12 / 14 / 0.93 | 4 / 5 / 0.90 | 3 / 5 / 0.77 | 4 / 6 / 0.81 | 6 / 6 / 1.00 | 4 / 6 / 0.81 |
| **emb:q embeddinggemma section** | **13 / 14 / 0.96** | **5 / 5 / 1.00** | 4 / 5 / 0.90 | 5 / 6 / 0.92 | 5 / 6 / 0.92 | **5 / 6 / 0.92** |
| hybrid:q bge-m3 section | 9 / 13 / 0.79 | 5 / 5 / 1.00 | 4 / 5 / 0.87 | 6 / 6 / 1.00 | 2 / 5 / 0.60 | 5 / 6 / 0.89 |
| hybrid:q embeddinggemma section | 11 / 14 / 0.87 | 5 / 5 / 1.00 | 4 / 5 / 0.87 | 6 / 6 / 1.00 | 3 / 6 / 0.69 | 5 / 6 / 0.89 |
| hybrid-nohint:q embeddinggemma section | 11 / 14 / 0.89 | 5 / 5 / 1.00 | 3 / 5 / 0.80 | 5 / 6 / 0.89 | 5 / 6 / 0.92 | 5 / 6 / 0.92 |

What the numbers say:

1. **The lexical search is better on Italian than the brief expected** - 11/14 at hit@3 -
   but for the wrong reason: the **screen hint**. In 8 of the 14 Italian questions the
   expected page is the page of the screen, the hint weighs x2 and puts it first. Where the
   hint does not name the page (off-screen) the lexical search finds it 3 times out of 6, and
   first only once: the screen page wins instead (Dashboard first for Q2, X12, X15...). Run
   without the hint it does better there (4/6 first) and worse everywhere else.
2. **Multilingual embeddings close the gap.** Section chunks + question alone: Italian
   14/14 at hit@3 with bge-m3 and embeddinggemma, 12-13/14 first; off-screen Italian 5-6/6.
   On the English originals they equal the lexical search; on paraphrases they beat it.
3. **Sections beat pages** for every multilingual model (one page of the manual covers
   several topics; the FAQ covers sixteen).
4. **Adding the screen to the embedded question hurts** (`emb:q+screen`): it drags the
   ranking towards the screen page, the same flaw as the lexical hint.
5. **RRF with today's lexical ranking hurts hit@1** on Italian (13 -> 11 with embeddinggemma,
   12 -> 9 with bge-m3): fusion imports the hint's bias. It helps on the English extras
   (exact words such as "line items", "tables"). Fusing with the hint-free lexical ranking
   (`hybrid-nohint`) keeps the off-screen gains.
6. **nomic-embed-text, English-only, is the control it was meant to be**: Italian 5/14 first
   with sections. Multilingual is what buys the gain.
7. **qwen3-embedding:0.6b** is between: good at hit@3, weaker at hit@1 (Home.md first in 6
   questions - the overview page that mentions everything).

### Telling "not in the manual" apart

Top cosine of `emb:q`; grounded = the 30 questions with an expected page, off-manual = Q6 x3
and X16.

| Model, chunks | Grounded: min / 10th pct / median | Off-manual: the four |
|---|---|---|
| bge-m3, section | 0.459 / 0.568 / 0.640 | 0.316, 0.423, 0.439, **0.485** |
| **embeddinggemma, section** | **0.387** / 0.454 / 0.559 | 0.108, 0.195, 0.213, **0.248** |
| qwen3-embedding, section | 0.437 / 0.568 / 0.666 | 0.253, 0.325, 0.325, 0.349 |
| nomic-embed-text, section | 0.446 / 0.491 / 0.657 | 0.463, 0.527, 0.546, 0.561 |

embeddinggemma and qwen3-embedding separate the two cleanly (a threshold around 0.30 and
0.39 respectively); bge-m3 overlaps (an off-manual question scores above the weakest
grounded one). Today the lexical search with the hint returns Dashboard, Home, Users,
Assistant for the weather in Milan: there is always "something", and only the model's
judgement stops a citation. Four off-manual questions are too few to fix a threshold;
they show it is possible with some models and not with others.

### Failures, question by question

- **lexical (today)**: Q2 en/it/para (Dashboard first: hint), X04, X08, X11, X12, X15
  (Dashboard first: hint), X07 (Sales first: hint), X10 (Leads first: hint). Every miss
  at hit@1 is the screen page coming first.
- **emb:q embeddinggemma section**: Q2-it -> Home ("Where your data is" is a section of Home:
  arguably right), Q5-para -> Marketing (searching by e-mail is Marketing's search too),
  X06 -> FAQ ("Why is the total of my proposal $0.00?").
- **emb:q bge-m3 section**: Q5 en/it -> Marketing, Q5-para -> Sales, Q2-para -> Data-Model,
  X05-it -> Users, X06 -> ToDo, X13 -> Draft-Proposal.

## Caveats

- **Small set**: 14 Italian questions, 6 off-screen per language. One question is 7 points
  (Italian) or 17 (off-screen). Differences of one or two questions between models are noise.
- **The questions were written by the agent that read the manual**, which favours words of
  the manual even in Italian ("lead", "proposta"). Real users would make the lexical search
  look worse, not better.
- **The screen distribution is a choice**: 8/14 Italian questions are asked from the page that
  answers them. Users who ask about the screen they are on are common, but the share decides
  how good the lexical search looks.
- One manual, 15 short pages. A long manual (hundreds of pages) is where both chunking and a
  threshold matter more; not measured.

## Against the decision criterion

The criterion of the brief: the **hybrid** raises Italian hit@3 by +25 points or more, and
loses at most one English question.

- Hybrid (RRF with today's lexical ranking), Italian hit@3: 11/14 -> 13/14 (bge-m3) or
  14/14 (embeddinggemma) = **+14 / +21 points: the criterion is not met**. English: no
  question lost (5/5, 5/5, 6/6; paraphrase 4/5 -> 5/5).
- But the criterion measures hit@3 on a set where the hint already solves most Italian
  questions. Where it does not (off-screen): lexical 3/6 -> embeddings 5-6/6 at hit@3, and
  1/6 -> 5-6/6 at hit@1 (**+67 to +83 points**). And the embeddings alone beat the hybrid at
  hit@1 on Italian (13 vs 11).

## Conclusion

1. **By the letter of the brief, phase 2 does not start**: the hybrid as specified gains 2-3
   Italian questions at hit@3.
2. **The measurement found a cheaper defect first**: the screen hint (x2) overrides the
   question. It costs the lexical search the off-screen questions in both languages and is
   inherited by any fusion with it. Lowering `HELPCHAT_HINT_WEIGHT`, or using the hint only
   to break ties, can be measured with this same harness (rebuild, `--retrieval`, rerun the
   script) before anything else - it is a constant in `source/`, so it is the owner's call.
3. **If embeddings go ahead**, the measurement points to: **section chunks**, the **question
   alone** (no screen), a **multilingual** model - **embeddinggemma** first (best hit@1,
   smallest, fastest, and the only clean "not in the manual" gap with bge-m3-level recall),
   bge-m3 second - and either the embeddings alone or a fusion with the hint-free lexical
   ranking, not with today's.
4. **Before deciding, a fairer question set**: questions written by someone who has not read
   the manual, asked from a realistic mix of screens. `questions.json` is the format; the
   two programs rerun in under a minute once the models are pulled.

## Files

- `embeddings/questions.json` - the questions (reusable by the Delphi side).
- `embeddings/embed_bench.py` - embeddings, fusion, metrics; vectors cached in
  `embeddings/cache` (svn-ignored, keyed by model digest).
- `results/retrieval-lexical.json` - the lexical rankings, from `HelpChatAILLMBench --retrieval`.
- `results/embeddings-v1.json` - every ranking of every run, the top-5 cosines, model info.

To rerun: build `Test\LLMBench\Delphi13\HelpChatAILLMBench.dproj`, then
`Test\Bin\Win32\HelpChatAILLMBench.exe --retrieval=Test\LLMBench\embeddings\questions.json`
and `python Test\LLMBench\embeddings\embed_bench.py` (`ollama pull bge-m3 embeddinggemma
qwen3-embedding:0.6b nomic-embed-text` first).

## Full table

hit@1 / hit@3 / MRR, n in the header.

| Method | Model | Chunks | it (n=14) hit@1 / hit@3 / MRR | en orig (n=5) hit@1 / hit@3 / MRR | en para (n=5) hit@1 / hit@3 / MRR | en extra (n=6) hit@1 / hit@3 / MRR | it, off-screen (n=6) hit@1 / hit@3 / MRR | en, off-screen (n=6) hit@1 / hit@3 / MRR |
|---|---|---|---:|---:|---:|---:|---:|---:|
| lexical | - | - | 9/14 / 11/14 / 0.74 | 4/5 / 5/5 / 0.90 | 4/5 / 4/5 / 0.83 | 3/6 / 6/6 / 0.72 | 1/6 / 3/6 / 0.40 | 1/6 / 5/6 / 0.50 |
| lexical-nohint | - | - | 8/14 / 9/14 / 0.62 | 4/5 / 4/5 / 0.85 | 2/5 / 3/5 / 0.54 | 4/6 / 5/6 / 0.78 | 4/6 / 4/6 / 0.67 | 4/6 / 5/6 / 0.78 |
| emb:q | bge-m3:latest | page | 11/14 / 13/14 / 0.86 | 4/5 / 5/5 / 0.87 | 2/5 / 4/5 / 0.62 | 5/6 / 6/6 / 0.89 | 5/6 / 5/6 / 0.88 | 5/6 / 6/6 / 0.89 |
| emb:q+screen | bge-m3:latest | page | 9/14 / 14/14 / 0.79 | 3/5 / 5/5 / 0.77 | 2/5 / 5/5 / 0.67 | 5/6 / 5/6 / 0.88 | 2/6 / 6/6 / 0.61 | 3/6 / 5/6 / 0.71 |
| hybrid:q | bge-m3:latest | page | 9/14 / 13/14 / 0.80 | 5/5 / 5/5 / 1.00 | 2/5 / 4/5 / 0.62 | 5/6 / 6/6 / 0.89 | 2/6 / 5/6 / 0.62 | 4/6 / 6/6 / 0.78 |
| hybrid:q+screen | bge-m3:latest | page | 9/14 / 13/14 / 0.78 | 4/5 / 5/5 / 0.87 | 4/5 / 4/5 / 0.85 | 3/6 / 6/6 / 0.72 | 1/6 / 5/6 / 0.48 | 1/6 / 5/6 / 0.49 |
| hybrid-nohint:q | bge-m3:latest | page | 9/14 / 13/14 / 0.80 | 4/5 / 5/5 / 0.87 | 3/5 / 4/5 / 0.72 | 4/6 / 6/6 / 0.81 | 5/6 / 5/6 / 0.88 | 4/6 / 6/6 / 0.83 |
| emb:q | bge-m3:latest | section | 12/14 / 14/14 / 0.93 | 4/5 / 5/5 / 0.90 | 3/5 / 5/5 / 0.77 | 4/6 / 6/6 / 0.81 | 6/6 / 6/6 / 1.00 | 4/6 / 6/6 / 0.81 |
| emb:q+screen | bge-m3:latest | section | 10/14 / 14/14 / 0.81 | 4/5 / 5/5 / 0.87 | 2/5 / 5/5 / 0.63 | 4/6 / 6/6 / 0.83 | 3/6 / 6/6 / 0.67 | 3/6 / 6/6 / 0.75 |
| hybrid:q | bge-m3:latest | section | 9/14 / 13/14 / 0.79 | 5/5 / 5/5 / 1.00 | 4/5 / 5/5 / 0.87 | 6/6 / 6/6 / 1.00 | 2/6 / 5/6 / 0.60 | 5/6 / 6/6 / 0.89 |
| hybrid:q+screen | bge-m3:latest | section | 9/14 / 13/14 / 0.77 | 5/5 / 5/5 / 1.00 | 4/5 / 4/5 / 0.85 | 4/6 / 6/6 / 0.81 | 1/6 / 5/6 / 0.46 | 3/6 / 5/6 / 0.68 |
| hybrid-nohint:q | bge-m3:latest | section | 11/14 / 14/14 / 0.88 | 4/5 / 5/5 / 0.90 | 2/5 / 5/5 / 0.67 | 5/6 / 6/6 / 0.89 | 6/6 / 6/6 / 1.00 | 5/6 / 6/6 / 0.89 |
| emb:q | embeddinggemma:latest | page | 12/14 / 14/14 / 0.93 | 4/5 / 5/5 / 0.87 | 3/5 / 4/5 / 0.75 | 5/6 / 6/6 / 0.89 | 5/6 / 6/6 / 0.92 | 5/6 / 6/6 / 0.89 |
| emb:q+screen | embeddinggemma:latest | page | 8/14 / 14/14 / 0.77 | 4/5 / 5/5 / 0.90 | 4/5 / 5/5 / 0.87 | 5/6 / 6/6 / 0.89 | 1/6 / 6/6 / 0.56 | 5/6 / 6/6 / 0.89 |
| hybrid:q | embeddinggemma:latest | page | 10/14 / 13/14 / 0.84 | 5/5 / 5/5 / 1.00 | 3/5 / 5/5 / 0.77 | 5/6 / 6/6 / 0.92 | 2/6 / 5/6 / 0.62 | 4/6 / 6/6 / 0.81 |
| hybrid:q+screen | embeddinggemma:latest | page | 9/14 / 13/14 / 0.79 | 4/5 / 5/5 / 0.90 | 4/5 / 4/5 / 0.85 | 3/6 / 6/6 / 0.72 | 1/6 / 5/6 / 0.51 | 1/6 / 5/6 / 0.51 |
| hybrid-nohint:q | embeddinggemma:latest | page | 10/14 / 14/14 / 0.86 | 4/5 / 5/5 / 0.90 | 3/5 / 5/5 / 0.77 | 4/6 / 6/6 / 0.81 | 5/6 / 6/6 / 0.92 | 4/6 / 6/6 / 0.83 |
| emb:q | embeddinggemma:latest | section | 13/14 / 14/14 / 0.96 | 5/5 / 5/5 / 1.00 | 4/5 / 5/5 / 0.90 | 5/6 / 6/6 / 0.92 | 5/6 / 6/6 / 0.92 | 5/6 / 6/6 / 0.92 |
| emb:q+screen | embeddinggemma:latest | section | 12/14 / 14/14 / 0.92 | 5/5 / 5/5 / 1.00 | 5/5 / 5/5 / 1.00 | 4/6 / 6/6 / 0.78 | 4/6 / 6/6 / 0.81 | 4/6 / 6/6 / 0.78 |
| hybrid:q | embeddinggemma:latest | section | 11/14 / 14/14 / 0.87 | 5/5 / 5/5 / 1.00 | 4/5 / 5/5 / 0.87 | 6/6 / 6/6 / 1.00 | 3/6 / 6/6 / 0.69 | 5/6 / 6/6 / 0.89 |
| hybrid:q+screen | embeddinggemma:latest | section | 9/14 / 13/14 / 0.78 | 5/5 / 5/5 / 1.00 | 4/5 / 4/5 / 0.85 | 4/6 / 6/6 / 0.81 | 1/6 / 5/6 / 0.48 | 3/6 / 5/6 / 0.68 |
| hybrid-nohint:q | embeddinggemma:latest | section | 11/14 / 14/14 / 0.89 | 5/5 / 5/5 / 1.00 | 3/5 / 5/5 / 0.80 | 5/6 / 6/6 / 0.89 | 5/6 / 6/6 / 0.92 | 5/6 / 6/6 / 0.92 |
| emb:q | qwen3-embedding:0.6b | page | 10/14 / 12/14 / 0.80 | 4/5 / 5/5 / 0.87 | 3/5 / 4/5 / 0.72 | 4/6 / 6/6 / 0.83 | 5/6 / 5/6 / 0.86 | 4/6 / 6/6 / 0.83 |
| emb:q+screen | qwen3-embedding:0.6b | page | 10/14 / 12/14 / 0.82 | 4/5 / 5/5 / 0.90 | 3/5 / 5/5 / 0.77 | 5/6 / 6/6 / 0.89 | 3/6 / 4/6 / 0.67 | 4/6 / 6/6 / 0.81 |
| hybrid:q | qwen3-embedding:0.6b | page | 9/14 / 13/14 / 0.79 | 5/5 / 5/5 / 1.00 | 3/5 / 4/5 / 0.72 | 5/6 / 6/6 / 0.89 | 2/6 / 5/6 / 0.62 | 4/6 / 5/6 / 0.76 |
| hybrid:q+screen | qwen3-embedding:0.6b | page | 9/14 / 12/14 / 0.78 | 5/5 / 5/5 / 1.00 | 4/5 / 4/5 / 0.85 | 4/6 / 6/6 / 0.81 | 1/6 / 4/6 / 0.49 | 3/6 / 5/6 / 0.68 |
| hybrid-nohint:q | qwen3-embedding:0.6b | page | 9/14 / 13/14 / 0.77 | 4/5 / 5/5 / 0.87 | 3/5 / 4/5 / 0.70 | 4/6 / 6/6 / 0.83 | 5/6 / 5/6 / 0.86 | 4/6 / 6/6 / 0.81 |
| emb:q | qwen3-embedding:0.6b | section | 9/14 / 14/14 / 0.82 | 4/5 / 5/5 / 0.90 | 3/5 / 4/5 / 0.74 | 5/6 / 6/6 / 0.92 | 3/6 / 6/6 / 0.75 | 4/6 / 6/6 / 0.83 |
| emb:q+screen | qwen3-embedding:0.6b | section | 9/14 / 13/14 / 0.80 | 5/5 / 5/5 / 1.00 | 4/5 / 5/5 / 0.90 | 5/6 / 6/6 / 0.92 | 2/6 / 5/6 / 0.62 | 4/6 / 6/6 / 0.83 |
| hybrid:q | qwen3-embedding:0.6b | section | 10/14 / 14/14 / 0.85 | 5/5 / 5/5 / 1.00 | 3/5 / 4/5 / 0.72 | 6/6 / 6/6 / 1.00 | 2/6 / 6/6 / 0.64 | 5/6 / 5/6 / 0.88 |
| hybrid:q+screen | qwen3-embedding:0.6b | section | 9/14 / 12/14 / 0.76 | 5/5 / 5/5 / 1.00 | 4/5 / 4/5 / 0.84 | 5/6 / 6/6 / 0.92 | 1/6 / 4/6 / 0.44 | 4/6 / 5/6 / 0.78 |
| hybrid-nohint:q | qwen3-embedding:0.6b | section | 9/14 / 13/14 / 0.80 | 4/5 / 5/5 / 0.90 | 3/5 / 4/5 / 0.70 | 5/6 / 6/6 / 0.89 | 4/6 / 6/6 / 0.83 | 5/6 / 6/6 / 0.89 |
| emb:q | nomic-embed-text:latest | page | 10/14 / 11/14 / 0.78 | 4/5 / 5/5 / 0.87 | 2/5 / 4/5 / 0.63 | 4/6 / 5/6 / 0.79 | 4/6 / 4/6 / 0.72 | 4/6 / 5/6 / 0.79 |
| emb:q+screen | nomic-embed-text:latest | page | 8/14 / 10/14 / 0.68 | 3/5 / 5/5 / 0.80 | 3/5 / 5/5 / 0.80 | 4/6 / 5/6 / 0.79 | 0/6 / 2/6 / 0.25 | 2/6 / 5/6 / 0.62 |
| hybrid:q | nomic-embed-text:latest | page | 10/14 / 12/14 / 0.81 | 5/5 / 5/5 / 1.00 | 3/5 / 5/5 / 0.77 | 5/6 / 6/6 / 0.89 | 2/6 / 4/6 / 0.57 | 4/6 / 6/6 / 0.78 |
| hybrid:q+screen | nomic-embed-text:latest | page | 8/14 / 14/14 / 0.74 | 4/5 / 5/5 / 0.90 | 4/5 / 4/5 / 0.85 | 4/6 / 6/6 / 0.81 | 0/6 / 6/6 / 0.39 | 2/6 / 5/6 / 0.60 |
| hybrid-nohint:q | nomic-embed-text:latest | page | 8/14 / 11/14 / 0.71 | 4/5 / 5/5 / 0.90 | 3/5 / 4/5 / 0.75 | 4/6 / 6/6 / 0.81 | 4/6 / 4/6 / 0.72 | 4/6 / 6/6 / 0.83 |
| emb:q | nomic-embed-text:latest | section | 5/14 / 10/14 / 0.56 | 4/5 / 5/5 / 0.90 | 3/5 / 4/5 / 0.72 | 4/6 / 6/6 / 0.83 | 3/6 / 5/6 / 0.66 | 4/6 / 6/6 / 0.81 |
| emb:q+screen | nomic-embed-text:latest | section | 9/14 / 13/14 / 0.76 | 5/5 / 5/5 / 1.00 | 3/5 / 4/5 / 0.72 | 4/6 / 6/6 / 0.81 | 2/6 / 6/6 / 0.58 | 3/6 / 6/6 / 0.69 |
| hybrid:q | nomic-embed-text:latest | section | 9/14 / 11/14 / 0.75 | 5/5 / 5/5 / 1.00 | 4/5 / 4/5 / 0.84 | 5/6 / 6/6 / 0.92 | 3/6 / 4/6 / 0.63 | 4/6 / 5/6 / 0.78 |
| hybrid:q+screen | nomic-embed-text:latest | section | 8/14 / 14/14 / 0.73 | 5/5 / 5/5 / 1.00 | 4/5 / 4/5 / 0.85 | 5/6 / 6/6 / 0.89 | 1/6 / 6/6 / 0.47 | 4/6 / 5/6 / 0.76 |
| hybrid-nohint:q | nomic-embed-text:latest | section | 7/14 / 10/14 / 0.64 | 4/5 / 5/5 / 0.90 | 2/5 / 3/5 / 0.60 | 4/6 / 6/6 / 0.81 | 4/6 / 5/6 / 0.75 | 4/6 / 5/6 / 0.79 |
