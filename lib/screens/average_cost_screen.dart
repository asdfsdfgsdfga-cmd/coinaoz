import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/calculations.dart';
import '../core/formatting.dart';
import '../core/position.dart';
import '../core/positions_store.dart';
import '../core/reminder_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'positions_screen.dart';

/// 平均成本计算器：编辑当前选中的本地持仓。
class AverageCostScreen extends StatefulWidget {
  const AverageCostScreen({super.key});

  @override
  State<AverageCostScreen> createState() => _AverageCostScreenState();
}

class _AverageCostScreenState extends State<AverageCostScreen> {
  static const _selectedKey = 'avg_cost_selected';

  List<Position> _positions = [];
  Position? _active;

  final _assetName = TextEditingController();
  final _currentPrice = TextEditingController();
  final _tpTarget = TextEditingController();
  final _slTarget = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _assetName.dispose();
    _currentPrice.dispose();
    _tpTarget.dispose();
    _slTarget.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _positions = await PositionsStore.load();
    if (_positions.isEmpty) {
      _active = PositionsStore.createBlank();
      _positions = [_active!];
    } else {
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString(_selectedKey);
      _active = _positions.firstWhere(
        (p) => p.id == selectedId,
        orElse: () => _positions.first,
      );
    }
    _syncControllers();
    await _persist();
    if (mounted) setState(() {});
  }

  void _syncControllers() {
    final a = _active;
    if (a == null) return;
    _assetName.text = a.name;
    _currentPrice.text = a.currentPrice == null ? '' : a.currentPrice.toString();
    _tpTarget.text = a.takeProfitTarget == null ? '' : a.takeProfitTarget.toString();
    _slTarget.text = a.stopLossTarget == null ? '' : a.stopLossTarget.toString();
  }

  /// 把控制器与交易记录回写到当前持仓并落盘。
  Future<void> _persist() async {
    final a = _active;
    if (a == null) return;
    final current = double.tryParse(_currentPrice.text.trim());
    final tp = double.tryParse(_tpTarget.text.trim());
    final sl = double.tryParse(_slTarget.text.trim());
    final updated = Position(
      id: a.id,
      type: a.type,
      name: _assetName.text.trim(),
      transactions: a.transactions,
      currentPrice: current,
      takeProfitTarget: tp,
      stopLossTarget: sl,
      reminderAt: a.reminderAt,
      updatedAt: DateTime.now(),
    );
    final index = _positions.indexWhere((p) => p.id == a.id);
    if (index >= 0) {
      _positions[index] = updated;
    } else {
      _positions.add(updated);
    }
    _active = updated;
    await PositionsStore.save(_positions);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, updated.id);
    await ReminderService.instance.sync(updated);
  }

  Future<void> _pickReminder() async {
    final a = _active;
    if (a == null) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: a.reminderAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(a.reminderAt ?? now),
    );
    if (time == null || !mounted) return;
    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _active = a.copyWith(reminderAt: when));
    await _persist();
  }

  Future<void> _clearReminder() async {
    final a = _active;
    if (a == null) return;
    setState(() => _active = Position(
      id: a.id,
      type: a.type,
      name: a.name,
      transactions: a.transactions,
      currentPrice: a.currentPrice,
      takeProfitTarget: a.takeProfitTarget,
      stopLossTarget: a.stopLossTarget,
      reminderAt: null,
      updatedAt: DateTime.now(),
    ));
    await _persist();
  }

  Future<void> _openPositions() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PositionsScreen(
          onSelected: (position) async {
            setState(() => _active = position);
            _syncControllers();
            await _persist();
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
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
                label: 'Quantity (${_active!.type.unitLabel})',
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
                  setState(() => _active!.transactions
                      .add(Transaction(price: p, quantity: q, time: DateTime.now())));
                  _persist();
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
    final a = _active;
    if (a == null || a.transactions.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Records'),
        content: const Text('Delete all buy records for this position?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _active!.transactions.clear();
                _currentPrice.clear();
              });
              _persist();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.loss)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _active;
    if (a == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final result = a.result;
    final currentPrice = a.currentPrice;
    final hasData = a.transactions.isNotEmpty;

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
            IconButton(
              tooltip: 'Positions',
              onPressed: _openPositions,
              icon: const Icon(Icons.account_balance_wallet_outlined),
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
            final selected = t == a.type;
            return ChoiceChip(
              label: Text(t.label),
              avatar: Icon(t.icon, size: 16, color: selected ? AppTheme.accent : Colors.white70),
              selected: selected,
              onSelected: (_) {
                setState(() => _active = a.copyWith(type: t));
                _persist();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 资产名称
        const _Label('Asset Name (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _assetName,
          onChanged: (_) => _persist(),
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
                value: '${Format.quantity(result.totalQuantity)} ${a.type.unitLabel}',
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
        const _Label('Current Price (optional, for P&L)'),
        const SizedBox(height: 8),
        TextField(
          controller: _currentPrice,
          onChanged: (_) {
            setState(() {});
            _persist();
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: '0.00',
          ),
        ),
        const SizedBox(height: 20),

        // 目标价
        SectionCard(
          title: 'Price Targets (optional)',
          child: Column(
            children: [
              NumberField(
                label: 'Take-Profit Target',
                controller: _tpTarget,
                prefix: '\$ ',
                onChanged: (_) => _persist(),
              ),
              const SizedBox(height: 14),
              NumberField(
                label: 'Stop-Loss Target',
                controller: _slTarget,
                prefix: '\$ ',
                onChanged: (_) => _persist(),
              ),
              const SizedBox(height: 10),
              _TargetStatus(position: a),
              const SizedBox(height: 12),
              _ReminderRow(
                reminderAt: a.reminderAt,
                onPick: _pickReminder,
                onClear: _clearReminder,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 买入记录
        Row(
          children: [
            const Expanded(child: _Label('Buy Records')),
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
                for (var i = 0; i < a.transactions.length; i++)
                  _TransactionTile(
                    index: i,
                    tx: a.transactions[i],
                    unit: a.type.unitLabel,
                    onDelete: () {
                      setState(() => a.transactions.removeAt(i));
                      _persist();
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

class _TargetStatus extends StatelessWidget {
  final Position position;

  const _TargetStatus({required this.position});

  @override
  Widget build(BuildContext context) {
    final current = position.currentPrice;
    if (current == null) {
      return Text(
        'Enter a current price to check target status.',
        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.5)),
      );
    }
    final lines = <Widget>[];
    if (position.takeProfitTarget != null) {
      final hit = position.tpTargetHit!;
      lines.add(_StatusLine(
        icon: hit ? Icons.check_circle : Icons.trending_up,
        color: AppTheme.profit,
        text: hit
            ? 'Take-profit target reached'
            : 'Take-profit target not reached yet',
      ));
    }
    if (position.stopLossTarget != null) {
      final hit = position.slTargetHit!;
      lines.add(_StatusLine(
        icon: hit ? Icons.check_circle : Icons.trending_down,
        color: AppTheme.loss,
        text: hit
            ? 'Stop-loss target reached'
            : 'Stop-loss target not reached yet',
      ));
    }
    if (lines.isEmpty) {
      return Text(
        'Set a take-profit or stop-loss target above.',
        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.5)),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines);
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusLine({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: color)),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final DateTime? reminderAt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ReminderRow({
    required this.reminderAt,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final when = reminderAt;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.alarm, size: 16, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                when == null
                    ? 'No reminder set'
                    : DateFormat('MMM d, HH:mm').format(when),
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        if (when != null)
          TextButton(onPressed: onClear, child: const Text('Remove')),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.alarm_add, size: 18),
          label: Text(when == null ? 'Set' : 'Change'),
        ),
      ],
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
          value: '\$${Format.signedMoney(pnl)}（${Format.signedPercent(pct)}）',
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
            icon: Icon(Icons.close, size: 18, color: Colors.white.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}
