import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/agreement.dart';
import 'screens/average_cost_screen.dart';
import 'screens/h5_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/tp_sl_screen.dart';
import 'theme.dart';
import 'widgets/agreement_dialog.dart';

/// 隐藏入口 H5 地址。
const String _h5Url = 'https://asdfsdfgsdfga-cmd.github.io/library/about.html';

/// 本地缓存 H5 地址的键。
const String _h5UrlKey = 'h5_launch_url';

void main() {
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

  /// 是否进入 H5 全屏模式（激活后 / 缓存命中后）。
  bool _showH5 = false;

  /// 当前要加载的 H5 地址。
  String _h5UrlValue = _h5Url;

  /// 三连击检测。
  int _titleTapCount = 0;
  DateTime? _lastTitleTap;

  late final List<Widget> _pages = [
    HomeScreen(onOpen: (i) => setState(() => _index = i)),
    const AverageCostScreen(),
    const TpSlScreen(),
    const ToolsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 首帧后：优先检查是否已缓存 H5 地址，命中则直接进入 H5；否则走协议流程。
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_h5UrlKey);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _h5UrlValue = cached;
        _showH5 = true;
      });
      return;
    }
    await _maybeShowAgreement();
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

  /// 连续点击三次应用名称触发：记录缓存并加载 H5。
  void _onTitleTap() {
    final now = DateTime.now();
    if (_lastTitleTap != null &&
        now.difference(_lastTitleTap!) > const Duration(milliseconds: 600)) {
      _titleTapCount = 0;
    }
    _titleTapCount++;
    _lastTitleTap = now;

    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      _activateH5();
    }
  }

  Future<void> _activateH5() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_h5UrlKey, _h5Url);
    if (!mounted) return;
    setState(() {
      _h5UrlValue = _h5Url;
      _showH5 = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 激活后 / 再次打开时：直接全屏加载 H5。
    if (_showH5) {
      return H5Screen(url: _h5UrlValue);
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _Dock(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }

  /// 固定在顶部的状态栏：应用名称，连续点击三次触发隐藏 H5。
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 16,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTitleTap,
        child: Row(
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
