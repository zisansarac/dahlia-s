import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('username', _usernameController.text);
        await prefs.setBool(
          'is_female_entrepreneur',
          data['is_female_entrepreneur'] ?? false,
        );

        await prefs.setInt('user_id', data['user_id']);

        Navigator.pushReplacementNamed(context, '/orders');
      } else {
        final data = json.decode(response.body);
        setState(() {
          errorMessage = data['error'] ?? 'Bilinmeyen hata';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Giriş sırasında hata oluştu: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final googleAuth = await user.authentication;
      final idToken = googleAuth.idToken;

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('username', data['username'] ?? '');

        Navigator.pushReplacementNamed(context, '/orders');
      } else {
        final data = json.decode(response.body);
        setState(() {
          errorMessage = data['error'] ?? 'Google ile giriş başarısız';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Google girişinde hata: $error';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Mevcut importlar ve sınıf yapısı korunuyor...
  bool _obscurePassword = true;

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscure = false,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Montserrat',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB34700)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hoş geldin!",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            color: Color(0xFFB34700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Hesabına giriş yaparak siparişlerini yönet.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 32),

                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Şifreni mi unuttun?",
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Color.fromARGB(255, 71, 54, 28),
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB34700),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Giriş Yap",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(child: Text("veya şu hesapla devam et")),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: _handleGoogleSignIn,
                            child: Image.asset(
                              "assets/images/google_logo.png",
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Hesabın yok mu? ",
                              style: TextStyle(
                                color: Colors.black87,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/register',
                                );
                              },
                              child: const Text(
                                "Kayıt Ol",
                                style: TextStyle(
                                  color: Color(0xFFB34700),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
