"""Phase 1 of Test/LLMBench/EMBEDDINGS.md: does semantic retrieval find the right page
of the CRM demo manual where the lexical search of the engine does not?

Inputs
  questions.json                         the questions, their screen and expected pages
  ../results/retrieval-lexical.json      the ranking of the real THelpChatDocIndex.Search,
                                         written by HelpChatAILLMBench --retrieval=...
  CRM Demo/Help/help-index.json + *.md   the corpus (the pages the index has)
Output
  ../results/embeddings-v1.json          every ranking and metric, for whoever goes on
  stdout                                 the Markdown tables of the report

Standard library only. Ollama at OLLAMA (default http://localhost:11434), /api/embed.
Vectors are cached in embeddings/cache (svn-ignored), keyed by model digest and text.

  python embed_bench.py [--models=bge-m3,embeddinggemma,...] [--ollama=http://host:11434]
"""
import hashlib
import json
import math
import os
import re
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
HELP = os.path.join(ROOT, 'CRM Demo', 'Help')
RESULTS = os.path.join(HERE, '..', 'results')
CACHE = os.path.join(HERE, 'cache')
OLLAMA = 'http://localhost:11434'
RRF_K = 60
TOP = 3  # what the prompt receives by default (GroundingMaxPages)

# What each model expects in front of a query and of a document. bge-m3 wants
# nothing; the others were trained with a prefix and lose quality without it.
PREFIXES = {
    'bge-m3': ('', ''),
    'embeddinggemma': ('task: search result | query: ', 'title: {title} | text: '),
    'qwen3-embedding': ('Instruct: Given a question about an application, retrieve the manual '
                        'section that answers it\nQuery: ', ''),
    'nomic-embed-text': ('search_query: ', 'search_document: '),
}


def model_family(model):
    return model.split(':')[0]


def http_json(url, payload=None, timeout=600):
    data = None if payload is None else json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode('utf-8'))


def model_info(model):
    tags = http_json(OLLAMA + '/api/tags')['models']
    for m in tags:
        if m['name'] == model or m['name'] == model + ':latest':
            show = http_json(OLLAMA + '/api/show', {'model': m['name']})
            info = show.get('model_info', {})
            ctx = next((v for k, v in info.items() if k.endswith('.context_length')), None)
            dim = next((v for k, v in info.items() if k.endswith('.embedding_length')), None)
            return {'name': m['name'], 'digest': m['digest'], 'size': m['size'],
                    'context': ctx, 'dim': dim,
                    'params': show.get('details', {}).get('parameter_size'),
                    'quant': show.get('details', {}).get('quantization_level')}
    raise SystemExit('model not in Ollama: ' + model)


