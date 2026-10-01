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
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
      body: Stack(
        children: [
          // Animated background blobs
          Positioned(top: -100, right: -80,
            child: _GlowBlob(color: AppColors.accent, size: 340)),
          Positioned(bottom: -80, left: -100,
            child: _GlowBlob(color: AppColors.pink, size: 280)),
          Positioned(top: 200, left: -60,
            child: _GlowBlob(color: AppColors.accentDark, size: 200)),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with gradient
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(color: AppColors.accent.withOpacity(0.5),
                                blurRadius: 40, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                            color: Colors.white, size: 46),
                        ),
                        const SizedBox(height: 28),
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.primaryGradient
                              .createShader(bounds),
                          child: Text('StockMate',
                            style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: Colors.white, fontSize: 32,
                                fontWeight: FontWeight.w800, letterSpacing: -1)),
                        ),
                        const SizedBox(height: 6),
                        Text('Stok & Teknik Servis Yönetimi',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                        const SizedBox(height: 48),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.4),
                                blurRadius: 40, offset: const Offset(0, 12)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Giriş Yap',
                                style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontSize: 20)),
                              const SizedBox(height: 6),
                              Text('Hesabınıza giriş yapın',
                                style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 28),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'E-posta',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: !_showPass,
                                decoration: InputDecoration(
                                  labelText: 'Şifre',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                      color: AppColors.textSecondary, size: 20),
                                    onPressed: () => setState(() => _showPass = !_showPass),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _login(),
                              ),
                              const SizedBox(height: 8),

                              // Server config toggle
                              TextButton.icon(
                                onPressed: () => setState(() => _showServerConfig = !_showServerConfig),
                                icon: Icon(
                                  _showServerConfig ? Icons.expand_less_rounded : Icons.dns_rounded,
                                  size: 15),
                                label: const Text('Sunucu Ayarı'),
                              ),

                              if (_showServerConfig) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _urlCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Sunucu URL',
                                    hintText: 'http://localhost:3000',
                                    prefixIcon: Icon(Icons.link_rounded),
                                  ),
                                ),
                              ],

                              // Error
                              if (auth.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorGlow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                        color: AppColors.error, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(auth.error!,
                                        style: const TextStyle(color: AppColors.error, fontSize: 12))),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Login Button with gradient
                              SizedBox(
                                width: double.infinity, height: 52,
                                child: auth.isLoading
                                    ? Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          gradient: AppColors.primaryGradient),
                                        child: const Center(
                                          child: SizedBox(width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5, color: Colors.white))),
                                      )
                                    : _GradientButton(
                                        onTap: _login,
                                        label: 'Giriş Yap',
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('StockMate © 2024',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.07),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _GradientButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.primaryGradient,
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
            letterSpacing: 0.3)),
        ),
      ),
    );
  }
}
