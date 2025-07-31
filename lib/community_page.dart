import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> posts = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<void> fetchPosts() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/community'),
    );

    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body);
      });
    } else {
      print('Mesajlar alınamadı: ${response.statusCode}');
    }
  }

  Future<void> postMessage() async {
    final userId = await getUserId();
    final city = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString('city') ?? '',
    );
    final message = _messageController.text.trim();

    print('🟠 DEBUG | userId: $userId, city: $city, message: "$message"');

    if (message.isEmpty || userId == null) {
      print('🔴 Mesaj boş veya userId null!');
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/community'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'message': message, 'city': city}),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      fetchPosts(); // listeyi yenile
    } else {
      print('🔴 Mesaj gönderilemedi: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text("Topluluk"),
        backgroundColor: const Color(0xFFB34700),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final post = posts[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['username'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(post['message'] ?? ''),
                      if (post['city'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          post['city'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // ↘️ Mesaj gönderme kutusu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Bir şeyler yaz...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFB34700)),
                  onPressed: () {
                    print("📤 GÖNDER butonuna basıldı!");
                    postMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
