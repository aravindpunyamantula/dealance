"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getOrCreateDMRoom = getOrCreateDMRoom;
exports.getUserRooms = getUserRooms;
exports.getMessages = getMessages;
exports.sendMessage = sendMessage;
const database_1 = __importDefault(require("../config/database"));
// ─── GET OR CREATE DM ROOM ───
async function getOrCreateDMRoom(userId1, userId2) {
    // Check if a direct room already exists between these two users
    const existingRoom = await database_1.default.chatRoom.findFirst({
        where: {
            type: 'DIRECT',
            AND: [
                { members: { some: { userId: userId1 } } },
                { members: { some: { userId: userId2 } } },
            ],
        },
        include: {
            members: { include: { user: { select: { id: true, name: true, avatar: true, role: true } } } },
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        },
    });
    if (existingRoom)
        return existingRoom;
    // Create new room
    return database_1.default.chatRoom.create({
        data: {
            type: 'DIRECT',
            members: {
                create: [
                    { userId: userId1 },
                    { userId: userId2 },
                ],
            },
        },
        include: {
            members: { include: { user: { select: { id: true, name: true, avatar: true, role: true } } } },
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        },
    });
}
// ─── LIST ROOMS ───
async function getUserRooms(userId) {
    const rooms = await database_1.default.chatRoom.findMany({
        where: { members: { some: { userId } } },
        include: {
            members: { include: { user: { select: { id: true, name: true, avatar: true, role: true } } } },
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        },
        orderBy: { updatedAt: 'desc' },
    });
    return rooms.map(room => ({
        ...room,
        otherUser: room.members.find(m => m.userId !== userId)?.user || null,
        lastMessage: room.messages[0] || null,
    }));
}
// ─── GET MESSAGES ───
async function getMessages(roomId, userId, page = 1, limit = 50) {
    // Verify membership
    const member = await database_1.default.chatMember.findUnique({
        where: { roomId_userId: { roomId, userId } },
    });
    if (!member)
        throw Object.assign(new Error('Not a member of this chat'), { statusCode: 403 });
    return database_1.default.message.findMany({
        where: { roomId },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: {
            sender: { select: { id: true, name: true, avatar: true } },
        },
    });
}
// ─── SEND MESSAGE ───
async function sendMessage(roomId, senderId, content, type = 'TEXT', metadata) {
    // Verify membership
    const member = await database_1.default.chatMember.findUnique({
        where: { roomId_userId: { roomId, userId: senderId } },
    });
    if (!member)
        throw Object.assign(new Error('Not a member of this chat'), { statusCode: 403 });
    const message = await database_1.default.message.create({
        data: { roomId, senderId, content, type, metadata },
        include: {
            sender: { select: { id: true, name: true, avatar: true } },
        },
    });
    // Update room timestamp
    await database_1.default.chatRoom.update({ where: { id: roomId }, data: { updatedAt: new Date() } });
    return message;
}
//# sourceMappingURL=chat.service.js.map