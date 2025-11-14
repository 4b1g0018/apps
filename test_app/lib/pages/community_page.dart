// lib/pages/community_page.dart

import 'package:flutter/material.dart';
import './create_post_page.dart'; // 【確認】導入我們剛建立的頁面

// 暫時的假資料模型
class MockPost {
  final String userName;
  final String title;
  final String content;
  final int likeCount;
  final int commentCount;

  MockPost({
    required this.userName,
    required this.title,
    required this.content,
    this.likeCount = 0,
    this.commentCount = 0,
  });
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  // 建立我們的假資料列表
  final List<MockPost> _mockPosts = [
    MockPost(
      userName: '健身小王子',
      title: '今天練胸日，PR 100kg 達成！',
      content: '努力了三個月，終於突破了個人紀錄，太開心了！繼續加油！#胸肌 #PR',
      likeCount: 42,
      commentCount: 8,
    ),
    MockPost(
      userName: '有氧女孩',
      title: '一週訓練課表分享',
      content: '分享我的一週三練課表：週一練腿、週三練背、週五全身循環。歡迎大家一起討論！',
      likeCount: 102,
      commentCount: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社群'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            onPressed: () {
              // TODO: 之後在這裡導向到「群組」頁面
            },
            tooltip: '我的群組',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _mockPosts.length,
        itemBuilder: (context, index) {
          final post = _mockPosts[index];
          return _buildPostCard(post);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '建立貼文',
      ),
    );
  }

  // 建立貼文卡片的 Helper 方法
  Widget _buildPostCard(MockPost post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 貼文頂部 (頭像 + 名稱)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.person, color: Colors.white70),
            ),
            title: Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          // 2. 貼文圖片 (本地佔位符)
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.image_outlined, color: Colors.white54, size: 60),
            ),
          ),
          
          // 3. 貼文標題和內容
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(post.content),
              ],
            ),
          ),
          const Divider(height: 1),
          // 4. 按讚和留言
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildActionButton(Icons.favorite_border, post.likeCount.toString()),
                const SizedBox(width: 24),
                _buildActionButton(Icons.comment_outlined, post.commentCount.toString()),
                const Spacer(),
                const Icon(Icons.bookmark_border, color: Colors.grey),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 建立按鈕的 Helper 方法
  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}