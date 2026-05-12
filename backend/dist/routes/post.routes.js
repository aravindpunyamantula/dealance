"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const postService = __importStar(require("../services/post.service"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// POST /api/posts — Create post
router.post('/', async (req, res, next) => {
    try {
        const { content, startupId, mediaUrls } = req.body;
        if (!content || content.trim().length === 0) {
            res.status(400).json({ error: 'Post content is required' });
            return;
        }
        const post = await postService.createPost(req.userId, { content: content.trim(), startupId, mediaUrls });
        res.status(201).json(post);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/posts — Get feed
router.get('/', async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const authorId = req.query.authorId;
        const feed = await postService.getFeed(req.userId, page, limit, authorId);
        res.json(feed);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/posts/:id/like — Toggle like
router.post('/:id/like', async (req, res, next) => {
    try {
        const result = await postService.toggleLike(req.params.id, req.userId);
        res.json(result);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/posts/:id/comments — Get comments
router.get('/:id/comments', async (req, res, next) => {
    try {
        const comments = await postService.getComments(req.params.id);
        res.json(comments);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/posts/:id/comments — Add comment
router.post('/:id/comments', async (req, res, next) => {
    try {
        const { content } = req.body;
        if (!content || content.trim().length === 0) {
            res.status(400).json({ error: 'Comment content is required' });
            return;
        }
        const comment = await postService.addComment(req.params.id, req.userId, content.trim());
        res.json(comment);
    }
    catch (err) {
        next(err);
    }
});
// DELETE /api/posts/:id — Delete post
router.delete('/:id', async (req, res, next) => {
    try {
        await postService.deletePost(req.params.id, req.userId);
        res.json({ message: 'Post deleted' });
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=post.routes.js.map