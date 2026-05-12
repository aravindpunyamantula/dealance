export declare function triggerAnalysis(ideaId: string, userId: string): Promise<{
    userId: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    status: string;
    ideaId: string;
    viabilityScore: number | null;
    report: string | null;
    errorMessage: string | null;
}>;
export declare function getReport(ideaId: string, userId: string): Promise<{
    parsedReport: any;
    userId: string;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    status: string;
    ideaId: string;
    viabilityScore: number | null;
    report: string | null;
    errorMessage: string | null;
}>;
export declare function getReportStatus(ideaId: string, userId: string): Promise<{
    id: string;
    createdAt: Date;
    updatedAt: Date;
    status: string;
    viabilityScore: number;
}>;
export declare function getInvestorAIReview(ideaId: string): Promise<string>;
//# sourceMappingURL=gemini.service.d.ts.map