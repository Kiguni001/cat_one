import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderName;
  final String content;
  final Timestamp timestamp;

  Message({required this.senderName, required this.content, required this.timestamp});

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      senderName: doc['senderName'],
      content: doc['content'],
      timestamp: doc['timestamp'],
    );
  }
}
