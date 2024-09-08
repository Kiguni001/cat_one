import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:sumhua_project/function/user_list_screen.dart';
import 'package:sumhua_project/function/room_chat.dart';

class SlideMenu extends StatefulWidget {
  @override
  _SlideMenuState createState() => _SlideMenuState();
}

class _SlideMenuState extends State<SlideMenu> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  String? userId;

  Future<List<DocumentSnapshot>> _getJoinedMenuItems(String userId) async {
    QuerySnapshot classmenuitemSnapshot =
        await FirebaseFirestore.instance.collection('classmenuitem').get();

    List<DocumentSnapshot> joinedMenuItems = [];

    for (var menuItem in classmenuitemSnapshot.docs) {
      QuerySnapshot roleSnapshot = await menuItem.reference
          .collection('role')
          .where('userId', isEqualTo: userId)
          .get();

      if (roleSnapshot.docs.isNotEmpty) {
        joinedMenuItems.add(menuItem);
      }
    }

    return joinedMenuItems;
  }

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      // เปลี่ยนเส้นทางไปยังหน้าล็อกอิน
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
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
                color: Color.fromARGB(255, 9, 191, 45),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 0.0),
                  child: Text(
                    'Menu',
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
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: userId != null
                  ? _getJoinedMenuItems(userId!)
                  : Future.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final menuItems = snapshot.data ?? [];

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: menuItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: Text('Add Menu Item'),
                        trailing: Icon(Icons.add),
                        onTap: () {
                          _showAddMenuOptionDialog();
                        },
                      );
                    }

                    final menuItem = menuItems[index - 1];
                    final data = menuItem.data() as Map<String, dynamic>?;
                    final isMuted = data?['muted'] ?? false;

                    return ListTile(
                      title: Text(data?['name'] ?? 'Unnamed Item'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'Mute') {
                            await FirebaseFirestore.instance
                                .collection('classmenuitem')
                                .doc(menuItem.id)
                                .update({'muted': !isMuted});
                          } else if (value == 'Delete') {
                            // เปลี่ยนจาก user.uid เป็น userId
                            _deleteMenuItem(menuItem, userId!);
                          } else if (value == 'View ID') {
                            _showMenuItemIdDialog(menuItem.id);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem(
                              value: 'Mute',
                              child: Text(isMuted ? 'Unmute' : 'Mute'),
                            ),
                            PopupMenuItem(
                              value: 'Delete',
                              child: Text('ลบเมนู'),
                            ),
                            PopupMenuItem(
                              value: 'View ID',
                              child: Text('ดูรหัสเมนู'),
                            ),
                          ];
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                RoomChat(data?['name'] ?? 'Unknown'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: Column(
                    children: [
                      Icon(Icons.message, color: Colors.blue),
                      Text('ข้อความ', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserListScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Column(
                    children: [
                      Icon(Icons.warehouse, color: Colors.blue),
                      Text('คลังไฟล์', style: TextStyle(fontSize: 12))
                    ],
                  ),
                  onPressed: () {
                    // Add functionality for file storage button here
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenuOptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select an Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Create Menu Item'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateMenuItemDialog();
                },
              ),
              ListTile(
                title: Text('Join Menu Item'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showJoinMenuItemDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateMenuItemDialog() {
    TextEditingController _textFieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Menu Item'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Enter menu item name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                final String menuItemName = _textFieldController.text.trim();
                if (menuItemName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a menu item name')),
                  );
                  return;
                }

                final User? user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please log in first')),
                  );
                  return;
                }

                final newItem = {
                  'username': user.displayName ?? 'Unknown User',
                  'userId': user.uid,
                  'name': menuItemName,
                  'muted': true,
                };

                try {
                  // เพิ่ม Menu Item ใน collection classmenuitem
                  final docRef = await FirebaseFirestore.instance
                      .collection('classmenuitem')
                      .add(newItem);

                  // เพิ่มผู้สร้างใน subcollection role เป็น admin
                  await docRef.collection('role').doc(user.uid).set({
                    'username': user.displayName ?? 'Unknown User',
                    'userId': user.uid,
                    'role': 'admin',
                  });

                  // สร้าง collection chatroom และ audioroom พร้อม document ชื่อ Chat และ Audio
                  await docRef.collection('chatroom').doc('Chat').set({
                    'name': 'Chat',
                    'createdAt': Timestamp.now(),
                  });

                  await docRef.collection('audioroom').doc('Audio').set({
                    'name': 'Audio',
                    'createdAt': Timestamp.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Menu Item created successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create Menu Item: $e')),
                  );
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showJoinMenuItemDialog() {
    TextEditingController _idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Join Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _idController,
                decoration: InputDecoration(hintText: "Enter menu item ID"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Clipboard.getData(Clipboard.kTextPlain).then((value) {
                    _idController.text = value?.text ?? '';
                  });
                },
                child: Text('Paste ID from Clipboard'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Join'),
              onPressed: () async {
                final String menuItemId = _idController.text.trim();
                if (menuItemId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a menu item ID')),
                  );
                  return;
                }

                final User? user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please log in first')),
                  );
                  return;
                }

                try {
                  // เข้าร่วม Menu Item โดยเพิ่มข้อมูลลงใน subcollection role
                  final menuItemRef = FirebaseFirestore.instance
                      .collection('classmenuitem')
                      .doc(menuItemId);

                  final roleRef = menuItemRef.collection('role').doc(user.uid);
                  await roleRef.set({
                    'username': user.displayName ?? 'Unknown User',
                    'userId': user.uid,
                    'role': 'member',
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully joined Menu Item!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to join Menu Item: $e')),
                  );
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showMenuItemIdDialog(String menuItemId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Menu Item ID'),
          content: Text(menuItemId),
          actions: <Widget>[
            TextButton(
              child: Text('Copy ID'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: menuItemId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Menu Item ID copied to clipboard')),
                );
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMenuItem(DocumentSnapshot menuItem, String userId) async {
    try {
      final menuItemRef =
          FirebaseFirestore.instance.collection('classmenuitem').doc(menuItem.id);
      final roleDoc = await menuItemRef.collection('role').doc(userId).get();

      if (roleDoc.exists && roleDoc.data()?['role'] == 'admin') {
        await menuItemRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu Item deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You do not have permission to delete this Menu Item')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete Menu Item: $e')),
      );
    }
  }
}
