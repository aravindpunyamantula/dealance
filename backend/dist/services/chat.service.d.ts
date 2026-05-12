export declare function getOrCreateDMRoom(userId1: string, userId2: string): Promise<{
    members: ({
        user: {
            role: string;
            name: string;
            id: string;
            avatar: string;
        };
    } & {
        userId: string;
        id: string;
        roomId: string;
        joinedAt: Date;
    })[];
    messages: {
        type: string;
        id: string;
        createdAt: Date;
        metadata: string | null;
        content: string;
        roomId: string;
        senderId: string;
    }[];
} & {
    type: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    dealId: string | null;
}>;
export declare function getUserRooms(userId: string): Promise<{
    otherUser: {
        role: string;
        name: string;
        id: string;
        avatar: string;
    };
    lastMessage: {
        type: string;
        id: string;
        createdAt: Date;
        metadata: string | null;
        content: string;
        roomId: string;
        senderId: string;
    };
    members: ({
        user: {
            role: string;
            name: string;
            id: string;
            avatar: string;
        };
    } & {
        userId: string;
        id: string;
        roomId: string;
        joinedAt: Date;
    })[];
    messages: {
        type: string;
        id: string;
        createdAt: Date;
        metadata: string | null;
        content: string;
        roomId: string;
        senderId: string;
    }[];
    type: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    dealId: string | null;
}[]>;
export declare function getMessages(roomId: string, userId: string, page?: number, limit?: number): Promise<({
    sender: {
        name: string;
        id: string;
        avatar: string;
    };
} & {
    type: string;
    id: string;
    createdAt: Date;
    metadata: string | null;
    content: string;
    roomId: string;
    senderId: string;
})[]>;
export declare function sendMessage(roomId: string, senderId: string, content: string, type?: string, metadata?: string): Promise<{
    sender: {
        name: string;
        id: string;
        avatar: string;
    };
} & {
    type: string;
    id: string;
    createdAt: Date;
    metadata: string | null;
    content: string;
    roomId: string;
    senderId: string;
}>;
//# sourceMappingURL=chat.service.d.ts.map