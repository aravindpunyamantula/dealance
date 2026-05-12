import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest, requireRole } from '../middleware/auth';
import * as dealService from '../services/deal.service';

const router = Router();
router.use(authenticate as any);

// POST /api/deals — Create deal offer (investor only)
router.post('/', requireRole('INVESTOR') as any, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const deal = await dealService.createDeal(req.userId!, req.body);
    res.status(201).json(deal);
  } catch (err) { next(err); }
});

// GET /api/deals — List my deals
router.get('/', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const deals = await dealService.getMyDeals(req.userId!);
    res.json(deals);
  } catch (err) { next(err); }
});

// GET /api/deals/:id — Get deal detail
router.get('/:id', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const deal = await dealService.getDeal(req.params.id as string, req.userId!);
    res.json(deal);
  } catch (err) { next(err); }
});

// PUT /api/deals/:id — Update deal terms (negotiate)
router.put('/:id', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const deal = await dealService.updateDeal(req.params.id as string, req.userId!, req.body);
    res.json(deal);
  } catch (err) { next(err); }
});

// PUT /api/deals/:id/accept — Accept deal
router.put('/:id/accept', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const deal = await dealService.updateDealStatus(req.params.id as string, req.userId!, 'ACCEPTED');
    res.json(deal);
  } catch (err) { next(err); }
});

// PUT /api/deals/:id/reject — Reject deal
router.put('/:id/reject', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const deal = await dealService.updateDealStatus(req.params.id as string, req.userId!, 'REJECTED');
    res.json(deal);
  } catch (err) { next(err); }
});

export default router;
