import 'package:flutter/material.dart';

import '../core/calculations.dart';
import '../core/formatting.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 工具页：盈亏计算、仓位管理、关于。
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: const [
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        ProfitLossCard(),
        SizedBox(height: 16),
        PositionSizeCard(),
        SizedBox(height: 16),
        AboutCard(),
      ],
    );
  }
}

/// 盈亏计算（支持双边手续费率）。
class ProfitLossCard extends StatefulWidget {
  const ProfitLossCard({super.key});

  @override
  State<ProfitLossCard> createState() => _ProfitLossCardState();
}

class _ProfitLossCardState extends State<ProfitLossCard> {
  final _entry = TextEditingController();
  final _exit = TextEditingController();
  final _qty = TextEditingController();
  final _fee = TextEditingController();

  @override
  void dispose() {
    _entry.dispose();
    _exit.dispose();
    _qty.dispose();
    _fee.dispose();
    super.dispose();
  }

  double _p(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final entry = _p(_entry);
    final exit = _p(_exit);
    final qty = _p(_qty);
    final feeRate = _p(_fee);
    final valid = entry > 0 && qty > 0 && exit >= 0;

    return SectionCard(
      title: 'Profit / Loss',
      child: Column(
        children: [
          NumberField(
            label: 'Buy Price',
            controller: _entry,
            prefix: '\$ ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Sell Price',
            controller: _exit,
            prefix: '\$ ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Quantity',
            controller: _qty,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Fee Rate (round-trip, optional)',
            controller: _fee,
            suffix: '%',
            hint: '0.00',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          if (valid)
            _buildResult(calcProfitLoss(
              entry: entry,
              exit: exit,
              quantity: qty,
              feeRate: feeRate,
            ))
          else
            Text(
              'Enter buy price, sell price and quantity',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(ProfitLossResult r) {
    final isWin = r.amount >= 0;
    final color = pnlColor(r.amount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isWin ? Icons.arrow_upward : Icons.arrow_downward, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isWin ? 'Net Profit' : 'Net Loss',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                '${Format.signedMoney(r.amount)}（${Format.signedPercent(r.percent)}）',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (r.feeAmount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gross P&L',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  Format.signedMoney(r.grossAmount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pnlColor(r.grossAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Est. Fees',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  '-${Format.money(r.feeAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 仓位管理（支持最小交易单位取整）。
class PositionSizeCard extends StatefulWidget {
  const PositionSizeCard({super.key});

  @override
  State<PositionSizeCard> createState() => _PositionSizeCardState();
}

class _PositionSizeCardState extends State<PositionSizeCard> {
  final _account = TextEditingController();
  final _risk = TextEditingController();
  final _entry = TextEditingController();
  final _stop = TextEditingController();
  final _lot = TextEditingController();

  @override
  void dispose() {
    _account.dispose();
    _risk.dispose();
    _entry.dispose();
    _stop.dispose();
    _lot.dispose();
    super.dispose();
  }

  double _p(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final account = _p(_account);
    final risk = _p(_risk);
    final entry = _p(_entry);
    final stop = _p(_stop);
    final lot = _p(_lot);
    final valid = account > 0 && risk > 0 && entry > 0 && stop > 0 && stop != entry;

    return SectionCard(
      title: 'Position Sizing',
      child: Column(
        children: [
          NumberField(
            label: 'Account Size',
            controller: _account,
            prefix: '\$ ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Risk per Trade',
            controller: _risk,
            suffix: '%',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Entry Price',
            controller: _entry,
            prefix: '\$ ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Stop Loss',
            controller: _stop,
            prefix: '\$ ',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          NumberField(
            label: 'Lot Size (optional, stock 1 lot = 100)',
            controller: _lot,
            hint: '0',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          if (valid)
            _buildResult(
              calcPositionSize(
                accountSize: account,
                riskPercent: risk,
                entry: entry,
                stop: stop,
                lotSize: lot,
              ),
              entry,
            )
          else
            Text(
              'Enter account size, risk, entry and stop',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(PositionSizeResult r, double entry) {
    return Column(
      children: [
        ResultRow(label: 'Risk Amount', value: '\$${Format.money(r.riskAmount)}'),
        ResultRow(label: 'Risk per Unit', value: '\$${Format.price(r.riskPerUnit)}'),
        const Divider(height: 24),
        ResultRow(
          label: 'Suggested Position Size',
          value: Format.quantity(r.positionSize),
          valueColor: AppTheme.accent,
          valueSize: 22,
          emphasize: true,
        ),
        if (r.positionSize > 0)
          ResultRow(
            label: 'Suggested Investment',
            value: '\$${Format.money(r.positionSize * entry)}',
          ),
      ],
    );
  }
}

/// 关于与免责声明。
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'About CoinAOZX FS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A simple, intuitive asset calculator for average cost, take-profit/stop-loss and position sizing across stocks, crypto, tokens and more.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Version 1.0.0', style: _small),
              const SizedBox(width: 16),
              Text('Built with Flutter', style: _small),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Disclaimer: All results are for reference only and do not constitute investment advice. Investing involves risk; make independent decisions.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.amber.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _small => TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.45),
      );
}
