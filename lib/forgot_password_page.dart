import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _emailSent = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) return;

    // TODO: Burada backend'e POST isteği atılmalı. Örnek:
    // await http.post('https://senin-backend.com/reset-password', body: {'email': email});

    setState(() {
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şifre Sıfırlama")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Kayıtlı e-posta adresinizi girin, size bir şifre sıfırlama bağlantısı gönderelim.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "E-posta"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sendResetEmail,
              child: const Text("Onayla"),
            ),
            const SizedBox(height: 16),
            if (_emailSent)
              const Text(
                "E-posta adresinize şifre sıfırlama bağlantısı gönderildi.",
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
