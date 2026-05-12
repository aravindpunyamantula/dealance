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
const dealService = __importStar(require("../services/deal.service"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// POST /api/deals — Create deal offer (investor only)
router.post('/', (0, auth_1.requireRole)('INVESTOR'), async (req, res, next) => {
    try {
        const deal = await dealService.createDeal(req.userId, req.body);
        res.status(201).json(deal);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/deals — List my deals
router.get('/', async (req, res, next) => {
    try {
        const deals = await dealService.getMyDeals(req.userId);
        res.json(deals);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/deals/:id — Get deal detail
router.get('/:id', async (req, res, next) => {
    try {
        const deal = await dealService.getDeal(req.params.id, req.userId);
        res.json(deal);
    }
    catch (err) {
        next(err);
    }
});
// PUT /api/deals/:id — Update deal terms (negotiate)
router.put('/:id', async (req, res, next) => {
    try {
        const deal = await dealService.updateDeal(req.params.id, req.userId, req.body);
        res.json(deal);
    }
    catch (err) {
        next(err);
    }
});
// PUT /api/deals/:id/accept — Accept deal
router.put('/:id/accept', async (req, res, next) => {
    try {
        const deal = await dealService.updateDealStatus(req.params.id, req.userId, 'ACCEPTED');
        res.json(deal);
    }
    catch (err) {
        next(err);
    }
});
// PUT /api/deals/:id/reject — Reject deal
router.put('/:id/reject', async (req, res, next) => {
    try {
        const deal = await dealService.updateDealStatus(req.params.id, req.userId, 'REJECTED');
        res.json(deal);
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=deal.routes.js.map