// lib/widgets/formatting_toolbar.dart
import 'package:flutter/material.dart';

class FormattingToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalics;
  final VoidCallback onBullet;
  final VoidCallback onHeading;
  final VoidCallback onFontSize;
  final VoidCallback onPreview;

  const FormattingToolbar({
    Key? key,
    required this.onBold,
    required this.onItalics,
    required this.onBullet,
    required this.onHeading,
    required this.onFontSize,
    required this.onPreview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      // If withOpacity is deprecated, use withAlpha:
      color: Theme.of(context).colorScheme.secondary.withAlpha((0.1 * 255).round()),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              tooltip: 'Bold',
              onPressed: onBold,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              tooltip: 'Italics',
              onPressed: onItalics,
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              tooltip: 'Bullet List',
              onPressed: onBullet,
            ),
            IconButton(
              icon: const Icon(Icons.title),
              tooltip: 'Heading',
              onPressed: onHeading,
            ),
            IconButton(
              icon: const Icon(Icons.format_size),
              tooltip: 'Font Size',
              onPressed: onFontSize,
            ),
            IconButton(
              icon: const Icon(Icons.remove_red_eye),
              tooltip: 'Preview',
              onPressed: onPreview,
            ),
          ],
        ),
      ),
    );
  }
}
