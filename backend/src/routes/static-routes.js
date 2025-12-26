/**
 * Static pages routes (privacy policy, support)
 * Add this file to: /root/SiteLedger/backend/src/routes/static-routes.js
 */
const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// Privacy Policy
router.get('/privacy-policy.html', (req, res) => {
    const filePath = path.join(__dirname, '../public/privacy-policy.html');
    
    // Check if file exists
    if (fs.existsSync(filePath)) {
        res.setHeader('Content-Type', 'text/html');
        res.sendFile(filePath);
    } else {
        res.status(404).send('Privacy policy not found');
    }
});

// Support Page
router.get('/support.html', (req, res) => {
    const filePath = path.join(__dirname, '../public/support.html');
    
    // Check if file exists
    if (fs.existsSync(filePath)) {
        res.setHeader('Content-Type', 'text/html');
        res.sendFile(filePath);
    } else {
        res.status(404).send('Support page not found');
    }
});

// Also serve without .html extension
router.get('/privacy-policy', (req, res) => {
    res.redirect('/privacy-policy.html');
});

router.get('/support', (req, res) => {
    res.redirect('/support.html');
});

// Root path - optional landing page
router.get('/pages', (req, res) => {
    res.setHeader('Content-Type', 'text/html');
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>SiteLedger</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    max-width: 600px;
                    margin: 100px auto;
                    padding: 20px;
                    text-align: center;
                }
                a {
                    color: #00968f;
                    text-decoration: none;
                    font-size: 18px;
                    margin: 0 20px;
                }
                a:hover { text-decoration: underline; }
            </style>
        </head>
        <body>
            <h1>🔧 SiteLedger</h1>
            <p>
                <a href="/privacy-policy.html">Privacy Policy</a> | 
                <a href="/support.html">Support</a>
            </p>
        </body>
        </html>
    `);
});

module.exports = router;
