export declare function createPost(userId: string, data: {
    content: string;
    startupId?: string;
    mediaUrls?: string[];
}): Promise<{
    user: {
        role: string;
        name: string;
        id: string;
        avatar: string;
    };
    _count: {
        comments: number;
        likes: number;
    };
    startup: {
        id: string;
        companyName: string;
        logoUrl: string;
        industry: string;
    };
} & {
    userId: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    content: string;
    mediaUrls: string | null;
    likesCount: number;
    startupId: string | null;
}>;
export declare function getFeed(userId: string, page?: number, limit?: number, authorId?: string): Promise<{
    isLiked: boolean;
    likes: any;
    mediaUrls: any;
    user: {
        role: string;
        name: string;
        id: string;
        avatar: string;
    };
    _count: {
        comments: number;
        likes: number;
    };
    startup: {
        id: string;
        companyName: string;
        tagline: string;
        logoUrl: string;
        industry: string;
    };
    userId: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    content: string;
    likesCount: number;
    startupId: string | null;
}[]>;
export declare function toggleLike(postId: string, userId: string): Promise<{
    liked: boolean;
}>;
export declare function addComment(postId: string, userId: string, content: string): Promise<{
    user: {
        name: string;
        id: string;
        avatar: string;
    };
} & {
    userId: string;
    id: string;
    createdAt: Date;
    content: string;
    postId: string;
}>;
export declare function getComments(postId: string): Promise<({
    user: {
        name: string;
        id: string;
        avatar: string;
    };
} & {
    userId: string;
    id: string;
    createdAt: Date;
    content: string;
    postId: string;
})[]>;
export declare function deletePost(postId: string, userId: string): Promise<{
    userId: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    content: string;
    mediaUrls: string | null;
    likesCount: number;
    startupId: string | null;
}>;
//# sourceMappingURL=post.service.d.ts.map