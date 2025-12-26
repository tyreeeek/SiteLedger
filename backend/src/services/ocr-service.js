/**
 * OCR Service for Receipt Processing
 * Uses OCR.space API for text extraction from receipt images
 */

const axios = require('axios');
const logger = require('../config/logger');

class OCRService {
    constructor() {
        this.apiKey = process.env.OCR_SPACE_API_KEY;
        this.apiUrl = 'https://api.ocr.space/parse/image';
        
        if (!this.apiKey) {
            logger.warn('OCR_SPACE_API_KEY not configured - OCR features will be limited');
        }
    }

    /**
     * Extract text from receipt image
     * @param {string} imageUrl - URL of the receipt image
     * @returns {Promise<Object>} - Extracted data
     */
    async processReceipt(imageUrl) {
        try {
            if (!this.apiKey) {
                logger.warn('OCR_SPACE_API_KEY not configured');
                return this.getMockOCRData();
            }

            // Use URLSearchParams instead of FormData for Node.js compatibility
            const params = new URLSearchParams();
            params.append('url', imageUrl);
            params.append('apikey', this.apiKey);
            params.append('language', 'eng');
            params.append('isOverlayRequired', 'false');
            params.append('detectOrientation', 'true');
            params.append('scale', 'true');

            const response = await axios.post(this.apiUrl, params, {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                timeout: 30000
            });

            if (response.data.IsErroredOnProcessing) {
                const error = response.data.ErrorMessage?.[0] || 'OCR processing failed';
                logger.error('OCR processing failed:', { error, imageUrl });
                throw new Error(error);
            }

            const ocrText = response.data.ParsedResults?.[0]?.ParsedText || '';
            logger.info('OCR processing successful', { imageUrl, textLength: ocrText.length });
            return this.parseReceiptData(ocrText);

        } catch (error) {
            logger.error('OCR processing error:', { error: error.message, imageUrl });
            return this.getMockOCRData();
        }
    }

    /**
     * Parse OCR text to extract receipt information
     * @param {string} text - Raw OCR text
     * @returns {Object} - Parsed receipt data
     */
    parseReceiptData(text) {
        const data = {
            vendor: this.extractVendor(text),
            amount: this.extractAmount(text),
            date: this.extractDate(text),
            category: this.suggestCategory(text),
            confidence: 0.85,
            rawText: text
        };

        return data;
    }

    /**
     * Extract vendor name from receipt text
     */
    extractVendor(text) {
        const lines = text.split('\n').filter(line => line.trim().length > 0);
        // Usually vendor name is in first few lines
        if (lines.length > 0) {
            return lines[0].substring(0, 50).trim();
        }
        return 'Unknown Vendor';
    }

    /**
     * Extract total amount from receipt
     */
    extractAmount(text) {
        // Look for common patterns: TOTAL, AMOUNT DUE, etc.
        const patterns = [
            /total[:\s]*\$?(\d+\.?\d*)/i,
            /amount due[:\s]*\$?(\d+\.?\d*)/i,
            /subtotal[:\s]*\$?(\d+\.?\d*)/i,
            /\$\s*(\d+\.\d{2})/
        ];

        for (const pattern of patterns) {
            const match = text.match(pattern);
            if (match && match[1]) {
                const amount = parseFloat(match[1]);
                if (amount > 0 && amount < 100000) {
                    return amount;
                }
            }
        }

        // Fallback: find largest dollar amount
        const amounts = text.match(/\$?\d+\.\d{2}/g) || [];
        const numbers = amounts.map(a => parseFloat(a.replace('$', '')));
        return numbers.length > 0 ? Math.max(...numbers) : 0;
    }

    /**
     * Extract date from receipt
     */
    extractDate(text) {
        const datePatterns = [
            /(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/,
            /(\d{4}[-\/]\d{1,2}[-\/]\d{1,2})/,
            /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2},?\s+\d{4}/i
        ];

        for (const pattern of datePatterns) {
            const match = text.match(pattern);
            if (match) {
                const dateStr = match[1] || match[0];
                const date = new Date(dateStr);
                if (!isNaN(date.getTime())) {
                    return date.toISOString().split('T')[0];
                }
            }
        }

        return new Date().toISOString().split('T')[0];
    }

    /**
     * Suggest category based on receipt content
     */
    suggestCategory(text) {
        const lowerText = text.toLowerCase();

        const categories = {
            'materials': ['hardware', 'lumber', 'building', 'supply', 'depot', 'lowes', 'home depot'],
            'equipment': ['tools', 'equipment', 'rental', 'machinery'],
            'fuel': ['gas', 'fuel', 'diesel', 'shell', 'exxon', 'chevron'],
            'food': ['restaurant', 'food', 'cafe', 'coffee', 'lunch', 'dinner'],
            'office': ['office', 'staples', 'paper', 'supplies'],
            'transportation': ['uber', 'lyft', 'taxi', 'parking', 'toll']
        };

        for (const [category, keywords] of Object.entries(categories)) {
            if (keywords.some(keyword => lowerText.includes(keyword))) {
                return category;
            }
        }

        return 'other';
    }

    /**
     * Return mock OCR data when API is not configured
     */
    getMockOCRData() {
        return {
            vendor: 'Receipt',
            amount: 0,
            date: new Date().toISOString().split('T')[0],
            category: 'other',
            confidence: 0,
            rawText: '',
            note: 'OCR API key not configured - manual entry required'
        };
    }
}

module.exports = new OCRService();
