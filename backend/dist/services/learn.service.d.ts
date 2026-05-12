export declare function seedArticles(): Promise<void>;
export declare function getArticles(filters?: {
    type?: string;
    category?: string;
    search?: string;
}): Promise<{
    type: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    title: string;
    contentUrl: string | null;
    description: string;
    content: string | null;
    thumbnailUrl: string | null;
    duration: string | null;
    category: string | null;
    author: string | null;
    published: boolean;
}[]>;
export declare function getCategories(): Promise<string[]>;
export declare function getArticleById(id: string): Promise<{
    type: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    title: string;
    contentUrl: string | null;
    description: string;
    content: string | null;
    thumbnailUrl: string | null;
    duration: string | null;
    category: string | null;
    author: string | null;
    published: boolean;
}>;
//# sourceMappingURL=learn.service.d.ts.map