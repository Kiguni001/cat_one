import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้าคลาส FirebaseAuth
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserStreamPage extends StatefulWidget {
  @override
  _UserStreamPageState createState() => _UserStreamPageState();
}

class _UserStreamPageState extends State<UserStreamPage> {
  @override
  void initState() {
    super.initState();
    _createStreamUserAndToken();
  }

  Future<void> _createStreamUserAndToken() async {
    // ดึงข้อมูลผู้ใช้จาก Firestore
    final user = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid);
    final userData = await user.get();

    // ตรวจสอบว่าผู้ใช้มีอยู่จริง
    if (userData.exists) {
      String username = userData['username'];
      String userId = userData.id;

      // ขอ Token สำหรับ Stream
      try {
        final token = await _getStreamToken(userId);
        print('User: $username, Token: $token');
      } catch (e) {
        print('Error generating token: $e');
      }
    }

    // นำทางไปยังหน้า login_page.dart
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<String> _getStreamToken(String userId) async {
    final url = Uri.parse('https://us-central1-newsumhua.cloudfunctions.net/generateToken');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final tokenData = json.decode(response.body);
      return tokenData['token'];
    } else {
      throw Exception('Failed to generate token: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(), // วงกลมหมุนเพื่อแสดงการรอผล
      ),
    );
  }
}
