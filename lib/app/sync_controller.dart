import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:financial_recording/app/app_events.dart';
import 'package:financial_recording/config/app_config_v2.dart';
import 'package:financial_recording/data/repositories/account_repository.dart';
import 'package:financial_recording/data/repositories/template_repository.dart';
import 'package:financial_recording/data/services/family_service.dart';
import 'package:financial_recording/data/services/recurring_service.dart';
import 'package:financial_recording/data/services/seed_service.dart';
import 'package:financial_recording/data/services/supabase_service.dart';
import 'package:financial_recording/data/services/sync/sync_service.dart';

/// Keeps the local boxes and the cloud ledger in step without the user
/// thinking about it:
/// - syncs on sign-in, on app resume, every few minutes, a few seconds
///   after any local edit, and when Realtime reports a change by another
///   device or family member;
/// - owns the family (household) state and moves this device between
///   ledgers when the user joins, leaves, or is removed from a family.
class SyncController extends GetxController {
  final _sync = SyncService();
  final _family = FamilyService();

  final syncing = false.obs;
  final lastSyncAt = Rxn<DateTime>();
  final errorText = RxnString();
  final household = Rxn<Household>();
  final members = <HouseholdMember>[].obs;
  final familyBusy = false.obs;

  Timer? _periodic;
  Timer? _debounce;
  RealtimeChannel? _channel;
  String? _channelLedger;
  final _boxSubs = <StreamSubscription>[];
  AppLifecycleListener? _lifecycle;
  bool _suppressLocal = false;
  bool _queued = false;

  static const _financialBoxes = [
    AppBoxes.accounts,
    AppBoxes.categories,
    AppBoxes.transactions,
    AppBoxes.tags,
    AppBoxes.budgets,
    AppBoxes.recurring,
    AppBoxes.goals,
    AppBoxes.templates,
    AppBoxes.debts,
    AppBoxes.memos,
  ];

  String? get _uid => SupabaseService.currentUser?.id;

  /// Ledger this device is looking at (own, or the family owner's).
  String? get ledgerOwnerId => _sync.ledgerOwnerId ?? _uid;

  bool get inFamily => household.value != null;
  bool get isFamilyOwner => household.value?.ownerId == _uid;

  /// Display name for [userId] within the family, if known.
  String? memberName(String? userId) {
    if (userId == null) return null;
    for (final m in members) {
      if (m.userId == userId) return m.label;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    lastSyncAt.value = _sync.lastSyncAt;
  }

  @override
  void onClose() {
    _stopAuto();
    super.onClose();
  }

  Future<void> onSignedIn(User user) async {
    // Another account's data on this device must never leak into this one.
    final previous = _sync.syncedUserId;
    if (previous != null && previous != user.id) {
      await _sync.wipeLocal();
      notifyDataChanged();
    }
    await refreshFamily(reconcile: true);
    await syncNow();
    _startAuto();
  }

  Future<void> onSignedOut() async {
    _stopAuto();
    household.value = null;
    members.clear();
  }

  /// Pushes pending edits and wipes the local copy; used by sign-out.
  /// Returns the sync error, if any, without wiping.
  Future<String?> flushAndWipe({bool force = false}) async {
    final r = await syncNow();
    if (!r.ok && !force) return r.error;
    _stopAuto();
    await _sync.wipeLocal();
    notifyDataChanged();
    return null;
  }

  Future<SyncResult> syncNow() async {
    if (_uid == null) return const SyncResult(pushed: 0, pulled: 0, error: 'Belum login.');
    if (syncing.value) {
      _queued = true;
      return const SyncResult(pushed: 0, pulled: 0);
    }
    syncing.value = true;
    _suppressLocal = true;
    try {
      var result = await _sync.syncNow();
      if (result.ok && await _housekeeping()) {
        result = await _sync.syncNow();
      }
      errorText.value = result.error;
      lastSyncAt.value = _sync.lastSyncAt;
      if (result.pulled > 0) notifyDataChanged();
      return result;
    } finally {
      syncing.value = false;
      // Box-watch events from rows we just wrote arrive asynchronously;
      // ignore them briefly so a pull doesn't schedule another sync.
      Future.delayed(const Duration(milliseconds: 1200), () => _suppressLocal = false);
      if (_queued) {
        _queued = false;
        _schedule(const Duration(seconds: 2));
      }
    }
  }

  /// First-run seeding and recurring posts, done only after the cloud
  /// ledger has been pulled so they never duplicate what's already there.
  /// Returns true when it wrote something that needs pushing.
  Future<bool> _housekeeping() async {
    var changed = false;
    // A brand-new ledger (nothing in the cloud either) gets starter
    // accounts, categories and quick templates — once.
    if (AccountRepository().all(includeArchived: true, includeDeleted: true).isEmpty) {
      await SeedService().seedIfEmpty();
      await QuickTemplateRepository().seedDefaultsIfEmpty();
      changed = true;
    }
    // Only the ledger owner's devices post recurring transactions, so two
    // family phones never both post the same monthly bill.
    if (ledgerOwnerId == _uid) {
      if (await RecurringService().catchUp(DateTime.now()) > 0) changed = true;
    }
    if (changed) notifyDataChanged();
    return changed;
  }

  // ---------------------------------------------------------------- family

  Future<void> refreshFamily({bool reconcile = false}) async {
    if (_uid == null) return;
    try {
      final (h, m) = await _family.fetch();
      household.value = h;
      members.assignAll(m);
      if (reconcile) await _reconcileLedger();
    } catch (_) {
      // Offline: keep whatever ledger we were on.
    }
  }

  Future<void> _reconcileLedger() async {
    final uid = _uid;
    if (uid == null) return;
    final expected = household.value?.ownerId ?? uid;
    final current = _sync.ledgerOwnerId ?? uid;
    if (expected == current) return;
    // Only our own ledger can still be pushed; a family ledger we've been
    // removed from would be rejected by RLS.
    await _sync.switchLedger(expected, pushFirst: current == uid);
    lastSyncAt.value = _sync.lastSyncAt;
    notifyDataChanged();
    _resubscribe();
  }

  Future<String?> createFamily(String name, String displayName) => _familyOp(() async {
        await _family.create(name, displayName: displayName);
        await refreshFamily(reconcile: true);
      });

  Future<String?> joinFamily(String code, String displayName) => _familyOp(() async {
        await _family.join(code, displayName: displayName);
        await refreshFamily(reconcile: true);
      });

  Future<String?> leaveFamily() => _familyOp(() async {
        await _family.leave();
        await refreshFamily(reconcile: true);
      });

  Future<String?> removeMember(String userId) => _familyOp(() async {
        await _family.removeMember(userId);
        await refreshFamily();
      });

  Future<String?> regenerateCode() => _familyOp(() async {
        await _family.regenerateCode();
        await refreshFamily();
      });

  Future<String?> renameFamily({String? name, String? displayName}) => _familyOp(() async {
        await _family.update(name: name, displayName: displayName);
        await refreshFamily();
      });

  Future<String?> _familyOp(Future<void> Function() op) async {
    if (familyBusy.value) return null;
    familyBusy.value = true;
    try {
      await op();
      return null;
    } on FamilyException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      familyBusy.value = false;
    }
  }

