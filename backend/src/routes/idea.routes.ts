import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import * as ideaService from '../services/idea.service';

const router = Router();

// All routes require auth
router.use(authenticate as any);

// GET /api/ideas - List user's ideas
router.get('/', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const ideas = await ideaService.getUserIdeas(req.userId!);
    res.json(ideas);
  } catch (err) {
    next(err);
  }
});

// POST /api/ideas - Create new idea
router.post('/', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const idea = await ideaService.createIdea(req.userId!, req.body);
    res.status(201).json(idea);
  } catch (err) {
    next(err);
  }
});

// GET /api/ideas/:id - Get single idea
router.get('/:id', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id as string;
    const idea = await ideaService.getIdeaById(id, req.userId!);
    res.json(idea);
  } catch (err) {
    next(err);
  }
});

// PUT /api/ideas/:id/step/:stepNumber - Update specific step
router.put('/:id/step/:stepNumber', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id as string;
    const stepNumber = parseInt(req.params.stepNumber as string);
    if (isNaN(stepNumber) || stepNumber < 1 || stepNumber > 5) {
      res.status(400).json({ error: 'Step number must be 1-5' });
      return;
    }

    const idea = await ideaService.updateIdeaStep(id, req.userId!, stepNumber, req.body);
    res.json(idea);
  } catch (err) {
    next(err);
  }
});

// POST /api/ideas/:id/submit - Submit idea
router.post('/:id/submit', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id as string;
    const idea = await ideaService.submitIdea(id, req.userId!);
    res.json(idea);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/ideas/:id - Delete idea
router.delete('/:id', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id as string;
    await ideaService.deleteIdea(id, req.userId!);
    res.json({ message: 'Idea deleted' });
  } catch (err) {
    next(err);
  }
});

export default router;
