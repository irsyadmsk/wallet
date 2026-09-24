import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:financial_recording/shared/responsive/breakpoints.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';
import 'package:financial_recording/util/calc/calc_engine.dart';

/// Amount calculator for the transaction form. Full expressions with
/// precedence, parentheses and shopping-style percent; a live result under
/// the expression; one-tap tools for splitting a bill, discounts, VAT and
/// rounding; keyboard input on desktop. Returns the rounded rupiah result,
/// or null when dismissed.
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key, this.initial});
  final int? initial;

  static Future<int?> show(BuildContext context, {int? initial}) {
    final child = CalculatorDialog(initial: initial);
    if (context.isCompact) {
      return showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => child,
      );
    }
    return showDialog<int>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
      ),
    );
  }

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  static final _group = NumberFormat.decimalPattern('id_ID');

  /// Raw expression using `,` for decimals and no grouping dots; grouping
  /// is added only for display.
  String _expr = '';
  final List<(String, int)> _tape = [];
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null && widget.initial != 0) _expr = widget.initial.toString();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double? get _value => CalcEngine.preview(_expr);
  int? get _rounded => _value?.round();

  String get _last => _expr.isEmpty ? '' : _expr[_expr.length - 1];
  bool get _endsWithOperator => CalcEngine.operators.contains(_last);

  /// The number currently being typed (after the last operator/paren).
  String get _currentNumber {
    final m = RegExp(r'[0-9,]*$').firstMatch(_expr);
    return m?.group(0) ?? '';
  }

  void _input(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (k) {
        case 'AC':
          if (_expr.isNotEmpty && _value != null) _tape.insert(0, (_display(_expr), _rounded!));
          if (_tape.length > 6) _tape.removeLast();
          _expr = '';
        case '⌫':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        case '()':
          final open = '('.allMatches(_expr).length - ')'.allMatches(_expr).length;
          final canClose = open > 0 && !_endsWithOperator && _last != '(' && _expr.isNotEmpty;
          if (canClose) {
            _expr += ')';
          } else {
            if (_expr.isNotEmpty && !_endsWithOperator && _last != '(') _expr += '×';
            _expr += '(';
          }
        case '%':
          if (_expr.isNotEmpty && !_endsWithOperator && _last != '(' && _last != '%') _expr += '%';
        case '+' || '-' || '×' || '÷':
          if (_expr.isEmpty) {
            if (k == '-') _expr = '-';
            return;
          }
          if (_endsWithOperator) {
            _expr = _expr.substring(0, _expr.length - 1) + k;
          } else if (_last != '(') {
            _expr += k;
          }
        case ',':
          if (_currentNumber.contains(',')) return;
          if (_currentNumber.isEmpty) _expr += '0';
          _expr += ',';
        case '=':
          final v = _rounded;
          if (v == null) return;
          _tape.insert(0, (_display(_expr), v));
          if (_tape.length > 6) _tape.removeLast();
          _expr = v.toString();
        default: // digits and 000
          if (_last == ')' || _last == '%') _expr += '×';
          if (_currentNumber == '0' && k != ',') _expr = _expr.substring(0, _expr.length - 1);
          if (_currentNumber.replaceAll(',', '').length >= 15) return;
          if (k == '000' && _currentNumber.isEmpty) return;
          _expr += k;
      }
    });
  }

  void _applyTool(String Function(String expr) wrap) {
    if (_expr.isEmpty || _value == null) return;
    HapticFeedback.lightImpact();
    setState(() => _expr = wrap(_expr));
  }

  Future<void> _split() async {
    if (_value == null) return;
    var n = 2;
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Bagi tagihan'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WIconButton(icon: Icons.remove_rounded, tooltip: 'Kurangi', filled: true, onPressed: n > 2 ? () => set(() => n--) : null),
              SizedBox(
                width: 110,
                child: Column(
                  children: [
                    Text('$n', style: AppTypography.display(size: 40, weight: FontWeight.w600, color: ctx.colors.textPrimary)),
                    Text('orang', style: TextStyle(color: ctx.colors.textSecondary)),
                  ],
                ),
              ),
              WIconButton(icon: Icons.add_rounded, tooltip: 'Tambah', filled: true, onPressed: n < 50 ? () => set(() => n++) : null),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, n), child: Text('Bagi $n')),
          ],
        ),
      ),
    );
    if (res != null) _applyTool((e) => '($e)÷$res');
  }

  Future<void> _discount() async {
    if (_value == null) return;
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Potongan diskon'),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final p in const [5, 10, 15, 20, 25, 30, 40, 50, 70])
                ActionChip(label: Text('$p%'), onPressed: () => Navigator.pop(ctx, p)),
            ],
          ),
        ],
      ),
    );
    if (res != null) _applyTool((e) => '($e)-$res%');
  }

  String _display(String raw) {
    // Group the integer part of every number with dots for readability.
    return raw.replaceAllMapped(RegExp(r'\d+'), (m) {
      final start = m.start;
      // Digits after a decimal comma stay ungrouped.
      if (start > 0 && raw[start - 1] == ',') return m.group(0)!;
      return _group.format(int.parse(m.group(0)!));
    }).replaceAll('-', '−');
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final ch = e.character;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _input('⌫');
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || ch == '=') {
      if (_value != null && _endsWithOperator == false && _expr == _rounded.toString()) {
        Navigator.of(context).pop(_rounded);
      } else {
        _input('=');
      }
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
    } else if (key == LogicalKeyboardKey.delete) {
      _input('AC');
    } else if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
      _input(ch);
    } else if (ch == '+' || ch == '-') {
      _input(ch!);
    } else if (ch == '*' || ch == 'x' || ch == 'X') {
      _input('×');
    } else if (ch == '/') {
      _input('÷');
    } else if (ch == '%') {
      _input('%');
    } else if (ch == ',' || ch == '.') {
      _input(',');
    } else if (ch == '(' || ch == ')') {
      _input('()');
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = _rounded;
    final expr = _display(_expr);

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Kalkulator', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                WIconButton(icon: Icons.close_rounded, tooltip: 'Tutup', onPressed: () => Navigator.of(context).maybePop()),
              ],
            ),
            const SizedBox(height: 8),
            // Display: expression on top, live result below.
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            expr.isEmpty ? '0' : expr,
                            maxLines: 1,
                            style: AppTypography.numeric(
                              size: 22,
                              weight: FontWeight.w500,
                              color: expr.isEmpty ? c.textTertiary : c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      WIconButton(
                        icon: Icons.backspace_outlined,
                        tooltip: 'Hapus satu karakter',
                        size: 40,
                        onPressed: _expr.isEmpty ? null : () => _input('⌫'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.hover),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a), child: child),
                        ),
                        child: Text(
                          value == null ? (_expr.isEmpty ? 'Rp 0' : 'Belum lengkap') : 'Rp ${_group.format(value)}',
                          key: ValueKey(value),
                          style: AppTypography.display(
                            size: 40,
                            weight: FontWeight.w600,
                            color: value == null && _expr.isNotEmpty ? c.textTertiary : c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // One-tap money tools.
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Tool(icon: Icons.call_split_rounded, label: 'Bagi orang', onTap: _value == null ? null : _split),
                  _Tool(icon: Icons.sell_outlined, label: 'Diskon', onTap: _value == null ? null : _discount),
                  // PPN 11% — tarif umum UU No. 7 Tahun 2021 (HPP) Pasal 7 ayat (1).
                  _Tool(icon: Icons.receipt_long_outlined, label: '+PPN 11%', onTap: _value == null ? null : () => _applyTool((e) => '($e)+11%')),
                  _Tool(icon: Icons.room_service_outlined, label: '+Servis 5%', onTap: _value == null ? null : () => _applyTool((e) => '($e)+5%')),
                  _Tool(
                    icon: Icons.unfold_less_rounded,
                    label: 'Bulatkan ribuan',
                    onTap: _value == null ? null : () => setState(() => _expr = ((_value! / 1000).round() * 1000).toString()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Keypad(onKey: _input),
            if (_tape.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Riwayat', style: TextStyle(fontSize: 12, color: c.textTertiary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              for (final (e, v) in _tape.take(3))
                Pressable(
                  onTap: () => setState(() => _expr = v.toString()),
                  semanticLabel: 'Pakai lagi $e sama dengan $v',
                  hoverLift: 0,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(e, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13)),
                        ),
                        Text('= ${_group.format(v)}',
                            style: AppTypography.numeric(size: 13, weight: FontWeight.w600, color: c.textPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            WButton(
              label: value == null ? 'Gunakan' : 'Gunakan Rp ${_group.format(math.max(0, value))}',
              arrow: true,
              expand: true,
              size: WButtonSize.large,
              onPressed: value == null || value <= 0 ? null : () => Navigator.of(context).pop(value),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        hoverLift: 0,
        borderRadius: BorderRadius.circular(99),
        builder: (context, s, _) => AnimatedContainer(
          duration: AppMotion.hover,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: s.active ? c.primaryContainer : c.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: onTap == null ? c.textTertiary : c.textPrimary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: onTap == null ? c.textTertiary : c.textPrimary)),
            ],
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;

  static const _rows = [
    ['AC', '()', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['000', '0', ',', '='],
  ];

  static const _labels = {'-': '−', '()': '( )', 'AC': 'AC'};
  static const _semantic = {
    'AC': 'Hapus semua',
    '()': 'Kurung',
    '%': 'Persen',
    '÷': 'Bagi',
    '×': 'Kali',
    '-': 'Kurang',
    '+': 'Tambah',
    '=': 'Sama dengan',
    ',': 'Koma desimal',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _Key(k: row[i], label: _labels[row[i]] ?? row[i], semantic: _semantic[row[i]] ?? row[i], onKey: onKey)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.k, required this.label, required this.semantic, required this.onKey});
  final String k;
  final String label;
  final String semantic;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isOp = const {'÷', '×', '-', '+'}.contains(k);
    final isEq = k == '=';
    final isFn = const {'AC', '()', '%'}.contains(k);
    final bg = isEq ? c.textPrimary : (isOp ? c.primaryContainer : (isFn ? c.surfaceAlt : c.surface));
    final fg = isEq ? c.surfaceAlt : (isOp ? c.primary : c.textPrimary);

    return Pressable(
      onTap: () => onKey(k),
      semanticLabel: semantic,
      hoverLift: 0,
      pressedScale: 0.92,
      borderRadius: BorderRadius.circular(16),
      builder: (context, s, _) => AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.standard,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.pressed ? Color.lerp(bg, fg, 0.12) : (s.hovered ? Color.lerp(bg, fg, 0.06) : bg),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isEq || isOp ? Colors.transparent : c.border),
        ),
        child: Text(
          label,
          style: AppTypography.numeric(size: k == '000' ? 18 : 22, weight: isOp || isEq ? FontWeight.w600 : FontWeight.w500, color: fg),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}
