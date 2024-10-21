import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // นำเข้า Firebase Firestore

class CallFriend extends StatelessWidget {
  final String userID; // เพิ่มตัวแปรรับ userID จากภายนอก

  const CallFriend({Key? key, required this.userID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeCall(userID: userID)); // ส่ง userID ไปยัง HomeCall
  }
}

class HomeCall extends StatelessWidget {
  final String userID; // รับ userID จาก CallFriend
  final callIDTextCtrl = TextEditingController(text: "");

  HomeCall({Key? key, required this.userID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: callIDTextCtrl,
                  decoration:
                      const InputDecoration(labelText: "สร้าง ID ง่ายๆเพื่อโทรกับเพื่อนของคุณ"),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // ดึงค่า userName จาก Firebase ก่อนที่จะไปหน้า FriendCallPage
                  String? userName = await getUserNameFromFirebase(userID);
                  if (userName != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return FriendCallPage(
                          callID: callIDTextCtrl.text,
                          userID: userID,
                          userName: userName, // ส่งค่า userName ไปยัง FriendCallPage
                        );
                      }),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ไม่พบชื่อผู้ใช้')),
                    );
                  }
                },
                child: const Text("โทร"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันดึง userName จาก Firebase โดยใช้ userID
  Future<String?> getUserNameFromFirebase(String userID) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      if (userDoc.exists) {
        return userDoc['username']; // คืนค่า username ถ้าเจอ
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null; // คืนค่า null ถ้าไม่เจอ
  }
}

class FriendCallPage extends StatelessWidget {
  final String callID;
  final String userID; // เพิ่มตัวแปรรับ userID
  final String userName; // เพิ่มตัวแปรรับ userName

  const FriendCallPage(
      {Key? key, required this.callID, required this.userID, required this.userName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: 432875762, // Your App ID
        appSign:
            '575d806874914557ff434677eb0f09ea6cbc4fb49b82ef41531dcbf9a6247a6f', // Your App Sign
        userID: userID, // ใช้ userID ที่ส่งมา
        userName: userName, // ใช้ userName ที่ดึงจาก Firebase
        callID: callID,
        config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
          ..layout = ZegoLayout.gallery(
              showScreenSharingFullscreenModeToggleButtonRules:
                  ZegoShowFullscreenModeToggleButtonRules.alwaysShow,
              showNewScreenSharingViewInFullscreenMode: false)
          ..bottomMenuBarConfig = ZegoBottomMenuBarConfig(buttons: [
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.hangUpButton,
            ZegoCallMenuBarButtonName.toggleScreenSharingButton
          ]), // Add a screen sharing toggle button.
      ),
    );
  }
}

