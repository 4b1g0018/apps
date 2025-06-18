// Flutter 健身教練 App 主程式（含 SQLite 註冊功能）
// ✅ 使用 sqflite 實作帳號密碼註冊與登入，並儲存身高、體重、自動計算 BMI
// ✅ 體脂率為選填欄位

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join; // 只匯入 join，避免引入 Context

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDB();
  runApp(const MyApp());
}

// 應用程式進入點
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: '健身', home: const LoginPage());
  }
}

// 🔐 登入與註冊頁面
class LoginPage extends StatefulWidget {
  //loginpage是個widget
  const LoginPage({super.key}); //statefulwidget 這個畫面有狀態會改變 登入註冊輸入的文字...
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //建立控制畫面的物件
  final _formKey = GlobalKey<FormState>(); //管理整個表單 檢查有沒有欄位沒有填入
  final TextEditingController _account = TextEditingController(); //存取輸入的值
  final TextEditingController _password = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _fat = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();

  bool isLogin = true; // true = 登入false = 正在註冊

  // 切換登入與註冊模式 //註冊時會呼叫toggleMode 顯示出註冊頁面
  void _toggleMode() => setState(() => isLogin = !isLogin); //依照當前是登入或註冊切換畫面 setState....狀態改變了重新載入畫面 

  // 提交登入或註冊資料
  void _handleSubmit() async {                     //檢查表單有沒有通過驗證
    if (!_formKey.currentState!.validate()) return; // !vaidate 沒通過後面沒法return

    final acc = _account.text.trim();               //提取輸入的帳號密碼 trim用來去除空白字元
    final pwd = _password.text.trim();

    if (isLogin) {                                                        
      final valid = await DatabaseHelper.instance.validateUser(acc, pwd); //使用datebasehelper中validateuser 進資料庫驗證帳號密碼
      if (!mounted) return; //確保畫面存在

      if (valid) {                                                 
        Navigator.pushReplacement(                                  //pushReplacement 移除當前畫面 無法回到登入畫面
          context,
          MaterialPageRoute(builder: (_) => const MainMenuPage()), //登入成功導向主畫面MainＭenuPage
        );

      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('帳號或密碼錯誤'))); //失敗顯示訊息
      }

    } else {
      final h = double.tryParse(_height.text);        
      final w = double.tryParse(_weight.text);            //將輸入值轉為數字
      final bmi = (h != null && w != null && h > 0)       //轉換使用者輸入的值 計算成bmi 若失敗為空
          ? (w / ((h / 100) * (h / 100))).toStringAsFixed(2)
          : '';

      if (bmi == '') {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('BMI 計算失敗，請輸入正確的身高與體重')),
      );
      return;
      }

      await DatabaseHelper.instance.insertUser({      //建立資料庫 （註冊資料）透過databasehelper寫入SQLite
        'account': acc,
        'password': pwd,
        'height': _height.text,
        'weight': _weight.text,
        'age': _age.text,
        'bmi': bmi,
        'fat': _fat.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('註冊成功，請登入')));  //註冊成功顯示
      setState(() => isLogin = true);                                   //自動切換為登入畫面  
    }
  }

  // 計算 BMI 
  void _updateBMI() {
  final h = double.tryParse(_height.text);            //double.tryParse 將輸入轉為數字
  final w = double.tryParse(_weight.text);
  if (h != null && w != null && h > 0) {
    final bmi = w / ((h / 100) * (h / 100));
    _bmiController.text = bmi.toStringAsFixed(2);   //輸入體重身高觸發計算
  } else {
    _bmiController.text = '';
  }
}


  // 登入/註冊 UI 表單
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? '登入' : '註冊')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(                                              //TextFormField(
                controller: _account,                                     //controller: _height _height讀取值
                decoration: const InputDecoration(labelText: '帳號'),
                validator: (v) => v!.isEmpty ? '請輸入帳號' : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: '密碼'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? '請輸入密碼' : null,
              ),
              if (!isLogin) ...[
                TextFormField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '身高 (cm)'),
                  validator: (v) => v!.isEmpty ? '請輸入身高' : null,
                  onChanged: (_) => _updateBMI(),
                ),
                TextFormField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '體重 (kg)'),
                  validator: (v) => v!.isEmpty ? '請輸入體重' : null,
                  onChanged: (_) => _updateBMI(),
                ),
                TextFormField(
                  readOnly: true,         //唯讀
                   controller: _bmiController,
                    decoration: const InputDecoration(labelText: 'BMI(自動計算)'),
                ),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '年齡'),
                  validator: (v) => v!.isEmpty ? '請輸入年齡' : null,
                ),
                TextFormField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '體脂率（選填）'),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSubmit,
                child: Text(isLogin ? '登入' : '註冊'),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: Text(isLogin ? '還沒有帳號？註冊' : '已有帳號？登入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ 登入成功後的主選單頁面
class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主選單')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('開始訓練')),
            ElevatedButton(onPressed: () {}, child: const Text('訓練紀錄')),
            ElevatedButton(onPressed: () {}, child: const Text('個人資料更改')),
            ElevatedButton(onPressed: () {}, child: const Text('詳細設定')),
          ],
        ),
      ),
    );
  }
}

// ✅ SQLite 輔助類別，處理初始化與基本 CRUD
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get db async => _db ??= await initDB();

  // 初始化資料庫
  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account TEXT UNIQUE,
            password TEXT,
            height TEXT,
            weight TEXT,
            age TEXT,
            bmi TEXT,
            fat TEXT
          )
        ''');
        // 預設建立一位 admin 帳號方便測試 demo
        await db.insert('users', {
          'account': 'admin',
          'password': 'admin123',
          'height': '170',
          'weight': '60',
          'age': '30',
          'bmi': '20.76',
          'fat': '15',
        });
      },
    );
  }

  // 註冊用戶資料
  Future<void> insertUser(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('users', data);
  }

  // 驗證帳號密碼是否正確（登入用）
  Future<bool> validateUser(String account, String password) async {
    final database = await db;
    final result = await database.query(
      'users',
      where: 'account = ? AND password = ?',
      whereArgs: [account, password],
    );
    return result.isNotEmpty;
  }
}
