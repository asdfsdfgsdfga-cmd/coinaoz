# CoinAOZX FS

A local-first set of trading calculators for stocks, crypto and tokens:

- **Average Cost** — log multiple buys and compute the weighted average cost,
  market value and unrealized P&L.
- **Take Profit / Stop Loss** — compute TP/SL prices, profit/loss at each
  level and the risk/reward ratio, by price or by percent.
- **Profit / Loss** — single-trade net P&L with an optional round-trip fee
  rate.
- **Position Sizing** — suggested position size from account size, per-trade
  risk, entry and stop-loss, with optional lot rounding.

All inputs are stored only on the device. The app has no account, no
analytics, no advertising SDK and no remote price feed.

## Development

- Flutter SDK (see `pubspec.yaml` for the Dart/Flutter SDK constraint)
- `flutter pub get`
- `flutter run`
- `flutter analyze`

## Disclaimer

All results are manual calculations for reference only and do not
constitute investment advice.
