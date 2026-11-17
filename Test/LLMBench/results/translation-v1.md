# Translating the question before the search - measurement v1

17 Nov 2026. The proposal: when the language of the chat differs from `DocLanguage`, a model
turns the question into English search terms, and `THelpChatDocIndex.Search` runs on the
question **plus** those terms. Measured on the real Delphi search
(`HelpChatAILLMBench --retrieval`), the CRM demo manual (15 pages, English), the questions of
`embeddings/questions.json` - the 34 of `embeddings-v1` plus 7 new **"user words"** Italian
questions (societa, offerta, preventivo: the words of someone who has not read the manual),
written before anything was measured.

- `embeddings/translate_queries.py` - one call per question and translator, the prompt in
  `questions-translated.json` (`translationPrompt`); every question is translated, English
  ones too, because in the engine the trigger is the language of the chat, not the one of the
  question.
- `HelpChatAILLMBench --retrieval=embeddings/questions-translated.json
  --out=results/retrieval-translated.json` - today's ranking and, per translator, the ranking
  of question + terms, with the screen as hint and without.
- `embeddings/score_translation.py` - the tables below.

Translators: `claude-haiku-5-5` (cloud), `qwen3-coder:30b` and `gemma4:12b` on the Ethea
Ollama server, temperature 0 on Ollama (Haiku at its default), at most 150 tokens on Ollama.

## Results

hit@1 / hit@3: the expected page first / among the 3 pages the prompt receives
(`GroundingMaxPages`). Questions whose answer is not in the manual are left out.

| Search | it, on screen (8) | it, off-screen (6) | it, user words (7) | en, original (11) | en, paraphrase (5) |
|---|---:|---:|---:|---:|---:|
| lexical (today) | 8 / 8 | 1 / 3 | 1 / 1 | 6 / 11 | 4 / 4 |
| lexical, no hint | 4 / 5 | 4 / 4 | 0 / 1 | 6 / 9 | 1 / 4 |
| + haiku terms | 8 / 8 | 3 / 6 | 1 / 4 | 10 / 11 | 3 / 5 |
| **+ haiku terms, no hint** | **8 / 8** | **5 / 6** | 0 / **6** | 8 / 10 | 4 / 5 |
| + gemma terms | 7 / 8 | 3 / 4 | 1 / 3 | 8 / 11 | 3 / 5 |
| + gemma terms, no hint | 8 / 8 | 4 / 6 | 0 / 5 | 8 / 11 | 3 / 4 |
| + qwen terms | 6 / 8 | 3 / 4 | 2 / 2 | 8 / 11 | 2 / 4 |
| + qwen terms, no hint | 4 / 7 | 3 / 5 | 1 / 3 | 6 / 10 | 3 / 4 |

The 21 Italian questions together, hit@3: today **12**; Haiku terms 18 with the hint, **20**
without; gemma 15 / 19; qwen 14 / 15. On the 14 Italian questions of `embeddings-v1` alone,
Haiku terms without the hint find 13 first and 14 among the 3 - what the best embedding
model (`embeddinggemma`, section chunks) found there, with no embedding service.

## What the numbers say

1. **The translation works, and it is the hint that decides how well.** With the screen as
   hint (weight 2) the search still drags the page of the screen to the top: Italian off-screen
   goes from 3 to 6 of 6 at hit@3 with Haiku, but the user words only from 1 to 4. Without the
   hint the terms carry the question: 20 of 21 Italian among the 3.
2. **Without the hint the English original questions lose a little at hit@1** (Haiku 10 -> 8)
   and nothing that matters at hit@3 (11 -> 10). The terms help English too: the synonyms took
   today's 6 of 11 first to 10 with the hint.
3. **The translator matters.** Haiku is the best; gemma4:12b is close without the hint (19 of
   21) and the fastest; qwen3-coder writes long lists of loosely related words that dilute the
   search (and, without a token cap, looped for five minutes) - a coding model is the wrong
   tool here.
4. **Two pages compete for good reasons.** "Inserisci una societa" finds `Assistant.md` first
   and `Accounts.md` second: the assistant page says "add Harbor Lane Foods to the accounts -
   it adds the company", which is also an answer. "Come chiudo un'offerta come vinta?" is a
   vocabulary gap even in English: the manual says *Complete* / *Accepted*, nobody says *won*;
   only qwen guessed "accept quote".
