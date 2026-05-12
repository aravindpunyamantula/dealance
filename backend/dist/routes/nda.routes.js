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
const auth_1 = require("../middleware/auth");
const ndaService = __importStar(require("../services/nda.service"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// POST /api/nda/sign — Investor signs NDA
router.post('/sign', (0, auth_1.requireRole)('INVESTOR'), async (req, res, next) => {
    try {
        const { ideaId, signatureText } = req.body;
        if (!ideaId || !signatureText) {
            res.status(400).json({ error: 'ideaId and signatureText are required' });
            return;
        }
        if (signatureText.trim().length < 2) {
            res.status(400).json({ error: 'Please provide your full legal name' });
            return;
        }
        const result = await ndaService.signNDA(ideaId, req.userId, signatureText.trim());
        res.json(result);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/nda/check/:ideaId — Check NDA status
router.get('/check/:ideaId', (0, auth_1.requireRole)('INVESTOR'), async (req, res, next) => {
    try {
        const result = await ndaService.checkNDA(req.params.ideaId, req.userId);
        res.json(result);
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=nda.routes.js.map