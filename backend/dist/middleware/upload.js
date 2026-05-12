"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.upload = void 0;
exports.generateFileKey = generateFileKey;
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const uuid_1 = require("uuid");
// Store files in memory for S3 upload
const storage = multer_1.default.memoryStorage();
// File filter
const fileFilter = (_req, file, cb) => {
    const allowedTypes = [
        'application/pdf',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation', // pptx
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // docx
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // xlsx
        'video/mp4',
        'audio/mpeg',
        'image/jpeg',
        'image/png',
        'image/webp',
    ];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    }
    else {
        cb(new Error(`File type ${file.mimetype} not allowed`));
    }
};
exports.upload = (0, multer_1.default)({
    storage,
    fileFilter,
    limits: {
        fileSize: 50 * 1024 * 1024, // 50MB max
    },
});
function generateFileKey(originalName, folder = 'uploads') {
    const ext = path_1.default.extname(originalName);
    return `${folder}/${(0, uuid_1.v4)()}${ext}`;
}
//# sourceMappingURL=upload.js.map