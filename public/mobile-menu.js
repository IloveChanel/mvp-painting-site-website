(function(){
  var btn=document.querySelector('[data-mobile-menu-btn]');
  var panel=document.querySelector('[data-mobile-menu]');
  if(!btn||!panel)return; btn.addEventListener('click',()=>panel.classList.toggle('open'));
})();
