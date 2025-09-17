// Add your JavaScript code here for interactivity, animations, or form handling.

document.addEventListener('DOMContentLoaded', function() {
  var ctaButtons = document.querySelectorAll('.btn-primary, .cta-button a');
  ctaButtons.forEach(function(btn) {
    btn.addEventListener('click', function() {
      // Example: Track CTA clicks or show a message
      console.log('CTA button clicked!');
    });
  });
});
// ...existing code...

// Hero rotation for .parallax-hero
document.addEventListener('DOMContentLoaded', function () {
  const slides = document.querySelectorAll('.parallax-hero .slide');
  let current = 0;
  if (slides.length > 1) {
    slides[0].classList.add('active');
    setInterval(() => {
      slides[current].classList.remove('active');
      current = (current + 1) % slides.length;
      slides[current].classList.add('active');
    }, 4000); // 4 seconds per slide
  }
});
// ...existing code...

// Mobile menu toggle
document.addEventListener('DOMContentLoaded', function () {
  const menuBtn = document.querySelector('[data-mobile-menu-btn]');
  const mobileMenu = document.querySelector('[data-mobile-menu]');
  const body = document.body;

  if (menuBtn && mobileMenu) {
    menuBtn.addEventListener('click', function () {
      mobileMenu.classList.toggle('open');
      body.classList.toggle('menu-open');
    });
  }
});