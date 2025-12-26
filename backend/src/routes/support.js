// Support Routes
// Handles contact support requests

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');
const emailService = require('../utils/emailService');

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

    // Send email to support team at siteledger@siteledger.ai
    const emailSubject = `Support Request: ${subject}`;
    const emailBody = `
      <h2>New Support Request</h2>
      <p><strong>From:</strong> ${name} (${email})</p>
      <p><strong>User ID:</strong> ${req.user.id}</p>
      <p><strong>Subject:</strong> ${subject}</p>
      <p><strong>Message:</strong></p>
      <p>${message.replace(/\n/g, '<br>')}</p>
      <hr>
      <p><small>Submitted at: ${new Date().toISOString()}</small></p>
    `;

    await emailService.sendEmail(
      'siteledger@siteledger.ai',
      emailSubject,
      emailBody
    );

    console.log('Support request sent to siteledger@siteledger.ai', {
      userId: req.user.id,
      userEmail: req.user.email,
      subject,
      timestamp: new Date().toISOString()
    });

    res.json({ 
      message: 'Support request submitted successfully',
      ticketId: `SUPPORT-${Date.now()}-${req.user.id.substring(0, 8)}`,
      estimatedResponseTime: '24 hours'
    });
  } catch (error) {
    console.error('Error submitting support request:', {
      error: error.message,
      userId: req.user?.id
    });
    res.status(500).json({ error: 'Failed to submit support request' });
  }
});

module.exports = router;
