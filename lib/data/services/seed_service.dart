import 'package:uuid/uuid.dart';
import 'package:financial_recording/data/models/account_model/account_model.dart';
import 'package:financial_recording/data/models/tx_category_model/tx_category_model.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/domain/enums/account_group_type.dart';

/// Seeds a minimal, usable starting point for a brand new install: one cash account and a small default category set.
class SeedService {
  static const _uuid = Uuid();

  Future<void> seedIfEmpty() async {
    final accounts = AccountRepository();
    final categories = TxCategoryRepository();

    if (accounts.all(includeArchived: true).isEmpty) {
      await accounts.upsert(AccountModel(
        id: _uuid.v4(),
        name: 'Tunai',
        groupCode: AccountGroupType.cash.code,
        colorValue: 0xFF10B981,
      ));
    }

    // Account-group rows (typeCode 2) share this box; only real categories count.
    if (categories.all(includeArchived: true).every((c) => c.typeCode == TxCategoryModel.accountGroupType)) {
      final expense = <String, String>{
        '🍜': 'Makanan',
        '🚖': 'Transportasi',
        '🪑': 'Kebutuhan harian',
        '🧥': 'Pakaian',
        '🧘': 'Kesehatan',
        '📙': 'Pendidikan',
        '🎁': 'Hadiah',
        '🎬': 'Hiburan',
        '📦': 'Lainnya',
      };
      final income = <String, String>{
        '💰': 'Gaji',
        '🏅': 'Bonus',
        '🤑': 'Uang jajan',
        '📦': 'Lainnya',
      };
      var seq = 0;
      for (final entry in expense.entries) {
        await categories.upsert(TxCategoryModel(
          id: _uuid.v4(),
          name: entry.value,
          emoji: entry.key,
          typeCode: 1,
          orderSeq: seq++,
        ));
      }
      seq = 0;
      for (final entry in income.entries) {
        await categories.upsert(TxCategoryModel(
          id: _uuid.v4(),
          name: entry.value,
          emoji: entry.key,
          typeCode: 0,
          orderSeq: seq++,
        ));
      }
    }
  }
}
