import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../config/database';
import { setOtp, getOtp, deleteOtp } from './redis';
import { emailService } from './email.service';

const JWT_SECRET = process.env.JWT_SECRET || 'dealance-dev-jwt-secret-2026';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'dealance-dev-refresh-secret-2026';
const OTP_TTL = 300; // 5 minutes

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

function generateTokens(userId: string, role: string): TokenPair {
  const accessToken = jwt.sign(
    { userId, role },
    JWT_SECRET,
    { expiresIn: 3600 } // 1 hour
  );

  const refreshToken = jwt.sign(
    { userId, tokenId: uuidv4() },
    JWT_REFRESH_SECRET,
    { expiresIn: 604800 } // 7 days
  );

  return { accessToken, refreshToken };
}

function generateOtpCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Send OTP to email.
 * For MVP: logs OTP to console. In production: integrate email service.
 */
export async function sendOtp(email: string) {
  const code = generateOtpCode();
  const key = `otp:${email.toLowerCase().trim()}`;

  // Store in Redis/memory with 5 min TTL
  await setOtp(key, code, OTP_TTL);

  // For MVP — log to console. In production, send via email service (SendGrid, SES, etc.)
  console.log(`\n📧 OTP for ${email}: ${code}\n`);

  // Send real email asynchronously (fire-and-forget)
  // This prevents SMTP connection timeouts from blocking the API response
  emailService.sendOtpEmail(email, code);

  return { message: 'OTP sent successfully', email: email.toLowerCase().trim() };
}

/**
 * Verify OTP and authenticate user.
 * Creates a new user if email doesn't exist.
 */
export async function verifyOtp(email: string, code: string, userData?: { name?: string, role?: string, phone?: string, linkedIn?: string, education?: string, networth?: string }) {
  const normalizedEmail = email.toLowerCase().trim();
  const key = `otp:${normalizedEmail}`;

  // Get stored OTP
  const storedCode = await getOtp(key);

  if (!storedCode) {
    throw Object.assign(new Error('OTP expired or not found. Please request a new one.'), { statusCode: 400 });
  }

  if (storedCode !== code) {
    throw Object.assign(new Error('Invalid OTP code'), { statusCode: 401 });
  }

  // OTP valid — delete it
  await deleteOtp(key);

  // Find or create user
  let user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    select: { id: true, name: true, email: true, role: true, avatar: true, createdAt: true },
  });

  let isNewUser = false;

  if (!user) {
    // New user — create account
    isNewUser = true;
    user = await prisma.user.create({
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
  await prisma.refreshToken.create({
    data: {
      token: tokens.refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { user, isNewUser, ...tokens };
}

export async function refreshAccessToken(refreshToken: string) {
  const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET) as { userId: string };

  const storedToken = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
    include: { user: true },
  });

  if (!storedToken || storedToken.expiresAt < new Date()) {
    throw Object.assign(new Error('Invalid refresh token'), { statusCode: 401 });
  }

  // Delete old refresh token (rotation)
  await prisma.refreshToken.delete({ where: { id: storedToken.id } });

  // Generate new tokens
  const tokens = generateTokens(decoded.userId, storedToken.user.role);

  // Store new refresh token
  await prisma.refreshToken.create({
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
export async function googleSignIn(idToken: string) {
  // Verify the Google ID token by calling Google's tokeninfo endpoint
  const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
  
  if (!response.ok) {
    throw Object.assign(new Error('Invalid Google token'), { statusCode: 401 });
  }

  const payload: any = await response.json();
  const { email, name, picture } = payload;

  if (!email) {
    throw Object.assign(new Error('Google account has no email'), { statusCode: 400 });
  }

  const normalizedEmail = email.toLowerCase().trim();

  // Find or create user
  let user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    select: { id: true, name: true, email: true, role: true, avatar: true, createdAt: true },
  });

  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    user = await prisma.user.create({
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
  await prisma.refreshToken.create({
    data: {
      token: tokens.refreshToken,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { user, isNewUser, ...tokens };
}

