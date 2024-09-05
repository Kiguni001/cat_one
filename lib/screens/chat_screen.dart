import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumhua_project/models/message.dart'; // นำเข้าโมเดล Message

class ChatScreen extends StatefulWidget {
  final String menuItemId;

  ChatScreen(this.menuItemId);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference messagesCollection = FirebaseFirestore.instance.collection('messages');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Page'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesCollection
                  .where('menuItemId', isEqualTo: widget.menuItemId)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs.map((doc) => Message.fromDocument(doc)).toList();

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(message.senderName[0]),
                      ),
                      title: Text(message.senderName),
                      subtitle: Text(message.content),
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
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    final newMessage = {
      'senderName': 'Member 1', // แทนที่ด้วยชื่อผู้ส่งที่แท้จริง
      'content': _controller.text,
      'timestamp': Timestamp.now(),
      'menuItemId': widget.menuItemId,
    };

    messagesCollection.add(newMessage);
    _controller.clear();
  }
}
