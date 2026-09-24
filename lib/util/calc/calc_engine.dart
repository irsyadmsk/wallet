/// Expression evaluator behind the amount calculator.
///
/// Grammar (precedence low → high):
///   expr   := term (('+' | '-') term)*
///   term   := unary (('×' | '÷') unary)*
///   unary  := '-' unary | postfix
///   postfix:= primary '%'?
///   primary:= number | '(' expr ')'
///
/// Percent follows phone-calculator rules so shopping maths reads
/// naturally: `a + b%` adds b percent *of a*, `a - b%` subtracts it, while
/// `a × b%` and a lone `b%` just mean b/100.
///
/// Numbers accept `.` as a thousands separator and `,` as the decimal
/// mark (Indonesian convention), e.g. `12.500,5`.
class CalcEngine {
  CalcEngine._(this._tokens);

  final List<String> _tokens;
  int _pos = 0;

  static const operators = {'+', '-', '×', '÷'};

  /// Evaluates [input]. Returns null when the expression is incomplete or
  /// invalid (e.g. trailing operator, unbalanced parentheses, ÷ 0).
  static double? evaluate(String input) {
    final tokens = tokenize(input);
    if (tokens == null || tokens.isEmpty) return null;
    final e = CalcEngine._(tokens);
    try {
      final (v, _) = e._expr();
      if (e._pos != tokens.length) return null;
      if (v.isNaN || v.isInfinite) return null;
      return v;
    } on FormatException {
      return null;
    }
  }

  /// Like [evaluate], but tolerant of what a user is still typing: drops a
  /// trailing operator and closes open parentheses, so a live preview can
  /// show "= 35.000" while "35.000 +" is on screen.
  static double? preview(String input) {
    var s = input.trimRight();
    while (s.isNotEmpty && (operators.contains(s[s.length - 1]) || s.endsWith('('))) {
      s = s.substring(0, s.length - 1).trimRight();
    }
    final open = '('.allMatches(s).length - ')'.allMatches(s).length;
    if (open > 0) s += ')' * open;
    return evaluate(s);
  }

  static List<String>? tokenize(String input) {
    final out = <String>[];
    final s = input.replaceAll(' ', '').replaceAll('*', '×').replaceAll('/', '÷').replaceAll('x', '×');
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (_isDigit(ch) || ch == ',' || ch == '.') {
        final start = i;
        while (i < s.length && (_isDigit(s[i]) || s[i] == ',' || s[i] == '.')) {
          i++;
        }
        out.add(s.substring(start, i));
        continue;
      }
      if ('+-×÷()%'.contains(ch)) {
        out.add(ch);
        i++;
        continue;
      }
      return null;
    }
    return out;
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  /// Parses an Indonesian-formatted number: dots group thousands, a comma
  /// marks decimals.
  static double? parseNumber(String raw) {
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    if ('.'.allMatches(normalized).length > 1) return null;
    if (normalized == '.') return null;
    return double.tryParse(normalized.startsWith('.') ? '0$normalized' : normalized);
  }

  String? get _peek => _pos < _tokens.length ? _tokens[_pos] : null;

  String _next() {
    if (_pos >= _tokens.length) throw const FormatException('unexpected end');
    return _tokens[_pos++];
  }

  // Returns (value, wasPercentLiteral).
  (double, bool) _expr() {
    var (left, leftPct) = _term();
    while (_peek == '+' || _peek == '-') {
      final op = _next();
      final (right, pct) = _term();
      final delta = pct ? left * right : right;
      left = op == '+' ? left + delta : left - delta;
      leftPct = false;
    }
    return (left, leftPct);
  }

  (double, bool) _term() {
    var (left, leftPct) = _unary();
    while (_peek == '×' || _peek == '÷') {
      final op = _next();
      final (right, _) = _unary();
      if (op == '×') {
        left = left * right;
      } else {
        if (right == 0) throw const FormatException('division by zero');
        left = left / right;
      }
      leftPct = false;
    }
    return (left, leftPct);
  }

  (double, bool) _unary() {
    if (_peek == '-') {
      _next();
      final (v, pct) = _unary();
      return (-v, pct);
    }
    if (_peek == '+') {
      _next();
      return _unary();
    }
    return _postfix();
  }

  (double, bool) _postfix() {
    final v = _primary();
    if (_peek == '%') {
      _next();
      return (v / 100, true);
    }
    return (v, false);
  }

  double _primary() {
    final t = _next();
    if (t == '(') {
      final (v, _) = _expr();
      if (_next() != ')') throw const FormatException('missing )');
      return v;
    }
    final n = parseNumber(t);
    if (n == null) throw FormatException('bad number $t');
    return n;
  }
}
