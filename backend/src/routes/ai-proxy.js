/**
 * AI Proxy Routes
 * Provides AI text analysis for iOS app via Puter.js
 */

const express = require("express");
const router = express.Router();
const { authenticate } = require("../middleware/auth");
const AIInsightsService = require("../services/ai-insights");

/**
 * POST /api/ai/analyze
 * Analyze text using Puter.js AI
 * For iOS app to call instead of OpenRouter directly
 */
router.post("/analyze", authenticate, async (req, res) => {
  try {
    const { text, systemPrompt } = req.body;

    if (!text) {
      return res.status(400).json({ error: "Text is required" });
    }

    const defaultSystemPrompt = systemPrompt || "You are a helpful assistant. Provide concise, accurate responses.";

    // Use the AI service to get analysis
    try {
      const response = await AIInsightsService.callAIProvider(text, defaultSystemPrompt);
      res.json({ 
        success: true,
        response: response,
        provider: "puter.js"
      });
    } catch (error) {
      // If AI fails, return a helpful fallback
      res.json({ 
        success: true,
        response: "AI analysis is temporarily unavailable. Please try again later.",
        provider: "fallback",
        error: error.message
      });
    }
  } catch (error) {
    console.error("Error in AI proxy:", error);
    res.status(500).json({ 
      error: "AI analysis failed", 
      success: false 
    });
  }
});

module.exports = router;