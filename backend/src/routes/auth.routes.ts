import { Router, Request, Response, NextFunction } from 'express';
import * as authService from '../services/auth.service';

const router = Router();

// POST /api/auth/send-otp
router.post('/send-otp', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email } = req.body;

    if (!email) {
      res.status(400).json({ error: 'Email is required' });
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      res.status(400).json({ error: 'Invalid email format' });
      return;
    }

    const result = await authService.sendOtp(email);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/verify-otp
router.post('/verify-otp', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, code, name, role, phone, linkedIn, education, networth } = req.body;

    if (!email || !code) {
      res.status(400).json({ error: 'Email and OTP code are required' });
      return;
    }

    if (code.length !== 6) {
      res.status(400).json({ error: 'OTP must be 6 digits' });
      return;
    }

    const result = await authService.verifyOtp(email, code, { name, role, phone, linkedIn, education, networth });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      res.status(400).json({ error: 'Refresh token required' });
      return;
    }

    const tokens = await authService.refreshAccessToken(refreshToken);
    res.json(tokens);
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/google — Google OAuth sign-in
router.post('/google', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      res.status(400).json({ error: 'Google ID token is required' });
      return;
    }

    const result = await authService.googleSignIn(idToken);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;

