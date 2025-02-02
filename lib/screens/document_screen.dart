import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DocumentScreen extends StatefulWidget {
  final String shadowId;
  final String template;

  const DocumentScreen({super.key, required this.shadowId, required this.template});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final TextEditingController _documentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _documentController = TextEditingController();
    _loadDocumentContent();
  }

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentContent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _documentController.text = prefs.getString(widget.shadowId) ?? '';
    });
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.shadowId, _documentController.text.trim());
    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Changes saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
          child: Text('ShadowDocs - ${widget.shadowId.substring(0, 8)}'),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _openMenu,
            tooltip: 'More Options',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _documentController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration.collapsed(
            hintText: 'Start typing your document...',
          ),
          onChanged: (text) => setState(() => _isEditing = text.isNotEmpty),
        ),
      ),
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuOption(Icons.person_add, 'Invite Collaborators', _inviteCollaborators),
            _buildMenuOption(Icons.delete, 'Delete Shadow', _confirmDeleteShadow),
            _buildMenuOption(Icons.print, 'Print Document', _printDocument),
            _buildMenuOption(Icons.download, 'Export Document', _exportDocument),
          ],
        ),
      ),
    );
  }

  ListTile _buildMenuOption(IconData icon, String text, VoidCallback action) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        action();
      },
    );
  }

  void _inviteCollaborators() {
    final link = 'https://shadowdocs.com/invite/${widget.shadowId}';
    Share.share('Collaborate with me on ShadowDocs!\n$link');
  }

  void _confirmDeleteShadow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This will permanently delete the shadow document. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteShadow();
              if (!mounted) return;
              Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShadow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.shadowId);
    
    // Remove from dashboard list
    final shadows = prefs.getStringList('shadows') ?? [];
    shadows.removeWhere((s) => s.startsWith('${widget.shadowId}|'));
    await prefs.setStringList('shadows', shadows);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shadow document deleted")),
    );
  }

  void _printDocument() {
    Clipboard.setData(ClipboardData(text: _documentController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Content copied to clipboard for printing")),
    );
  }

  Future<void> _exportDocument() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.shadowId}.txt');
      await file.writeAsString(_documentController.text);
      await Share.shareXFiles([XFile(file.path)], text: 'Shadow Document Export');
      await file.delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to export document")),
      );
    }
  }
}