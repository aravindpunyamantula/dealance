import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import * as chatService from '../services/chat.service';

const router = Router();
router.use(authenticate as any);

// GET /api/chat/rooms — List my chat rooms
router.get('/rooms', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const rooms = await chatService.getUserRooms(req.userId!);
    res.json(rooms);
  } catch (err) { next(err); }
});

// POST /api/chat/rooms — Create or get DM room
router.post('/rooms', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { otherUserId } = req.body;
    if (!otherUserId) {
      res.status(400).json({ error: 'otherUserId is required' });
      return;
    }
    const room = await chatService.getOrCreateDMRoom(req.userId!, otherUserId);
    res.json(room);
  } catch (err) { next(err); }
});

// GET /api/chat/rooms/:id/messages — Get messages
router.get('/rooms/:id/messages', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const messages = await chatService.getMessages(req.params.id as string, req.userId!, page);
    res.json(messages);
  } catch (err) { next(err); }
});

// POST /api/chat/rooms/:id/messages — Send message
router.post('/rooms/:id/messages', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { content, type, metadata } = req.body;
    if (!content || content.trim().length === 0) {
      res.status(400).json({ error: 'Message content is required' });
      return;
    }
    const message = await chatService.sendMessage(
      req.params.id as string, req.userId!, content.trim(), type || 'TEXT', metadata
    );
    // Emit via Socket.IO if available
    const io = req.app.get('io');
    if (io) {
      io.to(`room:${req.params.id}`).emit('chat:message', message);
    }
    res.json(message);
  } catch (err) { next(err); }
});

export default router;
