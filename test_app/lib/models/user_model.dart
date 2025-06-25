// lib/models/user_model.dart

// 建立 User 類別，來標準化「一位使用者」的資料結構。
class User {
  final int? id;
  final String account;
  final String password;
  final String height;
  final String weight;
  final String age;
  final String bmi;
  final String? fat; // 體脂率是選填，所以設為可選

  User({
    this.id,
    required this.account,
    required this.password,
    required this.height,
    required this.weight,
    required this.age,
    required this.bmi,
    this.fat,
  });

  // 將 User 物件轉換成 Map，方便寫入資料庫
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account': account,
      'password': password,
      'height': height,
      'weight': weight,
      'age': age,
      'bmi': bmi,
      'fat': fat,
    };
  }

  // 從 Map 建立 User 物件，方便從資料庫讀取
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      account: map['account'],
      password: map['password'],
      height: map['height'],
      weight: map['weight'],
      age: map['age'],
      bmi: map['bmi'],
      fat: map['fat'],
    );
  }

  // 建立一個 copyWith 方法，這在更新部分資料時非常方便
  User copyWith({
    int? id,
    String? account,
    String? password,
    String? height,
    String? weight,
    String? age,
    String? bmi,
    String? fat,
  }) {
    return User(
      id: id ?? this.id,
      account: account ?? this.account,
      password: password ?? this.password,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      bmi: bmi ?? this.bmi,
      fat: fat ?? this.fat,
    );
  }
}
