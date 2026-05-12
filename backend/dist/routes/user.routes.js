"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const database_1 = __importDefault(require("../config/database"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// GET /api/user/profile - Get current user's profile
router.get('/profile', async (req, res, next) => {
    try {
        const user = await database_1.default.user.findUnique({
            where: { id: req.userId },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                avatar: true,
                bio: true,
                phone: true,
                linkedIn: true,
                education: true,
                networth: true,
                twitter: true,
                instagram: true,
                website: true,
                verified: true,
                createdAt: true,
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
// PUT /api/user/profile - Update profile
router.put('/profile', async (req, res, next) => {
    try {
        const { name, bio, phone, linkedIn, education, networth, twitter, instagram, website, avatar } = req.body;
        const user = await database_1.default.user.update({
            where: { id: req.userId },
            data: {
                ...(name && { name }),
                ...(bio !== undefined && { bio }),
                ...(phone !== undefined && { phone }),
                ...(linkedIn !== undefined && { linkedIn }),
                ...(education !== undefined && { education }),
                ...(networth !== undefined && { networth }),
                ...(twitter !== undefined && { twitter }),
                ...(instagram !== undefined && { instagram }),
                ...(website !== undefined && { website }),
                ...(avatar !== undefined && { avatar }),
            },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                avatar: true,
                bio: true,
                phone: true,
                linkedIn: true,
                education: true,
                networth: true,
                twitter: true,
                instagram: true,
                website: true,
                verified: true,
            },
        });
        res.json(user);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/user/notifications - Get notifications
router.get('/notifications', async (req, res, next) => {
    try {
        const notifications = await database_1.default.notification.findMany({
            where: { userId: req.userId },
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
        res.json(notifications);
    }
    catch (err) {
        next(err);
    }
});
// PUT /api/user/notifications/:id/read - Mark notification as read
router.put('/notifications/:id/read', async (req, res, next) => {
    try {
        await database_1.default.notification.update({
            where: { id: req.params.id },
            data: { read: true },
        });
        res.json({ message: 'Notification marked as read' });
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=user.routes.js.map