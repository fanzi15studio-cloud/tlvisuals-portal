import Foundation

enum ClientHTML {
    /// Le jeton est injecté côté serveur pour que la page fonctionne sans que
    /// l'utilisateur ait à le retaper dans chaque requête.
    static func page(token: String) -> String {
        // Le jeton atterrit dans un littéral JavaScript : on neutralise ce qui pourrait en sortir.
        let escaped = token
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "<", with: "\\u003C")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        return template.replacingOccurrences(of: "__TOKEN__", with: escaped)
    }

    // Volontairement en JS « ancien » (pas de ?. ni de ??) : le navigateur des
    // Tesla MCU2 tourne sur un Chromium daté.
    private static let template = #"""
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<title>Écran Mac</title>
<style>
  :root { --bg:#000; --panel:rgba(20,22,26,.94); --line:rgba(255,255,255,.14); --txt:#f2f4f7; --dim:#9aa3ad; --accent:#2f7cf6; }
  * { box-sizing:border-box; -webkit-tap-highlight-color:transparent; }
  html, body {
    margin:0; padding:0; width:100%; height:100%; background:var(--bg); color:var(--txt);
    overflow:hidden; overscroll-behavior:none; touch-action:none;
    -webkit-user-select:none; user-select:none;
    font-family:-apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
  }
  #stage { position:fixed; top:0; left:0; right:0; bottom:0; display:flex; align-items:center; justify-content:center; overflow:hidden; }
  #screen { max-width:100%; max-height:100%; display:block; transform-origin:0 0; will-change:transform; }
  #screen.pending { opacity:.35; }

  #menuBtn {
    position:fixed; top:10px; right:10px; width:52px; height:52px; border-radius:26px;
    border:1px solid var(--line); background:rgba(20,22,26,.7); color:var(--txt);
    font-size:22px; line-height:1; z-index:30;
  }
  #menuBtn.hidden { opacity:.18; }

  #panel {
    position:fixed; left:0; right:0; bottom:0; z-index:40;
    background:var(--panel); border-top:1px solid var(--line);
    padding:14px 14px 18px; transform:translateY(110%); transition:transform .22s ease;
    max-height:70%; overflow-y:auto; -webkit-overflow-scrolling:touch; touch-action:pan-y;
  }
  #panel.open { transform:translateY(0); }
  .row { display:flex; flex-wrap:wrap; align-items:center; margin:0 0 10px; }
  .row > * { margin:0 8px 8px 0; }
  .label { color:var(--dim); font-size:13px; text-transform:uppercase; letter-spacing:.06em; width:100%; margin:2px 0 6px; }
  button.b {
    min-height:52px; padding:0 18px; border-radius:12px; border:1px solid var(--line);
    background:#25282e; color:var(--txt); font-size:16px; font-weight:500;
  }
  button.b.on { background:var(--accent); border-color:var(--accent); color:#fff; }
  button.b.wide { flex:1 1 auto; }
  button.k { min-width:64px; min-height:52px; font-size:17px; }

  #kbd { position:fixed; left:-9999px; top:0; opacity:0; width:10px; height:10px; }

  #status { position:fixed; top:10px; left:10px; z-index:30; font-size:12px; color:var(--dim);
            background:rgba(20,22,26,.7); border:1px solid var(--line); border-radius:12px; padding:6px 10px; }
  #status.bad { color:#ff8a80; }

  #hint { position:fixed; top:0; left:0; right:0; bottom:0; z-index:50; background:rgba(0,0,0,.86);
          display:flex; align-items:center; justify-content:center; padding:24px; }
  #hint.gone { display:none; }
  #hintCard { max-width:620px; }
  #hintCard h1 { font-size:22px; margin:0 0 14px; }
  #hintCard ul { margin:0 0 20px; padding-left:20px; line-height:1.75; font-size:16px; color:#dfe4ea; }
  .ripple { position:fixed; width:56px; height:56px; margin:-28px 0 0 -28px; border-radius:28px;
            border:2px solid rgba(255,255,255,.85); z-index:20; pointer-events:none; animation:pop .4s ease-out forwards; }
  @keyframes pop { from { transform:scale(.3); opacity:.9; } to { transform:scale(1); opacity:0; } }
</style>
</head>
<body>

<div id="stage"><img id="screen" alt=""></div>
<div id="status">connexion…</div>
<button id="menuBtn" aria-label="Réglages">☰</button>
<input id="kbd" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">

