// Support Routes
// Handles contact support requests

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');
const logger = require('../config/logger');

/**
 * POST /api/support/contact
 * Submit a support request
 */
router.post('/contact', authenticate, [
  body('name').notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('subject').notEmpty().withMessage('Subject is required'),
  body('message').notEmpty().withMessage('Message is required')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { name, email, subject, message } = req.body;

    // Log the support request
    logger.info('Support request received', {
      userId: req.user.id,
      userEmail: req.user.email,
      subject,
      timestamp: new Date().toISOString()
    });

    // TODO: Send email to support team
    // This would typically use a service like SendGrid, AWS SES, or Nodemailer
    // For now, we'll just log it
    
    // In production, you would do something like:
    // await emailService.sendSupportRequest({
    //   from: email,
    //   name,
    //   subject,
    //   message,
    //   userId: req.user.id
    // });

    res.json({ 
      message: 'Support request submitted successfully',
      ticketId: `SUPPORT-${Date.now()}-${req.user.id.substring(0, 8)}`,
      estimatedResponseTime: '24 hours'
    });
  } catch (error) {
    logger.error('Error submitting support request:', {
      error: error.message,
      userId: req.user?.id
    });
    res.status(500).json({ error: 'Failed to submit support request' });
  }
});

module.exports = router;
