import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest, requireRole } from '../middleware/auth';
import * as ndaService from '../services/nda.service';

const router = Router();

router.use(authenticate as any);

// POST /api/nda/sign — Investor signs NDA
router.post('/sign', requireRole('INVESTOR') as any, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { ideaId, signatureText } = req.body;

    if (!ideaId || !signatureText) {
      res.status(400).json({ error: 'ideaId and signatureText are required' });
      return;
    }

    if (signatureText.trim().length < 2) {
      res.status(400).json({ error: 'Please provide your full legal name' });
      return;
    }

    const result = await ndaService.signNDA(ideaId, req.userId!, signatureText.trim());
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// GET /api/nda/check/:ideaId — Check NDA status
router.get('/check/:ideaId', requireRole('INVESTOR') as any, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await ndaService.checkNDA(req.params.ideaId as string, req.userId!);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
