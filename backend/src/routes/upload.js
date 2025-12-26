/**
 * File Upload Routes
 * Handles uploads to DigitalOcean Spaces (S3-compatible)
 * Production-ready with security hardening
 */

const express = require('express');
const multer = require('multer');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

const isProduction = process.env.NODE_ENV === 'production';
const useLocalStorage = !isProduction || !process.env.SPACES_ACCESS_KEY;

// Create local uploads directory if using local storage
if (useLocalStorage) {
    const uploadsDir = path.join(__dirname, '../../uploads');
    ['receipts', 'documents', 'profiles'].forEach(subdir => {
        const dir = path.join(uploadsDir, subdir);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
    });
    console.log('📁 Using local file storage for uploads (dev mode)');
}

// Validate required environment variables in production
if (isProduction) {
    const required = ['SPACES_ENDPOINT', 'SPACES_ACCESS_KEY', 'SPACES_SECRET_KEY', 'SPACES_BUCKET'];
    const missing = required.filter(key => !process.env[key]);
    if (missing.length > 0) {
        console.error(`❌ Missing required env vars for uploads: ${missing.join(', ')}`);
    }
}

// Configure DigitalOcean Spaces
const spacesEndpoint = new AWS.Endpoint(process.env.SPACES_ENDPOINT || 'https://nyc3.digitaloceanspaces.com');
const s3 = new AWS.S3({
    endpoint: spacesEndpoint,
    accessKeyId: process.env.SPACES_ACCESS_KEY,
    secretAccessKey: process.env.SPACES_SECRET_KEY,
    signatureVersion: 'v4' // Use latest signature version
});

const BUCKET = process.env.SPACES_BUCKET || 'siteledger-files';
const CDN_ENDPOINT = process.env.SPACES_CDN_ENDPOINT || `https://${BUCKET}.nyc3.cdn.digitaloceanspaces.com`;

// Allowed file extensions (whitelist approach)
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.heic', '.pdf'];
const ALLOWED_MIMETYPES = ['image/jpeg', 'image/png', 'image/heic', 'application/pdf'];

// Multer config with security hardening
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 50 * 1024 * 1024, // 50MB limit
        files: 1 // Only one file at a time
    },
    fileFilter: (req, file, cb) => {
        // Check mimetype
        if (!ALLOWED_MIMETYPES.includes(file.mimetype)) {
            return cb(new Error('Invalid file type. Allowed: JPEG, PNG, HEIC, PDF'));
        }
        
        // Check extension (prevent extension spoofing)
        const ext = path.extname(file.originalname).toLowerCase();
        if (!ALLOWED_EXTENSIONS.includes(ext)) {
            return cb(new Error('Invalid file extension'));
        }
        
        cb(null, true);
    }
});

/**
 * Sanitize filename to prevent path traversal
 */
const sanitizeFilename = (userId, folder, originalname) => {
    // Only use UUID for filename - ignore user input completely
    const ext = path.extname(originalname).toLowerCase();
    const safeExt = ALLOWED_EXTENSIONS.includes(ext) ? ext : '.jpg';
    return `${folder}/${userId}/${uuidv4()}${safeExt}`;
};

/**
 * POST /api/upload/receipt
 * Upload a receipt image
 */
router.post('/receipt', upload.single('file'), async (req, res) => {
    console.log('POST /api/upload/receipt called');
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file provided' });
        }
        
        const fileName = sanitizeFilename(req.user.id, 'receipts', req.file.originalname);
        
        if (useLocalStorage) {
            // Save to local filesystem
            const localPath = path.join(__dirname, '../../uploads', fileName);
            const dir = path.dirname(localPath);
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
            fs.writeFileSync(localPath, req.file.buffer);
            // Use proper production URL
            const baseURL = isProduction ? 'https://api.siteledger.ai' : 'http://localhost:3000';
            const fileURL = `${baseURL}/uploads/${fileName}`;
            console.log(`✅ Receipt saved locally: ${fileURL}`);
            return res.json({ url: fileURL });
        }
        
        const params = {
            Bucket: BUCKET,
            Key: fileName,
            Body: req.file.buffer,
            ContentType: req.file.mimetype,
            ACL: 'public-read',
            // Add cache control for CDN
            CacheControl: 'max-age=31536000' // 1 year cache
        };
        
        await s3.upload(params).promise();
        
        const fileURL = `${CDN_ENDPOINT}/${fileName}`;
        
        res.json({ url: fileURL });
    } catch (error) {
        console.error('Upload receipt error:', error);
        res.status(500).json({ error: 'Failed to upload file', details: error.message || error });
    }
});

