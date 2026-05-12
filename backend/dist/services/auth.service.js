"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendOtp = sendOtp;
exports.verifyOtp = verifyOtp;
exports.refreshAccessToken = refreshAccessToken;
exports.googleSignIn = googleSignIn;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const uuid_1 = require("uuid");
const database_1 = __importDefault(require("../config/database"));
const redis_1 = require("./redis");
const nodemailer_1 = __importDefault(require("nodemailer"));
const JWT_SECRET = process.env.JWT_SECRET || 'dealance-dev-jwt-secret-2026';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dealance-dev-refresh-secret-2026';
const OTP_TTL = 300; // 5 minutes
function generateTokens(userId, role) {
    const accessToken = jsonwebtoken_1.default.sign({ userId, role }, JWT_SECRET, { expiresIn: 3600 } // 1 hour
    );
    const refreshToken = jsonwebtoken_1.default.sign({ userId, tokenId: (0, uuid_1.v4)() }, JWT_REFRESH_SECRET, { expiresIn: 604800 } // 7 days
    );
    return { accessToken, refreshToken };
}
function generateOtpCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}
/**
 * Send OTP to email.
 * For MVP: logs OTP to console. In production: integrate email service.
 */
async function sendOtp(email) {
    const code = generateOtpCode();
    const key = `otp:${email.toLowerCase().trim()}`;
    // Store in Redis/memory with 5 min TTL
    await (0, redis_1.setOtp)(key, code, OTP_TTL);
    // For MVP — log to console. In production, send via email service (SendGrid, SES, etc.)
    console.log(`\n📧 OTP for ${email}: ${code}\n`);
    // Send real email if SMTP is configured
    if (process.env.SMTP_USER && process.env.SMTP_PASS && process.env.SMTP_USER !== 'your-email@gmail.com') {
        try {
            const transporter = nodemailer_1.default.createTransport({
                host: process.env.SMTP_HOST || 'smtp.gmail.com',
                port: parseInt(process.env.SMTP_PORT || '587'),
                secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
                auth: {
                    user: process.env.SMTP_USER,
                    pass: process.env.SMTP_PASS,
                },
                connectionTimeout: 10000, // 10 seconds
                greetingTimeout: 10000, // 10 seconds
                socketTimeout: 20000, // 20 seconds
            });
            await transporter.sendMail({
                from: process.env.EMAIL_FROM || '"Dealance" <noreply@dealance.com>',
                to: email,
                subject: 'Your Dealance Verification Code',
                text: `Your Dealance verification code is: ${code}\n\nThis code will expire in 5 minutes.`,
                html: `
          <div style="font-family: sans-serif; padding: 20px;">
            <h2>Dealance Verification</h2>
            <p>Your verification code is:</p>
            <h1 style="color: #EFBA8F; letter-spacing: 5px;">${code}</h1>
            <p>This code will expire in 5 minutes.</p>
          </div>
        `,
            });
            console.log(`✉️  Real email sent successfully to ${email}`);
        }
        catch (err) {
            console.error(`❌ Failed to send email to ${email}:`, err.message);
        }
    }
    return { message: 'OTP sent successfully', email: email.toLowerCase().trim() };
}
/**
 * Verify OTP and authenticate user.
 * Creates a new user if email doesn't exist.
 */
async function verifyOtp(email, code, userData) {
    const normalizedEmail = email.toLowerCase().trim();
    const key = `otp:${normalizedEmail}`;
    // Get stored OTP
    const storedCode = await (0, redis_1.getOtp)(key);
    if (!storedCode) {
        throw Object.assign(new Error('OTP expired or not found. Please request a new one.'), { statusCode: 400 });
    }
    if (storedCode !== code) {
        throw Object.assign(new Error('Invalid OTP code'), { statusCode: 401 });
    }
    // OTP valid — delete it
    await (0, redis_1.deleteOtp)(key);
    // Find or create user
    let user = await database_1.default.user.findUnique({
        where: { email: normalizedEmail },
        select: { id: true, name: true, email: true, role: true, avatar: true, createdAt: true },
    });
    let isNewUser = false;
    if (!user) {
        // New user — create account
        isNewUser = true;
        user = await database_1.default.user.create({
            data: {
                name: userData?.name || normalizedEmail.split('@')[0], // fallback name from email
                email: normalizedEmail,
                passwordHash: '', // no password needed for OTP auth
                role: userData?.role || 'ENTREPRENEUR',
                phone: userData?.phone,
                linkedIn: userData?.linkedIn,
                education: userData?.education,
                networth: userData?.networth,
            },
            select: { id: true, name: true, email: true, role: true, avatar: true, createdAt: true },
        });
    }
    // Generate tokens
    const tokens = generateTokens(user.id, user.role);
    // Store refresh token
    await database_1.default.refreshToken.create({
        data: {
            token: tokens.refreshToken,
            userId: user.id,
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        },
    });
    return { user, isNewUser, ...tokens };
}
async function refreshAccessToken(refreshToken) {
    const decoded = jsonwebtoken_1.default.verify(refreshToken, JWT_REFRESH_SECRET);
    const storedToken = await database_1.default.refreshToken.findUnique({
        where: { token: refreshToken },
        include: { user: true },
    });
    if (!storedToken || storedToken.expiresAt < new Date()) {
        throw Object.assign(new Error('Invalid refresh token'), { statusCode: 401 });
    }
    // Delete old refresh token (rotation)
    await database_1.default.refreshToken.delete({ where: { id: storedToken.id } });
    // Generate new tokens
    const tokens = generateTokens(decoded.userId, storedToken.user.role);
    // Store new refresh token
    await database_1.default.refreshToken.create({
        data: {
            token: tokens.refreshToken,
            userId: decoded.userId,
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        },
    });
    return tokens;
}
/**
 * Google OAuth sign-in.
 * Validates Google ID token, creates or finds user, returns JWT tokens.
 */
async function googleSignIn(idToken) {
    // Verify the Google ID token by calling Google's tokeninfo endpoint
    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    if (!response.ok) {
        throw Object.assign(new Error('Invalid Google token'), { statusCode: 401 });
    }
    const payload = await response.json();
    const { email, name, picture } = payload;
    if (!email) {
        throw Object.assign(new Error('Google account has no email'), { statusCode: 400 });
    }
    const normalizedEmail = email.toLowerCase().trim();
    // Find or create user
    let user = await database_1.default.user.findUnique({
        where: { email: normalizedEmail },
        select: { id: true, name: true, email: true, role: true, avatar: true, createdAt: true },
    });
    let isNewUser = false;
    if (!user) {
        isNewUser = true;
        user = await database_1.default.user.create({
            data: {
                name: name || normalizedEmail.split('@')[0],
                email: normalizedEmail,
                passwordHash: '', // no password for OAuth
                avatar: picture || null,
                role: 'ENTREPRENEUR', // default role, can be changed later
            },
            select: { id: true, name: true, email: true, role: true, avatar: true, createdAt: true },
        });
    }
    // Generate tokens
    const tokens = generateTokens(user.id, user.role);
    // Store refresh token
    await database_1.default.refreshToken.create({
        data: {
            token: tokens.refreshToken,
            userId: user.id,
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        },
    });
    return { user, isNewUser, ...tokens };
}
//# sourceMappingURL=auth.service.js.map