  // ------------------------------------------------------------- automation

  void _startAuto() {
    _periodic?.cancel();
    // Also re-checks family membership, so a device whose owner removed it
    // while it was offline moves back to its own ledger without a restart.
    _periodic = Timer.periodic(const Duration(minutes: 3), (_) async {
      await refreshFamily(reconcile: true);
      await syncNow();
    });

    for (final s in _boxSubs) {
      s.cancel();
    }
    _boxSubs.clear();
    for (final name in _financialBoxes) {
      if (!Hive.isBoxOpen(name)) continue;
      _boxSubs.add(Hive.box(name).watch().listen((_) {
        if (_suppressLocal || syncing.value) return;
        _schedule(const Duration(seconds: 4));
      }));
    }

    _lifecycle ??= AppLifecycleListener(onResume: () {
      refreshFamily(reconcile: true);
      syncNow();
    });
    _resubscribe();
  }

  void _stopAuto() {
    _periodic?.cancel();
    _periodic = null;
    _debounce?.cancel();
    for (final s in _boxSubs) {
      s.cancel();
    }
    _boxSubs.clear();
    _lifecycle?.dispose();
    _lifecycle = null;
    _unsubscribe();
  }

  void _schedule(Duration delay) {
    _debounce?.cancel();
    _debounce = Timer(delay, syncNow);
  }

  /// One Realtime channel per ledger: any change to that ledger's rows
  /// (by us, another device, or a family member) triggers a quick pull.
  void _resubscribe() {
    final ledger = ledgerOwnerId;
    if (ledger == null || ledger == _channelLedger) return;
    _unsubscribe();
    var channel = SupabaseService.client.channel('ledger-$ledger');
    for (final table in const [
      'accounts', 'categories', 'transactions', 'tags', 'budgets',
      'recurring', 'goals', 'templates', 'debts', 'memos',
    ]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: ledger),
        callback: (_) => _schedule(const Duration(milliseconds: 1500)),
      );
    }
    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'household_members',
      callback: (_) => refreshFamily(reconcile: true),
    );
    _channel = channel..subscribe();
    _channelLedger = ledger;
  }

  void _unsubscribe() {
    final c = _channel;
    _channel = null;
    _channelLedger = null;
    if (c != null) SupabaseService.client.removeChannel(c);
  }
}
