import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomSlideBar extends StatefulWidget {
  final String menuItemName; // รับค่าชื่อเมนู

  RoomSlideBar({required this.menuItemName}); // คอนสตรัคเตอร์รับค่า

  @override
  _RoomSlideBarState createState() => _RoomSlideBarState();
}

class _RoomSlideBarState extends State<RoomSlideBar> {
  List<String> chatRooms = []; // List to hold the names of created chat rooms
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  late String userId;

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    }
    _loadChatRooms(); // Load existing chat rooms
  }

  void _loadChatRooms() async {
    // Load chat rooms from Firestore for the specific menuItemName
    QuerySnapshot querySnapshot = await usersCollection
        .doc(userId)
        .collection(widget.menuItemName)
        .get();

    if (!mounted) return; // ตรวจสอบว่า widget ยังคงอยู่ใน tree หรือไม่

    setState(() {
      chatRooms = querySnapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  void _showAddRoomDialog() {
    TextEditingController _textFieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ตั้งชื่อ Chat Room'),
          content: TextField(
            controller: _textFieldController,
            autofocus: true,
            decoration: InputDecoration(hintText: "ใส่ชื่อ Chat Room"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('สร้าง'),
              onPressed: () async {
                if (_textFieldController.text.isNotEmpty) {
                  // Add the new Chat Room to Firestore under the selected menuItem collection
                  await usersCollection
                      .doc(userId)
                      .collection(widget.menuItemName) // ใช้ widget.menuItemName ที่รับมาจาก RoomChat
                      .add({
                    'name': _textFieldController.text,
                    'createdAt': Timestamp.now(),
                  });

                  if (!mounted) return; // ตรวจสอบว่า widget ยังคงอยู่ใน tree ก่อนที่จะอัปเดต

                  setState(() {
                    chatRooms.add(_textFieldController.text); // Add the new Chat Room to the list
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('สร้าง Room'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showAddRoomDialog(); // Call the function to create Chat Room
              },
              child: Text('สร้าง Chat Room'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                // Add logic to create an Audio Room here
              },
              child: Text('สร้าง Audio Room'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange,
            ),
            child: Text(
              'Room SlideBar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chat'),
            onTap: () {
              // Implement Chat Navigation
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              // Implement Settings Navigation
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add Room'),
            onTap: () {
              _showMenuDialog(); // Show menu dialog when "Add Room" is clicked
            },
          ),
          ...chatRooms.map((chatRoomName) => Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: ListTile(
              leading: Icon(Icons.chat_bubble_outline, size: 20),
              title: Text(
                chatRoomName,
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                // Implement navigation to the created Chat Room
              },
            ),
          )),
        ],
      ),
    );
  }
}
