import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import prisma from '../config/database';

const router = Router();

router.use(authenticate as any);

// GET /api/user/profile - Get current user's profile
router.get('/profile', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const user = await prisma.user.findUnique({
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
  } catch (err) {
    next(err);
  }
});

// PUT /api/user/profile - Update profile
router.put('/profile', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { name, bio, phone, linkedIn, education, networth, twitter, instagram, website, avatar } = req.body;

    const user = await prisma.user.update({
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
  } catch (err) {
    next(err);
  }
});

// GET /api/user/notifications - Get notifications
router.get('/notifications', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    res.json(notifications);
  } catch (err) {
    next(err);
  }
});

// PUT /api/user/notifications/:id/read - Mark notification as read
router.put('/notifications/:id/read', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    await prisma.notification.update({
      where: { id: req.params.id as string },
      data: { read: true },
    });

    res.json({ message: 'Notification marked as read' });
  } catch (err) {
    next(err);
  }
});

export default router;
