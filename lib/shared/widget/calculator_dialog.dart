import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

/// A basic +/-/×/÷ calculator for the amount field — handy for splitting a
/// bill or totalling receipt items without leaving the form. Returns the
/// evaluated integer result, or null if dismissed.
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key, this.initial});
  final int? initial;

  static Future<int?> show(BuildContext context, {int? initial}) {
    return showDialog<int>(
      context: context,
      builder: (_) => CalculatorDialog(initial: initial),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

enum _Op { add, sub, mul, div }

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '';
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

  void _tapDigit(String d) {
    setState(() {
      if (_justEvaluated) {
        _display = '';
        _justEvaluated = false;
      }
      if (d == '.' && _display.contains('.')) return;
      if (_display == '0' && d != '.') _display = '';
      _display += d;
    });
  }

  void _tapOp(_Op op) {
    setState(() {
      if (_display.isNotEmpty) {
        _applyPending(double.tryParse(_display) ?? 0);
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
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      _applyPending(value);
      _display = _formatResult(_accumulator ?? 0);
      _pendingOp = null;
      _justEvaluated = true;
    });
  }

  void _clear() {
    setState(() {
      _display = '';
      _accumulator = null;
      _pendingOp = null;
      _justEvaluated = false;
    });
  }

  String _formatResult(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kalkulator', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                _display.isEmpty ? '0' : _display,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _row(['7', '8', '9', '÷']),
            _row(['4', '5', '6', '×']),
            _row(['1', '2', '3', '-']),
            _row(['C', '0', '=', '+']),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _equals();
                      final result = double.tryParse(_display)?.round() ?? 0;
                      Navigator.of(context).pop(result);
                    },
                    child: const Text('Gunakan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Row(
      children: [
        for (final k in keys)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: _CalcKey(label: k, onTap: () => _onKey(k)),
            ),
          ),
      ],
    );
  }

  void _onKey(String k) {
    switch (k) {
      case 'C':
        _clear();
        break;
      case '=':
        _equals();
        break;
      case '+':
        _tapOp(_Op.add);
        break;
      case '-':
        _tapOp(_Op.sub);
        break;
      case '×':
        _tapOp(_Op.mul);
        break;
      case '÷':
        _tapOp(_Op.div);
        break;
      default:
        _tapDigit(k);
    }
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOp = ['+', '-', '×', '÷', '='].contains(label);
    return Material(
      color: isOp ? colors.primaryContainer : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isOp ? colors.primary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
