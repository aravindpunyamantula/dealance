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
const feedService = __importStar(require("../services/feed.service"));
const router = (0, express_1.Router)();
// All routes require auth + INVESTOR role
router.use(auth_1.authenticate);
router.use((0, auth_1.requireRole)('INVESTOR'));
// GET /api/feed — Investor deal flow feed
router.get('/', async (req, res, next) => {
    try {
        const feed = await feedService.getDealFlowFeed(req.userId);
        res.json(feed);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/feed/:ideaId — Full idea details (with access check)
router.get('/:ideaId', async (req, res, next) => {
    try {
        const idea = await feedService.getIdeaForInvestor(req.params.ideaId, req.userId);
        res.json(idea);
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=feed.routes.js.map