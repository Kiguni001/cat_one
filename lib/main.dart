import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sumhua_project/firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';
import 'screens/signup_page.dart';  // นำเข้าไฟล์ signup_page.dart
import 'screens/user_stream.dart';   // นำเข้าไฟล์ user_stream.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/main': (context) => MainPage(),
        '/signup': (context) => SignupPage(), // เพิ่ม Routing สำหรับหน้าลงทะเบียน
        '/user_stream': (context) => UserStreamPage(), // เพิ่ม Routing สำหรับหน้าสร้าง Stream user
      },
    );
  }
}
