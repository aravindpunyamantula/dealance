import prisma from '../config/database';

// ─── CREATE POST ───
export async function createPost(userId: string, data: { content: string; startupId?: string; mediaUrls?: string[] }) {
  return prisma.post.create({
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
export async function getFeed(userId: string, page: number = 1, limit: number = 20, authorId?: string) {
  const skip = (page - 1) * limit;
  
  const whereClause = authorId ? { userId: authorId } : {};

  const posts = await prisma.post.findMany({
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
export async function toggleLike(postId: string, userId: string) {
  const existing = await prisma.postLike.findUnique({
    where: { postId_userId: { postId, userId } },
  });

  if (existing) {
    await prisma.postLike.delete({ where: { id: existing.id } });
    await prisma.post.update({ where: { id: postId }, data: { likesCount: { decrement: 1 } } });
    return { liked: false };
  } else {
    await prisma.postLike.create({ data: { postId, userId } });
    await prisma.post.update({ where: { id: postId }, data: { likesCount: { increment: 1 } } });
    return { liked: true };
  }
}

// ─── COMMENTS ───
export async function addComment(postId: string, userId: string, content: string) {
  return prisma.comment.create({
    data: { postId, userId, content },
    include: {
      user: { select: { id: true, name: true, avatar: true } },
    },
  });
}

export async function getComments(postId: string) {
  return prisma.comment.findMany({
    where: { postId },
    orderBy: { createdAt: 'asc' },
    include: {
      user: { select: { id: true, name: true, avatar: true } },
    },
  });
}

// ─── DELETE POST ───
export async function deletePost(postId: string, userId: string) {
  const post = await prisma.post.findFirst({ where: { id: postId, userId } });
  if (!post) throw Object.assign(new Error('Post not found'), { statusCode: 404 });
  return prisma.post.delete({ where: { id: postId } });
}
