/* HelpChat panel — Ethea S.r.l. — Apache 2.0.
   HTMX drives the structure (history load, send, clear as HTML fragment swaps);
   the reply polling uses fetch so a transient error never surfaces as a page
   error. window.HC is injected by the server: {token, apiBase, pollMs, maxPolls,
   lang, labels, docs, docBase}. Native hosts call window.hcAsk(text, send),
   window.hcFocus(), window.hcOpenDoc(page), window.hcSystem(text) and, where
   they can listen, window.hcVoiceEnable/hcVoiceState/hcVoiceText.
   Links never navigate the panel: a documentation page (relative link, or one
   starting with docBase, when the server has docs) opens in the documentation
   view; any other relative link does nothing; http(s)/mailto links are left to
   the host, which opens them outside.
   The question box empties as soon as a question leaves; Up/Down recall the
   previous questions (the user bubbles of the conversation plus what was sent
   in this page), like a shell. */
(function () {
  'use strict';
  var HC = window.HC || {};
  var TOKEN_HEADER = 'X-HelpChat-Token';
  var body = document.getElementById('hc-body');
  var form = document.getElementById('hc-form');
  var input = document.getElementById('hc-input');
  var sendBtn = document.getElementById('hc-send');
  var stopBtn = document.getElementById('hc-stop');
  var footer = document.querySelector('.hc-chat-footer');
  var docView = document.getElementById('hc-doc');
  var docBody = document.getElementById('hc-doc-body');
  var docTitle = document.getElementById('hc-doc-title');
  var micBtn = document.getElementById('hc-mic');
  var docPage = '';          // page shown in the documentation view
  var docHistory = [];       // pages to go back to, inside the view
  var MAX_QUESTIONS = 100;
  var questions = [];        // previous questions, oldest first
  var questionPos = -1;      // index being shown by Up/Down; -1 = the draft
  var questionDraft = '';    // what was typed before browsing the questions
  var polling = {};          // message id -> attempts
  var pollingCount = 0;

  function api(path) { return (HC.apiBase || '') + path; }
  function scrollBottom() { body.scrollTop = body.scrollHeight; }
  function findMsg(id) {
    var nodes = body.querySelectorAll('[data-msgid]');
    for (var i = 0; i < nodes.length; i++) if (nodes[i].getAttribute('data-msgid') === id) return nodes[i];
    return null;
  }
  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function showSystem(text) {
    var div = document.createElement('div');
    div.className = 'hc-chat-msg hc-chat-system';
    div.innerHTML = '<div class="hc-chat-bubble">' + escapeHtml(text) + '</div>';
    body.appendChild(div);
    scrollBottom();
  }
  function setBusy(on) {
    stopBtn.hidden = !on;
    sendBtn.hidden = on;
  }

  // ---- reply polling (recursive timeout: no interval to cancel) -------------
  function startPoll(id) {
    if (polling[id] !== undefined) return;
    polling[id] = 0;
    pollingCount++;
    setBusy(true);
    poll(id);
  }
  function stopPoll(id) {
    if (polling[id] === undefined) return;
    delete polling[id];
    pollingCount--;
    if (pollingCount <= 0) { pollingCount = 0; setBusy(false); focusInput(); }
  }
  function poll(id) {
    if (polling[id] === undefined) return;
    if (++polling[id] > (HC.maxPolls || 900)) { stopPoll(id); return; }
    var headers = {}; headers[TOKEN_HEADER] = HC.token;
    fetch(api('/api/poll/' + encodeURIComponent(id)), { headers: headers, cache: 'no-store' })
      .then(function (r) { return r.ok ? r.text() : ''; })
      .then(function (html) {
        var el = findMsg(id);
        if (!el || !html) { stopPoll(id); return; }
        el.outerHTML = html;               // the old node is gone: re-read it
        scrollBottom();
        var fresh = findMsg(id);
        if (!fresh || !fresh.hasAttribute('data-pending')) { stopPoll(id); return; }
        setTimeout(function () { poll(id); }, HC.pollMs || 800);
      })
      .catch(function () {                 // transient error: just retry
        setTimeout(function () { poll(id); }, HC.pollMs || 800);
      });
  }
  function watchPending() {
    var nodes = body.querySelectorAll('[data-pending]');
    for (var i = 0; i < nodes.length; i++) startPoll(nodes[i].getAttribute('data-msgid'));
  }
  function cancelAll() {
    var headers = {}; headers[TOKEN_HEADER] = HC.token;
    Object.keys(polling).forEach(function (id) {
      fetch(api('/api/cancel/' + encodeURIComponent(id)), { method: 'POST', headers: headers }).catch(function () {});
    });
  }

  // ---- previous questions (Up/Down) -------------------------------------------
  function rememberQuestion(text) {
    text = String(text || '').trim();
    if (!text) return;
    if (questions[questions.length - 1] !== text) questions.push(text);
    if (questions.length > MAX_QUESTIONS) questions.shift();
  }
  // The conversation already holds the questions of earlier sessions: when the
  // history is (re)loaded they seed the list, if nothing was asked here yet.
  function seedQuestions() {
    if (questions.length) return;
    var nodes = body.querySelectorAll('.hc-chat-user .hc-chat-bubble');
    for (var i = 0; i < nodes.length; i++) rememberQuestion(nodes[i].innerText);
  }
  function showQuestion(pos) {
    questionPos = pos;
    input.value = pos < 0 ? questionDraft : questions[pos];
    autosize();
    input.setSelectionRange(input.value.length, input.value.length);
  }
  // Up only from the first line and Down only from the last one, so a
  // multi-line question can still be edited with the arrows.
  function onFirstLine() { return input.value.lastIndexOf('\n', input.selectionStart - 1) < 0; }
  function onLastLine() { return input.value.indexOf('\n', input.selectionEnd) < 0; }
  function browseQuestions(e) {
    if (e.shiftKey || e.altKey || e.ctrlKey || e.metaKey || !questions.length) return;
    if (e.key === 'ArrowUp' && onFirstLine()) {
      if (questionPos === 0) { e.preventDefault(); return; }
      if (questionPos < 0) questionDraft = input.value;
      e.preventDefault();
      showQuestion(questionPos < 0 ? questions.length - 1 : questionPos - 1);
    } else if (e.key === 'ArrowDown' && onLastLine() && questionPos >= 0) {
      e.preventDefault();
      showQuestion(questionPos + 1 < questions.length ? questionPos + 1 : -1);
    }
  }

  // ---- htmx wiring ---------------------------------------------------------
  // In htmx 2 detail.elt of a swap event is the target: who sent the request is
  // detail.requestConfig.elt.
  function fromForm(e) { return e.detail.requestConfig && e.detail.requestConfig.elt === form; }
  document.body.addEventListener('htmx:configRequest', function (e) {
    e.detail.headers[TOKEN_HEADER] = HC.token;
    if (e.detail.elt !== form) return;
    var text = (e.detail.parameters.message || '').trim();
    if (!text) { e.preventDefault(); return; }
    rememberQuestion(text);
  });
  // The parameters are already taken: the box empties while the reply comes.
  document.body.addEventListener('htmx:beforeRequest', function (e) {
    if (e.detail.elt !== form) return;
    if (voiceOn) uiCommand('mic-stop');   // the question is leaving: stop listening
    input.value = '';
    questionPos = -1;
    questionDraft = '';
    autosize();
  });
  document.body.addEventListener('htmx:afterSwap', function (e) {
    if (e.detail.target !== body) return;
    scrollBottom();
    watchPending();
    if (!fromForm(e)) seedQuestions();
    focusInput();          // every command ends with the caret back in the box
  });
  document.body.addEventListener('htmx:responseError', function () { showSystem(HC.labels.sendError); });
  document.body.addEventListener('htmx:sendError', function () { showSystem(HC.labels.sendError); });

  // ---- documentation view ------------------------------------------------------
  function hasScheme(href) { return /^[a-z][a-z0-9+.\-]*:/i.test(href) || href.indexOf('//') === 0; }
  function docIsOpen() { return !docView.hidden; }
  // {page, hash} of a documentation link, or null. A relative link is resolved
  // against the page it is in (inside the view) or against the root (a reply).
  function docTarget(href, fromDoc) {
    if (!HC.docs || !href) return null;
    var base = HC.docBase || '';
    if (base && href.toLowerCase().indexOf(base.toLowerCase()) === 0) href = href.substring(base.length);
    else if (hasScheme(href)) return null;
    if (href.charAt(0) === '#') return null;
    var u;
    try { u = new URL(href, 'http://doc/' + (fromDoc ? docPage : '')); } catch (ex) { return null; }
    var page = u.pathname.replace(/^\/+/, '');
    try { page = decodeURIComponent(page); } catch (ex) { /* keep it encoded */ }
    return page ? { page: page, hash: u.hash } : null;
  }
  function showDoc(on) {
    docView.hidden = !on;
    body.hidden = on;
    footer.hidden = on;
    if (!on) { docBody.innerHTML = ''; docPage = ''; docHistory = []; scrollBottom(); focusInput(); }
  }
  function scrollToHash(hash) {
    var target = null;
    if (hash && hash.length > 1) {
      var id = hash.substring(1);
      try { id = decodeURIComponent(id); } catch (ex) { /* as is */ }
      target = document.getElementById(id) || document.getElementsByName(id)[0] || null;
    }
    if (target && docBody.contains(target)) target.scrollIntoView(); else docBody.scrollTop = 0;
  }
  // mode: 'new' (from the chat or the host: a fresh history), 'link' (from a
  // page: the current one is remembered), 'back' (from the history).
  function openDoc(page, hash, mode) {
    var headers = {}; headers[TOKEN_HEADER] = HC.token;
    fetch(api('/api/doc?page=' + encodeURIComponent(page)), { headers: headers, cache: 'no-store' })
      .then(function (r) { return r.ok ? r.text() : null; })
      .then(function (html) {
        if (mode === 'new') docHistory = [];
        else if (mode === 'link' && docPage) docHistory.push(docPage);
        if (html === null) {
          docBody.innerHTML = '<p class="hc-chat-doc-missing">' +
            escapeHtml(String(HC.labels.docNotFound || '%s').replace('%s', page)) + '</p>';
          docTitle.textContent = page;
          docPage = '';
        } else {
          docBody.innerHTML = html;
          var article = docBody.firstElementChild;
          docPage = (article && article.getAttribute('data-page')) || page;
          docTitle.textContent = (article && article.getAttribute('data-title')) || page;
        }
        showDoc(true);
        scrollToHash(hash);
      })
      .catch(function () { showSystem(HC.labels.sendError); });
  }
  function docBack() {
    if (docHistory.length) openDoc(docHistory.pop(), '', 'back'); else showDoc(false);
  }
  document.getElementById('hc-doc-back').addEventListener('click', docBack);
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest ? e.target.closest('a[href]') : null;
    if (!a) return;
    var href = a.getAttribute('href');
    var fromDoc = docBody.contains(a);
    if (href.charAt(0) === '#') { e.preventDefault(); if (fromDoc) scrollToHash(href); return; }
    var target = docTarget(href, fromDoc);
    if (target) { e.preventDefault(); openDoc(target.page, target.hash, fromDoc ? 'link' : 'new'); return; }
    // A relative link that is not a page would load a server path in the panel.
    if (!hasScheme(href)) e.preventDefault();
  });

  // ---- keyboard and buttons --------------------------------------------------
  function autosize() {
    input.style.height = 'auto';
    input.style.height = Math.min(input.scrollHeight, 120) + 'px';
  }
  // The caret belongs in the question box: every command puts it back there,
  // unless the documentation view is open, which has a focus of its own.
  function focusInput() {
    if (docIsOpen()) return;
    try { input.focus({ preventScroll: true }); } catch (ex) { input.focus(); }
  }
  // Clicking a button must not take the focus away in the first place: it is
  // the default action of mousedown that moves it, and the click still happens.
  document.addEventListener('mousedown', function (e) {
    var el = e.target;
    while (el && el !== document.body) {
      if (el.tagName === 'BUTTON') { e.preventDefault(); return; }
      el = el.parentNode;
    }
  });
  function submit() {
    if (!input.value.trim()) return;
    htmx.trigger(form, 'submit');
  }
  // The page has no bridge to its host (FMX exposes none, a remote page has no
  // native side): what it asks of its host is an HTTP call the host listens to —
  // the same server when the engine is local, the loopback host channel when the
  // engine is remote. HC.hostCommands false means nobody is listening.
  function uiCommand(name) {
    if (HC.hostCommands === false) return;
    var headers = {}; headers[TOKEN_HEADER] = HC.uiToken || HC.token;
    fetch((HC.uiBase || HC.apiBase || '') + '/api/ui/' + name,
      { method: 'POST', headers: headers }).catch(function () {});
  }
  function closePanel() { uiCommand('close'); }

  // ---- voice input -----------------------------------------------------------
  // The page owns no microphone: the host listens (Windows speech recognition)
  // and pushes what it hears through hcVoiceText. A hypothesis replaces the
  // previous one, a recognized sentence stays, so the box fills while talking.
  var voiceOn = false;
  var voiceBase = '';      // the box before the dictation, plus every final piece
  function voiceJoin(a, b) {
    if (!a) return b;
    if (!b) return a;
    return /[\s([]$/.test(a) ? a + b : a + ' ' + b;
  }
  function voiceShow(hypothesis) {
    input.value = voiceJoin(voiceBase, hypothesis || '');
    autosize();
    input.setSelectionRange(input.value.length, input.value.length);
  }
  if (micBtn) {
    micBtn.addEventListener('click', function () {
      uiCommand(voiceOn ? 'mic-stop' : 'mic-start');
    });
  }
  // The microphone belongs to the host, not to the page: only a host that can
  // listen shows the button, and it brings its own label (already localized).
  window.hcVoiceEnable = function (on, label) {
    if (!micBtn) return;
    micBtn.hidden = !on;
    if (label) {
      micBtn.title = String(label);
      micBtn.setAttribute('aria-label', String(label));
    }
    if (!on) window.hcVoiceState(false);
  };
  // The host says when it starts and stops listening: two commands, never a
  // toggle, so the page and the host cannot disagree about the state.
  window.hcVoiceState = function (on) {
    voiceOn = !!on;
    if (micBtn) micBtn.setAttribute('aria-pressed', voiceOn ? 'true' : 'false');
    if (voiceOn) {
      voiceBase = input.value;
      focusInput();
    }
  };
  window.hcVoiceText = function (text, final) {
    if (!voiceOn) return;
    if (final) { voiceBase = voiceJoin(voiceBase, String(text || '')); voiceShow(''); }
    else voiceShow(String(text || ''));
    questionPos = -1;
  };
  input.addEventListener('input', function () { questionPos = -1; autosize(); });
  input.addEventListener('keydown', function (e) {
    if (e.key === 'ArrowUp' || e.key === 'ArrowDown') browseQuestions(e);
    else if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submit(); }
    else if (e.key === 'Escape') { e.preventDefault(); closePanel(); }
  });
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if (docIsOpen()) { e.preventDefault(); showDoc(false); } else closePanel();
  });
  stopBtn.addEventListener('click', cancelAll);
  var closeBtn = document.querySelector('[data-action="close"]');
  if (closeBtn) {
    if (HC.hostCommands === false) closeBtn.hidden = true;
    else closeBtn.addEventListener('click', closePanel);
  }

  // ---- native entry points ---------------------------------------------------
  window.hcAsk = function (text, send) {
    input.value = text || '';
    autosize();
    if (send) submit(); else focusInput();
  };
  // A line of system text in the conversation (the host reports a failure).
  window.hcSystem = function (text) { if (text) showSystem(String(text)); };
  window.hcFocus = function () { if (docIsOpen()) docBody.focus(); else focusInput(); };
  window.hcOpenDoc = function (page) { if (page) openDoc(String(page), '', 'new'); };
  // {"--hc-bg":"#...", ..., "color-scheme":"dark"}: the host pushes its colours
  // when its style changes; an empty object restores the stylesheet defaults.
  window.hcApplyTheme = function (vars) {
    var root = document.documentElement;
    var style = document.getElementById('hc-theme');
    if (style) style.textContent = '';
    var names = ['--hc-bg', '--hc-surface', '--hc-text', '--hc-muted', '--hc-border', '--hc-accent',
      '--hc-accent-text', '--hc-user-bg', '--hc-user-text', '--hc-assistant-bg', '--hc-assistant-text',
      '--hc-system-bg', '--hc-system-text', '--hc-error-bg', '--hc-error-text', '--hc-code-bg', '--hc-font'];
    names.forEach(function (n) { root.style.removeProperty(n); });
    root.style.removeProperty('color-scheme');
    if (!vars) return;
    Object.keys(vars).forEach(function (k) {
      if (k === 'color-scheme') root.style.colorScheme = vars[k];
      else if (k.indexOf('--hc-') === 0) root.style.setProperty(k, vars[k]);
    });
  };
  window.hcRefresh = function () { htmx.ajax('GET', api('/api/history'), { target: '#hc-body', swap: 'innerHTML' }); };

  autosize();
  focusInput();
})();
