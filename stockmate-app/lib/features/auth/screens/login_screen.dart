import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _showPass = false;
  bool _showServerConfig = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _urlCtrl.text = ApiService.instance.baseUrl;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_urlCtrl.text.isNotEmpty && _urlCtrl.text != ApiService.instance.baseUrl) {
      await ApiService.instance.setBaseUrl(_urlCtrl.text.trim());
    }
    final ok = await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(), _passCtrl.text.trim());
    if (ok && mounted) {
      final user = ref.read(authProvider).user!;
      context.go(user.isBoss ? '/boss/dashboard' : '/employee/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0D1520), Color(0xFF0F1923), Color(0xFF131D2B)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentDark],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.accentGlow, blurRadius: 30, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 24),
                    Text('StockMate', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      letterSpacing: 1.5, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Stok Yönetim Sistemi / Inventory Management',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                    const SizedBox(height: 48),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giriş Yap / Sign In',
                            style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'E-posta / Email',
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: !_showPass,
                            decoration: InputDecoration(
                              labelText: 'Şifre / Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textSecondary),
                                onPressed: () => setState(() => _showPass = !_showPass),
                              ),
                            ),
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 8),

                          // Server config toggle
                          TextButton.icon(
                            onPressed: () => setState(() => _showServerConfig = !_showServerConfig),
                            icon: Icon(_showServerConfig ? Icons.expand_less : Icons.dns_outlined,
                              size: 16, color: AppColors.textSecondary),
                            label: Text('Sunucu Ayarı / Server Settings',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                          ),

                          if (_showServerConfig) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _urlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Sunucu URL (örn: http://192.168.1.100:3000)',
                                prefixIcon: Icon(Icons.link, color: AppColors.textSecondary),
                              ),
                            ),
                          ],

                          if (auth.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorGlow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.error.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(auth.error!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 12))),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _login,
                              child: auth.isLoading
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Giriş Yap / Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
