import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    // เอาเครื่องหมาย / ออกจากค่าที่ใส่เข้ามา
    text = text.replaceAll("/", "");

    // ถ้ามีตัวเลขมากกว่า 2 ตัว ให้ใส่ / ที่ตำแหน่ง 2
    if (text.length > 2) {
      text = text.substring(0, 2) + '/' + text.substring(2);
    }

    // ถ้ามีตัวเลขมากกว่า 5 ตัว ให้ใส่ / ที่ตำแหน่ง 5
    if (text.length > 5) {
      text = text.substring(0, 5) + '/' + text.substring(5, 9);
    }

    // ควบคุมไม่ให้ความยาวของข้อมูลเกิน 10 ตัว
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController(); // Birthday
  final TextEditingController _ageController = TextEditingController(); // Age

  String _selectedStatus = 'นักเรียน'; // ค่าดรอปดาวน์เริ่มต้น

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final birthday = _birthdayController.text.trim(); // Birthday
    final age = _ageController.text.trim(); // Age

    if (username.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        birthday.isEmpty ||
        age.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    try {
      // ตรวจสอบอีเมลและเบอร์โทรว่ามีอยู่แล้วหรือไม่
      if (await _isEmailInUse(email)) {
        _showError('This email is already in use.');
        return;
      }

      if (await _isPhoneInUse(phone)) {
        _showError('This phone number is already in use.');
        return;
      }

      // สร้างผู้ใช้ด้วย Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // บันทึกข้อมูลผู้ใช้ใน Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'phone': phone,
        'email': email,
        'birthday': birthday, // Birthday
        'age': age, // Age
        'status': _selectedStatus, // Status
        'role': 'Member',
      });

      // นำทางไปยังหน้า user_stream.dart เพื่อสร้าง Stream user และ token
      Navigator.pushReplacementNamed(context, '/user_stream');
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _showError('Error registering user: ${e.toString()}');
    }
  }

  Future<bool> _isEmailInUse(String email) async {
    final emailQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return emailQuery.docs.isNotEmpty;
  }

  Future<bool> _isPhoneInUse(String phone) async {
    final phoneQuery = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    return phoneQuery.docs.isNotEmpty;
  }

  void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        _showError('The password provided is too weak.');
        break;
      case 'email-already-in-use':
        _showError('The account already exists for that email.');
        break;
      case 'invalid-email':
        _showError('The email address is not valid.');
        break;
      default:
        _showError('Error registering user: ${e.message}');
        break;
    }
  }

  void _showError(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 48, 47, 50),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Sign Up Account',
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
            _buildLogo(),
            SizedBox(height: 40),
            _buildTextField(_usernameController, 'Username', Icons.person),
            SizedBox(height: 20),
            _buildTextField(_emailController, 'Email', Icons.email,
                keyboardType: TextInputType.emailAddress),
            SizedBox(height: 20),
            _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                keyboardType: TextInputType.phone),
            SizedBox(height: 20),
            _buildTextField(_passwordController, 'Password', Icons.lock,
                obscureText: true),
            SizedBox(height: 20),
            _buildBirthdayField(), // Updated Birthday Field
            SizedBox(height: 20),
            _buildTextField(_ageController, 'Age', Icons.person,
                keyboardType: TextInputType.number), // Age
            SizedBox(height: 20),
            _buildStatusDropdown(), // ดรอปดาวน์ Status
            SizedBox(height: 30),
            _buildSignupButton(),
            SizedBox(height: 20),
            _buildLoginOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage('assets/SumhuaPro.png'), // เพิ่มโลโก้ของคุณ
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool obscureText = false,
      List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // กำหนด inputFormatter
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildBirthdayField() {
    return GestureDetector(
      onTap: () async {
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (selectedDate != null) {
          _birthdayController.text =
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: _birthdayController,
          decoration: InputDecoration(
            labelText: 'Birthday',
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      items: ['นักเรียน', 'นักศึกษา','ครูผู้สอน', 'อาจารย์'].map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
      style: TextStyle(color: Colors.white), // กำหนดสีขาวให้ข้อความที่แสดงใน dropdown
      dropdownColor: Colors.cyan[800], // กำหนดพื้นหลังของ dropdown เป็นสี cyan[800]
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: TextStyle(color: Colors.white),
        prefixIcon: Icon(Icons.person_outline, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      onPressed: _registerUser,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[900],
        padding: EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Sign Up',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildLoginOption() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, '/login_page');
      },
      child: Center(
        child: Text(
          'Already have an account? Log in',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
