import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  SetupScreenState createState() => SetupScreenState();
}

class SetupScreenState extends State<SetupScreen> {
  String? userId;
  final TextEditingController _nameController = TextEditingController();
  bool idGenerated = false;

  Future<void> _generateId() async {
    String deviceId = await _getDeviceId();
    setState(() {
      userId = deviceId;
      idGenerated = true;
    });
  }

  Future<String> _getDeviceId() async {
    var uuid = const Uuid();
    return uuid.v4();
  }

  Future<void> _saveUserInfo() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a display name.")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId!);
    await prefs.setString('displayName', _nameController.text.trim());

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup ShadowDocs'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: idGenerated ? _buildNameInput() : _buildGenerateButton(),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.security, size: 100, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          'Generate your unique ShadowDocs ID.',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _generateId,
          icon: const Icon(Icons.vpn_key),
          label: const Text('Generate ID', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person, size: 100, color: Colors.green),
        const SizedBox(height: 20),
        Text(
          'Your ID: $userId',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Set a Display Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saveUserInfo,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}
