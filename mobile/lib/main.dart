import 'package:flutter/material.dart';
import 'package:mobile/core/config/app_theme.dart';
import 'package:mobile/ui/pages/home_page.dart';
import 'package:mobile/ui/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? userPhone = prefs.getString('user_phone');
  
  runApp(UbuntuXApp(initialPage: userPhone != null ? const HomePage() : const LoginPage()));
}

class UbuntuXApp extends StatelessWidget {
  final Widget initialPage;
  
  const UbuntuXApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UbuntuX',
      debugShowCheckedModeBanner: false,
      theme: UbuntuXTheme.darkTheme,
      home: initialPage,
    );
  }
}
