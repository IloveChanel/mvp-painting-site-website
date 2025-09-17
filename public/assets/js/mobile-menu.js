// Mobile menu toggler — idempotent + desktop-resize safe
(() => {
  const btn = document.querySelector('[data-mobile-menu-btn]');
  const drawer = document.querySelector('[data-mobile-menu]');
  if (!btn || !drawer || btn.dataset.mmInit === '1') return; // avoid double-binding
  btn.dataset.mmInit = '1';

  const open = () => {
    drawer.classList.add('open');
    document.body.classList.add('menu-open');
    btn.setAttribute('aria-expanded', 'true');
  };
  const close = () => {
    drawer.classList.remove('open');
    document.body.classList.remove('menu-open');
    btn.setAttribute('aria-expanded', 'false');
  };

  // Toggle
  btn.addEventListener('click', () => {
    drawer.classList.contains('open') ? close() : open();
  });

  // Close on link click + Esc
  drawer.addEventListener('click', (e) => { if (e.target.matches('a')) close(); });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });

  // Close when switching to desktop
  const mql = window.matchMedia('(min-width: 768px)');
  const onChange = (e) => { if (e.matches) close(); };
  if (mql.addEventListener) mql.addEventListener('change', onChange);
  else mql.addListener(onChange);
})();


