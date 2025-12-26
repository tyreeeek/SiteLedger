/**
 * Config Routes - Secure API key delivery
 * Keys are stored in environment variables on the server
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

/**
 * GET /api/config/keys
 * Returns API keys for authenticated users only
 * Keys are stored server-side, never in the mobile app
 */
router.get('/keys', authenticate, (req, res) => {
    try {
        // Return API keys from environment variables
        // Support both OPENROUTER_API_KEY and OPENAI_API_KEY for backward compatibility
        const keys = {
            ocrSpaceKey: process.env.OCR_SPACE_API_KEY || '',
            openRouterKey: process.env.OPENROUTER_API_KEY || process.env.OPENAI_API_KEY || '',
            aiModel: process.env.AI_MODEL_NAME || process.env.OPENAI_MODEL || 'meta-llama/llama-3.3-70b-instruct:free'
        };
        
        // Validate that keys exist
        if (!keys.ocrSpaceKey || !keys.openRouterKey) {
            console.warn('Warning: API keys not configured in environment');
        }
        
        res.json(keys);
    } catch (error) {
        console.error('Error fetching config keys:', error);
        res.status(500).json({ error: 'Failed to retrieve configuration' });
    }
});

module.exports = router;
