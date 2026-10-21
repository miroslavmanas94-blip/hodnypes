const CACHE_NAME='hodnypes-static-v1';
const STATIC_ASSETS=['/assets/site.css','/assets/site.js','/manifest.webmanifest','/assets/icon.svg'];
self.addEventListener('install',event=>{
 event.waitUntil((async()=>{const cache=await caches.open(CACHE_NAME);await Promise.allSettled(STATIC_ASSETS.map(async url=>{const response=await fetch(url,{cache:'no-cache'});if(response.ok)await cache.put(url,response)}));await self.skipWaiting()})());
});
self.addEventListener('activate',event=>{
 event.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(key=>key.startsWith('hodnypes-static-')&&key!==CACHE_NAME).map(key=>caches.delete(key)));await self.clients.claim()})());
});
self.addEventListener('fetch',event=>{
 const request=event.request;
 if(request.method!=='GET')return;
 const url=new URL(request.url);
 if(url.origin!==self.location.origin||!STATIC_ASSETS.includes(url.pathname))return;
 event.respondWith((async()=>{const cache=await caches.open(CACHE_NAME);try{const response=await fetch(request);if(response.ok)await cache.put(request,response.clone());return response}catch{const cached=await cache.match(request);if(cached)return cached;return new Response('Tento soubor není dostupný offline.',{status:503,headers:{'content-type':'text/plain; charset=utf-8'}})}})());
});