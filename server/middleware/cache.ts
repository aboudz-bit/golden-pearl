interface CacheEntry {
  data: any;
  expiresAt: number;
}

const store = new Map<string, CacheEntry>();

export function getCached(key: string): any | null {
  const entry = store.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    store.delete(key);
    return null;
  }
  return entry.data;
}

export function setCache(key: string, data: any, ttlSeconds = 60) {
  store.set(key, { data, expiresAt: Date.now() + ttlSeconds * 1000 });
}

export function invalidateCache(key: string) {
  store.delete(key);
}

export function invalidateCachePrefix(prefix: string) {
  for (const key of store.keys()) {
    if (key.startsWith(prefix)) store.delete(key);
  }
}
