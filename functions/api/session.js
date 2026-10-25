const SUPABASE_URL='https://krgtpruozlhygziwlwbt.supabase.co';
const SUPABASE_KEY='sb_publishable_IUbDhP7T_2m7XiAKcSg0Ng_v2F4A97e';
export async function onRequestPost({request}) {
 const origin=request.headers.get('Origin');
 if(origin && origin!==new URL(request.url).origin)return new Response('Origin not allowed',{status:403});
 let body;try{body=await request.json()}catch{return new Response('Invalid JSON',{status:400})}
 const token=typeof body.access_token==='string'?body.access_token:'';
 if(!token||token.length>8192)return new Response('Missing access token',{status:400});
 const verified=await fetch(SUPABASE_URL+'/auth/v1/user',{headers:{apikey:SUPABASE_KEY,authorization:'Bearer '+token}});
 if(!verified.ok)return new Response('Session could not be verified',{status:401,headers:{'cache-control':'no-store'}});
 const user=await verified.json();
 // Never trust a client-supplied lifetime. Use the signed access token's exp claim
 // and keep the HttpOnly cookie no longer than the access token itself.
 let exp=0;
 try {
  const payload=token.split('.')[1];
  if(!payload)throw new Error('Malformed token');
  const decoded=atob(payload.replace(/-/g,'+').replace(/_/g,'/'));
  exp=Number(JSON.parse(decoded).exp)||0;
 } catch {return new Response('Invalid access token',{status:401,headers:{'cache-control':'no-store'}})}
 const maxAge=Math.min(3600,exp-Math.floor(Date.now()/1000));
 if(maxAge<1)return new Response('Expired access token',{status:401,headers:{'cache-control':'no-store'}});
 return new Response(JSON.stringify({ok:true,user:{id:user.id,email:user.email},expires_in:maxAge}),{headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','set-cookie':'hp_session='+encodeURIComponent(token)+'; Path=/; Max-Age='+maxAge+'; Secure; HttpOnly; SameSite=Lax'}});
}