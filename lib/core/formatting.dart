import 'package:intl/intl.dart';

/// 统一的数字/货币格式化工具。
///
/// 针对股票、加密货币、代币等价格差异巨大的场景做了自适应：
/// - 大于等于 1000：千分位 + 2 位小数
/// - 1 到 1000：最多 4 位小数
/// - 小于 1：最多 8 位有效小数（自动去除末尾 0）
class Format {
  Format._();

  static final NumberFormat _grouped = NumberFormat('#,##0.##');

  /// 自适应数量格式化（用于数量）。
  static String quantity(double v, {int maxDecimals = 8}) {
    return _smart(v, maxDecimals: maxDecimals);
  }

  /// 自适应价格格式化。
  static String price(double v) {
    return _smart(v, maxDecimals: 8);
  }

  /// 金额格式化（保留 2 位小数 + 千分位）。
  static String money(double v) {
    if (v.isNaN || v.isInfinite) return '—';
    final neg = v < 0;
    final abs = v.abs();
    String s;
    if (abs >= 1) {
      s = NumberFormat('#,##0.00').format(abs);
    } else {
      s = _smart(abs, maxDecimals: 6);
    }
    return neg ? '-$s' : s;
  }

  /// 带符号的金额（+/-）。
  static String signedMoney(double v) {
    if (v.isNaN || v.isInfinite) return '—';
    final sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    return '$sign${money(v.abs())}';
  }

  /// 百分比。
  static String percent(double v, {int decimals = 2}) {
    if (v.isNaN || v.isInfinite) return '—';
    return '${NumberFormat('#,##0.${'#' * decimals}').format(v)}%';
  }

  /// 带符号百分比。
  static String signedPercent(double v, {int decimals = 2}) {
    if (v.isNaN || v.isInfinite) return '—';
    final sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    return '$sign${percent(v.abs(), decimals: decimals)}';
  }

  static String _smart(double v, {int maxDecimals = 8}) {
    if (v.isNaN || v.isInfinite) return '—';
    final neg = v < 0;
    final a = v.abs();
    String s;
    if (a >= 1000) {
      s = _grouped.format(a);
    } else if (a >= 1) {
      s = _trim(NumberFormat('#,##0.####').format(a));
    } else if (a == 0) {
      s = '0';
    } else {
      s = _trim(a.toStringAsFixed(maxDecimals));
    }
    return neg ? '-$s' : s;
  }

  static String _trim(String s) {
    if (!s.contains('.')) return s;
    var out = s;
    while (out.endsWith('0')) {
      out = out.substring(0, out.length - 1);
    }
    if (out.endsWith('.')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}
