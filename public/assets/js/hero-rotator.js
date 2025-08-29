document.addEventListener('DOMContentLoaded', () => {
  const hero = document.querySelector('#hero-index');
  if (!hero) return;
  const slides = [...hero.querySelectorAll('.slide')];
  if (!slides.length) return;
  let i = 0;
  slides[i].classList.add('active');
  setInterval(() => {
    slides[i].classList.remove('active');
    i = (i + 1) % slides.length;
    slides[i].classList.add('active');
  }, 6000);
  window.addEventListener('scroll', () => {
    const y = window.scrollY * 0.25;
    slides.forEach(s => s.style.transform = `translateY(${y}px)`);
  }, { passive: true });
});
