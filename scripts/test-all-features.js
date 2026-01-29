// Comprehensive test script for all backend features
const http = require('http');

const BASE_URL = 'http://localhost:3000/api/v1';
const EMAIL = 'test@example.com';
const PASSWORD = 'Test123!@#';

let token = '';
let testResults = {
  passed: 0,
  failed: 0,
  errors: [],
};

function makeRequest(method, path, data = null, useAuth = false) {
  return new Promise((resolve, reject) => {
    if (!path.startsWith('/')) {
      path = '/' + path;
    }
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port || 3000,
      path: url.pathname,
      method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (useAuth && token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

function test(name, fn) {
  return async () => {
    try {
      await fn();
      testResults.passed++;
      console.log(`✅ ${name}`);
      return true;
    } catch (error) {
      testResults.failed++;
      testResults.errors.push({ name, error: error.message });
      console.log(`❌ ${name}: ${error.message}`);
      return false;
    }
  };
}

async function runTests() {
  console.log('🧪 Comprehensive Backend Feature Tests\n');
  console.log('='.repeat(60));

  // Test 1: Health Check
  await test('Health Check', async () => {
    const response = await makeRequest('GET', '/health');
    if (response.status !== 200 || response.data.status !== 'ok') {
      throw new Error('Health check failed');
    }
  })();

  // Test 2: Login
  await test('Login', async () => {
    const response = await makeRequest('POST', '/auth/login', {
      email: EMAIL,
      password: PASSWORD,
    });
    if (!response.data.accessToken) {
      throw new Error('Login failed');
    }
    token = response.data.accessToken;
  })();

  if (!token) {
    console.log('\n❌ Cannot continue without authentication');
    return;
  }

  // Test 3: Get Explorer Subjects
  await test('Get Explorer Subjects', async () => {
    const response = await makeRequest('GET', '/subjects/explorer');
    if (response.status !== 200 || !Array.isArray(response.data)) {
      throw new Error('Failed to get explorer subjects');
    }
  })();

  // Test 4: Get Dashboard
  await test('Get Dashboard', async () => {
    const response = await makeRequest('GET', '/dashboard', null, true);
    if (response.status !== 200 || !response.data.stats) {
      throw new Error('Failed to get dashboard');
    }
  })();

  // Test 5: Get Currency
  await test('Get Currency', async () => {
    const response = await makeRequest('GET', '/currency', null, true);
    if (response.status !== 200 || typeof response.data.xp !== 'number') {
      throw new Error('Failed to get currency');
    }
  })();

  // Test 6: Get Daily Quests
  await test('Get Daily Quests', async () => {
    const response = await makeRequest('GET', '/quests/daily', null, true);
    if (response.status !== 200) {
      throw new Error('Failed to get daily quests');
    }
  })();

  // Test 7: Get Global Leaderboard
  await test('Get Global Leaderboard', async () => {
    const response = await makeRequest('GET', '/leaderboard/global?limit=10');
    if (response.status !== 200 || !response.data.entries) {
      throw new Error('Failed to get leaderboard');
    }
  })();

  // Test 8: Get Weekly Leaderboard
  await test('Get Weekly Leaderboard', async () => {
    const response = await makeRequest('GET', '/leaderboard/weekly?limit=10', null, true);
    if (response.status !== 200 || !response.data.entries) {
      throw new Error('Failed to get weekly leaderboard');
    }
  })();

  // Test 9: Get My Rank
  await test('Get My Rank', async () => {
    const response = await makeRequest('GET', '/leaderboard/me', null, true);
    if (response.status !== 200 || typeof response.data.globalRank !== 'number') {
      throw new Error('Failed to get user rank');
    }
  })();

  // Test 10: Start Placement Test
  let testId = null;
  await test('Start Placement Test', async () => {
    const subjectsResponse = await makeRequest('GET', '/subjects/explorer');
    if (subjectsResponse.data && subjectsResponse.data.length > 0) {
      const subjectId = subjectsResponse.data[0].id;
      const response = await makeRequest(
        'POST',
        '/test/start',
        { subjectId },
        true,
      );
      if (response.status === 200 || response.status === 201) {
        testId = response.data.id;
      } else {
        throw new Error('Failed to start placement test');
      }
    }
  })();

  // Test 11: Get Current Test
  await test('Get Current Test', async () => {
    const response = await makeRequest('GET', '/test/current', null, true);
    if (response.status !== 200 && response.data.message !== 'No active test') {
      throw new Error('Failed to get current test');
    }
  })();

  // Test 12: Get Scholar Subjects
  await test('Get Scholar Subjects', async () => {
    const response = await makeRequest('GET', '/subjects/scholar', null, true);
    if (response.status !== 200 || !Array.isArray(response.data)) {
      throw new Error('Failed to get scholar subjects');
    }
  })();

  // Test 13: Get Onboarding Status
  await test('Get Onboarding Status', async () => {
    const response = await makeRequest('GET', '/onboarding/status', null, true);
    if (response.status !== 200) {
      throw new Error('Failed to get onboarding status');
    }
  })();

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 Test Summary:');
  console.log(`   ✅ Passed: ${testResults.passed}`);
  console.log(`   ❌ Failed: ${testResults.failed}`);
  console.log(`   📈 Success Rate: ${((testResults.passed / (testResults.passed + testResults.failed)) * 100).toFixed(1)}%`);

  if (testResults.errors.length > 0) {
    console.log('\n❌ Errors:');
    testResults.errors.forEach((err) => {
      console.log(`   - ${err.name}: ${err.error}`);
    });
  }

  if (testResults.failed === 0) {
    console.log('\n🎉 All tests passed! Backend is ready!');
  }
}

runTests().catch(console.error);

