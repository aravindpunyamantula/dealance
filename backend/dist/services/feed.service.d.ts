/**
 * Get deal flow feed for an investor.
 * - PUBLIC ideas: full details
 * - NDA_REQUIRED ideas: redacted (only teaser info) unless NDA is signed
 * - INVITE_ONLY ideas: only if investor has been invited
 */
export declare function getDealFlowFeed(investorId: string): Promise<{
    id: string;
    companyName: string;
    industry: string;
    tagline: string;
    stage: string;
    visibility: string;
    status: string;
    submittedAt: Date;
    createdAt: Date;
    ndaSigned: boolean;
    oneLiner: any;
    detailedProblem: any;
    solution: any;
    productDescription: any;
    businessModel: any;
    fundingAmount: string;
    fundingType: string;
    equityOffered: any;
    pitchDeckUrl: any;
    videoPitchUrl: any;
    evidenceUrl: any;
    user: {
        name: string;
        id: string;
        avatar: string;
        linkedIn: string;
        instagram: string;
        twitter: string;
        website: string;
    };
    aiScore: number;
}[]>;
/**
 * Get full idea details for investor (checks access rights).
 */
export declare function getIdeaForInvestor(ideaId: string, investorId: string): Promise<{
    aiReports: {
        userId: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: string;
        ideaId: string;
        viabilityScore: number | null;
        report: string | null;
        errorMessage: string | null;
    }[];
    user: {
        name: string;
        id: string;
        email: string;
        avatar: string;
        bio: string;
        phone: string;
        linkedIn: string;
        instagram: string;
        twitter: string;
        website: string;
    };
} & {
    userId: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    businessType: string;
    companyName: string | null;
    tagline: string | null;
    logoUrl: string | null;
    cardUrl: string | null;
    oneLiner: string | null;
    detailedProblem: string | null;
    solution: string | null;
    evidenceUrl: string | null;
    pitchDeckUrl: string | null;
    videoPitchUrl: string | null;
    productDescription: string | null;
    industry: string | null;
    subDomains: string | null;
    businessModel: string | null;
    targetGeography: string | null;
    stage: string | null;
    currentCustomers: string | null;
    revenue: string | null;
    growthRate: string | null;
    dailyActiveUsers: number | null;
    currentValuation: string | null;
    fundingAmount: string | null;
    fundingType: string | null;
    equityOffered: string | null;
    useOfFunds: string | null;
    founderName: string | null;
    founderEmail: string | null;
    founderPhone: string | null;
    teamMembers: string | null;
    status: string;
    currentStep: number;
    submittedAt: Date | null;
    visibility: string;
}>;
//# sourceMappingURL=feed.service.d.ts.map