// API Configuration
// Change this based on your setup

class ApiConfig {
  // Option 1: Android Emulator (default)
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // Option 2: iOS Simulator
  // static const String baseUrl = 'http://localhost:3000/api/v1';

  // Option 3: Physical Device - Use your computer's IP
  // Find IP: Windows (ipconfig) or Mac/Linux (ifconfig)
  // Example: http://192.168.1.100:3000/api/v1

  // static const String baseUrl = 'http://26.213.113.234:3000/api/v1'; // Your current IP
  static const String baseUrl =
      'https://edtech-ai-mvp2.vercel.app/api/v1'; // Your current IP

  // Option 4: If 10.0.2.2 doesn't work, try localhost
  // static const String baseUrl = 'http://localhost:3000/api/v1';
}
