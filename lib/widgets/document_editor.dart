// lib/widgets/document_editor.dart
import 'package:flutter/material.dart';

class DocumentEditor extends StatelessWidget {
  final TextEditingController controller;
  final double fontSize;
  final ValueChanged<String> onChanged;

  const DocumentEditor({
    Key? key,
    required this.controller,
    required this.fontSize,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          style: TextStyle(fontSize: fontSize),
          decoration: const InputDecoration.collapsed(
            hintText: 'Start typing your document...',
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
