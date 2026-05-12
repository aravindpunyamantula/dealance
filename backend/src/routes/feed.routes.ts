import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest, requireRole } from '../middleware/auth';
import * as feedService from '../services/feed.service';

const router = Router();

// All routes require auth + INVESTOR role
router.use(authenticate as any);
router.use(requireRole('INVESTOR') as any);

// GET /api/feed — Investor deal flow feed
router.get('/', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const feed = await feedService.getDealFlowFeed(req.userId!);
    res.json(feed);
  } catch (err) {
    next(err);
  }
});

// GET /api/feed/:ideaId — Full idea details (with access check)
router.get('/:ideaId', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const idea = await feedService.getIdeaForInvestor(req.params.ideaId as string, req.userId!);
    res.json(idea);
  } catch (err) {
    next(err);
  }
});

export default router;
