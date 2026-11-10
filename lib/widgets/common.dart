import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// 数字输入框（带标题、前缀/后缀）。
class NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final String? hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const NumberField({
    super.key,
    required this.label,
    required this.controller,
    this.prefix,
    this.suffix,
    this.hint,
    this.autofocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: prefix,
            suffixText: suffix,
            hintText: hint ?? '0.00',
          ),
        ),
      ],
    );
  }
}

/// 带标题的分区卡片。
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (trailing != null) ?trailing,
                ],
              ),
            if (title != null) const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// 结果行（标签 + 值）。
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double valueSize;
  final bool emphasize;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueSize = 16,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 涨跌用颜色。
Color pnlColor(double v) => v >= 0 ? AppTheme.profit : AppTheme.loss;
