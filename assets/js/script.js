/* ==========================================================
   TURBINA — Interações
   Depende do HTML descrito no chat (menu-toggle, mobile-panel,
   back-to-top, vignette, terminal-body com data-lines opcional)
   ========================================================== */

(() => {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const hasFinePointer = window.matchMedia('(pointer: fine)').matches;

  /* ---------- Navbar retrátil ---------- */
  const nav = document.querySelector('nav.top');
  if (nav) {
    let ticking = false;
    const updateNav = () => {
      nav.classList.toggle('is-scrolled', window.scrollY > 40);
      ticking = false;
    };
    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(updateNav);
        ticking = true;
      }
    }, { passive: true });
    updateNav();
  }

  /* ---------- Menu mobile ---------- */
  const menuToggle = document.querySelector('.menu-toggle');
  const mobilePanel = document.querySelector('.mobile-panel');
  if (menuToggle && mobilePanel) {
    const closeMenu = () => {
      menuToggle.setAttribute('aria-expanded', 'false');
      mobilePanel.classList.remove('is-open');
      document.body.classList.remove('menu-open');
    };
    const openMenu = () => {
      menuToggle.setAttribute('aria-expanded', 'true');
      mobilePanel.classList.add('is-open');
      document.body.classList.add('menu-open');
    };
    menuToggle.addEventListener('click', () => {
      const isOpen = menuToggle.getAttribute('aria-expanded') === 'true';
      isOpen ? closeMenu() : openMenu();
    });
    mobilePanel.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', closeMenu);
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') closeMenu();
    });
    // fecha o menu se a viewport crescer além do breakpoint mobile
    window.addEventListener('resize', () => {
      if (window.innerWidth > 980) closeMenu();
    });
  }

  /* ---------- Parallax das orbs (mouse) ---------- */
  const bgScene = document.querySelector('.bg-scene');
  if (bgScene && hasFinePointer && !reduceMotion) {
    let rafId = null;
    window.addEventListener('mousemove', (e) => {
      if (rafId) return;
      rafId = requestAnimationFrame(() => {
        const px = (e.clientX / window.innerWidth - 0.5) * 40; // amplitude limitada
        const py = (e.clientY / window.innerHeight - 0.5) * 40;
        bgScene.style.setProperty('--px', `${px}px`);
        bgScene.style.setProperty('--py', `${py}px`);
        rafId = null;
      });
    }, { passive: true });
  }

  /* ---------- Botão voltar ao topo ---------- */
  const backToTop = document.querySelector('.back-to-top');
  if (backToTop) {
    const toggleVisibility = () => {
      backToTop.classList.toggle('is-visible', window.scrollY > window.innerHeight * 0.6);
    };
    window.addEventListener('scroll', toggleVisibility, { passive: true });
    toggleVisibility();
    backToTop.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
    });
  }

  /* ---------- Terminal: digitação real (dispara uma vez, ao entrar em viewport) ---------- */
  const terminalBody = document.querySelector('.terminal-body');
  if (terminalBody) {
    const defaultLines = [
      { prompt: '$ ', text: 'turbina install --target=all', cls: '' },
      { prompt: '', text: 'Resolvendo dependências...', cls: 'muted-l' },
      { prompt: '', text: 'Pronto em 1.8s ✓', cls: '' },
    ];
    let lines = defaultLines;
    if (terminalBody.dataset.lines) {
      try { lines = JSON.parse(terminalBody.dataset.lines); } catch (_) { lines = defaultLines; }
    }

    const renderStatic = () => {
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

    const typeLines = () => {
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

    if (reduceMotion) {
      renderStatic();
    } else {
      let played = false;
      const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !played) {
            played = true;
            typeLines();
            observer.disconnect();
          }
        });
      }, { threshold: 0.4 });
      observer.observe(terminalBody);
    }
  }

  /* ---------- Tilt 3D nos cards de sistema ---------- */
  const tiltCards = document.querySelectorAll('[data-tilt]');
  if (!reduceMotion && tiltCards.length) {
    tiltCards.forEach((card) => {
      let bounds;
      let rafId = null;
      let pendingEvent = null;

      const applyTilt = () => {
        const e = pendingEvent;
        rafId = null;
        if (!e) return;
        const leftX = e.clientX - bounds.x;
        const topY = e.clientY - bounds.y;
        const center = { x: leftX - bounds.width / 2, y: topY - bounds.height / 2 };
        card.style.transform = `
          perspective(900px)
          rotateX(${(-center.y / bounds.height) * 10}deg)
          rotateY(${(center.x / bounds.width) * 12}deg)
          scale3d(1.015, 1.015, 1.015)
        `;
        card.style.setProperty('--mx', `${(leftX / bounds.width) * 100}%`);
        card.style.setProperty('--my', `${(topY / bounds.height) * 100}%`);
      };

      const rotateToMouse = (e) => {
        pendingEvent = e;
        if (!rafId) rafId = requestAnimationFrame(applyTilt);
      };

      card.addEventListener('mouseenter', () => {
        bounds = card.getBoundingClientRect();
        card.style.transition = 'none';
      });
      card.addEventListener('mousemove', rotateToMouse);
      card.addEventListener('mouseleave', () => {
        if (rafId) cancelAnimationFrame(rafId);
        rafId = null;
        pendingEvent = null;
        card.style.transition = 'transform 0.5s cubic-bezier(.2,.8,.2,1)';
        card.style.transform = 'perspective(900px) rotateX(0deg) rotateY(0deg) scale3d(1,1,1)';
      });
    });
  }

  /* ---------- Reveal suave das seções ao rolar
     (classe CSS, não transform inline — não colide com o tilt) ---------- */
  const revealTargets = document.querySelectorAll('.step-card, .os-card, .terminal-window, .faq-item');
  if (!reduceMotion && revealTargets.length) {
    const revealIo = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-revealed');
            revealIo.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12 }
    );
    revealTargets.forEach((el) => {
      el.classList.add('reveal-pending');
      revealIo.observe(el);
    });
  }

  /* ---------- Detecção de sistema operacional (recomendação, não bloqueio) ---------- */
  const detectOS = () => {
    const ua = (navigator.userAgent || '').toLowerCase();
    const platform = ((navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || '').toLowerCase();
    const combined = `${platform} ${ua}`;

    // celular/tablet: não faz sentido recomendar um instalador de desktop
    if (/android|iphone|ipad|ipod|mobile/.test(combined)) return null;

    if (combined.includes('mac')) return 'mac';
    if (combined.includes('win')) return 'win';
    if (combined.includes('linux') || combined.includes('x11') || combined.includes('ubuntu')) return 'linux';
    return null;
  };

  const detectedOS = detectOS();

  const lockCard = (card) => {
    card.classList.add('is-locked');
    const btn = card.querySelector('.os-download');
    if (!btn) return;
    btn.setAttribute('aria-disabled', 'true');
    btn.textContent = 'Indisponível para o seu sistema';
    btn.addEventListener('click', (e) => {
      e.preventDefault();
    });
  };

  if (detectedOS) {
    const detectedCard = document.querySelector(`.os-${detectedOS}`);
    if (detectedCard) {
      detectedCard.classList.add('is-detected');
      const badge = document.createElement('span');
      badge.className = 'os-detected-badge';
      badge.textContent = 'Recomendado pra você';
      detectedCard.prepend(badge);
    }
    ['win', 'mac', 'linux']
      .filter((os) => os !== detectedOS)
      .forEach((os) => {
        const card = document.querySelector(`.os-${os}`);
        if (card) lockCard(card);
      });
  }

  /* ---------- Toast de download por sistema operacional ----------
     Dispara UMA única vez por visita: no primeiro que acontecer entre
     45s de permanência na página OU o mouse saindo pelo topo da janela
     (exit-intent). Depois que a pessoa clicar em baixar ou fechar o
     toast, ele não aparece mais nessa nem em visitas futuras
     (guardado em localStorage). Também não dispara se a aba estiver
     em segundo plano no momento do gatilho. */
  if (detectedOS) {
    const STORAGE_KEY = 'turbina-toast-dismissed';
    const labels = { win: 'Windows', mac: 'macOS', linux: 'Linux' };
    const targetCard = document.querySelector(`.os-${detectedOS}`);
    const targetBtn = targetCard ? targetCard.querySelector('.os-download') : null;

    let alreadyHandled = localStorage.getItem(STORAGE_KEY) === '1';
    let toastEl = null;
    let toastTimer = null;

    const persistDismissed = () => {
      alreadyHandled = true;
      try { localStorage.setItem(STORAGE_KEY, '1'); } catch (_) { /* localStorage indisponível: ok ignorar */ }
    };

    const hideToast = () => {
      if (toastEl) toastEl.classList.remove('is-visible');
      if (toastTimer) clearTimeout(toastTimer);
    };

    const buildToast = () => {
      const toast = document.createElement('div');
      toast.className = 'os-toast';
      toast.setAttribute('role', 'status');
      toast.innerHTML = `
        <span class="os-toast-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 3v12"></path>
            <path d="m7 10 5 5 5-5"></path>
            <path d="M5 21h14"></path>
          </svg>
        </span>
        <span class="os-toast-body">
          <p>Detectamos que você está no <strong>${labels[detectedOS]}</strong>. Que tal baixar o Turbina para o seu sistema?</p>
          <a class="os-toast-link" href="#${detectedOS}">Baixar para ${labels[detectedOS]}</a>
        </span>
        <button type="button" class="os-toast-close" aria-label="Fechar aviso">&times;</button>
      `;
      document.body.appendChild(toast);

      toast.querySelector('.os-toast-link').addEventListener('click', () => {
        persistDismissed();
        hideToast();
      });
      toast.querySelector('.os-toast-close').addEventListener('click', () => {
        persistDismissed();
        hideToast();
      });

      return toast;
    };

    const showToastOnce = () => {
      if (alreadyHandled) return;
      if (document.hidden) return; // não mostra com a aba em segundo plano

      // se a pessoa já clicou em baixar diretamente no card, não precisa do toast
      alreadyHandled = true;

      if (!toastEl) toastEl = buildToast();
      requestAnimationFrame(() => toastEl.classList.add('is-visible'));

      // some sozinho depois de um tempo, mas continua "usado" (não repete)
      toastTimer = setTimeout(() => toastEl.classList.remove('is-visible'), 9000);
    };

    // gatilho 1: clicar em baixar diretamente cancela a necessidade do toast
    if (targetBtn) {
      targetBtn.addEventListener('click', () => {
        persistDismissed();
        hideToast();
      });
    }

    // gatilho 2: permanência de 45s na página
    let stayTimer = null;
    if (!alreadyHandled) {
      stayTimer = setTimeout(showToastOnce, 45000);
    }

    // gatilho 3: exit-intent (mouse saindo pela borda superior da janela)
    const onExitIntent = (e) => {
      if (alreadyHandled) {
        document.removeEventListener('mouseout', onExitIntent);
        return;
      }
      if (e.clientY <= 0) {
        if (stayTimer) clearTimeout(stayTimer);
        showToastOnce();
        document.removeEventListener('mouseout', onExitIntent);
      }
    };
    if (!alreadyHandled && hasFinePointer) {
      document.addEventListener('mouseout', onExitIntent);
    }
  }
})();
