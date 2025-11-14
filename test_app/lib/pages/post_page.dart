// lib/pages/post_page.dart

import 'package:flutter/material.dart'; // 【修正】這裡的 : 很重要

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('建立貼文'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
          
              Navigator.of(context).pop();
            },
            tooltip: '發布',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 預留上傳圖片/影片的區塊
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: Colors.white54, size: 50),
                  SizedBox(height: 8),
                  Text('上傳圖片/影片 (待開發)', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 標題輸入框
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '標題',
              hintText: '分享您的訓練成果...',
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 內容輸入框
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '內容',
              hintText: '分享更多細節...',
              border: OutlineInputBorder(),
            ),
            maxLines: 8,
          ),
        ],
      ),
    );
  }
}