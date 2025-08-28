(function(){
  const hero = document.getElementById('hero-index');
  if(!hero) return;

  const slides = Array.from(hero.querySelectorAll('.slide'));
  const prevBtn = hero.querySelector('.prev');
  const nextBtn = hero.querySelector('.next');

  let idx = 0, timer = null, dur = 5000;

  function show(i){
    slides.forEach((s,k)=> s.classList.toggle('active', k===i));
    idx = i;
  }
  function next(){ show((idx+1)%slides.length); }
  function prev(){ show((idx-1+slides.length)%slides.length); }

  function start(){ stop(); timer = setInterval(next, dur); }
  function stop(){ if(timer) clearInterval(timer); }

  nextBtn?.addEventListener('click', ()=>{ next(); start(); });
  prevBtn?.addEventListener('click', ()=>{ prev(); start(); });

  hero.addEventListener('mouseenter', stop);
  hero.addEventListener('mouseleave', start);

  // simple parallax on scroll
  window.addEventListener('scroll', ()=>{
    const r = hero.getBoundingClientRect();
    const y = Math.max(-120, Math.min(120, -r.top*0.15));
    slides.forEach(s => s.style.transform = `translateY(${y}px)`);
  });

  show(0);
  start();
})();
