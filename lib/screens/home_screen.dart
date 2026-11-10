import 'package:flutter/material.dart';

import '../theme.dart';
import 'privacy_policy_screen.dart';
import 'tools_screen.dart';

/// 首页：应用简介 + 各工具的快捷入口。
class HomeScreen extends StatelessWidget {
  final void Function(int index, {ToolsFocus? focus}) onOpen;

  const HomeScreen({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _HeroCard(onTap: () => onOpen(1)),
          const SizedBox(height: 16),
          const Text(
            'Tools',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ToolCard(
                  icon: Icons.flag,
                  title: 'TP / Stop Loss',
                  subtitle: 'Targets & risk/reward',
                  onTap: () => onOpen(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToolCard(
                  icon: Icons.receipt_long,
                  title: 'Profit / Loss',
                  subtitle: 'Single-trade P&L',
                  onTap: () => onOpen(3, focus: ToolsFocus.pnl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ToolCard(
                  icon: Icons.shield_outlined,
                  title: 'Position Sizing',
                  subtitle: 'Risk-based sizing',
                  onTap: () => onOpen(3, focus: ToolsFocus.sizing),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _TipCard(),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => PrivacyPolicyScreen.open(context),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                Icons.show_chart_rounded,
                size: 150,
                color: AppTheme.accent.withValues(alpha: 0.05),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: AppTheme.accent,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Average Cost\nCalculator',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Log multiple buys to auto-calculate the weighted average cost of stocks, crypto, tokens and other assets.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.62),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppTheme.accent,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.accent, size: 22),
                  const Spacer(),
                  Icon(
                    Icons.north_east,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.amber.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This app is for reference only and does not constitute investment advice. Investing involves risk — decide independently based on your own risk tolerance.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
