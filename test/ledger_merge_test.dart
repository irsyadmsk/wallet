import 'package:flutter_test/flutter_test.dart';

import 'package:financial_recording/data/services/sync/ledger_merge.dart';

void main() {
  final family = <String, List<Map<String, dynamic>>>{
    'categories': [
      {'id': 'f-makan', 'name': 'Makanan', 'typeCode': 1, 'parentId': null},
      {'id': 'f-kopi', 'name': 'Kopi', 'typeCode': 1, 'parentId': 'f-makan'},
    ],
    'accounts': [
      {'id': 'f-tunai', 'name': 'Tunai', 'groupCode': 1, 'openingBalance': 0},
    ],
    'tags': [
      {'id': 'f-rutin', 'name': 'Rutin'},
    ],
    'templates': [
      {'id': 'f-t1', 'name': 'Kopi', 'accountId': 'f-tunai', 'categoryId': 'f-kopi'},
    ],
    'budgets': [
      {'id': 'f-b1', 'categoryId': 'f-makan', 'isTotal': false},
    ],
    'crypto_holdings': [
      {'id': 'f-btc', 'coinId': 'bitcoin', 'amount': 0.01, 'costBasis': 10000000},
    ],
  };

  final mine = <String, List<Map<String, dynamic>>>{
    'categories': [
      {'id': 'm-makan', 'name': ' makanan ', 'typeCode': 1, 'parentId': null},
      {'id': 'm-kopi', 'name': 'Kopi', 'typeCode': 1, 'parentId': 'm-makan'},
      {'id': 'm-hobi', 'name': 'Hobi', 'typeCode': 1, 'parentId': null},
      {'id': 'm-gaji', 'name': 'Makanan', 'typeCode': 0, 'parentId': null}, // pemasukan: beda jenis
    ],
    'accounts': [
      {'id': 'm-tunai', 'name': 'Tunai', 'groupCode': 1, 'openingBalance': 0}, // bawaan, tak dipakai
      {'id': 'm-dompet', 'name': 'Tunai ', 'groupCode': 1, 'openingBalance': 50000}, // punya saldo
      {'id': 'm-bank', 'name': 'BCA', 'groupCode': 2, 'openingBalance': 0},
    ],
    'tags': [
      {'id': 'm-rutin', 'name': 'rutin'},
    ],
    'transactions': [
      {'id': 'tx1', 'accountId': 'm-bank', 'toAccountId': null, 'categoryId': 'm-kopi', 'tagIds': ['m-rutin'], 'amount': 20000},
      {'id': 'tx2', 'accountId': 'm-bank', 'toAccountId': null, 'categoryId': 'm-hobi', 'tagIds': [], 'amount': 50000},
    ],
    'templates': [
      {'id': 'm-t1', 'name': 'kopi', 'accountId': 'm-bank', 'categoryId': 'm-kopi'},
      {'id': 'm-t2', 'name': 'Parkir', 'accountId': 'm-bank', 'categoryId': 'm-hobi'},
    ],
    'budgets': [
      {'id': 'm-b1', 'categoryId': 'm-makan', 'isTotal': false},
      {'id': 'm-b2', 'categoryId': 'm-hobi', 'isTotal': false},
    ],
    'crypto_holdings': [
      {'id': 'm-btc', 'coinId': 'bitcoin', 'amount': 0.02, 'costBasis': 20000000},
      {'id': 'm-eth', 'coinId': 'ethereum', 'amount': 1, 'costBasis': 0},
    ],
    'memos': [
      {'id': 'memo1', 'title': 'catatan'},
    ],
  };

  final plan = LedgerMerge.plan(mine: mine, family: family);
  List<String> ids(String t) => [for (final r in plan[t] ?? const []) r['id'] as String];
  Map<String, dynamic> row(String t, String id) => plan[t]!.firstWhere((r) => r['id'] == id);

  test('kategori yang sama tidak diduplikasi; yang baru ikut dengan induk yang dipetakan', () {
    expect(ids('categories'), unorderedEquals(['m-hobi', 'm-gaji']));
  });

  test('transaksi diarahkan ke kategori & tag keluarga, id-nya tetap', () {
    final tx1 = row('transactions', 'tx1');
    expect(tx1['categoryId'], 'f-kopi');
    expect(tx1['tagIds'], ['f-rutin']);
    expect(tx1['accountId'], 'm-bank');
    expect(row('transactions', 'tx2')['categoryId'], 'm-hobi');
    expect(ids('tags'), isEmpty);
  });

  test('akun bawaan yang tak dipakai digabung, akun bersaldo tetap terpisah', () {
    expect(ids('accounts'), unorderedEquals(['m-dompet', 'm-bank']));
  });

  test('template & anggaran yang sudah dimiliki keluarga dilewati', () {
    expect(ids('templates'), ['m-t2']);
    expect(row('templates', 'm-t2')['categoryId'], 'm-hobi');
    expect(ids('budgets'), ['m-b2']);
  });

  test('kripto koin yang sama ditambahkan ke milik keluarga', () {
    final btc = row('crypto_holdings', 'f-btc');
    expect(btc['amount'], closeTo(0.03, 1e-12));
    expect(btc['costBasis'], 30000000);
    expect(ids('crypto_holdings'), unorderedEquals(['f-btc', 'm-eth']));
  });

  test('catatan pribadi lain disalin apa adanya', () {
    expect(ids('memos'), ['memo1']);
  });
}
