import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token yok');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _emailController.text = data['email'] ?? '';
          _bioController.text = data['bio'] ?? '';
          // Eğer backend profile image url veriyorsa onu burada set etmelisin
          // Şimdilik sadece fotoğraf değişimi var, backend’den görüntüleme farklı yapılabilir
        });
      } else {
        throw Exception('Profil verisi alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil yüklenirken hata: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveUserProfile() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token yok');

      // Profile bilgilerini backend'e PUT isteği ile gönderiyoruz
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bio': _bioController.text.trim(),
          // Eğer email düzenlenebiliyorsa buraya ekle
          //'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // Fotoğraf varsa yükle
        if (_profileImage != null) {
          await _uploadProfileImage(token);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
      } else {
        throw Exception('Profil güncellenemedi: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil kaydedilirken hata: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadProfileImage(String token) async {
    final uri = Uri.parse(
      'http://10.0.2.2:3000/api/user/upload-profile-picture',
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('profile_image', _profileImage!.path),
    );
    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil fotoğrafı başarıyla yüklendi")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fotoğraf yükleme hatası: ${response.statusCode}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Profilim",
          style: TextStyle(
            color: Color(0xFFB34700),
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFB34700)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage("assets/images/avatar.jpg")
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              backgroundColor: theme.primaryColor,
                              radius: 16,
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Kişisel Bilgiler",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Email Adresim",
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'Montserrat'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Biyografim",
                        prefixIcon: Icon(Icons.info_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'Montserrat'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB34700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("Kaydet"),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
