// lib/models/user_models.dart

class Visitor {
  int? id; // Veritabanı için otomatik artan ID
  String idOrPassport; // TCKN veya Pasaport
  String firstName;
  String lastName;
  String gender;
  int age;
  String phone;
  String email;
  String password;

  Visitor({
    this.id,
    required this.idOrPassport,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.phone,
    required this.email,
    required this.password,
  });

  // Veritabanına yazmak için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idOrPassport': idOrPassport,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'age': age,
      'phone': phone,
      'email': email,
      'password': password,
    };
  }

  // --- HATA DÜZELTMESİ: İŞTE DOĞRU fromMap FABRİKASI ---
  // Bu bir 'Future' DEĞİL, 'factory' olmalı.
  // Gelen 'map'in tipi Map<String, dynamic> olmalı.
  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      // Veritabanından gelen 'id' (int)
      id: map['id'] as int?,
      // Veritabanından gelen 'idOrPassport' (String)
      idOrPassport: map['idOrPassport'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      gender: map['gender'] as String,
      age: map['age'] as int,
      phone: map['phone'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
  // --- DÜZELTME BİTTİ ---
}

class Employee {
  int? id;
  String employeeId;
  String firstName;
  String lastName;
  String phone;
  String shopName;
  String taxId;
  String address;
  String email;
  String password;

  Employee({
    this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.shopName,
    required this.taxId,
    required this.address,
    required this.email,
    required this.password,
  });

  // Veritabanına yazmak için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'shopName': shopName,
      'taxId': taxId,
      'address': address,
      'email': email,
      'password': password,
    };
  }

  // Veritabanından okumak için (Login'de kullanılacak)
  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      phone: map['phone'] as String,
      shopName: map['shopName'] as String,
      taxId: map['taxId'] as String,
      address: map['address'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}
