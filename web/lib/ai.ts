/**
 * AI Service - Matches iOS AIService.swift
 * Integrates OpenAI GPT-4o-mini for receipt OCR and insights
 */

interface ReceiptData {
  vendor: string;
  amount: number | null;
  date: string;
  category?: string;
  confidence?: number;
}

interface AIInsight {
  title: string;
  description: string;
  type: 'warning' | 'info' | 'success';
  priority: 'high' | 'medium' | 'low';
}

class AIService {
  private static instance: AIService;
  private apiKey: string = process.env.NEXT_PUBLIC_OPENROUTER_API_KEY || '';
  private baseURL: string = 'https://openrouter.ai/api/v1';

  private constructor() {
    // Silently handle missing API key - features will be disabled
  }

  static get shared(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }

  /**
   * Extract receipt data from image using GPT-4o-mini Vision
   */
  async extractReceiptData(imageData: string): Promise<ReceiptData> {
    if (!this.apiKey) {
      throw new Error('OpenAI API key not configured');
    }

    try {
      // Remove data URL prefix if present
      const base64Image = imageData.includes(',') 
        ? imageData.split(',')[1] 
        : imageData;

      const response = await fetch(`${this.baseURL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
          'HTTP-Referer': 'https://siteledger.ai',
          'X-Title': 'SiteLedger',
        },
        body: JSON.stringify({
          model: 'openai/gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: 'You are a receipt OCR system. Extract vendor name, total amount, and date from receipt images. Return ONLY valid JSON with this exact structure: {"vendor": "string", "amount": number, "date": "YYYY-MM-DD", "category": "materials|equipment|labor|permits|transportation|other", "confidence": 0.0-1.0}. If you cannot read a field, use null for numbers, empty string for text.'
            },
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: 'Extract the vendor name, total amount, date, and best category guess from this receipt image.'
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:image/jpeg;base64,${base64Image}`,
                    detail: 'low' // Use low detail for cost efficiency
                  }
                }
              ]
            }
          ],
          max_tokens: 300,
          temperature: 0.1, // Low temperature for consistent extraction
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error?.message || 'OpenAI API request failed');
      }

      const data = await response.json();
      const content = data.choices[0]?.message?.content;

      if (!content) {
        throw new Error('No content in OpenAI response');
      }

      // Parse the JSON response
      const extracted: ReceiptData = JSON.parse(content);

      // Validate and normalize the data
      return {
        vendor: extracted.vendor || '',
        amount: extracted.amount,
        date: extracted.date || new Date().toISOString().split('T')[0],
        category: extracted.category || 'materials',
        confidence: extracted.confidence || 0.7,
      };
    } catch (error: any) {
      // Return empty data on error so user can manually enter
      return {
        vendor: '',
        amount: null,
        date: new Date().toISOString().split('T')[0],
        category: 'materials',
        confidence: 0,
      };
    }
  }

  /**
   * Generate AI insights for a job
   */
  async generateJobInsights(jobData: any): Promise<AIInsight[]> {
    if (!this.apiKey) {
      return [];
    }

    try {
      const response = await fetch(`${this.baseURL}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: 'You are a construction project analyst. Analyze job data and provide actionable insights about budget, timeline, and risks. Return ONLY valid JSON array: [{"title": "string", "description": "string", "type": "warning|info|success", "priority": "high|medium|low"}]'
            },
            {
              role: 'user',
              content: `Analyze this job and provide 3-5 insights:\n${JSON.stringify(jobData, null, 2)}`
            }
          ],
          max_tokens: 500,
          temperature: 0.3,
        }),
      });

      if (!response.ok) {
        throw new Error('OpenAI API request failed');
      }

      const data = await response.json();
      const content = data.choices[0]?.message?.content;
      
      if (!content) {
        return [];
      }

      return JSON.parse(content);
    } catch (error) {
      return [];
    }
  }

  /**
   * Categorize a receipt automatically
   */
  categorizeReceipt(vendor: string, amount: number): string {
    const vendorLower = vendor.toLowerCase();
    
    // Simple rule-based categorization
    if (vendorLower.includes('home depot') || vendorLower.includes('lowes') || vendorLower.includes('lumber')) {
      return 'materials';
    }
    if (vendorLower.includes('rent') || vendorLower.includes('equipment')) {
      return 'equipment';
    }
    if (vendorLower.includes('permit') || vendorLower.includes('license')) {
      return 'permits';
    }
    if (vendorLower.includes('gas') || vendorLower.includes('fuel') || vendorLower.includes('uber')) {
      return 'transportation';
    }
    
    return 'materials'; // Default category
  }

  /**
   * Calculate AI confidence score for receipt data
   */
  calculateConfidence(data: ReceiptData): number {
    let score = 0;
    
    // Vendor name exists and is reasonable length
    if (data.vendor && data.vendor.length >= 3 && data.vendor.length <= 50) {
      score += 0.3;
    }
    
    // Amount is reasonable (between $1 and $10,000)
    if (data.amount && data.amount > 0 && data.amount < 10000) {
      score += 0.4;
    }
    
    // Date is valid and recent (within 1 year)
    if (data.date) {
      const receiptDate = new Date(data.date);
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
      
      if (receiptDate >= oneYearAgo && receiptDate <= new Date()) {
        score += 0.3;
      }
    }
    
    return Math.min(score, 1.0);
  }

  /**
   * Check if AI service is available
   */
  isAvailable(): boolean {
    return !!this.apiKey;
  }

  /**
   * Get AI automation mode from localStorage
   */
  getAutomationMode(): 'manual' | 'assist' | 'autopilot' {
    if (typeof window === 'undefined') return 'manual';
    return (localStorage.getItem('ai_automation_mode') as any) || 'assist';
  }

  /**
   * Get AI confidence threshold from localStorage
   */
  getConfidenceThreshold(): number {
    if (typeof window === 'undefined') return 0.85;
    const stored = localStorage.getItem('ai_confidence_threshold');
    return stored ? parseFloat(stored) : 0.85;
  }
}

export default AIService;
