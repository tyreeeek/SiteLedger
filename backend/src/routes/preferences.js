// User Preferences Routes
// Handles AI automation, notifications, theme, and data retention settings

const express = require('express');
const router = express.Router();
const pool = require('../database/db');
const { authenticate } = require('../middleware/auth');

// ==================== AI AUTOMATION SETTINGS ====================

// Get AI automation settings
router.get('/ai-automation', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT ai_automation_settings FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0].ai_automation_settings || {});
  } catch (error) {
    console.error('Error fetching AI automation settings:', error);
    res.status(500).json({ error: 'Failed to fetch settings' });
  }
});

// Update AI automation settings
router.put('/ai-automation', authenticate, async (req, res) => {
  try {
    const {
      automationLevel,
      autoFillReceipts,
      autoAssignJobs,
      autoCalculateLaborCosts,
      autoGenerateSummaries,
      autoGenerateInsights
    } = req.body;

    const settings = {
      automationLevel: automationLevel || 'assist',
      autoFillReceipts: autoFillReceipts !== undefined ? autoFillReceipts : true,
      autoAssignJobs: autoAssignJobs !== undefined ? autoAssignJobs : true,
      autoCalculateLaborCosts: autoCalculateLaborCosts !== undefined ? autoCalculateLaborCosts : true,
      autoGenerateSummaries: autoGenerateSummaries !== undefined ? autoGenerateSummaries : false,
      autoGenerateInsights: autoGenerateInsights !== undefined ? autoGenerateInsights : true
    };

    const result = await pool.query(
      'UPDATE users SET ai_automation_settings = $1, updated_at = NOW() WHERE id = $2 RETURNING ai_automation_settings',
      [JSON.stringify(settings), req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ 
      message: 'AI automation settings updated successfully',
      settings: result.rows[0].ai_automation_settings 
    });
  } catch (error) {
    console.error('Error updating AI automation settings:', error);
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

// ==================== NOTIFICATION PREFERENCES ====================

// Get notification preferences
router.get('/notifications', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT notification_preferences FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0].notification_preferences || {});
  } catch (error) {
    console.error('Error fetching notification preferences:', error);
    res.status(500).json({ error: 'Failed to fetch preferences' });
  }
});

// Update notification preferences
router.put('/notifications', authenticate, async (req, res) => {
  try {
    const preferences = req.body;

    const result = await pool.query(
      'UPDATE users SET notification_preferences = $1, updated_at = NOW() WHERE id = $2 RETURNING notification_preferences',
      [JSON.stringify(preferences), req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ 
      message: 'Notification preferences updated successfully',
      preferences: result.rows[0].notification_preferences 
    });
  } catch (error) {
    console.error('Error updating notification preferences:', error);
    res.status(500).json({ error: 'Failed to update preferences' });
  }
});

// ==================== THEME PREFERENCE ====================

// Get theme preference
router.get('/theme', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT theme FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ theme: result.rows[0].theme || 'light' });
  } catch (error) {
    console.error('Error fetching theme:', error);
    res.status(500).json({ error: 'Failed to fetch theme' });
  }
});

// Update theme preference
router.put('/theme', authenticate, async (req, res) => {
  try {
    const { theme } = req.body;

    if (!['light', 'dark', 'system'].includes(theme)) {
      return res.status(400).json({ error: 'Invalid theme. Must be light, dark, or system' });
    }

    const result = await pool.query(
      'UPDATE users SET theme = $1, updated_at = NOW() WHERE id = $2 RETURNING theme',
      [theme, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ 
      message: 'Theme updated successfully',
      theme: result.rows[0].theme 
    });
  } catch (error) {
    console.error('Error updating theme:', error);
    res.status(500).json({ error: 'Failed to update theme' });
  }
});

// ==================== DATA RETENTION SETTINGS ====================

// Get data retention settings
router.get('/data-retention', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT data_retention_settings FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0].data_retention_settings || {});
  } catch (error) {
    console.error('Error fetching data retention settings:', error);
    res.status(500).json({ error: 'Failed to fetch settings' });
  }
});

// Update data retention settings
router.put('/data-retention', authenticate, async (req, res) => {
  try {
    const settings = req.body;

    const result = await pool.query(
      'UPDATE users SET data_retention_settings = $1, updated_at = NOW() WHERE id = $2 RETURNING data_retention_settings',
      [JSON.stringify(settings), req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ 
      message: 'Data retention settings updated successfully',
      settings: result.rows[0].data_retention_settings 
    });
  } catch (error) {
    console.error('Error updating data retention settings:', error);
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

// ==================== ALL PREFERENCES (GET ALL AT ONCE) ====================

// Get all user preferences
router.get('/all', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT ai_automation_settings, notification_preferences, theme, data_retention_settings FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      aiAutomation: result.rows[0].ai_automation_settings || {},
      notifications: result.rows[0].notification_preferences || {},
      theme: result.rows[0].theme || 'light',
      dataRetention: result.rows[0].data_retention_settings || {}
    });
  } catch (error) {
    console.error('Error fetching preferences:', error);
    res.status(500).json({ error: 'Failed to fetch preferences' });
  }
});

module.exports = router;
