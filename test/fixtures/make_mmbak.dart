import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

/// Builds a tiny Money Manager-shaped `.mmbak` (SQLite) file in memory and
/// returns its bytes: 1 group, 2 accounts, 1 category, 2 transactions.
Uint8List makeMmbakBytes() {
  final path = '${Directory.systemTemp.path}/fixture-${DateTime.now().microsecondsSinceEpoch}.mmbak';
  final db = sqlite3.open(path);
  db.execute('''
    CREATE TABLE ASSETGROUP (uid TEXT, TYPE INTEGER);
    CREATE TABLE ASSETS (uid TEXT, groupUid TEXT, NIC_NAME TEXT, ORDERSEQ INTEGER, IS_DEL INTEGER);
    CREATE TABLE ZCATEGORY (uid TEXT, NAME TEXT, TYPE INTEGER, ORDERSEQ INTEGER, pUid TEXT, C_IS_DEL INTEGER);
    CREATE TABLE INOUTCOME (uid TEXT, assetUid TEXT, toAssetUid TEXT, ctgUid TEXT, ZMONEY REAL,
      ZDATE INTEGER, WDATE TEXT, DO_TYPE TEXT, ZCONTENT TEXT, txUidTrans TEXT, IS_DEL INTEGER);
    INSERT INTO ASSETGROUP VALUES ('1', 1);
    INSERT INTO ASSETS VALUES ('acc-cash', '1', 'Dompet', 0, 0), ('acc-bank', '1', 'Bank', 1, 0);
    INSERT INTO ZCATEGORY VALUES ('cat-food', 'Makan', 1, 0, '', 0);
    INSERT INTO INOUTCOME VALUES
      ('tx-1', 'acc-cash', NULL, 'cat-food', 25000, 1758700000000, NULL, '1', 'Nasi padang', NULL, 0),
      ('tx-2', 'acc-bank', NULL, NULL, 1000000, 1758700000000, NULL, '0', 'Gaji', NULL, 0);
  ''');
  db.dispose();
  final file = File(path);
  final bytes = file.readAsBytesSync();
  file.deleteSync();
  return bytes;
}
