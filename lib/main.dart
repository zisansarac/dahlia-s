import 'package:flutter/material.dart';
import 'package:siparis_app/login_page.dart';
import 'package:siparis_app/profil_page.dart';
import 'package:siparis_app/register_page.dart';
import 'package:siparis_app/theme.dart';
import 'order_list.dart';
// import 'login_page.dart';
import 'splash_screen_1.dart';
import 'reset_password_page.dart';
//import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sipariş Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // ← Temayı buradan çağırıyoruz
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/orders': (context) => OrderListPage(),
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => ProfilePage(),
        '/reset-password-test': (context) => const ResetPasswordPage(
          token:
              '1eaf7d8e640a902ad7b6d023ccf4d46c2daf2679eae7f0bca582dd3a917cf852',
        ),
      },
    );
  }
}
