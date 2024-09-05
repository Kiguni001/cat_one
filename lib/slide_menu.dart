import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard functionality
import 'package:sumhua_project/function/user_list_screen.dart';
import 'package:sumhua_project/function/room_chat.dart';

class SlideMenu extends StatefulWidget {
  @override
  _SlideMenuState createState() => _SlideMenuState();
}

class _SlideMenuState extends State<SlideMenu> {
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
            child: StreamBuilder<QuerySnapshot>(
              stream: usersCollection
                  .doc(userId)
                  .collection('menuItems')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final menuItems = snapshot.data!.docs;

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
                        onSelected: (value) {
                          if (value == 'Mute') {
                            usersCollection
                                .doc(userId)
                                .collection('menuItems')
                                .doc(menuItem.id)
                                .update({'muted': !isMuted});
                          } else if (value == 'Delete') {
                            usersCollection
                                .doc(userId)
                                .collection('menuItems')
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
                    // เพิ่มการทำงานเมื่อกดปุ่ม คลังสินค้า
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
              onPressed: () {
                final newItem = {
                  'name': _textFieldController.text,
                  'createdBy': userId, // ID ของผู้สร้าง
                  'sharedWith': [], // ลิสต์ของ User IDs ที่ได้รับการแชร์
                  'muted': false,
                };
                usersCollection
                    .doc(userId)
                    .collection('menuItems')
                    .add(newItem);
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
                final menuItemId = _idController.text.trim();
                if (menuItemId.isNotEmpty) {
                  try {
                    // ค้นหา Menu Item ที่มี id ตรงกันในคอลเลกชันของ User1 (ID ของ User1)
                    final menuItemDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc('User1ID') // ใส่ ID ของ User1 ตรงนี้
                        .collection('menuItems')
                        .doc(menuItemId)
                        .get();

                    if (menuItemDoc.exists) {
                      final menuItemData = menuItemDoc.data();

                      // เพิ่ม Menu Item ให้กับ User2
                      await usersCollection
                          .doc(userId) // User2's document ID
                          .collection('menuItems')
                          .doc(menuItemId)
                          .set(menuItemData!, SetOptions(merge: true));

                      Navigator.of(context).pop();
                    } else {
                      // หากไม่เจอ Menu Item
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Menu Item not found')),
                      );
                    }
                  } catch (e) {
                    // จัดการกับข้อผิดพลาดที่เกิดขึ้น
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('An error occurred: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMenuItemIdDialog(String itemId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Menu Item ID'),
          content: Text('ID: $itemId'),
          actions: <Widget>[
            TextButton(
              child: Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: itemId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ID copied to clipboard')),
                );
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
