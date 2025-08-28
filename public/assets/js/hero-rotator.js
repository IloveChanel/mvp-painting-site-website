document.addEventListener('DOMContentLoaded', () => {
  const hero = document.querySelector('[data-hero="rotation"]');
  if (!hero) return;

  const slides = Array.from(hero.querySelectorAll('.slide'));
  if (!slides.length) return;

  let i = 0;
  slides[0].classList.add('active');

  setInterval(() => {
    slides[i].classList.remove('active');
    i = (i + 1) % slides.length;
    slides[i].classList.add('active');
  }, 5000);
});
