"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BUCKET = exports.s3Client = void 0;
exports.uploadToS3 = uploadToS3;
exports.getPresignedUrl = getPresignedUrl;
exports.deleteFromS3 = deleteFromS3;
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const s3Client = new client_s3_1.S3Client({
    region: process.env.S3_REGION || 'us-east-1',
    ...(process.env.S3_ENDPOINT ? { endpoint: process.env.S3_ENDPOINT, forcePathStyle: true } : {}),
    credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY || '',
        secretAccessKey: process.env.S3_SECRET_KEY || '',
    },
});
exports.s3Client = s3Client;
const BUCKET = process.env.S3_BUCKET || 'dealance-uploads';
exports.BUCKET = BUCKET;
async function uploadToS3(key, body, contentType) {
    await s3Client.send(new client_s3_1.PutObjectCommand({
        Bucket: BUCKET,
        Key: key,
        Body: body,
        ContentType: contentType,
    }));
    // Return the public URL
    if (process.env.S3_ENDPOINT) {
        return `${process.env.S3_ENDPOINT}/${BUCKET}/${key}`;
    }
    return `https://${BUCKET}.s3.${process.env.S3_REGION}.amazonaws.com/${key}`;
}
async function getPresignedUrl(key) {
    const command = new client_s3_1.GetObjectCommand({ Bucket: BUCKET, Key: key });
    return (0, s3_request_presigner_1.getSignedUrl)(s3Client, command, { expiresIn: 3600 });
}
async function deleteFromS3(key) {
    await s3Client.send(new client_s3_1.DeleteObjectCommand({ Bucket: BUCKET, Key: key }));
}
//# sourceMappingURL=s3.js.map