import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pass_three.dart'; // นำเข้าไฟล์ pass_three.dart

class PassTwoPage extends StatefulWidget {
  final String uid;
  final String email; // เพิ่มตัวแปร email

  PassTwoPage({required this.uid, required this.email});

  @override
  _PassTwoPageState createState() => _PassTwoPageState();
}

class _PassTwoPageState extends State<PassTwoPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String? _selectedStatus; // ตัวแปรสำหรับเก็บสถานะที่เลือก
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _username;

  // รายการสถานะสำหรับ Dropdown
  final List<String> _statuses = ['นักเรียน', 'นักศึกษา', 'ครูผู้สอน', 'อาจารย์'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.data()?['username'];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _verifyUserData() async {
    final phone = _phoneController.text.trim();
    final birthday = _birthdayController.text.trim();
    final status = _selectedStatus;

    if (phone.isEmpty || birthday.isEmpty || status == null) {
      _showError('กรุณากรอกข้อมูลทั้งหมด.');
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(widget.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null &&
            userData['phone'] == phone &&
            userData['birthday'] == birthday &&
            userData['status'] == status) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForgotPasswordPage(uid: widget.uid, email: widget.email),
            ),
          );
        } else {
          _showError('ข้อมูลไม่ถูกต้อง');
        }
      }
    } catch (e) {
      _showError('Error verifying user data: ${e.toString()}');
    }
  }

  void _showError(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตรวจสอบข้อมูล'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('ชื่อผู้ใช้: $_username'),
            SizedBox(height: 20),
            _buildTextField(_phoneController, 'หมายเลขโทรศัพท์'),
            SizedBox(height: 20),
            _buildDatePickerField(), // เปลี่ยนให้เป็นฟังก์ชันใหม่สำหรับเลือกวันเกิด
            SizedBox(height: 20),
            _buildStatusDropdown(), // เปลี่ยนให้เป็น Dropdown สำหรับสถานะ
            SizedBox(height: 20),
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: _buildTextField(_birthdayController, 'วันเกิด (dd/mm/yyyy)'),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.day}/${picked.month}/${picked.year}"; // รูปแบบ dd/mm/yyyy
      });
    }
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      hint: Text('เลือกสถานะ'),
      onChanged: (newValue) {
        setState(() {
          _selectedStatus = newValue;
        });
      },
      items: _statuses.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status),
        );
      }).toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return ElevatedButton(
      onPressed: _verifyUserData,
      child: Text('ตรวจสอบข้อมูล'),
    );
  }
}
