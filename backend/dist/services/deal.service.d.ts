export declare function createDeal(investorId: string, data: {
    startupId: string;
    investmentAmount?: string;
    equityOffered?: string;
    valuation?: string;
    terms?: any;
}): Promise<{
    investor: {
        name: string;
        id: string;
        avatar: string;
    };
    startup: {
        id: string;
        companyName: string;
        industry: string;
    };
    entrepreneur: {
        name: string;
        id: string;
        avatar: string;
    };
} & {
    id: string;
    createdAt: Date;
    updatedAt: Date;
    equityOffered: string | null;
    status: string;
    investorId: string;
    startupId: string;
    investmentAmount: string | null;
    valuation: string | null;
    terms: string | null;
    chatRoomId: string | null;
    entrepreneurId: string;
}>;
export declare function getMyDeals(userId: string): Promise<({
    investor: {
        name: string;
        id: string;
        avatar: string;
    };
    startup: {
        id: string;
        companyName: string;
        industry: string;
        fundingAmount: string;
    };
    entrepreneur: {
        name: string;
        id: string;
        avatar: string;
    };
} & {
    id: string;
    createdAt: Date;
    updatedAt: Date;
    equityOffered: string | null;
    status: string;
    investorId: string;
    startupId: string;
    investmentAmount: string | null;
    valuation: string | null;
    terms: string | null;
    chatRoomId: string | null;
    entrepreneurId: string;
})[]>;
export declare function getDeal(dealId: string, userId: string): Promise<{
    investor: {
        name: string;
        id: string;
        email: string;
        avatar: string;
    };
    startup: {
        id: string;
        companyName: string;
        industry: string;
        fundingAmount: string;
        equityOffered: string;
    };
    entrepreneur: {
        name: string;
        id: string;
        email: string;
        avatar: string;
    };
} & {
    id: string;
    createdAt: Date;
    updatedAt: Date;
    equityOffered: string | null;
    status: string;
    investorId: string;
    startupId: string;
    investmentAmount: string | null;
    valuation: string | null;
    terms: string | null;
    chatRoomId: string | null;
    entrepreneurId: string;
}>;
export declare function updateDeal(dealId: string, userId: string, data: {
    investmentAmount?: string;
    equityOffered?: string;
    valuation?: string;
    terms?: any;
}): Promise<{
    investor: {
        name: string;
        id: string;
    };
    startup: {
        id: string;
        companyName: string;
    };
    entrepreneur: {
        name: string;
        id: string;
    };
} & {
    id: string;
    createdAt: Date;
    updatedAt: Date;
    equityOffered: string | null;
    status: string;
    investorId: string;
    startupId: string;
    investmentAmount: string | null;
    valuation: string | null;
    terms: string | null;
    chatRoomId: string | null;
    entrepreneurId: string;
}>;
export declare function updateDealStatus(dealId: string, userId: string, status: 'ACCEPTED' | 'REJECTED'): Promise<{
    investor: {
        name: string;
        id: string;
    };
    startup: {
        id: string;
        companyName: string;
    };
    entrepreneur: {
        name: string;
        id: string;
    };
} & {
    id: string;
    createdAt: Date;
    updatedAt: Date;
    equityOffered: string | null;
    status: string;
    investorId: string;
    startupId: string;
    investmentAmount: string | null;
    valuation: string | null;
    terms: string | null;
    chatRoomId: string | null;
    entrepreneurId: string;
}>;
//# sourceMappingURL=deal.service.d.ts.map