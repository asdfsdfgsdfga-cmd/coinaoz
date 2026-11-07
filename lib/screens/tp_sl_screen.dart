import 'package:flutter/material.dart';

import '../core/calculations.dart';
import '../core/formatting.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 止盈止损计算器。
class TpSlScreen extends StatefulWidget {
  const TpSlScreen({super.key});

  @override
  State<TpSlScreen> createState() => _TpSlScreenState();
}

class _TpSlScreenState extends State<TpSlScreen> {
  final _entry = TextEditingController();
  final _quantity = TextEditingController();
  final _tpValue = TextEditingController();
  final _slValue = TextEditingController();

  bool _tpByPrice = true;
  bool _slByPrice = true;

  @override
  void dispose() {
    _entry.dispose();
    _quantity.dispose();
    _tpValue.dispose();
    _slValue.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final entry = _parse(_entry);
    final quantity = _parse(_quantity);
    final tpInput = _parse(_tpValue);
    final slInput = _parse(_slValue);

    final tpPrice =
        _tpByPrice ? tpInput : entry * (1 + tpInput / 100);
    final slPrice =
        _slByPrice ? slInput : entry * (1 - slInput / 100);

    final valid = entry > 0 && quantity > 0;
    final tpValid = tpPrice > entry;
    final slValid = slPrice > 0 && slPrice < entry;

    TpSlResult? result;
    if (valid && tpValid && slValid) {
      result = calcTpSl(
        entry: entry,
        quantity: quantity,
        tpPrice: tpPrice,
        slPrice: slPrice,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Take Profit / Stop Loss',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SectionCard(
          title: 'Position',
            child: Column(
              children: [
                NumberField(
                  label: 'Cost / Entry Price',
                  controller: _entry,
                  prefix: '\$ ',
                  autofocus: true,
                ),
                const SizedBox(height: 14),
                NumberField(label: 'Quantity', controller: _quantity),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Take Profit',
            child: Column(
              children: [
                _ModeToggle(
                  byPrice: _tpByPrice,
                  onChanged: (v) => setState(() => _tpByPrice = v),
                ),
                const SizedBox(height: 12),
                NumberField(
                  label: _tpByPrice ? 'TP Price' : 'TP (%)',
                  controller: _tpValue,
                  prefix: _tpByPrice ? '\$ ' : null,
                  suffix: _tpByPrice ? null : '%',
                ),
                if (entry > 0 && tpInput > 0) ...[
                  const SizedBox(height: 10),
                  _Hint(
                    text: 'TP price: \$${Format.price(tpPrice)}',
                    ok: tpValid,
                    error: tpValid ? null : 'TP must be above entry',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Stop Loss',
            child: Column(
              children: [
                _ModeToggle(
                  byPrice: _slByPrice,
                  onChanged: (v) => setState(() => _slByPrice = v),
                ),
                const SizedBox(height: 12),
                NumberField(
                  label: _slByPrice ? 'SL Price' : 'SL (%)',
                  controller: _slValue,
                  prefix: _slByPrice ? '\$ ' : null,
                  suffix: _slByPrice ? null : '%',
                ),
                if (entry > 0 && slInput > 0) ...[
                  const SizedBox(height: 10),
                  _Hint(
                    text: 'SL price: \$${Format.price(slPrice)}',
                    ok: slValid,
                    error: slValid ? null : 'SL must be below entry and above 0',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Result',
            child: result == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Enter valid position, TP and SL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ResultRow(
                        label: 'TP Price',
                        value: '\$${Format.price(result.tpPrice)}',
                        valueColor: AppTheme.profit,
                      ),
                      ResultRow(
                        label: 'SL Price',
                        value: '\$${Format.price(result.slPrice)}',
                        valueColor: AppTheme.loss,
                      ),
                      const Divider(height: 24),
                      ResultRow(
                        label: 'Profit at TP',
                        value: '+\$${Format.money(result.profitAmount)}',
                        valueColor: AppTheme.profit,
                      ),
                      ResultRow(
                        label: 'Loss at SL',
                        value: '-\$${Format.money(result.lossAmount)}',
                        valueColor: AppTheme.loss,
                      ),
                      const Divider(height: 24),
                      ResultRow(
                        label: 'Risk / Reward Ratio',
                        value: '1 : ${Format.quantity(result.riskRewardRatio)}',
                        valueColor: AppTheme.accent,
                        valueSize: 20,
                        emphasize: true,
                      ),
                      const SizedBox(height: 8),
                      _RatioBar(ratio: result.riskRewardRatio),
                    ],
                  ),
          ),
        ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool byPrice;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.byPrice, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('By Price'),
          selected: byPrice,
          onSelected: (_) => onChanged(true),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('By Percent'),
          selected: !byPrice,
          onSelected: (_) => onChanged(false),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final bool ok;
  final String? error;

  const _Hint({required this.text, required this.ok, this.error});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTheme.profit : AppTheme.loss;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.error_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            error ?? text,
            style: TextStyle(
              fontSize: 12.5,
              color: ok ? Colors.white.withValues(alpha: 0.7) : color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatioBar extends StatelessWidget {
  final double ratio;

  const _RatioBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    // 盈亏比 >= 1 时显示绿色，< 1 显示红色。
    final r = ratio.clamp(0.0, 3.0).toDouble();
    final fill = (r / 3.0).clamp(0.0, 1.0);
    final good = ratio >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              good ? AppTheme.profit : AppTheme.loss,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          good ? 'R/R ≥ 1 — favorable' : 'R/R < 1 — adjust TP/SL',
          style: TextStyle(
            fontSize: 12,
            color: (good ? AppTheme.profit : AppTheme.loss)
                .withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
