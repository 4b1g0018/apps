// lib/pages/community_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import './create_post_page.dart';
import './community_profile_page.dart';

class CommunityPage extends StatefulWidget {
  final String account;
  const CommunityPage({super.key, required this.account});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社群'),
        backgroundColor: Colors.black,
        leading: null, 
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityProfilePage(account: widget.account)));
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('第 47 週', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(5, (index) => _buildDateCard('11月 ${17 + index}', '週${index + 1}')),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.instance.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('發生錯誤'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('目前還沒有貼文，快來搶頭香！'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildPostCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateCard(String date, String day) {
    final bool isSelected = date.endsWith('17');
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: 80, height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade800 : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(date, style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
            Text(day, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data) {
    final userName = data['authorName'] ?? '未知使用者';
    final title = data['title'] ?? '無標題';
    final content = data['content'] ?? '';
    final imageBase64 = data['imageUrl'] as String?; 

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey.shade800, child: const Icon(Icons.person, color: Colors.white70)),
            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          if (imageBase64 != null && imageBase64.isNotEmpty)
            Image.memory(
              base64Decode(imageBase64), 
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(height: 250, color: Colors.grey[900], child: const Center(child: Icon(Icons.error))),
            )
          else
            // 【修正】這裡就是您之前警告的地方，已加入 const
            Container(
              width: double.infinity, 
              height: 250, 
              color: Colors.grey[900],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, color: Colors.white24, size: 60),
                  SizedBox(height: 8),
                  Text('無圖片', style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(content),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('0', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 24),
                const Icon(Icons.comment_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('0', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.bookmark_border, color: Colors.grey),
              ],
            ),
          )
        ],
      ),
    );
  }
}