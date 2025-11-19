// lib/pages/community_page.dart

import 'package:flutter/material.dart';
import './create_post_page.dart';
import './community_profile_page.dart';

// 暫時的假資料模型
class MockPost {
  final String userName;
  final String title;
  final String content;
  final int likeCount;
  final int commentCount;

  const MockPost({
    required this.userName,
    required this.title,
    required this.content,
    this.likeCount = 0,
    this.commentCount = 0,
  });
}

class CommunityPage extends StatefulWidget {
  final String account;
  const CommunityPage({super.key, required this.account});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  // 將假資料設為 const
  final List<MockPost> _mockPosts = const [
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
        backgroundColor: Colors.black, // 確保 AppBar 頂部也是黑色
        
      
        actions: [
          
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityProfilePage(account: widget.account),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. 置頂 Header 區塊 (不會滾動) ---
          Container(
            color: Colors.black, // 匹配 Retro 風格的黑色背景
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '第 47 週', // 靜態週數
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // 橫向滾動的日期卡片
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAddPostCard(context), // 【新增】第一個項目是 '+' 號卡片
                      const SizedBox(width: 8),
                      ...List.generate(5, (index) => _buildDateCard('11月 ${17 + index}', '週${index + 1}')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- 2. 可滾動的 Feed 區塊 ---
          Expanded( // 讓 ListView 佔據所有剩餘空間
            child: ListView.builder(
              itemCount: _mockPosts.length,
              itemBuilder: (context, index) {
                final post = _mockPosts[index];
                return _buildPostCard(post);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 【新增】建立新增貼文的卡片
  Widget _buildAddPostCard(BuildContext context) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary, // 藍色背景
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage()));
        },
        borderRadius: BorderRadius.circular(10),
        child: const Center(
          child: Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
    );
  }

  // Helper 方法：建立橫向滾動的日期卡片
  Widget _buildDateCard(String date, String day) {
    // 這裡只是模擬方塊的樣式
    final bool isSelected = date.endsWith('17'); // 模擬選中 11/17
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: 80,
        height: 60,
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