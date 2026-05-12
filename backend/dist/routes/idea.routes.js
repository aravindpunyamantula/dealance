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
const ideaService = __importStar(require("../services/idea.service"));
const router = (0, express_1.Router)();
// All routes require auth
router.use(auth_1.authenticate);
// GET /api/ideas - List user's ideas
router.get('/', async (req, res, next) => {
    try {
        const ideas = await ideaService.getUserIdeas(req.userId);
        res.json(ideas);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/ideas - Create new idea
router.post('/', async (req, res, next) => {
    try {
        const idea = await ideaService.createIdea(req.userId, req.body);
        res.status(201).json(idea);
    }
    catch (err) {
        next(err);
    }
});
// GET /api/ideas/:id - Get single idea
router.get('/:id', async (req, res, next) => {
    try {
        const id = req.params.id;
        const idea = await ideaService.getIdeaById(id, req.userId);
        res.json(idea);
    }
    catch (err) {
        next(err);
    }
});
// PUT /api/ideas/:id/step/:stepNumber - Update specific step
router.put('/:id/step/:stepNumber', async (req, res, next) => {
    try {
        const id = req.params.id;
        const stepNumber = parseInt(req.params.stepNumber);
        if (isNaN(stepNumber) || stepNumber < 1 || stepNumber > 5) {
            res.status(400).json({ error: 'Step number must be 1-5' });
            return;
        }
        const idea = await ideaService.updateIdeaStep(id, req.userId, stepNumber, req.body);
        res.json(idea);
    }
    catch (err) {
        next(err);
    }
});
// POST /api/ideas/:id/submit - Submit idea
router.post('/:id/submit', async (req, res, next) => {
    try {
        const id = req.params.id;
        const idea = await ideaService.submitIdea(id, req.userId);
        res.json(idea);
    }
    catch (err) {
        next(err);
    }
});
// DELETE /api/ideas/:id - Delete idea
router.delete('/:id', async (req, res, next) => {
    try {
        const id = req.params.id;
        await ideaService.deleteIdea(id, req.userId);
        res.json({ message: 'Idea deleted' });
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=idea.routes.js.map