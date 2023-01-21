import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
//import 'package:path_provider/path_provider.dart';
import 'dart:async';

const String date = 'date';
const String disease = 'disease';
const String treatmentThree = 'treatmentThree';
const String treatmentTwo = 'treatmentTwo';
const String treatmentOne = 'treatmentOne';
const String confidence = 'confidence';
const String image = 'image';
const String id = 'id';
const String _predictionTable = 'Predictions';

class PredictionTabledata {
  late String date;
  late String disease;
  late String treatmentThree;
  late String treatmentTwo;
  late String treatmentOne;
  late int confidence;
  late String image;
  String? id;
  PredictionTabledata(
      {this.id,
      required this.date,
      required this.disease,
      required this.confidence,
      required this.treatmentOne,
      required this.treatmentTwo,
      required this.treatmentThree,
      required this.image});
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'disease': disease,
      'confidence': confidence,
      'treatmentOne': treatmentOne,
      'treatmentThree': treatmentThree,
      'treatmentTwo': treatmentTwo,
      'date': date,
      'image': image
    };
    return map;
  }

  PredictionTabledata.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    date = map['date'];
    disease = map['disease'];
    confidence = map['confidence'];
    treatmentOne = map['treatmentOne'];
    treatmentTwo = map['treatmentTwo'];
    treatmentThree = map['treatmentThree'];
    image = map['image'];
  }
}

class databaseHelper {
  static Database? _db;
  static const _dbName = 'database.db';
  static const _dbVersion = 1;
  static const _predictionTable = 'Predictions';

  //making it a singleton class
  databaseHelper._privateConstructor();

  static final databaseHelper instance = databaseHelper._privateConstructor();

  Future<Database?> get database async {
    if (_db != null) return _db;
    _db = await _initiateDatabase();
    return _db;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute("""
            CREATE TABLE $_predictionTable (
              $id INTEGER PRIMARY KEY,
              $disease TEXT NOT NULL,
              $confidence INTEGER NOT NULL,
              $treatmentOne TEXT NOT NULL,
              $treatmentTwo TEXT NOT NULL,
              $treatmentThree TEXT NOT NULL,
              $date TEXT NOT NULL,
              $image TEXT NOT NULL
            )""");
  }

  Future _initiateDatabase() async {
    Directory path = await Directory('');
    String dbpath = join(path.path, _dbName);
    return await openDatabase(dbpath, version: _dbVersion, onCreate: _onCreate);
  }

  Future<int> insertPrediction(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(_predictionTable, row);
  }

  Future<List<Map<String, dynamic>>> queryAllPredictions() async {
    Database? db = await instance.database;
    return await db!.query(_predictionTable);
  }

  Future<List<Map<String, dynamic>>> queryPrediction(int predictionId) async {
    Database? db = await instance.database;
    return await db!.query(_predictionTable,
        columns: [
          '$date',
          '$disease',
          '$treatmentOne',
          '$treatmentTwo',
          '$id',
          '$treatmentThree',
          '$image'
        ],
        where: "$id=?",
        whereArgs: [id]);
  }

  Future deletePrediction(int predictionId) async {
    Database? db = await instance.database;
    return await db!
        .delete(_predictionTable, where: 'id=?', whereArgs: [predictionId]);
  }
}
