import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import * as postService from '../services/post.service';

const router = Router();
router.use(authenticate as any);

// POST /api/posts — Create post
router.post('/', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { content, startupId, mediaUrls } = req.body;
    if (!content || content.trim().length === 0) {
      res.status(400).json({ error: 'Post content is required' });
      return;
    }
    const post = await postService.createPost(req.userId!, { content: content.trim(), startupId, mediaUrls });
    res.status(201).json(post);
  } catch (err) { next(err); }
});

// GET /api/posts — Get feed
router.get('/', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const authorId = req.query.authorId as string | undefined;
    const feed = await postService.getFeed(req.userId!, page, limit, authorId);
    res.json(feed);
  } catch (err) { next(err); }
});

// POST /api/posts/:id/like — Toggle like
router.post('/:id/like', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await postService.toggleLike(req.params.id as string, req.userId!);
    res.json(result);
  } catch (err) { next(err); }
});

// GET /api/posts/:id/comments — Get comments
router.get('/:id/comments', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const comments = await postService.getComments(req.params.id as string);
    res.json(comments);
  } catch (err) { next(err); }
});

// POST /api/posts/:id/comments — Add comment
router.post('/:id/comments', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { content } = req.body;
    if (!content || content.trim().length === 0) {
      res.status(400).json({ error: 'Comment content is required' });
      return;
    }
    const comment = await postService.addComment(req.params.id as string, req.userId!, content.trim());
    res.json(comment);
  } catch (err) { next(err); }
});

// DELETE /api/posts/:id — Delete post
router.delete('/:id', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    await postService.deletePost(req.params.id as string, req.userId!);
    res.json({ message: 'Post deleted' });
  } catch (err) { next(err); }
});

export default router;
