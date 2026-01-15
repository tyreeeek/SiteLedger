/**
 * Config Routes - App configuration
 * No API keys needed - using Puter.js (free AI) and Tesseract (local OCR)
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

/**
 * GET /api/config/keys
 * Returns configuration for authenticated users
 * Note: No API keys needed - all services are free/local
 */
router.get('/keys', authenticate, (req, res) => {
    try {
        // Return empty config - no API keys needed
        // Puter.js AI is free and requires no authentication
        // Tesseract OCR runs locally on the server
        const config = {
            aiProvider: 'puter',
            ocrProvider: 'tesseract',
            requiresApiKeys: false
        };
        
        res.json(config);
    } catch (error) {
        console.error('Error fetching config:', error);
        res.status(500).json({ error: 'Failed to retrieve configuration' });
    }
});

module.exports = router;
