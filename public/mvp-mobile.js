(function(){
  var btn=document.querySelector('[data-mvp-menu-btn]');
  var panel=document.querySelector('[data-mvp-menu]');
  if(!btn||!panel) return;
  btn.addEventListener('click', ()=> panel.classList.toggle('open'));
})();
