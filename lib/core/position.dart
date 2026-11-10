import 'calculations.dart';

/// 一条持仓记录（本地保存，可包含多笔买入）。
class Position {
  final String id;
  AssetType type;
  String name;
  double? currentPrice;
  List<Transaction> transactions;
  double? takeProfitTarget;
  double? stopLossTarget;
  DateTime? reminderAt;
  DateTime updatedAt;

  Position({
    required this.id,
    required this.type,
    required this.name,
    required this.transactions,
    this.currentPrice,
    this.takeProfitTarget,
    this.stopLossTarget,
    this.reminderAt,
    required this.updatedAt,
  });

  AverageCostResult get result => calcAverageCost(transactions);

  double get quantity => result.totalQuantity;

  double get averageCost => result.averagePrice;

  double? get marketValue =>
      currentPrice != null && quantity > 0 ? currentPrice! * quantity : null;

  double? get pnlAmount {
    if (currentPrice == null || quantity <= 0 || averageCost <= 0) return null;
    return (currentPrice! - averageCost) * quantity;
  }

  double? get pnlPercent {
    if (currentPrice == null || averageCost <= 0) return null;
    return (currentPrice! - averageCost) / averageCost * 100;
  }

  /// 止盈目标是否已被当前价触及。
  bool? get tpTargetHit {
    if (currentPrice == null || takeProfitTarget == null) return null;
    return currentPrice! >= takeProfitTarget!;
  }

  /// 止损目标是否已被当前价触及。
  bool? get slTargetHit {
    if (currentPrice == null || stopLossTarget == null) return null;
    return currentPrice! <= stopLossTarget!;
  }

  Position copyWith({
    AssetType? type,
    String? name,
    double? currentPrice,
    List<Transaction>? transactions,
    double? takeProfitTarget,
    double? stopLossTarget,
    DateTime? reminderAt,
    DateTime? updatedAt,
  }) {
    return Position(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      transactions: transactions ?? this.transactions,
      currentPrice: currentPrice ?? this.currentPrice,
      takeProfitTarget: takeProfitTarget ?? this.takeProfitTarget,
      stopLossTarget: stopLossTarget ?? this.stopLossTarget,
      reminderAt: reminderAt ?? this.reminderAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'currentPrice': currentPrice,
        'takeProfitTarget': takeProfitTarget,
        'stopLossTarget': stopLossTarget,
        'reminderAt': reminderAt?.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Position.fromJson(Map<String, dynamic> json) {
    final txsRaw = (json['transactions'] as List? ?? []);
    return Position(
      id: json['id'] as String? ?? '',
      type: AssetType.values[
          ((json['type'] as num?) ?? 2).toInt().clamp(0, AssetType.values.length - 1)],
      name: json['name'] as String? ?? '',
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      takeProfitTarget: (json['takeProfitTarget'] as num?)?.toDouble(),
      stopLossTarget: (json['stopLossTarget'] as num?)?.toDouble(),
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['reminderAt'] as int),
      updatedAt: json['updatedAt'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      transactions: txsRaw
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
