import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_notifier.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? displayName = prefs.getString('displayName');
    String? accountId = prefs.getString('userId');

    setState(() {
      _displayNameController.text = displayName ?? '';
      _accountId = accountId ?? 'Unknown ID';
    });
  }

  Future<void> _saveDisplayName() async {
    String displayName = _displayNameController.text.trim();
    if (displayName.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', displayName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Display name saved.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Display name cannot be empty.")),
      );
    }
  }

  Future<void> _deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('displayName');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account ID deleted.")),
    );
    Navigator.pushReplacementNamed(context, '/setup');
  }

  @override
  Widget build(BuildContext context) {
    var themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                'Display Name',
                style: TextStyle(fontSize: 18),
              ),
              subtitle: TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your display name',
                  border: UnderlineInputBorder(),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveDisplayName,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text(
                'Account ID',
                style: TextStyle(fontSize: 18),
              ),
              subtitle: Text(
                _accountId ?? 'Unknown ID',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              secondary: const Icon(Icons.brightness_6),
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontSize: 18),
              ),
              value: themeNotifier.isDarkMode,
              onChanged: (value) async {
                themeNotifier.toggleTheme();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool('isDarkMode', value);
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'DELETE ACCOUNT ID',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