<div id="panel">
  <div class="row"><span class="label">Mode tactile</span>
    <button class="b on wide" id="modeTouch">Tactile — glisser = défiler</button>
    <button class="b wide" id="modeMouse">Souris — glisser = curseur</button>
  </div>
  <div class="row"><span class="label">Qualité de l'image</span>
    <button class="b" data-preset="eco">Éco</button>
    <button class="b on" data-preset="normal">Normal</button>
    <button class="b" data-preset="sharp">Net</button>
    <button class="b" data-preset="max">Max</button>
  </div>
  <div class="row"><span class="label">Affichage</span>
    <button class="b" id="zoomOut">Zoom −</button>
    <button class="b" id="zoomReset">100 %</button>
    <button class="b" id="zoomIn">Zoom +</button>
    <button class="b" id="invert">Défilement inversé</button>
    <button class="b" id="full">Plein écran</button>
    <button class="b" id="reconnect">Reconnecter</button>
  </div>
  <div class="row"><span class="label">Clavier</span>
    <button class="b" id="kbOpen">Ouvrir le clavier</button>
    <button class="b k" data-key="Enter">⏎</button>
    <button class="b k" data-key="Backspace">⌫</button>
    <button class="b k" data-key="Tab">⇥</button>
    <button class="b k" data-key="Escape">esc</button>
    <button class="b k" data-key="ArrowLeft">←</button>
    <button class="b k" data-key="ArrowDown">↓</button>
    <button class="b k" data-key="ArrowUp">↑</button>
    <button class="b k" data-key="ArrowRight">→</button>
  </div>
  <div class="row"><span class="label">Raccourcis</span>
    <button class="b" data-key="C" data-mods="cmd">⌘ Copier</button>
    <button class="b" data-key="V" data-mods="cmd">⌘ Coller</button>
    <button class="b" data-key="X" data-mods="cmd">⌘ Couper</button>
    <button class="b" data-key="Z" data-mods="cmd">⌘ Annuler</button>
    <button class="b" data-key="A" data-mods="cmd">⌘ Tout</button>
    <button class="b" data-key="S" data-mods="cmd">⌘ Enregistrer</button>
    <button class="b wide" id="close">Fermer</button>
  </div>
</div>

<div id="hint"><div id="hintCard">
  <h1>Écran Mac déporté</h1>
  <ul>
    <li><b>Appui simple</b> : clic — <b>double appui</b> : double-clic</li>
    <li><b>Appui long</b> : clic droit (mode Tactile)</li>
    <li><b>Appui long puis glisser</b> : glisser-déposer / sélection</li>
    <li><b>Glisser un doigt</b> : défilement (mode Tactile) ou déplacement du curseur (mode Souris)</li>
    <li><b>Deux doigts</b> : zoomer et déplacer la vue</li>
    <li><b>☰ en haut à droite</b> : qualité, clavier, zoom</li>
  </ul>
  <button class="b wide" id="hintOk">Commencer</button>
</div></div>

