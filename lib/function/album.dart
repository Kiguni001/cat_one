import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AlbumPage extends StatefulWidget {
  final String classroomId;

  AlbumPage({required this.classroomId});

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  bool _showImages = true; // สำหรับการสลับระหว่างแสดงภาพและไฟล์

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('อัลบั้มภาพและไฟล์'),
        backgroundColor: Colors.brown[700],
        actions: [
          IconButton(
            icon: Icon(_showImages ? Icons.insert_drive_file : Icons.image),
            onPressed: () {
              setState(() {
                _showImages = !_showImages; // สลับระหว่างแสดงภาพและไฟล์
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groupchatroom') // ดึงข้อมูลจาก collection หลัก
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // ดึงเอกสารทั้งหมดของ groupchatroom
          final chatRooms = snapshot.data!.docs;

          // ดึงข้อมูลจาก subcollection data ของ groupchatroom ที่มี classroomId ตรงกัน
          return FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait(
              chatRooms.map((room) {
                return FirebaseFirestore.instance
                    .collection('groupchatroom')
                    .doc(room.id) // เข้าถึงเอกสารใน collection groupchatroom
                    .collection('data') // เข้าถึง subcollection data
                    .where('classroomId', isEqualTo: widget.classroomId) // ตรวจสอบ classroomId
                    .get(); // ดึงข้อมูล
              }).toList(),
            ),
            builder: (context, futureSnapshot) {
              if (!futureSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              // รวมเอกสารจาก subcollections ต่างๆ
              final allData = futureSnapshot.data!
                  .expand((querySnapshot) => querySnapshot.docs)
                  .toList();

              // คัดแยกข้อมูลตาม type ที่ต้องการแสดงผล (image หรือ file)
              List<Widget> items = allData.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _showImages
                    ? data['type'] == 'image' // แสดงเฉพาะภาพถ้า _showImages เป็นจริง
                    : data['type'] == 'file'; // แสดงเฉพาะไฟล์ถ้า _showImages เป็นเท็จ
              }).map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                if (data['type'] == 'image') {
                  return GestureDetector(
                    onTap: () {
                      // เพิ่มการคลิกเพื่อดูภาพขนาดใหญ่ได้ที่นี่
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        data['content'], // URL ของภาพ
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                } else if (data['type'] == 'file') {
                  return ListTile(
                    leading: Icon(Icons.attach_file),
                    title: Text(data['fileName'] ?? 'ไฟล์แนบ'), // แสดงชื่อไฟล์
                    onTap: () {
                      // เพิ่มฟังก์ชันการเปิดไฟล์
                    },
                  );
                }
                return SizedBox.shrink();
              }).toList();

              // แสดงข้อมูลใน GridView หรือ ListView ตามที่ผู้ใช้สลับระหว่างภาพและไฟล์
              return GridView.count(
                crossAxisCount: _showImages ? 3 : 1, // ปรับจำนวนคอลัมน์ตามโหมดการแสดงผล
                children: items,
              );
            },
          );
        },
      ),
    );
  }
}
