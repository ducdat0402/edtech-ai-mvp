const { exec } = require('child_process');
const os = require('os');

const port = process.env.PORT || 3000;

if (os.platform() === 'win32') {
  // Windows
  exec(`netstat -ano | findstr :${port}`, (error, stdout, stderr) => {
    if (stdout) {
      const lines = stdout.trim().split('\n');
      const pids = new Set();
      
      lines.forEach(line => {
        const parts = line.trim().split(/\s+/);
        const pid = parts[parts.length - 1];
        if (pid && !isNaN(pid)) {
          pids.add(pid);
        }
      });
      
      if (pids.size > 0) {
        console.log(`🔪 Killing processes on port ${port}: ${Array.from(pids).join(', ')}`);
        pids.forEach(pid => {
          exec(`taskkill /PID ${pid} /F`, (err) => {
            if (!err) {
              console.log(`✅ Killed process ${pid}`);
            }
          });
        });
        // Wait a bit for processes to be killed
        setTimeout(() => {
          console.log('✅ Port cleanup completed');
        }, 1000);
      } else {
        console.log(`✅ Port ${port} is free`);
      }
    } else {
      console.log(`✅ Port ${port} is free`);
    }
  });
} else {
  // Linux/Mac
  exec(`lsof -ti:${port}`, (error, stdout, stderr) => {
    if (stdout) {
      const pids = stdout.trim().split('\n').filter(Boolean);
      if (pids.length > 0) {
        console.log(`🔪 Killing processes on port ${port}: ${pids.join(', ')}`);
        pids.forEach(pid => {
          exec(`kill -9 ${pid}`, (err) => {
            if (!err) {
              console.log(`✅ Killed process ${pid}`);
            }
          });
        });
        setTimeout(() => {
          console.log('✅ Port cleanup completed');
        }, 1000);
      }
    } else {
      console.log(`✅ Port ${port} is free`);
    }
  });
}

