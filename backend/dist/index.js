"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const http_1 = require("http");
const socket_io_1 = require("socket.io");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const dotenv_1 = __importDefault(require("dotenv"));
const dns_1 = __importDefault(require("dns"));
// Force IPv4 for external connections to fix ENETUNREACH issues on cloud providers like Render
if (dns_1.default.setDefaultResultOrder) {
    dns_1.default.setDefaultResultOrder('ipv4first');
}
dotenv_1.default.config();
const errorHandler_1 = require("./middleware/errorHandler");
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const idea_routes_1 = __importDefault(require("./routes/idea.routes"));
const user_routes_1 = __importDefault(require("./routes/user.routes"));
const ai_routes_1 = __importDefault(require("./routes/ai.routes"));
const upload_routes_1 = __importDefault(require("./routes/upload.routes"));
const learn_routes_1 = __importDefault(require("./routes/learn.routes"));
const feed_routes_1 = __importDefault(require("./routes/feed.routes"));
const nda_routes_1 = __importDefault(require("./routes/nda.routes"));
const investor_routes_1 = __importDefault(require("./routes/investor.routes"));
const post_routes_1 = __importDefault(require("./routes/post.routes"));
const chat_routes_1 = __importDefault(require("./routes/chat.routes"));
const deal_routes_1 = __importDefault(require("./routes/deal.routes"));
const learn_service_1 = require("./services/learn.service");
const app = (0, express_1.default)();
const httpServer = (0, http_1.createServer)(app);
const PORT = process.env.PORT || 3000;
// ─── Socket.IO ───
const io = new socket_io_1.Server(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
});
// Store io instance on app for routes to access
app.set('io', io);
// Socket.IO auth middleware
io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token)
        return next(new Error('Authentication required'));
    try {
        const decoded = jsonwebtoken_1.default.verify(token, process.env.JWT_SECRET);
        socket.userId = decoded.userId;
        next();
    }
    catch {
        next(new Error('Invalid token'));
    }
});
io.on('connection', (socket) => {
    const userId = socket.userId;
    console.log(`🔌 User connected: ${userId}`);
    // Auto-join user's personal room for notifications
    socket.join(`user:${userId}`);
    // Join chat rooms
    socket.on('chat:join', (roomId) => {
        socket.join(`room:${roomId}`);
        console.log(`💬 User ${userId} joined room ${roomId}`);
    });
    socket.on('chat:leave', (roomId) => {
        socket.leave(`room:${roomId}`);
    });
    socket.on('chat:typing', (data) => {
        socket.to(`room:${data.roomId}`).emit('chat:typing', { userId, roomId: data.roomId });
    });
    socket.on('disconnect', () => {
        console.log(`🔌 User disconnected: ${userId}`);
    });
});
// ─── Express Middleware ───
app.use((0, cors_1.default)({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true }));
// ─── Routes ───
app.use('/api/auth', auth_routes_1.default);
app.use('/api/ideas', idea_routes_1.default);
app.use('/api/user', user_routes_1.default);
app.use('/api/ai', ai_routes_1.default);
app.use('/api/upload', upload_routes_1.default);
app.use('/api/learn', learn_routes_1.default);
app.use('/api/feed', feed_routes_1.default); // Investor deal flow
app.use('/api/nda', nda_routes_1.default);
app.use('/api/investors', investor_routes_1.default);
app.use('/api/posts', post_routes_1.default); // Social feed
app.use('/api/chat', chat_routes_1.default); // Messaging
app.use('/api/deals', deal_routes_1.default); // Investment deals
// ─── Auth: complete-signup for role selection ───
const database_1 = __importDefault(require("./config/database"));
const auth_1 = require("./middleware/auth");
app.post('/api/auth/complete-signup', auth_1.authenticate, async (req, res, next) => {
    try {
        const { name, role } = req.body;
        if (!role || !['ENTREPRENEUR', 'INVESTOR'].includes(role)) {
            res.status(400).json({ error: 'Valid role required (ENTREPRENEUR or INVESTOR)' });
            return;
        }
        const user = await database_1.default.user.update({
            where: { id: req.userId },
            data: {
                ...(name && { name }),
                role,
            },
            select: { id: true, name: true, email: true, role: true, avatar: true, bio: true },
        });
        res.json(user);
    }
    catch (err) {
        next(err);
    }
});
// ─── Public profile endpoint ───
app.get('/api/users/:id/profile', auth_1.authenticate, async (req, res, next) => {
    try {
        const user = await database_1.default.user.findUnique({
            where: { id: req.params.id },
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
        if (!user) {
            res.status(404).json({ error: 'User not found' });
            return;
        }
        res.json(user);
    }
    catch (err) {
        next(err);
    }
});
// Health check
app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
// Global error handler
app.use(errorHandler_1.errorHandler);
httpServer.listen(PORT, async () => {
    console.log(`🚀 Dealance API running on http://localhost:${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🔌 Socket.IO ready`);
    try {
        await (0, learn_service_1.seedArticles)();
        console.log('📚 Learning content seeded');
    }
    catch (err) {
        console.warn('⚠️ Could not seed articles:', err.message?.slice(0, 100));
    }
    // Seed test investor
    try {
        const existing = await database_1.default.user.findUnique({ where: { email: 'investor@dealance.com' } });
        if (!existing) {
            await database_1.default.user.create({
                data: {
                    name: 'Demo Investor', email: 'investor@dealance.com', passwordHash: '',
                    role: 'INVESTOR', bio: 'Angel investor focused on early-stage tech startups.',
                    linkedIn: 'https://linkedin.com/in/demo-investor', twitter: 'https://twitter.com/demoinvestor',
                    website: 'https://demoinvestor.com', verified: true,
                },
            });
            console.log('🏦 Test investor seeded: investor@dealance.com');
        }
    }
    catch (err) {
        console.warn('⚠️ Could not seed investor:', err.message?.slice(0, 100));
    }
});
exports.default = app;
//# sourceMappingURL=index.js.map