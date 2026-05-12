import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import * as geminiService from '../services/gemini.service';

const router = Router();

router.use(authenticate as any);

// POST /api/ai/analyze/:ideaId - Trigger AI analysis
router.post('/analyze/:ideaId', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const ideaId = req.params.ideaId as string;
    const report = await geminiService.triggerAnalysis(ideaId, req.userId!);
    res.json(report);
  } catch (err) {
    next(err);
  }
});

// GET /api/ai/report/:ideaId - Get AI report
router.get('/report/:ideaId', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const ideaId = req.params.ideaId as string;
    const report = await geminiService.getReport(ideaId, req.userId!);
    res.json(report);
  } catch (err) {
    next(err);
  }
});

// GET /api/ai/status/:ideaId - Check report status
router.get('/status/:ideaId', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const ideaId = req.params.ideaId as string;
    const status = await geminiService.getReportStatus(ideaId, req.userId!);
    res.json(status || { status: 'NOT_STARTED' });
  } catch (err) {
    next(err);
  }
});

// GET /api/ai/investor-review/:ideaId - Investor AI Review
router.get('/investor-review/:ideaId', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    if (req.userRole !== 'INVESTOR') {
      return res.status(403).json({ error: 'Only investors can access this feature' });
    }
    const ideaId = req.params.ideaId as string;
    const reportMarkdown = await geminiService.getInvestorAIReview(ideaId);
    res.json({ report: reportMarkdown });
  } catch (err) {
    next(err);
  }
});

export default router;
