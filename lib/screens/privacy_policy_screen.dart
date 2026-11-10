import 'package:flutter/material.dart';

/// 应用内原生隐私政策页面（静态文案，无外链、无 WebView）。
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: const [
            _Section(
              title: 'Summary',
              body:
                  'CoinAOZX FS is a local-first set of trading calculators for '
                  'average cost, take-profit/stop-loss, profit/loss and position '
                  'sizing. The app does not require an account, does not collect '
                  'personal information, and does not transmit your inputs to any '
                  'server.',
            ),
            _Section(
              title: 'Information Stored On Your Device',
              body:
                  'Prices, quantities, asset names and any other entries you type '
                  'are saved only on this device through local storage (shared '
                  'preferences) so your inputs are still available after you close '
                  'the app. You can erase these records at any time by using the '
                  'in-app clear controls or by deleting the app.',
            ),
            _Section(
              title: 'Data Collection & Sharing',
              body:
                  'We do not collect, transmit, sell or share your personal data or '
                  'calculation inputs. The app contains no advertising SDK, no '
                  'analytics or crash-reporting SDK, and no account or social-login '
                  'feature.',
            ),
            _Section(
              title: 'No Real-Time Market Data',
              body:
                  'The app has no connection to any exchange or price feed. All '
                  'prices shown come from values you enter yourself, and every '
                  'result is a manual calculation only. Nothing in the app constitutes '
                  'investment advice.',
            ),
            _Section(
              title: 'Third-Party Services',
              body:
                  'The app uses the Flutter framework and standard system '
                  'capabilities only. It does not embed any third-party web page, '
                  'content library or remote service.',
            ),
            _Section(
              title: 'Children’s Privacy',
              body:
                  'This app is not directed at children under 13, and it does not '
                  'knowingly collect any personal information.',
            ),
            _Section(
              title: 'Contact',
              body:
                  'If you have questions about this privacy policy, please contact '
                  'the developer through the contact channel listed on the App '
                  'Store product page.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
