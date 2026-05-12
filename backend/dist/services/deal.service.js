"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDeal = createDeal;
exports.getMyDeals = getMyDeals;
exports.getDeal = getDeal;
exports.updateDeal = updateDeal;
exports.updateDealStatus = updateDealStatus;
const database_1 = __importDefault(require("../config/database"));
// ─── CREATE DEAL OFFER ───
async function createDeal(investorId, data) {
    // Get startup and verify it exists + is submitted
    const startup = await database_1.default.idea.findFirst({
        where: { id: data.startupId, status: 'SUBMITTED' },
    });
    if (!startup)
        throw Object.assign(new Error('Startup not found'), { statusCode: 404 });
    // Create a chat room for this deal negotiation
    const chatRoom = await database_1.default.chatRoom.create({
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
    return database_1.default.deal.create({
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
async function getMyDeals(userId) {
    return database_1.default.deal.findMany({
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
async function getDeal(dealId, userId) {
    const deal = await database_1.default.deal.findFirst({
        where: { id: dealId, OR: [{ investorId: userId }, { entrepreneurId: userId }] },
        include: {
            startup: { select: { id: true, companyName: true, industry: true, fundingAmount: true, equityOffered: true } },
            investor: { select: { id: true, name: true, avatar: true, email: true } },
            entrepreneur: { select: { id: true, name: true, avatar: true, email: true } },
        },
    });
    if (!deal)
        throw Object.assign(new Error('Deal not found'), { statusCode: 404 });
    return deal;
}
// ─── UPDATE DEAL (NEGOTIATE) ───
async function updateDeal(dealId, userId, data) {
    const deal = await database_1.default.deal.findFirst({
        where: { id: dealId, OR: [{ investorId: userId }, { entrepreneurId: userId }] },
    });
    if (!deal)
        throw Object.assign(new Error('Deal not found'), { statusCode: 404 });
    return database_1.default.deal.update({
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
async function updateDealStatus(dealId, userId, status) {
    const deal = await database_1.default.deal.findFirst({
        where: { id: dealId, OR: [{ investorId: userId }, { entrepreneurId: userId }] },
    });
    if (!deal)
        throw Object.assign(new Error('Deal not found'), { statusCode: 404 });
    return database_1.default.deal.update({
        where: { id: dealId },
        data: { status },
        include: {
            startup: { select: { id: true, companyName: true } },
            investor: { select: { id: true, name: true } },
            entrepreneur: { select: { id: true, name: true } },
        },
    });
}
//# sourceMappingURL=deal.service.js.map