"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authService = __importStar(require("../services/auth.service"));
const router = (0, express_1.Router)();
// POST /api/auth/send-otp
router.post('/send-otp', async (req, res, next) => {
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
    }
    catch (err) {
        next(err);
    }
});
// POST /api/auth/verify-otp
router.post('/verify-otp', async (req, res, next) => {
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
    }
    catch (err) {
        next(err);
    }
});
// POST /api/auth/refresh
router.post('/refresh', async (req, res, next) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            res.status(400).json({ error: 'Refresh token required' });
            return;
        }
        const tokens = await authService.refreshAccessToken(refreshToken);
        res.json(tokens);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/auth/google — Google OAuth sign-in
router.post('/google', async (req, res, next) => {
    try {
        const { idToken } = req.body;
        if (!idToken) {
            res.status(400).json({ error: 'Google ID token is required' });
            return;
        }
        const result = await authService.googleSignIn(idToken);
        res.json(result);
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=auth.routes.js.map