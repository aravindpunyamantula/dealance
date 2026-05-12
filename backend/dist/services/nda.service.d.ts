/**
 * Sign an NDA for an idea.
 */
export declare function signNDA(ideaId: string, investorId: string, signatureText: string): Promise<{
    message: string;
    signature: {
        id: string;
        ideaId: string;
        investorId: string;
        signatureText: string;
        signedAt: Date;
    };
}>;
/**
 * Check if investor has signed NDA for an idea.
 */
export declare function checkNDA(ideaId: string, investorId: string): Promise<{
    signed: boolean;
    signature: {
        id: string;
        ideaId: string;
        investorId: string;
        signatureText: string;
        signedAt: Date;
    };
}>;
/**
 * Invite an investor to an INVITE_ONLY idea (called by entrepreneur).
 */
export declare function inviteInvestor(ideaId: string, entrepreneurId: string, investorId: string): Promise<{
    message: string;
    access: {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: string;
        ideaId: string;
        investorId: string;
    };
}>;
/**
 * Get list of investors for directory (searchable).
 */
export declare function getInvestorDirectory(search?: string): Promise<{
    name: string;
    id: string;
    email: string;
    avatar: string;
    bio: string;
    linkedIn: string;
    verified: boolean;
}[]>;
/**
 * Get investors already invited to an idea.
 */
export declare function getInvitedInvestors(ideaId: string, entrepreneurId: string): Promise<({
    investor: {
        name: string;
        id: string;
        email: string;
        avatar: string;
    };
} & {
    id: string;
    createdAt: Date;
    updatedAt: Date;
    status: string;
    ideaId: string;
    investorId: string;
})[]>;
//# sourceMappingURL=nda.service.d.ts.map