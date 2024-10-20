import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumhua_project/function/groupchat.dart';
import 'package:sumhua_project/function/user_list_screen.dart';
import 'package:sumhua_project/function/settings_page.dart';
import 'package:sumhua_project/function/login_page.dart';
import 'package:sumhua_project/function/aa_audio.dart'; // นำเข้า aa_audio.dart

class RoomSlideBar extends StatefulWidget {
  final String menuItemName;

  RoomSlideBar({required this.menuItemName});

  @override
  _RoomSlideBarState createState() => _RoomSlideBarState();
}

class _RoomSlideBarState extends State<RoomSlideBar> {
  late String menuItemId;
  late String userId;
  String userRole = '';
  List<Map<String, dynamic>> chatRooms = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    userId = user.uid;

    // ดึง ID ของ menuItem จากชื่อ
    QuerySnapshot menuItemSnapshot = await FirebaseFirestore.instance
        .collection('classmenuitem')
        .where('name', isEqualTo: widget.menuItemName)
        .get();

    if (menuItemSnapshot.docs.isNotEmpty) {
      menuItemId = menuItemSnapshot.docs.first.id;

      // ตรวจสอบ role ของ user
      DocumentSnapshot roleDoc = await FirebaseFirestore.instance
          .collection('classmenuitem')
          .doc(menuItemId)
          .collection('role')
          .doc(userId)
          .get();

      if (roleDoc.exists) {
        var data = roleDoc.data() as Map<String, dynamic>?;
        userRole = data?['role'] ?? '';
      }

      // ดึงข้อมูล chatroom
      QuerySnapshot chatroomSnapshot = await FirebaseFirestore.instance
          .collection('classmenuitem')
          .doc(menuItemId)
          .collection('chatroom')
          .get();

      if (mounted) {
        setState(() {
          chatRooms = chatroomSnapshot.docs
              .map((doc) => {
                    'name': doc['name'],
                    'id': doc.id,
                  })
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Container(
            height: 110.0,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900], // สีส้ม
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 0.0),
                  child: Text(
                    'เมนูของห้องเรียน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // เพิ่มปุ่ม Chat Friend และ Setting ด้านบนปุ่ม Add Room
                ListTile(
                  leading:
                      Icon(Icons.chat, color: Colors.blue), // ไอคอน Chat Friend
                  title: Text('แชทส่วนตัว'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserListScreen(), // เปิดหน้า UserListScreen
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings,
                      color: Colors.grey), // ไอคอน Settings
                  title: Text('การตั้งค่า'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SettingsPage(), // เรียกหน้า Settings
                      ),
                    );
                  },
                ),

                // เพิ่มปุ่ม "เข้าห้องพูดคุย"
                ListTile(
                  leading: Icon(Icons.chat_bubble,
                      color: Colors.green), // ไอคอน Voice Chat
                  title: Text('เข้าห้องพูดคุย'),
                  onTap: () {
                    _showCallDialog(); // เรียกแสดง Dialog เพื่อให้ผู้ใช้กรอก call ID
                  },
                ),

                ListTile(
                  title: Text('สร้างห้องพูดคุย'),
                  trailing: Icon(Icons.add),
                  onTap: () {
                    _showAddRoomDialog();
                  },
                ),
                // แสดงผลรายการห้อง Chat Rooms
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ห้องข้อความ รายการ:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ...chatRooms
                          .map((room) => ListTile(
                                title: Text(room['name']),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupChatPage(
                                        documentId: room['id'],
                                      ),
                                    ),
                                  );
                                },
                                trailing: Icon(Icons.chat),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

void _showCallDialog() {
  final callIDController = TextEditingController(); // ไม่มีค่าเริ่มต้น ให้กรอกเอง
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('เข้าห้องพูดคุย'),
        content: TextField(
          controller: callIDController,
          decoration: InputDecoration(hintText: 'ใส่ Call ID'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              final callID = callIDController.text.trim();
              if (callID.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallPage(callID: callID), // ส่ง callID ที่ผู้ใช้กรอกไปยัง CallPage
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('กรุณาใส่ Call ID')),
                );
              }
            },
            child: Text('เข้าห้อง'),
          ),
        ],
      );
    },
  );
}


  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('สร้างห้องพูดคุย'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('สร้างห้องข้อความ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _createRoom('chatroom');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createRoom(String roomType) async {
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('คุณไม่มีสิทธิ์ในการสร้างห้อง')),
      );
      return;
    }

    TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('สร้าง ห้องพูดคุย'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: "ใส่ชื่อห้อง"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            TextButton(
              child: Text('สร้าง'),
              onPressed: () async {
                final roomName = _nameController.text.trim();
                if (roomName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a room name')),
                  );
                  return;
                }

                try {
                  final roomCollection = FirebaseFirestore.instance
                      .collection('classmenuitem')
                      .doc(menuItemId)
                      .collection('chatroom');

                  DocumentReference newRoomRef = await roomCollection.add({
                    'name': roomName,
                    'createdAt': Timestamp.now(),
                    'userId': userId,
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating room: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}