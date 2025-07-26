import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:siparis_app/constants.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = "Şifreler uyuşmuyor.";
      });
      return;
    }

    setState(() => _isLoading = true);

    final response = await http.post(
      Uri.parse(
        "${ApiConstants.resetPassword}/${widget.token}",
      ), // Emulatör için IP
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': _newPasswordController.text}),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      setState(() {
        _message = "Şifre başarıyla güncellendi.";
      });
    } else {
      setState(() {
        _message = "Şifre sıfırlama başarısız oldu.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yeni Şifre Belirle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Yeni şifrenizi girin", style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Yeni Şifre"),
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Şifre Tekrar"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: Text(
                  _isLoading ? "Gönderiliyor..." : "Şifreyi Güncelle",
                ),
              ),
              if (_message != null) ...[
                SizedBox(height: 20),
                Text(_message!, style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
