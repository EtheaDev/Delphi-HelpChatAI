"""Does a translated question find the page of an English manual that the
question itself does not? The measurement of the proposal: when the language of
the chat differs from DocLanguage, a model turns the question into English search
terms before THelpChatDocIndex.Search, and the search runs on the question plus
those terms.

Inputs
  questions.json                     the questions, their screen and expected pages
Output
  questions-translated.json          the same questions, each with "translations":
                                     {translator: terms}, and the time and tokens
                                     of every call; the input of
                                     HelpChatAILLMBench --retrieval=questions-translated.json

Every question is translated, English ones too: in the engine the trigger is the
language of the chat, not the language of the question, so an English question
asked in an Italian chat goes through the translator as well, and must not lose.

The Claude key is read from %APPDATA%\\HelpChatAI\\helpchatai.json (Claude.ApiKey)
or ANTHROPIC_API_KEY, and never printed.

  python translate_queries.py [--translators=haiku,qwen,gemma] [--ollama=http://host:11434]
"""
import json
import os
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'questions-translated.json')
# A list of search terms is short: the cap is what stops a local model that
# loops on synonyms (qwen3-coder did, for five minutes).
MAX_TOKENS = 150
OLLAMA = 'http://localhost:11434'

SYSTEM = (
    'You prepare the search of the user manual of an application. The manual is written in '
    'English. Given the question of a user, which may be in any language, reply with one line '
    'of English search terms: the words the manual most likely uses for what the user asks, '
    'adding the common synonyms (for example: company, account; quote, proposal; delete, '
    'remove). Reply with the terms only: no preamble, no translation of the question, no '
    'explanation, no quotes. If the question is already in English, repeat its key words and '
    'add the synonyms.')

TRANSLATORS = {
    'haiku': ('claude', 'claude-haiku-5-5'),
    'qwen': ('ollama', 'qwen3-coder:30b'),
    'gemma': ('ollama', 'gemma4:12b'),
}
# gemma4 thinks unasked and spends the whole cap on it: the switch the engine
# also uses on Chat Completions.
EXTRA = {'gemma4:12b': {'reasoning_effort': 'none'}}


def post(url, payload, headers, timeout=300):
    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'),
                                 headers={'Content-Type': 'application/json', **headers})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode('utf-8'))


def claude_key():
    key = os.environ.get('ANTHROPIC_API_KEY', '')
    if key:
        return key
    path = os.path.join(os.environ['APPDATA'], 'HelpChatAI', 'helpchatai.json')
    return json.load(open(path, encoding='utf-8-sig')).get('Claude', {}).get('ApiKey', '')


def translate_claude(model, text, key):
    r = post('https://api.anthropic.com/v1/messages',
             {'model': model, 'max_tokens': 1024, 'system': SYSTEM,
              'messages': [{'role': 'user', 'content': text}]},
             {'x-api-key': key, 'anthropic-version': '2023-06-01'})
    out = ' '.join(b['text'] for b in r['content'] if b['type'] == 'text')
    u = r.get('usage', {})
    return out, u.get('input_tokens', 0), u.get('output_tokens', 0)


def translate_ollama(model, text):
    r = post(OLLAMA + '/v1/chat/completions',
             {'model': model, 'temperature': 0, 'max_tokens': MAX_TOKENS, **EXTRA.get(model, {}),
              'messages': [{'role': 'system', 'content': SYSTEM}, {'role': 'user', 'content': text}]},
             {})
    u = r.get('usage', {})
    return (r['choices'][0]['message'].get('content') or '', u.get('prompt_tokens', 0),
            u.get('completion_tokens', 0))


def main():
    global OLLAMA
    names = list(TRANSLATORS)
    for a in sys.argv[1:]:
        if a.startswith('--translators='):
            names = a[14:].split(',')
        elif a.startswith('--ollama='):
            OLLAMA = a[9:].rstrip('/')
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    data = json.load(open(os.path.join(HERE, 'questions.json'), encoding='utf-8-sig'))
    # Keep what the other translators wrote in a previous run.
    data['translators'] = {}
    if os.path.exists(OUT):
        old = json.load(open(OUT, encoding='utf-8'))
        prev = {q['id']: q for q in old['questions']}
        for q in data['questions']:
            for k in ('translations', 'translationStats'):
                if k in prev.get(q['id'], {}):
                    q[k] = {n: v for n, v in prev[q['id']][k].items() if n not in names}
        data['translators'] = {n: m for n, m in old.get('translators', {}).items() if n not in names}
    key = claude_key() if any(TRANSLATORS[n][0] == 'claude' for n in names) else ''
    for name in names:
        kind, model = TRANSLATORS[name]
        if kind == 'ollama':  # load the model before timing anything
            try:
                translate_ollama(model, 'Hello')
            except Exception as e:
                print(f'{name}: the model did not load ({e}); skipped')
                continue
        for q in data['questions']:
            t0 = time.perf_counter()
            try:
                if kind == 'claude':
                    out, tin, tout = translate_claude(model, q['text'], key)
                else:
                    out, tin, tout = translate_ollama(model, q['text'])
            except Exception as e:  # a failed translation searches with the question alone
                out, tin, tout = '', 0, 0
                print(f'  {name} {q["id"]}: {e}')
            ms = (time.perf_counter() - t0) * 1000
            out = ' '.join(out.split())
            q.setdefault('translations', {})[name] = out
            q.setdefault('translationStats', {})[name] = {'ms': round(ms), 'in': tin, 'out': tout}
            print(f'{name:6} {q["id"]:8} {ms:6.0f} ms  {out}', flush=True)
        data['translators'][name] = model
        data['translationPrompt'] = SYSTEM
        with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