<script>
(function () {
  var TOKEN = "__TOKEN__";
  var img = document.getElementById('screen');
  var stage = document.getElementById('stage');
  var panel = document.getElementById('panel');
  var statusEl = document.getElementById('status');
  var kbdInput = document.getElementById('kbd');

  var mode = 'touch';          // 'touch' | 'mouse'
  var invertScroll = false;
  var remote = { w: 1440, h: 900 };
  var view = { scale: 1, tx: 0, ty: 0 };
  var queue = [];
  var pointers = {};
  var pointerOrder = [];
  var gesture = null;          // null | 'scroll' | 'cursor' | 'drag' | 'pinch' | 'consumed'
  var pressTimer = null;
  var buttonHeld = false;
  var lastTap = { t: 0, x: 0, y: 0 };
  var pinch = null;

  function url(path) {
    var sep = path.indexOf('?') >= 0 ? '&' : '?';
    return path + (TOKEN ? sep + 't=' + encodeURIComponent(TOKEN) : '');
  }

  // ---------- flux vidéo ----------

  function connectStream() {
    img.className = 'pending';
    img.src = url('/stream?r=' + new Date().getTime());
  }
  img.addEventListener('load', function () { img.className = ''; });
  img.addEventListener('error', function () { setTimeout(connectStream, 1500); });

  // ---------- envoi des événements ----------

  function push(event) {
    queue.push(event);
    if (queue.length > 120) { queue.splice(0, queue.length - 120); }
  }

  var flushing = false;
  function flush() {
    if (flushing || queue.length === 0) { return; }
    var batch = queue;
    queue = [];
    flushing = true;
    fetch(url('/input'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ events: batch })
    }).then(function () { flushing = false; })
      .catch(function () { flushing = false; });
  }
  setInterval(flush, 40);

  // ---------- coordonnées ----------

  function norm(clientX, clientY) {
    var r = img.getBoundingClientRect();
    if (r.width <= 0 || r.height <= 0) { return null; }
    return { x: (clientX - r.left) / r.width, y: (clientY - r.top) / r.height };
  }

  // Ratio entre un pixel affiché sur la Tesla et un point de l'écran Mac.
  function remoteRatio() {
    var r = img.getBoundingClientRect();
    if (r.width <= 0) { return 1; }
    return remote.w / r.width;
  }

  function ripple(x, y) {
    var el = document.createElement('div');
    el.className = 'ripple';
    el.style.left = x + 'px';
    el.style.top = y + 'px';
    document.body.appendChild(el);
    setTimeout(function () { if (el.parentNode) { el.parentNode.removeChild(el); } }, 420);
  }

  // ---------- transformation de la vue ----------

  function applyView() {
    if (view.scale === 1 && view.tx === 0 && view.ty === 0) {
      img.style.transform = '';
      return;
    }
    img.style.transform = 'translate(' + view.tx + 'px,' + view.ty + 'px) scale(' + view.scale + ')';
  }

  function zoomBy(factor, cx, cy) {
    var next = Math.min(4, Math.max(1, view.scale * factor));
    if (next === view.scale) { return; }
    var k = next / view.scale;
    view.tx = cx - k * (cx - view.tx);
    view.ty = cy - k * (cy - view.ty);
    view.scale = next;
    if (view.scale <= 1.001) { view = { scale: 1, tx: 0, ty: 0 }; }
    applyView();
  }

  // ---------- gestes ----------

  function clearPressTimer() {
    if (pressTimer) { clearTimeout(pressTimer); pressTimer = null; }
  }

  stage.addEventListener('pointerdown', function (e) {
    e.preventDefault();
    if (stage.setPointerCapture) { try { stage.setPointerCapture(e.pointerId); } catch (err) {} }

    pointers[e.pointerId] = { x: e.clientX, y: e.clientY, sx: e.clientX, sy: e.clientY, t: new Date().getTime() };
    pointerOrder.push(e.pointerId);

    if (pointerOrder.length === 2) {
      clearPressTimer();
      var a = pointers[pointerOrder[0]], b = pointers[pointerOrder[1]];
      if (a && b) {
        pinch = {
          dist: Math.max(1, Math.hypot(b.x - a.x, b.y - a.y)),
          cx: (a.x + b.x) / 2,
          cy: (a.y + b.y) / 2
        };
        gesture = 'pinch';
      }
      return;
    }

    if (pointerOrder.length !== 1) { return; }
    gesture = null;

    clearPressTimer();
    pressTimer = setTimeout(function () {
      pressTimer = null;
      if (gesture !== null) { return; }
      var p = pointers[pointerOrder[0]];
      if (!p) { return; }
      if (mode === 'touch') {
        var n = norm(p.x, p.y);
        if (n) { push({ t: 'down', x: n.x, y: n.y }); }
        buttonHeld = true;
        gesture = 'drag';
      } else {
        push({ t: 'down' });
        buttonHeld = true;
        gesture = 'cursor';
      }
      ripple(p.x, p.y);
    }, 550);
  }, false);

  stage.addEventListener('pointermove', function (e) {
    var p = pointers[e.pointerId];
    if (!p) { return; }
    e.preventDefault();

    var dx = e.clientX - p.x;
    var dy = e.clientY - p.y;
    p.x = e.clientX;
    p.y = e.clientY;

    if (gesture === 'pinch' && pointerOrder.length >= 2) {
      var a = pointers[pointerOrder[0]], b = pointers[pointerOrder[1]];
      if (!a || !b || !pinch) { return; }
      var dist = Math.max(1, Math.hypot(b.x - a.x, b.y - a.y));
      var cx = (a.x + b.x) / 2, cy = (a.y + b.y) / 2;
      zoomBy(dist / pinch.dist, cx, cy);
      if (view.scale > 1) {
        view.tx += cx - pinch.cx;
        view.ty += cy - pinch.cy;
        applyView();
      }
      pinch.dist = dist; pinch.cx = cx; pinch.cy = cy;
      return;
    }

    if (pointerOrder.length !== 1 || e.pointerId !== pointerOrder[0]) { return; }

    var travel = Math.hypot(e.clientX - p.sx, e.clientY - p.sy);
    if (gesture === null && travel > 12) {
      clearPressTimer();
      gesture = (mode === 'touch') ? 'scroll' : 'cursor';
    }

    if (gesture === 'scroll') {
      var sign = invertScroll ? -1 : 1;
      push({ t: 'scroll', dx: sign * dx, dy: sign * dy });
    } else if (gesture === 'cursor') {
      var ratio = remoteRatio();
      var speed = Math.hypot(dx, dy);
      var accel = 1 + Math.min(speed / 14, 1.6);
      push({ t: 'moverel', dx: dx * ratio * accel, dy: dy * ratio * accel });
    } else if (gesture === 'drag') {
      var n = norm(e.clientX, e.clientY);
      if (n) { push({ t: 'drag', x: n.x, y: n.y }); }
    }
  }, false);

  function endPointer(e) {
    var p = pointers[e.pointerId];
    delete pointers[e.pointerId];
    var index = pointerOrder.indexOf(e.pointerId);
    if (index >= 0) { pointerOrder.splice(index, 1); }
    if (!p) { return; }
    clearPressTimer();

    if (gesture === 'pinch') {
      if (pointerOrder.length === 0) { gesture = null; pinch = null; }
      return;
    }

    if (buttonHeld) {
      var n = norm(e.clientX, e.clientY);
      if (mode === 'touch' && n) { push({ t: 'up', x: n.x, y: n.y }); } else { push({ t: 'up' }); }
      buttonHeld = false;
    } else if (gesture === null) {
      // Appui bref : clic. Deux appuis rapprochés = double-clic natif macOS.
      var now = new Date().getTime();
      var near = Math.hypot(p.sx - lastTap.x, p.sy - lastTap.y) < 40;
      var count = (now - lastTap.t < 400 && near) ? 2 : 1;

      if (mode === 'mouse') {
        // Mode trackpad : on clique là où le curseur se trouve, pas sous le doigt.
        push({ t: 'click', n: count });
        lastTap = { t: now, x: p.sx, y: p.sy };
        flush();
      } else {
        var target = norm(p.sx, p.sy);
        if (target) {
          push({ t: 'click', x: target.x, y: target.y, n: count });
          lastTap = { t: now, x: p.sx, y: p.sy };
          flush();
        }
      }
    }

    if (pointerOrder.length === 0) { gesture = null; pinch = null; }
  }

  stage.addEventListener('pointerup', endPointer, false);
  stage.addEventListener('pointercancel', endPointer, false);
  stage.addEventListener('contextmenu', function (e) { e.preventDefault(); }, false);
  // On bloque le rebond du navigateur Tesla, sauf dans le panneau qui doit rester défilable.
  document.addEventListener('touchmove', function (e) {
    var node = e.target;
    while (node) {
      if (node === panel) { return; }
      node = node.parentNode;
    }
    e.preventDefault();
  }, { passive: false });

  // ---------- clavier ----------

  var SPECIAL = {
    Enter: 'Enter', Backspace: 'Backspace', Tab: 'Tab', Escape: 'Escape',
    ArrowLeft: 'ArrowLeft', ArrowRight: 'ArrowRight', ArrowUp: 'ArrowUp', ArrowDown: 'ArrowDown',
    Home: 'Home', End: 'End', PageUp: 'PageUp', PageDown: 'PageDown', Delete: 'ForwardDelete'
  };

  kbdInput.addEventListener('keydown', function (e) {
    var key = e.key;
    if (!key) { return; }
    if (SPECIAL[key]) {
      var mods = [];
      if (e.metaKey) { mods.push('cmd'); }
      if (e.shiftKey) { mods.push('shift'); }
      if (e.altKey) { mods.push('alt'); }
      if (e.ctrlKey) { mods.push('ctrl'); }
      push({ t: 'key', k: SPECIAL[key], mods: mods });
      e.preventDefault();
      flush();
      return;
    }
    if (key.length === 1 && !e.metaKey && !e.ctrlKey) {
      push({ t: 'text', s: key });
      e.preventDefault();
      flush();
    }
  }, false);

  // Certains claviers virtuels n'émettent pas de keydown : on rattrape via `input`.
  kbdInput.addEventListener('input', function () {
    var value = kbdInput.value;
    kbdInput.value = '';
    if (value) { push({ t: 'text', s: value }); flush(); }
  }, false);

  function openKeyboard() {
    kbdInput.value = '';
    kbdInput.focus();
  }

  // ---------- interface ----------

  function setMode(next) {
    mode = next;
    document.getElementById('modeTouch').className = 'b wide' + (next === 'touch' ? ' on' : '');
    document.getElementById('modeMouse').className = 'b wide' + (next === 'mouse' ? ' on' : '');
  }

  function setPreset(name, button) {
    var buttons = document.querySelectorAll('[data-preset]');
    for (var i = 0; i < buttons.length; i++) { buttons[i].className = 'b'; }
    button.className = 'b on';
    fetch(url('/config'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ preset: name })
    }).then(function () { setTimeout(connectStream, 250); }).catch(function () {});
  }

  document.getElementById('menuBtn').addEventListener('click', function () {
    panel.className = panel.className.indexOf('open') >= 0 ? '' : 'open';
  }, false);
  document.getElementById('close').addEventListener('click', function () { panel.className = ''; }, false);
  document.getElementById('modeTouch').addEventListener('click', function () { setMode('touch'); }, false);
  document.getElementById('modeMouse').addEventListener('click', function () { setMode('mouse'); }, false);
  document.getElementById('kbOpen').addEventListener('click', openKeyboard, false);
  document.getElementById('reconnect').addEventListener('click', connectStream, false);
  document.getElementById('zoomIn').addEventListener('click', function () {
    zoomBy(1.25, window.innerWidth / 2, window.innerHeight / 2);
  }, false);
  document.getElementById('zoomOut').addEventListener('click', function () {
    zoomBy(0.8, window.innerWidth / 2, window.innerHeight / 2);
  }, false);
  document.getElementById('zoomReset').addEventListener('click', function () {
    view = { scale: 1, tx: 0, ty: 0 }; applyView();
  }, false);
  document.getElementById('invert').addEventListener('click', function () {
    invertScroll = !invertScroll;
    this.className = 'b' + (invertScroll ? ' on' : '');
  }, false);
  document.getElementById('full').addEventListener('click', function () {
    var el = document.documentElement;
    if (document.fullscreenElement) {
      if (document.exitFullscreen) { document.exitFullscreen(); }
    } else if (el.requestFullscreen) {
      el.requestFullscreen();
    } else if (el.webkitRequestFullscreen) {
      el.webkitRequestFullscreen();
    }
  }, false);
  document.getElementById('hintOk').addEventListener('click', function () {
    document.getElementById('hint').className = 'gone';
  }, false);

  var presetButtons = document.querySelectorAll('[data-preset]');
  for (var i = 0; i < presetButtons.length; i++) {
    (function (button) {
      button.addEventListener('click', function () { setPreset(button.getAttribute('data-preset'), button); }, false);
    })(presetButtons[i]);
  }

  var keyButtons = document.querySelectorAll('[data-key]');
  for (var j = 0; j < keyButtons.length; j++) {
    (function (button) {
      button.addEventListener('click', function () {
        var mods = button.getAttribute('data-mods');
        push({ t: 'key', k: button.getAttribute('data-key'), mods: mods ? mods.split(',') : [] });
        flush();
      }, false);
    })(keyButtons[j]);
  }

  // ---------- état de la connexion ----------

  function refreshStatus() {
    var started = new Date().getTime();
    fetch(url('/info')).then(function (response) {
      return response.json();
    }).then(function (info) {
      if (info && info.display) { remote = { w: info.display.width, h: info.display.height }; }
      var latency = new Date().getTime() - started;
      statusEl.className = '';
      statusEl.textContent = remote.w + '×' + remote.h + ' · ' + latency + ' ms'
        + (info && info.input === false ? ' · lecture seule' : '');
    }).catch(function () {
      statusEl.className = 'bad';
      statusEl.textContent = 'Mac injoignable…';
      connectStream();
    });
  }
  setInterval(refreshStatus, 5000);
  refreshStatus();

  // Empêche l'écran de la Tesla de se mettre en veille, quand l'API existe.
  if (navigator.wakeLock && navigator.wakeLock.request) {
    navigator.wakeLock.request('screen').catch(function () {});
  }

  setMode('touch');
  applyView();
  connectStream();
})();
</script>
</body>
</html>
"""#
}
