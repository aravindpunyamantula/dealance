const { PrismaClient } = require('@prisma/client');

async function testUrl(url) {
  console.log('Testing:', url.split('@')[1]); // hide pass
  const prisma = new PrismaClient({
    datasources: { db: { url } },
    log: ['info', 'warn', 'error'],
  });
  try {
    const c = await prisma.article.count();
    console.log('Success! Count:', c);
  } catch(e) {
    console.error('Failed:', e.message);
  } finally {
    await prisma.$disconnect();
  }
}

const base = "postgresql://postgres:9177870477@database-1.cm7g22sws8hs.us-east-1.rds.amazonaws.com:5432/database-1";

(async () => {
  await testUrl(base + '?sslmode=require');
  await testUrl(base + '?sslmode=disable');
  await testUrl(base + '?connect_timeout=30&pool_timeout=30');
})();
