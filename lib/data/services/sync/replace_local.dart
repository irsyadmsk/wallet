import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/recurring_repository.dart';
import 'package:financial_recording/data/repositories/tag_repository.dart';
import 'package:financial_recording/data/repositories/tx_category_repository.dart';
import 'package:financial_recording/data/repositories/tx_repository.dart';
import 'package:financial_recording/data/services/sync/tombstone_service.dart';

/// Records a tombstone for every row about to be wiped by a "replace all"
/// import or restore, so the cloud drops them too. Without this the old
/// rows return on the next full pull (a new device, or signing in again)
/// alongside the new ones.
Future<void> tombstoneBeforeReplace({
  AccountRepository? accounts,
  TxCategoryRepository? categories,
  TxRepository? transactions,
  TagRepository? tags,
  RecurringRepository? recurring,
}) async {
  final t = TombstoneService();
  if (accounts != null) {
    await t.recordAll('accounts', accounts.all(includeArchived: true, includeDeleted: true).map((a) => a.id));
  }
  if (categories != null) await t.recordAll('categories', categories.all(includeArchived: true).map((c) => c.id));
  if (transactions != null) await t.recordAll('transactions', transactions.all().map((x) => x.id));
  if (tags != null) await t.recordAll('tags', tags.all(includeArchived: true).map((x) => x.id));
  if (recurring != null) await t.recordAll('recurring', recurring.all().map((r) => r.id));
}
