import 'package:flutter/material.dart';

import '../core/agreement.dart';
import '../screens/privacy_policy_screen.dart';
import '../theme.dart';

/// 首页「风险与隐私提示」弹窗。
///
/// - 展示风险免责声明；
/// - 「《隐私政策》」可点击，跳转加载 H5；
/// - 返回 true 表示用户同意并继续。
class AgreementDialog extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDecline;

  const AgreementDialog({
    super.key,
    required this.onAgree,
    required this.onDecline,
  });

  /// 弹出协议弹窗，返回用户是否同意。
  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Risk & Privacy Notice',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return AgreementDialog(
          onAgree: () => Navigator.of(dialogContext).pop(true),
          onDecline: () => Navigator.of(dialogContext).pop(false),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }

  void _openPrivacy(BuildContext context) {
    PrivacyPolicyScreen.open(
      context,
      url: AppAgreement.privacyUrl,
      title: AppAgreement.privacyTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.accent, AppTheme.accentBright],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Risk & Privacy Notice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'This app only provides calculation tools for average cost, '
                  'take-profit/stop-loss and position sizing. All data is stored '
                  'locally on your device and nothing here constitutes investment '
                  'advice. Prices of stocks, crypto and other assets are highly '
                  'volatile — investing involves risk. Please make independent '
                  'decisions with caution.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 16),
                // 点击跳转加载隐私政策 H5
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openPrivacy(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          size: 18,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'By continuing, you confirm you have read and agree to the ',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppTheme.accentBright,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.accentBright,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onAgree,
                    child: const Text(
                      'Agree & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: TextButton(
                    onPressed: onDecline,
                    child: Text(
                      'Decline & Exit',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
