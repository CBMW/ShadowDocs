// lib/screens/document_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../services/webrtc_service.dart';
import '../widgets/formatting_toolbar.dart';
import '../widgets/document_editor.dart';
import '../widgets/markdown_preview.dart';
import '../widgets/shadow_options_menu.dart';
import '../widgets/shadow_info_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DocumentScreen extends StatefulWidget {
  final String shadowId;
  final String template;

  const DocumentScreen({
    Key? key,
    required this.shadowId,
    required this.template,
  }) : super(key: key);

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  bool _showToolbar = false;
  double _fontSize = 16.0;
  late WebRTCService _webrtcService;
  bool _isConnected = false;
  bool _isShared = false;
  String? _shareToken;

  // Simulated metadata – in a production app, load these from storage or your backend.
  final String createdBy = "User123";
  final String createdAt = "2023-01-01 12:00";
  int connectedUsers = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadDocument();
    _initializeWebRTC();
    _checkSharedStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _webrtcService.close();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString(widget.shadowId) ?? '';
    });
  }

  /// Initialize the WebRTC connection.
  Future<void> _initializeWebRTC() async {
    _webrtcService = WebRTCService();
    bool isOfferer = !_isShared;
    await _webrtcService.initialize(isOfferer: isOfferer);
    _webrtcService.onDataReceived = (data) {
      if (data != _controller.text) {
        setState(() {
          _controller.text = data;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document updated by peer")),
        );
      }
    };
    setState(() {
      _isConnected = true;
    });
  }

  Future<void> _checkSharedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("shared_${widget.shadowId}_token");
    if (token != null && token.isNotEmpty) {
      setState(() {
        _isShared = true;
        _shareToken = token;
      });
    }
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final content = _controller.text.trim();
    await prefs.setString(widget.shadowId, content);
    if (_isConnected && _isShared) {
      await _webrtcService.send(content);
    }
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Changes saved and synced")),
    );
  }

  /// Invites collaborators by generating a secure share link.
  void _inviteCollaborators() {
    final uuid = Uuid();
    String token = uuid.v4();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("shared_${widget.shadowId}_token", token);
      setState(() {
        _isShared = true;
        _shareToken = token;
      });
      final shareLink = "https://shadowdocs.com/join/${widget.shadowId}?token=$token";
      Share.share("Join my ShadowDocs document:\n$shareLink");
    });
  }

  void _changeFontSize() {
    showDialog(
      context: context,
      builder: (context) {
        double tempSize = _fontSize;
        return AlertDialog(
          title: const Text("Adjust Font Size"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Slider(
                value: tempSize,
                min: 10,
                max: 30,
                divisions: 20,
                label: tempSize.round().toString(),
                onChanged: (value) {
                  setState(() {
                    tempSize = value;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _fontSize = tempSize;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _previewDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Preview"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: MarkdownPreview(markdownData: _controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  // Markdown formatting actions:
  void _applyBold() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    final selected = selection.textInside(text);
    int base = selection.start;
    String newText;
    if (selected.isEmpty) {
      newText = text.replaceRange(selection.start, selection.end, '**bold**');
      _controller.text = newText;
      _controller.selection = TextSelection(baseOffset: base + 2, extentOffset: base + 6);
    } else {
      newText = text.replaceRange(selection.start, selection.end, '**$selected**');
      _controller.text = newText;
      _controller.selection = TextSelection(baseOffset: base, extentOffset: selection.end + 4);
    }
  }

  void _applyItalics() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    final selected = selection.textInside(text);
    int base = selection.start;
    String newText;
    if (selected.isEmpty) {
      newText = text.replaceRange(selection.start, selection.end, '*italic*');
      _controller.text = newText;
      _controller.selection = TextSelection(baseOffset: base + 1, extentOffset: base + 7);
    } else {
      newText = text.replaceRange(selection.start, selection.end, '*$selected*');
      _controller.text = newText;
      _controller.selection = TextSelection(baseOffset: base, extentOffset: selection.end + 2);
    }
  }

  void _applyBullet() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    int lineStart = text.lastIndexOf('\n', selection.start - 1);
    lineStart = (lineStart == -1) ? 0 : lineStart + 1;
    if (text.substring(lineStart).startsWith('- ')) return;
    String newText = text.replaceRange(lineStart, lineStart, '- ');
    _controller.text = newText;
    int offset = selection.start + 2;
    _controller.selection = TextSelection.collapsed(offset: offset);
  }

  void _applyHeading() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;
    int lineStart = text.lastIndexOf('\n', selection.start - 1);
    lineStart = (lineStart == -1) ? 0 : lineStart + 1;
    if (text.substring(lineStart).startsWith('# ')) {
      String newText = text.replaceRange(lineStart, lineStart + 2, '');
      _controller.text = newText;
      int offset = selection.start - 2;
      _controller.selection = TextSelection.collapsed(offset: offset);
    } else {
      String newText = text.replaceRange(lineStart, lineStart, '# ');
      _controller.text = newText;
      int offset = selection.start + 2;
      _controller.selection = TextSelection.collapsed(offset: offset);
    }
  }

  // --- Drop-down menu actions ---

  // Delete Shadow
  void _confirmDeleteShadow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This will permanently delete the shadow. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteShadow();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shadow deleted")),
    );
  }

  // Export Shadow as PDF
  Future<void> _exportShadow() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(child: pw.Text(_controller.text)),
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${widget.shadowId}.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Shadow Document Export');
    await file.delete();
  }

  // About Shadow
  void _showAboutShadow() {
    showDialog(
      context: context,
      builder: (context) => ShadowInfoDialog(
        shadowId: widget.shadowId,
        createdBy: createdBy,
        createdAt: createdAt,
        connectedUsers: connectedUsers,
      ),
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
          IconButton(
            icon: Icon(_showToolbar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            tooltip: 'Formatting Options',
            onPressed: () {
              setState(() {
                _showToolbar = !_showToolbar;
              });
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _saveChanges,
            ),
          // Use the modular drop-down menu for additional options.
          ShadowOptionsMenu(
            onDelete: _confirmDeleteShadow,
            onShare: _inviteCollaborators,
            onExport: _exportShadow,
            onAbout: _showAboutShadow,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showToolbar)
            FormattingToolbar(
              onBold: _applyBold,
              onItalics: _applyItalics,
              onBullet: _applyBullet,
              onHeading: _applyHeading,
              onFontSize: _changeFontSize,
              onPreview: _previewDocument,
            ),
          DocumentEditor(
            controller: _controller,
            fontSize: _fontSize,
            onChanged: (text) {
              setState(() {
                _isEditing = text.isNotEmpty;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _inviteCollaborators,
        tooltip: 'Invite Collaborators',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
