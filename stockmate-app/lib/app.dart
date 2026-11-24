import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'features/auth/providers/auth_provider.dart';

// ─── Theme Mode Provider ───────────────────────────────────────────────────────
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('dark_mode', !isDark);
  }

  bool get isDark => state == ThemeMode.dark;
}

// ─── Dark Mode Toggle Button (AppBar actions için) ──────────────────────────
/// Her sayfanın AppBar'ında en üstte yer alan gece modu aç/kapa butonu.
class DarkModeToggleButton extends ConsumerWidget {
  const DarkModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: IconButton(
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        splashRadius: 18,
        onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        tooltip: isDark ? 'Gündüz Moduna Geç' : 'Gece Moduna Geç',
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF475569),
            size: 19,
          ),
        ),
      ),
    );
  }
}

// ─── App Root ────────────────────────────────────────────────────────────────
class StockMateApp extends ConsumerWidget {
  const StockMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'StockMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => InactivityWrapper(child: child ?? const SizedBox()),
    );
  }
}

// ─── Inactivity Auto-Logout ───────────────────────────────────────────────────
class InactivityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const InactivityWrapper({super.key, required this.child});

  @override
  ConsumerState<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends ConsumerState<InactivityWrapper> {
  Timer? _timer;
  static const _timeout = Duration(minutes: 10);

  void _resetTimer() {
    _timer?.cancel();
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (isAuth) {
      _timer = Timer(_timeout, _onTimeout);
    }
  }

  void _onTimeout() async {
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (isAuth) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('10 dakika işlem yapılmadığı için oturumunuz kapatıldı.'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _resetTimer();
      } else {
        _timer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
