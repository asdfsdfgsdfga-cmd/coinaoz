import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/calculations.dart';
import '../core/formatting.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 平均成本计算器。
class AverageCostScreen extends StatefulWidget {
  const AverageCostScreen({super.key});

  @override
  State<AverageCostScreen> createState() => _AverageCostScreenState();
}

class _AverageCostScreenState extends State<AverageCostScreen> {
  static const _prefsKey = 'avg_cost_asset';

  AssetType _assetType = AssetType.crypto;
  final _assetName = TextEditingController();
  final _currentPrice = TextEditingController();
  final List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      // 用简单分隔符存储：type|name|currentPrice|price,qty;price,qty;...
      final parts = raw.split('|');
      final typeIndex = int.tryParse(parts[0]) ?? 2;
      final safeTypeIndex =
          (typeIndex < 0 || typeIndex >= AssetType.values.length) ? 2 : typeIndex;
      final name = parts.length > 1 ? parts[1] : '';
      final current = parts.length > 2 ? parts[2] : '';
      final txsRaw = parts.length > 3 ? parts[3] : '';
      if (!mounted) return;
      setState(() {
        _assetType = AssetType.values[safeTypeIndex];
        _assetName.text = name;
        _currentPrice.text = current;
        _transactions.clear();
        if (txsRaw.isNotEmpty) {
          for (final chunk in txsRaw.split(';')) {
            final kv = chunk.split(',');
            if (kv.length >= 2) {
              final p = double.tryParse(kv[0]);
              final q = double.tryParse(kv[1]);
              if (p != null && q != null) {
                _transactions.add(Transaction(price: p, quantity: q));
              }
            }
          }
        }
      });
    } catch (_) {
      // 忽略损坏数据
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final txs = _transactions
        .map((t) => '${t.price},${t.quantity}')
        .join(';');
    await prefs.setString(
      _prefsKey,
      '${_assetType.index}|${_assetName.text}|${_currentPrice.text}|$txs',
    );
  }

  void _addTransaction() {
    final priceCtl = TextEditingController();
    final qtyCtl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Buy Record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              NumberField(
                label: 'Buy Price',
                controller: priceCtl,
                prefix: '\$ ',
                autofocus: true,
              ),
              const SizedBox(height: 14),
              NumberField(
                label: 'Quantity (${_assetType.unitLabel})',
                controller: qtyCtl,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final p = double.tryParse(priceCtl.text.trim());
                  final q = double.tryParse(qtyCtl.text.trim());
                  if (p == null || q == null || p <= 0 || q <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid price and quantity')),
                    );
                    return;
                  }
                  setState(() {
                    _transactions.add(Transaction(price: p, quantity: q));
                  });
                  _save();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearAll() {
    if (_transactions.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Records'),
        content: const Text('Delete all buy records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _transactions.clear();
                _currentPrice.clear();
              });
              _save();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.loss)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _assetName.dispose();
    _currentPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = calcAverageCost(_transactions);
    final currentPrice = double.tryParse(_currentPrice.text.trim());
    final hasData = _transactions.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Average Cost',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (hasData)
              IconButton(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear',
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 资产类型
        const _Label('Asset Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AssetType.values.map((t) {
              final selected = t == _assetType;
              return ChoiceChip(
                label: Text(t.label),
                avatar: Icon(
                  t.icon,
                  size: 16,
                  color: selected ? AppTheme.accent : Colors.white70,
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() => _assetType = t);
                  _save();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 资产名称
          _Label('Asset Name (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _assetName,
            onChanged: (_) => _save(),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'e.g. BTC / AAPL'),
          ),
          const SizedBox(height: 20),

          // 结果
          SectionCard(
            title: 'Result',
            child: Column(
              children: [
                ResultRow(
                  label: 'Total Cost',
                  value: '\$${Format.money(result.totalCost)}',
                ),
                ResultRow(
                  label: 'Total Quantity',
                  value: '${Format.quantity(result.totalQuantity)} ${_assetType.unitLabel}',
                ),
                const Divider(height: 24),
                ResultRow(
                  label: 'Average Cost',
                  value: '\$${Format.price(result.averagePrice)}',
                  valueColor: AppTheme.accent,
                  valueSize: 22,
                  emphasize: true,
                ),
                if (currentPrice != null && currentPrice > 0 && hasData) ...[
                  const Divider(height: 24),
                  _PnLBlock(
                    currentPrice: currentPrice,
                    avgPrice: result.averagePrice,
                    quantity: result.totalQuantity,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 当前价格
          _Label('Current Price (optional, for P&L)'),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPrice,
            onChanged: (_) {
              setState(() {});
              _save();
            },
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: 20),

          // 买入记录
          Row(
            children: [
              const Expanded(
                child: _Label('Buy Records'),
              ),
              if (hasData)
                TextButton.icon(
                  onPressed: _addTransaction,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasData)
            _EmptyTransactions(onAdd: _addTransaction)
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _transactions.length; i++)
                    _TransactionTile(
                      index: i,
                      tx: _transactions[i],
                      unit: _assetType.unitLabel,
                      onDelete: () {
                        setState(() => _transactions.removeAt(i));
                        _save();
                      },
                    ),
                ],
              ),
            ),
        ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

class _PnLBlock extends StatelessWidget {
  final double currentPrice;
  final double avgPrice;
  final double quantity;

  const _PnLBlock({
    required this.currentPrice,
    required this.avgPrice,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final marketValue = currentPrice * quantity;
    final pnl = (currentPrice - avgPrice) * quantity;
    final pct = avgPrice > 0 ? (currentPrice - avgPrice) / avgPrice * 100 : 0.0;
    return Column(
      children: [
        ResultRow(
          label: 'Market Value',
          value: '\$${Format.money(marketValue)}',
        ),
        ResultRow(
          label: 'Unrealized P&L',
          value:
              '\$${Format.signedMoney(pnl)}（${Format.signedPercent(pct)}）',
          valueColor: pnlColor(pnl),
          emphasize: true,
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTransactions({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.white.withValues(alpha: 0.4),
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'No buy records yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final int index;
  final Transaction tx;
  final String unit;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.index,
    required this.tx,
    required this.unit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${Format.price(tx.price)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Format.quantity(tx.quantity)} $unit',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${Format.money(tx.price * tx.quantity)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.close,
              size: 18,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
