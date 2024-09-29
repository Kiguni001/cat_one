import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pass_two.dart'; // นำเข้าไฟล์ pass_two.dart

class NewPasswordPage extends StatefulWidget {
  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _verifyUser() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('กรุณากรอกอีเมล.');
      return;
    }

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // พบอีเมล ให้ไปยังหน้า pass_two.dart
        final uid = userQuery.docs.first.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PassTwoPage(uid: uid),
          ),
        );
      } else {
        _showError('ไม่พบอีเมลนี้ในระบบ');
      }
    } catch (e) {
      _showError('Error verifying user: ${e.toString()}');
    }
  }

  void _showError(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'ลืมรหัสผ่าน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            _buildTextField(_emailController, 'ใส่อีเมล', Icons.email, false),
            SizedBox(height: 30),
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool obscureText) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0)),
        labelText: label,
        labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return ElevatedButton(
      onPressed: _verifyUser,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        'ตรวจสอบ',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
