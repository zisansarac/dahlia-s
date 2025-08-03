import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:siparis_app/theme.dart'; // AppTheme import

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _messageController = TextEditingController();
  Map<int, TextEditingController> _commentControllers = {};
  List<dynamic> posts = [];
  Map<int, List<dynamic>> commentsMap = {};
  Map<int, bool> isCommentsVisible = {};
  Set<int> postingCommentIds = {};
  int? currentUserId;
  bool isPostingMessage = false;

  @override
  void initState() {
    super.initState();
    loadUserAndPosts();
  }

  void showSnackBar(String message, {Color bgColor = AppTheme.primaryColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> loadUserAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');
    await fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/community?user_id=$currentUserId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body);
        commentsMap.clear();
      });
    }
  }

  Future<void> fetchComments(int postId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/community/$postId/comments'),
    );
    if (response.statusCode == 200) {
      setState(() {
        commentsMap[postId] = json.decode(response.body);
      });
    }
  }

  Future<void> postMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || currentUserId == null) return;

    setState(() => isPostingMessage = true);

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/community'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': currentUserId, 'message': message}),
    );

    setState(() => isPostingMessage = false);

    if (response.statusCode == 201) {
      _messageController.clear();
      await fetchPosts();
      showSnackBar('Mesaj gönderildi ✅');
    } else {
      showSnackBar('Mesaj gönderilemedi ❌', bgColor: Colors.red);
    }
  }

  Future<void> toggleLike(int postId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/community/$postId/like'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': currentUserId}),
    );

    if (response.statusCode == 200) {
      final liked = json.decode(response.body)['liked'];
      setState(() {
        final index = posts.indexWhere((p) => p['id'] == postId);
        if (index != -1) {
          posts[index]['isLiked'] = liked ? 1 : 0;
          posts[index]['likes'] =
              (posts[index]['likes'] ?? 0) + (liked ? 1 : -1);
        }
      });
    }
  }

  Future<void> editPost(int postId, String oldMessage) async {
    final controller = TextEditingController(text: oldMessage);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Mesajı Düzenle',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(hintText: 'Yeni mesaj'),
        ),
        actions: [
          TextButton(
            child: Text('İptal', style: Theme.of(context).textTheme.bodyMedium),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Kaydet'),
            onPressed: () async {
              final newMessage = controller.text.trim();
              if (newMessage.isNotEmpty) {
                await http.put(
                  Uri.parse('http://10.0.2.2:3000/api/community/$postId'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'user_id': currentUserId,
                    'message': newMessage,
                  }),
                );
                Navigator.pop(context);
                await fetchPosts();
                showSnackBar('Mesaj güncellendi ✅');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> deletePost(int postId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:3000/api/community/$postId/$currentUserId'),
    );
    if (response.statusCode == 200) {
      await fetchPosts();
      showSnackBar('Mesaj silindi 🗑️');
    }
  }

  Future<void> postComment(int postId) async {
    final comment = _commentControllers[postId]?.text.trim();
    if (comment == null || comment.isEmpty) return;

    setState(() => postingCommentIds.add(postId));

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/community/$postId/comment'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': currentUserId, 'comment': comment}),
    );

    if (response.statusCode == 201) {
      _commentControllers[postId]?.clear();
      await fetchComments(postId);
      showSnackBar('Yorum eklendi 💬');
    }

    setState(() => postingCommentIds.remove(postId));
  }

  Future<void> deleteComment(int commentId, int postId) async {
    await http.delete(
      Uri.parse(
        'http://10.0.2.2:3000/api/community/comment/$commentId/$currentUserId',
      ),
    );
    await fetchComments(postId);
    showSnackBar('Yorum silindi 🗑️');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Topluluk",
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
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
                final postId = post['id'];
                _commentControllers.putIfAbsent(
                  postId,
                  () => TextEditingController(),
                );

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
                      // Kullanıcı adı + düzenle/sil
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            post['username'] ?? '',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (post['user_id'] == currentUserId)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () =>
                                      editPost(postId, post['message']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => deletePost(postId),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(post['message'] ?? '', style: textTheme.bodyMedium),
                      const SizedBox(height: 12),

                      // Beğeni ve Yorumlar butonu
                      Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: IconButton(
                              key: ValueKey(post['isLiked']),
                              icon: Icon(
                                post['isLiked'] == 1
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post['isLiked'] == 1
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              onPressed: () => toggleLike(postId),
                            ),
                          ),
                          Text(
                            '${post['likes'] ?? 0}',
                            style: textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              if (isCommentsVisible[postId] == true) {
                                setState(
                                  () => isCommentsVisible[postId] = false,
                                );
                              } else {
                                await fetchComments(postId);
                                setState(
                                  () => isCommentsVisible[postId] = true,
                                );
                              }
                            },
                            child: Text(
                              isCommentsVisible[postId] == true
                                  ? 'Yorumları Gizle'
                                  : 'Yorumlar',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Yorumlar
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child:
                            (commentsMap[postId] != null &&
                                (isCommentsVisible[postId] ?? false))
                            ? Column(
                                children: [
                                  const Divider(),
                                  ...commentsMap[postId]!.map((comment) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.comment, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  style: textTheme.bodyMedium,
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${comment['username']}: ',
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    TextSpan(
                                                      text: comment['comment'],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (comment['user_id'] ==
                                                  currentUserId)
                                                Row(
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => editPost(
                                                        comment['id'],
                                                        comment['comment'],
                                                      ),
                                                      child: const Text(
                                                        "Düzenle",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          deleteComment(
                                                            comment['id'],
                                                            postId,
                                                          ),
                                                      child: const Text("Sil"),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _commentControllers[postId],
                                          style: textTheme.bodyMedium,
                                          decoration: const InputDecoration(
                                            hintText: 'Yorum yaz...',
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: postingCommentIds.contains(postId)
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.send),
                                        onPressed:
                                            postingCommentIds.contains(postId)
                                            ? null
                                            : () => postComment(postId),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Mesaj yazma kutusu
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
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Bir şeyler yaz...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppTheme.primaryColor),
                  onPressed: postMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
