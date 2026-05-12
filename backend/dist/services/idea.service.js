"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createIdea = createIdea;
exports.getUserIdeas = getUserIdeas;
exports.getIdeaById = getIdeaById;
exports.updateIdeaStep = updateIdeaStep;
exports.submitIdea = submitIdea;
exports.deleteIdea = deleteIdea;
const database_1 = __importDefault(require("../config/database"));
async function createIdea(userId, data) {
    return database_1.default.idea.create({
        data: {
            userId,
            businessType: data.businessType || 'STARTUP',
            companyName: data.companyName,
            tagline: data.tagline,
            oneLiner: data.oneLiner,
            detailedProblem: data.detailedProblem,
            solution: data.solution,
            productDescription: data.productDescription,
            status: 'DRAFT',
            currentStep: 1,
        },
    });
}
async function getUserIdeas(userId) {
    return database_1.default.idea.findMany({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        include: {
            aiReports: {
                select: { id: true, status: true, viabilityScore: true, createdAt: true },
                orderBy: { createdAt: 'desc' },
                take: 1,
            },
        },
    });
}
async function getIdeaById(ideaId, userId) {
    const idea = await database_1.default.idea.findFirst({
        where: { id: ideaId, userId },
        include: {
            aiReports: {
                orderBy: { createdAt: 'desc' },
                take: 1,
            },
        },
    });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    return idea;
}
async function updateIdeaStep(ideaId, userId, stepNumber, data) {
    // Verify ownership
    const idea = await database_1.default.idea.findFirst({ where: { id: ideaId, userId } });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    // Map step number to fields
    const updateData = {};
    switch (stepNumber) {
        case 1: // Problem & Solution
            if (data.businessType)
                updateData.businessType = data.businessType;
            if (data.oneLiner)
                updateData.oneLiner = data.oneLiner;
            if (data.detailedProblem)
                updateData.detailedProblem = data.detailedProblem;
            if (data.solution)
                updateData.solution = data.solution;
            if (data.productDescription)
                updateData.productDescription = data.productDescription;
            if (data.companyName)
                updateData.companyName = data.companyName;
            if (data.tagline)
                updateData.tagline = data.tagline;
            if (data.evidenceUrl)
                updateData.evidenceUrl = data.evidenceUrl;
            if (data.pitchDeckUrl)
                updateData.pitchDeckUrl = data.pitchDeckUrl;
            if (data.videoPitchUrl)
                updateData.videoPitchUrl = data.videoPitchUrl;
            if (data.logoUrl)
                updateData.logoUrl = data.logoUrl;
            if (data.cardUrl)
                updateData.cardUrl = data.cardUrl;
            break;
        case 2: // Market & Business
            if (data.industry)
                updateData.industry = data.industry;
            if (data.subDomains)
                updateData.subDomains = JSON.stringify(data.subDomains);
            if (data.businessModel)
                updateData.businessModel = data.businessModel;
            if (data.targetGeography)
                updateData.targetGeography = data.targetGeography;
            if (data.stage)
                updateData.stage = data.stage;
            break;
        case 3: // Traction
            if (data.currentCustomers)
                updateData.currentCustomers = data.currentCustomers;
            if (data.revenue)
                updateData.revenue = data.revenue;
            if (data.growthRate)
                updateData.growthRate = data.growthRate;
            if (data.dailyActiveUsers !== undefined)
                updateData.dailyActiveUsers = data.dailyActiveUsers;
            break;
        case 4: // Financial
            if (data.currentValuation)
                updateData.currentValuation = data.currentValuation;
            if (data.fundingAmount)
                updateData.fundingAmount = data.fundingAmount;
            if (data.fundingType)
                updateData.fundingType = data.fundingType;
            if (data.equityOffered)
                updateData.equityOffered = data.equityOffered;
            if (data.useOfFunds)
                updateData.useOfFunds = JSON.stringify(data.useOfFunds);
            break;
        case 5: // Team
            if (data.founderName)
                updateData.founderName = data.founderName;
            if (data.founderEmail)
                updateData.founderEmail = data.founderEmail;
            if (data.founderPhone)
                updateData.founderPhone = data.founderPhone;
            if (data.teamMembers)
                updateData.teamMembers = JSON.stringify(data.teamMembers);
            if (data.visibility)
                updateData.visibility = data.visibility;
            break;
        default:
            throw Object.assign(new Error('Invalid step number (1-5)'), { statusCode: 400 });
    }
    // Update current step if moving forward
    if (stepNumber > idea.currentStep) {
        updateData.currentStep = stepNumber;
    }
    return database_1.default.idea.update({
        where: { id: ideaId },
        data: updateData,
    });
}
async function submitIdea(ideaId, userId) {
    const idea = await database_1.default.idea.findFirst({ where: { id: ideaId, userId } });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    if (idea.status === 'SUBMITTED') {
        throw Object.assign(new Error('Idea already submitted'), { statusCode: 400 });
    }
    return database_1.default.idea.update({
        where: { id: ideaId },
        data: { status: 'SUBMITTED', submittedAt: new Date() },
    });
}
async function deleteIdea(ideaId, userId) {
    const idea = await database_1.default.idea.findFirst({ where: { id: ideaId, userId } });
    if (!idea) {
        throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
    }
    return database_1.default.idea.delete({ where: { id: ideaId } });
}
//# sourceMappingURL=idea.service.js.map