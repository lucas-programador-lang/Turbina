/* ==========================================================
   TURBINA — Tutorial com abas (Windows / macOS / Linux)
   Marca cada .terminal-body tratado com data-typed="1" para
   não colidir com o observer genérico do script.js.
   ========================================================== */

(() => {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const tabs = document.querySelectorAll('.tutorial-tab');
  const panels = document.querySelectorAll('.terminal-panel');
  if (!tabs.length || !panels.length) return;

  const played = new Set(); // controla quais painéis já digitaram

  const typeLines = (terminalBody) => {
    let lines;
    try { lines = JSON.parse(terminalBody.dataset.lines); } catch (_) { return; }

    terminalBody.dataset.typed = '1';
    terminalBody.innerHTML = '';
    let lineIndex = 0;

    const typeLine = () => {
      if (lineIndex >= lines.length) {
        const cursor = document.createElement('span');
        cursor.className = 'cursor';
        terminalBody.appendChild(cursor);
        return;
      }
      const { prompt, text, cls } = lines[lineIndex];
      const lineEl = document.createElement('div');
      if (prompt) {
        const promptEl = document.createElement('span');
        promptEl.className = 'prompt';
        promptEl.textContent = prompt;
        lineEl.appendChild(promptEl);
      }
      const textEl = document.createElement('span');
      if (cls) textEl.className = cls;
      lineEl.appendChild(textEl);
      terminalBody.appendChild(lineEl);

      let charIndex = 0;
      const typeChar = () => {
        if (charIndex < text.length) {
          textEl.textContent += text[charIndex];
          charIndex += 1;
          setTimeout(typeChar, 22 + Math.random() * 28);
        } else {
          lineIndex += 1;
          setTimeout(typeLine, 260);
        }
      };
      typeChar();
    };
    typeLine();
  };

  const renderStatic = (terminalBody) => {
    let lines;
    try { lines = JSON.parse(terminalBody.dataset.lines); } catch (_) { return; }
    terminalBody.dataset.typed = '1';
    terminalBody.innerHTML = '';
    lines.forEach(({ prompt, text, cls }) => {
      const lineEl = document.createElement('div');
      if (prompt) {
        const p = document.createElement('span');
        p.className = 'prompt';
        p.textContent = prompt;
        lineEl.appendChild(p);
      }
      const t = document.createElement('span');
      if (cls) t.className = cls;
      t.textContent = text;
      lineEl.appendChild(t);
      terminalBody.appendChild(lineEl);
    });
  };

  const activatePanel = (os) => {
    tabs.forEach((tab) => {
      const isActive = tab.dataset.os === os;
      tab.classList.toggle('is-active', isActive);
      tab.setAttribute('aria-selected', String(isActive));
    });
    panels.forEach((panel) => {
      const isActive = panel.dataset.osPanel === os;
      panel.hidden = !isActive;
      panel.classList.toggle('is-active', isActive);
      if (isActive && !played.has(os)) {
        played.add(os);
        const body = panel.querySelector('.terminal-body');
        if (body) reduceMotion ? renderStatic(body) : typeLines(body);
      }
    });
  };

  tabs.forEach((tab) => {
    tab.addEventListener('click', () => activatePanel(tab.dataset.os));
  });

  // digita o painel inicial (Windows) assim que ele entra na viewport
  const initialPanel = document.querySelector('.terminal-panel.is-active');
  if (initialPanel) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          activatePanel(initialPanel.dataset.osPanel);
          observer.disconnect();
        }
      });
    }, { threshold: 0.4 });
    observer.observe(initialPanel);
  }

  /* ---------- Bloqueio de cópia nos terminais ilustrativos ---------- */
  document.querySelectorAll('.no-copy').forEach((el) => {
    ['copy', 'cut', 'contextmenu', 'selectstart', 'dragstart'].forEach((evt) => {
      el.addEventListener(evt, (e) => e.preventDefault());
    });
  });

  document.addEventListener('keydown', (e) => {
    const insideTerminal = e.target.closest && e.target.closest('.no-copy');
    if (!insideTerminal) return;
    const key = e.key.toLowerCase();
    if ((e.ctrlKey || e.metaKey) && (key === 'c' || key === 'a' || key === 'x')) {
      e.preventDefault();
    }
  });
})();
