import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inline emoji bar to insert emojis into the message field.
class EmojiBar extends StatelessWidget {
  final void Function(String emoji) onEmojiTap;

  const EmojiBar({super.key, required this.onEmojiTap});

  static const List<String> _emojis = [
    '😀', '😂', '❤️', '👍', '👋', '🎉', '🔥', '✨', '😢', '🙏',
    '😊', '🥳', '💪', '👏', '🤔', '😎', '💯', '🌟', '💬', '✅',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _emojis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onEmojiTap(emoji);
              },
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
