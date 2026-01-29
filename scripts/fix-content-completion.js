// Debug script for content completion
const http = require('http');

const BASE_URL = 'http://localhost:3000/api/v1';
const EMAIL = 'test@example.com';
const PASSWORD = 'Test123!@#';

let token = '';

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

async function debug() {
  console.log('🔍 Debugging Content Completion...\n');

  // Login
  const loginRes = await makeRequest('POST', '/auth/login', {
    email: EMAIL,
    password: PASSWORD,
  });
  token = loginRes.data.accessToken;
  console.log('✅ Logged in');

  // Get subjects
  const subjectsRes = await makeRequest('GET', '/subjects/explorer');
  console.log(`\n📚 Found ${subjectsRes.data.length} subjects`);

  // Find subject with nodes that have content items
  for (const subject of subjectsRes.data) {
    console.log(`\n🔍 Checking subject: ${subject.name}`);
    
    const nodesRes = await makeRequest('GET', `/nodes/subject/${subject.id}`);
    console.log(`   Nodes: ${nodesRes.data.length}`);

    for (const node of nodesRes.data) {
      const itemsRes = await makeRequest('GET', `/content/node/${node.id}`, null, true);
      console.log(`   Node "${node.title}": ${itemsRes.data.length} items`);

      if (itemsRes.data.length > 0) {
        const item = itemsRes.data[0];
        console.log(`\n✅ Found item: ${item.title} (type: ${item.type}, id: ${item.id})`);
        
        // Try to complete
        console.log(`\n🔄 Attempting to complete item...`);
        const completeRes = await makeRequest('POST', '/progress/complete-item', {
          nodeId: node.id,
          contentItemId: item.id,
          itemType: item.type,
        }, true);

        console.log(`   Status: ${completeRes.status}`);
        if (completeRes.status === 200 || completeRes.status === 201) {
          console.log(`   ✅ Success!`);
          console.log(`   Rewards:`, completeRes.data.rewards);
        } else {
          console.log(`   ❌ Error:`, JSON.stringify(completeRes.data, null, 2));
        }
        return;
      }
    }
  }
}

debug().catch(console.error);

