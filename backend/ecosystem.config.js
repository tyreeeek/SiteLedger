module.exports = {
  apps: [{
    name: 'siteledger-backend',
    script: 'src/index.js',
    cwd: '/root/siteledger/backend',
    instances: 1,
    autorestart: true,
    watch: false, // Set to true for development auto-reload
    max_memory_restart: '500M',
    env_file: '.env', // Load environment variables from .env file
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    
    // Auto-restart settings
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000,
    
    // Advanced features
    listen_timeout: 3000,
    kill_timeout: 5000,
    wait_ready: false,
    
    // Graceful shutdown
    shutdown_with_message: false
  }]
};
