// TURBINA — interações leves: tilt 3D nos cards de sistema
(function () {
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const cards = document.querySelectorAll('[data-tilt]');

  if (prefersReduced) return;

  cards.forEach((card) => {
    let bounds;

    const rotateToMouse = (e) => {
      const mouseX = e.clientX;
      const mouseY = e.clientY;
      const leftX = mouseX - bounds.x;
      const topY = mouseY - bounds.y;
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

    card.addEventListener('mouseenter', () => {
      bounds = card.getBoundingClientRect();
      card.style.transition = 'none';
    });

    card.addEventListener('mousemove', rotateToMouse);

    card.addEventListener('mouseleave', () => {
      card.style.transition = 'transform 0.5s cubic-bezier(.2,.8,.2,1)';
      card.style.transform = 'perspective(900px) rotateX(0deg) rotateY(0deg) scale3d(1,1,1)';
    });
  });

  // Reveal suave das seções ao rolar a página
  const revealTargets = document.querySelectorAll('.step-card, .os-card, .terminal-window, .faq-item');
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.style.opacity = '1';
          entry.target.style.transform = entry.target.style.transform.replace('translateY(24px)', 'translateY(0)');
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.12 }
  );

  revealTargets.forEach((el) => {
    el.style.opacity = '0';
    el.style.transform = (el.style.transform || '') + ' translateY(24px)';
    el.style.transition = 'opacity 0.7s ease, transform 0.7s cubic-bezier(.2,.8,.2,1)';
    io.observe(el);
  });
})();
