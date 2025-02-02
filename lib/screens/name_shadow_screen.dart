import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class NameShadowScreen extends StatefulWidget {
  final String template;

  const NameShadowScreen({super.key, required this.template});

  @override
  _NameShadowScreenState createState() => _NameShadowScreenState();
}

class _NameShadowScreenState extends State<NameShadowScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Uuid _uuid = const Uuid();

  void _createShadow() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name")),
      );
      return;
    }
    Navigator.pop(context, {
      'id': _uuid.v4(),
      'name': name,
      'template': widget.template
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Name Your Shadow')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Template: ${widget.template}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Shadow Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createShadow,
              child: const Text('Create Shadow'),
            ),
          ],
        ),
      ),
    );
  }
}