import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friendchat.dart';

class UserListScreen extends StatelessWidget {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.cyan,
        appBarTheme: AppBarTheme(
          color: Colors.cyan,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.cyan,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('รายชื่อผู้ใช้'),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: usersCollection
                    .doc(currentUser.uid)
                    .collection('friends')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final friends = snapshot.data?.docs ?? [];

                  if (friends.isEmpty) {
                    return Center(child: Text('ไม่มีรายชื่อผู้ใช้'));
                  }

                  return ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend =
                          friends[index].data() as Map<String, dynamic>;
                      final friendUID = friend['uid'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: usersCollection.doc(friendUID).get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              title: Text('Loading...'),
                            );
                          }
                          if (userSnapshot.hasError) {
                            return ListTile(
                              title: Text('Error: ${userSnapshot.error}'),
                            );
                          }

                          final userData = userSnapshot.data?.data()
                                  as Map<String, dynamic>? ??
                              {};
                          final username = userData.containsKey('username')
                              ? userData['username']
                              : 'Unknown User';
                          final profilePicUrl = userData
                                  .containsKey('profilePic')
                              ? userData['profilePic']
                              : 'https://example.com/default-profile-pic.png'; // Replace with default URL

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(userData[
                                      'profileImageUrl'] ??
                                  'https://example.com/default-profile-pic.png'), // URL รูปโปรไฟล์หรือรูป default
                            ),
                            title: Text(username),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteFriend(context, friendUID);
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendChatPage(
                                    friendName: friend['name'] ?? 'No Name',
                                    friendUID: friendUID,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Add Friend'),
                onPressed: () {
                  _showAddFriendDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFriend(BuildContext context, String friendUID) async {
    // Delete the friend from the user's friend list
    await usersCollection
        .doc(currentUser.uid)
        .collection('friends')
        .doc(friendUID)
        .delete();

    // Optionally, show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ลบเพื่อนเรียบร้อยแล้ว')),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    TextEditingController _textFieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Friend'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Enter friend's username"),
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
                final friendUsername = _textFieldController.text;

                QuerySnapshot userSnapshot = await usersCollection
                    .where('username', isEqualTo: friendUsername)
                    .get();

                if (userSnapshot.docs.isNotEmpty) {
                  final friendDoc = userSnapshot.docs.first;
                  final friendUID = friendDoc.id;

                  DocumentSnapshot friendSnapshot = await usersCollection
                      .doc(currentUser.uid)
                      .collection('friends')
                      .doc(friendUID)
                      .get();

                  if (friendSnapshot.exists) {
                    Navigator.of(context).pop();
                    _showAlreadyFriendDialog(context);
                  } else {
                    await usersCollection
                        .doc(currentUser.uid)
                        .collection('friends')
                        .doc(friendUID)
                        .set({'name': friendDoc['username'], 'uid': friendUID});

                    await usersCollection
                        .doc(friendUID)
                        .collection('friends')
                        .doc(currentUser.uid)
                        .set({
                      'name': currentUser.displayName ?? 'Unknown',
                      'uid': currentUser.uid
                    });

                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context).pop();
                  _showErrorDialog(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('ไม่มีรายชื่อผู้ใช้นี้'),
          actions: <Widget>[
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

  void _showAlreadyFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Already a Friend'),
          content: Text('คุณเป็นเพื่อนกับผู้ใช้นี้อยู่แล้ว'),
          actions: <Widget>[
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
