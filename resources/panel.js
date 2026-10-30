/* HelpChat panel — Ethea S.r.l. — Apache 2.0.
   HTMX drives the structure (history load, send, clear as HTML fragment swaps);
   the reply polling uses fetch so a transient error never surfaces as a page
   error. window.HC is injected by the server: {token, apiBase, pollMs, maxPolls,
   lang, labels, docs, docBase}. Native hosts call window.hcAsk(text, send),
   window.hcFocus(), window.hcOpenDoc(page), window.hcSystem(text),
   window.hcSetAssistant(name, iconDataUri) and, where they can listen,
   window.hcVoiceEnable/hcVoiceState/hcVoiceText.
   Links never navigate the panel: a documentation page (relative link, or one
   starting with docBase, when the server has docs) opens in the documentation
   view; any other relative link does nothing; http(s)/mailto links are left to
   the host, which opens them outside.
   The question box empties as soon as a question leaves; Up/Down recall the
   previous questions (the user bubbles of the conversation plus what was sent
   in this page), like a shell.
   Attachments (HC.attach): the clip and dropping a file on the panel post the
   bytes to /api/attach, which answers with the chip to draw. They belong to
   the conversation, not to one question - they are sent again with every
   question until ↺ clears it, which is what makes a second question about the
   same document work.
   The file-type glyphs are Material Design Icons (Pictogrammers), Apache 2.0:
   generic glyphs, no brand logo - the Brand/Logos category of that set is
   excluded from its licence and none of it is used here. */
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
  var attachBar = document.getElementById('hc-attachments');
  var fileInput = document.getElementById('hc-file');
  var clipBtn = document.getElementById('hc-clip');
  var attachments = [];      // {id, name, sizeText, ext} as the server took them
  var attachSeq = 0;         // local id of a chip while it is still uploading

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
    // The conversation was cleared: the engine dropped its attachments with
    // it, so the bar has to go as well.
    if (e.detail.requestConfig &&
        String(e.detail.requestConfig.path || '').indexOf('/api/clear') >= 0) {
      attachments = [];
      renderAttachments();
    }
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

  // ---- attachments -----------------------------------------------------------
  // One glyph per family, drawn at 24x24. A document is red, a spreadsheet
  // green, a presentation orange, an image purple: the convention everyone
  // reads at a glance, and none of it is a logo.
  var ICONS = {
    pdf: ['#d93025', 'M19 3H5C3.9 3 3 3.9 3 5V19C3 20.1 3.9 21 5 21H19C20.1 21 21 20.1 21 19V5C21 3.9 20.1 3 19 3M9.5 11.5C9.5 12.3 8.8 13 8 13H7V15H5.5V9H8C8.8 9 9.5 9.7 9.5 10.5V11.5M14.5 13.5C14.5 14.3 13.8 15 13 15H10.5V9H13C13.8 9 14.5 9.7 14.5 10.5V13.5M18.5 10.5H17V11.5H18.5V13H17V15H15.5V9H18.5V10.5M12 10.5H13V13.5H12V10.5M7 10.5H8V11.5H7V10.5Z'],
    image: ['#8e24aa', 'M13,9H18.5L13,3.5V9M6,2H14L20,8V20A2,2 0 0,1 18,22H6C4.89,22 4,21.1 4,20V4C4,2.89 4.89,2 6,2M6,20H15L18,20V12L14,16L12,14L6,20M8,9A2,2 0 0,0 6,11A2,2 0 0,0 8,13A2,2 0 0,0 10,11A2,2 0 0,0 8,9Z'],
    word: ['#2b579a', 'M15.5,17H14L12,9.5L10,17H8.5L6.1,7H7.8L9.34,14.5L11.3,7H12.7L14.67,14.5L16.2,7H17.9M19,3H5C3.89,3 3,3.89 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,3.89 20.1,3 19,3Z'],
    excel: ['#217346', 'M16.2,17H14.2L12,13.2L9.8,17H7.8L11,12L7.8,7H9.8L12,10.8L14.2,7H16.2L13,12M19,3H5C3.89,3 3,3.89 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,3.89 20.1,3 19,3Z'],
    ppt: ['#d24726', 'M9.8,13.4H12.3C13.8,13.4 14.46,13.12 15.1,12.58C15.74,12.03 16,11.25 16,10.23C16,9.26 15.75,8.5 15.1,7.88C14.45,7.29 13.83,7 12.3,7H8V17H9.8V13.4M19,3A2,2 0 0,1 21,5V19A2,2 0 0,1 19,21H5A2,2 0 0,1 3,19V5C3,3.89 3.9,3 5,3H19M9.8,12V8.4H12.1C12.76,8.4 13.27,8.65 13.6,9C13.93,9.35 14.1,9.72 14.1,10.24C14.1,10.8 13.92,11.19 13.6,11.5C13.28,11.81 12.9,12 12.22,12H9.8Z'],
    csv: ['#217346', 'M14 2H6C4.9 2 4 2.9 4 4V20C4 21.1 4.9 22 6 22H18C19.1 22 20 21.1 20 20V8L14 2M15 16L13 20H10L12 16H9V11H15V16M13 9V3.5L18.5 9H13Z'],
    json: ['#b08000', 'M5,3H7V5H5V10A2,2 0 0,1 3,12A2,2 0 0,1 5,14V19H7V21H5C3.93,20.73 3,20.1 3,19V15A2,2 0 0,0 1,13H0V11H1A2,2 0 0,0 3,9V5A2,2 0 0,1 5,3M19,3A2,2 0 0,1 21,5V9A2,2 0 0,0 23,11H24V13H23A2,2 0 0,0 21,15V19A2,2 0 0,1 19,21H17V19H19V14A2,2 0 0,1 21,12A2,2 0 0,1 19,10V5H17V3H19M12,15A1,1 0 0,1 13,16A1,1 0 0,1 12,17A1,1 0 0,1 11,16A1,1 0 0,1 12,15M8,15A1,1 0 0,1 9,16A1,1 0 0,1 8,17A1,1 0 0,1 7,16A1,1 0 0,1 8,15M16,15A1,1 0 0,1 17,16A1,1 0 0,1 16,17A1,1 0 0,1 15,16A1,1 0 0,1 16,15Z'],
    text: ['', 'M6,2A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2H6M6,4H13V9H18V20H6V4M8,12V14H16V12H8M8,16V18H13V16H8Z'],
    other: ['', 'M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z']
  };
  var BY_EXT = {
    pdf: 'pdf',
    png: 'image', jpg: 'image', jpeg: 'image', gif: 'image', webp: 'image', bmp: 'image',
    doc: 'word', docx: 'word', odt: 'word', rtf: 'word',
    xls: 'excel', xlsx: 'excel', ods: 'excel',
    ppt: 'ppt', pptx: 'ppt', odp: 'ppt',
    csv: 'csv', tsv: 'csv',
    json: 'json',
    txt: 'text', md: 'text', log: 'text', ini: 'text', xml: 'text', yaml: 'text', yml: 'text'
  };
  function iconFor(ext) { return ICONS[BY_EXT[String(ext || '').toLowerCase()] || 'other']; }
  function iconSvg(ext) {
    var icon = iconFor(ext);
    return '<svg class="hc-chat-chip-icon" viewBox="0 0 24 24" aria-hidden="true">' +
      '<path fill="' + (icon[0] || 'currentColor') + '" d="' + icon[1] + '"/></svg>';
  }

  function renderAttachments() {
    if (!attachBar) return;
    var html = '';
    for (var i = 0; i < attachments.length; i++) {
      var a = attachments[i];
      html += '<span class="hc-chat-chip' + (a.busy ? ' hc-chat-chip-busy' : '') +
        '" data-att="' + escapeHtml(a.id) + '" title="' + escapeHtml(a.name) + '">' +
        (a.busy ? '<span class="hc-chat-spinner" role="progressbar"></span>' : iconSvg(a.ext)) +
        '<span class="hc-chat-chip-name">' + escapeHtml(a.name) + '</span>' +
        (a.sizeText ? '<span class="hc-chat-chip-size">' + escapeHtml(a.sizeText) + '</span>' : '') +
        (a.busy ? '' : '<button type="button" class="hc-chat-chip-x" data-att-x="' +
          escapeHtml(a.id) + '" title="' + escapeHtml(HC.labels.attachRemove || '') +
          '" aria-label="' + escapeHtml(HC.labels.attachRemove || '') + '">&#x2715;</button>') +
        '</span>';
    }
    attachBar.innerHTML = html;
    attachBar.hidden = attachments.length === 0;
  }
  function extOf(name) {
    var dot = String(name || '').lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1);
  }
  function dropAttachment(id) {
    for (var i = 0; i < attachments.length; i++)
      if (attachments[i].id === id) { attachments.splice(i, 1); return; }
  }
  // The bytes go up as the whole body: no multipart to build here and none to
  // decode on the other side. The name rides in the query string.
  function upload(file) {
    if (!HC.attach || !file) return;
    var maxKB = HC.attachMaxKB || 0;
    if (maxKB > 0 && file.size > maxKB * 1024) {
      showSystem(String(HC.attachTooLarge || '%s').replace('%s', file.name));
      return;
    }
    var local = 'up' + (++attachSeq);
    attachments.push({ id: local, name: file.name, ext: extOf(file.name), busy: true });
    renderAttachments();
    var headers = {}; headers[TOKEN_HEADER] = HC.token;
    headers['Content-Type'] = 'application/octet-stream';
    fetch(api('/api/attach?name=' + encodeURIComponent(file.name)),
      { method: 'POST', headers: headers, body: file })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (data) {
        dropAttachment(local);
        if (!data) { showSystem(HC.labels.attachFailed); renderAttachments(); return; }
        // The server refused it (a type no model reads, a limit): its sentence
        // is already localized and says what to do about it.
        if (data.error) { showSystem(data.error); renderAttachments(); return; }
        attachments.push({ id: data.id, name: data.name, ext: data.ext, sizeText: data.sizeText });
        renderAttachments();
        focusInput();
      })
      .catch(function () {
        dropAttachment(local);
        renderAttachments();
        showSystem(HC.labels.attachFailed);
      });
  }
  function removeAttachment(id) {
    var headers = {}; headers[TOKEN_HEADER] = HC.token;
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
    fetch(api('/api/attach/remove'),
      { method: 'POST', headers: headers, body: 'id=' + encodeURIComponent(id) })
      .catch(function () {});
    dropAttachment(id);
    renderAttachments();
    focusInput();
  }
  function uploadList(files) {
    for (var i = 0; i < files.length; i++) upload(files[i]);
  }
  // The attachments belong to the conversation, and the server is where they
  // live: the page asks for them when it loads, the way it asks for the
  // history. Without this a reload - and a VCL style change recreates the
  // window, which reloads the page - would leave the bar empty while the
  // documents kept going out with every question.
  function loadAttachments() {
    if (!HC.attach) return;
    var headers = {}; headers[TOKEN_HEADER] = HC.token;
    fetch(api('/api/attachments'), { headers: headers, cache: 'no-store' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (data) {
        if (!data || !data.items) return;
        // Whatever was still uploading when this started keeps its chip.
        var busy = attachments.filter(function (a) { return a.busy; });
        attachments = data.items.concat(busy);
        renderAttachments();
      })
      .catch(function () {});
  }
  if (clipBtn && fileInput) {
    if (HC.attach) {
      clipBtn.hidden = false;
      loadAttachments();
      if (HC.attachAccept) fileInput.setAttribute('accept', HC.attachAccept);
    }
    clipBtn.addEventListener('click', function () { fileInput.click(); });
    fileInput.addEventListener('change', function () {
      uploadList(fileInput.files);
      fileInput.value = '';     // the same file twice in a row still fires change
    });
  }
  if (attachBar) {
    attachBar.addEventListener('click', function (e) {
      var btn = e.target && e.target.closest ? e.target.closest('[data-att-x]') : null;
      if (btn) removeAttachment(btn.getAttribute('data-att-x'));
    });
  }
  // Dropping a file anywhere on the panel attaches it: the clip is for those
  // who look for a button, this is for everybody else.
  document.addEventListener('dragover', function (e) {
    if (!HC.attach) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'copy';
  });
  document.addEventListener('drop', function (e) {
    if (!HC.attach) return;
    e.preventDefault();
    if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files.length)
      uploadList(e.dataTransfer.files);
  });

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
  /* The name and the icon of the header, changed without reloading the page:
     the page it loads with already carries them, this is for a host that
     changes them while the panel is open. An icon is taken only as a data:
     URI, which is all the CSP of the page would fetch anyway. */
  window.hcSetAssistant = function (name, icon) {
    var brand = document.querySelector('.hc-chat-brand');
    var title = document.querySelector('.hc-chat-title');
    if (title && name) {
      title.textContent = String(name);
      document.title = String(name);
    }
    if (!brand) return;
    var img = brand.querySelector('.hc-chat-icon');
    var uri = icon ? String(icon) : '';
    if (uri.slice(0, 11).toLowerCase() !== 'data:image/') uri = '';
    if (!uri) {
      if (img) brand.removeChild(img);
      return;
    }
    if (!img) {
      img = document.createElement('img');
      img.className = 'hc-chat-icon';
      img.alt = '';
      img.setAttribute('aria-hidden', 'true');
      brand.insertBefore(img, brand.firstChild);
    }
    img.src = uri;
  };

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
