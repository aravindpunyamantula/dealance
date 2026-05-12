import Redis from 'ioredis';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

let redis: Redis | null = null;
let useInMemory = false;

// In-memory fallback for when Redis is not available
const memoryStore = new Map<string, { value: string; expiresAt: number }>();

function getRedis(): Redis {
  if (!redis) {
    redis = new Redis(REDIS_URL, {
      maxRetriesPerRequest: 1,
      retryStrategy: (times) => {
        if (times > 2) {
          console.warn('⚠️  Redis unavailable — falling back to in-memory OTP store');
          useInMemory = true;
          return null; // stop retrying
        }
        return Math.min(times * 200, 1000);
      },
      lazyConnect: true,
    });

    redis.on('error', () => {
      useInMemory = true;
    });
  }
  return redis;
}

// Try connecting on startup
(async () => {
  try {
    const r = getRedis();
    await r.connect();
    console.log('✅ Redis connected');
  } catch {
    console.warn('⚠️  Redis not available — using in-memory OTP store');
    useInMemory = true;
  }
})();

export async function setOtp(key: string, value: string, ttlSeconds: number): Promise<void> {
  if (useInMemory) {
    memoryStore.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
    return;
  }
  try {
    await getRedis().setex(key, ttlSeconds, value);
  } catch {
    // Fallback
    memoryStore.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
  }
}

export async function getOtp(key: string): Promise<string | null> {
  if (useInMemory) {
    const entry = memoryStore.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      memoryStore.delete(key);
      return null;
    }
    return entry.value;
  }
  try {
    return await getRedis().get(key);
  } catch {
    // Fallback
    const entry = memoryStore.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      memoryStore.delete(key);
      return null;
    }
    return entry.value;
  }
}

export async function deleteOtp(key: string): Promise<void> {
  if (useInMemory) {
    memoryStore.delete(key);
    return;
  }
  try {
    await getRedis().del(key);
  } catch {
    memoryStore.delete(key);
  }
}
