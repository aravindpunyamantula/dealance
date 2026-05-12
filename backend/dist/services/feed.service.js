"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDealFlowFeed = getDealFlowFeed;
exports.getIdeaForInvestor = getIdeaForInvestor;
const database_1 = __importDefault(require("../config/database"));
/**
 * Get deal flow feed for an investor.
 * - PUBLIC ideas: full details
 * - NDA_REQUIRED ideas: redacted (only teaser info) unless NDA is signed
 * - INVITE_ONLY ideas: only if investor has been invited
 */
async function getDealFlowFeed(investorId) {
    // Get all submitted ideas that are either PUBLIC or NDA_REQUIRED
    const publicAndNdaIdeas = await database_1.default.idea.findMany({
        where: {
            status: 'SUBMITTED',
            visibility: { in: ['PUBLIC', 'NDA_REQUIRED'] },
        },
        include: {
            user: {
                select: {
                    id: true, name: true, avatar: true,
                    linkedIn: true, twitter: true, instagram: true, website: true,
                },
            },
            aiReports: {
                where: { status: 'COMPLETE' },
                select: { viabilityScore: true },
                orderBy: { createdAt: 'desc' },
                take: 1,
            },
            ndaSignatures: {
                where: { investorId },
                select: { id: true },
                take: 1,
            },
        },
        orderBy: { submittedAt: 'desc' },
    });
    // Get INVITE_ONLY ideas where this investor has been invited
    const invitedIdeas = await database_1.default.idea.findMany({
        where: {
            status: 'SUBMITTED',
            visibility: 'INVITE_ONLY',
            accessList: {
                some: { investorId, status: 'INVITED' },
            },
        },
        include: {
            user: {
                select: {
                    id: true, name: true, avatar: true,
                    linkedIn: true, twitter: true, instagram: true, website: true,
                },
            },
            aiReports: {
                where: { status: 'COMPLETE' },
                select: { viabilityScore: true },
                orderBy: { createdAt: 'desc' },
                take: 1,
            },
        },
        orderBy: { submittedAt: 'desc' },
    });
    // Redact NDA_REQUIRED ideas that haven't been signed
    const feed = publicAndNdaIdeas.map((idea) => {
        const hasSigned = idea.ndaSignatures.length > 0;
        if (idea.visibility === 'NDA_REQUIRED' && !hasSigned) {
            // Return redacted version — only teaser info
            return {
                id: idea.id,
                companyName: idea.companyName,
                industry: idea.industry,
                tagline: idea.tagline,
                stage: idea.stage,
                visibility: idea.visibility,
                status: idea.status,
                submittedAt: idea.submittedAt,
                createdAt: idea.createdAt,
                ndaSigned: false,
                // Redact sensitive fields
                oneLiner: null,
                detailedProblem: null,
                solution: null,
                productDescription: null,
                businessModel: null,
                fundingAmount: idea.fundingAmount, // Show the ask but not details
                fundingType: idea.fundingType,
                equityOffered: null,
                pitchDeckUrl: null,
                videoPitchUrl: null,
                evidenceUrl: null,
                user: idea.user,
                aiScore: idea.aiReports[0]?.viabilityScore ?? null,
            };
        }
        return {
            ...idea,
            ndaSigned: hasSigned,
            aiScore: idea.aiReports[0]?.viabilityScore ?? null,
        };
    });
    // Add invited ideas (full access)
    const invitedFeed = invitedIdeas.map((idea) => ({
        ...idea,
        ndaSigned: true, // Invited = full access
        aiScore: idea.aiReports[0]?.viabilityScore ?? null,
    }));
    return [...feed, ...invitedFeed];
}
/**
 * Get full idea details for investor (checks access rights).
 */
async function getIdeaForInvestor(ideaId, investorId) {
    const idea = await database_1.default.idea.findFirst({
        where: { id: ideaId, status: 'SUBMITTED' },
        include: {
            user: {
                select: {
                    id: true, name: true, email: true, avatar: true, bio: true,
                    linkedIn: true, twitter: true, instagram: true, website: true, phone: true,
                },
            },
            aiReports: {
                where: { status: 'COMPLETE' },
                orderBy: { createdAt: 'desc' },
                take: 1,
            },
        },
    });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    // Check access rights
    if (idea.visibility === 'INVITE_ONLY') {
        const access = await database_1.default.ideaAccess.findUnique({
            where: { ideaId_investorId: { ideaId, investorId } },
        });
        if (!access) {
            throw Object.assign(new Error('You do not have access to this idea'), { statusCode: 403 });
        }
    }
    if (idea.visibility === 'NDA_REQUIRED') {
        const nda = await database_1.default.nDASignature.findUnique({
            where: { ideaId_investorId: { ideaId, investorId } },
        });
        if (!nda) {
            throw Object.assign(new Error('NDA signature required to view this idea'), { statusCode: 403 });
        }
    }
    return idea;
}
//# sourceMappingURL=feed.service.js.map