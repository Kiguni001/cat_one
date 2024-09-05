import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sumhua_project/firebase_options.dart';
import 'dart:io';
import 'slide_menu.dart'; // Ensure this file is correctly located in your project
import 'screens/login_page.dart';
import 'screens/main_page.dart'; // Ensure this file is correctly located in your project

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
        '/main': (context) => MainPage(), // Ensure MainPage is imported correctly
      },
    );
  }
}