/**
 * POST /api/upload/document
 * Upload a document (PDF or image)
 */
router.post('/document', upload.single('file'), async (req, res) => {
    console.log('POST /api/upload/document called');
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file provided' });
        }
        
        const fileName = sanitizeFilename(req.user.id, 'documents', req.file.originalname);
        
        if (useLocalStorage) {
            const localPath = path.join(__dirname, '../../uploads', fileName);
            const dir = path.dirname(localPath);
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
            fs.writeFileSync(localPath, req.file.buffer);
            // Use proper production URL
            const baseURL = isProduction ? 'https://api.siteledger.ai' : 'http://localhost:3000';
            const fileURL = `${baseURL}/uploads/${fileName}`;
            console.log(`✅ Document saved locally: ${fileURL}`);
            return res.json({ url: fileURL });
        }
        
        const params = {
            Bucket: BUCKET,
            Key: fileName,
            Body: req.file.buffer,
            ContentType: req.file.mimetype,
            ACL: 'public-read',
            CacheControl: 'max-age=31536000'
        };
        
        await s3.upload(params).promise();
        
        const fileURL = `${CDN_ENDPOINT}/${fileName}`;
        
        res.json({ url: fileURL });
    } catch (error) {
        console.error('Upload document error:', error);
        res.status(500).json({ error: 'Failed to upload file', details: error.message || error });
    }
});

/**
 * POST /api/upload/profile
 * Upload a profile photo
 */
router.post('/profile', upload.single('file'), async (req, res) => {
    console.log('POST /api/upload/profile called');
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file provided' });
        }
        
        // Profile photos use user ID as filename (overwrites previous)
        const ext = path.extname(req.file.originalname).toLowerCase();
        const safeExt = ['.jpg', '.jpeg', '.png'].includes(ext) ? ext : '.jpg';
        const fileName = `profiles/${req.user.id}${safeExt}`;
        
        if (useLocalStorage) {
            const localPath = path.join(__dirname, '../../uploads', fileName);
            const dir = path.dirname(localPath);
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
            fs.writeFileSync(localPath, req.file.buffer);
            // Use proper production URL with cache busting
            const baseURL = isProduction ? 'https://api.siteledger.ai' : 'http://localhost:3000';
            const fileURL = `${baseURL}/uploads/${fileName}?v=${Date.now()}`;
            console.log(`✅ Profile photo saved locally: ${fileURL}`);
            return res.json({ url: fileURL });
        }
        
        const params = {
            Bucket: BUCKET,
            Key: fileName,
            Body: req.file.buffer,
            ContentType: req.file.mimetype,
            ACL: 'public-read',
            CacheControl: 'max-age=86400' // 1 day cache for profiles (can change)
        };
        
        await s3.upload(params).promise();
        
        // Add timestamp to bust cache when profile updates
        const fileURL = `${CDN_ENDPOINT}/${fileName}?v=${Date.now()}`;
        
        res.json({ url: fileURL });
    } catch (error) {
        console.error('Upload profile error:', error);
        res.status(500).json({ error: 'Failed to upload file', details: error.message || error });
    }
});

/**
 * DELETE /api/upload
 * Delete a file from Spaces
 */
router.delete('/', async (req, res) => {
    try {
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({ error: 'No URL provided' });
        }
        
        // Extract key from URL
        const key = url.replace(`${CDN_ENDPOINT}/`, '');
        
        // Verify user owns this file (key should contain their user ID)
        if (!key.includes(req.user.id)) {
            return res.status(403).json({ error: 'Access denied' });
        }
        
        await s3.deleteObject({
            Bucket: BUCKET,
            Key: key
        }).promise();
        
        res.json({ message: 'File deleted' });
    } catch (error) {
        console.error('Delete file error:', error);
        res.status(500).json({ error: 'Failed to delete file' });
    }
});

module.exports = router;
