import prisma from '../config/database';

// ─── GET OR CREATE DM ROOM ───
export async function getOrCreateDMRoom(userId1: string, userId2: string) {
  // Check if a direct room already exists between these two users
  const existingRoom = await prisma.chatRoom.findFirst({
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

  if (existingRoom) return existingRoom;

  // Create new room
  return prisma.chatRoom.create({
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
export async function getUserRooms(userId: string) {
  const rooms = await prisma.chatRoom.findMany({
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
export async function getMessages(roomId: string, userId: string, page: number = 1, limit: number = 50) {
  // Verify membership
  const member = await prisma.chatMember.findUnique({
    where: { roomId_userId: { roomId, userId } },
  });
  if (!member) throw Object.assign(new Error('Not a member of this chat'), { statusCode: 403 });

  return prisma.message.findMany({
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
export async function sendMessage(roomId: string, senderId: string, content: string, type: string = 'TEXT', metadata?: string) {
  // Verify membership
  const member = await prisma.chatMember.findUnique({
    where: { roomId_userId: { roomId, userId: senderId } },
  });
  if (!member) throw Object.assign(new Error('Not a member of this chat'), { statusCode: 403 });

  const message = await prisma.message.create({
    data: { roomId, senderId, content, type, metadata },
    include: {
      sender: { select: { id: true, name: true, avatar: true } },
    },
  });

  // Update room timestamp
  await prisma.chatRoom.update({ where: { id: roomId }, data: { updatedAt: new Date() } });

  return message;
}
