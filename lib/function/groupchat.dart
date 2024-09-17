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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chat'),
        backgroundColor: Colors.orange,
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
                    return ListTile(
                      leading: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(messageData['senderUID']) // ใช้ senderUID แทน friendUID
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
                          final userName =
                              userData?['name'] ?? 'Unknown'; // ใช้ชื่อที่ได้รับจาก Firebase

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
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sent by: ${messageData['senderName']}', // แสดงชื่อของผู้ส่งถัดจาก Sent by:
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (messageData['type'] == 'message')
                            Text(messageData['content'])
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
                      hintText: 'Type your message here...',
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
