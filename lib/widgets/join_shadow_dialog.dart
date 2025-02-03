// lib/widgets/join_shadow_dialog.dart
import 'package:flutter/material.dart';

class JoinShadowDialog extends StatefulWidget {
  /// Callback that receives the parsed shadow ID when the user taps JOIN.
  final Function(String shadowId) onJoin;

  const JoinShadowDialog({Key? key, required this.onJoin}) : super(key: key);

  @override
  _JoinShadowDialogState createState() => _JoinShadowDialogState();
}

class _JoinShadowDialogState extends State<JoinShadowDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  void _handleJoin() {
    final link = _controller.text.trim();

    // Basic validation: Check if the link contains '/join/'
    final joinIndex = link.indexOf('/join/');
    if (joinIndex == -1) {
      setState(() {
        _errorMessage = 'Invalid share link format.';
      });
      return;
    }

    // Extract everything after '/join/'
    final shadowPart = link.substring(joinIndex + '/join/'.length);
    if (shadowPart.isEmpty) {
      setState(() {
        _errorMessage = 'No shadow ID found in link.';
      });
      return;
    }

    // In our share links, we expect a comma‑separated list of IDs.
    // For simplicity, we use only the first ID.
    final shadowIds = shadowPart.split(',');
    final shadowId = shadowIds.first;
    widget.onJoin(shadowId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Shadow'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter share link',
              errorText: _errorMessage,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: _handleJoin,
          child: const Text('JOIN'),
        ),
      ],
    );
  }
}
