import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'features/auth/providers/auth_provider.dart';

class StockMateApp extends ConsumerWidget {
  const StockMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StockMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => InactivityWrapper(child: child ?? const SizedBox()),
    );
  }
}

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
