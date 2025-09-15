import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/upload_manager.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfilePage({Key? key, required this.profile}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _saving = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile['name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.profile['email'] ?? Supabase.instance.client.auth.currentUser?.email ?? '');
    _avatarUrl = widget.profile['avatar_url'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    setState(() => _saving = true);

    try {
      final bytes = await file.readAsBytes();
      final filename = 'avatars/${Supabase.instance.client.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final url = await UploadManager().uploadWithFallback(
        bytes: bytes,
        path: filename,
        contentType: 'image/png',
      );
      setState(() => _avatarUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in')));
      setState(() => _saving = false);
      return;
    }

    final updates = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'avatar_url': _avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final resp = await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        ...updates,
      }).select().maybeSingle();

      await Supabase.instance.client.auth.updateUser(UserAttributes(displayName: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), photoURL: _avatarUrl));

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _saving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                        child: _avatarUrl == null ? const Icon(Icons.camera_alt) : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                    ),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
