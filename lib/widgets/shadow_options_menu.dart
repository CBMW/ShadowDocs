// lib/widgets/shadow_options_menu.dart
import 'package:flutter/material.dart';

enum ShadowMenuOption { delete, share, export, about }

class ShadowOptionsMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onAbout;

  const ShadowOptionsMenu({
    Key? key,
    required this.onDelete,
    required this.onShare,
    required this.onExport,
    required this.onAbout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ShadowMenuOption>(
      icon: const Icon(Icons.more_vert),
      onSelected: (option) {
        switch (option) {
          case ShadowMenuOption.delete:
            onDelete();
            break;
          case ShadowMenuOption.share:
            onShare();
            break;
          case ShadowMenuOption.export:
            onExport();
            break;
          case ShadowMenuOption.about:
            onAbout();
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<ShadowMenuOption>>[
        const PopupMenuItem(
          value: ShadowMenuOption.delete,
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Shadow'),
          ),
        ),
        const PopupMenuItem(
          value: ShadowMenuOption.share,
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text('Share Shadow'),
          ),
        ),
        const PopupMenuItem(
          value: ShadowMenuOption.export,
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Export Shadow'),
          ),
        ),
        const PopupMenuItem(
          value: ShadowMenuOption.about,
          child: ListTile(
            leading: Icon(Icons.info),
            title: Text('About Shadow'),
          ),
        ),
      ],
    );
  }
}
