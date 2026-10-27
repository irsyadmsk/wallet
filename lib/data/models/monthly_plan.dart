/// Personal planning only. Checking an item never posts a ledger transaction.
class AllocationItem {
  final String id, group, name, note;
  final int amount;
  final bool done;
  const AllocationItem({
    required this.id,
    required this.group,
    required this.name,
    required this.amount,
    this.note = '',
    this.done = false,
  });

  AllocationItem copy({
    String? group,
    String? name,
    String? note,
    int? amount,
    bool? done,
  }) => AllocationItem(
    id: id,
    group: group ?? this.group,
    name: name ?? this.name,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    done: done ?? this.done,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'group': group,
    'name': name,
    'note': note,
    'amount': amount,
    'done': done,
  };
  factory AllocationItem.fromJson(Map<String, dynamic> j) {
    String text(String key, int max) {
      final value = j[key];
      if (value is! String ||
          value.length > max ||
          (key != 'note' && value.trim().isEmpty)) {
        throw const FormatException('Format pos tidak valid.');
      }
      return value;
    }

    if (j['done'] is! bool) {
      throw const FormatException('Status pos tidak valid.');
    }
    return AllocationItem(
      id: text('id', 100),
      group: text('group', 100),
      name: text('name', 200),
      note: text('note', 2000),
      amount: planMoney(j['amount']),
      done: j['done'] as bool,
    );
  }
}

int planMoney(dynamic v) {
  if (v is! int || v < 0 || v > 1000000000000) {
    throw const FormatException('Nominal harus rupiah bulat, 0–1 triliun.');
  }
  return v;
}

class MonthlyPlan {
  final int gross;
  final int? received;
  final List<AllocationItem> items;
  MonthlyPlan({
    this.gross = 0,
    this.received,
    List<AllocationItem> items = const [],
  }) : items = List.unmodifiable(items);
  int get deductions => items
      .where((i) => i.group == 'Potongan gaji')
      .fold(0, (s, i) => s + i.amount);
  int get net => gross - deductions;
  int get planned => items
      .where((i) => i.group != 'Potongan gaji')
      .fold(0, (s, i) => s + i.amount);
  int get completed => items
      .where((i) => i.done && i.group != 'Potongan gaji')
      .fold(0, (s, i) => s + i.amount);
  MonthlyPlan copy({
    int? gross,
    int? received,
    bool clearReceived = false,
    List<AllocationItem>? items,
  }) => MonthlyPlan(
    gross: gross ?? this.gross,
    received: clearReceived ? null : received ?? this.received,
    items: items ?? this.items,
  );
  MonthlyPlan forNewMonth() => copy(
    clearReceived: true,
    items: items.map((i) => i.copy(done: false)).toList(),
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'gross': gross,
    'received': received,
    'items': items.map((i) => i.toJson()).toList(),
  };
  factory MonthlyPlan.fromJson(Map<String, dynamic> j) {
    final rows = j['items'];
    if (j['version'] != 1 || rows is! List || rows.length > 200) {
      throw const FormatException('Format rencana tidak didukung.');
    }
    final items = rows
        .map(
          (i) => AllocationItem.fromJson(Map<String, dynamic>.from(i as Map)),
        )
        .toList();
    if (items.map((i) => i.id).toSet().length != items.length) {
      throw const FormatException('ID pos berulang.');
    }
    return MonthlyPlan(
      gross: planMoney(j['gross']),
      received: j['received'] == null ? null : planMoney(j['received']),
      items: items,
    );
  }
}
