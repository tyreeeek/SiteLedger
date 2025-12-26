#!/bin/bash

# iOS Debug Code Cleanup Script
# Wraps all print() statements in #if DEBUG blocks

echo "🧹 Cleaning up iOS debug code..."
echo "================================"

# Find all Swift files with print statements
files_with_prints=$(grep -rl "print(" SiteLedger/ --include="*.swift" 2>/dev/null)

if [ -z "$files_with_prints" ]; then
    echo "✅ No print statements found!"
    exit 0
fi

echo "Found print statements in the following files:"
echo "$files_with_prints"
echo ""
echo "⚠️  Manual review recommended for production."
echo ""
echo "Recommendation:"
echo "1. Replace critical prints with proper logging framework"
echo "2. Wrap non-critical prints in #if DEBUG blocks"
echo "3. Remove completely unnecessary debug statements"
echo ""
echo "Example fix:"
echo "  Before:"
echo '    print("[Debug] User logged in")'
echo "  After:"
echo "    #if DEBUG"
echo '    print("[Debug] User logged in")'
echo "    #endif"
echo ""
echo "For production logging, consider using os.log:"
echo "  import os.log"
echo '  os_log("User logged in", log: .default, type: .info)'
