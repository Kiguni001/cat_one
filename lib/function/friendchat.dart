import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class FriendChatPage extends StatefulWidget {
  final String friendName;
  final String friendUID;

  FriendChatPage({required this.friendName, required this.friendUID});

  @override
  _FriendChatPageState createState() => _FriendChatPageState();
}

class _FriendChatPageState extends State<FriendChatPage> {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _messageController = TextEditingController();

  CollectionReference get chatCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('friends')
      .doc(widget.friendUID)
      .collection('chat');

  CollectionReference get friendChatCollection => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.friendUID)
      .collection('friends')
      .doc(currentUser.uid)
      .collection('chat');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatCollection
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message['senderUID'] == currentUser.uid;
                    final timestamp = message['timestamp'];

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: isSender
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isSender) ...[
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Text(widget.friendName[0]),
                            ),
                            SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isSender
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSender
                                        ? Colors.blue
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: message['type'] == 'text'
                                      ? Text(
                                          message['content'],
                                          style: TextStyle(
                                            color: isSender
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        )
                                      : message['type'] == 'image'
                                          ? Image.network(message['url'])
                                          : message['type'] == 'file'
                                              ? ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  title:
                                                      Text(message['content']),
                                                  leading:
                                                      Icon(Icons.attach_file),
                                                  onTap: () => _openFileOrImage(
                                                      message['url'], 'file'),
                                                )
                                              : Container(),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () async {
                    await _sendFile();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () async {
                    await _sendImage();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    await _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = path.basename(file.path);

      try {
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'chats/${currentUser.uid}/${widget.friendUID}/files/$fileName');

        UploadTask uploadTask = storageReference.putFile(file);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();

        Map<String, dynamic> messageData = {
          'type': 'file',
          'content': fileName,
          'url': downloadURL,
          'timestamp': FieldValue.serverTimestamp(),
          'senderUID': currentUser.uid,
        };

        await chatCollection.add(messageData);
        await friendChatCollection.add(messageData);
      } catch (e) {
        _handleFileError(e);
      }
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String fileName = path.basename(imageFile.path);

      try {
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'chats/${currentUser.uid}/${widget.friendUID}/images/$fileName');

        UploadTask uploadTask = storageReference.putFile(imageFile);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();

        Map<String, dynamic> messageData = {
          'type': 'image',
          'content': fileName,
          'url': downloadURL,
          'timestamp': FieldValue.serverTimestamp(),
          'senderUID': currentUser.uid,
        };

        await chatCollection.add(messageData);
        await friendChatCollection.add(messageData);
      } catch (e) {
        _handleFileError(e);
      }
    }
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text;

    if (message.isNotEmpty) {
      Map<String, dynamic> messageData = {
        'type': 'text',
        'content': message,
        'timestamp': FieldValue.serverTimestamp(),
        'senderUID': currentUser.uid,
      };

      await chatCollection.add(messageData);
      await friendChatCollection.add(messageData);

      _messageController.clear();
    }
  }

  void _openFileOrImage(String url, String type) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file or image.')));
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'Unknown time';
    }

    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    return 'Invalid time format';
  }

  void _handleFileError(dynamic e) {
    if (e is FirebaseException && e.code == 'unauthorized') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are not authorized to upload this file.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while uploading the file.')),
      );
    }
  }
}
