'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".vercel/project.json": "3653fee0b3a089c3e5bed53a4e741186",
".vercel/README.txt": "2b13c79d37d6ed82a3255b83b6815034",
"404.html": "b70cc054f8dcfb3941760a53cfd27436",
"assets/AssetManifest.bin": "82f1dcab87cd24394403520334b41388",
"assets/AssetManifest.bin.json": "fdf6f71005c0c90a2ed06fcabbddfb83",
"assets/AssetManifest.json": "3b10ee663d45d7a5cc1c6bf71fa63c76",
"assets/assets/currency/gtu_coin.png": "796aa4ff7e449ca308c63deeeb21e86a",
"assets/assets/mascot/celebrating.svg": "6ca684b043a6d7f4cdbbfc422f3c52d9",
"assets/assets/mascot/happy.svg": "cbe1ca9cc59ab8d6776460dc7ab286b7",
"assets/assets/mascot/idle.svg": "fc5f95076b332fac15f9bb58bfa37059",
"assets/assets/mascot/sad.svg": "14b09ccf67f64ce67ac547d564bf3c2d",
"assets/assets/onboarding/noto/1f30d.json": "6e9d18b8717e5c8a33c8bdd36869667b",
"assets/assets/onboarding/noto/1f31f.json": "aeb9750114315e433cfe315ca9ac3e09",
"assets/assets/onboarding/noto/1f393.json": "22aa626fa8eacc866f39c90166e6d6df",
"assets/assets/onboarding/noto/1f3af.json": "4e5b0def39df0a8f07cc14dd6e1d7278",
"assets/assets/onboarding/noto/1f3c6.json": "b0ed67012e809c97bef2eb657f85db37",
"assets/assets/onboarding/noto/1f3e0.json": "a3e50a6d9214996c12814003e414b6a0",
"assets/assets/onboarding/noto/1f4a1.json": "531c7e54e7a01b07938f58421ae464d5",
"assets/assets/onboarding/noto/1f4aa.json": "b8b34511f12bd1368247f1fc4233018e",
"assets/assets/onboarding/noto/1f4ac.json": "738964ff1788abf10881c5042afd2d8f",
"assets/assets/onboarding/noto/1f4bb.json": "91e8e7cdabca89d12ad88dbb1c133cbd",
"assets/assets/onboarding/noto/1f4c8.json": "4b83976875f5b6a7079cb4a7176dc75b",
"assets/assets/onboarding/noto/1f4da.json": "1bba77e9f63c67346c9ccd5dd0080099",
"assets/assets/onboarding/noto/1f4e3.json": "42e5553649b864125a9c08deb65ae668",
"assets/assets/onboarding/noto/1f50e.json": "a8b68285a5aad22261dbde5eeac73491",
"assets/assets/onboarding/noto/1f514.json": "c69931d05d2776c3a65410e225560435",
"assets/assets/onboarding/noto/1f525.json": "6d754bc92785de68d465754a5f759425",
"assets/assets/onboarding/noto/1f634.json": "eacdfb60f2422315fdd9d31696a1e138",
"assets/assets/onboarding/noto/1f680.json": "0f5829c570a49f00b763a1ecef62f798",
"assets/assets/onboarding/noto/1f91d.json": "e510c3a31bc872fa1a723497d39062dc",
"assets/assets/onboarding/noto/1f9e0.json": "4f67adcd802879fdb6b7930204ffb8fd",
"assets/assets/onboarding/noto/23f3.json": "378206c445617c64c2a2c0f4a0042eb4",
"assets/assets/onboarding/noto/26a1.json": "a43b208de7f18fa19c7840deb64b2f75",
"assets/assets/onboarding/noto/270f.json": "75248e1d655b7966ed99290c066d9ef7",
"assets/assets/onboarding/noto/274c.json": "2c7d2063192ea06a4a7d047e8bf13b74",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "2c21755a3ed737ce1c68c715d3ec846c",
"assets/NOTICES": "f5191c370f9205e174c1df7320b5cb9a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/media_kit/assets/web/hls1.4.10.js": "bd60e2701c42b6bf2c339dcf5d495865",
"assets/packages/quill_native_bridge_linux/assets/xclip": "d37b0dbbc8341839cde83d351f96279e",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "d84726dddd10976def594a7a099ffd41",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "48bb99ae4a78f3a674d8fa3cbf661001",
"google_signin.js": "edb2ff386563d9dace2887536621a2cd",
"icons/Icon-192.png": "13f0d5047374973994e19a1b5bcda4ab",
"icons/Icon-512.png": "5ee52801d2a6da4564b0a034dfdd3ad8",
"icons/Icon-maskable-192.png": "13f0d5047374973994e19a1b5bcda4ab",
"icons/Icon-maskable-512.png": "5ee52801d2a6da4564b0a034dfdd3ad8",
"index.html": "1269b405a268a8d4c2800299c956c251",
"/": "1269b405a268a8d4c2800299c956c251",
"main.dart.js": "dd62a0a0801c6a6c0f47b7dc9692ebd8",
"manifest.json": "e610a2844abc5d278321007727b59e83",
"reset-password.html": "d336452ff4f0d891d492a2bcb65a807b",
"version.json": "9bf98a70eefd11bf8f0e049ec5a8834b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
