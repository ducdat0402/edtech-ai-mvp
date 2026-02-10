import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edtech_mobile/theme/colors.dart';

/// A fullscreen image viewer with zoom/pan and optional gallery swipe.
///
/// Usage:
/// ```dart
/// FullscreenImageViewer.show(
///   context: context,
///   imageUrls: ['url1', 'url2', 'url3'],
///   initialIndex: 0,
///   captions: ['Caption 1', 'Caption 2', 'Caption 3'], // optional
/// );
/// ```
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final List<String>? captions;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.captions,
  });

  /// Convenience method to open the viewer as a fullscreen overlay.
  static void show({
    required BuildContext context,
    required List<String> imageUrls,
    int initialIndex = 0,
    List<String>? captions,
  }) {
    if (imageUrls.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullscreenImageViewer(
              imageUrls: imageUrls,
              initialIndex: initialIndex,
              captions: captions,
            ),
          );
        },
      ),
    );
  }

  /// Convenience for a single image.
  static void showSingle({
    required BuildContext context,
    required String imageUrl,
    String? caption,
  }) {
    show(
      context: context,
      imageUrls: [imageUrl],
      initialIndex: 0,
      captions: caption != null ? [caption] : null,
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;
  late AnimationController _uiAnimController;
  late Animation<double> _uiOpacity;

  // Track interactive viewer state per page to reset on swipe
  final Map<int, TransformationController> _transformControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    _uiAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _uiOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _uiAnimController, curve: Curves.easeInOut),
    );

    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _uiAnimController.dispose();
    for (final c in _transformControllers.values) {
      c.dispose();
    }
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  TransformationController _getTransformController(int index) {
    return _transformControllers.putIfAbsent(
        index, () => TransformationController());
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (_showUI) {
        _uiAnimController.reverse();
      } else {
        _uiAnimController.forward();
      }
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isGallery = widget.imageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          children: [
            // ── Image pages ──
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              physics: isGallery
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                // Reset zoom of previous page
                final prev = _transformControllers[_currentIndex];
                if (prev != null) {
                  prev.value = Matrix4.identity();
                }
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final url = widget.imageUrls[index];
                return _buildZoomableImage(index, url);
              },
            ),

            // ── Top bar: close + counter ──
            AnimatedBuilder(
              animation: _uiOpacity,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0 - _uiOpacity.value,
                  child: IgnorePointer(
                    ignoring: !_showUI,
                    child: child,
                  ),
                );
              },
              child: _buildTopBar(isGallery),
            ),

            // ── Bottom: caption + page dots ──
            if (_hasCaption || isGallery)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _uiOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 1.0 - _uiOpacity.value,
                      child: IgnorePointer(
                        ignoring: !_showUI,
                        child: child,
                      ),
                    );
                  },
                  child: _buildBottomBar(isGallery),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _hasCaption {
    if (widget.captions == null) return false;
    if (_currentIndex >= widget.captions!.length) return false;
    return widget.captions![_currentIndex].isNotEmpty;
  }

  String get _currentCaption {
    if (widget.captions == null) return '';
    if (_currentIndex >= widget.captions!.length) return '';
    return widget.captions![_currentIndex];
  }

  Widget _buildZoomableImage(int index, String url) {
    final controller = _getTransformController(index);

    return InteractiveViewer(
      transformationController: controller,
      maxScale: 5.0,
      minScale: 0.5,
      panEnabled: true,
      scaleEnabled: true,
      onInteractionEnd: (details) {
        // If zoomed out too much, snap back
        final scale = controller.value.getMaxScaleOnAxis();
        if (scale < 0.9) {
          controller.value = Matrix4.identity();
        }
      },
      child: Center(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final progress = loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: progress,
                            color: AppColors.purpleNeon,
                            strokeWidth: 3,
                          ),
                        ),
                        if (progress != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: AppColors.textTertiary, size: 64),
                      SizedBox(height: 12),
                      Text(
                        'Không thể tải hình ảnh',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(
                child: Icon(Icons.image_not_supported,
                    color: AppColors.textTertiary, size: 64),
              ),
      ),
    );
  }

  Widget _buildTopBar(bool isGallery) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Close button
            _buildCircleButton(
              icon: Icons.close,
              onTap: _close,
            ),
            const Spacer(),
            // Page counter for gallery
            if (isGallery)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
            // Placeholder for symmetry
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isGallery) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caption
          if (_hasCaption)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _currentCaption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Page dots for gallery
          if (isGallery && widget.imageUrls.length <= 20)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.purpleNeon
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
