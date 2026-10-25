import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
const URL='https://krgtpruozlhygziwlwbt.supabase.co',KEY='sb_publishable_IUbDhP7T_2m7XiAKcSg0Ng_v2F4A97e';
const db=createClient(URL,KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true,flowType:'pkce'}});
const $=s=>document.querySelector(s);
const menu=$('#menu-toggle'),links=$('#site-links');
menu?.addEventListener('click',()=>{const open=links.classList.toggle('open');menu.setAttribute('aria-expanded',String(open));menu.textContent=open?'Zavřít ×':'Menu ☰'});
const path=location.pathname==='/'?'/':location.pathname.endsWith('/')?location.pathname:location.pathname+'/';
document.querySelectorAll('.links a').forEach(a=>{if(a.getAttribute('href')===path)a.classList.add('active')});
const authTabs=[...document.querySelectorAll('[data-auth-tab]')];
if(authTabs.length){
 let mode='login';
 const nameField=$('#name-field'),passwordField=$('#password-field'),password=$('#auth-password'),submit=$('#auth-submit'),title=$('#auth-title'),message=$('#auth-message');
 function setMode(next){mode=next;authTabs.forEach(b=>b.classList.toggle('active',b.dataset.authTab===mode));nameField.hidden=mode!=='register';passwordField.hidden=mode==='reset';password.required=mode!=='reset';password.autocomplete=mode==='register'?'new-password':'current-password';submit.textContent=mode==='login'?'Přihlásit se ↗':mode==='register'?'Vytvořit účet zdarma ↗':'Poslat odkaz pro obnovu ↗';title.textContent=mode==='login'?'Vstup do svého prostoru.':mode==='register'?'Začněte svou společnou cestu.':'Obnovit přístup k účtu.';message.textContent='';}
 authTabs.forEach(b=>b.addEventListener('click',()=>setMode(b.dataset.authTab)));
 $('#auth-form').addEventListener('submit',async e=>{e.preventDefault();submit.disabled=true;message.className='notice';message.textContent='Chvilku, ověřujeme údaje…';try{const email=$('#auth-email').value.trim(),pass=password.value;let result;if(mode==='login')result=await db.auth.signInWithPassword({email,password:pass});else if(mode==='register')result=await db.auth.signUp({email,password:pass,options:{data:{full_name:$('#auth-name').value.trim()}}});else result=await db.auth.resetPasswordForEmail(email,{redirectTo:location.origin+'/ucet/'});if(result.error)throw result.error;if(mode==='login'){const session=result.data?.session;if(!session)throw new Error('Přihlášení nevrátilo aktivní relaci.');await syncServerSession(session);message.textContent='Přihlášení proběhlo. Otevíráme tvůj prostor…';location.href=safeNext();return}message.textContent=mode==='register'?'Účet byl vytvořen. Pokud je vyžadováno ověření e-mailu, zkontroluj svou schránku.':'Pokud účet existuje a odesílání e-mailů je nastavené, přijde ti odkaz pro obnovu.';message.className='notice'}catch(err){message.className='notice error';message.textContent=err.message||'Přihlášení se nepodařilo. Zkus to znovu.'}finally{submit.disabled=false}});
 $('#google-login')?.addEventListener('click',async()=>{const {error}=await db.auth.signInWithOAuth({provider:'google',options:{redirectTo:location.origin+'/ucet/?next=%2Fakademie%2F'}});if(error){message.className='notice error';message.textContent=error.message}});
}
function safeNext(){const n=new URLSearchParams(location.search).get('next')||'/akademie/';return n.startsWith('/')&&!n.startsWith('//')?n:'/akademie/'}
async function syncServerSession(session){const response=await fetch('/api/session',{method:'POST',headers:{'content-type':'application/json'},credentials:'same-origin',body:JSON.stringify({access_token:session.access_token,expires_in:session.expires_in||3600})});if(!response.ok)throw new Error('Relaci se nepodařilo bezpečně propojit se serverem ('+response.status+'). Zkus se přihlásit znovu.');return response.json()}
async function clearServerSession(){try{await fetch('/api/logout',{method:'POST',credentials:'same-origin'})}catch{}}
let authRedirectPending=false;
db.auth.onAuthStateChange((event,session)=>{
 if(session){
  queueMicrotask(async()=>{
   try{
    await syncServerSession(session);
    if(path==='/ucet/'&&!authRedirectPending){
     authRedirectPending=true;
     location.replace(safeNext());
    }
   }catch(err){console.error('Session sync failed:',err)}
  });
 }else if(event==='SIGNED_OUT')queueMicrotask(clearServerSession);
});
const {data:initialAuth}=await db.auth.getSession();
if(initialAuth.session){try{await syncServerSession(initialAuth.session);if(path==='/ucet/'){location.replace(safeNext())}}catch(err){console.error(err)}}
const ws=$('#workspace');
if(ws){
 const page=ws.dataset.page;
 const {data:{session}}=await db.auth.getSession();
 if(!session){ws.innerHTML='<div class="panel"><h2>Přihlas se do svého prostoru</h2><p class="muted">Pro zobrazení osobních dat se nejprve přihlas.</p><a class="btn" href="/ucet/">Přihlásit se ↗</a></div>'}
 else {
  const tabs=[['overview','Přehled'],['dogs','Moji psi'],['missions','Mise'],['community','Komunita'],['events','Akce'],['settings','Nastavení']];
  ws.innerHTML='<div class="panel"><div style="display:flex;justify-content:space-between;gap:15px;align-items:center;flex-wrap:wrap"><div><div class="eyebrow">TVŮJ OSOBNÍ PROSTOR</div><h2 style="margin:10px 0">Ahoj, '+escapeHtml(session.user.user_metadata?.full_name||session.user.email?.split('@')[0]||'pejskaři')+'!</h2><p class="muted">Dnes stačí jeden malý krok.</p></div><button id="logout" class="btn light">Odhlásit se</button></div><div class="tabs" style="margin-top:24px">'+tabs.map(t=>'<button type="button" data-tab="'+t[0]+'">'+t[1]+'</button>').join('')+'</div><div id="tab-content"><div class="empty-state">Vyber sekci a pokračuj vlastním tempem.</div></div></div>';
  $('#logout').addEventListener('click',async()=>{await db.auth.signOut();location.href='/'});
  const target=$('#tab-content');
  async function showTab(tab){
   ws.querySelectorAll('[data-tab]').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));
   if(tab==='overview'){target.innerHTML='<div class="grid"><article class="news-card"><span class="tag">První krok</span><h3>Profil tvého psa</h3><p>Přidej jméno a několik základních informací.</p><button class="btn light" data-tab="dogs">Spravovat psy</button></article><article class="news-card"><span class="tag">Vlastní tempo</span><h3>Tréninkový záznam</h3><p>Zapiš si, co se vám dnes povedlo.</p><button class="btn light" data-tab="missions">Otevřít mise</button></article><article class="news-card"><span class="tag">Společně</span><h3>Komunita</h3><p>Prohlédni si dostupné příspěvky.</p><button class="btn light" data-tab="community">Otevřít komunitu</button></article></div>'}
   else if(tab==='dogs'){target.innerHTML='<h3>Profily psů</h3><form id="dog-form" class="panel"><div class="field"><label for="dog-name">Jméno psa</label><input id="dog-name" required maxlength="80" placeholder="Např. Monty"></div><div class="field-row"><div class="field"><label for="dog-breed">Plemeno</label><input id="dog-breed" maxlength="100" placeholder="Plemeno (nepovinné)"></div><div class="field"><label for="dog-birth">Datum narození</label><input id="dog-birth" type="date"></div></div><div class="field"><label for="dog-bio">Něco o mém parťákovi</label><textarea id="dog-bio" maxlength="1000" placeholder="Povaha, zájmy, cíle…"></textarea></div><button class="btn">Přidat psa ↗</button><div id="dog-msg" aria-live="polite"></div></form><div id="dog-list" class="stack" style="margin-top:16px"></div>';
    const list=$('#dog-list');const {data,error}=await db.from('hp_dogs').select('id,name,breed,birth_date,bio,created_at').eq('owner_id',session.user.id).order('created_at',{ascending:false});
    if(error){list.innerHTML='<div class="notice error">Profily psů teď nelze načíst. Databázová tabulka nebo oprávnění nejsou dostupné.</div>'}else list.innerHTML=data.length?data.map(d=>'<article class="news-card"><span class="tag">Psí parťák</span><h3>'+escapeHtml(d.name)+'</h3><p>'+escapeHtml(d.breed||'Plemeno neuvedeno')+(d.birth_date?' · '+escapeHtml(d.birth_date):'')+'</p><p>'+escapeHtml(d.bio||'')+'</p></article>').join(''):'<div class="empty-state">Zatím tu není žádný pes. Přidej první profil výše.</div>';
    $('#dog-form').addEventListener('submit',async e=>{e.preventDefault();const msg=$('#dog-msg');const {error}=await db.from('hp_dogs').insert({owner_id:session.user.id,name:$('#dog-name').value.trim(),breed:$('#dog-breed').value.trim()||null,birth_date:$('#dog-birth').value||null,bio:$('#dog-bio').value.trim()||null});msg.className=error?'notice error':'notice';msg.textContent=error?'Profil se nepodařilo uložit. Zkontroluj databázové nastavení.':'Profil psa byl uložen.';if(!error)showTab('dogs')});
   }
   else if(tab==='missions'){target.innerHTML='<h3>Tréninkový deník</h3><form id="log-form" class="panel"><div class="field"><label for="log-title">Co jste dnes trénovali?</label><input id="log-title" required maxlength="140" placeholder="Např. klidné přivolání"></div><div class="field"><label for="log-notes">Co se povedlo?</label><textarea id="log-notes" maxlength="2000" placeholder="Zapiš drobný pokrok nebo co chcete zkusit příště."></textarea></div><button class="btn">Uložit záznam ↗</button><div id="log-msg" aria-live="polite"></div></form><div id="log-list" class="stack" style="margin-top:16px"></div>';
    const list=$('#log-list');const {data,error}=await db.from('hp_diary_entries').select('id,title,notes,created_at').eq('user_id',session.user.id).order('created_at',{ascending:false}).limit(20);
    if(error)list.innerHTML='<div class="notice error">Deník zatím není dostupný v databázi.</div>';else list.innerHTML=data.length?data.map(d=>'<article class="news-card"><span class="tag">'+new Date(d.created_at).toLocaleDateString('cs-CZ')+'</span><h3>'+escapeHtml(d.title)+'</h3><p>'+escapeHtml(d.notes||'')+'</p></article>').join(''):'<div class="empty-state">Ještě žádné záznamy. Zapiš si první malý pokrok.</div>';
    $('#log-form').addEventListener('submit',async e=>{e.preventDefault();const {error}=await db.from('hp_diary_entries').insert({user_id:session.user.id,title:$('#log-title').value.trim(),notes:$('#log-notes').value.trim()||null});const m=$('#log-msg');m.className=error?'notice error':'notice';m.textContent=error?'Záznam se nepodařilo uložit.':'Záznam uložen.';if(!error)showTab('missions')});
   }
   else if(tab==='community'){target.innerHTML='<h3>Komunitní příspěvky</h3><form id="post-form" class="panel"><div class="field"><label for="post-text">Co bys chtěl/a sdílet?</label><textarea id="post-text" maxlength="3000" required placeholder="Otázka, zkušenost nebo malý úspěch…"></textarea></div><button class="btn">Publikovat příspěvek ↗</button><div id="post-msg" aria-live="polite"></div></form><div id="post-list" class="stack" style="margin-top:16px"></div>';
    const list=$('#post-list');const {data,error}=await db.from('hp_posts').select('id,body,created_at,user_id').order('created_at',{ascending:false}).limit(30);
    if(error)list.innerHTML='<div class="notice error">Komunitní příspěvky nejsou dostupné.</div>';else list.innerHTML=data.length?data.map(d=>'<article class="news-card"><span class="tag">'+new Date(d.created_at).toLocaleDateString('cs-CZ')+'</span><p>'+escapeHtml(d.body)+'</p></article>').join(''):'<div class="empty-state">Komunita zatím čeká na první příspěvek.</div>';
    $('#post-form').addEventListener('submit',async e=>{e.preventDefault();const {error}=await db.from('hp_posts').insert({user_id:session.user.id,body:$('#post-text').value.trim(),visibility:'public'});const m=$('#post-msg');m.className=error?'notice error':'notice';m.textContent=error?'Příspěvek se nepodařilo uložit.':'Příspěvek byl publikován.';if(!error)showTab('community')});
   }
   else if(tab==='events'){const {data,error}=await db.from('hp_events').select('id,title,description,starts_at,capacity').eq('status','published').order('starts_at',{ascending:true}).limit(50);target.innerHTML=error?'<div class="notice error">Akce nyní nelze načíst.</div>':data.length?data.map(d=>'<article class="news-card"><span class="tag">'+(d.starts_at?new Date(d.starts_at).toLocaleString('cs-CZ'):'Termín bude upřesněn')+'</span><h3>'+escapeHtml(d.title)+'</h3><p>'+escapeHtml(d.description||'')+'</p></article>').join(''):'<div class="empty-state">Zatím nejsou zveřejněné žádné akce.</div>'}
   else if(tab==='settings'){target.innerHTML='<h3>Nastavení účtu</h3><div class="panel"><p><strong>E-mail</strong><br>'+escapeHtml(session.user.email||'')+'</p><p class="muted">Správa úplného smazání účtu vyžaduje bezpečný serverový postup a není zde zatím aktivní. Pro žádost použij oficiální kontakt.</p><a class="btn light" href="/kontakt/">Kontaktovat podporu</a></div>'}
  }
  ws.addEventListener('click',e=>{const b=e.target.closest('[data-tab]');if(b&&b.dataset.tab)showTab(b.dataset.tab)});
  ws.querySelector('[data-tab="overview"]').classList.add('active');showTab(page==='profile'?'dogs':page==='missions'?'missions':page==='community'?'community':page==='admin'?'settings':'overview');
 }
}
function escapeHtml(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
