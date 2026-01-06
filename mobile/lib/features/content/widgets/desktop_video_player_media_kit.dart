import 'package:flutter/material.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

String _getFullUrl(String url) {
  // If already a full URL (http/https), return as is
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  
  // If it's a Cloudinary URL (starts with res.cloudinary.com), add https://
  if (url.contains('cloudinary.com')) {
    return url.startsWith('https://') ? url : 'https://$url';
  }
  
  // If it's a relative path (starts with /uploads/), convert to full URL
  if (url.startsWith('/uploads/')) {
    // Remove /api/v1 from base URL if present
    String baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }
  
  return url;
}

Widget buildMediaKitVideoPlayer(String videoUrl, double? height, double? width) {
  final fullUrl = _getFullUrl(videoUrl);
  
  return _MediaKitVideoPlayerWidget(
    videoUrl: fullUrl,
    height: height ?? 200,
    width: width,
  );
}

class _MediaKitVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double height;
  final double? width;

  const _MediaKitVideoPlayerWidget({
    required this.videoUrl,
    required this.height,
    this.width,
  });

  @override
  State<_MediaKitVideoPlayerWidget> createState() => _MediaKitVideoPlayerWidgetState();
}

class _MediaKitVideoPlayerWidgetState extends State<_MediaKitVideoPlayerWidget> {
  late final Player player;
  late final VideoController controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      print('Initializing media_kit player with URL: ${widget.videoUrl}');
      // Initialize MediaKit Player
      player = Player();
      controller = VideoController(player);
      
      // Set video source
      player.open(Media(widget.videoUrl));
      
      // Listen for player state changes
      player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
      
      // Listen for errors
      player.stream.error.listen((error) {
        print('MediaKit player error: $error');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
      
      // Set initialized after player is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_hasError) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    } catch (e) {
      print('Error initializing media_kit player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white70, size: 48),
              SizedBox(height: 8),
              Text(
                'Không thể tải video',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 8),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: widget.height,
        width: widget.width ?? double.infinity,
        child: Video(
          controller: controller,
          controls: AdaptiveVideoControls,
        ),
      ),
    );
  }
}

