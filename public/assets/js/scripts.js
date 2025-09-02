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