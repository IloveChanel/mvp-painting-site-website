(() => {
  // find the slides container by id or data-attribute
  const slidesRoot =
    document.querySelector('#hero-index .slides') ||
    document.querySelector('[data-hero="rotation"] .slides');

  if (!slidesRoot) return;

  const slides = Array.from(slidesRoot.children);
  if (!slides.length) return;

  let i = 0;
  const show = n => {
    slides.forEach((s, idx) => s.classList.toggle('active', idx === n));
  };

  show(0);                      // show first
  const INTERVAL_MS = 5000;     // change speed here (5000 = 5s)
  setInterval(() => {
    i = (i + 1) % slides.length;
    show(i);
  }, INTERVAL_MS);
})();
