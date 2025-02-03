// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:shared_preferences/shared_preferences.dart';
import 'name_shadow_screen.dart';
import 'settings_screen.dart';
import 'document_screen.dart'; // Adjust the path based on your file structure
import '../widgets/join_shadow_dialog.dart'; // Import the join shadow dialog

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, String>> shadows = [];
  bool isSharingMode = false;
  List<bool> selectedShadows = [];
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadShadows();
  }

  Future<void> _loadShadows() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? shadowList = prefs.getStringList('shadows');
    if (shadowList != null) {
      setState(() {
        shadows = shadowList.map((shadow) {
          List<String> parts = shadow.split('|');
          return {'id': parts[0], 'name': parts[1], 'template': parts[2]};
        }).toList();
      });
    }
  }

  Future<void> _saveShadows() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> shadowList = shadows
        .map((s) => '${s['id']}|${s['name']}|${s['template']}')
        .toList();
    await prefs.setStringList('shadows', shadowList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () =>
              Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
          child: const Text('ShadowDocs'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _buildMainContent(),
      floatingActionButton: isSharingMode
          ? _buildShareButton()
          : FloatingActionButton(
              onPressed: _showActionOptions,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildMainContent() {
    if (shadows.isEmpty) {
      return const Center(
          child: Text('No Shadows Yet', style: TextStyle(fontSize: 18)));
    }
    return Stack(
      children: [
        _buildShadowList(),
        if (isSharingMode) _buildShareButton(),
      ],
    );
  }

  Widget _buildShadowList() {
    return ListView.builder(
      itemCount: shadows.length,
      itemBuilder: (context, index) => isSharingMode
          ? CheckboxListTile(
              title: Text(shadows[index]['name']!),
              value: selectedShadows[index],
              onChanged: (value) =>
                  setState(() => selectedShadows[index] = value!),
            )
          : ListTile(
              title: Text(shadows[index]['name']!),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentScreen(
                      shadowId: shadows[index]['id']!,
                      template: shadows[index]['template']!,
                    ),
                  ),
                ).then((_) => _loadShadows());
              },
            ),
    );
  }

  void _showActionOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Create Shadow'),
              onTap: () {
                Navigator.pop(context);
                _showCreateShadowDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.input),
              title: const Text('Join Shadow'),
              onTap: () {
                Navigator.pop(context);
                _showJoinShadowDialog();
              },
            ),
            if (shadows.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Shadow'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    isSharingMode = true;
                    selectedShadows = List.filled(shadows.length, false);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateShadowDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shadow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTemplateTile('Blank'),
            _buildTemplateTile('Resume/CV'),
            _buildTemplateTile('Meeting Minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  ListTile _buildTemplateTile(String template) {
    return ListTile(
      title: Text(template),
      onTap: () => _navigateToNameShadowScreen(template),
    );
  }

  void _navigateToNameShadowScreen(String template) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NameShadowScreen(template: template),
      ),
    );
    if (result != null) {
      setState(() => shadows.add(result));
      await _saveShadows();
    }
  }

  Widget _buildShareButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: _shareSelectedShadows,
          child: const Text('SHARE SELECTED'),
        ),
      ),
    );
  }

  void _shareSelectedShadows() {
    final selected = <Map<String, String>>[];
    for (int i = 0; i < shadows.length; i++) {
      if (selectedShadows[i]) {
        selected.add(shadows[i]);
      }
    }
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No shadows selected")),
      );
      return;
    }

    // Generate a secure share link.
    final link = _generateShareLink(
      selected.map((s) => s['id']!).toList(),
    );
    _showShareLinkDialog(link);
    setState(() => isSharingMode = false);
  }

  /// Generates a secure share link based on the selected shadow IDs.
  String _generateShareLink(List<String> ids) {
    // In production, generate a long secure token per shadow.
    // For now, we simply join the IDs.
    return "https://shadowdocs.com/join/${ids.join(',')}";
  }

  /// Shows a dialog with the share link and provides a copy button.
  void _showShareLinkDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Link'),
        content: SelectableText(link),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied to clipboard")),
              );
            },
            child: const Text('COPY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  /// Displays the join shadow dialog (modularized in its own widget).
  void _showJoinShadowDialog() {
    showDialog(
      context: context,
      builder: (context) => JoinShadowDialog(onJoin: _handleJoinShadow),
    );
  }

  /// Handles the join shadow action by extracting the shadow ID and adding
  /// the new shadow to local storage.
  void _handleJoinShadow(String shadowId) async {
    // Check if the shadow already exists.
    bool exists = shadows.any((s) => s['id'] == shadowId);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shadow already joined")),
      );
      return;
    }
    // Create a new shadow entry with a default name and template.
    final newShadow = {
      'id': shadowId,
      'name': 'Joined Shadow ${shadowId.substring(0, 8)}',
      'template': 'Joined'
    };
    setState(() {
      shadows.add(newShadow);
    });
    await _saveShadows();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shadow joined successfully")),
    );
  }
}
