import { Router, Request, Response, NextFunction } from 'express';
import * as learnService from '../services/learn.service';

const router = Router();

// GET /api/learn/articles - List articles (public, no auth needed)
router.get('/articles', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { type, category, search } = req.query;
    const articles = await learnService.getArticles({
      type: type as string,
      category: category as string,
      search: search as string,
    });
    res.json(articles);
  } catch (err) {
    next(err);
  }
});

// GET /api/learn/categories - List categories
router.get('/categories', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const categories = await learnService.getCategories();
    res.json(categories);
  } catch (err) {
    next(err);
  }
});

// GET /api/learn/articles/:id - Single article
router.get('/articles/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const article = await learnService.getArticleById(req.params.id as string);
    res.json(article);
  } catch (err) {
    next(err);
  }
});

export default router;
