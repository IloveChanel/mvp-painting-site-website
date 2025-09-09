// /assets/js/hero-rotator.js
(() => {
  function initHeroRotation(section, intervalMs = 5000) {
    const slidesWrap = section.querySelector('.slides');
    if (!slidesWrap) return;
    const slides = Array.from(slidesWrap.querySelectorAll('.slide'));
    if (!slides.length) return;

    // Ensure one slide is visible on load
    let idx = slides.findIndex(s => s.classList.contains('active'));
    if (idx === -1) { idx = 0; slides[0].classList.add('active'); }

    let timerId = null;
    const next = () => {
      slides[idx].classList.remove('active');
      idx = (idx + 1) % slides.length;
      slides[idx].classList.add('active');
    };

    const start = () => { if (!timerId) timerId = setInterval(next, intervalMs); };
    const stop  = () => { if (timerId) { clearInterval(timerId); timerId = null; } };

    start();
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) stop(); else start();
    });
  }

  window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-hero="rotation"]').forEach(section => {
      const speedAttr = section.getAttribute('data-speed');
      const speed = Number.parseInt(speedAttr, 10);
      initHeroRotation(section, Number.isFinite(speed) ? speed : 5000);
    });
  });
})();
