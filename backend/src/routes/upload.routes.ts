import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { upload, generateFileKey } from '../middleware/upload';
import { uploadToS3 } from '../config/s3';
import path from 'path';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

router.use(authenticate as any);

// For MVP: if S3 is not configured, save files locally
const LOCAL_UPLOAD_DIR = path.join(__dirname, '../../uploads');

// Ensure upload directory exists
if (!fs.existsSync(LOCAL_UPLOAD_DIR)) {
  fs.mkdirSync(LOCAL_UPLOAD_DIR, { recursive: true });
}

// POST /api/upload - Upload a file
router.post('/', upload.single('file'), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'No file provided' });
      return;
    }

    const folder = (req.body.folder as string) || 'uploads';
    const fileKey = generateFileKey(req.file.originalname, folder);

    let fileUrl: string;

    // Try S3 upload, fallback to local
    try {
      if (process.env.S3_ACCESS_KEY && process.env.S3_ACCESS_KEY !== 'minioadmin') {
        fileUrl = await uploadToS3(fileKey, req.file.buffer, req.file.mimetype);
      } else {
        throw new Error('Using local storage');
      }
    } catch {
      // Local fallback: save to disk
      const localPath = path.join(LOCAL_UPLOAD_DIR, fileKey);
      const dir = path.dirname(localPath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(localPath, req.file.buffer);
      fileUrl = `/uploads/${fileKey}`;
    }

    res.json({
      url: fileUrl,
      key: fileKey,
      originalName: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/upload/multiple - Upload multiple files
router.post('/multiple', upload.array('files', 10), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const files = req.files as Express.Multer.File[];
    if (!files || files.length === 0) {
      res.status(400).json({ error: 'No files provided' });
      return;
    }

    const folder = (req.body.folder as string) || 'uploads';
    const results = [];

    for (const file of files) {
      const fileKey = generateFileKey(file.originalname, folder);
      let fileUrl: string;

      try {
        if (process.env.S3_ACCESS_KEY && process.env.S3_ACCESS_KEY !== 'minioadmin') {
          fileUrl = await uploadToS3(fileKey, file.buffer, file.mimetype);
        } else {
          throw new Error('Using local storage');
        }
      } catch {
        const localPath = path.join(LOCAL_UPLOAD_DIR, fileKey);
        const dir = path.dirname(localPath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
        fs.writeFileSync(localPath, file.buffer);
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
  } catch (err) {
    next(err);
  }
});

export default router;
