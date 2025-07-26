import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> uploadProfileImage(File imageFile) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final uri = Uri.parse('http://10.0.2.2:3000/api/user/upload-profile-picture');
  final request = http.MultipartRequest('POST', uri);

  request.headers['Authorization'] = 'Bearer $token';

  request.files.add(
    await http.MultipartFile.fromPath(
      'profile_image',
      imageFile.path,
      filename: basename(imageFile.path),
    ),
  );

  final response = await request.send();

  if (response.statusCode == 200) {
    print('✅ Profil fotoğrafı başarıyla yüklendi');
  } else {
    print('❌ Yükleme hatası: ${response.statusCode}');
  }
}
