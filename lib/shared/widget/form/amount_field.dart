import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:financial_recording/data/services/currency/currency.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_typography.dart';
import 'package:financial_recording/shared/widget/calculator_dialog.dart';
import 'package:financial_recording/util/thousands_formatter/thousands_formatter.dart';

/// Rupiah amount input used by every money form.
///
/// - digits are grouped while typing ("1.250.000") and the caret stays put
///   when editing the middle;
/// - a line under the field reads the amount back in words ("1,25 juta"),
///   so a missing or extra zero is obvious;
/// - quick chips add common amounts or append "000" without retyping;
/// - the calculator (sums, splits, discounts) is one tap away.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Jumlah',
    this.large = false,
    this.autofocus = false,
    this.allowNegative = false,
    this.showQuickChips = true,
    this.showCalculator = true,
    this.accent,
    this.helper,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.currency = Currency.idr,
  });

  /// Currency code of the amount ([Currency.all]); decides the prefix and how
  /// many decimals can be typed. [value] is in that currency's smallest unit.
  final String currency;

  final int value;
  final ValueChanged<int> onChanged;
  final String label;

  /// Hero style for the main amount of a form.
  final bool large;
  final bool autofocus;
  final bool allowNegative;
  final bool showQuickChips;
  final bool showCalculator;

  /// Colour of the typed amount (e.g. red for an expense) in [large] mode.
  final Color? accent;
  final String? helper;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<int>? onSubmitted;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller = TextEditingController(text: _format(widget.value));
  Currency get _cur => Currency.of(widget.currency);
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late ThousandsFormatter _formatter = _makeFormatter();

  ThousandsFormatter _makeFormatter() => ThousandsFormatter(allowNegative: widget.allowNegative, decimals: _cur.decimals);

  static const _quickAdds = [10000, 20000, 50000, 100000];

  String _format(int v) => v == 0 ? '' : formatAmount(v, decimals: Currency.of(widget.currency).decimals);
  int get _current => parseAmount(_controller.text, decimals: _cur.decimals, allowNegative: widget.allowNegative);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AmountField old) {
    super.didUpdateWidget(old);
    if (old.currency != widget.currency) {
      // Switching account currency: same number, new unit rules.
      _formatter = _makeFormatter();
      _set(widget.value, notify: false);
      return;
    }
    // A value pushed in from outside (OCR, calculator, a suggestion chip).
    if (widget.value != _current) _set(widget.value, notify: false);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  void _set(int v, {bool notify = true}) {
    final text = _format(v);
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    if (notify) widget.onChanged(v);
    setState(() {});
  }

  Future<void> _openCalculator() async {
    final result = await CalculatorDialog.show(context, initial: _current);
    if (result != null && (result >= 0 || widget.allowNegative)) _set(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = _current;
    final idr = _cur.isRupiah;
    final words = idr ? amountInWords(value) : '';
    final large = widget.large;
    final textColor = large && value != 0 ? (widget.accent ?? c.textPrimary) : c.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.numberWithOptions(signed: widget.allowNegative, decimal: _cur.decimals > 0),
            textInputAction: widget.textInputAction,
            inputFormatters: [_formatter],
            // Keep the chips and the read-back line above the keyboard too.
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            style: large
                ? AppTypography.numeric(size: 30, weight: FontWeight.w600, color: textColor)
                : AppTypography.numeric(size: 16, weight: FontWeight.w500, color: textColor),
            onChanged: (_) {
              widget.onChanged(_current);
              setState(() {});
            },
            onSubmitted: (_) => widget.onSubmitted?.call(_current),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: '0',
              prefixText: _cur.isGold ? null : '${_cur.symbol} ',
              suffixText: _cur.isGold ? 'gram' : null,
              prefixStyle: large
                  ? AppTypography.numeric(size: 20, weight: FontWeight.w500, color: c.textSecondary)
                  : TextStyle(color: c.textSecondary),
              contentPadding: large ? const EdgeInsets.fromLTRB(16, 22, 8, 18) : null,
              floatingLabelBehavior: large ? FloatingLabelBehavior.always : null,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != 0 && _focus.hasFocus)
                    IconButton(
                      tooltip: 'Kosongkan',
                      icon: Icon(Icons.backspace_outlined, size: 20, color: c.textTertiary),
                      onPressed: () => _set(0),
                    ),
                  if (widget.showCalculator && idr)
                    IconButton(
                      tooltip: 'Kalkulator',
                      icon: Icon(Icons.calculate_outlined, color: c.primary),
                      onPressed: _openCalculator,
                    ),
                ],
              ),
            ),
          ),
          if (words.isNotEmpty || widget.helper != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
              child: Text(
                [if (words.isNotEmpty) words, if (widget.helper != null) widget.helper!].join(' · '),
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ),
          if (widget.showQuickChips && idr && (large || _focus.hasFocus))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(
                      label: '000',
                      tooltip: 'Tambah tiga nol',
                      onTap: value == 0 || value.abs() >= 1000000000000 ? null : () => _set(value * 1000),
                    ),
                    for (final a in _quickAdds)
                      _Chip(label: '+${_short(a)}', tooltip: 'Tambah ${formatThousands(a)}', onTap: () => _set(value + a)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _short(int v) => v >= 1000000 ? '${v ~/ 1000000}jt' : '${v ~/ 1000}rb';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, required this.tooltip});
  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: tooltip,
          child: ActionChip(
            label: Text(label, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
            visualDensity: VisualDensity.compact,
            onPressed: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
          ),
        ),
      );
}

/// Reads an amount back the way people say it: 1500000 → "1,5 juta",
/// 250000 → "250 ribu", 2000000000 → "2 miliar". Empty below 1.000.
String amountInWords(int value) {
  final v = value.abs();
  if (v < 1000) return '';
  final sign = value < 0 ? 'minus ' : '';
  const units = [(1000000000000, 'triliun'), (1000000000, 'miliar'), (1000000, 'juta'), (1000, 'ribu')];
  final (unit, name) = units.firstWhere((u) => v >= u.$1);
  final x = v / unit;
  var s = x.toStringAsFixed(x >= 100 ? 0 : (x >= 10 ? 1 : 2));
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  // Rounded for reading; flag it so "≈ 1,25 juta" isn't taken as exact.
  final approx = (double.parse(s) * unit).round() != v ? '≈ ' : '';
  return '$approx$sign${s.replaceAll('.', ',')} $name';
}
