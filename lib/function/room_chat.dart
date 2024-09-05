import 'package:flutter/material.dart';
import 'roomslidebar.dart'; // นำเข้า SlideBar ใหม่ที่สร้าง

class RoomChat extends StatelessWidget {
  final String menuItemName; // รับค่าชื่อเมนู

  RoomChat(this.menuItemName); // คอนสตรัคเตอร์รับค่า

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room Chat'),
        backgroundColor: Colors.orange,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // เปิด SlideBar
            },
          ),
        ),
      ),
      drawer: RoomSlideBar(menuItemName: menuItemName), // ส่งค่า menuItemName ไปที่ RoomSlideBar
      body: Center(
        child: Text(menuItemName), // แสดงชื่อเมนูที่รับมา
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: RoomChat("KKK"))); // ค่าเริ่มต้น
