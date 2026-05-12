import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest, requireRole } from '../middleware/auth';
import * as ndaService from '../services/nda.service';

const router = Router();

router.use(authenticate as any);

// GET /api/investors — Search investor directory (entrepreneur only)
router.get('/', requireRole('ENTREPRENEUR') as any, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const search = req.query.search as string | undefined;
    const investors = await ndaService.getInvestorDirectory(search);
    res.json(investors);
  } catch (err) {
    next(err);
  }
});

// POST /api/investors/invite — Invite investor to idea (entrepreneur only)
router.post('/invite', requireRole('ENTREPRENEUR') as any, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { ideaId, investorId } = req.body;

    if (!ideaId || !investorId) {
      res.status(400).json({ error: 'ideaId and investorId are required' });
      return;
    }

    const result = await ndaService.inviteInvestor(ideaId, req.userId!, investorId);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/investors/invited/:ideaId — Get investors invited to an idea
router.get('/invited/:ideaId', requireRole('ENTREPRENEUR') as any, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await ndaService.getInvitedInvestors(req.params.ideaId as string, req.userId!);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
