"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createPost = createPost;
exports.getFeed = getFeed;
exports.toggleLike = toggleLike;
exports.addComment = addComment;
exports.getComments = getComments;
exports.deletePost = deletePost;
const database_1 = __importDefault(require("../config/database"));
// ─── CREATE POST ───
async function createPost(userId, data) {
    return database_1.default.post.create({
        data: {
            userId,
            content: data.content,
            startupId: data.startupId || null,
            mediaUrls: data.mediaUrls ? JSON.stringify(data.mediaUrls) : null,
        },
        include: {
            user: { select: { id: true, name: true, avatar: true, role: true } },
            startup: { select: { id: true, companyName: true, industry: true, logoUrl: true } },
            _count: { select: { comments: true, likes: true } },
        },
    });
}
// ─── GET FEED ───
async function getFeed(userId, page = 1, limit = 20, authorId) {
    const skip = (page - 1) * limit;
    const whereClause = authorId ? { userId: authorId } : {};
    const posts = await database_1.default.post.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
            user: { select: { id: true, name: true, avatar: true, role: true } },
            startup: { select: { id: true, companyName: true, industry: true, logoUrl: true, tagline: true } },
            _count: { select: { comments: true, likes: true } },
            likes: { where: { userId }, select: { id: true }, take: 1 },
        },
    });
    // Transform to include isLiked flag
    return posts.map(post => ({
        ...post,
        isLiked: post.likes.length > 0,
        likes: undefined, // Remove raw likes array
        mediaUrls: post.mediaUrls ? JSON.parse(post.mediaUrls) : [],
    }));
}
// ─── LIKE/UNLIKE ───
async function toggleLike(postId, userId) {
    const existing = await database_1.default.postLike.findUnique({
        where: { postId_userId: { postId, userId } },
    });
    if (existing) {
        await database_1.default.postLike.delete({ where: { id: existing.id } });
        await database_1.default.post.update({ where: { id: postId }, data: { likesCount: { decrement: 1 } } });
        return { liked: false };
    }
    else {
        await database_1.default.postLike.create({ data: { postId, userId } });
        await database_1.default.post.update({ where: { id: postId }, data: { likesCount: { increment: 1 } } });
        return { liked: true };
    }
}
// ─── COMMENTS ───
async function addComment(postId, userId, content) {
    return database_1.default.comment.create({
        data: { postId, userId, content },
        include: {
            user: { select: { id: true, name: true, avatar: true } },
        },
    });
}
async function getComments(postId) {
    return database_1.default.comment.findMany({
        where: { postId },
        orderBy: { createdAt: 'asc' },
        include: {
            user: { select: { id: true, name: true, avatar: true } },
        },
    });
}
// ─── DELETE POST ───
async function deletePost(postId, userId) {
    const post = await database_1.default.post.findFirst({ where: { id: postId, userId } });
    if (!post)
        throw Object.assign(new Error('Post not found'), { statusCode: 404 });
    return database_1.default.post.delete({ where: { id: postId } });
}
//# sourceMappingURL=post.service.js.map