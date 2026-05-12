"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setOtp = setOtp;
exports.getOtp = getOtp;
exports.deleteOtp = deleteOtp;
const ioredis_1 = __importDefault(require("ioredis"));
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
let redis = null;
let useInMemory = false;
// In-memory fallback for when Redis is not available
const memoryStore = new Map();
function getRedis() {
    if (!redis) {
        redis = new ioredis_1.default(REDIS_URL, {
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
    }
    catch {
        console.warn('⚠️  Redis not available — using in-memory OTP store');
        useInMemory = true;
    }
})();
async function setOtp(key, value, ttlSeconds) {
    if (useInMemory) {
        memoryStore.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
        return;
    }
    try {
        await getRedis().setex(key, ttlSeconds, value);
    }
    catch {
        // Fallback
        memoryStore.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
    }
}
async function getOtp(key) {
    if (useInMemory) {
        const entry = memoryStore.get(key);
        if (!entry)
            return null;
        if (Date.now() > entry.expiresAt) {
            memoryStore.delete(key);
            return null;
        }
        return entry.value;
    }
    try {
        return await getRedis().get(key);
    }
    catch {
        // Fallback
        const entry = memoryStore.get(key);
        if (!entry)
            return null;
        if (Date.now() > entry.expiresAt) {
            memoryStore.delete(key);
            return null;
        }
        return entry.value;
    }
}
async function deleteOtp(key) {
    if (useInMemory) {
        memoryStore.delete(key);
        return;
    }
    try {
        await getRedis().del(key);
    }
    catch {
        memoryStore.delete(key);
    }
}
//# sourceMappingURL=redis.js.map