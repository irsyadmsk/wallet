/// Personal planning only. Checking an item never posts a ledger transaction.
class PlanRule {
  final String kind, currency;
  final int price, taxBps, months, target, weight, priority;
  final bool taxIncluded, enabled;
  const PlanRule({required this.kind, this.currency = 'IDR', this.price = 0,
    this.taxBps = 0, this.months = 1, this.taxIncluded = false,
    this.enabled = true, this.target = 0, this.weight = 0, this.priority = 1});

  int quote(int fx) {
    if (!enabled) return 0;
    if (currency == 'USD' && fx <= 0) {
      throw const FormatException('Isi kurs USD/IDR sebelum menghitung langganan dolar.');
    }
    final numerator = BigInt.from(price) * BigInt.from(currency == 'USD' ? fx : 1) *
        BigInt.from(taxIncluded ? 10000 : 10000 + taxBps);
    final denominator = BigInt.from(months * 10000 * (currency == 'USD' ? 100 : 1));
    return planMoney(((numerator + denominator ~/ BigInt.two) ~/ denominator).toInt());
  }

  Map<String, dynamic> toJson() => {'kind': kind, 'currency': currency,
    'price': price, 'taxBps': taxBps, 'months': months,
    'taxIncluded': taxIncluded, 'enabled': enabled, 'target': target,
    'weight': weight, 'priority': priority};
  factory PlanRule.fromJson(Map<String, dynamic> j) {
    final kind = j['kind'], currency = j['currency'];
    if (!['subscription', 'saving'].contains(kind) ||
        !['IDR', 'USD'].contains(currency) || j['months'] is! int ||
        ![1, 12].contains(j['months']) ||
        j['enabled'] is! bool || j['taxIncluded'] is! bool) {
      throw const FormatException('Aturan alokasi tidak valid.');
    }
    int bounded(String key, int max) {
      final v = planMoney(j[key]);
      if (v > max) throw const FormatException('Aturan alokasi di luar batas.');
      return v;
    }
    return PlanRule(kind: kind as String, currency: currency as String,
      price: planMoney(j['price']), taxBps: bounded('taxBps', 10000),
      months: j['months'] as int, enabled: j['enabled'] as bool,
      taxIncluded: j['taxIncluded'] as bool, target: planMoney(j['target']),
      weight: bounded('weight', 10000), priority: bounded('priority', 10000));
  }
}

class AllocationItem {
  final String id, group, name, note;
  final int amount, opening, spent;
  final int? actual;
  final bool done, rollover;
  final PlanRule? rule;
  const AllocationItem({required this.id, required this.group,
    required this.name, required this.amount, this.note = '', this.done = false,
    this.rule, this.actual, this.opening = 0, this.spent = 0, this.rollover = false});

  int get balance => opening + (actual ?? 0) - spent;
  AllocationItem copy({String? group, String? name, String? note, int? amount,
    bool? done, PlanRule? rule, bool clearRule = false, int? actual,
    bool clearActual = false, int? opening, int? spent, bool? rollover}) =>
      AllocationItem(id: id, group: group ?? this.group, name: name ?? this.name,
        note: note ?? this.note, amount: amount ?? this.amount,
        done: done ?? this.done, rule: clearRule ? null : rule ?? this.rule,
        actual: clearActual ? null : actual ?? this.actual,
        opening: opening ?? this.opening, spent: spent ?? this.spent,
        rollover: rollover ?? this.rollover);
  Map<String, dynamic> toJson() => {'id': id, 'group': group, 'name': name,
    'note': note, 'amount': amount, 'done': done,
    if (rule != null) 'rule': rule!.toJson(),
    if (actual != null) 'actual': actual,
    if (rollover || opening != 0 || spent != 0) ...{
      'opening': opening, 'spent': spent, 'rollover': rollover}};
  factory AllocationItem.fromJson(Map<String, dynamic> j) {
    String text(String key, int max) {
      final value = j[key];
      if (value is! String || value.length > max ||
          (key != 'note' && value.trim().isEmpty)) {
        throw const FormatException('Format pos tidak valid.');
      }
      return value;
    }
    if (j['done'] is! bool || (j.containsKey('rollover') && j['rollover'] is! bool)) {
      throw const FormatException('Status pos tidak valid.');
    }
    final rule = j['rule'] == null ? null :
      PlanRule.fromJson(Map<String, dynamic>.from(j['rule'] as Map));
    if (j['group'] == 'Potongan gaji' && rule != null) {
      throw const FormatException('Potongan gaji harus berupa pos tetap.');
    }
    return AllocationItem(id: text('id', 100), group: text('group', 100),
      name: text('name', 200), note: text('note', 2000),
      amount: planMoney(j['amount']), done: j['done'] as bool, rule: rule,
      actual: j['actual'] == null ? null : planMoney(j['actual']),
      opening: signedPlanMoney(j['opening'] ?? 0),
      spent: planMoney(j['spent'] ?? 0), rollover: j['rollover'] == true);
  }
}

int planMoney(dynamic v) {
  if (v is! int || v < 0 || v > 1000000000000) {
    throw const FormatException('Nominal harus rupiah bulat, 0–1 triliun.');
  }
  return v;
}
int signedPlanMoney(dynamic v) {
  if (v is! int || v.abs() > 1000000000000) {
    throw const FormatException('Saldo dana di luar batas.');
  }
  return v;
}

