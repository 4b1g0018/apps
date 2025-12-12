
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart'; // 【新增】

class PostDetailPage extends StatelessWidget {
  final Map<String, dynamic> postData;

  const PostDetailPage({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    final String title = postData['title'] ?? '無標題';
    final String content = postData['content'] ?? '';
    final String authorName = postData['authorName'] ?? '未知作者';
    final String? imageBase64 = postData['imageUrl'];
    final Timestamp? timestamp = postData['timestamp'];
    
    String dateStr = '';
    if (timestamp != null) {
      dateStr = DateFormat('yyyy/MM/dd HH:mm').format(timestamp.toDate());
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark mode background
      appBar: AppBar(
        title: const Text('貼文詳情'),
        backgroundColor: Colors.black,
        actions: [
          if (FirestoreService.instance.getCurrentUserUid() == postData['authorId'])
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    titlePadding: EdgeInsets.zero,
                    contentPadding: EdgeInsets.zero,
                    actionsPadding: EdgeInsets.zero,
                    backgroundColor: const Color(0xFF2C2C2E), // Match SettingsPage dialog color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                    content: SizedBox(
                      width: 270,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text('確認刪除', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
                            child: Text('確定要刪除這篇貼文嗎？\n此動作無法復原。', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                          ),
                          Divider(height: 1, color: Colors.grey.shade700),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: TextButton(
                              child: Text('刪除', style: TextStyle(color: Colors.red.shade400, fontSize: 17, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                Navigator.pop(ctx); 
                                if (postData['postId'] != null) {
                                  try {
                                    await FirestoreService.instance.deletePost(postData['postId']);
                                    if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('貼文刪除成功'), backgroundColor: Colors.green)
                                       );
                                       Navigator.pop(context); // Close Detail Page
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('刪除失敗: $e'), backgroundColor: Colors.red)
                                       );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade700),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: TextButton(
                              child: const Text('取消', style: TextStyle(fontSize: 17, color: Colors.blueAccent)), // Use Blue for Cancel/Safe
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FutureBuilder<String?>(
                    future: FirestoreService.instance.getUserAvatar(postData['authorId']),
                    builder: (context, snapshot) {
                      final avatarBase64 = snapshot.data;
                      return CircleAvatar(
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: (avatarBase64 != null && avatarBase64.isNotEmpty)
                            ? MemoryImage(base64Decode(avatarBase64))
                            : null,
                        child: (avatarBase64 == null || avatarBase64.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white70)
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Image
            if (imageBase64 != null && imageBase64.isNotEmpty)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Image.memory(
                  base64Decode(imageBase64),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
