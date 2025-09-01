document.addEventListener('DOMContentLoaded', () => {
  const root = document.querySelector('[data-hero="rotation"] .slides');
  if (!root) return;
  const slides = Array.from(root.children);
  let i = 0;
  const show = n => slides.forEach((s, idx) => s.classList.toggle('active', idx === n));
  show(0);
  setInterval(() => { i = (i + 1) % slides.length; show(i); }, 4000);
});
