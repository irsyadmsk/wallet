import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/shared/responsive/adaptive_dialog.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

final _thousands = NumberFormat.decimalPattern('id_ID');

/// A +/-/×/÷ calculator for the amount field — handy for splitting a bill or
/// totalling receipt items without leaving the form. Shows a running
/// expression trail above a large, thousands-formatted live result so long
/// Rupiah amounts stay legible while typing. Returns the evaluated integer
/// result, or null if dismissed.
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key, this.initial});
  final int? initial;

  static Future<int?> show(BuildContext context, {int? initial}) {
    return showAdaptiveSheet<int>(
      context,
      builder: (_) => CalculatorDialog(initial: initial),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

enum _Op { add, sub, mul, div }

String _opSymbol(_Op op) => switch (op) {
      _Op.add => '+',
      _Op.sub => '−',
      _Op.mul => '×',
      _Op.div => '÷',
    };

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '';
  String _trail = '';
  double? _accumulator;
  _Op? _pendingOp;
  bool _justEvaluated = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null && widget.initial != 0) {
      _display = widget.initial.toString();
    }
  }

  String _formatted(String raw) {
    if (raw.isEmpty) return '0';
    final n = num.tryParse(raw);
    return n == null ? raw : _thousands.format(n);
  }

  void _tapDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_justEvaluated) {
        _display = '';
        _trail = '';
        _justEvaluated = false;
      }
      if (_display == '0') _display = '';
      // Cap length so the live display never overflows the card.
      if (_display.length >= 15) return;
      _display += d;
    });
  }

  void _tapOp(_Op op) {
    if (_display.isEmpty && _accumulator == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_display.isNotEmpty) {
        _trail = '$_trail${_formatted(_display)} ${_opSymbol(op)} ';
        _applyPending(double.tryParse(_display) ?? 0);
      } else if (_pendingOp != null) {
        // Swap the pending operator instead of stacking a new term.
        _trail = '${_trail.substring(0, _trail.length - 2)}${_opSymbol(op)} ';
      }
      _pendingOp = op;
      _display = '';
      _justEvaluated = false;
    });
  }

  void _applyPending(double value) {
    if (_pendingOp == null || _accumulator == null) {
      _accumulator = value;
      return;
    }
    switch (_pendingOp!) {
      case _Op.add:
        _accumulator = _accumulator! + value;
        break;
      case _Op.sub:
        _accumulator = _accumulator! - value;
        break;
      case _Op.mul:
        _accumulator = _accumulator! * value;
        break;
      case _Op.div:
        _accumulator = value == 0 ? _accumulator : _accumulator! / value;
        break;
    }
  }

  void _equals() {
    if (_pendingOp == null || _display.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      _trail = '$_trail${_formatted(_display)} =';
      _applyPending(value);
      _display = _formatResult(_accumulator ?? 0);
      _pendingOp = null;
      _justEvaluated = true;
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_justEvaluated) {
        _clear();
        return;
      }
      if (_display.isNotEmpty) {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  void _clear() {
    setState(() {
      _display = '';
      _trail = '';
      _accumulator = null;
      _pendingOp = null;
      _justEvaluated = false;
    });
  }

  String _formatResult(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  int _resultValue() {
    if (_pendingOp != null && _display.isNotEmpty) {
      _equals();
    }
    final raw = _display.isNotEmpty ? _display : (_accumulator?.toString() ?? '0');
    return double.tryParse(raw)?.round() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Text('Kalkulator', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 18,
                    child: Text(
                      _trail,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(fontSize: 14, color: colors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatted(_display),
                      maxLines: 1,
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _row([_Key.text('AC', danger: true), _Key.digit('0'), _Key.icon(Icons.backspace_outlined), _Key.op(_Op.add)]),
            _row([_Key.digit('1'), _Key.digit('2'), _Key.digit('3'), _Key.op(_Op.sub)]),
            _row([_Key.digit('4'), _Key.digit('5'), _Key.digit('6'), _Key.op(_Op.mul)]),
            _row([_Key.digit('7'), _Key.digit('8'), _Key.digit('9'), _Key.op(_Op.div)]),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
                onPressed: _equals,
                child: const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => Navigator.of(context).pop(_resultValue()),
                    child: const Text('Gunakan', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<_Key> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          for (final k in keys)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _CalcKey(spec: k, onTap: () => _onKey(k)),
              ),
            ),
        ],
      ),
    );
  }

  void _onKey(_Key k) {
    switch (k.kind) {
      case _KeyKind.clear:
        _clear();
        break;
      case _KeyKind.backspace:
        _backspace();
        break;
      case _KeyKind.op:
        _tapOp(k.op!);
        break;
      case _KeyKind.digit:
        _tapDigit(k.label!);
        break;
    }
  }
}

enum _KeyKind { digit, op, clear, backspace }

class _Key {
  const _Key._(this.kind, {this.label, this.op, this.icon, this.danger = false});
  factory _Key.digit(String d) => _Key._(_KeyKind.digit, label: d);
  factory _Key.op(_Op op) => _Key._(_KeyKind.op, label: _opSymbol(op), op: op);
  factory _Key.text(String label, {bool danger = false}) =>
      _Key._(label == 'AC' ? _KeyKind.clear : _KeyKind.digit, label: label, danger: danger);
  factory _Key.icon(IconData icon) => _Key._(_KeyKind.backspace, icon: icon);

  final _KeyKind kind;
  final String? label;
  final _Op? op;
  final IconData? icon;
  final bool danger;
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.spec, required this.onTap});
  final _Key spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOp = spec.kind == _KeyKind.op;
    final isUtility = spec.kind == _KeyKind.clear || spec.kind == _KeyKind.backspace;

    final bg = isOp
        ? colors.primaryContainer
        : spec.danger
            ? colors.danger.withValues(alpha: 0.12)
            : colors.surfaceAlt;
    final fg = isOp
        ? colors.primary
        : spec.danger
            ? colors.danger
            : isUtility
                ? colors.textSecondary
                : colors.textPrimary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          child: spec.icon != null
              ? Icon(spec.icon, color: fg, size: 22)
              : Text(
                  spec.label ?? '',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg),
                ),
        ),
      ),
    );
  }
}
