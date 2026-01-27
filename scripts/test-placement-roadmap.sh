#!/bin/bash

# Test Placement Test và Roadmap Generation
# Usage: ./scripts/test-placement-roadmap.sh

BASE_URL="http://localhost:3000/api/v1"
EMAIL="test@example.com"
PASSWORD="Test123!@#"

echo "🧪 Testing Placement Test & Roadmap Generation"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Login
echo -e "${BLUE}Step 1: Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

if ! echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
  echo -e "${RED}❌ Login failed. Creating new user...${NC}"
  REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"fullName\":\"Test User\"}")
  
  if echo "$REGISTER_RESPONSE" | grep -q "access_token"; then
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✅ User registered${NC}"
  else
    echo -e "${RED}❌ Registration failed${NC}"
    echo "$REGISTER_RESPONSE"
    exit 1
  fi
else
  TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
  echo -e "${GREEN}✅ Login successful${NC}"
fi

echo "Token: ${TOKEN:0:50}..."
echo ""

# Step 2: Get Explorer Subject ID
echo -e "${BLUE}Step 2: Get Explorer Subject${NC}"
SUBJECTS_RESPONSE=$(curl -s "$BASE_URL/subjects/explorer")
SUBJECT_ID=$(echo "$SUBJECTS_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$SUBJECT_ID" ]; then
  echo -e "${RED}❌ No subjects found. Run seed first!${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Found subject: $SUBJECT_ID${NC}"
echo ""

# Step 3: Start Placement Test
echo -e "${BLUE}Step 3: Start Placement Test${NC}"
TEST_START_RESPONSE=$(curl -s -X POST "$BASE_URL/test/start" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"subjectId\":\"$SUBJECT_ID\"}")

