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
    QuerySnapshot classmenuitemSnapshot = await FirebaseFirestore.instance
        .collection('classmenuitem')
        .get();

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
              future: userId != null ? _getJoinedMenuItems(userId!) : Future.value([]),
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
                            await FirebaseFirestore.instance
                                .collection('classmenuitem')
                                .doc(menuItem.id)
                                .delete();
                          } else if (value == 'View ID') {
                            _showMenuItemIdDialog(menuItem.id);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem(
                              value: 'Mute',
                              child: Text(isMuted
                                  ? 'เปิดการแจ้งเตือนเมนูนี้'
                                  : 'ปิดการแจ้งเตือนเมนูนี้'),
                            ),
                            PopupMenuItem(
                              value: 'Delete',
                              child: Text('ลบเมนู'),
                            ),
                            PopupMenuItem(
                              value: 'View ID',
                              child: Text('ดูเลข ID'),
                            ),
                          ];
                        },
                        icon: Icon(Icons.more_vert),
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
                decoration: InputDecoration(hintText: "Enter Menu Item ID"),
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

                if (menuItemId.isNotEmpty) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please log in first')),
                      );
                      return;
                    }

                    await joinGroup(menuItemId, user.uid,
                        user.displayName ?? 'Unknown User');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: $e')),
                    );
                  }
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please enter a valid Menu Item ID')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> joinGroup(
      String menuItemId, String userId, String userName) async {
    try {
      if (menuItemId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid Menu Item ID')),
        );
        return;
      }

      // เข้าถึง Menu Item โดยตรง
      final menuItemDoc = await FirebaseFirestore.instance
          .collection('classmenuitem')
          .doc(menuItemId)
          .get();

      if (menuItemDoc.exists) {
        final roleDoc = menuItemDoc.reference.collection('role').doc(userId);
        final roleSnapshot = await roleDoc.get();

        if (roleSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have already joined this group.')),
          );
        } else {
          // เพิ่มผู้ใช้ใน subcollection role เป็น member
          await roleDoc.set({
            'username': userName,
            'userId': userId,
            'role': 'member',
          });

          // อัปเดตข้อมูล Menu Item ของผู้ใช้ใน collection users (ถ้ายังคงต้องการ)
          // สามารถเพิ่มได้ตามต้องการ เช่น ถ้าต้องการให้ข้อมูล Menu Item อยู่ใน collection ของผู้ใช้
          // await FirebaseFirestore.instance
          //     .collection('users')
          //     .doc(userId)
          //     .collection('menuItems')
          //     .doc(menuItemId)
          //     .set(menuItemDoc.data() as Map<String, dynamic>, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully joined the group!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu Item not found')),
        );
      }
    } catch (e) {
      print('Error joining group: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _showMenuItemIdDialog(String menuItemId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Menu Item ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(menuItemId),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Copy ID'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: menuItemId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ID copied to clipboard!')),
                );
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
