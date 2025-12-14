#!/bin/bash

# API Testing Script
# Usage: ./scripts/test-api.sh

BASE_URL="http://localhost:3000/api/v1"
EMAIL="test@example.com"
PASSWORD="Test123!@#"

echo "🧪 Testing EdTech AI MVP API"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Register
echo -e "${YELLOW}1. Testing Register...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"fullName\":\"Test User\"}")

if echo "$REGISTER_RESPONSE" | grep -q "access_token"; then
  echo -e "${GREEN}✅ Register successful${NC}"
  TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
else
  echo -e "${YELLOW}⚠️  User might already exist, trying login...${NC}"
  # Try login instead
  LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
  
  if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    echo -e "${GREEN}✅ Login successful${NC}"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
  else
    echo -e "${RED}❌ Login failed${NC}"
    echo "$LOGIN_RESPONSE"
    exit 1
  fi
fi

echo "Token: ${TOKEN:0:50}..."
echo ""

# Test 2: Get Explorer Subjects
echo -e "${YELLOW}2. Testing Get Explorer Subjects...${NC}"
EXPLORER_RESPONSE=$(curl -s "$BASE_URL/subjects/explorer")
if echo "$EXPLORER_RESPONSE" | grep -q "IC3 GS6"; then
  echo -e "${GREEN}✅ Explorer subjects retrieved${NC}"
else
  echo -e "${RED}❌ Failed to get explorer subjects${NC}"
fi
echo ""

# Test 3: Get Dashboard
echo -e "${YELLOW}3. Testing Get Dashboard...${NC}"
DASHBOARD_RESPONSE=$(curl -s "$BASE_URL/dashboard" \
  -H "Authorization: Bearer $TOKEN")
if echo "$DASHBOARD_RESPONSE" | grep -q "stats"; then
  echo -e "${GREEN}✅ Dashboard retrieved${NC}"
else
  echo -e "${RED}❌ Failed to get dashboard${NC}"
  echo "$DASHBOARD_RESPONSE"
fi
echo ""

# Test 4: Get Currency
echo -e "${YELLOW}4. Testing Get Currency...${NC}"
CURRENCY_RESPONSE=$(curl -s "$BASE_URL/currency" \
  -H "Authorization: Bearer $TOKEN")
if echo "$CURRENCY_RESPONSE" | grep -q "coins"; then
  echo -e "${GREEN}✅ Currency retrieved${NC}"
else
  echo -e "${RED}❌ Failed to get currency${NC}"
fi
echo ""

# Test 5: Start Placement Test
echo -e "${YELLOW}5. Testing Start Placement Test...${NC}"
TEST_START_RESPONSE=$(curl -s -X POST "$BASE_URL/test/start" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{}")
if echo "$TEST_START_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✅ Placement test started${NC}"
  TEST_ID=$(echo "$TEST_START_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -1)
else
  echo -e "${RED}❌ Failed to start placement test${NC}"
  echo "$TEST_START_RESPONSE"
fi
echo ""

# Test 6: Get Daily Quests
echo -e "${YELLOW}6. Testing Get Daily Quests...${NC}"
QUESTS_RESPONSE=$(curl -s "$BASE_URL/quests/daily" \
  -H "Authorization: Bearer $TOKEN")
if echo "$QUESTS_RESPONSE" | grep -q "quests"; then
  echo -e "${GREEN}✅ Daily quests retrieved${NC}"
else
  echo -e "${RED}❌ Failed to get daily quests${NC}"
fi
echo ""

echo -e "${GREEN}✅ All tests completed!${NC}"

