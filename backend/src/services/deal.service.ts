import prisma from '../config/database';

// ─── CREATE DEAL OFFER ───
export async function createDeal(investorId: string, data: {
  startupId: string;
  investmentAmount?: string;
  equityOffered?: string;
  valuation?: string;
  terms?: any;
}) {
  // Get startup and verify it exists + is submitted
  const startup = await prisma.idea.findFirst({
    where: { id: data.startupId, status: 'SUBMITTED' },
  });
  if (!startup) throw Object.assign(new Error('Startup not found'), { statusCode: 404 });

  // Create a chat room for this deal negotiation
  const chatRoom = await prisma.chatRoom.create({
    data: {
      type: 'DEAL',
      members: {
        create: [
          { userId: investorId },
          { userId: startup.userId },
        ],
      },
    },
  });

  return prisma.deal.create({
    data: {
      startupId: data.startupId,
      investorId,
      entrepreneurId: startup.userId,
      investmentAmount: data.investmentAmount,
      equityOffered: data.equityOffered,
      valuation: data.valuation,
      terms: data.terms ? JSON.stringify(data.terms) : null,
      chatRoomId: chatRoom.id,
      status: 'PROPOSED',
    },
    include: {
      startup: { select: { id: true, companyName: true, industry: true } },
      investor: { select: { id: true, name: true, avatar: true } },
      entrepreneur: { select: { id: true, name: true, avatar: true } },
    },
  });
}

// ─── GET MY DEALS ───
export async function getMyDeals(userId: string) {
  return prisma.deal.findMany({
    where: { OR: [{ investorId: userId }, { entrepreneurId: userId }] },
    orderBy: { updatedAt: 'desc' },
    include: {
      startup: { select: { id: true, companyName: true, industry: true, fundingAmount: true } },
      investor: { select: { id: true, name: true, avatar: true } },
      entrepreneur: { select: { id: true, name: true, avatar: true } },
    },
  });
}

// ─── GET DEAL ───
export async function getDeal(dealId: string, userId: string) {
  const deal = await prisma.deal.findFirst({
    where: { id: dealId, OR: [{ investorId: userId }, { entrepreneurId: userId }] },
    include: {
      startup: { select: { id: true, companyName: true, industry: true, fundingAmount: true, equityOffered: true } },
      investor: { select: { id: true, name: true, avatar: true, email: true } },
      entrepreneur: { select: { id: true, name: true, avatar: true, email: true } },
    },
  });
  if (!deal) throw Object.assign(new Error('Deal not found'), { statusCode: 404 });
  return deal;
}

// ─── UPDATE DEAL (NEGOTIATE) ───
export async function updateDeal(dealId: string, userId: string, data: {
  investmentAmount?: string;
  equityOffered?: string;
  valuation?: string;
  terms?: any;
}) {
  const deal = await prisma.deal.findFirst({
    where: { id: dealId, OR: [{ investorId: userId }, { entrepreneurId: userId }] },
  });
  if (!deal) throw Object.assign(new Error('Deal not found'), { statusCode: 404 });

  return prisma.deal.update({
    where: { id: dealId },
    data: {
      status: 'NEGOTIATING',
      ...(data.investmentAmount && { investmentAmount: data.investmentAmount }),
      ...(data.equityOffered && { equityOffered: data.equityOffered }),
      ...(data.valuation && { valuation: data.valuation }),
      ...(data.terms && { terms: JSON.stringify(data.terms) }),
    },
    include: {
      startup: { select: { id: true, companyName: true } },
      investor: { select: { id: true, name: true } },
      entrepreneur: { select: { id: true, name: true } },
    },
  });
}

// ─── ACCEPT/REJECT DEAL ───
export async function updateDealStatus(dealId: string, userId: string, status: 'ACCEPTED' | 'REJECTED') {
  const deal = await prisma.deal.findFirst({
    where: { id: dealId, OR: [{ investorId: userId }, { entrepreneurId: userId }] },
  });
  if (!deal) throw Object.assign(new Error('Deal not found'), { statusCode: 404 });

  return prisma.deal.update({
    where: { id: dealId },
    data: { status },
    include: {
      startup: { select: { id: true, companyName: true } },
      investor: { select: { id: true, name: true } },
      entrepreneur: { select: { id: true, name: true } },
    },
  });
}
