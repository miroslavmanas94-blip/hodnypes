import { readFileSync, existsSync } from 'node:fs';
import vm from 'node:vm';
const requiredFiles=['functions/_middleware.js','functions/api/session.js','functions/api/logout.js','assets/site.js','assets/platform.js','assets/site.css','index.html','manifest.webmanifest','supabase/migrations/20261022180000_add_private_dog_media_storage.sql','supabase/migrations/20261022190000_platform_core.sql','supabase/migrations/20261022203000_realtime_events_reactions.sql','supabase/migrations/20261022204000_event_capacity_waitlist.sql','supabase/migrations/20261022205000_lock_waitlist_function_execution.sql','supabase/migrations/20261022210000_event_roles_and_permissions.sql','supabase/migrations/20261022211000_manual_point_awards.sql','supabase/migrations/20261022212000_admin_course_read.sql','supabase/migrations/20261022213000_public_member_profiles.sql','supabase/migrations/20261022202000_direct_messages.sql','supabase/migrations/20261022201000_admin_review_access.sql','supabase/migrations/20261022200000_admin_publishing_policies.sql'];
const missing=requiredFiles.filter(f=>!existsSync(f));if(missing.length){console.error('Missing required files:',missing.join(', '));process.exit(1)}
const read=f=>readFileSync(f,'utf8');
const middleware=read('functions/_middleware.js').replace('export async function onRequest','async function onRequest');
const browser=read('assets/site.js').split('\n').slice(1).join('\n');
const platform=read('assets/platform.js').replace(/^import .*?;\s*/s,'');
for(const [name,src] of [['middleware',middleware],['browser JavaScript',browser],['platform JavaScript',platform]]){try{new vm.Script(name==='browser JavaScript'?'(async()=>{'+String.fromCharCode(10)+src+String.fromCharCode(10)+'})()':src,{filename:name});console.log('✓ Syntax:',name)}catch(e){console.error('✗ Syntax:',name,e.message);process.exitCode=1}}
const manifest=JSON.parse(read('manifest.webmanifest'));if(manifest.lang!=='cs'||!manifest.start_url||!manifest.icons?.length){console.error('Invalid web app manifest');process.exitCode=1}
const mw=read('functions/_middleware.js'),site=read('assets/site.js'),html=read('index.html'),core=read('supabase/migrations/20261022190000_platform_core.sql'),storage=read('supabase/migrations/20261022180000_add_private_dog_media_storage.sql');
for(const route of ['/','/ucet/','/o-nas/','/vycvik/','/akce/','/kontakt/','/akademie/','/profil/','/mise/','/lekce/','/komunita/','/zpravy/','/plemena/','/administrace/','/rezervace/','/pravidla/','/soukromi/'])if(!mw.includes("'"+route+"':{")){console.error('Missing route:',route);process.exitCode=1}
if(/maps\.google\.com|google\.com\/maps|navigator\.geolocation|getCurrentPosition|watchPosition/.test(mw+site+platform)){console.error('Location sharing/map code is forbidden');process.exitCode=1}
if(!storage.includes('storage.objects')||!storage.includes('auth.uid()')||!storage.includes('public = false')){console.error('Private media storage policy missing');process.exitCode=1}
for(const table of ['hp_posts','hp_comments','hp_reactions','hp_follows','hp_groups','hp_events','hp_missions','hp_training_entries','hp_courses','hp_articles','hp_notifications','hp_user_preferences','hp_reports'])if(!core.includes('public.'+table)){console.error('Missing schema table:',table);process.exitCode=1}
if(!site.includes('signInWithPassword')||!site.includes('signInWithOAuth')||!site.includes('resetPasswordForEmail')){console.error('Authentication flows missing');process.exitCode=1}
if(!mw.includes('src="/assets/platform.js"')||!mw.includes('id="workspace"')||!mw.includes('data-page=')){console.error('Member platform needs its workspace mount point and page context');process.exitCode=1}
if(!site.includes("async function syncServerSession(session)")||!site.includes("fetch('/api/session'")||!site.includes("fetch('/api/logout'")){console.error('Browser and server auth sessions are not synchronized');process.exitCode=1}
if(!site.includes('let authRedirectPending=false')||!site.includes("location.replace(safeNext())")){console.error('OAuth callback must wait for server session sync and return to the requested page');process.exitCode=1}
const sessionApi=read('functions/api/session.js'),logoutApi=read('functions/api/logout.js');
if(!sessionApi.includes("set-cookie")||!sessionApi.includes("/auth/v1/user")||!logoutApi.includes("Max-Age=0")){console.error('Secure session cookie endpoints are incomplete');process.exitCode=1}
const platformSource=read('assets/platform.js');
if(!platformSource.includes("from('hp_courses').select('id,title,summary,category,difficulty,language,is_paid')")||!platformSource.includes("from('dog_profiles')")){console.error('Member features are not aligned with required data tables');process.exitCode=1}

if(!html.includes('/assets/site.css')||!html.includes('/assets/site.js')){console.error('Static fallback missing site assets');process.exitCode=1}
if(process.exitCode)process.exit(process.exitCode);console.log('✓ Routes, authentication, privacy and database checks passed');
