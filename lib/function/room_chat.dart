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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/RoomOne.jpeg'), // กำหนดรูปภาพพื้นหลัง
            fit: BoxFit.cover, // ปรับให้รูปภาพครอบคลุมพื้นที่ทั้งหมด
          ),
        ),
        child: Stack(
          children: [
            // ใช้ Positioned เพื่อขยับข้อความขึ้นไปข้างบน
            Positioned(
              top: 150, // ปรับตำแหน่งความสูงที่นี่
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  menuItemName,
                  style: TextStyle(
                    color: Colors.white, // กำหนดสีข้อความเป็นสีขาว
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    // เพิ่มเส้นขอบรอบตัวอักษร
                    shadows: [
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        blurRadius: 2.0,
                        color: Colors.black, // สีดำสำหรับเงา (เส้นขอบ)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: RoomChat("KKK"))); // ค่าเริ่มต้น