class MonthlyPlan {
  final int gross, bonus, fx;
  final int? received;
  final List<AllocationItem> items;
  MonthlyPlan({this.gross = 0, this.received, this.bonus = 0, this.fx = 0,
    List<AllocationItem> items = const []}) : items = List.unmodifiable(items);
  int get deductions => items.where((i) => i.group == 'Potongan gaji')
    .fold(0, (s, i) => s + i.amount);
  int get net => gross - deductions;
  int get available => (received ?? net) + bonus;
  int get planned => items.where((i) => i.group != 'Potongan gaji')
    .fold(0, (s, i) => s + i.amount);
  int get completed => items.where((i) => i.done && i.group != 'Potongan gaji')
    .fold(0, (s, i) => s + i.amount);
  int get actual => items.where((i) => i.group != 'Potongan gaji')
    .fold(0, (s, i) => s + (i.actual ?? 0));
  int get digital => items.where((i) => i.rule?.kind == 'subscription' ||
    ['langganan', 'langganan digital'].contains(i.group.trim().toLowerCase()))
    .fold(0, (s, i) => s + i.amount);
  int get unallocated => available - planned;
  MonthlyPlan copy({int? gross, int? received, bool clearReceived = false,
    int? bonus, int? fx, List<AllocationItem>? items}) => MonthlyPlan(
      gross: gross ?? this.gross, received: clearReceived ? null : received ?? this.received,
      bonus: bonus ?? this.bonus, fx: fx ?? this.fx, items: items ?? this.items);

  /// Fixed costs stay fixed. Base targets follow priority, then weighted surplus.
  /// Calculations only affect the selected document, never an account ledger.
  MonthlyPlan recalculate() {
    final rows = items.map((i) {
      if (i.rule?.kind != 'subscription') return i;
      final amount = i.rule!.quote(fx);
      return i.copy(amount: amount, done: amount == i.amount && i.done);
    }).toList();
    final savings = rows.where((i) => i.rule?.kind == 'saving').toList();
    final order = {for (var n = 0; n < rows.length; n++) rows[n].id: n};
    savings.sort((a, b) {
      final p = a.rule!.priority.compareTo(b.rule!.priority);
      return p == 0 ? order[a.id]!.compareTo(order[b.id]!) : p;
    });
    final fixed = rows.where((i) => i.group != 'Potongan gaji' && i.rule?.kind != 'saving')
      .fold(0, (int s, i) => s + i.amount);
    var room = available - fixed;
    if (room < 0) room = 0;
    final amounts = <String, int>{};
    for (final i in savings) {
      final target = i.rule!.enabled ? i.rule!.target : 0;
      final funded = room < target ? room : target;
      amounts[i.id] = funded;
      room -= funded;
    }
    final weighted = savings.where((i) => i.rule!.enabled && i.rule!.weight > 0).toList();
    final weights = weighted.fold(0, (int s, i) => s + i.rule!.weight);
    if (weights > 0) {
      final residues = <String, BigInt>{};
      var distributed = 0;
      for (final i in weighted) {
        final numerator = BigInt.from(room) * BigInt.from(i.rule!.weight);
        final part = (numerator ~/ BigInt.from(weights)).toInt();
        residues[i.id] = numerator % BigInt.from(weights);
        amounts[i.id] = amounts[i.id]! + part;
        distributed += part;
      }
      weighted.sort((a, b) {
        final remainder = residues[b.id]!.compareTo(residues[a.id]!);
        return remainder == 0 ? order[a.id]!.compareTo(order[b.id]!) : remainder;
      });
      for (var n = 0; n < room - distributed; n++) {
        amounts[weighted[n].id] = amounts[weighted[n].id]! + 1;
      }
    }
    return copy(items: rows.map((i) => amounts.containsKey(i.id)
      ? i.copy(amount: amounts[i.id], done: i.done && i.amount == amounts[i.id]) : i).toList());
  }

  MonthlyPlan forNewMonth({MonthlyPlan? previous}) {
    final prior = {for (final i in previous?.items ?? <AllocationItem>[]) i.id: i};
    return copy(clearReceived: true, bonus: 0, items: items.map((i) => i.copy(
      done: false, clearActual: true, spent: 0,
      opening: i.rollover ? prior[i.id]?.balance ?? i.opening : 0)).toList()).recalculate();
  }
  Map<String, dynamic> toJson() => {'version': 1, 'gross': gross,
    'received': received, 'bonus': bonus, 'fx': fx,
    'items': items.map((i) => i.toJson()).toList()};
  factory MonthlyPlan.fromJson(Map<String, dynamic> j) {
    final rows = j['items'];
    if (j['version'] != 1 || rows is! List || rows.length > 200) {
      throw const FormatException('Format rencana tidak didukung.');
    }
    final items = rows.map((i) => AllocationItem.fromJson(
      Map<String, dynamic>.from(i as Map))).toList();
    if (items.map((i) => i.id).toSet().length != items.length) {
      throw const FormatException('ID pos berulang.');
    }
    final fx = planMoney(j['fx'] ?? 0);
    if (fx > 1000000) throw const FormatException('Kurs di luar batas.');
    return MonthlyPlan(gross: planMoney(j['gross']),
      received: j['received'] == null ? null : planMoney(j['received']),
      bonus: planMoney(j['bonus'] ?? 0), fx: fx, items: items);
  }
}
