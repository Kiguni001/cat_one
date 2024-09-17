import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumhua_project/function/groupchat.dart';
import 'package:sumhua_project/function/user_list_screen.dart';
import 'package:sumhua_project/function/voice_channel.dart';

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
    // Uncomment the following line to run the migration
    // _migrateAudioRooms();
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
                color: Colors.orange, // สีส้ม
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 0.0),
                  child: Text(
                    'Room Management',
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
                  title: Text('Chat Friend'),
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
                  title: Text('Settings'),
                  onTap: () {
                    // Action เมื่อกด Settings
                  },
                ),
                ListTile(
                  title: Text('Add Room'),
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
                        'Chat Rooms:',
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
                        'Audio Rooms:',
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
                                      builder: (context) => VoiceChannelPage(
                                        channelName:
                                            roomName, // ส่งชื่อห้องที่เลือก
                                        token: null, // หรือส่ง token หากมี
                                      ),
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
          title: Text('Create Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Create Chat Room'),
                onTap: () {
                  Navigator.of(context).pop();
                  _createRoom('chatroom');
                },
              ),
              ListTile(
                title: Text('Create Audio Room'),
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
              'Create ${roomType == 'chatroom' ? 'Chat Room' : 'Audio Room'}'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: "Enter room name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            TextButton(
              child: Text('Create'),
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

                    // สร้างห้องเสียงใน Agora
                    await _createAgoraChannel(
                        newRoomRef.id); // ส่ง id ของเอกสารที่สร้าง
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${roomType == 'chatroom' ? 'Chat Room' : 'Audio Room'} created successfully')),
                    );
                  }

                  // Refresh the list of rooms after creating a new one
                  await _initialize();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to create ${roomType == 'chatroom' ? 'Chat Room' : 'Audio Room'}: $e')),
                    );
                  }
                }

                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAgoraChannel(String documentId) async {
    // สร้างห้องเสียงใน Agora โดยใช้ documentId
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceChannelPage(
          channelName: documentId, // ส่ง id ของเอกสารที่สร้าง
          token: null, // หรือส่ง token หากมี
        ),
      ),
    );
  }

  Future<void> _migrateAudioRooms() async {
    final QuerySnapshot oldAudioRoomsSnapshot = await FirebaseFirestore.instance
        .collection('classmenuitem')
        .doc(menuItemId)
        .collection('audioroom')
        .get();

    final CollectionReference newAudioRoomsCollection = FirebaseFirestore
        .instance
        .collection('classmenuitem')
        .doc(menuItemId)
        .collection('groupaudioroom');

    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in oldAudioRoomsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      await newAudioRoomsCollection.add(data);
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
