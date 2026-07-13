// HocVui Flutter service worker
//
// Caches the Flutter app shell + main assets for offline support and
// faster repeat visits. Replaces the Flutter default (which just
// unregisters itself) so users get:
//
// - Offline mode: app still loads on planes / no-wifi
// - Repeat visits: zero asset re-download (cached on first visit)
// - Updates: the versioned ?v= on flutter_bootstrap.js / main.dart.js
//   triggers an automatic cache refresh — no stale code
//
// Strategy: stale-while-revalidate. Serve from cache instantly, then
// refresh in the background. The cache is keyed by the asset URL (which
// includes the ?v= timestamp), so a new deploy gets a new URL and the
// old cache entry is naturally orphaned and evicted by the size cap.

'use strict';

const CACHE_NAME = 'hocvui-app-v1';
const MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

// App shell: what we pre-cache on install so the app boots offline.
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/assets/AssetManifest.bin.json',
  '/assets/FontManifest.json',
  '/canvaskit/canvaskit.js',
  '/canvaskit/canvaskit.wasm',
  '/canvaskit/chromium/',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      // Pre-cache the app shell. Best-effort: if a single asset fails
      // (e.g. 404), skip it instead of failing the whole install.
      await Promise.all(
        PRECACHE_URLS.map(async (url) => {
          try {
            const res = await fetch(url, { cache: 'no-cache' });
            if (res.ok) await cache.put(url, res);
          } catch (_) {
            // network not available yet — that's fine
          }
        })
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // Drop any old caches from previous deploys.
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((n) => n !== CACHE_NAME)
          .map((n) => caches.delete(n))
      );
      // Take control of all open tabs immediately.
      const clients = await self.clients.matchAll({ type: 'window' });
      clients.forEach((c) => c.navigate(c.url));
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // Only handle same-origin GETs. Everything else (cross-origin, POST,
  // etc.) goes straight to the network.
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;

  // SPA fallback: any navigation to a non-asset path → serve /index.html
  // so the Flutter router takes over. This is what makes /app/pricing
  // work on hard-refresh when the user isn't on the root.
  if (req.mode === 'navigate') {
    event.respondWith(
      (async () => {
        try {
          // Try network first so updates are picked up immediately.
          const fresh = await fetch(req);
          const cache = await caches.open(CACHE_NAME);
          cache.put('/', fresh.clone());
          return fresh;
        } catch (_) {
          // Offline: serve cached /index.html
          const cached = await caches.match('/index.html');
          if (cached) return cached;
          return new Response('Offline', { status: 503 });
        }
      })()
    );
    return;
  }

  // Stale-while-revalidate for static assets.
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      const cached = await cache.match(req);
      const network = fetch(req)
        .then(async (res) => {
          if (res.ok) {
            // Evict old entries to keep cache size bounded.
            const keys = await cache.keys();
            if (keys.length > 80) {
              const toDelete = keys
                .filter((k) => Date.now() - (k.__timestamp || 0) > MAX_AGE_MS)
                .slice(0, keys.length - 80);
              await Promise.all(toDelete.map((k) => cache.delete(k)));
            }
            cache.put(req, res.clone());
          }
          return res;
        })
        .catch(() => cached); // offline → cached

      // Serve from cache immediately if present; otherwise wait for network.
      return cached || network;
    })()
  );
});
