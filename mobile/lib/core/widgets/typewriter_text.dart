import 'package:flutter/material.dart';

/// Widget hiển thị text với hiệu ứng typewriter (gõ từng ký tự)
class TypeWriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final VoidCallback? onComplete;
  final bool autoStart;

  const TypeWriterText({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 30),
    this.onComplete,
    this.autoStart = true,
  });

  @override
  State<TypeWriterText> createState() => _TypeWriterTextState();
}

class _TypeWriterTextState extends State<TypeWriterText> {
  String _displayText = '';
  int _currentIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _startTyping();
    }
  }

  @override
  void didUpdateWidget(TypeWriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !widget.autoStart) {
      // Reset khi text thay đổi và autoStart = false
      setState(() {
        _displayText = '';
        _currentIndex = 0;
        _isComplete = false;
      });
      if (widget.autoStart) {
        _startTyping();
      }
    }
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      setState(() {
        _isComplete = true;
      });
      widget.onComplete?.call();
      return;
    }

    _typeNextChar();
  }

  void _typeNextChar() {
    if (_currentIndex < widget.text.length) {
      setState(() {
        _displayText = widget.text.substring(0, _currentIndex + 1);
        _currentIndex++;
      });

      // Tính toán delay dựa trên ký tự (nhanh hơn cho khoảng trắng và dấu câu)
      Duration delay = widget.speed;
      if (_currentIndex < widget.text.length) {
        final char = widget.text[_currentIndex];
        if (char == ' ' || char == '\n') {
          delay = Duration(milliseconds: widget.speed.inMilliseconds ~/ 2);
        } else if (char == '.' || char == '!' || char == '?') {
          delay = Duration(milliseconds: widget.speed.inMilliseconds * 2);
        } else if (char == ',' || char == ';' || char == ':') {
          delay = Duration(milliseconds: (widget.speed.inMilliseconds * 1.5).round());
        }
      }

      Future.delayed(delay, _typeNextChar);
    } else {
      setState(() {
        _isComplete = true;
      });
      widget.onComplete?.call();
    }
  }

  /// Bắt đầu lại animation từ đầu
  void restart() {
    setState(() {
      _displayText = '';
      _currentIndex = 0;
      _isComplete = false;
    });
    _startTyping();
  }

  /// Skip animation và hiển thị toàn bộ text ngay lập tức
  void skip() {
    if (!_isComplete) {
      setState(() {
        _displayText = widget.text;
        _currentIndex = widget.text.length;
        _isComplete = true;
      });
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isComplete ? null : skip, // Tap để skip animation
      child: Text(
        _displayText,
        style: widget.style,
      ),
    );
  }
}
