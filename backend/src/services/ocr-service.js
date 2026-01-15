/**
 * OCR Service for Receipt Processing
 * Uses OCR.space API (free tier: 25,000 requests/month)
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');
const logger = require('../config/logger');

const OCR_SPACE_API_URL = 'https://api.ocr.space/parse/image';
const OCR_SPACE_API_KEY = 'K87899142388957'; // Free tier key

class OCRService {
    constructor() {
        logger.info('✅ OCR Service initialized with OCR.space (free tier: 25k/month)');
    }

    /**
     * Extract text from receipt image using OCR.space
     * @param {string} imageUrlOrPath - URL or local file path of the receipt image
     * @returns {Promise<Object>} - Extracted data
     */
    async processReceipt(imageUrlOrPath) {
        try {
            logger.info('🔍 Processing OCR with OCR.space for image:', imageUrlOrPath);

            // Check if this is a local development URL (api.siteledger.ai in dev is local)
            const isLocalDevUrl = imageUrlOrPath.includes('api.siteledger.ai/uploads/');
            
            let response;

            if (isLocalDevUrl) {
                // Extract the file path from URL and read as base64
                // URL format: https://api.siteledger.ai/uploads/receipts/{userId}/{uuid}.jpg
                // Local path: backend/uploads/receipts/{userId}/{uuid}.jpg
                const urlObj = new URL(imageUrlOrPath);
                const urlPath = urlObj.pathname; // /uploads/receipts/...
                const localPath = path.join(__dirname, '../../', urlPath);
                
                logger.info('📁 Local dev file detected. Reading from:', localPath);
                
                if (!fs.existsSync(localPath)) {
                    logger.error('❌ Local file not found:', localPath);
                    logger.error('❌ __dirname:', __dirname);
                    logger.error('❌ Attempted path:', localPath);
                    return this.getEmptyResult();
                }
                
                const imageBuffer = fs.readFileSync(localPath);
                const base64Image = imageBuffer.toString('base64');
                
                // Detect image type from file extension
                const ext = path.extname(localPath).toLowerCase();
                let mimeType = 'image/jpeg';
                if (ext === '.png') mimeType = 'image/png';
                else if (ext === '.heic') mimeType = 'image/heic';
                
                logger.info('📤 Sending base64 image to OCR.space', { 
                    base64Length: base64Image.length,
                    filePath: localPath,
                    mimeType
                });
                
                // Determine file extension for OCR.space
                let fileExtension = 'jpg';
                if (ext === '.png') fileExtension = 'png';
                else if (ext === '.pdf') fileExtension = 'pdf';
                
                // Call OCR.space API with base64 image using form-data format
                const FormData = require('form-data');
                const form = new FormData();
                form.append('apikey', OCR_SPACE_API_KEY);
                form.append('language', 'eng');
                form.append('isOverlayRequired', 'false');
                form.append('detectOrientation', 'true');
                form.append('scale', 'true');
                form.append('OCREngine', '2');
                form.append('filetype', fileExtension);
                form.append('base64Image', `data:${mimeType};base64,${base64Image}`);
                
                response = await axios.post(OCR_SPACE_API_URL, form, {
                    headers: {
                        ...form.getHeaders()
                    },
                    timeout: 30000
                });
            } else {
                // Use URL method for external/production images (DigitalOcean Spaces)
                logger.info('🌐 Processing external/production URL:', imageUrlOrPath);
                
                response = await axios.get('https://api.ocr.space/parse/imageurl', {
                    params: {
                        apikey: OCR_SPACE_API_KEY,
                        url: imageUrlOrPath,
                        language: 'eng',
                        isOverlayRequired: false,
                        detectOrientation: true,
                        scale: true,
                        OCREngine: 2
                    },
                    timeout: 30000
                });
            }

            logger.info('📥 OCR.space response:', { 
                isErroredOnProcessing: response.data?.IsErroredOnProcessing,
                errorMessage: response.data?.ErrorMessage,
                hasText: !!response.data?.ParsedResults?.[0]?.ParsedText
            });

            if (response.data?.IsErroredOnProcessing) {
                logger.error('❌ OCR.space processing error:', response.data.ErrorMessage);
                return this.getEmptyResult();
            }

            const text = response.data?.ParsedResults?.[0]?.ParsedText || '';
            
            if (!text || text.length < 10) {
                logger.warn('No meaningful text extracted from image');
                return this.getEmptyResult();
            }

            logger.info('✅ OCR successful!', { 
                textLength: text.length,
                preview: text.substring(0, 100)
            });
            
            // Log full text for debugging (first 1000 chars to see more content)
            logger.info('📄 Full OCR text (first 1000 chars):', text.substring(0, 1000));
            logger.info('📄 OCR text line count:', text.split('\n').length);

            return this.parseReceiptData(text);

        } catch (error) {
            logger.error('❌ OCR.space error:', { 
                error: error.message,
                response: error.response?.data,
                imageUrlOrPath 
            });
            return this.getEmptyResult();
        }
    }

    /**
     * Return empty result when OCR fails
     */
    getEmptyResult() {
        return {
            vendor: '',
            amount: 0,
            date: new Date().toISOString().split('T')[0],
            category: 'misc', // Default per database constraint
            confidence: 0,
            rawText: ''
        };
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
            confidence: 0.85, // OCR.space default confidence
            rawText: text
        };

        logger.info('📊 Parsed receipt data:', {
            vendor: data.vendor,
            amount: data.amount,
            date: data.date,
            category: data.category
        });

        return data;
    }

    /**
     * Extract vendor name from receipt text
     */
    extractVendor(text) {
        const lines = text.split('\n').filter(line => line.trim().length > 0);
        
        // Common vendor name patterns (PRIORITY ORDER)
        const vendorPatterns = [
            // PRIORITY 1: Exact match for major stores (case-insensitive, flexible spacing)
            /\b(walmart|target|home\s*depot|lowe'?s|marshalls?|tj\s*maxx|costco|sam'?s\s*club|kroger|safeway|publix|whole\s*foods|trader\s*joe'?s|best\s*buy|staples|office\s*depot|cvs|walgreens|rite\s*aid)\b/i,
            
            // PRIORITY 2: Store name at the very start (usually first line)
            /^([A-Z][A-Za-z\s&'.-]{2,40})(?:\s*\n|$)/,
            
            // PRIORITY 3: "Sold by" or "Merchant" indicators
            /(?:sold\s*by|merchant|retailer|store\s*name)[:\s]+([A-Za-z\s&'.-]{2,40})/i,
            
            // PRIORITY 4: Store/Shop/Market followed by name
            /(?:store|shop|market)[:\s]+([A-Za-z\s&'.-]{2,40})/i
        ];
        
        // Try pattern matching first
        for (const pattern of vendorPatterns) {
            const match = text.match(pattern);
            if (match && match[1]) {
                let vendor = match[1].trim();
                
                // Clean up vendor name
                vendor = vendor.replace(/\s{2,}/g, ' '); // Multiple spaces → single space
                vendor = vendor.replace(/[^\w\s&'.-]/g, ''); // Remove weird characters
                vendor = vendor.substring(0, 50); // Max 50 chars
                
                if (vendor.length >= 2) {
                    logger.info('🏪 Vendor extracted via pattern:', { vendor, patternIndex: vendorPatterns.indexOf(pattern) });
                    return vendor;
                }
            }
        }
        
        // Fallback: Use first non-empty line (but clean it aggressively)
        if (lines.length > 0) {
            let vendor = lines[0].trim();
            
            // Remove common noise words/patterns
            vendor = vendor.replace(/^(receipt|invoice|store|#\d+|\*+)/i, '').trim();
            vendor = vendor.replace(/\s{2,}/g, ' ');
            vendor = vendor.substring(0, 50);
            
            if (vendor.length >= 2 && !/^\d+$/.test(vendor)) { // Not just numbers
                logger.info('🏪 Vendor extracted from first line (cleaned):', { vendor });
                return vendor;
            }
        }
        
        logger.warn('⚠️ No vendor found in text - returning empty string');
        return '';
    }

    /**
     * Extract total amount from receipt
     */
    extractAmount(text) {
        const lowerText = text.toLowerCase();
        
        // Look for common total patterns (most specific first)
        const patterns = [
            // PRIORITY 1: Most common "Total" formats
            /\btotal\b[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            /(?:grand\s*)?total[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            /total\s*amount[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            
            // PRIORITY 2: Alternative total formats
            /amount\s*due[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            /balance\s*due[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            /\bamount\s*paid[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            
            // PRIORITY 3: Multi-line total (common in receipts)
            /\btotal\b[\s\r\n]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            
            // PRIORITY 4: Payment-specific
            /\b(?:payment|charge)\b[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            
            // PRIORITY 5: Abbreviations
            /\b(?:tot|ttl)\b[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i,
            
            // PRIORITY 6: Subtotal as fallback
            /\bsubtotal\b[:\s]*\$?\s*(\d{1,6}[,.]\d{2})/i
        ];

        for (const pattern of patterns) {
            const match = text.match(pattern);
            if (match && match[1]) {
                const amountStr = match[1].replace(/,/g, ''); // Remove commas
                const amount = parseFloat(amountStr);
                if (amount > 0 && amount < 1000000) {
                    logger.info('💰 Amount extracted via pattern:', { 
                        pattern: pattern.source.substring(0, 50), 
                        amount, 
                        matchedText: match[0].substring(0, 30) 
                    });
                    return amount;
                }
            }
        }

        logger.warn('⚠️ No "total" keyword found - using fallback strategies');

        // Fallback Strategy 1: Find ALL dollar amounts, return the LARGEST one
        // (Total is usually the biggest number on a receipt)
        const allDollarMatches = text.match(/\$\s*(\d{1,6}(?:[,.]\d{2,3})*)/g) || [];
        const allPlainMoneyMatches = text.match(/\b(\d{1,6}\.\d{2})\b/g) || [];
        
        const allAmounts = [...allDollarMatches, ...allPlainMoneyMatches]
            .map(a => {
                const cleaned = a.replace(/[$\s,]/g, '');
                return parseFloat(cleaned);
            })
            .filter(n => !isNaN(n) && n > 0.01 && n < 100000); // Reasonable receipt range
        
        if (allAmounts.length > 0) {
            // Sort descending and return the largest amount
            const sortedAmounts = allAmounts.sort((a, b) => b - a);
            const largestAmount = sortedAmounts[0];
            
            logger.info('💰 Amount extracted via FALLBACK (largest amount):', { 
                largestAmount, 
                allFound: sortedAmounts.slice(0, 5) // Log top 5 for debugging
            });
            
            return largestAmount;
        }

        logger.error('❌ No valid amounts found anywhere in receipt text');
        return 0;
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
     * Valid categories: materials, fuel, equipment, subcontractors, misc
     */
    suggestCategory(text) {
        const lowerText = text.toLowerCase();

        const categories = {
            'materials': ['hardware', 'lumber', 'building', 'supply', 'depot', 'lowes', 'home depot', 'construction'],
            'equipment': ['tools', 'equipment', 'rental', 'machinery', 'tractor'],
            'fuel': ['gas', 'fuel', 'diesel', 'shell', 'exxon', 'chevron', 'petrol', 'station'],
            'subcontractors': ['contractor', 'subcontractor', 'labor', 'plumbing', 'electric', 'hvac']
        };

        for (const [category, keywords] of Object.entries(categories)) {
            if (keywords.some(keyword => lowerText.includes(keyword))) {
                return category;
            }
        }

        return 'misc'; // Default category per database constraint
    }
}

module.exports = new OCRService();
