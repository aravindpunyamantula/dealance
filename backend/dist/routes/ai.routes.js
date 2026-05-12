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
const geminiService = __importStar(require("../services/gemini.service"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// POST /api/ai/analyze/:ideaId - Trigger AI analysis
router.post('/analyze/:ideaId', async (req, res, next) => {
    try {
        const ideaId = req.params.ideaId;
        const report = await geminiService.triggerAnalysis(ideaId, req.userId);
        res.json(report);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/ai/report/:ideaId - Get AI report
router.get('/report/:ideaId', async (req, res, next) => {
    try {
        const ideaId = req.params.ideaId;
        const report = await geminiService.getReport(ideaId, req.userId);
        res.json(report);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/ai/status/:ideaId - Check report status
router.get('/status/:ideaId', async (req, res, next) => {
    try {
        const ideaId = req.params.ideaId;
        const status = await geminiService.getReportStatus(ideaId, req.userId);
        res.json(status || { status: 'NOT_STARTED' });
    }
    catch (err) {
        next(err);
    }
});
// GET /api/ai/investor-review/:ideaId - Investor AI Review
router.get('/investor-review/:ideaId', async (req, res, next) => {
    try {
        if (req.userRole !== 'INVESTOR') {
            return res.status(403).json({ error: 'Only investors can access this feature' });
        }
        const ideaId = req.params.ideaId;
        const reportMarkdown = await geminiService.getInvestorAIReview(ideaId);
        res.json({ report: reportMarkdown });
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=ai.routes.js.map