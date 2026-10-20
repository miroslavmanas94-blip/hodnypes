const SUPABASE_URL='https://krgtpruozlhygziwlwbt.supabase.co';
const SUPABASE_KEY='sb_publishable_IUbDhP7T_2m7XiAKcSg0Ng_v2F4A97e';
export async function onRequestPost({request}) {
 const origin=request.headers.get('Origin');
 if(origin && origin!==new URL(request.url).origin)return new Response('Origin not allowed',{status:403});
 let body;try{body=await request.json()}catch{return new Response('Invalid JSON',{status:400})}
 const token=typeof body.access_token==='string'?body.access_token:'';
 if(!token||token.length>8192)return new Response('Missing access token',{status:400});
 const verified=await fetch(SUPABASE_URL+'/auth/v1/user',{headers:{apikey:SUPABASE_KEY,authorization:'Bearer '+token}});
 if(!verified.ok)return new Response('Session could not be verified',{status:401});
 const user=await verified.json();
 const requested=Number(body.expires_in)||3600;
 const maxAge=Math.max(60,Math.min(3600,requested));
 return new Response(JSON.stringify({ok:true,user:{id:user.id,email:user.email}}),{headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','set-cookie':'hp_session='+encodeURIComponent(token)+'; Path=/; Max-Age='+maxAge+'; Secure; HttpOnly; SameSite=Lax'}});
}