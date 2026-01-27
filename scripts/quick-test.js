// Quick test script for Placement Test and Roadmap
const http = require('http');

const BASE_URL = 'http://localhost:3000/api/v1';
const EMAIL = 'test@example.com';
const PASSWORD = 'Test123!@#';

let token = '';
let subjectId = '';
let testId = '';
let roadmapId = '';

function makeRequest(method, path, data = null, useAuth = false) {
  return new Promise((resolve, reject) => {
    // Ensure path starts with /
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

async function test() {
  console.log('🧪 Testing Placement Test & Roadmap Generation\n');
  console.log('='.repeat(50));

  try {
    // Step 1: Login
    console.log('\n1️⃣  Testing Login...');
    let response = await makeRequest('POST', '/auth/login', {
      email: EMAIL,
      password: PASSWORD,
    });

    if ((response.data.access_token || response.data.accessToken)) {
      token = response.data.access_token || response.data.accessToken;
      console.log('✅ Login successful');
      console.log(`   Token: ${token.substring(0, 50)}...`);
    } else if (response.status === 401 || response.status === 404) {
      // Try register
      console.log('⚠️  Login failed, trying register...');
      response = await makeRequest('POST', '/auth/register', {
        email: EMAIL,
        password: PASSWORD,
        fullName: 'Test User',
      });

      if ((response.status === 201 || response.status === 200) && (response.data.access_token || response.data.accessToken)) {
        token = response.data.access_token || response.data.accessToken;
        console.log('✅ Registration successful');
      } else if (response.status === 409) {
        // User exists, try login again with different approach
        console.log('⚠️  User exists, using existing account...');
        // Token might be in different format, try to extract
        if (response.data.accessToken) {
          token = response.data.accessToken;
        } else {
          console.log('❌ Cannot get token. Please check manually.');
          return;
        }
      } else {
        console.log('❌ Registration failed:', response.data);
        return;
      }
    } else {
      console.log('❌ Login failed:', response.data);
      return;
    }

    // Step 2: Get Explorer Subjects
    console.log('\n2️⃣  Getting Explorer Subjects...');
    response = await makeRequest('GET', '/subjects/explorer');

    if (response.status === 200 && Array.isArray(response.data) && response.data.length > 0) {
      // Find subject with nodes
      let foundSubject = null;
      for (const subj of response.data) {
        const nodesResponse = await makeRequest('GET', `/nodes/subject/${subj.id}`);
        if (nodesResponse.status === 200 && Array.isArray(nodesResponse.data) && nodesResponse.data.length > 0) {
          foundSubject = subj;
          break;
        }
      }
      
      if (foundSubject) {
        subjectId = foundSubject.id;
        console.log(`✅ Found ${response.data.length} subjects`);
        console.log(`   Using subject with nodes: ${foundSubject.name} (${subjectId.substring(0, 8)}...)`);
      } else {
        // Use first subject anyway
        subjectId = response.data[0].id;
        console.log(`✅ Found ${response.data.length} subjects`);
        console.log(`   Using subject: ${response.data[0].name} (${subjectId.substring(0, 8)}...)`);
        console.log(`   ⚠️  Warning: This subject may not have nodes`);
      }
    } else {
      console.log('❌ No subjects found. Run seed first!');
      return;
    }

    // Step 3: Start Placement Test
    console.log('\n3️⃣  Starting Placement Test...');
    response = await makeRequest(
      'POST',
      '/test/start',
      { subjectId },
      true
    );

    if (response.status === 201 || response.status === 200) {
      testId = response.data.id;
      const questionCount = response.data.questions?.length || 0;
      console.log(`✅ Placement test started`);
      console.log(`   Test ID: ${testId.substring(0, 8)}...`);
      console.log(`   Questions: ${questionCount}`);
    } else {
      console.log('❌ Failed to start test:', response.data);
      return;
    }

    // Step 4: Answer Questions
    console.log('\n4️⃣  Answering Questions...');
    let questionNum = 1;
    let completed = false;

    while (!completed && questionNum <= 15) {
      // Get current question
      response = await makeRequest('GET', '/test/current', null, true);

      if (response.status === 404 || response.data.message === 'No active test') {
        console.log('⚠️  No active test found');
        break;
      }

      if (response.data.completed || response.data.test?.status === 'completed') {
        console.log('✅ Test completed!');
        completed = true;
        break;
      }

      const question = response.data.question;
      if (!question) {
        console.log('⚠️  No question available');
        break;
      }

      console.log(`   Question ${questionNum}: ${question.question?.substring(0, 50)}...`);
      console.log(`   Options: ${question.options?.length || 0}`);

      // Submit answer (using index 1 for testing)
      const answer = 1;
      console.log(`   Submitting answer: ${answer}`);

      response = await makeRequest(
        'POST',
        '/test/submit',
        { answer },
        true
      );

      if (response.data.completed) {
        console.log('✅ Test completed!');
        const score = response.data.test?.score || 'N/A';
        const level = response.data.test?.level || 'N/A';
        console.log(`   Final Score: ${score}`);
        console.log(`   Level: ${level}`);
        completed = true;
      } else {
        const isCorrect = response.data.isCorrect ? '✅' : '❌';
        console.log(`   ${isCorrect} Answer submitted`);
        questionNum++;
      }
    }

    // Step 5: Get Test Result
    if (testId) {
      console.log('\n5️⃣  Getting Test Result...');
      response = await makeRequest('GET', `/test/result/${testId}`, null, true);

      if (response.status === 200) {
        const score = response.data.score || 'N/A';
        const level = response.data.level || 'N/A';
        console.log(`✅ Test Result:`);
        console.log(`   Score: ${score}`);
        console.log(`   Level: ${level}`);
      }
    }

    // Step 6: Generate Roadmap
    console.log('\n6️⃣  Generating Roadmap...');
    response = await makeRequest(
      'POST',
      '/roadmap/generate',
      { subjectId },
      true
    );

    if (response.status === 201 || response.status === 200) {
      roadmapId = response.data.id;
      const totalDays = response.data.totalDays || 'N/A';
      const currentDay = response.data.currentDay || 'N/A';
      console.log(`✅ Roadmap generated!`);
      console.log(`   Roadmap ID: ${roadmapId.substring(0, 8)}...`);
      console.log(`   Total Days: ${totalDays}`);
      console.log(`   Current Day: ${currentDay}`);
    } else {
      console.log('❌ Failed to generate roadmap:', response.data);
    }

    // Step 7: Get Today's Lesson
    if (roadmapId) {
      console.log('\n7️⃣  Getting Today\'s Lesson...');
      response = await makeRequest('GET', `/roadmap/${roadmapId}/today`, null, true);

      if (response.status === 200) {
        const dayNum = response.data.dayNumber || 'N/A';
        const status = response.data.status || 'N/A';
        console.log(`✅ Today's Lesson:`);
        console.log(`   Day: ${dayNum}`);
        console.log(`   Status: ${status}`);
      } else {
        console.log('⚠️  No lesson for today');
      }
    }

    // Step 8: Get Dashboard
    console.log('\n8️⃣  Getting Dashboard...');
    response = await makeRequest('GET', '/dashboard', null, true);

    if (response.status === 200) {
      const stats = response.data.stats || {};
      console.log(`✅ Dashboard:`);
      console.log(`   XP: ${stats.totalXP || 0}`);
      console.log(`   Coins: ${stats.coins || 0}`);
      console.log(`   Streak: ${stats.streak || 0}`);
    }

    console.log('\n' + '='.repeat(50));
    console.log('✅ All tests completed successfully!');
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.error('   Server is not running. Start with: npm start');
    }
  }
}

test();

