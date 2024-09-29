import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingPage extends StatefulWidget {
  @override
  _ProfileSettingPageState createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  // Controllers for read-only fields
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<String> _statusOptions = [
    'นักเรียน',
    'นักศึกษา',
    'ครูผู้สอน',
    'อาจารย์'
  ];

  User? _currentUser;
  File? _profileImage;
  bool _isSaveButtonEnabled = false;

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

      // Load additional user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        _usernameController.text = userDoc['username'] ?? '';
        _statusController.text = userDoc['status'] ?? '';
        _birthdayController.text = userDoc['birthday'] ?? '';
        _ageController.text = userDoc['age']?.toString() ?? '';
        _phoneController.text = userDoc['phone'] ?? '';
      }
    }
  }

  void _checkIfSaveButtonShouldBeEnabled() {
    if (_nameController.text.trim() != _currentUser!.displayName ||
        _usernameController.text.trim() != '' ||
        _statusController.text.trim() != '') {
      setState(() {
        _isSaveButtonEnabled = true;
      });
    } else {
      setState(() {
        _isSaveButtonEnabled = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser != null && _isSaveButtonEnabled) {
      String newName = _nameController.text.trim();
      String newUsername = _usernameController.text.trim();
      String newStatus = _statusController.text.trim();

      try {
        // Update display name
        if (newName.isNotEmpty) {
          await _currentUser!.updateDisplayName(newName);
        }

        // Upload profile image
        if (_profileImage != null) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('$fileName.jpg');
          UploadTask uploadTask = storageRef.putFile(_profileImage!);
          TaskSnapshot snapshot = await uploadTask;
          String imageUrl = await snapshot.ref.getDownloadURL();

          // Update user profile photo URL in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.uid)
              .update({
            'profileImageUrl': imageUrl,
          });

          // Update the user's photo URL
          await _currentUser!.updatePhotoURL(imageUrl);
        }

        // Update other fields in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({
          'username': newUsername,
          'status': newStatus,
        });

        // Reload user to reflect changes
        await _currentUser!.reload();
        _currentUser = FirebaseAuth.instance.currentUser;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
          );
        }

        // Reset save button state
        setState(() {
          _isSaveButtonEnabled = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _isSaveButtonEnabled = true; // Enable save button when image is picked
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งค่าโปรไฟล์'),
        backgroundColor: Colors.lime[900],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt,
                          size: 50, color: Colors.lime[800])
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อเล่น',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lime, width: 2.0),
                  ),
                ),
                onChanged: (value) => _checkIfSaveButtonShouldBeEnabled(),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (Editable)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _checkIfSaveButtonShouldBeEnabled(),
              ),
              SizedBox(height: 15),
              // ปรับ TextField ของ Status ให้เป็น DropdownButtonFormField
              DropdownButtonFormField<String>(
                value: _statusController.text.isNotEmpty
                    ? _statusController.text
                    : null,
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _statusController.text = newValue!;
                    _checkIfSaveButtonShouldBeEnabled();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: 'Birthday',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSaveButtonEnabled ? _updateProfile : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaveButtonEnabled ? Colors.lime : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'บันทึกการเปลี่ยนแปลง',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
