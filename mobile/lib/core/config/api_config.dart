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

//  static const String baseUrl = 'http://localhost:3000/api/v1';
  static const String baseUrl =
      // 'https://edtech-ai-backend-tbq7.onrender.com/api/v1';
      'https://api.gamistu.com/api/v1';

  /// URL đầy đủ để tải ảnh/static (API nằm dưới `/api/v1`, file tĩnh thường ở gốc host).
  static String absoluteMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    var origin = baseUrl.trim();
    if (origin.endsWith('/')) {
      origin = origin.substring(0, origin.length - 1);
    }
    if (origin.endsWith('/api/v1')) {
      origin = origin.substring(0, origin.length - 7);
    }
    final seg = p.startsWith('/') ? p : '/$p';
    return '$origin$seg';
  }

  /// Base URL without /api/v1 (for Socket.IO)
  static String get serverUrl {
    const u = baseUrl;
    if (u.endsWith('/api/v1')) return u.substring(0, u.length - 7);
    if (u.endsWith('/api/v1/')) return u.substring(0, u.length - 8);
    return u;
  }

  // Option 4: If 10.0.2.2 doesn't work, try localhost
  // static const String baseUrl = 'http://localhost:3000/api/v1';
}
