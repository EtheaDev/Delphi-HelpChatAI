"""Scores the rankings of HelpChatAILLMBench --retrieval=questions-translated.json:
today's lexical search against the same search on the question plus the English
terms each translator wrote (translate_queries.py). Prints the Markdown tables.

  python score_translation.py [../results/retrieval-translated.json]
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOP = 3


def metrics(ranked, expected):
    rank = next((i + 1 for i, u in enumerate(ranked) if u in expected), None)
    return rank == 1, rank is not None and rank <= TOP, 1.0 / rank if rank else 0.0


def off_screen(q):
    return q['screen'] + '.md' not in q['expected']


SLICES = [
    ('it, on screen', lambda q: q['lang'] == 'it' and q['variant'] != 'user' and q['expected'] and not off_screen(q)),
    ('it, off-screen', lambda q: q['lang'] == 'it' and q['variant'] != 'user' and q['expected'] and off_screen(q)),
    ('it, user words', lambda q: q['variant'] == 'user'),
    ('en, original', lambda q: q['lang'] == 'en' and q['variant'] in ('orig', 'extra') and q['expected']),
    ('en, paraphrase', lambda q: q['variant'] == 'para' and q['expected']),
]


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'results', 'retrieval-translated.json')
    res = json.load(open(path, encoding='utf-8-sig'))
    data = json.load(open(os.path.join(HERE, 'questions-translated.json'), encoding='utf-8'))
    qs = {q['id']: q for q in data['questions']}
    rows = {}  # method -> {id: ranked}
    for r in res['results']:
        rows.setdefault('lexical (today)', {})[r['id']] = [x['page'] for x in r['ranking']]
        rows.setdefault('lexical, no hint', {})[r['id']] = [x['page'] for x in r['rankingNoHint']]
        for name, t in r.get('translated', {}).items():
            rows.setdefault(f'+ {name} terms', {})[r['id']] = [x['page'] for x in t['ranking']]
            rows.setdefault(f'+ {name} terms, no hint', {})[r['id']] = [x['page'] for x in t['rankingNoHint']]
    order = ['lexical (today)', 'lexical, no hint'] + sorted(k for k in rows if k.startswith('+'))
    head = '| Search |' + ''.join(
        f' {n} ({sum(1 for q in qs.values() if f(q))}) |' for n, f in SLICES)
    print('hit@1 / hit@3 (the page is the first / among the 3 the prompt receives)\n')
    print(head)
    print('|---|' + '---:|' * len(SLICES))
    for m in order:
        cells = []
        for _, f in SLICES:
            ids = [i for i, q in qs.items() if f(q) and i in rows[m]]
            h1 = h3 = 0
            for i in ids:
                a, b, _ = metrics(rows[m][i], qs[i]['expected'])
                h1 += a
                h3 += b
            cells.append(f' {h1} / {h3} |')
        print(f'| {m} |' + ''.join(cells))
    # What a translation costs, per translator.
    print('\n| Translator | Model | ms (median) | ms (max) | tokens in / out (mean) |')
    print('|---|---|---:|---:|---:|')
    for name, model in data.get('translators', {}).items():
        st = [q['translationStats'][name] for q in qs.values() if name in q.get('translationStats', {})]
        ms = sorted(s['ms'] for s in st)
        if not ms:
            continue
        print(f'| {name} | `{model}` | {ms[len(ms) // 2]} | {ms[-1]} | '
              f'{sum(s["in"] for s in st) / len(st):.0f} / {sum(s["out"] for s in st) / len(st):.0f} |')
    # Per question, the rank of the expected page, for the Italian ones.
    print('\nRank of the first expected page (- = not found), Italian questions:\n')
    print('| Question | Screen | ' + ' | '.join(order) + ' |')
    print('|---|---|' + '---:|' * len(order))
    for i, q in qs.items():
        if q['lang'] != 'it' or not q['expected']:
            continue
        cells = []
        for m in order:
            ranked = rows[m].get(i, [])
            rank = next((k + 1 for k, u in enumerate(ranked) if u in q['expected']), None)
            cells.append(str(rank) if rank else '-')
        print(f'| {i} {q["text"]} | {q["screen"]} | ' + ' | '.join(cells) + ' |')


if __name__ == '__main__':
    main()
