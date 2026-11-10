import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../core/position.dart';
import '../core/positions_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 持仓列表：查看、切换、删除本地保存的持仓。
class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key, required this.onSelected});

  /// 选中某条持仓后回调（由父级设为当前持仓并关闭本页）。
  final ValueChanged<Position> onSelected;

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  List<Position> _positions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await PositionsStore.load();
    if (!mounted) return;
    setState(() {
      _positions = list;
      _loading = false;
    });
  }

  Future<void> _addNew() async {
    final blank = PositionsStore.createBlank();
    _positions = [..._positions, blank];
    await PositionsStore.save(_positions);
    if (!mounted) return;
    widget.onSelected(blank);
  }

  Future<void> _delete(Position position) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Position'),
        content: Text('Remove "${position.name.isEmpty ? 'Untitled' : position.name}" and its records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.loss)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _positions = _positions.where((p) => p.id != position.id).toList();
    await PositionsStore.save(_positions);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        actions: [
          IconButton(
            tooltip: 'New position',
            onPressed: _addNew,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _positions.isEmpty
              ? _Empty(onAdd: _addNew)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    for (final p in _positions) _PositionCard(
                      position: p,
                      onTap: () => widget.onSelected(p),
                      onDelete: () => _delete(p),
                    ),
                  ],
                ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final Position position;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PositionCard({
    required this.position,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final result = position.result;
    final pnl = position.pnlAmount;
    final pct = position.pnlPercent;
    final label = position.name.isEmpty ? 'Untitled' : position.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(position.type.icon, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      position.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ResultRow(
                        label: 'Avg Cost',
                        value: '\$${Format.price(result.averagePrice)}',
                      ),
                    ),
                    Expanded(
                      child: ResultRow(
                        label: 'Quantity',
                        value: '${Format.quantity(result.totalQuantity)} ${position.type.unitLabel}',
                      ),
                    ),
                  ],
                ),
                if (pnl != null && pct != null)
                  ResultRow(
                    label: 'Unrealized P&L',
                    value:
                        '\$${Format.signedMoney(pnl)}（${Format.signedPercent(pct)}）',
                    valueColor: pnlColor(pnl),
                    emphasize: true,
                  ),
                if (position.takeProfitTarget != null ||
                    position.stopLossTarget != null)
                  _TargetRow(position: position),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final Position position;

  const _TargetRow({required this.position});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (position.takeProfitTarget != null) {
      final hit = position.tpTargetHit;
      chips.add(_Chip(
        label: 'TP \$${Format.price(position.takeProfitTarget!)}',
        hit: hit,
        activeColor: AppTheme.profit,
      ));
    }
    if (position.stopLossTarget != null) {
      final hit = position.slTargetHit;
      chips.add(_Chip(
        label: 'SL \$${Format.price(position.stopLossTarget!)}',
        hit: hit,
        activeColor: AppTheme.loss,
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 8, children: chips),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool? hit;
  final Color activeColor;

  const _Chip({required this.label, required this.hit, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final color = hit == null
        ? Colors.white.withValues(alpha: 0.4)
        : hit!
            ? activeColor
            : Colors.white.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hit == true ? Icons.check_circle : Icons.circle_outlined,
              size: 13, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;

  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white.withValues(alpha: 0.4), size: 44),
            const SizedBox(height: 12),
            Text(
              'No saved positions yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Position'),
            ),
          ],
        ),
      ),
    );
  }
}
