// lib/pages/device_connection_page.dart

import 'package:flutter/material.dart';
// 我們不再需要引入 flutter_blue_plus，因為所有的互動都透過我們自己的 service
// import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
import '../services/bluetooth_service.dart';

class DeviceConnectionPage extends StatefulWidget {
  const DeviceConnectionPage({super.key});

  @override
  State<DeviceConnectionPage> createState() => _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends State<DeviceConnectionPage> {
  // 建立一個我們自己的 BluetoothService 的實例
  final BluetoothService _bluetoothService = BluetoothService();
  
  @override
  void dispose() {
    // 在頁面銷毀時，呼叫 service 的 dispose 方法來釋放資源
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('連接裝置'),
      ),
      body: Column(
        children: [
          // --- 掃描狀態與按鈕 ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            // 我們用 StreamBuilder 來監聽「是否正在掃描」的狀態
            child: StreamBuilder<bool>(
              stream: _bluetoothService.isScanning,
              initialData: false, // 初始狀態為「未掃描」
              builder: (context, snapshot) {
                final isScanning = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isScanning ? '正在掃描...' : '附近的裝置',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // 如果正在掃描，就顯示一個轉圈圈的進度條
                    if (isScanning)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    // 如果沒有在掃描，就顯示一個「重新掃描」的按鈕
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _bluetoothService.startScan(),
                      ),
                  ],
                );
              },
            ),
          ),

          // --- 掃描結果列表 ---
          Expanded(
            // 【修改】我們將 StreamBuilder 的泛型，從 ScanResult 改為我們自訂的 MockBluetoothDevice
            child: StreamBuilder<List<MockBluetoothDevice>>(
              stream: _bluetoothService.scanResults,
              initialData: const [], // 初始為一個空列表
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data!.isEmpty) {
                  return const Center(child: Text('點擊右下角按鈕開始掃描'));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('發生錯誤: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('找不到任何裝置'));
                }

                final results = snapshot.data!;
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.bluetooth, size: 32),
                        title: Text(result.platformName),
                        subtitle: Text(result.remoteId),
                        trailing: ElevatedButton(
                          child: const Text('連接'),
                          onPressed: () {
                            _bluetoothService.stopScan();
                            _bluetoothService.connectToDevice(result);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- 懸浮按鈕，用來開始掃描 ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bluetoothService.startScan(),
        child: const Icon(Icons.search),
      ),
    );
  }
}
