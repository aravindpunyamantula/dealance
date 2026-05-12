import multer from 'multer';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

// Store files in memory for S3 upload
const storage = multer.memoryStorage();

// File filter
const fileFilter = (_req: Express.Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
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
  } else {
    cb(new Error(`File type ${file.mimetype} not allowed`));
  }
};

export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB max
  },
});

export function generateFileKey(originalName: string, folder: string = 'uploads'): string {
  const ext = path.extname(originalName);
  return `${folder}/${uuidv4()}${ext}`;
}
