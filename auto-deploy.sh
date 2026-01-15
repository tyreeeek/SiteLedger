#!/bin/bash

# Install expect if not present
if ! command -v expect &> /dev/null; then
    echo "Installing expect..."
    brew install expect
fi

# Create expect script for automated deployment
expect << 'EOF'
set timeout 300
set password "Dk7!vР9#Qm4\$Хe2@Hs8Zt"

spawn ssh root@api.siteledger.ai

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    "# " {
        send "cd /var/www/siteledger\r"
        expect "# "
        
        send "git pull origin main\r"
        expect "# "
        
        send "npm install --production\r"
        expect "# "
        
        send "pm2 restart siteledger-backend\r"
        expect "# "
        
        send "pm2 save\r"
        expect "# "
        
        send "exit\r"
    }
    timeout {
        puts "Connection timed out"
        exit 1
    }
    eof {
        puts "Connection closed"
        exit 0
    }
}

expect eof
EOF

echo ""
echo "✅ Backend deployed to production!"
echo "🌐 Changes will be live at https://siteledger.ai"
