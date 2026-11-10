import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/agreement.dart';
import 'core/reminder_service.dart';
import 'screens/average_cost_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/tp_sl_screen.dart';
import 'theme.dart';
import 'widgets/agreement_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.instance.init();
  runApp(const CoinAozxApp());
}

class CoinAozxApp extends StatelessWidget {
  const CoinAozxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinAOZX FS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  ToolsFocus? _toolsFocus;

  late final List<Widget> _pages = [
    HomeScreen(onOpen: _open),
    const AverageCostScreen(),
    const TpSlScreen(),
    ToolsScreen(focus: _toolsFocus),
  ];

  void _open(int index, {ToolsFocus? focus}) {
    setState(() {
      _index = index;
      if (index == 3) _toolsFocus = focus;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAgreement());
  }

  Future<void> _maybeShowAgreement() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppAgreement.acceptedKey) ?? false) return;
    if (!mounted) return;

    final agreed = await AgreementDialog.show(context);
    if (agreed) {
      await prefs.setBool(AppAgreement.acceptedKey, true);
    } else {
      // 不同意则退出应用。
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _Dock(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/branding/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text('CoinAOZX FS'),
        ],
      ),
    );
  }
}

/// 底部导航项描述。
class _DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _DockItem(this.icon, this.activeIcon, this.label);
}

const _dockItems = [
  _DockItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _DockItem(Icons.calculate_outlined, Icons.calculate_rounded, 'Avg Cost'),
  _DockItem(Icons.flag_outlined, Icons.flag_rounded, 'TP/SL'),
  _DockItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Tools'),
];

/// 悬浮式底部停靠栏：圆角悬浮、选中项图标高亮并带柔和光晕。
class _Dock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _Dock({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _dockItems.length; i++)
              Expanded(
                child: _DockButton(
                  item: _dockItems[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final _DockItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DockButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        selected ? AppTheme.accent : Colors.white.withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: iconColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: iconColor,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
