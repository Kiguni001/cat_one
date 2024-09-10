import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingPage extends StatefulWidget {
  @override
  _ProfileSettingPageState createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser != null) {
      String newName = _nameController.text.trim();
      String newEmail = _emailController.text.trim();

      try {
        // Update display name
        if (newName.isNotEmpty) {
          await _currentUser!.updateDisplayName(newName);
        }

        // Update email
        if (newEmail.isNotEmpty && newEmail != _currentUser!.email) {
          await _currentUser!.updateEmail(newEmail);
        }

        // Reload user to reflect changes
        await _currentUser!.reload();
        _currentUser = FirebaseAuth.instance.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update your profile', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
