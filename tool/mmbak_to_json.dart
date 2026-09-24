// Standalone CLI (plain `dart run`, no Flutter engine needed) that converts
// a Money Manager `.mmbak` SQLite backup into this app's v2 JSON backup
// format, reusing the exact same reader/mapper the in-app importer uses.
//
// Usage:
//   dart run tool/mmbak_to_json.dart <input.mmbak> <output.json>
import 'dart:convert';
import 'dart:io';

import 'package:financial_recording/data/import/mmbak_mapper.dart';
import 'package:financial_recording/data/import/mmbak_reader_io.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/mmbak_to_json.dart <input.mmbak> <output.json>');
    exitCode = 1;
    return;
  }
  final inputPath = args[0];
  final outputPath = args[1];

  stdout.writeln('Membaca $inputPath ...');
  final raw = await MmbakReader.read(path: inputPath);
  stdout.writeln('Memetakan data...');
  final preview = MmbakMapper.map(raw);

  final json = {
    'schemaVersion': 2,
    'exportedAt': DateTime.now().toIso8601String(),
    'accounts': preview.accounts.map((a) => a.toJson()).toList(),
    'categories': preview.categories.map((c) => c.toJson()).toList(),
    'transactions': preview.transactions.map((t) => t.toJson()).toList(),
    'tags': preview.tags.map((t) => t.toJson()).toList(),
    'budgets': [],
    'recurringRules': preview.recurringRules.map((r) => r.toJson()).toList(),
  };

  final file = File(outputPath);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));

  stdout.writeln('--- Ringkasan ---');
  stdout.writeln('Akun        : ${preview.accounts.length}');
  stdout.writeln('Kategori    : ${preview.categories.length}');
  stdout.writeln('Transaksi   : ${preview.transactions.length}'
      ' (income=${preview.incomeCount}, expense=${preview.expenseCount}, transfer=${preview.transferCount})');
  stdout.writeln('Tag         : ${preview.tags.length}');
  stdout.writeln('Berulang    : ${preview.recurringRules.length}');
  stdout.writeln('Net worth   : Rp ${preview.netWorth}');
  stdout.writeln('Peringatan  : ${preview.warnings.length}');
  for (final w in preview.warnings) {
    stdout.writeln('  - $w');
  }
  stdout.writeln('Ditulis ke $outputPath');
}
