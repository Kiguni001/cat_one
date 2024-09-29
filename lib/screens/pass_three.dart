import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PassThreePage extends StatelessWidget {
  final String uid;

  PassThreePage({required this.uid});

  final TextEditingController _newPasswordController = TextEditingController();

  Future<void> _changePassword(BuildContext context) async {
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.isEmpty) {
      _showMessage(context, 'กรุณากรอกรหัสผ่านใหม่');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        _showMessage(context, 'เปลี่ยนรหัสผ่านสำเร็จ');
        // สามารถนำทางไปยังหน้าที่คุณต้องการหลังจากเปลี่ยนรหัสผ่านเสร็จ
        // Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      _showMessage(context, 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน: ${e.toString()}');
    }
  }

  void _showMessage(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งรหัสผ่านใหม่'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('กรุณากรอกรหัสผ่านใหม่:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            _buildTextField(_newPasswordController, 'รหัสผ่านใหม่'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _changePassword(context),
              child: Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
      ),
    );
  }
}
