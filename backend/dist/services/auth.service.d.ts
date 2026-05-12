export interface TokenPair {
    accessToken: string;
    refreshToken: string;
}
/**
 * Send OTP to email.
 * For MVP: logs OTP to console. In production: integrate email service.
 */
export declare function sendOtp(email: string): Promise<{
    message: string;
    email: string;
}>;
/**
 * Verify OTP and authenticate user.
 * Creates a new user if email doesn't exist.
 */
export declare function verifyOtp(email: string, code: string, userData?: {
    name?: string;
    role?: string;
    phone?: string;
    linkedIn?: string;
    education?: string;
    networth?: string;
}): Promise<{
    accessToken: string;
    refreshToken: string;
    user: {
        role: string;
        name: string;
        id: string;
        email: string;
        avatar: string;
        createdAt: Date;
    };
    isNewUser: boolean;
}>;
export declare function refreshAccessToken(refreshToken: string): Promise<TokenPair>;
/**
 * Google OAuth sign-in.
 * Validates Google ID token, creates or finds user, returns JWT tokens.
 */
export declare function googleSignIn(idToken: string): Promise<{
    accessToken: string;
    refreshToken: string;
    user: {
        role: string;
        name: string;
        id: string;
        email: string;
        avatar: string;
        createdAt: Date;
    };
    isNewUser: boolean;
}>;
//# sourceMappingURL=auth.service.d.ts.map