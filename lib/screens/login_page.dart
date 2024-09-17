import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 48, 47, 50),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Login SumHua Account',
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
            _buildTextField(_emailController, 'Email', Icons.email, false),
            SizedBox(height: 20),
            _buildTextField(_passwordController, 'Password', Icons.lock, true),
            SizedBox(height: 30),
            _buildLoginButton(),
            SizedBox(height: 20),
            _buildSignupOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage('assets/SumhuaPro.png'), // ใส่โลโก้ของคุณ
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, bool obscureText) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 255, 255, 255)),
        labelText: label,
        labelStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: const Color.fromARGB(255, 255, 255, 255), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType:
          obscureText ? TextInputType.text : TextInputType.emailAddress,
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(
            119, 55, 71, 79), // เปลี่ยนจาก primary เป็น backgroundColor
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _login,
      child: Text(
        'Login',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white, // สีของข้อความ
        ),
      ),
    );
  }

  Widget _buildSignupOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Don\'t have an account?'),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupPage()),
            );
          },
          child: Text(
            'Sign up',
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
