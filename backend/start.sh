#!/bin/bash

echo "========================================"
echo " EdTech AI MVP - Backend Starter"
echo "========================================"
echo ""

echo "[1/3] Checking port 3000..."

# Find process on port 3000
PID=$(netstat -ano 2>/dev/null | grep :3000 | grep LISTENING | awk '{print $5}' | head -1)

if [ ! -z "$PID" ]; then
    echo "Found process $PID on port 3000, killing it..."
    # Try Windows taskkill first, then Linux kill
    taskkill //F //PID $PID 2>/dev/null || kill -9 $PID 2>/dev/null
    sleep 2
fi

echo "[2/3] Port 3000 is free"
echo ""

echo "[3/3] Starting backend..."
cd "$(dirname "$0")"
npm start

