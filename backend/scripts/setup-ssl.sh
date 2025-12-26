#!/bin/bash
# SiteLedger Production SSL Setup Script
# Run this on your DigitalOcean droplet (68.183.25.130)

set -e

echo "🔐 SiteLedger Production SSL Configuration"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Configuration
DOMAIN="api.siteledger.ai"
EMAIL="admin@siteledger.ai"  # Change this to your email

echo "📋 Configuration:"
echo "   Domain: $DOMAIN"
echo "   Email: $EMAIL"
echo ""

# Step 1: Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install Nginx and Certbot
echo "🔧 Installing Nginx and Certbot..."
apt install -y nginx certbot python3-certbot-nginx

# Step 3: Create Nginx configuration
echo "⚙️  Creating Nginx configuration..."
cat > /etc/nginx/sites-available/siteledger <<'EOF'
server {
    listen 80;
    server_name api.siteledger.ai;
    
    # Allow Certbot to verify domain
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/siteledger /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

echo "✅ Nginx configured and running"
echo ""

# Step 4: Get SSL certificate
echo "🔐 Obtaining SSL certificate from Let's Encrypt..."
echo "   NOTE: Make sure DNS for $DOMAIN points to this server!"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."

certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect

echo ""
echo "✅ SSL certificate obtained!"
echo ""

# Step 5: Configure auto-renewal
echo "🔄 Setting up auto-renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

# Test renewal
certbot renew --dry-run

echo ""
echo "✅ Auto-renewal configured (runs twice daily)"
echo ""

# Step 6: Update Nginx for better SSL security
echo "🔒 Enhancing SSL security..."
cat > /etc/nginx/sites-available/siteledger <<'EOF'
server {
    listen 80;
    server_name api.siteledger.ai;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.siteledger.ai;

    ssl_certificate /etc/letsencrypt/live/api.siteledger.ai/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.siteledger.ai/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    
    # HSTS (uncomment after testing)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Node.js backend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
EOF

# Reload Nginx
nginx -t && systemctl reload nginx

echo "✅ SSL configuration enhanced"
echo ""

# Step 7: Configure firewall
echo "🛡️  Configuring firewall..."
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

echo "✅ Firewall configured"
echo ""

# Step 8: Test SSL
echo "🧪 Testing SSL configuration..."
curl -I https://$DOMAIN/health

echo ""
echo "🎉 SSL CONFIGURATION COMPLETE!"
echo ""
echo "📋 Next Steps:"
echo "   1. Update iOS app APIService.swift:"
echo "      private let baseURL = \"https://$DOMAIN/api\""
echo ""
echo "   2. Update iOS app APIKeyManager.swift:"
echo "      let baseURL = \"https://$DOMAIN/api\""
echo ""
echo "   3. Remove ATS exception from Info.plist"
echo ""
echo "   4. Test iOS app connection:"
echo "      curl https://$DOMAIN/health"
echo ""
echo "   5. Monitor SSL certificate expiration:"
echo "      certbot certificates"
echo ""
echo "📊 Certificate Status:"
certbot certificates
echo ""
echo "✅ Production HTTPS ready!"
