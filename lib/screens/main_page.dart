import 'package:flutter/material.dart';
import '../slide_menu.dart'; // Update the path as needed
import '../profile_setting.dart'; // นำเข้าไฟล์ profile_setting.dart

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sumhua Menu Page'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // ฟังก์ชันเปิด Drawer
              },
            );
          },
        ),
        backgroundColor:
            const Color.fromARGB(255, 132, 132, 132), // สีส้มเข้มสำหรับ AppBar
      ),
      drawer: SlideMenu(), // Ensure SlideMenu is imported correctly
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/MenuPage.jpeg'), // ใส่รูปพื้นหลังที่นี่
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200, // ขนาดความกว้างของปุ่ม
                child: ElevatedButton(
                  onPressed: () {
                    // นำทางไปยังหน้า ProfileSettingPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileSettingPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        120, 33, 149, 243), // Background color of the button
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Text(
                        'Profile',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30), // Spacing between buttons
              SizedBox(
                width: 200, // ขนาดความกว้างของปุ่ม
                child: ElevatedButton(
                  onPressed: () {
                    // Add action for "Friend Chat" button
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        123, 76, 175, 79), // Background color of the button
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Text(
                        'Friend Chat',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
