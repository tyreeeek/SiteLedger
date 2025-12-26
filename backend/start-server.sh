#!/bin/bash

# SiteLedger Backend Startup Script
# Keeps the backend server running and restarts on crashes

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting SiteLedger Backend Server...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -q 2>/dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL doesn't appear to be running. Starting it...${NC}"
    brew services start postgresql@14 2>/dev/null || brew services start postgresql 2>/dev/null
    sleep 2
fi

# Kill any existing server process
if [ -f server.pid ]; then
    OLD_PID=$(cat server.pid)
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 Stopping existing server (PID: $OLD_PID)...${NC}"
        kill $OLD_PID 2>/dev/null
        sleep 1
    fi
    rm -f server.pid
fi

# Start the server in background with auto-restart
echo -e "${GREEN}✅ Starting server with auto-restart...${NC}"
echo -e "${GREEN}📍 Server URL: http://192.168.1.147:3000${NC}"
echo -e "${GREEN}💚 Health check: http://192.168.1.147:3000/health${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""

# Function to start server
start_server() {
    node src/index.js >> server.log 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > server.pid
    echo -e "${GREEN}▶️  Server started with PID: $SERVER_PID${NC}"
}

# Trap Ctrl+C
trap 'echo -e "\n${YELLOW}🛑 Shutting down server...${NC}"; kill $(cat server.pid 2>/dev/null) 2>/dev/null; rm -f server.pid; exit 0' INT TERM

# Start server and monitor
start_server

# Monitor and auto-restart
while true; do
    sleep 5
    
    if [ -f server.pid ]; then
        PID=$(cat server.pid)
        if ! ps -p $PID > /dev/null 2>&1; then
            echo -e "${RED}❌ Server crashed! Restarting in 3 seconds...${NC}"
            sleep 3
            start_server
        fi
    else
        echo -e "${RED}❌ PID file missing! Restarting server...${NC}"
        start_server
    fi
done
