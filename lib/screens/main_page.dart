import 'package:flutter/material.dart';
import '../slide_menu.dart'; // Update the path as needed
import '../profile_setting.dart'; // นำเข้าไฟล์ profile_setting.dart
import '../function/user_list_screen.dart'; // นำเข้า user_list_screen.dart ที่เก็บไว้ใน lib/function

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการเมนู'),
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
        color: Colors.white, // เปลี่ยนพื้นหลังเป็นสีขาว
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ปุ่มห้องเรียนอยู่ด้านบนสุด
              SizedBox(
                width: 200, // ขนาดความกว้างของปุ่ม
                child: ElevatedButton(
                  onPressed: () {
                    // นำทางไปยังหน้า SlideMenu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SlideMenu()), // เปลี่ยนไปที่ SlideMenu
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // สีพื้นหลังของปุ่มเป็นสีขาว
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 10, // เพิ่มเงาให้กับปุ่ม
                    shadowColor: Colors.black.withOpacity(0.5), // กำหนดสีเงา
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.class_, color: Colors.grey, size: 50), // สีไอคอนเป็นสีเทา
                      SizedBox(height: 10),
                      Text(
                        'ห้องเรียน',
                        style: TextStyle(color: Colors.grey, fontSize: 18), // สีข้อความเป็นสีเทา
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
                    // นำทางไปยังหน้า user_list_screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // สีพื้นหลังของปุ่มเป็นสีขาว
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 10, // เพิ่มเงาให้กับปุ่ม
                    shadowColor: Colors.black.withOpacity(0.5), // กำหนดสีเงา
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, color: Colors.grey, size: 50), // สีไอคอนเป็นสีเทา
                      SizedBox(height: 10),
                      Text(
                        'คุยส่วนตัว',
                        style: TextStyle(color: Colors.grey, fontSize: 18), // สีข้อความเป็นสีเทา
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
                    // นำทางไปยังหน้า ProfileSettingPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileSettingPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // สีพื้นหลังของปุ่มเป็นสีขาว
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 10, // เพิ่มเงาให้กับปุ่ม
                    shadowColor: Colors.black.withOpacity(0.5), // กำหนดสีเงา
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: Colors.grey, size: 50), // สีไอคอนเป็นสีเทา
                      SizedBox(height: 10),
                      Text(
                        'โปรไฟล์',
                        style: TextStyle(color: Colors.grey, fontSize: 18), // สีข้อความเป็นสีเทา
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
