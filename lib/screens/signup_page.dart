import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        email.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    try {
      // Check if email or phone number already exists
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        _showError('This email is already in use.');
        return;
      }

      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        _showError('This phone number is already in use.');
        return;
      }

      // Create user with Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user details in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'phone': phone,
        'email': email,
        'role': 'Member',
      });

      // Navigate to the login page after successful registration
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
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
    } catch (e) {
      _showError('Error registering user: ${e.toString()}');
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
            color: Colors.white, // สีของข้อความ "Login"
            fontSize: 20, // ขนาดตัวอักษร (ปรับได้ตามต้องการ)
            fontWeight: FontWeight.bold, // ทำตัวอักษรหนา (ถ้าต้องการ)
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
      bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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

  Widget _buildSignupButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(
            119, 55, 71, 79),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _registerUser,
      child:
          Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget _buildLoginOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account?'),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text(
            'Login',
            style: TextStyle(
              color: Colors.yellow[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
