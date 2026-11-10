import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'calculations.dart';
import 'position.dart';

/// 持仓本地存储：所有数据只保存在设备上，不联网上传。
class PositionsStore {
  static const _key = 'positions_v1';
  static const _legacyKey = 'avg_cost_asset';

  static final _rand = Random();

  static Future<List<Position>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        final list = decoded.map((e) => Position.fromJson(e)).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {
        // 损坏数据则回退到迁移逻辑。
      }
    }

    // 迁移旧版单条持仓的管道分隔数据。
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      final migrated = _fromLegacy(legacy);
      if (migrated != null) {
        await prefs.remove(_legacyKey);
        return [migrated];
      }
    }
    return [];
  }

  static Future<void> save(List<Position> positions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(positions.map((p) => p.toJson()).toList()),
    );
  }

  static String newId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'p_${now}_${_rand.nextInt(1 << 30).toRadixString(16)}';
  }

  static Position createBlank() => Position(
        id: newId(),
        type: AssetType.crypto,
        name: '',
        transactions: [],
        updatedAt: DateTime.now(),
      );

  static Position? _fromLegacy(String raw) {
    try {
      final parts = raw.split('|');
      if (parts.length < 4) return null;
      final typeIndex = int.tryParse(parts[0]) ?? 2;
      final safeType = (typeIndex < 0 || typeIndex >= AssetType.values.length)
          ? 2
          : typeIndex;
      final name = parts[1];
      final current = double.tryParse(parts[2]);
      final txsRaw = parts[3];
      final txs = <Transaction>[];
      if (txsRaw.isNotEmpty) {
        for (final chunk in txsRaw.split(';')) {
          final kv = chunk.split(',');
          if (kv.length >= 2) {
            final p = double.tryParse(kv[0]);
            final q = double.tryParse(kv[1]);
            if (p != null && q != null) txs.add(Transaction(price: p, quantity: q));
          }
        }
      }
      return Position(
        id: newId(),
        type: AssetType.values[safeType],
        name: name,
        currentPrice: current,
        transactions: txs,
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
