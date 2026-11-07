import 'package:flutter/material.dart';

/// 支持的资产类型。
enum AssetType {
  stock,
  crypto,
  token,
  other;

  String get label {
    switch (this) {
      case AssetType.stock:
        return 'Stock';
      case AssetType.crypto:
        return 'Crypto';
      case AssetType.token:
        return 'Token';
      case AssetType.other:
        return 'Other';
    }
  }

  /// 数量单位名称。
  String get unitLabel {
    switch (this) {
      case AssetType.stock:
        return 'shares';
      case AssetType.crypto:
        return 'coins';
      case AssetType.token:
        return 'units';
      case AssetType.other:
        return 'units';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetType.stock:
        return Icons.trending_up;
      case AssetType.crypto:
        return Icons.currency_bitcoin;
      case AssetType.token:
        return Icons.token;
      case AssetType.other:
        return Icons.category;
    }
  }
}

/// 一笔买入/持有记录。
class Transaction {
  final double price;
  final double quantity;
  final DateTime? time;

  const Transaction({
    required this.price,
    required this.quantity,
    this.time,
  });

  Map<String, dynamic> toJson() => {
        'price': price,
        'quantity': quantity,
        'time': time?.millisecondsSinceEpoch,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        time: json['time'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
      );
}

/// 平均成本计算结果。
class AverageCostResult {
  final double totalCost;
  final double totalQuantity;
  final double averagePrice;

  const AverageCostResult({
    required this.totalCost,
    required this.totalQuantity,
    required this.averagePrice,
  });
}

/// 计算加权平均成本。
///
/// 平均价 = Σ(price × quantity) / Σ(quantity)。
/// 传入的记录中 quantity 必须为正数（买入）。
AverageCostResult calcAverageCost(List<Transaction> transactions) {
  double cost = 0;
  double qty = 0;
  for (final t in transactions) {
    if (t.quantity <= 0) continue;
    cost += t.price * t.quantity;
    qty += t.quantity;
  }
  final avg = qty > 0 ? cost / qty : 0.0;
  return AverageCostResult(totalCost: cost, totalQuantity: qty, averagePrice: avg);
}

/// 止盈止损计算结果。
class TpSlResult {
  final double tpPrice; // 止盈价（绝对价）
  final double slPrice; // 止损价（绝对价）
  final double profitAmount; // 到止盈价的盈利
  final double lossAmount; // 到止损价的亏损（正值）
  final double riskRewardRatio; // 盈亏比

  const TpSlResult({
    required this.tpPrice,
    required this.slPrice,
    required this.profitAmount,
    required this.lossAmount,
    required this.riskRewardRatio,
  });
}

/// 计算止盈止损。
///
/// [entry] 成本/入场价，[quantity] 数量，[tpPrice] 止盈价，[slPrice] 止损价。
TpSlResult calcTpSl({
  required double entry,
  required double quantity,
  required double tpPrice,
  required double slPrice,
}) {
  final profit = (tpPrice - entry) * quantity;
  final loss = (entry - slPrice) * quantity;
  final ratio = loss > 0 ? (profit / loss).abs() : 0.0;
  return TpSlResult(
    tpPrice: tpPrice,
    slPrice: slPrice,
    profitAmount: profit,
    lossAmount: loss.abs(),
    riskRewardRatio: ratio,
  );
}

/// 单笔盈亏结果。
class ProfitLossResult {
  final double grossAmount; // 毛盈亏（未扣除手续费）
  final double feeAmount; // 估算手续费（双边）
  final double amount; // 净盈亏
  final double percent; // 净收益率

  const ProfitLossResult({
    required this.grossAmount,
    required this.feeAmount,
    required this.amount,
    required this.percent,
  });
}

/// 计算单笔盈亏（可含双边手续费率）。
///
/// [feeRate] 双边手续费率（百分比），默认 0（不计手续费）。
ProfitLossResult calcProfitLoss({
  required double entry,
  required double exit,
  required double quantity,
  double feeRate = 0,
}) {
  final gross = (exit - entry) * quantity;
  final turnover = (entry + exit) * quantity;
  final fee = turnover * feeRate / 100;
  final amount = gross - fee;
  final cost = entry * quantity;
  final percent = cost > 0 ? amount / cost * 100 : 0.0;
  return ProfitLossResult(
    grossAmount: gross,
    feeAmount: fee,
    amount: amount,
    percent: percent,
  );
}

/// 仓位大小计算结果。
class PositionSizeResult {
  final double riskAmount; // 愿意承担的风险金额
  final double riskPerUnit; // 每单位风险
  final double positionSize; // 建议仓位数量

  const PositionSizeResult({
    required this.riskAmount,
    required this.riskPerUnit,
    required this.positionSize,
  });
}

/// 计算建议仓位大小。
///
/// [accountSize] 账户资金，[riskPercent] 单笔风险百分比，
/// [entry] 入场价，[stop] 止损价，[lotSize] 最小交易单位（0 表示不取整，
/// 股票 1 手 = 100 股时传 100）。
PositionSizeResult calcPositionSize({
  required double accountSize,
  required double riskPercent,
  required double entry,
  required double stop,
  double lotSize = 0,
}) {
  final riskAmount = accountSize * riskPercent / 100;
  final riskPerUnit = (entry - stop).abs();
  var size = riskPerUnit > 0 ? riskAmount / riskPerUnit : 0.0;
  if (lotSize > 0 && size > 0) {
    size = (size / lotSize).floor() * lotSize;
  }
  return PositionSizeResult(
    riskAmount: riskAmount,
    riskPerUnit: riskPerUnit,
    positionSize: size,
  );
}
