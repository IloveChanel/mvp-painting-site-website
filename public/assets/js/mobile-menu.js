// mobile-menu.js — toggles the mobile drawer
(function () {
  const btn = document.querySelector('[data-mobile-menu-btn]');
  const drawer = document.querySelector('[data-mobile-menu]');
  if (!btn || !drawer || btn.dataset.mmInit === '1') return;
  btn.dataset.mmInit = '1';

  const open = () => {
    drawer.removeAttribute('hidden');
    drawer.classList.add('open');
    document.body.classList.add('menu-open');
    btn.setAttribute('aria-expanded','true');
  };
  const close = () => {
    drawer.classList.remove('open');
    drawer.setAttribute('hidden','');
    document.body.classList.remove('menu-open');
    btn.setAttribute('aria-expanded','false');
  };

  btn.addEventListener('click', () =>
    drawer.hasAttribute('hidden') ? open() : close()
  );
  drawer.addEventListener('click', e => { if (e.target.matches('a')) close(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
})();

