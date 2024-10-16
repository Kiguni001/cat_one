import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumhua_project/function/groupchat.dart';
import 'package:sumhua_project/function/user_list_screen.dart';
import 'package:sumhua_project/function/voice_channel.dart';
import 'package:sumhua_project/function/settings_page.dart';
import 'package:sumhua_project/src/pages/index.dart';
import 'package:sumhua_project/function/login_page.dart';


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
  List<String> audioRooms = [];

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

      // ดึงข้อมูล chatroom และ groupaudioroom
      QuerySnapshot chatroomSnapshot = await FirebaseFirestore.instance
          .collection('classmenuitem')
          .doc(menuItemId)
          .collection('chatroom')
          .get();

      QuerySnapshot groupaudioroomSnapshot = await FirebaseFirestore.instance
          .collection('classmenuitem')
          .doc(menuItemId)
          .collection('groupaudioroom')
          .get();

      if (mounted) {
        setState(() {
          chatRooms = chatroomSnapshot.docs
              .map((doc) => {
                    'name': doc['name'],
                    'id': doc.id,
                  })
              .toList();

          audioRooms = groupaudioroomSnapshot.docs
              .map((doc) => doc['name'] as String)
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

                ListTile(
                  leading: Icon(Icons.voice_chat,
                      color: Colors.green), // ไอคอน Voice Chat
                  title: Text('เข้าห้องแชทเสียง'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LoginPage(), // นำไปยังหน้า LoginPage
                      ),
                    );
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

                // แสดงผลรายการห้อง Audio Rooms
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ห้องคุยเสียง รายการ:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ...audioRooms
                          .map((roomName) => ListTile(
                                title: Text(roomName),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          IndexPage(), // นำไปยังหน้า IndexPage
                                    ),
                                  );
                                },
                                trailing: Icon(Icons.volume_up),
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
              ListTile(
                title: Text('สร้างห้องคุยเสียง'),
                onTap: () {
                  Navigator.of(context).pop();
                  _createRoom('audioroom');
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
          title: Text(
              'สร้าง ${roomType == 'chatroom' ? 'ห้องพูดคุย' : 'ห้องคุยเสียง'}'),
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
                  final roomCollection = roomType == 'chatroom'
                      ? FirebaseFirestore.instance
                          .collection('classmenuitem')
                          .doc(menuItemId)
                          .collection('chatroom')
                      : FirebaseFirestore.instance
                          .collection('classmenuitem')
                          .doc(menuItemId)
                          .collection('groupaudioroom');

                  DocumentReference newRoomRef = await roomCollection.add({
                    'name': roomName,
                    'createdAt': Timestamp.now(),
                    'userId': userId,
                  });

                  if (roomType == 'audioroom') {
                    await FirebaseFirestore.instance
                        .collection('theaudioroom')
                        .doc(newRoomRef.id) // ใช้ id ของเอกสารที่สร้าง
                        .set({
                      'name': roomName,
                      'userId': userId,
                      'menuItemId': menuItemId,
                      'createdAt': Timestamp.now(),
                    });

                    // นำทางไปยัง IndexPage แทน AudioRoom
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IndexPage(), // นำทางไปที่ IndexPage
                      ),
                    );
                  }
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
