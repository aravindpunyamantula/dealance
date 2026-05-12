"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const upload_1 = require("../middleware/upload");
const s3_1 = require("../config/s3");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const router = (0, express_1.Router)();
router.use(auth_1.authenticate);
// For MVP: if S3 is not configured, save files locally
const LOCAL_UPLOAD_DIR = path_1.default.join(__dirname, '../../uploads');
// Ensure upload directory exists
if (!fs_1.default.existsSync(LOCAL_UPLOAD_DIR)) {
    fs_1.default.mkdirSync(LOCAL_UPLOAD_DIR, { recursive: true });
}
// POST /api/upload - Upload a file
router.post('/', upload_1.upload.single('file'), async (req, res, next) => {
    try {
        if (!req.file) {
            res.status(400).json({ error: 'No file provided' });
            return;
        }
        const folder = req.body.folder || 'uploads';
        const fileKey = (0, upload_1.generateFileKey)(req.file.originalname, folder);
        let fileUrl;
        // Try S3 upload, fallback to local
        try {
            if (process.env.S3_ACCESS_KEY && process.env.S3_ACCESS_KEY !== 'minioadmin') {
                fileUrl = await (0, s3_1.uploadToS3)(fileKey, req.file.buffer, req.file.mimetype);
            }
            else {
                throw new Error('Using local storage');
            }
        }
        catch {
            // Local fallback: save to disk
            const localPath = path_1.default.join(LOCAL_UPLOAD_DIR, fileKey);
            const dir = path_1.default.dirname(localPath);
            if (!fs_1.default.existsSync(dir)) {
                fs_1.default.mkdirSync(dir, { recursive: true });
            }
            fs_1.default.writeFileSync(localPath, req.file.buffer);
            fileUrl = `/uploads/${fileKey}`;
        }
        res.json({
            url: fileUrl,
            key: fileKey,
            originalName: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
        });
    }
    catch (err) {
        next(err);
    }
});
// POST /api/upload/multiple - Upload multiple files
router.post('/multiple', upload_1.upload.array('files', 10), async (req, res, next) => {
    try {
        const files = req.files;
        if (!files || files.length === 0) {
            res.status(400).json({ error: 'No files provided' });
            return;
        }
        const folder = req.body.folder || 'uploads';
        const results = [];
        for (const file of files) {
            const fileKey = (0, upload_1.generateFileKey)(file.originalname, folder);
            let fileUrl;
            try {
                if (process.env.S3_ACCESS_KEY && process.env.S3_ACCESS_KEY !== 'minioadmin') {
                    fileUrl = await (0, s3_1.uploadToS3)(fileKey, file.buffer, file.mimetype);
                }
                else {
                    throw new Error('Using local storage');
                }
            }
            catch {
                const localPath = path_1.default.join(LOCAL_UPLOAD_DIR, fileKey);
                const dir = path_1.default.dirname(localPath);
                if (!fs_1.default.existsSync(dir)) {
                    fs_1.default.mkdirSync(dir, { recursive: true });
                }
                fs_1.default.writeFileSync(localPath, file.buffer);
                fileUrl = `/uploads/${fileKey}`;
            }
            results.push({
                url: fileUrl,
                key: fileKey,
                originalName: file.originalname,
                mimetype: file.mimetype,
                size: file.size,
            });
        }
        res.json(results);
    }
    catch (err) {
        next(err);
    }
});
exports.default = router;
//# sourceMappingURL=upload.routes.js.map