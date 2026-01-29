#!/bin/bash
echo "Killing process on port 3000..."

# Find and kill process on port 3000
PID=$(netstat -ano | grep :3000 | grep LISTENING | awk '{print $5}' | head -1)

if [ ! -z "$PID" ]; then
    echo "Found process $PID"
    # Try Windows taskkill first
    taskkill //F //PID $PID 2>/dev/null || kill -9 $PID 2>/dev/null
    echo "Process killed!"
    sleep 2
else
    echo "No process found on port 3000"
fi

echo "Port 3000 should be free now"
echo "You can now run: npm start"

