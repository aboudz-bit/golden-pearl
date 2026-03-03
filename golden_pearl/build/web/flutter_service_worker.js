'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"index.html": "0c9578a4c52dd95853cba2d54a5e2d61",
"/": "0c9578a4c52dd95853cba2d54a5e2d61",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "27361387bc24144b46a745f1afe92b50",
"canvaskit/canvaskit.wasm": "a37f2b0af4995714de856e21e882325c",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "f7c5e5502d577306fb6d530b1864ff86",
"canvaskit/chromium/canvaskit.wasm": "c054c2c892172308ca5a0bd1d7a7754b",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "9fe690d47b904d72c7d020bd303adf16",
"canvaskit/skwasm.wasm": "1c93738510f202d9ff44d36a4760126b",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "cce05849f83dbe99afffc6d6124bcf3f",
"main.dart.js": "9a7ba01c64b40863988ebc6098a06798",
"version.json": "13982b32f6ff844cb7645701df52e3db",
"assets/assets/images/IMG_6908_1772497872149.jpeg": "d2119547a915908bffce2d619862fe3a",
"assets/assets/images/IMG_6900_1772497749832.jpeg": "ec4ebc2b865c9fc83e16990149982116",
"assets/assets/images/IMG_6909_1772497872149.jpeg": "954ced569609cf6f1c1f6a57daf20b02",
"assets/assets/images/IMG_6910_1772497872149.jpeg": "48f920f8503c1d68905ea0b7dd5db3af",
"assets/assets/images/kids_floral_ruffle.png": "dec08bd9df525f89034760fa5d4566a8",
"assets/assets/images/IMG_6907_1772497872149.jpeg": "9cc59152d16420693a47b68459d36589",
"assets/assets/images/IMG_6902_1772497749832.jpeg": "4699e039548939fab0d33dff34bfd11f",
"assets/assets/images/IMG_6901_1772497749832.jpeg": "3f30092276d942caf23debe2f4925deb",
"assets/assets/images/IMG_6904_1772497749831.jpeg": "08bea0d5d7ad056174dc02d4d20a8701",
"assets/assets/images/IMG_6903_1772497749832.jpeg": "f0c3f78643cdf5f519ca79200f270b76",
"assets/assets/images/kids_blue_collar_dress.png": "3c796e7f68d63404e8fd34b67efbb74f",
"assets/assets/images/kids_linen_embroidered.png": "6d76c219b1ea5fa0ec8efb2c596aaa97",
"assets/assets/images/kids_linen_puff_sleeve.png": "7f88d919350dd94468336e8219bc056a",
"assets/assets/images/kids_floral_feather.png": "e77feda7a196bf8016d106a88c21a219",
"assets/assets/images/gift_welcome_boy_basket.png": "a06517bf2172794c32b011b6ad9b7e12",
"assets/assets/images/logo.png": "b5c2b844defc830f668d10c8161539a8",
"assets/assets/images/IMG_6905_1772497749831.jpeg": "2ff1cb2f6ae703adfc39fe17ec0bd4b8",
"assets/assets/images/gift_baby_clear_box.png": "9c27415a7a00e5ad2c37ecf2117e7342",
"assets/assets/images/gift_welcome_boy_elegant.png": "6bc6de06cfd16b36029f69c1e4d35634",
"assets/assets/images/gift_bunny_basket_closeup.png": "b7c8dd11e25a0adf79dfc3f75e0f6982",
"assets/assets/images/hero1.png": "c31e3f635db7669965a16fd61423b64c",
"assets/assets/images/gift_nutcracker_bibs_set.png": "bc29ce85425f07fbd05c861f9dcf23dd",
"assets/assets/images/gift_nutcracker_bib.png": "cba0d1c73ae45f221850c63c32bdf60e",
"assets/assets/images/kids_mannequin_display.png": "b9b30baccb51dcbf3d92a1e8c716a695",
"assets/assets/images/kids_grey_lace_collection.png": "545bea73d75e3b2198aa930125cc5896",
"assets/assets/images/gift_nutcracker_pouch.png": "fc7b64faa46fd4f57226bde9cb2d7aac",
"assets/assets/images/kids_cream_satin_collection.png": "e548dc3e6ad02126fde88b1e1fcf2173",
"assets/assets/images/kids_blue_bow_dress.png": "366ee870d37c8ffe2ea4eab1296878ef",
"assets/assets/images/gift_pink_bunny_basket.png": "314f5492ae616ae2920f7a982be6c63b",
"assets/assets/images/kids_silver_embroidered.png": "59cbea2b423de2dfe89014c9683baf7f",
"assets/assets/images/kids_brocade_dress.png": "ba04cc0b23469182e910147e06aa558d",
"assets/assets/images/hero3.png": "d577c143f6c07bff9b32c67c32c1a157",
"assets/assets/images/hero2.png": "4116bebfe52d37a430434b5bb9b46c5b",
"assets/fonts/PlayfairDisplay-Regular.ttf": "038aec929d8d05c5de0bb20e040f9973",
"assets/fonts/PlayfairDisplay-SemiBold.ttf": "038aec929d8d05c5de0bb20e040f9973",
"assets/fonts/PlayfairDisplay-Bold.ttf": "038aec929d8d05c5de0bb20e040f9973",
"assets/fonts/MaterialIcons-Regular.otf": "49218c38223aea5a92c5a045beacecd8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "825e75415ebd366b740bb49659d7a5c6",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "8d825a35677a4e0fb2a586b030e1a573",
"assets/AssetManifest.bin": "9a1aac19b0f1a8acded62430010db9c5",
"assets/AssetManifest.bin.json": "3d84ac4709067ca0a1b1543a38230960",
"assets/FontManifest.json": "e17f829cc4c059a6ca8f84df499fad85",
"assets/NOTICES": "a19dc19810e74e34bffff3be7e9ca823",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"manifest.json": "4e224c48ff69d1c06ef46a90010f723e"};
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
