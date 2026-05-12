"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.signNDA = signNDA;
exports.checkNDA = checkNDA;
exports.inviteInvestor = inviteInvestor;
exports.getInvestorDirectory = getInvestorDirectory;
exports.getInvitedInvestors = getInvitedInvestors;
const database_1 = __importDefault(require("../config/database"));
/**
 * Sign an NDA for an idea.
 */
async function signNDA(ideaId, investorId, signatureText) {
    // Verify idea exists and requires NDA
    const idea = await database_1.default.idea.findFirst({
        where: { id: ideaId, status: 'SUBMITTED', visibility: 'NDA_REQUIRED' },
    });
    if (!idea) {
        throw Object.assign(new Error('Idea not found or does not require NDA'), { statusCode: 404 });
    }
    // Check if already signed
    const existing = await database_1.default.nDASignature.findUnique({
        where: { ideaId_investorId: { ideaId, investorId } },
    });
    if (existing) {
        return { message: 'NDA already signed', signature: existing };
    }
    // Create NDA signature
    const signature = await database_1.default.nDASignature.create({
        data: {
            ideaId,
            investorId,
            signatureText,
        },
    });
    // Notify the entrepreneur
    await database_1.default.notification.create({
        data: {
            userId: idea.userId,
            type: 'INVESTOR_VIEW',
            title: 'NDA Signed',
            message: `An investor has signed the NDA for your idea "${idea.companyName || idea.oneLiner || 'Untitled'}"`,
            data: JSON.stringify({ ideaId, investorId }),
        },
    });
    return { message: 'NDA signed successfully', signature };
}
/**
 * Check if investor has signed NDA for an idea.
 */
async function checkNDA(ideaId, investorId) {
    const signature = await database_1.default.nDASignature.findUnique({
        where: { ideaId_investorId: { ideaId, investorId } },
    });
    return { signed: !!signature, signature };
}
/**
 * Invite an investor to an INVITE_ONLY idea (called by entrepreneur).
 */
async function inviteInvestor(ideaId, entrepreneurId, investorId) {
    // Verify idea ownership
    const idea = await database_1.default.idea.findFirst({
        where: { id: ideaId, userId: entrepreneurId },
    });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    // Check if already invited
    const existing = await database_1.default.ideaAccess.findUnique({
        where: { ideaId_investorId: { ideaId, investorId } },
    });
    if (existing) {
        return { message: 'Investor already invited', access: existing };
    }
    // Create access record
    const access = await database_1.default.ideaAccess.create({
        data: {
            ideaId,
            investorId,
            status: 'INVITED',
        },
    });
    // Notify investor
    await database_1.default.notification.create({
        data: {
            userId: investorId,
            type: 'INVESTOR_VIEW',
            title: 'New Deal Invitation',
            message: `You've been invited to view "${idea.companyName || idea.oneLiner || 'an idea'}"`,
            data: JSON.stringify({ ideaId }),
        },
    });
    return { message: 'Investor invited successfully', access };
}
/**
 * Get list of investors for directory (searchable).
 */
async function getInvestorDirectory(search) {
    const where = { role: 'INVESTOR' };
    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
            { bio: { contains: search, mode: 'insensitive' } },
        ];
    }
    return database_1.default.user.findMany({
        where,
        select: {
            id: true,
            name: true,
            email: true,
            avatar: true,
            bio: true,
            linkedIn: true,
            verified: true,
        },
        orderBy: { name: 'asc' },
        take: 50,
    });
}
/**
 * Get investors already invited to an idea.
 */
async function getInvitedInvestors(ideaId, entrepreneurId) {
    // Verify ownership
    const idea = await database_1.default.idea.findFirst({
        where: { id: ideaId, userId: entrepreneurId },
    });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    return database_1.default.ideaAccess.findMany({
        where: { ideaId },
        include: {
            investor: {
                select: { id: true, name: true, email: true, avatar: true },
            },
        },
        orderBy: { createdAt: 'desc' },
    });
}
//# sourceMappingURL=nda.service.js.map