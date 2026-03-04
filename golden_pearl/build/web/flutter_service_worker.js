'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "27361387bc24144b46a745f1afe92b50",
"canvaskit/canvaskit.wasm": "a37f2b0af4995714de856e21e882325c",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "f7c5e5502d577306fb6d530b1864ff86",
"canvaskit/chromium/canvaskit.wasm": "c054c2c892172308ca5a0bd1d7a7754b",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "9fe690d47b904d72c7d020bd303adf16",
"canvaskit/skwasm.wasm": "1c93738510f202d9ff44d36a4760126b",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "0d965254a2b8c8de252173e9b45af875",
"index.html": "0c9578a4c52dd95853cba2d54a5e2d61",
"/": "0c9578a4c52dd95853cba2d54a5e2d61",
"main.dart.js": "3da45d45a4c23ebe0351e4a639a5f329",
"version.json": "13982b32f6ff844cb7645701df52e3db",
"assets/assets/images/IMG_6907_1772497872149.jpeg": "9cc59152d16420693a47b68459d36589",
"assets/assets/images/IMG_6902_1772497749832.jpeg": "4699e039548939fab0d33dff34bfd11f",
"assets/assets/images/IMG_6909_1772497872149.jpeg": "954ced569609cf6f1c1f6a57daf20b02",
"assets/assets/images/IMG_6910_1772497872149.jpeg": "48f920f8503c1d68905ea0b7dd5db3af",
"assets/assets/images/IMG_6908_1772497872149.jpeg": "d2119547a915908bffce2d619862fe3a",
"assets/assets/images/dress_orange_floral_vneck.jpeg": "d2119547a915908bffce2d619862fe3a",
"assets/assets/images/jalabiya_floral_tiered.jpeg": "4699e039548939fab0d33dff34bfd11f",
"assets/assets/images/gift_pink_bunny_basket.png": "26bd9adddb4490942e7b5b756d41d4dd",
"assets/assets/images/gift_nutcracker_pouch.png": "1bacecb3b85206f4512cc9e648b86b9f",
"assets/assets/images/dress_white_lace_bridal.jpeg": "48f920f8503c1d68905ea0b7dd5db3af",
"assets/assets/images/gift_welcome_boy_elegant.png": "568c8bdf422259e107d6448d8cac41f6",
"assets/assets/images/gift_bunny_basket_closeup.png": "6844a141e15dc626f9125a4e7ac74335",
"assets/assets/images/dress_white_lace_2.png": "48f920f8503c1d68905ea0b7dd5db3af",
"assets/assets/images/dress_orange_floral_flowing.jpeg": "954ced569609cf6f1c1f6a57daf20b02",
"assets/assets/images/hero3.png": "ae7984b6257b1b622fc59a3c4744a425",
"assets/assets/images/dress_coral_draped.jpeg": "9cc59152d16420693a47b68459d36589",
"assets/assets/images/gift_nutcracker_bibs_set.png": "42b2d6d2e4a52f41c075127038eac1ec",
"assets/assets/images/gift_baby_clear_box.png": "e937276f12976e52c5e8fa57ef4514a7",
"assets/assets/images/gift_welcome_boy_basket.png": "0480eef5829e4e190c15fd461461b9bc",
"assets/assets/images/kids_blue_bow_dress.png": "efe84482102ebba8a149d4e2b0e530f9",
"assets/assets/images/kids_blue_collar_dress.png": "760eaf311589e40ef0c06438af8bca67",
"assets/assets/images/kids_cream_satin_collection.png": "328a9672bb3f173864a0ddea54740a92",
"assets/assets/images/hero1.png": "4078de91598867a469e0c3722179921c",
"assets/assets/images/kids_linen_embroidered.png": "b3652b267306e21813b814af49113f51",
"assets/assets/images/kids_brocade_dress.png": "32a99b6036297b56dfe1e5b62deb57cf",
"assets/assets/images/gift_nutcracker_bib.png": "69ec3f46ad6a3347450ceb54c1d42e70",
"assets/assets/images/kids_floral_feather.png": "02e7ac8c091f2acd1134c1d11f07d1d5",
"assets/assets/images/hero2.png": "37f0814a93eeccbc90efe2495f259e61",
"assets/assets/images/kids_grey_lace_collection.png": "672036206a5cd61cabb3e92e20325026",
"assets/assets/images/kids_mannequin_display.png": "10eebce9470312c68b9150fd270d472a",
"assets/assets/images/logo.png": "54943e2b5a9fc642b1bb6f5b089939ed",
"assets/assets/images/kids_linen_puff_sleeve.png": "cb5bddacb04598370bee5431fa8be660",
"assets/assets/images/kids_silver_embroidered.png": "3d6f1eda690d5b645416b4b920754c11",
"assets/assets/images/jalabiya_gold_embroidered.jpeg": "851fd99d236b3349da8da9e815abafa2",
"assets/assets/images/kids_floral_dress_1.jpeg": "8045eab68fed48b490411a18cb73992a",
"assets/assets/images/jalabiya_sage_blush_duo.jpeg": "0fe1ac758e165def68c70a70959ccc5b",
"assets/assets/images/IMG_6903_1772497749832.jpeg": "13a00f2d0c8008fae6654b85771aa099",
"assets/assets/images/kids_floral_ruffle.png": "4728b807cfa460d3e3a6f9de4cdee233",
"assets/assets/images/kids_floral_dress_2.jpeg": "b94284e848def025dbc534ddc0f8f29a",
"assets/assets/images/IMG_6904_1772497749831.jpeg": "18990dfe6667b763214c22993d41ce52",
"assets/assets/images/IMG_6905_1772497749831.jpeg": "0fe1ac758e165def68c70a70959ccc5b",
"assets/assets/images/IMG_6900_1772497749832.jpeg": "851fd99d236b3349da8da9e815abafa2",
"assets/assets/images/jalabiya_burgundy_embroidered.jpeg": "18990dfe6667b763214c22993d41ce52",
"assets/assets/images/jalabiya_blue_green_embroidered.jpeg": "f187db98d39a07d340aacb088b64bda0",
"assets/assets/images/IMG_6901_1772497749832.jpeg": "f187db98d39a07d340aacb088b64bda0",
"assets/assets/images/jalabiya_burgundy_lace.jpeg": "13a00f2d0c8008fae6654b85771aa099",
"assets/fonts/PlayfairDisplay-Bold.ttf": "038aec929d8d05c5de0bb20e040f9973",
"assets/fonts/PlayfairDisplay-Regular.ttf": "038aec929d8d05c5de0bb20e040f9973",
"assets/fonts/PlayfairDisplay-SemiBold.ttf": "038aec929d8d05c5de0bb20e040f9973",
"assets/fonts/MaterialIcons-Regular.otf": "a20bc6232324c264d346e333dc8be84c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "825e75415ebd366b740bb49659d7a5c6",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "0cb6503350155c571258d2dc3e4071ef",
"assets/AssetManifest.bin.json": "8bad6f9569d27cf8186d426fad2b2119",
"assets/AssetManifest.bin": "fea3372df40886bb41db0851efa4c4d4",
"assets/FontManifest.json": "e17f829cc4c059a6ca8f84df499fad85",
"assets/NOTICES": "a19dc19810e74e34bffff3be7e9ca823",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"manifest.json": "4e224c48ff69d1c06ef46a90010f723e",
"images/IMG_6902_1772497749832.jpeg": "4699e039548939fab0d33dff34bfd11f",
"images/IMG_6907_1772497872149.jpeg": "9cc59152d16420693a47b68459d36589",
"images/IMG_6908_1772497872149.jpeg": "d2119547a915908bffce2d619862fe3a",
"images/IMG_6909_1772497872149.jpeg": "954ced569609cf6f1c1f6a57daf20b02",
"images/IMG_6910_1772497872149.jpeg": "48f920f8503c1d68905ea0b7dd5db3af",
"images/jalabiya_floral_tiered.jpeg": "4699e039548939fab0d33dff34bfd11f",
"images/dress_coral_draped.jpeg": "9cc59152d16420693a47b68459d36589",
"images/dress_orange_floral_vneck.jpeg": "d2119547a915908bffce2d619862fe3a",
"images/dress_orange_floral_flowing.jpeg": "954ced569609cf6f1c1f6a57daf20b02",
"images/dress_white_lace_bridal.jpeg": "48f920f8503c1d68905ea0b7dd5db3af",
"images/dress_white_lace_2.png": "48f920f8503c1d68905ea0b7dd5db3af",
"images/gift_baby_clear_box.png": "e937276f12976e52c5e8fa57ef4514a7",
"images/gift_bunny_basket_closeup.png": "6844a141e15dc626f9125a4e7ac74335",
"images/gift_nutcracker_bib.png": "69ec3f46ad6a3347450ceb54c1d42e70",
"images/gift_nutcracker_bibs_set.png": "42b2d6d2e4a52f41c075127038eac1ec",
"images/gift_nutcracker_pouch.png": "1bacecb3b85206f4512cc9e648b86b9f",
"images/gift_pink_bunny_basket.png": "26bd9adddb4490942e7b5b756d41d4dd",
"images/gift_welcome_boy_basket.png": "0480eef5829e4e190c15fd461461b9bc",
"images/gift_welcome_boy_elegant.png": "568c8bdf422259e107d6448d8cac41f6",
"images/hero1.png": "4078de91598867a469e0c3722179921c",
"images/hero2.png": "37f0814a93eeccbc90efe2495f259e61",
"images/hero3.png": "ae7984b6257b1b622fc59a3c4744a425",
"images/kids_blue_bow_dress.png": "efe84482102ebba8a149d4e2b0e530f9",
"images/kids_blue_collar_dress.png": "760eaf311589e40ef0c06438af8bca67",
"images/kids_brocade_dress.png": "32a99b6036297b56dfe1e5b62deb57cf",
"images/kids_cream_satin_collection.png": "328a9672bb3f173864a0ddea54740a92",
"images/kids_floral_feather.png": "02e7ac8c091f2acd1134c1d11f07d1d5",
"images/kids_floral_ruffle.png": "4728b807cfa460d3e3a6f9de4cdee233",
"images/kids_grey_lace_collection.png": "672036206a5cd61cabb3e92e20325026",
"images/kids_linen_embroidered.png": "b3652b267306e21813b814af49113f51",
"images/kids_linen_puff_sleeve.png": "cb5bddacb04598370bee5431fa8be660",
"images/kids_mannequin_display.png": "10eebce9470312c68b9150fd270d472a",
"images/kids_silver_embroidered.png": "3d6f1eda690d5b645416b4b920754c11",
"images/logo.png": "54943e2b5a9fc642b1bb6f5b089939ed",
"images/IMG_6900_1772497749832.jpeg": "851fd99d236b3349da8da9e815abafa2",
"images/IMG_6901_1772497749832.jpeg": "f187db98d39a07d340aacb088b64bda0",
"images/IMG_6903_1772497749832.jpeg": "13a00f2d0c8008fae6654b85771aa099",
"images/IMG_6904_1772497749831.jpeg": "18990dfe6667b763214c22993d41ce52",
"images/IMG_6905_1772497749831.jpeg": "0fe1ac758e165def68c70a70959ccc5b",
"images/jalabiya_blue_green_embroidered.jpeg": "f187db98d39a07d340aacb088b64bda0",
"images/jalabiya_burgundy_embroidered.jpeg": "18990dfe6667b763214c22993d41ce52",
"images/jalabiya_burgundy_lace.jpeg": "13a00f2d0c8008fae6654b85771aa099",
"images/jalabiya_gold_embroidered.jpeg": "851fd99d236b3349da8da9e815abafa2",
"images/jalabiya_sage_blush_duo.jpeg": "0fe1ac758e165def68c70a70959ccc5b",
"images/kids_floral_dress_1.jpeg": "8045eab68fed48b490411a18cb73992a",
"images/kids_floral_dress_2.jpeg": "b94284e848def025dbc534ddc0f8f29a",
"videos/dresses_video.mp4": "73b261b75316d03ec221b806f8696f3d",
"videos/kids_floral_dress.mp4": "2771ceb0df903a6af7d80887d96f1010"};
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
