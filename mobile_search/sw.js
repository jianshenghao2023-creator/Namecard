const VERSION = new URL(self.location.href).searchParams.get('v') || 'dev';
const CACHE_NAME = `namecard-query-${VERSION}`;
const ASSETS = [
  './',
  './index.html',
  './styles.css',
  './app-online-sync-v2.js',
  './contacts-data.json',
  './manifest.webmanifest',
  './icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await Promise.all(ASSETS.map(async (asset) => {
      const response = await fetch(new Request(asset, { cache: 'reload' }));
      await cache.put(asset, response);
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys
      .filter((key) => key.startsWith('namecard-query-') && key !== CACHE_NAME)
      .map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) {
    return;
  }
  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirst(event.request, './index.html'));
    return;
  }
  event.respondWith(networkFirst(event.request));
});

async function networkFirst(request, fallback) {
  try {
    const response = await fetch(request);
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, response.clone());
    return response;
  } catch (error) {
    const cached = await caches.match(request, { ignoreSearch: true });
    return cached || (fallback ? caches.match(fallback) : undefined);
  }
}
