import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // เพิ่มการนำเข้าที่นี่

class VoiceChannelPage extends StatefulWidget {
  final String channelId; // รับ channelId ที่ส่งมาจาก roomslidebar.dart

  VoiceChannelPage({required this.channelId});

  @override
  _VoiceChannelPageState createState() => _VoiceChannelPageState();
}

class _VoiceChannelPageState extends State<VoiceChannelPage> {
  late stream.StreamChatClient client;
  late String userId;
  late String userToken;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      userToken = await getToken(userId); // สร้าง Token สำหรับผู้ใช้

      client = stream.StreamChatClient(
        'q32a5zv4uj3q', // ใส่ API Key ของคุณ
        logLevel: stream.Level.INFO,
      );

      try {
        await client.connectUser(
          stream.User(id: userId),
          userToken,
        );

        // เข้าร่วม channel
        await client.channel('voice', id: widget.channelId).watch();
      } catch (e) {
        // จัดการข้อผิดพลาดในการเชื่อมต่อ
        print('Error connecting user: $e');
      }
    } else {
      // จัดการกรณีที่ผู้ใช้ไม่ได้เข้าสู่ระบบ
      // อาจจะแสดงหน้าจอเข้าสู่ระบบหรือแจ้งเตือน
      print('User is not logged in.');
    }
  }

  Future<String> getToken(String userId) async {
    try {
      // เรียกใช้ Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createStreamToken');
      final response = await callable.call();
      
      // รับ Token จากการตอบกลับ
      return response.data['token'];
    } catch (e) {
      // จัดการข้อผิดพลาด
      print('Error getting token: $e');
      return '';
    }
  }

  @override
  void dispose() {
    client.disconnectUser();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelId),
      ),
      body: Center(
        child: Text('Voice Channel: ${widget.channelId}'),
      ),
    );
  }
}
