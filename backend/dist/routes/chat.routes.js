"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const chatService = __importStar(require("../services/chat.service"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// GET /api/chat/rooms — List my chat rooms
router.get('/rooms', async (req, res, next) => {
    try {
        const rooms = await chatService.getUserRooms(req.userId);
        res.json(rooms);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/chat/rooms — Create or get DM room
router.post('/rooms', async (req, res, next) => {
    try {
        const { otherUserId } = req.body;
        if (!otherUserId) {
            res.status(400).json({ error: 'otherUserId is required' });
            return;
        }
        const room = await chatService.getOrCreateDMRoom(req.userId, otherUserId);
        res.json(room);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/chat/rooms/:id/messages — Get messages
router.get('/rooms/:id/messages', async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const messages = await chatService.getMessages(req.params.id, req.userId, page);
        res.json(messages);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/chat/rooms/:id/messages — Send message
router.post('/rooms/:id/messages', async (req, res, next) => {
    try {
        const { content, type, metadata } = req.body;
        if (!content || content.trim().length === 0) {
            res.status(400).json({ error: 'Message content is required' });
            return;
        }
        const message = await chatService.sendMessage(req.params.id, req.userId, content.trim(), type || 'TEXT', metadata);
        // Emit via Socket.IO if available
        const io = req.app.get('io');
        if (io) {
            io.to(`room:${req.params.id}`).emit('chat:message', message);
        }
        res.json(message);
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=chat.routes.js.map