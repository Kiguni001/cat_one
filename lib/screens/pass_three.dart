import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final String uid; 
  final String email; // เพิ่มตัวแปร email

  // สร้าง constructor ที่รับ uid และ email
  ForgotPasswordPage({required this.uid, required this.email}) {
    _emailController.text = email; // ตั้งค่าให้กับช่องกรอก Gmail
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(context, 'กรุณากรอกอีเมล');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print('อีเมลถูกส่งไปยัง: $email'); // ตรวจสอบ
      _showMessage(context, 'ลิงก์รีเซ็ตรหัสผ่านถูกส่งไปที่อีเมลของคุณแล้ว');
    } catch (e) {
      print('Error: ${e.toString()}'); // ดูข้อความข้อผิดพลาด
      _showMessage(context, 'เกิดข้อผิดพลาด: ${e.toString()}');
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
        title: Text('ลืมรหัสผ่าน'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('ลิงก์รีเซ็ตรหัสผ่านจะถูกส่งไปที่ Gmail:',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            _buildTextField(_emailController, 'Gmail'), // ใช้ฟังก์ชันนี้เพื่อสร้างช่องกรอก Gmail
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetPassword(context),
              child: Text('ส่งลิงก์รีเซ็ตรหัสผ่าน',
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true, // ทำให้ช่องกรอกเป็นแบบล็อค
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