if echo "$TEST_START_RESPONSE" | grep -q "id"; then
  TEST_ID=$(echo "$TEST_START_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo -e "${GREEN}✅ Placement test started (ID: $TEST_ID)${NC}"
  
  # Get question count
  QUESTION_COUNT=$(echo "$TEST_START_RESPONSE" | grep -o '"questions":\[[^]]*\]' | grep -o 'questionId' | wc -l)
  echo "   Questions in test: $QUESTION_COUNT"
else
  echo -e "${RED}❌ Failed to start placement test${NC}"
  echo "$TEST_START_RESPONSE"
  exit 1
fi
echo ""

# Step 4: Answer Questions
echo -e "${BLUE}Step 4: Answer Questions${NC}"
QUESTION_NUM=1
COMPLETED=false

while [ "$COMPLETED" = false ]; do
  # Get current question
  CURRENT_RESPONSE=$(curl -s "$BASE_URL/test/current" \
    -H "Authorization: Bearer $TOKEN")
  
  if echo "$CURRENT_RESPONSE" | grep -q "No active test"; then
    echo -e "${YELLOW}⚠️  No active test found${NC}"
    break
  fi
  
  if echo "$CURRENT_RESPONSE" | grep -q "already completed"; then
    echo -e "${GREEN}✅ Test completed!${NC}"
    COMPLETED=true
    break
  fi
  
  # Extract question and options
  QUESTION_TEXT=$(echo "$CURRENT_RESPONSE" | grep -o '"question":"[^"]*' | head -1 | cut -d'"' -f4)
  OPTIONS_COUNT=$(echo "$CURRENT_RESPONSE" | grep -o '"options":\[[^]]*\]' | grep -o ',' | wc -l)
  OPTIONS_COUNT=$((OPTIONS_COUNT + 1))
  
  echo "   Question $QUESTION_NUM: ${QUESTION_TEXT:0:50}..."
  echo "   Options: $OPTIONS_COUNT"
  
  # Submit answer (random for testing, or use correct answer)
  # For testing, we'll use answer index 1 (second option)
  ANSWER=1
  echo "   Submitting answer: $ANSWER"
  
  SUBMIT_RESPONSE=$(curl -s -X POST "$BASE_URL/test/submit" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"answer\":$ANSWER}")
  
  if echo "$SUBMIT_RESPONSE" | grep -q "completed"; then
    echo -e "${GREEN}   ✅ Test completed!${NC}"
    COMPLETED=true
    
    # Extract score and level
    SCORE=$(echo "$SUBMIT_RESPONSE" | grep -o '"score":[0-9]*' | cut -d':' -f2)
    LEVEL=$(echo "$SUBMIT_RESPONSE" | grep -o '"level":"[^"]*' | cut -d'"' -f4)
    echo "   Final Score: $SCORE"
    echo "   Level: $LEVEL"
  else
    IS_CORRECT=$(echo "$SUBMIT_RESPONSE" | grep -o '"isCorrect":[^,}]*' | cut -d':' -f2)
    if [ "$IS_CORRECT" = "true" ]; then
      echo -e "   ${GREEN}✅ Correct!${NC}"
    else
      echo -e "   ${RED}❌ Incorrect${NC}"
    fi
    QUESTION_NUM=$((QUESTION_NUM + 1))
  fi
  
  echo ""
  
  # Safety check
  if [ $QUESTION_NUM -gt 15 ]; then
    echo -e "${YELLOW}⚠️  Too many questions, stopping${NC}"
    break
  fi
done

# Step 5: Get Test Result
echo -e "${BLUE}Step 5: Get Test Result${NC}"
if [ ! -z "$TEST_ID" ]; then
  RESULT_RESPONSE=$(curl -s "$BASE_URL/test/result/$TEST_ID" \
    -H "Authorization: Bearer $TOKEN")
  
  if echo "$RESULT_RESPONSE" | grep -q "score"; then
    SCORE=$(echo "$RESULT_RESPONSE" | grep -o '"score":[0-9]*' | cut -d':' -f2)
    LEVEL=$(echo "$RESULT_RESPONSE" | grep -o '"level":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✅ Test Result:${NC}"
    echo "   Score: $SCORE"
    echo "   Level: $LEVEL"
  else
    echo -e "${RED}❌ Failed to get result${NC}"
  fi
fi
echo ""

# Step 6: Generate Roadmap
echo -e "${BLUE}Step 6: Generate Roadmap${NC}"
ROADMAP_RESPONSE=$(curl -s -X POST "$BASE_URL/roadmap/generate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"subjectId\":\"$SUBJECT_ID\"}")

if echo "$ROADMAP_RESPONSE" | grep -q "id"; then
  ROADMAP_ID=$(echo "$ROADMAP_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  TOTAL_DAYS=$(echo "$ROADMAP_RESPONSE" | grep -o '"totalDays":[0-9]*' | cut -d':' -f2)
  CURRENT_DAY=$(echo "$ROADMAP_RESPONSE" | grep -o '"currentDay":[0-9]*' | cut -d':' -f2)
  
  echo -e "${GREEN}✅ Roadmap generated!${NC}"
  echo "   Roadmap ID: $ROADMAP_ID"
  echo "   Total Days: $TOTAL_DAYS"
  echo "   Current Day: $CURRENT_DAY"
else
  echo -e "${RED}❌ Failed to generate roadmap${NC}"
  echo "$ROADMAP_RESPONSE"
fi
echo ""

# Step 7: Get Today's Lesson
echo -e "${BLUE}Step 7: Get Today's Lesson${NC}"
if [ ! -z "$ROADMAP_ID" ]; then
  TODAY_RESPONSE=$(curl -s "$BASE_URL/roadmap/$ROADMAP_ID/today" \
    -H "Authorization: Bearer $TOKEN")
  
  if echo "$TODAY_RESPONSE" | grep -q "dayNumber"; then
    DAY_NUM=$(echo "$TODAY_RESPONSE" | grep -o '"dayNumber":[0-9]*' | cut -d':' -f2)
    STATUS=$(echo "$TODAY_RESPONSE" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
    echo -e "${GREEN}✅ Today's Lesson:${NC}"
    echo "   Day: $DAY_NUM"
    echo "   Status: $STATUS"
  else
    echo -e "${YELLOW}⚠️  No lesson for today${NC}"
  fi
fi
echo ""

# Step 8: Get Dashboard
echo -e "${BLUE}Step 8: Get Dashboard${NC}"
DASHBOARD_RESPONSE=$(curl -s "$BASE_URL/dashboard" \
  -H "Authorization: Bearer $TOKEN")

if echo "$DASHBOARD_RESPONSE" | grep -q "stats"; then
  echo -e "${GREEN}✅ Dashboard retrieved${NC}"
  # Extract stats
  XP=$(echo "$DASHBOARD_RESPONSE" | grep -o '"totalXP":[0-9]*' | cut -d':' -f2)
  COINS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"coins":[0-9]*' | cut -d':' -f2)
  STREAK=$(echo "$DASHBOARD_RESPONSE" | grep -o '"streak":[0-9]*' | cut -d':' -f2)
  echo "   XP: $XP"
  echo "   Coins: $COINS"
  echo "   Streak: $STREAK"
else
  echo -e "${RED}❌ Failed to get dashboard${NC}"
fi
echo ""

echo -e "${GREEN}✅ All tests completed!${NC}"