class Embedder:
    """One model, a disk cache, and the bookkeeping the report needs."""

    def __init__(self, info):
        self.info = info
        self.model = info['name']
        self.qpre, self.dpre = PREFIXES.get(model_family(self.model), ('', ''))
        os.makedirs(CACHE, exist_ok=True)
        self.path = os.path.join(CACHE, model_family(self.model) + '-' + info['digest'][:12] + '.json')
        self.cache = json.load(open(self.path, encoding='utf-8')) if os.path.exists(self.path) else {}
        self.overflow = []  # texts longer than the context: (label, tokens)

    def save(self):
        json.dump(self.cache, open(self.path, 'w', encoding='utf-8'))

    def _call(self, text, truncate):
        return http_json(OLLAMA + '/api/embed',
                         {'model': self.model, 'input': text, 'truncate': truncate,
                          'keep_alive': '30m'})

    def embed(self, text, label=''):
        key = hashlib.sha1(text.encode('utf-8')).hexdigest()
        if key in self.cache:
            return self.cache[key]['v']
        try:
            r = self._call(text, False)
        except urllib.error.HTTPError as e:
            # Longer than the context: say so, then measure the truncated vector,
            # which is what an index built without care would hold.
            self.overflow.append((label, e.read().decode('utf-8', 'replace')[:200]))
            r = self._call(text, True)
        v = normalize(r['embeddings'][0])
        self.cache[key] = {'v': v, 'tokens': r.get('prompt_eval_count')}
        return v

    def tokens(self, text):
        e = self.cache.get(hashlib.sha1(text.encode('utf-8')).hexdigest())
        return e and e.get('tokens')

    def time_query(self, text, runs=5):
        """Warm latency of one question, never cached."""
        self._call(self.qpre + text, True)
        best = []
        for _ in range(runs):
            t = time.perf_counter()
            self._call(self.qpre + text, True)
            best.append((time.perf_counter() - t) * 1000)
        best.sort()
        return best[len(best) // 2]


def normalize(v):
    n = math.sqrt(sum(x * x for x in v)) or 1.0
    return [x / n for x in v]


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


# ---------------------------------------------------------------- corpus

def load_pages():
    index = json.load(open(os.path.join(HELP, 'help-index.json'), encoding='utf-8-sig'))
    return [{'url': e['url'], 'title': e['title'], 'text': e['text']} for e in index]


MD_NOISE = [
    (re.compile(r'!\[[^\]]*\]\([^)]*\)'), ''),          # images
    (re.compile(r'\[([^\]]*)\]\([^)]*\)'), r'\1'),      # links -> their text
    (re.compile(r'[*`>|]'), ' '),
    (re.compile(r'^\s*-{2,}\s*$', re.M), ''),
    (re.compile(r'[ \t]+'), ' '),
    (re.compile(r'\n{3,}'), '\n\n'),
]


def clean_md(s):
    for rx, rep in MD_NOISE:
        s = rx.sub(rep, s)
    return s.strip()


def section_chunks(page):
    """Split a page on ##/###; each chunk carries 'Title > Heading > Sub'."""
    md = open(os.path.join(HELP, page['url']), encoding='utf-8-sig').read()
    chunks, path, buf = [], [], []

    def flush():
        body = clean_md('\n'.join(buf))
        if body or path:
            head = ' > '.join([page['title']] + path)
            chunks.append({'url': page['url'], 'label': head, 'text': head + '\n\n' + body})

    for line in md.splitlines():
        m = re.match(r'^(#{1,3})\s+(.*)$', line)
        if m:
            level = len(m.group(1))
            if level == 1:
                continue  # the page title is already in every label
            flush()
            buf = []
            path = path[:level - 2] + [m.group(2).strip()]
        else:
            buf.append(line)
    flush()
    return chunks


# ---------------------------------------------------------------- rankings

def rank_by_cosine(qv, chunks, vecs):
    """Pages by their best chunk: [(url, score)] descending."""
    best = {}
    for c, v in zip(chunks, vecs):
        s = dot(qv, v)
        if s > best.get(c['url'], -2):
            best[c['url']] = s
    return sorted(best.items(), key=lambda kv: -kv[1])


def rrf(*rankings):
    score = {}
    for r in rankings:
        for i, url in enumerate(r):
            score[url] = score.get(url, 0.0) + 1.0 / (RRF_K + i + 1)
    return [u for u, _ in sorted(score.items(), key=lambda kv: -kv[1])]


def metrics(ranked, expected):
    rank = next((i + 1 for i, u in enumerate(ranked) if u in expected), None)
    return {'hit1': rank == 1, 'hit3': rank is not None and rank <= TOP,
            'rr': 1.0 / rank if rank else 0.0, 'rank': rank}


# ---------------------------------------------------------------- main

def main():
    global OLLAMA
    models = ['bge-m3', 'embeddinggemma', 'qwen3-embedding:0.6b', 'nomic-embed-text']
    for a in sys.argv[1:]:
        if a.startswith('--models='):
            models = a[9:].split(',')
        elif a.startswith('--ollama='):
            OLLAMA = a[9:].rstrip('/')

    questions = json.load(open(os.path.join(HERE, 'questions.json'), encoding='utf-8-sig'))['questions']
    lexical = json.load(open(os.path.join(RESULTS, 'retrieval-lexical.json'), encoding='utf-8-sig'))
    lex = {r['id']: r for r in lexical['results']}
    pages = load_pages()
    chunkings = {
        'page': [{'url': p['url'], 'label': p['title'], 'text': p['title'] + '\n\n' + p['text']}
                 for p in pages],
        'section': [c for p in pages for c in section_chunks(p)],
    }

    out = {'questions': questions, 'models': {}, 'runs': []}

    # The lexical baseline goes through the same scoring.
    for q in questions:
        lr = [x['page'] for x in lex[q['id']]['ranking']]
        ln = [x['page'] for x in lex[q['id']]['rankingNoHint']]
        out['runs'].append({'id': q['id'], 'method': 'lexical', 'model': '-', 'chunking': '-',
                            'ranked': lr, **metrics(lr, q['expected'])})
        out['runs'].append({'id': q['id'], 'method': 'lexical-nohint', 'model': '-', 'chunking': '-',
                            'ranked': ln, **metrics(ln, q['expected'])})

    for model in models:
        info = model_info(model)
        emb = Embedder(info)
        minfo = dict(info)
        print(f'# {info["name"]} {info["digest"][:12]} ctx={info["context"]} dim={info["dim"]}',
              file=sys.stderr)
        for chunking, chunks in chunkings.items():
            t = time.perf_counter()
            fresh = sum(1 for c in chunks
                        if hashlib.sha1(fill_doc(emb, c).encode('utf-8')).hexdigest() not in emb.cache)
            vecs = [emb.embed(fill_doc(emb, c), c['label']) for c in chunks]
            secs = time.perf_counter() - t
            toks = [emb.tokens(fill_doc(emb, c)) or 0 for c in chunks]
            minfo[chunking] = {'chunks': len(chunks), 'embed_s': round(secs, 2) if fresh == len(chunks) else None,
                               'max_tokens': max(toks), 'total_tokens': sum(toks)}
            for q in questions:
                lr = [x['page'] for x in lex[q['id']]['ranking']]
                variants = {
                    'q': emb.qpre + q['text'],
                    'q+screen': emb.qpre + q['text'] + ' (screen: ' + q['screen'] + ')',
                }
                er = {}
                for vname, text in variants.items():
                    scored = rank_by_cosine(emb.embed(text, q['id']), chunks, vecs)
                    er[vname] = [u for u, _ in scored]
                    out['runs'].append({'id': q['id'], 'method': 'emb:' + vname, 'model': info['name'],
                                        'chunking': chunking, 'ranked': er[vname],
                                        'top_cos': round(scored[0][1], 4),
                                        'scores': [[u, round(s, 4)] for u, s in scored[:5]],
                                        **metrics(er[vname], q['expected'])})
                for vname in variants:
                    hr = rrf(lr, er[vname])
                    out['runs'].append({'id': q['id'], 'method': 'hybrid:' + vname, 'model': info['name'],
                                        'chunking': chunking, 'ranked': hr,
                                        **metrics(hr, q['expected'])})
                # The same fusion with the lexical ranking searched without the
                # screen hint: the hint weighs x2 and pushes the page of the screen
                # first even when the question is about another one.
                ln = [x['page'] for x in lex[q['id']]['rankingNoHint']]
                hr = rrf(ln, er['q'])
                out['runs'].append({'id': q['id'], 'method': 'hybrid-nohint:q', 'model': info['name'],
                                    'chunking': chunking, 'ranked': hr, **metrics(hr, q['expected'])})
        minfo['query_ms'] = round(emb.time_query(questions[0]['text']), 1)
        minfo['overflow'] = emb.overflow
        out['models'][info['name']] = minfo
        emb.save()

    json.dump(out, open(os.path.join(RESULTS, 'embeddings-v1.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, separators=(',', ':'))
    print(report(out))


def fill_doc(emb, chunk):
    title = chunk['label'].split(' > ')[0]
    return emb.dpre.replace('{title}', title) + chunk['text']


# ---------------------------------------------------------------- report

SLICES = [
    ('it', lambda q: q['lang'] == 'it' and q['expected']),
    ('en orig', lambda q: q['variant'] == 'orig' and q['expected']),
    ('en para', lambda q: q['variant'] == 'para' and q['expected']),
    ('en extra', lambda q: q['lang'] == 'en' and q['variant'] == 'extra' and q['expected']),
    # The screen hint names the expected page in most questions, and then it alone
    # finds the page: these are the questions where it cannot.
    ('it, off-screen', lambda q: q['lang'] == 'it' and q['expected'] and off_screen(q)),
    ('en, off-screen', lambda q: q['lang'] == 'en' and q['expected'] and off_screen(q)),
]


def off_screen(q):
    return q['screen'] + '.md' not in q['expected']


def report(out):
    qs = {q['id']: q for q in out['questions']}
    runs = out['runs']
    keys = []
    for r in runs:
        k = (r['method'], r['model'], r['chunking'])
        if k not in keys:
            keys.append(k)

    lines = []
    head = '| Method | Model | Chunks |' + ''.join(
        f' {name} (n={sum(1 for q in out["questions"] if f(q))}) hit@1 / hit@3 / MRR |' for name, f in SLICES)
    lines += [head, '|---|---|---|' + '---:|' * len(SLICES)]
    for k in keys:
        cells = []
        for name, f in SLICES:
            rs = [r for r in runs if (r['method'], r['model'], r['chunking']) == k and f(qs[r['id']])]
            n = len(rs)
            h1 = sum(r['hit1'] for r in rs)
            h3 = sum(r['hit3'] for r in rs)
            mrr = sum(r['rr'] for r in rs) / n if n else 0
            cells.append(f' {h1}/{n} / {h3}/{n} / {mrr:.2f} |')
        lines.append(f'| {k[0]} | {k[1]} | {k[2]} |' + ''.join(cells))
    return '\n'.join(lines)


if __name__ == '__main__':
    main()
