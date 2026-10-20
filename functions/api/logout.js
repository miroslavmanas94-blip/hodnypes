export async function onRequestPost({request}) {
 const origin=request.headers.get('Origin');
 if(origin && origin!==new URL(request.url).origin)return new Response('Origin not allowed',{status:403});
 return new Response(JSON.stringify({ok:true}),{headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store','set-cookie':'hp_session=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Lax'}});
}