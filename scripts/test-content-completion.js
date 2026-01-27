// Test Content Completion Flow
const http = require('http');

const BASE_URL = 'http://localhost:3000/api/v1';
const EMAIL = 'test@example.com';
const PASSWORD = 'Test123!@#';

let token = '';
let subjectId = '';
let nodeId = '';
let contentItems = [];

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

async function test() {
  console.log('🧪 Testing Content Completion Flow\n');
  console.log('='.repeat(50));

  try {
    // Step 1: Login
    console.log('\n1️⃣  Login...');
    let response = await makeRequest('POST', '/auth/login', {
      email: EMAIL,
      password: PASSWORD,
    });

    if (response.data.accessToken) {
      token = response.data.accessToken;
      console.log('✅ Login successful');
    } else {
      console.log('❌ Login failed:', response.data);
      return;
    }

    // Step 2: Get Explorer Subject with nodes
    console.log('\n2️⃣  Getting Explorer Subject...');
    response = await makeRequest('GET', '/subjects/explorer');

    if (response.status === 200 && Array.isArray(response.data) && response.data.length > 0) {
      // Find subject with nodes that have content items
      for (const subj of response.data) {
        const nodesResponse = await makeRequest('GET', `/nodes/subject/${subj.id}`);
        if (nodesResponse.status === 200 && Array.isArray(nodesResponse.data) && nodesResponse.data.length > 0) {
          // Check each node for content items
          for (const node of nodesResponse.data) {
            const itemsResponse = await makeRequest('GET', `/content/node/${node.id}`);
            if (itemsResponse.status === 200 && Array.isArray(itemsResponse.data) && itemsResponse.data.length > 0) {
              subjectId = subj.id;
              nodeId = node.id;
              console.log(`✅ Found subject: ${subj.name}`);
              console.log(`   Node: ${node.title} (${nodeId.substring(0, 8)}...)`);
              console.log(`   Content Items: ${itemsResponse.data.length}`);
              break;
            }
          }
          if (nodeId) break;
        }
      }

      if (!nodeId) {
        console.log('❌ No nodes found');
        return;
      }
    } else {
      console.log('❌ No subjects found');
      return;
    }

    // Step 3: Get Content Items
    console.log('\n3️⃣  Getting Content Items...');
    response = await makeRequest('GET', `/content/node/${nodeId}`, null, true);

    if (response.status === 200 && Array.isArray(response.data)) {
      contentItems = response.data;
      console.log(`✅ Found ${contentItems.length} content items`);
      
      // Group by type
      const byType = {
        concept: contentItems.filter(i => i.type === 'concept'),
        example: contentItems.filter(i => i.type === 'example'),
        hidden_reward: contentItems.filter(i => i.type === 'hidden_reward'),
        boss_quiz: contentItems.filter(i => i.type === 'boss_quiz'),
      };
      
      console.log(`   Concepts: ${byType.concept.length}`);
      console.log(`   Examples: ${byType.example.length}`);
      console.log(`   Hidden Rewards: ${byType.hidden_reward.length}`);
      console.log(`   Boss Quiz: ${byType.boss_quiz.length}`);
    } else {
      console.log('❌ Failed to get content items');
      return;
    }

    // Step 4: Get Initial Progress
    console.log('\n4️⃣  Getting Initial Progress...');
    response = await makeRequest('GET', `/progress/node/${nodeId}`, null, true);

    if (response.status === 200) {
      const hud = response.data.hud;
      console.log('✅ Progress retrieved:');
      console.log(`   Concepts: ${hud.concepts.completed}/${hud.concepts.total}`);
      console.log(`   Examples: ${hud.examples.completed}/${hud.examples.total}`);
      console.log(`   Hidden Rewards: ${hud.hiddenRewards.completed}/${hud.hiddenRewards.total}`);
      console.log(`   Boss Quiz: ${hud.bossQuiz.completed}/${hud.bossQuiz.total}`);
      console.log(`   Overall: ${hud.progressPercentage.toFixed(1)}%`);
    }

    // Step 5: Get Initial Currency
    console.log('\n5️⃣  Getting Initial Currency...');
    response = await makeRequest('GET', '/currency', null, true);

    if (response.status === 200) {
      console.log('✅ Currency:');
      console.log(`   XP: ${response.data.xp || 0}`);
      console.log(`   Coins: ${response.data.coins || 0}`);
      console.log(`   Streak: ${response.data.currentStreak || 0}`);
    }

    // Step 6: Complete Content Items
    console.log('\n6️⃣  Completing Content Items...');
    
    let totalXP = 0;
    let totalCoins = 0;
    let completedCount = 0;

    // Complete first concept
    if (contentItems.find(i => i.type === 'concept')) {
      const concept = contentItems.find(i => i.type === 'concept');
      console.log(`   Completing concept: ${concept.title.substring(0, 30)}...`);
      
      response = await makeRequest('POST', '/progress/complete-item', {
        nodeId,
        contentItemId: concept.id,
        itemType: 'concept',
      }, true);

      if (response.status === 200 || response.status === 201) {
        const rewards = response.data.rewards;
        totalXP += rewards.xp || 0;
        totalCoins += rewards.coins || 0;
        completedCount++;
        console.log(`   ✅ Completed! Rewards: +${rewards.xp || 0} XP, +${rewards.coins || 0} Coins`);
      } else {
        console.log(`   ❌ Failed:`, response.data);
      }
    }

    // Complete first example
    if (contentItems.find(i => i.type === 'example')) {
      const example = contentItems.find(i => i.type === 'example');
      console.log(`   Completing example: ${example.title.substring(0, 30)}...`);
      
      response = await makeRequest('POST', '/progress/complete-item', {
        nodeId,
        contentItemId: example.id,
        itemType: 'example',
      }, true);

      if (response.status === 200 || response.status === 201) {
        const rewards = response.data.rewards;
        totalXP += rewards.xp || 0;
        totalCoins += rewards.coins || 0;
        completedCount++;
        console.log(`   ✅ Completed! Rewards: +${rewards.xp || 0} XP, +${rewards.coins || 0} Coins`);
      }
    }

    // Step 7: Check Updated Progress
    console.log('\n7️⃣  Checking Updated Progress...');
    response = await makeRequest('GET', `/progress/node/${nodeId}`, null, true);

    if (response.status === 200) {
      const hud = response.data.hud;
      console.log('✅ Updated Progress:');
      console.log(`   Concepts: ${hud.concepts.completed}/${hud.concepts.total}`);
      console.log(`   Examples: ${hud.examples.completed}/${hud.examples.total}`);
      console.log(`   Overall: ${hud.progressPercentage.toFixed(1)}%`);
      console.log(`   Completed: ${hud.isCompleted ? 'Yes' : 'No'}`);
    }

    // Step 8: Check Updated Currency
    console.log('\n8️⃣  Checking Updated Currency...');
    response = await makeRequest('GET', '/currency', null, true);

    if (response.status === 200) {
      console.log('✅ Updated Currency:');
      console.log(`   XP: ${response.data.xp || 0} (+${totalXP})`);
      console.log(`   Coins: ${response.data.coins || 0} (+${totalCoins})`);
      console.log(`   Streak: ${response.data.currentStreak || 0}`);
    }

    // Step 9: Check Daily Quests Progress
    console.log('\n9️⃣  Checking Daily Quests...');
    response = await makeRequest('GET', '/quests/daily', null, true);

    if (response.status === 200) {
      const quests = response.data.quests || response.data || [];
      console.log(`✅ Found ${quests.length} daily quests`);
      
      const completeItemsQuest = quests.find(q => q.type === 'complete_items');
      if (completeItemsQuest) {
        console.log(`   Complete Items Quest: ${completeItemsQuest.progress}/${completeItemsQuest.requirements.count}`);
      }
    }

    console.log('\n' + '='.repeat(50));
    console.log(`✅ Test completed! Completed ${completedCount} items`);
    console.log(`   Total Rewards: +${totalXP} XP, +${totalCoins} Coins`);

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.error('   Server is not running. Start with: npm start');
    }
  }
}

test();

