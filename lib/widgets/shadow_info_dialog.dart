// lib/widgets/shadow_info_dialog.dart
import 'package:flutter/material.dart';

class ShadowInfoDialog extends StatelessWidget {
  final String shadowId;
  final String createdBy;
  final String createdAt;
  final int connectedUsers;

  const ShadowInfoDialog({
    Key? key,
    required this.shadowId,
    required this.createdBy,
    required this.createdAt,
    required this.connectedUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About Shadow'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shadow ID: $shadowId'),
          const SizedBox(height: 8),
          Text('Created By: $createdBy'),
          const SizedBox(height: 8),
          Text('Created At: $createdAt'),
          const SizedBox(height: 8),
          Text('Connected Users: $connectedUsers'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
