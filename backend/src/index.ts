import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import dns from 'dns';

// Force IPv4 for external connections to fix ENETUNREACH issues on cloud providers like Render
if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}

dotenv.config();

import { errorHandler } from './middleware/errorHandler';
import authRoutes from './routes/auth.routes';
import ideaRoutes from './routes/idea.routes';
import userRoutes from './routes/user.routes';
import aiRoutes from './routes/ai.routes';
import uploadRoutes from './routes/upload.routes';
import learnRoutes from './routes/learn.routes';
import feedRoutes from './routes/feed.routes';
import ndaRoutes from './routes/nda.routes';
import investorRoutes from './routes/investor.routes';
import postRoutes from './routes/post.routes';
import chatRoutes from './routes/chat.routes';
import dealRoutes from './routes/deal.routes';
import { seedArticles } from './services/learn.service';

const app = express();
const httpServer = createServer(app);
const PORT = process.env.PORT || 3000;

// ─── Socket.IO ───
const io = new SocketIOServer(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

// Store io instance on app for routes to access
app.set('io', io);

// Socket.IO auth middleware
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication required'));
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
    (socket as any).userId = decoded.userId;
    next();
  } catch {
    next(new Error('Invalid token'));
  }
});

io.on('connection', (socket) => {
  const userId = (socket as any).userId;
  console.log(`🔌 User connected: ${userId}`);

  // Auto-join user's personal room for notifications
  socket.join(`user:${userId}`);

  // Join chat rooms
  socket.on('chat:join', (roomId: string) => {
    socket.join(`room:${roomId}`);
    console.log(`💬 User ${userId} joined room ${roomId}`);
  });

  socket.on('chat:leave', (roomId: string) => {
    socket.leave(`room:${roomId}`);
  });

  socket.on('chat:typing', (data: { roomId: string }) => {
    socket.to(`room:${data.roomId}`).emit('chat:typing', { userId, roomId: data.roomId });
  });

  socket.on('disconnect', () => {
    console.log(`🔌 User disconnected: ${userId}`);
  });
});

// ─── Express Middleware ───
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Routes ───
app.use('/api/auth', authRoutes);
app.use('/api/ideas', ideaRoutes);
app.use('/api/user', userRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/learn', learnRoutes);
app.use('/api/feed', feedRoutes);      // Investor deal flow
app.use('/api/nda', ndaRoutes);
app.use('/api/investors', investorRoutes);
app.use('/api/posts', postRoutes);     // Social feed
app.use('/api/chat', chatRoutes);      // Messaging
app.use('/api/deals', dealRoutes);     // Investment deals

// ─── Auth: complete-signup for role selection ───
import prisma from './config/database';
import { authenticate, AuthRequest } from './middleware/auth';

app.post('/api/auth/complete-signup', authenticate as any, async (req: any, res, next) => {
  try {
    const { name, role } = req.body;
    if (!role || !['ENTREPRENEUR', 'INVESTOR'].includes(role)) {
      res.status(400).json({ error: 'Valid role required (ENTREPRENEUR or INVESTOR)' });
      return;
    }
    const user = await prisma.user.update({
      where: { id: req.userId },
      data: {
        ...(name && { name }),
        role,
      },
      select: { id: true, name: true, email: true, role: true, avatar: true, bio: true },
    });
    res.json(user);
  } catch (err) { next(err); }
});

// ─── Public profile endpoint ───
app.get('/api/users/:id/profile', authenticate as any, async (req: any, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.params.id as string },
      select: {
        id: true, name: true, avatar: true, bio: true, role: true,
        linkedIn: true, twitter: true, instagram: true, website: true,
        createdAt: true,
        ideas: {
          where: { status: 'SUBMITTED', visibility: 'PUBLIC' },
          select: { id: true, companyName: true, tagline: true, industry: true, logoUrl: true },
          take: 10,
        },
        _count: { select: { posts: true, ideas: true } },
      },
    });
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    res.json(user);
  } catch (err) { next(err); }
});

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Global error handler
app.use(errorHandler);

httpServer.listen(PORT, async () => {
  console.log(`🚀 Dealance API running on http://localhost:${PORT}`);
  console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔌 Socket.IO ready`);

  try {
    await seedArticles();
    console.log('📚 Learning content seeded');
  } catch (err) {
    console.warn('⚠️ Could not seed articles:', (err as any).message?.slice(0, 100));
  }

  // Seed test investor
  try {
    const existing = await prisma.user.findUnique({ where: { email: 'investor@dealance.com' } });
    if (!existing) {
      await prisma.user.create({
        data: {
          name: 'Demo Investor', email: 'investor@dealance.com', passwordHash: '',
          role: 'INVESTOR', bio: 'Angel investor focused on early-stage tech startups.',
          linkedIn: 'https://linkedin.com/in/demo-investor', twitter: 'https://twitter.com/demoinvestor',
          website: 'https://demoinvestor.com', verified: true,
        },
      });
      console.log('🏦 Test investor seeded: investor@dealance.com');
    }
  } catch (err) {
    console.warn('⚠️ Could not seed investor:', (err as any).message?.slice(0, 100));
  }
});

export default app;
