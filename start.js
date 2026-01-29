// Safe start script - kills process on port 3000 before starting
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

async function killPort3000() {
  try {
    // Windows
    const { stdout } = await execAsync('netstat -ano | findstr :3000 | findstr LISTENING');
    const lines = stdout.trim().split('\n');
    
    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      const pid = parts[parts.length - 1];
      if (pid && !isNaN(pid)) {
        console.log(`Killing process ${pid} on port 3000...`);
        try {
          await execAsync(`taskkill /F /PID ${pid}`);
          console.log(`✅ Process ${pid} killed`);
        } catch (e) {
          // Process might already be dead
        }
      }
    }
    
    // Wait a bit for port to be released
    await new Promise(resolve => setTimeout(resolve, 2000));
  } catch (e) {
    // No process found or error - that's OK
    console.log('Port 3000 is free');
  }
}

async function start() {
  console.log('🔍 Checking port 3000...');
  await killPort3000();
  console.log('🚀 Starting backend...');
  
  // Start NestJS
  const { spawn } = require('child_process');
  const child = spawn('npm', ['run', 'start:dev'], {
    stdio: 'inherit',
    shell: true,
  });
  
  child.on('error', (err) => {
    console.error('Failed to start:', err);
    process.exit(1);
  });
}

start();

