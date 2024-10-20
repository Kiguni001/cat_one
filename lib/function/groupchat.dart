import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'file_preview_page.dart'; // Import the new file preview page

class GroupChatPage extends StatefulWidget {
  final String documentId;

  GroupChatPage({required this.documentId});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _messageController = TextEditingController();
  late String _userId;
  late CollectionReference _dataCollection;
  File? _file;
  String _message = '';

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
    _userId = user.uid;

    _dataCollection = FirebaseFirestore.instance
        .collection('groupchatroom')
        .doc(widget.documentId)
        .collection('data');
  }

  Future<void> _sendMessage(String message) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final senderName = currentUser?.displayName ?? 'Unknown';
    final senderId = currentUser?.uid ?? '';

    if (message.isNotEmpty) {
      try {
        await _dataCollection.add({
          'content': message,
          'senderName': senderName,
          'senderUID': senderId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'message',
        });
        _messageController.clear();
      } catch (e) {
        print('Failed to send message: $e');
      }
    }
  }

  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('files')
            .child('$fileName.${result.files.single.extension}');
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final fileUrl = await snapshot.ref.getDownloadURL();
        final currentUser = FirebaseAuth.instance.currentUser;
        final senderName = currentUser?.displayName ?? 'Unknown';
        final senderId = currentUser?.uid ?? '';

        await _dataCollection.add({
          'content': fileUrl,
          'senderName': senderName,
          'senderUID': senderId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'file',
        });
      } catch (e) {
        print('Failed to send file: $e');
      }
    }
  }

  Future<void> _sendImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child('$fileName.${result.files.single.extension}');
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final imageUrl = await snapshot.ref.getDownloadURL();
        final currentUser = FirebaseAuth.instance.currentUser;
        final senderName = currentUser?.displayName ?? 'Unknown';
        final senderId = currentUser?.uid ?? '';

        await _dataCollection.add({
          'content': imageUrl,
          'senderName': senderName,
          'senderUID': senderId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'image',
        });
      } catch (e) {
        print('Failed to send image: $e');
      }
    }
  }

  Future<String> _getUserStatus(String uid) async {
    try {
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      return userData?['status'] ?? 'Unknown status';
    } catch (e) {
      print('Error fetching user status: $e');
      return 'Unknown status';
    }
  }

  void _viewFile(String url, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilePreviewPage(
          fileUrl: url,
          fileType: type,
        ),
      ),
    );
  }

  // เพิ่มฟังก์ชันสำหรับแสดงอัลบั้ม
  void _viewAlbum() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumPage(documentId: widget.documentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ห้องข้อความกลุ่ม',
          style: TextStyle(color: Colors.white), // ปรับข้อความให้เป็นสีขาว
        ),
        backgroundColor: Colors.brown[700],
        actions: [
          IconButton(
            icon: Icon(Icons.photo_album),
            color: Colors.white,  // กำหนดสีของไอคอนเป็นสีขาว
            onPressed: _viewAlbum, // เมื่อกดจะเปิดหน้าอัลบั้ม
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dataCollection
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                return ListView(
                  reverse: true,
                  children: messages.map((message) {
                    final messageData = message.data() as Map<String, dynamic>;
                    final senderUID = messageData['senderUID'];
                    return ListTile(
                      leading: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(senderUID) // ใช้ senderUID แทน friendUID
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircleAvatar(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return CircleAvatar(child: Icon(Icons.error));
                          }
                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>?;

                          final profileImageUrl =
                              userData?['profileImageUrl'] ?? '';
                          final userName = userData?['name'] ??
                              'Unknown'; // ใช้ชื่อที่ได้รับจาก Firebase

                          return CircleAvatar(
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Text(userName.isNotEmpty ? userName[0] : '?')
                                : null,
                          );
                        },
                      ),
                      title: FutureBuilder<String>(
                        future: _getUserStatus(senderUID),
                        builder: (context, statusSnapshot) {
                          if (statusSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text('Loading status...');
                          }
                          if (statusSnapshot.hasError) {
                            return Text('Error loading status');
                          }
                          final userStatus = statusSnapshot.data ?? 'Unknown';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$userStatus: ${messageData['senderName']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (messageData['type'] == 'message')
                                SelectableText(messageData['content'])
                              else if (messageData['type'] == 'image')
                                GestureDetector(
                                  onTap: () {
                                    _viewFile(messageData['content'], 'image');
                                  },
                                  child: Image.network(
                                    messageData['content'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (messageData['type'] == 'file')
                                GestureDetector(
                                  onTap: () {
                                    _viewFile(messageData['content'], 'file');
                                  },
                                  child: Row(
                                    children: [
                                      Icon(Icons.attach_file),
                                      Text('File attached'),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _sendFile,
                ),
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (value) {
                      setState(() {
                        _message = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_message);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// สร้างหน้า AlbumPage เพื่อแสดงภาพและไฟล์
class AlbumPage extends StatefulWidget {
  final String documentId;

  AlbumPage({required this.documentId});

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  // ตัวแปรสำหรับเลือกแสดงผล
  bool isImageView = true;

  @override
  Widget build(BuildContext context) {
    final dataCollection = FirebaseFirestore.instance
        .collection('groupchatroom')
        .doc(widget.documentId)
        .collection('data');

    return Scaffold(
      appBar: AppBar(
        title: Text('อัลบั้ม ภาพ/ไฟล์'),
        actions: [
          // ปุ่มสำหรับสลับการแสดงผล (ภาพ/ไฟล์)
          ToggleButtons(
            children: [Icon(Icons.image), Icon(Icons.attach_file)],
            isSelected: [isImageView, !isImageView],
            onPressed: (index) {
              setState(() {
                isImageView = index == 0;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;
          final imagesAndFiles = data
              .where((doc) =>
                  (isImageView && doc['type'] == 'image') ||
                  (!isImageView && doc['type'] == 'file'))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // จำนวนคอลัมน์ในกริด
              crossAxisSpacing: 10, // ระยะห่างระหว่างคอลัมน์
              mainAxisSpacing: 10, // ระยะห่างระหว่างแถว
            ),
            itemCount: imagesAndFiles.length,
            itemBuilder: (context, index) {
              final messageData = imagesAndFiles[index].data()
                  as Map<String, dynamic>;
              final senderName = messageData['senderName'] ?? 'Unknown';

              if (messageData['type'] == 'image') {
                // ถ้าเป็นรูปภาพให้แสดงในรูปแบบกริด
                return GestureDetector(
                  onTap: () {
                    // เพิ่มฟังก์ชันการคลิกเพื่อดูภาพหรือไฟล์
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(messageData['content']),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('ส่งโดย: $senderName'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(messageData['content']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              } else {
                // ถ้าเป็นไฟล์ให้แสดงเป็นไอคอนพร้อมชื่อไฟล์
                return GestureDetector(
                  onTap: () {
                    // เพิ่มฟังก์ชันการคลิกเพื่อดูไฟล์
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file, size: 50),
                              SizedBox(height: 10),
                              Text('ไฟล์แนบ'),
                              SizedBox(height: 10),
                              Text('ส่งโดย: $senderName'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.attach_file,
                        size: 50,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
