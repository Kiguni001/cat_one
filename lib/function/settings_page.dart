import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumhua_project/screens/main_page.dart'; // อิมพอร์ต MainPage

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool isNotificationEnabled = true;
  late String userId;
  late String menuItemId = ''; // กำหนดค่าเริ่มต้นให้เป็นค่าว่าง

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;

      // ดึง menuItemId จาก Firestore โดยค้นหาใน collection classmenuitem และตรวจสอบใน collection ย่อย role
      QuerySnapshot classMenuItemsSnapshot =
          await FirebaseFirestore.instance.collection('classmenuitem').get();

      for (var doc in classMenuItemsSnapshot.docs) {
        DocumentSnapshot roleDoc = await FirebaseFirestore.instance
            .collection('classmenuitem')
            .doc(doc.id)
            .collection('role')
            .doc(userId)
            .get();

        if (roleDoc.exists) {
          setState(() {
            // กำหนด menuItemId เมื่อพบเอกสาร role ที่ตรงกับ userId
            menuItemId = doc.id;
            print('menuItemId: $menuItemId'); // ข้อความดีบั๊ก
          });
          break; // ออกจากลูปเมื่อพบ menuItemId
        }
      }

      if (menuItemId.isEmpty) {
        print(
            'No menuItem found for userId: $userId'); // แสดง userId ในข้อความดีบั๊ก
        // แสดงข้อความเตือนบน UI แทนการมีค่า menuItemId ว่างเปล่า
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ไม่พบคลาสที่คุณเข้าร่วม')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การตั้งค่า'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              title: Text('โหมดมืด'),
              value: isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('การแจ้งเตือน'),
              value: isNotificationEnabled,
              onChanged: (bool value) {
                setState(() {
                  isNotificationEnabled = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _showLeaveClassDialog,
              child: Text('ออกจากห้องเรียนนี้'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveClassDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Leave Class'),
          content: Text('คุณต้องการออกจากคลาสนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                await _leaveClass();
                Navigator.of(context).pop();
                _showLeaveClassSuccessDialog(); // เรียกใช้การแสดงหน้าต่างหลังจากออกคลาส
              },
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _leaveClass() async {
    if (userId.isNotEmpty && menuItemId.isNotEmpty) {
      try {
        // ลบเอกสารของผู้ใช้จาก collection 'role'
        await FirebaseFirestore.instance
            .collection('classmenuitem')
            .doc(menuItemId)
            .collection('role')
            .doc(userId)
            .delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถออกจากคลาสได้: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถออกจากคลาสได้: ข้อมูลไม่ครบถ้วน')),
      );
    }
  }

  void _showLeaveClassSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ออกจากคลาสแล้ว'),
          content: Text('คุณออกจากคลาสนี้เรียบร้อยแล้ว'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => MainPage()),
                );
              },
              child: Text('กลับหน้าหลัก'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getMenuItemId() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return '';
    }
    final String userId = user.uid;

    try {
      // ดึงค่า menuItemId จาก Firestore โดยการค้นหา classmenuitem ของผู้ใช้
      QuerySnapshot menuItemsSnapshot = await FirebaseFirestore.instance
          .collection('classmenuitem')
          .where('userId', isEqualTo: userId)
          .get();

      if (menuItemsSnapshot.docs.isNotEmpty) {
        return menuItemsSnapshot.docs.first.id;
      } else {
        return ''; // ไม่มีข้อมูล menuItemId
      }
    } catch (e) {
      print('Error fetching menuItemId: $e');
      return '';
    }
  }
}