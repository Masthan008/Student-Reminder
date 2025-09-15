import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _profile = null;
        _loading = false;
      });
      return;
    }

    final res = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (res != null) {
      setState(() {
        _profile = Map<String, dynamic>.from(res as Map);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _onEditPressed() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(profile: _profile ?? {}),
      ),
    );
    if (result == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _profile == null
          ? const Center(child: Text('Not logged in'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage:
                        _profile!['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
                    child: _profile!['avatar_url'] == null ? const Icon(Icons.person, size: 48) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(_profile!['name'] ?? 'No name', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(_profile!['email'] ?? 'No email'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _onEditPressed,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}
