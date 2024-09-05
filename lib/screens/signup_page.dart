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

    if (username.isEmpty || password.isEmpty || phone.isEmpty || email.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    try {
      // Check if email or phone number already exists
      final emailQuery = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (emailQuery.docs.isNotEmpty) {
        _showError('This email is already in use.');
        return;
      }

      final phoneQuery = await _firestore.collection('users').where('phone', isEqualTo: phone).get();
      if (phoneQuery.docs.isNotEmpty) {
        _showError('This phone number is already in use.');
        return;
      }

      // Create user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
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
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
