import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // สำหรับ Clipboard functionality
import 'package:share_plus/share_plus.dart'; // สำหรับการแชร์ลิงก์
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
                          } else if (value == 'Share') {
                            _showShareLinkDialog(menuItem.id);
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
                            PopupMenuItem(
                              value: 'Share',
                              child: Text('แชร์ลิงก์'),
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
                    .add(newItem)
                    .then((docRef) {
                  // หลังจากสร้าง Menu Item ใหม่เสร็จสิ้น
                  _showShareLinkDialog(
                      docRef.id); // แสดงลิงก์ของ Menu Item ที่สร้าง
                });
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

                if (menuItemId.isNotEmpty && menuItemId.length > 0) {
                  try {
                    // การค้นหา Menu Item โดยใช้ FieldPath.documentId
                    final QuerySnapshot menuItemDocs = await FirebaseFirestore
                        .instance
                        .collectionGroup('menuItems')
                        .where(FieldPath.documentId, isEqualTo: menuItemId)
                        .get();

                    if (menuItemDocs.docs.isNotEmpty) {
                      // ดำเนินการหากพบ Menu Item
                      final menuItemData = menuItemDocs.docs.first.data()
                          as Map<String, dynamic>;

                      // เพิ่ม Menu Item ให้กับ User ปัจจุบัน
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('menuItems')
                          .doc(menuItemId)
                          .set(menuItemData, SetOptions(merge: true));
                    } else {
                      // หากไม่พบ Menu Item
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Menu Item not found')),
                      );
                    }
                  } catch (e) {
                    // แสดงข้อผิดพลาด
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: $e')),
                    );
                  }
                } else {
                  // หากไม่มีการกรอก ID
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
                Clipboard.setData(ClipboardData(
                    text: menuItemId)); // คัดลอก ID ไปยังคลิปบอร์ด
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

  void _showShareLinkDialog(String menuItemId) {
    final shareLink =
        'https://sumhua.com/menuItem/$menuItemId'; // ลิงก์ที่สามารถแชร์ได้

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Share Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share this link:'),
              SelectableText(
                  shareLink), // ใช้ SelectableText เพื่อให้ผู้ใช้คัดลอกลิงก์
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Copy Link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: shareLink)); // คัดลอกลิงก์ไปยังคลิปบอร์ด
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link copied to clipboard!')),
                );
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Share'),
              onPressed: () {
                Share.share(
                    'Check out this menu item: $shareLink'); // แชร์ลิงก์
              },
            ),
          ],
        );
      },
    );
  }
}