5. **Thinking models must be told not to think**: gemma4 spent the whole cap reasoning and
   returned nothing until `reasoning_effort: none` - the switch the engine already uses.

## Cost

| Translator | Model | ms (median) | ms (max) | tokens in / out (mean) |
|---|---|---:|---:|---:|
| haiku | `claude-haiku-5-5` | 785 | 2325 | 176 / 45 |
| qwen | `qwen3-coder:30b` | 2790 | 2918 | 139 / 86 |
| gemma | `gemma4:12b` | 359 | 471 | 144 / 14 |


One request per question, only when the languages differ: about 150 tokens in and 15-90
out, under a second with Haiku and gemma, nothing that touches the prompt cache of the
answer (it is a request of its own). The answer starts that much later.

## Limits

- **Small set**: 21 Italian questions; one question is 5 points.
- **The user words were written by someone who had read the manual** (who wrote this),
  though before measuring. A fairer set is still the one of `EMBEDDINGS.md`: questions by
  someone who has not.
- **One run**; Haiku ran at its default temperature. The format slipped once in 41 (a
  preamble before the terms, U04-it), harmless to the search.
- **Follow-up questions were not measured** ("e come la cancello?"): the translator would
  receive the question before it.

## Conclusion

Worth building: question + terms, **without the screen hint when the question was
translated**, behind the condition chat language <> `DocLanguage`. The translator is the
model in use unless a lighter one is configured; it gets a token cap, no reasoning, and a
failure falls back to the question alone.

Rank of the first expected page, per Italian question:

| Question | Screen | lexical (today) | lexical, no hint | + gemma terms | + gemma terms, no hint | + haiku terms | + haiku terms, no hint | + qwen terms | + qwen terms, no hint |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Q1-it Come sposto un lead in un'altra colonna della bacheca? E le date cosa diventano? | Leads | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 |
| Q2-it Dove vengono salvati i miei dati? E come faccio a ripartire dai dati di esempio? | Dashboard | 5 | - | 4 | 2 | 3 | 2 | 2 | 2 |
| Q3-it Posso modificare una proposta dopo averla salvata? | Sales | 1 | 1 | 2 | 1 | 1 | 1 | 1 | 1 |
| Q4-it Quale esportazione mi dà un file da aprire con Excel? | Accounts | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Q5-it Come trovo un lead se conosco solo il suo indirizzo email? | Leads | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 6 |
| X01-it Il calendario mostra gli appuntamenti dei lead? | Calendar | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 |
| X03-it Come aggiungo un nuovo utente? | Users | 1 | - | 1 | 1 | 1 | 1 | 1 | 1 |
| X05-it Come elimino un'azienda cliente? | Accounts | 1 | - | 1 | 1 | 1 | 1 | 2 | 2 |
| X07-it Perché il totale della mia proposta è zero? | Sales | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| X09-it L'assistente può modificare i miei dati da solo? | Leads | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| X10-it Come allego un documento a un lead? | Leads | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| X12-it Quali funzioni non sono ancora implementate? | Dashboard | 4 | 1 | 4 | 1 | 2 | 1 | 6 | 3 |
| X14-it Come segno una proposta come accettata? | Sales | 1 | 5 | 1 | 1 | 1 | 1 | 1 | 1 |
| X15-it Posso rimpicciolire la finestra? | Dashboard | 5 | - | 3 | 2 | 2 | 1 | 8 | 6 |
| U01-it Inserisci una società | Dashboard | - | - | 3 | 2 | 3 | 2 | 9 | 7 |
| U02-it Come aggiungo una nuova società? | Leads | 4 | - | 4 | 4 | 3 | 3 | 4 | 5 |
| U03-it Se elimino un'azienda, cosa succede ai lead collegati? | Dashboard | 8 | 3 | 3 | 2 | 3 | 2 | 8 | 4 |
| U04-it Come chiudo un'offerta come vinta? | Dashboard | - | - | 4 | 2 | 6 | 5 | 1 | 1 |
| U05-it Dove vedo tutti i preventivi che ho fatto? | Leads | - | - | 12 | 6 | 5 | 2 | 10 | 5 |
| U06-it Come preparo un preventivo per un potenziale cliente? | Dashboard | - | - | 4 | 2 | 7 | 3 | 6 | 3 |
| U07-it Come cerco una società per nome? | Accounts | 1 | - | 1 | 2 | 1 | 2 | 1 | 3 |
