// lib/utils/database_helper.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_models.dart';

class DatabaseHelper {
  static const _databaseName = "StashAppV2.db";
  static const _databaseVersion = 1;

  // Tablo adları
  static const tableVisitors = 'visitors';
  static const tableEmployees = 'employees';

  // Sütun adları (Ortak)
  static const columnId = 'id';
  static const columnFirstName = 'firstName';
  static const columnLastName = 'lastName';
  static const columnPhone = 'phone';
  static const columnEmail = 'email';
  static const columnPassword = 'password';

  // Sütun adları (Ziyaretçi)
  static const columnIdOrPassport = 'idOrPassport';
  static const columnGender = 'gender';
  static const columnAge = 'age';

  // Sütun adları (Çalışan)
  static const columnEmployeeId = 'employeeId';
  static const columnShopName = 'shopName';
  static const columnTaxId = 'taxId';
  static const columnAddress = 'address';

  // Sınıfı 'singleton' yapıyoruz
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Veritabanını açar (yoksa oluşturur)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL ile tabloları oluştur
  Future _onCreate(Database db, int version) async {
    // Ziyaretçi Tablosu
    await db.execute('''
          CREATE TABLE $tableVisitors (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnIdOrPassport TEXT NOT NULL,
            $columnFirstName TEXT NOT NULL,
            $columnLastName TEXT NOT NULL,
            $columnGender TEXT NOT NULL,
            $columnAge INTEGER NOT NULL,
            $columnPhone TEXT NOT NULL,
            $columnEmail TEXT NOT NULL UNIQUE,
            $columnPassword TEXT NOT NULL
          )
          ''');

    // Çalışan Tablosu
    await db.execute('''
          CREATE TABLE $tableEmployees (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnEmployeeId TEXT NOT NULL,
            $columnFirstName TEXT NOT NULL,
            $columnLastName TEXT NOT NULL,
            $columnPhone TEXT NOT NULL,
            $columnShopName TEXT NOT NULL,
            $columnTaxId TEXT NOT NULL,
            $columnAddress TEXT NOT NULL,
            $columnEmail TEXT NOT NULL UNIQUE,
            $columnPassword TEXT NOT NULL
          )
          ''');
  }

  // --- CRUD İşlemleri ---

  // YENİ ZİYARETÇİ EKLE
  Future<int> insertVisitor(Visitor visitor) async {
    Database db = await instance.database;
    return await db.insert(tableVisitors, visitor.toMap());
  }

  // YENİ ÇALIŞAN EKLE
  Future<int> insertEmployee(Employee employee) async {
    Database db = await instance.database;
    return await db.insert(tableEmployees, employee.toMap());
  }

  // ZİYARETÇİ GİRİŞİ
  Future<Visitor?> getVisitorLogin(String email, String password) async {
    Database db = await instance.database;
    var res = await db.query(tableVisitors,
        where: "$columnEmail = ? AND $columnPassword = ?",
        whereArgs: [email, password]);

    if (res.isNotEmpty) {
      // Modeli fromMap ile oluşturmak daha temiz olurdu ama şimdilik Map döndürüyoruz
      // Basitlik için ilk kaydı Visitor modeline dönüştürüp döndürebiliriz
      // (Modelinize 'factory Visitor.fromMap' eklerseniz daha iyi olur)
      return Visitor.fromMap(res.first);
    }
    return null;
  }

  // ÇALIŞAN GİRİŞİ
  Future<Employee?> getEmployeeLogin(String email, String password) async {
    Database db = await instance.database;
    var res = await db.query(tableEmployees,
        where: "$columnEmail = ? AND $columnPassword = ?",
        whereArgs: [email, password]);

    if (res.isNotEmpty) {
      return Employee.fromMap(res.first);
    }
    return null;
  }
}

// NOT: Visitor modeline de Employee'deki gibi 'fromMap' factory'si eklerseniz
// getVisitorLogin fonksiyonu da Employee.fromMap(res.first) gibi temiz çalışır.
// Lütfen 'user_models.dart' dosyasına gidip Visitor sınıfına şunu ekleyin:

/*
  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'],
      idOrPassport: map['idOrPassport'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      gender: map['gender'],
      age: map['age'],
      phone: map['phone'],
      email: map['email'],
      password: map['password'],
    );
  }
*/
